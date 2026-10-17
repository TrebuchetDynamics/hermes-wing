# Saved connection workflows: current-source offline increment

Task: CONNECTION-SAVED-WORKFLOWS. Goal: CONNECTION-PATHS.
Baseline: `542deae1048fd1d13f236678683a048a28913965`.
This receipt concerns the isolated task candidate, not canonical integration,
publication, native installation or live authentication.

## Scope and correction

The existing Local/Remote, saved-name/remove and saved-editor implementations are
retained. This increment fixes connection-lifecycle ordering and saved-host
keyboard visibility, reusing existing regression journeys in a current-source
composition check. It does
not add SSH or OAuth authority, an installer, a management service or Agent changes.
Raw legacy records and credential slots remain inert and preserved.

Public `connect()` previously waited for recovery-storage cleanup before acquiring
its connection generation. A later disconnect could invalidate the channel first,
then the obsolete connect could resume, acquire a new generation and reconnect.
The same pre-network gap existed in `connectLocalServeReads()`.

Both entry points now capture the existing recovery and connection generations
before cleanup and reject superseded continuation. Disconnect reserves both
invalidations synchronously, so its older cleanup cannot instead cancel a newer
connect. Disposal also invalidates the captured generations. No new protocol field,
credential migration or parallel owner store was introduced.

The single [channel regression](../../test/core/hermes/channel/hermes_connection_intent_test.dart)
uses a deterministic cleanup barrier. It covers an old direct/Local-read intent
superseded by disconnect, replacement or disposal, and a newer direct connect
following an earlier disconnect. Both ordering defects were observed failing before
the corresponding correction. Direct Agent traffic is recorded by the injected API
client; Local cases assert state/lifecycle rejection, not a native-network capture.

Official Desktop reference inspected read-only at
`158fd638da1629c8e62caf9ade1515d162def8ab`:
`apps/desktop/src/store/connections.ts:345–469` and the superseded-dial case in
`apps/desktop/src/store/connections.test.ts:313–342`. Its outcome is that only the
latest selected connection/profile activates. Wing preserves that outcome using
its existing channel generations, not Electron activation or backend authority.
This source trace is not a Desktop parity qualification.

The reused phone-guide checks also exposed stale harness navigation: documentation
buttons now live inside the existing setup-details disclosure. The widget cases
and shared enrollment fixture now open that public disclosure before using those
buttons. Preparation, denial, retry and owner-preservation assertions remain; no
production guide behavior changed and no duplicate journey was added. The reused
Remote retry check now finds the save-failure notice by its exact public text,
matching the current static-text semantics rather than requiring a group role.

A fresh compact browser editor run separately exposed a real focus defect: Tab
reached a saved-host action while its row remained above the visible scroll area.
The strict existing named-focus/viewport assertion failed even after fresh keyboard
traversal. Saved-host rows now reveal themselves when focus enters their controls,
using the existing focus-driven scrolling pattern. The test's visibility and
keyboard-only requirements remain unchanged; no pointer or scripted-scroll
workaround is used to qualify editor actions. The deferred reveal checks mounting,
not retained focus; a same-frame focus departure can still cause a row reveal.
It cannot change the selected endpoint or send an Agent request.

## Acceptance and evidence boundaries

- **Local existing-home/preparation-needed:** production enrollment widgets
  distinguish absent default metadata, found default directory and deliberately
  selected alternate directory. Chooser cancellation, Back and late results preserve
  the saved owner and inert records. Directory existence is discovery only: Wing
  neither reads Agent files nor proves an installation, starts a process or selects
  a Project. The Android-targeted widget journey uses the manual Termux guide,
  documentation failure/retry, direct denial and storage failure/retry. These are
  host-run fixtures, not Android or native chooser execution.
- **Remote auth/storage and retry:** existing public form tests cover denied
  authentication, sanitized errors, unconfirmed secure save, retained drafts and
  explicit retry. Reused late-save browser cases replace the channel through the
  existing qualification hook; they are not public saved-host replacement proof.
  The Remote explanation explicitly says browser OAuth is unsupported. No sign-in
  is simulated and a denial does not identify an OAuth-only server.
- **Name/edit/Test/remove:** existing public-control tests and browser journeys are
  reused rather than copied. Rename/remove cancellation, stable identity, uncertain
  writes and explicit retry remain covered. Editor Test is direct capability
  discovery only; it is not chat or inference readiness. Its browser owner bootstrap
  remains an existing qualification hook, distinct from public editor controls.
- **Colliding saved hosts:** the revised browser matrix saves two distinct loopback
  origins through Add Hermes, advertises the same supported query-profile context
  on both synthetic origins, opens A, parks A discovery, cancels through All chats
  and opens saved B through the public contact. Profile/session IDs collide, while
  origin-specific canonical history distinguishes their transcripts. After releasing
  A, it waits for A's downstream session-list response to finish and two browser
  frames before asserting B's selection, connected status, profile/session and
  history. This is a bounded response/render barrier, not an internal-future oracle.
  The complementary existing two-host widget journey drains delayed success/error
  completions and verifies exact origin, canonical history, draft and request counts.
- **Saved versus connected:** the compiled saved workflow checks that a successful
  Add persists the host without selecting a session; only explicit saved-contact
  selection loads canonical history. Successful discovery or persistence never
  claims model/provider readiness. Direct journeys require no Wing Link request,
  pairing, install prompt or management credential and allow no Agent mutation.

The [existing browser matrix](../../playwright/tests/regression/connection-production-matrix.spec.mjs)
now runs against the rebuilt `lib/main_e2e.dart`, using the root Playwright config.
It imports the existing direct-first-run, Remote retry, saved workflow and saved
editor cases instead of introducing duplicate journeys. The historical alternate
matrix config/aggregator and old setup entrypoint are not this execution path.
Existing [rename/remove](saved-connection-owner-safety.md),
[editor](saved-endpoint-edit.md), [native editor](saved-endpoint-edit-native.md),
[real-storage](saved-endpoint-storage-native.md) and
[two-host native](two-host-recovery-native.md) receipts retain their original scope;
this increment neither repeats their native work nor transfers their platform claims.

## Executed final checks

Linux-hosted Flutter 3.44.2 / Dart 3.12.2, Node 22.22.2 and Chromium
152.0.7977.75. These results apply to the final task candidate:

- Scoped `dart format --output=none --set-exit-if-changed`: five changed Dart
  files, zero changes. Both changed browser modules pass `node --check`.
- `flutter test --no-pub --concurrency=1 test/features/enrollment/ test/features/hermes_chat/screens/hermes_connection_primary_entry_test.dart`:
  **33 passed**.
- `flutter test --no-pub --concurrency=1 test/core/hermes/channel/hermes_api_channel_test.dart test/core/hermes/channel/hermes_connection_intent_test.dart test/features/hermes_chat/screens/hermes_chat_saved_connection_workflows_test.dart test/features/hermes_chat/screens/hermes_chat_saved_endpoint_edit_test.dart test/features/hermes_chat/screens/hermes_chat_remote_connection_retry_test.dart test/features/hermes_chat/screens/hermes_chat_two_host_recovery_test.dart test/features/hermes_chat/screens/hermes_remote_auth_explanation_test.dart test/features/hermes_chat/widgets/platform_local_connection_behavior_test.dart`:
  **412 passed**.
- `flutter test --no-pub --concurrency=1 test/integration/android_direct_setup_enrollment_test.dart`:
  **5 passed**, including 320/1024 logical widths at 1x/2x Flutter text. This is
  Android-targeted widget execution on Linux, not an Android application launch.
- `flutter analyze --no-pub`: **no issues**.
- `flutter build web --release --no-pub -t lib/main_e2e.dart`: **passed**.
  JavaScript SHA-256:
  `2cb23dbf3eadd4973518f1470749996d9efb6fac1db166fbbd78792e381e1e11`.
  Existing dependency Wasm dry-run warnings remain; no WebAssembly qualification.
- `npx playwright test --config=playwright.config.mjs playwright/tests/regression/connection-production-matrix.spec.mjs --workers=1 --retries=0 --max-failures=1 --reporter=list,json --output="$TMPDIR/browser-artifacts"`:
  **19 passed**, zero skipped/unexpected/flaky, 9.1 minutes. The real fixtures
  used allocated loopback ports 20112/20113; the owned server was stopped.
  Saved-editor cases include 390/1280 CSS widths at 1x/2x browser zoom, not
  additional Flutter text scaling. The four enlarged-text widget combinations
  remain separately attributed above.
- `git diff --check`, receipt-link validation and selected-source/evidence checks:
  **passed**. Independent read-only review found no Critical/Important blocker.

Evidence remains in the task attempt's supplied `$TMPDIR`: final command logs,
`browser-results.json`, `browser-exit.json`, `flutter-exits.json`,
`browser-artifacts/`, `candidate-inputs.json` and `workflow-summary.json`.
All 714 selected Wing source/test/harness/manifest fingerprints match the executed
candidate; this is not an SDK/package-cache inventory. Fourteen real-page boundary
receipts have zero Agent mutations, management attempts and page errors. Four
persistent editor receipts separately retain their read-only request assertions.
One intentional negative control issues a synthetic denied management GET and
proves the traffic detector rejects it; it is not part of a real connection flow.
Both two-owner receipts preserve B with colliding `default`/session identities.
No screenshots, browser profiles, build output or credentials are committed.

For a long supplied temporary path, Chromium's Unix socket needs a short lexical
alias. The supervising shell opened the same supplied directory with
`exec {slot_fd}<"$TMPDIR"` and passed `/proc/$$/fd/$slot_fd` as the browser process's
`TMPDIR`. Physical temporary files stayed inside the original task directory;
logs, JSON and artifact output paths used its original absolute path. This is
runner preparation, not a product change or a new storage location.

## Remaining qualification

No native application, physical chooser/keyring, Android device, SSH tunnel,
OAuth sign-in, real Agent credential, provider inference or personal runtime was
operated here. Installation/adoption, live authentication and OS-specific
persistence/chooser qualification remain separate. No main integration, push,
release or deployment is implied by this local task commit.
