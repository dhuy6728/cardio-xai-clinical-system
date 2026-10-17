# CardioXAI Mobile Client (Ứng dụng Di động Chẩn đoán Nguy cơ Tim mạch & XAI)

Ứng dụng di động Flutter đa nền tảng (Android / iOS) kết nối trực tiếp với máy chủ **FastAPI** và cơ sở dữ liệu quan hệ **SQL** với chi phí **0 đồng**.

---

## 1. Cấu trúc Ứng dụng Di động

```
mobile_app/
├── lib/
│   ├── main.dart                      # Điểm khởi chạy ứng dụng & điều hướng Bottom Navigation
│   ├── models/
│   │   └── patient.dart               # Định nghĩa các Data Model tương ứng với FastAPI Schema
│   ├── services/
│   │   └── api_service.dart           # HTTP Client kết nối API RESTful (Analyze, History)
│   └── screens/
│       ├── assessment_screen.dart     # Màn hình khám bệnh: Form nhập liệu, BMI, kết quả, SHAP Waterfall
│       └── history_screen.dart        # Màn hình hồ sơ bệnh án: Danh sách lịch sử lưu trong CSDL SQL
├── pubspec.yaml                       # Quản lý thư viện phụ thuộc (http, fl_chart, intl)
└── README.md                          # Hướng dẫn cài đặt & vận hành 0đ
```

---

## 2. Hướng dẫn Chạy ứng dụng trên Điện thoại (Chi phí 0đ)

### Bước 1: Khởi động Máy chủ FastAPI Backend trên Máy tính
Đảm bảo máy tính của bạn đang chạy backend:
```powershell
py -3.14 -m uvicorn api:app --host 0.0.0.0 --port 8000
```
- Tài liệu API tương tác (Swagger UI): `http://localhost:8000/docs`

---

### Bước 2: Kết nối Điện thoại với Máy chủ (Chọn 1 trong 2 cách hoàn toàn miễn phí)

#### Cách A: Kết nối qua cùng mạng Wi-Fi nhà / trường (0đ - Khuyên dùng)
1. Mở PowerShell trên máy tính, gõ `ipconfig` để lấy địa chỉ IPv4 (ví dụ: `192.168.1.15`).
2. Mở ứng dụng trên điện thoại, nhấn vào nút bánh răng **Cài đặt (Settings)** ở góc dưới bên phải.
3. Nhập URL: `http://192.168.1.15:8000` $\to$ Nhấn **Lưu**.

#### Cách B: Dùng Cloudflare Tunnel (0đ - Dùng cho 4G hoặc bảo vệ khóa luận)
Nếu điện thoại dùng 4G hoặc khác mạng Wi-Fi với máy tính:
1. Tải công cụ miễn phí `cloudflared`:
   ```powershell
   winget install Cloudflare.cloudflared
   ```
2. Mở đường hầm HTTPS ra ngoài Internet:
   ```powershell
   cloudflared tunnel --url http://localhost:8000
   ```
3. Cloudflare sẽ cấp 1 đường link miễn phí dạng: `https://your-tunnel-name.trycloudflare.com`.
4. Nhập đường link này vào ô Cài đặt trong App điện thoại $\to$ Kết nối thành công ở bất kỳ đâu!

---

### Bước 3: Build file cài đặt `.apk` cho điện thoại Android (0đ)
Nếu máy bạn đã cài Flutter SDK:
```bash
cd mobile_app
flutter pub get
flutter build apk --release
```
File APK sẽ được tạo tại `build/app/outputs/flutter-apk/app-release.apk`. Bạn chỉ cần gửi file này qua Zalo/Drive vào điện thoại và bấm **Cài đặt** là xong!
