# 🩺 CardioXAI: Hệ thống Dự đoán Nguy cơ Tim mạch & Giải thích Y tế (Explainable AI)

[![Python 3.14](https://img.shields.io/badge/Python-3.14-blue.svg)](https://www.python.org/)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.143-009688.svg)](https://fastapi.tiangolo.com/)
[![Streamlit](https://img.shields.io/badge/Streamlit-1.66-FF4B4B.svg)](https://streamlit.io/)
[![XGBoost](https://img.shields.io/badge/XGBoost-3.4-green.svg)](https://xgboost.readthedocs.io/)
[![SHAP & LIME](https://img.shields.io/badge/XAI-SHAP%20%7C%20LIME-orange.svg)](https://shap.readthedocs.io/)
[![Flutter](https://img.shields.io/badge/Mobile-Flutter-02569B.svg)](https://flutter.dev/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

> **Đề tài Khóa luận Tốt nghiệp:** Nghiên cứu và ứng dụng kỹ thuật Explainable AI (XAI) trong dự đoán nguy cơ mắc bệnh tim mạch và phân tích tác động của các chỉ số y sinh.

---

## 🌟 Tổng quan Kiến trúc Đa nền tảng

Hệ thống được thiết kế theo tiêu chuẩn công cụ hỗ trợ ra quyết định lâm sàng (Clinical Decision Support System - CDSS) gồm 4 phân hệ chính:
1. **Pipeline Tiền xử lý Dữ liệu Y sinh:** Xử lý 70,000 bản ghi, lọc 4,802 dòng nhiễu lâm sàng huyết áp và thể trạng, chuẩn hóa không rò rỉ dữ liệu.
2. **Lõi Học máy Tối ưu hóa (Champion Model):** So sánh XGBoost, Random Forest, SVM; tinh chỉnh siêu tham số bằng **Optuna** (ROC-AUC đạt **0.8009**, Recall đạt **80.99%** trên tập Test $N=13,040$).
3. **Module Giải thích XAI Độc lập:** Bóc tách đóng góp biên bằng **TreeSHAP** (Beeswarm, Dependence, Waterfall) và **LIME** (Luật điều kiện cục bộ).
4. **Hệ thống Giao diện Kép:**
   - **Web Dashboard (Streamlit):** Dành cho bác sĩ chuyên khoa phân tích chuyên sâu tại bệnh viện.
   - **Mobile Client (Flutter):** Ứng dụng di động theo dõi chỉ số huyết áp và cảnh báo sớm nguy cơ tim mạch.
   - **Backend API (FastAPI) & CSDL SQL:** Lưu trữ lịch sử bệnh án, phản hồi suy luận $< 15\,\text{ms}$.

---

## 📁 Cấu trúc Thư mục Dự án

```text
cardio_xai_project/
├── api.py                    # Máy chủ RESTful API (FastAPI) phục vụ Mobile & Web
├── app.py                    # Giao diện Web lâm sàng (Streamlit Medical Dashboard)
├── requirements.txt          # Danh sách thư viện phụ thuộc Python
├── .gitignore                # Cấu hình bỏ qua tệp tạm và dữ liệu nhạy cảm
│
├── data/
│   ├── raw/                  # Bộ dữ liệu lâm sàng gốc (cardio_train.csv)
│   ├── processed/            # Dữ liệu sạch (train.csv, test.csv, scaler.joblib)
│   └── cardioxai.db          # Cơ sở dữ liệu quan hệ SQLite / SQL
│
├── docs/                     # Báo cáo học thuật cho Khóa luận tốt nghiệp
│   ├── Bao_Cao_Phase_1_2.docx # Bản Word chuẩn in ấn 1-inch, typography học thuật
│   └── Bao_Cao_Phase_1_2.md   # Bản Markdown đối chiếu
│
├── mobile_app/               # Ứng dụng Di động Đa nền tảng (Flutter)
│   ├── lib/
│   │   ├── main.dart
│   │   ├── models/patient.dart
│   │   ├── screens/assessment_screen.dart
│   │   ├── screens/history_screen.dart
│   │   └── services/api_service.dart
│   └── pubspec.yaml
│
├── models/                   # Trọng số mô hình và bộ giải thích đã tuần tự hóa
│   ├── best_model.joblib     # Champion Model (XGBoost Optuna Tuned)
│   ├── shap_explainer.joblib # Bộ giải thích TreeSHAP tốc độ cao
│   ├── lime_explainer.pkl    # Bộ giải thích LIME Tabular
│   └── model_metadata.json   # Siêu dữ liệu cấu hình siêu tham số
│
├── reports/
│   ├── figures/              # Toàn bộ biểu đồ SHAP & LIME phân giải cao (300 DPI)
│   ├── metrics_comparison.csv
│   └── metrics_comparison.md
│
└── src/                      # Mã nguồn module hóa
    ├── config.py             # Cấu hình ngưỡng y học và tham số
    ├── database.py           # Quản lý CSDL SQL (users, patient_records, xai_audit_logs)
    ├── explain.py            # Module tích hợp SHAP & LIME
    ├── export_docx.py        # Xuất báo cáo Word chuẩn ISO/IEC 29500
    ├── preprocess.py         # Pipeline làm sạch và lọc nhiễu sinh lý
    ├── schemas.py            # Pydantic data contracts
    ├── train.py              # Huấn luyện, so sánh mô hình & Optuna
    └── utils.py              # Logging & tiện ích
```

---

## 🚀 Hướng dẫn Cài đặt & Khởi chạy Nhanh

### 1. Cài đặt Môi trường Python
```bash
# Clone repository về máy
git clone <URL_REPO_CUA_BAN>
cd cardio_xai_project

# Cài đặt thư viện phụ thuộc
pip install -r requirements.txt
```

### 2. Chạy Pipeline Tiền xử lý & Huấn luyện (Nếu muốn chạy lại từ đầu)
```bash
# Phase 1: Tiền xử lý dữ liệu lâm sàng
python src/preprocess.py

# Phase 2: Huấn luyện so sánh mô hình và tinh chỉnh Optuna
python src/train.py --optuna-trials 15

# Phase 3: Sinh biểu đồ giải thích SHAP & LIME
python src/explain.py
```

### 3. Khởi chạy Web Dashboard (Streamlit)
```bash
streamlit run app.py
```
👉 Truy cập giao diện tại: `http://localhost:8501`

### 4. Khởi chạy Máy chủ API (FastAPI) phục vụ Mobile
```bash
uvicorn api:app --host 0.0.0.0 --port 8000
```
👉 Xem tài liệu API tương tác (Swagger UI) tại: `http://localhost:8000/docs`

---

## 📊 Tóm tắt Kết quả Thực nghiệm trên Tập Test ($N = 13,040$)

| Hạng | Thuật toán | ROC-AUC | Recall (Độ nhạy) | Precision | F1-Score | Accuracy | Thời gian suy luận |
| :---: | :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| 🥇 | **XGBoost (Optuna Tuned)** | **0.8009** | **0.8099** | **0.7517** | **0.7797** | **0.7325** | **0.015 s** |
| 🥈 | XGBoost (Baseline) | 0.7996 | 0.8052 | 0.7505 | 0.7769 | 0.7297 | 0.015 s |
| 🥉 | Random Forest | 0.7979 | 0.8129 | 0.7470 | 0.7785 | 0.7297 | 0.087 s |
| 4 | Support Vector Machine (SVM) | 0.7856 | 0.8208 | 0.7444 | 0.7807 | 0.7305 | 4.460 s |

---

## 📄 Bản quyền & Trích dẫn
Đề tài Khóa luận Tốt nghiệp Đại học được phát triển dưới sự hướng dẫn chuyên môn theo giấy phép mã nguồn mở MIT.
