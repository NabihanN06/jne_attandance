# 🧪 QA CHECKLIST — JNE Martapura Attendance System

> Master index untuk QA checklist yang sudah dipecah per section.
> Setiap file bisa dikerjain paralel oleh tester berbeda.
> Last update: 2026-05-23

---

## 📋 16 Section + Sign-off

| # | File | Section | Estimasi Waktu | Tester |
|---|------|---------|----------------|--------|
| 1 | [01_pre_test_setup.md](01_pre_test_setup.md) | Pre-Test Setup | 2 jam | Setup |
| 2 | [02_qa_admin_functional.md](02_qa_admin_functional.md) | QA Admin Panel Functional | 1 hari | Tester Web |
| 3 | [03_qa_mobile_functional.md](03_qa_mobile_functional.md) | QA Mobile App Functional | 1 hari | Tester Mobile |
| 4 | [04_qa_integration.md](04_qa_integration.md) | Integration Cross-System E2E | 4 jam | Senior Tester |
| 5 | [05_qa_security.md](05_qa_security.md) | Security & Permission | 4 jam | Security Tester |
| 6 | [06_qa_performance.md](06_qa_performance.md) | Performance & Stability | 4 jam | Performance Tester |
| 7 | [07_qa_offline_edge.md](07_qa_offline_edge.md) | Offline & Edge Cases | 3 jam | Tester Mobile |
| 8 | [08_qa_ui_ux.md](08_qa_ui_ux.md) | UI/UX & Accessibility | 3 jam | UX Tester |
| 9 | [09_qa_data_validation.md](09_qa_data_validation.md) | Data Validation | 2 jam | Tester Web/Mobile |
| 10 | [10_qa_cloud_functions.md](10_qa_cloud_functions.md) | Cloud Functions | 2 jam | Backend Tester |
| 11 | [11_qa_notification_fcm.md](11_qa_notification_fcm.md) | Notification (FCM) | 2 jam | Tester Mobile |
| 12 | [12_cross_device.md](12_cross_device.md) | Cross-Device & Compatibility | 4 jam | Tester Multi-Device |
| 13 | [13_pre_deployment.md](13_pre_deployment.md) | Pre-Deployment Final Check | 2 jam | Release Manager |
| 14 | [14_post_deployment.md](14_post_deployment.md) | Post-Deployment Monitoring | Ongoing | DevOps |
| 15 | [15_bug_report_template.md](15_bug_report_template.md) | Bug Report Template | — | Semua Tester |
| 16 | [16_test_scenarios.md](16_test_scenarios.md) | Test Data Skenario E2E | 4 jam | Senior Tester |
| — | [sign_off.md](sign_off.md) | Final Sign-off & Approval | — | QA Lead + PM |

---

## 🎯 Cara Pakai

### Untuk Tester Individu
1. Buka file section yang ditugaskan ke kamu
2. Tandai per item: ✅ pass / ❌ fail / ⏭️ skip
3. Tulis catatan kalau ada
4. Bug yang ketemu → buat laporan baru pakai template di [15_bug_report_template.md](15_bug_report_template.md)
5. Setelah selesai semua item → tandatangan di bagian bawah file

### Untuk QA Lead
1. Assign tester per section sesuai role
2. Track progress via Github Issues / Trello / Notion (per section = 1 task)
3. Daily standup review status per section
4. Setelah semua section approved → isi [sign_off.md](sign_off.md)

### Smoke Test Cepat (kalau waktu mepet)
Cuma jalanin [16_test_scenarios.md](16_test_scenarios.md) — 8 skenario E2E realistik. Kalau semua skenario pass, app **minimum viable** untuk release. Section lain tetap harus diselesaikan secara paralel.

---

## 📊 Status Overview Template

Untuk daily reporting, copy template ini ke daily report:

```markdown
## QA Status — [TANGGAL]

| Section | Tester | % Done | Status | Bugs Found | Blockers |
|---------|--------|--------|--------|------------|----------|
| 01 Pre-Test Setup       | __ | 0%  | ⏸️ | 0 | — |
| 02 Admin Functional     | __ | 0%  | ⏸️ | 0 | — |
| 03 Mobile Functional    | __ | 0%  | ⏸️ | 0 | — |
| 04 Integration E2E      | __ | 0%  | ⏸️ | 0 | — |
| 05 Security             | __ | 0%  | ⏸️ | 0 | — |
| 06 Performance          | __ | 0%  | ⏸️ | 0 | — |
| 07 Offline & Edge       | __ | 0%  | ⏸️ | 0 | — |
| 08 UI/UX & a11y         | __ | 0%  | ⏸️ | 0 | — |
| 09 Data Validation      | __ | 0%  | ⏸️ | 0 | — |
| 10 Cloud Functions      | __ | 0%  | ⏸️ | 0 | — |
| 11 Notification FCM     | __ | 0%  | ⏸️ | 0 | — |
| 12 Cross-Device         | __ | 0%  | ⏸️ | 0 | — |
| 13 Pre-Deployment       | __ | 0%  | ⏸️ | 0 | — |

Legenda: ⏸️ Not started · 🔄 In progress · ✅ Done · 🚫 Blocked
```

---

## 🚨 Klasifikasi Bug Severity

| Severity | Definisi | Contoh | Aksi |
|----------|----------|--------|------|
| 🔴 **Critical** | App crash, data loss, security breach, blocker total | Login gak bisa, absensi tidak tersimpan, foto bocor public | **STOP RELEASE** sampai fix |
| 🟠 **High** | Fitur utama tidak berfungsi tapi ada workaround | Cuti approve tidak kirim FCM, chat tidak real-time | Fix sebelum release |
| 🟡 **Medium** | Fitur sekunder error, UX issue | Toast tidak muncul, sort tidak akurat | Fix kalau ada waktu / patch berikutnya |
| 🟢 **Low** | Cosmetic, typo, minor UX | Spasi salah, warna tidak konsisten | Patch berikutnya |

---

## 📎 Referensi

- [../DOKUMENTASI_PROJECT.md](../DOKUMENTASI_PROJECT.md) — Dokumentasi teknis lengkap
- [../FIRESTORE_SCHEMA.md](../FIRESTORE_SCHEMA.md) — Schema database
- [../QA_CHECKLIST.md](../QA_CHECKLIST.md) — Master file (full version dalam 1 file)
- [../README.md](../README.md) — Overview project

---

**Dibuat untuk QA JNE Martapura** | Edisi Pre-Release v1.0
