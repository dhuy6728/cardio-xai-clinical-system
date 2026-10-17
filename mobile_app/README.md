# Hướng dẫn Kết nối Firebase & Chạy CardioXAI Mobile trong Android Studio

Dự án **CardioXAI Mobile** được phát triển trên nền tảng **Flutter & Dart**, kết nối song song với **Firebase Authentication** và **CSDL Quan hệ SQL (SQLite / PostgreSQL)** qua backend **FastAPI**.

---

## 🛠️ 1. Mở Dự Án Trong Android Studio

1. Mở phần mềm **Android Studio**.
2. Chọn **File** $\rightarrow$ **Open...** và chọn đường dẫn thư mục:
   ```text
   C:\Users\ADMIN\.gemini\antigravity\scratch\cardio_xai_project\mobile_app
   ```
3. Đảm bảo bạn đã cài đặt 2 plugin: **Flutter** và **Dart** trong phần *Settings $\rightarrow$ Plugins*.

---

## 🔥 2. Cấu hình Liên Kết Firebase (Miễn phí 0đ)

Hệ thống đã được thiết kế sẵn để liên kết trực tiếp với Firebase Authentication:

1. Truy cập vào **[Firebase Console](https://console.firebase.google.com/)** (đăng nhập bằng tài khoản Google miễn phí).
2. Bấm **Add Project** $\rightarrow$ Đặt tên dự án: `cardio-xai-app`.
3. Bật dịch vụ **Authentication**:
   - Chọn mục **Build** $\rightarrow$ **Authentication** $\rightarrow$ **Get Started**.
   - Ở tab **Sign-in method**: Kích hoạt **Email/Password**.
4. Thêm ứng dụng Android vào Firebase:
   - Nhập Package Name: `com.cardioxai.clinical`
   - Tải tệp `google-services.json` và lưu vào thư mục:
     ```text
     mobile_app/android/app/google-services.json
     ```
5. Mọi tài khoản đăng ký trên điện thoại sẽ tự động đồng bộ mã định danh `firebase_uid` về CSDL SQL tập trung của bệnh viện.

---

## 📱 3. Các Chức Năng Hoàn Chỉnh Trên Ứng Dụng

| Màn hình | Tính năng nổi bật |
| :--- | :--- |
| **Đăng Nhập / Đăng Ký** | • Đăng ký tài khoản mới với Email, Mật khẩu, Số điện thoại.<br>• Đăng nhập an toàn với mã hóa mật khẩu SHA-256.<br>• Phù hợp cho cả bệnh nhân lớn tuổi lẫn bác sĩ chuyên khoa. |
| **Khám & XAI** | • Nhập chỉ số y sinh (Tuổi, Giới tính, Chiều cao, Cân nặng, Huyết áp, Cholesterol...).<br>• Menu nạp nhanh ca mẫu (Ca nguy cơ cao, Ca khỏe mạnh).<br>• Hiển thị thanh đóng góp SHAP trực quan (Đỏ: tăng nguy cơ, Xanh: bảo vệ). |
| **Hồ sơ Bệnh (SQL)** | • Xem toàn bộ lịch sử các lần khám bệnh.<br>• Đồng bộ hai chiều giữa Web Dashboard và Điện thoại di động. |
| **Trang Cá Nhân** | • Đổi mật khẩu tài khoản bảo mật.<br>• Tra cứu mã định danh Firebase UID.<br>• Nút đăng xuất an toàn khỏi thiết bị. |

---

## 🌐 4. Địa Chỉ Kết Nối Mặc Định

- Khi chạy trên **Android Emulator**: `http://10.0.2.2:8000`
- Khi chạy trên **Điện thoại thật (Cùng mạng Wifi)**: `http://<IP_MÁY_TÍNH>:8000` (ví dụ: `http://192.168.1.5:8000`)
- Khi chạy thử trên **Trình duyệt**: `http://localhost:8501` (Giao diện Web đồng bộ dữ liệu thời gian thực).
