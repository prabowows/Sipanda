# UI/UX & Responsive Design System: SIPANDA

**Sistem Integrasi Peringatan Dini Adaptif**
*(Berdasarkan `PRD_SIPANDA.md` dan `ARCHITECTURE_SIPANDA.md`)*

Dokumen ini adalah acuan tata letak (wireframes), desain sistem, dan alur pengguna (User Flow) yang dirancang agar dapat diintegrasikan dengan sempurna dan **sepenuhnya responsif** di seluruh platform (Mobile, Tablet, Web Desktop) dalam pengembangan Flutter.

---

## 1. Design System & Tokens

### A. Color Palette (Semantic)
Warna sangat krusial di SIPANDA karena menandakan status peringatan dini krisis.

- **Status Aman** (Aman/Normal)
  - Map Layer / Fill: `rgba(76, 175, 80, 0.4)`
  - Alert Accent: `#2E7D32` (Green)
- **Status Waspada** (Warning)
  - Map Layer / Fill: `rgba(255, 193, 7, 0.4)`
  - Alert Accent: `#F57F17` (Amber)
- **Status Siaga** (Danger/Critical)
  - Map Layer / Fill: `rgba(244, 67, 54, 0.5)`
  - Alert Accent: `#B71C1C` (Red)

### B. Base Brand Colors & UI Elements
Desain difokuskan pada *Dark Mode* untuk menonjolkan kecerahan warna peringatan spasial di atas peta GIS.
- **Background Utama (Dark)**: `#121212`
- **Surface/Card**: `#1E1E1E` (Dengan opacity transparan 80% untuk efek *Glassmorphism* di atas peta)
- **Text (Primary)**: `#FFFFFF`
- **Text (Secondary)**: `#B3B3B3`
- **Primary CTA Button**: `#1976D2` (Blue, untuk action generik non-danger).

### C. Responsive Typography
Skala teks (*fluid typography*) yang membesar sedikit di Desktop:
- **Font Family**: `Inter` atau `Roboto`
- **Heading 1 (H1)**: `Semibold` (Mobile: 24px, Desktop: 28px)
- **Heading 2 (H2)**: `Medium` (Mobile: 18px, Desktop: 20px)
- **Body Text**: `Regular` (Mobile & Desktop: 14px)
- **Caption**: `Light` (Mobile & Desktop: 12px)

---

## 2. Responsive Layout Strategy (Breakpoints)

Untuk memastikan UI Flutter tidak hanya terasa seperti aplikasi "mobile yang direntangkan" di Web, implementasi kode kelak wajib menggunakan `MediaQuery` dan `LayoutBuilder` berdasarkan acuan dimensi berikut:

| Device / Screen | Breakpoint (Width) | Layout Behavior | Navigation System |
|---|---|---|---|
| **Mobile (Portrait/App)** | `< 600px` | Single Column (Tumpuk Vertikal). Area sempit. | Bottom Sheet / Drawer |
| **Tablet (Web/Pad)** | `600px - 1024px` | 2 Columns, Split View (Peta & Panel List). | Collapsed Sidebar (Icon only) |
| **Desktop (Web Admin)** | `> 1024px` | Multi-Column Grid. Pemanfaatan *Real-estate* lebar. | Full Sidebar (Icon + Text) |

---

## 3. Wireframes & Responsive Layout Definition
*(Siap divisualisasikan pada Google Stitch / IDE)*

### 3.1 Citizen Dashboard Screen (Warga)
Penyesuaian responsif layar utama bagi masyarakat saat memantau cuaca:

- **📱 Mobile View (< 600px)**:
  - **Root**: `Stack` memadukan Layer.
  - **Background Penuh**: Peta GIS `FlutterMap` mengisi 100% layar HP.
  - **Notifikasi Float**: Indikator "Aman/Siaga" berbentuk *Pill* melayang di tengah atas (*Glassmorphism*).
  - **Panel Data**: Menggunakan `DraggableScrollableSheet` di bawah layar. Pengguna melakukan *swipe-up* untuk melihat tren kurva hujan (`fl_chart`). Saat dilepas, sheet turun sehingga peta kembali terlihat.

- **💻 Desktop / Tablet Web View (> 600px)**:
  - **Root**: `Row` (Membelah halaman secara horizontal).
  - **Sisi Kiri (60% Lebar)**: Peta GIS statis tanpa tertutup apapun.
  - **Sisi Kanan (40% Lebar)**: Sebuah `Container` Dashboard Panel tersemat (*Pinned*). `DraggableScrollableSheet` pada HP dibuang, digantikan dengan susunan list langsung yang mendemonstrasikan status, temperatur, dan diagram probabilitas secara konstan.

### 3.2 Admin Web Portal (Pengelola)
Dashboard BPBD yang adaptif, memungkinkan pekerja mengelola status dari HP atau Komputer Posko:

- **💻 Desktop View (> 1024px)**:
  - **Navigasi Kiri**: Sidebar menu paten dengan lebar 250px.
  - **Konten Tengah**: `GridView` (2 hingga 3 Kolom) memperlihatkan kartu metrik (Sinkronisasi API API, dll).
  - **Tabel Peringatan**: Menampilkan fungsionalitas **Manual Override** menggunakan `DataTable` lebar dengan fitur *dropdown* "Ubah Status" dan kolom detail yang komprehensif.

- **📱 Mobile View (< 600px)**:
  - **Navigasi Kiri**: Hilang. Diubah menjadi tombol *Hamburger Menu* yang memanggil *Drawer* menu.
  - **Konten Tengah**: Layout `GridView` bertransisi menjadi daftar vertikal `ListView`.
  - **Tabel Peringatan**: Karena `DataTable` sulit dibaca di HP, datanya dikonversi ke bentukan **Card-list**. Setiap kotak Card berisi data per Kecamatan dan satu tombol besar *Action Bottom Sheet* untuk mengubah status (*Override*), memaksimalkan UX sentuhan jari (*Touch Target Size*).

---

## 4. UI/UX Micro-Interactions & Accessibility (WCAG)

- **Color Accessibility Check**: Gradasi darurat di atas peta tidak disetel opasitas penuh (Hanya 40-50%) agar detail jalan layang, sungai, dan nama daerah asli tetap terbaca jelas secara kontras.
- **Progressive / Skeleton Loading**: Karena web app seringkali meminta data API asinkron dari Firebase, kita hindari indikator *Spinner* biasa; sediakan desain bayangan abu-abu menyala (*Skeleton Block*) pada Chart dan Tabel agar transisi pergerakan antarmuka terlihat *premium/smooth*.
- **Destructive Action Dialog**: Baik di HP maupun Web, jika Admin mereset parameter peringatan (Override ML), sistem WAJIB mengeluarkan *Alert Modal* peringatan dengan tombol merah, mencegah Admin melakukan kesalahan ketik (Miss-click) dari sistem *touchscreen*.
