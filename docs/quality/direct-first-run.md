# Direct first-run Agent entry

> Reference correction: [official Desktop authority](official-desktop-reference.md). Prior Desktop source citations and parity conclusions in this document are withdrawn. Wing test results remain historical behavior evidence only.

## Integrated Agent-only consumer regression closure — t_2f66df41

This section supersedes the partial combined-suite evidence below, not its
historical receipts. `CONNECTION-LINK-REMOVAL` and `CONNECTION-PATHS` remain open;
service/packaging retirement and live qualification are outside this slice.

Original pre-edit admission returned `worker_start_admitted` using the card's
`pass_workspace.py` command, manifest `pass-51360244646a857d-dd90ebf6d75a4ac39311d5f5c31acc07.json`
and SHA256 `a5aadd03abdee089f040049df2fe570da0dccf8b0e34b1ad3082c0c2ad7262ca`.
Clean detached base: `5df931b33e5c4aaf8c098cc20e698a846f5b7255`.
Original tool history establishes ordering; a later replay is not admission.

### Smallest repair and acceptance evidence

The full named union initially returned **1509 passes, two failures**. First,
[Android SSH/Remote entry](../../test/features/hermes_chat/screens/hermes_ssh_no_cli_test.dart)
tapped an off-screen Remote chip after scrolling through Local/SSH setup, then
failed the URL-field assertion at old line 83. The test now brings the existing
control into view before tapping, matching its other mode transitions. Second,
[Remote auth explanation](../../test/features/hermes_chat/screens/hermes_remote_auth_explanation_test.dart)
still required the retired name at old line 67. It now asserts Agent access-token
and host-management-token distinction and rejects the retired name. Provider-key,
OAuth limitation, explicit retry, no-connect and semantics checks remain intact.
Focused GREEN: **six passes**. No production defect was demonstrated; production,
localization, callers, fixtures, configuration, exports and dependencies are
unchanged. This is test repair and fresh qualification, not new connection support.

- Fresh entry/auth retry: [six public Chromium cases](../../playwright/tests/regression/direct-first-run.spec.mjs)
  pass at 390/1280px, with redacted denial, explicit retry, canonical session history,
  no automatic retry and no Agent mutations or management requests. Browser SSH
  is explicitly unavailable and deliberately switches to Remote; Local is manual
  loopback entry, not native discovery.
- Saved-owner/auth recovery: [eleven production matrix cases](../../playwright/tests/regression/connection-production-matrix.spec.mjs)
  pass, including failed persistence, replacement-owner fencing, delayed discovery,
  saved endpoint keyboard edit/test and 2x zoom. Aggregation verifies ten real
  journey boundary receipts and five management-denial negative controls; no retries.
- Legacy handoff rejection, cancel/back, exact credential/profile/session ownership,
  raw-store preservation, no replay, TLS fail-closed guidance, redaction and
  accessibility retain their regressions in the complete **1511-pass** Flutter union.
  Platform overrides in widget tests are not physical Android execution.

### Executed checks and reproducibility

Linux host: Flutter 3.44.2 / Dart 3.12.2, Node 26.7.0 (not documented Node 22),
npm 11.19.0, system Chromium 152.0.7977.75. `timeout 5m npm ci` restored the locked
three packages, reporting zero vulnerabilities; lockfiles did not change.

```bash
dart format --output=none --set-exit-if-changed test/features/hermes_chat/screens/hermes_ssh_no_cli_test.dart test/features/hermes_chat/screens/hermes_remote_auth_explanation_test.dart
timeout 5m flutter analyze
timeout 15m flutter test --concurrency=1 test/features/enrollment test/features/local_setup test/features/hermes_chat/screens test/features/hermes_chat/gateways test/core/hermes/setup test/tooling/hermes_domain_authority_contract_test.dart test/tooling/enrollment_retirement_contract_test.dart test/tooling/link_localization_retirement_contract_test.dart
timeout 10m flutter build web --release -t lib/main_e2e.dart
WING_APP_URL=http://127.0.0.1:18995/ CHROME_EXECUTABLE=/usr/bin/chromium timeout 20m npx playwright test --config=playwright.config.mjs playwright/tests/regression/direct-first-run.spec.mjs --retries=0
timeout 10m flutter build web --release -t lib/main_connection_production_matrix_e2e.dart
WING_APP_URL=http://127.0.0.1:18995/ CHROME_EXECUTABLE=/usr/bin/chromium timeout 20m npx playwright test --config=playwright/connection_production_matrix.config.mjs
node playwright/support/connection_production_matrix_fixture.mjs playwright/.matrix-results/results.json
git diff --check
```

The direct target requires an owned `PORT=18995 HERMES_E2E_PORT=18996 node serve_web.mjs`
fixture with a successful health check and cleanup. Matrix configuration starts
its own fixture and requires its existing production `WingApp` entrypoint, not
`main_e2e.dart`. Heavy checks run sequentially. Analyzer reported no issues;
both JS release builds passed, retaining upstream `flutter_tts` Wasm dry-run and
Cupertino-font warnings. This does not qualify Wasm. First browser subprocess
durations: 43.24s direct, 108.35s matrix; the successful union reported 6m52s.
One earlier post-edit union invocation was interrupted by the terminal transport's
420s limit, not an assertion failure or pass; a tracked finite-timeout rerun passed.

Private logs, exact argv/exits/durations, lockfile hashes, browser receipts and
source manifest are retained in workspace `.dart_tool/t_2f66df41/`. The 678-file
test/build input manifest SHA256 is
`5d4375b3cd07a3354b1a22ca378f9535c7de97f67ac2c422afe649e261110e20`.
The mandatory finish gate repeats the listed checks and scoped local-link
validation before committing exactly these two tests and this receipt. Its exact
commit/ref and final receipt belong to the native review handoff; this document
is not a build input. Total review time and monetary cost are unknown.

Implemented: two attributable stale test regressions repaired. Qualified: the
named Linux-hosted deterministic Flutter and Chromium journeys. Delivered:
local candidate only, pending independent native review and coordinator integration;
no merge, push or publication by this worker. Native SSH, physical Android/Termux,
native Local discovery, live authenticated Agent/provider, full release and
service/packaging retirement remain **NOT_CHECKED**. The coordinator owns the
existing retirement/qualification next slice; neither parent nor milestone closes.

## Agent-only TLS recovery regression — t_b967a50b

This bounded continuation closes the stale TLS test dependency recorded below,
not `CONNECTION-LINK-REMOVAL`, `CONNECTION-LINK-RETIREMENT` or `CONNECTION-PATHS`.
Only the [auth-recovery test](../../test/features/hermes_chat/screens/hermes_chat_screen_auth_recovery_test.dart)
and this receipt changed. Production, localization, transport, fakes, dependencies,
user stores and ledger remain unchanged.

### Admission and source

The original pre-edit tool history records successful `worker_start_admitted`:

```text
python3 /home/xel/git/gormes/hermes-toolset/skills/autowork/scripts/pass_workspace.py --manifest /home/xel/.hermes/profiles/wing/autowork/pass-8403344eddc919b8-6944d399f8c34e37ac2c3e6b5696f91a.json --manifest-sha256 ac06ce35f8adf12c95b578c0ed8bf2017bd8ed007443dab5ddcb1bf300f585a0 --workspace /home/xel/.hermes/cache/scratch/autowork-passes/8403344eddc919b8-6944d399f8c34e37ac2c3e6b5696f91a
```

Clean detached base: `59a099c35115ce1e8d65f8456449c5dfeeaa620b`, the integrated
browser repair. Changed test SHA256:
`a4d70fd4f5ae0337fa92fb2130377b27b3da65f9653627411639a67541178d91`.
The finish gate's exact two-file commit/ref and check receipt belong to the native
card handoff; this receipt is not a build input.

### Acceptance and executed checks

The unmodified target reproduced RED: ten passes and one failure at old line 220,
expecting **Re-pair explicitly**. The corrected typed TLS case asserts the complete
current certificate/trusted-host guidance, including trusted-administrator
verification before reconnecting. It rejects **Re-pair**, retains opaque-error
redaction and asserts zero automatic connect calls after settling. Existing
auth recovery, explicit reconnect, equivalent-endpoint credential preservation,
duplicate-tap fencing, approval visibility and accessibility assertions remain
intact. No transport validation or fail-closed policy was changed.

Inspected source: [typed error presentation](../../lib/features/hermes_chat/screens/widgets/hermes_chat_error.dart),
[English copy](../../lib/l10n/app_en.arb) and
[transport failure mapping](../../lib/core/hermes/channel/api_channel/hermes_api_channel_connection.dart).
The scope reaches only the existing test and receipt: no caller, fixture, config,
export, dependency or generated localization changes are needed.

```bash
dart format test/features/hermes_chat/screens/hermes_chat_screen_auth_recovery_test.dart
timeout 10m flutter test --concurrency=1 --reporter expanded test/features/hermes_chat/screens/hermes_chat_screen_auth_recovery_test.dart
timeout 10m flutter test --concurrency=1 --reporter expanded test/features/enrollment test/features/hermes_chat/screens/hermes_connection_primary_entry_test.dart test/features/hermes_chat/screens/hermes_chat_screen_auth_recovery_test.dart test/tooling/hermes_domain_authority_contract_test.dart test/tooling/enrollment_retirement_contract_test.dart test/tooling/link_localization_retirement_contract_test.dart
timeout 5m flutter analyze
git diff --check
```

Linux-hosted deterministic Flutter results: focused GREEN, 11 passes (2s reported
test time); named union, 65 passes (41s); analyzer, no issues (6.3s); format,
zero changes; whitespace check passed. Scoped local Markdown link validation is
included in the finish gate, which repeats the required passing commands before
committing exactly these two files. No unexpected failures or retry fixes occurred
after the initial RED. Total execution/review time and monetary cost are unknown.

Implemented: current Agent-only TLS trust guidance is regression-covered without
legacy pairing promotion. Qualified: the named deterministic Flutter targets on
Linux only; platform overrides are not physical Android qualification. Delivered:
local candidate only, pending independent native review and coordinator integration.
The unchanged Chromium receipts below are preserved historical evidence, not fresh
browser execution. Native SSH, Android/Termux, native Local discovery, live
authentication/provider generation, packaging and the full release gate remain
**NOT_CHECKED**. The next slice remains coordinator-owned retirement/qualification;
this worker does not close the parent ledger or publish the candidate.

## Current public browser regression closure — t_ff373dd7

This section supersedes the historical entry/optional-pairing claims below.
It advances `CONNECTION-LINK-REMOVAL` / `CONNECTION-PATHS`, not their closure.
Only this receipt and the [six-case browser test](../../playwright/tests/regression/direct-first-run.spec.mjs)
changed. Production, fixtures, configs, dependencies, Agent references and ledger
are unchanged; no user state or credential migration is involved.

### Admission and source

The original startup guard ran successfully before any edit or test:

```text
python3 /home/xel/git/gormes/hermes-toolset/skills/autowork/scripts/pass_workspace.py --manifest /home/xel/.hermes/profiles/wing/autowork/pass-4256d7cb4183e49e-4512f94bcae24ae2b2a17aabe5e5582d.json --manifest-sha256 be6f9e77f1f6080d0c88443ce7001de023d8b8a1a02d3d90c58152ab1198e33c --workspace /home/xel/.hermes/cache/scratch/autowork-passes/4256d7cb4183e49e-4512f94bcae24ae2b2a17aabe5e5582d
```

Outcome: `worker_start_admitted`; clean detached snapshot at
`a8f59ecad082f8e6c28eb93b358a521a94b0bef8`. Original tool history, not a later
replay, establishes admission. Candidate identity is this base plus the owned
test SHA256 `764116db6ae99da4b60b40f06c5cd21f1358b463cd3199100cf0cc71f9b33b18`.
Fresh compiled `main.dart.js` SHA256:
`4a0bf0fead7c5e96fd1f7e005207475b233eac2a93277e41e779f944114ee598`.
`pubspec.lock` SHA256: `f089602c321af4a65d6f1dc70b6adef724079bedc8e4f1d0496f7b8e22641c89`;
`package-lock.json`: `f32c4b4d226bf6cef1a1f66733d4c2e065e0656d1223e89f17ceb68f42429b63`.
The finish gate's exact local commit/ref is recorded in the native card handoff;
the receipt itself is not a compilation input.

### RED → GREEN and acceptance

Original RED: a fresh release `main_e2e.dart` build followed by the unmodified
suite failed all six cases at old line 54: no public **Add Hermes** button in the
empty state. It now renders **Welcome to Hermes Wing**. The obsolete optional
pairing action is also absent in Chromium, not a hidden control to activate.

Decision: use the delivered public welcome actions, not synthetic connect hooks.
**Get Started** selects Local, **Connect via SSH** selects SSH, and **Connect to
Remote Hermes** selects Remote. Tab/Space reaches those actions, chips, form
fields and explicit submission/retry at both 390 and 1280px (height 1100px).
Existing contact activation still uses a click; this is not an entirely
keyboard-only session journey or screen-reader qualification.

The SSH-entry cases explicitly assert **Managed SSH is not available in this
browser. Use Wing on Android or desktop.**, no URL textbox and no submit button,
then deliberately select Remote before testing direct authentication. Their
receipts record `authMode: Remote`; they do not fabricate an SSH tunnel. Local
uses the browser's manual loopback Agent form, not native Hermes-home discovery.
Remote retains its nested VPN / NetBird / Tailscale choice.

All six cases retain the simulated 401, redacted private response, exactly one
denied attempt and no automatic retry during the existing 500ms observation,
then explicit retry, online contact and exact canonical history for
`synthetic-restoration-000`. Each records zero Agent mutations, management
requests and page errors. The existing matrix observer supplies fail-closed
management denial and broader mutation detection; the original legacy-route
prefix detector remains. Fixture-reset POSTs use the test request client, not
product traffic. `/enroll` and its direct form both reject QR, pairing paste,
use-another-computer and optional-pairing promotion. Two unchanged adjacent
browser-surfaces entry/enrollment cases also pass.

### Executed commands

Linux: Flutter 3.44.2 / Dart 3.12.2, Node 26.7.0 (not documented Node 22),
Chrome for Testing 151.0.7922.34. No package/tool upgrades were made. Initial
Playwright invocation failed before test discovery because this isolated
snapshot lacked `@playwright/test`; `timeout 5m npm ci --offline --ignore-scripts`
restored the locked three packages and reported zero vulnerabilities.

```bash
timeout 8m flutter build web --release -t lib/main_e2e.dart --no-wasm-dry-run
PORT=18867 HERMES_E2E_PORT=18868 timeout 40m node serve_web.mjs
node --check playwright/tests/regression/direct-first-run.spec.mjs
WING_APP_URL=http://127.0.0.1:18867/ CHROME_EXECUTABLE=/home/xel/.cache/ms-playwright/chromium-1234/chrome-linux64/chrome NODE_OPTIONS=--max-old-space-size=2048 timeout 12m npx --no-install playwright test --config=playwright.config.mjs playwright/tests/regression/direct-first-run.spec.mjs --workers=1 --output=build/t_ff373dd7/red
WING_APP_URL=http://127.0.0.1:18867/ CHROME_EXECUTABLE=/home/xel/.cache/ms-playwright/chromium-1234/chrome-linux64/chrome NODE_OPTIONS=--max-old-space-size=2048 timeout 12m npx --no-install playwright test --config=playwright.config.mjs playwright/tests/regression/direct-first-run.spec.mjs playwright/tests/regression/browser-surfaces.spec.mjs --grep 'fresh public|Hermes empty state|enrollment exposes direct' --workers=1 --output=build/t_ff373dd7/green
timeout 8m flutter test --concurrency=1 test/features/enrollment test/features/hermes_chat/screens/hermes_connection_primary_entry_test.dart test/tooling/hermes_domain_authority_contract_test.dart test/tooling/enrollment_retirement_contract_test.dart test/tooling/link_localization_retirement_contract_test.dart
timeout 5m flutter analyze
git diff --check -- playwright/tests/regression/direct-first-run.spec.mjs docs/quality/direct-first-run.md
```

Results: fresh initial compile 43.0s; existing Cupertino-font warning retained.
Original RED: six failures, no retries. First repaired run: six passed in 40.3s.
Final combined browser run: eight passed in 43.5s, no retries. Required Flutter
suite: 54 passed; analyzer: no issues (6.1s). Node syntax and scoped whitespace
checks passed. Compact browser contexts, six per-case receipts and results were
retained under workspace `.pi/t_ff373dd7/` before owned build-output cleanup.
The finish gate repeats required checks in sequence against the owned candidate.
These are reported tool durations, not measured total task/review time; monetary
cost and review duration are unknown. No visual inspection claim is made here.

Additional outside-scope check: the same Flutter command with
`test/features/hermes_chat/screens/hermes_chat_screen_auth_recovery_test.dart`
added returned 64 passes and one failure: **typed TLS failure gives trust recovery
guidance**, line 220 still expects **Re-pair explicitly**. Unchanged English
source now requires certificate/identity verification through a trusted
administrator before reconnecting. No test was weakened or production copy
changed. Coordinator dependency: reconcile that stale TLS expectation in its
own admitted slice before claiming the combined broader suite passes.

Implemented: six tests match current public entry and absence of legacy promotion.
Qualified: deterministic Chromium/Linux and named Flutter tests only. Delivered:
not integrated or published by this worker; independent native review of the exact
finish commit is pending. `CONNECTION-LINK-REMOVAL` stays in progress. Native SSH,
physical Android/Termux, native Local discovery, live authenticated Agent,
provider generation, packaging/removal, broad release gate and final milestone
acceptance remain **NOT_CHECKED**. The coordinator owns the next existing
retirement/qualification slice and the out-of-scope TLS test dependency.

## Historical first-run implementation — t_98b85c1b

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
