+++
schema = 1
id = "MOBILE-GATEWAY-SIGNIN"
title = "Direct mobile gateway sign-in with metadata QR"
short = "Mobile gateway sign-in"
status = "done"
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
checks = ["flutter --version --machine", "flutter pub get --enforce-lockfile", "flutter test --no-pub --concurrency=1 test/core/hermes/auth/native_gateway_auth_test.dart test/core/hermes/auth/secure_gateway_token_store_test.dart test/core/hermes/setup/hermes_gateway_invite_test.dart test/core/hermes/channel/hermes_remote_gateway_test.dart test/features/enrollment/gateway_https_flow_test.dart test/features/enrollment/gateway_login_entry_test.dart", "flutter analyze --no-pub", "flutter build web --release --no-pub -t lib/main_e2e.dart", "node desktop_plugins/wing-connect/build.mjs --check", "node --check desktop_plugins/wing-connect/plugin.js", "node --experimental-vm-modules --test test/tooling/test_gateway_qr_plugin.mjs", "git diff --exit-code -- pubspec.yaml pubspec.lock", "git diff --check"]
exclusions = ["No Agent modifications", "No gateway startup, VPN/firewall changes or hosted deployment", "No credential QR or legacy pairing", "No live-account/provider qualification from fixtures"]
closure = "coordinator_verified"
closure_evidence = "tasks/evidence/MOBILE-GATEWAY-SIGNIN.toml"
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
- Sources: docs/product/enrollment.md#android-gateway-sign-in-candidate; docs/adr/security-and-privacy.md#gateway-sign-in-and-metadata-qr; desktop_plugins/wing-connect/README.md#source-and-validation
- Blocker resolution: not runnable: needs Scope, Acceptance, Checks and Touches (draft: checks); filled the missing exact offline check commands from current auth/token/invite/channel/enrollment tests and the plugin README. This is task-contract repair, not new product authority or test success. Preserve all acceptance, rank, saved implementation and live-device limits.
- Next action: Reconcile the already-present gateway sign-in implementation and retained source-bound checks; do not rebuild it from scratch. Run missing/invalidated exact checks on documented Flutter 3.44.2 and Node 22; retained Flutter 3.44.9 evidence does not qualify the pinned SDK. Plugin decoding requires the existing zbarimg tool; report unavailable tool input rather than fabricate a pass. Preserve origin/token/callback and no-replay assertions. Physical camera/system-browser/live-account and installation checks remain separately unqualified; no service setup, provider call, APK installation or deployment is authorized by this recovery.
- Pending live: Actual official Hermes Desktop plugin installation/load and operator interaction remain unqualified; no runtime installation was performed.
- Pending live: Physical Android camera scan, actual system-browser PKCE login/callback, platform secure persistence, refresh and cancellation require device qualification.
- Pending live: Reachable live HTTPS gateway/account qualification with valid certificates, fresh WSS tickets, exact-session recovery and deliberate generation without replay remains separate; no service setup, account/provider call, APK installation or deployment was performed.
