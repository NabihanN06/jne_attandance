# 4. QA INTEGRATION CROSS-SYSTEM (E2E)

> **Tujuan**: Verifikasi alur data lintas admin ↔ mobile ↔ backend bekerja konsisten.
> **Estimasi waktu**: 4 jam
> **Prasyarat**: Section 2 & 3 sudah pass dasar
> **Tester**: Senior QA Tester (perlu pegang admin + mobile bersamaan)

---

## 4.1 Onboarding End-to-End

**Goal**: Karyawan baru dari nol sampai bisa absen pertama.

- [ ] Admin tambah karyawan baru via AddEmployeeModal
- [ ] Karyawan dapat email otomatis (cek inbox `personalEmail`)
- [ ] Email berisi kredensial + link APK + instruksi clear
- [ ] Karyawan install APK
- [ ] Login pertama dengan password default (`JNE123!`)
- [ ] Force change password screen muncul
- [ ] Ganti password → masuk home
- [ ] Lakukan face enrollment
- [ ] Admin dapat notif "X selesai enrollment"
- [ ] Hari pertama: check-in + check-out berhasil
- [ ] Admin lihat record absensi di dashboard

**Time-to-complete**: __________________

## 4.2 Absensi End-to-End

**Goal**: Absensi dari mobile harus tercermin lengkap di admin & terhitung benar.

- [ ] Karyawan check-in di mobile dalam radius geofence
- [ ] Admin lihat di dashboard real-time (tanpa refresh)
- [ ] Foto tersimpan di Storage (cek Firebase Console)
- [ ] Link foto valid di Firestore `attendance.checkIn.photoUrl`
- [ ] Status `present` atau `late` benar (cek vs jam masuk shift)
- [ ] Lokasi GPS sesuai dengan posisi karyawan
- [ ] `distance` field < radiusMeters
- [ ] `faceScore` >= threshold settings
- [ ] Check-out → `totalWorkMinutes` calculated
- [ ] Cloud Function `scheduledOvertimeCalc` jalan 23:00 → `overtimeMinutes` updated (verifikasi besok pagi)

## 4.3 Cuti End-to-End

**Goal**: Pengajuan cuti dari mobile → approval admin → notif balik.

- [ ] Karyawan submit cuti via mobile
- [ ] Admin dapat notif "ada cuti baru" real-time di NotificationPanel
- [ ] Admin buka /leaves → cuti baru muncul
- [ ] Admin approve
- [ ] Karyawan dapat push notif "Cuti Approved"
- [ ] Status cuti update di mobile real-time
- [ ] Saat tanggal cuti tiba → status `attendance` auto-jadi `leave` (cek hari H)
- [ ] Cuti reject dengan alasan: alasan muncul di mobile

## 4.4 Chat End-to-End

**Goal**: 2-way chat sinkron real-time.

- [ ] Admin kirim pesan ke karyawan A
- [ ] Karyawan A dapat push notif (kalau app background)
- [ ] Karyawan A buka app → pesan muncul
- [ ] Karyawan balas → admin terima real-time
- [ ] Status `sent` → `delivered` (saat sampai device) → `read` (saat buka chat)
- [ ] Typing indicator sinkron 2 arah
- [ ] Multi-message dalam satu sesi: semua terkirim berurutan

## 4.5 SOS Emergency End-to-End

**Goal**: Sinyal darurat sampai ke admin dalam hitungan detik.

- [ ] Karyawan kirim SOS dari lokasi acak (di luar kantor)
- [ ] Admin Dashboard ActiveAlerts → popup + suara (kalau di-implement)
- [ ] Admin click → lokasi karyawan di map (cek koordinat akurat)
- [ ] Admin verifikasi situasi (telp/chat karyawan)
- [ ] Admin resolve → status `sos_alerts` jadi `resolved`
- [ ] Karyawan dapat notif "SOS direspon" (jika ada)
- [ ] History SOS tetap tersimpan untuk audit
- [ ] Latency: < 5 detik dari tap SOS ke admin notif

## 4.6 Presence/Online End-to-End

**Goal**: Online indicator akurat & responsif.

- [ ] Karyawan buka app → indicator hijau di admin dalam < 35 detik
- [ ] Karyawan tutup app → indicator abu setelah ~40 detik
- [ ] Multiple devices login → semua tracked (1 user online via 2 device)
- [ ] Logout 1 device → device lain tetap online (kalau implementasinya per-user)
- [ ] App force kill → setelah heartbeat expire, jadi offline

## 4.7 Dispute Loop End-to-End

**Goal**: Komplain karyawan terlacak penuh dari submit sampai konfirmasi.

- [ ] Karyawan submit dispute
- [ ] Admin lihat di dashboard requests
- [ ] Admin balas via thread
- [ ] Karyawan terima notif, buka thread, balas
- [ ] Loop chat lancar
- [ ] Admin tandai resolved
- [ ] Karyawan terima notifikasi "perlu konfirmasi"
- [ ] Karyawan konfirmasi + isi rating
- [ ] Rating tersimpan di doc dispute
- [ ] FAQ tampil sesuai topik

## 4.8 Broadcast End-to-End

**Goal**: Broadcast dari admin sampai ke semua karyawan target.

- [ ] Admin buat broadcast ke 1 dept
- [ ] Semua karyawan dept itu dapat push notif
- [ ] Karyawan di luar dept TIDAK dapat
- [ ] Broadcast muncul di mobile notification list
- [ ] Click broadcast → buka detail

---

## Bug Yang Ditemukan (E2E specific)

| ID | Flow | Step where it broke | Deskripsi | Status |
|----|------|---------------------|-----------|--------|
|    |      |                     |           |        |

---

**Tester**: ____________________________
**Tanggal selesai**: ____________________
**Total flow**: ___ / 8 pass
**Status**: ⬜ All pass / ⬜ Pass with issues / ⬜ Blocked
