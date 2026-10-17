"""
CardioXAI Clinical & Patient Decision Support System.
Split into two dedicated, professional portals:
1. 🩺 Dành cho Y Bác sĩ (Clinical Decision Support & Explainable AI)
2. 🫀 Dành cho Bệnh nhân (Patient Health Portal: Trang chủ Kiến thức, Bài báo & Chẩn đoán tự đánh giá)
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
from src.articles import (
    get_all_articles,
    get_categories,
    get_article_by_id,
    STANDARD_HEALTH_METRICS,
    EMERGENCY_CONTACTS,
)

# Page Configuration
st.set_page_config(
    page_title="CardioXAI - Nền tảng Y tế Tim mạch Thông minh",
    page_icon="🫀",
    layout="wide",
    initial_sidebar_state="expanded",
)

# Clean, modern, eye-friendly clinical CSS
st.markdown(
    """
    <style>
    @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap');

    html, body, [class*="css"] {
        font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
        color: #1E293B;
    }

    .block-container {
        padding-top: 1.8rem;
        padding-bottom: 2.5rem;
        max-width: 1320px;
    }

    /* Page headers */
    .page-header {
        border-bottom: 1px solid #E2E8F0;
        padding-bottom: 14px;
        margin-bottom: 22px;
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
        font-size: 0.95rem;
        margin-top: 5px;
        line-height: 1.5;
    }

    /* Patient Hero Banner */
    .patient-hero {
        background: linear-gradient(135deg, #0284C7 0%, #0F4C81 100%);
        color: white;
        padding: 28px 32px;
        border-radius: 16px;
        margin-bottom: 24px;
        box-shadow: 0 4px 14px rgba(2, 132, 199, 0.15);
    }
    .patient-hero h2 {
        color: white !important;
        font-size: 1.7rem;
        font-weight: 700;
        margin: 0 0 10px 0;
    }
    .patient-hero p {
        color: #E0F2FE;
        font-size: 0.98rem;
        margin: 0;
        max-width: 900px;
        line-height: 1.6;
    }

    /* Article Card */
    .article-card {
        background: #FFFFFF;
        border: 1px solid #E2E8F0;
        border-radius: 14px;
        padding: 22px;
        margin-bottom: 18px;
        transition: transform 0.15s ease, box-shadow 0.15s ease;
        box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
    }
    .article-card:hover {
        transform: translateY(-2px);
        box-shadow: 0 8px 20px rgba(0, 0, 0, 0.06);
        border-color: #CBD5E1;
    }
    .article-header {
        display: flex;
        align-items: center;
        justify-content: space-between;
        margin-bottom: 10px;
    }
    .article-tag {
        display: inline-block;
        padding: 3px 10px;
        border-radius: 20px;
        font-size: 0.76rem;
        font-weight: 600;
        letter-spacing: 0.3px;
    }
    .article-readtime {
        font-size: 0.8rem;
        color: #94A3B8;
    }
    .article-title {
        font-size: 1.18rem;
        font-weight: 700;
        color: #0F172A;
        margin: 8px 0 10px 0;
        line-height: 1.4;
    }
    .article-summary {
        font-size: 0.92rem;
        color: #475569;
        line-height: 1.55;
        margin-bottom: 14px;
    }
    .article-footer {
        display: flex;
        align-items: center;
        justify-content: space-between;
        font-size: 0.82rem;
        color: #64748B;
        border-top: 1px solid #F1F5F9;
        padding-top: 12px;
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

    /* Directive recommendations */
    .directive-box {
        border-radius: 10px;
        padding: 16px 20px;
        margin-top: 14px;
        margin-bottom: 22px;
        font-size: 0.95rem;
        line-height: 1.6;
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

    /* Badges */
    .badge-pill {
        display: inline-block;
        padding: 4px 12px;
        border-radius: 14px;
        font-size: 0.8rem;
        font-weight: 600;
    }
    .badge-high { background: #FEE2E2; color: #991B1B; }
    .badge-mod { background: #FEF3C7; color: #92400E; }
    .badge-low { background: #DCFCE7; color: #166534; }

    /* Standard metric card */
    .metric-standard-box {
        background: #F8FAFC;
        border: 1px solid #E2E8F0;
        border-radius: 10px;
        padding: 14px;
        margin-bottom: 12px;
    }
    </style>
    """,
    unsafe_allow_html=True,
)


@st.cache_resource(show_spinner="Đang khởi tạo mô hình y sinh chuẩn...")
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
# SIDEBAR: ROLE / PORTAL SELECTION
# ==========================================
st.sidebar.markdown("### 🫀 Nền Tảng CardioXAI")
st.sidebar.caption("Hệ thống Hỗ trợ Y tế Tim mạch Quốc gia")

portal_mode = st.sidebar.radio(
    "CHỌN VAI TRÒ SỬ DỤNG:",
    [
        "🫀 Dành cho Bệnh Nhân (Cộng đồng)",
        "👨‍⚕️ Dành cho Y Bác Sĩ (Lâm sàng & XAI)",
    ],
    index=0,
)

st.sidebar.markdown("---")

# ==============================================================================
# 1. PORTAL: DÀNH CHO BỆNH NHÂN (PATIENT HEALTH PORTAL)
# ==============================================================================
if "Bệnh Nhân" in portal_mode:
    # Patient Navigation Menu (Thanh công cụ)
    patient_nav = st.sidebar.radio(
        "THANH CÔNG CỤ BỆNH NHÂN:",
        [
            "🏠 Trang Chủ (Kiến thức & Bài báo)",
            "🩺 Chẩn Đoán (Tự đánh giá nguy cơ)",
            "📊 Bảng Chỉ Số Sức Khỏe Chuẩn",
            "🚑 Danh Bạ Cấp Cứu Khẩn Cấp",
        ],
        index=0,
    )

    # --------------------------------------------------------------------------
    # 1.1 TRANG CHỦ BỆNH NHÂN (HOME & ARTICLES)
    # --------------------------------------------------------------------------
    if patient_nav == "🏠 Trang Chủ (Kiến thức & Bài báo)":
        # Hero Banner
        st.markdown(
            """
            <div class="patient-hero">
                <h2>🫀 Vì Một Trái Tim Khỏe Mạnh Cho Bạn & Gia Đình</h2>
                <p>
                    Chào mừng bạn đến với Cổng thông tin & Tự chăm sóc sức khỏe tim mạch <b>CardioXAI</b>.
                    Tại đây, bạn có thể tra cứu kiến thức y khoa chính thống từ Hội Tim Mạch Việt Nam (VNHA) và Hiệp hội Tim mạch Hoa Kỳ (AHA),
                    tìm hiểu các nguyên nhân gây bệnh, cách nhận biết cơn đau ngực cấp cứu, và chế độ dinh dưỡng bảo vệ mạch máu trọn đời.
                </p>
            </div>
            """,
            unsafe_allow_html=True,
        )

        # 4 Quick Health Highlights
        c_hl1, c_hl2, c_hl3, c_hl4 = st.columns(4)
        with c_hl1:
            st.markdown(
                """
                <div class="card-metric" style="border-top: 3px solid #0284C7;">
                    <div class="card-label">Huyết áp lý tưởng</div>
                    <div class="card-value" style="font-size: 1.45rem; color: #0284C7;">< 120/80</div>
                    <div class="card-sub">mmHg (Đo lúc nghỉ)</div>
                </div>
                """,
                unsafe_allow_html=True,
            )
        with c_hl2:
            st.markdown(
                """
                <div class="card-metric" style="border-top: 3px solid #10B981;">
                    <div class="card-label">Mỡ máu Cholesterol</div>
                    <div class="card-value" style="font-size: 1.45rem; color: #10B981;">< 5.2</div>
                    <div class="card-sub">mmol/L (Toàn phần)</div>
                </div>
                """,
                unsafe_allow_html=True,
            )
        with c_hl3:
            st.markdown(
                """
                <div class="card-metric" style="border-top: 3px solid #F59E0B;">
                    <div class="card-label">Thể trạng BMI chuẩn</div>
                    <div class="card-value" style="font-size: 1.45rem; color: #F59E0B;">18.5 - 22.9</div>
                    <div class="card-sub">kg/m² (Chuẩn Châu Á)</div>
                </div>
                """,
                unsafe_allow_html=True,
            )
        with c_hl4:
            st.markdown(
                """
                <div class="card-metric" style="border-top: 3px solid #8B5CF6;">
                    <div class="card-label">Vận động thể lực</div>
                    <div class="card-value" style="font-size: 1.45rem; color: #8B5CF6;">150</div>
                    <div class="card-sub">Phút mỗi tuần</div>
                </div>
                """,
                unsafe_allow_html=True,
            )

        st.markdown("<br>", unsafe_allow_html=True)

        # Filter & Search Controls
        col_search, col_filter = st.columns([2, 1])
        with col_search:
            search_query = st.text_input("🔍 Tìm kiếm bài viết, triệu chứng, chế độ ăn, lời khuyên...", placeholder="Ví dụ: nhồi máu cơ tim, giảm muối, đau ngực, mỡ máu...")
        with col_filter:
            categories = get_categories()
            selected_cat = st.selectbox("📂 Lọc theo chuyên mục:", categories)

        articles = get_all_articles()

        # Filtering logic
        if selected_cat != "Tất cả":
            articles = [a for a in articles if a["category"] == selected_cat]
        if search_query.strip():
            q = search_query.strip().lower()
            articles = [
                a for a in articles
                if q in a["title"].lower() or q in a["summary"].lower() or q in a["content"].lower()
            ]

        st.markdown(f"**Hiển thị {len(articles)} bài viết chuyên sâu từ chuyên gia tim mạch:**")

        # Render Articles
        for art in articles:
            with st.container():
                st.markdown(
                    f"""
                    <div class="article-card">
                        <div class="article-header">
                            <span class="article-tag" style="background-color: {art['badge_color']}20; color: {art['badge_color']};">
                                {art['icon']} {art['category']}
                            </span>
                            <span class="article-readtime">⏱️ {art['read_time']} | 📅 {art['date']}</span>
                        </div>
                        <div class="article-title">{art['title']}</div>
                        <div class="article-summary">{art['summary']}</div>
                        <div class="article-footer">
                            <span>✍️ <b>Tác giả:</b> {art['author']}</span>
                        </div>
                    </div>
                    """,
                    unsafe_allow_html=True,
                )

                with st.expander(f"📖 Đọc chi tiết bài viết: '{art['title']}'"):
                    st.markdown("#### 📌 Các điểm cốt lõi cần nhớ:")
                    for pt in art["key_takeaways"]:
                        st.markdown(f"- **{pt}**")
                    st.markdown("---")
                    st.markdown(art["content"])
                    st.info(f"💡 *Nguồn tài liệu y khoa tham khảo: Hội Tim Mạch Việt Nam (VNHA) & Hiệp hội Tim mạch Châu Âu (ESC).*")

    # --------------------------------------------------------------------------
    # 1.2 CHẨN ĐOÁN DÀNH CHO BỆNH NHÂN (PATIENT SELF-ASSESSMENT)
    # --------------------------------------------------------------------------
    elif patient_nav == "🩺 Chẩn Đoán (Tự đánh giá nguy cơ)":
        st.markdown(
            """
            <div class="page-header">
                <h1 class="page-title">🩺 Tự Đánh Giá Nguy Cơ Tim Mạch Của Bạn</h1>
                <div class="page-subtitle">
                    Hệ thống ứng dụng trí tuệ nhân tạo để phân tích nguy cơ mắc bệnh tim mạch tiềm ẩn.
                    Hãy điền thông tin trung thực dựa trên kết quả khám sức khỏe gần nhất của bạn.
                </div>
            </div>
            """,
            unsafe_allow_html=True,
        )

        with st.form("patient_assessment_form"):
            st.markdown("##### 1. Thông tin cá nhân & Thể trạng")
            p_col1, p_col2, p_col3 = st.columns(3)
            with p_col1:
                p_name = st.text_input("Họ và tên của bạn:", value="Nguyễn Văn A")
                p_age = st.number_input("Tuổi của bạn:", min_value=18, max_value=90, value=48, step=1)
            with p_col2:
                p_gender_str = st.radio("Giới tính sinh học:", ["Nam", "Nữ"], horizontal=True)
                p_gender = 2 if p_gender_str == "Nam" else 1
                p_height = st.number_input("Chiều cao (cm):", min_value=130, max_value=210, value=165, step=1)
            with p_col3:
                p_weight = st.number_input("Cân nặng (kg):", min_value=35.0, max_value=160.0, value=68.0, step=0.5)
                # Live calculated BMI
                p_bmi = round(p_weight / ((p_height / 100.0) ** 2), 2)
                st.markdown(f"<div style='margin-top:28px;'><b>Chỉ số BMI dự tính:</b> <span style='font-size:1.15rem; color:#0284C7; font-weight:700;'>{p_bmi} kg/m²</span></div>", unsafe_allow_html=True)

            st.markdown("---")
            st.markdown("##### 2. Huyết áp & Kết quả xét nghiệm máu (Nếu có)")
            p_b1, p_b2, p_b3 = st.columns(3)
            with p_b1:
                p_ap_hi = st.number_input("Huyết áp tối đa (Tâm thu - mmHg):", min_value=80, max_value=230, value=130, step=5, help="Số đo phía trên trên máy đo huyết áp tại nhà.")
                p_ap_lo = st.number_input("Huyết áp tối thiểu (Tâm trương - mmHg):", min_value=50, max_value=140, value=85, step=5, help="Số đo phía dưới trên máy đo huyết áp tại nhà.")
            with p_b2:
                p_chol_dict = {
                    1: "Bình thường (< 5.2 mmol/L)",
                    2: "Hơi cao / Ranh giới (5.2 - 6.2 mmol/L)",
                    3: "Rất cao (> 6.2 mmol/L)"
                }
                p_chol = st.selectbox("Mức Cholesterol toàn phần trong máu:", [1, 2, 3], format_func=lambda x: p_chol_dict[x], help="Xem trong phiếu xét nghiệm sinh hóa máu.")
            with p_b3:
                p_gluc_dict = {
                    1: "Bình thường (< 5.6 mmol/L)",
                    2: "Tiền đái tháo đường (5.6 - 6.9 mmol/L)",
                    3: "Đái tháo đường (≥ 7.0 mmol/L)"
                }
                p_gluc = st.selectbox("Đường huyết lúc đói (Glucose):", [1, 2, 3], format_func=lambda x: p_gluc_dict[x], help="Chỉ số xét nghiệm đường máu khi chưa ăn sáng.")

            st.markdown("---")
            st.markdown("##### 3. Thói quen sinh hoạt hàng ngày")
            p_s1, p_s2, p_s3 = st.columns(3)
            with p_s1:
                p_smoke = 1 if st.checkbox("Có hút thuốc lá (chủ động hoặc thường xuyên)") else 0
            with p_s2:
                p_alco = 1 if st.checkbox("Có uống rượu bia hàng tuần") else 0
            with p_s3:
                p_active = 1 if st.checkbox("Có tập thể dục đều đặn (≥ 30 phút/ngày)", value=True) else 0

            submitted = st.form_submit_button("🔬 PHÂN TÍCH NGUY CƠ TIM MẠCH", use_container_width=True)

        if submitted:
            # Prepare patient features
            patient_raw = {
                "age": float(p_age),
                "height": float(p_height),
                "weight": float(p_weight),
                "ap_hi": float(p_ap_hi),
                "ap_lo": float(p_ap_lo),
                "bmi": float(p_bmi),
                "gender": int(p_gender),
                "cholesterol": int(p_chol),
                "gluc": int(p_gluc),
                "smoke": int(p_smoke),
                "alco": int(p_alco),
                "active": int(p_active),
            }

            p_df_unscaled = pd.DataFrame([patient_raw])
            p_df_scaled = p_df_unscaled.copy()
            p_df_scaled[NUMERICAL_FEATURES] = scaler.transform(p_df_unscaled[NUMERICAL_FEATURES])

            p_prob = float(model.predict_proba(p_df_scaled)[0, 1])

            st.markdown("<br>", unsafe_allow_html=True)
            st.markdown("### 📊 Kết Quả Đánh Giá Nguy Cơ Sức Khỏe Của Bạn")

            if p_prob >= 0.65:
                r_level = "NGUY CƠ CAO"
                r_color = "#DC2626"
                r_bg = "dir-high"
                r_guide = """
                **Khuyến cáo khẩn cấp:** Nguy cơ tim mạch của bạn đang ở mức cao. Các chỉ số cho thấy thành mạch máu và tim đang chịu áp lực lớn.
                * **Hành động ngay:** Bạn nên đến bệnh viện hoặc phòng khám chuyên khoa tim mạch trong tuần này để được bác sĩ chỉ định đo điện tim (ECG), siêu âm tim và xét nghiệm mỡ máu chuyên sâu.
                * **Chế độ ăn:** Cắt giảm muối ăn ngay hôm nay (không chấm nước mắm, không ăn đồ muối chua, thịt hộp).
                * **Thuốc lá & Rượu:** Ngừng ngay thuốc lá nếu đang hút vì khói thuốc làm co thắt mạch vành đột ngột.
                """
            elif p_prob >= 0.35:
                r_level = "NGUY CƠ TRUNG BÌNH (TIỀM ẨN)"
                r_color = "#D97706"
                r_bg = "dir-mod"
                r_guide = """
                **Khuyến cáo:** Bạn đang có một số yếu tố nguy cơ tim mạch cần được can thiệp sớm để tránh tiến triển thành bệnh lý mạn tính.
                * **Hành động:** Đo huyết áp tại nhà 2 lần/tuần và ghi chép nhật ký theo dõi.
                * **Tập luyện:** Duy trì đi bộ nhanh hoặc đạp xe tối thiểu 30 phút mỗi ngày.
                * **Dinh dưỡng:** Tăng cường rau xanh, cá hồi/cá thu, các loại hạt dinh dưỡng (hạnh nhân, óc chó) và hạn chế thịt mỡ.
                """
            else:
                r_level = "NGUY CƠ THẤP (AN TOÀN)"
                r_color = "#16A34A"
                r_bg = "dir-low"
                r_guide = """
                **Chúc mừng bạn!** Trái tim của bạn hiện đang có các chỉ số nằm trong vùng bảo vệ an toàn.
                * **Duy trì lối sống:** Tiếp tục duy trì chế độ dinh dưỡng lành mạnh, vận động thể chất thường xuyên và giữ tinh thần lạc quan, thư thái.
                * **Khám định kỳ:** Hãy khám sức khỏe tổng quát 1 lần mỗi năm để kiểm tra định kỳ huyết áp và đường máu.
                """

            c_res1, c_res2, c_res3 = st.columns(3)
            with c_res1:
                st.markdown(
                    f"""
                    <div class="card-metric">
                        <div class="card-label">Điểm Nguy Cơ Tim Mạch</div>
                        <div class="card-value" style="color: {r_color};">{p_prob:.1%}</div>
                        <div class="card-sub">Thang đo trí tuệ nhân tạo (XGBoost)</div>
                    </div>
                    """,
                    unsafe_allow_html=True,
                )
            with c_res2:
                st.markdown(
                    f"""
                    <div class="card-metric">
                        <div class="card-label">Phân Tầng An Toàn</div>
                        <div class="card-value" style="color: {r_color}; font-size: 1.45rem;">{r_level}</div>
                        <div class="card-sub">Khuyến nghị từ Hội Tim Mạch</div>
                    </div>
                    """,
                    unsafe_allow_html=True,
                )
            with c_res3:
                st.markdown(
                    f"""
                    <div class="card-metric">
                        <div class="card-label">Thể Trạng BMI</div>
                        <div class="card-value">{p_bmi} <span style="font-size:1rem; font-weight:500;">kg/m²</span></div>
                        <div class="card-sub">Cân nặng {p_weight}kg / Cao {p_height}cm</div>
                    </div>
                    """,
                    unsafe_allow_html=True,
                )

            st.markdown(
                f"""
                <div class="directive-box {r_bg}">
                    <h4>Lời Khuyên Dành Riêng Cho Bạn ({p_name}):</h4>
                    {r_guide}
                </div>
                """,
                unsafe_allow_html=True,
            )

            # Auto save record
            save_assessment(p_name, patient_raw, p_prob, r_level, f"Tự đánh giá bệnh nhân: {r_level}")
            st.success("✅ Đã tự động lưu phiếu đánh giá vào nhật ký theo dõi sức khỏe của bạn!")

    # --------------------------------------------------------------------------
    # 1.3 BẢNG CHỈ SỐ SỨC KHỎE CHUẨN
    # --------------------------------------------------------------------------
    elif patient_nav == "📊 Bảng Chỉ Số Sức Khỏe Chuẩn":
        st.markdown(
            """
            <div class="page-header">
                <h1 class="page-title">📊 Bảng Tra Cứu Các Chỉ Số Sức Khỏe Tim Mạch Chuẩn</h1>
                <div class="page-subtitle">Dựa trên khuyến cáo chính thức của Hội Tim Mạch Việt Nam & Hiệp hội Tim mạch Châu Âu (ESC).</div>
            </div>
            """,
            unsafe_allow_html=True,
        )

        for met in STANDARD_HEALTH_METRICS:
            st.markdown(
                f"""
                <div class="metric-standard-box">
                    <h4 style="margin: 0 0 6px 0; color: #0F172A;">{met['name']} ({met['unit']})</h4>
                    <div style="font-size: 0.9rem; color: #475569; margin-bottom: 8px;">💡 <b>Lời khuyên đo:</b> {met['advice']}</div>
                    <div style="display: flex; gap: 15px; flex-wrap: wrap;">
                        <span style="background: #DCFCE7; color: #166534; padding: 4px 12px; border-radius: 6px; font-size: 0.85rem; font-weight: 600;">
                            ✓ Vùng Tối Ưu: {met['optimal']}
                        </span>
                        <span style="background: #FEF3C7; color: #92400E; padding: 4px 12px; border-radius: 6px; font-size: 0.85rem; font-weight: 600;">
                            ⚠️ Cần Chú Ý: {met['warning']}
                        </span>
                        <span style="background: #FEE2E2; color: #991B1B; padding: 4px 12px; border-radius: 6px; font-size: 0.85rem; font-weight: 600;">
                            🚨 Mức Nguy Hiểm: {met['danger']}
                        </span>
                    </div>
                </div>
                """,
                unsafe_allow_html=True,
            )

    # --------------------------------------------------------------------------
    # 1.4 DANH BẠ CẤP CỨU KHẨN CẤP
    # --------------------------------------------------------------------------
    elif patient_nav == "🚑 Danh Bạ Cấp Cứu Khẩn Cấp":
        st.markdown(
            """
            <div class="page-header">
                <h1 class="page-title">🚑 Đường Dây Nóng Cấp Cứu & Cơ Sở Tim Mạch Uy Tín</h1>
                <div class="page-subtitle">Lưu lại ngay những số điện thoại khẩn cấp khi người thân có dấu hiệu đau ngực dữ dội, khó thở hoặc nghi ngờ nhồi máu cơ tim.</div>
            </div>
            """,
            unsafe_allow_html=True,
        )

        for c in EMERGENCY_CONTACTS:
            st.markdown(
                f"""
                <div class="card-metric" style="margin-bottom: 12px; display: flex; align-items: center; justify-content: space-between;">
                    <div>
                        <div style="font-size: 1.1rem; font-weight: 700; color: #0F172A;">{c['name']}</div>
                        <div style="font-size: 0.88rem; color: #64748B; margin-top: 2px;">{c['desc']}</div>
                    </div>
                    <div>
                        <a href="tel:{c['phone'].replace(' ', '')}" style="background: #EF4444; color: white; padding: 8px 18px; border-radius: 8px; font-weight: 700; text-decoration: none; display: inline-block;">
                            📞 {c['phone']}
                        </a>
                    </div>
                </div>
                """,
                unsafe_allow_html=True,
            )


# ==============================================================================
# 2. PORTAL: DÀNH CHO Y BÁC SĨ (CLINICAL & EXPLAINABLE AI)
# ==============================================================================
else:
    st.sidebar.markdown("**Hồ sơ khám lâm sàng chuyên sâu:**")

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

    # Header for Clinical Portal
    st.markdown(
        """
        <div class="page-header">
            <h1 class="page-title">👨‍⚕️ Cổng Hỗ Trợ Quyết Định Lâm Sàng Tim Mạch (CardioXAI Pro)</h1>
            <div class="page-subtitle">Hội chẩn y khoa bằng mô hình AI minh bạch (XGBoost tối ưu kết hợp SHAP Waterfall & LIME Rules)</div>
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

    # Tabs for Doctor
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
                Biểu đồ <b>SHAP Waterfall</b> thể hiện đóng góp biên của từng chỉ số y sinh đối với ca bệnh này:
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
