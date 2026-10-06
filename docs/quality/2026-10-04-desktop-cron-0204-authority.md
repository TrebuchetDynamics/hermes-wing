# Desktop continuation — metadata-only model authority, 2026-10-04 02:04

## Result

Added a production-channel Chat widget regression at **390px and 1280px**.
Exact off-page `older-A` / `coder` metadata survives Chat remount and displays
`shared-model`. Two authenticated catalog providers expose the same model ID.
Opening the real picker passes **no confirmed session lock**; the catalog pair
is a draft. Selecting the other provider, cancelling and reopening leaves the
server-owned session model unchanged, discards the draft and emits **zero
mutations**. No provider is inferred from model text.

This pins existing behavior, not a behavior fix or a manufactured failing RED.
The picker currently labels catalog drafts as `Selected`; the test does not
assert that this is authoritative session identity or sufficient parity wording.
The integrated browser's exact restored-pair oracle remains unchanged and failed.
No synthetic runtime decoder, shadow pair cache or model POST replay was added.

## Ownership and source trace

Admission: goal ledger releases prior scopes; `hermes cron list` shows only this
continuation running and hourly autogoal completed. Native process/delegation lists
are empty and OS QA census shows no Flutter/build/browser/fixture/display owner.
Autogoal's latest session records deferral rather than a product task handoff.
One direct owner leased only the new test, goal ledger and this receipt, plus
scratch evidence. No workers or external coding executor were dispatched.

- [Prior source assessment](2026-10-04-desktop-cron-0147-runtime-pair.md) traces
  Agent's exact-session model-only projection and Desktop's local override store.
  Neither synthetic fixture runtime nor Desktop privileged storage grants Wing
  confirmed-pair read authority. No upstream checkout was changed or executed.
- [New authority test](../../test/features/hermes_chat/screens/hermes_chat_model_authority_test.dart)
  uses the existing [restoration HTTP harness](../../test/features/hermes_chat/gateways/hermes_gateway_session_restoration_test.dart)
  and production channel/directory, not a fake picker channel. Endpoint-store origin
  and synthetic credential match the harness. Riverpod owns directory disposal
  after provider construction; no double teardown is introduced.
- [Chat picker composition](../../lib/features/hermes_chat/screens/state/hermes_chat_layout.dart)
  supplies `currentSessionModel` only from an accepted exact-session lock.
- [Picker](../../lib/features/hermes_chat/widgets/session_model_picker_sheet.dart)
  initializes a catalog draft without a lock and changes drafts locally until
  explicit confirmation. The regression opens this real user surface twice at
  each width, changes provider, cancels, and checks state plus request recording.
- [Model restoration regression](../../test/features/hermes_chat/screens/hermes_chat_model_restoration_test.dart)
  and [picker regressions](../../test/features/hermes_chat/screens/hermes_chat_session_picker_test.dart)
  ran alongside the new target. Existing sources remained read-only.

## Executed verification

Linux Flutter widget runner; Flutter 3.44.2 revision `c9a6c48423`, Dart 3.12.2.
This is not a launched native desktop application or compiled browser journey.

Scratch: `/home/xel/.hermes/profiles/wing/cache/scratch/desktop-cron-0204-authority/`.

1. `dart format test/features/hermes_chat/screens/hermes_chat_model_authority_test.dart`
   — exit **0**, one file formatted. Bound 30s.
2. `flutter test --no-pub --concurrency=1 --reporter=json test/features/hermes_chat/screens/hermes_chat_model_authority_test.dart test/features/hermes_chat/screens/hermes_chat_model_restoration_test.dart test/features/hermes_chat/screens/hermes_chat_session_picker_test.dart`
   — exit **0**, **18 passed, 0 failed/errors/skipped**; includes both new width
   cases. 08:06:49–08:07:00 UTC, bound 120s.
3. `flutter analyze --no-pub` — exit **0**, no issues. 08:07:00–08:07:05 UTC,
   bound 120s.
4. Parent JSON/source gate — exit **0**, both new cases present, 460 pre-existing
   execution-source hashes unchanged. `verified.json`, `source-before.json`,
   `results.json`, `format.log`, `tests.log`, `analyze.log` preserve exact evidence.

One preparation helper failed with `KeyError: content` before writing a test or
running any verification command; direct file creation resolved the tool response
shape issue. No failed test gate was retried or assertion weakened.

## Review, cleanup and next checkpoint

Direct source review: test-only scope, deterministic synthetic data, explicit
operation-admission assertion before opening the picker, exact restored ownership,
canonical history, empty confirmed locks, and zero recorded mutation requests.
Existing integrated browser rejection/confirmation/restoration/count assertions,
production implementation, ROADMAP and upstreams were preserved. Independent
review remains open. Formatter/analyzer/widget results are not runtime/card acceptance.

All commands were synchronous and exited; no service, display, browser, child or
persistent process was started. Closing document/link/diff checks and fresh QA
census are recorded in `close.json`; ledger ownership released afterward.

Next checkpoint: exact confirmed provider/model restoration still requires a
supported advertised read contract or separately reviewed native integration.
Review the existing native design's model-read authority/security criteria before
any implementation lease; do not rerun the unchanged failing browser workflow or
weaken its oracle. Full integrated Escape/resume/final-count proof, native process
relaunch, approved live inference and independent acceptance remain open.

Run summary: not_available — host accounting was not exposed.
