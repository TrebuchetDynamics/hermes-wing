# Connections UX and lifecycle verification — 2026-09-08

## Problem and changes

Both Gateway and Chat labelled saved-connection deletion as **Disconnect**.
A failing widget regression confirmed that disconnect removed the saved entry.
Disconnect now closes chat, clears startup restoration, and retains enrollment.
Explicit removal remains a separate, confirmed action.

Connections (`/gateway`) owns the saved-host list, connection editing, status
refresh, chat connect/disconnect, and Wing Link trust. Settings links there.
The phone navigation exposes Chat, Profiles, Connections, and More; More omits
the primary tabs. Empty Connections has an enrollment action without a second
prompt to select an absent host. Duplicate rename controls were consolidated.

The directory now distinguishes the management host from the active chat
contact. Inspecting Connections does not activate chat. Wing Link profile and
trust reads work while chat is disconnected. Native-only profile management
offers an explicit connection action. Native Agent capabilities are applied
only to the selected endpoint's identity.

Startup restoration cannot override an explicit disconnect. Reconnection waits
for disconnect teardown. A grouped host's Disconnect targets its actual active
profile endpoint. Revoking a Wing Link device clears the shared management
enrollment across that device's saved profiles, preserving Agent credentials
and other device enrollments.

Hermes Agent remains authoritative, and chat remains direct to its data plane.
No host service-stop operation, proxy, arbitrary-path operation, or upstream
modification was introduced.

## Reference study

Desktop's `lat.md/connections.md`, `ConnectionPane.tsx`, `Layout.tsx`, and
`Gateway.tsx` informed the distinction between connection management, chat
identity, and local runtime controls. Its `lat` executable was unavailable;
the local design notes and live source were read directly. Desktop's local
runtime controls were not treated as remote Wing Link capabilities.

## Executed checks

- `dart format --output=none --set-exit-if-changed lib test integration_test`:
  350 files, no formatting changes.
- `flutter analyze`: no issues.
- `flutter test --concurrency=1`: 1,639 tests passed before the final grouped-host
  regression and empty-state adjustment.
- Final affected-suite run: 188 tests passed across Gateway, gateway directory,
  Profiles, Chat gateway switching, Settings, app shell, and gateway route tests.
- `(cd wing_link && go test ./...)`: passed.
- `npm audit`: zero vulnerabilities.
- `flutter build web --release -t lib/main_e2e.dart`: passed.
- `npm run web:e2e`: functional suites passed; the screenshot suite initially
  expected the removed Settings connection list. After updating that assertion,
  the final `npx playwright test --config=playwright.config.mjs
  playwright/tests/regression/browser-surfaces.spec.mjs
  playwright/tests/screenshots/e2e-screenshots.spec.mjs` run passed all 14 tests.
  Other browser suites contributed 32 passes and one intentionally skipped live
  test. The affected suites were rerun against the rebuilt web target.
- `npm run readme:assets`: regenerated assets; mobile navigation and desktop
  Settings/Connections captures were inspected.
- `flutter build apk --release`: passed; universal APK at
  `build/app/outputs/flutter-apk/app-release.apk`.
- `git diff --check`: passed.

Build warnings remain for Android compile-SDK/plugin alignment, Kotlin plugin
migration, Cupertino font assets, and dependency WebAssembly dry-run checks.
These did not prevent the Android or JavaScript web builds.

## Qualification limits and device journey

Evidence is deterministic Flutter testing, Linux-hosted Chromium, and Android
compilation. No physical Android, live paired-host, or acoustic acceptance is
claimed. The earlier Profiles Chat voice/duplicate-message inventory is not
resolved by this connection-focused change.

For physical qualification, pair a test host with two enrolled profiles. Open
chat with one profile, then select its host in Connections and disconnect.
Verify both profiles remain saved, background/foreground does not reconnect,
and Wing Link trust and Profiles remain operable. Reconnect explicitly, switch
profiles, and repeat. On a disposable pairing, verify self-revocation removes
management access from both saved profiles while preserving Agent chat access.
