"""
Phase 4: Clinical Decision Support Dashboard (Streamlit).
Streamlined, clean medical aesthetics with Explainable AI (SHAP & LIME).
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
    page_title="CardioXAI - Hỗ trợ Quyết định Lâm sàng Tim mạch",
    page_icon="🫀",
    layout="wide",
    initial_sidebar_state="expanded",
)

# Clean, balanced, eye-friendly clinical CSS (neutral slate + soft medical accents)
st.markdown(
    """
    <style>
    @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap');

    html, body, [class*="css"] {
        font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
        color: #1E293B;
    }

    /* Page container */
    .block-container {
        padding-top: 2rem;
        padding-bottom: 2.5rem;
        max-width: 1300px;
    }

    /* Clean subtle header */
    .page-header {
        border-bottom: 1px solid #E2E8F0;
        padding-bottom: 14px;
        margin-bottom: 20px;
    }
    .page-title {
        font-size: 1.65rem;
        font-weight: 700;
        color: #0F172A;
        margin: 0;
        display: flex;
        align-items: center;
        gap: 10px;
    }
    .page-subtitle {
        color: #64748B;
        font-size: 0.92rem;
        margin-top: 4px;
    }

    /* Metric Cards: Flat, elegant, neutral */
    .card-metric {
        background: #FFFFFF;
        border: 1px solid #E2E8F0;
        border-radius: 12px;
        padding: 16px 20px;
        box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
    }
    .card-label {
        font-size: 0.8rem;
        font-weight: 600;
        color: #64748B;
        text-transform: uppercase;
        letter-spacing: 0.5px;
    }
    .card-value {
        font-size: 1.85rem;
        font-weight: 700;
        margin-top: 4px;
        color: #0F172A;
        line-height: 1.2;
    }
    .card-sub {
        font-size: 0.82rem;
        margin-top: 4px;
        color: #475569;
    }

    /* Directive recommendations: Soft tinted background */
    .directive-box {
        border-radius: 10px;
        padding: 14px 18px;
        margin-top: 14px;
        margin-bottom: 22px;
        font-size: 0.92rem;
        line-height: 1.5;
        border-left: 4px solid;
    }
    .dir-high {
        background-color: #FEF2F2;
        border-color: #EF4444;
        color: #991B1B;
    }
    .dir-mod {
        background-color: #FFFBEB;
        border-color: #F59E0B;
        color: #92400E;
    }
    .dir-low {
        background-color: #F0FDF4;
        border-color: #10B981;
        color: #065F46;
    }

    /* Clean navigation tabs */
    .stTabs [data-baseweb="tab-list"] {
        gap: 8px;
        border-bottom: 1px solid #E2E8F0;
    }
    .stTabs [data-baseweb="tab"] {
        padding: 8px 16px;
        font-size: 0.9rem;
        font-weight: 500;
        color: #64748B;
        border-radius: 6px 6px 0 0;
    }
    .stTabs [aria-selected="true"] {
        color: #0284C7 !important;
        font-weight: 600 !important;
        border-bottom: 2px solid #0284C7 !important;
        background-color: transparent !important;
    }

    /* Badges */
    .badge-pill {
        display: inline-block;
        padding: 3px 10px;
        border-radius: 12px;
        font-size: 0.78rem;
        font-weight: 600;
    }
    .badge-high { background: #FEE2E2; color: #991B1B; }
    .badge-mod { background: #FEF3C7; color: #92400E; }
    .badge-low { background: #DCFCE7; color: #166534; }
    </style>
    """,
    unsafe_allow_html=True,
)


@st.cache_resource(show_spinner="Đang khởi tạo mô hình chuẩn...")
def load_resources():
    """Loads and caches model, scaler, and explainers."""
    model = joblib.load(BEST_MODEL_FILE)
    scaler = joblib.load(SCALER_FILE)

    shap_explainer_path = MODELS_DIR / "shap_explainer.joblib"
    if shap_explainer_path.exists():
        shap_explainer = joblib.load(shap_explainer_path)
    else:
        shap_explainer = shap.TreeExplainer(model)

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
            class_names=["Healthy", "Cardiovascular Risk"],
            mode="classification",
            random_state=42,
        )

    return model, scaler, shap_explainer, lime_explainer


model, scaler, shap_explainer, lime_explainer = load_resources()

# ==========================================
# SIDEBAR: THÔNG TIN KHÁM BỆNH NHÂN
# ==========================================
st.sidebar.markdown("### 🫀 CardioXAI Clinical")
st.sidebar.caption("Hệ thống hỗ trợ chẩn đoán & giải thích y tế")

# Persona presets
preset = st.sidebar.selectbox(
    "Nạp nhanh ca lâm sàng mẫu:",
    [
        "Tùy chỉnh (Nhập tự do)",
        "Ca 1: Bệnh nhân Nguy cơ Cao (51t, HA 145/95, Chol 3)",
        "Ca 2: Người khỏe mạnh (32t, HA 118/76, Chol 1)",
    ],
)

if preset == "Ca 1: Bệnh nhân Nguy cơ Cao (51t, HA 145/95, Chol 3)":
    init_name, init_age, init_gender = "Trần Văn Cao", 51, "Nam"
    init_h, init_w = 168, 90.0
    init_ap_hi, init_ap_lo = 145, 95
    init_chol, init_gluc = 3, 2
    init_smoke, init_alco, init_active = 1, 0, 0
elif preset == "Ca 2: Người khỏe mạnh (32t, HA 118/76, Chol 1)":
    init_name, init_age, init_gender = "Lê Thị Thảo", 32, "Nữ"
    init_h, init_w = 165, 61.0
    init_ap_hi, init_ap_lo = 118, 76
    init_chol, init_gluc = 1, 1
    init_smoke, init_alco, init_active = 0, 0, 1
else:
    init_name, init_age, init_gender = "Nguyễn Văn A", 50, "Nam"
    init_h, init_w = 165, 72.0
    init_ap_hi, init_ap_lo = 130, 85
    init_chol, init_gluc = 2, 1
    init_smoke, init_alco, init_active = 0, 0, 1

patient_name = st.sidebar.text_input("Tên bệnh nhân:", value=init_name)

st.sidebar.markdown("**1. Thông số thể trạng**")
age = st.sidebar.slider("Tuổi", min_value=30, max_value=65, value=init_age, step=1)
gender_str = st.sidebar.radio("Giới tính", ["Nữ", "Nam"], index=1 if init_gender == "Nam" else 0, horizontal=True)
gender = 2 if gender_str == "Nam" else 1

col_h, col_w = st.sidebar.columns(2)
with col_h:
    height = st.number_input("Chiều cao (cm)", min_value=120, max_value=220, value=int(init_h), step=1)
with col_w:
    weight = st.number_input("Cân nặng (kg)", min_value=35.0, max_value=180.0, value=float(init_w), step=0.5)

bmi = round(weight / ((height / 100.0) ** 2), 2)
if bmi < 18.5:
    bmi_category, bmi_cls = "Thiếu cân", "badge-low"
elif bmi < 25.0:
    bmi_category, bmi_cls = "Bình thường", "badge-low"
elif bmi < 30.0:
    bmi_category, bmi_cls = "Tiền béo phì", "badge-mod"
else:
    bmi_category, bmi_cls = "Béo phì", "badge-high"

st.sidebar.markdown(
    f"<div style='font-size:0.85rem; color:#475569; margin-top:2px;'>BMI: <b>{bmi} kg/m²</b> &nbsp; <span class='badge-pill {bmi_cls}'>{bmi_category}</span></div>",
    unsafe_allow_html=True,
)

st.sidebar.markdown("---")
st.sidebar.markdown("**2. Huyết áp & Hóa sinh**")
col_hi, col_lo = st.sidebar.columns(2)
with col_hi:
    ap_hi = st.number_input("HA tâm thu", min_value=90, max_value=240, value=int(init_ap_hi), step=5)
with col_lo:
    ap_lo = st.number_input("HA tâm trương", min_value=60, max_value=140, value=int(init_ap_lo), step=5)

chol_options = {1: "Mức 1: Bình thường (< 5.2 mmol/L)", 2: "Mức 2: Hơi cao (5.2 - 6.2 mmol/L)", 3: "Mức 3: Rất cao (> 6.2 mmol/L)"}
cholesterol = st.sidebar.selectbox("Cholesterol toàn phần", options=[1, 2, 3], format_func=lambda x: chol_options[x], index=init_chol - 1)

gluc_options = {1: "Mức 1: Bình thường (< 5.6 mmol/L)", 2: "Mức 2: Rối loạn dung nạp (5.6 - 6.9)", 3: "Mức 3: Đái tháo đường (≥ 7.0 mmol/L)"}
gluc = st.sidebar.selectbox("Đường huyết đói (Glucose)", options=[1, 2, 3], format_func=lambda x: gluc_options[x], index=init_gluc - 1)

st.sidebar.markdown("---")
st.sidebar.markdown("**3. Thói quen**")
c_s1, c_s2, c_s3 = st.sidebar.columns(3)
with c_s1:
    smoke = 1 if st.checkbox("Hút thuốc", value=bool(init_smoke)) else 0
with c_s2:
    alco = 1 if st.checkbox("Rượu bia", value=bool(init_alco)) else 0
with c_s3:
    active = 1 if st.checkbox("Vận động", value=bool(init_active)) else 0

st.sidebar.markdown("<br>", unsafe_allow_html=True)
save_db_btn = st.sidebar.button("💾 Lưu ca khám vào CSDL SQL", use_container_width=True)

# Process inference
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

pred_proba = float(model.predict_proba(patient_df_scaled)[0, 1])

# Classify risk
if pred_proba >= 0.65:
    risk_level = "NGUY CƠ CAO"
    risk_color = "#DC2626"
    badge_style = "badge-high"
    dir_class = "dir-high"
    recommendation_text = f"Bệnh nhân có nguy cơ tim mạch cao ({pred_proba:.1%}). Bác sĩ cần chỉ định Điện tâm đồ (ECG), siêu âm tim Doppler và lập phác đồ kiểm soát huyết áp/lipid máu tích cực."
elif pred_proba >= 0.35:
    risk_level = "NGUY CƠ TRUNG BÌNH"
    risk_color = "#D97706"
    badge_style = "badge-mod"
    dir_class = "dir-mod"
    recommendation_text = f"Bệnh nhân có nguy cơ tim mạch tiềm ẩn ({pred_proba:.1%}). Khuyến nghị theo dõi huyết áp định kỳ và can thiệp thay đổi lối sống (kiểm soát cân nặng, giảm muối, tập luyện đều đặn)."
else:
    risk_level = "NGUY CƠ THẤP"
    risk_color = "#16A34A"
    badge_style = "badge-low"
    dir_class = "dir-low"
    recommendation_text = f"Các chỉ số tim mạch hiện tại trong dải an toàn ({pred_proba:.1%}). Khuyến khích duy trì lối sống lành mạnh, ăn nhiều rau quả và khám sức khỏe định kỳ hàng năm."

# Save record trigger
if save_db_btn:
    rec_id = save_assessment(patient_name, patient_raw, pred_proba, risk_level, recommendation_text)
    st.sidebar.success(f"Đã lưu hồ sơ thành công! (Mã số #{rec_id})")

# ==========================================
# MAIN DASHBOARD CONTENT
# ==========================================
st.markdown(
    """
    <div class="page-header">
        <h1 class="page-title">🫀 Hệ thống Chẩn đoán Nguy cơ Tim mạch & Giải thích Y tế (CardioXAI)</h1>
        <div class="page-subtitle">Hỗ trợ hội chẩn y khoa bằng mô hình AI minh bạch (XGBoost kết hợp SHAP & LIME)</div>
    </div>
    """,
    unsafe_allow_html=True,
)

# 4 Balanced Metric Cards
col1, col2, col3, col4 = st.columns(4)

with col1:
    delta_str = f"+{(pred_proba - 0.5):.1%}" if pred_proba >= 0.5 else f"{(pred_proba - 0.5):.1%}"
    st.markdown(
        f"""
        <div class="card-metric">
            <div class="card-label">Xác suất Bệnh Tim mạch</div>
            <div class="card-value" style="color: {risk_color};">{pred_proba:.1%}</div>
            <div class="card-sub">So với ngưỡng 50%: <b>{delta_str}</b></div>
        </div>
        """,
        unsafe_allow_html=True,
    )

with col2:
    st.markdown(
        f"""
        <div class="card-metric">
            <div class="card-label">Phân tầng Rủi ro</div>
            <div class="card-value" style="font-size: 1.55rem; color: {risk_color};">
                <span class="badge-pill {badge_style}">{risk_level}</span>
            </div>
            <div class="card-sub">Theo thang đo lâm sàng ESC/ACC</div>
        </div>
        """,
        unsafe_allow_html=True,
    )

with col3:
    st.markdown(
        f"""
        <div class="card-metric">
            <div class="card-label">Thể trạng (BMI)</div>
            <div class="card-value">{bmi} <span style="font-size:1rem; font-weight:500; color:#64748B;">kg/m²</span></div>
            <div class="card-sub">Phân nhóm: <b>{bmi_category}</b></div>
        </div>
        """,
        unsafe_allow_html=True,
    )

with col4:
    bp_status = "⚠️ Huyết áp cao" if (ap_hi >= 140 or ap_lo >= 90) else "✓ Huyết áp bình thường"
    st.markdown(
        f"""
        <div class="card-metric">
            <div class="card-label">Huyết áp Lâm sàng</div>
            <div class="card-value">{int(ap_hi)}/{int(ap_lo)} <span style="font-size:1rem; font-weight:500; color:#64748B;">mmHg</span></div>
            <div class="card-sub">{bp_status}</div>
        </div>
        """,
        unsafe_allow_html=True,
    )

# Recommendation Box
st.markdown(
    f"""
    <div class="directive-box {dir_class}">
        <strong>Khuyến nghị lâm sàng cho ca bệnh '{patient_name}':</strong><br>
        {recommendation_text}
    </div>
    """,
    unsafe_allow_html=True,
)

# Clean Tabs
tab_shap, tab_lime, tab_global, tab_history, tab_model = st.tabs([
    "🔍 1. Giải thích Cá thể hóa (SHAP)",
    "📊 2. Luật Điều kiện (LIME)",
    "🌐 3. Quy luật Quần thể",
    "🗄️ 4. Hồ sơ Bệnh án SQL",
    "📈 5. Kiểm định Mô hình",
])

# ------------------------------------------
# TAB 1: SHAP WATERFALL
# ------------------------------------------
with tab_shap:
    st.markdown(
        """
        <div style="font-size:0.92rem; color:#475569; margin-bottom: 12px;">
            Biểu đồ <b>SHAP Waterfall</b> thể hiện đóng góp biên của từng chỉ số y sinh đối với bệnh nhân này:
            <span style="color:#DC2626; font-weight:600;">Thanh Đỏ (+) làm tăng rủi ro</span> | 
            <span style="color:#2563EB; font-weight:600;">Thanh Xanh (-) giúp giảm rủi ro</span>.
        </div>
        """,
        unsafe_allow_html=True,
    )

    shap_vals = shap_explainer(patient_df_scaled)
    explanation = shap.Explanation(
        values=shap_vals.values[0],
        base_values=shap_vals.base_values[0],
        data=patient_df_unscaled.values[0],
        feature_names=[CLINICAL_FEATURE_LABELS.get(col, col) for col in patient_df_scaled.columns],
    )

    c_plot, c_table = st.columns([1.3, 1])

    with c_plot:
        fig_shap, ax_shap = plt.subplots(figsize=(8.5, 4.8), dpi=200)
        shap.plots.waterfall(explanation, max_display=9, show=False)
        plt.title(f"SHAP Waterfall: Ca bệnh {patient_name} (Xác suất = {pred_proba:.1%})", fontsize=10, fontweight="bold", pad=10)
        plt.tight_layout()
        st.pyplot(fig_shap, clear_figure=True)
        plt.close(fig_shap)

    with c_table:
        st.markdown("**Bảng giá trị đóng góp Shapley:**")
        shap_df = pd.DataFrame({
            "Chỉ số": [CLINICAL_FEATURE_LABELS.get(col, col) for col in patient_df_scaled.columns],
            "Giá trị đo": patient_df_unscaled.values[0],
            "SHAP": shap_vals.values[0],
            "Tác động": [
                "Tăng nguy cơ (+)" if v > 0.05 else ("Bảo vệ (-)" if v < -0.05 else "Trung tính")
                for v in shap_vals.values[0]
            ],
        }).sort_values(by="SHAP", ascending=False)

        st.dataframe(
            shap_df.style.format({"SHAP": "{:+.4f}"}),
            use_container_width=True,
            hide_index=True,
        )

# ------------------------------------------
# TAB 2: LIME
# ------------------------------------------
with tab_lime:
    st.markdown(
        """
        <div style="font-size:0.92rem; color:#475569; margin-bottom: 12px;">
            <b>LIME (Local Interpretable Model-agnostic Explanations)</b> trích xuất các điều kiện y sinh cục bộ giải thích quyết định của mô hình.
        </div>
        """,
        unsafe_allow_html=True,
    )

    exp = lime_explainer.explain_instance(
        patient_df_scaled.iloc[0].values,
        model.predict_proba,
        num_features=7,
        labels=[1],
    )

    c_l1, c_l2 = st.columns([1.2, 1])
    with c_l1:
        fig_lime = exp.as_pyplot_figure(label=1)
        fig_lime.set_size_inches(7.5, 4.2)
        plt.title("Trọng số điều kiện LIME", fontsize=10, fontweight="bold")
        plt.tight_layout()
        st.pyplot(fig_lime, clear_figure=True)
        plt.close(fig_lime)

    with c_l2:
        st.markdown("**Các quy luật điều kiện kích hoạt:**")
        lime_rules = exp.as_list(label=1)
        for rule, weight in lime_rules:
            if weight > 0:
                st.markdown(f"- 🔴 **{rule}**: Tăng nguy cơ (`+{weight:.3f}`)")
            else:
                st.markdown(f"- 🟢 **{rule}**: Giảm nguy cơ (`{weight:.3f}`)")

# ------------------------------------------
# TAB 3: GLOBAL POPULATION
# ------------------------------------------
with tab_global:
    st.markdown(
        """
        <div style="font-size:0.92rem; color:#475569; margin-bottom: 14px;">
            Quy luật tương quan trên 65,198 mẫu bệnh nhân trong nghiên cứu.
        </div>
        """,
        unsafe_allow_html=True,
    )

    g1, g2 = st.columns(2)
    with g1:
        st.image(str(FIGURES_DIR / "shap_summary_beeswarm.png"), caption="Phân bố tác động toàn cục của các chỉ số (SHAP Beeswarm)")
        st.image(str(FIGURES_DIR / "shap_dependence_ap_hi.png"), caption="Quan hệ phi tuyến giữa Huyết áp tâm thu và Nguy cơ tim mạch")
    with g2:
        st.image(str(FIGURES_DIR / "shap_feature_importance_bar.png"), caption="Độ quan trọng trung bình toàn cục (|SHAP|)")
        st.image(str(FIGURES_DIR / "shap_dependence_bmi.png"), caption="Tương tác nguy cơ theo chỉ số BMI")

# ------------------------------------------
# TAB 4: SQL DATABASE
# ------------------------------------------
with tab_history:
    st.markdown("**Hồ sơ bệnh nhân đã lưu trong hệ thống CSDL SQL:**")
    records = get_all_records(limit=50)
    if records:
        df_rec = pd.DataFrame(records)
        df_rec["Xác suất"] = df_rec["risk_probability"].apply(lambda p: f"{p:.1%}")
        cols_show = ["id", "patient_name", "age", "bmi", "ap_hi", "ap_lo", "cholesterol", "Xác suất", "risk_level", "created_at"]
        st.dataframe(
            df_rec[cols_show].rename(columns={
                "id": "Mã",
                "patient_name": "Tên bệnh nhân",
                "age": "Tuổi",
                "bmi": "BMI",
                "ap_hi": "HA thu",
                "ap_lo": "HA trương",
                "cholesterol": "Cholesterol",
                "risk_level": "Phân tầng",
                "created_at": "Ngày khám",
            }),
            use_container_width=True,
            hide_index=True,
        )
    else:
        st.info("Chưa có hồ sơ bệnh án nào được ghi nhận. Nhập thông tin và bấm 'Lưu ca khám vào CSDL SQL' ở thanh bên trái.")

# ------------------------------------------
# TAB 5: MODEL BENCHMARK
# ------------------------------------------
with tab_model:
    st.markdown("**Thông số kiểm định mô hình (XGBoost Tuned by Optuna):**")
    if METRICS_CSV_FILE.exists():
        df_metrics = pd.read_csv(METRICS_CSV_FILE)
        st.dataframe(df_metrics, use_container_width=True, hide_index=True)

    st.markdown(
        """
        - **ROC-AUC (0.8009):** Khả năng phân loại tổng thể vượt trội so với Random Forest và SVM.
        - **Độ nhạy / Recall (80.99%):** Giúp phát hiện sớm đa số người có nguy cơ để can thiệp kịp thời.
        - **Thời gian xử lý (< 20ms):** Đảm bảo phản hồi tức thì cho bác sĩ lâm sàng.
        """
    )
