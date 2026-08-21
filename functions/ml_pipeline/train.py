import os
import time
import numpy as np
import pandas as pd
from datetime import datetime, timezone
import optuna
from sklearn.model_selection import KFold
from sklearn.metrics import mean_squared_error
from firebase_admin import firestore

from ml_pipeline.model import SipandaMultivariateModel, get_default_model_path

# Mute verbose Optuna logs in production
optuna.logging.set_verbosity(optuna.logging.WARNING)

def extract_features_and_targets_from_history(records: list):
    """
    Transforms raw telemetry history list into Feature Matrix (X) and Target Matrix (Y).
    X shape: (N, 11) -> [rain, temp, hu, pressure, rain_lag1, temp_lag1, hu_lag1, rain_lag2, temp_lag2, hu_lag2, delta_rain]
    Y shape: (N, 9)  -> [rain_t1, rain_t2, rain_t3, temp_t1, temp_t2, temp_t3, hu_t1, hu_t2, hu_t3]
    """
    df = pd.DataFrame(records)
    
    # Sort chronologically
    if 'timestamp' in df.columns:
        df = df.sort_values(by='timestamp').reset_index(drop=True)
        
    # Ensure standard numeric columns
    for col in ['rainfall', 'temp', 'humidity', 'pressure']:
        if col not in df.columns:
            if col == 'rainfall': df[col] = 0.0
            elif col == 'temp': df[col] = 28.0
            elif col == 'humidity': df[col] = 75.0
            elif col == 'pressure': df[col] = 1010.0
        df[col] = pd.to_numeric(df[col], errors='coerce').fillna(0.0)

    # Generate Lag Features
    df['rain_lag1'] = df['rainfall'].shift(1).fillna(df['rainfall'])
    df['temp_lag1'] = df['temp'].shift(1).fillna(df['temp'])
    df['hu_lag1']   = df['humidity'].shift(1).fillna(df['humidity'])
    
    df['rain_lag2'] = df['rainfall'].shift(2).fillna(df['rain_lag1'])
    df['temp_lag2'] = df['temp'].shift(2).fillna(df['temp_lag1'])
    df['hu_lag2']   = df['humidity'].shift(2).fillna(df['hu_lag1'])
    
    df['delta_rain'] = df['rainfall'] - df['rain_lag1']

    # Generate Multi-Step Target Labels (T+1, T+2, T+3)
    df['target_rain_t1'] = df['rainfall'].shift(-1)
    df['target_rain_t2'] = df['rainfall'].shift(-2)
    df['target_rain_t3'] = df['rainfall'].shift(-3)
    
    df['target_temp_t1'] = df['temp'].shift(-1)
    df['target_temp_t2'] = df['temp'].shift(-2)
    df['target_temp_t3'] = df['temp'].shift(-3)
    
    df['target_hu_t1']   = df['humidity'].shift(-1)
    df['target_hu_t2']   = df['humidity'].shift(-2)
    df['target_hu_t3']   = df['humidity'].shift(-3)

    # Drop incomplete rows due to lead shifting or fill with reasonable trend extrapolation
    df = df.bfill().ffill()

    feature_cols = [
        'rainfall', 'temp', 'humidity', 'pressure',
        'rain_lag1', 'temp_lag1', 'hu_lag1',
        'rain_lag2', 'temp_lag2', 'hu_lag2',
        'delta_rain'
    ]
    target_cols = [
        'target_rain_t1', 'target_rain_t2', 'target_rain_t3',
        'target_temp_t1', 'target_temp_t2', 'target_temp_t3',
        'target_hu_t1',   'target_hu_t2',   'target_hu_t3'
    ]

    X = df[feature_cols].values
    Y = df[target_cols].values
    return X, Y


def generate_synthetic_history(count=500):
    """
    Generates synthetic 500-sample hydrometeorological time-series
    for Semarang City as a warm-start dataset if database is newly initialized.
    """
    np.random.seed(int(time.time()) % 100000)
    data = []
    base_time = int(time.time()) - (count * 15 * 60) # 15 min interval
    
    curr_rain = 5.0
    curr_temp = 29.0
    curr_hu = 75.0
    
    for i in range(count):
        # Markov random walk with seasonal trends
        rain_step = np.random.normal(0, 3.0)
        curr_rain = max(0.0, min(120.0, curr_rain + rain_step))
        
        # Temp inverse to rain
        temp_drift = -0.05 * curr_rain + np.random.normal(0, 0.4)
        curr_temp = max(22.0, min(36.0, 30.0 + temp_drift))
        
        # Humidity proportional to rain
        hu_drift = 0.3 * curr_rain + np.random.normal(0, 1.5)
        curr_hu = max(50.0, min(99.0, 70.0 + hu_drift))
        
        data.append({
            'timestamp': datetime.fromtimestamp(base_time + (i * 900), tz=timezone.utc),
            'rainfall': float(round(curr_rain, 2)),
            'temp': float(round(curr_temp, 2)),
            'humidity': float(round(curr_hu, 2)),
            'pressure': float(round(1012.0 - (curr_rain * 0.05) + np.random.normal(0, 0.5), 2)),
            'district_name': 'Semarang Batch'
        })
    return data


def retrain_with_bayesian_optimization(db, max_records=500, n_trials=25):
    """
    Periodic 3-Hour Retraining Pipeline.
    1. Fetches up to 500 recent records from Firestore 'telemetry_history'.
    2. Runs Bayesian Optimization (Optuna) to auto-tune XGBoost hyperparameters.
    3. Fits model on 500 records and saves to 'model_latest.pkl'.
    4. Records metadata in 'config/ml_metadata'.
    """
    print(f"\n[SIPANDA RETRAIN] Starting 3-Hour Auto-Tuning Pipeline (Limit: {max_records} records)...")
    start_time = time.time()
    
    records = []
    try:
        if db is not None:
            # Query last 500 history records
            docs = db.collection("telemetry_history")\
                     .order_by("timestamp", direction=firestore.Query.DESCENDING)\
                     .limit(max_records)\
                     .stream()
            records = [d.to_dict() for d in docs]
            print(f"[SIPANDA RETRAIN] Fetched {len(records)} records from Firestore 'telemetry_history'.")
    except Exception as e:
        print(f"[SIPANDA RETRAIN] Warning: Failed to query Firestore history: {e}")

    # Fallback to bootstrap synthetic data if not enough history
    if len(records) < 50:
        print(f"[SIPANDA RETRAIN] Database has only {len(records)} records (< 50). Augmenting with synthetic history to reach {max_records}...")
        records = generate_synthetic_history(max_records)

    X, Y = extract_features_and_targets_from_history(records)
    print(f"[SIPANDA RETRAIN] Dataset prepared: X shape {X.shape}, Y shape {Y.shape}")

    # 2. Bayesian Optimization Objective via Optuna (TPE Sampler)
    def objective(trial):
        params = {
            'n_estimators': trial.suggest_int('n_estimators', 50, 250),
            'max_depth': trial.suggest_int('max_depth', 3, 8),
            'learning_rate': trial.suggest_float('learning_rate', 0.01, 0.25, log=True),
            'subsample': trial.suggest_float('subsample', 0.6, 1.0),
            'colsample_bytree': trial.suggest_float('colsample_bytree', 0.6, 1.0),
            'gamma': trial.suggest_float('gamma', 0.0, 3.0),
            'reg_alpha': trial.suggest_float('reg_alpha', 1e-6, 5.0, log=True),
            'reg_lambda': trial.suggest_float('reg_lambda', 1e-6, 5.0, log=True),
            'random_state': 42,
            'n_jobs': -1
        }
        
        # 5-Fold Cross Validation
        kf = KFold(n_splits=5, shuffle=True, random_state=42)
        cv_rmse = []
        
        for train_idx, val_idx in kf.split(X):
            X_tr, X_val = X[train_idx], X[val_idx]
            Y_tr, Y_val = Y[train_idx], Y[val_idx]
            
            temp_model = SipandaMultivariateModel(best_params=params)
            temp_model.fit(X_tr, Y_tr)
            preds = temp_model.predict(X_val)
            
            # Root Mean Squared Error across all 9 outputs
            rmse = np.sqrt(mean_squared_error(Y_val, preds))
            cv_rmse.append(rmse)
            
        return float(np.mean(cv_rmse))

    print(f"[SIPANDA RETRAIN] Running Bayesian Optimization ({n_trials} trials)...")
    study = optuna.create_study(direction='minimize')
    study.optimize(objective, n_trials=n_trials, timeout=20)
    
    best_params = study.best_params
    best_rmse = study.best_value
    elapsed_time = round(time.time() - start_time, 2)
    
    print(f"[SIPANDA RETRAIN] Optimization Completed in {elapsed_time}s!")
    print(f"[SIPANDA RETRAIN] Best Cross-Validation RMSE: {best_rmse:.4f}")
    print(f"[SIPANDA RETRAIN] Best Hyperparameters: {best_params}")

    # 3. Fit Final Model on All Records
    final_model = SipandaMultivariateModel(best_params=best_params)
    final_model.fit(X, Y)
    
    # 4. Save to model_latest.pkl
    save_path = get_default_model_path()
    final_model.save(save_path)

    # 5. Commit Metadata to Firestore
    metadata = {
        "last_trained_at": firestore.SERVER_TIMESTAMP if db else datetime.now(timezone.utc).isoformat(),
        "trained_records_count": len(X),
        "best_rmse": float(round(best_rmse, 4)),
        "best_hyperparameters": best_params,
        "optimization_algorithm": "Optuna TPE (Bayesian Optimization)",
        "training_duration_seconds": elapsed_time,
        "model_file": os.path.basename(save_path),
        "target_variables": ["rainfall_3h", "temperature_3h", "humidity_3h"]
    }
    
    if db is not None:
        try:
            db.collection("config").document("ml_metadata").set(metadata, merge=True)
            print("[SIPANDA RETRAIN] Metadata logged to Firestore 'config/ml_metadata'.")
        except Exception as e:
            print(f"[SIPANDA RETRAIN] Warning: Failed to write Firestore metadata: {e}")

    return final_model, metadata
