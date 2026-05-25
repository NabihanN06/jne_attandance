# 14. POST-DEPLOYMENT MONITORING

> **Tujuan**: Monitor health setelah deploy untuk deteksi masalah dini & ambil aksi cepat.
> **Estimasi waktu**: Ongoing (24 jam, 1 minggu, 1 bulan, monthly)
> **Prasyarat**: Production deployed
> **Owner**: DevOps / On-call Engineer

---

## 14.1 First 24 Hours — Hyper Vigilance

### Tiap 2 jam cek

- [ ] Firebase Console > Functions > Logs
  - [ ] Error rate < 5%
  - [ ] No spike in execution time
  - [ ] No `Function execution took too long` errors
- [ ] Firebase Console > Firestore > Usage
  - [ ] Reads/writes growth normal
  - [ ] No infinite loop suspect
- [ ] Firebase Console > Authentication
  - [ ] New signups muncul wajar
  - [ ] No mass failed login
- [ ] Firebase Console > Storage
  - [ ] Upload count wajar
  - [ ] No spike size
- [ ] Crashlytics (kalau install)
  - [ ] Crash rate < 1%
  - [ ] No critical crash report
- [ ] User feedback channel
  - [ ] Tim support tidak banjir komplain
  - [ ] Login issues collection tidak meledak

### Aksi kalau ada masalah
- [ ] **Critical**: rollback immediate
- [ ] **High**: hotfix dalam 4 jam
- [ ] **Medium**: monitor, patch dalam 24 jam
- [ ] **Low**: backlog

## 14.2 First Week — Stability Watch

Daily check:

- [ ] Cek absensi rate (% karyawan check-in tiap hari)
  - [ ] Target: > 90% dari aktif user
  - [ ] Kalau rendah: cek apakah ada blocker (app error, network, dll)
- [ ] Cek face enrollment completion rate
  - [ ] Target: 100% karyawan aktif sudah enroll dalam 3 hari
- [ ] Cek `login_issues` collection
  - [ ] Berapa user lapor masalah?
  - [ ] Pattern: device tertentu? operasi tertentu?
- [ ] Cek `pending_sync` collection
  - [ ] Ada yang stuck offline > 24 jam?
  - [ ] `syncAttempts` tinggi → indikasi error sync
- [ ] Performance metrics di Firebase Performance Monitoring
  - [ ] App start time trend
  - [ ] Network request time
  - [ ] Custom traces (kalau implement)
- [ ] Cost report
  - [ ] Estimasi cost per bulan masih sesuai budget
  - [ ] Tidak ada spike anomali

## 14.3 First Month — Trend Analysis

Weekly check:

- [ ] Firestore document count growth reasonable
  - [ ] `attendance` ~ users × workdays
  - [ ] `leaves` proporsi normal
  - [ ] `messages` linear dengan aktivitas chat
  - [ ] `user_heartbeats` — banyak (tiap 30s), pastikan cleanup
- [ ] Storage size growth (photos)
  - [ ] Estimasi: 200KB/foto × 2/hari × users × workdays
  - [ ] Cleanup policy (kalau ada): foto > 6 bulan delete?
- [ ] FCM delivery rate
  - [ ] Target > 95%
  - [ ] Gagal delivery → cek token expired ratio
- [ ] App crash rate
  - [ ] Target < 1%
  - [ ] Cek top crashes, prioritize fix
- [ ] User retention rate
  - [ ] Daily Active Users (DAU)
  - [ ] Weekly Active Users (WAU)
- [ ] Cost vs budget
  - [ ] Firestore reads: estimasi vs actual
  - [ ] Storage cost
  - [ ] Cloud Functions invocations cost

## 14.4 Quarterly Health Check

- [ ] Audit `audit_log` collection
  - [ ] Aksi admin yang sensitive
  - [ ] Anomaly detection
- [ ] Review user feedback
  - [ ] Survey ke karyawan
  - [ ] Pain points
- [ ] Performance regression
  - [ ] Compare metrics bulan ke bulan
- [ ] Security audit
  - [ ] Cek rules masih tepat
  - [ ] Cek tidak ada exposed credential
- [ ] Update dependencies
  - [ ] Firebase SDK upgrade
  - [ ] Flutter SDK upgrade
  - [ ] Next.js patch update

## 14.5 Alerting Setup

### Critical Alerts (immediate notify)
- [ ] **Error rate > 5% / 5 menit** — pakai Cloud Monitoring
- [ ] **Firestore quota approaching 80%** — pakai Budget Alert
- [ ] **Function execution time spike > 30s avg** — Cloud Monitoring
- [ ] **Auth signup failure spike** — manual log monitor
- [ ] **App crash spike** — Crashlytics velocity alert
- [ ] **SOS alerts** — always priority (real-time admin notif)

### Warning Alerts (notify within 1h)
- [ ] **Storage > threshold** (e.g., 50GB)
- [ ] **Cost > budget threshold**
- [ ] **Login issues volume tinggi**
- [ ] **`pending_sync` doc tidak ke-sync > 1 jam**

### Setup Tools
- [ ] Google Cloud Monitoring dashboard ready
- [ ] Slack/Telegram/Email channel untuk alert
- [ ] On-call rotation jadwal
- [ ] Runbook untuk tiap alert (action plan)

## 14.6 Backup & Disaster Recovery

- [ ] Firestore backup schedule (daily/weekly)
  - [ ] Setup via `gcloud firestore export`
  - [ ] Backup ke Cloud Storage bucket terpisah
- [ ] Storage backup (foto-foto)
  - [ ] Versioning enabled?
  - [ ] Lifecycle policy (move ke cold storage setelah X bulan)
- [ ] Disaster recovery plan
  - [ ] RTO (Recovery Time Objective): berapa lama bisa down?
  - [ ] RPO (Recovery Point Objective): berapa data loss acceptable?
  - [ ] Restore procedure documented & tested

## 14.7 User Support

- [ ] Channel komunikasi user → admin (WA business, email)
- [ ] FAQ updated berdasar pertanyaan yang sering masuk
- [ ] In-app help/FAQ link ready
- [ ] Response time SLA: critical < 1 jam, normal < 24 jam

## 14.8 Incident Response

Kalau ada major incident:

1. [ ] **Detect** — alert atau user report
2. [ ] **Acknowledge** — on-call respond dalam 15 menit
3. [ ] **Diagnose** — identify root cause
4. [ ] **Mitigate** — quick fix or rollback
5. [ ] **Resolve** — permanent fix
6. [ ] **Post-mortem** — write up incident, prevention plan
7. [ ] **Communicate** — update stakeholders

### Incident Severity Levels

| Level | Definisi | Response Time | Resolution Time |
|-------|----------|---------------|-----------------|
| **P0** | Total outage, data loss | < 15 min | < 4 hours |
| **P1** | Critical feature broken | < 1 hour | < 24 hours |
| **P2** | Non-critical feature issue | < 4 hours | < 1 week |
| **P3** | Cosmetic / minor | Next sprint | Next release |

## 14.9 Continuous Improvement

- [ ] Monthly retro: apa yang bisa improved?
- [ ] Roadmap update berdasar usage data
- [ ] A/B test fitur baru (kalau scale memungkinkan)
- [ ] User interview / survey rutin

## 14.10 Monitoring Dashboard Template

Setup dashboard untuk visualize key metrics:

| Metric | Source | Frequency | Owner |
|--------|--------|-----------|-------|
| DAU | Firebase Analytics | Daily | PM |
| Check-in rate | Firestore custom query | Daily | HR |
| Crash rate | Crashlytics | Daily | DevOps |
| API error rate | Cloud Monitoring | Real-time | DevOps |
| Cost | GCP Billing | Weekly | Finance |
| Storage growth | Firebase Storage Usage | Weekly | DevOps |

---

## On-Call Contacts

| Role | Name | Contact | Backup |
|------|------|---------|--------|
| Dev Lead | __________ | __________ | __________ |
| DevOps | __________ | __________ | __________ |
| PM | __________ | __________ | __________ |
| HR (user issue) | __________ | __________ | __________ |

---

**Maintenance window**: Setiap [hari/jam], biasanya jam minim aktivitas (e.g., Sabtu 23:00-02:00 WIB)

**Status**: ⬜ Stable / ⬜ Some issues being monitored / ⬜ Active incident
