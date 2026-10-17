"""
Pydantic Data Contracts & Schemas for FastAPI API Endpoints.
"""

from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field


class PatientInput(BaseModel):
    """Patient biomedical features required for risk assessment."""
    age: float = Field(..., ge=18, le=100, description="Age in years", example=52.0)
    gender: int = Field(..., ge=1, le=2, description="1: Female, 2: Male", example=2)
    height: float = Field(..., ge=100, le=230, description="Height in cm", example=168.0)
    weight: float = Field(..., ge=30, le=200, description="Weight in kg", example=78.5)
    ap_hi: int = Field(..., ge=90, le=240, description="Systolic Blood Pressure (mmHg)", example=140)
    ap_lo: int = Field(..., ge=60, le=140, description="Diastolic Blood Pressure (mmHg)", example=90)
    cholesterol: int = Field(..., ge=1, le=3, description="1: Normal, 2: Above Normal, 3: Very High", example=2)
    gluc: int = Field(..., ge=1, le=3, description="1: Normal, 2: Above Normal, 3: Very High", example=1)
    smoke: int = Field(0, ge=0, le=1, description="Smoking status: 0: No, 1: Yes", example=0)
    alco: int = Field(0, ge=0, le=1, description="Alcohol intake: 0: No, 1: Yes", example=0)
    active: int = Field(1, ge=0, le=1, description="Physical activity: 0: No, 1: Yes", example=1)

    patient_name: Optional[str] = Field("Bệnh nhân ẩn danh", description="Patient display name")
    user_id: Optional[int] = Field(None, description="Optional associated user ID")


class PredictionResult(BaseModel):
    risk_probability: float = Field(..., description="Estimated probability of Cardiovascular Disease [0.0 - 1.0]")
    risk_percentage: str = Field(..., description="Risk formatted as percentage")
    risk_level: str = Field(..., description="LOW, MODERATE, or HIGH")
    prediction: int = Field(..., description="0: Healthy, 1: Cardiovascular Disease")
    bmi: float = Field(..., description="Calculated Body Mass Index (kg/m²)")
    bmi_category: str = Field(..., description="WHO Category: Normal, Overweight, Obese")
    recommendation: str = Field(..., description="Automated clinical recommendation")


class FeatureContribution(BaseModel):
    feature: str
    display_name: str
    actual_value: float
    shap_value: float
    impact: str  # 'INCREASES_RISK', 'PROTECTIVE', 'NEUTRAL'


class ShapExplanationResponse(BaseModel):
    base_value: float
    prediction_value: float
    contributions: List[FeatureContribution]


class LimeRule(BaseModel):
    rule: str
    weight: float
    impact: str


class FullAnalysisResponse(BaseModel):
    record_id: Optional[int]
    prediction: PredictionResult
    shap_explanation: ShapExplanationResponse
    lime_rules: List[LimeRule]
