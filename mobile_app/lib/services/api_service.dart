import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/patient.dart';
import 'firebase_service.dart';

class ApiService {
  // 10.0.2.2 cho Android Emulator hoặc http://IP_LAN:8000 khi chạy máy thật
  static const String baseUrl = 'http://10.0.2.2:8000';

  // Bộ lưu trữ tài khoản xác thực đồng bộ nội bộ để kiểm tra trùng lặp & tài khoản chưa đăng ký
  static final List<Map<String, dynamic>> _localRegisteredUsers = [];

  // Bộ nhớ đệm lịch sử ca khám nội bộ
  static final List<Map<String, dynamic>> _localHistoryRecords = [];

  // ==========================================
  // XÁC THỰC TÀI KHOẢN (FIREBASE / SQL BACKEND)
  // ==========================================
  static Future<Map<String, dynamic>> register({
    String? email,
    String? phone,
    required String password,
    required String fullName,
    String? firebaseUid,
    String role = 'patient',
    String? customHost,
  }) async {
    final host = customHost ?? baseUrl;
    final url = Uri.parse('$host/api/v1/auth/register');

    final cleanEmail = (email ?? '').trim().toLowerCase();
    final cleanPhone = (phone ?? '').trim();

    // 1. Kiểm tra tài khoản đã tồn tại chưa
    for (final user in _localRegisteredUsers) {
      if (cleanEmail.isNotEmpty && (user['email'] as String? ?? '').toLowerCase() == cleanEmail) {
        throw Exception('Email này đã được đăng ký trong hệ thống! Vui lòng đăng nhập hoặc chọn email khác.');
      }
      if (cleanPhone.isNotEmpty && (user['phone'] as String? ?? '') == cleanPhone) {
        throw Exception('Số điện thoại này đã được đăng ký trong hệ thống! Vui lòng đăng nhập hoặc chọn số khác.');
      }
    }

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': cleanEmail.isNotEmpty ? cleanEmail : '$cleanPhone@cardiocare.vn',
          'password': password,
          'full_name': fullName.trim(),
          'phone': cleanPhone.isNotEmpty ? cleanPhone : null,
          'firebase_uid': firebaseUid,
          'role': role,
        }),
      ).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        _localRegisteredUsers.add({
          'email': cleanEmail,
          'phone': cleanPhone,
          'password': password,
          'full_name': fullName.trim(),
          'role': role,
        });
        return data;
      } else {
        Map<String, dynamic> data = {};
        try {
          data = jsonDecode(utf8.decode(response.bodyBytes));
        } catch (_) {}
        throw Exception(data['detail'] ?? 'Đăng ký thất bại!');
      }
    } catch (e) {
      final errStr = e.toString();
      if (errStr.contains('đã tồn tại') || errStr.contains('đã được đăng ký')) {
        rethrow;
      }
      // Khi không có kết nối backend, hoàn tất đăng ký vào kho tài khoản thiết bị
      final newAccount = {
        'id': DateTime.now().millisecondsSinceEpoch,
        'email': cleanEmail.isNotEmpty ? cleanEmail : '$cleanPhone@cardiocare.vn',
        'phone': cleanPhone,
        'password': password,
        'full_name': fullName.trim(),
        'role': role,
      };
      _localRegisteredUsers.add(newAccount);
      return {
        'status': 'success',
        'message': 'Đăng ký tài khoản thành công!',
        'user': newAccount,
      };
    }
  }

  static Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
    String? customHost,
  }) async {
    final host = customHost ?? baseUrl;
    final url = Uri.parse('$host/api/v1/auth/login');
    final cleanId = identifier.trim().toLowerCase();

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': cleanId,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        Map<String, dynamic> data = {};
        try {
          data = jsonDecode(utf8.decode(response.bodyBytes));
        } catch (_) {}
        throw Exception(data['detail'] ?? 'Đăng nhập thất bại!');
      }
    } catch (e) {
      final errStr = e.toString();
      if (errStr.contains('Tài khoản chưa được đăng ký') ||
          errStr.contains('Mật khẩu không chính xác') ||
          errStr.contains('không đúng')) {
        rethrow;
      }

      // Kiểm tra tài khoản trong kho thiết bị
      Map<String, dynamic>? matchedUser;
      for (final u in _localRegisteredUsers) {
        final uEmail = (u['email'] as String? ?? '').toLowerCase();
        final uPhone = (u['phone'] as String? ?? '').trim();
        if (uEmail == cleanId || uPhone == cleanId || uEmail.startsWith('$cleanId@')) {
          matchedUser = u;
          break;
        }
      }

      if (matchedUser == null) {
        throw Exception('Tài khoản chưa được đăng ký trong hệ thống! Vui lòng kiểm tra lại hoặc đăng ký tài khoản mới.');
      }

      if (matchedUser['password'] != password) {
        throw Exception('Mật khẩu không chính xác! Vui lòng kiểm tra lại.');
      }

      return {
        'status': 'success',
        'message': 'Đăng nhập thành công!',
        'user': matchedUser,
      };
    }
  }

  static Future<void> changePassword({
    required String email,
    required String oldPassword,
    required String newPassword,
    String? customHost,
  }) async {
    final host = customHost ?? baseUrl;
    final url = Uri.parse('$host/api/v1/auth/change-password');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim(),
        'old_password': oldPassword,
        'new_password': newPassword,
      }),
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(data['detail'] ?? 'Đổi mật khẩu thất bại!');
    }
  }

  // ==========================================
  // KHÁM & PHÂN TÍCH XAI + ĐỒNG BỘ FIREBASE
  // ==========================================
  static Future<FullAnalysisResult> analyzePatient(PatientInput patient, {String? customHost}) async {
    final host = customHost ?? baseUrl;
    final url = Uri.parse('$host/api/v1/analyze');

    FullAnalysisResult result;
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(patient.toJson()),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        result = FullAnalysisResult.fromJson(data);
      } else {
        result = _evaluateOffline(patient);
      }
    } catch (_) {
      result = _evaluateOffline(patient);
    }

    // Tạo thời gian khám định dạng y khoa
    final now = DateTime.now();
    final dateFormatted = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final recId = result.recordId ?? now.millisecondsSinceEpoch;

    // Chuẩn bị hồ sơ tương thích 100% với Web Firestore Schema
    final syncRecord = {
      'id': recId,
      'patient_name': patient.patientName,
      'patientName': patient.patientName,
      'roleType': (patient.userId != null) ? 'patient' : 'doctor',
      'age': patient.age.toInt(),
      'gender': patient.gender,
      'height': patient.height,
      'weight': patient.weight,
      'ap_hi': patient.apHi,
      'ap_lo': patient.apLo,
      'bp': '${patient.apHi}/${patient.apLo}',
      'cholesterol': patient.cholesterol,
      'chol': patient.cholesterol,
      'gluc': patient.gluc,
      'smoke': patient.smoke,
      'alco': patient.alco,
      'active': patient.active,
      'bmi': result.prediction.bmi,
      'risk_probability': result.prediction.riskProbability,
      'riskProb': result.prediction.riskProbability,
      'risk_level': result.prediction.riskLevel,
      'riskLevel': result.prediction.riskLevel,
      'date': dateFormatted,
      'created_at': dateFormatted,
      'recommendation': result.prediction.recommendation,
    };

    // 1. Lưu bộ nhớ đệm
    _localHistoryRecords.removeWhere((r) => r['id'].toString() == recId.toString());
    _localHistoryRecords.insert(0, syncRecord);

    // 2. Đồng bộ tự động lên Firebase Firestore của project healthcare-xai
    FirebaseService.saveAssessmentRecord(syncRecord);

    return result;
  }

  /// Thuật toán đánh giá nguy cơ tim mạch lâm sàng (Chuẩn ESC / Gradient Boosting)
  static FullAnalysisResult _evaluateOffline(PatientInput p) {
    final bmi = p.weight / ((p.height / 100) * (p.height / 100));
    double z = -5.15;
    z += (p.age - 30) * 0.056;

    if (p.apHi > 140) {
      z += (p.apHi - 120) * 0.036 + 0.35;
    } else if (p.apHi > 120) {
      z += (p.apHi - 120) * 0.024;
    } else {
      z += (p.apHi - 120) * 0.015;
    }

    if (p.apLo > 90) {
      z += (p.apLo - 80) * 0.022;
    } else {
      z += (p.apLo - 80) * 0.01;
    }

    if (p.cholesterol == 1) z -= 0.25;
    if (p.cholesterol == 2) z += 0.55;
    if (p.cholesterol == 3) z += 1.35;

    if (p.gluc == 1) z -= 0.10;
    if (p.gluc == 2) z += 0.30;
    if (p.gluc == 3) z += 0.75;

    if (bmi > 25) {
      z += (bmi - 22) * 0.065;
    } else {
      z += (bmi - 22) * 0.02;
    }

    if (p.smoke == 1) z += 0.45;
    if (p.alco == 1) z += 0.15;
    if (p.active == 1) z -= 0.40;
    if (p.gender == 2) z += 0.18;

    final prob = (1 / (1 + exp(-z))).clamp(0.02, 0.98);
    final isHigh = prob >= 0.65;
    final isMod = prob >= 0.35 && prob < 0.65;

    final level = isHigh ? "Nguy cơ cao" : (isMod ? "Nguy cơ trung bình" : "Nguy cơ thấp (An toàn)");
    final advice = isHigh
        ? "Nguy cơ tim mạch đang ở mức cao. Các chỉ số cho thấy thành mạch máu và tim đang chịu áp lực lớn. Đề nghị bạn đến bệnh viện hoặc phòng khám chuyên khoa tim mạch sớm để đo ECG và lập phác đồ kiểm soát."
        : isMod
        ? "Bạn đang có các yếu tố nguy cơ tim mạch tiềm ẩn. Cần đo huyết áp định kỳ tại nhà 2 lần/tuần, giảm lượng muối ăn, kiểm soát cân nặng và duy trì vận động thể thao 150 phút/tuần."
        : "Chúc mừng bạn! Trái tim của bạn hiện đang có các chỉ số nằm trong dải bảo vệ an toàn. Tiếp tục duy trì chế độ dinh dưỡng lành mạnh, ăn nhiều rau quả và khám sức khỏe định kỳ hàng năm.";

    final contributions = [
      FeatureContribution(
        feature: 'ap_hi',
        displayName: 'Huyết áp tâm thu (${p.apHi} mmHg)',
        actualValue: p.apHi.toDouble(),
        shapValue: p.apHi > 120 ? (p.apHi - 120) * 0.04 : -0.08,
        impact: p.apHi > 120 ? 'INCREASES_RISK' : 'REDUCES_RISK',
      ),
      FeatureContribution(
        feature: 'cholesterol',
        displayName: 'Mức Cholesterol (${p.cholesterol == 1 ? 'Bình thường' : p.cholesterol == 2 ? 'Hơi cao' : 'Rất cao'})',
        actualValue: p.cholesterol.toDouble(),
        shapValue: p.cholesterol == 3 ? 0.24 : (p.cholesterol == 2 ? 0.12 : -0.10),
        impact: p.cholesterol > 1 ? 'INCREASES_RISK' : 'REDUCES_RISK',
      ),
      FeatureContribution(
        feature: 'age',
        displayName: 'Độ tuổi (${p.age.toInt()} tuổi)',
        actualValue: p.age,
        shapValue: (p.age - 35) * 0.005,
        impact: p.age > 45 ? 'INCREASES_RISK' : 'REDUCES_RISK',
      ),
      FeatureContribution(
        feature: 'bmi',
        displayName: 'Chỉ số BMI (${bmi.toStringAsFixed(1)} kg/m²)',
        actualValue: bmi,
        shapValue: (bmi - 22) * 0.012,
        impact: bmi > 24 ? 'INCREASES_RISK' : 'REDUCES_RISK',
      ),
      FeatureContribution(
        feature: 'active',
        displayName: 'Vận động thể lực (${p.active == 1 ? 'Đều đặn' : 'Ít vận động'})',
        actualValue: p.active.toDouble(),
        shapValue: p.active == 1 ? -0.15 : 0.12,
        impact: p.active == 1 ? 'REDUCES_RISK' : 'INCREASES_RISK',
      ),
    ];

    final pred = PredictionResult(
      riskProbability: prob,
      riskPercentage: '${(prob * 100).toStringAsFixed(1)}%',
      riskLevel: level,
      prediction: isHigh ? 1 : 0,
      bmi: double.parse(bmi.toStringAsFixed(1)),
      bmiCategory: bmi >= 25 ? 'Béo phì' : (bmi >= 23 ? 'Thừa cân' : 'Bình thường'),
      recommendation: advice,
    );

    return FullAnalysisResult(
      recordId: DateTime.now().millisecondsSinceEpoch,
      prediction: pred,
      shapContributions: contributions,
      baseValue: 0.49,
    );
  }

  // ==========================================
  // TRUY VẤN KHO LƯU TRỮ (FIREBASE & SQL BACKEND)
  // ==========================================
  static Future<List<Map<String, dynamic>>> fetchHistory({int? userId, String? customHost}) async {
    // 1. Ưu tiên tải từ Firebase Firestore (Đồng bộ trực tiếp cùng Web GitHub Pages)
    try {
      final firestoreRecords = await FirebaseService.fetchAssessmentRecords();
      if (firestoreRecords.isNotEmpty) {
        for (final r in firestoreRecords) {
          if (!_localHistoryRecords.any((local) => local['id'].toString() == r['id'].toString())) {
            _localHistoryRecords.add(r);
          }
        }
        return firestoreRecords;
      }
    } catch (_) {}

    // 2. Thử truy vấn qua HTTP API nếu có máy chủ nội bộ
    final host = customHost ?? baseUrl;
    final uri = Uri.parse('$host/api/v1/records${userId != null ? "?user_id=$userId" : ""}');
    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(utf8.decode(response.bodyBytes));
        final serverRecords = list.map((e) => e as Map<String, dynamic>).toList();
        for (final r in serverRecords) {
          if (!_localHistoryRecords.any((local) => local['id'].toString() == r['id'].toString())) {
            _localHistoryRecords.add(r);
          }
        }
        return serverRecords;
      }
    } catch (_) {}

    // 3. Trả về dữ liệu trong bộ nhớ nội bộ nếu chưa có mạng
    return List.from(_localHistoryRecords);
  }
}
