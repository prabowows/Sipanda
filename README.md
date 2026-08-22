# 🐼 SiPanda — Sistem Integrasi Peringatan Dini Adaptif Cuaca Kota Semarang

<p align="center">
  <a href="https://sipanda-semarang.web.app">
    <img src="https://img.shields.io/badge/Live_Production-sipanda--semarang.web.app-00C853?style=for-the-badge&logo=googlechrome&logoColor=white" alt="Live Demo" />
  </a>
  <img src="https://img.shields.io/badge/Flutter-3.22+-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/XGBoost-MultiOutput-FF6F00?style=for-the-badge&logo=scikitlearn&logoColor=white" alt="XGBoost" />
  <img src="https://img.shields.io/badge/Optuna-Bayesian_TPE-007ACC?style=for-the-badge&logo=python&logoColor=white" alt="Optuna" />
  <img src="https://img.shields.io/badge/Google_Cloud-Cloud_Scheduler-4285F4?style=for-the-badge&logo=googlecloud&logoColor=white" alt="Google Cloud" />
  <img src="https://img.shields.io/badge/Firestore-Live_NoSQL-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" alt="Firestore" />
</p>

---

## 📌 Penjelasan Produk (Product Overview)

**SiPanda (Sistem Integrasi Peringatan Dini Adaptif - Cuaca Kota Semarang)** adalah platform peramalan cuaca multivariat dan mitigasi risiko bencana berbasis *Artificial Intelligence* dan *Geographic Information System (GIS)* yang mencakup **16 Kecamatan di Kota Semarang**.

SiPanda mengintegrasikan data telemetri **BMKG**, model **Multivariate Multi-Output XGBoost Regressor**, optimasi Bayesian otomatis (**Optuna TPE**), serta arsitektur komputasi *serverless* **Google Cloud Platform** untuk menghasilkan peramalan jangka pendek bertingkat (**Horizon 1 Jam [T+1], 2 Jam [T+2], dan 3 Jam [T+3] ke depan**) secara *real-time*.

---

## 🌟 Fitur Utama Sistem (Key Features)

### 🗺️ 1. Interactive GIS Risk Map (Peta Risiko Wilayah 16 Kecamatan)
- Poligon spasial presisi GeoJSON untuk 16 kecamatan se-Kota Semarang.
- Pewarnaan status risiko dinamis berbasis ambang batas cuaca:
  - 🟢 **Aman**: Curah hujan rendah & kelembapan stabil.
  - 🟠 **Waspada**: Fluktuasi suhu/kelembapan & hujan intensitas sedang.
  - 🔴 **Siaga / Bahaya**: Potensi curah hujan lebat berisiko banjir genangan / rob.
- Layer filter interaktif untuk **Curah Hujan (mm)**, **Suhu (°C)**, dan **Kelembapan (%)**.

### 🧠 2. Machine Learning Engine: Multivariate Multi-Output XGBoost Forecaster
- **Multivariate Input & Target**: Memproses korelasi fisik antara curah hujan, suhu, dan kelembapan secara simultan.
- **Multi-Horizon Output**: Menghasilkan estimasi matriks 9 dimensi:
  $$\mathbf{Y} = [Rain_{T+1..3}, Temp_{T+1..3}, Hum_{T+1..3}]$$
- **Bayesian Auto-Tuning (Optuna TPE)**: Kalibrasi hyperparameter otomatis setiap 3 jam sekali menggunakan 25 trial *Tree-Structured Parzen Estimator*.
- **Akurasi Tinggi**: $R^2 \ge 0.95$ dan $RMSE \le 0.044$ pada pengujian *5-Fold Time-Series Cross Validation*.

### 🛡️ 3. Admin ML Portal & Model Hub (`/admin`)
- Terletak tepat di bawah navigasi Dashboard untuk pemantauan operasional *engine*.
- **Live Metadata Synchronized**: Menampilkan metrik evaluasi asli ($RMSE, MAE, R^2$), status *Engine Online*, dan hyperparameter terbaik langsung dari Firestore `config/ml_metadata`.
- **Model Artifact Downloader**: Kemudahan ekspor berkas biner `model_latest.pkl` berukuran ~1.42 MB lengkap dengan *SHA-256 Checksum* yang kompatibel dengan Python dan Jupyter Notebook.
- **Interactive Auto-Tune Trigger**: Tombol kalibrasi manual untuk simulasi dan *commit* metadata terbaru ke database.

### 📊 4. Time-Series Analysis & Excel Export
- Grafik tren garis (*Line Chart*) interaktif untuk 10 titik waktu terkini.
- Fitur **Export Excel (.xlsx)** multi-periode per kecamatan untuk analisis data analitik lanjutan.

---

## 🏗️ Arsitektur Sistem & Alur Data (Architecture Pipeline)

```text
┌─────────────────────────────────────────────────────────────────────────────────┐
│ 1. DATA TELEMETRI EKSTERNAL                                                     │
│    API BMKG Publik (adm4 untuk 16 Kecamatan Semarang)                           │
└────────────────────────────────────────┬────────────────────────────────────────┘
                                         │ Fetch Tiap 15 Menit
                                         ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│ 2. GOOGLE CLOUD PLATFORM (SERVERLESS BACKEND)                                   │
│    ├── Cloud Scheduler:                                                         │
│    │   ├── scheduled_fetch (every 15 minutes)                                   │
│    │   └── scheduled_retrain (every 3 hours)                                    │
│    └── Cloud Functions Gen 2 (Node.js 22 & Python Core):                        │
│        ├── Ingestion & Sanitasi Data Telemetri                                  │
│        └── Bayesian Auto-Tuning XGBoost Pipeline (Optuna TPE 25 Trials)         │
└────────────────────────────────────────┬────────────────────────────────────────┘
                                         │ Simpan Data & Metadata
                                         ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│ 3. CLOUD FIRESTORE DATABASE                                                     │
│    ├── telemetry_history (Subkoleksi Log Data Real-Time)                        │
│    └── config/ml_metadata (Dokumen Metrik Evaluasi, Timestamp & Hyperparameter) │
└────────────────────────────────────────┬────────────────────────────────────────┘
                                         │ Real-Time Stream / REST API
                                         ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│ 4. SIPANDA FRONTEND APPLICATION                                                 │
│    ├── Citizen Dashboard (Interactive GIS Map, Time-Series & Warning Badges)    │
│    └── Admin ML Portal (/admin) (Engine Monitoring & .pkl Model Exporter)       │
└─────────────────────────────────────────────────────────────────────────────────┘
```

---

## 📂 Struktur Direktori Proyek (Project Structure)

```text
SiPanda/
├── PRD/
│   └── PRD_Algoritma.md          # Dokumen Spesifikasi Produk & Algoritma ML Lengkap
├── functions/                    # Backend Serverless Google Cloud Functions
│   ├── index.js                  # Cloud Function Entry (scheduled_fetch & scheduled_retrain)
│   ├── package.json              # Dependencies (firebase-admin, firebase-functions v5)
│   └── ml_pipeline/              # Skrip Pipeline Pelatihan & Tuning Python
│       ├── train.py              # XGBoost Training & Optuna TPE Implementation
│       └── requirements.txt      # scikit-learn, xgboost, optuna, pandas, numpy
├── sipanda_app/                  # Frontend Flutter Cross-Platform
│   ├── lib/
│   │   ├── main.dart             # App Entry Point & Route Definitions
│   │   ├── firebase_options.dart # Konfigurasi Firebase Multiplatform
│   │   ├── core/
│   │   │   ├── database_service.dart   # Firestore SDK & REST API Layer
│   │   │   ├── theme.dart              # Vanilla Dark Glassmorphism Design System
│   │   │   ├── services/bmkg_service.dart # Telemetri & State Parser
│   │   │   └── utils/                  # Excel Exporter & Web File Saver
│   │   ├── features/
│   │   │   ├── citizen/
│   │   │   │   ├── dashboard_screen.dart # Layar Utama Dashboard & Navigasi Sidebar
│   │   │   │   └── widgets/map_risk_layer.dart # Peta Interaktif GIS Flutter Map
│   │   │   └── admin/
│   │   │       └── admin_dashboard_screen.dart # Admin Portal & ML Model Hub
│   │   └── models/               # Model Entitas Data (DistrictData, WeatherRecord)
│   └── pubspec.yaml              # Dependensi Flutter (fl_chart, flutter_map, etc.)
└── README.md                     # Dokumentasi Utama Repositori
```

---

## 🛠️ Spesifikasi Teknologi (Tech Stack)

| Komponen | Teknologi | Deskripsi |
| :--- | :--- | :--- |
| **Frontend Framework** | **Flutter (v3.22+)** | Framework multiplatform Web, Android, dan iOS. |
| **Machine Learning** | **XGBoost & Scikit-Learn** | Model *Multivariate Multi-Output Regressor*. |
| **Hyperparameter Tuning**| **Optuna (TPE Sampler)** | *Bayesian Optimization* untuk auto-tune 7 parameter. |
| **Database** | **Google Cloud Firestore** | NoSQL Database untuk *telemetry_history* dan *ml_metadata*. |
| **Serverless Compute** | **Cloud Functions Gen 2** | Microservice *Node.js 22 & Python* di Google Cloud. |
| **Automation & Cron** | **Google Cloud Scheduler** | Eksekusi otomatis 24/7 (tiap 15 menit & tiap 3 jam). |
| **Hosting & CDN** | **Firebase Hosting** | Distribusi web cepat dengan kompresi GZIP dan HTTPS SSL. |
| **GIS Engine** | **Flutter Map & GeoJSON** | Render batas wilayah 16 kecamatan Kota Semarang. |

---

## 📖 Dokumentasi Terkait

- 📑 **[Product Requirements Document (PRD) Algoritma ML](PRD/PRD_Algoritma.md)** — Rincian lengkap arsitektur matematika, formulasi matriks, parameter importance, dan evaluasi benchmarking.
- 🌐 **[Live Production Web Portal](https://sipanda-semarang.web.app)** — Antarmuka publik dan Admin Portal yang aktif di domain.
- ☁️ **[Google Cloud Project Console](https://console.cloud.google.com/cloudscheduler?project=sipanda-semarang)** — Monitoring Cloud Scheduler & Cloud Functions.

---

<p align="center">
  <b>SiPanda Semarang</b> • <i>Sistem Integrasi Peringatan Dini Adaptif Cuaca & Mitigasi Banjir</i><br>
  Dikembangkan oleh Tim Core ML & Software Engineering SiPanda
</p>
