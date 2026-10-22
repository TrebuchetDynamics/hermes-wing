+++
schema = 1
id = "MOBILE-GATEWAY-SIGNIN"
title = "Direct mobile gateway sign-in with metadata QR"
short = "Mobile gateway sign-in"
status = "open"
goal = "CONNECTION-PATHS"
section = "Next"
rank = 16010
depends_on = []
touches = ["lib/core/hermes/auth", "lib/features/enrollment", "desktop_plugins/wing-connect"]
resources = []
kind = "implementation"
ownership = "worker"
scope = "Android explicit metadata QR/manual HTTPS origin, native PKCE browser login, secure origin-scoped tokens and direct native gateway chat. Standalone Desktop SDK QR UI, no backend."
acceptance = ["QR excludes all credentials and legacy formats", "Phone initiates advertised native_pkce and stores only exact-origin tokens securely", "HTTPS/WSS uses valid certificates, fresh tickets and existing no-replay session gates", "Cancellation, refresh and secure persistence have regression coverage", "Report real-device and live-host gates separately"]
checks = []
exclusions = ["No Agent modifications", "No gateway startup, VPN/firewall changes or hosted deployment", "No credential QR or legacy pairing", "No live-account/provider qualification from fixtures"]
+++

# Mobile gateway sign-in candidate

## Source

User approved adapting Desktop native PKCE and a non-secret metadata QR.
Reference `47b23fa048`: `apps/desktop/electron/native-oauth.ts`,
`native-oauth-login.ts`; `hermes_cli/dashboard_auth/routes.py:242-335,556-617`.
Official Desktop SDK supplies only UI contributions; no secret API is imported.

## Candidate behavior

- Android enrollment disclosure opens scanner or manual HTTPS origin/profile.
- Strict four-field JSON `hermes-wing-gateway` QR contains no credential.
- Phone browser authorization uses S256, state and the phone's loopback callback.
- Secure per-origin access/refresh tokens remain separate from API-server keys.
- Direct HTTPS/WSS native reader negotiates one-use ticket, exclusive submit and
  server requests before enabling exact-session Chat. No incidental prompt.
- Saved session checkpoint fences uncertainty; no automatic mutation retries.
- Desktop UI plugin generates SVG QR offline; installable `plugin.js` uses only
  official SDK/React imports. No Agent files, credential reads or service changes.

## Observed checks so far

Available Flutter 3.44.9 / Dart 3.12.2 differs from documented 3.44.2 pin.

- Focused auth, enrollment, native reader/lifecycle and recovery regression run:
  **114 passed** (`flutter test --no-pub --concurrency=1` with selected paths).
- Separate HTTPS/WSS integration fixture exercises exact profile and a deliberate
  synthetic Send with no replay. Phone UI test exercises PKCE callback, token
  exchange, secure save and native Chat navigation using real TLS sockets and
  simulated browser authorization. Neither is a real Hermes-account login.
- `flutter analyze --no-pub`: no issues at last run.
- `flutter build web --release --no-pub -t lib/main_e2e.dart`: passed. Existing
  flutter_tts Wasm/font warnings retained; not Wasm qualification.
- Android `emulator-5554`, isolated `.qa` debug app: **1 integration test passed**,
  manual entry/insecure refusal and secure-store load at 390px, 100/200% text.
  Existing secure-storage SDK37-vs-compile36 warning; Flutter teardown attempted
  original package uninstall and reported DELETE_FAILED_INTERNAL_ERROR. Test result
  remained exit 0; no paired app data was cleared by this task.
- Desktop plugin: **5 Node tests passed** with `--experimental-vm-modules`,
  including zbar decoding of rendered QR and reproducible artifact check.
- An earlier broad test attempt timed out at 180s; not counted as passed. A
  source-contract allowlist was narrowly updated for the new model-only recovery
  store; final 114-test run passed.

## Pending gates

Independent final review, APK artifact verification and canonical integration.
Physical QR camera, system-browser callback on physical Android, real-account
login, network/VPN route and actual Agent generation are unqualified.
The inspected local API listeners do not establish a reachable HTTPS native
sign-in gateway. This client does not create one; host setup remains explicit.
