"""
Phase 3: Explainable AI (XAI) Integration with SHAP & LIME.

Responsibilities:
1. Global Interpretability:
   - SHAP Summary Beeswarm Plot: Population-level feature impact distribution.
   - SHAP Global Feature Importance Bar Plot: Mean absolute SHAP value ranking.
   - SHAP Dependence Plots: Non-linear interaction dynamics for Blood Pressure (ap_hi, ap_lo) and BMI.
2. Local Interpretability (Patient-Level):
   - SHAP Waterfall Plots: Clinical risk factor breakdown for individual patients (High Risk vs. Low Risk).
   - LIME Tabular Explainer: Local surrogate model extracting discrete decision rules.
3. Production API for Phase 4:
   - Reusable explainers and helper functions engineered for real-time Streamlit dashboard rendering.
"""

import argparse
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

import joblib
import lime
import lime.lime_tabular
import matplotlib
matplotlib.use("Agg")  # Non-interactive backend for headless figure generation
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import shap

# Ensure local imports work when running as script
if str(Path(__file__).resolve().parent.parent) not in sys.path:
    sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from src.config import (
    BEST_MODEL_FILE,
    FIGURES_DIR,
    MODELS_DIR,
    NUMERICAL_FEATURES,
    RANDOM_STATE,
    SCALER_FILE,
    TARGET_COLUMN,
    TEST_DATA_FILE,
    TRAIN_DATA_FILE,
)
from src.utils import load_artifact, setup_logger

logger = setup_logger("XAI_Integration")

# Clean clinical feature display labels
CLINICAL_FEATURE_LABELS = {
    "age": "Age (years)",
    "height": "Height (cm)",
    "weight": "Weight (kg)",
    "ap_hi": "Systolic BP (mmHg)",
    "ap_lo": "Diastolic BP (mmHg)",
    "bmi": "BMI (kg/m²)",
    "gender": "Gender (1:F, 2:M)",
    "cholesterol": "Cholesterol (1-3)",
    "gluc": "Glucose (1-3)",
    "smoke": "Smoking (0/1)",
    "alco": "Alcohol (0/1)",
    "active": "Physical Activity (0/1)",
}


def load_model_and_data() -> Tuple[Any, Any, pd.DataFrame, pd.Series, pd.DataFrame, pd.Series, pd.DataFrame]:
    """Loads champion model, scaler, and datasets with both scaled and unscaled feature representations."""
    if not BEST_MODEL_FILE.exists():
        raise FileNotFoundError(
            f"Model not found at {BEST_MODEL_FILE}. Please execute Phase 2 (python src/train.py) first."
        )

    model = load_artifact(BEST_MODEL_FILE)
    scaler = load_artifact(SCALER_FILE)

    train_df = pd.read_csv(TRAIN_DATA_FILE)
    test_df = pd.read_csv(TEST_DATA_FILE)

    X_train_scaled = train_df.drop(columns=[TARGET_COLUMN])
    y_train = train_df[TARGET_COLUMN]

    X_test_scaled = test_df.drop(columns=[TARGET_COLUMN])
    y_test = test_df[TARGET_COLUMN]

    # Reconstruct original unscaled physical values for clinical interpretability
    X_test_unscaled = X_test_scaled.copy()
    X_test_unscaled[NUMERICAL_FEATURES] = scaler.inverse_transform(X_test_scaled[NUMERICAL_FEATURES])
    X_test_unscaled = X_test_unscaled.round({"age": 1, "height": 0, "weight": 1, "ap_hi": 0, "ap_lo": 0, "bmi": 2})

    logger.info(
        f"Model ({type(model).__name__}) and data loaded. "
        f"Train size: {X_train_scaled.shape[0]:,}, Test size: {X_test_scaled.shape[0]:,}"
    )
    return model, scaler, X_train_scaled, y_train, X_test_scaled, y_test, X_test_unscaled


def build_shap_explainer(model: Any) -> shap.TreeExplainer:
    """Builds a fast, mathematically exact TreeExplainer for the tree-based champion model."""
    logger.info("Initializing SHAP TreeExplainer for XGBoost Champion model...")
    explainer = shap.TreeExplainer(model)
    return explainer


def build_lime_explainer(
    X_train: pd.DataFrame, categorical_features: Optional[List[str]] = None
) -> lime.lime_tabular.LimeTabularExplainer:
    """Builds a LimeTabularExplainer fitted on training feature statistics."""
    logger.info("Initializing LIME Tabular Explainer...")
    feature_names = list(X_train.columns)
    cat_indices = (
        [feature_names.index(col) for col in categorical_features if col in feature_names]
        if categorical_features
        else []
    )

    explainer = lime.lime_tabular.LimeTabularExplainer(
        training_data=X_train.values,
        feature_names=feature_names,
        class_names=["Healthy (Low Risk)", "Cardiovascular Risk"],
        categorical_features=cat_indices,
        mode="classification",
        random_state=RANDOM_STATE,
    )
    return explainer


def generate_global_shap_explanations(
    explainer: shap.TreeExplainer,
    X_scaled: pd.DataFrame,
    X_unscaled: pd.DataFrame,
    sample_size: int = 2000,
    output_dir: Path = FIGURES_DIR,
) -> shap.Explanation:
    """
    Computes global SHAP values and outputs:
    1. Summary Beeswarm Plot (reports/figures/shap_summary_beeswarm.png)
    2. Global Feature Importance Bar Plot (reports/figures/shap_feature_importance_bar.png)
    3. Dependence Plot for Systolic Blood Pressure (reports/figures/shap_dependence_ap_hi.png)
    4. Dependence Plot for Diastolic Blood Pressure (reports/figures/shap_dependence_ap_lo.png)
    5. Dependence Plot for Body Mass Index (reports/figures/shap_dependence_bmi.png)
    """
    logger.info(f"Computing SHAP values for global analysis on N={sample_size:,} test samples...")
    sample_idx = np.random.choice(len(X_scaled), size=min(sample_size, len(X_scaled)), replace=False)
    X_sample_scaled = X_scaled.iloc[sample_idx]
    X_sample_unscaled = X_unscaled.iloc[sample_idx]

    shap_values = explainer(X_sample_scaled)

    # Attach unscaled data to explanation object for clinically intuitive axes and labels
    shap_values_display = shap.Explanation(
        values=shap_values.values,
        base_values=shap_values.base_values,
        data=X_sample_unscaled.values,
        feature_names=[CLINICAL_FEATURE_LABELS.get(col, col) for col in X_sample_scaled.columns],
    )

    output_dir.mkdir(parents=True, exist_ok=True)

    # 1. SHAP Summary Beeswarm Plot
    logger.info("Generating Global Plot 1: SHAP Summary Beeswarm Plot...")
    plt.figure(figsize=(10, 7), dpi=300)
    shap.plots.beeswarm(shap_values_display, max_display=12, show=False)
    plt.title("SHAP Global Summary Beeswarm Plot: Feature Impact on Cardio Risk", fontsize=13, pad=15, fontweight="bold")
    plt.xlabel("SHAP Value (Impact on Log-Odds of Cardiovascular Disease)", fontsize=11, labelpad=10)
    plt.tight_layout()
    beeswarm_path = output_dir / "shap_summary_beeswarm.png"
    plt.savefig(beeswarm_path, dpi=300, bbox_inches="tight")
    plt.close()
    logger.info(f"Saved: {beeswarm_path}")

    # 2. SHAP Feature Importance Bar Plot
    logger.info("Generating Global Plot 2: SHAP Feature Importance Bar Plot...")
    plt.figure(figsize=(10, 6), dpi=300)
    shap.plots.bar(shap_values_display, max_display=12, show=False)
    plt.title("SHAP Global Feature Importance (Mean |SHAP Value|)", fontsize=13, pad=15, fontweight="bold")
    plt.xlabel("Mean |SHAP Value| (Average Absolute Impact)", fontsize=11, labelpad=10)
    plt.tight_layout()
    bar_path = output_dir / "shap_feature_importance_bar.png"
    plt.savefig(bar_path, dpi=300, bbox_inches="tight")
    plt.close()
    logger.info(f"Saved: {bar_path}")

    # 3. SHAP Dependence Plot: Systolic Blood Pressure (ap_hi)
    logger.info("Generating Global Plot 3: SHAP Dependence Plot for Systolic BP (ap_hi)...")
    ap_hi_label = CLINICAL_FEATURE_LABELS["ap_hi"]
    plt.figure(figsize=(9, 6), dpi=300)
    shap.plots.scatter(
        shap_values_display[:, ap_hi_label],
        color=shap_values_display[:, CLINICAL_FEATURE_LABELS["age"]],
        show=False,
    )
    plt.title("SHAP Dependence Plot: Systolic BP (ap_hi) colored by Age", fontsize=12, pad=15, fontweight="bold")
    plt.xlabel("Systolic Blood Pressure (mmHg)", fontsize=11)
    plt.ylabel("SHAP Value for Systolic BP", fontsize=11)
    plt.axhline(0, color="gray", linestyle="--", alpha=0.6)
    plt.tight_layout()
    dep_ap_hi_path = output_dir / "shap_dependence_ap_hi.png"
    plt.savefig(dep_ap_hi_path, dpi=300, bbox_inches="tight")
    plt.close()
    logger.info(f"Saved: {dep_ap_hi_path}")

    # 4. SHAP Dependence Plot: Diastolic Blood Pressure (ap_lo)
    logger.info("Generating Global Plot 4: SHAP Dependence Plot for Diastolic BP (ap_lo)...")
    ap_lo_label = CLINICAL_FEATURE_LABELS["ap_lo"]
    plt.figure(figsize=(9, 6), dpi=300)
    shap.plots.scatter(
        shap_values_display[:, ap_lo_label],
        color=shap_values_display[:, ap_hi_label],
        show=False,
    )
    plt.title("SHAP Dependence Plot: Diastolic BP (ap_lo) colored by Systolic BP", fontsize=12, pad=15, fontweight="bold")
    plt.xlabel("Diastolic Blood Pressure (mmHg)", fontsize=11)
    plt.ylabel("SHAP Value for Diastolic BP", fontsize=11)
    plt.axhline(0, color="gray", linestyle="--", alpha=0.6)
    plt.tight_layout()
    dep_ap_lo_path = output_dir / "shap_dependence_ap_lo.png"
    plt.savefig(dep_ap_lo_path, dpi=300, bbox_inches="tight")
    plt.close()
    logger.info(f"Saved: {dep_ap_lo_path}")

    # 5. SHAP Dependence Plot: BMI
    logger.info("Generating Global Plot 5: SHAP Dependence Plot for BMI...")
    bmi_label = CLINICAL_FEATURE_LABELS["bmi"]
    plt.figure(figsize=(9, 6), dpi=300)
    shap.plots.scatter(
        shap_values_display[:, bmi_label],
        color=shap_values_display[:, CLINICAL_FEATURE_LABELS["cholesterol"]],
        show=False,
    )
    plt.title("SHAP Dependence Plot: BMI colored by Cholesterol Level", fontsize=12, pad=15, fontweight="bold")
    plt.xlabel("Body Mass Index (BMI, kg/m²)", fontsize=11)
    plt.ylabel("SHAP Value for BMI", fontsize=11)
    plt.axvline(25.0, color="green", linestyle=":", label="Normal BMI Upper Bound (25.0)")
    plt.axvline(30.0, color="red", linestyle=":", label="Obesity Threshold (30.0)")
    plt.axhline(0, color="gray", linestyle="--", alpha=0.6)
    plt.legend(frameon=True)
    plt.tight_layout()
    dep_bmi_path = output_dir / "shap_dependence_bmi.png"
    plt.savefig(dep_bmi_path, dpi=300, bbox_inches="tight")
    plt.close()
    logger.info(f"Saved: {dep_bmi_path}")

    return shap_values_display


def explain_single_patient_shap(
    explainer: shap.TreeExplainer,
    patient_scaled: pd.Series,
    patient_unscaled: pd.Series,
    patient_title: str,
    output_path: Path,
) -> None:
    """Generates a patient-specific SHAP Waterfall Plot."""
    patient_df_scaled = pd.DataFrame([patient_scaled])
    shap_vals = explainer(patient_df_scaled)

    # Attach unscaled physical values for medical clarity
    explanation = shap.Explanation(
        values=shap_vals.values[0],
        base_values=shap_vals.base_values[0],
        data=patient_unscaled.values,
        feature_names=[CLINICAL_FEATURE_LABELS.get(col, col) for col in patient_scaled.index],
    )

    plt.figure(figsize=(9, 6), dpi=300)
    shap.plots.waterfall(explanation, max_display=10, show=False)
    plt.title(f"SHAP Waterfall Plot: {patient_title}", fontsize=12, pad=15, fontweight="bold")
    plt.tight_layout()
    output_path.parent.mkdir(parents=True, exist_ok=True)
    plt.savefig(output_path, dpi=300, bbox_inches="tight")
    plt.close()
    logger.info(f"Saved patient SHAP Waterfall: {output_path}")


def explain_single_patient_lime(
    lime_explainer: lime.lime_tabular.LimeTabularExplainer,
    predict_fn: Any,
    patient_scaled: pd.Series,
    patient_title: str,
    output_png_path: Path,
    output_html_path: Optional[Path] = None,
    num_features: int = 8,
) -> List[Tuple[str, float]]:
    """Generates a patient-specific LIME Tabular Explanation bar chart and HTML report."""
    exp = lime_explainer.explain_instance(
        patient_scaled.values,
        predict_fn,
        num_features=num_features,
        labels=[1],  # Explain probability of Cardiovascular Disease
    )

    # Plot as clean, styled horizontal bar chart
    fig = exp.as_pyplot_figure(label=1)
    plt.title(f"LIME Local Explanation: {patient_title}", fontsize=12, pad=15, fontweight="bold")
    plt.xlabel("LIME Feature Weight (Contribution to Risk)", fontsize=11)
    plt.tight_layout()
    output_png_path.parent.mkdir(parents=True, exist_ok=True)
    plt.savefig(output_png_path, dpi=300, bbox_inches="tight")
    plt.close(fig)
    logger.info(f"Saved patient LIME chart: {output_png_path}")

    if output_html_path:
        exp.save_to_file(str(output_html_path))
        logger.info(f"Saved patient LIME interactive HTML: {output_html_path}")

    return exp.as_list(label=1)


def run_xai_pipeline(output_dir: Path = FIGURES_DIR) -> None:
    """Executes complete Phase 3 Explainable AI pipeline."""
    logger.info("========== STARTING PHASE 3: EXPLAINABLE AI (XAI) INTEGRATION ==========")

    model, scaler, X_train_scaled, y_train, X_test_scaled, y_test, X_test_unscaled = load_model_and_data()

    # 1. Initialize explainers
    shap_explainer = build_shap_explainer(model)
    lime_explainer = build_lime_explainer(
        X_train_scaled, categorical_features=["gender", "cholesterol", "gluc", "smoke", "alco", "active"]
    )

    # 2. Global Interpretability Analysis
    generate_global_shap_explanations(
        shap_explainer, X_test_scaled, X_test_unscaled, sample_size=2000, output_dir=output_dir
    )

    # 3. Local Interpretability Case Studies
    # Identify Patient Case 1: High Risk Patient (predicted prob >= 0.85)
    # Identify Patient Case 2: Low Risk Patient (predicted prob <= 0.15)
    test_probs = model.predict_proba(X_test_scaled)[:, 1]

    high_risk_candidates = np.where(test_probs >= 0.85)[0]
    low_risk_candidates = np.where(test_probs <= 0.15)[0]

    high_idx = int(high_risk_candidates[0]) if len(high_risk_candidates) > 0 else int(np.argmax(test_probs))
    low_idx = int(low_risk_candidates[0]) if len(low_risk_candidates) > 0 else int(np.argmin(test_probs))

    # --- Patient A (High Risk Case Study) ---
    p_high_scaled = X_test_scaled.iloc[high_idx]
    p_high_unscaled = X_test_unscaled.iloc[high_idx]
    prob_high = test_probs[high_idx]
    title_high = f"High Risk Patient (Pred Risk: {prob_high:.1%})"
    logger.info(f"Analyzing {title_high} -> Details: {p_high_unscaled.to_dict()}")

    explain_single_patient_shap(
        shap_explainer,
        p_high_scaled,
        p_high_unscaled,
        title_high,
        output_dir / "shap_waterfall_patient_high_risk.png",
    )
    explain_single_patient_lime(
        lime_explainer,
        model.predict_proba,
        p_high_scaled,
        title_high,
        output_dir / "lime_patient_high_risk.png",
        output_dir / "lime_patient_high_risk.html",
    )

    # --- Patient B (Low Risk Case Study) ---
    p_low_scaled = X_test_scaled.iloc[low_idx]
    p_low_unscaled = X_test_unscaled.iloc[low_idx]
    prob_low = test_probs[low_idx]
    title_low = f"Healthy Patient (Pred Risk: {prob_low:.1%})"
    logger.info(f"Analyzing {title_low} -> Details: {p_low_unscaled.to_dict()}")

    explain_single_patient_shap(
        shap_explainer,
        p_low_scaled,
        p_low_unscaled,
        title_low,
        output_dir / "shap_waterfall_patient_low_risk.png",
    )
    explain_single_patient_lime(
        lime_explainer,
        model.predict_proba,
        p_low_scaled,
        title_low,
        output_dir / "lime_patient_low_risk.png",
        output_dir / "lime_patient_low_risk.html",
    )

    # 4. Serialize explainers for Phase 4 Dashboard real-time inference
    logger.info("Serializing XAI explainers for Phase 4 Dashboard...")
    joblib.dump(shap_explainer, MODELS_DIR / "shap_explainer.joblib", compress=3)
    
    import cloudpickle
    with open(MODELS_DIR / "lime_explainer.pkl", "wb") as f:
        cloudpickle.dump(lime_explainer, f)
    logger.info(f"Explainers serialized to: {MODELS_DIR}")

    logger.info("========== PHASE 3 COMPLETED SUCCESSFULLY ==========")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Phase 3: Explainable AI Pipeline")
    parser.add_argument(
        "--output-dir",
        type=str,
        default=str(FIGURES_DIR),
        help="Directory to save explanation figures",
    )
    args = parser.parse_args()

    run_xai_pipeline(Path(args.output_dir))
