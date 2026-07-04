# Task Breakdown — JNE Attendance System

> Kontrak dokumen: menerjemahkan PRD + SRS + SDD + UIUX_FLOW jadi pekerjaan yang bisa di-assign & ditrack. Setiap task punya **DoD (Definition of Done)** dan dependency. Status per 4 Juli 2026.

Legenda: ✅ selesai & live · 🔄 berjalan · ⬜ backlog

---

## Milestone 1 — Fondasi (Setup, Auth, Infrastruktur) ✅

| Task | DoD | Status |
|------|-----|--------|
| Setup repo (parent + admin nested git) + struktur folder | Kedua repo ter-push, gitlink admin berfungsi | ✅ |
| CI GitHub Actions (admin web+functions, mobile, public_site) | Semua job hijau di main | ✅ |
| Firebase project (`admin-absensi-jne-mtp`, asia-southeast2, Blaze) | Firestore, Auth, Storage, FCM, Functions aktif | ✅ |
| Firestore Security Rules per-koleksi | Deploy = file repo; user hanya akses miliknya; fcm_tokens & chats terkunci pemilik | ✅ |
| Auth email/password + role admin/superadmin + gating admin panel | Non-admin ditolak login web | ✅ |
| Onboarding otomatis (`onEmployeeCreated`): akun + email kredensial + link APK | Karyawan baru bisa login dari email saja; link tidak lewat tracker | ✅ |
| Seed scripts (admin, departments, employees, history) | `node scripts/setup_admin.mjs` dkk. jalan | ✅ |

## Milestone 2 — Modul Inti Absensi ✅

| Task | DoD | Status |
|------|-----|--------|
| Absen masuk/keluar + verifikasi wajah on-device (ML Kit) | FR-2.1; wajah tak cocok ditolak | ✅ |
| Geofence GPS (radius Settings, bypass kurir) | FR-2.2 | ✅ |
| Anti-duplikat harian (docId `{uid}_{tanggal}` + transaksi) | FR-2.3 | ✅ |
| Kunci CTA setelah masuk+keluar ("Absensi Selesai") | FR-2.4 | ✅ |
| Telat per-shift (`jamKerjaId`) + `lateMinutes` | FR-2.5 | ✅ |
| Shift malam lintas tengah malam vs record basi (jendela 18 jam) | FR-2.6/2.7 | ✅ |
| Offline queue SQLite + sync periodik | FR-2.8 | ✅ |
| Rollover hari otomatis (ganti tanggal tanpa restart) | Status kembali "Belum Absen" lewat tengah malam | ✅ |
| **Lembur SPL**: pengajuan APK, approval batas jam admin, hitung otomatis saat checkout, fallback cron 23:00 | FR-3 lengkap | ✅ |
| **Cuti**: 5 tipe, kuota tahunan atomik, surat dokter wajib sick, auto-row absensi, refund saat hapus | FR-4 lengkap | ✅ |
| **Cron alfa 23:59** (`scheduledAbsentMarker`) | FR-5 | ✅ |

## Milestone 3 — Komunikasi & Pendukung ✅

| Task | DoD | Status |
|------|-----|--------|
| Chat dua arah (koleksi flat `messages` + chatId) + push dua arah | FR-6.1/6.2 | ✅ |
| Presence admin & karyawan (heartbeat 30 dtk, toleransi jam 5 mnt) | FR-6.3 | ✅ |
| Dispute loop dua arah + rating + FAQ | FR-7 | ✅ |
| Notifikasi: hapus permanen, hapus semua, broadcast hide lokal, ikon JNE, pengingat 6×/hari | FR-8 | ✅ |
| SOS darurat (Opsi → Darurat) + admin alert | Alur SOS PRD §5.5 | ✅ |
| Kalender bersama + broadcast admin | Event tampil di kedua klien | ✅ |
| Dwibahasa ID/EN kedua aplikasi | Semua layar utama ter-wire | ✅ |
| Dark/light mode sistemik kedua aplikasi | Semua layar theme-aware | ✅ |

## Milestone 4 — Rilis, Kualitas & Operasional 🔄

| Task | DoD | Status |
|------|-----|--------|
| Distribusi APK arm64 (37 MB) + `app-latest.json` + prompt update | FR-9; URL publik HTTP 200 | ✅ |
| Runbook rilis terdokumentasi & teruji | build → upload → JSON → ACL | ✅ |
| Crashlytics + audit_log | Crash & aksi penting terekam | ✅ |
| Dokumen fondasi: PRD, SRS, SDD, UIUX_FLOW, TASKS | Kelima dokumen ada & saling nyambung | ✅ |
| Export CSV/PDF halaman data admin | 15 halaman punya tombol export | ✅ |
| Verifikasi rutin pra-rilis: `flutter analyze+test`, ESLint, `next build`, `tsc` | Semua hijau sebelum tiap rilis | ✅ (jalan terus) |
| E2E mobile (Maestro flows di `user_mobile/.maestro/`) | Flow absen+cuti happy-path hijau | 🔄 |
| CD hosting otomatis (public_site, gated FIREBASE_TOKEN) | Deploy otomatis saat merge | ⬜ |
| Backup/export Firestore terjadwal | Snapshot mingguan ke bucket | ⬜ |
| Rekap payroll bulanan otomatis (gabung lembur + telat + cuti) | Halaman gaji membaca `overtimeMinutes` agregat | ⬜ |
| Multi-hub (lebih dari 1 kantor/geofence) | Skema settings per-hub | ⬜ (out-of-scope MVP) |

---

## Aturan Perubahan

Perubahan kebutuhan mengalir **PRD → SRS → SDD/UIUX → TASKS** (dan kebalikannya saat update dokumen). Task baru wajib menunjuk requirement SRS (mis. "FR-3.4") supaya tidak ada pekerjaan tanpa dasar.
