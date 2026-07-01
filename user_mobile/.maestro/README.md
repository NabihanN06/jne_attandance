# Maestro E2E Flows — `user_mobile`

End-to-end flows for the JNE Absensi mobile app using
[Maestro](https://maestro.mobile.dev). Maestro drives the app as a black box
via YAML flows, auto-handles OS permission dialogs, and works with Flutter.

> Status: **skeleton**. `01_app_smoke.yaml` runs out-of-the-box. The other flows
> are structured and valid, but the real interaction steps are commented `TODO`s
> that need a seeded test account, mock GPS, correct selectors, or face stubbing.

---

## 1. Prerequisites

- **Maestro CLI** — installed at `~/.maestro/bin` (added to Windows user PATH).
  Verify: `maestro --version`. Reinstall: `curl -fsSL "https://get.maestro.mobile.dev" | bash`.
- **Java 11+** (JDK 17 present) and **Android platform-tools / adb** (present).
- A **running emulator or connected device** with the app installed
  (`flutter run` once, or `flutter install`), built against a valid
  `android/app/google-services.json`.

## 2. Running

```bash
maestro test .maestro                       # whole suite
maestro test .maestro/01_app_smoke.yaml     # one flow
maestro test .maestro -e EMAIL=budi@jne.mtp.com -e PASSWORD='Rahasia123!'

maestro studio                              # interactive: inspect the view tree
                                            # & record flows (best way to find selectors)
```

## 3. Claude Code MCP integration

The Maestro MCP server is registered (`claude mcp add maestro -- maestro mcp`)
so Claude can drive Maestro directly (start a device, run/inspect flows).

- It shows **✔ Connected** once `~/.maestro/bin` is on PATH (already persisted
  to the Windows user PATH).
- **Restart Claude Code** so it (a) picks up the updated PATH and (b) loads the
  new MCP's tools — MCP tools are only registered at session start.

## 4. What you must provide for the flow tests

| Need | Why | How |
| --- | --- | --- |
| **Seeded test account** | login + downstream flows | Create a karyawan on a **test** Firebase project; pass via `-e EMAIL=… -e PASSWORD=…`. |
| **First-login account** | `auth/first_login_change_password` | A user with `firstLogin=true`. |
| **Mock GPS inside geofence** | check-in passes | `adb emu geo fix LONGITUDE LATITUDE`, or a mock-location app. |
| **Real camera / face** | face check-in & enrollment | Physical device, or stub `FaceService`. |
| **Throwaway Firebase project** | SOS / dispute / chat write real docs | Point `google-services.json` at a test project. |

## 5. Stable selectors (recommended)

The flows currently match by visible text (e.g. `tapOn: "Masuk"`), which is
brittle because labels are i18n (ID/EN). For robust selectors, add **Semantics
identifiers** to key widgets so Maestro can match `id:`:

```dart
Semantics(
  identifier: 'loginButton',
  child: ElevatedButton(/* ... */),
)
```

```yaml
- tapOn:
    id: "loginButton"
```

Priority widgets: `emailField`, `passwordField`, `loginButton`, `checkInButton`,
`checkOutButton`, `sosButton`, `submitLeave`, `submitOvertime`, `chatInput`,
`chatSend`. (Same list as the Patrol `KEYS_TODO.md`.)

## 6. Layout

```
.maestro/
├── config.yaml                 ← suite globs + env creds
├── README.md
├── subflows/
│   └── login.yaml              ← reusable: launch + grant perms + login
├── 01_app_smoke.yaml           ← runs out-of-the-box
├── auth/           login · first_login_change_password · report_login_issue
├── onboarding/     permissions_and_enroll
├── attendance/     check_in_out · offline_attendance
├── leave/          submit_leave
├── overtime/       submit_overtime
├── communication/  chat · dispute
├── sos/            sos
├── profile/        profile_settings
└── navigation/     navigation_smoke
```

## 7. Maestro vs Patrol

This repo also has a Patrol skeleton in `integration_test/`. **Pick one** to
avoid duplicated maintenance:

- **Maestro** — no Dart, black-box, easy to author (`maestro studio`), great with
  the MCP; weaker at white-box assertions and injecting fakes.
- **Patrol** — Dart, can inject fake services (GPS/face) and assert widget state;
  more setup.

If you standardise on Maestro, delete `integration_test/` and drop the
`patrol` dev-dependency from `pubspec.yaml`.
