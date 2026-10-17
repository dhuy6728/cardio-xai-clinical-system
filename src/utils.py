"""
Utility functions for logging, model serialization, and metrics evaluation.
"""

import json
import logging
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional
import joblib
import pandas as pd
from tabulate import tabulate


def setup_logger(name: str = "CardioXAI", log_file: Optional[Path] = None) -> logging.Logger:
    """Configures a standardized, informative console and file logger."""
    logger = logging.getLogger(name)
    logger.setLevel(logging.INFO)

    if not logger.handlers:
        formatter = logging.Formatter(
            "[%(asctime)s] [%(levelname)s] [%(filename)s:%(lineno)d] - %(message)s",
            datefmt="%Y-%m-%d %H:%M:%S",
        )

        console_handler = logging.StreamHandler(sys.stdout)
        console_handler.setFormatter(formatter)
        logger.addHandler(console_handler)

        if log_file:
            log_file.parent.mkdir(parents=True, exist_ok=True)
            file_handler = logging.FileHandler(str(log_file), encoding="utf-8")
            file_handler.setFormatter(formatter)
            logger.addHandler(file_handler)

    return logger


def save_artifact(obj: Any, file_path: Path) -> None:
    """Saves a Python object using joblib with high compression."""
    file_path.parent.mkdir(parents=True, exist_ok=True)
    joblib.dump(obj, file_path, compress=3)


def load_artifact(file_path: Path) -> Any:
    """Loads a serialized artifact using joblib."""
    if not file_path.exists():
        raise FileNotFoundError(f"Artifact not found: {file_path}")
    return joblib.load(file_path)


def save_json(data: Dict[str, Any], file_path: Path) -> None:
    """Saves dictionary data to a formatted JSON file."""
    file_path.parent.mkdir(parents=True, exist_ok=True)
    with open(file_path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=4, ensure_ascii=False)


def load_json(file_path: Path) -> Dict[str, Any]:
    """Loads JSON data from file."""
    if not file_path.exists():
        raise FileNotFoundError(f"JSON file not found: {file_path}")
    with open(file_path, "r", encoding="utf-8") as f:
        return json.load(f)


def format_metrics_table(results: List[Dict[str, Any]]) -> str:
    """Formats model evaluation metrics as a clean GitHub-Flavored Markdown table."""
    df_metrics = pd.DataFrame(results)
    # Sort by ROC-AUC descending
    if "ROC-AUC" in df_metrics.columns:
        df_metrics = df_metrics.sort_values(by="ROC-AUC", ascending=False)

    return tabulate(df_metrics, headers="keys", tablefmt="github", floatfmt=".4f", showindex=False)
