# Arsitektur Teknis: SIPANDA (Sistem Integrasi Peringatan Dini Adaptif)

Dokumen ini mendeskripsikan arsitektur teknis *high-level* dari project **SiPanda**.

## 1. High-Level Architecture Diagram (Firebase Full-Stack)

Arsitektur SiPanda mengandalkan integrasi antara layanan **Firebase Backend-as-a-Service (BaaS)**, **Google Cloud Functions**, dan **Flutter** untuk multi-platform aplikasi (Peta Warga & Web Admin).

```mermaid
graph TD
    A[BMKG Weather API] -->|Cloud Scheduler (dinamis via app_config)| B(Firebase Function: Ingestion)
    B -->|Ingest JSON| C[(Cloud Firestore)]
    
    C -. trigger .-> D[ML Service: Predictive Pipeline\n(XGBoost, RF, Meta LR)]
    D -. check status override .-> D
    D -->|Predict 'Siaga'/'Waspada'| C
    
    E[Admin Web Portal (Flutter Web)] -->|Input Ground Truth| C
    E -->|Config & Manual Override| C
    
    C -. ground truth threshold .-> F[ML Service: Adaptive Learning]
    F -->|Update Model Weights| D
    
    C <-->|Data Stream & Push Config| G[Aplikasi Mobile Warga - Flutter]
    
    G --> H[GIS Map - flutter_map]
    G --> I[Weather Charts - fl_chart]
```

## 2. Komponen Utama

### A. Frontend (Flutter)
- **Aplikasi Mobile (Citizen App)**: Aplikasi untuk warga Semarang yang menyediakan visualisasi risiko berbasis peta (GIS) berlapis gradasi (hijau, kuning, merah) dan diagram analisis kondisi cuaca. Target perangkat: iOS dan Android.
- **Admin Web Portal**: Dashboard bagi BPBD/otoritas. Menggunakan Flutter-Web dan di-host via Firebase Hosting. 
  - Fokus utama: Manajemen `Config` (interval sinkronisasi), Pemasukan `Ground Truth`, dan eksekusi `Manual Override`.

### B. Backend & Cloud 
- **Cloud Firestore (NoSQL)**: Berfungsi sebagai *single source of truth*. Semua log metrik sensor/cuaca, hasil prediksi, konfigurasi admin, dan input *ground truth* direkam di sini.
- **Cloud Functions (Python Gen 2)**: 
  - *Data Ingestion (Telemetry fetch)* dari sumber pihak ketiga (BMKG API).
  - *ML Predictive Pipeline*: Trigger berbasis cron atau event Firestore untuk memprediksi risiko banjir secara berkala (6 jam ke depan).
  - *Admin Override Engine*: Fungsi kontrol untuk menumpuk/mengalahkan status ML apabila admin menyalakan *manual override* (pencegahan _false alarm_).

### C. Machine Learning Engine (Stacking Ensemble)
Sistem *Machine Learning* berjalan secara otomatis namun bisa diperbarui (*Adaptive Learning*):
- **Predictive Model**: Ensemble tiga algoritma mencakup **XGBoost**, **Random Forest**, dan *Meta classifier* **Logistic Regression**.
- **Retrain Logic**: Apabila admin mendaftarkan kejadian "aktual banjir" (*Ground truth*), sistem bisa mengevaluasi gap error. Melampaui limit toleransi tertentu akan otomatis memicu training ulang (update *model weights*).

## 3. Strategi Sinkronisasi Data (Real-time DB)

Karena menyangkut peta hidup (GIS) dengan warna dinamis:
- Aplikasi tidak selalu _polling_ ke REST API melainkan men-*subscribe* ke dokumen *Firebase Stream*. 
- Admin dapat mengatur atribut interval **(UI Rendering Throttle)** agar perangkat warga tipe _low-end_ tidak kewalahan dalam me-render ulang poligon GIS GeoJSON secara berlebihan.
- Komponen widget grafik (seperti *fl_charts*) diisolasi *state*-nya dari pergerakan peta agar keduanya tidak mengalami _stuttering_ ketika data Firestore termutakhirkan.

## 4. Aliran Data BMKG (Data Flow Strategy)

Berdasarkan struktur JSON *response* dari API BMKG, sistem membagi ekstraksi data menjadi dua peruntukan agar performa aplikasi tetap ringan dan *Machine Learning* mendapatkan _feature_ yang kaya:

### A. Ekstraksi Data untuk Model Machine Learning (Backend)
Cloud Functions akan mengekstrak indikator kuantitatif lengkap dan menyimpannya ke koleksi historis Firestore untuk dikonsumsi algoritma *Stacking Ensemble*:
- `tp` (Curah Hujan / Total Precipitation) - *Fitur Utama*
- `hu` (Kelembapan Udara)
- `tcc` (Tutupan Awan / Total Cloud Cover)
- `ws` (Kecepatan Angin / Wind Speed)
- `wd_deg` (Arah Angin)
- `vs` (Jarak Pandang / Visibility)

### B. Ekstraksi Data untuk Tampilan Warga (Frontend UI)
Aplikasi warga (*Citizen App*) hanya akan berlangganan (_subscribe_) ke dokumen _Firebase Stream_ yang berisi *subset* data hasil ringkasan agar UI tidak berat:
- **Lokasi (`kecamatan`, `desa`)**: Sebagai identifikasi wilayah pada peta GeoJSON.
- **Sumbu Waktu (`local_datetime`)**: Menjadi sumbu X pada *fl_chart*.
- **Curah Hujan (`tp`)**: Ditampilkan menonjol sebagai grafik batang/area (*primary metric*).
- **Suhu & Kelembapan (`t`, `hu`)**: Sebagai garis referensi (sumbu Y sekunder) di dalam *fl_chart*.
- **Kondisi Visual (`weather_desc`, `image`)**: Ditampilkan dalam bentuk ikon *(svg mapped to local asset)* dan teks (misal: "Cerah Berawan") pada *header dashboard* status krisis.
