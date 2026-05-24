# 3. QA MOBILE APP — FUNCTIONAL

> **Tujuan**: Verifikasi semua fitur mobile app berfungsi sesuai spec.
> **Estimasi waktu**: 1 hari kerja
> **Prasyarat**: [01_pre_test_setup.md](01_pre_test_setup.md) selesai + APK release ter-install
> **Tester**: Mobile QA Tester
> **Device**: Android (minimal 2 device, 1 lama + 1 baru)

---

## 3.1 Authentication

- [ ] Splash screen tampil 2-3 detik
- [ ] Onboarding screen muncul saat first install
- [ ] Login dengan email valid → masuk home
- [ ] Login dengan password salah → error
- [ ] **First login** dengan default password `JNE123!` → wajib ganti password screen
- [ ] Validasi password baru: min 8 karakter, ada angka
- [ ] Ganti password berhasil → `firstLogin=false` di Firestore
- [ ] Lapor masalah login (anonymous):
  - [ ] Form muncul di login screen
  - [ ] Field validation (name min 1, desc min 10)
  - [ ] Submit → tersimpan di `login_issues`
  - [ ] Admin lihat di dashboard
- [ ] Logout → kembali ke login, session cleared
- [ ] Re-login → state restored
- [ ] Login dengan email invalid format → error

## 3.2 Permission Flow

- [ ] First launch minta permission:
  - [ ] Camera
  - [ ] Location (foreground + background opsional)
  - [ ] Notification (Android 13+)
  - [ ] Storage (untuk foto)
- [ ] Permission denied → tampil halaman penjelasan + tombol Settings
- [ ] Permission granted → lanjut ke home
- [ ] Permission revoked tengah pakai → graceful handling

## 3.3 Face Enrollment

- [ ] Buka camera → preview tampil
- [ ] Face detection box muncul saat ada wajah
- [ ] Foto capture → preview hasil
- [ ] Upload → progress indicator
- [ ] Success → kembali ke home, `faceRegistered=true`
- [ ] **Cloud Function `onFaceEnrolled`** trigger → admin dapat notif
- [ ] Wajah multi-orang dalam frame → tolak atau warning
- [ ] No face detected → tombol upload disabled
- [ ] Retake foto berfungsi
- [ ] Kamera depan/belakang switch (jika ada)

## 3.4 Check-in Absensi

- [ ] Klik "Check In" di home
- [ ] **Geofence check**: kalau di luar radius → tolak + tampil jarak ke kantor
- [ ] Di dalam radius → buka camera
- [ ] Face detection → tampil score
- [ ] Score < threshold → tolak + retry
- [ ] Score OK → upload foto + write Firestore
- [ ] Status determined: present / late (jika > checkInTime + tolerance)
- [ ] Success screen → "Berhasil Check In"
- [ ] Home page update: tombol check-in disabled, muncul tombol check-out
- [ ] Foto check-in tampil di history

## 3.5 Check-out Absensi

- [ ] Klik "Check Out"
- [ ] Geofence + face check sama
- [ ] Upload foto check-out + write Firestore
- [ ] `totalWorkMinutes` ter-calculate (checkOut.time - checkIn.time)
- [ ] Jika > shift duration: `overtimeMinutes` > 0
- [ ] Success screen
- [ ] Home page update: status hari ini selesai
- [ ] Tidak bisa check-out tanpa check-in dulu

## 3.6 Riwayat Absensi

- [ ] List bulan ini default
- [ ] Filter bulan/tahun → data sesuai
- [ ] Click record → detail (foto, lokasi, jam)
- [ ] Stats card: hadir, terlambat, absen, lembur
- [ ] Empty state untuk bulan tanpa data
- [ ] Pull to refresh

## 3.7 Pengajuan Cuti

- [ ] Buka form cuti
- [ ] Pilih type (sick/annual/personal/emergency/other)
- [ ] Pilih startDate & endDate → totalDays auto-calculate
- [ ] Upload dokumen (opsional untuk sakit) → preview
- [ ] Submit → toast success, status pending
- [ ] Cuti terlihat di list "Cuti Saya"
- [ ] Cancel cuti pending → terhapus
- [ ] Cancel cuti approved → ditolak (validasi backend)
- [ ] Approved cuti → dapat push notif
- [ ] Rejected cuti → dapat push notif + alasan
- [ ] Validasi startDate tidak boleh < today
- [ ] Validasi endDate >= startDate

## 3.8 Pengajuan Lembur

- [ ] Form overtime tampil
- [ ] Submit → tersimpan, status pending
- [ ] Approval/rejection alur sama dengan cuti
- [ ] Validasi durationHours > 0

## 3.9 Statistik Personal

- [ ] Grafik kehadiran bulanan
- [ ] Persentase hadir/terlambat
- [ ] Total jam kerja
- [ ] Comparison antar bulan
- [ ] Smooth scroll, tidak lag

## 3.10 Kalender Event

- [ ] Event dari admin muncul di kalender
- [ ] Click event → detail (lokasi, waktu, organizer)
- [ ] Reminder lokal muncul H-1 dan 30 menit sebelum
- [ ] Navigasi bulan prev/next
- [ ] Multi-day event render benar

## 3.11 Chat dengan Admin

- [ ] Klik chat → list konversasi (biasanya 1: dengan admin)
- [ ] Tap admin → buka chat
- [ ] Kirim pesan → tampil real-time
- [ ] Status: sent → delivered → read
- [ ] Admin balas → notif muncul saat app background
- [ ] App foreground → pesan langsung muncul
- [ ] Typing indicator tampil saat admin mengetik
- [ ] Scroll history smooth
- [ ] Pesan panjang wrap dengan benar

## 3.12 SOS Emergency

- [ ] Tombol SOS prominent di home/menu
- [ ] Tap SOS → konfirmasi (cegah accidental)
- [ ] Konfirmasi → kirim lokasi + tampil "SOS Terkirim"
- [ ] Admin dapat alert real-time di dashboard
- [ ] Lokasi akurat (cek di Maps)
- [ ] Tidak butuh internet stabil → tetap kirim kalau ada koneksi

## 3.13 Dispute (Komplain)

- [ ] Submit dispute baru
- [ ] Admin balas → real-time muncul di mobile
- [ ] Thread chat berfungsi
- [ ] Admin tandai resolved → mobile tampil tombol "Konfirmasi"
- [ ] Konfirmasi + kasih rating → tersimpan
- [ ] FAQ tampil setelah konfirmasi

## 3.14 Notifikasi (Mobile)

- [ ] FCM token saved ke `fcm_tokens` saat login
- [ ] Push notif diterima saat app background
- [ ] Tap notif → buka screen relevan
- [ ] In-app notification list tampil semua
- [ ] Mark as read berfungsi
- [ ] Broadcast dari admin muncul
- [ ] Badge count akurat
- [ ] Mark all read berfungsi

## 3.15 Profil & Pengaturan

- [ ] Profil tampil data lengkap (name, dept, position, foto)
- [ ] Edit profil terbatas (no role/email/employeeId change)
- [ ] Settings:
  - [ ] Dark/Light mode toggle
  - [ ] Notification enable/disable
  - [ ] Reminder enable/disable
  - [ ] Language
  - [ ] About / version info

## 3.16 Help & FAQ

- [ ] FAQ list tampil
- [ ] Contact admin link / WA
- [ ] Versi app & contact info

---

## Bug Yang Ditemukan

| ID | Severity | Modul | Device | Deskripsi | Status |
|----|----------|-------|--------|-----------|--------|
|    |          |       |        |           |        |

(Pakai template di [15_bug_report_template.md](15_bug_report_template.md))

---

**Tester**: ____________________________
**Device 1**: __________________________
**Device 2**: __________________________
**Tanggal selesai**: ____________________
**Total item**: ___ / ___ pass
**Status**: ⬜ All pass / ⬜ Pass with bugs / ⬜ Blocked
