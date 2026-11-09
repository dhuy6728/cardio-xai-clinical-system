import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cardio_xai_mobile/screens/assessment_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AssessmentScreen UI & Clean Input Tests', () {
    testWidgets('1. Tất cả các ô nhập liệu hoàn toàn TRỐNG và BMI hiển thị BMI: --', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: AssessmentScreen(
          apiHost: 'http://127.0.0.1:8000',
          user: {'role': 'patient', 'full_name': 'Nguyễn Văn Test'},
        ),
      ));

      // Kiểm tra tất cả TextFormField đều rỗng (Không có dữ liệu điền sẵn)
      final formFields = find.byType(TextFormField);
      for (final field in formFields.evaluate()) {
        final widget = field.widget as TextFormField;
        expect(widget.controller?.text, isEmpty);
      }

      // Kiểm tra huy hiệu BMI mặc định là "BMI: --"
      expect(find.text('BMI: --'), findsOneWidget);

      // Kiểm tra có các nhãn trường cân xứng
      expect(find.text('Tuổi'), findsOneWidget);
      expect(find.text('Chiều cao (cm)'), findsOneWidget);
      expect(find.text('Cân nặng (kg)'), findsOneWidget);
      expect(find.text('HA Tâm thu (mmHg)'), findsOneWidget);
      expect(find.text('HA Tâm trương (mmHg)'), findsOneWidget);
      expect(find.text('Hút thuốc'), findsOneWidget);
      expect(find.text('Rượu bia'), findsOneWidget);
      expect(find.text('Vận động'), findsOneWidget);

      // Không có menu ca bệnh mẫu / preset
      expect(find.byIcon(Icons.flash_on), findsNothing);
    });

    testWidgets('2. Tự động tính toán huy hiệu BMI khi người dùng nhập chiều cao và cân nặng', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: AssessmentScreen(
          apiHost: 'http://127.0.0.1:8000',
          user: {'role': 'patient', 'full_name': 'Nguyễn Văn Test'},
        ),
      ));

      // Nhập chiều cao 170cm và cân nặng 65kg
      await tester.enterText(find.widgetWithText(TextFormField, 'Chiều cao (cm)'), '170');
      await tester.enterText(find.widgetWithText(TextFormField, 'Cân nặng (kg)'), '65');
      await tester.pumpAndSettle();

      // BMI = 65 / (1.7^2) = 22.5 (Bình thường)
      expect(find.text('BMI: 22.5 (Bình thường)'), findsOneWidget);
    });

    testWidgets('3. Từ chối gửi khi các trường bắt buộc bị bỏ trống', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(600, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MaterialApp(
        home: AssessmentScreen(
          apiHost: 'http://127.0.0.1:8000',
          user: {'role': 'patient', 'full_name': 'Nguyễn Văn Test'},
        ),
      ));

      // Bấm nút Đánh giá nguy cơ
      await tester.tap(find.text('Đánh giá nguy cơ & lưu kho lưu trữ'));
      await tester.pumpAndSettle();

      // Phải báo lỗi validation
      expect(find.text('Vui lòng nhập tuổi'), findsOneWidget);
      expect(find.text('Vui lòng nhập chiều cao'), findsOneWidget);
      expect(find.text('Vui lòng nhập cân nặng'), findsOneWidget);
    });
  });
}
