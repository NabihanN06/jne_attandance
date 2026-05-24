# 13. PRE-DEPLOYMENT FINAL CHECK

> **Tujuan**: Last check sebelum tekan tombol deploy/release.
> **Estimasi waktu**: 2 jam
> **Prasyarat**: Section 1-12 selesai
> **Owner**: Release Manager / Tech Lead

---

## 13.1 Code Quality

- [ ] `npx tsc --noEmit` admin → exit 0, no errors
- [ ] `npx next lint` admin → exit 0, no errors
- [ ] `flutter analyze` mobile → "No issues found!"
- [ ] `npm run build` admin → success, no warnings
- [ ] `flutter build apk --release` → success
- [ ] `flutter build appbundle --release` → success (untuk Play Store)
- [ ] Tidak ada `console.log` / `print` debug statement tertinggal
- [ ] Tidak ada `TODO` / `FIXME` comment critical
- [ ] Tidak ada hardcoded credential
- [ ] Tidak ada feature flag yang harusnya OFF di production

## 13.2 Secret & Config Check

### Admin
- [ ] `.env.local` admin TIDAK ada di git (`git ls-files | grep .env.local`)
- [ ] `firebase-credentials-dev.json` TIDAK ada di git
- [ ] Tambah `firebase-credentials-dev.json` ke `admin/.gitignore` (preventive)
- [ ] Production env vars (`FIREBASE_PROJECT_ID`, `FIREBASE_CLIENT_EMAIL`, `FIREBASE_PRIVATE_KEY`) di Vercel/Firebase Hosting set lengkap
- [ ] `NEXT_PUBLIC_FIREBASE_*` env vars production set (6 vars)
- [ ] Firebase project ID benar (production vs staging — JANGAN salah)

### Mobile
- [ ] `key.properties` mobile TIDAK ada di git
- [ ] **Keystore backup** ke cloud/external drive (DANGER kalau hilang)
- [ ] Keystore password disimpan di password manager
- [ ] `google-services.json` (Android) sesuai production project
- [ ] `GoogleService-Info.plist` (iOS) sesuai production project

## 13.3 Database Production Setup

- [ ] Production Firestore rules deployed (`firebase deploy --only firestore:rules`)
- [ ] Production indexes deployed (`firebase deploy --only firestore:indexes`)
  - [ ] Cek di Firebase Console > Firestore > Indexes status "Enabled"
  - [ ] Tidak ada index yang masih "Building"
- [ ] Storage rules deployed (`firebase deploy --only storage`)
- [ ] Cloud Functions deployed di region `asia-southeast2` (`firebase deploy --only functions`)
- [ ] Settings `settings/system` doc terbuat dengan office config production
- [ ] Departments seeded
- [ ] Admin super user terdaftar (`scripts/setup_admin.mjs`)

## 13.4 Mobile Release Config

- [ ] `applicationId` = `id.co.jne.mtp.absensi` (production, bukan `com.example.*`)
- [ ] Version code & version name di [pubspec.yaml](user_mobile/pubspec.yaml) sesuai:
  - First release: `1.0.0+1`
  - Update berikutnya: increment versionCode (`1.0.1+2`)
- [ ] ProGuard rules tested → tidak ada crash di release mode
- [ ] App icon high-res ada di mipmap-xxxhdpi (192x192 untuk launcher)
- [ ] App icon adaptive icon (foreground + background) untuk Android 8+
- [ ] Splash screen tampil benar (no flash blank)
- [ ] App name final di AndroidManifest.xml
- [ ] App permission di manifest minimal & justified
- [ ] APK size reasonable (< 50MB ideal)
- [ ] App Bundle (.aab) bisa di-upload Play Store

## 13.5 Play Store Submission (Mobile)

- [ ] Privacy policy URL ready (hosted di public_site atau separate)
- [ ] Terms of Service URL ready
- [ ] App description short (max 80 char)
- [ ] App description full (max 4000 char)
- [ ] Screenshots phone (min 2, max 8)
  - [ ] Phone 16:9 atau 9:16
  - [ ] Tablet 7" (opsional)
  - [ ] Tablet 10" (opsional)
- [ ] Feature graphic 1024x500 px
- [ ] App icon 512x512 px (high-res)
- [ ] Category: Business / Productivity
- [ ] Content rating: dilengkapi via Play Console questionnaire
- [ ] Data safety form filled:
  - [ ] Location: collected, used for absensi
  - [ ] Photos: collected, used for face recognition
  - [ ] Personal info (name, email, phone): collected
  - [ ] Data encrypted in transit (HTTPS)
  - [ ] Data deletion request mechanism
- [ ] Target audience age: 18+
- [ ] **Internal testing track first** → verify works
- [ ] **External testing** (closed beta) → user feedback
- [ ] **Production release** setelah testing pass

## 13.6 Admin Deployment

### Build & Deploy
- [ ] Build production: `npm run build` di admin → `.next/` + `out/` generated
- [ ] Deploy ke Firebase Hosting target `admin` ATAU Vercel
- [ ] Custom domain configured (kalau ada)
- [ ] SSL/HTTPS active (auto via Vercel/Firebase)

### Firebase Auth Config
- [ ] `Authorized domains` include production URL (Firebase Console > Authentication > Settings)
- [ ] OAuth providers (kalau dipakai) configured
- [ ] Email templates customized (signup, reset password)

### Security Headers
- [ ] CSP (Content-Security-Policy) tidak break app
- [ ] X-Frame-Options: DENY/SAMEORIGIN
- [ ] X-Content-Type-Options: nosniff
- [ ] Strict-Transport-Security set
- [ ] Cookie Secure + HttpOnly + SameSite

### CORS
- [ ] API routes accept domain admin saja (kalau ada cross-origin)
- [ ] Firebase config domain whitelist

## 13.7 Cloud Functions Final

- [ ] Node runtime: minimal Node 20 (Node 22 lebih baik, Node 20 deprecated 2026-10-30)
- [ ] `firebase-functions` package up to date
- [ ] Memory allocation per function reasonable
- [ ] Timeout setting reasonable
- [ ] Logs not too verbose (cost & noise)

## 13.8 Communication & Documentation

- [ ] CHANGELOG.md updated (kalau dipakai)
- [ ] Release notes ready (untuk PM/HR)
- [ ] User guide / onboarding doc (FAQ untuk karyawan)
- [ ] Admin manual (kalau perlu)
- [ ] Tim deploy notify (Slack/Telegram/WA)
- [ ] Rollback plan ready (kalau mau revert)

## 13.9 Final Sanity Test

- [ ] 1 admin baru daftar via setup_admin.mjs → login success
- [ ] 1 karyawan baru ditambahkan → email terkirim
- [ ] Karyawan install APK → login → enroll → check-in 1x → check-out 1x
- [ ] Admin approve cuti dummy → karyawan terima notif
- [ ] Smoke test 5 menit semua flow utama

## 13.10 Cost & Quota Check

- [ ] Firebase Spark plan limit aware (atau upgrade ke Blaze)
- [ ] Firestore daily read/write quota cukup
- [ ] Storage quota cukup (foto absensi banyak)
- [ ] FCM quota gratis (unlimited)
- [ ] Cloud Functions quota OK
- [ ] Cloud Scheduler 3 jobs gratis (cukup)

---

## Release Decision

**Apakah siap release?**

- ⬜ Ya, semua check pass → APPROVED FOR RELEASE
- ⬜ Tidak, ada blocker → BLOCKED, lihat tabel issue
- ⬜ Bisa release dengan known issue minor → CONDITIONAL APPROVAL

### Known Issues (kalau ada)

| # | Issue | Severity | Workaround | Fix Planned |
|---|-------|----------|------------|-------------|
|   |       |          |            |             |

---

**Release Manager**: ____________________________
**Tanggal sign-off**: ____________________
**Versi**: Admin v____ / Mobile v____
**Deploy time scheduled**: ____________________
