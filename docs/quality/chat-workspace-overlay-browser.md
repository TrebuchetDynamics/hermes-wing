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
dismissal and draft entry use real rendered controls. The shell-history cases now traverse and activate shell entries by Tab/Enter,
including compact Settings through More. Bootstrap and draft entry still use
test hooks and a composer click; these are not end-to-end keyboard-only journeys.
Clicking the composer after return does not prove automatic shell return focus.

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

## Session-owner replacement follow-through

Four additional compiled cases replace the active session while Settings or
Profiles remains open, at both widths and 200% text. The existing E2E create-session
hook invokes the production channel; the test binds the replacement to the exact
session ID returned by the synthetic server, rather than accepting transient null
selection as a different owner. Browser Back, Forward and Escape must retain that
new identity, return URL and empty transcript. The old history and Thinking control
must stay absent. Exactly one deliberate session creation is allowed; no prompt,
Stop or approval is sent by overlay navigation.

This is **session replacement within the same endpoint/profile**, driven through
an existing test seam, not rendered profile/connection switching. It does not
qualify late completion of a replaced active run or cross-endpoint credentials.
No production behavior, hook or fixture protocol changed.

A rebuilt negative control deliberately retained the previous active session after
successful creation. All four new cases failed at the exact returned-session ID
assertion. The production source was restored byte-for-byte before final rebuild.
This proves that the owner precondition is meaningful, not coverage of every
possible stale-route or asynchronous-response bug.

## Chat-local focus follow-through

Four additional compiled cases exercise rendered Settings/Profiles slash suggestions
at both widths and 200% text. Each checks Close, Escape and browser Back; the
actual DOM editor must regain focus with its consumed command text empty, without
a compensating composer click. The exact return URL and complete channel summary
stay unchanged, with zero observed API mutations and page errors.

The rebuilt Flutter 3.44.2/Dart 3.12.2 app passed all 20 overlay browser cases under
Node.js 22.5.1 and system Chromium, with no retries. The first four new cases failed
on an incorrect text selector: Flutter exposes a button whose accessible name
includes the slash command and its description. Switching to that actual button
role/name fixed the harness; it did not change production behavior. The preceding
16 browser cases already passed on the same compiled app.

## Keyboard shell-entry follow-through

The four shell-history cases now reach the actual rendered Settings/Profiles
control using the existing keyboard actor, assert its exact role/name and focus
inside the viewport, and activate it with Enter. Compact Settings first reaches
More, then the sheet's Settings action. Both initial entry and deliberate reopen
use this path; the other overlay cases retain pointer-entry coverage.

On the unchanged production app based on `b451d87e`, the rebuilt deterministic
Flutter 3.44.2/Dart 3.12.2 application passed all 20 overlay cases under Node.js
22.5.1 and system Chromium, with zero retries. Analyzer and 25 focused router/
receipt tests passed. The first browser attempt passed 17 cases and failed three
because the new helper incorrectly assumed every control had an `aria-label`.
Using the same rendered-text fallback as the keyboard actor corrected the test;
no production code or capability changed. Independent read-only review approved
the exact test source.

This qualifies keyboard shell entry and existing modal keyboard dismissal in
Chromium, not automatic shell return focus, visible focus styling, keyboard-only
bootstrap, Linux GTK keyboard entry or physical input.

## Remaining acceptance

The separate [Linux GTK receipt](chat-workspace-overlay-native.md) now covers
shell entries and retained draft/transcript through keyboard Close/Escape and
framework Back, with an in-memory channel. It does not promote this browser's
HTTP/SSE evidence to native transport proof.

Profile/connection replacement, late old-run completion after replacement, shell
return focus and native streaming remain unqualified. GTK now separately covers
chat-local slash/Tab-completion/Manage focus return; browser Manage/Tab-completion,
Android, physical keyboard/IME, screen readers and live Agent/provider behavior
remain unqualified. Keep the original task and acceptance open; next qualify
remaining owner-switching and shell-focus behavior, without repeating these matrices.
