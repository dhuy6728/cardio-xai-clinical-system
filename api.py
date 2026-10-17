"""
FastAPI Production Microservice for Cardiovascular Risk Prediction & Explainable AI.
Engineered for mobile applications (Flutter / React Native), web clients, and clinical databases.
Now includes full Authentication (Register, Login, Change Password, Firebase Sync).
"""

import sys
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

import cloudpickle
import joblib
import numpy as np
import pandas as pd
import shap
from fastapi import FastAPI, HTTPException, Query, status
from fastapi.middleware.cors import CORSMiddleware

# Ensure project root is in sys.path
BASE_DIR = Path(__file__).resolve().parent
if str(BASE_DIR) not in sys.path:
    sys.path.insert(0, str(BASE_DIR))

from src.config import (
    BEST_MODEL_FILE,
    MODELS_DIR,
    NUMERICAL_FEATURES,
    SCALER_FILE,
    TRAIN_DATA_FILE,
)
from src.database import (
    authenticate_user,
    get_patient_history,
    get_record_with_xai,
    register_user,
    save_patient_record,
    update_user_password,
)
from src.explain import CLINICAL_FEATURE_LABELS
from src.schemas import (
    AuthResponse,
    ChangePasswordRequest,
    FeatureContribution,
    FullAnalysisResponse,
    LimeRule,
    PatientInput,
    PredictionResult,
    ShapExplanationResponse,
    UserLoginRequest,
    UserRegisterRequest,
    UserResponse,
)

# Initialize FastAPI app
app = FastAPI(
    title="CardioXAI Clinical Decision Support API",
    description="RESTful Microservice providing Real-time Cardiovascular Disease Risk Prediction with SHAP & LIME XAI Explanations.",
    version="1.1.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

# Enable Cross-Origin Resource Sharing (CORS) for Mobile and Web Clients
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Global artifacts loaded at startup
MODEL = None
SCALER = None
SHAP_EXPLAINER = None
LIME_EXPLAINER = None


@app.on_event("startup")
def startup_event():
    """Loads and warms up machine learning model and XAI explainers once during cold-start."""
    global MODEL, SCALER, SHAP_EXPLAINER, LIME_EXPLAINER

    if not BEST_MODEL_FILE.exists() or not SCALER_FILE.exists():
        raise RuntimeError("Model or Scaler artifacts missing. Ensure Phase 2 has executed.")

    MODEL = joblib.load(BEST_MODEL_FILE)
    SCALER = joblib.load(SCALER_FILE)

    shap_path = MODELS_DIR / "shap_explainer.joblib"
    if shap_path.exists():
        SHAP_EXPLAINER = joblib.load(shap_path)
    else:
        SHAP_EXPLAINER = shap.TreeExplainer(MODEL)

    lime_path = MODELS_DIR / "lime_explainer.pkl"
    if lime_path.exists():
        with open(lime_path, "rb") as f:
            LIME_EXPLAINER = cloudpickle.load(f)
    else:
        import lime.lime_tabular
        train_df = pd.read_csv(TRAIN_DATA_FILE)
        X_train = train_df.drop(columns=["cardio"])
        LIME_EXPLAINER = lime.lime_tabular.LimeTabularExplainer(
            training_data=X_train.values,
            feature_names=list(X_train.columns),
            class_names=["Healthy", "Cardio Risk"],
            mode="classification",
            random_state=42,
        )


# ==========================================
# AUTHENTICATION ENDPOINTS (MOBILE / WEB)
# ==========================================
@app.post("/api/v1/auth/register", response_model=AuthResponse, tags=["Authentication & Firebase"])
def auth_register(req: UserRegisterRequest):
    """Registers a new patient or doctor account in SQL database (Firebase synced)."""
    try:
        user_data = register_user(
            email=req.email,
            password=req.password,
            full_name=req.full_name,
            firebase_uid=req.firebase_uid,
            phone=req.phone,
        )
        return AuthResponse(
            status="success",
            message="Đăng ký tài khoản thành công!",
            user=UserResponse(**user_data),
        )
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))


@app.post("/api/v1/auth/login", response_model=AuthResponse, tags=["Authentication & Firebase"])
def auth_login(req: UserLoginRequest):
    """Authenticates user credentials."""
    user = authenticate_user(email=req.email, password=req.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Email hoặc mật khẩu không chính xác!",
        )
    return AuthResponse(
        status="success",
        message="Đăng nhập thành công!",
        user=UserResponse(**user),
    )


@app.post("/api/v1/auth/change-password", tags=["Authentication & Firebase"])
def auth_change_password(req: ChangePasswordRequest):
    """Changes password after verifying old password."""
    success = update_user_password(
        email=req.email,
        old_password=req.old_password,
        new_password=req.new_password,
    )
    if not success:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Mật khẩu hiện tại không đúng hoặc email không tồn tại!",
        )
    return {"status": "success", "message": "Đổi mật khẩu thành công!"}


# ==========================================
# CLINICAL PREDICTION & EXPLAINABLE AI
# ==========================================
def _prepare_patient_dfs(patient: PatientInput) -> Tuple[pd.DataFrame, pd.DataFrame, float]:
    """Helper to compute BMI and return both unscaled and scaled patient feature vectors."""
    bmi = round(patient.weight / ((patient.height / 100.0) ** 2), 2)

    raw_dict = {
        "age": patient.age,
        "height": patient.height,
        "weight": patient.weight,
        "ap_hi": patient.ap_hi,
        "ap_lo": patient.ap_lo,
        "bmi": bmi,
        "gender": patient.gender,
        "cholesterol": patient.cholesterol,
        "gluc": patient.gluc,
        "smoke": patient.smoke,
        "alco": patient.alco,
        "active": patient.active,
    }

    df_unscaled = pd.DataFrame([raw_dict])
    df_scaled = df_unscaled.copy()
    df_scaled[NUMERICAL_FEATURES] = SCALER.transform(df_unscaled[NUMERICAL_FEATURES])

    return df_unscaled, df_scaled, bmi


def _get_clinical_recommendation(risk_prob: float, bmi: float, ap_hi: int) -> Tuple[str, str, str]:
    """Derives clinical risk level, category, and action-oriented medical guidance."""
    if bmi < 18.5:
        bmi_cat = "Thiếu cân"
    elif bmi < 25.0:
        bmi_cat = "Bình thường"
    elif bmi < 30.0:
        bmi_cat = "Tiền béo phì"
    else:
        bmi_cat = "Béo phì"

    if risk_prob >= 0.65:
        risk_level = "HIGH"
        recommendation = (
            f"Bệnh nhân thuộc nhóm NGUY CƠ CAO ({risk_prob:.1%}). Cần chỉ định khẩn: "
            "Điện tâm đồ (ECG), siêu âm tim Doppler và kiểm soát huyết áp/statin tích cực."
        )
    elif risk_prob >= 0.35:
        risk_level = "MODERATE"
        recommendation = (
            f"Bệnh nhân có NGUY CƠ TRUNG BÌNH ({risk_prob:.1%}). Khuyến nghị theo dõi "
            "huyết áp lưu động định kỳ, xét nghiệm lipid máu 3 tháng/lần và điều chỉnh lối sống."
        )
    else:
        risk_level = "LOW"
        recommendation = (
            f"Bệnh nhân thuộc nhóm NGUY CƠ THẤP ({risk_prob:.1%}). Khuyến khích duy trì "
            "thói quen thể lực đều đặn và khám định kỳ mỗi 12 tháng."
        )

    return risk_level, bmi_cat, recommendation


@app.get("/", tags=["System"])
def root():
    return {
        "service": "CardioXAI Clinical Decision Support Microservice",
        "status": "online",
        "version": "1.1.0",
        "endpoints": {
            "docs": "/docs",
            "auth_register": "POST /api/v1/auth/register",
            "auth_login": "POST /api/v1/auth/login",
            "auth_change_password": "POST /api/v1/auth/change-password",
            "full_analysis": "POST /api/v1/analyze",
            "clinical_records": "GET /api/v1/records",
        },
    }


@app.post("/api/v1/predict", response_model=PredictionResult, tags=["Clinical AI"])
def predict_cardio_risk(patient: PatientInput):
    """Real-time Cardiovascular Risk Inference using Champion XGBoost model."""
    df_unscaled, df_scaled, bmi = _prepare_patient_dfs(patient)
    risk_prob = float(MODEL.predict_proba(df_scaled)[0, 1])
    risk_level, bmi_cat, recommendation = _get_clinical_recommendation(risk_prob, bmi, patient.ap_hi)

    return PredictionResult(
        risk_probability=round(risk_prob, 4),
        risk_percentage=f"{risk_prob:.1%}",
        risk_level=risk_level,
        prediction=int(risk_prob >= 0.5),
        bmi=bmi,
        bmi_category=bmi_cat,
        recommendation=recommendation,
    )


@app.post("/api/v1/explain/shap", response_model=ShapExplanationResponse, tags=["Explainable AI"])
def explain_shap(patient: PatientInput):
    """Calculates Shapley additive feature attributions."""
    df_unscaled, df_scaled, _ = _prepare_patient_dfs(patient)
    shap_vals = SHAP_EXPLAINER(df_scaled)

    base_val = float(shap_vals.base_values[0])
    pred_val = float(shap_vals.values[0].sum() + base_val)

    contributions = []
    for col in df_scaled.columns:
        val_shap = float(shap_vals.values[0][df_scaled.columns.get_loc(col)])
        actual_val = float(df_unscaled[col].iloc[0])
        display_name = CLINICAL_FEATURE_LABELS.get(col, col)

        if val_shap > 0.05:
            impact = "INCREASES_RISK"
        elif val_shap < -0.05:
            impact = "PROTECTIVE"
        else:
            impact = "NEUTRAL"

        contributions.append(
            FeatureContribution(
                feature=col,
                display_name=display_name,
                actual_value=actual_val,
                shap_value=round(val_shap, 4),
                impact=impact,
            )
        )

    contributions.sort(key=lambda x: abs(x.shap_value), reverse=True)

    return ShapExplanationResponse(
        base_value=round(base_val, 4),
        prediction_value=round(pred_val, 4),
        contributions=contributions,
    )


@app.post("/api/v1/explain/lime", response_model=List[LimeRule], tags=["Explainable AI"])
def explain_lime(patient: PatientInput, num_features: int = Query(6, ge=3, le=12)):
    """Computes Local Interpretable Model-agnostic Explanations."""
    _, df_scaled, _ = _prepare_patient_dfs(patient)

    exp = LIME_EXPLAINER.explain_instance(
        df_scaled.iloc[0].values,
        MODEL.predict_proba,
        num_features=int(num_features),
        labels=[1],
    )

    rules = []
    for rule_str, weight in exp.as_list(label=1):
        impact = "INCREASES_RISK" if weight > 0 else "PROTECTIVE"
        rules.append(
            LimeRule(
                rule=rule_str,
                weight=round(float(weight), 4),
                impact=impact,
            )
        )

    return rules


@app.post("/api/v1/analyze", response_model=FullAnalysisResponse, tags=["Mobile One-Shot API"])
def full_patient_analysis(patient: PatientInput, save_to_db: bool = True):
    """Combined endpoint for Prediction + SHAP + LIME and persistence to SQL database."""
    pred_res = predict_cardio_risk(patient)
    shap_res = explain_shap(patient)
    lime_res = explain_lime(patient, num_features=8)

    record_id = None
    if save_to_db:
        raw_dict = patient.model_dump() if hasattr(patient, "model_dump") else patient.dict()
        raw_dict["bmi"] = pred_res.bmi
        record_id = save_patient_record(
            patient_data=raw_dict,
            risk_prob=pred_res.risk_probability,
            risk_level=pred_res.risk_level,
            recommendation=pred_res.recommendation,
            shap_data=shap_res.model_dump() if hasattr(shap_res, "model_dump") else shap_res.dict(),
            lime_data=[r.model_dump() if hasattr(r, "model_dump") else r.dict() for r in lime_res],
            user_id=patient.user_id,
            patient_name=patient.patient_name or "Bệnh nhân",
        )

    return FullAnalysisResponse(
        record_id=record_id,
        prediction=pred_res,
        shap_explanation=shap_res,
        lime_rules=lime_res,
    )


@app.get("/api/v1/records", tags=["Clinical Database"])
def list_records(user_id: Optional[int] = None, limit: int = Query(50, ge=1, le=200)):
    """Retrieves patient historical records from SQL database."""
    return get_patient_history(user_id=user_id, limit=limit)


@app.get("/api/v1/records/{record_id}", tags=["Clinical Database"])
def get_record_detail(record_id: int):
    """Retrieves a single clinical record alongside its complete XAI audit trail."""
    rec = get_record_with_xai(record_id)
    if not rec:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Record {record_id} not found")
    return rec


@app.get("/api/v1/articles", tags=["Patient Health Portal"])
def get_patient_articles(category: Optional[str] = None):
    """Returns curated patient cardiovascular health articles, filtered optionally by category."""
    from src.articles import get_all_articles
    articles = get_all_articles()
    if category and category != "Tất cả":
        articles = [a for a in articles if a["category"] == category or a.get("category_id") == category]
    return articles


@app.get("/api/v1/articles/{article_id}", tags=["Patient Health Portal"])
def get_patient_article(article_id: str):
    """Returns full content of a specific cardiovascular health article."""
    from src.articles import get_article_by_id
    art = get_article_by_id(article_id)
    if not art:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Article {article_id} not found")
    return art


@app.get("/api/v1/health-metrics", tags=["Patient Health Portal"])
def get_standard_health_metrics():
    """Returns standard medical target metrics (BP, Cholesterol, Glucose, BMI) for patient reference."""
    from src.articles import STANDARD_HEALTH_METRICS
    return STANDARD_HEALTH_METRICS


@app.get("/api/v1/emergency-contacts", tags=["Patient Health Portal"])
def get_emergency_contacts():
    """Returns emergency hotline numbers and specialized cardiovascular centers."""
    from src.articles import EMERGENCY_CONTACTS
    return EMERGENCY_CONTACTS

