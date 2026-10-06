# Desktop continuation — explicit session-model picker

Occurrence: 2026-10-03 22:00 local. Bounded verification only; no implementation change or acceptance-card transition.

## Ownership and binding

The [goal ledger](../plans/2026-10-03-desktop-port-goal.md) and primary conversation release agree prior scopes are released. Delegation and terminal tools returned no active handles; process census found no competing Flutter/Dart/Xvfb/fixture/Playwright command. One owner claimed this receipt, the ledger, generated build output and wing scratch artifacts before execution. No subagents or persistent processes were dispatched.

The already-dirty worktree was preserved. Before/after SHA-256 maps of 499 scoped production/test/platform/browser/script and dependency/config files were identical. Manifest digest: `20f7eda21499bfc4e9b1b68842783e12918e9aaa16b0dbec0d70a518e85b345a`. Compiled `build/web/main.dart.js` digest: `ca26b754738822a031d12acdcb2545424aa920cee7cd4132e3ce5333605ed7ee`. This binds the exercised source subset, not all unrelated dirty documents or runtime state. No upstream writes, personal auth inspection, installs, inference, commits, releases or scheduler changes occurred.

## Executed gate

```sh
flutter test --no-pub --concurrency=1 --reporter=json \
  test/features/hermes_chat/widgets/session_model_picker_sheet_test.dart \
  test/features/hermes_chat/widgets/session_model_picker_search_test.dart \
  test/features/hermes_chat/screens/hermes_chat_session_picker_test.dart
flutter build web --release --no-pub -t lib/main_e2e.dart
PORT=9280 HERMES_E2E_PORT=9281 node serve_web.mjs
CHROME_EXECUTABLE=/usr/bin/chromium \
  WING_APP_URL=http://127.0.0.1:9280/ HERMES_E2E_PORT=9281 \
  PLAYWRIGHT_JSON_OUTPUT_FILE="$TMPDIR/desktop-cron-2200-picker/playwright.json" \
  ./node_modules/.bin/playwright test \
  playwright/tests/regression/session-model-picker.spec.mjs \
  --workers=1 --retries=0 --reporter=list,json \
  --output="$TMPDIR/desktop-cron-2200-picker/browser-artifacts"
```

Each command exited 0. Widget command ran 04:02:09–04:02:21 UTC October 4 (October 3 local); fresh build 04:02:21–04:03:08; Chromium 04:03:08–04:03:22. Parent parsed JSON events/reporter results rather than inferring success from process exit:

- **26 widget tests passed, zero failed/skipped**, excluding loader pseudo-tests. Includes raw session-only identity, unconfigured/stale catalog rejection, pending double-confirmation inhibition, keyboard selection/cancellation, 390px keyboard inset with 200% text, inventory/disposal races, confirmed-lock versus catalog default, and profile/session/inventory/connection/pending roundtrip invalidation. Late session-switch success cannot close a stale picker as saved.
- **2 Chromium journeys passed**, one each at 390px and 1280px; zero failures/skips/flaky and exactly one attempt each. Production Chat/picker performed case-insensitive search, provider filtering, clear/reset, excluded-provider no-results, explicit raw selection, rejected first confirmation, deliberate retry, confirmed identity on reopen and Escape cancellation.
- Both attached synthetic fixture receipts were decoded and validated: exactly three deliberate lock attempts with `{provider: alpha, model: alpha/model-99}`; confirmed runtime readback `{provider: alpha, model: alpha/model-99, model_lock: accepted, route_source: session}`. Search/filter and Escape assertions preserved lock counts; readback was session-scoped. The receipt reports lock attempts, not a comprehensive audit of every possible mutation route.

Environment: Linux Chromium 152.0.7977.75 on Ubuntu 24.04.4 LTS; Flutter 3.44.2 framework `c9a6c484230f8b5e408ec57be1ef71dee1e77020`, Dart 3.12.2; Node v26.7.0 differs from intended Node 22. Existing flutter_tts Wasm dry-run warnings persisted; this was a JS-release build, not Wasm qualification.

## Evidence and cleanup

Scratch directory: `/home/xel/.hermes/profiles/wing/cache/scratch/desktop-cron-2200-picker/`.

`results.json` records commands/exits/timestamps; `picker-tests.log`, `build.log`, `journeys.log`, `playwright.json`, `validated-artifacts.json`, SDK/version logs, source manifests and baseline Git status preserve observed evidence. `run.py` is a bounded synchronous runner (widget 120s, build 180s, browser 120s, outer deadline 480s) with fixture cleanup in finally.

Exclusive fixture PID `1473650` was terminated/reaped with exit -15. Both owned ports returned connection-refused code 111 afterward. No existing listener was reused or terminated. No browser/service/display remains owned by this run. Two evidence-helper errors were corrected without rerunning tests: read-file envelope parsing and inline base64 attachment handling. They were tooling parsing errors, not failed product tests or same-tick gate retries.

## Limits and next checkpoint

This verifies the explicit session-model picker subset through synthetic Agent responses and production Flutter UI. It does not establish actual Agent/provider inference, native process relaunch, full keyboard-only browser traversal, physical accessibility, Android, profile administration or the integrated daily-use milestone. The [previous browser receipt](2026-10-03-desktop-cron-2143-browser.md) and this run remain separate scenarios.

Next dependency-ready scope: read-only source/fixture assessment of composing explicit profile/model selection into the complete single-session Chat/approval/Stop/reload journey, with exact identity/readback/count coverage and bounded proposed regression scope before edits. Do not repeat these unchanged suites. Native development dependencies, separately reviewed native integration and private approved-target authentication remain distinct owner-only gates; no native retry or auth scan was performed here.

Run summary: not_available — host accounting was not exposed.
