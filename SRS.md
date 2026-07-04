# Software Requirements Specification (SRS)

## JNE Attendance System — Martapura

> Kontrak dokumen: PRD menetapkan tujuan & scope → **SRS ini menerjemahkan PRD jadi aturan yang bisa dites** → SDD menerjemahkan SRS jadi desain teknis → Task Breakdown (TASKS.md) jadi pekerjaan.
>
> Format requirement memakai **Given–When–Then** supaya langsung bisa dipakai QA. Setiap fitur ditutup **Acceptance Criteria** (definisi "selesai").

---

## 1. Functional Requirements per Fitur

### FR-1 Autentikasi & Onboarding

| ID | Given | When | Then |
|----|-------|------|------|
| FR-1.1 | Admin membuat karyawan baru di halaman Karyawan | Dokumen `users/{uid}` dibuat | Cloud Function `onEmployeeCreated` membuat akun Firebase Auth + password sementara, menyimpan `tempPasswordPlain` di dokumen user, dan mengirim email onboarding (Brevo → fallback Gmail SMTP) berisi kredensial + tombol & URL polos download APK |
| FR-1.2 | Karyawan baru menerima kredensial | Login pertama kali di APK | Sistem MEMAKSA ganti password sebelum bisa lanjut; setelah ganti, `tempPasswordPlain` dihapus otomatis (`onUserProfileUpdated`) |
| FR-1.3 | Karyawan sudah ganti password | Belum melakukan pendaftaran wajah | Sistem mengarahkan ke halaman Enroll wajah; absensi TIDAK bisa dilakukan sebelum wajah terdaftar |
| FR-1.4 | User dengan role `admin`/`superadmin` | Login di admin panel web | Diterima masuk; role lain ditolak dengan pesan akses ditolak |
| FR-1.5 | Calon user gagal login | Menekan "Laporkan kendala login" | Laporan tertulis ke koleksi `login_issues` TANPA harus terautentikasi; hanya admin yang bisa membaca |

**Acceptance criteria:** karyawan baru bisa dari nol (dibuat admin) sampai absen pertama tanpa bantuan teknis, hanya lewat email onboarding.

### FR-2 Absensi Harian (Clock In / Clock Out)

| ID | Given | When | Then |
|----|-------|------|------|
| FR-2.1 | Karyawan berada ≤ radius geofence kantor (default 50 m, bisa dioverride di Settings) | Menekan tombol Absen Masuk | Kamera wajah terbuka; verifikasi wajah on-device (ML Kit); jika cocok, dokumen `attendance/{uid}_{yyyy-MM-dd}` dibuat |
| FR-2.2 | Karyawan di luar radius | Menekan tombol absen | Ditolak dengan pesan "di luar radius"; kurir dengan flag `courierBypassGeofence` dikecualikan |
| FR-2.3 | Karyawan sudah absen masuk hari ini | Mencoba absen masuk lagi | Transaksi Firestore MENOLAK (dokumen per-hari unik `{uid}_{tanggal}` = UNIQUE constraint) dengan pesan sudah absen |
| FR-2.4 | Karyawan sudah masuk DAN keluar hari ini | Melihat Beranda | Tombol absen menjadi **"Absensi Hari Ini Selesai"** (nonaktif) sampai ganti hari |
| FR-2.5 | Karyawan check-in > jam masuk shift | Check-in tersimpan | `lateMinutes` dihitung dari jam shift per-user (`jamKerjaId`) dan status = `late` |
| FR-2.6 | Karyawan shift malam check-in kemarin (< 18 jam lalu), belum checkout | Membuka Beranda lewat tengah malam | Tombol tetap "Absen Keluar" dan checkout menutup record kemarin (durasi lintas-tengah-malam benar) |
| FR-2.7 | Record kemarin LUPA di-checkout (≥ 18 jam sejak check-in) | Hari baru | Record basi DIABAIKAN: tombol kembali "Absen Masuk"; checkout hari ini TIDAK menimpa record kemarin |
| FR-2.8 | Tidak ada koneksi internet & `allowOfflineAttendance` aktif | Absen masuk | Record antre di SQLite lokal, banner "belum tersinkron" muncul, sinkron otomatis tiap 60 dtk saat online |
| FR-2.9 | Checkout tersimpan | — | `totalWorkMinutes`, `overtimeMinutes`, `splStatus`, `isHoliday`, `shiftEnd` ditulis ke dokumen attendance (lihat FR-3) |
| FR-2.10 | Foto absen diambil | Upload | Disimpan ke Storage `attendance_photos/`, dokumen menyimpan **download URL** (tidak pernah path lokal) |

**Validasi:** koordinat harus dalam rentang bumi; `date` & `attendanceDate` WAJIB keduanya terisi (kontrak lintas-platform); waktu server (bukan jam HP) dipakai untuk tanggal check-in online.

**Acceptance criteria:** satu karyawan = maksimal 1 dokumen absensi per hari; tidak ada jalur yang bisa membuat duplikat atau menimpa record hari lain.

### FR-3 Lembur (SPL — Surat Perintah Lembur)

| ID | Given | When | Then |
|----|-------|------|------|
| FR-3.1 | Hari kerja biasa, karyawan pulang > jam shift, TANPA SPL approved | Checkout | `overtimeMinutes = 0`, `splStatus = NONE/PENDING`; keterlambatan pulang tercatat tapi TIDAK dihitung lembur |
| FR-3.2 | Karyawan mengajukan SPL (tanggal + alasan) via APK | Submit | Dokumen `overtime` status `pending` muncul realtime di admin (Lembur & Kotak Masuk); duplikat tanggal yang sama ditolak |
| FR-3.3 | Admin menyetujui SPL dengan batas N jam | Karyawan checkout di tanggal itu | `overtimeMinutes = min(checkout − jam pulang shift, N×60, 240)`; realisasi disinkronkan balik ke dokumen SPL |
| FR-3.4 | Hari Minggu / libur nasional | Checkout | SELURUH menit kerja = lembur TANPA perlu SPL; jika > 6 jam dikurangi 60 menit istirahat |
| FR-3.5 | APK tidak menghitung (versi lama/gangguan) | Cron 23:00 WIB | `scheduledOvertimeCalc` menghitung fallback dengan aturan identik; dokumen yang sudah punya `overtimeMinutes` di-skip (tidak dobel) |
| FR-3.6 | SPL berstatus pending | Owner membatalkan | Boleh (update/delete); setelah approved, owner hanya boleh menulis field realisasi (`overtimeMinutes/overtimeHours/actualMinutes/updatedAt`) |

**Business rules:** batas lembur hari kerja **maksimal 240 menit/hari**; jam yang diset admin saat approve = **batas atas**, bukan durasi final; status `overtime` hanya menimpa `present` (catatan `late` dipertahankan).

**Acceptance criteria:** tidak ada jalan mendapatkan menit lembur di hari kerja tanpa SPL approved; angka lembur di APK, admin, dan payroll bersumber dari field yang sama (`overtimeMinutes`).

### FR-4 Cuti / Izin / Sakit

| ID | Given | When | Then |
|----|-------|------|------|
| FR-4.1 | Karyawan memilih tipe (annual/sick/permission/personal/urgent), tanggal, alasan | Submit | Dokumen `leaves` status `pending`; total hari dihitung hanya HARI KERJA (Sabtu-Minggu dilewati) |
| FR-4.2 | Tipe = `sick` | Submit tanpa foto surat dokter | DITOLAK di sisi form ("Foto surat dokter wajib dilampirkan"); foto diambil dari kamera, diupload ke `leave_attachments/`, admin melihat link "Lihat Surat Dokter" |
| FR-4.3 | Tipe = `annual`, sisa kuota < total hari | Admin approve | Approve GAGAL dengan pesan sisa saldo (transaksi atomik `approveLeave`); status kembali pending |
| FR-4.4 | Tipe = `annual`, kuota cukup | Admin approve | `usedAnnual` bertambah atomik; `balanceApplied/balanceDays/balanceField` tercatat di dokumen leave (anti potong-dobel) |
| FR-4.5 | Tipe sick/permission/personal/urgent | Admin approve | TIDAK memotong kuota; hanya tercatat `usedSick`/`usedPermission` untuk laporan |
| FR-4.6 | Cuti disetujui | — | Cloud Function membuat baris `attendance` status `leave` untuk SETIAP tanggal rentang (docId `{uid}_{tanggal}`) supaya tidak terhitung alfa |
| FR-4.7 | Pengajuan yang sudah memotong saldo dihapus | Hapus | Saldo dikembalikan dulu (`refundLeaveBalance`) sebelum dokumen dihapus |
| FR-4.8 | Admin membuka Kelola Saldo | Edit | HANYA `annualQuota` yang bisa diubah (0–60); angka terpakai read-only (dihitung otomatis dari approval) |
| FR-4.9 | Status pengajuan berubah | — | Karyawan menerima push FCM + notifikasi in-app (approve hijau, reject merah + alasan wajib) |

**Acceptance criteria:** angka "terpakai" di admin dan "sisa cuti" di APK selalu identik dengan riwayat approval; tidak ada jalur edit manual angka terpakai.

### FR-5 Deteksi Alfa Otomatis

| ID | Given | When | Then |
|----|-------|------|------|
| FR-5.1 | Karyawan aktif (bukan admin) tidak check-in dan tidak tercakup cuti approved | Cron 23:59 WIB | Dokumen `attendance` status `absent` dibuat otomatis (`markedBy: system_auto`) |
| FR-5.2 | Hari Minggu | Cron 23:59 | Dilewati (bukan hari kerja) |

**Acceptance criteria:** laporan bulanan tidak punya tanggal "bolong" — setiap hari kerja per karyawan punya status (present/late/overtime/leave/absent).

### FR-6 Chat Karyawan ↔ Admin

| ID | Given | When | Then |
|----|-------|------|------|
| FR-6.1 | Karyawan mengirim pesan | — | Pesan masuk koleksi flat `messages` dengan `chatId = uid karyawan`; admin menerima badge + suara "ding" realtime + **push web** ke semua browser admin yang mengizinkan notifikasi |
| FR-6.2 | Admin mengirim pesan | — | Karyawan menerima push FCM + mirror ke `userNotifications` |
| FR-6.3 | Admin membuka dashboard (halaman mana pun) | Karyawan melihat header chat | Status admin **Online** (presence heartbeat 30 dtk; tab ditutup → offline; toleransi selisih jam HP 5 menit) |
| FR-6.4 | Gambar dikirim di chat | — | Diupload ke Storage, dokumen menyimpan download URL |
| FR-6.5 | Status pesan | — | Lifecycle `sent → delivered → read`; field waktu = `createdAt` |

### FR-7 Dispute / Sanggah Absensi

| ID | Given | When | Then |
|----|-------|------|------|
| FR-7.1 | Karyawan membuka riwayat absensi berstatus telat/absen | Tombol "Sanggah" | Form sanggah (alasan wajib, bukti foto opsional ≤ 5 MB) → thread dua arah dengan admin |
| FR-7.2 | Karyawan tap baris riwayat NORMAL | — | Bottom-sheet DETAIL absensi (jam, jam kerja, telat, lembur); Sanggah hanya aksi sekunder di dalamnya |
| FR-7.3 | Admin merespon/menutup dispute | — | Karyawan dinotifikasi; setelah selesai karyawan bisa konfirmasi + beri rating |

### FR-8 Notifikasi

| ID | Given | When | Then |
|----|-------|------|------|
| FR-8.1 | Notifikasi personal (userNotifications) | Swipe / long-press hapus | Terhapus PERMANEN di server (rules mengizinkan delete milik sendiri) |
| FR-8.2 | Broadcast (milik bersama) | Dihapus user | Disembunyikan permanen secara lokal (SharedPreferences); server tidak berubah |
| FR-8.3 | Ikon notifikasi Android | Notif tampil di status bar | Siluet monokrom logo JNE (`ic_stat_notify`) + aksen merah #E31E24 — untuk notif lokal, pengingat, dan FCM background |
| FR-8.4 | Pengingat absensi aktif | 20/10/3 menit sebelum jam masuk & keluar | Notifikasi lokal terjadwal, hanya hari kerja (Minggu + libur nasional dilewati) |
| FR-8.5 | Badge "Kotak Masuk" admin menyala | Admin membuka halaman | Feed "Notifikasi Masuk" menampilkan item yang dihitung badge; bisa tandai dibaca satuan/semua & hapus |

### FR-9 Distribusi & Update APK

| ID | Given | When | Then |
|----|-------|------|------|
| FR-9.1 | Rilis APK baru diupload ke URL tetap | HP dengan build lama membuka app | Dialog update muncul (bandingkan `app-latest.json` vs build terpasang); `forceUpdate: true` memblokir pemakaian sampai update |
| FR-9.2 | Tombol download di email onboarding di-tap | Kapan pun | Selalu mengunduh build TERBARU (URL tetap, file ditimpa tiap rilis); link TIDAK melewati tracker email |

---

## 2. Validation Rules (Lintas Fitur)

| Field | Aturan |
|-------|--------|
| Email login | Format email valid (Firebase Auth) |
| Password | Minimal 6 karakter; wajib ganti dari password sementara |
| Koordinat kantor | lat −90..90, lng −180..180 — form Settings menolak di luar rentang (mencegah geofence rusak total) |
| Kuota cuti tahunan | Integer 0–60 |
| Batas jam SPL (admin) | Integer 1–12 (efektif ter-cap 4 jam untuk hari kerja) |
| Foto bukti dispute | ≤ 5 MB |
| Alasan penolakan (cuti/lembur/dispute) | WAJIB diisi saat reject |
| `leaves.type` | Salah satu dari `sick, annual, personal, permission, urgent` — kedua klien wajib menangani kelimanya |
| Gambar chat/bukti/surat dokter | Selalu download URL Storage, tidak pernah path lokal device |

## 3. Business Rules Inti

1. **Satu hari = satu dokumen absensi** per karyawan (docId `{uid}_{yyyy-MM-dd}`).
2. **Lembur hari kerja tanpa SPL approved = 0** — berapa pun telatnya pulang.
3. **Cap lembur harian 240 menit**; hari libur dihitung penuh minus istirahat.
4. Hanya **cuti tahunan** yang dibatasi & memotong kuota; sakit/izin tidak.
5. Jam masuk/pulang mengikuti **shift per-karyawan** (`jamKerjaId`), bukan jam global.
6. Aturan per-departemen (jam mulai, target paket kurir, shift malam lintas tengah malam, telat-sebagai-pengurang-jam) mengikuti `departmentRules.ts`.
7. Role: `superadmin` > `admin` > karyawan. Halaman berbahaya (dulu: maintenance/seeding) dihapus dari produk.

## 4. Error States & Messages (Kondisi Penting)

| Kondisi | Perilaku |
|---------|----------|
| Absen di luar radius | Snackbar merah "di luar radius kantor" |
| Absen dobel | "Anda sudah melakukan absensi masuk hari ini." |
| Checkout tanpa koneksi | "Koneksi internet diperlukan untuk absen keluar." |
| Approve cuti tanpa saldo | Toast merah berisi sisa saldo; status tidak berubah |
| Listener gagal (permission-denied dsb.) | APK: banner merah "Sebagian data gagal dimuat" + dialog detail; Admin: error benign saat sign-out DITELAN oleh wrapper `listen()` |
| Wajah tidak cocok 3× | Admin dinotifikasi (`onAttendanceFailed`) |
| Email onboarding gagal terkirim | Kredensial tetap tersedia di halaman Detail Karyawan (kartu manual + tombol WhatsApp) |

## 5. Non-Functional Requirements

| Kategori | Requirement | Implementasi |
|----------|-------------|--------------|
| **Realtime** | Perubahan data tampil di klien lain < 2 dtk tanpa refresh | Firestore `onSnapshot` di kedua klien; tidak ada polling |
| **Performance mobile** | Listener dibatasi (attendance 70, leaves ∞ user sendiri, overtime/dispute 20, notif 20, broadcast 10); rebuild di-coalesce per-microtask | `_scheduleNotify()` |
| **Performance admin** | Listener sering-nembak (heartbeat) wajib guard bail-out; chart tanpa animasi berulang | `project_admin_perf` |
| **Security** | Firestore Rules: setiap koleksi dikunci per-pemilik/admin; token FCM tidak bisa didaftarkan atas nama orang lain; kredensial SMTP/API di Secret Manager; `.env` & file AI tidak masuk repo | firestore.rules |
| **Audit** | Aksi penting (absen masuk/keluar) tercatat di `audit_log` | append-only, baca admin-only |
| **Availability** | Absen masuk tetap bisa saat offline (antrean SQLite + sync 60 dtk) | offline_service |
| **Crash monitoring** | Semua crash Flutter terekam | Firebase Crashlytics |
| **Scalability** | Semua query per-user ber-`limit()`; tidak ada full-collection scan dari klien | — |
| **Ukuran APK** | ≤ 40 MB (arm64 split; universal dilarang untuk distribusi) | 37 MB |
| **Waktu** | Tanggal absensi memakai waktu server (HTTP Date), timezone operasional Asia/Makassar (WITA), cron Asia/Jakarta | — |

## 6. Acceptance Criteria Global (Definition of Done Produk)

- [x] `flutter analyze` & `flutter test` hijau; ESLint + `next build` hijau; `tsc` functions hijau
- [x] Semua data di UI bersumber dari Firestore (tidak ada angka statis/dummy di halaman produksi)
- [x] Setiap perubahan data admin ⇄ mobile terlihat realtime dua arah
- [x] Rules ter-deploy identik dengan `admin/firestore.rules` di repo
- [x] Rilis mengikuti runbook: bump versi → build split-per-abi → upload URL tetap → update `app-latest.json` → re-grant ACL publik
