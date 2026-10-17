"""
Central Configuration for Cardiovascular Disease Prediction & XAI Pipeline.
Defines paths, feature schemas, clinical constraints, and hyperparameter search spaces.
"""

from pathlib import Path

# ==========================================
# 1. DIRECTORY & PATH MANAGEMENT
# ==========================================
BASE_DIR = Path(__file__).resolve().parent.parent

DATA_DIR = BASE_DIR / "data"
RAW_DATA_DIR = DATA_DIR / "raw"
PROCESSED_DATA_DIR = DATA_DIR / "processed"

RAW_DATA_FILE = RAW_DATA_DIR / "cardio_train.csv"
TRAIN_DATA_FILE = PROCESSED_DATA_DIR / "train.csv"
TEST_DATA_FILE = PROCESSED_DATA_DIR / "test.csv"
SCALER_FILE = PROCESSED_DATA_DIR / "scaler.joblib"
FEATURE_NAMES_FILE = PROCESSED_DATA_DIR / "feature_names.json"

MODELS_DIR = BASE_DIR / "models"
BEST_MODEL_FILE = MODELS_DIR / "best_model.joblib"
MODEL_METADATA_FILE = MODELS_DIR / "model_metadata.json"

REPORTS_DIR = BASE_DIR / "reports"
FIGURES_DIR = REPORTS_DIR / "figures"
METRICS_CSV_FILE = REPORTS_DIR / "metrics_comparison.csv"
METRICS_MD_FILE = REPORTS_DIR / "metrics_comparison.md"

# Ensure runtime directories exist
for folder in [RAW_DATA_DIR, PROCESSED_DATA_DIR, MODELS_DIR, REPORTS_DIR, FIGURES_DIR]:
    folder.mkdir(parents=True, exist_ok=True)

# ==========================================
# 2. DATASET & CLINICAL FEATURE SCHEMA
# ==========================================
TARGET_COLUMN = "cardio"
ID_COLUMN = "id"

# Continuous numerical features to be standardized
NUMERICAL_FEATURES = [
    "age",       # converted to years
    "height",    # cm
    "weight",    # kg
    "ap_hi",     # Systolic blood pressure (mmHg)
    "ap_lo",     # Diastolic blood pressure (mmHg)
    "bmi",       # Body Mass Index (kg/m^2)
]

# Categorical and binary features (kept unscaled for medical interpretability)
CATEGORICAL_FEATURES = [
    "gender",       # 1: Female, 2: Male
    "cholesterol",  # 1: Normal, 2: Above Normal, 3: Well Above Normal
    "gluc",         # 1: Normal, 2: Above Normal, 3: Well Above Normal
    "smoke",        # 0: No, 1: Yes
    "alco",         # 0: No, 1: Yes
    "active",       # 0: No, 1: Yes
]

ALL_FEATURES = NUMERICAL_FEATURES + CATEGORICAL_FEATURES

# ==========================================
# 3. CLINICAL DATA CLEANING CONSTRAINTS
# ==========================================
# Systolic Blood Pressure range (mmHg)
AP_HI_MIN = 90
AP_HI_MAX = 250

# Diastolic Blood Pressure range (mmHg)
AP_LO_MIN = 60
AP_LO_MAX = 150

# Physiological sanity bounds for height & weight
HEIGHT_MIN = 100  # cm
HEIGHT_MAX = 250  # cm
WEIGHT_MIN = 30   # kg
WEIGHT_MAX = 250  # kg

# ==========================================
# 4. TRAINING & REPRODUCIBILITY CONFIG
# ==========================================
RANDOM_STATE = 42
TEST_SIZE = 0.20
CV_FOLDS = 5

# Optuna Hyperparameter Tuning Configuration
OPTUNA_N_TRIALS = 30
OPTUNA_TIMEOUT = 1200  # 20 minutes max
