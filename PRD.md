# Product Requirements Document (PRD)

## JNE Attendance System

**Versi:** 1.0  
**Tanggal:** 29 Mei 2026  
**Author:** Zainul Arkaan  
**Status:** Active Development

---

## 1. Overview Produk

### 1.1 Tentang Aplikasi

JNE Attendance System adalah sistem manajemen kehadiran karyawan berbasis digital yang dibangun khusus untuk lingkungan kerja JNE (Jalur Nugraha Ekakurir) cabang Mataram. Sistem ini menggantikan sistem absensi manual (kertas/finger print konvensional) dengan solusi berbasis foto wajah + GPS yang real-time, aman, dan terintegrasi penuh antara HR/admin dengan karyawan di lapangan.

Sistem ini terdiri dari dua produk yang saling terhubung:

- **Admin Panel** — Web dashboard untuk tim HR dan manajemen
- **Mobile App** — Aplikasi Android untuk karyawan harian

### 1.2 Masalah yang Diselesaikan

| Masalah Lama                                  | Solusi Sistem Ini                                       |
| --------------------------------------------- | ------------------------------------------------------- |
| Absensi manual rawan manipulasi (titip absen) | Face recognition on-device + geofence GPS               |
| HR tidak tahu kondisi karyawan real-time      | Dashboard live + heartbeat monitoring                   |
| Pengajuan cuti lewat kertas/grup WA           | Fitur leave management digital dengan approval workflow |
| Tidak ada riwayat kehadiran yang terstruktur  | Semua record tersimpan Firestore dengan audit trail     |
| Karyawan tidak bisa hubungi admin langsung    | Chat 2-way + dispute resolution system                  |
| Tidak ada sistem darurat karyawan             | SOS alert dengan lokasi real-time ke admin              |

---

## 2. Target User

### 2.1 Primary Users

#### A. Karyawan (Mobile App User)

- **Profil:** Karyawan operasional JNE, dari kurir hingga staf gudang dan kantor
- **Usia:** 20–45 tahun
- **Device:** Android (Android 8.0+)
- **Literasi Digital:** Menengah — familiar dengan WhatsApp, tapi tidak selalu tech-savvy
- **Kebutuhan Utama:**
  - Absen masuk/keluar dengan mudah dari HP
  - Lihat riwayat kehadiran dan gaji lembur
  - Ajukan cuti tanpa repot ke kantor
  - Komunikasi langsung dengan atasan/HR

#### B. Admin / HR (Admin Panel User)

- **Profil:** Tim HR, supervisor, kepala divisi JNE Mataram
- **Device:** Laptop/Desktop (Chrome, Firefox)
- **Literasi Digital:** Menengah–tinggi, familiar dengan spreadsheet dan dashboard
- **Kebutuhan Utama:**
  - Monitor kehadiran semua karyawan real-time
  - Kelola data karyawan, shift, dan jadwal
  - Approve/reject pengajuan cuti dan lembur
  - Lihat laporan dan analitik kehadiran

### 2.2 Secondary Users

- **Superadmin:** Akses penuh ke semua konfigurasi sistem, dapat reset data dan kelola admin lain
- **Kepala Unit:** Akses terbatas untuk monitoring tim mereka

---

## 3. Goals & Objectives

### 3.1 Business Goals

1. **Eliminasi kecurangan absensi** — Titip absen mustahil dengan face recognition + GPS wajib
2. **Efisiensi operasional HR** — Kurangi waktu proses administrasi kehadiran dari harian menjadi otomatis
3. **Transparansi data kehadiran** — Semua pihak (karyawan & HR) punya akses ke data yang sama dan akurat
4. **Respons darurat lebih cepat** — SOS alert memastikan admin tahu kondisi darurat dalam hitungan detik

### 3.2 Product Goals

1. **Akurasi absensi ≥ 99%** — Face score + geofence memastikan data valid
2. **Uptime sistem ≥ 99.5%** — Firebase infrastructure + offline fallback SQLite
3. **Waktu approval cuti < 24 jam** — Notification workflow mendorong admin untuk merespons cepat
4. **Zero data loss** — Offline queue (SQLite + pending_sync) menjamin absensi tetap tersimpan walau offline
5. **Onboarding karyawan baru < 5 menit** — Email otomatis + first-login password change

### 3.3 Success Metrics

| Metrik                              | Target                         |
| ----------------------------------- | ------------------------------ |
| Tingkat kehadiran terdokumentasi    | 100% dari total karyawan aktif |
| Waktu rata-rata absen (tap to done) | < 30 detik                     |
| Dispute yang terselesaikan          | ≥ 95% dalam 48 jam             |
| Karyawan yang sudah enroll wajah    | ≥ 98% dari karyawan aktif      |
| Rating resolusi dispute oleh user   | ≥ 4/5 bintang rata-rata        |

---

## 4. Fitur Utama

### 4.1 Mobile App — Karyawan

#### Modul Absensi

- **Check-in / Check-out** dengan:
  - Verifikasi wajah via ML Kit Face Detection (on-device, no server call)
  - Validasi GPS geofence (radius configurable dari admin)
  - Foto bukti absensi diupload ke Firebase Storage
  - Mode offline — absensi tersimpan lokal (SQLite) dan auto-sync saat online kembali
- **Status absensi harian** — Tampil status (hadir, terlambat, tidak hadir, izin) di home screen
- **Riwayat kehadiran** — List bulanan dengan durasi kerja, overtime, dan status

#### Modul Cuti & Lembur

- **Pengajuan cuti** — Form dengan tipe cuti (tahunan, sakit, pribadi, darurat, lain-lain), tanggal, dan alasan
- **Upload dokumen** — Lampiran bukti sakit/surat dari Firebase Storage
- **Tracking status** — Karyawan bisa lihat status real-time (pending / approved / rejected)
- **Pengajuan lembur** — Input jam dan alasan, pending approval admin

#### Modul Komunikasi

- **Chat 2-way** — Direct messaging dengan admin/HR (bukan antar sesama karyawan)
- **Dispute / Komplain** — Thread percakapan multi-turn dengan admin untuk permasalahan absensi
  - Karyawan bisa balas, admin bisa reply, status: pending → in_review → resolved → closed
  - Karyawan konfirmasi resolusi + beri rating 1–5 bintang
- **Notifikasi** — Push notification untuk approval cuti, balasan chat, pengumuman

#### Modul Darurat & Informasi

- **SOS Alert** — Kirim sinyal darurat + lokasi GPS ke admin dalam 1 klik
- **Broadcast** — Pengumuman resmi dari manajemen (read-only)
- **Kalender** — Jadwal event, hari libur, meeting perusahaan
- **FAQ** — Self-service help untuk pertanyaan umum, reduce ticket

#### Modul Profil & Pengaturan

- **Profil karyawan** — Foto, data diri, departemen, posisi, NIK
- **Ganti password** — Mandatory saat login pertama (first-login flow)
- **Dark/Light mode** — Tema persisted ke SharedPreferences
- **Enroll wajah** — Registrasi wajah untuk absensi (wajib sebelum bisa check-in)
- **Laporan masalah login** — Bisa dilaporkan tanpa harus login terlebih dahulu

### 4.2 Admin Panel — HR & Manajemen

#### Dashboard

- **Live attendance board** — Kartu real-time tiap karyawan: hadir / belum absen / terlambat / cuti
- **Online presence indicator** — Dot hijau/abu berdasarkan heartbeat 30 detik dari mobile
- **SOS Alert popup** — Muncul otomatis saat ada karyawan kirim darurat
- **Statistik harian** — Total hadir, tidak hadir, terlambat, cuti hari ini
- **Chart kehadiran** — Grafik tren mingguan/bulanan (recharts)

#### Manajemen Karyawan

- **Tambah karyawan** — Form lengkap + generate akun Firebase Auth otomatis + kirim email onboarding
- **Edit profil karyawan** — Data, departemen, shift, kontrak
- **Face enrollment** — Admin bisa trigger ulang enroll wajah
- **Status aktif/nonaktif** — Soft delete karyawan tanpa hapus data

#### Manajemen Kehadiran

- **Tabel absensi** — Filter by date, departemen, status; lihat foto check-in/out
- **Edit request approval** — Approve/reject koreksi absensi yang diajukan karyawan
- **Export laporan** — Download rekap kehadiran ke format yang bisa diproses

#### Manajemen Cuti & Lembur

- **List pengajuan** — Semua cuti/lembur pending dengan detail
- **Approve / Reject** — Satu klik dengan alasan penolakan
- **Saldo cuti** — Kelola saldo cuti tahunan per karyawan

#### Manajemen Shift & Jam Kerja

- **Definisi shift** — Nama shift, jam masuk, jam keluar, toleransi terlambat, hari kerja
- **Jam kerja custom** — Konfigurasi jadwal non-standar per divisi/karyawan

#### Komunikasi Admin

- **Chat dengan karyawan** — Inbox semua percakapan, kirim pesan
- **Broadcast** — Kirim pengumuman ke semua atau departemen tertentu
- **Dispute management** — Balas komplain karyawan, tandai resolved

#### Pengaturan Sistem

- **Konfigurasi kantor** — Koordinat GPS dan radius geofence (meter)
- **Konfigurasi absensi** — Maks percobaan face, threshold similarity
- **Konfigurasi notifikasi** — Toggle push notification per event
- **Maintenance** — Tools seed data, reset cache

#### Laporan & Analitik

- **Kalender organisasi** — Kelola event, meeting, hari libur
- **Audit log** — Riwayat semua aksi admin (siapa ubah apa kapan)
- **Login issues** — Monitor laporan masalah login karyawan

---

## 5. User Flow

### 5.1 Onboarding Karyawan Baru

```
Admin input data karyawan di panel
  → Firestore create users/{uid}
  → Cloud Function otomatis:
      - Buat akun Firebase Auth (email + password default)
      - Kirim email ke personalEmail berisi:
          • Username (NIK/email)
          • Password sementara
          • Link download APK
  → Karyawan install APK → login dengan kredensial email
  → Sistem deteksi firstLogin=true → redirect ke ChangePasswordScreen
  → Karyawan ganti password → firstLogin=false
  → Karyawan diarahkan ke Face Enrollment Screen
  → Setelah enroll → bisa akses semua fitur
```

### 5.2 Alur Absensi Harian

```
Karyawan buka app → Home Screen
  → Tap "Absen Masuk"
  → Sistem cek lokasi GPS (geofence)
      ✗ Diluar radius → tolak, tampil pesan error
      ✓ Dalam radius → lanjut
  → Buka kamera → face detection real-time
      ✗ Wajah tidak terdeteksi / score rendah → tampil error
      ✓ Score ≥ threshold → capture foto
  → Jika ONLINE:
      Upload foto ke Storage → write Firestore attendance/{userId}_{date}
  → Jika OFFLINE:
      Simpan ke SQLite + pending_sync
      → Saat online: auto-sync, hapus pending
  → Tampil konfirmasi "Absensi Berhasil" + waktu
  → Admin dashboard update real-time via Firestore listener
```

### 5.3 Alur Pengajuan Cuti

```
Karyawan → Menu Cuti → Ajukan Cuti
  → Isi form: tipe, tanggal mulai-selesai, alasan, upload dokumen
  → Submit → leaves/{id} status: pending
  → Admin dapat notifikasi → buka panel /leaves
  → Admin review → Approve / Reject + alasan
  → Cloud Function trigger: kirim FCM push ke karyawan
  → Karyawan dapat notifikasi + status terupdate di app
```

### 5.4 Alur Dispute / Komplain

```
Karyawan → Profile → Dispute → Ajukan Masalah
  → Isi form komplain → disputes/{id} status: pending
  → Admin buka /requests → lihat dispute → balas (reply ke sub-collection messages)
  → Status berubah: in_review
  → Karyawan terima notif → buka dispute detail → baca balasan admin
  → Karyawan bisa balas lagi (multi-turn thread)
  → Admin tandai resolved
  → Karyawan tampil banner "Masalah diselesaikan"
      → Konfirmasi: "Sudah selesai?" [Ya / Belum]
          Ya → beri rating 1-5 bintang → status: closed
          Belum → status: reopened → loop ulang ke admin
```

### 5.5 Alur SOS Emergency

```
Karyawan tap tombol SOS di app
  → Sistem ambil lokasi GPS
  → Write PARALEL ke:
      • sos_alerts (status: active)
      • adminNotifications (type: SOS)
  → Admin dashboard: ActiveAlerts component popup real-time
  → Admin hubungi karyawan / dispatch bantuan
  → Admin klik "Resolve" → status: resolved
```

---

## 6. Design & UI/UX

### 6.1 Prinsip Desain

- **Premium, bukan ramai** — 1 accent color per halaman, tidak campur-campur warna
- **Consistent border-radius** — `rounded-2xl` atau `rounded-3xl` konsisten di seluruh app
- **Tipografi hierarkis** — 3 level saja: heading 16px bold / body 13px regular / caption 11px
- **Informasi dulu, dekorasi belakangan** — No decorative elements yang tidak berfungsi

### 6.2 Admin Panel — Dark Crimson Gaming Theme

```
Background halaman : #1A0B10
Background card    : #2C1419
Accent utama       : #E5374A (merah crimson)
Text primer        : #FFFFFF
Text sekunder      : rgba(255,255,255,0.6)
Border             : rgba(255,255,255,0.06)
```

- Gradient halus dan subtle orbs sebagai elemen dekoratif
- Tidak ada flat color — semua card punya depth
- Ikon dari `lucide-react`, animasi dari `Framer Motion`
- Font: **Plus Jakarta Sans** (Google Fonts)

### 6.3 Admin Panel — Chat Page (Green Minimal)

```
Accent     : #16A34A (hijau)
Card       : White dengan border border-slate-200 rounded-3xl
Background : Light neutral
```

- Bersih, minimal, tidak ada color agresif
- Bubble chat dengan tail, timestamp tipis

### 6.4 Mobile App — Zen Premium Theme

```
Dark mode:
  Background  : #0B1120 (deep navy)
  Card        : #131D2E
  Accent      : #4F46E5 (indigo) + #22D3EE (cyan highlight)
  JNE Orange  : #FF6B00 (branding, sparingly)

Light mode:
  Background  : #F8FAFC
  Card        : #FFFFFF
  Same accents
```

- Konsisten di semua 20+ screen via `isDarkMode` dari AppProvider
- Rounded corners konsisten, letter spacing baik
- Animasi subtle via `animate_do` package

### 6.5 UX Patterns

- **Skeleton loading** — Placeholder saat data fetch, tidak blank/spinner kasar
- **Pull-to-refresh** — Standard pada list views
- **Optimistic UI** — Status tampil langsung sebelum Firestore confirm
- **Real-time update** — Tidak perlu refresh manual, Firestore listener otomatis
- **Empty state** — Ilustrasi dan teks jelas saat tidak ada data
- **Error handling** — Toast/snackbar dengan pesan user-friendly, bukan error code teknis

---

## 7. Database Overview

### 7.1 Platform

**Firebase Project:** `admin-absensi-jne-mtp`  
**Region:** `asia-southeast2` (Jakarta)  
**Database:** Cloud Firestore (NoSQL, real-time)

### 7.2 Koleksi Utama (21 Koleksi)

| Koleksi                     | Fungsi                      | Doc ID Convention       |
| --------------------------- | --------------------------- | ----------------------- |
| `users`                     | Profil karyawan & admin     | Firebase Auth UID       |
| `attendance`                | Record absensi harian       | `{userId}_{YYYY-MM-DD}` |
| `leaves`                    | Pengajuan cuti              | Auto ID                 |
| `overtime`                  | Pengajuan lembur            | Auto ID                 |
| `shifts` / `jamKerja`       | Definisi jam kerja          | Auto ID                 |
| `departments`               | Definisi departemen         | Auto ID                 |
| `messages`                  | Chat flat admin↔karyawan    | Auto ID                 |
| `disputes`                  | Komplain karyawan           | Auto ID                 |
| `disputes/{id}/messages`    | Thread balasan dispute      | Auto ID                 |
| `sos_alerts`                | Sinyal darurat + lokasi     | Auto ID                 |
| `broadcasts`                | Pengumuman global           | Auto ID                 |
| `events` / `calendarEvents` | Event kalender              | Auto ID                 |
| `edit_requests`             | Koreksi absensi             | Auto ID                 |
| `adminNotifications`        | Notif untuk admin dashboard | Auto ID                 |
| `userNotifications`         | Notif personal karyawan     | Auto ID                 |
| `settings/system`           | Config sistem (single doc)  | `system`                |
| `user_heartbeats`           | Status online mobile        | userId                  |
| `fcm_tokens`                | Push notification tokens    | Token string            |
| `audit_log`                 | Jejak aksi admin            | Auto ID                 |
| `login_issues`              | Laporan masalah login       | Auto ID                 |
| `pending_sync`              | Antrian offline             | Auto ID                 |
| `leave_balances`            | Saldo cuti per user         | userId                  |

### 7.3 Relasi Kunci

```
users
  ├── attendance (userId field)
  ├── leaves (userId field)
  ├── overtime (userId field)
  ├── messages (senderId / receiverId)
  ├── disputes (userId field)
  │     └── messages (sub-collection)
  ├── userNotifications (userId field)
  └── fcm_tokens (userId field)

settings/system
  └── office.lat, office.lng, office.radiusMeters
        → dipakai geofence check di mobile

shifts / jamKerja
  → diassign ke users.shiftId
  → dipakai scheduledOvertimeCalc Cloud Function
```

### 7.4 Composite Indexes

- `attendance`: (userId ASC, date DESC)
- `leaves`: (userId ASC, createdAt DESC)
- `overtime`: (userId ASC, date DESC)

---

## 8. Tech Stack

### 8.1 Mobile App

| Layer            | Teknologi                                                                 |
| ---------------- | ------------------------------------------------------------------------- |
| Framework        | Flutter SDK ^3.10.4 (Dart)                                                |
| State Management | Provider pattern (`AppProvider`, `ChatProvider`)                          |
| Backend SDK      | Firebase Core, Auth, Firestore, Storage, Messaging, Performance           |
| Face Detection   | `google_mlkit_face_detection` (on-device)                                 |
| Geolocation      | `geolocator` + `google_maps_flutter`                                      |
| Offline Storage  | `sqflite` (SQLite queue)                                                  |
| Preferences      | `shared_preferences`                                                      |
| UI Extras        | `google_fonts`, `animate_do`, `percent_indicator`, `cached_network_image` |
| Utilities        | `connectivity_plus`, `permission_handler`, `flutter_local_notifications`  |

### 8.2 Admin Panel

| Layer           | Teknologi                        |
| --------------- | -------------------------------- |
| Framework       | Next.js 16.1.6 (App Router)      |
| UI Library      | React 19.2.3 + TypeScript 5      |
| Styling         | Tailwind CSS v4.2                |
| Animation       | Framer Motion 12, anime.js 4     |
| Charts          | recharts                         |
| Icons           | lucide-react                     |
| Notifications   | sonner (toast)                   |
| Firebase Client | firebase 12.9                    |
| Firebase Server | firebase-admin 12 (API routes)   |
| Font            | Plus Jakarta Sans (Google Fonts) |

### 8.3 Backend

| Layer             | Teknologi                                            |
| ----------------- | ---------------------------------------------------- |
| Database          | Cloud Firestore (NoSQL)                              |
| Auth              | Firebase Authentication (email + password)           |
| Storage           | Firebase Cloud Storage (foto wajah, dokumen)         |
| Push Notification | Firebase Cloud Messaging (FCM)                       |
| Server Functions  | Cloud Functions v1 (Node.js / TypeScript)            |
| Server API        | Next.js API Routes (admin-only, verified via cookie) |
| Region            | `asia-southeast2` (Jakarta)                          |

### 8.4 Cloud Functions (8 Functions)

| Function                | Trigger                       | Fungsi                                  |
| ----------------------- | ----------------------------- | --------------------------------------- |
| `onEmployeeCreated`     | Firestore users onCreate      | Buat Auth account + notif admin         |
| `sendOnboardingEmail`   | Firestore users onCreate      | Kirim email kredensial + link APK       |
| `onLeaveStatusUpdate`   | Firestore leaves onUpdate     | FCM push approval/rejection ke karyawan |
| `onAttendanceCreated`   | Firestore attendance onCreate | Processing & logging                    |
| `onUserProfileUpdated`  | Firestore users onUpdate      | Sync profil                             |
| `onFaceEnrolled`        | Firestore users onUpdate      | Notif admin face enrollment selesai     |
| `onAttendanceFailed`    | HTTPS Callable                | Notif admin gagal face recognition 3x   |
| `scheduledOvertimeCalc` | PubSub 23:00 WIB daily        | Kalkulasi lembur semua karyawan         |

---

## 9. Security & Permissions

### 9.1 Firestore Security Rules

- **Admin catch-all**: Role `admin` / `superadmin` bisa read/write semua koleksi
- **Karyawan**: Hanya bisa akses data milik sendiri (`userId == request.auth.uid`)
- **Koleksi sensitif**: `audit_log`, `fcm_tokens`, `leave_balances` — admin-only
- **login_issues**: Izin create **tanpa auth** (user belum bisa login) dengan validasi field ketat
- **attendance `get`**: Longgar untuk semua auth user (diperlukan Firestore transaction)
- **Chat**: Security rule block employee↔employee, hanya admin↔employee

### 9.2 Admin Session

- Cookie `jne_admin_session` diverify di setiap API route server-side
- Dual verify: Firebase Auth UID + role check ke Firestore `users` collection
- Tidak ada sensitive data yang di-expose ke client tanpa verifikasi

### 9.3 Mobile Security

- Face recognition score harus ≥ threshold (configurable dari `settings/system`)
- Max percobaan face configurable — setelah melebihi, trigger notif ke admin
- DeviceId tracking — deteksi login dari device berbeda
- Offline data di SQLite ter-clear saat logout

---

## 10. Technical Requirements

### 10.1 Mobile

- **Minimum OS:** Android 8.0 (API 26)
- **Permission required:** Camera, Location (Always / In-use), Notification, Storage
- **Offline capability:** Absensi bisa dilakukan tanpa internet, auto-sync saat online
- **Heartbeat:** Write ke Firestore setiap 30 detik saat app aktif (presence system)
- **Push notification:** FCM dengan Android notification channel `high_importance_channel`
- **Face enrollment:** Wajib sebelum bisa absensi — enforced di app level

### 10.2 Admin Panel

- **Browser support:** Chrome 100+, Firefox 100+, Edge 100+
- **Responsive:** Minimal support tablet landscape; primary target desktop 1280px+
- **Real-time:** Semua tabel absensi dan notifikasi via Firestore `onSnapshot` listener
- **Session:** HTTP-only cookie, expire sesuai Firebase Auth token (1 jam + refresh)

### 10.3 Backend / Infrastructure

- **Firestore region:** `asia-southeast2` untuk latensi rendah di Indonesia
- **Functions timeout:** Default 60 detik, `scheduledOvertimeCalc` timeout 540 detik
- **Storage rules:** Foto absensi hanya bisa diakses auth user (pemilik atau admin)
- **FCM multicast:** Semua token aktif user di-multicast, token expired auto-cleanup

### 10.4 Performance Targets

| Metric                                        | Target                  |
| --------------------------------------------- | ----------------------- |
| Admin dashboard initial load                  | < 3 detik (cold)        |
| Firestore listener update latency             | < 500ms                 |
| Mobile check-in process (GPS + face + upload) | < 15 detik (online, 4G) |
| Mobile check-in process (offline mode)        | < 5 detik               |
| Cloud Function cold start                     | < 3 detik               |
| FCM delivery latency                          | < 10 detik              |

---

## 11. Scope Project

### 11.1 Dalam Scope (In Scope)

**Mobile:**

- Autentikasi karyawan (email + password, first-login mandatory change)
- Face enrollment + face recognition absensi
- GPS geofence validation absensi
- Check-in / check-out harian
- Mode offline + sync otomatis
- Riwayat kehadiran pribadi
- Pengajuan cuti (semua tipe)
- Pengajuan lembur
- Chat 2-way dengan admin
- Dispute / komplain sistem + thread + rating
- Notifikasi push (FCM)
- SOS alert + GPS
- Broadcast / pengumuman (read-only)
- Kalender event perusahaan
- Profil karyawan + ganti password
- Dark/light mode
- FAQ self-service
- Laporan masalah login (unauthenticated)

**Admin Panel:**

- Login admin + session management
- Dashboard live kehadiran
- Presence monitoring real-time
- SOS alert popup
- CRUD karyawan + onboarding email otomatis
- Face enrollment management
- Manajemen kehadiran + edit request approval
- Manajemen cuti (approve/reject) + saldo cuti
- Manajemen lembur
- Shift & jam kerja management
- Chat inbox + kirim pesan
- Broadcast / pengumuman
- Dispute management + reply
- Kalender event perusahaan
- Laporan kehadiran + export
- Pengaturan sistem (GPS, face threshold, dll)
- Audit log
- Login issues management
- Departemen management

### 11.2 Diluar Scope (Out of Scope)

- Integrasi payroll / penggajian otomatis (hanya data kehadiran, bukan kalkulasi gaji)
- Integrasi HRD eksternal (SIAK, SAP, dll)
- iOS app (Android only)
- Web app untuk karyawan (admin panel only di web)
- Chat group / broadcast reply (broadcast satu arah)
- Chat antar sesama karyawan
- Fingerprint biometrik (hanya face recognition)
- Jadwal shift rotasi otomatis
- Manajemen penggajian dan slip gaji
- Multi-cabang / multi-office (single office geofence)

### 11.3 Risiko & Mitigasi

| Risiko                                      | Dampak                    | Mitigasi                                                       |
| ------------------------------------------- | ------------------------- | -------------------------------------------------------------- |
| Karyawan tidak punya kamera bagus           | Face detection gagal      | Konfigurasi threshold yang toleran, admin bisa override manual |
| Koneksi internet buruk di lapangan          | Absensi tidak tersimpan   | Offline mode SQLite + auto-sync                                |
| Token FCM expired                           | Notifikasi tidak terkirim | Cloud Function auto-cleanup token invalid                      |
| GPS spoofing                                | Absensi dari luar kantor  | Kombinasi dengan face recognition — sulit spoof keduanya       |
| Data Firestore tak sinkron (race condition) | Record dobel/hilang       | Firestore transaction + docId deterministic `{userId}_{date}`  |
| Karyawan lupa password pertama              | Tidak bisa login          | Fitur login_issues tanpa auth + kontak admin                   |

---

## 12. Deployment & Environments

### 12.1 Environment

| Environment | Deskripsi                                     |
| ----------- | --------------------------------------------- |
| Development | `npm run dev` (admin), `flutter run` (mobile) |
| Production  | Firebase Hosting (admin), Play Store (mobile) |

### 12.2 Scripts Utilitas

```bash
# Admin panel
cd admin && npm run dev

# Mobile
cd user_mobile && flutter run

# Deploy Cloud Functions
cd admin/functions && firebase deploy --only functions

# Deploy Firestore Rules
firebase deploy --only firestore:rules

# Seed data
node admin/scripts/seed_employees.mjs
node admin/scripts/seed_departments.mjs
node admin/scripts/setup_admin.mjs
```

### 12.3 Firebase Project

- **Project ID:** `admin-absensi-jne-mtp`
- **Region:** `asia-southeast2`
- **Services aktif:** Firestore, Auth, Storage, FCM, Cloud Functions

---

### 13. ini adalah gambar conoth utnuk sistem pembagian dari link donwload dan juga buat login dan password nya

![alt text](image-1.png) -> kamu cek itu di gambar situ itu gw mau nya kek begitu okk dan itu nanti ke kirim nya lewat gmail asli dari Email Pribadi (Gmail) itu yang ada di kolom tambah karyawan okk
_Dokumen ini adalah living document — diperbarui seiring development berlanjut._
