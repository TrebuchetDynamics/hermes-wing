# Linux-host all-features verification

Date: 2026-10-06 (UTC). **Verdict: BLOCK for complete Linux/native qualification;
shared-code and compiled-browser coverage is substantial but not wholly green.**
Latest explicitly requested full current-source rerun: **3,489 passed, six failed**,
`npm run test -- --reporter expanded`, exit 1. All six remaining failures are the
current Connections keyboard fixture cases described below. Source fingerprints
still match `late-source-manifest.json` after that run; no root drift was found.
The five evidence Python runners independently pass syntax parsing. This does not
make the application's failed test gate green.
This is an execution receipt, not a release, parity, independent security-audit,
live Agent/provider, or native desktop support claim.

## Scope and source binding

- Exercised a copy of the dirty working source, including the three untracked Dart
  regression files, rather than only the staged shell delivery snapshot.
- Product source, tests, platform hosts, assets, package manifests, scripts,
  Playwright fixtures and source-contract documentation were copied under
  `.task-evidence/linux-all-features/project/`. No upstream repository, personal
  Agent state, credentials or personal desktop was used as a test target.
- Per-file SHA-256 manifests: `source-manifest.json` (baseline inputs),
  `followup-source-manifest.json`, and `late-source-manifest.json`.
- **Harness completeness caveat:** `.metadata` and `site/` were supplied during
  initial setup; the extensionless `wing-cli` was inadvertently absent when its
  seven source/CLI checks ran. The unchanged executable was then supplied, and
  the affected CLI cases were rerun in the separate current-source follow-up.
  Those seven initial failures are harness failures, not product failures.
  The baseline full-suite result remains failed; it is not relabeled green.
- Other workers changed the root during execution. `freshness-final.json` records
  changes/deletions against the baseline. All baseline `lib/` inputs remained
  byte-identical at the final source check. The approval-settlement test changed;
  the six-case shell-activity test was removed by the delivery lane. Late Go
  OmniRoute dependency/test edits were independently copied and rerun. Documentation
  changes are not silently attributed to the earlier full suite.
- Follow-up snapshot `project-followup/` captured current source again. The first
  follow-up included a now-deleted test path and therefore had an additional
  **test-loader failure**. The final focused invocation excludes that nonexistent
  target and passes; it does not replace a full current-tree gate.

## Host/tooling and native prerequisite result

Observed: Linux `7.0.0-31-generic`, x86_64; Flutter `3.44.2`, framework
`c9a6c48423`, Dart `3.12.2`; Go `1.26.1`; Node `26.7.0`; `/usr/bin/chromium`;
`/usr/bin/xvfb-run`. Node differs from the documented Node 22 baseline.
Exact version/preflight outputs are retained in `host-preflight.json`.

`gtk+-3.0` metadata is present. **Six development modules are missing:**

1. `libsecret-1`
2. `gstreamer-1.0`
3. `gstreamer-app-1.0`
4. `gstreamer-audio-1.0`
5. `gstreamer-video-1.0`
6. `gstreamer-plugins-base-1.0`

- `bash scripts/run_linux_e2e.sh` exits **2** before any app launch, explicitly
  reporting its required libsecret/GStreamer modules missing.
- `flutter build linux --release` exits **1** at **CMake configuration**:
  `audioplayers_linux/linux/CMakeLists.txt:24` calls `pkg_check_modules`, and
  `FindPkgConfig.cmake` cannot find `gstreamer-1.0`; output ends
  `Unable to generate build files`.
- No Linux executable was produced or launched. Native interactive, clipboard,
  GTK save dialog, IME, secure-storage/keyring, process relaunch, microphone and
  native accessibility checks are **NOT_CHECKED**, not failed product behaviors.
- The rootless release launcher was inspected but not run: its fallback downloads
  Debian packages and removes a build tree. No package download/install, sudo,
  fake headers/libraries, plugin suppression or personal display workaround was
  used. The existing dependency blocker `BLK-20261005-003` was not modified.
- `DISPLAY` was removed for executed commands. Browser processes were headless,
  with temporary Playwright contexts; no personal display/session was driven.

Reproduction after approved dependency provisioning, in an isolated source copy:
`bash scripts/run_linux_e2e.sh` and `flutter build linux --release`.
Full native qualification additionally needs the guarded daily-workflow,
secure-storage, native input and export launchers; their source exists but was
not executed past this failed native prerequisite.

## Executed gates (observed_check_results/v1)

Each raw receipt records exact argv, cwd/source, exit status, start/end epochs and
log path: `checks.json`, `extra-browser-checks.json`, `followup-checks.json`,
`late-checks.json`, and `diagnostic-browser-checks.json`.
All logs named below are in `.task-evidence/linux-all-features/`.

| Baseline command | Exit | Log |
| --- | ---: | --- |
| `flutter pub get --offline` | 0 | `pub-get.log` |
| `bash scripts/run_linux_e2e.sh` | 2 | `native-launcher.log` |
| `flutter build linux --release` | 1 | `native-build.log` |
| `dart format --output=none --set-exit-if-changed lib test integration_test` | 0 | `format.log` |
| `flutter analyze` | 0 | `analyze.log` |
| `flutter test --concurrency=1 --reporter expanded` | 1 | `flutter-test.log` |
| `go test ./...` | 0 | `go-test.log` |
| `flutter build web --release -t lib/main_e2e.dart` | 0 | `web-build.log` |
| `npm run web:e2e` | 1 | `web-e2e.log` |

- Formatter: **454 files, zero changes**, exit 0; read-only formatting.
- Analyzer: **No issues found**, exit 0.
- Full Dart suite: **3,470 passed, 29 failed**, final summary `16:52 +3470 -29:
  Some tests failed`, exit 1. Executed once with concurrency 1. Default Flutter
  widget/unit execution is not `integration_test` native execution.
- Wing Link: **nine tested packages passed**, main package has no test files;
  `go test ./...` exit 0. No individual Go test-case count is inferred from this
  package-level output.
- Web target: real release compilation of `lib/main_e2e.dart`, exit 0. Warnings
  include `flutter_tts` WebAssembly dry-run interop incompatibilities and an absent
  Cupertino font family. The tested artifact is the normal compiled browser target,
  not a WASM qualification.
- `npm run web:e2e` exits **1**. Its default runner stops on a failed spec, so this
  invocation alone does **not** cover the entire default browser list. Remaining
  deterministic suites were actually executed individually afterward, with fresh
  Playwright processes and recorded results, rather than silently omitted.
- npm audit, CI, physical-device and signed-release gates were **NOT_CHECKED**.

| Late current-source command | Exit | Log |
| --- | ---: | --- |
| `flutter analyze` | 0 | `late-analyze.log` |
| `flutter test --concurrency=1 --reporter expanded test/tooling/package_scripts_contract_test.dart test/tooling/wing_cli_contract_test.dart test/core/hermes/channel/hermes_approval_settlement_owner_test.dart` | 0 | `late-targeted.log` |
| `go test ./...` | 0 | `late-go-test.log` |

Late targeted Flutter result: **35 passed**. This covers both CLI contract files
and the revised approval-settlement file. Late analyzer reports no issues;
late Wing Link Go tests pass all nine tested packages. No full-suite current-tree
PASS is claimed from these focused results.

## Compiled-browser execution

The fixture used only owned loopback listeners. Initial npm ports: `18767/18768`;
supplemental: `18777/18778`; targeted diagnostics: `18877/18878`.
Live-provider/environment opt-ins were removed from the runner environment.

- Initial `browser-surfaces`: **11 expected + 1 flaky**, no terminal failure.
  Diagnostics timed out waiting for E2E startup once, then passed on retry.
- Initial `browser-cors-streams`: **1 passed + 1 failed**. The failing approval
  deadline case never reached its behavior assertion because the E2E connect hook
  failed to initialize within 8 seconds on both attempts.
- Fresh complete supplemental set: **25 suites; 94 expected, 6 unexpected,
  2 flaky, 0 skipped**. Counts are parsed from retained Playwright JSON, not
  progress/retry lines. `browser-summary.json` is the per-suite count source.
- Supplemental CORS suite: **2 passed**, including the >21-second SSE approval
  deadline assertion. Preserve the initial startup failure as a flaky/environment
  signal rather than presenting all attempts as green.
- Connections health had two retry-passing cases; keyboard Connections had six
  clean passes. A separate no-retry keyboard rerun and no-retry Diagnostics rerun
  each passed one case.
- Default live say-hi was not executed with credentials; live API/provider,
  externally served Pages, and packaged release-artifact suites were deliberately
  excluded from the supplemental deterministic set. They require different
  authorized targets and are **NOT_CHECKED**.

| Supplemental suite | Expected | Unexpected | Flaky | Exit |
| --- | ---: | ---: | ---: | ---: |
| `browser-cors-streams` | 2 | 0 | 0 | 0 |
| `chat-approval-confirmations` | 1 | 0 | 0 | 0 |
| `chat-tts` | 18 | 1 | 0 | 1 |
| `chat-window` | 4 | 0 | 0 | 0 |
| `connections-health` | 4 | 0 | 2 | 0 |
| `connections-keyboard` | 6 | 0 | 0 | 0 |
| `desktop-daily-workflow` | 0 | 2 | 0 | 1 |
| `desktop-navigation-groups` | 1 | 0 | 0 | 0 |
| `global-session-access` | 1 | 0 | 0 | 0 |
| `hermes-lifecycle` | 2 | 0 | 0 | 0 |
| `hermes-smoke` | 7 | 1 | 0 | 1 |
| `inventory-keyboard` | 4 | 0 | 0 | 0 |
| `persona-keyboard` | 12 | 0 | 0 | 0 |
| `persona-ownership` | 8 | 0 | 0 | 0 |
| `production-chat-journey` | 2 | 0 | 0 | 0 |
| `profile-keyboard` | 2 | 0 | 0 | 0 |
| `profile-search` | 2 | 0 | 0 | 0 |
| `provider-keyboard` | 2 | 0 | 0 | 0 |
| `provider-search` | 2 | 0 | 0 | 0 |
| `schedule-search` | 2 | 0 | 0 | 0 |
| `session-model-picker` | 0 | 2 | 0 | 1 |
| `session-restoration` | 6 | 0 | 0 | 0 |
| `tools-search` | 2 | 0 | 0 | 0 |
| `transcript-export` | 2 | 0 | 0 | 0 |
| `e2e-screenshots` | 2 | 0 | 0 | 0 |

The daily-workflow suite requires
`scripts/support/desktop_daily_workflow_fixture.mjs`, not bare `serve_web.mjs`.
The bare-fixture run failed both widths at the initial history check. A separate
run with the **correct existing fixture**, unchanged test and explicit output
directory got through initial selection, rejected/accepted model save, approval,
authoritative Stop and exact off-page restoration, then **failed both widths at
model-picker reopen after reload** (`desktop-daily-workflow.spec.mjs:192`).
Do not count it as a complete daily-workflow pass.

## Per-feature coverage (verification_matrix/v1)

PASS below means the named deterministic methods passed, **not** full platform or
live support. Where a feature has both passing subflows and a failing acceptance
case, its overall row is FAIL and the passing subflows remain explicitly named.

| Feature / route | Result | Actual evidence and boundary |
| --- | --- | --- |
| Chat `/hermes` | FAIL overall; bounded subflows PASS | Production Chat journey passes at 390/1280px (approval/deny/Stop/transport recovery); CORS/SSE, lifecycle, transcript window and exact session restoration pass. Full daily workflow/model restoration and two stale-locator browser cases fail. No actual inference. |
| Office `/office` | PASS bounded | Unit/widget Office checks and compiled browser connected-empty/recovery route; shell navigation includes Office. Contacts/search/activation have deterministic widget coverage. No 3D, account/wallet or live contacts qualification. |
| Profiles `/profiles` | PASS bounded | Full-suite lifecycle/editor/catalog/directory/ownership tests; browser search and keyboard clear/escape at 390/1280; unsupported administration fails closed. Wing Link transactional setup tested with fakes, not a deployed installation. |
| Persona `/soul` | PASS bounded | Eight browser ownership/fidelity cases plus twelve keyboard save/cancel/conflict/readback/reopen cases; profile-scoped revision and late-owner regressions in Dart. Native/live SOUL not checked. |
| Providers `/providers` | PASS inventory/gating | Browser read-only inventory, literal search and keyboard escape/clear, zero-mutation ownership assertions; Dart credential/model capability tests. Paid validation, inference, OAuth and existing-profile compatibility are not qualified. |
| Tools `/tools` | PASS bounded | Browser inventory/search/disclosure/refresh plus keyboard workflows at 390/1280; exact scoped/read-only receipts; Dart search/ownership/admission tests. MCP administration/discovery mutations unsupported. |
| Schedules `/tasks` | PASS inventory/gating | Browser search/filter/clear/read-only refresh/failure/Retry plus keyboard workflows; Dart scoped bootstrap, ownership and pull-refresh cases. Create/edit/run/pause/delete and Kanban unsupported. |
| Connections `/gateway` | FAIL current widget harness; browser PASS | Browser health recovery and six keyboard journeys pass; saved-host/trust/owner cases run in Dart. Six current client/router keyboard widgets fail before keyboard interaction because the history fixture is invalid. Native/live health and lifecycle unqualified. |
| Settings `/settings`, voice/diagnostics | PASS bounded, initial startup flake retained | Full-suite appearance/preferences/theme tests, browser settings screenshots, keyboard voice controls and redacted export. Diagnostics fresh no-retry check passes. Real Linux menu/clipboard/audio not exercised. |
| Enrollment `/enroll`, direct manual connection | PASS deterministic | Browser secure empty-state enrollment, computer setup to pairing and manual connect; Dart payload/intent/journey tests; Go pairing/security contracts. No real QR camera, installed service or enrollment credential persistence. |
| Local setup `/setup/local` | PASS typed/fake controls; native NOT_CHECKED | Dart local Linux setup stage/Stop/conflict and refusal tests plus Go bootstrap/setup isolation; actual install/service bootstrap was not run. |
| Approval / Stop | PASS shared/fixture; live NOT_CHECKED | Correlated approve/deny, terminal-history reconciliation, no silent replay, stale ownership and retry gates; revised approval settlement independently passes. No real tool authorization/provider execution. |
| Session restore / global Open/New | PASS bounded; model restore FAIL | Six browser exact off-page restoration/retry/supersession cases, global Open/New and grouped shell navigation pass. Correct daily fixture restores exact session/history without replay before model picker reopens with the wrong selected provider/model. Native process relaunch not checked. |
| Transcript text/Markdown export | PASS browser/shared; native NOT_CHECKED | Two browser download/readback cases and full-suite export/redaction/size/owner cases; real GTK dialog not launched. |
| Clipboard / copy outcomes | PASS mocked settlement; native NOT_CHECKED | Full-suite session-ID, diagnostics, error, surface and transcript clipboard success/rejection/owner cases. No personal OS clipboard was read or written by a native app. |
| Preferences / light-dark | PASS shared/browser | Settings/theme/pin/draft/voice persistence tests; shell light/dark/focus tests and browser reload voice preference. No native keyring/preferences relaunch evidence. |
| Keyboard / large text / reduced motion | PASS many slices; gaps remain | Browser keyboard Tools/Schedules/Profiles/Providers/Persona/Connections and grouped navigation; 390/1280 widgets including 200% text, large Markdown/plain reader and transcript projection. Six invalid Connections fixtures do not qualify their keyboard cases. Not a screen-reader or Linux IME qualification. |
| Wing Link setup/security | PASS Go/Flutter contracts | All nine Go packages: pairing, protocol, scopes/revocation, approval/idempotency, TLS/identity, audit redaction and fixed compatibility. Synthetic tests do not equal independent security audit. |
| Wing Link lifecycle/update/rollback | PASS deterministic; service NOT_CHECKED | Go service/health, activation and updater/rollback tests; no personal systemd restart/update, production signing or real service qualification. |
| Directory grants | PASS deterministic | Go rooted grant/browser containment/revocation/symlink tests and Dart approved-child-folder sheet; no live grant or file enumeration performed. |
| Discover `/discover`, Memory `/memory` | UNSUPPORTED | Planned destinations, not working features in the live route tree. No fake implementation is tested as support. |
| Kanban, Hermes Project creation/assignment, full admin | UNSUPPORTED | Missing exact advertised contracts; controls remain hidden/unavailable. Project-aware Chat, peer admin, general CLI/config, remote OAuth and existing-profile provider compatibility are not granted by inventories. |
| Physical mic/speech/AEC, secure storage, Linux IME/window lifecycle | NOT_CHECKED | Native build prerequisite failed; browser TTS uses deterministic speech/audio seams. Physical/acoustic and plugin support cannot be inferred. |

## Failures and diagnosis (observations versus hypotheses)

### Full Dart suite

All 29 exact baseline failed test identifiers are retained in
`baseline-failed-cases.json` and listed below. They group as:

1. **Seven CLI cases:** missing copied `wing-cli`; harness omission, subsequently
   resolved by supplying the unchanged source executable. Final focused run passes.
2. **Six Connections keyboard cases:** both widths × success/failure/unsupported.
   `gateway_keyboard_client_test.dart:87` returns a history envelope without
   `object: list` or `session_id`. `HermesMessagePage.fromJson`
   (`lib/core/hermes/models/hermes_session.dart:244–254`) rejects it; connection
   bootstrap catches the exception and reports error status. The test does not
   assert connected state before querying health controls at lines 153/164.
   Read-only tracing supports a fixture failure, not a demonstrated keyboard defect.
   These six cases fail again in the follow-up snapshot; no oracle was weakened.
3. **Six baseline shell-activity cases:** expected synchronous activity/listener
   and queued-admission behavior differs from that baseline implementation.
   `activate` sets busy before awaiting disconnection but only notifies afterward
   (`hermes_gateway_directory.dart:1043–1053`); profile selection awaits its queue
   predecessor before setting busy (`926–955`). This explains the early empty
   transition list and false busy observations. Deeper admission/reentrancy
   expectations also failed; no product fix is asserted. The delivery lane removed
   this test file during the run. Its failure is historical snapshot evidence,
   not an extant current-tree target.
4. **Ten old approval-settlement cases:** baseline history fixture `{data: []}`
   violates the same identity contract, leaving no connected session; unawaited
   send rejects and the test waits for a stream until its 30-second timeout.
   A different worker revised the test with valid history, explicit connection/
   session assertions and bounded startup. The final unchanged-current-source
   focused run passes its twelve cases; this verifier did not edit that test.

- `test/tooling/package_scripts_contract_test.dart: wing-cli keeps token output explicit`
- `test/tooling/package_scripts_contract_test.dart: wing-cli creates a pairing link without exposing the token`
- `test/tooling/package_scripts_contract_test.dart: wing-cli brokers one token once and renders its QR locally`
- `test/tooling/wing_cli_contract_test.dart: wing-cli rejects malformed origins without a traceback`
- `test/tooling/wing_cli_contract_test.dart: wing-cli rejects invalid broker setup without a traceback`
- `test/tooling/wing_cli_contract_test.dart: wing-cli does not forward credentials through enrollment redirects`
- `test/tooling/wing_cli_contract_test.dart: wing-cli rejects unsafe enrollment responses without a traceback`
- `test/features/gateway/gateway_keyboard_client_test.dart: actual client/router Connections keyboard success at 390.0 / 200%`
- `test/features/gateway/gateway_keyboard_client_test.dart: actual client/router Connections keyboard failure at 390.0 / 200%`
- `test/features/gateway/gateway_keyboard_client_test.dart: actual client/router Connections keyboard unsupported at 390.0 / 200%`
- `test/features/gateway/gateway_keyboard_client_test.dart: actual client/router Connections keyboard success at 1280.0 / 200%`
- `test/features/gateway/gateway_keyboard_client_test.dart: actual client/router Connections keyboard failure at 1280.0 / 200%`
- `test/features/gateway/gateway_keyboard_client_test.dart: actual client/router Connections keyboard unsupported at 1280.0 / 200%`
- `test/features/hermes_chat/gateways/hermes_directory_shell_activity_test.dart: directory reports pending activation and clears after failure=false`
- `test/features/hermes_chat/gateways/hermes_directory_shell_activity_test.dart: directory reports pending activation and clears after failure=true`
- `test/features/hermes_chat/gateways/hermes_directory_shell_activity_test.dart: queued profile work remains busy until its final operation settles`
- `test/features/hermes_chat/gateways/hermes_directory_shell_activity_test.dart: synchronous listener cannot overtake an admitted profile request`
- `test/features/hermes_chat/gateways/hermes_directory_shell_activity_test.dart: synchronous activity listener preserves newer intent cancel=false`
- `test/features/hermes_chat/gateways/hermes_directory_shell_activity_test.dart: synchronous activity listener preserves newer intent cancel=true`
- `test/core/hermes/channel/hermes_approval_settlement_owner_test.dart: dispose retires delayed approval failure=false`
- `test/core/hermes/channel/hermes_approval_settlement_owner_test.dart: dispose retires delayed approval failure=true`
- `test/core/hermes/channel/hermes_approval_settlement_owner_test.dart: retired false settlement preserves replacement admission origin=false busy=false`
- `test/core/hermes/channel/hermes_approval_settlement_owner_test.dart: retired false settlement preserves replacement admission origin=false busy=true`
- `test/core/hermes/channel/hermes_approval_settlement_owner_test.dart: retired true settlement preserves replacement admission origin=false busy=false`
- `test/core/hermes/channel/hermes_approval_settlement_owner_test.dart: retired true settlement preserves replacement admission origin=false busy=true`
- `test/core/hermes/channel/hermes_approval_settlement_owner_test.dart: retired false settlement preserves replacement admission origin=true busy=false`
- `test/core/hermes/channel/hermes_approval_settlement_owner_test.dart: retired false settlement preserves replacement admission origin=true busy=true`
- `test/core/hermes/channel/hermes_approval_settlement_owner_test.dart: retired true settlement preserves replacement admission origin=true busy=false`
- `test/core/hermes/channel/hermes_approval_settlement_owner_test.dart: retired true settlement preserves replacement admission origin=true busy=true`

### Browser failures

- `chat-tts.spec.mjs:662`, **Agent speech stops when starting a new session**:
  line 679 resolves non-exact `New session` to both route-local `New session` and
  global shell `New Session`. Both attempts fail strict mode **before** new-session
  TTS cancellation is exercised. This is observed locator ambiguity; no claim
  that speech cancellation itself is broken.
- `hermes-smoke.spec.mjs:120`, **Hermes route renders connected session/capabilities
  in a real browser e2e build**: identical two-button ambiguity at line 187, after
  its connection/capability assertions. Neither test was changed to make it green.
- `session-model-picker.spec.mjs:5`, **session picker search/filter/rejected
  confirmation/retry**, both widths: initial `Hermes model` exact checkbox is
  absent (line 13). Source now prefers recovered session metadata model
  `hermes-agent` to a fallback label (`hermes_chat_layout.dart:1330–1341`);
  the correctly prepared daily journey uses `hermes-agent` and reaches model save.
  A stale initial locator is the source-supported hypothesis; the standalone
  test's full search/filter workflow remains failed in this pass.
- `desktop-daily-workflow.spec.mjs:73`, both widths: bare fixture lacks the required
  later-page inventory projection; initial history fails at line 94. With the
  correct existing fixture, the real remaining failure is at line **192** after
  reload: expected `Selected: Display alpha (alpha) — alpha/model-99`, but the
  retained DOM snapshot shows **`Selected: Display beta (beta) — shared`** while
  the shell still displays **`Model: alpha/model-99`**. The picker reads only
  accepted in-memory `sessionModelLocks` (`hermes_chat_layout.dart:1217–1232`);
  metadata display alone does not reestablish a confirmed provider/model lock.
  This is an observed deterministic model-restoration mismatch, not merely
  a missing bootstrap fixture. It blocks complete daily-workflow qualification.
- CORS and Diagnostics startup failures and two Connections health retry-passing
  cases remain recorded as flaky startup/timing evidence. No proven production
  root cause is assigned to those intermittent timeouts.

## Artifacts, integrity and completion boundary

- Raw gate logs/argv receipts and full source manifests are retained under
  [the evidence directory](../../.task-evidence/linux-all-features/).
- Per-suite supplemental JSON includes semantic snapshots, request traces and
  image attachments as base64. Later Playwright processes replace their ordinary
  `test-results/` directory; rely on the retained per-suite JSON, not old ephemeral
  paths printed in earlier logs.
- The correct daily run preserves its error-context snapshots under
  `daily-correct-fixture-artifacts/`, including the mismatched restored selection.
- Six keyboard focus crops were decoded from the no-retry Connections JSON into
  `retained-focus/`. The Chat shell focus and refresh crops were visually inspected:
  they show the expected bounded controls without obvious clipping. This is narrow
  Chromium evidence, not a full visual/accessibility or native verdict.
- Baseline source manifest SHA-256: `545761c0a344c59c205acecaf57afe7c7247b51f0291015d8aac57fa4291fe5a`.
- Compiled browser `build/web/main.dart.js` SHA-256:
  `fc523a6a52c53bc62d18bc3b8908b4cc3bf035e86b839df75e621422857380fd`.
- This lane changed only this report and its isolated evidence/harness files.
  No root product/test edits, Git staging/commit/push, credentials, Agent changes,
  personal runtime reconfiguration, paid API calls or service restarts were made.

**Remaining:** approve/provision the existing missing Linux development
prerequisites, then run native isolated launch/input/export/storage/relaunch checks;
repair or refresh separately owned stale/invalid test fixtures and locators;
resolve the observed provider/model selection restoration mismatch; rerun the
relevant cases and a complete gate on a newly pinned integrated source snapshot.
Real Agent/provider generation still needs a separately approved disposable
runtime and supported private authentication. A green fixture is not that proof.
