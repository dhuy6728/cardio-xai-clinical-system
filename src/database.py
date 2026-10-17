"""
SQL Database Management Layer for CardioXAI.
Supports local SQLite (zero-cost, zero-configuration) and cloud PostgreSQL (Supabase / Neon / Firebase sync).
"""

import hashlib
import json
import os
import sqlite3
import uuid
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List, Optional

# Database file location for zero-cost local storage
BASE_DIR = Path(__file__).resolve().parent.parent
DB_FILE = BASE_DIR / "data" / "cardioxai.db"


def _hash_password(password: str) -> str:
    """Zero-cost SHA-256 salted password hashing."""
    salt = "cardio_xai_clinical_salt_2026"
    return hashlib.sha256((password + salt).encode("utf-8")).hexdigest()


def get_connection() -> sqlite3.Connection:
    """Creates a connection with row-dictionary factory for clean JSON serialization."""
    DB_FILE.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(str(DB_FILE))
    conn.row_factory = sqlite3.Row
    return conn


def init_db() -> None:
    """Initializes relational tables: users, patient_records, and xai_audit_logs."""
    conn = get_connection()
    cursor = conn.cursor()

    # 1. Users table (linked with Firebase UID / Local Auth)
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        firebase_uid TEXT UNIQUE,
        email TEXT UNIQUE,
        password_hash TEXT,
        full_name TEXT,
        role TEXT DEFAULT 'patient', -- 'patient' or 'doctor'
        phone TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    """)

    # 2. Patient clinical records table (Time-series longitudinal tracking)
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS patient_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        patient_name TEXT DEFAULT 'Bệnh nhân',
        age REAL NOT NULL,
        gender INTEGER NOT NULL,
        height REAL NOT NULL,
        weight REAL NOT NULL,
        bmi REAL NOT NULL,
        ap_hi INTEGER NOT NULL,
        ap_lo INTEGER NOT NULL,
        cholesterol INTEGER NOT NULL,
        gluc INTEGER NOT NULL,
        smoke INTEGER NOT NULL,
        alco INTEGER NOT NULL,
        active INTEGER NOT NULL,
        risk_probability REAL NOT NULL,
        risk_level TEXT NOT NULL,
        recommendation TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users (id)
    );
    """)

    # 3. XAI Explanations Audit Trail
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS xai_audit_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        record_id INTEGER NOT NULL,
        shap_values_json TEXT NOT NULL,
        lime_rules_json TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (record_id) REFERENCES patient_records (id)
    );
    """)

    conn.commit()
    conn.close()


# ==========================================
# AUTHENTICATION & USER MANAGEMENT
# ==========================================
def register_user(
    email: str,
    password: str,
    full_name: str,
    firebase_uid: Optional[str] = None,
    phone: Optional[str] = None,
    role: str = "patient",
) -> Dict[str, Any]:
    """Registers a new user into SQL database (supports Firebase sync)."""
    conn = get_connection()
    cursor = conn.cursor()

    email_clean = email.strip().lower()
    cursor.execute("SELECT id FROM users WHERE email = ?", (email_clean,))
    if cursor.fetchone():
        conn.close()
        raise ValueError("Email này đã được đăng ký trong hệ thống!")

    uid = firebase_uid or f"fb_{uuid.uuid4().hex[:16]}"
    pwd_hash = _hash_password(password)

    cursor.execute("""
    INSERT INTO users (firebase_uid, email, password_hash, full_name, role, phone)
    VALUES (?, ?, ?, ?, ?, ?)
    """, (uid, email_clean, pwd_hash, full_name.strip(), role, phone))

    user_id = cursor.lastrowid
    conn.commit()
    conn.close()

    return {
        "id": user_id,
        "firebase_uid": uid,
        "email": email_clean,
        "full_name": full_name.strip(),
        "role": role,
    }


def authenticate_user(email: str, password: str) -> Optional[Dict[str, Any]]:
    """Authenticates email and password against local SQL database."""
    conn = get_connection()
    cursor = conn.cursor()

    email_clean = email.strip().lower()
    pwd_hash = _hash_password(password)

    cursor.execute(
        "SELECT id, firebase_uid, email, full_name, role, phone, created_at FROM users WHERE email = ? AND password_hash = ?",
        (email_clean, pwd_hash),
    )
    row = cursor.fetchone()
    conn.close()

    if row:
        return dict(row)
    return None


def update_user_password(email: str, old_password: str, new_password: str) -> bool:
    """Updates password verifying the previous password."""
    conn = get_connection()
    cursor = conn.cursor()

    email_clean = email.strip().lower()
    old_hash = _hash_password(old_password)
    new_hash = _hash_password(new_password)

    cursor.execute("SELECT id FROM users WHERE email = ? AND password_hash = ?", (email_clean, old_hash))
    user = cursor.fetchone()
    if not user:
        conn.close()
        return False

    cursor.execute("UPDATE users SET password_hash = ? WHERE id = ?", (new_hash, user["id"]))
    conn.commit()
    conn.close()
    return True


# ==========================================
# CLINICAL RECORDS MANAGEMENT
# ==========================================
def save_patient_record(
    patient_data: Dict[str, Any],
    risk_prob: float,
    risk_level: str,
    recommendation: str,
    shap_data: Optional[Dict[str, Any]] = None,
    lime_data: Optional[List[Dict[str, Any]]] = None,
    user_id: Optional[int] = None,
    patient_name: str = "Bệnh nhân",
) -> int:
    """Inserts a new clinical record and optional XAI audit log."""
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("""
    INSERT INTO patient_records (
        user_id, patient_name, age, gender, height, weight, bmi,
        ap_hi, ap_lo, cholesterol, gluc, smoke, alco, active,
        risk_probability, risk_level, recommendation
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """, (
        user_id,
        patient_name,
        patient_data["age"],
        patient_data["gender"],
        patient_data["height"],
        patient_data["weight"],
        patient_data["bmi"],
        patient_data["ap_hi"],
        patient_data["ap_lo"],
        patient_data["cholesterol"],
        patient_data["gluc"],
        patient_data["smoke"],
        patient_data["alco"],
        patient_data["active"],
        risk_prob,
        risk_level,
        recommendation,
    ))

    record_id = cursor.lastrowid

    if shap_data or lime_data:
        cursor.execute("""
        INSERT INTO xai_audit_logs (record_id, shap_values_json, lime_rules_json)
        VALUES (?, ?, ?)
        """, (
            record_id,
            json.dumps(shap_data or {}, ensure_ascii=False),
            json.dumps(lime_data or [], ensure_ascii=False),
        ))

    conn.commit()
    conn.close()
    return record_id


def save_assessment(
    patient_name: str,
    patient_data: Dict[str, Any],
    risk_prob: float,
    risk_level: str,
    recommendation: str,
    shap_data: Optional[Dict[str, Any]] = None,
    lime_data: Optional[List[Dict[str, Any]]] = None,
    user_id: Optional[int] = None,
) -> int:
    """Convenience wrapper for save_patient_record."""
    return save_patient_record(
        patient_data=patient_data,
        risk_prob=risk_prob,
        risk_level=risk_level,
        recommendation=recommendation,
        shap_data=shap_data,
        lime_data=lime_data,
        user_id=user_id,
        patient_name=patient_name,
    )


def get_patient_history(user_id: Optional[int] = None, limit: int = 50) -> List[Dict[str, Any]]:
    """Retrieves patient historical records ordered by timestamp descending."""
    conn = get_connection()
    cursor = conn.cursor()

    if user_id:
        cursor.execute(
            "SELECT * FROM patient_records WHERE user_id = ? ORDER BY created_at DESC LIMIT ?",
            (user_id, limit),
        )
    else:
        cursor.execute(
            "SELECT * FROM patient_records ORDER BY created_at DESC LIMIT ?",
            (limit,),
        )

    rows = cursor.fetchall()
    results = [dict(row) for row in rows]
    conn.close()
    return results


def get_all_records(limit: int = 100) -> List[Dict[str, Any]]:
    """Alias for get_patient_history."""
    return get_patient_history(user_id=None, limit=limit)


def get_record_with_xai(record_id: int) -> Optional[Dict[str, Any]]:
    """Fetches a specific record alongside its XAI explanation audit log."""
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("SELECT * FROM patient_records WHERE id = ?", (record_id,))
    rec = cursor.fetchone()
    if not rec:
        conn.close()
        return None

    data = dict(rec)
    cursor.execute("SELECT * FROM xai_audit_logs WHERE record_id = ?", (record_id,))
    xai = cursor.fetchone()
    if xai:
        data["xai_audit"] = {
            "shap_values": json.loads(xai["shap_values_json"]),
            "lime_rules": json.loads(xai["lime_rules_json"]),
        }
    else:
        data["xai_audit"] = None

    conn.close()
    return data


# Auto-initialize database on import
init_db()
