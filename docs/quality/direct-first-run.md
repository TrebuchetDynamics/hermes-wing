# Direct first-run Agent entry

> Reference correction: [official Desktop authority](official-desktop-reference.md). Prior Desktop source citations and parity conclusions in this document are withdrawn. Wing test results remain historical behavior evidence only.


Card `t_98b85c1b`, goal task `M1-DIRECT-FIRST-RUN`. This qualifies a bounded
connection prerequisite, not M1 or the whole connection/authentication matrix.

## Implemented

Chat's empty-directory and connect-another **Add Hermes** actions now push the
existing `/hermes/add` form instead of enrollment. `/enroll` exposes direct
**Add Hermes** before separately labelled **Optional setup and pairing**. The
form also exposes an explicit secondary link back to optional setup. No router,
transport, credential acquisition, installer or SSH process implementation changed.

The existing Local / SSH / Remote controls remain primary; VPN / NetBird /
Tailscale remains nested under Remote. SSH explicitly requires a trusted tunnel
established outside Wing. Agent connection, sanitized failure, explicit retry,
secure persistence and owner fencing still use the existing shared channel/store.
Pairing ingress, review, pins and management credentials remain separate.
Missing advertised operations remain unavailable; this does not implement OAuth.

Production locations:

- [Enrollment chooser](../../lib/features/enrollment/screens/hermes_enrollment_screen.dart)
- [Public Chat entry](../../lib/features/hermes_chat/screens/hermes_chat_screen.dart)
- [Existing connection form](../../lib/features/hermes_chat/screens/state/hermes_chat_layout.dart)
- [Unchanged connection/save fences](../../lib/features/hermes_chat/screens/state/hermes_chat_connection.dart)
- [English source copy](../../lib/l10n/app_en.arb); localization output regenerated.

## Attribution and candidate identity

Pre-existing dirty bytes were captured before implementation in
`build/t_98b85c1b/baseline.tar.gz` (SHA256
`d19caf4ae45c4ea373188127bdb3bd8c4244b7020413c5241a967fbcce8ba00e`).
The separately attributed baseline commit is
`c7899719a9aa9c5619412a9977804917eec46a49`. Review/cherry-pick only its child
implementation commit, not that baseline's unrelated changes.

The final Wing-only qualified candidate is retained in
`build/t_98b85c1b/qualified-candidate.tar.gz`, with manifest
`build/t_98b85c1b/qualified-manifest.json`. Its source fingerprint is
`7a0055385e2bc6ed9623ee516ebe867b3f2c5c89374fd699b38e4f1b1476860a`;
archive SHA256 is
`d20791ef6b2e6b238b6e698b4fcc877011b76bbdf6933d019259043c8cac4ff6`.
Receipt/goal bookkeeping added afterward is not a build input. Source hashes,
lockfiles, exact commands, durations and request traces are in the
[durable evidence receipt](direct-first-run-evidence.json). Archive captures are
Wing-only: upstream clones and local runtime/credential directories excluded.
Other workers' pre-existing and concurrent changes are not this card's output.

Read-only references: `withdrawn source citation` at
`withdrawn reference revision` and `hermes-agent/` at
`158fd638da1629c8e62caf9ade1515d162def8ab`. Desktop's
`src/renderer/src/components/settings/ConnectionPane.tsx:193-234` supplies
local/remote/SSH terminology; its privileged process behavior is not ported.
Agent's `gateway/platforms/api_server.py` advertises capabilities/session routes.
Wing's existing exact-capability transport remains authoritative at runtime.

## Acceptance evidence

1. Public no-host keyboard entry reaches the real Local/SSH/Remote form, without
   pairing/install credentials. The [dedicated widget regression](../../test/features/enrollment/hermes_direct_first_run_test.dart)
   reproduced four missing-form failures before the routing fix (`red.log`).
   Fixed journeys pass at 390/1280 logical pixels and 1x/2x text. Incoming pairing,
   payload validation, enrollment trust and auth-recovery targets also pass.
   [Compiled Chromium journeys](../../playwright/tests/regression/direct-first-run.spec.mjs)
   enter via public `/hermes` controls, not a synthetic connect hook. Optional
   pairing remains keyboard reachable; existing owner/cancel/back journeys pass.
2. Six browser traces record only Agent reads: capabilities, health/detailed
   health, sessions, exact-session messages and advertised jobs. Each records
   zero Wing Link requests and zero mutations, a simulated 401 with private
   response content absent from UI, no automatic retry, then an explicit successful
   retry. The widget regression additionally injects failed optional management,
   returns via public manual recovery, and verifies no additional enrollment
   exchange/persistence and no management fields in the Agent-only save. This is
   deterministic client qualification, not actual authenticated Agent evidence.
3. Fresh release JS target, analyzer, format, focused widgets and Chromium pass.
   Fresh wide SSH and compact Remote/keyboard-focused optional action captures
   were loaded and inspected. Labels and SSH limitations are readable; compact
   form scrolls to submission and optional setup (not all controls fit above the
   fold). Existing helper text may ellipsize in compact width. Enlarged text was
   exercised in Flutter widgets, not an OS/browser font-setting claim.

## Executed checks

All final checks below exited 0. Complete logs and prior attempts are retained in
`build/t_98b85c1b/`; durations are measured subprocess wall time.

- `flutter gen-l10n` — 0.35s.
- `dart format --output=none --set-exit-if-changed lib/features/enrollment/screens/hermes_enrollment_screen.dart lib/features/hermes_chat/screens/hermes_chat_screen.dart lib/features/hermes_chat/screens/state/hermes_chat_layout.dart test/features/enrollment/hermes_direct_first_run_test.dart` — four files, zero changes, 0.17s.
- `timeout 5m flutter analyze` — no issues, 14.93s.
- `timeout 8m flutter test --concurrency=1 test/features/enrollment test/features/hermes_chat/screens/hermes_connection_primary_entry_test.dart test/features/hermes_chat/screens/hermes_chat_screen_auth_recovery_test.dart` — 123 passed, 22.30s.
- `timeout 5m flutter test --concurrency=1 test/features/enrollment/hermes_direct_first_run_test.dart` — four passed, 8.56s.
- `timeout 8m flutter build web --release -t lib/main_e2e.dart --no-wasm-dry-run` — fresh build, 39.43s; existing Cupertino font warning retained.
- `WING_APP_URL=http://127.0.0.1:18867/ CHROME_EXECUTABLE=<home>/.cache/ms-playwright/chromium-1234/chrome-linux64/chrome NODE_OPTIONS=--max-old-space-size=2048 timeout 12m npx playwright test --config=playwright.config.mjs playwright/tests/regression/direct-first-run.spec.mjs playwright/tests/regression/connection-primary-entry.spec.mjs --workers=1 --output=build/t_98b85c1b/browser` — ten passed, 242.49s.
- Scoped `git diff --check` — passed; exact file arguments in receipt.

Fixture launcher: `PORT=18867 HERMES_E2E_PORT=18868 timeout 40m node serve_web.mjs`.
Flutter 3.44.2 / Dart 3.12.2, Node 26.7.0, Chromium 151.0.7922.34 on Linux.
The documented Node 22 was not the installed executable.

Retries are not hidden: the predecessor was terminated during wasm dry-run;
JS-only compilation succeeded with `--no-wasm-dry-run`. Default Playwright browser
revision was absent, so installed Chromium was selected explicitly. Dedicated
browser tests initially assumed stale labels and exact textbox labels (Flutter
appends focused hints); selectors were corrected without changing transport or
weakening assertions. A later recapture run outlived the initial 20-minute fixture
launcher and failed with connection-refused; restarting the owned deterministic
fixture under 40-minute timeout produced the final ten passes. Recorded check
wall time through the receipt is 1245.04s; interrupted predecessor build duration,
review duration and monetary cost are unknown.

## Qualified versus delivered

Qualified: deterministic Flutter widgets and compiled Chromium on Linux only.
Implemented: scoped direct first-run entry and optional-management recovery.
Delivered to protected main: **NOT_CHECKED**; local agent commit/native review
handoff do not imply merge, release or owner acceptance. No upstream repositories,
shared services or other profiles were modified. Owned large build output is
removed after preserving source snapshots, compact logs, receipts and captures.

The first-run paragraphs in [connection paths](../product/desktop-connection-paths.md)
and [enrollment](../product/enrollment.md) were written concurrently by the docs
lane and describe this slice as unqualified. This receipt supersedes only that
qualification statement; those unrelated dirty docs are not claimed here.

Remaining: full `CONNECTION-SETUP-AUTH-MATRIX`, managed SSH lifecycle/host trust,
OAuth/acquisition, actual local/remote authenticated Agent qualification,
native GTK/physical Android, broad frozen combined gate and protected-PR delivery.
M1's live provider generation/approval/Stop/relaunch journey remains separately
open under `PARITY-LIVE-WORKFLOW`; no inference was attempted here. Neither M1
nor CONNECTION-PATHS is marked met. Next delivery step is independent native
review and integration-owner assembly; the next milestone slice remains the
already tracked live daily workflow, not another task created by this card.

Questions: none. Defaults applied: reuse existing direct form/channel; keep
management optional and SSH externally established.
