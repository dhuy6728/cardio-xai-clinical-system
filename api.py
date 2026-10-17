"""
FastAPI Production Microservice for Cardiovascular Risk Prediction & Explainable AI.
Engineered for mobile applications (Flutter / React Native), web clients, and clinical databases.
"""

import sys
from pathlib import Path
from typing import Any, Dict, List, Optional

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
    get_patient_history,
    get_record_with_xai,
    save_patient_record,
)
from src.explain import CLINICAL_FEATURE_LABELS
from src.schemas import (
    FeatureContribution,
    FullAnalysisResponse,
    LimeRule,
    PatientInput,
    PredictionResult,
    ShapExplanationResponse,
)

# Initialize FastAPI app
app = FastAPI(
    title="CardioXAI Clinical Decision Support API",
    description="RESTful Microservice providing Real-time Cardiovascular Disease Risk Prediction with SHAP & LIME XAI Explanations.",
    version="1.0.0",
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
        rec = "Nguy cơ tim mạch rất cao. Chỉ định khám chuyên khoa tim mạch, đo điện tâm đồ (ECG) và can thiệp hạ áp/hạ lipid máu ngay lập tức."
    elif risk_prob >= 0.35:
        risk_level = "MODERATE"
        rec = "Nguy cơ tim mạch trung bình. Khuyến cáo theo dõi huyết áp tại nhà 2 lần/ngày, giảm muối và điều chỉnh cân nặng."
    else:
        risk_level = "LOW"
        rec = "Nguy cơ tim mạch thấp. Duy trì chế độ ăn lành mạnh và tập luyện thể dục ít nhất 150 phút/tuần."

    return risk_level, bmi_cat, rec


@app.get("/", tags=["System"])
def root():
    """Health check and API overview."""
    return {
        "system": "CardioXAI Clinical Decision Support System",
        "status": "ONLINE",
        "model": "XGBoost (Optuna Tuned)",
        "xai_frameworks": ["TreeSHAP", "LIME"],
        "endpoints": {
            "predict": "/api/v1/predict",
            "explain_shap": "/api/v1/explain/shap",
            "explain_lime": "/api/v1/explain/lime",
            "full_analysis": "/api/v1/analyze",
            "history": "/api/v1/records",
            "interactive_docs": "/docs",
        },
    }


@app.post("/api/v1/predict", response_model=PredictionResult, tags=["Clinical AI"])
def predict_cardio_risk(patient: PatientInput):
    """
    Sub-15ms real-time inference returning calibrated cardiovascular disease risk probability.
    """
    df_unscaled, df_scaled, bmi = _prepare_patient_dfs(patient)

    prob = float(MODEL.predict_proba(df_scaled)[0, 1])
    pred_class = int(prob >= 0.5)
    risk_level, bmi_cat, rec = _get_clinical_recommendation(prob, bmi, patient.ap_hi)

    return PredictionResult(
        risk_probability=round(prob, 4),
        risk_percentage=f"{prob:.1%}",
        risk_level=risk_level,
        prediction=pred_class,
        bmi=bmi,
        bmi_category=bmi_cat,
        recommendation=rec,
    )


@app.post("/api/v1/explain/shap", response_model=ShapExplanationResponse, tags=["Explainable AI"])
def explain_shap(patient: PatientInput):
    """
    Returns exact Shapley values and feature contributions for native mobile Waterfall charting.
    """
    df_unscaled, df_scaled, _ = _prepare_patient_dfs(patient)

    shap_vals = SHAP_EXPLAINER(df_scaled)
    base_val = float(shap_vals.base_values[0])
    values = shap_vals.values[0]

    contributions = []
    for col, shap_v in zip(df_scaled.columns, values):
        actual_v = float(df_unscaled[col].iloc[0])
        display_label = CLINICAL_FEATURE_LABELS.get(col, col)

        impact = "INCREASES_RISK" if shap_v > 0.05 else ("PROTECTIVE" if shap_v < -0.05 else "NEUTRAL")
        contributions.append(
            FeatureContribution(
                feature=col,
                display_name=display_label,
                actual_value=actual_v,
                shap_value=round(float(shap_v), 4),
                impact=impact,
            )
        )

    # Sort descending by absolute SHAP impact
    contributions.sort(key=lambda x: abs(x.shap_value), reverse=True)

    return ShapExplanationResponse(
        base_value=round(base_val, 4),
        prediction_value=round(float(base_val + sum(values)), 4),
        contributions=contributions,
    )


@app.post("/api/v1/explain/lime", response_model=List[LimeRule], tags=["Explainable AI"])
def explain_lime(patient: PatientInput, num_features: int = 8):
    """
    Returns discrete local decision rules extracted by LIME surrogate modeling.
    """
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
    """
    Combined endpoint performing Prediction + SHAP + LIME and persisting the record to the SQL database.
    Ideal for mobile apps to conserve network bandwidth and battery.
    """
    # 1. Prediction
    pred_res = predict_cardio_risk(patient)

    # 2. SHAP
    shap_res = explain_shap(patient)

    # 3. LIME
    lime_res = explain_lime(patient, num_features=8)

    # 4. Save to SQL Database
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
    """Retrieves patient historical records from SQL database for time-series longitudinal tracking."""
    return get_patient_history(user_id=user_id, limit=limit)


@app.get("/api/v1/records/{record_id}", tags=["Clinical Database"])
def get_record_detail(record_id: int):
    """Retrieves a single clinical record alongside its complete XAI audit trail."""
    rec = get_record_with_xai(record_id)
    if not rec:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Record {record_id} not found")
    return rec
