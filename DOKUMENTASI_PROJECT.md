# 📚 DOKUMENTASI LENGKAP — JNE MARTAPURA ATTENDANCE SYSTEM

> Dokumentasi komprehensif **backend + frontend admin panel + mobile app**.
> Last update: 2026-05-23
> Project Firebase: `admin-absensi-jne-mtp` | Region Functions: `asia-southeast2` (Jakarta)



## 📑 DAFTAR ISI

1. [Arsitektur Umum](#1-arsitektur-umum)
2. [Backend (Firebase)](#2-backend-firebase)
   - [Tech Stack](#21-tech-stack-backend)
   - [Database Schema — 21 Koleksi Firestore](#22-database-schema--21-koleksi-firestore)
   - [Firestore Security Rules](#23-firestore-security-rules)
   - [Cloud Functions](#24-cloud-functions)
   - [API Routes Next.js](#25-api-routes-nextjs)
3. [Admin Panel (Next.js)](#3-admin-panel-nextjs)
   - [Tech Stack](#31-tech-stack-admin)
   - [Struktur Folder](#32-struktur-folder-admin)
   - [20+ Custom Hooks](#33-custom-hooks-business-logic)
   - [Context Providers](#34-context-providers)
   - [Library Files](#35-library-files)
   - [TypeScript Types](#36-typescript-types-utama)
   - [Fitur](#37-fitur-admin-panel)
4. [Mobile App (Flutter)](#4-mobile-app-flutter)
   - [Tech Stack](#41-tech-stack-mobile)
   - [Struktur Folder](#42-struktur-folder-mobile)
   - [AppProvider Methods](#43-appprovider--method-utama)
   - [Service Utilities](#44-service-utilities-mobile)
   - [Fitur](#45-fitur-mobile-app)
5. [Alur Data Operasional](#5-alur-data-operasional-10-flow)
6. [Design System (Zen Premium)](#6-design-system-zen-premium)
7. [Deployment & Scripts](#7-deployment--scripts)
8. [Security Highlights](#8-security-highlights)
9. [Riwayat Commit Penting](#9-riwayat-commit-penting)
10. [FAQ — Pertanyaan Umum](#10-faq--pertanyaan-umum)

---

## 1. ARSITEKTUR UMUM

Project ini adalah **ekosistem absensi terintegrasi** yang terdiri dari **3 komponen utama**:

```
┌─────────────────────────────────────────────────────────────┐
│                    JNE ATTENDANCE SYSTEM                     │
├──────────────────┬──────────────────┬───────────────────────┤
│  📱 MOBILE APP   │  💻 ADMIN PANEL  │  ☁️ FIREBASE BACKEND  │
│  (Flutter)       │  (Next.js 16)    │  (Firestore + Auth)   │
│  Karyawan        │  HR/Manajemen    │  + Cloud Functions    │
└──────────────────┴──────────────────┴───────────────────────┘
```

- **Project Firebase ID**: `admin-absensi-jne-mtp`
- **Region Cloud Functions**: `asia-southeast2` (Jakarta)
- **Path Project**:
  - [user_mobile/](user_mobile/) — Flutter app untuk karyawan
  - [admin/](admin/) — Next.js dashboard untuk admin
  - [admin/functions/](admin/functions/) — Firebase Cloud Functions (server-side logic)

**Design Philosophy**: *Zen Premium Command Center* — Closed-Loop Telemetry antara mobile unit & command tower (admin).

> Catatan: README menyebut PostgreSQL via Data Connect, tapi implementasi aktual murni Firestore.

---

## 2. BACKEND (FIREBASE)

### 2.1 Tech Stack Backend

| Service | Fungsi |
|---------|--------|
| **Firebase Auth** | Login/Authentication (email + password) |
| **Cloud Firestore** | Database NoSQL real-time (semua data: user, attendance, leave, dll) |
| **Firebase Storage** | Penyimpanan foto wajah (face enrollment) & bukti absensi |
| **Firebase Cloud Messaging (FCM)** | Push notification ke mobile + admin |
| **Cloud Functions** (Node.js v1) | Server-side automation, trigger Firestore, scheduled jobs |
| **Firebase Hosting / App Hosting** | Deployment admin panel |

### 2.2 Database Schema — 21 Koleksi Firestore

Schema lengkap di [FIRESTORE_SCHEMA.md](FIRESTORE_SCHEMA.md). Ringkasan koleksi utama:

| # | Koleksi | Fungsi | Field Kunci |
|---|---------|--------|-------------|
| 1 | `users` | Profil karyawan & admin | uid, name, email, employeeId(NIK), department, position, role, faceRegistered, fcmToken, deviceId, deviceModel, registeredDeviceId, photoUrl, joinDate, contractType, isActive, firstLogin, personalEmail |
| 2 | `shifts` / `jamKerja` | Definisi jam kerja | name, checkInTime("HH:mm"), checkOutTime, toleranceMinutes, workingDays[], color, isActive |
| 3 | `attendance` | Catatan absensi harian (**docId: `{userId}_{date}`**) | userId, employeeName, employeeId, department, jamKerjaId, date("YYYY-MM-DD"), status, checkIn{time, lat, lng, distance, faceScore, photoUrl}, checkOut{...}, totalWorkMinutes, overtimeMinutes, lateMinutes, notes |
| 4 | `leaves` | Pengajuan cuti | userId, type(sick/annual/personal/emergency/other), status(pending/approved/rejected), startDate, endDate, totalDays, reason, documentUrl, rejectionReason, reviewedBy, reviewedAt |
| 5 | `overtime` | Pengajuan lembur | userId, date, durationHours, reason, status |
| 6 | `settings/system` | **Single doc** konfigurasi | office{name, address, lat, lng, radiusMeters}, attendance{maxFaceAttempts, faceSimilarityThreshold, allowOfflineAttendance}, notifications{...}, company{companyName, hrEmail, hrPhone, appDownloadUrl} |
| 7 | `adminNotifications` | Notif untuk dashboard admin | type, title, message, employeeId, employeeName, relatedId, isRead |
| 8 | `userNotifications` | Notif personal karyawan | userId, type, title, message, isRead |
| 9 | `events` / `calendarEvents` | Event/meeting kalender | title, description, startDate, endDate, location, category, attendees[], departments[], organizerId, color, notificationSentDayBefore, notificationSent30Min |
| 10 | `departments` | Definisi departemen | name, description, color, isActive |
| 11 | `edit_requests` | Permohonan koreksi absensi | attendanceId, userId, reason, status, requestedChanges{checkIn, checkOut, status} |
| 12 | `disputes` | Komplain karyawan ke admin | userId, status. **Subcollection: `messages/{messageId}`** |
| 14 | `user_heartbeats` | Heartbeat online status (mobile tulis tiap 30s) | userId, timestamp, deviceId, appVersion |
| 15 | `user_presence` | Presence (alternatif/parallel) | docId=userId, isOnline |
| 16 | `messages` | Chat admin↔karyawan flat (filter by chatId) | senderId, senderName, senderRole, receiverId, receiverRole, content, status(sent/delivered/read), readAt, deliveredAt |
| 17 | `chats/{chatId}/typing/status` | Typing indicators | nested subcollection |
| 18 | `broadcasts` | Pengumuman global (employee read-only) | title, message, createdAt |
| 19 | `pending_sync` | Antrian absensi offline | userId, date, type(checkIn/checkOut), time, lat, lng, photoUrl, deviceId, synced, syncAttempts |
| 20 | `fcm_tokens` | Token push (**docId = token itself**) | userId, deviceId, appVersion |
| 21 | `admin_fcm_tokens` | Token FCM khusus admin | userId, token data |
| 22 | `audit_log` | Audit trail aksi admin | action, targetUserId, metadata, timestamp |
| 23 | `login_issues` | Lapor masalah login (**anonymous create**) | name, emailOrEmployeeId, description, status(pending) |
| 24 | `leave_balances/{userId}` | Saldo cuti per user | annual, sick, dll. **Admin-only write** |
| 25 | `meetingNotifications` | Scheduled meeting notifications (managed by CF) | eventId, eventTitle, targetDepartments[], targetEmployees[], type(day_before/30_min_before), scheduledAt, sent |

### Aturan Schema Penting

- **Timestamp**: gunakan Firestore `Timestamp` type, bukan string
- **Admin** menulis nested object (`checkIn.time` dll); **mobile** flatten saat baca, simpan `checkIn`/`checkOut` time sebagai string `HH:mm` lokal
- **Status flow `messages`**: `sent` → `delivered` (onMessage di mobile) → `read` (saat buka chat page)
- **`user_heartbeats`**: kalau selisih timestamp > 40 detik → user offline
- **`pending_sync`**: ConnectivityService deteksi online → push ke koleksi `attendance` utama

### Composite Indexes Required

File `firestore.indexes.json`:

```json
{
  "indexes": [
    { "collectionGroup": "attendance", "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "date", "order": "DESCENDING" }
      ]
    },
    { "collectionGroup": "leaves", "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    { "collectionGroup": "overtime", "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "date", "order": "DESCENDING" }
      ]
    }
  ]
}
```

### 2.3 Firestore Security Rules

File: [admin/firestore.rules](admin/firestore.rules)

#### Helper Functions

```javascript
function isAuth() { return request.auth != null; }

function isAdmin() {
  return isAuth() &&
    (get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin' ||
     get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'superadmin');
}

function isOwner(uid) { return isAuth() && request.auth.uid == uid; }
```

#### Pola Akses per Koleksi

| Koleksi | Read | Create | Update | Delete |
|---------|------|--------|--------|--------|
| **catch-all `{document=**}`** | admin | admin | admin | admin |
| `users` | owner / admin | admin | owner (tidak bisa ubah role, employeeId, department, email, uid) | admin |
| `attendance` | `get`: **semua auth** (untuk transaction.get); `list`: owner/admin | owner | owner | admin |
| `leaves` | owner / admin | owner | owner (status='pending' only) | owner (pending only) |
| `overtime` | owner / admin | owner | — | owner (pending only) |
| `disputes` | owner / admin | owner | owner / admin | admin |
| `disputes/{id}/messages` | semua auth | semua auth | — | — |
| `messages` (chat) | sender/receiver/admin | sender only | sender/receiver/admin (untuk status delivered/read) | admin |
| `chats/{chatId}` + typing | semua auth | semua auth | — | — |
| `adminNotifications` | admin / employeeId | semua auth | admin | admin |
| `userNotifications` | owner / admin | admin only | owner (mark read) | admin |
| `broadcasts`, `calendarEvents`, `shifts`, `departments`, `settings`, `jamKerja` | semua auth | admin | admin | admin |
| `fcm_tokens` | admin | semua auth | semua auth | semua auth |
| `audit_log` | admin | semua auth | — | admin |
| `edit_requests` | owner / admin | owner | admin (approval) | admin |
| `login_issues` | admin | **TANPA AUTH** (validasi field size) | admin | admin |
| `user_presence` | semua auth | owner (uid match) | owner | owner |
| `admin_fcm_tokens`, `leave_balances` | admin | admin | admin | admin |

#### Special Cases & Pitfalls

1. **`attendance.get` longgar untuk semua auth** — karena `transaction.get()` pada doc baru (belum exist) akan fail kalau rule pakai `resource.data`.
2. **`login_issues` tanpa auth** — user belum bisa login, jadi rules cek ukuran field: name 1-100, emailOrEmployeeId 1-150, description 10-2000, status harus 'pending'. Mitigasi spam.
3. **`messages.update` izinkan receiver** — supaya receiver bisa update status `delivered` & `read`, bukan cuma sender.
4. **Cloud Functions bypass rules** — pakai Admin SDK, bisa baca/tulis apapun.

### 2.4 Cloud Functions

File: [admin/functions/src/index.ts](admin/functions/src/index.ts)

#### Helper: `sendPushToUser`

Ambil semua FCM token aktif user dari `fcm_tokens` (query by userId), multicast via `sendEachForMulticast`, clean up token expired otomatis (error codes: `messaging/registration-token-not-registered`, `messaging/invalid-registration-token`). Payload includes android `channelId` default `high_importance_channel`.

#### Daftar 6 Functions

| # | Nama | Trigger | Fungsi |
|---|------|---------|--------|
| 1 | `onEmployeeCreated` | Firestore `users/{uid}` onCreate | Buat Firebase Auth account default + tulis `adminNotifications` "karyawan baru" |
| 2 | `onLeaveStatusUpdate` | Firestore `leaves/{id}` onUpdate | Kirim FCM push ke karyawan saat cuti approved/rejected |
| 3 | `onAttendanceCreated` | Firestore `attendance/{id}` onCreate | Logging/processing absensi |
| 4 | `onUserProfileUpdated` | Firestore `users/{uid}` onUpdate | Sync perubahan profil |
| 5 | `onFaceEnrolled` | Firestore `users/{uid}` onUpdate (`faceRegistered=true`) | Notif admin "X selesai enroll wajah" |
| 6 | `onAttendanceFailed` | HTTPS Callable | Notif admin saat user gagal face recognition 3x |
| 7 | `scheduledOvertimeCalc` | PubSub schedule **23:00 Asia/Jakarta** | Kalkulasi overtime harian semua karyawan |
| 8 | `sendOnboardingEmail` | Firestore `users/{uid}` onCreate | Kirim email kredensial login + link download APK ke `personalEmail` |

### 2.5 API Routes Next.js

Folder: [admin/src/app/api/](admin/src/app/api/). Semua route memverifikasi cookie `jne_admin_session` + role admin via `adminAuth.getUser()` + `adminDb.collection('users').doc().get()`.

| Route | Method | Fungsi |
|-------|--------|--------|
| `/api/audit-log` | POST | Tulis log aksi admin ke `audit_log` |
| `/api/notify-admin` | POST | Kirim notifikasi ke admin |
| `/api/notify-user` | POST | Kirim FCM push ke karyawan tertentu via `adminMessaging` |
| `/api/send-notification` | POST | Generic notification dispatcher |

---

## 3. ADMIN PANEL (Next.js)

### 3.1 Tech Stack Admin

File: [admin/package.json](admin/package.json)

| Package | Versi | Fungsi |
|---------|-------|--------|
| `next` | **16.1.6** | App Router (RSC), SSR |
| `react` / `react-dom` | **19.2.3** | UI library |
| `firebase` | 12.9.0 | Client SDK |
| `firebase-admin` | 12.0.0 | Server SDK (untuk API routes) |
| `tailwindcss` | **4.2.0** | Styling utility-first |
| `framer-motion` | 12.34.2 | Animasi |
| `animejs` | 4.3.6 | Animasi advanced |
| `lucide-react` | 0.574.0 | Icon set |
| `recharts` | 3.7.0 | Chart library |
| `sonner` | 2.0.7 | Toast notification |
| `date-fns` | 4.1.0 | Date utility |
| `typescript` | 5 | Type safety |

**Tailwind v4 Quirks**:
- Pakai `bg-linear-to-r` (bukan `bg-gradient-to-r`)
- Pakai `border-white/6` (bukan `border-white/[0.06]`)
- Design tokens: `text-h1` (30px), `text-stats` (36px), `text-desc` (14px)

### 3.2 Struktur Folder Admin

```
admin/src/
├── app/                          # Next.js App Router
│   ├── (admin)/                  # 18 protected admin routes
│   │   ├── dashboard/            # Overview & stats real-time
│   │   ├── employees/            # CRUD karyawan
│   │   ├── attendance/           # Monitoring absensi
│   │   ├── leaves/               # Approval cuti
│   │   ├── shifts/               # Pengaturan shift
│   │   ├── jam-kerja/            # Pengaturan jam kerja
│   │   ├── departments/          # Manajemen departemen
│   │   ├── reports/              # Laporan & export PDF/Excel
│   │   ├── analytics/            # Analytics dashboard
│   │   ├── calendar/             # Kalender event/meeting
│   │   ├── chat/                 # Chat dengan karyawan
│   │   ├── broadcast/            # Broadcast pengumuman
│   │   ├── requests/             # Overtime + edit requests
│   │   ├── edit-requests/        # Approval koreksi absensi
│   │   ├── face-enrollment/      # Monitor enrollment wajah
│   │   ├── head-units/           # Unit kepala departemen
│   │   ├── login-issues/         # Lihat laporan masalah login
│   │   ├── settings/             # System settings
│   │   └── layout.tsx            # Sidebar + Header wrapper
│   ├── (auth)/
│   │   ├── login/
│   │   └── forgot-password/
│   ├── api/                      # 4 API routes (lihat 2.5)
│   ├── layout.tsx                # Root layout + Providers
│   ├── template.tsx              # Page transitions
│   └── globals.css
│
├── components/
│   ├── layout/                   # AdminLayout, Header, Sidebar, NotificationPanel
│   ├── dashboard/                # ActiveAlerts, AttendanceChart
│   ├── employees/                # AddEmployeeModal
│   ├── departments/
│   ├── calendar/                 # CalendarGrid, EventListPanel, EventModal
│   ├── settings/                 # 5 panel: Office, Attendance, Company, Notifications, Maintenance
│   ├── notifications/
│   ├── jne/                      # Brand-specific
│   └── ui/                       # AnimatedButton, Badge, BentoCard, ComingSoon,
│                                 #  Interactive, LoadingSpinner, Modal, Pagination,
│                                 #  SearchBar, Skeleton, ThemeToggle
│
├── hooks/                        # 20+ custom hooks (lihat 3.3)
├── context/                      # AuthContext, ConfirmContext, NotificationContext, ThemeContext
├── lib/                          # firebase.ts, firebase-admin.ts, firestore.ts,
│                                 #  firestore/settings.ts, departmentRules.ts, fortress.ts
├── types/index.ts                # Semua TS types
└── utils/                        # calendarHelpers, dateFormatters
```

### 3.3 Custom Hooks (Business Logic)

Folder: [admin/src/hooks/](admin/src/hooks/). Pattern: tiap fitur punya hook sendiri yang encapsulate Firestore subscription + state + handler.

| Hook | Fungsi |
|------|--------|
| `useAddEmployeeLogic` | Form tambah karyawan + validasi (terkait `AddEmployeeModal.tsx`) |
| `useAdminFCM` | Setup FCM token + listener untuk admin dashboard |
| `useAnime` | Wrapper animejs untuk timeline animation |
| `useCalendarManagement` | CRUD calendar events, schedule meeting notifications |
| `useChat` | Real-time chat admin↔employee (flat `messages` collection) |
| `useDashboardLogic` | Orkestrasi dashboard page |
| `useDashboardStats` | Real-time stats (hadir/terlambat/absen hari ini, weekly chart) |
| `useDebounce` | Debounce input untuk search |
| `useDepartmentManagement` | CRUD `departments` |
| `useEmployeeManagement` | CRUD `users`, search, filter departemen |
| `useHeaderLogic` | Header bar: search global, notif panel, profile dropdown |
| `useHolidays` | Hari libur nasional (untuk kalender) |
| `useJamKerjaManagement` | CRUD `jamKerja` collection |
| `useShiftManagement` | CRUD `shifts` (paralel dengan jam kerja) |
| `useLeaveManagement` | Approve/reject cuti, filter status |
| `useLoginLogic` | Form login + error mapping Firebase Auth |
| `useNotificationPanelLogic` | Notif panel real-time + mark read |
| `useReportManagement` | Export laporan PDF/Excel per periode |
| `useSettingsManagement` | System settings CRUD |
| `useSidebarLogic` | Sidebar collapse/expand state |

#### Pola Umum Hook

```typescript
export function useXManagement() {
  const [items, setItems] = useState<X[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const unsub = subscribeToX((data) => {
      setItems(data);
      setLoading(false);
    });
    return () => unsub();
  }, []);

  return { items, loading, addX, updateX, deleteX };
}
```

Subscription helpers di [admin/src/lib/firestore.ts](admin/src/lib/firestore.ts):
`subscribeToEmployees`, `subscribeToTodayAttendance`, `subscribeToLeaves`, `subscribeToDepartments`, `subscribeToEvents`, `subscribeToNotifications`, `subscribeToPresence`, `subscribeToAllPresence`, `subscribeToUserFCMTokens`.

### 3.4 Context Providers

Folder: [admin/src/context/](admin/src/context/)

| Context | Fungsi |
|---------|--------|
| `AuthContext` | State user login, role check, login/logout, route guard |
| `ConfirmContext` | Modal konfirmasi global (confirm/cancel) |
| `NotificationContext` | State notifikasi & toast (sonner) |
| `ThemeContext` | Dark/light mode toggle (tema crimson gaming) |

### 3.5 Library Files

| File | Fungsi |
|------|--------|
| [lib/firebase.ts](admin/src/lib/firebase.ts) | Inisialisasi Firebase Client SDK |
| [lib/firebase-admin.ts](admin/src/lib/firebase-admin.ts) | Inisialisasi Firebase Admin SDK (server-side) |
| [lib/firestore.ts](admin/src/lib/firestore.ts) | Semua fungsi CRUD Firestore (`getEmployees`, `addEmployee`, `registerEmployee`, `subscribeToTodayAttendance`, dll) |
| [lib/firestore/settings.ts](admin/src/lib/firestore/settings.ts) | Helper khusus settings |
| [lib/departmentRules.ts](admin/src/lib/departmentRules.ts) | Aturan per-departemen (jam kerja, geofence, target) |
| [lib/fortress.ts](admin/src/lib/fortress.ts) | Security utility (validasi, sanitasi, `fortressRetry`) |

#### Fungsi-Fungsi di `firestore.ts`

**Employees**: `getEmployees`, `getEmployee`, `addEmployee`, `getNextEmployeeId`, `registerEmployee`, `updateEmployee`, `deleteEmployee`, `subscribeToEmployees`

**Jam Kerja**: `getJamKerjas`, `addJamKerja`, `updateJamKerja`, `deleteJamKerja`, `subscribeToJamKerjas`

**Leaves**: `getLeaves`, `updateLeaveStatus`, `deleteLeave`, `subscribeToLeaves`

**Attendance**: `getAttendanceByDate`, `getAttendanceByRange`, `deleteAttendance`, `subscribeToTodayAttendance`

**Notifications**: `subscribeToNotifications`, `markNotificationRead`, `markAllNotificationsRead`, `deleteNotification`, `deleteAllReadNotifications`

**Settings**: `getSystemSettings`, `updateSystemSettings`

**Events**: `getEvents`, `addEvent`, `updateEvent`, `deleteEvent`, `subscribeToEvents`, `scheduleMeetingNotifications`

**Departments**: `getDepartments`, `addDepartment`, `updateDepartment`, `deleteDepartment`, `subscribeToDepartments`

**Audit & Presence**: `logAudit`, `updatePresence`, `subscribeToPresence`, `subscribeToAllPresence`

**FCM**: `saveFCMToken`, `deleteFCMToken`, `subscribeToUserFCMTokens`

### 3.6 TypeScript Types Utama

File: [admin/src/types/index.ts](admin/src/types/index.ts)

```typescript
UserRole = 'admin' | 'superadmin' | 'employee' | 'kurir' | 'driver'
AttendanceStatus = 'present' | 'late' | 'absent' | 'leave' | 'overtime' | 'holiday'
LeaveType = 'sick' | 'annual' | 'personal' | 'emergency' | 'other'
LeaveStatus = 'pending' | 'approved' | 'rejected'
WorkDay = 'monday' | 'tuesday' | ... | 'sunday'
NotificationType = 'leave_request' | 'face_enrolled' | 'face_failed' |
                   'new_employee' | 'attendance_alert' | 'meeting_reminder' | 'system'
EventCategory = 'meeting' | 'training' | 'social' | 'deadline' | 'other'
TimeValue = string | { seconds: number } | { toDate: () => Date }
```

**Interface utama** (40+): `Employee`, `JamKerja`, `AttendanceRecord`, `LeaveRequest`, `AdminNotification`, `EditRequest`, `OfficeSettings`, `AttendanceSettings`, `NotificationSettings`, `CompanySettings`, `SystemSettings`, `DashboardStats`, `WeeklyAttendanceData`, `DepartmentData`, `DepartmentItem`, `DepartmentRule`, `CalendarEvent`, `MeetingNotificationSchedule`, `Settings`, `AuditAction`, `AuditLogEntry`, `AttendanceFilter`, `EmployeeFilter`.

### 3.7 Fitur Admin Panel

1. **Dashboard** — Statistik real-time (hadir, terlambat, izin), grafik mingguan, alert aktif
2. **Karyawan** — CRUD lengkap, custom jam kerja saat tambah karyawan (commit `32c3968`), filter departemen, search
3. **Absensi** — Real-time monitoring hari ini, history, filter tanggal/status
4. **Cuti** — Approve/reject + alasan, lihat dokumen pendukung
5. **Shift/Jam Kerja** — CRUD shift, set hari kerja, toleransi terlambat
6. **Departemen** — CRUD + warna identitas
7. **Kalender** — Event/meeting dengan FCM reminder otomatis (1 hari & 30 menit sebelum)
8. **Chat** — 2-way messaging dengan status sent/delivered/read
9. **Broadcast** — Pengumuman ke semua/grup karyawan
10. **Pengaturan** — Geofence (office lat/lng + radius), face threshold, notification config, maintenance mode
11. **Laporan** — Export PDF/Excel per periode
12. **Login Issues** — Lihat laporan user yang tidak bisa login
13. **Edit Requests** — Approve koreksi absensi dari karyawan
14. **Face Enrollment Monitor** — Lihat status enrollment wajah per karyawan
15. **Head Units** — Manajemen kepala unit/departemen

---

## 4. MOBILE APP (Flutter)

### 4.1 Tech Stack Mobile

File: [user_mobile/pubspec.yaml](user_mobile/pubspec.yaml)

| Package | Versi | Fungsi |
|---------|-------|--------|
| `firebase_core` | ^2.30 | Firebase init |
| `cloud_firestore` | ^4.17 | Firestore client |
| `firebase_auth` | ^4.19 | Auth |
| `firebase_storage` | ^11.6 | Storage |
| `firebase_messaging` | ^14.9 | FCM |
| `firebase_performance` | any | Performance monitoring |
| `camera` | ^0.10.5+9 | Akses kamera |
| `google_mlkit_face_detection` | ^0.11 | Face detection on-device |
| `geolocator` | ^12 | GPS untuk geofencing |
| `google_maps_flutter` | ^2.7 | Tampilan peta |
| `permission_handler` | ^11.3 | Request permission |
| `provider` | ^6.1 | State management |
| `connectivity_plus` | ^6.0 | Deteksi online/offline |
| `sqflite` | ^2.3 | SQLite lokal (offline cache) |
| `path_provider` | ^2.1 | Path filesystem |
| `shared_preferences` | ^2.2 | Preferensi user |
| `flutter_local_notifications` | ^17.2 | Notif lokal |
| `image_picker` | ^1.1 | Upload foto |
| `flutter_image_compress` | ^2.3 | Compress foto |
| `cached_network_image` | ^3.4 | Image caching |
| `intl` | ^0.19 | Format tanggal/locale |
| `google_fonts` | ^6.2 | Font Google |
| `animate_do` | ^3.3 | Animasi |
| `percent_indicator` | ^4.2 | Progress UI |
| `http` | ^1.2 | HTTP client |

**Flutter SDK**: ^3.10.4

### 4.2 Struktur Folder Mobile

```
user_mobile/lib/
├── main.dart                     # Entry point, init Firebase
│
├── models/
│   └── app_models.dart           # UserModel, AttendanceModel, LeaveModel,
│                                 # DisputeMessage, NotificationModel, dll
│
├── providers/
│   ├── app_provider.dart         # State global utama (auth, attendance, leave, dll)
│   └── chat_provider.dart        # State chat dengan admin
│
├── screen/                       # 20 folder screens
│   ├── splash/                   # Splash screen
│   ├── onboarding/               # First-time intro
│   ├── welcome/                  # Welcome screen
│   ├── auth/
│   │   ├── login_page.dart
│   │   ├── change_password_required_screen.dart   # First login wajib ganti password
│   │   └── report_login_issue_screen.dart         # Lapor masalah login ke admin
│   ├── permission/               # Request permission camera/location
│   ├── home/
│   │   └── home_screen.dart      # Home dengan Bento tiles (Zen Premium)
│   ├── attendance/
│   │   ├── attendance_page.dart  # Check-in/out + face + GPS
│   │   ├── dispute_submission_screen.dart
│   │   └── dispute_detail_screen.dart
│   ├── enroll/                   # Face enrollment (registrasi wajah)
│   ├── leave/                    # Form pengajuan cuti
│   ├── overtime/                 # Form pengajuan lembur
│   ├── history/                  # Riwayat absensi
│   ├── statistic/                # Stats personal (grafik)
│   ├── calendar/                 # Kalender event
│   ├── chat/
│   │   └── chat_page.dart        # Chat dengan admin (Travigo-style)
│   ├── notification/             # Notification list
│   ├── profile/                  # Profil & edit
│   ├── settings/                 # Pengaturan app
│   ├── option/                   # Menu opsi
│   ├── help/                     # FAQ & bantuan
│   └── succeed/                  # Success/confirmation screen
│
├── widgets/
│   ├── bento_tile.dart           # Komponen tile Bento-UI
│   ├── onboarding_widget.dart
│   └── package_loading.dart
│
└── utils/
    ├── colors.dart               # Zen Premium palette
    ├── constants.dart            # Konstanta global
    ├── connectivity_service.dart # Monitor online/offline
    ├── geofence_service.dart     # Haversine distance, validasi radius
    ├── offline_service.dart      # SQLite queue + auto-sync
    ├── presence_service.dart     # Heartbeat 30 detik
    └── fortress_utils.dart       # Security helpers
```

### 4.3 AppProvider — Method Utama

File: [user_mobile/lib/providers/app_provider.dart](user_mobile/lib/providers/app_provider.dart)

`AppProvider extends ChangeNotifier` + `WidgetsBindingObserver`. Inject `ConnectivityService` di constructor.

#### Init & Lifecycle

| Method | Fungsi |
|--------|--------|
| `AppProvider(ConnectivityService)` | Constructor |
| `_init()` | Listen auth state changes |
| `_fetchCurrentUser(uid)` | Load profil dari `users/{uid}` |
| `_listenToMyData()` | Listener notif + broadcast |
| `_listenToLeaves()` | Stream `leaves` milik user |
| `_listenToSettings()` | Stream `settings/system` |
| `_cancelAllSubscriptions()` | Cleanup |
| `didChangeAppLifecycleState(state)` | Handle resume/pause untuk presence |

#### Auth

| Method | Fungsi |
|--------|--------|
| `login(email, password)` | Firebase Auth login |
| `logout()` | Clear session |
| `changePassword(newPassword)` | Ganti password (first login) |
| `markPasswordChanged()` | Set firstLogin=false di Firestore |
| `submitLoginIssue({name, emailOrEmployeeId, description})` | Anonymous create `login_issues` |

#### Preferences

| Method | Fungsi |
|--------|--------|
| `_loadPreferences()` | Load dari SharedPreferences |
| `toggleTheme()` / `setDarkMode(bool)` | Theme |
| `setNotificationsEnabled(bool)` | On/off notif |
| `setReminderEnabled(bool)` | On/off reminder |
| `setLanguage(code)` | Set bahasa |

#### Notifications

| Method | Fungsi |
|--------|--------|
| `markNotificationAsRead(notifId)` | Mark single read |
| `markAllNotificationsRead()` | Mark all read |
| `_updateNotifications(snap, isBroadcast)` | Merge `userNotifications` + `broadcasts` |

#### FCM & Presence

| Method | Fungsi |
|--------|--------|
| `_saveFCMToken()` | Tulis ke `fcm_tokens/{token}` dengan field userId |
| `_updatePresence(isOnline)` | Write `user_presence` + `user_heartbeats` |
| `_stopPresence()` | Stop heartbeat |
| `_schedulePeriodicSync()` | Auto-trigger syncPendingRecords periodic |

#### Attendance

| Method | Fungsi |
|--------|--------|
| `fetchAttendanceByMonth(month, year)` | Load history |
| `addAttendanceCheckIn(status, {localImagePath, lat, lng})` | Check-in |
| `addAttendanceCheckOut({localImagePath, lat, lng})` | Check-out |
| `_uploadAttendancePhoto(docId, localPath, isCheckOut)` | Upload Storage |
| `_checkConnectivity()` | Bool online |
| `syncPendingRecords()` | Push `pending_sync` → `attendance` |
| `calculateOvertime()` | Kalkulasi lokal |
| `getStatsForMonth(month, year)` | Hadir/terlambat/absen counts |

#### Leave & Overtime

| Method | Fungsi |
|--------|--------|
| `submitLeave({type, startDate, endDate, reason, documentUrl})` | Ajukan cuti |
| `submitOvertime({date, durationHours, reason})` | Ajukan lembur |
| `cancelLeaveRequest(requestId)` | Hanya saat status='pending' |
| `cancelOvertimeRequest(requestId)` | Hanya saat status='pending' |

#### SOS, Face & Helper

| Method | Fungsi |
|--------|--------|
| `sendSOS(lat, lng, locationName)` | Write `sos_alerts` + `adminNotifications` parallel |
| `registerFace(localPath)` | Upload Storage + set faceRegistered=true |
| `getFirstAdmin()` | Ambil admin pertama (chat target default) |
| `_mapMobileStatusToAdmin(status)` | Convert status string mobile→admin |

#### Dispute Loop

| Method | Fungsi |
|--------|--------|
| `submitDispute({...})` | Create `disputes/{id}` |
| `streamDisputeMessages(disputeId)` | Real-time `disputes/{id}/messages` |
| `replyToDispute({...})` | Reply ke thread |
| `confirmDisputeResolution({rating, ...})` | Konfirmasi + rating + FAQ |

### 4.4 Service Utilities Mobile

| Service | Fungsi |
|---------|--------|
| `GeofenceService` | Haversine formula: cek jarak user dari kantor; valid jika `d <= radiusMeters` (default 500m). Office lat/lng dari `settings/system` |
| `ConnectivityService` | Monitor online/offline real-time, trigger sync queue saat reconnect |
| `OfflineService` | Simpan absensi ke SQLite saat offline + write `pending_sync`, sync saat online |
| `PresenceService` | Heartbeat ke `user_heartbeats` setiap 30 detik |
| `FortressUtils` | Security helpers (validasi input, sanitasi) |

#### Formula Haversine

```
d = 2R × arcsin(√[sin²(Δφ/2) + cos(φ1)cos(φ2)sin²(Δλ/2)])
R = 6371000 (radius bumi dalam meter)
```

Validasi: attendance hanya diizinkan jika `d <= radius_limit` (default 500m).

### 4.5 Fitur Mobile App

1. **Login** + first-login force change password
2. **Lapor Masalah Login** (anonymous, ke admin) — commit `dbfb5ef`
3. **Face Enrollment** — capture & upload wajah (ML Kit)
4. **Check-in/out Absensi**:
   - Validasi GPS geofencing (Haversine)
   - Face recognition (faceScore)
   - Upload foto bukti ke Storage
   - Offline mode → queue ke `pending_sync` + SQLite
5. **Pengajuan Cuti** — pilih type + upload dokumen
6. **Pengajuan Lembur**
7. **Riwayat Absensi** + statistik bulanan
8. **Kalender Event/Meeting** (sync dari admin)
9. **Chat 2-way** dengan admin (status sent/delivered/read)
10. **Notifikasi** — personal + broadcast
12. **Dispute Loop** — komplain + thread + konfirmasi + rating + FAQ (Mei 2026)
13. **Dark/Light Mode** — sistem tema-aware (Mei 2026)
14. **Profil** — lihat & edit (terbatas)
15. **Help/FAQ** — bantuan offline

---

## 5. ALUR DATA OPERASIONAL (10 Flow)

### 5.1 Onboarding Karyawan Baru

```
Admin → AddEmployeeModal → Firestore users/{uid} (create)
  → CF onEmployeeCreated: buat Auth account default + write adminNotifications
  → CF sendOnboardingEmail: kirim email kredensial + link APK ke personalEmail
  → User dapat email, login pertama → firstLogin=true → ChangePasswordRequiredScreen
  → User ganti password → markPasswordChanged() set firstLogin=false
```

### 5.2 Absensi Check-in (Mobile)

```
Tap "Check In" di home_screen
  → GeofenceService Haversine: hitung jarak ke office.lat/lng dari settings/system
  → Jika distance > radiusMeters: tolak
  → Buka camera → ML Kit face detection → faceScore
  → IF online:
      upload foto ke Firebase Storage → write attendance/{userId}_{date}
      (nested checkIn: {time, lat, lng, distance, faceScore, photoUrl})
  → IF offline:
      simpan ke SQLite + pending_sync collection
      ConnectivityService detect online → syncPendingRecords()
      push ke attendance, hapus pending_sync entry
  → Admin dashboard real-time listener (subscribeToTodayAttendance) → update UI
```

### 5.3 Pengajuan & Approval Cuti

```
Mobile submitLeave() → leaves/{id} (status: pending)
Admin /leaves → useLeaveManagement → updateLeaveStatus(id, 'approved'|'rejected')
  → CF onLeaveStatusUpdate trigger
  → sendPushToUser() → FCM push ke karyawan
  → Mobile FCM listener → tampil notif
  → leaves doc juga di-stream listener mobile → UI status update
```

### 5.4 SOS Emergency

```
Mobile sendSOS(lat, lng, locationName)
  → write sos_alerts (status: active) DAN adminNotifications (parallel write)
  → Admin Dashboard ActiveAlerts component listen → pop-up real-time
  → Admin resolve → update status: 'resolved'
```

**Why parallel write:** `sos_alerts` untuk live dashboard, `adminNotifications` untuk history/log permanen.

### 5.5 Heartbeat & Presence

```
Mobile PresenceService → write user_heartbeats setiap 30 detik (userId, timestamp)
Admin subscribeToAllPresence() / subscribeToPresence(userId)
  → hitung (Date.now() - lastHeartbeat.timestamp)
  → > 40 detik → user offline
  → Dashboard tampil indicator hijau/abu real-time
```

### 5.6 Chat 2-way (admin ↔ employee)

```
Sender write ke `messages` (flat, filter by chatId field)
  status flow: 'sent' → 'delivered' (recipient device receive via onMessage)
                       → 'read' (recipient buka chat page)
chats/{chatId}/typing/status subcollection → typing indicators
```

**Constraint:** chat HANYA 2-way admin↔employee. Security rule block employee↔employee.

### 5.7 Dispute Loop (Two-way, ditambah Mei 2026)

```
Mobile submitDispute() → disputes/{id}
Admin balas → write subcollection disputes/{id}/messages/{mid}
Mobile streamDisputeMessages(disputeId) → real-time chat
Admin tandai resolved
Mobile confirmDisputeResolution() → kirim rating + akses FAQ
```

### 5.8 Edit Request Absensi

```
Mobile submit (jam typo dll) → edit_requests/{id} (status: pending,
                                                    requestedChanges{checkIn, checkOut, status})
Admin /edit-requests → approve → terapkan ke attendance doc + log audit_log
```

### 5.9 Overtime Daily Calc

```
CF scheduledOvertimeCalc setiap 23:00 WIB
  → loop semua attendance hari ini
  → hitung overtimeMinutes = totalWorkMinutes - normalShiftMinutes
  → write back ke attendance doc
```

### 5.10 FCM Token Lifecycle

```
Mobile login → _saveFCMToken() → write fcm_tokens/{token}
                                  (docId = token itself, field userId)
Token rotated/invalidated → CF sendPushToUser deteksi error → auto-delete
Logout → token tidak otomatis dihapus (assumption: user mungkin login lagi)
```

---

## 6. DESIGN SYSTEM ("Zen Premium")

### Palet Warna

| Token | Hex | Penggunaan |
|-------|-----|------------|
| Dark BG | `#121826` | Background dark mode (deep navy, bukan pure black) |
| Light BG | `#F8FAFC` | Background light mode |
| Indigo | `#4F46E5` | Primary accent |
| Cyan | `#22D3EE` | Secondary accent |
| JNE Orange | `#FF6B00` | Call-to-action (tombol prioritas) |
| Slate 400 | `#94A3B8` | Text secondary |

### Style per Surface

- **Dashboard Admin**: Dark crimson gaming theme
- **Chat**: Clean green Travigo-style
- **Mobile**: Zen Premium dengan Bento-UI
- **Dark/Light mode systemic** sejak overhaul Mei 2026 — semua screen tema-aware

### Tipografi

- **Mobile**: Outfit (Google Fonts), `fontWeight: w900` untuk title, `letterSpacing: 2` untuk caps
- **Admin**: Plus Jakarta Sans
- **Design tokens admin**: `text-h1` (30px), `text-stats` (36px), `text-desc` (14px)

---

## 7. DEPLOYMENT & SCRIPTS

### Admin Panel (Next.js)

```bash
cd admin
npm install
npm run dev          # dev server (port 3000)
npm run build        # production build
npm run start        # production server
firebase deploy --only hosting   # deploy ke Firebase Hosting
```

Deployment alternatif: **Vercel** (per README — connect repo, set env vars, whitelist domain di Firebase Auth).

### Mobile App (Flutter)

```bash
cd user_mobile
flutter pub get
flutter run                       # debug mode
flutter build apk --release       # produksi APK
# Output: build/app/outputs/flutter-apk/app-release.apk
```

Play Store signing sudah siap (commit `dbfb5ef`).

### Cloud Functions

```bash
cd admin/functions
npm install
firebase deploy --only functions
```

### Firebase Rules & Indexes

```bash
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
firebase deploy --only storage
firebase deploy --only dataconnect    # jika pakai
```

### Scripts Seed

Folder: [admin/scripts/](admin/scripts/)

- `seed_departments.mjs` — seed departemen default
- `seed_employees.mjs` — seed karyawan dummy
- `seed_history.mjs` — seed history absensi dummy
- `setup-admin.mjs` / `setup_admin.mjs` — buat akun super admin

### Konfigurasi `.env` Admin

```
NEXT_PUBLIC_FIREBASE_API_KEY=
NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=
NEXT_PUBLIC_FIREBASE_PROJECT_ID=admin-absensi-jne-mtp
NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET=
NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=
NEXT_PUBLIC_FIREBASE_APP_ID=
FIREBASE_PROJECT_ID=
FIREBASE_CLIENT_EMAIL=
FIREBASE_PRIVATE_KEY=
```

### Mobile Config

- Letakkan `google-services.json` di `user_mobile/android/app/`
- Letakkan `GoogleService-Info.plist` di `user_mobile/ios/Runner/`

---

## 8. SECURITY HIGHLIGHTS

1. **Firebase Security Rules** — granular per-collection, role-based
2. **Session Cookie** (`jne_admin_session`) untuk API routes admin
3. **Server-side verification** di setiap API route (cek role admin)
4. **Audit Log** (`audit_log`) untuk traceability aksi admin
5. **First-login Force Password Change** (`firstLogin: true`)
6. **Device Binding** (`registeredDeviceId`) — opsional anti-share akun
7. **FCM Token Cleanup** otomatis (Cloud Function hapus token expired)
8. **Login Issue Validation** — field size limit untuk mitigasi spam
9. **`fortress.ts` & `fortress_utils.dart`** — utility validasi/sanitasi
10. **Geofence + Face Score** — double verification absensi
11. **Cloud Functions Admin SDK bypass** — server-side aman dari aturan client

---

## 9. RIWAYAT COMMIT PENTING

| Commit | Fitur |
|--------|-------|
| `32c3968` | Custom jam kerja saat tambah karyawan (admin) |
| `dbfb5ef` | Play Store-ready signing + first-login password + lapor admin (mobile) |
| `aaf7266` | Audit fixes: crash + race + timezone + perf + dark-mode systemic |
| `4f428b9` | Clear lingering analyzer diagnostics |
| `8348c31` | Initial commit besar |

---

## 10. FAQ — Pertanyaan Umum

**Q: Database-nya pakai apa?**
A: Firestore (NoSQL, real-time). README menyebut PostgreSQL via Data Connect tapi implementasi aktual saat ini murni Firestore.

**Q: Gimana cara user offline absen?**
A: Disimpan ke SQLite lokal + koleksi `pending_sync`. `ConnectivityService` detect online → `syncPendingRecords()` push ke `attendance`.

**Q: Validasi lokasi pakai apa?**
A: Haversine formula di `geofence_service.dart`. Office lat/lng + radius diset admin di `settings/system`.

**Q: Face recognition pakai apa?**
A: Google ML Kit Face Detection (on-device, gratis, offline-capable). Foto disimpan di Firebase Storage.

**Q: Push notification?**
A: Firebase Cloud Messaging. Token disimpan per device di `fcm_tokens`. Cloud Function `sendPushToUser` multicast ke semua device user.

**Q: Online/offline indicator gimana?**
A: Mobile tulis `user_heartbeats` tiap 30 detik. Admin hitung selisih timestamp, kalau >40s → offline.

**Q: Bisa chat antar karyawan?**
A: Tidak. Chat hanya 2-way admin ↔ karyawan (security rules block lainnya).

**Q: Approve cuti gimana flow-nya?**
A: Admin click approve di `/leaves` → update Firestore → Cloud Function `onLeaveStatusUpdate` trigger → FCM push otomatis ke karyawan.

**Q: Bisa tambah departemen baru?**
A: Bisa. Admin → `/departments` → CRUD. `useDepartmentManagement` hook handle logic, rules disimpan di `departmentRules.ts`.

**Q: Email onboarding pakai apa?**
A: Cloud Function `sendOnboardingEmail` trigger saat user dibuat. Kirim kredensial + link APK ke `personalEmail` karyawan.

**Q: Kenapa rule `attendance.get` longgar untuk semua auth?**
A: Karena `transaction.get()` pada doc yang belum exist akan fail kalau rule pakai `resource.data`. Solusi: `get` longgar (cek by docId), `list` ketat (cek userId).

**Q: Bagaimana `messages` status `delivered` & `read` di-update kalau cuma sender yang allowed write?**
A: Rules `messages.update` izinkan sender, receiver, atau admin. Receiver butuh permission untuk update status.

**Q: Kenapa `login_issues` bisa dibuat tanpa auth?**
A: User yang gak bisa login berarti gak punya auth. Mitigasi spam: validasi field size (name 1-100, desc 10-2000) dan status harus 'pending'.

**Q: Apakah Cloud Function `scheduledOvertimeCalc` jalan otomatis?**
A: Ya, via PubSub schedule setiap 23:00 Asia/Jakarta. Tidak perlu di-trigger manual.

**Q: Apakah ada API REST tradisional?**
A: Tidak. Komunikasi langsung Firestore SDK (client) + Cloud Functions (server-side). API Routes Next.js hanya untuk operasi privilege admin (notify-user, audit-log).

**Q: Bagaimana sistem dispute bekerja?**
A: Mobile submit → `disputes/{id}`. Admin balas via subcollection `messages`. Mobile stream real-time. Setelah resolved, mobile konfirmasi + rating. Detail di [memory/project_dispute_loop.md](.claude/projects/c--Users-USER-jne-attandance/memory/project_dispute_loop.md).

**Q: Apakah app support multi-device login?**
A: Ya — `fcm_tokens` simpan token per-device, `sendPushToUser` multicast ke semua device. Tapi ada `registeredDeviceId` opsional untuk batasi 1 device per user.

**Q: Apakah ada role lain selain admin/employee?**
A: Ya di types: `'admin' | 'superadmin' | 'employee' | 'kurir' | 'driver'`. `superadmin` punya akses sama dengan admin di rules. `kurir`/`driver` aktif untuk fitur tertentu.

---

## 📎 LAMPIRAN — File Path Referensi

### Backend
- [admin/firestore.rules](admin/firestore.rules) — Security rules
- [admin/firestore.indexes.json](admin/firestore.indexes.json) — Composite indexes
- [admin/storage.rules](admin/storage.rules) — Storage rules
- [admin/functions/src/index.ts](admin/functions/src/index.ts) — Cloud Functions
- [admin/firebase.json](admin/firebase.json) — Firebase config

### Admin
- [admin/package.json](admin/package.json)
- [admin/next.config.ts](admin/next.config.ts)
- [admin/tailwind.config.js](admin/tailwind.config.js)
- [admin/src/lib/firestore.ts](admin/src/lib/firestore.ts) — Semua CRUD function
- [admin/src/types/index.ts](admin/src/types/index.ts) — Semua TS types
- [admin/src/app/(admin)/layout.tsx](admin/src/app/(admin)/layout.tsx)
- [admin/src/components/layout/AdminLayout.tsx](admin/src/components/layout/AdminLayout.tsx)
- [admin/src/components/employees/AddEmployeeModal.tsx](admin/src/components/employees/AddEmployeeModal.tsx)

### Mobile
- [user_mobile/pubspec.yaml](user_mobile/pubspec.yaml)
- [user_mobile/lib/main.dart](user_mobile/lib/main.dart)
- [user_mobile/lib/providers/app_provider.dart](user_mobile/lib/providers/app_provider.dart)
- [user_mobile/lib/models/app_models.dart](user_mobile/lib/models/app_models.dart)
- [user_mobile/lib/utils/geofence_service.dart](user_mobile/lib/utils/geofence_service.dart)
- [user_mobile/lib/utils/offline_service.dart](user_mobile/lib/utils/offline_service.dart)
- [user_mobile/lib/utils/presence_service.dart](user_mobile/lib/utils/presence_service.dart)

### Dokumentasi Lain
- [README.md](README.md) — Overview project
- [FIRESTORE_SCHEMA.md](FIRESTORE_SCHEMA.md) — Detail schema Firestore
- [PANDUAN_KURIR.md](PANDUAN_KURIR.md) — Panduan kurir

---

**Dibuat untuk JNE Martapura** | Sistem Absensi Terintegrasi
