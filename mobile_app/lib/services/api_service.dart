import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/patient.dart';

class ApiService {
  // Thay đổi IP này thành IP máy tính chạy FastAPI (ví dụ: 192.168.1.x)
  // hoặc URL Cloudflare Tunnel / Render miễn phí
  static const String baseUrl = 'http://10.0.2.2:8000'; // 10.0.2.2 cho Android Emulator hoặc http://localhost:8000

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

  static Future<List<Map<String, dynamic>>> fetchHistory({String? customHost}) async {
    final host = customHost ?? baseUrl;
    final url = Uri.parse('$host/api/v1/records');

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(utf8.decode(response.bodyBytes));
      return list.map((e) => e as Map<String, dynamic>).toList();
    } else {
      throw Exception('Không thể tải lịch sử bệnh án');
    }
  }
}
