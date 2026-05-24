# 9. QA DATA VALIDATION

> **Tujuan**: Pastikan data yang masuk valid & data di database konsisten.
> **Estimasi waktu**: 2 jam
> **Prasyarat**: Akses Firestore Console
> **Tester**: Tester Web/Mobile

---

## 9.1 Form Validation — Client Side

### Admin: AddEmployeeModal

- [ ] Field `name` kosong → error "Nama wajib diisi"
- [ ] Field `name` < 3 char → error "Minimal 3 karakter"
- [ ] Field `email` kosong → error
- [ ] Field `email` format salah (no `@`) → error
- [ ] Field `email` duplicate → error dari backend
- [ ] Field `personalEmail` format salah → error
- [ ] Field `phone` non-numeric → error
- [ ] Field `phone` < 10 atau > 13 digit → error
- [ ] Field `department` belum dipilih → error
- [ ] Field `position` kosong → error

### Admin: Add Jam Kerja

- [ ] `checkInTime` format selain HH:mm → error
- [ ] `checkOutTime` <= `checkInTime` → error atau allow next-day flag
- [ ] `toleranceMinutes` negatif → error
- [ ] `workingDays` kosong → error

### Admin: Add Event

- [ ] `startDate` > `endDate` → error
- [ ] `attendees` kosong → warning atau allow
- [ ] `title` kosong → error

### Mobile: Submit Cuti

- [ ] Type belum dipilih → error
- [ ] `startDate` < today → error (kecuali emergency)
- [ ] `endDate` < `startDate` → error
- [ ] `reason` kosong → error
- [ ] `reason` < 10 char → warning
- [ ] Dokumen > 5 MB → error
- [ ] Dokumen format selain image/pdf → error

### Mobile: Submit Overtime

- [ ] `durationHours` <= 0 → error
- [ ] `durationHours` > 12 → warning
- [ ] `reason` kosong → error

### Mobile: Report Login Issue

- [ ] `name` < 1 atau > 100 char → tolak (sesuai rule)
- [ ] `emailOrEmployeeId` < 1 atau > 150 char → tolak
- [ ] `description` < 10 atau > 2000 char → tolak

### Mobile: Submit Dispute

- [ ] Subject kosong → error
- [ ] Content < 10 char → error

## 9.2 Server-side Validation (via Firestore Rules)

- [ ] Bypass client validation pakai console → tetap di-tolak rules
- [ ] Submit data dengan tipe salah (string vs number) → rules tolak
- [ ] Field required missing → tolak

## 9.3 Data Integrity

Cek langsung di Firestore Console:

- [ ] Tidak ada `null` di field required di `users` (name, email, role)
- [ ] Tidak ada `null` di `attendance.userId`, `attendance.date`
- [ ] Tidak ada `null` di `leaves.startDate`, `leaves.endDate`
- [ ] `createdAt` & `updatedAt` selalu Timestamp type, bukan string
- [ ] `checkIn.time` & `checkOut.time` selalu Timestamp
- [ ] Foreign reference (jamKerjaId di user) valid (doc target exists)
- [ ] Foreign reference (department di user) valid
- [ ] Status enum hanya nilai valid:
  - `users.role`: admin/superadmin/employee/kurir/driver
  - `attendance.status`: present/late/absent/leave/overtime/holiday
  - `leaves.type`: sick/annual/personal/emergency/other
  - `leaves.status`: pending/approved/rejected
  - `messages.status`: sent/delivered/read

## 9.4 Data Consistency

- [ ] `attendance.totalWorkMinutes` = `checkOut.time - checkIn.time` (toleransi 1 menit rounding)
- [ ] `attendance.lateMinutes` > 0 hanya kalau status `late`
- [ ] `attendance.overtimeMinutes` > 0 hanya untuk yang lewat shift
- [ ] `leaves.totalDays` = endDate - startDate + 1
- [ ] `user.faceRegistered=true` ↔ ada foto di Storage
- [ ] `user.firstLogin=false` setelah ganti password

## 9.5 Migration & Backward Compat

- [ ] User lama dengan schema lama → tetap kebaca (graceful null handling)
- [ ] Field baru → default value reasonable
- [ ] Attendance lama tanpa `faceScore` → tetap tampil
- [ ] Leave lama tanpa `documentUrl` → tampil "Tidak ada dokumen"

## 9.6 Encoding & Special Characters

- [ ] Nama dengan accent (é, ñ, å) → tersimpan & tampil benar
- [ ] Nama dengan CJK (中文, 日本語, 한글) → tersimpan & tampil
- [ ] Emoji di chat / reason cuti → tersimpan
- [ ] Newline di reason → tampil sebagai multi-line
- [ ] Tab/whitespace stripping (kalau perlu)

## 9.7 Numerik & Format

- [ ] Phone tampil dengan format konsisten (`+62812...` atau `0812...`)
- [ ] Date tampil format Indonesia (`23 Mei 2026` atau `23/05/2026` konsisten)
- [ ] Time tampil `HH:mm` (24h format)
- [ ] Currency / angka besar pakai separator (Rp 1.000.000)
- [ ] Persentase 1 desimal (`95.5%`)

## 9.8 Locale & Timezone

- [ ] Semua tanggal di Firestore disimpan UTC Timestamp
- [ ] Display tanggal pakai WIB (UTC+7) di admin & mobile
- [ ] `Intl.DateTimeFormat('id-ID', ...)` konsisten
- [ ] Bulan tampil dalam Bahasa Indonesia ("Mei" bukan "May")

## 9.9 ID & Uniqueness

- [ ] `employeeId` (NIK) unique global (cek before insert)
- [ ] `attendance` docId = `{userId}_{date}` unique (prevent double check-in)
- [ ] `fcm_tokens` docId = token itself unique
- [ ] User UID unique (Firebase Auth handles)

## 9.10 Defensive Coding

- [ ] Null check sebelum access nested field di mobile (`user?.checkIn?.time`)
- [ ] Default value untuk optional field (e.g., `phone ?? 'Tidak ada'`)
- [ ] Array empty check sebelum `.map()` atau `.length`
- [ ] Date parsing wrap try-catch

---

## Findings

| Type | Field | Issue | Affected docs |
|------|-------|-------|---------------|
|      |       |       |               |

---

**Tester**: ____________________________
**Tanggal selesai**: ____________________
**Data issue found**: ___
**Status**: ⬜ Clean / ⬜ Need data cleanup / ⬜ Validation gap
