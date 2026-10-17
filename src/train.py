"""
Phase 2: Model Training, Comparison & Hyperparameter Optimization.

Responsibilities:
1. Model Candidates:
   - XGBoost (XGBClassifier)
   - Random Forest (RandomForestClassifier)
   - Support Vector Machine (SVC with probability estimation)
2. Hyperparameter Optimization:
   - Automated Bayesian optimization with Optuna for XGBoost.
   - Stratified K-Fold Cross Validation optimizing ROC-AUC.
3. Comprehensive Metrics Evaluation on Holdout Test Set:
   - ROC-AUC
   - Recall (Sensitivity)
   - Precision (PPV)
   - F1-Score
   - Accuracy
4. Persistence & Reporting:
   - Saves comparative metrics to CSV and GitHub-Flavored Markdown.
   - Persists the Champion Model to models/best_model.joblib for Phase 3 (XAI) and Phase 4 (Dashboard).
"""

import argparse
import sys
import time
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List, Tuple

import numpy as np
import optuna
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import (
    accuracy_score,
    f1_score,
    precision_score,
    recall_score,
    roc_auc_score,
)
from sklearn.model_selection import StratifiedKFold, cross_val_score
from sklearn.svm import SVC
from xgboost import XGBClassifier

# Silence Optuna verbose logs by default
optuna.logging.set_verbosity(optuna.logging.WARNING)

# Ensure local imports work when running as script
if str(Path(__file__).resolve().parent.parent) not in sys.path:
    sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from src.config import (
    BEST_MODEL_FILE,
    CV_FOLDS,
    METRICS_CSV_FILE,
    METRICS_MD_FILE,
    MODEL_METADATA_FILE,
    OPTUNA_N_TRIALS,
    OPTUNA_TIMEOUT,
    RANDOM_STATE,
    TARGET_COLUMN,
    TEST_DATA_FILE,
    TRAIN_DATA_FILE,
)
from src.utils import format_metrics_table, save_artifact, save_json, setup_logger

logger = setup_logger("ModelTraining")


def load_train_test_data() -> Tuple[pd.DataFrame, pd.Series, pd.DataFrame, pd.Series]:
    """Loads preprocessed train and test sets."""
    if not TRAIN_DATA_FILE.exists() or not TEST_DATA_FILE.exists():
        raise FileNotFoundError(
            f"Preprocessed data not found at {TRAIN_DATA_FILE}. "
            "Please execute Phase 1 (python src/preprocess.py) first."
        )

    train_df = pd.read_csv(TRAIN_DATA_FILE)
    test_df = pd.read_csv(TEST_DATA_FILE)

    X_train = train_df.drop(columns=[TARGET_COLUMN])
    y_train = train_df[TARGET_COLUMN]

    X_test = test_df.drop(columns=[TARGET_COLUMN])
    y_test = test_df[TARGET_COLUMN]

    logger.info(
        f"Data loaded successfully. Features: {list(X_train.columns)}. "
        f"Train shape: {X_train.shape}, Test shape: {X_test.shape}"
    )
    return X_train, y_train, X_test, y_test


def evaluate_model(
    name: str, model: Any, X_test: pd.DataFrame, y_test: pd.Series
) -> Dict[str, Any]:
    """Evaluates a fitted classification model on test set across standard medical metrics."""
    start_time = time.time()
    y_pred = model.predict(X_test)
    inference_time = time.time() - start_time

    # Calculate prediction probabilities for ROC-AUC
    if hasattr(model, "predict_proba"):
        y_prob = model.predict_proba(X_test)[:, 1]
    elif hasattr(model, "decision_function"):
        y_prob = model.decision_function(X_test)
    else:
        y_prob = y_pred

    auc_score = roc_auc_score(y_test, y_prob)
    rec_score = recall_score(y_test, y_pred)
    prec_score = precision_score(y_test, y_pred, zero_division=0)
    f1 = f1_score(y_test, y_pred)
    acc = accuracy_score(y_test, y_pred)

    metrics = {
        "Model": name,
        "ROC-AUC": round(auc_score, 4),
        "Recall": round(rec_score, 4),
        "Precision": round(prec_score, 4),
        "F1-Score": round(f1, 4),
        "Accuracy": round(acc, 4),
        "Inference_Sec": round(inference_time, 4),
    }

    logger.info(
        f"[{name}] Test Results -> ROC-AUC: {metrics['ROC-AUC']:.4f} | "
        f"Recall: {metrics['Recall']:.4f} | Precision: {metrics['Precision']:.4f} | "
        f"F1: {metrics['F1-Score']:.4f} | Acc: {metrics['Accuracy']:.4f}"
    )
    return metrics


def tune_xgboost_optuna(
    X_train: pd.DataFrame,
    y_train: pd.Series,
    n_trials: int = OPTUNA_N_TRIALS,
    timeout: int = OPTUNA_TIMEOUT,
) -> Tuple[Dict[str, Any], float]:
    """
    Optimizes XGBoost hyperparameters using Optuna with 5-fold Stratified Cross-Validation.
    Maximizes ROC-AUC to balance discrimination power.
    """
    logger.info(
        f"Starting Optuna hyperparameter optimization for XGBoost ({n_trials} trials, {CV_FOLDS}-fold CV)..."
    )

    skf = StratifiedKFold(n_splits=CV_FOLDS, shuffle=True, random_state=RANDOM_STATE)

    def objective(trial: optuna.Trial) -> float:
        params = {
            "n_estimators": trial.suggest_int("n_estimators", 100, 600, step=50),
            "max_depth": trial.suggest_int("max_depth", 3, 9),
            "learning_rate": trial.suggest_float("learning_rate", 0.01, 0.2, log=True),
            "subsample": trial.suggest_float("subsample", 0.6, 1.0, step=0.1),
            "colsample_bytree": trial.suggest_float("colsample_bytree", 0.6, 1.0, step=0.1),
            "min_child_weight": trial.suggest_int("min_child_weight", 1, 10),
            "gamma": trial.suggest_float("gamma", 0.0, 5.0, step=0.5),
            "reg_alpha": trial.suggest_float("reg_alpha", 1e-3, 10.0, log=True),
            "reg_lambda": trial.suggest_float("reg_lambda", 1e-3, 10.0, log=True),
            "random_state": RANDOM_STATE,
            "eval_metric": "logloss",
            "use_label_encoder": False,
            "n_jobs": -1,
        }

        clf = XGBClassifier(**params)
        scores = cross_val_score(clf, X_train, y_train, cv=skf, scoring="roc_auc", n_jobs=-1)
        return scores.mean()

    study = optuna.create_study(direction="maximize", sampler=optuna.samplers.TPESampler(seed=RANDOM_STATE))
    study.optimize(objective, n_trials=n_trials, timeout=timeout)

    logger.info(f"Optuna Optimization complete. Best CV ROC-AUC: {study.best_value:.4f}")
    logger.info(f"Best Hyperparameters: {study.best_params}")
    return study.best_params, study.best_value


def train_and_compare(
    run_optuna: bool = True, optuna_trials: int = OPTUNA_N_TRIALS
) -> Tuple[pd.DataFrame, Any]:
    """
    Huấn luyện và so sánh 3 thuật toán:
    1. XGBoost (Baseline)
    2. Random Forest
    3. Support Vector Machine (SVM)
    4. XGBoost (Optuna Tuned - Best Model)
    """
    logger.info("========== STARTING PHASE 2: MODEL TRAINING & COMPARISON ==========")

    X_train, y_train, X_test, y_test = load_train_test_data()
    metrics_list: List[Dict[str, Any]] = []

    # 1. Baseline XGBoost
    logger.info("Training 1/3: Baseline XGBoost Classifier...")
    t0 = time.time()
    xgb_base = XGBClassifier(
        n_estimators=200,
        max_depth=5,
        learning_rate=0.05,
        random_state=RANDOM_STATE,
        eval_metric="logloss",
        use_label_encoder=False,
        n_jobs=-1,
    )
    xgb_base.fit(X_train, y_train)
    logger.info(f"XGBoost Baseline trained in {time.time() - t0:.2f}s")
    metrics_list.append(evaluate_model("XGBoost (Baseline)", xgb_base, X_test, y_test))

    # 2. Random Forest
    logger.info("Training 2/3: Random Forest Classifier...")
    t0 = time.time()
    rf = RandomForestClassifier(
        n_estimators=200,
        max_depth=12,
        min_samples_split=10,
        min_samples_leaf=4,
        random_state=RANDOM_STATE,
        n_jobs=-1,
    )
    rf.fit(X_train, y_train)
    logger.info(f"Random Forest trained in {time.time() - t0:.2f}s")
    metrics_list.append(evaluate_model("Random Forest", rf, X_test, y_test))

    # 3. Support Vector Machine (SVM)
    logger.info("Training 3/3: Support Vector Machine (SVC)...")
    t0 = time.time()
    # If training dataset is large (> 10k), use a representative stratified subsample for SVM fitting
    # to avoid O(N^3) bottleneck while preserving calibration and support vectors
    if len(X_train) > 10000:
        logger.info(f"Subsampling 8,000 samples for SVM training efficiency (total={len(X_train)})...")
        from sklearn.model_selection import StratifiedShuffleSplit
        sss = StratifiedShuffleSplit(n_splits=1, train_size=8000, random_state=RANDOM_STATE)
        idx, _ = next(sss.split(X_train, y_train))
        X_train_svm = X_train.iloc[idx]
        y_train_svm = y_train.iloc[idx]
    else:
        X_train_svm = X_train
        y_train_svm = y_train

    svm = SVC(
        C=1.0,
        kernel="rbf",
        probability=True,
        random_state=RANDOM_STATE,
        cache_size=1000,
        max_iter=3000,
    )
    svm.fit(X_train_svm, y_train_svm)
    logger.info(f"Support Vector Machine trained in {time.time() - t0:.2f}s")
    metrics_list.append(evaluate_model("Support Vector Machine (SVM)", svm, X_test, y_test))

    # 4. Optuna Hyperparameter Optimization for XGBoost
    champion_model = xgb_base
    champion_name = "XGBoost (Baseline)"

    if run_optuna:
        best_params, best_cv_score = tune_xgboost_optuna(
            X_train, y_train, n_trials=optuna_trials, timeout=OPTUNA_TIMEOUT
        )
        logger.info("Fitting final tuned XGBoost with best Optuna parameters on full training set...")
        xgb_tuned = XGBClassifier(
            **best_params,
            random_state=RANDOM_STATE,
            eval_metric="logloss",
            use_label_encoder=False,
            n_jobs=-1,
        )
        xgb_tuned.fit(X_train, y_train)

        tuned_metrics = evaluate_model("XGBoost (Optuna Tuned)", xgb_tuned, X_test, y_test)
        metrics_list.append(tuned_metrics)

        # Compare with baseline
        if tuned_metrics["ROC-AUC"] >= metrics_list[0]["ROC-AUC"]:
            champion_model = xgb_tuned
            champion_name = "XGBoost (Optuna Tuned)"
        else:
            champion_model = xgb_base
            champion_name = "XGBoost (Baseline)"
    else:
        best_params = xgb_base.get_params()
        best_cv_score = None

    # Format and save comparison table
    comparison_table_md = format_metrics_table(metrics_list)
    df_metrics = pd.DataFrame(metrics_list).sort_values(by="ROC-AUC", ascending=False)

    df_metrics.to_csv(METRICS_CSV_FILE, index=False)
    with open(METRICS_MD_FILE, "w", encoding="utf-8") as f:
        f.write("# Cardiovascular Disease Prediction: Model Comparison\n\n")
        f.write(f"*Evaluated on Holdout Test Set (N = {len(X_test):,})*\n\n")
        f.write(comparison_table_md)
        f.write("\n\n*Selected Champion Model for Phase 3 (XAI) and Phase 4 (Dashboard):* **" + champion_name + "**\n")

    logger.info("\n" + "=" * 65 + "\n" + "MODEL COMPARISON SUMMARY TABLE:\n" + "=" * 65 + "\n" + comparison_table_md + "\n" + "=" * 65)

    # Persist Champion Model & Metadata
    save_artifact(champion_model, BEST_MODEL_FILE)
    logger.info(f"Champion Model ({champion_name}) serialized to: {BEST_MODEL_FILE}")

    metadata = {
        "champion_model": champion_name,
        "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "best_hyperparameters": best_params if run_optuna else "default_baseline",
        "best_cv_score": best_cv_score,
        "features": list(X_train.columns),
        "metrics_summary": metrics_list,
    }
    save_json(metadata, MODEL_METADATA_FILE)
    logger.info(f"Model metadata serialized to: {MODEL_METADATA_FILE}")
    logger.info("========== PHASE 2 COMPLETED SUCCESSFULLY ==========")

    return df_metrics, champion_model


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Phase 2: Model Training and Optuna Tuning")
    parser.add_argument(
        "--optuna-trials",
        type=int,
        default=OPTUNA_N_TRIALS,
        help="Number of Optuna search trials",
    )
    parser.add_argument(
        "--skip-optuna",
        action="store_true",
        help="Skip hyperparameter tuning and evaluate baselines only",
    )
    args = parser.parse_args()

    train_and_compare(run_optuna=not args.skip_optuna, optuna_trials=args.optuna_trials)
