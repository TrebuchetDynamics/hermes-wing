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

## Browser shell-return focus follow-through

The four keyboard shell-history cases now capture the originating control's
actual rendered role/name before entry and assert automatic DOM focus there after
browser Back, Forward followed by Escape, and keyboard Close. Compact Settings
returns to More, not its dismissed sheet action. No compensating pointer or
keyboard input precedes these assertions. Draft readback occurs after the last
return, so inspecting the editor cannot change the focus remembered by Forward.

All 20 compiled Chromium overlay cases passed at 390/1280px and 200% text, with
zero retries, on Flutter 3.44.2/Dart 3.12.2 and Node.js 22.5.1. Analyzer and all
24 focused router tests passed. Independent native-source review approved the exact
spec. No production behavior, fixture protocol, dependency or capability changed.
The initial attempt passed 16 cases; four failed because clicking the composer
between Back and Forward changed the expected return focus. Removing that
intermediate input retained final draft readback and tested an uninterrupted
shell-focus journey instead; this was a harness correction, not a product fix.

A rebuilt negative control cleared focus before the production overlay push.
Compact Profiles failed at automatic focus return after Back; compact Settings
passed and the remaining two cases were not run after the first failure. An
earlier mutation clearing focus only after the overlay future completed was not
detected by the four cases. These are bounded sensitivity checks, not exhaustive
focus-defect coverage. Production source was restored byte-for-byte for the final
rebuild and browser run.

## Late old-run completion after session replacement

Four additional compiled cases start a pending reasoning SSE run with rendered
Send, open Settings or Profiles, then replace the session through the existing
production-channel seam. Only after the exact returned replacement ID is selected
does the test release the original run. The server's completed run and original
session history must contain the expected reply. A read-only deterministic-entry
session summary then waits for the original session's exact canonical reply ID
and completed status in the production channel's background cache. This is the
client reconciliation barrier; downloading SSE alone is not sufficient.

The modal stays visible throughout completion. Back, Forward and Escape retain
the replacement session, empty active transcript and original return URL; old
reply/reasoning controls do not become visible. Exactly one deliberate run
submission and one deliberate session creation are allowed, with no navigation
Stop, approval or extra send. The original four non-streaming replacement cases
remain in the same parameterized matrix. All 24 compiled Chromium cases pass at
390/1280px and 200% text, with zero retries. Analysis and the 24 router tests pass.
The new summary exists only in `lib/main_e2e.dart`, exposes IDs/status without
content, and neither selects a session nor changes production channel behavior.

This qualifies same-endpoint/profile background completion, not profile or
connection replacement, reconnect, native streaming or a live Agent.

Independent host-native source review approved after adding the exact client
reconciliation barrier. A compiled negative control changed only final background
history reconciliation to reselect its old session. Compact Settings failed the
new post-barrier owner assertion; three cases were not run after the failure
limit. The mutation was restored byte-for-byte before the final rebuild. This
checks owner-hijack sensitivity, not every possible late-response failure.

## Rendered profile-switch recovery

Two additional compiled cases select **Chat with Coding profile** in the rendered
Profiles overlay, at 390/1280px and 200% text. Per-test synthetic advertised
profile reads reuse the existing profile-keyboard pattern; coder has a distinct
session and assistant history. Only bootstrap uses the existing connection and
default-inventory hooks. The actual profile action, deliberate overlay reopen,
browser Back/Forward and Escape must retain coder's exact session/history, exclude
the old profile's transcript and active-row marker, and issue zero API mutations.
Session inventory and history requests must carry the explicit coder query.

The valid fixture reproduced a production defect: the profile action selected
coder successfully but pushed the same Chat shell above its retained instance,
leaving blank content in Chromium. A production-router widget regression failed
with duplicate Navigator page keys and no hit-testable composer. Profiles now
pops a retained `ChatWorkspaceOverlay` instead of pushing a second shell. Direct
Profiles entry without a retained workspace keeps its existing push-and-Back
behavior. The two new widget cases assert the same mounted Chat, exact return URL,
selected profile, visible composer and no residual route stack.

On Flutter 3.44.2/Dart 3.12.2, Node.js 22.5.1 and system Chromium, all 26 rebuilt
browser cases passed with zero retries/skips/flaky outcomes. Analysis, Dart format
and the 64 focused router/profile widget tests passed. Independent native-source
review approved the source after fixture/recovery rework. Initial harness failures
included a missing history envelope identity and an incorrect expectation that
programmatic pop creates a browser Forward entry. The final case deliberately
reopens Profiles before testing Back/Forward; production validation was not weakened.
The pre-fix blank-Chat reproduction and red widget test are retained privately;
no separate deliberate production mutation was necessary for this bug fix.

This is rendered same-endpoint profile selection over synthetic HTTP, not connection
replacement, profile switching during an active run, GTK profile-switch execution,
real authentication or live Agent/provider qualification.

## Distinct-connection owner replacement

Four compiled cases replace the channel's connection while Settings or Profiles
remains open, at 390/1280px and 200% text. The existing E2E connect hook calls the
production `HermesApiChannel`; an intercepted distinct loopback origin supplies a
new session and assistant history. Only synthetic read responses are used; this
is not a rendered Connections selection, saved-host credential test or live Agent.
After replacement settles, the modal must still be visible. Back, Forward/Escape
and deliberate reopen/Close must retain the exact replacement session/state and
original Chat URL, display its distinct history, exclude old history and issue
zero API mutations. Assertions require reads from the replacement origin rather
than accepting an unchanged original owner. The default browser runner includes
these cases through the existing overlay spec.

The rebuilt final matrix passed all 30 Chromium cases with zero retries, skips or
flaky outcomes on Flutter 3.44.2/Dart 3.12.2 and Node.js 22.5.1. The 26 focused
router tests and `flutter analyze --no-pub` passed. This is test-only follow-through;
production source is unchanged and parent acceptance stays open.

A compiled negative control made production reconnect a no-op when already
connected. The compact Settings case failed the exact replacement-session barrier;
three cases were not run after the failure limit. That temporary line was restored
byte-for-byte before rebuilding the final candidate. An initial test-harness
failure came from Flutter's duplicated Profiles tooltip name after shell rebuild;
the helper now accepts the same bounded label duplication as Settings. No product
validation or behavior was changed.

## Chat-local Manage and keyboard suggestion recovery

Six additional compiled cases exercise the rendered profile picker's **Manage
profiles** action and Settings/Profiles suggestion activation by Tab traversal and
Enter, at 390/1280px and 200% text. Bootstrap alone uses the existing synthetic
connection/default-inventory hooks; Manage uses the same advertised synthetic
profile-read contract as the rendered profile-switch cases. Direct Tab execution
from the composer remains native-desktop-only: web preserves browser traversal,
and the tests assert Tab alone neither executes the suggestion nor clears its
prefix. This is an accessible browser path, not web Tab-completion parity.

Close, Escape, browser Back and Forward/Escape must restore the composer
**before any compensating input**. Manage retains the unsent draft; local command
execution deliberately clears its prefix. The canonical transcript, exact channel
state and complete Chat URL remain unchanged, with zero API mutations. The default
browser runner already selects the expanded spec.

These cases reproduced a browser-history focus defect: explicit pop returned focus,
but history restoration could retain a removed suggestion or profile-picker control
as the underlying route's focus target. The shared overlay opener now requests the
caller-owned return focus before pushing, so Navigator retains that target for
history restoration. Its existing mounted/current-route check still protects the
post-pop request. Shell entries omit that optional focus node and keep their
originating-control behavior. No Agent/transport or profile-selection behavior changes.

Initial diagnostics also attempted an invalid unfocused semantics-textarea draft
read. That did not prove data loss: the rendered draft remained visible. The final
regression reads the focused editor only after asserting automatic return focus;
there is no focus-assertion bypass. Waiting for profile-picker route disposal did
not repair the defect and that experimental production change was removed. The
pre-fix failing assertions and final source-bound logs are retained privately.

The rebuilt application passes all 36 Chromium cases with zero retries, skips or
flaky outcomes on Flutter 3.44.2/Dart 3.12.2 and Node.js 22.5.1. Analysis, Dart
formatting and 84 focused router, shell-focus and profile-picker regressions pass.
The six new cases pass with all automatic-focus assertions enabled, including
Back and Forward/Escape; the source change is two lines in the shared opener.

## Active-run rendered profile switching

Two additional Chromium cases select **Chat with Coding profile** in the rendered
Profiles overlay while the original synthetic reasoning run is streaming. They
cover 390/1280px and 200% text. The replacement must settle to the explicit `coder`
profile, distinct session and canonical coding history before the controller
completes the original run. Canonical server readback requires that original
run/session and exact output. Reopen, Back, Forward and Escape must retain the
replacement state/history without old reply, reasoning controls or active-row
markers. Only the original deliberate `POST /v1/runs` is allowed; profile switching
and navigation issue no mutation. Existing bootstrap hooks and per-test synthetic
read contracts are unchanged. The default browser suite already selects this spec.

The rebuilt matrix passes all 38 Chromium cases with zero retries, skips or flaky
outcomes on Flutter 3.44.2/Dart 3.12.2 and Node.js 22.5.1. Locked offline dependency
resolution, `flutter analyze --no-pub`, all 26 router regressions, JavaScript syntax
and staged whitespace checks pass. Required independent native-source review
approved the corrected test blob `01ec178d2c292ee3160b1d65121eb7108b5ef2d6`.
Production source, fixtures and dependencies are unchanged.

A temporary production mutation made profile selection a no-op during streaming;
both new cases failed the exact selected-profile barrier (`default` versus `coder`).
The line was removed byte-for-byte before the final rebuild. The initial harness
instead waited for SSE termination before releasing the synthetic server, timing
out in both cases (36 existing cases passed). Removing that wait fixes the test
ordering, not a product defect; initial failures remain in private receipts.

This qualifies rendered switching away from a pending synthetic run and retention
of the new owner after canonical server completion. It does **not** prove Flutter
consumed cancelled old terminal events, recoverable detached-run persistence,
automatic return focus after an owner-changing action, switch-back recovery,
native streaming or live Agent/provider behavior. Parent acceptance remains open.

## Rendered saved-host switching

Two additional compiled cases save two credential-free synthetic loopback hosts
through the real Add Hermes forms, then select the original host's conversation.
Only accessibility/reduced-motion setup and an initial `#/hermes` route
normalization use browser seams; neither connection uses a connect hook. At
390px the selected-contact conversation deliberately hides the bottom bar, so
Settings opens through the rendered `/settings` suggestion; at 1280px it opens
through the shell. Both use 200% text. Form entry uses Tab and actual typing,
including Flutter's focus-dependent URL accessible name.

Settings' Connections link leaves the overlay. Selecting the distinct saved host
and **Connect chat**, then Chat, must load its exact session and different history.
Reopened Settings must preserve that replacement through Back, Forward/Escape and
Close, exclude the original transcript, and issue zero API mutations. Distinct
replacement-origin session/history reads are required. The existing hook-driven
Settings/Profiles replacement cases remain unchanged in scope; the default runner
already includes the expanded spec.

The rebuilt application passes all 40 Chromium overlay cases without retries,
skips or flaky outcomes on Flutter 3.44.2/Dart 3.12.2, Node.js 22.5.1 and system
Chromium. Analysis, locked offline dependencies and 26 focused router tests pass.
Independent native-source review approved test blob
`5f623ed634d725ac9596b102861c3968855b7f3d`. Production and dependency bytes are
unchanged. A temporary production mutation skipped Connections' gateway switch;
both new cases rejected the original session at the replacement-session barrier.
That mutation was restored byte-for-byte before rebuilding the final application.

Initial attempts failed on unfocused/offscreen Flutter form semantics, a URL
accessible name that changes with focus, mixed hook/directory ownership, startup
redirects, and the compact selected-contact navigation path. The final fixture
uses public form/selection controls and settled editor typing instead; these
were harness corrections, not product fixes. Retained failures are private.

This qualifies rendered switching between empty-credential synthetic saved hosts,
not saved-secret isolation, cross-origin credential reuse, active-run connection
switching, GTK HTTP/SSE or live authentication. Parent acceptance remains open.

## Active-run rendered saved-host switching

Two additional Chromium cases exercise the same public saved-host selection while
an original synthetic reasoning run is visibly streaming. At 390/1280px and 200%
text, Settings → Connections → saved host → **Connect chat** must settle the distinct
replacement session and history before the controller releases the original run.
Readback requires the exact original run/session, completed output and persisted
assistant message. Back, Forward/Escape and Close then retain replacement ownership
and history, excluding the original reply and reasoning controls. Exactly one
browser `POST /v1/runs` is permitted; switching/navigation cannot replay or cancel it.
No new fixture, production API, connection hook or dependency is introduced.

The first compact attempt timed out looking for a slash suggestion while streaming.
The rendered shell's More tab was available; entry now uses that shell when visible
and retains the existing local suggestion path when the selected-contact view hides
it. This is a harness correction, not a product change. A temporary production
mutation made Connections' gateway switch inert; both new cases failed the exact
replacement-session barrier, still observing the original session. The mutation was
removed byte-for-byte before the final rebuild. Independent native-source review
approved test blob `c6ce8bcd38e6b812e596151299813dae595f7b97`.

The rebuilt application passes all 42 Chromium overlay cases with zero retries,
skips or flaky outcomes on Flutter 3.44.2/Dart 3.12.2, Node.js 22.5.1 and system
Chromium. Locked offline resolution, `flutter analyze --no-pub`, all 26 router
regressions, JavaScript syntax and staged whitespace checks pass. Production,
fixture and dependency bytes are unchanged.

This qualifies new-owner retention after original **server** completion, not client
consumption of cancelled terminal events, switch-back/detached recovery, saved-secret
isolation, native HTTP/SSE or live authentication. Parent acceptance remains open.

## Compact native follow-through: browser requalification

On the WING-TASK-408 candidate based on `6ba1b086`, the unchanged browser suite
passes all 42 cases at 390/1280px and 200% text, with zero retries or skips.
`flutter build web --release --no-pub -t lib/main_e2e.dart` rebuilt the application
before the run. Flutter 3.44.2/Dart 3.12.2 and Chromium 152.0.7977.75 on Linux were
used; existing dependency Wasm dry-run/font warnings do not qualify Wasm support.

```bash
# Existing serve_web.mjs: PORT=20130 HERMES_E2E_PORT=20131
WING_APP_URL=http://127.0.0.1:20130/ CHROME_EXECUTABLE=/usr/bin/chromium \
  node node_modules/@playwright/test/cli.js test --config=playwright.config.mjs \
  playwright/tests/regression/chat-workspace-overlay.spec.mjs \
  --workers=1 --retries=0 --reporter=list,json --output="$TMPDIR/browser-output"
```

The JSON result is retained as `$TMPDIR/browser-results.json` using
`PLAYWRIGHT_JSON_OUTPUT_NAME`. Chromium needed a short `/proc/<shell-pid>/fd/<fd>`
alias for the allocated `$TMPDIR` directory to avoid its Unix socket path limit;
the first launch failed before executing application behavior. Both fixture servers
were stopped after the passing run. Production and browser-test bytes are unchanged.
This rechecks the existing history/focus/owner barriers; it does not add a browser
compact-contact-menu qualification or turn native framework Back into browser Back.
The [new compact GTK cases](chat-workspace-overlay-native.md#compact-saved-host-settings-entry-and-replacement)
are separate native HTTP/SSE evidence, not a browser result.

## UI-DRIFT-REPAIR-001: Settings picker navigation

Retry baseline: `c26b43ea72b9acceb87351e235e65d508ce0e9ab`. The original
Settings locator drift came from `61743180`: the hierarchical picker selects
Theme within Appearance and is named **Settings Theme**, not **Settings Appearance**.
Commit `b2ba738c`, already in this baseline, corrected the overlay spec's locator.
This retry changes no browser or production source, timeout, assertion or journey.

Each rendered saved-host case was exercised alone at 390/1280px, idle/active run,
all with 200% text, using its exact title as `TITLE`:

```bash
export PATH="$AUTOWORK_CACHE/node-22.22.2/bin:$PATH"
# Owned serve_web.mjs fixture: PORT=$((AUTOWORK_PORT_BASE+20)), API port +21.
WING_APP_URL="http://127.0.0.1:$((AUTOWORK_PORT_BASE+20))/" \
  autowork-run timeout 180 npx playwright test --config=playwright.config.mjs \
  playwright/tests/regression/chat-workspace-overlay.spec.mjs \
  --grep "${TITLE}\$" --retries=0
```

Titles start `Settings retains replacement connection via rendered saved-host selection`,
optionally followed by ` during active run`, then
` through overlay history at 390px/200% text` or
` through overlay history at 1280px/200% text`.
The first three isolated cells passed (one test each). The wide active-run cell
first timed out clicking Add Hermes, then timed out clicking Chat on its first
rerun. The next **three consecutive isolated runs of that same journey passed**
with zero retries (23.8s, 29.4s and 22.2s). These intermittent baseline action
failures are recorded rather than called a repaired layout defect or ignored
without repeat evidence. No timeout increase was used as a fix.

The complete configured web command ran all 12 default specs:

```bash
export PORT=$((AUTOWORK_PORT_BASE+30))
export HERMES_E2E_PORT=$((AUTOWORK_PORT_BASE+33))
export WING_APP_URL="http://127.0.0.1:$PORT/"
autowork-run timeout 1500 bash -c 'flutter build web --release -t lib/main_e2e.dart && npm run web:e2e'
```

All **42 overlay cases pass**, with zero retries, failures or skips. Rendered
host selection, exact replacement session/history, original-run completion
readback, Back/Forward, Escape/Close, focus and no-replay assertions are unchanged.
The overall web gate remains **red**: **96 passed, one flaky, one failed, one
pre-existing opt-in live Agent skip**, exit 1. The flaky Settings-search 390px
case initially matched both the live announcement and visible result text; its
suite retry and one isolated zero-retry rerun pass. The failed
`reasoning-disclosure.spec.mjs` case, `reasoning keyboard status, focus and exact
session replacement`, cannot find the reasoning body after Enter. It fails again
alone, and also fails identically on a freshly built detached `c26b43ea` baseline.
These untouched journeys are unrelated failures, not green web-gate evidence.
The isolated commands use the same config with `--retries=0`:

```bash
npx playwright test --config=playwright.config.mjs playwright/tests/regression/settings-search.spec.mjs --grep 'Settings search selects and cancels without Agent mutation at 390px' --retries=0
npx playwright test --config=playwright.config.mjs playwright/tests/regression/reasoning-disclosure.spec.mjs --grep 'reasoning keyboard status, focus and exact session replacement' --retries=0
```

The baseline uses `git worktree add --detach "$TMPDIR/r2-baseline" c26b43ea72b9acceb87351e235e65d508ce0e9ab`,
locked preparation and a fresh `flutter build web --release -t lib/main_e2e.dart`;
its owned fixture uses allocated ports +50/+51. Initial occupied API ports +31/+32
were left untouched; all owned fixture servers were stopped after validation.
Flutter 3.44.2/Dart 3.12.2, Node.js 22.22.2 and bundled Chromium ran on Linux.
Existing font/Wasm dry-run warnings do not qualify Wasm. This is deterministic
browser evidence, not native, physical-device, live Agent or whole-Dart-suite
acceptance. [Cluster A](connection-primary-entry.md#ui-drift-repair-001-current-connection-journey-repair)
records the separate widget repair and remaining baseline reasoning failures.

## Remaining acceptance

The separate [Linux GTK receipt](chat-workspace-overlay-native.md) covers the
in-memory shell/chat-local focus matrix and the production HTTP/SSE streaming,
populated Profiles and empty-credential saved-host replacement matrices at both
widths. Those bounded native receipts do not qualify live Agent/provider behavior
or browser history. The distinct-origin hook and rendered browser cases above
retain their separate bounds.

Saved-secret switching, cancelled client terminal-event consumption, detached
recovery, Android, physical keyboard/IME and screen readers remain unqualified.
Browser Manage and keyboard suggestion recovery are covered above; browser direct
Tab completion remains unsupported by its native-only shortcut gate. The shared
focus change was separately [requalified in GTK](chat-workspace-overlay-native.md#shared-browser-focus-fix-gtk-requalification).
Keep the parent acceptance and its live task open. Do not repeat delivered matrices.
