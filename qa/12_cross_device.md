# 12. CROSS-DEVICE & COMPATIBILITY

> **Tujuan**: App jalan smooth di berbagai device, OS, browser, dan kondisi network.
> **Estimasi waktu**: 4 jam (paralel pakai multiple device)
> **Prasyarat**: Pool device test lengkap
> **Tester**: Multi-Device Tester

---

## 12.1 Android Versions

Test minimal 1 device per versi:

- [ ] **Android 5.0 Lollipop (API 21)** — minimum target
  - [ ] App install
  - [ ] Login
  - [ ] Check-in dengan camera + face detection
  - [ ] Notif diterima
- [ ] **Android 8 Oreo (API 26)**
  - [ ] Background service jalan
  - [ ] Notification channel berfungsi
- [ ] **Android 10 (API 29)**
  - [ ] Scoped storage compatible
  - [ ] Dark mode system follow
- [ ] **Android 11 (API 30)**
  - [ ] Background location permission baru
  - [ ] One-time permission grant
- [ ] **Android 12 (API 31)**
  - [ ] Material You theming (kalau adapt)
  - [ ] Approximate location option
- [ ] **Android 13 (API 33)**
  - [ ] Notification permission dialog baru
  - [ ] Photo Picker baru
- [ ] **Android 14 (API 34)**
  - [ ] Foreground service type baru
  - [ ] Predictive back gesture
- [ ] **Android 15** (kalau available)

## 12.2 iOS Versions (jika target aktif)

- [ ] **iOS 13+** — minimum
- [ ] **iOS 15**
- [ ] **iOS 16**
- [ ] **iOS 17 latest**

### iOS-specific
- [ ] App Tracking Transparency dialog (kalau perlu tracking)
- [ ] Permission dialog wording iOS style
- [ ] Notification badge update
- [ ] Face ID / Touch ID integration (kalau ada)

## 12.3 Device Screen Sizes

- [ ] **Small (4-5 inch)**: iPhone SE, Android compact
  - [ ] No overflow
  - [ ] Font readable
  - [ ] Tombol tap-friendly
- [ ] **Medium (5.5-6 inch)**: most common
  - [ ] Optimal layout
- [ ] **Large (6.5+ inch)**: flagship phones
  - [ ] No wasted space
  - [ ] Bento tiles proportional
- [ ] **Tablet 7-10 inch**
  - [ ] Layout adapt (multi-column kalau implement)
  - [ ] Tidak stretched seperti phone
- [ ] **Foldable** (Galaxy Z Fold, etc.)
  - [ ] Handle fold/unfold transitions
  - [ ] Layout adapt ke screen besar saat unfolded

## 12.4 Device Manufacturers

Tester perilaku spesifik vendor:

- [ ] **Samsung** (One UI) — battery saver aggressive
- [ ] **Xiaomi/Redmi** (MIUI) — autostart permission, battery whitelist
- [ ] **Oppo/Realme** (ColorOS) — battery optimization
- [ ] **Vivo** (FunTouchOS) — background restriction
- [ ] **Google Pixel** (stock Android) — baseline behavior
- [ ] **Huawei** (HarmonyOS / EMUI) — no Google Services on some → FCM mungkin gagal

### Karena masalah autostart/battery:
- [ ] App tetap dapat FCM saat killed (cek di MIUI khususnya)
- [ ] Background sync (heartbeat) tetap jalan
- [ ] Notif tidak di-silently-block

## 12.5 Browser Admin

- [ ] **Chrome** (latest) — primary
  - [ ] All features work
  - [ ] DevTools no error
- [ ] **Microsoft Edge** (latest)
  - [ ] Identik dengan Chrome (Chromium based)
- [ ] **Firefox** (latest)
  - [ ] CSS render benar (Tailwind v4 quirks)
  - [ ] FCM Web (kalau implement)
- [ ] **Safari** (latest, kalau ada user Mac)
  - [ ] Date format
  - [ ] Storage API compatible

## 12.6 Browser Versions

- [ ] Chrome 100+ → support
- [ ] Chrome 90-100 → minimal acceptable
- [ ] Chrome < 90 → tampil warning "Upgrade browser"
- [ ] Safari iOS untuk browse admin di iPad → minimal functional

## 12.7 Browser Features

- [ ] Cookies enabled → session work
- [ ] Cookies disabled → tampil error "Aktifkan cookies"
- [ ] LocalStorage enabled → preferences saved
- [ ] LocalStorage disabled → graceful (preference reset tiap session)
- [ ] Service Worker (kalau implement PWA)
- [ ] Push API (kalau implement web push)

## 12.8 Network Conditions

Test pakai Chrome DevTools throttle + real network:

- [ ] **WiFi cepat (50Mbps+)** — baseline
- [ ] **4G/LTE (10Mbps)** — usable, all features
- [ ] **3G (1.5Mbps)** — usable dengan loading state lebih lama
- [ ] **Slow 2G (250kbps)** — minimal functional, no crash
- [ ] **Offline** → graceful, banner "OFFLINE MODE"

## 12.9 Locale & Region

- [ ] System lang Indonesia → display Indonesia
- [ ] System lang English → display English (kalau translation ada)
- [ ] System lang lain → fallback Indonesia atau English
- [ ] Number format: titik vs koma decimal (id-ID pakai koma)
- [ ] Date format: id-ID `23/05/2026` atau `23 Mei 2026`
- [ ] RTL languages: tidak applicable (skip)

## 12.10 Time Zone Test

- [ ] Device timezone WIB (Asia/Jakarta) → baseline
- [ ] Device timezone WITA (Asia/Makassar) → tetap pakai WIB office time
- [ ] Device timezone WIT (Asia/Jayapura) → sama
- [ ] Device timezone UTC → testing convert
- [ ] Device timezone yang salah → app tetap pakai server time

## 12.11 Device Performance Tier

- [ ] **Low-end** (2GB RAM, slow CPU) — app usable, no crash
- [ ] **Mid-range** (4GB RAM) — smooth
- [ ] **High-end** (8GB+ RAM) — premium experience

### Low-end specific
- [ ] Tidak ada OutOfMemory crash
- [ ] Camera tidak freeze
- [ ] Face detection acceptable speed

## 12.12 Storage Constraints

- [ ] Device storage > 100MB free → install OK
- [ ] Device storage < 100MB free → install warning
- [ ] Storage penuh saat capture foto → graceful error

## 12.13 Battery States

- [ ] Battery > 20% → normal
- [ ] Battery < 20% (Battery Saver on) → background service mungkin throttled
- [ ] Battery < 5% (critical) → essential features only
- [ ] Charging vs not charging → no difference in functionality

## 12.14 Bluetooth & Other Permission

- [ ] Bluetooth permission tidak diminta (tidak applicable)
- [ ] Contacts permission tidak diminta
- [ ] Microphone permission tidak diminta (kecuali fitur audio)

---

## Device Test Matrix

| Device | OS Version | Screen | Brand | Network | All Pass? |
|--------|-----------|--------|-------|---------|-----------|
|        |           |        |       |         | ⬜         |
|        |           |        |       |         | ⬜         |
|        |           |        |       |         | ⬜         |
|        |           |        |       |         | ⬜         |

---

**Tester**: ____________________________
**Tanggal selesai**: ____________________
**Device tested**: ___
**Device compatibility issue**: ___
**Status**: ⬜ Wide compatible / ⬜ Issues on specific devices / ⬜ Critical compat issue
