import 'package:flutter_test/flutter_test.dart';
import 'package:cardio_xai_mobile/services/firebase_service.dart';
import 'package:cardio_xai_mobile/services/api_service.dart';
import 'package:cardio_xai_mobile/models/patient.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Firebase Firestore Sync & Data Normalization Tests', () {
    test('1. Chuẩn hóa hồ sơ từ Web (camelCase) sang cấu trúc Mobile', () {
      final webRecord = {
        'id': '1731140000000',
        'roleType': 'doctor',
        'patientName': 'Nguyễn Văn Minh',
        'date': '09/11/2026 17:15',
        'riskProb': 0.725,
        'riskLevel': 'Nguy cơ cao',
        'bp': '155/95',
        'bmi': '27.4',
        'chol': 3,
        'gluc': 2,
        'recommendation': 'Chỉ định làm ECG và siêu âm tim Doppler',
      };

      final normalized = FirebaseService.normalizeRecord(webRecord, '1731140000000');

      expect(normalized['id'], '1731140000000');
      expect(normalized['patient_name'], 'Nguyễn Văn Minh');
      expect(normalized['roleType'], 'doctor');
      expect(normalized['risk_probability'], 0.725);
      expect(normalized['risk_level'], 'Nguy cơ cao');
      expect(normalized['ap_hi'], 155);
      expect(normalized['ap_lo'], 95);
      expect(normalized['bmi'], '27.4');
      expect(normalized['cholesterol'], 3);
      expect(normalized['gluc'], 2);
      expect(normalized['created_at'], '09/11/2026 17:15');
      expect(normalized['recommendation'], contains('ECG'));
    });

    test('2. Chuẩn hóa hồ sơ từ Mobile (snake_case) đảm bảo tương thích 100%', () {
      final mobileRecord = {
        'id': 1731140000001,
        'roleType': 'patient',
        'patient_name': 'Bệnh nhân',
        'created_at': '09/11/2026 17:20',
        'risk_probability': 0.18,
        'risk_level': 'Nguy cơ thấp (An toàn)',
        'ap_hi': 118,
        'ap_lo': 76,
        'bmi': 21.5,
        'cholesterol': 1,
        'gluc': 1,
        'recommendation': 'Tiếp tục duy trì lối sống lành mạnh',
      };

      final normalized = FirebaseService.normalizeRecord(mobileRecord, '1731140000001');

      expect(normalized['patient_name'], 'Bệnh nhân');
      expect(normalized['risk_probability'], 0.18);
      expect(normalized['risk_level'], contains('Nguy cơ thấp'));
      expect(normalized['ap_hi'], 118);
      expect(normalized['ap_lo'], 76);
      expect(normalized['cholesterol'], 1);
    });

    test('3. Phân tích lâm sàng offline / client-side tính toán chính xác và trả về đầy đủ SHAP', () async {
      final patient = PatientInput(
        age: 54,
        gender: 2,
        height: 168,
        weight: 86,
        apHi: 155,
        apLo: 98,
        cholesterol: 3,
        gluc: 2,
        smoke: 1,
        alco: 1,
        active: 0,
        patientName: 'Trần Văn Cao',
      );

      final result = await ApiService.analyzePatient(patient, customHost: 'http://127.0.0.1:59999');

      expect(result.prediction.riskProbability, greaterThan(0.65));
      expect(result.prediction.riskLevel, 'Nguy cơ cao');
      expect(result.shapContributions.length, greaterThanOrEqualTo(5));

      final history = await ApiService.fetchHistory(customHost: 'http://127.0.0.1:59999');
      expect(history.any((r) => r['patient_name'] == 'Trần Văn Cao'), isTrue);
    });
  });
}
