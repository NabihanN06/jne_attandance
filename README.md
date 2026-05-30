# JNE Attendance System

Sistem manajemen kehadiran karyawan JNE berbasis face recognition + GPS, terdiri dari:

- **Admin Panel** — Web dashboard Next.js untuk HR/manajemen (`admin/`)
- **Mobile App** — Aplikasi Android Flutter untuk karyawan (`user_mobile/`)
- **Backend** — Firebase Firestore + Cloud Functions + FCM

---

## Daftar Isi

1. [Prasyarat](#1-prasyarat)
2. [Struktur Folder](#2-struktur-folder)
3. [Setup Firebase](#3-setup-firebase)
4. [Setup Admin Panel](#4-setup-admin-panel)
5. [Setup Mobile App](#5-setup-mobile-app)
6. [Menjalankan Admin Panel](#6-menjalankan-admin-panel)
7. [Menjalankan Mobile App](#7-menjalankan-mobile-app)
8. [Deploy Cloud Functions](#8-deploy-cloud-functions)
9. [Akun Default untuk Testing](#9-akun-default-untuk-testing)
10. [Troubleshooting](#10-troubleshooting)

---

## 1. Prasyarat

Pastikan semua tools berikut sudah terinstal sebelum melanjutkan.

### Node.js & npm

Versi yang dibutuhkan: **Node.js 18 atau 20 (LTS)**

```bash
node -v   # harus 18.x atau 20.x
npm -v    # harus 9.x atau 10.x
```

Download: https://nodejs.org/en/download

### Flutter SDK

Versi yang dibutuhkan: **Flutter 3.10.4 atau lebih baru**

```bash
flutter --version
flutter doctor     # pastikan tidak ada error merah
```

Download + panduan install Windows: https://docs.flutter.dev/get-started/install/windows

### Android Studio

Diperlukan untuk emulator Android atau build ke device fisik.

Download: https://developer.android.com/studio

Setelah install:
1. Buka Android Studio → **SDK Manager**
2. Install **Android SDK Platform 33 atau 34**
3. Di tab **SDK Tools**, centang **Android Emulator** dan **Android SDK Platform-Tools**
4. Buat virtual device: **Device Manager → Create Device → Pixel 6, API 33**

### Firebase CLI

```bash
npm install -g firebase-tools
firebase login
```

Ikuti proses login browser yang muncul. Verifikasi:

```bash
firebase projects:list   # harus ada proyek admin-absensi-jne-mtp
```

---

## 2. Struktur Folder

```
jne_attandance/
├── admin/                    ← Admin Panel (Next.js)
│   ├── src/
│   │   ├── app/
│   │   │   ├── (admin)/     # 18+ halaman protected
│   │   │   ├── (auth)/      # login, forgot-password
│   │   │   └── api/         # server-side API routes
│   │   ├── components/      # UI components
│   │   ├── hooks/           # 20+ business logic hooks
│   │   ├── context/         # Auth, Theme, Notification
│   │   └── lib/             # firebase.ts, firebase-admin.ts
│   ├── functions/
│   │   └── src/index.ts     # 7 Cloud Functions
│   ├── firestore.rules
│   ├── firestore.indexes.json
│   └── package.json
│
├── user_mobile/              ← Mobile App (Flutter)
│   └── lib/
│       ├── main.dart
│       ├── models/app_models.dart
│       ├── providers/
│       │   ├── app_provider.dart  # State global
│       │   └── chat_provider.dart
│       ├── screen/           # 20+ screens
│       └── utils/            # geofence, offline, connectivity, presence
│
├── PRD.md
├── QA_AUDIT.md
└── README.md
```

---

## 3. Setup Firebase

Project Firebase yang digunakan: **`admin-absensi-jne-mtp`**, region `asia-southeast2`.

### 3.1 Konfigurasi Admin Panel — Client SDK

File `admin/src/lib/firebase.ts` harus berisi config Firebase. Cara mendapatkan config:

1. Buka https://console.firebase.google.com → pilih project `admin-absensi-jne-mtp`
2. Klik ikon gear → **Project Settings**
3. Scroll ke **Your apps** → pilih web app
4. Copy `firebaseConfig` dan pastikan isinya sudah ada di `admin/src/lib/firebase.ts`

### 3.2 Konfigurasi Admin Panel — Admin SDK (Server-side)

File `admin/src/lib/firebase-admin.ts` butuh Service Account untuk API routes.

Cara mendapatkan Service Account:
1. Firebase Console → Project Settings → **Service Accounts**
2. Klik **Generate new private key** → download JSON
3. Simpan sebagai `admin/service-account.json`

> File `service-account.json` tidak boleh di-commit ke git — sudah ada di `.gitignore`.

### 3.3 Environment Variables Admin Panel

Buat file `admin/.env.local` (kalau belum ada):

```env
# Firebase Client Config (prefix NEXT_PUBLIC_ = aman di browser)
NEXT_PUBLIC_FIREBASE_API_KEY=your-api-key
NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=admin-absensi-jne-mtp.firebaseapp.com
NEXT_PUBLIC_FIREBASE_PROJECT_ID=admin-absensi-jne-mtp
NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET=admin-absensi-jne-mtp.appspot.com
NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=your-sender-id
NEXT_PUBLIC_FIREBASE_APP_ID=your-app-id

# Firebase Admin SDK — path ke service account
GOOGLE_APPLICATION_CREDENTIALS=./service-account.json
```

Nilai-nilai ini bisa didapat dari Firebase Console → Project Settings → Your apps → Config.

### 3.4 Konfigurasi Mobile App — google-services.json

File ini harus ada di `user_mobile/android/app/google-services.json`.

Cara mendapatkan:
1. Firebase Console → Project Settings → Your apps
2. Klik icon Android → **Download google-services.json**
3. Letakkan file di `user_mobile/android/app/`

### 3.5 Aktifkan Layanan Firebase

Di Firebase Console, pastikan layanan berikut sudah aktif:

| Layanan | Cara Aktifkan |
|---|---|
| Authentication | Authentication → Sign-in method → Email/Password → Enable |
| Firestore | Firestore Database → Create database → Production mode |
| Storage | Storage → Get started |
| Cloud Messaging | Sudah aktif by default |

---

## 4. Setup Admin Panel

### 4.1 Install Dependencies

```bash
cd admin
npm install
```

Tunggu hingga selesai (1-3 menit tergantung koneksi).

### 4.2 Install Dependencies Cloud Functions

```bash
cd admin/functions
npm install
cd ../..
```

### 4.3 Deploy Firestore Security Rules

```bash
cd admin
firebase use admin-absensi-jne-mtp
firebase deploy --only firestore:rules
```

### 4.4 Deploy Firestore Indexes

```bash
firebase deploy --only firestore:indexes
```

> Indexes diperlukan agar query seperti `attendance` by userId + date tidak error.

### 4.5 (Opsional) Isi Data Awal

Jika Firestore masih kosong, jalankan scripts seed:

```bash
cd admin
node scripts/setup_admin.mjs       # Wajib pertama — buat akun admin
node scripts/seed_departments.mjs  # Isi data departemen
node scripts/seed_employees.mjs    # Isi data karyawan contoh
```

---

## 5. Setup Mobile App

### 5.1 Install Flutter Dependencies

```bash
cd user_mobile
flutter pub get
```

Perintah ini mengunduh semua package (Firebase, ML Kit, geolocator, sqflite, dll).

### 5.2 Verifikasi Konfigurasi Android

Pastikan `user_mobile/android/app/build.gradle` memiliki:

```gradle
android {
    defaultConfig {
        minSdkVersion 26   // Android 8.0 minimum
    }
}
```

Jika nilainya kurang dari 26, ubah ke 26.

### 5.3 Verifikasi google-services.json

```bash
ls user_mobile/android/app/google-services.json
# Harus ada file ini
```

### 5.4 Flutter Doctor

```bash
flutter doctor -v
```

Semua item harus ✅ kecuali yang berhubungan dengan iOS atau Xcode (tidak diperlukan).

---

## 6. Menjalankan Admin Panel

### Development Mode

```bash
cd admin
npm run dev
```

Buka browser: **http://localhost:3000**

Halaman login akan tampil. Gunakan akun admin dari `setup_admin.mjs`.

### Build Production

```bash
cd admin
npm run build
npm run start
```

### Yang Diharapkan

- Halaman `/login` dengan form email + password
- Setelah login: Dashboard real-time dengan statistik kehadiran
- Sidebar navigasi: Karyawan, Kehadiran, Cuti, Chat, Laporan, Pengaturan, dll

---

## 7. Menjalankan Mobile App

### Opsi A — Emulator Android

1. Buka **Android Studio → Device Manager**
2. Klik ▶ Play pada virtual device yang sudah dibuat
3. Tunggu emulator menyala (1-2 menit)

Lalu di terminal:

```bash
cd user_mobile
flutter run
```

### Opsi B — Device Fisik Android

1. Aktifkan **Developer Options** di HP:
   - Pengaturan → Tentang Ponsel → ketuk **Nomor Build** 7x
2. Aktifkan **USB Debugging** di Developer Options
3. Hubungkan HP ke laptop via USB → pilih **Allow** di popup HP

Verifikasi device terdeteksi:
```bash
flutter devices
# Harus muncul nama device Anda
```

Jalankan:
```bash
cd user_mobile
flutter run
```

### Jika Ada Lebih dari Satu Device

```bash
flutter run -d emulator-5554    # ganti dengan device-id yang muncul di flutter devices
```

### Yang Diharapkan

- Splash screen JNE → halaman login
- Setelah login: Home screen dengan status absensi dan menu
- Jika login pertama: diarahkan ke halaman ganti password wajib

---

## 8. Deploy Cloud Functions

Lakukan ini hanya jika ada perubahan pada `admin/functions/src/index.ts`.

### 8.1 Setup SMTP untuk Email Onboarding (Wajib sebelum deploy pertama)

`onEmployeeCreated` mengirim email kredensial ke karyawan baru via Gmail SMTP + Nodemailer. Kalau SMTP belum diset, function tetap jalan tapi email di-skip dan admin harus share kredensial manual.

**Langkah setup Gmail App Password:**

1. Login ke akun Gmail yang akan dipakai untuk kirim email (mis. `bot@jne-mtp.com` atau Gmail HR)
2. Aktifkan 2-Factor Authentication: https://myaccount.google.com/security
3. Buat App Password: https://myaccount.google.com/apppasswords
   - Pilih app: **Mail**
   - Pilih device: **Other** → tulis "JNE Functions"
   - Copy 16-character App Password yang muncul (mis. `abcd efgh ijkl mnop`)

**Set credentials ke Firebase Functions config:**

```bash
cd admin
firebase functions:config:set \
  smtp.user="bot@gmail.com" \
  smtp.password="abcd efgh ijkl mnop" \
  smtp.from_name="JNE Martapura HR" \
  apk.url="https://link-ke-download-apk"
```

Verifikasi config terset:
```bash
firebase functions:config:get
```

### 8.2 Build TypeScript

```bash
cd admin/functions
npm run build
```

### 8.3 Deploy

```bash
# Deploy semua functions
firebase deploy --only functions

# Deploy function tertentu saja
firebase deploy --only functions:onEmployeeCreated
firebase deploy --only functions:onOvertimeStatusUpdate
firebase deploy --only functions:scheduledOvertimeCalc
```

### 8.4 Deploy Rules + Indexes (setelah ada perubahan)

```bash
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
```

> **Catatan:** Deploy Cloud Functions memerlukan akun Firebase dengan **Blaze plan** (pay-as-you-go). Spark plan (gratis) tidak mendukung outbound network di Cloud Functions (jadi SMTP tidak akan jalan di Spark).

---

## 9. Akun Default untuk Testing

### Admin Panel

Setelah menjalankan `setup_admin.mjs`, lihat outputnya untuk kredensial, atau:

```
Email    : admin@jne-mtp.com
Password : (cek output script, atau reset dari Firebase Console → Authentication)
```

### Mobile App (Karyawan Test)

Karyawan ditambahkan via Admin Panel. Setelah admin tambah karyawan:

1. Firebase Auth account otomatis dibuat oleh Cloud Function `onEmployeeCreated`
2. Admin share email + password sementara ke karyawan
3. Karyawan login → wajib ganti password → lalu enroll wajah → bisa absen

---

## 10. Troubleshooting

### `Module not found` saat `npm run dev`

```bash
cd admin
rm -rf node_modules .next
npm install
npm run dev
```

### `Firebase: Error (auth/invalid-credential)` di Admin Panel

- Pastikan `admin/.env.local` sudah diisi dengan nilai yang benar
- Pastikan Firebase Authentication → Email/Password sudah di-enable
- Pastikan tidak ada typo di `NEXT_PUBLIC_FIREBASE_PROJECT_ID`

### `PERMISSION_DENIED` dari Firestore

```bash
# Deploy ulang security rules
cd admin
firebase deploy --only firestore:rules
```

Jika masih error: cek Firebase Console → Firestore → Rules → pastikan rules aktif dan tidak expired.

### Flutter `MissingPluginException`

```bash
cd user_mobile
flutter clean
flutter pub get
flutter run
```

### Flutter error `google-services.json` tidak ditemukan

Pastikan file ada di path yang benar:
```
user_mobile/android/app/google-services.json
```

Jika belum ada, download dari Firebase Console → Project Settings → Your apps → Android.

### Flutter `minSdkVersion` error

Buka `user_mobile/android/app/build.gradle`, cari `minSdkVersion` dan ubah ke minimal `26`.

### Permission Camera / Location ditolak di emulator

1. Buka **Settings** di emulator
2. Apps → JNE Attendance → Permissions
3. Aktifkan Camera dan Location

### Port 3000 sudah terpakai

```bash
# Jalankan di port lain
cd admin
npx next dev -p 3001
```

Atau hentikan proses yang memakai port 3000:

```bash
# PowerShell
$pid = (Get-NetTCPConnection -LocalPort 3000).OwningProcess
Stop-Process -Id $pid
```

### `firebase: command not found` setelah install

Tambahkan npm global bin ke PATH:

```bash
# Cek lokasi npm global
npm config get prefix
# Tambahkan <prefix>/bin ke PATH environment variable Windows
```

---

## Tech Stack

| Komponen | Teknologi | Versi |
|---|---|---|
| Admin Panel | Next.js + React + TypeScript | 16.1.6 / 19.2.3 / 5 |
| Styling | Tailwind CSS v4 + Framer Motion | 4.2 / 12 |
| Mobile App | Flutter + Dart | SDK ^3.10.4 |
| State Management | Provider | 6.x |
| Database | Firebase Firestore (NoSQL) | — |
| Auth | Firebase Authentication | — |
| Storage | Firebase Cloud Storage | — |
| Push Notif | Firebase Cloud Messaging | — |
| Functions | Cloud Functions v1 (Node.js) | — |
| Face Detection | Google ML Kit (on-device) | — |
| GPS | Geolocator + Google Maps Flutter | — |
| Offline Cache | sqflite (SQLite) | — |
