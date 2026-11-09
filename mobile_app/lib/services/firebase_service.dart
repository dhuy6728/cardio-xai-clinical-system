import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Dịch vụ đồng bộ dữ liệu thời gian thực giữa Web (GitHub Pages) và Mobile (Android)
/// Sử dụng chung Google Firebase Firestore Collection: "assessment_records"
class FirebaseService {
  static bool _initialized = false;
  static bool get isInitialized => _initialized;

  static const String collectionName = 'assessment_records';

  /// Khởi tạo Firebase SDK (Hỗ trợ Android, Web và graceful fallback)
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      if (kIsWeb) {
        await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: "AIzaSyCVtfCHB27aszRGQvvMf13JAXq4EZL9CX0",
            authDomain: "healthcare-xai.firebaseapp.com",
            projectId: "healthcare-xai",
            storageBucket: "healthcare-xai.firebasestorage.app",
            messagingSenderId: "506715356518",
            appId: "1:506715356518:web:20f72d91be3f66583edca7",
            measurementId: "G-E5PEK4MJMR",
          ),
        );
      } else {
        // Trên Android đọc trực tiếp từ google-services.json
        await Firebase.initializeApp();
      }
      _initialized = true;
      debugPrint("Firebase initialized successfully for CardioCare AI!");
    } catch (e) {
      debugPrint("Firebase initialize notice: $e (Falling back gracefully to local storage)");
    }
  }

  /// Lưu bản ghi ca khám vào Cloud Firestore
  static Future<bool> saveAssessmentRecord(Map<String, dynamic> record) async {
    if (!_initialized) {
      await initialize();
    }
    if (!_initialized) return false;

    try {
      final docId = record['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();
      await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(docId)
          .set(record, SetOptions(merge: true));
      debugPrint("Firebase: Đã đồng bộ hồ sơ [$docId] lên Firestore thành công!");
      return true;
    } catch (e) {
      debugPrint("Firebase: Lưu lên Firestore không thành công ($e)");
      return false;
    }
  }

  /// Tải danh sách hồ sơ từ Cloud Firestore
  static Future<List<Map<String, dynamic>>> fetchAssessmentRecords() async {
    if (!_initialized) {
      await initialize();
    }
    if (!_initialized) return [];

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection(collectionName)
          .get();

      final List<Map<String, dynamic>> records = [];
      for (final doc in querySnapshot.docs) {
        records.add(normalizeRecord(doc.data(), doc.id));
      }

      // Sắp xếp hồ sơ mới nhất lên đầu
      records.sort((a, b) => _extractTime(b).compareTo(_extractTime(a)));
      return records;
    } catch (e) {
      debugPrint("Firebase fetch notice: $e");
      return [];
    }
  }

  /// Stream lắng nghe dữ liệu thời gian thực từ Firestore
  static Stream<List<Map<String, dynamic>>> streamAssessmentRecords() {
    if (!_initialized) {
      initialize();
    }

    return FirebaseFirestore.instance
        .collection(collectionName)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs.map((doc) => normalizeRecord(doc.data(), doc.id)).toList();
          list.sort((a, b) => _extractTime(b).compareTo(_extractTime(a)));
          return list;
        });
  }

  /// Xóa bản ghi khỏi Firestore
  static Future<bool> deleteAssessmentRecord(String id) async {
    if (!_initialized) await initialize();
    if (!_initialized) return false;
    try {
      await FirebaseFirestore.instance.collection(collectionName).doc(id).delete();
      return true;
    } catch (e) {
      debugPrint("Firebase: Xóa hồ sơ thất bại: $e");
      return false;
    }
  }

  /// Chuẩn hóa record để tương thích 100% giữa Web (camelCase) và Mobile/FastAPI (snake_case)
  static Map<String, dynamic> normalizeRecord(Map<String, dynamic> raw, String docId) {
    // Parse huyết áp
    int apHi = 120;
    int apLo = 80;
    if (raw['ap_hi'] != null) {
      apHi = (raw['ap_hi'] as num).toInt();
    } else if (raw['bp'] != null) {
      final parts = raw['bp'].toString().split('/');
      if (parts.isNotEmpty) apHi = int.tryParse(parts[0]) ?? 120;
      if (parts.length > 1) apLo = int.tryParse(parts[1]) ?? 80;
    }
    if (raw['ap_lo'] != null) {
      apLo = (raw['ap_lo'] as num).toInt();
    }

    // Parse xác suất nguy cơ
    double riskProb = 0.0;
    if (raw['risk_probability'] != null) {
      riskProb = (raw['risk_probability'] as num).toDouble();
    } else if (raw['riskProb'] != null) {
      riskProb = (raw['riskProb'] as num).toDouble();
    }

    final dateStr = raw['date'] ?? raw['created_at'] ?? 'Gần đây';

    return {
      'id': raw['id'] ?? docId,
      'patient_name': raw['patientName'] ?? raw['patient_name'] ?? 'Bệnh nhân',
      'roleType': raw['roleType'] ?? 'patient',
      'risk_probability': riskProb,
      'risk_level': raw['riskLevel'] ?? raw['risk_level'] ?? (riskProb >= 0.65 ? 'Nguy cơ cao' : riskProb >= 0.35 ? 'Nguy cơ trung bình' : 'Nguy cơ thấp (An toàn)'),
      'ap_hi': apHi,
      'ap_lo': apLo,
      'bmi': raw['bmi']?.toString() ?? '22.0',
      'age': raw['age'] ?? 50,
      'cholesterol': raw['cholesterol'] ?? raw['chol'] ?? 1,
      'gluc': raw['gluc'] ?? 1,
      'smoke': raw['smoke'] ?? 0,
      'alco': raw['alco'] ?? 0,
      'active': raw['active'] ?? 1,
      'created_at': dateStr,
      'recommendation': raw['recommendation'] ?? raw['advice'] ?? '',
    };
  }

  static int _extractTime(Map<String, dynamic> r) {
    if (r['id'] is num) return (r['id'] as num).toInt();
    if (r['id'] is String) {
      final parsed = int.tryParse(r['id']);
      if (parsed != null) return parsed;
    }
    return 0;
  }
}
