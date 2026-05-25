# 16. TEST DATA SKENARIO E2E

> **Tujuan**: 8 skenario realistik untuk smoke test minimum sebelum release.
> **Estimasi waktu**: 4 jam total (30 menit per skenario)
> **Prasyarat**: Section 1 Pre-Test Setup selesai
> **Tester**: Senior QA Tester

---

## Cara Pakai

1. Eksekusi tiap skenario dari A sampai H berurutan
2. Tandai ✅/❌ per step
3. Catat masalah pakai template [15_bug_report_template.md](15_bug_report_template.md)
4. Kalau semua skenario PASS → app **minimum viable** untuk release
5. Skenario gagal di tengah → STOP, fix dulu, ulangi

---

## 🎬 SKENARIO A: New Employee Onboarding

**Goal**: Karyawan baru dari nol bisa absen pertama dalam 1 jam.

**Persona**: Budi Santoso, kurir baru, hari pertama kerja.

### Steps

1. [ ] **Admin** buka /employees → klik "Tambah Karyawan"
2. [ ] Isi form:
   - Nama: `Budi Santoso`
   - Email: `budi.santoso` (akan jadi budi.santoso@jne.mtp.com)
   - Personal email: `budi.santoso@gmail.com` (atau email tester yang bisa dicek)
   - Phone: `081234567890`
   - Departemen: `Kurir`
   - Position: `Kurir Rider`
   - Jam Kerja: pilih default atau custom
3. [ ] Submit form
4. [ ] **Verifikasi**: Toast success, modal close, Budi muncul di list
5. [ ] **Verifikasi**: Cloud Function `onEmployeeCreated` → Firebase Auth account terbuat
6. [ ] **Verifikasi**: `adminNotifications` punya doc baru type `new_employee`
7. [ ] **Verifikasi**: Cek inbox `budi.santoso@gmail.com` → email onboarding masuk dalam 1 menit
8. [ ] **Verifikasi**: Email berisi: email login, password default `JNE123!`, link APK
9. [ ] **Karyawan (Budi)** install APK di device
10. [ ] Buka app → splash → onboarding (kalau first install)
11. [ ] Login dengan `budi.santoso@jne.mtp.com` + `JNE123!`
12. [ ] **Verifikasi**: Force change password screen muncul
13. [ ] Ganti password baru (min 8 char, ada angka)
14. [ ] **Verifikasi**: Masuk home → Cloud Function set `firstLogin=false`
15. [ ] Grant semua permission (camera, location, notif)
16. [ ] Buka menu Face Enrollment → capture & upload
17. [ ] **Verifikasi**: Foto upload sukses → `faceRegistered=true`
18. [ ] **Verifikasi**: Admin dapat notif "Budi selesai enrollment"
19. [ ] Pergi ke kantor (atau mock lokasi dalam radius)
20. [ ] Tap "Check In" di home
21. [ ] **Verifikasi**: Geofence pass → camera open
22. [ ] Capture wajah → face score OK
23. [ ] **Verifikasi**: Attendance doc terbuat di Firestore
24. [ ] **Verifikasi**: Admin dashboard tampil Budi check-in real-time
25. [ ] **Verifikasi**: Foto check-in tersimpan di Storage

**Time-to-complete**: __________ (target: < 1 jam)

**Status**: ⬜ Pass / ⬜ Fail di step ___

---

## 🎬 SKENARIO B: Cuti Sakit Mendadak

**Goal**: Karyawan ajukan cuti sakit, admin approve, push notif sampai.

**Persona**: Ani, sakit demam, mau cuti hari ini & 2 hari ke depan.

### Steps

1. [ ] **Karyawan (Ani)** buka app → menu "Cuti"
2. [ ] Klik "Ajukan Cuti"
3. [ ] Pilih type: `Sakit`
4. [ ] Start date: today
5. [ ] End date: today + 2 hari → totalDays auto-calculate = 3
6. [ ] Reason: "Demam tinggi, perlu istirahat"
7. [ ] Upload surat dokter (foto/PDF dummy)
8. [ ] Submit
9. [ ] **Verifikasi**: Toast success, cuti muncul di "Cuti Saya" status `Pending`
10. [ ] **Verifikasi**: Admin dapat notif "Ada cuti baru dari Ani"
11. [ ] **Admin** buka /leaves → pilih cuti Ani
12. [ ] Lihat detail + dokumen pendukung
13. [ ] Klik "Approve"
14. [ ] **Verifikasi**: Status berubah jadi `Approved`
15. [ ] **Verifikasi**: Cloud Function `onLeaveStatusUpdate` trigger
16. [ ] **Verifikasi**: Ani dapat push notif "Cuti kamu Approved"
17. [ ] **Verifikasi**: Status cuti di mobile Ani update real-time jadi `Approved`
18. [ ] **Verifikasi (besok)**: Tanggal cuti, status `attendance` Ani auto-`leave`

**Status**: ⬜ Pass / ⬜ Fail di step ___

---

## 🎬 SKENARIO C: Karyawan di Luar Geofence

**Goal**: Sistem tolak absensi user yang tidak di area kantor.

**Persona**: Joko, kurir, masih di lapangan.

### Steps

1. [ ] **Karyawan (Joko)** posisi > 500m dari kantor (mock GPS atau fisik di luar)
2. [ ] Buka app → tap "Check In"
3. [ ] **Verifikasi**: Tampil pesan "Anda berada X meter dari kantor. Harap berada dalam radius 500m"
4. [ ] **Verifikasi**: TIDAK ada record di Firestore `attendance`
5. [ ] **Verifikasi**: TIDAK ada record di `pending_sync`
6. [ ] Joko pergi ke kantor (atau set mock lokasi dalam radius)
7. [ ] Tap "Check In" lagi
8. [ ] **Verifikasi**: Geofence pass → camera open → berhasil check-in

**Status**: ⬜ Pass / ⬜ Fail di step ___

**Edge case bonus**:
- [ ] Tepat di garis radius 500m → behavior konsisten (allow atau block, harus jelas)
- [ ] Akurasi GPS rendah (indoor) → user dikasih warning

---

## 🎬 SKENARIO D: SOS Emergency Drill

**Goal**: Sinyal darurat sampai ke admin dalam < 5 detik.

**Persona**: Rina, supir, motor mogok di jalan sepi.

### Steps

1. [ ] **Karyawan (Rina)** buka app dari lokasi acak (di luar kantor)
2. [ ] Tap tombol "SOS" (prominent di home/menu)
3. [ ] **Verifikasi**: Konfirmasi dialog muncul (cegah accidental tap)
4. [ ] Tap "Kirim SOS"
5. [ ] **Verifikasi**: Loading indicator
6. [ ] **Verifikasi**: Toast "SOS Terkirim" muncul dalam < 3 detik
7. [ ] **Verifikasi**: Doc baru di `sos_alerts` status `active`
8. [ ] **Verifikasi**: Doc di `adminNotifications` parallel write
9. [ ] **Admin** Dashboard → ActiveAlerts component pop-up real-time
10. [ ] **Verifikasi**: Sound/vibrasi notif (kalau diimplement)
11. [ ] Admin click alert → tampil lokasi Rina di map
12. [ ] **Verifikasi**: Koordinat akurat (cek pakai Google Maps URL)
13. [ ] Admin hubungi Rina via chat / WA
14. [ ] Admin klik "Resolve" → status `resolved`
15. [ ] **Verifikasi**: History SOS tetap tersimpan untuk audit

**Latency total**: __________ (target: < 5 detik dari tap SOS ke admin tampil)

**Status**: ⬜ Pass / ⬜ Fail di step ___

---

## 🎬 SKENARIO E: Offline Check-out

**Goal**: Karyawan tetap bisa check-out tanpa internet, sync saat online.

**Persona**: Karyawan pulang kerja, sinyal di area parkir lemah.

### Steps

1. [ ] **Karyawan** check-in pagi normal (online)
2. [ ] Sore: matikan WiFi dan mobile data
3. [ ] **Verifikasi**: App tampil banner "OFFLINE MODE • DATA WILL SYNC LATER"
4. [ ] Tap "Check Out"
5. [ ] **Verifikasi**: Geofence pass (cache lokasi) ATAU graceful kalau perlu GPS
6. [ ] Capture wajah → face score (cache threshold dari settings)
7. [ ] Submit
8. [ ] **Verifikasi**: Toast "Data akan disinkronisasi nanti"
9. [ ] **Verifikasi**: Data tersimpan di SQLite local
10. [ ] **Verifikasi**: Doc di `pending_sync` Firestore (jika ada koneksi terputus-putus)
11. [ ] Nyalakan WiFi
12. [ ] **Verifikasi**: ConnectivityService detect online
13. [ ] **Verifikasi**: `syncPendingRecords()` jalan otomatis
14. [ ] **Verifikasi**: Record push ke `attendance` (atau update existing doc dengan checkOut)
15. [ ] **Verifikasi**: `pending_sync` doc deleted atau `synced=true`
16. [ ] **Verifikasi**: Foto upload ke Storage berhasil
17. [ ] **Verifikasi**: Admin lihat record lengkap di dashboard
18. [ ] **Verifikasi**: `totalWorkMinutes` calculated benar

**Status**: ⬜ Pass / ⬜ Fail di step ___

---

## 🎬 SKENARIO F: Multi-Device Login

**Goal**: User pakai 2 device, push notif sampai ke keduanya.

**Persona**: Karyawan punya HP utama & HP cadangan.

### Steps

1. [ ] **Karyawan** login di HP A
2. [ ] **Verifikasi**: FCM token A saved di `fcm_tokens` dengan userId karyawan
3. [ ] Login di HP B (tanpa logout HP A)
4. [ ] **Verifikasi**: FCM token B saved (2 token untuk userId yang sama)
5. [ ] **Admin** kirim pesan chat ke karyawan
6. [ ] **Verifikasi**: HP A dapat push notif
7. [ ] **Verifikasi**: HP B dapat push notif
8. [ ] Karyawan buka HP A → chat update jadi `read`
9. [ ] **Verifikasi**: Status `read` sync ke HP B juga (real-time listener)
10. [ ] **Admin** approve cuti karyawan
11. [ ] **Verifikasi**: Kedua HP dapat notif "Cuti Approved"
12. [ ] Logout HP A
13. [ ] **Verifikasi**: HP B tetap login, masih bisa pakai
14. [ ] **Verifikasi**: Push masih sampai ke HP B
15. [ ] Login lagi di HP A
16. [ ] **Verifikasi**: Token baru saved (atau lama re-validated)

**Status**: ⬜ Pass / ⬜ Fail di step ___

---

## 🎬 SKENARIO G: Bulk Karyawan & Reporting

**Goal**: System handle banyak karyawan + export laporan.

### Steps

1. [ ] **Admin** jalankan `node admin/scripts/seed_employees.mjs` untuk seed 50 karyawan dummy
2. [ ] **Verifikasi**: 50 user terbuat di `users` collection
3. [ ] **Verifikasi**: 50 Auth account terbuat
4. [ ] **Verifikasi**: 50 email onboarding terkirim (atau di-skip kalau dev mode)
5. [ ] **Verifikasi**: Dashboard tetap responsif (load < 3 detik)
6. [ ] Buka /employees → list 50 karyawan tampil
7. [ ] **Verifikasi**: Pagination berfungsi (20 per page atau scroll)
8. [ ] Search by name "Test" → hasil filter benar
9. [ ] Filter departemen → tampil sesuai
10. [ ] Jalankan `seed_history.mjs` untuk seed 30 hari attendance
11. [ ] **Verifikasi**: ~1500 attendance docs terbuat (50 × 30)
12. [ ] Buka /reports
13. [ ] Pilih periode 1 bulan
14. [ ] Klik "Export PDF"
15. [ ] **Verifikasi**: File ter-download dalam < 30 detik
16. [ ] **Verifikasi**: PDF rapi, semua 50 karyawan ada
17. [ ] Klik "Export Excel"
18. [ ] **Verifikasi**: File Excel valid, data lengkap
19. [ ] **Verifikasi**: Summary stats akurat (total hadir, terlambat, dll)

**Status**: ⬜ Pass / ⬜ Fail di step ___

---

## 🎬 SKENARIO H: Year-End Boundary

**Goal**: Pastikan tanggal & timezone benar di transisi tahun.

### Steps (simulasi pakai device dengan time manipulation)

1. [ ] Set device date ke `31 Desember 2026 23:00 WIB`
2. [ ] **Karyawan** check-in (anggap shift malam)
3. [ ] **Verifikasi**: Attendance doc `date = '2026-12-31'`
4. [ ] **Verifikasi**: `checkIn.time` Timestamp benar (server time)
5. [ ] Set device date ke `1 Januari 2027 00:30 WIB`
6. [ ] Karyawan check-out
7. [ ] **Verifikasi**: `checkOut.time` Timestamp benar
8. [ ] **Verifikasi**: `totalWorkMinutes` = ~1.5 jam (1h 30m)
9. [ ] **Verifikasi**: Attendance doc tidak duplicate ke tahun baru
10. [ ] **Verifikasi**: Riwayat bulan Desember tampil
11. [ ] Buka history Januari → kalau ada record day 1, tampil
12. [ ] **Verifikasi**: Stats bulanan tidak campur tahun

**Status**: ⬜ Pass / ⬜ Fail di step ___

**Bonus edge case**:
- [ ] Tahun kabisat: 29 Februari (test kalau ada tahun kabisat di range testing)
- [ ] Format tanggal display konsisten

---

## 📊 Hasil Smoke Test

| Skenario | Status | Time | Notes |
|----------|--------|------|-------|
| A. Onboarding | ⬜ | __ | |
| B. Cuti Sakit | ⬜ | __ | |
| C. Outside Geofence | ⬜ | __ | |
| D. SOS Emergency | ⬜ | __ | |
| E. Offline Sync | ⬜ | __ | |
| F. Multi-Device | ⬜ | __ | |
| G. Bulk + Report | ⬜ | __ | |
| H. Year Boundary | ⬜ | __ | |

**Total Pass**: ___ / 8

---

## ✅ Decision

- ⬜ Semua 8 skenario PASS → app **READY for release**
- ⬜ 1-2 skenario fail (non-critical) → patch dulu, release setelah fix
- ⬜ > 3 skenario fail → **BLOCKED**, comprehensive fix sprint

---

**Tester**: ____________________________
**Tanggal**: ____________________
**Catatan**: ____________________
