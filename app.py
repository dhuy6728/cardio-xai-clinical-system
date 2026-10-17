"""
Phase 4: Interactive Medical Dashboard (Streamlit) - Enterprise Clinical Redesign.
Clinical Decision Support System with Explainable AI (SHAP & LIME) & Patient Records.
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
from src.database import save_assessment, get_all_records

# Page Configuration
st.set_page_config(
    page_title="CardioXAI Pro - Clinical Decision Support",
    page_icon="🫀",
    layout="wide",
    initial_sidebar_state="expanded",
)

# Custom Ultra-Modern Medical Glassmorphism & Responsive CSS
st.markdown(
    """
    <style>
    @import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');

    html, body, [class*="css"] {
        font-family: 'Plus Jakarta Sans', -apple-system, BlinkMacSystemFont, sans-serif;
    }

    /* Main Container Padding */
    .block-container {
        padding-top: 1.8rem;
        padding-bottom: 3rem;
        max-width: 1400px;
    }

    /* Hero Banner Header */
    .hero-header {
        background: linear-gradient(135deg, #0F2027 0%, #203A43 50%, #2C5364 100%);
        border-radius: 20px;
        padding: 28px 36px;
        color: white;
        margin-bottom: 24px;
        box-shadow: 0 10px 30px rgba(15, 32, 39, 0.25);
        display: flex;
        align-items: center;
        justify-content: space-between;
        border: 1px solid rgba(255, 255, 255, 0.1);
    }
    .hero-title {
        font-size: 2.1rem;
        font-weight: 800;
        letter-spacing: -0.5px;
        margin: 0;
        background: linear-gradient(90deg, #FFFFFF, #90E0EF);
        -webkit-background-clip: text;
        -webkit-text-fill-color: transparent;
    }
    .hero-badge {
        display: inline-block;
        background: rgba(0, 180, 216, 0.2);
        color: #90E0EF;
        padding: 4px 12px;
        border-radius: 20px;
        font-size: 0.8rem;
        font-weight: 700;
        letter-spacing: 0.5px;
        text-transform: uppercase;
        margin-bottom: 8px;
        border: 1px solid rgba(144, 224, 239, 0.3);
    }
    .hero-desc {
        color: #E0E1DD;
        font-size: 0.95rem;
        margin-top: 6px;
        line-height: 1.5;
        max-width: 850px;
    }

    /* Metric Cards Grid */
    .metric-card {
        background: #FFFFFF;
        border-radius: 16px;
        padding: 20px;
        box-shadow: 0 4px 20px rgba(0, 0, 0, 0.05);
        border: 1px solid #E2E8F0;
        transition: transform 0.2s ease, box-shadow 0.2s ease;
        height: 100%;
        display: flex;
        flex-direction: column;
        justify-content: space-between;
    }
    .metric-card:hover {
        transform: translateY(-2px);
        box-shadow: 0 8px 25px rgba(0, 0, 0, 0.09);
    }
    .metric-title {
        font-size: 0.82rem;
        font-weight: 700;
        color: #64748B;
        text-transform: uppercase;
        letter-spacing: 0.6px;
        margin-bottom: 6px;
    }
    .metric-val {
        font-size: 2.1rem;
        font-weight: 800;
        color: #0F172A;
        line-height: 1.1;
    }
    .metric-subtitle {
        font-size: 0.85rem;
        margin-top: 6px;
        font-weight: 600;
    }

    /* Dynamic Risk Pill Badges */
    .risk-pill-high {
        display: inline-flex;
        align-items: center;
        gap: 6px;
        background: #FEE2E2;
        color: #991B1B;
        padding: 4px 12px;
        border-radius: 30px;
        font-weight: 700;
        font-size: 0.85rem;
    }
    .risk-pill-mod {
        display: inline-flex;
        align-items: center;
        gap: 6px;
        background: #FEF3C7;
        color: #92400E;
        padding: 4px 12px;
        border-radius: 30px;
        font-weight: 700;
        font-size: 0.85rem;
    }
    .risk-pill-low {
        display: inline-flex;
        align-items: center;
        gap: 6px;
        background: #DCFCE7;
        color: #166534;
        padding: 4px 12px;
        border-radius: 30px;
        font-weight: 700;
        font-size: 0.85rem;
    }

    /* Actionable Clinical Directive Box */
    .directive-card-high {
        background: linear-gradient(135deg, #FFF5F5 0%, #FED7D7 100%);
        border-left: 6px solid #E53E3E;
        border-radius: 14px;
        padding: 18px 22px;
        color: #742A2A;
        box-shadow: 0 4px 15px rgba(229, 62, 62, 0.1);
        margin-bottom: 20px;
    }
    .directive-card-mod {
        background: linear-gradient(135deg, #FFFDF0 0%, #FEFCBF 100%);
        border-left: 6px solid #D69E2E;
        border-radius: 14px;
        padding: 18px 22px;
        color: #744210;
        box-shadow: 0 4px 15px rgba(214, 158, 46, 0.1);
        margin-bottom: 20px;
    }
    .directive-card-low {
        background: linear-gradient(135deg, #F0FFF4 0%, #C6F6D5 100%);
        border-left: 6px solid #38A169;
        border-radius: 14px;
        padding: 18px 22px;
        color: #22543D;
        box-shadow: 0 4px 15px rgba(56, 161, 105, 0.1);
        margin-bottom: 20px;
    }

    /* Custom Streamlit Tabs */
    .stTabs [data-baseweb="tab-list"] {
        gap: 12px;
        background-color: transparent;
        border-bottom: 2px solid #E2E8F0;
        padding-bottom: 6px;
    }
    .stTabs [data-baseweb="tab"] {
        border-radius: 10px;
        padding: 10px 18px;
        font-weight: 600;
        font-size: 0.95rem;
        color: #475569;
        background: #F8FAFC;
        border: 1px solid #E2E8F0;
        transition: all 0.2s ease;
    }
    .stTabs [aria-selected="true"] {
        background: linear-gradient(135deg, #1F4E79 0%, #0D6EFD 100%) !important;
        color: white !important;
        border-color: #0D6EFD !important;
        box-shadow: 0 4px 12px rgba(13, 110, 253, 0.25);
    }

    /* Sidebar Styling */
    section[data-testid="stSidebar"] {
        background: #F8FAFC;
        border-right: 1px solid #E2E8F0;
    }
    .sidebar-section-title {
        font-size: 0.85rem;
        font-weight: 800;
        color: #0F172A;
        text-transform: uppercase;
        letter-spacing: 0.7px;
        margin-top: 18px;
        margin-bottom: 8px;
        display: flex;
        align-items: center;
        gap: 6px;
    }
    </style>
    """,
    unsafe_allow_html=True,
)


@st.cache_resource(show_spinner="Đang tối ưu mô hình XGBoost và các bộ giải thích XAI...")
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
st.sidebar.markdown(
    """
    <div style="display: flex; align-items: center; gap: 12px; margin-bottom: 16px;">
        <div style="background: linear-gradient(135deg, #1F4E79, #00B4D8); width: 44px; height: 44px; border-radius: 12px; display: flex; align-items: center; justify-content: center; color: white; font-size: 24px; box-shadow: 0 4px 10px rgba(0, 180, 216, 0.3);">
            🫀
        </div>
        <div>
            <div style="font-weight: 800; font-size: 1.15rem; color: #0F172A; line-height: 1.2;">CardioXAI Pro</div>
            <div style="font-size: 0.75rem; color: #64748B; font-weight: 600;">Hỗ trợ Quyết định Y khoa</div>
        </div>
    </div>
    """,
    unsafe_allow_html=True,
)

# Patient Name
patient_name = st.sidebar.text_input("Họ và Tên Bệnh nhân:", value="Nguyễn Văn A")

# Preset clinical personas
preset = st.sidebar.selectbox(
    "Mẫu ca lâm sàng chuẩn hóa:",
    [
        "Tùy chỉnh (Nhập tự do)",
        "Ca 1: Bệnh nhân Nguy cơ Cao (51t, HA 145/95, BMI 32, Chol 3)",
        "Ca 2: Bệnh nhân Khỏe mạnh (32t, HA 118/76, BMI 22.5, Chol 1)",
        "Ca 3: Tiền béo phì trung niên (45t, HA 135/88, BMI 27)",
    ],
)

if preset == "Ca 1: Bệnh nhân Nguy cơ Cao (51t, HA 145/95, BMI 32, Chol 3)":
    init_age, init_gender = 51, "Nam"
    init_h, init_w = 168, 90.0
    init_ap_hi, init_ap_lo = 145, 95
    init_chol, init_gluc = 3, 2
    init_smoke, init_alco, init_active = 1, 0, 0
elif preset == "Ca 2: Bệnh nhân Khỏe mạnh (32t, HA 118/76, BMI 22.5, Chol 1)":
    init_age, init_gender = 32, "Nữ"
    init_h, init_w = 165, 61.0
    init_ap_hi, init_ap_lo = 118, 76
    init_chol, init_gluc = 1, 1
    init_smoke, init_alco, init_active = 0, 0, 1
elif preset == "Ca 3: Tiền béo phì trung niên (45t, HA 135/88, BMI 27)":
    init_age, init_gender = 45, "Nam"
    init_h, init_w = 170, 78.0
    init_ap_hi, init_ap_lo = 135, 88
    init_chol, init_gluc = 2, 1
    init_smoke, init_alco, init_active = 0, 1, 1
else:
    init_age, init_gender = 50, "Nam"
    init_h, init_w = 165, 72.0
    init_ap_hi, init_ap_lo = 130, 85
    init_chol, init_gluc = 2, 1
    init_smoke, init_alco, init_active = 0, 0, 1

st.sidebar.markdown('<div class="sidebar-section-title">👤 Thông số Nhân trắc học</div>', unsafe_allow_html=True)
age = st.sidebar.slider("Tuổi (năm)", min_value=30, max_value=65, value=init_age, step=1)
gender_str = st.sidebar.radio("Giới tính", ["Nữ", "Nam"], index=1 if init_gender == "Nam" else 0, horizontal=True)
gender = 2 if gender_str == "Nam" else 1

col_h, col_w = st.sidebar.columns(2)
with col_h:
    height = st.number_input("Chiều cao (cm)", min_value=120, max_value=220, value=int(init_h), step=1)
with col_w:
    weight = st.number_input("Cân nặng (kg)", min_value=35.0, max_value=180.0, value=float(init_w), step=0.5)

# Calculate and display BMI dynamically with professional badges
bmi = round(weight / ((height / 100.0) ** 2), 2)
if bmi < 18.5:
    bmi_category = "Thiếu cân"
    bmi_badge = "background: #E2E8F0; color: #475569;"
elif bmi < 25.0:
    bmi_category = "Bình thường"
    bmi_badge = "background: #DCFCE7; color: #166534;"
elif bmi < 30.0:
    bmi_category = "Tiền béo phì"
    bmi_badge = "background: #FEF3C7; color: #92400E;"
else:
    bmi_category = "Béo phì"
    bmi_badge = "background: #FEE2E2; color: #991B1B;"

st.sidebar.markdown(
    f"""
    <div style="background: white; border: 1px solid #E2E8F0; border-radius: 10px; padding: 10px 14px; margin-top: 6px; display: flex; justify-content: space-between; align-items: center;">
        <span style="font-size: 0.85rem; font-weight: 600; color: #475569;">Chỉ số BMI:</span>
        <span style="font-size: 0.95rem; font-weight: 800; color: #0F172A;">{bmi} kg/m²</span>
        <span style="{bmi_badge} padding: 2px 8px; border-radius: 6px; font-size: 0.75rem; font-weight: 700;">{bmi_category}</span>
    </div>
    """,
    unsafe_allow_html=True,
)

st.sidebar.markdown('<div class="sidebar-section-title">🩺 Huyết áp & Hóa sinh</div>', unsafe_allow_html=True)
col_hi, col_lo = st.sidebar.columns(2)
with col_hi:
    ap_hi = st.number_input("Huyết áp TT (ap_hi)", min_value=90, max_value=240, value=int(init_ap_hi), step=5)
with col_lo:
    ap_lo = st.number_input("Huyết áp TTr (ap_lo)", min_value=60, max_value=140, value=int(init_ap_lo), step=5)

if ap_hi <= ap_lo:
    st.sidebar.error("⚠️ Cảnh báo lâm sàng: Huyết áp tâm thu phải lớn hơn huyết áp tâm trương!")

cholesterol_dict = {"Mức 1: Bình thường (< 5.2 mmol/L)": 1, "Mức 2: Hơi cao (5.2 - 6.2 mmol/L)": 2, "Mức 3: Rất cao (> 6.2 mmol/L)": 3}
chol_str = st.sidebar.selectbox("Cholesterol toàn phần", list(cholesterol_dict.keys()), index=init_chol - 1)
cholesterol = cholesterol_dict[chol_str]

gluc_dict = {"Mức 1: Bình thường (< 5.6 mmol/L)": 1, "Mức 2: Rối loạn dung nạp (5.6 - 6.9)": 2, "Mức 3: Đái tháo đường (≥ 7.0 mmol/L)": 3}
gluc_str = st.sidebar.selectbox("Đường huyết lúc đói (Glucose)", list(gluc_dict.keys()), index=init_gluc - 1)
gluc = gluc_dict[gluc_str]

st.sidebar.markdown('<div class="sidebar-section-title">🏃 Thói quen Sống & Nguy cơ Hành vi</div>', unsafe_allow_html=True)
col_s1, col_s2, col_s3 = st.sidebar.columns(3)
with col_s1:
    smoke = 1 if st.checkbox("Hút thuốc", value=bool(init_smoke)) else 0
with col_s2:
    alco = 1 if st.checkbox("Bia rượu", value=bool(init_alco)) else 0
with col_s3:
    active = 1 if st.checkbox("Vận động", value=bool(init_active)) else 0

st.sidebar.markdown("<br>", unsafe_allow_html=True)
save_db_btn = st.sidebar.button("💾 Lưu Hồ sơ vào SQL CSDL", use_container_width=True)

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
pred_proba = float(model.predict_proba(patient_df_scaled)[0, 1])
pred_class = int(pred_proba >= 0.5)

if pred_proba >= 0.65:
    risk_level = "NGUY CƠ CAO"
    risk_css_pill = "risk-pill-high"
    risk_icon = "🔴"
    directive_css = "directive-card-high"
    directive_text = f"<strong>Phác đồ can thiệp cấp thiết:</strong> Bệnh nhân thuộc phân tầng nguy cơ cao ({pred_proba:.1%}). Cần chỉ định ngay Điện tâm đồ (ECG 12 chuyển đạo), Siêu âm tim Doppler, xét nghiệm bộ mỡ máu (Lipid panel), và thiết lập phác đồ điều trị huyết áp/statin hạ lipid máu."
elif pred_proba >= 0.35:
    risk_level = "NGUY CƠ TRUNG BÌNH"
    risk_css_pill = "risk-pill-mod"
    risk_icon = "🟡"
    directive_css = "directive-card-mod"
    directive_text = f"<strong>Phác đồ theo dõi tích cực:</strong> Bệnh nhân có nguy cơ tim mạch tiềm ẩn ({pred_proba:.1%}). Khuyến nghị theo dõi huyết áp lưu động (ABPM), tầm soát đường huyết định kỳ 3 tháng/lần và điều chỉnh tích cực chế độ ăn giảm muối, tăng cường tập luyện thể lực."
else:
    risk_level = "NGUY CƠ THẤP"
    risk_css_pill = "risk-pill-low"
    risk_icon = "🟢"
    directive_css = "directive-card-low"
    directive_text = f"<strong>Khuyến nghị bảo vệ sức khỏe:</strong> Các chỉ số tim mạch và chuyển hóa nằm trong ngưỡng an toàn ({pred_proba:.1%}). Bác sĩ khuyên bệnh nhân tiếp tục duy trì vận động thể chất thường xuyên và khám định kỳ mỗi 12 tháng."

# Save to SQL database if button clicked
if save_db_btn:
    rec_id = save_assessment(patient_name, patient_raw, pred_proba, risk_level, directive_text)
    st.sidebar.success(f"Đã lưu hồ sơ bệnh án thành công! (Mã HS: #{rec_id})")

# ==========================================
# HERO BANNER
# ==========================================
st.markdown(
    f"""
    <div class="hero-header">
        <div>
            <div class="hero-badge">Clinical AI Intelligence v2.0 • Zero-Budget Production</div>
            <h1 class="hero-title">CardioXAI: Hệ thống Dự đoán Nguy cơ Tim mạch & Giải thích Y tế</h1>
            <div class="hero-desc">
                Hệ thống hỗ trợ quyết định lâm sàng (CDSS) tích hợp mô hình Machine Learning siêu tham số tối ưu cùng 
                kỹ thuật Explainable AI (SHAP Waterfall & LIME), cung cấp minh chứng định lượng vì sao đưa ra kết luận chẩn đoán.
            </div>
        </div>
        <div style="text-align: right; background: rgba(255,255,255,0.08); padding: 14px 20px; border-radius: 16px; border: 1px solid rgba(255,255,255,0.15);">
            <div style="font-size: 0.75rem; color: #90E0EF; font-weight: 700; text-transform: uppercase;">Mô hình Champion</div>
            <div style="font-size: 1.15rem; font-weight: 800; color: white;">XGBoost (Optuna)</div>
            <div style="font-size: 0.8rem; color: #E0E1DD;">ROC-AUC 0.8009 • Recall 81.0%</div>
        </div>
    </div>
    """,
    unsafe_allow_html=True,
)

# ==========================================
# CLINICAL METRIC STATS CARDS
# ==========================================
col_m1, col_m2, col_m3, col_m4 = st.columns(4)

with col_m1:
    st.markdown(
        f"""
        <div class="metric-card">
            <div>
                <div class="metric-title">Xác suất Bệnh Tim mạch</div>
                <div class="metric-val" style="color: {'#E53E3E' if pred_proba>=0.5 else '#38A169'};">{pred_proba:.1%}</div>
            </div>
            <div class="metric-subtitle" style="color: {'#E53E3E' if pred_proba>=0.5 else '#38A169'};">
                {'▲ Tăng ' if pred_proba>=0.5 else '▼ Dưới '} {abs(pred_proba - 0.5):.1%} so với ngưỡng 50%
            </div>
        </div>
        """,
        unsafe_allow_html=True,
    )

with col_m2:
    st.markdown(
        f"""
        <div class="metric-card">
            <div>
                <div class="metric-title">Phân tầng Nguy cơ Lâm sàng</div>
                <div style="margin-top: 10px;">
                    <span class="{risk_css_pill}">{risk_icon} {risk_level}</span>
                </div>
            </div>
            <div class="metric-subtitle" style="color: #64748B;">
                Dựa trên chuẩn Hiệp hội Tim mạch
            </div>
        </div>
        """,
        unsafe_allow_html=True,
    )

with col_m3:
    st.markdown(
        f"""
        <div class="metric-card">
            <div>
                <div class="metric-title">Chỉ số Thể trạng (BMI)</div>
                <div class="metric-val">{bmi} <span style="font-size: 1rem; font-weight: 600; color: #64748B;">kg/m²</span></div>
            </div>
            <div class="metric-subtitle" style="color: #64748B;">
                Phân loại: <strong>{bmi_category}</strong>
            </div>
        </div>
        """,
        unsafe_allow_html=True,
    )

with col_m4:
    st.markdown(
        f"""
        <div class="metric-card">
            <div>
                <div class="metric-title">Huyết áp Lâm sàng</div>
                <div class="metric-val">{int(ap_hi)}/{int(ap_lo)} <span style="font-size: 1rem; font-weight: 600; color: #64748B;">mmHg</span></div>
            </div>
            <div class="metric-subtitle" style="color: {'#E53E3E' if ap_hi>=140 or ap_lo>=90 else '#38A169'};">
                {'⚠️ Tăng huyết áp' if ap_hi>=140 or ap_lo>=90 else '✓ Huyết áp ổn định'}
            </div>
        </div>
        """,
        unsafe_allow_html=True,
    )

st.markdown("<br>", unsafe_allow_html=True)

# Actionable Directive
st.markdown(
    f"""
    <div class="{directive_css}">
        {directive_text}
    </div>
    """,
    unsafe_allow_html=True,
)

# ==========================================
# INTERACTIVE TABS
# ==========================================
tab_shap, tab_lime, tab_global, tab_history, tab_model = st.tabs([
    "🔍 1. Giải thích Cá thể hóa (SHAP)",
    "📊 2. Bóc tách Luật Điều kiện (LIME)",
    "🌐 3. Quy luật Toàn cục (Global Population XAI)",
    "🗄️ 4. Lịch sử Bệnh án (SQL Database)",
    "📈 5. Kiểm định Mô hình (Model Governance)",
])

# ------------------------------------------
# TAB 1: SHAP WATERFALL PLOT
# ------------------------------------------
with tab_shap:
    st.markdown(
        """
        <div style="background: white; border: 1px solid #E2E8F0; border-radius: 14px; padding: 20px; margin-bottom: 20px;">
            <h4 style="margin: 0 0 10px 0; color: #0F172A;">Biểu đồ SHAP Waterfall: Cơ chế Đóng góp Biên Từng Chỉ số</h4>
            <div style="color: #64748B; font-size: 0.95rem; line-height: 1.6;">
                Biểu đồ dưới đây minh họa chi tiết giá trị cộng dồn từ mức nguy cơ kỳ vọng toàn quần thể <code>E[f(X)] = 0.346</code> 
                đến xác suất dự báo cụ thể của riêng ca bệnh này:
                <br>
                • <strong style="color: #E53E3E;">Thanh Đỏ (Giá trị dương +):</strong> Chỉ số y sinh đang <em>đẩy tăng nguy cơ</em> tim mạch.<br>
                • <strong style="color: #3182CE;">Thanh Xanh (Giá trị âm -):</strong> Chỉ số y sinh đang <em>đóng vai trò bảo vệ, kéo giảm nguy cơ</em>.
            </div>
        </div>
        """,
        unsafe_allow_html=True,
    )

    with st.spinner("Đang tính toán giá trị Shapley theo thời gian thực..."):
        shap_vals = shap_explainer(patient_df_scaled)
        explanation = shap.Explanation(
            values=shap_vals.values[0],
            base_values=shap_vals.base_values[0],
            data=patient_df_unscaled.values[0],
            feature_names=[CLINICAL_FEATURE_LABELS.get(col, col) for col in patient_df_scaled.columns],
        )

        col_w1, col_w2 = st.columns([1.3, 1])

        with col_w1:
            fig_shap, ax_shap = plt.subplots(figsize=(9, 5.2), dpi=250)
            shap.plots.waterfall(explanation, max_display=10, show=False)
            plt.title(f"SHAP Waterfall: Ca bệnh '{patient_name}' (P_nguy cơ = {pred_proba:.1%})", fontsize=11, fontweight="bold", pad=12)
            plt.tight_layout()
            st.pyplot(fig_shap, clear_figure=True)
            plt.close(fig_shap)

        with col_w2:
            st.markdown("##### 📋 Bóc tách Định lượng Đóng góp Biên:")
            shap_df = pd.DataFrame({
                "Chỉ số Y sinh": [CLINICAL_FEATURE_LABELS.get(col, col) for col in patient_df_scaled.columns],
                "Giá trị đo": patient_df_unscaled.values[0],
                "Giá trị SHAP": shap_vals.values[0],
                "Tác động": [
                    "🔴 Tăng nguy cơ" if v > 0.05 else ("🟢 Giúp bảo vệ" if v < -0.05 else "⚪ Trung tính")
                    for v in shap_vals.values[0]
                ],
            }).sort_values(by="Giá trị SHAP", ascending=False)

            st.dataframe(
                shap_df.style.format({"Giá trị SHAP": "{:+.4f}"}),
                use_container_width=True,
                hide_index=True,
            )

# ------------------------------------------
# TAB 2: LIME LOCAL EXPLAINER
# ------------------------------------------
with tab_lime:
    st.markdown(
        """
        <div style="background: white; border: 1px solid #E2E8F0; border-radius: 14px; padding: 20px; margin-bottom: 20px;">
            <h4 style="margin: 0 0 10px 0; color: #0F172A;">Mô hình Tuyến tính Cục bộ LIME (Local Interpretable Model-agnostic Explanations)</h4>
            <div style="color: #64748B; font-size: 0.95rem; line-height: 1.6;">
                LIME xấp xỉ cục bộ quyết định của mô hình xung quanh bệnh nhân để trích xuất các điều kiện lâm sàng then chốt theo dạng luật logic.
            </div>
        </div>
        """,
        unsafe_allow_html=True,
    )

    with st.spinner("Đang tính toán xấp xỉ cục bộ LIME..."):
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
            plt.title("Trọng số Điều kiện LIME đối với Bệnh Tim mạch", fontsize=11, fontweight="bold")
            plt.xlabel("Trọng số LIME", fontsize=10)
            plt.tight_layout()
            st.pyplot(fig_lime, clear_figure=True)
            plt.close(fig_lime)

        with col_l2:
            st.markdown("##### 📌 Quy luật Quyết định Cục bộ:")
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
    st.markdown(
        """
        <div style="background: white; border: 1px solid #E2E8F0; border-radius: 14px; padding: 20px; margin-bottom: 20px;">
            <h4 style="margin: 0 0 10px 0; color: #0F172A;">Quy luật Y sinh Toàn Quần thể (N = 65,198 Mẫu Bệnh nhân)</h4>
            <div style="color: #64748B; font-size: 0.95rem;">
                Đối chiếu tương quan giữa chỉ số cá nhân và hành vi rủi ro toàn cục được mô hình hóa từ tập dữ liệu lớn.
            </div>
        </div>
        """,
        unsafe_allow_html=True,
    )

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
# TAB 4: SQL DATABASE PATIENT RECORDS
# ------------------------------------------
with tab_history:
    st.markdown(
        """
        <div style="background: white; border: 1px solid #E2E8F0; border-radius: 14px; padding: 20px; margin-bottom: 20px;">
            <h4 style="margin: 0 0 10px 0; color: #0F172A;">Hồ sơ Bệnh án Lưu trữ Tập trung (SQL Database)</h4>
            <div style="color: #64748B; font-size: 0.95rem;">
                Toàn bộ các ca khám bệnh được lưu trữ toàn vẹn trong cơ sở dữ liệu quan hệ, sẵn sàng đồng bộ đa nền tảng (Web & Mobile App).
            </div>
        </div>
        """,
        unsafe_allow_html=True,
    )

    db_records = get_all_records(limit=100)
    if db_records:
        df_db = pd.DataFrame(db_records)
        df_db["Xác suất"] = df_db["risk_probability"].apply(lambda p: f"{p:.1%}")
        display_cols = ["id", "patient_name", "age", "gender", "bmi", "ap_hi", "ap_lo", "cholesterol", "Xác suất", "risk_level", "created_at"]
        st.dataframe(
            df_db[display_cols].rename(columns={
                "id": "Mã HS",
                "patient_name": "Họ và Tên",
                "age": "Tuổi",
                "gender": "Giới",
                "bmi": "BMI",
                "ap_hi": "HA Thu",
                "ap_lo": "HA Trương",
                "cholesterol": "Cholesterol",
                "risk_level": "Phân tầng Rủi ro",
                "created_at": "Thời gian Khám",
            }),
            use_container_width=True,
            hide_index=True,
        )
    else:
        st.info("Chưa có hồ sơ bệnh án nào được lưu. Bác sĩ có thể nhập thông tin và bấm 'Lưu Hồ sơ vào SQL CSDL' ở cột bên trái.")

# ------------------------------------------
# TAB 5: MODEL GOVERNANCE & METRICS
# ------------------------------------------
with tab_model:
    st.markdown(
        """
        <div style="background: white; border: 1px solid #E2E8F0; border-radius: 14px; padding: 20px; margin-bottom: 20px;">
            <h4 style="margin: 0 0 10px 0; color: #0F172A;">Báo cáo Kiểm định Năng lực Mô hình (Model Governance & Benchmark)</h4>
            <div style="color: #64748B; font-size: 0.95rem;">
                Mô hình triển khai là <strong>XGBoost Classifier</strong> đã được tối ưu siêu tham số bằng thuật toán <strong>Optuna (Bayesian TPE)</strong> 
                qua 5-Fold Stratified Cross-Validation và đánh giá độc lập trên 13,040 mẫu kiểm định:
            </div>
        </div>
        """,
        unsafe_allow_html=True,
    )

    if METRICS_CSV_FILE.exists():
        df_metrics = pd.read_csv(METRICS_CSV_FILE)
        st.dataframe(df_metrics.style.highlight_max(subset=["ROC-AUC", "Recall", "F1-Score", "Accuracy"], color="#D1E7DD"), use_container_width=True, hide_index=True)

    st.markdown(
        """
        - 🏆 **ROC-AUC (0.8009):** Năng lực phân định ngưỡng bệnh lý tim mạch đạt tiêu chuẩn xuất sắc.
        - 🩺 **Recall / Độ nhạy (80.99%):** Giảm thiểu tối đa việc bỏ sót ca bệnh nguy hiểm trong khám sàng lọc.
        - ⚡ **Độ trễ suy luận (0.015s):** Đạt tiêu chuẩn thời gian thực cho cả Web Dashboard lẫn ứng dụng di động.
        """
    )
