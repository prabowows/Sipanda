import numpy as np
from datetime import datetime, timezone
from firebase_admin import firestore
from ml_pipeline.model import load_or_init_model

def classify_flood_risk(rainfall_mm: float, humidity_pct: float) -> tuple[str, float]:
    """
    Classifies flood risk severity and probability based on rainfall and humidity thresholds.
    Returns: (risk_level: 'aman'|'waspada'|'siaga', flood_prob_pct: float)
    """
    # Weighted risk heuristic: Heavy rain (>20mm) or moderate rain + saturated humidity (>85%)
    if rainfall_mm >= 20.0 or (rainfall_mm >= 15.0 and humidity_pct >= 85.0):
        prob = min(98.0, 70.0 + (rainfall_mm * 1.2))
        return "siaga", round(prob, 1)
    elif rainfall_mm >= 7.0 or (rainfall_mm >= 5.0 and humidity_pct >= 80.0):
        prob = min(69.0, 40.0 + (rainfall_mm * 2.0))
        return "waspada", round(prob, 1)
    else:
        prob = min(39.0, max(5.0, rainfall_mm * 3.0 + (humidity_pct * 0.1)))
        return "aman", round(prob, 1)


def run_prediction(db, telemetry_data: dict):
    """
    Event-driven inference triggered every time telemetry is fetched.
    Loads 'model_latest.pkl' and generates 3-hour multivariate forecast
    (Rainfall, Temperature, Humidity, and Risk Level).
    """
    model = load_or_init_model()
    now_utc = datetime.now(timezone.utc)
    
    predictions_summary = {}

    for doc_id, data in telemetry_data.items():
        name = data.get("name", doc_id)
        rainfall = float(data.get("rainfall", 0.0))
        temp = float(data.get("temp", 28.0))
        humidity = float(data.get("humidity", 75.0))
        pressure = float(data.get("pressure", 1010.0))

        # Lag features from history or fallback to current
        rain_lag1 = float(data.get("rain_lag1", rainfall))
        temp_lag1 = float(data.get("temp_lag1", temp))
        hu_lag1   = float(data.get("hu_lag1", humidity))
        
        rain_lag2 = float(data.get("rain_lag2", rain_lag1))
        temp_lag2 = float(data.get("temp_lag2", temp_lag1))
        hu_lag2   = float(data.get("hu_lag2", hu_lag1))
        
        delta_rain = rainfall - rain_lag1

        # Feature Vector (1, 11)
        features = np.array([[
            rainfall, temp, humidity, pressure,
            rain_lag1, temp_lag1, hu_lag1,
            rain_lag2, temp_lag2, hu_lag2,
            delta_rain
        ]])

        # Predict 3-hour horizon (9 targets)
        pred = model.predict(features)[0]
        
        rain_t1, rain_t2, rain_t3 = float(pred[0]), float(pred[1]), float(pred[2])
        temp_t1, temp_t2, temp_t3 = float(pred[3]), float(pred[4]), float(pred[5])
        hu_t1, hu_t2, hu_t3       = float(pred[6]), float(pred[7]), float(pred[8])

        risk_t1, prob_t1 = classify_flood_risk(rain_t1, hu_t1)
        risk_t2, prob_t2 = classify_flood_risk(rain_t2, hu_t2)
        risk_t3, prob_t3 = classify_flood_risk(rain_t3, hu_t3)

        current_risk, current_prob = classify_flood_risk(rainfall, humidity)

        # Build 3-hour forecast array for Flutter time-series chart
        forecast_3h = [
            {
                "hour_offset": 1,
                "time_label": "+1 Jam",
                "rainfall": round(rain_t1, 1),
                "temp": round(temp_t1, 1),
                "humidity": round(hu_t1, 0),
                "risk": risk_t1,
                "flood_prob": prob_t1,
                "is_prediction": True
            },
            {
                "hour_offset": 2,
                "time_label": "+2 Jam",
                "rainfall": round(rain_t2, 1),
                "temp": round(temp_t2, 1),
                "humidity": round(hu_t2, 0),
                "risk": risk_t2,
                "flood_prob": prob_t2,
                "is_prediction": True
            },
            {
                "hour_offset": 3,
                "time_label": "+3 Jam",
                "rainfall": round(rain_t3, 1),
                "temp": round(temp_t3, 1),
                "humidity": round(hu_t3, 0),
                "risk": risk_t3,
                "flood_prob": prob_t3,
                "is_prediction": True
            }
        ]

        # Overall peak risk in next 3 hours
        all_risks = [current_risk, risk_t1, risk_t2, risk_t3]
        if "siaga" in all_risks: peak_risk = "siaga"
        elif "waspada" in all_risks: peak_risk = "waspada"
        else: peak_risk = "aman"
        
        peak_prob = max(current_prob, prob_t1, prob_t2, prob_t3)

        predictions_summary[doc_id] = {
            "name": name,
            "current_rainfall": rainfall,
            "current_temp": temp,
            "current_humidity": humidity,
            "current_risk": current_risk,
            "peak_risk_3h": peak_risk,
            "peak_prob_3h": peak_prob,
            "forecast_3h": forecast_3h
        }

        if db is not None:
            # 1. Update active district state
            doc_ref = db.collection("districts").document(doc_id)
            doc_ref.set({
                "name": name,
                "rainfall": rainfall,
                "temp": temp,
                "humidity": humidity,
                "pressure": pressure,
                "flood_prob": current_prob,
                "ml_risk": current_risk,
                "peak_risk_3h": peak_risk,
                "peak_prob_3h": peak_prob,
                "forecast_3h": forecast_3h,
                "last_updated": firestore.SERVER_TIMESTAMP
            }, merge=True)

            # 2. Append to telemetry history for future 3-hour retraining buffer
            try:
                db.collection("telemetry_history").add({
                    "district_id": doc_id,
                    "district_name": name,
                    "rainfall": rainfall,
                    "temp": temp,
                    "humidity": humidity,
                    "pressure": pressure,
                    "timestamp": firestore.SERVER_TIMESTAMP
                })
            except Exception as e:
                print(f"[SIPANDA INFERENCE] Warning: Failed logging to telemetry_history: {e}")

    print(f"[SIPANDA INFERENCE] Multivariate 3-hour forecast updated for {len(predictions_summary)} districts.")
    return predictions_summary
