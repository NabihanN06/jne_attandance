# 5. QA SECURITY & PERMISSION

> **Tujuan**: Verifikasi pertahanan terhadap akses unauthorized, injection, dan abuse.
> **Estimasi waktu**: 4 jam
> **Prasyarat**: Setup test akun (Section 1) + akses Firebase Console
> **Tester**: Security QA Tester / Senior Tester

---

## 5.1 Firestore Rules Enforcement

Test pakai 2 akun: karyawan A & karyawan B + admin. Pakai Firebase Emulator atau test langsung di staging.

- [ ] Karyawan A TIDAK bisa baca dokumen `users/{B_uid}` (test via console / mobile hack)
- [ ] Karyawan A TIDAK bisa update field `role` sendiri
- [ ] Karyawan A TIDAK bisa update field `employeeId`, `department`, `email`, `uid` sendiri
- [ ] Karyawan A TIDAK bisa create attendance dengan `userId = B_uid`
- [ ] Karyawan A TIDAK bisa update leaves milik B
- [ ] Karyawan A TIDAK bisa update leaves yang sudah `approved` (rule: status='pending' only)
- [ ] Karyawan A TIDAK bisa delete leaves yang sudah `approved`
- [ ] Karyawan A TIDAK bisa baca chat antar admin↔B
- [ ] Karyawan A TIDAK bisa baca semua `userNotifications` orang lain
- [ ] Karyawan A BISA update status messages dia jadi `read`/`delivered`
- [ ] Karyawan TIDAK bisa write ke `audit_log`
- [ ] Karyawan TIDAK bisa write ke `settings/system`
- [ ] Karyawan TIDAK bisa write ke `leave_balances`
- [ ] Admin BISA semua operasi (test verifikasi positif)
- [ ] Unauthenticated TIDAK bisa apa-apa kecuali:
  - [ ] Create `login_issues` dengan field valid
  - [ ] Read `shifts`/`departments`/`settings` (kalau rule allow read auth)

## 5.2 Login Security

- [ ] Brute force: 5x login salah → rate limited (Firebase Auth default reCAPTCHA)
- [ ] Password tidak pernah tampil plain di UI (input type="password")
- [ ] Password tidak ke-log di console browser
- [ ] Session cookie HttpOnly, Secure, SameSite=Lax/Strict (cek devtools)
- [ ] CSRF protection untuk POST endpoints (cek API routes)
- [ ] Login URL HTTPS only (HTTP redirect ke HTTPS)
- [ ] Reset password link expire setelah waktu tertentu
- [ ] Reset password butuh confirmation password baru

## 5.3 API Routes Authorization

Test pakai Postman / curl:

- [ ] `POST /api/notify-user` TANPA session cookie → 401 Unauthorized
- [ ] `POST /api/notify-user` dengan session karyawan (non-admin) → 403 Forbidden
- [ ] `POST /api/notify-user` dengan session admin valid → 200 OK
- [ ] `POST /api/audit-log` access control sama
- [ ] `POST /api/notify-admin` access control sama
- [ ] `POST /api/send-notification` access control sama
- [ ] Tidak ada API yang leak data sensitive di response error
- [ ] Rate limit per endpoint (kalau diimplement)

## 5.4 Storage Security

- [ ] User A TIDAK bisa download foto user B (cek storage.rules)
- [ ] Admin BISA download semua foto
- [ ] File size limit (e.g., max 5MB) → tolak file besar
- [ ] File type validation (only image/jpeg, image/png)
- [ ] Upload file `.exe` atau `.sh` → ditolak
- [ ] Direct URL access (tanpa auth) → ditolak
- [ ] Signed URL expire setelah waktu tertentu

## 5.5 Input Sanitization

- [ ] SQL injection: tidak applicable (NoSQL)
- [ ] NoSQL injection: input `{ $ne: null }` di field → diproses sebagai string biasa
- [ ] XSS: input `<script>alert(1)</script>` di name → tersimpan as text, render escaped
- [ ] XSS: input HTML/script di reason cuti → tampil sebagai text plain
- [ ] Field size limit di rules `login_issues` enforced (name 1-100, desc 10-2000)
- [ ] Field size limit di chat message (jika ada)
- [ ] Unicode special chars handled (emoji, RTL text)

## 5.6 Device Binding (Opsional, jika fitur aktif)

- [ ] User login di device A → `registeredDeviceId` tersimpan
- [ ] Login di device B → tolak / warning
- [ ] Admin bisa reset `registeredDeviceId` via dashboard
- [ ] Kalau fitur off (default) → multi-device login boleh

## 5.7 Mock GPS Detection

- [ ] Test pakai aplikasi Fake GPS (Mock Location)
- [ ] Geolocator detect `isMocked: true`
- [ ] Tolak absensi atau flag suspicious (cek attendance doc)
- [ ] Notif admin "absensi mencurigakan" (jika diimplement)

## 5.8 Sensitive Data Exposure

- [ ] Token FCM tidak ke-log di console mobile
- [ ] Password tidak masuk ke `audit_log`
- [ ] Firebase API key public (`NEXT_PUBLIC_*`) — OK exposed
- [ ] Firebase ADMIN credentials (`FIREBASE_PRIVATE_KEY`) — TIDAK exposed di client
- [ ] `firebase-credentials-dev.json` tidak di-commit ke git
- [ ] `key.properties` tidak di-commit ke git
- [ ] `.env.local` tidak di-commit ke git
- [ ] Error stack trace tidak expose path server di production

## 5.9 Photo & PII (Personally Identifiable Information)

- [ ] Foto wajah karyawan tidak accessible publik
- [ ] Email karyawan tidak expose ke karyawan lain
- [ ] Phone tidak expose
- [ ] EmployeeId tidak expose di URL public
- [ ] Foto absensi ada watermark / metadata removal (opsional)

## 5.10 Session Management

- [ ] Session expire setelah idle (cek timeout config)
- [ ] Logout invalidate session di server
- [ ] Login di device baru tidak otomatis logout device lama (kalau multi-device allowed)
- [ ] Force logout dari admin → user kick keluar

## 5.11 Race Condition

- [ ] User check-in 2x dalam 1 detik (double-tap) → hanya 1 record tercipta
- [ ] User update profil simultan dari 2 device → last-write-wins atau merge benar
- [ ] Admin approve cuti yang sudah di-cancel user → ditolak

---

## Findings & Recommendations

```
[Tulis temuan vulnerability atau gap security di sini]
```

---

**Tester**: ____________________________
**Tanggal selesai**: ____________________
**Vulnerability ditemukan**: ___ (Critical: ___, High: ___, Medium: ___, Low: ___)
**Status**: ⬜ Secure for release / ⬜ Need fixes / ⬜ Critical issues — BLOCK
