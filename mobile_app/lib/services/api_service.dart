import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/patient.dart';

class ApiService {
  // 10.0.2.2 cho Android Emulator hoặc http://IP_LAN:8000 khi chạy máy thật
  static const String baseUrl = 'http://10.0.2.2:8000';

  // ==========================================
  // XÁC THỰC TÀI KHOẢN (FIREBASE / SQL BACKEND)
  // ==========================================
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    String? firebaseUid,
    String? customHost,
  }) async {
    final host = customHost ?? baseUrl;
    final url = Uri.parse('$host/api/v1/auth/register');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim(),
        'password': password,
        'full_name': fullName.trim(),
        'phone': phone?.trim(),
        'firebase_uid': firebaseUid,
      }),
    );

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['detail'] ?? 'Đăng ký thất bại!');
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    String? customHost,
  }) async {
    final host = customHost ?? baseUrl;
    final url = Uri.parse('$host/api/v1/auth/login');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim(),
        'password': password,
      }),
    );

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['detail'] ?? 'Đăng nhập thất bại!');
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
