# UI/UX Flow — JNE Attendance System

> Kontrak dokumen: menerjemahkan PRD + SRS jadi interaksi & tampilan. Prinsip desain & tema ada di PRD §6; dokumen ini fokus ke **alur layar, state UI, dan microcopy**.

---

## 1. Peta Layar (Screen Inventory)

### Mobile (Flutter — karyawan)

| Layar | Route | Fungsi |
|-------|-------|--------|
| Splash → Onboarding → Login | `/`, `/onboarding`, `/login` | Entry; wajib ganti password saat login pertama |
| Izin Lokasi / Kamera | `/permission/*` | Minta permission sebelum dipakai |
| Enroll Wajah | `/enroll` | Registrasi wajah (wajib sebelum absen) |
| **Beranda** | `/home` | Hero absensi (jam masuk/keluar/lokasi + CTA dinamis), statistik bulan, mini-map, saldo cuti, menu cepat (Chat, Pengajuan, **Lembur**, Lokasi), navbar 4 item ber-label |
| Absen | `/attendance` | Kamera verifikasi wajah utk masuk/keluar |
| Riwayat | `/history` | Filter bulan/tahun; tap baris = bottom-sheet detail; Sanggah utk telat/absen |
| Cuti | `/leave` | Form tipe/tanggal/alasan; surat dokter wajib utk Sakit |
| Lembur (SPL) | `/overtime` | Ajukan SPL + kartu pemakaian bulanan |
| Statistik / Recap | `/statistic`, `/recap` | Agregat bulanan dari data attendance asli |
| Notifikasi | `/notification` | Filter semua/belum dibaca; swipe hapus; hapus semua |
| Chat HR | `/chat` | Thread dengan admin; status Online/Offline admin realtime |
| Pengajuan Saya | `/my_requests` | Status cuti/lembur/sanggah |
| Profil / ID Card | `/profile`, `/profile/id_card` | Info akun, saldo cuti, layanan, kartu pegawai |
| Opsi | `/option` | Semua fitur + **SOS Darurat** |
| Pengaturan | `/settings` | Dark mode, bahasa ID/EN, notifikasi, pengingat |

### Admin (Next.js — HR/manajemen)

| Halaman | Path | Fungsi |
|---------|------|--------|
| Dashboard | `/dashboard` | Ringkasan live |
| Kehadiran | `/attendance/*` | Live, per-departemen, riwayat, galeri foto |
| Kotak Masuk | `/requests` | **Feed Notifikasi Masuk** (sumber badge) + persetujuan cuti/lembur |
| Cuti & Izin | `/leaves` | Approval + link Surat Dokter + **Kelola Saldo (kuota-only)** |
| Lembur | `/overtime` | Approval SPL (set BATAS jam; realisasi otomatis) |
| Karyawan / Detail | `/employees*` | CRUD + kartu statistik real-time + kredensial onboarding |
| Pesan | `/chat` | Chat semua karyawan + presence |
| Lainnya | kalender, broadcast, laporan, analytics, wajah, kurir/paket, sales, gaji, pengaturan | — |

## 2. User Flow Utama (entry → goal)

```
ABSENSI:  Buka app → Beranda → [luar radius? tombol tolak] → Absen Masuk
          → kamera wajah → cocok → tersimpan → status "Hadir/Terlambat"
          → sore: Absen Keluar → lembur terhitung otomatis → CTA terkunci
             "Absensi Hari Ini Selesai" sampai besok

CUTI:     Beranda → Saldo Cuti "Ajukan" → pilih tipe → [Sakit? wajib foto
          surat dokter] → kirim → admin approve/reject → notif masuk
          → kalender absensi terisi otomatis status cuti

LEMBUR:   Menu cepat "Lembur" → ajukan SPL (tanggal+alasan) SEBELUM pulang
          → admin approve (batas jam) → pulang telat → menit lembur
          otomatis tercatat → terlihat di Statistik & admin

SANGGAH:  Riwayat → baris telat/absen → "Sanggah" → form + bukti
          → thread admin → selesai → konfirmasi + rating
```

## 3. State UI (wajib di setiap layar data)

| State | Perlakuan standar |
|-------|-------------------|
| **Loading** | Mobile: `PackageLoading` (animasi paket JNE); Admin: spinner + label "Memuat..." |
| **Empty** | Ilustrasi + judul + subjudul menjelaskan kenapa kosong ("Tidak ada permintaan menunggu — semua sudah diproses") |
| **Error** | Mobile: banner merah global "Sebagian data gagal dimuat • ketuk untuk detail" + dialog berisi error mentah (bisa disalin); Admin: toast + error benign sign-out ditelan wrapper |
| **Offline** | Banner merah "Mode Offline • data akan tersinkron otomatis" + banner sinkron di Riwayat |
| **Success** | Snackbar/toast hijau, teks aksi yang barusan terjadi |
| **Disabled** | Tombol abu/transparan + alasan terlihat (mis. "Absensi Hari Ini Selesai" dengan ikon centang) |

## 4. Microcopy Penting (kunci, jangan diganti asal)

| Konteks | Teks |
|---------|------|
| CTA absen | "Absen Masuk Sekarang" / "Absen Keluar Sekarang" / "Absensi Hari Ini Selesai" |
| Luar radius | "Anda berada di luar radius kantor. Mendekatlah ke lokasi kantor." |
| Surat dokter | "Foto surat dokter wajib dilampirkan untuk izin sakit." |
| SPL note | "Ajukan SEBELUM absen pulang… durasi lembur dihitung OTOMATIS dari jam absen pulang (maksimal 4 jam/hari)." |
| Reject wajib alasan | "Wajib memberikan alasan penolakan..." |
| Saldo habis | "Saldo cuti tahunan karyawan ini sudah habis — tidak bisa disetujui." |

Semua teks tersedia **dwibahasa ID/EN** (mobile: `app_strings.dart` via `context.tr()`; admin: `i18n.tsx` via `useT()`), bahasa default ID.

## 5. Component Rules

- **Warna status**: negatif WAJIB merah brand `#E31E24`; sukses emerald; menunggu amber; lembur violet; JNE orange utk aksen saldo.
- **Mobile design system**: WAJIB `context.palette` + komponen `ui_kit.dart` (GlassCard, AppCard, PrimaryButton, SectionLabel, AppInfoRow…) — dilarang hardcode warna baru.
- **Ikon navigasi & menu**: pakai aset PNG `assets/images/iconapk/`; setiap item navbar punya label teks di bawah ikon.
- **Tabel admin**: header uppercase kecil `text-slate-400`, baris hover; angka `tabular-nums`.
- **Modal**: konfirmasi destruktif selalu lewat `ConfirmContext` (judul + varian danger + label eksplisit).
- **Tailwind v4 syntax** di admin (`bg-linear-to-r`, `border-white/6`); token: `text-h1` 30px, `text-stats` 36px, `text-desc` 14px.
- **Dark/light**: kedua aplikasi theme-aware penuh; admin memakai CSS var (`--surface-card`, `--text-primary`, …).

## 6. Handoff Notes

- Padding konten admin: `p-8 lg:p-12` dari AdminLayout; full-bleed pakai `-m-8 lg:-m-12`.
- Mobile safe-area pakai `MediaQuery.padding`; padding layar standar 20; radius kartu 20–28.
- Breakpoint admin: sidebar collapse < lg; grid stat 2 kolom < lg, 4 kolom ≥ lg.
- Interaksi: haptic ringan pada tombol nav mobile; animasi masuk `FadeInUp/Down` 300–500 ms, jangan animasi berulang di list panjang.
