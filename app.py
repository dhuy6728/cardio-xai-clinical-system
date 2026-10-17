"""
Phase 4: Interactive Medical Dashboard (Streamlit).
Clinical Decision Support System with Explainable AI (SHAP & LIME).
"""

import sys
from pathlib import Path
from typing import Dict, Tuple

import cloudpickle
import joblib
import lime
import lime.lime_tabular
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import shap
import streamlit as st

# Ensure project root is in sys.path
BASE_DIR = Path(__file__).resolve().parent
if str(BASE_DIR) not in sys.path:
    sys.path.insert(0, str(BASE_DIR))

from src.config import (
    BEST_MODEL_FILE,
    FIGURES_DIR,
    METRICS_CSV_FILE,
    MODELS_DIR,
    NUMERICAL_FEATURES,
    SCALER_FILE,
    TRAIN_DATA_FILE,
)
from src.explain import CLINICAL_FEATURE_LABELS

# Page Configuration
st.set_page_config(
    page_title="CardioXAI - Hệ thống Chẩn đoán & Giải thích Nguy cơ Tim mạch",
    page_icon="🩺",
    layout="wide",
    initial_sidebar_state="expanded",
)

# Custom Styling (Medical Clean Theme)
st.markdown(
    """
    <style>
    .main-title {
        font-size: 2.2rem;
        color: #1F4E79;
        font-weight: 700;
        margin-bottom: 0.2rem;
    }
    .sub-title {
        font-size: 1.05rem;
        color: #555555;
        margin-bottom: 1.5rem;
    }
    .risk-card-high {
        background-color: #FDF2F2;
        border-left: 6px solid #E02424;
        padding: 18px;
        border-radius: 8px;
        margin-bottom: 20px;
    }
    .risk-card-moderate {
        background-color: #FEFCE8;
        border-left: 6px solid #CA8A04;
        padding: 18px;
        border-radius: 8px;
        margin-bottom: 20px;
    }
    .risk-card-low {
        background-color: #F0FDF4;
        border-left: 6px solid #16A34A;
        padding: 18px;
        border-radius: 8px;
        margin-bottom: 20px;
    }
    </style>
    """,
    unsafe_allow_html=True,
)


@st.cache_resource(show_spinner="Đang tải mô hình Champion XGBoost và bộ giải thích XAI...")
def load_resources():
    """Loads and caches models, scaler, explainers, and background dataset for real-time responsiveness."""
    model = joblib.load(BEST_MODEL_FILE)
    scaler = joblib.load(SCALER_FILE)

    # Load pre-trained SHAP TreeExplainer
    shap_explainer_path = MODELS_DIR / "shap_explainer.joblib"
    if shap_explainer_path.exists():
        shap_explainer = joblib.load(shap_explainer_path)
    else:
        shap_explainer = shap.TreeExplainer(model)

    # Load LIME explainer
    lime_explainer_path = MODELS_DIR / "lime_explainer.pkl"
    if lime_explainer_path.exists():
        with open(lime_explainer_path, "rb") as f:
            lime_explainer = cloudpickle.load(f)
    else:
        train_df = pd.read_csv(TRAIN_DATA_FILE)
        X_train = train_df.drop(columns=["cardio"])
        lime_explainer = lime.lime_tabular.LimeTabularExplainer(
            training_data=X_train.values,
            feature_names=list(X_train.columns),
            class_names=["Healthy (Low Risk)", "Cardiovascular Risk"],
            mode="classification",
            random_state=42,
        )

    return model, scaler, shap_explainer, lime_explainer


model, scaler, shap_explainer, lime_explainer = load_resources()

# ==========================================
# SIDEBAR: PATIENT BIOMEDICAL INPUTS
# ==========================================
st.sidebar.image(
    "https://img.icons8.com/fluency/96/cardiology.png",
    width=70,
)
st.sidebar.title("Thông tin Bệnh nhân")
st.sidebar.markdown("*Nhập các chỉ số y sinh phục vụ chẩn đoán:*")

# Preset clinical personas
preset = st.sidebar.selectbox(
    "Mẫu bệnh nhân tham chiếu nhanh:",
    ["Tùy chỉnh (Nhập tay)", "Ca 1: Bệnh nhân Nguy cơ Cao (51t, HA 145/95, BMI 32)", "Ca 2: Bệnh nhân Khỏe mạnh (32t, HA 118/76, BMI 22.5)"],
)

if preset == "Ca 1: Bệnh nhân Nguy cơ Cao (51t, HA 145/95, BMI 32)":
    init_age, init_gender = 51, "Nam"
    init_h, init_w = 168, 90.0
    init_ap_hi, init_ap_lo = 145, 95
    init_chol, init_gluc = 3, 2
    init_smoke, init_alco, init_active = 1, 0, 0
elif preset == "Ca 2: Bệnh nhân Khỏe mạnh (32t, HA 118/76, BMI 22.5)":
    init_age, init_gender = 32, "Nữ"
    init_h, init_w = 165, 61.0
    init_ap_hi, init_ap_lo = 118, 76
    init_chol, init_gluc = 1, 1
    init_smoke, init_alco, init_active = 0, 0, 1
else:
    init_age, init_gender = 50, "Nam"
    init_h, init_w = 165, 72.0
    init_ap_hi, init_ap_lo = 130, 85
    init_chol, init_gluc = 2, 1
    init_smoke, init_alco, init_active = 0, 0, 1

age = st.sidebar.slider("Tuổi (năm)", min_value=30, max_value=65, value=init_age, step=1)
gender_str = st.sidebar.radio("Giới tính", ["Nữ", "Nam"], index=1 if init_gender == "Nam" else 0, horizontal=True)
gender = 2 if gender_str == "Nam" else 1

col_h, col_w = st.sidebar.columns(2)
with col_h:
    height = st.number_input("Chiều cao (cm)", min_value=120, max_value=220, value=int(init_h), step=1)
with col_w:
    weight = st.number_input("Cân nặng (kg)", min_value=35.0, max_value=180.0, value=float(init_w), step=0.5)

# Calculate and display BMI dynamically
bmi = round(weight / ((height / 100.0) ** 2), 2)
if bmi < 18.5:
    bmi_category = "Thiếu cân"
    bmi_color = "gray"
elif bmi < 25.0:
    bmi_category = "Bình thường"
    bmi_color = "green"
elif bmi < 30.0:
    bmi_category = "Tiền béo phì"
    bmi_color = "orange"
else:
    bmi_category = "Béo phì"
    bmi_color = "red"

st.sidebar.markdown(f"**BMI tính toán:** `{bmi} kg/m²` (:{bmi_color}[{bmi_category}])")

st.sidebar.markdown("---")
st.sidebar.subheader("Huyết áp & Sinh hóa")

col_hi, col_lo = st.sidebar.columns(2)
with col_hi:
    ap_hi = st.number_input("Huyết áp tâm thu (ap_hi)", min_value=90, max_value=240, value=int(init_ap_hi), step=5)
with col_lo:
    ap_lo = st.number_input("Huyết áp tâm trương (ap_lo)", min_value=60, max_value=140, value=int(init_ap_lo), step=5)

if ap_hi <= ap_lo:
    st.sidebar.error("Cảnh báo y khoa: Huyết áp tâm thu phải lớn hơn huyết áp tâm trương!")

cholesterol_dict = {"Mức 1: Bình thường (< 5.2 mmol/L)": 1, "Mức 2: Hơi cao (5.2 - 6.2 mmol/L)": 2, "Mức 3: Rất cao (> 6.2 mmol/L)": 3}
chol_str = st.sidebar.selectbox("Cholesterol toàn phần", list(cholesterol_dict.keys()), index=init_chol - 1)
cholesterol = cholesterol_dict[chol_str]

gluc_dict = {"Mức 1: Bình thường (< 5.6 mmol/L)": 1, "Mức 2: Rối loạn dung nạp (5.6 - 6.9)": 2, "Mức 3: Rất cao (≥ 7.0 mmol/L)": 3}
gluc_str = st.sidebar.selectbox("Đường huyết lúc đói (Glucose)", list(gluc_dict.keys()), index=init_gluc - 1)
gluc = gluc_dict[gluc_str]

st.sidebar.markdown("---")
st.sidebar.subheader("Thói quen sinh hoạt")
smoke = 1 if st.sidebar.checkbox("Hút thuốc lá", value=bool(init_smoke)) else 0
alco = 1 if st.sidebar.checkbox("Uống rượu bia thường xuyên", value=bool(init_alco)) else 0
active = 1 if st.sidebar.checkbox("Vận động thể lực đều đặn", value=bool(init_active)) else 0

analyze_btn = st.sidebar.button("🔬 Phân tích Nguy cơ & Giải thích XAI", type="primary", use_container_width=True)

# Prepare Patient Data Vector
patient_raw = {
    "age": float(age),
    "height": float(height),
    "weight": float(weight),
    "ap_hi": float(ap_hi),
    "ap_lo": float(ap_lo),
    "bmi": float(bmi),
    "gender": int(gender),
    "cholesterol": int(cholesterol),
    "gluc": int(gluc),
    "smoke": int(smoke),
    "alco": int(alco),
    "active": int(active),
}

patient_df_unscaled = pd.DataFrame([patient_raw])
patient_df_scaled = patient_df_unscaled.copy()
patient_df_scaled[NUMERICAL_FEATURES] = scaler.transform(patient_df_unscaled[NUMERICAL_FEATURES])

# Model Inference
pred_proba = model.predict_proba(patient_df_scaled)[0, 1]
pred_class = int(pred_proba >= 0.5)

# ==========================================
# MAIN DASHBOARD AREA
# ==========================================
st.markdown('<div class="main-title">🩺 CardioXAI: Hệ thống Dự đoán Nguy cơ Tim mạch & Giải thích Y tế</div>', unsafe_allow_html=True)
st.markdown(
    '<div class="sub-title">Ứng dụng kỹ thuật Explainable AI (SHAP & LIME) hỗ trợ bác sĩ lâm sàng phân tích định lượng tác động của các chỉ số y sinh học.</div>',
    unsafe_allow_html=True,
)

# Clinical Result Cards
col_res1, col_res2, col_res3, col_res4 = st.columns([1.2, 1, 1, 1.5])

with col_res1:
    st.metric(
        label="Xác suất Mắc bệnh Tim mạch",
        value=f"{pred_proba:.1%}",
        delta=f"{(pred_proba - 0.5):.1%} so với ngưỡng 50%",
        delta_color="inverse",
    )

with col_res2:
    if pred_proba >= 0.65:
        risk_level = "NGUY CƠ CAO"
        badge_color = "#E02424"
    elif pred_proba >= 0.35:
        risk_level = "NGUY CƠ TRUNG BÌNH"
        badge_color = "#CA8A04"
    else:
        risk_level = "NGUY CƠ THẤP"
        badge_color = "#16A34A"
    st.metric(label="Phân tầng Rủi ro Lâm sàng", value=risk_level)

with col_res3:
    st.metric(label="Chỉ số Thể trạng (BMI)", value=f"{bmi} kg/m²", delta=bmi_category, delta_color="off")

with col_res4:
    if pred_proba >= 0.65:
        st.markdown(
            f'<div class="risk-card-high"><strong>Khuyến nghị lâm sàng:</strong> Bệnh nhân thuộc nhóm nguy cơ cao ({pred_proba:.1%}). Cần chỉ định điện tâm đồ (ECG), siêu âm tim và lập phác đồ kiểm soát huyết áp/cholesterol tích cực.</div>',
            unsafe_allow_html=True,
        )
    elif pred_proba >= 0.35:
        st.markdown(
            f'<div class="risk-card-moderate"><strong>Khuyến nghị lâm sàng:</strong> Bệnh nhân có nguy cơ tim mạch tiềm ẩn ({pred_proba:.1%}). Khuyến nghị theo dõi huyết áp định kỳ và can thiệp thay đổi lối sống (giảm cân, dinh dưỡng).</div>',
            unsafe_allow_html=True,
        )
    else:
        st.markdown(
            f'<div class="risk-card-low"><strong>Khuyến nghị lâm sàng:</strong> Chỉ số tim mạch hiện tại trong dải an toàn ({pred_proba:.1%}). Khuyến khích duy trì lối sống lành mạnh và vận động thể lực thường xuyên.</div>',
            unsafe_allow_html=True,
        )

st.markdown("---")

# ==========================================
# INTERACTIVE TABS
# ==========================================
tab_shap, tab_lime, tab_global, tab_model = st.tabs([
    "🔍 1. Giải thích Cá thể hóa (SHAP Waterfall)",
    "📊 2. Bóc tách Luật Quyết định (LIME)",
    "🌐 3. Tương tác Toàn cục (Global Population XAI)",
    "📈 4. Báo cáo Kiểm định Mô hình (Model Governance)",
])

# ------------------------------------------
# TAB 1: SHAP WATERFALL PLOT
# ------------------------------------------
with tab_shap:
    st.subheader("Giải thích Đóng góp Biên của từng Chỉ số qua Biểu đồ SHAP Waterfall")
    st.markdown(
        """
        Biểu đồ **SHAP Waterfall** minh họa chi tiết quá trình dịch chuyển từ **mức nguy cơ kỳ vọng nền $E[f(X)]$** 
        đến **giá trị dự báo thực tế $f(x)$** của riêng bệnh nhân này:
        - 🟥 **Thanh màu Đỏ (hướng sang phải, giá trị dương):** Chỉ số y sinh đang **làm tăng nguy cơ tim mạch**.
        - 🟦 **Thanh màu Xanh (hướng sang trái, giá trị âm):** Chỉ số y sinh đang **đóng vai trò bảo vệ, kéo giảm nguy cơ**.
        """
    )

    with st.spinner("Đang tính toán giá trị Shapley cho bệnh nhân..."):
        shap_vals = shap_explainer(patient_df_scaled)
        explanation = shap.Explanation(
            values=shap_vals.values[0],
            base_values=shap_vals.base_values[0],
            data=patient_df_unscaled.values[0],
            feature_names=[CLINICAL_FEATURE_LABELS.get(col, col) for col in patient_df_scaled.columns],
        )

        fig_shap, ax_shap = plt.subplots(figsize=(9, 5), dpi=250)
        shap.plots.waterfall(explanation, max_display=10, show=False)
        plt.title(f"SHAP Waterfall: Phân tích Ca bệnh (Xác suất nguy cơ = {pred_proba:.1%})", fontsize=11, fontweight="bold", pad=12)
        plt.tight_layout()
        st.pyplot(fig_shap, clear_figure=True)
        plt.close(fig_shap)

    # Tabular Breakdown of SHAP Values
    shap_df = pd.DataFrame({
        "Chỉ số Y sinh": [CLINICAL_FEATURE_LABELS.get(col, col) for col in patient_df_scaled.columns],
        "Giá trị thực tế": patient_df_unscaled.values[0],
        "Giá trị SHAP đóng góp": shap_vals.values[0],
        "Tác động Lâm sàng": [
            "🟥 Làm tăng nguy cơ" if v > 0.05 else ("🟦 Giúp bảo vệ" if v < -0.05 else "⬜ Trung tính")
            for v in shap_vals.values[0]
        ],
    }).sort_values(by="Giá trị SHAP đóng góp", ascending=False)

    st.markdown("##### Bảng Bóc tách Định lượng Đóng góp Biên (Shapley Values):")
    st.dataframe(
        shap_df.style.format({"Giá trị SHAP đóng góp": "{:+.4f}"}),
        use_container_width=True,
        hide_index=True,
    )

# ------------------------------------------
# TAB 2: LIME LOCAL EXPLAINER
# ------------------------------------------
with tab_lime:
    st.subheader("Bóc tách Luật Nguy cơ Bằng Mô hình Cục bộ LIME")
    st.markdown(
        """
        **LIME (Local Interpretable Model-agnostic Explanations)** xây dựng một mô hình xấp xỉ tuyến tính cục bộ 
        xung quanh điểm dữ liệu của bệnh nhân để rút ra các **khoảng giá trị điều kiện (decision rules)** trực quan.
        """
    )

    with st.spinner("Đang sinh giải thích cục bộ LIME..."):
        exp = lime_explainer.explain_instance(
            patient_df_scaled.iloc[0].values,
            model.predict_proba,
            num_features=8,
            labels=[1],
        )

        col_l1, col_l2 = st.columns([1.2, 1])

        with col_l1:
            fig_lime = exp.as_pyplot_figure(label=1)
            fig_lime.set_size_inches(7.5, 4.5)
            plt.title("Trọng số LIME đóng góp vào Xác suất Bệnh Tim mạch", fontsize=11, fontweight="bold")
            plt.xlabel("Trọng số LIME", fontsize=10)
            plt.tight_layout()
            st.pyplot(fig_lime, clear_figure=True)
            plt.close(fig_lime)

        with col_l2:
            st.markdown("##### Các điều kiện lâm sàng được kích hoạt:")
            lime_rules = exp.as_list(label=1)
            for rule, weight in lime_rules:
                if weight > 0:
                    st.error(f"**{rule}**: Tăng nguy cơ (+{weight:.3f})")
                else:
                    st.success(f"**{rule}**: Giảm nguy cơ ({weight:.3f})")

# ------------------------------------------
# TAB 3: GLOBAL POPULATION XAI
# ------------------------------------------
with tab_global:
    st.subheader("Phân tích Toàn cục trên Quần thể Bệnh nhân Nghiên cứu (N = 65,198)")
    st.markdown("Đối chiếu các chỉ số của bệnh nhân hiện tại với quy luật phân bố rủi ro trên quy mô toàn quần thể:")

    g_col1, g_col2 = st.columns(2)
    with g_col1:
        st.markdown("##### 1. SHAP Summary Beeswarm Plot")
        st.image(str(FIGURES_DIR / "shap_summary_beeswarm.png"), caption="Phân bố tác động toàn cục của các đặc trưng (N=2,000 mẫu)")

        st.markdown("##### 3. SHAP Dependence: Huyết áp Tâm thu (ap_hi)")
        st.image(str(FIGURES_DIR / "shap_dependence_ap_hi.png"), caption="Quan hệ phi tuyến giữa Huyết áp tâm thu và Nguy cơ, tương tác với Tuổi")

    with g_col2:
        st.markdown("##### 2. SHAP Global Feature Importance")
        st.image(str(FIGURES_DIR / "shap_feature_importance_bar.png"), caption="Xếp hạng độ quan trọng trung bình của các chỉ số y sinh")

        st.markdown("##### 4. SHAP Dependence: Chỉ số BMI")
        st.image(str(FIGURES_DIR / "shap_dependence_bmi.png"), caption="Điểm uốn nguy cơ tại ngưỡng BMI 25.0 kg/m² và 30.0 kg/m²")

# ------------------------------------------
# TAB 4: MODEL GOVERNANCE & METRICS
# ------------------------------------------
with tab_model:
    st.subheader("Báo cáo Kiểm định Năng lực Mô hình (Model Governance & Evaluation)")
    st.markdown(
        """
        Mô hình triển khai là **XGBoost Classifier** đã được tinh chỉnh siêu tham số tối ưu bằng thuật toán **Optuna (Bayesian TPE)** 
        qua 5-Fold Stratified Cross-Validation và đánh giá trên tập kiểm định độc lập ($N = 13,040$ mẫu):
        """
    )

    if METRICS_CSV_FILE.exists():
        df_metrics = pd.read_csv(METRICS_CSV_FILE)
        st.dataframe(df_metrics.style.highlight_max(subset=["ROC-AUC", "Recall", "F1-Score", "Accuracy"], color="#D1E7DD"), use_container_width=True, hide_index=True)
    else:
        st.info("Chưa tìm thấy tệp metrics_comparison.csv.")

    st.markdown(
        """
        - **ROC-AUC (0.8009):** Năng lực phân loại rủi ro trên mọi ngưỡng xác suất đạt mức xuất sắc.
        - **Recall / Độ nhạy (80.99%):** Giảm thiểu tối đa việc bỏ sót bệnh nhân có bệnh lý tim mạch thực tế.
        - **Tốc độ suy luận (0.015 giây):** Đảm bảo phản hồi thời gian thực tức thì khi bác sĩ thao tác trên Dashboard.
        """
    )
