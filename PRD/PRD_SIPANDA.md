# Product Requirement Document (PRD) & Technical Guide: SIPANDA

## 1. Product Overview
**Name**: SIPANDA (Sistem Integrasi Peringatan Dini Adaptif)
**Objective**: Mengembangkan sistem peringatan dini banjir yang adaptif dan real-time untuk Kota Semarang menggunakan arsitektur Firebase Full-Stack ditambah *Admin Portal* untuk pengendalian operasional krisis dan retrain logika XGBoost / Ensemble Machine Learning.

## 2. MoSCoW Prioritization
### Must-Have (Kebutuhan Utama)
* **Automated Data Ingestion**: Penarikan data cuaca dari API (seperti OpenWeather) dengan interval pengambilan waktu yang dinamis.
* **NoSQL Database**: Firebase Cloud Firestore untuk merekam data spasial cuaca, menyimpan file konfigurasi, log admin, dan result output.
* **ML Predictions (Stacking Ensemble)**: Algoritma Klasifikasi ML (XGBoost, Random Forest + Logistic Regression Meta) menentukan bahaya "Aman", "Waspada", atau "Siaga".
* **Frontend App Warga (Flutter Mobile)**: Aplikasi dengan fungsionalitas UI Peta GIS Semarang dinamis (Degradasi warna resiko tiap kecamatan) dan deretan panel *Weather Visualization Charts* (Suhu, Hujan, Tekanan Udara dsb). 
* **Admin Web Portal (Flutter Web)**: Dashboard utama bagi otoritas atau dinas BPBD/Kominfo untuk:
    1. Mengubah Interval waktu pemanggilan API (misal: saat kemarau update tiap 30 menit, saat hujan badai update tiap 5 menit).
    2. Mengubah Interval sinkronisasi rendering warna UI pada peta aplikasi masyarakat.
    3. Eksekusi tindakan *Manual Override* membatalkan/mengubah prediksi status risiko ML bilamana model salah prediksi.

### Should-Have (Sangat Dianjurkan)
* **Ground Truth & Adaptive Learning**: Web Portal dapat menerima input "kasus aktual" (*Ground Truth*) dari admin. Firestore akan mentrigger pipeline update / kalibrasi *weight* *Machine Learning* bila ada ketidaksesuaian prediksi pada riwayat lampau.
* **Validation & Evaluation Metrics**: Sistem ML mengukur performa sendiri seperti **RMSE**, **Accuracy, Precision, Recall, F1-Score**.

### Could-Have (Bisa Ditambahkan Nanti)
* Broadcast *Push Notification* (FCM) massal dari Admin Web langsung ke ponsel masyarakat saat status zona pindah ke "Siaga Banjir".
* Generate *Excel Reports* dari UI Admin.

### Won't-Have (Tidak di fase awal)
* Penambahan sensor hardware IoT secara lokal (*Hardware independent* selagi masih di Fase MVP).

---

## 3. High-Level Architecture (Firebase Full-Stack)

```mermaid
graph TD
    A[Public Weather API] -->|Cloud Scheduler (dinamis via app_config)| B(Firebase Function: Ingestion)
    B -->|Ingest JSON| C[(Cloud Firestore)]
    C -. trigger .-> D[ML Service: Predictive Pipeline]
    D -. check status override .-> D
    D -->|Predict 'Siaga'/'Waspada'| C
    E[Admin Web Portal] -->|Input Ground Truth| C
    E -->|Config & Manual Override| C
    C -. ground truth threshold .-> F[ML Service: Adaptive Learning]
    F -->|Update Model Weights| D
    C <-->|Data Stream & Push Config| G[Aplikasi Mobile Warga - Flutter]
    G --> H[GIS Map - flutter_map]
    G --> I[Weather Charts - fl_chart]
```

---

## 4. User Stories & Acceptance Criteria (AC)

| ID | User Story | Acceptance Criteria (AC) | Prioritas |
|---|---|---|---|
| US-01 | Sebagai Admin, saya dapat mengatur interval waktu penarikan data API dari web agar efisien biaya cloud. | Parameter `api_fetch_interval` di DB terupdate, fungsi cloud segera menaati durasi sinkronisasi baru secara otomatis. | Must |
| US-02 | Sebagai Admin, saya dapat mengatur jeda waktu merender UI peta masyarakat demi kemulusan app HP lama. | Parameter `ui_sync_interval` disiarkan via Firebase Bundle/Stream ke klien, client side men-*throttle* redraw GIS layer. | Must |
| US-03 | Sebagai Admin, saya wajib punya kuasa menganulir (*Override*) warna Peringatan dari ML guna cegah kepanikan. | Admin set Overridden_Status, layer backend/ui seketika mempercayai instruksi admin daripada prediksi ML di wilayah tsb. | Must |
| US-04 | Sebagai sistem, saya menarik dan mengekstrak metrik data telemetri sesuai timer admin. | Fungsi Fetcher berjalan via cron menit ke menit namun menghitung diferensial durasinya. | Must |
| US-05 | Sebagai sistem, saya memproses *Stacking Ensemble ML* memprakirakan risiko 6 jam kedepan. | Firebase Functions menginjeksi Data + Evaluasi Prediksi ke koleksi aktif kota. | Must |
| US-06 | Sebagai warga kota, saya dapat melihat peta wilayah saya (GeoJSON) memperbaharui warna kerawanan. | Gradasi *Hijau/Kuning/Merah* aktif dan berubah sesuai _real-time pipeline_ atau *override admin*. | Must |
| US-07 | Sebagai warga kota, saya melihat statistik analitik *fl_chart* grafik naik/turun hujan dan cuaca. | Peta widget mendampingi widget panel grafis tanpa konflik loading. | Must |
| US-08 | Sebagai Admin, saya menginput kasus faktual (*ground truth*) pasca hujan ke dalam sistem. | Dokumen masuk, threshold performa dieksekusi, berpotensi memicu *retrain pipeline*. | Should |

---

## 5. Complete Code Structure (Monorepo)

```text
sipanda-project/
├── sipanda_app/                  # Frontend (Flutter) -> Build untuk Android/iOS & Admin Web
│   ├── assets/
│   │   └── semarang.geojson      
│   ├── lib/
│   │   ├── main.dart             
│   │   ├── features/
│   │   │   ├── citizen/          # Modul Warga (Peta, Alert, Charts)
│   │   │   │   ├── dashboard_screen.dart
│   │   │   │   ├── widgets/map_risk_layer.dart
│   │   │   │   └── widgets/dynamic_charts.dart
│   │   │   └── admin/            # Portal Dashboard Admin (Web Build Target)
│   │   │       ├── admin_login_screen.dart
│   │   │       ├── config_panel_screen.dart      # Set interval API & UI Sync
│   │   │       ├── ground_truth_entry.dart
│   │   │       └── override_control_screen.dart  # Override status
│   │   ├── core/
│   │   │   ├── config_service.dart     # Service berlangganan interval Firestore
│   │   │   └── database_service.dart   
│   │   └── models/
│   └── pubspec.yaml              
│
├── functions/                    # Cloud Functions (Python Gen 2)
│   ├── main.py                   # Export Gateway
│   ├── core/
│   │   └── telemetry_fetch.py    # Logika baca 'app_config' & pull API
│   ├── ml_pipeline/
│   │   ├── model.py              # Stacking Regressor/Classifier
│   │   ├── predict.py            
│   │   ├── train.py              
│   │   └── evaluate.py           
│   └── admin/
│       └── overrides.py          # Logika layer tumpuk admin vs ML output
└── firebase.json                 
```

## 6. Implementation Strategy & Next Steps
1. **Frontend Flutter (Shared Web & Mobile)**: Injeksi Firebase. Karena Flutter sudah *First Class Web Support*, *Admin Dashboard* hanya perlu dibuat route beda (e.g., `/admin`) dan dideploy via Firebase Hosting. 
2. **Setup Smart Cron Fetcher**: Buat `telemetry_fetch.py` yang dicek melalui Cloud Scheduler 1-menit. Modul ini selalu memastikan `Time.Now() - LastFetchTimestamp >= AdminSettingInterval` sebelum mengambil _request API OpenWeather_.
3. **Database Firestore Priority Rules**: Bangun koleksi terpisah `overrides` atau layer param di JSON Kecamatan. Jika ada value *Overriden_Risk*, Firebase Stream harus mengutamakan data ini di atas *ML_Risk*.
4. **Machine Learning Pipeline**: Sempurnakan klasifikasi XGBoost untuk bisa di-update _weights_-nya ketika ada Trigger dari portal Web Admin (`Ground Truth Entry`).
