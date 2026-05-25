# 🚚 JNE MARTAPURA — Sistem Absensi Terintegrasi

> **Update Presentasi v2.0** — Mei 2026
> Format: Marp Markdown (bisa di-render jadi PDF/PPTX via VS Code Marp extension)
>
> Cara pakai:
> 1. Install extension **Marp for VS Code**
> 2. Buka file ini di VS Code
> 3. Klik tombol "Open Preview" (top-right) — slide langsung tampil
> 4. Export: klik "..." → Export Slide Deck → pilih PDF / PPTX / HTML

---

<!-- Hapus baris di atas saat presentasi. Bagian di bawah ini = slides. -->

---
marp: true
theme: default
class:
  - lead
  - invert
paginate: true
backgroundColor: #121826
color: #F8FAFC
header: 'JNE Martapura · Attendance System'
footer: 'v2.0 · Mei 2026 · Confidential'
style: |
  section {
    font-family: 'Plus Jakarta Sans', sans-serif;
  }
  h1 { color: #22D3EE; }
  h2 { color: #4F46E5; }
  h3 { color: #FF6B00; }
  strong { color: #FF6B00; }
  code { background: rgba(255,255,255,0.1); padding: 2px 6px; border-radius: 4px; }
  table { font-size: 0.85em; }
  .columns { display: grid; grid-template-columns: repeat(2, 1fr); gap: 1.5rem; }
  .stat-big { font-size: 4rem; font-weight: 900; color: #FF6B00; line-height: 1; }
---

<!-- _class: lead -->

# 🚚 JNE Martapura
## Sistem Absensi Terintegrasi

### Update v2.0 — Mei 2026

**Zen Premium Command Center**
Mobile + Web Dashboard + Cloud Backend

---

## 📊 Dari Mana Kita Mulai

### Masalah Sebelumnya
- ❌ Absensi manual via spreadsheet
- ❌ Tidak ada verifikasi lokasi karyawan
- ❌ Foto bukti hilang / tidak terlacak
- ❌ Pengajuan cuti via WhatsApp tidak terstruktur
- ❌ Komunikasi admin ↔ karyawan terfragmentasi
- ❌ Tidak ada laporan otomatis bulanan

### Tujuan Sistem
✅ **Single source of truth** untuk semua data attendance
✅ **Real-time** monitoring HR
✅ **Mobile-first** untuk 50+ karyawan lapangan

---

## 🏗️ Arsitektur Sistem

```
┌─────────────────────────────────────────────────┐
│         JNE ATTENDANCE ECOSYSTEM                 │
├──────────────┬──────────────┬───────────────────┤
│  📱 MOBILE   │  💻 ADMIN    │  ☁️ FIREBASE      │
│  (Flutter)   │  (Next.js 16)│  Backend          │
│              │              │                   │
│  Karyawan    │  HR + Mgr    │  • Firestore      │
│  50+ user    │  Dashboard   │  • Auth           │
│              │              │  • Storage        │
│              │              │  • FCM            │
│              │              │  • 8 Functions    │
└──────────────┴──────────────┴───────────────────┘
              ↕ Real-time sync ↕
```

**Region**: `asia-southeast2` (Jakarta) — latency < 200ms

---

## 🛠️ Tech Stack

<div class="columns">

### Frontend Admin
- Next.js **16.1** (App Router)
- React **19.2**
- TypeScript **5**
- Tailwind CSS **v4**
- Framer Motion + animejs
- Recharts (analytics)

### Mobile App
- Flutter **3.10+**
- Provider state management
- Firebase SDK
- Google ML Kit (face detection)
- Geolocator (GPS)
- SQLite (offline cache)

</div>

### Backend
**Firebase**: Firestore · Auth · Storage · Cloud Functions (Node 20) · FCM

---

## ⭐ Highlights Update v2.0 (vs v1.0)

| Feature | v1.0 | v2.0 ✨ |
|---------|------|---------|
| Theme System | Light only | **Dark + Light systemic** |
| Login Issue Report | — | ✅ Anonymous form di login screen |
| First-Login Password | Default | ✅ **Force change** + validasi |
| Play Store Ready | Debug signing | ✅ **Release signing + ProGuard** |
| Dispute Loop | One-way | ✅ **Two-way thread + rating + FAQ** |
| Custom Jam Kerja | Per-system | ✅ **Per-karyawan saat tambah** |
| Onboarding Email | Manual | ✅ **Auto-send Cloud Function** |
| Heartbeat/Presence | — | ✅ **Online status real-time** |
| Audit fixes | — | ✅ Crash, race, timezone, perf |

---

## 📱 Mobile App — 15 Fitur Utama

<div class="columns">

### Authentication
- Login + force change password
- **Lapor masalah login** (anonymous)
- Face enrollment (ML Kit)

### Daily Operations
- Check-in / Check-out
- **Geofence Haversine**
- **Offline mode** + auto-sync
- Riwayat absensi
- Statistik bulanan
- Chat 2-way dengan admin
- Notifikasi (FCM + in-app)
- Broadcast

</div>

### Self-Service
Cuti · Lembur · Dispute · **FAQ (14 entries)** · Profil · Dark/Light mode

---

## 💻 Admin Panel — 18 Modul

<div class="columns">

### Core HR
- Dashboard real-time
- Karyawan (CRUD + custom shift)
- Absensi monitoring
- Cuti approval
- Departemen
- Jam Kerja / Shift

### Operations
- Edit-request
- Overtime request
- Face enrollment monitor
- Login issues
- Head units
- Maintenance mode

</div>

### Engagement
Chat · Broadcast · Calendar (auto reminder) · Analytics · Reports (PDF/Excel) · Settings

---

## 🔄 Alur Operasional — Contoh Absensi

```
Karyawan tap "Check In"
       ↓
[GeofenceService] Haversine → cek distance ke kantor
       ↓ (within 500m)
[Camera] open → ML Kit face detection
       ↓ (faceScore >= threshold)
[Firestore write] attendance/{userId}_{date}
       ↓
[Cloud Function] onAttendanceCreated trigger
       ↓
[Admin Dashboard] subscribeToTodayAttendance
       ↓
Real-time update tanpa refresh — < 2 detik
```

**Fallback offline**: SQLite + `pending_sync` → auto-sync saat online

---

## ☁️ Backend — 8 Cloud Functions

| Function | Trigger | Fungsi |
|----------|---------|--------|
| `onEmployeeCreated` | Firestore | Auto-create Auth + notif admin |
| `sendOnboardingEmail` | Firestore | Email kredensial + link APK |
| `onLeaveStatusUpdate` | Firestore | FCM push approve/reject |
| `onAttendanceCreated` | Firestore | Logging absensi |
| `onUserProfileUpdated` | Firestore | Sync profile |
| `onFaceEnrolled` | Firestore | Notif admin enrollment |
| `onAttendanceFailed` | Callable | Notif gagal face 3x |
| `scheduledOvertimeCalc` | PubSub 23:00 WIB | Kalkulasi overtime harian |

**Region**: `asia-southeast2` · **Runtime**: Node 20

---

## 🗄️ Database — 21 Koleksi Firestore

<div class="columns">

### Core Data
- `users` — karyawan + admin
- `attendance` — daily logs
- `leaves` — cuti
- `overtime` — lembur
- `shifts` / `jamKerja`
- `departments`

### Communication
- `messages` — chat 2-way
- `chats/{id}/typing` — typing
- `broadcasts` — pengumuman
- `adminNotifications`
- `userNotifications`

</div>

### Operational
`user_heartbeats` · `pending_sync` · `disputes` · `edit_requests` · `login_issues` · `events` · `fcm_tokens` · `audit_log` · `settings/system`

---

## 🔐 Security Highlights

### Layer 1: Authentication
- Firebase Auth (email + password)
- Session cookie (HttpOnly, Secure, SameSite)
- **First-login force password change**
- Rate limiting (Firebase built-in)

### Layer 2: Authorization
- **Firestore Security Rules** granular per-collection
- Role-based: admin/superadmin/employee
- API routes verify session + role admin

### Layer 3: Data
- **Geofence + Face Score** double verification absensi
- Mock GPS detection
- Audit log untuk semua aksi admin
- Field size limit untuk `login_issues` (anti-spam)

---

## 🎨 Design — Zen Premium Palette

<div class="columns">

### Warna
- `#121826` — Deep Navy (dark BG)
- `#F8FAFC` — Off-White (light BG)
- `#4F46E5` — Indigo (primary)
- `#22D3EE` — Cyan (secondary)
- `#FF6B00` — JNE Orange (CTA)

### Style per Surface
- **Dashboard**: Dark Crimson Gaming
- **Chat**: Clean Green Travigo
- **Mobile**: Bento UI Zen Premium

</div>

**Typography**: Plus Jakarta Sans (admin) · Outfit (mobile)
**Mode**: Dark/Light systemic — semua screen tema-aware ✨

---

## 📊 Statistik Project

<div class="columns">

<div>

### Codebase
- **3.045 baris** QA checklist (16 section)
- **1.011 baris** dokumentasi teknis
- **20+ screens** mobile
- **30 routes** admin
- **20+ custom hooks** business logic
- **40+ TypeScript interfaces**

</div>

<div>

### Build Output
- Admin: **50 static pages** (`out/`)
- Mobile APK: **84 MB** release signed
- Build time admin: < 20s
- Build time mobile: ~3 menit
- Lighthouse perf: target 80+

</div>

</div>

---

## ✅ Quality Assurance — 16 Section

```
qa/
├── README.md                      ← Index + status template
├── 01_pre_test_setup.md           ← Akun, device, tools
├── 02_qa_admin_functional.md      ← 16 modul admin
├── 03_qa_mobile_functional.md     ← 16 modul mobile
├── 04_qa_integration.md           ← 8 flow E2E
├── 05_qa_security.md              ← 11 area security
├── 06_qa_performance.md           ← Performance + metrics
├── 07_qa_offline_edge.md          ← 12 edge cases
├── 08_qa_ui_ux.md                 ← UI/UX + a11y
├── 09 → 16 ...                    ← Data, FCM, Devices, dll
└── sign_off.md                    ← Final approval
```

**Total 18 file** — bisa di-assign paralel per tester role

---

## 🚀 Status Deployment

<div class="columns">

### ✅ Sudah Live
- Firestore Rules
- 12 Composite Indexes
- Storage Rules
- 8 Cloud Functions
- Settings doc seeded

### ⏳ Siap Deploy
- Admin Panel (Firebase Hosting / Vercel)
- Mobile APK ke Play Store (Internal Testing first)
- 1 index tambahan (`messages.chatId+createdAt ASC`)

</div>

### Pre-Release Checks
- ✅ TypeScript admin: 0 errors
- ✅ ESLint admin: 0 errors (179 style warnings)
- ✅ Production build admin: success
- ✅ Flutter analyze: No issues!
- ✅ APK release build: 84.3 MB signed

---

## 🎬 Demo Flow — Onboarding Karyawan Baru

### Skenario 30 menit live demo

1. **Admin** buka /employees → "Tambah Karyawan"
2. Isi: Budi Santoso, Kurir, personal@gmail.com
3. **Submit** → Email otomatis terkirim (Cloud Function)
4. **Budi** install APK → buka email → login
5. **Force change password** screen muncul
6. Ganti password → grant permission → enroll wajah
7. **Admin** dapat notif "Budi selesai enrollment"
8. Budi pergi ke kantor → tap Check-in
9. Geofence ✅ → Camera ✅ → Face score ✅
10. **Admin Dashboard** real-time update — record muncul instant

**End-to-end**: < 1 jam dari add karyawan ke absen pertama 🚀

---

## 📈 Metric Sukses (Target 1 Bulan)

<div class="columns">

<div>

### Adoption
- **100%** karyawan aktif install APK
- **100%** selesai face enrollment dalam 3 hari
- **>95%** absensi tercatat tepat waktu

### Engagement
- **>90%** check-in rate harian
- **<5%** offline-sync failure
- Avg response chat admin: < 4 jam

</div>

<div>

### Technical
- **>99%** uptime
- **<5s** FCM push latency
- **<1%** app crash rate
- **0** Critical bug post-release

### Business
- HR time saving: **>50%** (vs manual)
- Disputes resolution: **<24 jam** avg
- Cost: dalam budget Firebase

</div>

</div>

---

## 🛣️ Roadmap Selanjutnya

### Q3 2026 (Juni–September)
- 🤖 **AI Analytics** — prediksi pola terlambat
- 📊 **Custom Dashboard** per role
- 🌐 **Multi-bahasa** (Indonesia + English)
- 📍 **Multi-office** support

### Q4 2026 (Oktober–Desember)
- 📶 **NFC Integration** (backup absen)
- 📄 **Auto-Payroll** generation
- ✅ **Approval workflow** chain (multi-step)
- 🔔 **Slack/Teams** integration

### 2027
- 🎯 **Biometric upgrade** — fingerprint backup
- 🏆 **Leaderboard** karyawan rajin
- 📱 **iOS** release

---

## 🤔 FAQ untuk Stakeholder

### Q: Berapa biaya operational per bulan?
A: Estimasi $20-50/bulan (Firebase Spark/Blaze hybrid) untuk 50 karyawan. Storage cost growth tergantung retention foto.

### Q: Data karyawan aman?
A: ✅ Firestore Security Rules granular, ✅ Auth Firebase enterprise, ✅ Storage rule terbatas, ✅ Audit log lengkap.

### Q: Bagaimana kalau Firebase down?
A: Offline mode aktif (SQLite cache), data sync saat online. Disaster recovery plan ready.

### Q: Skala maksimal?
A: Tested untuk **50 karyawan**. Architecture support hingga **500+** tanpa perubahan signifikan (Firestore auto-scale).

### Q: Bisa add fitur baru cepat?
A: ✅ Modular hook-based architecture. Estimasi 1-2 minggu per fitur medium.

---

## 👥 Tim & Kontak

### Development
**Lead Developer**: Zainul Arkaan
**Email**: zainaril13@gmail.com

### Stakeholder
- **Owner**: JNE Martapura
- **End Users**: 50+ karyawan operasional
- **Admin Users**: HR + Manager (2-5 user)

### Repository
- Path: `c:/Users/USER/jne_attandance/`
- Firebase Project: `admin-absensi-jne-mtp`

---

## 📚 Dokumentasi Terkait

| Dokumen | Fungsi |
|---------|--------|
| [README.md](README.md) | Overview project |
| [DOKUMENTASI_PROJECT.md](DOKUMENTASI_PROJECT.md) | Technical docs 1.000+ baris |
| [FIRESTORE_SCHEMA.md](FIRESTORE_SCHEMA.md) | Schema database lengkap |
| [QA_CHECKLIST.md](QA_CHECKLIST.md) | QA master checklist |
| [qa/](qa/) | 16 section QA terpisah |
| [PANDUAN_KURIR.md](PANDUAN_KURIR.md) | User guide kurir |

---

<!-- _class: lead -->

# 🎉 Terima Kasih

## Siap untuk Production Release 🚀

### Pertanyaan?

**Live demo tersedia** — APK installer + admin URL siap dibagikan
ke tim pilot setelah approval.

> *"Closed-Loop Telemetry · Real-time Operations · Zen Premium"*

---

# 📎 LAMPIRAN

Bagian di bawah ini = **slide tambahan / appendix**.
Pakai kalau ada pertanyaan teknis spesifik dari audience.

---

## Appendix A — Database Schema Detail

```typescript
// Contoh: koleksi attendance
{
  userId: string                  // Auth UID
  date: string                    // "YYYY-MM-DD"
  status: 'present' | 'late' | 'absent' | 'leave' | 'overtime'

  checkIn: {
    time: Timestamp
    latitude: number
    longitude: number
    distance: number              // meter dari kantor
    faceScore: number             // 0-100
    photoUrl?: string             // Firebase Storage
  }

  checkOut?: { ... }              // Sama strukturnya

  totalWorkMinutes?: number
  overtimeMinutes?: number
  lateMinutes?: number
}
```

**DocID**: `{userId}_{date}` → idempotent, no double check-in

---

## Appendix B — Firestore Rules (Sample)

```javascript
match /attendance/{attendanceId} {
  // GET longgar (untuk transaction.get pada doc baru)
  allow get: if isAuth();

  // LIST: hanya owner atau admin
  allow list: if isAuth() && (
    resource.data.userId == request.auth.uid || isAdmin()
  );

  // CREATE: hanya owner sendiri
  allow create: if isAuth() &&
    request.resource.data.userId == request.auth.uid;
}

match /login_issues/{issueId} {
  // SPECIAL: tanpa auth (user belum login)
  // Validasi field size untuk mitigasi spam
  allow create: if
    request.resource.data.name.size() <= 100 &&
    request.resource.data.description.size() >= 10;
}
```

---

## Appendix C — Geofence Formula

### Haversine Distance Calculation

```dart
double calculateDistance(
  double lat1, double lng1,
  double lat2, double lng2,
) {
  const R = 6371000; // radius bumi (meter)
  final dLat = _toRad(lat2 - lat1);
  final dLng = _toRad(lng2 - lng1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
            cos(_toRad(lat1)) * cos(_toRad(lat2)) *
            sin(dLng / 2) * sin(dLng / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return R * c;
}
```

**Validasi**: `distance <= settings.office.radiusMeters` (default 500m)

---

## Appendix D — Cloud Function Sample

### Send Push to All User Devices

```typescript
async function sendPushToUser(userId, payload) {
  const tokens = await db.collection('fcm_tokens')
    .where('userId', '==', userId).get();

  const res = await messaging.sendEachForMulticast({
    tokens: tokens.docs.map(d => d.id),
    notification: { title: payload.title, body: payload.body },
    android: {
      priority: 'high',
      notification: { channelId: 'high_importance_channel' }
    }
  });

  // Auto-cleanup token expired
  res.responses.forEach((r, i) => {
    if (!r.success && isExpiredError(r.error?.code)) {
      db.collection('fcm_tokens').doc(tokens[i].id).delete();
    }
  });
}
```

---

## Appendix E — Performance Targets

| Metric | Target | Sumber |
|--------|--------|--------|
| Admin FCP | < 2 detik | Lighthouse 3G |
| Admin LCP | < 3 detik | Lighthouse 3G |
| Admin TTI | < 4 detik | Lighthouse 3G |
| Lighthouse Perf | ≥ 80 | Production build |
| Mobile cold start | < 3 detik | Real device |
| Camera open | < 2 detik | Real device |
| Face detection | < 500ms | ML Kit on-device |
| Upload 2MB foto (4G) | < 10s | Real network |
| FCM latency | < 5 detik | End-to-end |
| Memory steady | < 250 MB | Flutter DevTools |
| APK size | < 50 MB (ideal) | Build output |
| Crash rate | < 1% | Crashlytics |

---

## Appendix F — Cost Estimation

### Firebase Spark Plan (Free Tier)
**Untuk 50 user, estimasi monthly usage**:

| Service | Free Quota | Estimated Usage | Status |
|---------|-----------|-----------------|--------|
| Firestore reads | 50K/day | ~30K/day | ✅ Within |
| Firestore writes | 20K/day | ~10K/day | ✅ Within |
| Storage | 5 GB | ~3 GB (foto 6 bulan) | ✅ Within |
| Cloud Functions | 125K invokes/month | ~50K | ✅ Within |
| FCM | Unlimited | All push | ✅ Free |
| Auth | Unlimited | All login | ✅ Free |

**Verdict**: Spark Plan **CUKUP** untuk 50 user. Upgrade ke **Blaze** kalau:
- Scale > 200 user
- Storage > 5GB
- Custom domain
- Cloud Run / external API calls

---

## Appendix G — Rollback Plan

### Kalau ada Critical Bug Post-Release

#### Cloud Functions
```bash
# Revert ke versi sebelumnya via Git
cd admin/functions
git revert HEAD
npm run build
firebase deploy --only functions
```

#### Admin Panel
```bash
# Re-deploy versi sebelumnya
git checkout <previous-tag>
npm run build
firebase deploy --only hosting:admin
```

#### Mobile App
- **Tidak bisa rollback** di Play Store langsung
- **Pause rollout** di Play Console
- Push hotfix versi baru (versionCode +1)
- Komunikasi via in-app banner

#### Database
- Restore dari backup harian (`gcloud firestore import`)
- RTO target: < 4 jam
- RPO target: < 24 jam

---

## Appendix H — Skenario Test E2E

### 8 Skenario Mandatory (Smoke Test)

| # | Skenario | Goal |
|---|----------|------|
| A | New Employee Onboarding | Nol → absen pertama < 1 jam |
| B | Cuti Sakit Mendadak | Submit → approve → notif |
| C | Karyawan di Luar Geofence | Tolak + pesan jelas |
| E | Offline Check-out | Auto-sync saat online |
| F | Multi-Device Login | FCM ke semua device |
| G | Bulk Karyawan + Report | 50 user, export PDF/Excel |
| H | Year-End Boundary | Date/timezone konsisten |

**Detail step-by-step**: lihat [qa/16_test_scenarios.md](qa/16_test_scenarios.md)

---

## Appendix I — Riwayat Versi

```
v1.0 (Mar 2026)  ─ Initial release, basic CRUD
                   Dashboard, employees, attendance

v1.1 (Apr 2026)  ─ Chat 2-way
                   Calendar event + reminder
                   Audit log

v1.2 (Apr 2026)  ─ Settings system doc
                   Geofence configurable
                   Department rules

v2.0 (Mei 2026)  ─ ⭐ UI Overhaul: Dark/Light systemic
                   ⭐ Dispute Loop (two-way + rating)
                   ⭐ First-login password + Lapor Admin
                   ⭐ Play Store ready (release signing)
                   ⭐ Custom jam kerja per karyawan
                   ⭐ Audit fixes (crash, race, timezone)

v2.1 (planned)   ─ Auto-payroll, multi-language
v3.0 (planned)   ─ AI analytics, NFC backup, iOS
```

---

<!-- _class: lead -->

# 🚀 Ready to Ship

## v2.0 — Production Release Approved

**Mobile APK**: ✅ Built & Signed (84.3 MB)
**Admin Panel**: ✅ Build Success (50 static pages)
**Backend**: ✅ Deployed (Functions + Rules + Storage)
**QA**: ✅ 16 sections + 8 E2E scenarios ready

---

### 🎬 Next Step: Live Demo & Pilot Test

Internal Testing → Closed Beta (5 karyawan) → Full Rollout

---

**JNE Martapura · Sistem Operasional**
*Zen Premium · Closed-Loop Telemetry · Built with ❤️*
