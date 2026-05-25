# 15. BUG REPORT TEMPLATE

> **Tujuan**: Template standar untuk laporan bug supaya developer cepat reproduce & fix.
> **Pakai**: Setiap kali ketemu bug di section manapun.

---

## 📋 Template Bug Report

Copy template di bawah ini untuk tiap bug baru. Simpan di folder `qa/bugs/BUG-XXX.md` atau langsung post ke Github Issues / Trello / Notion.

```markdown
# 🐛 BUG-XXX: [Judul Singkat]

**Severity**: 🔴 Critical | 🟠 High | 🟡 Medium | 🟢 Low
**Component**: Admin / Mobile / Backend / Cloud Function
**Module**: [e.g., Attendance Check-in, Leave Approval]
**Found in QA Section**: [e.g., Section 3.4 — Check-in Absensi]
**Found by**: [Tester name]
**Date**: YYYY-MM-DD
**Build**: Admin v[hash] / Mobile v1.0.0+1
**Status**: 🆕 New | 🔍 Investigating | 🛠️ In Progress | ✅ Fixed | ❌ Won't Fix | 🔁 Duplicate

---

## Deskripsi

[Apa yang terjadi, jelaskan singkat 1-2 kalimat]

## Steps to Reproduce

1. Buka [screen/page]
2. Klik [button/action]
3. Input [data]
4. ...

## Expected Behavior

[Apa yang seharusnya terjadi]

## Actual Behavior

[Apa yang terjadi sekarang — termasuk error message kalau ada]

## Environment

| Item | Value |
|------|-------|
| Device | [e.g., Samsung A52, Xiaomi Redmi Note 11] |
| OS | [e.g., Android 13, iOS 17.0] |
| App version | [e.g., 1.0.0+1] |
| Browser | [e.g., Chrome 120 — kalau admin] |
| Network | [WiFi / 4G / 3G / Offline] |
| User Role | [admin / superadmin / employee] |
| Account | [test account email kalau perlu] |
| Time | [HH:mm WIB, tanggal] |

## Frequency

- ⬜ Selalu reproducible (100%)
- ⬜ Sering (>50%)
- ⬜ Kadang (<50%)
- ⬜ Sekali (race condition?)

## Screenshots / Recordings

[Attach gambar/video. Untuk video bisa pakai ScreenRecorder, untuk admin pakai Chrome DevTools recording]

## Logs / Error Stack

```
[Paste error log, console output, Firebase function log, dll]
```

## Impact

[Berapa user terdampak? Blocker untuk release? Workaround tersedia?]

## Workaround (sementara)

[Cara user bisa lanjut pakai meski bug ada, kalau ada]

## Suggested Fix (optional)

[Kalau tester punya hint penyebab atau lokasi kode, tulis di sini]

## Related Bugs

- BUG-XXX: [related issue]
- BUG-XXX: [related issue]

## Assignee

**Developer**: ___________________
**Reviewer**: ___________________
**ETA**: YYYY-MM-DD

---

## Resolution

**Fixed in commit**: [commit hash]
**Fixed in version**: [admin v____ / mobile v____]
**Verified by**: [tester name]
**Verified date**: YYYY-MM-DD
**Notes**: [optional]
```

---

## 🎯 Severity Guide — Cara Tentukan Level

### 🔴 Critical
**Definisi**: App tidak bisa dipakai sama sekali ATAU data loss ATAU security breach
**Contoh**:
- Login gagal total (semua user)
- Absensi tidak tersimpan ke Firestore
- Foto wajah bocor ke public URL
- Admin tidak bisa akses dashboard
- App crash setiap dibuka
- SQL/NoSQL injection vulnerability

**Action**: **STOP RELEASE**, fix segera (24 jam max), hotfix jika prod.

### 🟠 High
**Definisi**: Fitur utama tidak berfungsi tapi masih ada workaround
**Contoh**:
- Approve cuti tidak kirim push notif (admin bisa kirim manual)
- Chat tidak real-time tapi muncul setelah refresh
- Geofence false reject (user di dalam dianggap di luar)
- Foto tidak tersimpan ke Storage tapi attendance doc terbuat

**Action**: Fix sebelum release. Kalau sudah live, patch dalam 1 minggu.

### 🟡 Medium
**Definisi**: Fitur sekunder error, atau UX significant tapi tidak blocker
**Contoh**:
- Toast confirmation tidak muncul
- Sort by name tidak akurat
- Dark mode tidak persist setelah restart
- Animasi jank di list panjang
- Notif sound tidak terdengar (visual muncul)

**Action**: Fix kalau ada waktu. Atau patch berikutnya.

### 🟢 Low
**Definisi**: Cosmetic, typo, minor inconvenience
**Contoh**:
- Spasi salah di label
- Warna tidak konsisten antar halaman
- Padding sedikit off
- Typo "Berhasi" → "Berhasil"
- Tooltip terlalu cepat hide

**Action**: Backlog, batch ke patch berikutnya.

---

## 📝 Tips Menulis Bug Report

1. **Title singkat & spesifik** — bukan "Login error" tapi "Login fail di Samsung A52 dengan password berisi karakter @"
2. **Reproducible steps** — anggap developer belum pernah lihat app, bisa follow step-by-step
3. **Lampiri bukti** — screenshot/video > 1000 kata
4. **Cantumkan log** — console error, Firebase log, network tab
5. **Test di multiple device** sebelum lapor (kadang issue device-specific)
6. **Hindari duplikat** — search dulu di Github Issues / Trello
7. **Update setelah investigation** — kalau ketemu info baru, update bug report
8. **Tag yang relevan** — `severity:critical`, `area:mobile`, `module:chat`, dll

---

## 🗂️ Bug Tracking Locations

Pilih salah satu (atau gabungan):

- **Github Issues**: untuk dev team yang familiar dengan git workflow
- **Trello/Notion**: untuk PM-friendly tracking
- **Linear**: untuk advanced workflow
- **File markdown** `qa/bugs/BUG-XXX.md`: untuk small team

---

## 🔄 Bug Lifecycle

```
🆕 New
   ↓
🔍 Investigating (developer review)
   ↓
🛠️ In Progress (developer fixing)
   ↓
🧪 Ready for QA (developer fixed, QA verify)
   ↓
✅ Verified (QA confirm fix)
   ↓
🚀 Released (deployed ke production)
   ↓
🔒 Closed (done)
```

Status alternatif:
- ❌ **Won't Fix**: tidak akan diperbaiki (jelaskan alasannya)
- 🔁 **Duplicate**: sama dengan BUG-XXX
- ❓ **Cannot Reproduce**: developer tidak bisa reproduce, perlu detail dari tester

---

**Pakai template ini konsisten supaya QA → Dev workflow lancar.**
