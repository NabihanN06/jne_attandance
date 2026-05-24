# 7. QA OFFLINE & EDGE CASES

> **Tujuan**: Verifikasi behavior aplikasi di kondisi tidak ideal (offline, slow network, time edge, data ekstrem).
> **Estimasi waktu**: 3 jam
> **Prasyarat**: Mobile app installed + admin panel running
> **Tester**: Mobile QA Tester

---

## 7.1 Mobile Offline Mode

- [ ] Matikan WiFi/data → app tampil banner "OFFLINE MODE • DATA WILL SYNC LATER"
- [ ] Check-in offline:
  - [ ] Tersimpan ke SQLite lokal
  - [ ] Tersimpan ke `pending_sync` Firestore (saat back online, atau queued)
  - [ ] User dapat feedback "Akan disinkronisasi nanti"
- [ ] Hidupkan internet → auto sync ke `attendance`
- [ ] `synced=true` setelah sync sukses
- [ ] Doc di `pending_sync` ter-delete atau marked synced
- [ ] Multiple offline records (e.g., check-in pagi, check-out sore offline) → sync semua urut
- [ ] `syncAttempts` increment kalau retry
- [ ] Sync gagal terus (max retry) → tampil notif "Sync error, hubungi admin"
- [ ] Foto offline disimpan local path → upload saat online

## 7.2 Network Edge Cases

- [ ] WiFi → Mobile data switch tengah upload → tetap selesai
- [ ] Mobile data → WiFi switch → tetap connected
- [ ] Slow 2G → upload foto → progress indicator + tidak crash
- [ ] Timeout handling: kalau request > 30s → tampil error + retry button
- [ ] Retry mechanism untuk upload foto (max 3x dengan exponential backoff)
- [ ] No internet sama sekali → semua tombol absen ke local queue
- [ ] Internet flap (on-off-on-off) → tidak crash, sync stabilize

## 7.3 Edge Case Data — Attendance

- [ ] User check-in 2x dalam 1 hari → tolak (docId = `{userId}_{date}` idempotent)
- [ ] User check-out tanpa check-in → tolak dengan pesan jelas
- [ ] User check-in tengah malam (23:55) → tanggal benar (sebelum midnight)
- [ ] User check-out lewat tengah malam (00:30 next day) → tanggal check-out vs check-in handled (jam kerja malam)
- [ ] User skip check-out → besok pagi auto-marked absent atau partial
- [ ] User check-in saat hari libur (`workingDays` tidak include) → tolak atau allow (sesuai policy)

## 7.4 Edge Case Data — Leave

- [ ] Cuti backdate (start < today) → tolak validasi
- [ ] Cuti overlap dengan cuti existing approved → tolak / warning
- [ ] Cuti dengan startDate > endDate → tolak
- [ ] Cuti 0 hari (start == end di tanggal yang sama) → handled (1 day)
- [ ] Cuti > 90 hari → warning atau tolak (sesuai policy)
- [ ] Cancel cuti yang sedang berlangsung → tolak / partial
- [ ] Approve cuti yang sudah lewat tanggalnya → handled

## 7.5 Edge Case Data — User

- [ ] Karyawan delete → attendance history milik dia tetap ada (soft delete?)
- [ ] Karyawan delete → tidak bisa login lagi (Auth disabled)
- [ ] Department delete → karyawan dengan dept tsb → tolak / reassign
- [ ] Karyawan dengan nama panjang (>50 char) → tampil truncate
- [ ] Karyawan dengan special char di nama (é, å, 中, 😀) → tersimpan benar
- [ ] EmployeeId duplicate → auto-generate next number

## 7.6 Time Zone Edge Cases

- [ ] Server timezone (Firestore Timestamp UTC) vs lokal WIB
- [ ] Karyawan di zona waktu beda (zona android device WIT/WITA) → tetap pakai WIB office
- [ ] Tengah malam check-in → tanggal benar (sebelum atau sesudah midnight)
- [ ] DST: tidak ada di Indonesia, skip
- [ ] Year-end (31 Des → 1 Jan) → record ter-attribut ke tahun benar

## 7.7 Date Edge Cases

- [ ] 29 Feb tahun kabisat → handled (akhir Februari)
- [ ] Akhir bulan (28/30/31) → next month rollover OK
- [ ] Tanggal kosong / null → fallback ke today
- [ ] Tanggal masa depan (e.g., 2099) → handled atau tolak

## 7.8 Camera Edge Cases

- [ ] Camera permission revoked tengah pakai → graceful (back to home + minta permission)
- [ ] Low light → face detection robust (tampilkan "Kurang cahaya, mohon area terang")
- [ ] Kamera depan vs belakang → switch berfungsi
- [ ] Foto rotated landscape/portrait → orientation correct setelah upload
- [ ] Camera busy (app lain pakai) → error message jelas
- [ ] Camera hardware error → fallback / retry option
- [ ] Foto bukan wajah (objek lain) → ML Kit tolak

## 7.9 Geolocation Edge Cases

- [ ] GPS off → minta nyalain (dialog system)
- [ ] Indoor (signal lemah) → tampil "Mencari sinyal GPS..."
- [ ] Lokasi akurasi rendah (>100m accuracy) → warning, izinkan retry
- [ ] Berpindah dari outdoor ke indoor saat check-in → tetap pakai posisi awal
- [ ] Lokasi dummy (mock GPS app) → detect & tolak
- [ ] First location request timeout → retry

## 7.10 Empty/Null State

- [ ] User baru daftar, belum pernah absen → home tampil ajakan check-in
- [ ] User belum face enroll → tombol absensi disabled + arahkan ke enroll
- [ ] Belum ada notifikasi → empty state "Belum ada notifikasi"
- [ ] Belum ada cuti → empty state "Belum ada pengajuan cuti"
- [ ] Belum ada event kalender → empty state
- [ ] Belum ada chat → tampil "Belum ada pesan"

## 7.11 Concurrent Modifications

- [ ] 2 admin approve cuti yang sama bersamaan → last-write-wins atau lock
- [ ] User update profil dari 2 device bersamaan → merge atau warning
- [ ] Admin delete karyawan saat karyawan sedang check-in → graceful

## 7.12 Resource Exhaustion

- [ ] Storage penuh di device → upload gagal dengan pesan jelas
- [ ] Memory penuh → app tidak crash, release resource
- [ ] Battery critical (< 5%) → fitur GPS/camera tetap jalan atau warning

---

## Catatan

```
[Tulis edge case unik yang ditemukan + reproduksi step]
```

---

**Tester**: ____________________________
**Tanggal selesai**: ____________________
**Bug ditemukan**: ___
**Status**: ⬜ Robust / ⬜ Need hardening / ⬜ Critical edge case found
