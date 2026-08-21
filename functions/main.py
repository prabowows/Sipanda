import os
from datetime import datetime, timezone
from firebase_admin import initialize_app, firestore
from firebase_functions import scheduler_fn

from core.telemetry_fetch import ingest_telemetry
from ml_pipeline.predict import run_prediction
from ml_pipeline.train import retrain_with_bayesian_optimization

# Initialize Firebase Admin
app = initialize_app()
db = firestore.client()

@scheduler_fn.on_schedule(schedule="every 15 minutes")
def scheduled_fetch(event: scheduler_fn.ScheduledEvent) -> None:
    """
    Data Ingestion & Event-Driven Inference Pipeline:
    Fetches latest telemetry from BMKG weather API and immediately
    runs Multivariate XGBoost inference (3-Hour Forecast) for all 16 districts.
    """
    print("[SIPANDA SCHEDULER] Starting live telemetry ingestion for 16 Semarang districts...")
    
    # 1. Fetch live telemetry for all 16 districts
    weather_data = ingest_telemetry()
    print(f"[SIPANDA SCHEDULER] Fetched {len(weather_data)} districts from BMKG API.")
    
    # 2. Run Multivariate ML Inference & commit forecast_3h to Firestore
    print("[SIPANDA SCHEDULER] Running Multivariate 3-Hour Time-Series Inference...")
    run_prediction(db, weather_data)
    
    # 3. Record fetch metadata in config/system
    db.collection("config").document("system").set({
        "last_api_fetch": firestore.SERVER_TIMESTAMP,
        "last_fetch_status": "SUCCESS",
        "districts_count": len(weather_data)
    }, merge=True)
    
    print("[SIPANDA SCHEDULER] Telemetry ingestion & inference completed successfully!")


@scheduler_fn.on_schedule(schedule="every 3 hours")
def scheduled_retrain(event: scheduler_fn.ScheduledEvent) -> None:
    """
    Periodic 3-Hour Auto-Tuning & Retraining Pipeline:
    Queries the last 500 records from 'telemetry_history',
    auto-tunes XGBoost hyperparameters using Bayesian Optimization (Optuna),
    and updates 'model_latest.pkl'.
    """
    print("[SIPANDA RETRAIN] Starting 3-Hour Bayesian Auto-Tuning Pipeline...")
    try:
        retrain_with_bayesian_optimization(db, max_records=500, n_trials=25)
        print("[SIPANDA RETRAIN] 3-Hour Auto-Tune completed successfully!")
    except Exception as e:
        print(f"[SIPANDA RETRAIN] Error during 3-hour retrain: {e}")
