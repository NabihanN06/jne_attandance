# 8. QA UI/UX & ACCESSIBILITY

> **Tujuan**: Konsistensi visual, kemudahan pakai, dan accessibility.
> **Estimasi waktu**: 3 jam
> **Prasyarat**: Admin + Mobile running
> **Tester**: UX QA Tester

---

## 8.1 Visual Consistency — Admin

- [ ] Font konsisten: Plus Jakarta Sans di semua halaman
- [ ] Spacing konsisten (padding 8/16/24/32 px)
- [ ] Warna sesuai Zen Premium palette (#121826 dark, #4F46E5 indigo, #22D3EE cyan, #FF6B00 JNE Orange)
- [ ] Icon set konsisten (lucide-react)
- [ ] Border radius konsisten (8/12/16/24 px)
- [ ] Tombol primary, secondary, danger style konsisten antar halaman
- [ ] Badge & chip style konsisten
- [ ] Card shadow & elevation konsisten
- [ ] Modal style konsisten

## 8.2 Visual Consistency — Mobile

- [ ] Font Outfit di semua screen
- [ ] Bento tile size & corner radius konsisten
- [ ] Header style konsisten antar screen
- [ ] Spacing konsisten
- [ ] Icon material/cupertino konsisten
- [ ] Tombol CTA pakai JNE Orange untuk priority action
- [ ] Background dark zen navy konsisten

## 8.3 Dark/Light Mode

### Admin
- [ ] Toggle dark mode → semua page update tanpa refresh
- [ ] Tidak ada teks invisible (kontras buruk) di salah satu mode
- [ ] Toast/modal pakai theme yang aktif
- [ ] Chart warna readable di kedua mode
- [ ] Icon tone match background

### Mobile
- [ ] Toggle dark mode di settings → semua screen update
- [ ] Tema persist setelah app restart
- [ ] System theme follow (kalau setting "auto")
- [ ] Splash screen theme-aware

## 8.4 Responsive Admin

- [ ] Desktop (1920x1080) → layout optimal
- [ ] Laptop (1366x768) → tidak ada scroll horizontal
- [ ] Tablet (768px) → sidebar collapsible / hamburger menu
- [ ] Mobile browser (375px) → minimal functional, no overlap
- [ ] Print preview (Ctrl+P) → bisa untuk report

## 8.5 Mobile Responsive (Screen Sizes)

- [ ] Small (4-5 inch, e.g., iPhone SE) — no overflow
- [ ] Medium (5.5-6 inch) — optimal
- [ ] Large (6.5+ inch) — tidak ada wasted space
- [ ] Tablet 10 inch — layout adapt
- [ ] Foldable (Galaxy Fold etc.) — handle gracefully
- [ ] Landscape orientation — adapt atau locked portrait

## 8.6 Animations

- [ ] Page transitions smooth (<300ms)
- [ ] Modal open/close < 300ms
- [ ] Tidak ada animation jank
- [ ] Respect `prefers-reduced-motion` (kalau diimplement)
- [ ] Loading shimmer/skeleton smooth
- [ ] Framer Motion / animate_do tidak overlap dengan scroll

## 8.7 Loading States

- [ ] Skeleton loader untuk list (admin & mobile)
- [ ] Spinner untuk action button (saat submit)
- [ ] Toast feedback untuk semua action (success/error)
- [ ] Empty states informatif (gambar + teks ajakan)
- [ ] Progressive image loading (blur → sharp)
- [ ] Pull-to-refresh visual feedback

## 8.8 Error States

- [ ] Error message jelas, bukan "Error 500" generik
- [ ] Retry button untuk operasi gagal
- [ ] Validation error inline di form field (red border + helper text)
- [ ] 404 page custom untuk URL salah (admin)
- [ ] Network error: "Koneksi internet bermasalah"
- [ ] Permission denied: "Akses tidak diizinkan"
- [ ] Crash recovery (Sentry / Crashlytics integrate)

## 8.9 Accessibility (a11y) — Admin

- [ ] Semua button ada `aria-label`
- [ ] Form input ada `<label>` terkait via `htmlFor`/`id`
- [ ] Heading hierarchy benar (h1 → h2 → h3, tidak skip level)
- [ ] Keyboard navigation (Tab/Shift+Tab) berfungsi
- [ ] Focus indicator visible (outline)
- [ ] Color contrast WCAG AA minimal (4.5:1 text, 3:1 UI)
- [ ] Color tidak satu-satunya pembeda (e.g., status icon + teks)
- [ ] Modal trap focus saat open
- [ ] Esc key close modal
- [ ] Screen reader test (NVDA/JAWS untuk Windows) — opsional advanced
- [ ] Image alt text untuk foto profil/asset

## 8.10 Accessibility (a11y) — Mobile

- [ ] Semantics Flutter di-set untuk komponen interaktif
- [ ] Tap target minimal 48x48 dp
- [ ] Text scale dukung sampai 200% (system font size)
- [ ] Contrast cukup
- [ ] TalkBack (Android) bisa baca elemen utama
- [ ] Tidak ada konten yang require gesture spesifik tanpa alternatif

## 8.11 Microcopy & Tone

- [ ] Bahasa konsisten (Bahasa Indonesia formal/casual sesuai brand)
- [ ] Typo nol
- [ ] Error message empati + actionable ("Mohon isi nama dulu" vs "Field required")
- [ ] Success message hangat ("Berhasil! Cuti kamu sudah dikirim ke admin")
- [ ] Tooltip jelas untuk icon yang ambigu
- [ ] Placeholder informatif bukan instruksi (instruksi pakai label)

## 8.12 Touch & Mouse Interaction

### Admin
- [ ] Hover states untuk button & link
- [ ] Cursor change (pointer untuk clickable)
- [ ] Click area sesuai visual size (no tiny target)
- [ ] Right-click konteks tidak break app

### Mobile
- [ ] Tap feedback (ripple/scale)
- [ ] Long-press handled (atau ignored)
- [ ] Swipe gesture untuk navigasi (kalau ada)
- [ ] Scroll smooth, momentum benar

## 8.13 Iconography & Imagery

- [ ] Semua icon punya makna jelas
- [ ] Icon tidak overlap dengan teks
- [ ] Foto profil placeholder default (inisial atau icon)
- [ ] Logo JNE tampil benar di header
- [ ] Aspect ratio gambar terjaga (no stretch)

## 8.14 Content Layout

- [ ] Line length text 50-80 char (readability)
- [ ] Paragraph spacing cukup
- [ ] List bullet/number konsisten
- [ ] Table responsive di mobile (scroll horizontal atau stack)
- [ ] Sticky header table saat scroll panjang

---

## Catatan Visual & UX Issue

| Modul | Issue | Severity | Screenshot |
|-------|-------|----------|------------|
|       |       |          |            |

---

**Tester**: ____________________________
**Tanggal selesai**: ____________________
**Bug visual ditemukan**: ___
**Status**: ⬜ Polished / ⬜ Need refinement / ⬜ Major UX issue
