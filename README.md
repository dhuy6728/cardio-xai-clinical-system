# 🩺 CardioCare AI: Hệ thống Dự đoán Nguy cơ Tim mạch & Giải thích Y tế (Explainable AI)

[![GitHub Pages](https://img.shields.io/badge/Live%20Demo-GitHub%20Pages-0284C7.svg?logo=github)](https://dhuy6728.github.io/cardio-xai-clinical-system/)
[![Firebase](https://img.shields.io/badge/Cloud%20Database-Firebase%20Firestore-FFCA28.svg?logo=firebase)](https://firebase.google.com/)
[![Flutter](https://img.shields.io/badge/Mobile%20App-Flutter%203.24-02569B.svg?logo=flutter)](https://flutter.dev/)
[![FastAPI](https://img.shields.io/badge/API-FastAPI-009688.svg?logo=fastapi)](https://fastapi.tiangolo.com/)
[![XGBoost](https://img.shields.io/badge/ML-XGBoost%20Tuned-green.svg?logo=xgboost)](https://xgboost.readthedocs.io/)
[![XAI](https://img.shields.io/badge/XAI-SHAP%20%7C%20LIME-orange.svg)](https://shap.readthedocs.io/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

> **Đề tài Khóa luận / Nghiên cứu Y khoa:**  
> *"Nghiên cứu và ứng dụng kỹ thuật Explainable AI (XAI) trong dự đoán nguy cơ mắc bệnh tim mạch và phân tích tác động của các chỉ số y sinh"*

---

## 🌐 Hệ sinh thái Đa nền tảng (Multi-Platform Ecosystem)

Dự án phát triển hoàn chỉnh giải pháp **Hỗ trợ Quyết định Lâm sàng (CDSS)** đồng bộ thời gian thực giữa Web và Di động:

1. 💻 **Web Clinical Cloud (GitHub Pages):**  
   👉 Trải nghiệm trực tuyến tại: [https://dhuy6728.github.io/cardio-xai-clinical-system/](https://dhuy6728.github.io/cardio-xai-clinical-system/)
   - **Cổng Y Bác sĩ (`doctor.html`, `doctor-history.html`):** Tiếp nhận ca bệnh, phân tích XAI SHAP bóc tách tỷ lệ rủi ro ($+/-$ % nguy cơ), đề xuất phác đồ cận lâm sàng (ECG, Doppler, Lipid máu) và quản lý kho bệnh án.
   - **Cổng Bệnh nhân (`index.html`, `assessment.html`, `history.html`):** Tự đánh giá nguy cơ bảo mật danh tính, theo dõi BMI động, tra cứu bảng chỉ số chuẩn y tế và cẩm nang phòng ngừa biến cố tim mạch.
   - **Xác thực & Quản lý phiên (`auth.html`):** Đăng nhập/Đăng ký linh hoạt bằng Email hoặc Số điện thoại cho Bác sĩ & Bệnh nhân, chống trùng lặp dữ liệu.
2. 📱 **Mobile Native Client (Flutter Android):**  
   - Giao diện Material 3 cân đối tỉ lệ, ô nhập liệu chuẩn xác không điền sẵn dữ liệu giả, tính BMI động.
   - Hoạt động ngoại tuyến (Offline-First) với thuật toán suy luận dự phòng khi không có Internet.
   - Đạt **16/16 Unit & Widget tests PASS** và đã xuất bản file APK: `mobile_app/build/app/outputs/flutter-apk/app-debug.apk`.
3. ☁️ **Đồng bộ Thời gian thực (Google Firebase Cloud):**  
   - Project: `healthcare-xai`.
   - Chia sẻ chung collection `assessment_records` và `users`, cho phép Bác sĩ/Bệnh nhân tạo ca khám ở Web hoặc Mobile thì phía còn lại lập tức cập nhật theo thời gian thực (*real-time listener*).
4. 🚀 **Backend Microservice (FastAPI & Streamlit):**  
   - RESTful API cung cấp endpoints dự đoán, giải thích XAI SHAP/LIME và xác thực tài khoản.
   - Dashboard nghiên cứu chuyên sâu hỗ trợ xuất báo cáo học thuật chuẩn Microsoft Word (.docx).

---

## 📊 Kết quả Huấn luyện & So sánh Mô hình ($N = 13,040$ Test Set)

Mô hình được huấn luyện trên 70.000 ca bệnh (lọc sạch còn 65.198 bản ghi sinh lý hợp lệ), phân chia Stratified $80/20$ và tối ưu hóa siêu tham số bằng **Optuna (Bayesian Optimization)** qua 5-Fold Cross-Validation:

| Thuật toán | ROC-AUC | Recall (Độ nhạy) | Precision | F1-Score | Accuracy | Độ trễ suy luận |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| 🥇 **XGBoost (Optuna Tuned) ★** | **0.8009** | **0.8099** | **0.7517** | **0.7797** | **0.7325** | **0.015 s** |
| 🥈 XGBoost (Baseline) | 0.7996 | 0.8052 | 0.7505 | 0.7769 | 0.7297 | 0.015 s |
| 🥉 Random Forest | 0.7979 | 0.8129 | 0.7470 | 0.7785 | 0.7297 | 0.087 s |
| 4. Support Vector Machine (SVM) | 0.7856 | 0.8208 | 0.7444 | 0.7807 | 0.7305 | 4.460 s |

> **Champion Model:** **XGBoost (Optuna Tuned)** đạt cân bằng tối ưu giữa khả năng phát hiện ca bệnh (Recall $> 80\%$) và tốc độ suy luận tức thì ($15\,\text{ms}$).

---

## 🧠 Giải thích Trực quan với Explainable AI (XAI)

Hệ thống tích hợp hai trụ cột giải thích hàng đầu:
* **SHAP (SHapley Additive exPlanations):**
  - **Toàn cục (Global):** *Beeswarm Plot* & *Feature Importance Bar* xác định **Huyết áp tâm thu (`ap_hi`)**, **Mức Cholesterol** và **Độ tuổi** là các yếu tố thúc đẩy nguy cơ tim mạch hàng đầu, trong khi **Vận động thể thao (`active`)** là yếu tố bảo vệ.
  - **Tương tác phi tuyến (Dependence):** Khảo sát ngưỡng bùng phát nguy cơ khi Huyết áp $> 140\,\text{mmHg}$ hoặc $\text{BMI} > 25\,\text{kg/m}^2$.
  - **Cục bộ từng ca bệnh (Waterfall Plot):** Bóc tách chính xác từng chỉ số làm tăng hoặc giảm xác suất nguy cơ so với ngưỡng cơ bản.
* **LIME (Local Interpretable Model-agnostic Explanations):**
  - Tạo lập các luật điều kiện dễ hiểu cho bác sĩ lâm sàng (VD: `140.00 < ap_hi <= 160.00`).

---

## 📁 Cấu trúc Thư mục Dự án

```text
cardio_xai_project/
├── index.html                    # Trang chủ & cẩm nang sức khỏe tim mạch
├── assessment.html               # Cổng tự đánh giá nguy cơ (Bệnh nhân)
├── doctor.html                   # Cổng khám lâm sàng & giải thích XAI (Bác sĩ)
├── history.html                  # Kho lưu trữ sức khỏe bệnh nhân
├── doctor-history.html           # Kho lưu trữ hồ sơ bệnh án bác sĩ
├── metrics.html                  # Bảng chỉ số sức khỏe chuẩn y tế
├── emergency.html                # Hướng dẫn cấp cứu 115
├── auth.html                     # Giao diện Đăng nhập & Đăng ký Web
├── api.py                        # Máy chủ RESTful API (FastAPI)
├── app.py                        # Dashboard nghiên cứu lâm sàng (Streamlit)
│
├── js/                           # Module hóa mã nguồn JavaScript
│   ├── auth.js                   # Quản lý phiên, xác thực & đồng bộ Firestore
│   ├── navbar.js                 # Điều hướng Header, hiển thị trạng thái đăng nhập
│   ├── assessment.js             # Logic chẩn đoán bệnh nhân & tính BMI động
│   ├── doctor.js                 # Logic khám lâm sàng & bóc tách SHAP
│   ├── history.js                # Quản lý kho lưu trữ & realtime sync
│   ├── storage.js                # Adapter đồng bộ Firestore & LocalStorage
│   ├── cardio-ai.js              # Thuật toán suy luận AI client-side
│   ├── firebase-config.js        # Cấu hình Firebase project "healthcare-xai"
│   ├── articles.js               # Dữ liệu cẩm nang tim mạch
│   └── toast.js                  # Thông báo Toast notification
│
├── docs/                         # Thư mục xuất bản trực tiếp lên GitHub Pages
│   ├── *.html, js/, css/
│   └── Bao_Cao_Phase_1_2.docx    # Báo cáo học thuật cho hội đồng chấm khóa luận
│
├── mobile_app/                   # Ứng dụng di động Flutter Android/iOS
│   ├── lib/
│   │   ├── main.dart             # Điểm khởi chạy & định tuyến giao diện
│   │   ├── models/patient.dart   # Schema dữ liệu bệnh nhân & XAI
│   │   ├── screens/              # Màn hình (auth, home, assessment, history, profile)
│   │   └── services/
│   │       ├── api_service.dart  # Kết nối API & fallback ngoại tuyến
│   │       └── firebase_service.dart # Đồng bộ Firestore 2 chiều
│   ├── test/                     # Bộ kiểm thử tự động 16/16 tests PASS
│   └── pubspec.yaml
│
├── models/                       # Trọng số mô hình và bộ giải thích đã lưu
│   ├── best_model.joblib         # XGBoost Champion Model
│   ├── shap_explainer.joblib     # TreeSHAP Explainer
│   ├── lime_explainer.pkl        # LIME Explainer
│   └── model_metadata.json       # Siêu dữ liệu mô hình
│
├── reports/
│   ├── figures/                  # Biểu đồ SHAP, LIME (300 DPI) & chụp màn hình
│   └── metrics_comparison.md     # Bảng so sánh chi tiết các mô hình
│
└── src/                          # Lõi xử lý dữ liệu và huấn luyện Python
    ├── preprocess.py             # Pipeline làm sạch 70.000 ca bệnh
    ├── train.py                  # Huấn luyện mô hình & Optuna Bayesian Search
    ├── explain.py                # Xây dựng SHAP & LIME
    ├── database.py               # Kết nối CSDL SQLite nội bộ
    └── export_docx.py            # Xuất tài liệu học thuật Word ISO/IEC 29500
```

---

## 🚀 Hướng dẫn Cài đặt & Khởi chạy

### 1. Trải nghiệm trực tuyến ngay (Không cần cài đặt)
Truy cập bản Web hoàn chỉnh tại:  
👉 **[https://dhuy6728.github.io/cardio-xai-clinical-system/](https://dhuy6728.github.io/cardio-xai-clinical-system/)**

### 2. Chạy Ứng dụng Di động (Flutter)
```bash
cd mobile_app

# Cài đặt packages
flutter pub get

# Kiểm tra chất lượng mã nguồn & chạy kiểm thử
flutter analyze
flutter test

# Khởi chạy trên máy ảo hoặc thiết bị thật
flutter run
```

### 3. Chạy Backend API (FastAPI) & Streamlit
```bash
# Cài đặt thư viện Python
pip install -r requirements.txt

# Chạy máy chủ API
uvicorn api:app --host 0.0.0.0 --port 8000
# 👉 Swagger UI tại: http://localhost:8000/docs

# Chạy Streamlit Dashboard
streamlit run app.py
# 👉 Truy cập tại: http://localhost:8501
```

---

## 📄 Bản quyền & Trích dẫn
Đề tài nghiên cứu ứng dụng AI trong Y tế được phát triển phục vụ mục đích học thuật, nghiên cứu khoa học và cộng đồng theo giấy phép mã nguồn mở **MIT License**.
