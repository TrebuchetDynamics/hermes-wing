# Gateway keyboard bootstrap fixture repair

Task: `t_d8c47dfc`. Goal task: `FIX-GATEWAY-KEYBOARD-390` (`PARITY`).
Status: executor-verified; same-card native review is the final delivery step.

## Root cause and bounded correction

A fresh run reproduced all six failures in
[`gateway_keyboard_client_test.dart`](../../test/features/gateway/gateway_keyboard_client_test.dart):
four missing Refresh semantic elements and two missing unsupported-health notices.
The deterministic history response omitted `object: list` and the exact
`session_id`. Production `HermesMessagePage.fromJson` correctly rejected it, so
`HermesApiChannel` never admitted the connection/bootstrap state required by the
Connections screen. This was a fixture failure, not a demonstrated layout defect.

The fixture now supplies the supported list envelope and exact synthetic session
identity, retaining pagination and empty history. Explicit assertions verify a
connected, settled default profile, admitted session history, active session and
absence of a connection error before mounting the production router. No existing
keyboard, pending single-read, redaction, fallback, recovery, capability, request
or ownership assertion was removed or weakened.

Authority tracing:

- [`HermesMessagePage`](../../lib/core/hermes/models/hermes_session.dart) requires
  list/session identity even for an empty page;
  [`history identity tests`](../../test/core/hermes/client/hermes_history_identity_test.dart)
  cover exact and malformed envelopes.
- [`API client`](../../lib/core/hermes/client/hermes_api_client.dart) validates
  identity before returning history;
  [`connection bootstrap`](../../lib/core/hermes/channel/api_channel/hermes_api_channel_connection.dart)
  admits history before publishing connected state.
- Read-only Agent reference `gateway/platforms/api_server.py:3322-3328` emits
  `object: list`, resolved `session_id`, data and pagination. Its nearest
  `tests/gateway/test_session_api.py` exercises paginated session history.
- [`GatewayScreen`](../../lib/features/gateway/screens/gateway_screen.dart)
  gates health on selected management/contact ownership and current Agent read
  authority. This direct synthetic connection has no saved endpoints: both
  management gateway and active contact remain null, the existing ad-hoc owner
  path. No directory override or artificial contact was introduced. The full
  existing before/after owner tuple and read-only oracle remain intact.

All six cases pass after the fixture-only repair, so no production Gateway,
transport/domain, shell, Chat/model/restoration, credential or upstream change was
necessary. Unrelated dirty-worktree changes were preserved.

## Executed checks

Commands ran from the repository root on the Linux Flutter widget runner:

- `flutter test --concurrency=1 test/features/gateway/gateway_keyboard_client_test.dart`
  before correction: exit 1, zero passes/six failures.
  Log: `.task-evidence/gateway-keyboard-before.log`.
- Same exact command after correction: exit 0, six passes, covering initial
  success/failure/unsupported health at both 390px and 1280px, height 1400px,
  200% text and reduced motion. Log: `.task-evidence/gateway-keyboard-after.log`.
- `dart format --output=none --set-exit-if-changed test/features/gateway/gateway_keyboard_client_test.dart`:
  exit 0, no changes.
- `flutter test --concurrency=1 test/features/gateway/gateway_screen_test.dart test/features/gateway/gateway_health_ownership_test.dart test/features/gateway/gateway_health_loader_ownership_test.dart`:
  exit 0, 68 passes. Log: `.task-evidence/gateway-keyboard-nearest.log`.
- `flutter analyze`: exit 0, no issues.
  Log: `.task-evidence/gateway-keyboard-analyze.log`.
- `git diff --check`: exit 0.

No compiled browser, native desktop application interaction, live Agent/provider,
physical device, screen reader or full repository gate was exercised in this
bounded fixture repair. These passing widgets do not establish full Desktop
parity. No new task, commit, publication or release was created.
