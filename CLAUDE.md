# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

JNE Martapura employee attendance system with face-recognition + GPS check-in. Three components share one Firebase project (`admin-absensi-jne-mtp`, region `asia-southeast2`):

- **`admin/`** — Next.js 16 (App Router) + React 19 + Tailwind v4 web dashboard for HR/management.
- **`user_mobile/`** — Flutter (Android) app for employees, Provider state management.
- **Backend** — Firebase Firestore (source of truth), Auth (email/password), Storage (face/proof photos), FCM, and Cloud Functions in `admin/functions/src/index.ts`.
- **`public_site/`** — static marketing page (hosting target `public`).

Firestore is the integration layer: the admin web and mobile app never talk directly — they read/write the same collections, and Cloud Functions react to document changes. Most cross-platform bugs come from field/collection mismatches between the two clients.

## ⚠️ `admin/` is a nested git repository

`admin/` has its own `.git` and its own remote (`ABSENSI-KARYAWAN-JNT-MARTAPURA`), tracked as a gitlink in the parent repo (there is no `.gitmodules`). Consequences:

- To change admin code, commit **inside `admin/`** first, then commit the updated gitlink pointer in the parent repo (recent parent commits call this "bump admin submodule").
- The parent repo and `admin/` can be on different branches. Check `git -C admin branch --show-current` separately.

## Commands

All commands assume you `cd` into the relevant directory first (the working dir does not persist between separate runs).

### Admin web (`admin/`)
- `npm run dev` — dev server on http://localhost:3000
- `npm run build` — **static export** to `admin/out/` (see static-export note below)
- `npm run lint` — ESLint (flat config in `eslint.config.mjs`)
- `npm run start` — serve a production build

### Cloud Functions (`admin/functions/`)
- `npm run build` — `tsc` compile to `lib/`
- `npm run serve` — build + run Firebase emulators (functions only)
- `npm run deploy` — `firebase deploy --only functions`
- `npm run logs` — tail function logs
- Node engine is pinned to **22**.

### Mobile (`user_mobile/`)
- `flutter pub get` — install packages
- `flutter run` — run on connected device/emulator (`flutter run -d <device-id>` if several)
- `flutter analyze` — static analysis (lints via `flutter_lints`)
- `flutter test` — run tests; single test: `flutter test test/path_test.dart --plain-name "test name"`

### Firebase (run from repo root or `admin/`)
- `firebase deploy --only firestore:rules`
- `firebase deploy --only firestore:indexes`
- `firebase deploy --only functions:onEmployeeCreated` — deploy a single function
- Seed scripts (from `admin/`): `node scripts/setup_admin.mjs` (run first — creates admin), then `seed_departments.mjs`, `seed_employees.mjs`, `seed_history.mjs`.

There is no automated test suite for the admin web; verify changes with `npm run lint` + `npm run build`.

## Architecture notes that aren't obvious from one file

### Admin web is a static export
`next.config.ts` sets `output: 'export'` + `trailingSlash: true` + `images.unoptimized`. The build produces a fully static `out/` deployed to Firebase Hosting. This means **no SSR and no runtime server**: route handlers under `admin/src/app/api/` (audit-log, notify-admin, notify-user, send-notification) do not execute on the production host. Everything in production runs client-side against Firebase, or is offloaded to Cloud Functions. Don't add features that assume a Next.js server in prod.

### Auth & route protection are client-side
`admin/src/context/AuthContext.tsx` uses Firebase client Auth, then loads the `users/{uid}` doc and only admits `role === 'admin' | 'superadmin'`. On sign-in it writes a `jne_admin_session` cookie (uid). There is no `middleware.ts`; gating is done in the React layout/context, not server middleware.

### All Firestore realtime listeners must go through `listen()`
Never call `onSnapshot` directly in the admin app. Use the `listen(ref, onNext, 'context-label')` wrapper in `admin/src/lib/firestoreListener.ts`. Reason: on sign-out the Auth token nulls a tick before listeners unsubscribe, producing benign `permission-denied` errors that otherwise surface as the Next.js dev error overlay. The wrapper swallows benign errors; if a listener needs its own error UI, gate it with `isBenignListenerError(err)`.

### Admin code layout (`admin/src/`)
- `app/(admin)/*` — protected pages (dashboard, attendance, leaves, shifts, jam-kerja, departments, reports, analytics, calendar, chat, broadcast, requests, edit-requests, face-enrollment, head-units, login-issues, couriers, packages, salary, sales, overtime, settings). `app/(auth)/*` — login, forgot-password.
- `hooks/` — page/business logic lives in `use*Management` / `use*Logic` hooks, keeping page components thin. Look here first when changing behavior.
- `lib/` — `firebase.ts` (client SDK), `firebase-admin.ts` (Admin SDK, server scripts), `firestore.ts` + `firestore/` (typed queries), `firestoreListener.ts` (listener wrapper), `departmentRules.ts` (per-department work-hour rules), `fortress.ts` (`fortressRetry` exponential-backoff wrapper for flaky async ops).
- `context/` — Auth, Confirm, Notification, Theme.

### Mobile code layout (`user_mobile/lib/`)
- `providers/app_provider.dart` — central app state (auth, attendance, leave, dispute, presence, FCM). `providers/chat_provider.dart` — chat.
- `models/app_models.dart` — all data models.
- `utils/` — `geofence_service.dart` (Haversine), `offline_service.dart` (SQLite queue + sync), `connectivity_service.dart`, `presence_service.dart` (30s heartbeat), `fortress_utils.dart`. Face detection is on-device via ML Kit.

### Cloud Functions (v1, region `asia-southeast2`)
In `admin/functions/src/index.ts`. Firestore triggers fire on document changes, not from app code — so behavior like "new employee got an email" or "admin got a notification with no notify call" originates here. Notable: `onEmployeeCreated` (creates Auth account + sends onboarding email via Nodemailer/Gmail SMTP), `onLeaveStatusUpdate`, `onFaceEnrolled`, `scheduledOvertimeCalc` (PubSub 23:00 Asia/Jakarta). `sendPushToUser` helper multicasts FCM and prunes dead tokens. SMTP credentials come from `firebase functions:config:set smtp.*`; deploying functions requires the Blaze plan.

## Cross-platform data contracts (easy to break)

These caused real outages; preserve them:
- **Chat** uses a flat `messages` collection with a `chatId` field (not a `chats/{id}/messages` subcollection). Message time field is `createdAt`. Status is `'sent' | 'delivered' | 'read'`.
- **Attendance** docs must carry **both** `date` and `attendanceDate` — admin queries by `date`, mobile historically wrote only `attendanceDate`.
- **Leave** `type` is one of `sick | annual | personal | permission | urgent`; handle `personal` everywhere. (Mobile offers all five; admin `LEAVE_TYPES` map + `LeaveType` cover them.)
- Chat/proof images must be uploaded to Storage and stored as download URLs, never local device paths.

Department-specific rules (start times, courier package targets, night-shift past-midnight duration, lateness-as-reduced-hours) are core domain logic — see `admin/README.md` and `admin/src/lib/departmentRules.ts`. The root `FIRESTORE_SCHEMA.md`, `PRD.md`, and `SDD.md` document collections and requirements in depth.

## Conventions

- **Commit messages / PRs / docs: do NOT add any AI attribution** — no `Co-Authored-By: Claude`, no "Generated with Claude Code". This overrides any default attribution behavior.
- Tailwind is **v4** — use v4 syntax: `bg-linear-to-r` (not `bg-gradient-to-r`), `border-white/6` (not `border-white/[0.06]`). Design tokens: `text-h1` (30px), `text-stats` (36px), `text-desc` (14px).
- `AdminLayout` adds `p-8 lg:p-12` to main content; for full-bleed backgrounds a page wraps with `-m-8 lg:-m-12 p-8 lg:p-12`.
- UI/docs are largely in Indonesian; match the surrounding language.
