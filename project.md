# Project Specification & Technical Documentation: JNE Absensi MTP

## 1. Metadata Proyek & Identitas Sistem
* **Nama Resmi Proyek:** JNE Absensi MTP (Multi-Terminal Platform)
* **Deskripsi Sistem:** Sistem absensi digital terintegrasi berbasis Mobile App (Android/Flutter) untuk karyawan lapangan dan Web Dashboard (Next.js) sebagai pusat monitoring manajemen real-time.
* **Konteks Rilis:** Showcase Project / Sidang UJIKOM SMK IDN (2026)
* **Mitra Target Operasional:** JNE Hub Martapura, Kalimantan Selatan, Indonesia
* **Tim Pengembang (Group 2 CodeKoe - 11 RPL):**
    * Nabihan Uthman Raziq — Banjarbaru, Kalimantan Selatan
    * Zainul Arkaan Al Insi — Cikarang Selatan, Jawa Barat
    * Mufti Arifudin Taqy — Tangerang, Banten
    * Muhammad Parisz — Serang, Banten
    * Yusuf Althaf Alfaruq — Sidoarjo, Jawa Timur
* **Status Deployment:** Production Live (Sudah aktif digunakan secara resmi untuk operasional harian)
* **Infrastruktur Produksi:** `admin-absensi-jne-mtp.web.app`
* **Metrik Stabilitas (Sprint Metrics):** 100% Uptime, 22 Commits (GitHub), 5.000+ Baris Kode, 6 Bugs Resolved, 7 Production Deploys, 2.7 GB Storage Optimized.

---

## 2. Analisis Konteks, Latar Belakang, & Problem Statement

### 2.1 Konteks Operasional Lapangan
JNE Hub Martapura berlokasi di Kalimantan Selatan dan beroperasi selama **24 jam penuh, 7 hari seminggu (24/7)** tanpa henti untuk menangani aktivitas *inbound* dan *outbound* paket. 
* **Karakteristik Tim:** Bersifat *multi-role* (terdiri dari kurir, driver, staf operasional gudang, dan admin).
* **Intensitas Kerja:** Setiap karyawan memiliki lebih dari 30 aktivitas berbeda per hari.
* **Kebutuhan Utama:** Operasional berjalan dengan sistem shift bergiliran. Monitoring kehadiran karyawan secara akurat dan real-time menjadi penentu utama kelancaran distribusi logistik dan efisiensi *payroll*.

### 2.2 Masalah Operasional Utama (Legacy Friction Points)
Sistem absensi manual lawas menimbulkan friksi masif pada lima titik lini operasional:
1.  **Form Manual & Kertas (`01`):** Pengisian fisik rentan robek, hilang, tidak bisa dilacak, dan memicu *overhead* karena admin harus melakukan entry ulang data secara manual.
2.  **Ketiadaan Data Real-time (`02`):** Manager baru mengetahui status kehadiran di akhir hari, membuat respon terhadap kekurangan personel di gudang menjadi sangat lambat (reaktif, bukan proaktif).
3.  **Sulit Verifikasi Lokasi (`03`):** Tanpa validasi GPS, klaim kehadiran tidak bisa dibuktikan secara objektif. Karyawan lapangan berpotensi absen dari mana saja tanpa konfirmasi fisik.
4.  **Distribusi Shift Tidak Terstruktur (`04`):** Jadwal shift disebarkan melalui grup WhatsApp secara manual, sehingga mudah tertimbun chat lain, membingungkan staf, dan rawan miskomunikasi.
5.  **Tidak Ada Audit Trail (`05`):** Ketiadaan rekam jejak digital mempersulit pelacakan riwayat keterlambatan, pengajuan izin, atau anomali data kehadiran, sehingga rentan manipulasi data.

---

## 3. Spesifikasi Arsitektur & Tech Stack

Sistem ini didesain menggunakan arsitektur **Serverless Client-Centric**, di mana seluruh klien (Mobile, Web, Email Service) mengakses satu backend tunggal berbasis Firebase Services.

### 3.1 Komponen Stack Teknologi
* **Mobile App Client:** Flutter (Dart + Material 3 Design). Menghasilkan single codebase untuk platform Android dengan performa setara native dan antarmuka yang intuitif di lapangan.
* **Web Dashboard Admin:** Next.js 14 (TypeScript + App Router). Mendukung *Server-Side Rendering* (SSR) dan proses deployment cepat ke Firebase Hosting.
* **Backend Serverless (Firebase):**
    * *Firestore:* Database NoSQL real-time untuk menyimpan koleksi data absensi, akun karyawan, dan dokumen izin.
    * *Firebase Auth:* Mengelola gerbang otentikasi login enkripsi dan manajemen sesi token pengguna.
    * *Firebase Storage:* Blob storage terenkripsi untuk menyimpan aset file foto selfie *check-in* karyawan.
    * *Firebase Hosting:* Infrastruktur CDN global untuk me-host aplikasi Web Admin.
* **Email Gateway Engine:** Resend API (+ React Email). Layanan email transaksional otomatis untuk mengirim kredensial akun baru dan pembaruan status izin.
* **Tools Pendukung:** GitHub (Version Control), VS Code (Editor), Firebase CLI (Deploy), Postman (API Testing), dan Figma (UI Mockup Design).

### 3.2 Diagram Arsitektur Komunikasi Data
+------------------------------------+
|        CLIENT-SIDE LAYERS          |
+------------------------------------+
|  [Mobile App]   -> Flutter/Android |
|  [Web Admin]    -> Next.js 14      |
|  [Mail Service] -> Resend API      |
+------------------------------------+
|
v  (Direct Secure API Integration via TLS 1.3)
+-----------------------------------------------------------------+
|                    FIREBASE SERVERLESS BACKEND                  |
+-----------------------------------------------------------------+
|  [Auth]      -> Session Identity Manager                        |
|  [Firestore] -> Real-time Document Store (Absen, User, Izin)   |
|  [Storage]   -> Blob Container (.webp Selfie Proof)             |
|  [Hosting]   -> Admin Web Production Build                      |
+-----------------------------------------------------------------+


---

## 4. Spesifikasi Fitur Lengkap

### 4.1 Fitur Aplikasi Mobile Karyawan (8 Fitur Inti)
1.  **Login Aman:** Validasi akun email & password aman melalui integrasi Firebase Auth SDK.
2.  **Check-in GPS:** Mengunci koordinat geolokasi aktual karyawan secara otomatis dari sensor GPS perangkat.
3.  **Check-out System:** Perekaman absen pulang kerja sekaligus memicu kalkulasi durasi jam kerja bersih secara otomatis.
4.  **Foto Selfie Bukti Kehadiran:** Pengambilan dokumentasi visual langsung melalui kamera depan (mencegah manipulasi gambar dari galeri).
5.  **Riwayat Absensi 30 Hari:** Menampilkan daftar log riwayat absensi personal satu bulan terakhir lengkap dengan jam dan indikator status.
6.  **Pengajuan Izin Digital:** Form digital untuk submit izin atau sakit langsung dari aplikasi tanpa perlu chat WhatsApp admin manual.
7.  **Inovasi Khusus - Fitur 'Lapor Login':** Mengizinkan karyawan mengirim tiket aduan kendala akun langsung dari layar login eksternal tanpa membutuhkan sesi autentikasi aktif.
8.  **Push Notification System:** Notifikasi pengingat otomatis status approval izin, jadwal shift, dan pengingat waktu *check-in/check-out*.

### 4.2 Fitur Web Dashboard Admin & Manager (8 Fitur Inti)
1.  **Dashboard Live Interaktif:** Panel utama grafik statistik kehadiran hari berjalan yang diperbarui instan secara real-time via WebSocket Firestore.
2.  **Daftar Kontrol Karyawan:** Manajemen penuh (CRUD) data profil staf, pembagian role akses (RBAC), serta status aktif/nonaktif akun.
3.  **Kelola Absensi & Verifikasi Lokasi:** Modul pengecekan detail absensi, review lokasi koordinat di peta, dan fitur edit log manual jika terjadi kondisi darurat operasional.
4.  **Approval Engine Izin:** Matriks persetujuan atau penolakan surat pengajuan izin dan sakit karyawan lapangan.
5.  **Inbox Tiket Lapor Login:** Konsol administrasi untuk memproses tiket gangguan masuk akun dan mengeksekusi reset kredensial password.
6.  **Export Laporan Multi-Format:** Ekstraksi data rekap kehadiran bulanan ke dalam format file `.xlsx` (Excel), `.csv`, atau `.pdf` dalam waktu 5 detik.
7.  **Audit Trail System:** Catatan log kronologis yang mendokumentasikan setiap aktivitas penting admin untuk menjamin akuntabilitas data internal.
8.  **Pengaturan Aturan Sistem:** Manajemen konfigurasi master data jam kerja, penentuan radius toleransi *geofence* (meter), dan policy sistem.

### 4.3 Kemampuan Tambahan & Fitur Unggulan (Critical Capabilities)
* **Mode Offline:** Proses *check-in* absensi tetap dapat dieksekusi di lapangan meskipun gawai berada di area *blank spot* (tanpa sinyal). Data absen disimpan sementara di penyimpanan lokal terenkripsi, lalu otomatis tersinkronisasi ke server cloud begitu koneksi internet pulih.
* **Otomasi Push Reminder:** Pengiriman alarm otomatis ke HP karyawan 10 menit sebelum shift dimulai, serta alert otomatis jika sistem mendeteksi karyawan melewati jam shift tanpa melakukan *check-out*.
* **Lokasi GPS Real-time Dashboard:** Posisi koordinat staf lapangan di-refresh otomatis ke peta admin dashboard setiap 30 detik sekali dengan tingkat akurasi presisi GPS $\pm$ 5 meter.

---

## 5. Logika Proses & Alur Kerja (Data Flow)

### 5.1 Alur Kerja Onboarding Karyawan Baru (Automated Email Pipeline)
Proses onboarding efisien dirancang untuk meminimalkan intervensi manual (Rata-rata waktu proses selesai < 1 jam kerja efektif):
1.  **Manager** mengirimkan daftar data mentah identitas staf baru kepada Administrator Sistem.
2.  **Admin** menginput data tersebut ke form panel Next.js Dashboard. Sistem memicu pembuatan dokumen akun baru dan men-generate pasword default yang acak.
3.  **Sistem (Resend API)** secara otomatis menangkap event database tersebut, me-render template HTML via React Email, dan mengirimkan email berisi informasi kredensial login resmi beserta tautan unduhan aman file APK aplikasi ke email karyawan baru.
4.  **Karyawan** menerima notifikasi email, mengunduh file APK dari link terenkripsi, lalu menginstalnya ke smartphone Android.
5.  **Karyawan** melakukan proses login pertama kali, sistem secara otomatis memaksa pergantian password default ke password privat baru. Akun siap digunakan untuk absensi hari pertama.

### 5.2 Alur Kerja Siklus Absensi Harian (Real-Time State Synchronization)
Menghilangkan ketergantungan dokumen fisik kertas maupun rekap manual chat WhatsApp:
* **Aksi Karyawan:** Membuka aplikasi (sesi token otomatis tervalidasi) $\rightarrow$ Klik Masuk $\rightarrow$ Sistem mengunci koordinat lokasi melalui sensor GPS dan menangkap gambar via kamera depan $\rightarrow$ Klik Kirim.
* **Validasi Firebase Server-Side:** Sistem mengunggah media foto ke Storage, mengompresinya secara asinkron, memvalidasi parameter stempel waktu server (*server timestamp*), lalu menyimpan dokumen log ke Firestore secara *atomic transaction*.
* **Konsumsi Admin Dashboard:** Web Admin Dashboard menangkap mutasi data real-time via listener aktif. Data grafik kehadiran langsung terupdate di monitor manager secara instan tanpa perlu mematikan halaman web.

### 5.3 Alur Siklus Problem-Solving & Inovasi 'Lapor Login'
Menyelesaikan masalah *deadlock* operasional (*"Bagaimana cara staf melaporkan kendala sistem jika mereka tidak bisa masuk ke dalam sistem absensi?"*):
[User di Layar Login]
|
v  (Klik Tombol 'Lapor Login' - Tanpa Autentikasi Sesi)
[Isi Form Ringkas] ---------> Input NIK, Deskripsi Masalah, Capture Foto Error (30 Detik)
|
v  (Commit Transaksi Langsung ke Firestore Koleksi login_reports)
[Admin Dashboard] ----------> Menerima Tiket Baru -> Admin Klik Tombol 'Reset Kredensial'
|
v  (Trigger Backend Cloud Function)
[Resend Mail API] ----------> Otomatis Mengirim Email Instruksi Password Baru ke User (<30 Detik)
|
v
[User Terima Email] --------> Kasus Selesai & Tiket Ditutup


---

## 6. Otomasi, Proteksi Keamanan, & Performa Data

### 6.1 Protokol Otomasi Komunikasi Transaksional (Resend Engine)
Sistem memiliki kemampuan komunikasi otonom tanpa memerlukan pengetikan email manual oleh staf HRD untuk 4 skenario kritikal:
1.  **Kredensial Akun Baru:** Distribusi parameter nama pengguna, sandi awal, dan dokumen panduan instalasi `.apk`.
2.  **Reset Password Otomatis:** Menjawab instruksi pemulihan akun yang diajukan melalui gerbang pengaduan 'Lapor Login'.
3.  **Pemberitahuan Kelayakan Izin:** Notifikasi instan ke email karyawan mengenai status permohonan dispensasi (Disetujui / Ditolak).
4.  **Penyelesaian Tiket Gangguan:** Konfirmasi otomatis kepada pelapor bahwa perbaikan bug kode/akun telah selesai dilakukan oleh tim pengembang.
* *Mekanisme Enjin:* Event Terjadi $\rightarrow$ Cloud Function Memanggil Resend API $\rightarrow$ Rendering React Email Template $\rightarrow$ Pengiriman via Domain Bersertifikat Keamanan SPF/DKIM $\rightarrow$ Inbox Masuk User (< 30 Detik).

### 6.2 Strategi Distribusi Aplikasi Internal (Enterprise APK Distribution)
Tim memutuskan memutus jalur distribusi Google Play Store berdasarkan analisis risiko taktis (Menghindari biaya akun dev \$25, memangkas birokrasi proses review rilis Google yang memakan waktu berhari-hari, mencegah kebocoran instalasi aplikasi internal ke publik luas, dan menyederhanakan konfigurasi penandatanganan rilis bagi developer muda).
* *Solusi Implementasi:* Berkas biner `.apk` versi produksi di-host di lingkungan Firebase Storage terlindungi. Akses unduhan dikunci menggunakan tautan bertanda tangan digital (*Dynamic Signed URLs*) dengan masa kedaluwarsa yang dikirimkan eksklusif ke email karyawan terdaftar. Pembaruan patch sistem dapat didistribusikan merata ke seluruh gawai karyawan dalam waktu kurang dari 1 jam efektif.

### 6.3 Skema Pertahanan Keamanan 4 Lapis (Defense-in-Depth Framework)
Sistem keamanan dirancang berlapis-lapis untuk menjaga kerahasiaan data karyawan dan mencegah manipulasi:
* **Lapis 1 (L1) — Perimeter & Distribusi:** Akses instalasi tertutup melalui tautan dinamis aman, membatasi pihak luar mengunduh file biner aplikasi.
* **Lapis 2 (L2) — Autentikasi Pengguna:** Otentikasi berlapis Firebase Auth menggunakan token JWT (*JSON Web Token*) yang dienkripsi pada sisi klien. Sesi dapat dinonaktifkan secara sepihak oleh admin dari dashboard jika gawai karyawan hilang.
* **Lapis 3 (L3) — Otorisasi Hak Akses (RBAC):** Pemisahan hak akses data secara kaku antar level peran pengguna (`employee`, `admin`, `manager`) sehingga tidak ada kebocoran wewenang manipulasi data.
* **Lapis 4 (L4) — Proteksi Server Database:** Konfigurasi aturan keamanan tingkat baris data database (*Firestore Security Rules*). Aturan ini menolak segala bentuk modifikasi query ilegal langsung ke database server, meskipun token otentikasi klien bocor atau diretas.
* *Enkripsi Transport:* Seluruh jalur komunikasi data diwajibkan berjalan di atas protokol enkripsi transportasi TLS 1.3.

### 6.4 Teknik Optimasi Performa & Efisiensi Data
* **Mobile Cold Start Optimization:** Membawa kecepatan muat aplikasi dari layar splash menuju halaman utama berjalan dalam waktu **< 3 detik** memanfaatkan teknik *lazy loading* pada pemuatan modul komponen Flutter.
* **Web Dashboard Fluidity:** Menjamin kelancaran rendering antarmuka web dashboard tetap konsisten pada tingkat **60 FPS** saat memuat ribuan baris log data absensi besar lewat implementasi taktik *server-side pagination* dan *virtual list component*.
* **Image Compression Engine:** Mengonversi visual foto selfie tangkapan kamera depan ke ekstensi format `.webp` dengan resolusi adaptif maksimal $800 \times 600$ piksel secara *on-the-fly*. Menghemat ruang penyimpanan cloud secara drastis dari rata-rata ukuran file 4 MB menjadi kurang dari 150 KB per transaksi absen.
* **Query Acceleration Indexing:** Membangun konfigurasi *Composite Indexing* pada database Firestore untuk mengoptimalkan kecepatan pembacaan query dengan filter penyaringan berlapis tingkat tinggi.
* **Storage Cleanup Protocol:** Eksekusi skrip otomatisasi pembersihan media log berkala untuk membuang aset file usang tidak terpakai, membebaskan kapasitas penyimpanan cloud server sebesar **2.7 GB storage**.

---

## 7. Analisis Biaya Operasional (In-House Build vs SaaS Vendor)

Berikut adalah metrik analisis finansial riil perbandingan pembiayaan sistem untuk pemakaian kapasitas organisasi skala **50 karyawan aktif**:

| Komponen Analisis Pengeluaran | Opsi Solusi SaaS Komersial Vendor (Talenta / Sejenis) | Sistem Mandiri In-House (JNE Absensi MTP) |
| :--- | :--- | :--- |
| **Tarif Lisensi Per Pengguna / Bulan** | Rp 35.000 / Personel | Rp 0 (Free Lifetime Open Source License) |
| **Biaya Pemakaian Database & Auth** | Termasuk paket retail | Rp 0 (Dioptimalkan masuk dalam kuota gratis *Spark Plan*) |
| **Biaya Media Asset Storage** | Termasuk paket retail | Rp 0 (Sangat efisien berkat mesin kompresi WebP) |
| **Engine Email Transaksional** | Termasuk paket retail | Rp 0 (Berada di bawah limit gratis 3.000 email/bulan Resend) |
| **Pembelian Custom Domain Korporat**| Tidak memerlukan | Rp 150.000 / Tahun |
| **Total Pengeluaran Bulanan** | Rp 1.750.000 | Rp 0 |
| **Total Akumulasi Biaya Per Tahun** | **Rp 21.000.000 / Tahun** | **< Rp 1.000.000 / Tahun (Fixed Cost)** |

> 📊 **Kesimpulan Finansial:** Membangun arsitektur serverless mandiri terbukti memangkas anggaran operasional perusahaan **lebih dari 20x lipat lebih hemat** dibandingkan menyewa sistem aplikasi retail pihak ketiga di pasaran. Skema biaya bersifat fixed cost (tidak melambung naik secara linear saat terjadi penambahan jumlah staf) sekaligus memberikan kedaulatan kepemilikan mutlak terhadap privasi data internal perusahaan.

---

## 8. Transformasi Operasional (Analisis Dampak Sistem)

| Skenario Operasional | Kondisi Lama (Sebelum Implementasi) | Kondisi Baru (Sesudah Implementasi) |
| :--- | :--- | :--- |
| **Metode Pencatatan Absen** | Pengisian kertas manual di meja depan, rentan manipulasi (titip absen rekan kerja). | Input digital terverifikasi koordinat GPS aktual perangkat dan lampiran foto selfie biometrik. |
| **Kecepatan Konsolidasi Data**| Rekapitulasi log data kehadiran mingguan memakan waktu berjam-jam kerja admin HRD via Excel. | Ketersediaan pelaporan rekap kehadiran real-time, dapat diakses manager kapan saja. |
| **Obyektifitas Validasi Lokasi**| Tidak memiliki bukti fisik lokasi kehadiran; klaim kehadiran staf lapangan tidak dapat diuji. | Audit lokasi presisi berbasis peta interaktif dengan tingkat akurasi radius koordinat $\pm$ 5 meter. |
| **Penanganan Masalah Sistem** | Penyampaian kendala masuk akun lewat chat pribadi WhatsApp, respon lambat, tiket aduan sering hilang. | Penanganan terstruktur lewat sistem tiket otomatis 'Lapor Login' dari layar luar aplikasi (Selesai dalam <1 jam). |

---

## 9. Rencana Pengembangan Masa Depan (Roadmap Strategy)

### 9.1 Garis Waktu Pengembangan Sistem
* **Fase NOW — Stabilisasi Arsitektur Inti (Q2 2026):** Implementasi instrumen monitoring error otomatis (*Sentry/Crashlytics Integration*), perbaikan minor komponen UX aplikasi mobile berdasarkan umpan balik sprint pertama, pelaksanaan audit keamanan berkala.
* **Fase NEXT — Ekspansi Fungsionalitas Fitur (Q3–Q4 2026):** Pengembangan modul kalkulasi jam lembur (*Overtime Processing Engine*), pembuatan sistem cetak template manajemen penugasan shift fleksibel, pengintegrasian push notification native berbasis Firebase Cloud Messaging (FCM), penyusunan modul dasbor analitik HR.
* **Fase LATER — Skalabilitas Masif & Integrasi Korporat (2027):** Replikasi arsitektur database untuk mendukung multi-hub logistik di luar area Martapura, pembukaan jalur integrasi API otomatis ke mesin sistem penggajian utama perusahaan (*Core Payroll System*), porting basis kode Flutter agar dapat dikompilasi secara native untuk platform Apple iOS dan pembuatan versi *Progressive Web App* (PWA) untuk web dashboard admin.

### 9.2 Strategi Peluncuran Bertahap di Lapangan (Phased Rollout Matrix)
Guna menjaga stabilitas sistem dan kesiapan tim teknis, ekspansi operasional dijalankan menggunakan taktik rilis bertahap:
* **Tahap 1 (Minggu 1–2) — Pilot Project Hub Martapura:** Implementasi terbatas pada 1 hub pilot utama dengan kapasitas 50 karyawan aktif. Fokus mutlak pada aktivitas pencarian bug sistem (*bug hunting*), stabilitas performa, dan validasi alur kerja harian.
* **Tahap 2 (Minggu 3–6) — Ekspansi 3 Hub Regional Kalsel:** Penambahan jangkauan sistem ke 3 Hub operasional logistik regional terdekat (Hub Banjarmasin, Hub Banjarbaru, Hub Tanjung), menaikkan volume beban server dengan penambahan $\pm$ 200 user baru ke database.
* **Tahap 3 (Bulan 2–3) — Konsolidasi Penuh Regional Kalimantan:** Implementasi menyeluruh mencakup 8 Hub utama se-pulau Kalimantan. Skala data melayani akumulasi kuantitas aktif >500 personel karyawan lapangan. Seluruh modul diaktifkan penuh.
* **Tahap 4 (Bulan 4+) — Nasional:** Duplikasi ekosistem infrastruktur database berskala nasional ke seluruh regional hub JNE di seluruh penjuru Indonesia, didukung kesiapan arsitektur sistem *database sharding redundancy* dan tim support operasional teknis yang bersiaga penuh 24/7.