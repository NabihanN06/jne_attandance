# 2. QA ADMIN PANEL — FUNCTIONAL

> **Tujuan**: Verifikasi semua fitur admin panel berfungsi sesuai spec.
> **Estimasi waktu**: 1 hari kerja
> **Prasyarat**: [01_pre_test_setup.md](01_pre_test_setup.md) selesai
> **Tester**: Web QA Tester

---

## 2.1 Authentication

- [ ] Login dengan email & password valid → masuk dashboard
- [ ] Login dengan password salah → error message jelas
- [ ] Login dengan email tidak terdaftar → error message
- [ ] Login dengan akun karyawan (role: employee) → ditolak (admin-only)
- [ ] Forgot password → email reset terkirim
- [ ] Click reset link → reset password berhasil
- [ ] Logout → kembali ke login page, session cleared
- [ ] Session expired → auto-redirect ke login
- [ ] Akses URL admin tanpa login → redirect login

## 2.2 Dashboard

- [ ] Stats card (Hadir/Terlambat/Absen hari ini) tampil angka benar
- [ ] Chart mingguan render benar
- [ ] Active Alerts (SOS, face_failed) tampil real-time
- [ ] Quick action buttons berfungsi (link ke modul terkait)
- [ ] Real-time update saat ada absensi baru tanpa refresh manual
- [ ] Empty state saat tidak ada data hari ini
- [ ] Klik card stats → drill-down ke modul detail

## 2.3 Manajemen Karyawan (/employees)

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
- [ ] WhatsApp button onboarding berfungsi (open wa.me link)
- [ ] Copy onboarding message berfungsi (toast confirm)

## 2.4 Monitoring Absensi (/attendance)

- [ ] List absensi hari ini → semua karyawan + status
- [ ] Filter tanggal → data sesuai
- [ ] Filter status (present/late/absent/leave) → filter benar
- [ ] Klik baris absensi → detail (foto, lokasi, waktu, faceScore)
- [ ] Foto check-in dan check-out tampil
- [ ] Map preview lokasi check-in akurat
- [ ] Real-time: karyawan check-in di mobile → muncul di admin tanpa refresh
- [ ] Export data per tanggal/bulan

## 2.5 Persetujuan Cuti (/leaves)

- [ ] List leaves dengan filter status (pending/approved/rejected)
- [ ] Lihat detail cuti + dokumen pendukung (kalau ada)
- [ ] Approve cuti → status berubah → push notif terkirim ke karyawan
- [ ] Reject cuti dengan alasan → status berubah → karyawan dapat notif + alasan
- [ ] **Cloud Function `onLeaveStatusUpdate`** trigger
- [ ] Cuti kemarin tidak bisa di-cancel oleh karyawan (validasi backend)
- [ ] Filter cuti by departemen/tanggal
- [ ] Bulk approve/reject berfungsi (jika ada)

## 2.6 Jam Kerja & Shift (/jam-kerja, /shifts)

- [ ] CRUD jam kerja:
  - [ ] Tambah dengan checkInTime, checkOutTime, toleranceMinutes
  - [ ] Edit jam kerja existing
  - [ ] Delete (validasi: tidak boleh delete kalau ada karyawan pakai)
- [ ] Set working days (Senin-Minggu) berfungsi
- [ ] Color picker berfungsi (untuk identifikasi di UI)
- [ ] isActive toggle berfungsi
- [ ] Format jam HH:mm valid

## 2.7 Departemen (/departments)

- [ ] CRUD departemen
- [ ] Color picker
- [ ] Delete validasi: tidak boleh kalau ada karyawan
- [ ] Department rules sinkron dengan `departmentRules.ts`
- [ ] Total karyawan per dept akurat

## 2.8 Kalender (/calendar)

- [ ] Tambah event dengan startDate, endDate, attendees
- [ ] Multi-day event tampil benar di grid
- [ ] Filter category (meeting/training/social/deadline)
- [ ] Edit event → tersimpan
- [ ] Delete event
- [ ] **Auto reminder** terkirim H-1 dan 30 menit sebelum
- [ ] `notificationSentDayBefore`/`notificationSent30Min` flag set true setelah kirim
- [ ] Target departments → semua karyawan dept itu dapat notif
- [ ] Navigasi bulan prev/next
- [ ] Today highlight

## 2.9 Chat (/chat)

- [ ] List konversasi dengan karyawan
- [ ] Buka chat → load history pesan
- [ ] Kirim pesan → muncul di mobile karyawan real-time
- [ ] Status `delivered` muncul saat mobile receive
- [ ] Status `read` muncul saat karyawan buka chat
- [ ] Typing indicator real-time
- [ ] Unread badge count akurat
- [ ] Scroll ke pesan lama tidak lag
- [ ] Search chat berdasar nama karyawan

## 2.10 Broadcast (/broadcast)

- [ ] Tulis broadcast → kirim ke semua karyawan / grup tertentu
- [ ] Karyawan dapat push notif
- [ ] Broadcast muncul di mobile notifikasi
- [ ] History broadcast tersimpan
- [ ] Edit/delete broadcast (jika diizinkan)
- [ ] Schedule broadcast (jika fitur ada)

## 2.11 Approve Request (/requests, /edit-requests)

- [ ] List overtime request → approve/reject
- [ ] List edit request absensi → review changes → approve
- [ ] Approve edit → attendance doc ter-update sesuai requestedChanges
- [ ] Audit log tercatat saat approve
- [ ] Reject dengan alasan

## 2.12 Laporan (/reports)

- [ ] Pilih periode (date range) → data ter-filter benar
- [ ] Filter departemen → data benar
- [ ] Export PDF → file ter-download, format rapi
- [ ] Export Excel → file ter-download, header & data benar
- [ ] Summary stats akurat (total kerja, total terlambat, dll)
- [ ] Empty state kalau periode tanpa data
- [ ] Per-employee breakdown

## 2.13 Pengaturan (/settings)

- [ ] **Office**: ubah lat/lng/radius → tersimpan → mobile pakai data baru
- [ ] **Attendance**: ubah faceSimilarityThreshold → mobile pakai
- [ ] **Company**: ubah info → muncul di mobile profile
- [ ] **Notifications**: toggle on/off → tersimpan
- [ ] **Maintenance**: mode maintenance → mobile tampil banner

## 2.14 Login Issues (/login-issues)

- [ ] List laporan masalah login dari user
- [ ] Tandai resolved
- [ ] Hubungi user via WA/email berdasar data laporan
- [ ] Validasi data laporan (size limit name/email/desc)

## 2.15 Face Enrollment Monitor (/face-enrollment)

- [ ] List karyawan dengan status face enrollment
- [ ] Klik karyawan → foto wajah tampil
- [ ] Karyawan baru enrol → muncul real-time

## 2.16 Notifikasi Panel (Header)

- [ ] Badge unread count akurat
- [ ] Click notifikasi → mark as read
- [ ] Notifikasi berurutan dari terbaru
- [ ] Mark all as read berfungsi
- [ ] Delete notifikasi berfungsi
- [ ] Tipe notif berbeda: leave_request, face_enrolled, sos, new_employee

---

## Bug Yang Ditemukan

| ID | Severity | Modul | Deskripsi | Status |
|----|----------|-------|-----------|--------|
|    |          |       |           |        |

(Pakai template di [15_bug_report_template.md](15_bug_report_template.md))

---

**Tester**: ____________________________
**Tanggal selesai**: ____________________
**Total item**: ___ / ___ pass
**Status**: ⬜ All pass / ⬜ Pass with bugs / ⬜ Blocked
