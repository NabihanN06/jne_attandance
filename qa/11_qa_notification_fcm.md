# 11. QA NOTIFICATION (FCM)

> **Tujuan**: Push notification delivery, token management, dan deep-link berfungsi sempurna.
> **Estimasi waktu**: 2 jam
> **Prasyarat**: Mobile app installed + admin punya akses untuk trigger notif
> **Tester**: Mobile QA Tester

---

## 11.1 Token Management

- [ ] Login mobile → FCM token saved ke `fcm_tokens/{token}` (docId = token, field userId)
- [ ] Cek Firestore: doc terbuat dengan userId benar
- [ ] App reinstall → token baru saved, token lama (kalau ada) di-delete oleh CF (saat invalid)
- [ ] Multi device login (user A di HP1 + HP2) → 2 token tersimpan untuk userId yang sama
- [ ] Logout mobile → token TIDAK auto-delete (assumsi: user mungkin login lagi)
- [ ] App update version → token tetap valid (kecuali force refresh)
- [ ] Token rotation otomatis sama Firebase → token baru saved, lama deprecated

## 11.2 Push Notification Delivery

### Test Trigger 1: Manual dari Admin
- [ ] Admin kirim notif via dashboard / API `/api/notify-user`
- [ ] User dapat push notif < 5 detik
- [ ] Notif tampil di notification bar
- [ ] Title + body tampil benar

### Test Trigger 2: Cloud Function (onLeaveStatusUpdate)
- [ ] Admin approve cuti
- [ ] User dapat push notif
- [ ] Sound default OR custom (sesuai settings.notificationsEnabled)
- [ ] Vibration

### Test Trigger 3: Broadcast
- [ ] Admin kirim broadcast
- [ ] Semua karyawan target dapat push

## 11.3 Notification States — App State

### App Background
- [ ] Push notif standard muncul di notification tray
- [ ] Sound + vibration
- [ ] Tap notif → buka app + navigasi ke screen relevan (deep link)

### App Foreground
- [ ] In-app toast atau silent (sesuai implementasi)
- [ ] Tidak duplikat dengan system notif
- [ ] Update badge count
- [ ] List notifikasi in-app update real-time

### App Killed (Force Stop)
- [ ] Push tetap diterima via OS FCM service
- [ ] Notif muncul di tray
- [ ] Tap → buka app dari cold start
- [ ] Setelah buka, screen relevan terbuka

## 11.4 Notification Types & Deep Link

- [ ] `leave_approved` → tap → buka leave detail screen
- [ ] `leave_rejected` → tap → buka leave detail dengan alasan
- [ ] `chat_message` → tap → buka chat screen dengan admin
- [ ] `sos_response` → tap → buka SOS history / map
- [ ] `meeting_reminder` (H-1) → tap → buka event detail
- [ ] `meeting_reminder` (30 min before) → tap → buka event detail
- [ ] `broadcast` → tap → buka broadcast list / detail
- [ ] `new_employee` (admin-side) → tap → buka karyawan detail di admin

## 11.5 Notification Settings User

- [ ] User toggle "Notifications off" di settings → TIDAK terima push
- [ ] Re-enable → push aktif lagi
- [ ] Granular setting per type (kalau diimplement): cuti only / chat only / dll
- [ ] System level permission revoke (Android settings) → FCM gagal kirim (graceful)

## 11.6 Notification Permission

### Android 13+
- [ ] First launch minta permission notif via dialog system
- [ ] Permission granted → push aktif
- [ ] Permission denied → tampil banner "Aktifkan notifikasi untuk update penting"
- [ ] Button banner → buka system settings

### Android < 13
- [ ] Permission otomatis granted (no dialog)

### iOS (kalau target aktif)
- [ ] Permission diminta sesuai iOS flow
- [ ] Badge count update

## 11.7 Notification Content & Format

- [ ] Title singkat (< 50 char) — judul jelas
- [ ] Body informatif (< 150 char ideal)
- [ ] No HTML / markdown raw (rendered as text)
- [ ] Emoji boleh di title/body kalau brand allow
- [ ] Data payload include `screen` atau `route` untuk deep link
- [ ] Image notif (rich notification) — kalau diimplement

## 11.8 Notification Channel (Android)

- [ ] Channel `high_importance_channel` exists dengan IMPORTANCE_HIGH
- [ ] Channel name & description bilingual (Indonesia + English)
- [ ] User bisa customize per-channel di system settings
- [ ] Sound channel-level berfungsi

## 11.9 Edge Cases FCM

- [ ] Multi-device: kirim 1 notif → semua device receive
- [ ] User di device baru (token belum saved) → tidak receive (sampai dia login)
- [ ] Token expired → CF auto-cleanup, notif berikutnya tidak fail
- [ ] Network offline saat trigger → FCM queue, deliver saat online
- [ ] Quiet hours / Do Not Disturb → push tetap masuk tapi silent (OS handle)
- [ ] Notification grouping (multiple notif dalam waktu dekat) — Android handle by tag/channel

## 11.10 In-App Notification List

- [ ] Notif di `userNotifications` muncul di list mobile
- [ ] Mark as read → `isRead=true`, badge update
- [ ] Mark all read → semua notif user diupdate
- [ ] Delete notif → terhapus dari list
- [ ] Pull to refresh → reload terbaru
- [ ] Pagination kalau > 50 notif
- [ ] Filter unread only

## 11.11 Admin Notification

- [ ] Admin dapat notif di header panel (real-time listener)
- [ ] Sound notif untuk SOS urgent
- [ ] Mark all read berfungsi
- [ ] Notif dari mobile (e.g., new SOS) muncul di admin instant

## 11.12 Delivery Rate

- [ ] Kirim 100 notif → minimal 95% delivered
- [ ] Cek Firebase Console > Cloud Messaging > Reports
- [ ] No silent failures (gagal tanpa error log)

---

## Latency Measurement

| Trigger | Latency (avg) | Notes |
|---------|---------------|-------|
| Admin manual notify | __ ms | |
| Leave approve | __ ms | |
| Broadcast 100 users | __ ms | |
| SOS to admin | __ ms | |
| Meeting reminder | __ ms | |

Target: < 5 detik end-to-end (trigger → device receive)

---

**Tester**: ____________________________
**Tanggal selesai**: ____________________
**Issue FCM**: ___
**Status**: ⬜ Reliable / ⬜ Need tuning / ⬜ Major delivery issue
