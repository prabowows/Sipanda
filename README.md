# 🐼 SiPanda — Sistem Integrasi Peringatan Dini Adaptif - Cuaca Kota Semarang

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Firebase-Firestore_&_Functions-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" alt="Firebase" />
  <img src="https://img.shields.io/badge/Google_Cloud-Cloud_Scheduler-4285F4?style=for-the-badge&logo=googlecloud&logoColor=white" alt="Google Cloud" />
  <img src="https://img.shields.io/badge/Node.js-v22-339933?style=for-the-badge&logo=nodedotjs&logoColor=white" alt="Node.js" />
  <img src="https://img.shields.io/badge/UI/UX-Dark_Glassmorphism-purple?style=for-the-badge" alt="Design" />
</p>

---

## 📌 Penjelasan Produk (Product Overview)

**SiPanda (Sistem Peringatan Dini Banjir & Telemetri Cuaca Kota Semarang)** adalah platform pemantauan cuaca dan mitigasi risiko banjir terpadu yang dirancang khusus untuk 16 Kecamatan di Kota Semarang.

Platform ini hadir sebagai solusi digital cerdas untuk memberikan **informasi kondisi cuaca dan potensi bencana banjir secara real-time dan akurat**, baik kepada masyarakat umum maupun tim penanggulangan bencana (BPBD / Command Center). Dengan mengombinasikan visualisasi peta wilayah berbasis **GIS (Geographic Information System)**, analisis tren **time-series**, serta otomatisasi data dari **BMKG**, SiPanda membantu mempercepat respons darurat dan meminimalisir dampak kerugian akibat cuaca ekstrem.

---

## 🌟 Fitur Utama Produk (Key Features)

### 🗺️ 1. Interactive GIS Risk Map (Peta Risiko Wilayah 16 Kecamatan)
* Memvisualisasikan poligon batas wilayah 16 Kecamatan di Kota Semarang secara presisi.
* Menyajikan indikator warna status risiko secara otomatis:
  * 🟢 **Aman**: Curah hujan normal & kelembapan stabil.
  * 🟠 **Waspada**: Hujan sedang / fluktuasi cuaca ekstrem.
  * 🔴 **Siaga / Hazard**: Curah hujan lebat (>10mm/jam) & probabilitas banjir tinggi.
* Mode tampilan peta interaktif yang dapat beralih antara **Curah Hujan**, **Suhu**, dan **Kelembapan**.

### ⚡ 2. Live Telemetry & Real-Time Sync
* Menyajikan pembaruan data telemetri cuaca terkini tanpa perlu memuat ulang (*refresh*) halaman.
* Terhubung langsung dengan aliran data terverifikasi untuk menjamin akurasi informasi kondisi cuaca saat ini.

### 📈 3. Analisis Time-Series Data Historis (10 Titik Terkini)
* Menyajikan grafik tren garis (*Line Chart*) interaktif untuk memantau pergerakan **Curah Hujan (mm)**, **Suhu (°C)**, dan **Kelembapan (%)** dari waktu ke waktu (WIB).
* Dilengkapi **Tabel Riwayat Log Historis** berdesain bersih yang mencantumkan detail jam penarikan data, volume hujan, dan deskripsi kondisi cuaca.

### 🛡️ 4. Sentinel Command Center & Admin Portal
* **Manual Override Status**: Memungkinkan petugas BPBD / Admin untuk mengubah tingkat status risiko suatu kecamatan secara langsung saat keadaan darurat di lapangan.
* **Pencatatan Ground Truth**: Fitur input kondisi faktual banjir sebagai basis data validasi dan retraining Machine Learning di masa mendatang.

---

## 🛠️ Teknologi & Tech Stack

SiPanda dibangun menggunakan ekosistem teknologi modern berbasis *Cloud-Native* dan *Cross-Platform Framework*:

| Kategori | Teknologi | Deskripsi |
| :--- | :--- | :--- |
| **Frontend Framework** | **Flutter Web & Mobile (v3.22+)** | Framework cross-platform untuk antarmuka interaktif yang cepat dan responsif di Web, Android, dan iOS. |
| **Web Rendering Engine**| **Flutter HTML Renderer** | Mengoptimalkan pemuatan aset DOM Web tanpa ketergantungan unduhan WebAssembly eksternal. |
| **UI / UX Design** | **Vanilla Dark Glassmorphism** | Tema futuristik dark-mode dengan efek blur dan kartu matriks bergaya enterprise Command Center. |
| **GIS & Map Engine** | **Flutter Map & GeoJSON** | Render poligon batas wilayah 16 kecamatan Semarang berbasis koordinat spatial GeoJSON. |
| **Data Visualization** | **FL Chart Library** | Visualisasi grafik garis (*Line Chart*) time-series yang dinamis untuk curah hujan, suhu, dan kelembapan. |
| **Database** | **Google Cloud Firestore** | NoSQL Database scalable yang menyimpan status aktif wilayah dan subkoleksi log historis time-series. |
| **Backend Serverless** | **Firebase Cloud Functions 2nd Gen (Node.js 22)** | Serverless microservice yang menangani penarikan data otomatis, transformasi data, dan kalkulasi risiko. |
| **Cloud Automation** | **Google Cloud Scheduler** | Job cron serverless yang mengeksekusi penarikan data otomatis setiap **15 menit** (`*/15 * * * *`). |
| **External Telemetry API** | **API BMKG Publik (Adm4 Semarang)** | Sumber data telemetri prakiraan cuaca resmi BMKG untuk kecamatan se-Kota Semarang. |

---

## 🏗️ Arsitektur Alur Data (Data Flow Architecture)

```text
[ API BMKG Publik ] 
        │
        ▼ (Setiap 15 Menit)
[ GCP Cloud Scheduler ] ──► [ Cloud Functions v2 (Node.js 22) ]
                                    │
                                    ▼
                         [ Google Cloud Firestore ]
                                    │
               ┌────────────────────┴────────────────────┐
               ▼                                         ▼
   (Live Stream Telemetry)                    (REST Fallback Engine)
               │                                         │
               └────────────────────┬────────────────────┘
                                    ▼
                 [ SiPanda Web & Mobile App (Flutter) ]
```

---

<p align="center">
  <b>SiPanda Semarang</b> — <i>Smart Disaster Mitigation & Live Weather Telemetry System</i>
</p>
