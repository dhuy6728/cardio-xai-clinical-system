import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/patient.dart';

class ApiService {
  // 10.0.2.2 cho Android Emulator hoặc http://IP_LAN:8000 khi chạy máy thật
  static const String baseUrl = 'http://10.0.2.2:8000';

  // Bộ lưu trữ tài khoản xác thực đồng bộ nội bộ để kiểm tra trùng lặp & tài khoản chưa đăng ký
  static final List<Map<String, dynamic>> _localRegisteredUsers = [];

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
  // KHÁM & PHÂN TÍCH XAI
  // ==========================================
  static Future<FullAnalysisResult> analyzePatient(PatientInput patient, {String? customHost}) async {
    final host = customHost ?? baseUrl;
    final url = Uri.parse('$host/api/v1/analyze');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(patient.toJson()),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return FullAnalysisResult.fromJson(data);
    } else {
      throw Exception('Lỗi kết nối máy chủ (${response.statusCode}): ${response.body}');
    }
  }

  static Future<List<Map<String, dynamic>>> fetchHistory({int? userId, String? customHost}) async {
    final host = customHost ?? baseUrl;
    final uri = Uri.parse('$host/api/v1/records${userId != null ? "?user_id=$userId" : ""}');

    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(utf8.decode(response.bodyBytes));
      return list.map((e) => e as Map<String, dynamic>).toList();
    } else {
      throw Exception('Không thể tải lịch sử bệnh án');
    }
  }
}
