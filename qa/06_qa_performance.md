# 6. QA PERFORMANCE & STABILITY

> **Tujuan**: Pastikan aplikasi cepat, stabil, dan tidak boros resource.
> **Estimasi waktu**: 4 jam
> **Prasyarat**: Build production (bukan dev mode) + data minimal 100 records
> **Tester**: Performance QA / DevOps

---

## 6.1 Admin Panel Performance

Pakai Chrome DevTools > Performance tab + Lighthouse.

- [ ] First Contentful Paint (FCP) < 2 detik (3G connection)
- [ ] Largest Contentful Paint (LCP) < 3 detik
- [ ] Time to Interactive (TTI) < 4 detik
- [ ] First Input Delay (FID) < 100ms
- [ ] Cumulative Layout Shift (CLS) < 0.1
- [ ] Dashboard interactive < 1.5 detik (warm cache)
- [ ] List dengan 100+ karyawan → smooth scroll (60 FPS)
- [ ] List dengan 1000+ attendance → pagination/virtualization, tidak freeze
- [ ] Real-time listener tidak bocor memory (Performance Profile 1 jam idle → heap growth < 10%)
- [ ] Multiple tabs admin (3+) → tidak crash, tidak duplicate listener
- [ ] Chart rendering < 500ms
- [ ] Lighthouse Performance Score >= 80
- [ ] Lighthouse Accessibility Score >= 90
- [ ] Lighthouse Best Practices Score >= 85

## 6.2 Admin Bundle Size

- [ ] Total JS bundle (gzipped) < 500 KB
- [ ] First load JS per route < 200 KB (cek `npm run build` output)
- [ ] Image assets < 5 MB total
- [ ] No duplicate dependencies (cek webpack-bundle-analyzer)

## 6.3 Mobile Performance

Pakai Android Profiler / Flutter DevTools.

- [ ] App cold start < 3 detik
- [ ] App warm start < 1 detik
- [ ] Camera open < 2 detik
- [ ] Face detection latency < 500ms
- [ ] Upload foto 2MB → < 10 detik di 4G
- [ ] Upload foto 2MB → < 30 detik di 3G
- [ ] No memory leak (Flutter DevTools Memory tab 30 menit usage)
- [ ] Memory steady-state < 250 MB
- [ ] Battery drain reasonable (heartbeat 30s + GPS) — ukur 1 jam idle vs aktif
- [ ] No ANR (App Not Responding) saat operasi berat
- [ ] FPS smooth (60 FPS target) saat scroll riwayat
- [ ] Frame drop < 5% saat animasi

## 6.4 Mobile APK Size

- [ ] APK release size < 50 MB (ideal)
- [ ] Split APK per ABI mengurangi size per device
- [ ] App Bundle (.aab) optimal untuk Play Store
- [ ] Asset images dikompres (PNG/WebP)

## 6.5 Database Query Performance

Pakai Firebase Console > Firestore Usage.

- [ ] Dashboard stats query < 1 detik
- [ ] List karyawan dengan 100+ data < 2 detik
- [ ] Composite indexes effective (tidak ada query "scanning many docs")
- [ ] Tidak ada N+1 query pattern (cek logs)
- [ ] Real-time listener limit 30 docs untuk notif (efisien)
- [ ] Pagination per 20-50 docs untuk list besar
- [ ] Read count per session < 200 (ekonomi quota)

## 6.6 Cloud Functions Performance

Cek Firebase Console > Functions > Performance.

- [ ] First invoke (cold start) < 5 detik
- [ ] Subsequent invokes (warm) < 1 detik
- [ ] Region `asia-southeast2` (Jakarta) → latency < 200ms dari Indonesia
- [ ] Memory allocation cukup (256MB / 512MB untuk processing besar)
- [ ] Execution time per function < 10 detik (timeout 60s default)
- [ ] Concurrent execution: 100 trigger barengan → no crash
- [ ] Error rate < 1%

## 6.7 Storage Upload Performance

- [ ] Foto check-in 2MB upload → progress smooth
- [ ] Retry mechanism kalau upload putus
- [ ] Background upload (kalau implement)
- [ ] No duplicate upload kalau retry

## 6.8 FCM Delivery Performance

- [ ] Push notif latency < 5 detik (dari trigger ke device receive)
- [ ] Delivery rate > 95%
- [ ] Multi-device → semua receive paralel
- [ ] Notif group tidak overflow

## 6.9 Stress Test

- [ ] Admin: 100 karyawan check-in simultan → tidak crash, semua tercatat
- [ ] Admin: 50 SOS alert simultan → semua tampil di dashboard
- [ ] Chat: 100 pesan bolak-balik dalam 1 menit → semua sampai, urut
- [ ] Cloud Function: scheduledOvertimeCalc untuk 500 karyawan → selesai < 5 menit

## 6.10 Network Conditions

Test dengan Chrome DevTools throttle / Network Link Conditioner:

- [ ] WiFi cepat (50Mbps+) — baseline
- [ ] 4G/LTE (10Mbps) — usable
- [ ] 3G regular (1.5Mbps) — fungsional dengan loading state
- [ ] Slow 2G (250kbps) — tidak crash, tampil "loading lambat"
- [ ] Offline → graceful, ada banner "OFFLINE MODE"

---

## Metrik Hasil

| Metrik | Target | Actual | Pass? |
|--------|--------|--------|-------|
| Admin FCP | <2s | __ | ⬜ |
| Admin LCP | <3s | __ | ⬜ |
| Lighthouse Perf | >=80 | __ | ⬜ |
| Mobile cold start | <3s | __ | ⬜ |
| Camera open | <2s | __ | ⬜ |
| Memory steady-state | <250MB | __ | ⬜ |
| Upload 2MB 4G | <10s | __ | ⬜ |
| FCM latency | <5s | __ | ⬜ |
| APK size | <50MB | __ | ⬜ |

## Catatan

```
[Tulis bottleneck atau rekomendasi optimization]
```

---

**Tester**: ____________________________
**Tanggal selesai**: ____________________
**Status**: ⬜ Acceptable / ⬜ Need optimization / ⬜ Critical performance issue
