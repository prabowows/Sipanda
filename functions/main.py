import os
from datetime import datetime, timezone
from firebase_admin import initialize_app, firestore
from firebase_functions import scheduler_fn

from core.telemetry_fetch import ingest_telemetry
from ml_pipeline.predict import run_prediction

# Initialize Firebase Admin
app = initialize_app()
db = firestore.client()

@scheduler_fn.on_schedule(schedule="every 15 minutes")  # Runs every 15 minutes
def scheduled_fetch(event: scheduler_fn.ScheduledEvent) -> None:
    """
    Firebase Scheduled Function 24/7.
    Fetches weather data for all 16 districts from BMKG live API,
    runs ML flood prediction model, and commits updates to Firestore.
    """
    print("[SIPANDA SCHEDULER] Starting live telemetry ingestion for 16 Semarang districts...")
    
    # 1. Fetch live telemetry for all 16 districts
    weather_data = ingest_telemetry()
    print(f"[SIPANDA SCHEDULER] Successfully fetched {len(weather_data)} districts from BMKG API.")
    
    # 2. Run ML Stacking Ensemble Prediction & update Firestore
    print("[SIPANDA SCHEDULER] Running Stacking Ensemble ML inference...")
    run_prediction(db, weather_data)
    
    # 3. Record last fetch timestamp in config/system
    db.collection("config").document("system").set({
        "last_api_fetch": firestore.SERVER_TIMESTAMP,
        "last_fetch_status": "SUCCESS",
        "districts_count": len(weather_data)
    }, merge=True)
    
    print("[SIPANDA SCHEDULER] Task completed successfully!")
