# ✅ Checklist Go-Live — Sistem Absensi JNE Martapura

Panduan langkah-demi-langkah untuk HR/Admin sebelum dan saat menggunakan sistem absensi
(wajah + GPS) secara resmi. Centang tiap item sambil dikerjakan.

**Tautan penting**

- Panel Admin: https://admin-absensi-jne-mtp.web.app
- Situs Publik (pelanggan): https://jne-martapura-kalsel.web.app
- Unduh APK karyawan: https://storage.googleapis.com/admin-absensi-jne-mtp.firebasestorage.app/public/app-jne-absensi.apk
- Versi aplikasi saat ini: **1.0.0 (build 7)** — pembaruan otomatis aktif

---

## TAHAP 0 — Persiapan Admin (sekali di awal)

- [ ] Login ke **Panel Admin** dengan akun admin/superadmin
- [ ] **Pengaturan → Lokasi Kantor**: set **titik GPS kantor** JNE Martapura + **radius geofence** (mis. 100 m). _Ini penentu absen dianggap "di kantor" atau tidak._
- [ ] **Departemen/Unit**: pastikan semua unit (Kurir, Driver, Inbound/Outbound, dll.) sudah dibuat
- [ ] **Jam Kerja / Shift**: atur jam masuk–keluar per departemen (termasuk shift malam bila ada)
- [ ] **Kuota Cuti**: atur jatah cuti tahunan per karyawan (bila dipakai)
- [ ] **Pengaturan Absensi**: cek toggle (wajib wajah, wajib GPS, toleransi telat, dll.) sesuai kebijakan
- [ ] Pastikan **APK terbaru** bisa diunduh dari tautan di atas (buka di HP, file ke-download)

---

## TAHAP 1 — Uji Pilot (1–2 orang dulu, WAJIB sebelum rollout)

> Tujuan: memastikan **wajah + GPS + kamera + notifikasi** benar-benar jalan di HP Android asli, di lokasi kantor sungguhan.

**Onboarding karyawan uji**

- [ ] Buat **1 akun karyawan** di **Karyawan → Tambah** (pakai email & data asli)
- [ ] Buka **Detail Karyawan** → bagikan kredensial via tombol **Kirim via WhatsApp** (atau Salin)
- [ ] Karyawan **install APK** (izinkan "Install dari sumber tak dikenal" bila diminta)
- [ ] Karyawan **login** pakai email + password sementara → **ganti password**
- [ ] Izinkan permission di HP: **Kamera, Lokasi, Notifikasi**
- [ ] **Daftar wajah (Face ID)** di menu profil/aplikasi

**Uji alur absensi (di lokasi kantor)**

- [ ] **Absen Masuk**: verifikasi wajah berhasil + GPS terdeteksi "di kantor" → sukses
- [ ] **Absen Keluar**: berhasil
- [ ] (Opsional) Uji **mode offline**: matikan internet → absen → nyalakan internet → data **tersinkron** otomatis
- [ ] Cek **pengingat absen** muncul (notifikasi sebelum jam masuk/keluar)

**Verifikasi di Panel Admin**

- [ ] Data absensi karyawan **muncul** di Dashboard & halaman Absensi
- [ ] **Foto wajah** absen masuk/keluar tampil di Detail Karyawan (Galeri Foto)
- [ ] **Statistik & Laporan** menghitung kehadiran dengan benar
- [ ] Karyawan bisa lihat **Recap Bulanan** di aplikasi

**Uji cuti & lembur**

- [ ] Karyawan **ajukan cuti** → muncul di **Kotak Masuk** admin → **Setujui** → karyawan dapat **notifikasi**
- [ ] Karyawan **ajukan lembur** → muncul di **Kotak Masuk** → **Setujui/Tolak** → notifikasi diterima
- [ ] Uji **tolak** dengan alasan → karyawan terima alasannya

✅ **Bila semua di atas mulus → AMAN untuk rollout ke semua karyawan.**

---

## TAHAP 2 — Rollout ke Semua Karyawan

- [ ] Buat **semua akun karyawan** (satu per satu di admin, atau lewat seed data)
- [ ] Bagikan kredensial ke tiap karyawan (tombol **WhatsApp** per orang)
- [ ] Umumkan cara pakai (install → login → daftar wajah → absen)
- [ ] Pantau **progres pendaftaran wajah** semua karyawan di admin
- [ ] **Hari pertama live**: pantau Dashboard realtime, siap bantu yang kesulitan
- [ ] Tetapkan PIC HR untuk tangani kendala hari pertama

---

## TAHAP 3 — Operasional Harian (HR)

- [ ] Pantau **Dashboard** kehadiran setiap pagi
- [ ] Proses **Kotak Masuk** (cuti & lembur) tiap hari — jangan menumpuk
- [ ] Cek inbox **Kendala Login** & **Permintaan Edit Data**
- [ ] Balas **Chat** support karyawan bila ada
- [ ] Akhir bulan: **Laporan → Cetak PDF / Excel / Ringkasan Unit** untuk manajemen

---

## 🆘 Troubleshooting Umum

| Masalah | Solusi cepat |
| --- | --- |
| Wajah tidak terbaca | Daftar ulang wajah; pastikan pencahayaan cukup & wajah jelas |
| GPS dianggap "jauh dari kantor" | Cek **radius geofence** di Pengaturan → Lokasi Kantor; pastikan GPS HP aktif (mode akurasi tinggi) |
| Tidak bisa login | Cek akun di admin; reset/bagikan ulang password sementara |
| APK tidak ter-install | Izinkan **"Install dari sumber tak dikenal"** di setting HP |
| Notifikasi tidak masuk | Izinkan **Notifikasi** untuk aplikasi di setting HP; pastikan tidak di-batasi baterai |
| Pengajuan tidak muncul di admin | Pastikan karyawan submit dari aplikasi; refresh halaman Kotak Masuk |

---

## 💤 Opsional (tidak menghambat pemakaian)

- [ ] **Email onboarding otomatis (SMTP)** — saat ini kredensial dibagikan via WhatsApp/manual (sudah cukup). Aktifkan bila ingin email otomatis (perlu App Password Gmail).
- [ ] **Auto-deploy (CI/CD)** — saat ini deploy manual. Aktifkan dengan menambah secret `FIREBASE_TOKEN` di GitHub bila ingin tiap perubahan otomatis ter-publish.

---

_Sistem sudah live & terverifikasi dari sisi kode/deploy. Checklist ini memastikan
kesiapan operasional & dunia-nyata sebelum dipakai seluruh tim. Selamat go-live! 🚀_
