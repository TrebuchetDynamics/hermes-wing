# Compiled Chat workspace overlay navigation

WING-TASK-408 remains in progress. This is bounded Chromium qualification of
existing production router/shell behavior, not a new modal implementation or
complete Desktop parity.

## Exercised behavior

`playwright/tests/regression/chat-workspace-overlay.spec.mjs` runs eight cases:
Settings and Profiles, each at 390px and 1280px, with the existing E2E 200% Flutter
text-scaling seam. Connected journeys open through production shell controls,
check Close autofocus and Tab/Shift+Tab return, use browser Back/Forward, dismiss
with Escape and keyboard-activated Close, and verify the original draft, rendered
transcript, complete return URL and channel summary. Separate disconnected deep
links return to Chat without connecting. Observed API mutation requests and page/
layout errors must remain empty in connected journeys.

Bootstrap alone uses the existing synthetic HTTP-channel connection hook; the
profile remains explicitly unselected (`selected_profile_id: null`). Navigation,
dismissal and draft entry use real rendered controls. The test does not claim
that clicking a shell entry is a keyboard-only entry journey, or that clicking
the composer proves automatic return focus.

The suite is included in `playwright/scripts/run_tests.sh` so normal `npm run
web:e2e` execution retains the regression. To run it alone after rebuilding:

```bash
flutter pub get --offline --enforce-lockfile
flutter build web --release --no-pub -t lib/main_e2e.dart
# Start the existing serve_web.mjs on two unused loopback fixture ports.
# WING_APP_URL must match PORT; set CHROME_EXECUTABLE if necessary.
npx playwright test --config=playwright.config.mjs \
  playwright/tests/regression/chat-workspace-overlay.spec.mjs \
  --workers=1 --retries=0
```

## Executed checks

On the isolated candidate based on `a60596f8`, Flutter 3.44.2/Dart 3.12.2,
Node.js 22.5.1 and system Chromium:

- Eight compiled browser cases passed with zero retries.
- The existing 24 `test/router/chat_workspace_overlay_test.dart` cases passed.
- `flutter analyze --no-pub` and locked offline dependency resolution passed.
- A negative control replaced only the overlay's retained `push` with `go`, then
  rebuilt the compiled app. Three connected cases failed at retained-draft
  recovery; four disconnected cases and compact Settings still passed. The exact
  production source was restored, not committed as a workaround.
- Early harness failures (semantic roles/names, an incorrect selected-profile
  expectation, and Escape outside the shared actor's allowed keys) were repaired.
  They are not product failures or passing acceptance evidence.

## Streaming follow-through

Four additional compiled cases exercise Settings and Profiles at both widths and
200% text. A deliberate rendered Send starts the existing synthetic reasoning SSE
scenario through the production HTTP channel. The tests require a streaming turn,
open the overlay, traverse browser Back/Forward while the same stream remains
active, then release the synthetic server while the overlay is still visible.
The channel must consume completion before dismissal. Escape returns to the exact
Chat URL, completed reasoning and rendered reply/history. The browser must issue
exactly one run submission and no approval, Stop or other mutation.

The synthetic server release is a test-controller operation, not a Wing approval
or live inference. This covers a pending reasoning stream and terminal reply burst,
not progressive token pacing or an actual provider. No new hook, fixture protocol,
dependency or production Dart behavior was added. The existing default runner
already selects this suite.

A compiled negative control changed only retained `push` to replacing `go`.
Three streaming cases rejected the lost return URL; compact Settings remained
green. Source was restored byte-for-byte before rebuilding the final application.
This detects navigation loss, not every possible stream interruption.

## Remaining acceptance

Owner replacement, chat-local slash/Manage entries, automatic focus restoration,
the isolated Linux app journey, Android, physical keyboard/IME, screen readers and
live Agent/provider behavior remain unqualified. Existing widget evidence is not
promoted to those targets. Keep the original task and its acceptance open; next
qualify owner replacement and execute the separate native journey.
