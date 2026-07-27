from ml_pipeline.model import load_stacking_ensemble

def run_prediction(db, telemetry_data: dict):
    """
    Predicts risk levels and updates Firestore.
    """
    model = load_stacking_ensemble()
    
    # Process districts
    for doc_id, data in telemetry_data.items():
        # Feature extraction
        features = [[data["rainfall"], data["pressure"], data["temp"]]]
        
        # Predict flood probability
        probability = model.predict_proba(features)[0][1] * 100
        
        # Classify Risk (Aman/Waspada/Siaga)
        if probability > 70:
            risk = "siaga"
        elif probability > 40:
            risk = "waspada"
        else:
            risk = "aman"
            
        print(f"[{data['name']}] Prob: {probability:.1f}% -> {risk.upper()}")
        
        # Commit to Firestore
        doc_ref = db.collection("districts").document(doc_id)
        doc_ref.set({
            "name": data["name"],
            "rainfall": data["rainfall"],
            "flood_prob": probability,
            "ml_risk": risk,
            # Use merge=True to ensure we don't accidentally overwrite 'override_risk' set by admin
        }, merge=True)
