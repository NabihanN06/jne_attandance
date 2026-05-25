# 🧪 QUALITY ASSURANCE CHECKLIST
## JNE Martapura Attendance System — Pre-Release QA Plan

> Format: checklist actionable. Tandai ✅ / ❌ / ⏭️ (skipped) per item saat testing.
> Versi target: Admin Panel + Mobile APK Release pertama
> Last update: 2026-05-23

---

## 📋 DAFTAR ISI

1. [Pre-Test Setup](#1-pre-test-setup)
2. [QA Admin Panel — Functional](#2-qa-admin-panel--functional)
3. [QA Mobile App — Functional](#3-qa-mobile-app--functional)
4. [QA Integration Cross-System](#4-qa-integration-cross-system)
5. [QA Security & Permission](#5-qa-security--permission)
6. [QA Performance & Stability](#6-qa-performance--stability)
7. [QA Offline & Edge Cases](#7-qa-offline--edge-cases)
8. [QA UI/UX & Accessibility](#8-qa-uiux--accessibility)
9. [QA Data Validation](#9-qa-data-validation)
10. [QA Cloud Functions](#10-qa-cloud-functions)
11. [QA Notification (FCM)](#11-qa-notification-fcm)
12. [Cross-Device & Compatibility](#12-cross-device--compatibility)
13. [Pre-Deployment Final Check](#13-pre-deployment-final-check)
14. [Post-Deployment Monitoring](#14-post-deployment-monitoring)
15. [Bug Report Template](#15-bug-report-template)
16. [Test Data Skenario](#16-test-data-skenario)

---

## 1. PRE-TEST SETUP

### 1.1 Lingkungan Test

- [ ] Buat **2 akun admin** test (admin1@jne.mtp.com, admin2@jne.mtp.com)
- [ ] Buat **5 akun karyawan** test dengan berbagai departemen
- [ ] Siapkan **2 device Android fisik** (minimal API 21 dan Android 14)
- [ ] Siapkan **iOS device** (kalau target iOS aktif)
- [ ] Browser admin: Chrome, Edge, Firefox versi terbaru
- [ ] **Jangan pakai production data** untuk QA — siapkan environment staging atau pakai data dummy
- [ ] Backup database sebelum test besar-besaran

### 1.2 Tools

- [ ] Firebase Console (cek Firestore, Auth, Storage, Functions logs)
- [ ] Android Studio / `adb logcat` untuk inspect mobile logs
- [ ] Chrome DevTools untuk inspect admin panel
- [ ] Postman / curl untuk test API routes
- [ ] Stopwatch (untuk ukur load time)
- [ ] Aplikasi mock GPS (cek geofence cheating defense)

### 1.3 Konfigurasi

- [ ] Firestore Security Rules deployed ke staging
- [ ] Cloud Functions deployed ke staging
- [ ] Office lat/lng di `settings/system` valid
- [ ] Office radiusMeters realistis (500m default)
- [ ] Face similarity threshold sesuai (default 70-80)
- [ ] Minimal 1 jam kerja default sudah dibuat
- [ ] Minimal 3 departemen sudah dibuat

---

## 2. QA ADMIN PANEL — FUNCTIONAL

### 2.1 Authentication

- [ ] Login dengan email & password valid → masuk dashboard
- [ ] Login dengan password salah → error message jelas
- [ ] Login dengan email tidak terdaftar → error message
- [ ] Login dengan akun karyawan (role: employee) → ditolak (admin-only)
- [ ] Forgot password → email reset terkirim
- [ ] Click reset link → reset password berhasil
- [ ] Logout → kembali ke login page, session cleared
- [ ] Session expired → auto-redirect ke login
- [ ] Akses URL admin tanpa login → redirect login

### 2.2 Dashboard

- [ ] Stats card (Hadir/Terlambat/Absen hari ini) tampil angka benar
- [ ] Chart mingguan render benar
- [ ] Active Alerts (face_failed) tampil real-time
- [ ] Quick action buttons berfungsi (link ke modul terkait)
- [ ] Real-time update saat ada absensi baru tanpa refresh manual
- [ ] Empty state saat tidak ada data hari ini

### 2.3 Manajemen Karyawan (/employees)

- [ ] List karyawan tampil semua + pagination
- [ ] Search by name → filter tepat
- [ ] Filter departemen → filter tepat
- [ ] Klik **Tambah Karyawan** → modal terbuka
- [ ] Form validation:
  - [ ] Name kosong → error
  - [ ] Email format salah → error
  - [ ] Email sudah dipakai → error
  - [ ] EmployeeId duplikat → auto-generate atau error
  - [ ] Phone format SALAH → error
- [ ] Submit valid → karyawan terbuat, modal close, toast success
- [ ] **Cloud Function `onEmployeeCreated`** trigger → Firebase Auth account terbuat
- [ ] **Cloud Function `sendOnboardingEmail`** trigger → email terkirim ke `personalEmail`
- [ ] Custom jam kerja saat tambah karyawan → tersimpan
- [ ] Edit karyawan → field bisa diubah (kecuali email/role) → tersimpan
- [ ] Delete karyawan → konfirmasi → terhapus dari list
- [ ] Detail karyawan → semua info tampil benar
- [ ] **Avatar/photoUrl** tampil (placeholder kalau tidak ada)

### 2.4 Monitoring Absensi (/attendance)

- [ ] List absensi hari ini → semua karyawan + status
- [ ] Filter tanggal → data sesuai
- [ ] Filter status (present/late/absent/leave) → filter benar
- [ ] Klik baris absensi → detail (foto, lokasi, waktu, faceScore)
- [ ] Foto check-in dan check-out tampil
- [ ] Map preview lokasi check-in akurat
- [ ] Real-time: karyawan check-in di mobile → muncul di admin tanpa refresh

### 2.5 Persetujuan Cuti (/leaves)

- [ ] List leaves dengan filter status (pending/approved/rejected)
- [ ] Lihat detail cuti + dokumen pendukung (kalau ada)
- [ ] Approve cuti → status berubah → push notif terkirim ke karyawan
- [ ] Reject cuti dengan alasan → status berubah → karyawan dapat notif + alasan
- [ ] **Cloud Function `onLeaveStatusUpdate`** trigger
- [ ] Cuti kemarin tidak bisa di-cancel oleh karyawan (validasi backend)

### 2.6 Jam Kerja & Shift (/jam-kerja, /shifts)

- [ ] CRUD jam kerja:
  - [ ] Tambah dengan checkInTime, checkOutTime, toleranceMinutes
  - [ ] Edit jam kerja existing
  - [ ] Delete (validasi: tidak boleh delete kalau ada karyawan pakai)
- [ ] Set working days (Senin-Minggu) berfungsi
- [ ] Color picker berfungsi (untuk identifikasi di UI)
- [ ] isActive toggle berfungsi

### 2.7 Departemen (/departments)

- [ ] CRUD departemen
- [ ] Color picker
- [ ] Delete validasi: tidak boleh kalau ada karyawan
- [ ] Department rules sinkron dengan `departmentRules.ts`

### 2.8 Kalender (/calendar)

- [ ] Tambah event dengan startDate, endDate, attendees
- [ ] Multi-day event tampil benar di grid
- [ ] Filter category (meeting/training/social/deadline)
- [ ] Edit event → tersimpan
- [ ] Delete event
- [ ] **Auto reminder** terkirim H-1 dan 30 menit sebelum
- [ ] `notificationSentDayBefore`/`notificationSent30Min` flag set true setelah kirim
- [ ] Target departments → semua karyawan dept itu dapat notif

### 2.9 Chat (/chat)

- [ ] List konversasi dengan karyawan
- [ ] Buka chat → load history pesan
- [ ] Kirim pesan → muncul di mobile karyawan real-time
- [ ] Status `delivered` muncul saat mobile receive
- [ ] Status `read` muncul saat karyawan buka chat
- [ ] Typing indicator real-time
- [ ] Unread badge count akurat
- [ ] Scroll ke pesan lama tidak lag

### 2.10 Broadcast (/broadcast)

- [ ] Tulis broadcast → kirim ke semua karyawan / grup tertentu
- [ ] Karyawan dapat push notif
- [ ] Broadcast muncul di mobile notifikasi
- [ ] History broadcast tersimpan

### 2.11 Approve Request (/requests, /edit-requests)

- [ ] List overtime request → approve/reject
- [ ] List edit request absensi → review changes → approve
- [ ] Approve edit → attendance doc ter-update sesuai requestedChanges
- [ ] Audit log tercatat saat approve

### 2.12 Laporan (/reports)

- [ ] Pilih periode (date range) → data ter-filter benar
- [ ] Filter departemen → data benar
- [ ] Export PDF → file ter-download, format rapi
- [ ] Export Excel → file ter-download, header & data benar
- [ ] Summary stats akurat (total kerja, total terlambat, dll)
- [ ] Empty state kalau periode tanpa data

### 2.13 Pengaturan (/settings)

- [ ] **Office**: ubah lat/lng/radius → tersimpan → mobile pakai data baru
- [ ] **Attendance**: ubah faceSimilarityThreshold → mobile pakai
- [ ] **Company**: ubah info → muncul di mobile profile
- [ ] **Notifications**: toggle on/off → tersimpan
- [ ] **Maintenance**: mode maintenance → mobile tampil banner

### 2.14 Login Issues (/login-issues)

- [ ] List laporan masalah login dari user
- [ ] Tandai resolved
- [ ] Hubungi user via WA/email berdasar data laporan
- [ ] Validasi data laporan (size limit name/email/desc)

### 2.15 Face Enrollment Monitor

- [ ] List karyawan dengan status face enrollment
- [ ] Klik karyawan → foto wajah tampil
- [ ] Karyawan baru enrol → muncul real-time

### 2.16 Notifikasi Panel (Header)

- [ ] Badge unread count akurat
- [ ] Click notifikasi → mark as read
- [ ] Notifikasi berurutan dari terbaru
- [ ] Mark all as read berfungsi
- [ ] Delete notifikasi berfungsi
- [ ] Tipe notif berbeda: leave_request, face_enrolled, new_employee

---

## 3. QA MOBILE APP — FUNCTIONAL

### 3.1 Authentication

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

### 3.2 Permission Flow

- [ ] First launch minta permission:
  - [ ] Camera
  - [ ] Location (foreground + background opsional)
  - [ ] Notification (Android 13+)
  - [ ] Storage (untuk foto)
- [ ] Permission denied → tampil halaman penjelasan + tombol Settings
- [ ] Permission granted → lanjut ke home

### 3.3 Face Enrollment

- [ ] Buka camera → preview tampil
- [ ] Face detection box muncul saat ada wajah
- [ ] Foto capture → preview hasil
- [ ] Upload → progress indicator
- [ ] Success → kembali ke home, `faceRegistered=true`
- [ ] **Cloud Function `onFaceEnrolled`** trigger → admin dapat notif
- [ ] Wajah multi-orang dalam frame → tolak atau warning
- [ ] No face detected → tombol upload disabled

### 3.4 Check-in Absensi

- [ ] Klik "Check In" di home
- [ ] **Geofence check**: kalau di luar radius → tolak + tampil jarak ke kantor
- [ ] Di dalam radius → buka camera
- [ ] Face detection → tampil score
- [ ] Score < threshold → tolak + retry
- [ ] Score OK → upload foto + write Firestore
- [ ] Status determined: present / late (jika > checkInTime + tolerance)
- [ ] Success screen → "Berhasil Check In"
- [ ] Home page update: tombol check-in disabled, muncul tombol check-out

### 3.5 Check-out Absensi

- [ ] Klik "Check Out"
- [ ] Geofence + face check sama
- [ ] Upload foto check-out + write Firestore
- [ ] `totalWorkMinutes` ter-calculate (checkOut.time - checkIn.time)
- [ ] Jika > shift duration: `overtimeMinutes` > 0
- [ ] Success screen
- [ ] Home page update: status hari ini selesai

### 3.6 Riwayat Absensi

- [ ] List bulan ini default
- [ ] Filter bulan/tahun → data sesuai
- [ ] Click record → detail (foto, lokasi, jam)
- [ ] Stats card: hadir, terlambat, absen, lembur
- [ ] Empty state untuk bulan tanpa data

### 3.7 Pengajuan Cuti

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

### 3.8 Pengajuan Lembur

- [ ] Form overtime tampil
- [ ] Submit → tersimpan, status pending
- [ ] Approval/rejection alur sama dengan cuti

### 3.9 Statistik Personal

- [ ] Grafik kehadiran bulanan
- [ ] Persentase hadir/terlambat
- [ ] Total jam kerja
- [ ] Comparison antar bulan

### 3.10 Kalender Event

- [ ] Event dari admin muncul di kalender
- [ ] Click event → detail (lokasi, waktu, organizer)
- [ ] Reminder lokal muncul H-1 dan 30 menit sebelum

### 3.11 Chat dengan Admin

- [ ] Klik chat → list konversasi (biasanya 1: dengan admin)
- [ ] Tap admin → buka chat
- [ ] Kirim pesan → tampil real-time
- [ ] Status: sent → delivered → read
- [ ] Admin balas → notif muncul saat app background
- [ ] App foreground → pesan langsung muncul
- [ ] Typing indicator tampil saat admin mengetik

### 3.13 Dispute (Komplain)

- [ ] Submit dispute baru
- [ ] Admin balas → real-time muncul di mobile
- [ ] Thread chat berfungsi
- [ ] Admin tandai resolved → mobile tampil tombol "Konfirmasi"
- [ ] Konfirmasi + kasih rating → tersimpan
- [ ] FAQ tampil setelah konfirmasi

### 3.14 Notifikasi (Mobile)

- [ ] FCM token saved ke `fcm_tokens` saat login
- [ ] Push notif diterima saat app background
- [ ] Tap notif → buka screen relevan
- [ ] In-app notification list tampil semua
- [ ] Mark as read berfungsi
- [ ] Broadcast dari admin muncul

### 3.15 Profil & Pengaturan

- [ ] Profil tampil data lengkap (name, dept, position, foto)
- [ ] Edit profil terbatas (no role/email/employeeId change)
- [ ] Settings:
  - [ ] Dark/Light mode toggle
  - [ ] Notification enable/disable
  - [ ] Reminder enable/disable
  - [ ] Language
  - [ ] About / version info

### 3.16 Help & FAQ

- [ ] FAQ list tampil
- [ ] Contact admin link / WA
- [ ] Versi app & contact info

---

## 4. QA INTEGRATION CROSS-SYSTEM

### 4.1 Onboarding End-to-End

- [ ] Admin tambah karyawan baru
- [ ] Karyawan dapat email otomatis (cek inbox)
- [ ] Email berisi kredensial + link APK
- [ ] Karyawan install APK
- [ ] Login pertama dengan password default
- [ ] Force change password screen muncul
- [ ] Ganti password → masuk home
- [ ] Lakukan face enrollment
- [ ] Admin dapat notif "X selesai enrollment"

### 4.2 Absensi End-to-End

- [ ] Karyawan check-in di mobile
- [ ] Admin lihat di dashboard real-time
- [ ] Foto tersimpan di Storage
- [ ] Link foto valid di Firestore
- [ ] Status `present`/`late` benar
- [ ] Check-out → totalWorkMinutes calculated
- [ ] Cloud Function `scheduledOvertimeCalc` jalan 23:00 → overtime updated

### 4.3 Cuti End-to-End

- [ ] Karyawan submit cuti
- [ ] Admin dapat notif "ada cuti baru"
- [ ] Admin approve
- [ ] Karyawan dapat push notif
- [ ] Status cuti update di mobile real-time
- [ ] Saat tanggal cuti → attendance status auto-jadi `leave`

### 4.4 Chat End-to-End

- [ ] Admin kirim pesan ke karyawan
- [ ] Karyawan dapat push notif (kalau app background)
- [ ] Karyawan buka app → pesan muncul
- [ ] Status delivered + read sinkron 2 arah

### 4.6 Presence/Online End-to-End

- [ ] Karyawan buka app → indicator hijau di admin
- [ ] Karyawan tutup app → indicator abu setelah 40 detik
- [ ] Multiple devices login → semua tracked

---

## 5. QA SECURITY & PERMISSION

### 5.1 Firestore Rules Enforcement

- [ ] Karyawan TIDAK bisa baca `users` karyawan lain (test via console)
- [ ] Karyawan TIDAK bisa update `role` sendiri
- [ ] Karyawan TIDAK bisa create attendance milik user lain
- [ ] Karyawan TIDAK bisa update leaves yang sudah approved
- [ ] Karyawan TIDAK bisa baca chat antar orang lain
- [ ] Admin BISA semua operasi
- [ ] Unauthenticated TIDAK bisa apa-apa kecuali create `login_issues`

### 5.2 Login Security

- [ ] Brute force: 5x login salah → rate limited (Firebase Auth default)
- [ ] Password tidak pernah tampil plain di UI
- [ ] Session cookie HttpOnly, Secure, SameSite (cek devtools)
- [ ] CSRF protection untuk POST endpoints

### 5.3 API Routes Authorization

- [ ] `/api/notify-user` tanpa session → 401
- [ ] `/api/notify-user` dengan session karyawan → 403
- [ ] `/api/audit-log` access control
- [ ] Tidak ada API leak data sensitive

### 5.4 Storage Security

- [ ] User TIDAK bisa download foto user lain
- [ ] Admin BISA download semua foto
- [ ] File size limit (e.g., max 5MB) → tolak file besar
- [ ] File type validation (only image/jpeg, image/png)

### 5.5 Input Sanitization

- [ ] SQL injection: tidak applicable (NoSQL)
- [ ] NoSQL injection: test malicious queries
- [ ] XSS: input HTML/script di name, reason, dll → escaped saat render
- [ ] Field size limit di rules `login_issues` enforced

### 5.6 Device Binding (Opsional)

- [ ] User login di device A → registeredDeviceId tersimpan
- [ ] Login di device B → tolak / warning
- [ ] Admin bisa reset registeredDeviceId

### 5.7 Mock GPS Detection

- [ ] Test pakai aplikasi Fake GPS
- [ ] Geolocator harusnya detect `isMocked: true`
- [ ] Tolak absensi atau flag suspicious

### 5.8 Sensitive Data

- [ ] Token FCM tidak ke-log di console
- [ ] Password tidak masuk ke audit log
- [ ] Firebase API key bukan untuk admin SDK (yang public OK)
- [ ] `firebase-credentials-dev.json` tidak di-commit (sudah verified)

---

## 6. QA PERFORMANCE & STABILITY

### 6.1 Admin Panel Performance

- [ ] First load < 3 detik (3G connection)
- [ ] Dashboard interactive < 1.5 detik
- [ ] List dengan 100+ karyawan → smooth scroll
- [ ] List dengan 1000+ attendance → pagination/virtualization
- [ ] Real-time listener tidak bocor memory (test 1 jam idle)
- [ ] Multiple tabs admin → tidak crash
- [ ] Chart rendering < 500ms

### 6.2 Mobile Performance

- [ ] App cold start < 3 detik
- [ ] Camera open < 2 detik
- [ ] Face detection latency < 500ms
- [ ] Upload foto 2MB → < 10 detik di 4G
- [ ] No memory leak (Profile Tool 30 menit usage)
- [ ] Battery drain reasonable (heartbeat tiap 30s tidak boros)
- [ ] Tidak ada ANR (App Not Responding)

### 6.3 Database Query Performance

- [ ] Dashboard stats query < 1 detik
- [ ] List karyawan dengan 100+ data < 2 detik
- [ ] Composite indexes effective (cek di Firebase Console)
- [ ] Tidak ada N+1 query pattern

### 6.4 Cloud Functions Cold Start

- [ ] First invoke < 5 detik
- [ ] Subsequent invokes < 1 detik
- [ ] Region asia-southeast2 (Jakarta) → latency rendah
- [ ] Memory allocation cukup (256MB / 512MB)

---

## 7. QA OFFLINE & EDGE CASES

### 7.1 Mobile Offline Mode

- [ ] Matikan WiFi/data → app tampil banner "OFFLINE MODE"
- [ ] Check-in offline → tersimpan ke SQLite + `pending_sync`
- [ ] Hidupkan internet → auto sync ke `attendance`
- [ ] `synced=true` setelah sync sukses
- [ ] Multiple offline records → sync semua
- [ ] `syncAttempts` increment kalau retry
- [ ] Sync gagal terus → tampil notif "Sync error"

### 7.2 Network Edge Cases

- [ ] WiFi → Mobile data switch → tetap connected
- [ ] Slow 2G → upload foto → progress indicator + tidak crash
- [ ] Timeout handling: kalau request > 30s → tampil error
- [ ] Retry mechanism untuk upload foto

### 7.3 Edge Case Data

- [ ] User check-in 2x dalam 1 hari → tolak (idempotent)
- [ ] User check-out tanpa check-in → tolak
- [ ] Cuti backdate (start < today) → tolak validasi
- [ ] Cuti overlap dengan cuti existing → tolak / warning
- [ ] Karyawan delete → attendance history milik dia tetap ada (soft delete?)
- [ ] Department delete → karyawan dengan dept tsb → tolak / reassign

### 7.4 Time Zone Edge Cases

- [ ] Server timezone (Firestore Timestamp) vs lokal WIB
- [ ] Karyawan di zona waktu beda → tetap pakai WIB office
- [ ] Tengah malam check-in → tanggal benar (sebelum atau sesudah midnight)
- [ ] DST: tidak ada di Indonesia, skip

### 7.5 Date Edge Cases

- [ ] 29 Feb tahun kabisat → handled
- [ ] Akhir bulan → next month rollover OK
- [ ] Akhir tahun (31 Des) → year increment OK

### 7.6 Camera Edge Cases

- [ ] Camera permission revoked tengah pakai → graceful
- [ ] Low light → face detection robust
- [ ] Kamera depan vs belakang → switch berfungsi
- [ ] Foto rotated landscape/portrait → orientation correct
- [ ] Camera busy (app lain pakai) → error message jelas

### 7.7 Geolocation Edge Cases

- [ ] GPS off → minta nyalain
- [ ] Indoor (signal lemah) → tampil "Mencari sinyal..."
- [ ] Lokasi akurasi rendah (>100m accuracy) → warning
- [ ] Berpindah dari outdoor ke indoor saat check-in → handle

---

## 8. QA UI/UX & ACCESSIBILITY

### 8.1 Visual Consistency

- [ ] Font konsisten (Plus Jakarta Sans admin, Outfit mobile)
- [ ] Spacing konsisten (padding 8/16/24/32)
- [ ] Warna sesuai Zen Premium palette
- [ ] Icon set konsisten (lucide-react admin, material/cupertino mobile)
- [ ] Border radius konsisten

### 8.2 Dark/Light Mode

- [ ] Toggle dark mode admin → semua page update
- [ ] Toggle dark mode mobile → semua screen update
- [ ] Tidak ada teks invisible (kontras buruk)
- [ ] Toast/modal pakai theme yang aktif
- [ ] Chart warna readable di kedua mode

### 8.3 Responsive Admin

- [ ] Desktop (1920x1080) → layout optimal
- [ ] Laptop (1366x768) → tidak ada scroll horizontal
- [ ] Tablet (768px) → sidebar collapsible
- [ ] Mobile browser → minimal functional (admin not primary target tapi)

### 8.4 Animations

- [ ] Page transitions smooth
- [ ] Modal open/close < 300ms
- [ ] Tidak ada animation jank
- [ ] Respect prefers-reduced-motion (kalau ada implementasi)

### 8.5 Loading States

- [ ] Skeleton loader untuk list
- [ ] Spinner untuk action button
- [ ] Toast feedback untuk semua action
- [ ] Empty states informatif

### 8.6 Error States

- [ ] Error message jelas (bukan "Error 500")
- [ ] Retry button untuk operasi gagal
- [ ] Validation error inline di form field
- [ ] 404 page custom untuk URL salah

### 8.7 Accessibility (a11y)

- [ ] Semua button ada `aria-label`
- [ ] Form input ada `<label>` terkait
- [ ] Heading hierarchy benar (h1 → h2 → h3)
- [ ] Keyboard navigation (Tab) berfungsi
- [ ] Focus indicator visible
- [ ] Color contrast WCAG AA minimal
- [ ] Screen reader test (NVDA/JAWS) — opsional advanced

---

## 9. QA DATA VALIDATION

### 9.1 Form Validation

- [ ] Required field kosong → error message tampil
- [ ] Field length validation enforce
- [ ] Email format: `name@domain.tld`
- [ ] Phone: digit only, length 10-13
- [ ] Date: tidak boleh masa depan untuk birthDate
- [ ] Number: numerik only, min/max enforced

### 9.2 Data Integrity

- [ ] Tidak ada `null` di field required di Firestore
- [ ] Timestamp benar-benar Timestamp type (bukan string)
- [ ] Foreign reference (jamKerjaId, departmentId) valid
- [ ] Status enum hanya nilai valid

### 9.3 Migration Backward Compat

- [ ] User lama dengan schema lama → tetap kebaca (graceful null handling)
- [ ] Field baru → default value reasonable

---

## 10. QA CLOUD FUNCTIONS

### 10.1 onEmployeeCreated

- [ ] Create user di Firestore → CF trigger
- [ ] Firebase Auth account terbuat (cek di Console)
- [ ] `adminNotifications` doc terbuat
- [ ] Idempotent: re-create → tidak duplicate

### 10.2 onLeaveStatusUpdate

- [ ] Update status leave → FCM push terkirim
- [ ] Token tidak valid → token deleted dari `fcm_tokens`
- [ ] Push payload include leave info

### 10.3 onFaceEnrolled

- [ ] Set `faceRegistered=true` → CF trigger
- [ ] Admin dapat notif

### 10.4 onAttendanceFailed (Callable)

- [ ] Mobile call function dengan userId → success
- [ ] Admin dapat notif "X gagal face 3x"

### 10.5 scheduledOvertimeCalc

- [ ] Cek log function pada 23:00 WIB
- [ ] Attendance hari ini → overtimeMinutes updated
- [ ] Tidak update attendance tanpa checkOut

### 10.6 sendOnboardingEmail

- [ ] Create user → email terkirim ke `personalEmail`
- [ ] Email berisi kredensial benar
- [ ] Email tidak ke spam folder

### 10.7 Function Logs

- [ ] Cek Firebase Console > Functions > Logs
- [ ] Tidak ada error spam
- [ ] Execution time < 5 detik per invoke

---

## 11. QA NOTIFICATION (FCM)

### 11.1 Token Management

- [ ] Login mobile → token saved ke `fcm_tokens/{token}`
- [ ] App reinstall → new token saved, old deleted (otomatis)
- [ ] Multi device → multiple tokens per user

### 11.2 Push Notification Delivery

- [ ] Kirim notif → tampil di notification bar mobile
- [ ] Sound default ATAU custom (sesuai settings.notificationsEnabled)
- [ ] Tap notif → buka screen relevan (deep link)
- [ ] App foreground → in-app toast atau silent
- [ ] App background → push notif standard
- [ ] App killed (force stop) → tetap diterima (FCM via OS)

### 11.3 Notification Types

- [ ] `leave_approved` → buka leave detail
- [ ] `chat_message` → buka chat
- [ ] `meeting_reminder` → buka event detail
- [ ] `broadcast` → buka broadcast list

### 11.4 Notification Settings

- [ ] User toggle "Notifications off" → tidak terima push
- [ ] Re-enable → push aktif lagi

---

## 12. CROSS-DEVICE & COMPATIBILITY

### 12.1 Android

- [ ] Android 5.0 Lollipop (minSdk 21) — minimum
- [ ] Android 8 Oreo — common older device
- [ ] Android 11
- [ ] Android 13 (notification permission baru)
- [ ] Android 14 latest

### 12.2 iOS (jika target aktif)

- [ ] iOS 13+
- [ ] iPhone SE (kecil)
- [ ] iPhone 13/14/15 (regular)
- [ ] iPad (tablet)

### 12.3 Device Screen Size

- [ ] Small (4-5 inch)
- [ ] Medium (5.5-6 inch)
- [ ] Large (6.5+ inch)
- [ ] Tablet
- [ ] No UI overlap, no overflow

### 12.4 Browser Admin

- [ ] Chrome (latest)
- [ ] Edge (latest)
- [ ] Firefox (latest)
- [ ] Safari (kalau ada user Mac)

### 12.5 Network Conditions

- [ ] WiFi cepat (50Mbps+)
- [ ] 4G/LTE (10Mbps)
- [ ] 3G (1Mbps)
- [ ] Edge case: throttled 2G

---

## 13. PRE-DEPLOYMENT FINAL CHECK

### 13.1 Code Quality

- [ ] `npx tsc --noEmit` admin → exit 0
- [ ] `npx next lint` admin → exit 0
- [ ] `flutter analyze` mobile → "No issues found!"
- [ ] `npm run build` admin → success
- [ ] `flutter build apk --release` → success

### 13.2 Secret & Config Check

- [ ] `.env.local` admin TIDAK di git
- [ ] `key.properties` mobile TIDAK di git
- [ ] `firebase-credentials-dev.json` TIDAK di git
- [ ] Keystore backup ke cloud/external drive
- [ ] Production env vars di Vercel/Firebase Hosting set lengkap
- [ ] Firebase project ID benar (production vs staging)

### 13.3 Database Production Setup

- [ ] Production Firestore rules deployed
- [ ] Production indexes deployed (cek di Console)
- [ ] Storage rules deployed
- [ ] Cloud Functions deployed di region asia-southeast2
- [ ] Settings `settings/system` doc terbuat dengan office config

### 13.4 Mobile Release Config

- [ ] `applicationId` = `id.co.jne.mtp.absensi` (production)
- [ ] Version code & version name di pubspec sesuai (bukan 1.0.0+1 kalau update)
- [ ] ProGuard rules tested → tidak ada crash di release mode
- [ ] App icon high-res (mipmap-xxxhdpi)
- [ ] Splash screen tampil benar
- [ ] App name & description final
- [ ] APK size reasonable (< 50MB ideal)

### 13.5 Play Store Submission (Mobile)

- [ ] Privacy policy URL ready
- [ ] App description (short & full)
- [ ] Screenshots (min 2, max 8 per device type)
- [ ] Feature graphic 1024x500
- [ ] App icon 512x512
- [ ] Categorization & content rating
- [ ] Data safety form filled (location, photos, etc.)
- [ ] Target audience age
- [ ] Internal testing track first → external testing → production

### 13.6 Admin Deployment

- [ ] Build static atau SSR sesuai target
- [ ] Domain custom configured
- [ ] SSL/HTTPS active
- [ ] `Authorized domains` di Firebase Auth include production URL
- [ ] CORS settings benar (jika API panggil dari domain lain)
- [ ] CSP header (Content-Security-Policy) tidak break app

---

## 14. POST-DEPLOYMENT MONITORING

### 14.1 First 24 Hours

- [ ] Cek Firebase Console > Functions > Logs setiap 2 jam
- [ ] Monitor Firestore reads/writes (cost watch)
- [ ] Monitor Firebase Auth signups
- [ ] Cek Storage usage
- [ ] Cek error rate di Crashlytics (kalau implementasi)
- [ ] Cek user feedback / complaints

### 14.2 First Week

- [ ] Cek absensi rate (% karyawan check-in tiap hari)
- [ ] Cek face enrollment completion rate
- [ ] Cek login issues collection — kalau banyak: ada masalah
- [ ] Cek `pending_sync` — ada yang stuck offline?
- [ ] Performance metrics di Firebase Performance Monitoring

### 14.3 Monthly Health Check

- [ ] Firestore document count growth reasonable
- [ ] Storage size growth (photos)
- [ ] FCM delivery rate > 95%
- [ ] App crash rate < 1%
- [ ] User retention rate
- [ ] Cost vs budget

### 14.4 Alerting

- [ ] Set up alert: error rate > 5% / 5 menit
- [ ] Set up alert: Firestore quota approaching
- [ ] Set up alert: function execution time spike
- [ ] Set up alert: storage usage > threshold

---

## 15. BUG REPORT TEMPLATE

```markdown
### 🐛 BUG REPORT

**Severity**: 🔴 Critical | 🟠 High | 🟡 Medium | 🟢 Low
**Component**: Admin / Mobile / Backend
**Module**: [e.g., Attendance Check-in]
**Found by**: [Tester name]
**Date**: YYYY-MM-DD
**Build**: Admin v[hash] / Mobile v1.0.0+1

#### Description
[Apa yang terjadi]

#### Steps to Reproduce
1.
2.
3.

#### Expected Behavior
[Apa yang seharusnya terjadi]

#### Actual Behavior
[Apa yang terjadi sekarang]

#### Environment
- Device: [e.g., Samsung A52, Android 13]
- Browser: [e.g., Chrome 120]
- Network: [WiFi / 4G]
- User Role: [admin / employee]

#### Screenshots/Logs
[Attach]

#### Workaround (if any)
[Cara sementara]
```

---

## 16. TEST DATA SKENARIO

### Skenario A: New Employee Onboarding
1. Admin add karyawan baru "Budi Santoso", dept "Kurir", personalEmail "budi@gmail.com"
2. Verifikasi: email otomatis, auth account, notif admin
3. Login Budi pertama kali → ganti password
4. Face enrollment
5. Day 1: check-in → check-out

### Skenario B: Cuti Sakit Mendadak
1. Karyawan "Ani" submit cuti sakit 3 hari (today-today+2)
2. Upload surat dokter
3. Admin approve
4. Verifikasi: Ani dapat push notif, status leave di attendance day 1-3

### Skenario C: Karyawan di Luar Geofence
1. Karyawan "Joko" buka app dari luar radius
2. Tap Check In → tampil "Anda berada X meter dari kantor"
3. Verifikasi: TIDAK ada record di Firestore
4. Joko ke dalam radius → check-in berhasil

### Skenario E: Offline Check-out
1. Karyawan check-in normal
2. Pulang: matikan WiFi → tap check-out
3. Verifikasi: data ke `pending_sync` + SQLite
4. Nyalakan WiFi → auto-sync ke `attendance`
5. Admin lihat record lengkap

### Skenario F: Multi-Device Login
1. Karyawan login di HP A
2. Login di HP B
3. Verifikasi: `fcm_tokens` punya 2 token untuk userId
4. Kirim chat → notif muncul di HP A dan B

### Skenario G: Bulk Karyawan
1. Admin tambah 50 karyawan via seed script
2. Verifikasi: dashboard tetap responsif
3. List employees pagination berfungsi
4. Export laporan 50 karyawan → file generated

### Skenario H: Year-Round Test
1. Set device time ke 31 Des
2. Karyawan check-out malam
3. Set device time ke 1 Jan
4. Verifikasi: tanggal record benar, tidak double-count

---

## ✅ SIGN-OFF

| Role | Nama | Tanggal | Signature |
|------|------|---------|-----------|
| QA Lead | __________ | __________ | __________ |
| Developer | Zainul Arkaan | __________ | __________ |
| Project Manager | __________ | __________ | __________ |
| Approver | __________ | __________ | __________ |

**Status Final**: ⬜ APPROVED FOR RELEASE / ⬜ NEED FIXES / ⬜ BLOCKED

**Catatan QA Lead**:
```
[Tulis ringkasan hasil QA, masalah yang masih open, dan rekomendasi]
```

---

**Dokumen ini wajib dilengkapi sebelum release production.**
Untuk pertanyaan: cek [DOKUMENTASI_PROJECT.md](DOKUMENTASI_PROJECT.md) atau [FIRESTORE_SCHEMA.md](FIRESTORE_SCHEMA.md).
