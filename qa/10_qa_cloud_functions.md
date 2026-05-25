# 10. QA CLOUD FUNCTIONS

> **Tujuan**: Verifikasi 8 Cloud Functions berfungsi sesuai trigger & business logic.
> **Estimasi waktu**: 2 jam
> **Prasyarat**: Functions deployed ke `asia-southeast2` + akses Firebase Console > Functions > Logs
> **Tester**: Backend QA / Developer

---

## 10.1 onEmployeeCreated

**Trigger**: Firestore `users/{uid}` onCreate
**File**: [admin/functions/src/index.ts](admin/functions/src/index.ts)

- [ ] Create user di Firestore via admin panel → CF trigger (cek logs)
- [ ] Firebase Auth account terbuat (cek di Console > Authentication)
- [ ] Default password set ke `JNE123!`
- [ ] `adminNotifications` doc terbuat (type: `new_employee`)
- [ ] Idempotent: kalau doc dihapus & dibuat ulang → tidak duplicate auth user (validation handle)
- [ ] Execution time < 3 detik
- [ ] No error di logs

**Test command via gcloud**:
```bash
firebase functions:log --only onEmployeeCreated
```

## 10.2 onLeaveStatusUpdate

**Trigger**: Firestore `leaves/{id}` onUpdate

- [ ] Update status leave dari `pending` → `approved` → FCM push terkirim
- [ ] Update status leave dari `pending` → `rejected` → FCM push dengan alasan
- [ ] Token tidak valid → token deleted dari `fcm_tokens` (cek log)
- [ ] Push payload include leave info (type, date, status)
- [ ] Tidak trigger kalau update field selain status
- [ ] Push delivered ke semua device user (multi-device)
- [ ] Execution time < 2 detik

## 10.3 onAttendanceCreated

**Trigger**: Firestore `attendance/{id}` onCreate

- [ ] Check-in baru → CF trigger
- [ ] Logging/processing absensi (cek log apa yang dilakukan)
- [ ] Tidak duplicate trigger pas update
- [ ] Execution time < 2 detik

## 10.4 onUserProfileUpdated

**Trigger**: Firestore `users/{uid}` onUpdate

- [ ] Update profile user → CF trigger
- [ ] Sync field tertentu (kalau ada)
- [ ] Tidak infinite loop (update from CF tidak trigger lagi)
- [ ] Execution time < 2 detik

## 10.5 onFaceEnrolled

**Trigger**: Firestore `users/{uid}` onUpdate (`faceRegistered=true`)

- [ ] Set `faceRegistered=true` via mobile → CF trigger
- [ ] Admin dapat notif "X selesai enrollment wajah"
- [ ] `adminNotifications` doc terbuat (type: `face_enrolled`)
- [ ] Tidak trigger kalau field selain `faceRegistered` berubah
- [ ] Idempotent: re-enroll → tetap kirim notif baru (atau dedup)

## 10.6 onAttendanceFailed (Callable)

**Trigger**: HTTPS Callable dari mobile

- [ ] Mobile panggil function dengan `{ userId }` → success response
- [ ] Admin dapat notif "X gagal face recognition 3x"
- [ ] Authentication required (tolak panggilan tanpa auth token)
- [ ] Rate limit (tidak spam multiple calls per detik)
- [ ] Execution time < 1 detik

**Test via Firebase emulator**:
```bash
firebase functions:shell
> onAttendanceFailed({ userId: 'test_uid' })
```

## 10.7 scheduledOvertimeCalc

**Trigger**: PubSub schedule `0 23 * * *` Asia/Jakarta (23:00 WIB)

- [ ] Cek log function pada 23:00 WIB hari pengetesan
- [ ] Loop semua `attendance` hari ini dengan `checkOut` lengkap
- [ ] Hitung `overtimeMinutes = totalWorkMinutes - normalShiftMinutes`
- [ ] Write back ke attendance doc
- [ ] Tidak update attendance tanpa checkOut
- [ ] Tidak update attendance status `leave` atau `absent`
- [ ] Execution time scale dengan jumlah karyawan (uji 100, 500, 1000)
- [ ] Idempotent: jalankan ulang → hasil sama
- [ ] Timezone benar (asia-southeast2 ≠ Asia/Jakarta, perlu explicit timezone dalam scheduler)

**Manual trigger via gcloud**:
```bash
gcloud scheduler jobs run firebase-schedule-scheduledOvertimeCalc-asia-southeast2 --location=asia-southeast2
```

## 10.8 sendOnboardingEmail

**Trigger**: Firestore `users/{uid}` onCreate

- [ ] Create user → email terkirim ke `personalEmail`
- [ ] Email berisi kredensial benar (email + default password)
- [ ] Email berisi link download APK
- [ ] Email tidak ke spam folder (test berbagai provider: Gmail, Yahoo, Outlook)
- [ ] Tidak kirim email kalau `personalEmail` kosong (graceful)
- [ ] Sender domain valid (configured)
- [ ] Subject line jelas: "Selamat Datang di JNE Attendance"
- [ ] Format email rapi (HTML + plaintext fallback)

## 10.9 Helper Function `sendPushToUser`

Indirect test via function 2, 5, 6, dll.

- [ ] Multi-token user → semua device dapat push
- [ ] Token expired → auto-delete dari `fcm_tokens`
- [ ] Error code `messaging/registration-token-not-registered` → clean up
- [ ] Error code `messaging/invalid-registration-token` → clean up
- [ ] Channel ID Android `high_importance_channel` set
- [ ] Sound default

## 10.10 Function Logs Health

- [ ] Cek Firebase Console > Functions > Logs (last 24 jam)
- [ ] Tidak ada error spam
- [ ] Tidak ada warning "Function execution took too long"
- [ ] Average execution time < 3 detik
- [ ] Cold start frequency reasonable (instance min 0 cost-efficient)

## 10.11 Region & Availability

- [ ] Semua function deployed di `asia-southeast2` (Jakarta)
- [ ] Latency dari Indonesia < 200ms
- [ ] Tidak ada function di region default `us-central1` (legacy)

## 10.12 Cost Monitoring

- [ ] Cek Cloud Functions invocations per day
- [ ] Estimasi cost per bulan reasonable
- [ ] Tidak ada infinite loop yang bikin cost spike

---

## Function Health Summary

| Function | Trigger | Avg Exec Time | Error Rate | Last Run | Status |
|----------|---------|---------------|------------|----------|--------|
| onEmployeeCreated | onCreate users | __ | __ | __ | ⬜ |
| onLeaveStatusUpdate | onUpdate leaves | __ | __ | __ | ⬜ |
| onAttendanceCreated | onCreate attendance | __ | __ | __ | ⬜ |
| onUserProfileUpdated | onUpdate users | __ | __ | __ | ⬜ |
| onFaceEnrolled | onUpdate users | __ | __ | __ | ⬜ |
| onAttendanceFailed | Callable | __ | __ | __ | ⬜ |
| scheduledOvertimeCalc | Schedule 23:00 | __ | __ | __ | ⬜ |
| sendOnboardingEmail | onCreate users | __ | __ | __ | ⬜ |

---

**Tester**: ____________________________
**Tanggal selesai**: ____________________
**Function issue**: ___
**Status**: ⬜ All functions healthy / ⬜ Some need fix / ⬜ Critical issue
