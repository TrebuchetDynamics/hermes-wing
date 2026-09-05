# Linux full-regression evidence — 2026-09-04

The full Linux feature inventory is exercised below. Extreme transcript stress
remains a performance limitation, recorded separately from functional regression. This report does not claim physical audio, signed distribution, or
production service qualification.

## Verified results

| Boundary | Result | Evidence |
| --- | --- | --- |
| Complete Dart unit/widget suite | **1,533 passed** in 4m 39s | `flutter test --concurrency=1 --coverage --reporter expanded` |
| Native Linux feature/app/router/shared inventory | **976 passed, zero failures** in 10m 21s | [Native runner](../../integration_test/linux_feature_regression_test.dart), 85 imported suites |
| Real Hermes Agent runtime with deterministic inference | **3 passed** | [Runtime integration tests](../../integration_test/linux_real_profiles_e2e_test.dart) |
| Actual Linux secure storage across app processes | **Write and verify phases passed** | [Keyring tests](../../integration_test/linux_secure_storage_integration_test.dart), fresh D-Bus session and GNOME Keyring |
| Browser functional regression on Linux | **35 passed** across five suites | Surfaces, CORS/SSE, approvals, Agent TTS, session/run lifecycle |
| Wing Link | **Full race suite passed**, nine tested packages | `(cd wing_link && go test -race ./...)` |
| Node tooling | **47 passed** | `node --test test/tooling/*.mjs`, Node 22 |
| Static checks | **Passed** | `flutter analyze`; Dart format check; `git diff --check` |
| Dependency audit | **Zero vulnerabilities** | Node 22 `npm audit` |
| Native production build | **Passed** | `flutter build linux --release --no-pub` |
| Deterministic browser build | **Passed** | `flutter build web --release -t lib/main_e2e.dart` |

The full Dart coverage receipt contains **17,523 / 19,883 lines (88.13%)**.
Unit and native counts overlap: the native runner executes existing feature
regressions in the Linux engine, so these counts must not be added together as
unique tests. The final unit and native runs include all test-harness corrections and the
large-message regression.

All five final functional browser suites passed in fresh processes with
`--retries=0`. Smoke and screenshot-only entrypoints were not used as qualification.
An earlier bootstrap-hook timeout is superseded by this complete final pass.

## Feature inventory exercised

| Area | Behavior covered |
| --- | --- |
| Enrollment and local setup | Pairing input, malformed/expired handoffs, credential failures, platform intents, setup progress, packaged commands, retry and accessible layouts |
| Chat and sessions | Composition, per-session drafts/history, gateway/profile switching, session CRUD/search/filtering/grouping, bulk selection/deletion and branching |
| Transcript | Markdown, code/diffs, copy/export, repeated context menus, selected-text keyboard copy, safe links/images, streaming, text scale and viewport reconciliation |
| Runs and approvals | Concurrent/background work, stop/retry/queue/steer, capability grants, approval identity and cancellation, reconnect without mutation replay |
| Voice controls | Capture/recognizer ownership, cancellation, lifecycle handling, partial results, TTS gating/playback/stop, unsupported-state behavior |
| Profiles, Projects and providers | Capability gates, directory handles, profile lifecycle and setup, provider/model controls, write-only credential forms, SOUL revision conflicts |
| Tools, schedules and Office | Inventories, filtering, refresh, scope, navigation and unsupported-operation states |
| Settings and gateway management | Health, trust/revocation UI, connection rotation, themes, diagnostics/redaction and preferences |
| Shared presentation | Adaptive navigation, keyboard/focus, semantics, 200% text, reduced motion, loading/error states |
| Agent/Wing Link boundaries | Full transport/domain and Go race suites, including authorization, operations, containment, protocol and lifecycle logic |

Support remains as documented in [Routes](../product/routes.md). Exercising an
unsupported-state test does not turn that operation into a supported feature.
Android presentation variants run inside the Linux engine are not Android device
qualification.

## Defects fixed and regression evidence

1. **Gateway disposal:** asynchronous startup/refresh could notify a disposed
   directory and start further work. Disposal now invalidates refresh/activation
   generations; startup and workers stop applying stale results. Two new tests
   reproduced and cover disposal during cached startup and an in-flight load.
2. **Repeated desktop context menus:** Flutter's selection toolbar could remain
   over the transcript after Wing's own message menu closed. Message text now
   uses the existing Wing menu while retaining selection and keyboard copy.
   Repeated native menu actions and a new selected-excerpt clipboard test pass.
3. **Unbroken-text parsing:** the Markdown parser's plain-text shortcut requires
   following whitespace and repeatedly scans suffixes of a long trailing word.
   A narrow terminal-word syntax consumes that word once, preserving the normal
   GFM syntax paths for punctuation and links. The new 100 KB rendering regression
   retains complete, selectable text.
4. **Code-block rendering:** code and diff text reuse a selection region instead
   of creating a read-only editable input for each block or diff line. Full code
   copying, expansion and diff presentation remain covered. The formerly
   timing-out 100 KB code benchmark completes its full repeated workload.
5. **Large-message accessibility freeze:** the intermediate 1 MB code workload
   exhausted Flutter 3.44.2's live semantics-node identifiers. CPU samples showed
   the ID-allocation loop in `SemanticsNode.attach`, rather than a slow parser.
   Messages over 32,768 characters now use a bounded scrollable block list.
   Offscreen blocks are unmounted; the complete source remains available to
   rendering, code copying and message copy/export. The regression checks bounded
   mounted blocks, Page Down, reaching the final block and copying it, including
   200% text and reduced motion. The benchmark scrolls this inner viewport.


The isolated keyring helper also handles desktop-portal FUSE mounts and the race
where a portal finishes unmounting during cleanup. Its final complete run exited
successfully and removed its temporary state.

The native harness also needed corrections: explicit fake storage and text-input
channels; propagation of framework pointer-cancellation events after popups;
platform-specific expectations/themes; stable first-run-tip arrangements; waits
for asynchronous packaged assets; and direct-channel recovery fixtures that do
not change into a saved-gateway directory mid-test. Callback-ownership speech
cases use a longer outer deadline; dedicated timeout tests retain their short
budgets. These changes do not weaken production timeouts or capability checks.

An intermediate 975-case native run finished with three test failures during
severe host memory pressure (RAM nearly exhausted, swap full). After the targeted
corrections, the fresh complete run passed all 975 cases.

## Actual runtime and storage checks

A separate temporary Hermes home ran the installed Agent. The observed installed
checkout was `24f5a60ed1dd382ee453567a9abe1b72316d5e65`. The configured local
inference service stopped responding during the first attempt; provider-backed
chat failed. An isolated deterministic OpenAI-compatible inference fixture then
allowed these **real Agent API/channel** flows to pass:

- Native UI session creation and a streamed provider response.
- Health, tool and model inventories; session create/rename/fork/select/delete;
  disconnect/reconnect and authoritative reconciliation.
- Accepted-run steering and stop, followed by reconnect with no duplicate user
  submission.

These are real Agent runtime checks with simulated inference, not evidence that
an external model provider is available. No existing user sessions or profiles
were changed. The isolated services and their credential-bearing state were
removed after testing.

The keyring test used the actual Flutter secure-storage plugin with an isolated
D-Bus session and unlocked GNOME Keyring. One app process stored independent,
random Agent and Wing Link credentials; a second process recovered both,
verified separation, and cleared them. Plaintext credentials were also checked
absent from ordinary preferences. Only credential digests crossed the app-process
boundary outside secure storage. This qualifies that tested Linux secret-service
path, not hardware-backed protection or locked-session behavior.

## Transcript stress matrix

The [raw receipt](linux-transcript-2026-09-04.json) preserves the original failed
run. Its 100 KB paragraph case reached a 14,416 ms streaming update (including a
requested 50 ms pump). The original 100 KB code case timed out after ten minutes;
eight following cases had invalid guarded-function failures, not independent
measurements.

The bounded renderer completed all five 100 KB cases and 1 MB paragraphs, plus
all twelve mounts of 1 MB code. The latter's streaming/long-jump phase exceeded
ten minutes and was terminated. The three later 1 MB cases were not measured in
that run. CPU samples showed widget teardown and selection-listener removal.
An experimental per-block selection change was slower and was reverted.

These are partial profile measurements, not a successful full stress matrix or
smoothness qualification. The complete source and artifact hashes for each
measured version are in the receipt. Final functional validation is separate.

| Bounded-view case | Mount p95 (ms) | Maximum stream update including pump (ms) |
| --- | ---: | ---: |
| paragraphs, 100,000 bytes | 567 | 434 |
| code, 100,000 bytes | 551 | 3,424 |
| line, 100,000 bytes | 601 | 270 |
| table, 100,000 bytes | 600 | 2,406 |
| unclosed, 100,000 bytes | 484 | 70 |
| paragraphs, 1,000,000 bytes | 1,483 | 3,284 |

An isolated Dart parser probe with the terminal-word rule parsed 100 KB of
unbroken text in 2,852 microseconds and 1 MB in 23,125 microseconds. These single
JIT probe samples are diagnostic evidence, not native rendering measurements.

## Reproduction and limits

The target was Ubuntu 24.04.4 Linux x64, Flutter 3.44.2 / Dart 3.12.2, Node 22.22.2,
Go 1.26.1, Xvfb and Mesa llvmpipe software rendering. Native build development
libraries were extracted locally because system installation was unavailable.
Commands inherited `PKG_CONFIG_PATH` and `LIBRARY_PATH` for those libraries.

```bash
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze
flutter test --concurrency=1 --coverage --reporter expanded
(cd wing_link && go test -race ./...)
node --test test/tooling/*.mjs
xvfb-run -a flutter test -d linux integration_test/linux_feature_regression_test.dart --reporter expanded
scripts/run_linux_secure_storage_regression.sh
flutter build linux --release --no-pub
flutter build web --release -t lib/main_e2e.dart
npm audit
git diff --check
```

The real-Agent target additionally requires `WING_LIVE_PROFILE_MANIFEST` pointing
to an owner-only ephemeral credential manifest and an isolated test runtime.
Browser functional tests use `serve_web.mjs` and these Playwright specs in fresh
processes: `browser-surfaces`, `browser-cors-streams`,
`chat-approval-confirmations`, `chat-tts`, and `hermes-lifecycle`.

No smoke entrypoint was used as qualification. Native feature tests inject
services and synthetic input; they do not qualify physical microphones,
acoustics, native IME input, external provider availability, signed installation,
service updates/rollback, or hardware-accelerated rendering. Linux default device
speech capture/TTS remain unavailable; the runtime tested here did not advertise
Agent audio. Service/release logic tests are not production installation evidence.

Final functional validation used baseline `d542f86b373542d8b0d1c6ad04d5e8541c458a38`
plus the production patch with SHA-256 `b988a65c2f8d9aedf1f417294164623783cd1bda0d521a28dcf87acfcfae3a0e`
(`git diff --binary -- lib` before staging). Performance receipts identify
their own earlier measured patches and bundles separately.
