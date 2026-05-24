# 1. PRE-TEST SETUP

> **Tujuan**: Siapkan environment, akun, device, dan konfigurasi sebelum testing dimulai.
> **Estimasi waktu**: 2 jam
> **Prasyarat**: Akses Firebase Console + repo project

---

## 1.1 Lingkungan Test

- [ ] Buat **2 akun admin** test
  - admin1@jne.mtp.com (role: admin)
  - admin2@jne.mtp.com (role: superadmin)
- [ ] Buat **5 akun karyawan** test dengan berbagai departemen
  - Karyawan 1: dept "Kurir"
  - Karyawan 2: dept "Driver"
  - Karyawan 3: dept "Inbound"
  - Karyawan 4: dept "Outbound"
  - Karyawan 5: dept "Admin Office"
- [ ] Siapkan **2 device Android fisik**
  - Device 1: minimal API 21 (Android 5)
  - Device 2: Android 13/14 (notification permission baru)
- [ ] Siapkan **iOS device** (kalau target iOS aktif)
- [ ] Browser admin: Chrome, Edge, Firefox versi terbaru
- [ ] **JANGAN pakai production data** — siapkan environment staging atau database test
- [ ] Backup database sebelum test besar-besaran
- [ ] Simpan kontak emergency dev kalau ada bug critical

## 1.2 Tools

- [ ] Firebase Console (Firestore, Auth, Storage, Functions logs, Performance)
- [ ] Android Studio / `adb logcat` untuk inspect mobile logs
- [ ] Chrome DevTools untuk inspect admin panel
- [ ] Postman / curl untuk test API routes
- [ ] Stopwatch (ukur load time)
- [ ] Aplikasi mock GPS (cek geofence cheating defense)
- [ ] Network throttler (DevTools / Network Link Conditioner / Charles Proxy)
- [ ] Screen recorder (untuk bukti bug visual)

## 1.3 Konfigurasi Backend

- [ ] Firestore Security Rules sudah deployed ke staging
- [ ] Cloud Functions sudah deployed ke region asia-southeast2
- [ ] Firestore Composite Indexes complete (cek di Firebase Console)
- [ ] Office lat/lng di `settings/system` valid (cek di Google Maps)
- [ ] Office `radiusMeters` realistis (default 500m, sesuaikan kebutuhan)
- [ ] Face similarity threshold sesuai (default 70-80)
- [ ] Minimal 1 jam kerja default sudah dibuat
- [ ] Minimal 3 departemen sudah dibuat
- [ ] Holiday list sudah di-input (kalau ada)

## 1.4 Konfigurasi Frontend

- [ ] Admin panel: env vars lengkap di staging (`NEXT_PUBLIC_FIREBASE_*`)
- [ ] Mobile app: `google-services.json` & `GoogleService-Info.plist` valid
- [ ] Mobile: APK build release version untuk test
- [ ] Browser cache cleared sebelum test admin

## 1.5 Test Data Awal

- [ ] Generate 30 hari riwayat absensi dummy via `seed_history.mjs`
- [ ] Buat 5 cuti dummy dengan berbagai status
- [ ] Buat 3 broadcast dummy
- [ ] Buat 2 event kalender dummy

## 1.6 Akun Komunikasi

- [ ] Email pribadi tester ready untuk terima onboarding email
- [ ] WhatsApp tester ready (untuk test link onboarding)
- [ ] Channel komunikasi tim (Slack/Discord/WA) untuk laporan real-time

---

## Catatan

```
[Tulis catatan setup atau masalah yang ditemui saat persiapan]
```

---

**Tester**: ____________________________
**Tanggal selesai**: ____________________
**Status**: ⬜ Done / ⬜ Need rework
