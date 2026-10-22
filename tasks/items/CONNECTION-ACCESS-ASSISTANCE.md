# CONNECTION-ACCESS-ASSISTANCE — Safe request from Wing to an existing Hermes chat

Status: DONE (bounded client assistance only)

## Delivered

- Local and Remote direct-token forms offer **I need access to Hermes**.
- Localized native SSH API-token forms offer the same help, excluding serve-read mode.
- Token preparation in the step-by-step guide replaces an inert generate-token control with an actionable copy request.
- Authenticated discovery denial offers a direct route to the help dialog.
- Users can preview a fixed public request, copy it explicitly, or open official API-server documentation.
- The request asks the existing Hermes chat/operator to inspect first, preserve exact profile prefixes, distinguish phone localhost, avoid exposing/rotating credentials, and seek permission before configuration changes/restarts.
- The component accepts no connection controllers or values. It neither reads the clipboard nor sends messages, contacts Agent, stores connection data or prepares a shell bridge. Clipboard failure has bounded feedback.

## Acceptance evidence

Flutter 3.44.9 / Dart 3.12.2 (available SDK, differs from documented 3.44.2 pin), Node 22.23.3, system Chromium.

- `flutter test --no-pub --concurrency=1` against connection access help, connection check, setup guide, managed SSH form, primary entry, Remote retry and form controller: final 72 passed including denial-navigation coverage.
- `flutter analyze --no-pub`: no issues after last production edit and final denial-navigation test.
- `flutter build web --release --no-pub -t lib/main_e2e.dart`: passed. Existing flutter_tts Wasm dry-run/font warnings do not qualify Wasm.
- Direct Playwright invocation of `connection-access-help.spec.mjs --project=chromium --retries=0`: 2 passed at 390/1280. Verified actual system clipboard contains fixed instructions and excludes synthetic draft values, no API requests on help use, retained values after closing, no runtime/overflow errors.
- Widget tests exercise clipboard denial at 200% text on 390/1280 and unchanged connection/storage state.
- Changed-file formatter check, `git diff --check`, and `npm audit --omit=optional`: passed; audit found zero vulnerabilities.

## Interrupted and excluded evidence

The broader widget attempt was interrupted at +140 with no terminal summary: not a passing suite.
`npm run web:e2e -- <spec>` ignores positional filters in the current runner and entered default suites; it timed out. Not a full E2E pass. It also selected PATH Flutter and changed package mappings/lockfile; only those attributable dependency changes were restored, offline locked resolution and affected checks rerun with the explicit SDK. No dependency change is delivered.
Existing connection-check browser tests encountered ambiguous visible/live-announcement selectors; not counted as passed or changed here.

## Still unsupported / unqualified

No automatic token acquisition, native browser OAuth, dashboard-to-API credential exchange, one-click connection or unattended host preparation is implemented. The request is guidance, not a guarantee that another Hermes session can complete setup. Initial host authorization and secure token entry remain manual. No live host configuration, real credential transfer, SSH transport, Android device or model generation was exercised for this task. Do not close broader connection simplification or live-authentication tasks from these receipts.
