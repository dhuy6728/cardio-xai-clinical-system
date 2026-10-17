import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cardio_xai_mobile/screens/auth_screen.dart';
import 'package:cardio_xai_mobile/services/api_service.dart';

void main() {
  group('ApiService Authentication Tests', () {
    test('1. Đăng nhập tài khoản chưa đăng ký sẽ bị từ chối kèm thông báo rõ ràng', () async {
      try {
        await ApiService.login(
          identifier: 'chuadangky@gmail.com',
          password: 'password123',
          customHost: 'http://127.0.0.1:59999', // Port không có server để test offline/local fallback
        );
        fail('Lẽ ra phải ném Exception từ chối tài khoản chưa đăng ký');
      } catch (e) {
        expect(e.toString(), contains('Tài khoản chưa được đăng ký trong hệ thống'));
      }
    });

    test('2. Đăng ký tài khoản mới bằng Số điện thoại thành công', () async {
      final res = await ApiService.register(
        phone: '0912345678',
        password: 'securepassword123',
        fullName: 'Nguyễn Văn Minh',
        role: 'patient',
        customHost: 'http://127.0.0.1:59999',
      );
      expect(res['status'], 'success');
      expect(res['user']['phone'], '0912345678');
      expect(res['user']['full_name'], 'Nguyễn Văn Minh');
    });

    test('3. Đăng ký lại cùng Số điện thoại sẽ bị từ chối do trùng lặp', () async {
      try {
        await ApiService.register(
          phone: '0912345678',
          password: 'differentpassword',
          fullName: 'Người Trùng SĐT',
          role: 'patient',
          customHost: 'http://127.0.0.1:59999',
        );
        fail('Lẽ ra phải ném Exception từ chối số điện thoại đã tồn tại');
      } catch (e) {
        expect(e.toString(), contains('Số điện thoại này đã được đăng ký trong hệ thống'));
      }
    });

    test('4. Đăng nhập đúng SĐT nhưng SAI mật khẩu sẽ bị từ chối', () async {
      try {
        await ApiService.login(
          identifier: '0912345678',
          password: 'saimatkhau',
          customHost: 'http://127.0.0.1:59999',
        );
        fail('Lẽ ra phải ném Exception từ chối sai mật khẩu');
      } catch (e) {
        expect(e.toString(), contains('Mật khẩu không chính xác'));
      }
    });

    test('5. Đăng nhập đúng SĐT và ĐÚNG mật khẩu thành công', () async {
      final res = await ApiService.login(
        identifier: '0912345678',
        password: 'securepassword123',
        customHost: 'http://127.0.0.1:59999',
      );
      expect(res['status'], 'success');
      expect(res['user']['phone'], '0912345678');
    });

    test('6. Đăng ký tài khoản Bác sĩ bằng Email thành công', () async {
      final res = await ApiService.register(
        email: 'dr.tran@hospital.vn',
        password: 'doctorpassword123',
        fullName: 'BS. Trần Văn Hùng',
        role: 'doctor',
        customHost: 'http://127.0.0.1:59999',
      );
      expect(res['status'], 'success');
      expect(res['user']['email'], 'dr.tran@hospital.vn');
      expect(res['user']['role'], 'doctor');
    });

    test('7. Đăng ký lại cùng Email sẽ bị từ chối do trùng lặp', () async {
      try {
        await ApiService.register(
          email: 'dr.tran@hospital.vn',
          password: 'anotherpassword',
          fullName: 'Trùng Email',
          role: 'doctor',
          customHost: 'http://127.0.0.1:59999',
        );
        fail('Lẽ ra phải ném Exception từ chối email đã tồn tại');
      } catch (e) {
        expect(e.toString(), contains('Email này đã được đăng ký trong hệ thống'));
      }
    });
  });

  group('AuthScreen Widget Tests', () {
    testWidgets('Tất cả các ô nhập liệu hoàn toàn TRỐNG và hiển thị gợi ý (hint text)', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: AuthScreen(apiHost: 'http://127.0.0.1:8000', onAuthSuccess: (_) {}),
      ));

      // Kiểm tra ô nhập trống hoàn toàn
      final textFormFields = find.byType(TextFormField);
      expect(textFormFields, findsNWidgets(2)); // Email & Mật khẩu ở chế độ đăng nhập mặc định

      for (final fieldFinder in textFormFields.evaluate()) {
        final formField = fieldFinder.widget as TextFormField;
        expect(formField.controller?.text, isEmpty);
      }

      // Kiểm tra có nút chọn phương thức xác thực
      expect(find.text('Dùng Email'), findsOneWidget);
      expect(find.text('Dùng Số điện thoại'), findsOneWidget);

      // Kiểm tra có nút chọn vai trò
      expect(find.text('Bệnh Nhân'), findsOneWidget);
      expect(find.text('Bác Sĩ'), findsOneWidget);
    });

    testWidgets('Chuyển đổi linh hoạt giữa Email và Số điện thoại', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: AuthScreen(apiHost: 'http://127.0.0.1:8000', onAuthSuccess: (_) {}),
      ));

      // Mặc định là Email
      expect(find.text('Địa chỉ Email'), findsOneWidget);

      // Bấm chuyển sang Dùng Số điện thoại
      await tester.tap(find.text('Dùng Số điện thoại'));
      await tester.pumpAndSettle();

      // Trường đã đổi sang Số điện thoại
      expect(find.text('Số điện thoại'), findsOneWidget);
      expect(find.text('Địa chỉ Email'), findsNothing);
    });

    testWidgets('Kiểm tra từ chối bỏ trống trường khi submit', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: AuthScreen(apiHost: 'http://127.0.0.1:8000', onAuthSuccess: (_) {}),
      ));

      // Bấm nút Đăng nhập khi các ô rỗng
      await tester.tap(find.text('Đăng Nhập Bệnh Nhân'));
      await tester.pumpAndSettle();

      // Phải báo lỗi validation
      expect(find.text('Vui lòng nhập địa chỉ email'), findsOneWidget);
      expect(find.text('Vui lòng nhập mật khẩu'), findsOneWidget);
    });
  });
}
