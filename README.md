# Đề tài Khóa luận Tốt nghiệp: Nghiên cứu và ứng dụng Kỹ thuật Explainable AI (XAI) trong Dự đoán Nguy cơ Mắc bệnh Tim mạch và Phân tích Tác động của các Chỉ số Y sinh

**Chuyên ngành:** Khoa học Dữ liệu / Trí tuệ Nhân tạo / Kỹ thuật Phần mềm  
**Kiến trúc:** 4-Phase Production Machine Learning & XAI Framework

---

## 1. Cấu trúc Thư mục Dự án (Project Structure)

```
cardio_xai_project/
│
├── data/
│   ├── raw/                  # Bộ dữ liệu gốc (cardio_train.csv)
│   └── processed/            # Dữ liệu đã làm sạch & chuẩn hóa (train.csv, test.csv, scaler.joblib)
│
├── models/                   # Artifacts mô hình đã huấn luyện (best_model.joblib, metadata.json)
│
├── reports/                  # Báo cáo đánh giá và bảng so sánh
│   ├── figures/              # Biểu đồ XAI (SHAP Summary, Dependence, Waterfall, LIME)
│   ├── metrics_comparison.csv
│   └── metrics_comparison.md
│
├── src/
│   ├── __init__.py
│   ├── config.py             # Cấu hình đường dẫn, ngưỡng lâm sàng y sinh, siêu tham số
│   ├── utils.py              # Tiện ích logging, serialization, định dạng bảng đánh giá
│   ├── preprocess.py         # Phase 1: Pipeline xử lý dữ liệu và loại bỏ nhiễu lâm sàng
│   ├── train.py              # Phase 2: Huấn luyện, so sánh XGBoost, RF, SVM & tối ưu Optuna
│   ├── explain.py            # Phase 3: Module XAI (SHAP & LIME Global/Local Explanations)
│   └── app.py                # Phase 4: Interactive Medical Dashboard (Streamlit)
│
├── requirements.txt          # Danh sách thư viện phụ thuộc
└── README.md                 # Hướng dẫn chi tiết vận hành dự án
```

---

## 2. Hướng dẫn Cài đặt Môi trường (Installation)

Khuyến nghị sử dụng môi trường ảo Python 3.10 - 3.12:

```bash
# Tạo môi trường ảo
python -m venv venv

# Kích hoạt môi trường (Windows PowerShell)
.\venv\Scripts\Activate.ps1

# Cài đặt toàn bộ thư viện cần thiết
pip install -r requirements.txt
```

---

## 3. Quy trình Triển khai (Execution Workflow)

### Phase 1: Tiền xử lý dữ liệu (Data Preprocessing)
Đặt file dữ liệu `cardio_train.csv` từ Kaggle vào thư mục `data/raw/` (hoặc hệ thống sẽ tự động phát sinh mẫu kiểm thử y sinh nếu chưa có sẵn file).

Chạy script tiền xử lý:
```bash
python src/preprocess.py
```
**Nhiệm vụ chính:**
1. Quy đổi `age` từ đơn vị ngày sang năm tuổi ($age_{years} = age / 365.25$).
2. Tính toán chỉ số khối cơ thể ($BMI = \frac{weight}{(height/100)^2}$).
3. Lọc bỏ nhiễu lâm sàng:
   - Huyết áp tâm thu `ap_hi` nằm ngoài $[90, 250]$ mmHg.
   - Huyết áp tâm trương `ap_lo` nằm ngoài $[60, 150]$ mmHg.
   - Huyết áp bất hợp lý: $ap\_hi \le ap\_lo$.
   - Loại bỏ trường `id` tránh rò rỉ dữ liệu (data leakage).
4. Phân chia Train/Test ($80/20$) phân tầng (`stratify=y`) và chuẩn hóa continuous features bằng `StandardScaler`.

### Phase 2: Huấn luyện & So sánh Mô hình (Model Training & Optimization)
Chạy script huấn luyện so sánh 3 thuật toán và tinh chỉnh bằng Optuna:
```bash
python src/train.py --optuna-trials 30
```
*(Nếu muốn chạy nhanh bỏ qua bước dò Optuna để kiểm thử: `python src/train.py --skip-optuna`)*

**Nhiệm vụ chính:**
1. Huấn luyện 3 thuật toán nền tảng: **XGBoost**, **Random Forest**, **Support Vector Machine (SVM)**.
2. Tối ưu hóa siêu tham số cho XGBoost với **Optuna** qua 5-Fold Stratified Cross-Validation nhắm đến mục tiêu tối đa hóa **ROC-AUC**.
3. Đánh giá kiểm thử độc lập trên Test Set theo 5 chỉ số cốt lõi trong chẩn đoán y tế: **ROC-AUC**, **Recall (Sensitivity)**, **Precision (PPV)**, **F1-Score**, **Accuracy**.
4. Xuất kết quả tự động ra `reports/metrics_comparison.csv` và lưu mô hình tối ưu vào `models/best_model.joblib`.
