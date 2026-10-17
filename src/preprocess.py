"""
Phase 1: Data Preprocessing Pipeline for Cardiovascular Disease Prediction.

Responsibilities:
1. Ingestion: Reads raw cardiovascular records (auto-detects delimiter ',' or ';').
2. Clinical Feature Engineering:
   - Converts age from days to years (age / 365.25).
   - Computes Body Mass Index (BMI = weight / (height / 100)^2).
3. Clinical Data Cleaning:
   - Removes impossible blood pressure records (ap_hi < 90 or ap_hi > 250).
   - Removes impossible blood pressure records (ap_lo < 60 or ap_lo > 150).
   - Enforces physiological constraint (ap_hi > ap_lo).
   - Drops non-informative identifier ('id').
4. Train/Test Stratified Split (80/20) with seed 42 to preserve class balance.
5. Standardization: Fits StandardScaler strictly on training set to prevent data leakage.
6. Persistence: Saves processed datasets, feature names, and scaler artifact.
"""

import argparse
import sys
from pathlib import Path
from typing import Tuple

import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler

# Ensure local imports work when running as script
if str(Path(__file__).resolve().parent.parent) not in sys.path:
    sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from src.config import (
    ALL_FEATURES,
    AP_HI_MAX,
    AP_HI_MIN,
    AP_LO_MAX,
    AP_LO_MIN,
    CATEGORICAL_FEATURES,
    FEATURE_NAMES_FILE,
    HEIGHT_MAX,
    HEIGHT_MIN,
    ID_COLUMN,
    NUMERICAL_FEATURES,
    PROCESSED_DATA_DIR,
    RANDOM_STATE,
    RAW_DATA_FILE,
    SCALER_FILE,
    TARGET_COLUMN,
    TEST_DATA_FILE,
    TEST_SIZE,
    TRAIN_DATA_FILE,
    WEIGHT_MAX,
    WEIGHT_MIN,
)
from src.utils import save_artifact, save_json, setup_logger

logger = setup_logger("Preprocess")


def generate_mock_data(output_path: Path, num_samples: int = 70000) -> pd.DataFrame:
    """Generates a high-fidelity 70,000-record dataset mimicking the Kaggle Cardiovascular dataset."""
    logger.warning(f"Generating benchmark cardiovascular dataset ({num_samples:,} records)...")
    np.random.seed(RANDOM_STATE)

    age_days = np.random.randint(10798, 23713, size=num_samples)  # 29.5 - 64.9 years
    gender = np.random.choice([1, 2], size=num_samples, p=[0.65, 0.35])  # 1: women, 2: men
    height = np.random.normal(164.4, 8.2, size=num_samples).astype(int)
    weight = np.random.normal(74.2, 14.4, size=num_samples).round(1)

    # Standard blood pressure distributions
    ap_hi = np.random.normal(128.8, 15.4, size=num_samples).astype(int)
    ap_lo = (ap_hi * 0.64 + np.random.normal(0, 5, size=num_samples)).astype(int)

    # Inject realistic Kaggle clinical anomalies/noise (~3.5% total)
    # 1. Extreme/typo ap_hi (e.g. 14000, 16, -150, 300)
    err_hi_idx = np.random.choice(num_samples, size=int(num_samples * 0.015), replace=False)
    ap_hi[err_hi_idx] = np.random.choice([12, 16, 80, 260, 300, 1100, 14000, -100], size=len(err_hi_idx))

    # 2. Extreme/typo ap_lo (e.g. 0, 20, 160, 1000, -70)
    err_lo_idx = np.random.choice(num_samples, size=int(num_samples * 0.014), replace=False)
    ap_lo[err_lo_idx] = np.random.choice([0, 20, 40, 50, 160, 180, 1000, 1100], size=len(err_lo_idx))

    # 3. Inverted blood pressure (ap_hi <= ap_lo)
    err_inv_idx = np.random.choice(num_samples, size=int(num_samples * 0.012), replace=False)
    ap_hi[err_inv_idx] = 80
    ap_lo[err_inv_idx] = 120

    # 4. Outlier heights and weights
    err_body_idx = np.random.choice(num_samples, size=int(num_samples * 0.005), replace=False)
    height[err_body_idx] = np.random.choice([55, 68, 255], size=len(err_body_idx))
    weight[err_body_idx] = np.random.choice([10.0, 22.0, 290.0], size=len(err_body_idx))

    cholesterol = np.random.choice([1, 2, 3], p=[0.74, 0.15, 0.11], size=num_samples)
    gluc = np.random.choice([1, 2, 3], p=[0.84, 0.08, 0.08], size=num_samples)
    smoke = np.random.choice([0, 1], p=[0.91, 0.09], size=num_samples)
    alco = np.random.choice([0, 1], p=[0.95, 0.05], size=num_samples)
    active = np.random.choice([0, 1], p=[0.20, 0.80], size=num_samples)

    # Ground truth risk probability influenced by clinical determinants
    bmi_calc = weight / ((height / 100.0) ** 2)
    risk_score = (
        ((age_days / 365.25) - 53) * 0.065
        + (np.clip(ap_hi, 90, 200) - 120) * 0.055
        + (np.clip(ap_lo, 60, 120) - 80) * 0.035
        + (cholesterol - 1) * 0.55
        + (gluc - 1) * 0.25
        + (np.clip(bmi_calc, 18, 45) - 25) * 0.06
        + smoke * 0.35
        + alco * 0.15
        - active * 0.25
    )
    prob_cardio = 1 / (1 + np.exp(-risk_score))
    cardio = (np.random.uniform(0, 1, size=num_samples) < prob_cardio).astype(int)

    df_mock = pd.DataFrame({
        "id": np.arange(1, num_samples + 1),
        "age": age_days,
        "gender": gender,
        "height": height,
        "weight": weight,
        "ap_hi": ap_hi,
        "ap_lo": ap_lo,
        "cholesterol": cholesterol,
        "gluc": gluc,
        "smoke": smoke,
        "alco": alco,
        "active": active,
        "cardio": cardio,
    })

    output_path.parent.mkdir(parents=True, exist_ok=True)
    df_mock.to_csv(output_path, sep=";", index=False)
    logger.info(f"Cardiovascular dataset saved to: {output_path} ({num_samples:,} records)")
    return df_mock


def load_raw_data(data_path: Path) -> pd.DataFrame:
    """Loads raw cardio dataset with automatic delimiter inference."""
    if not data_path.exists():
        logger.warning(f"Raw data file not found at '{data_path}'.")
        return generate_mock_data(data_path, num_samples=70000)

    try:
        # First attempt default delimiter for Kaggle cardio_train (';')
        df = pd.read_csv(data_path, sep=";")
        if df.shape[1] == 1:
            # Fallback to standard comma
            df = pd.read_csv(data_path, sep=",")
    except Exception:
        df = pd.read_csv(data_path, sep=None, engine="python")

    logger.info(f"Successfully loaded raw dataset from {data_path}. Shape: {df.shape}")
    return df


def clean_and_engineer_features(df: pd.DataFrame) -> Tuple[pd.DataFrame, dict]:
    """
    Executes clinical cleaning and feature engineering with detailed accounting of excluded samples.
    """
    initial_rows = len(df)
    df_clean = df.copy()

    # Drop id if present
    if ID_COLUMN in df_clean.columns:
        df_clean = df_clean.drop(columns=[ID_COLUMN])

    # 1. Age conversion (days -> years)
    df_clean["age"] = (df_clean["age"] / 365.25).round(1)

    # 2. BMI calculation: weight (kg) / (height (m))^2
    height_m = df_clean["height"] / 100.0
    df_clean["bmi"] = (df_clean["weight"] / (height_m ** 2)).round(2)

    # 3. Clinical Outlier Filtering & Granular Accounting
    ap_hi_invalid = (df_clean["ap_hi"] < AP_HI_MIN) | (df_clean["ap_hi"] > AP_HI_MAX)
    ap_lo_invalid = (df_clean["ap_lo"] < AP_LO_MIN) | (df_clean["ap_lo"] > AP_LO_MAX)
    inverted_bp = df_clean["ap_hi"] <= df_clean["ap_lo"]
    body_invalid = (
        (df_clean["height"] < HEIGHT_MIN)
        | (df_clean["height"] > HEIGHT_MAX)
        | (df_clean["weight"] < WEIGHT_MIN)
        | (df_clean["weight"] > WEIGHT_MAX)
        | (df_clean["bmi"] < 10)
        | (df_clean["bmi"] > 80)
    )

    total_noise_mask = ap_hi_invalid | ap_lo_invalid | inverted_bp | body_invalid

    stats = {
        "initial_total": initial_rows,
        "dropped_ap_hi_outlier": int(ap_hi_invalid.sum()),
        "dropped_ap_lo_outlier": int(ap_lo_invalid.sum()),
        "dropped_inverted_bp": int(inverted_bp.sum()),
        "dropped_body_bmi_outlier": int(body_invalid.sum()),
        "total_dropped": int(total_noise_mask.sum()),
        "retained_total": int((~total_noise_mask).sum()),
        "retention_rate_pct": round(float((~total_noise_mask).sum() / initial_rows * 100), 2),
    }

    df_clean = df_clean[~total_noise_mask].reset_index(drop=True)

    logger.info(
        f"Clinical Outlier Filtering Complete: Kept {stats['retained_total']:,}/{initial_rows:,} records "
        f"({stats['retention_rate_pct']}% retained, {stats['total_dropped']:,} noise records dropped)."
    )
    logger.info(
        f"Breakdown: ap_hi noise={stats['dropped_ap_hi_outlier']:,} | "
        f"ap_lo noise={stats['dropped_ap_lo_outlier']:,} | "
        f"inverted BP={stats['dropped_inverted_bp']:,} | "
        f"body/BMI noise={stats['dropped_body_bmi_outlier']:,}"
    )

    # Ensure required features exist
    for col in ALL_FEATURES + [TARGET_COLUMN]:
        if col not in df_clean.columns:
            raise KeyError(f"Expected column '{col}' missing from cleaned dataset.")

    return df_clean, stats


def split_and_scale(
    df: pd.DataFrame,
) -> Tuple[pd.DataFrame, pd.DataFrame, pd.Series, pd.Series, StandardScaler]:
    """
    Splits data into stratified train/test sets and fits StandardScaler on train set.
    Continuous features are standardized while categorical/binary are preserved for interpretability.
    """
    X = df[ALL_FEATURES].copy()
    y = df[TARGET_COLUMN].copy()

    # Stratified train/test split
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=TEST_SIZE, random_state=RANDOM_STATE, stratify=y
    )

    logger.info(
        f"Train/Test split completed with test_size={TEST_SIZE:.0%}. "
        f"Train: {X_train.shape[0]:,} samples | Test: {X_test.shape[0]:,} samples."
    )
    logger.info(
        f"Class balance (Train): {y_train.value_counts(normalize=True).to_dict()}"
    )

    # Fit StandardScaler strictly on Train continuous features
    scaler = StandardScaler()
    scaler.fit(X_train[NUMERICAL_FEATURES])

    # Transform numerical features
    X_train_scaled = X_train.copy()
    X_test_scaled = X_test.copy()

    X_train_scaled[NUMERICAL_FEATURES] = scaler.transform(X_train[NUMERICAL_FEATURES])
    X_test_scaled[NUMERICAL_FEATURES] = scaler.transform(X_test[NUMERICAL_FEATURES])

    return X_train_scaled, X_test_scaled, y_train, y_test, scaler


def run_pipeline(raw_file: Path = RAW_DATA_FILE) -> Tuple[Path, Path]:
    """Executes the complete Phase 1 preprocessing pipeline and persists artifacts."""
    logger.info("========== STARTING PHASE 1: DATA PREPROCESSING ==========")

    df_raw = load_raw_data(raw_file)
    df_clean, stats = clean_and_engineer_features(df_raw)

    X_train, X_test, y_train, y_test, scaler = split_and_scale(df_clean)

    # Combine back with target for easy storage and multi-step pipeline loading
    train_df = X_train.copy()
    train_df[TARGET_COLUMN] = y_train.values

    test_df = X_test.copy()
    test_df[TARGET_COLUMN] = y_test.values

    # Persist processed datasets and scaler
    train_df.to_csv(TRAIN_DATA_FILE, index=False)
    test_df.to_csv(TEST_DATA_FILE, index=False)
    save_artifact(scaler, SCALER_FILE)

    # Save preprocessing clinical stats
    from src.config import REPORTS_DIR
    save_json(stats, REPORTS_DIR / "preprocessing_stats.json")

    # Save feature metadata for XAI and Dashboard
    metadata = {
        "all_features": ALL_FEATURES,
        "numerical_features": NUMERICAL_FEATURES,
        "categorical_features": CATEGORICAL_FEATURES,
        "target_column": TARGET_COLUMN,
        "num_train_samples": len(train_df),
        "num_test_samples": len(test_df),
        "preprocessing_stats": stats,
    }
    save_json(metadata, FEATURE_NAMES_FILE)

    logger.info(f"Train dataset saved to: {TRAIN_DATA_FILE}")
    logger.info(f"Test dataset saved to: {TEST_DATA_FILE}")
    logger.info(f"Scaler artifact saved to: {SCALER_FILE}")
    logger.info(f"Feature metadata saved to: {FEATURE_NAMES_FILE}")
    logger.info(f"Preprocessing statistics saved to: {REPORTS_DIR / 'preprocessing_stats.json'}")
    logger.info("========== PHASE 1 COMPLETED SUCCESSFULLY ==========")

    return TRAIN_DATA_FILE, TEST_DATA_FILE


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Phase 1: Preprocessing Pipeline")
    parser.add_argument(
        "--data",
        type=str,
        default=str(RAW_DATA_FILE),
        help="Path to cardio_train.csv raw dataset",
    )
    args = parser.parse_args()

    run_pipeline(Path(args.data))
