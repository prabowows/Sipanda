import os
import sys
import time

# Pastikan path modul terbaca
sys.path.insert(0, os.path.dirname(__file__))

from ml_pipeline.train import retrain_with_bayesian_optimization
from ml_pipeline.predict import run_prediction

def test_full_pipeline_local():
    print("=" * 70)
    print("🚀 SIPANDA ML PIPELINE LOCAL TEST (XGBOOST + BAYESIAN AUTO-TUNE)")
    print("=" * 70)

    # 1. TEST AUTO-TUNING PIPELINE (500 RECORDS)
    print("\n[STEP 1] Menjalankan Retraining & Auto-Tuning Bayesian (Optuna)...")
    print("Sedang mengoptimasi hyperparameter XGBoost pada 500 record data...")
    
    # Run with None db to use synthetic bootstrap data locally
    model, metadata = retrain_with_bayesian_optimization(db=None, max_records=500, n_trials=15)
    
    print("\n✅ [STEP 1 SELESAI] Hasil Auto-Tuning:")
    print(f"  • Best Cross-Validation RMSE : {metadata['best_rmse']}")
    print(f"  • Durasi Optimasi           : {metadata['training_duration_seconds']} detik")
    print(f"  • Model Tersimpan           : {metadata['model_file']}")
    print(f"  • Best Hyperparameters      : {metadata['best_hyperparameters']}")

    # 2. TEST INFERENCE (SETIAP TARIK DATA)
    print("\n" + "=" * 70)
    print("[STEP 2] Menjalankan Inferensi Proyeksi 3 Jam ke Depan...")
    
    sample_telemetry = {
        "semarang_tengah": {
            "name": "Semarang Tengah",
            "rainfall": 14.5,
            "temp": 28.2,
            "humidity": 84.0,
            "pressure": 1008.5,
            "rain_lag1": 11.0,
            "temp_lag1": 28.8,
            "hu_lag1": 80.0,
        },
        "genuk": {
            "name": "Genuk (Daerah Rawan)",
            "rainfall": 22.0,
            "temp": 27.0,
            "humidity": 92.0,
            "pressure": 1006.0,
            "rain_lag1": 18.5,
            "temp_lag1": 27.5,
            "hu_lag1": 88.0,
        },
        "banyumanik": {
            "name": "Banyumanik (Daerah Dataran Tinggi)",
            "rainfall": 2.0,
            "temp": 25.5,
            "humidity": 70.0,
            "pressure": 1012.0,
            "rain_lag1": 1.5,
            "temp_lag1": 25.8,
            "hu_lag1": 68.0,
        }
    }

    results = run_prediction(db=None, telemetry_data=sample_telemetry)

    print("\n✅ [STEP 2 SELESAI] Hasil Prediksi Multivariate 3 Jam:")
    for doc_id, res in results.items():
        print(f"\n📍 Wilayah: {res['name']}")
        print(f"   Status Saat Ini : Hujan {res['current_rainfall']} mm | Suhu {res['current_temp']}°C | Lembap {res['current_humidity']}% -> {res['current_risk'].upper()}")
        print(f"   Peak Risk 3 Jam : {res['peak_risk_3h'].upper()} (Probabilitas: {res['peak_prob_3h']}%)")
        print("   Proyeksi Waktu  :")
        for pt in res['forecast_3h']:
            print(f"     • {pt['time_label']}: Hujan {pt['rainfall']} mm, Suhu {pt['temp']}°C, Lembap {pt['humidity']}%, Status: {pt['risk'].upper()}")

    print("\n" + "=" * 70)
    print("🎉 SEMUA PENGUJIAN LOKAL BERHASIL & SIAP DIGUNAKAN!")
    print("=" * 70)

if __name__ == "__main__":
    test_full_pipeline_local()
