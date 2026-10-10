# Global session panel adaptive qualification

Card `t_493629fd`; task `VERIFY-GLOBAL-SESSION-MODAL-ADAPTIVE`; goal
`PARITY-COMPOSITION`. This receipt qualifies the shared dirty checkout, not a
standalone branch, native application, live Agent, or screen reader.

## Delivered change

[HermesSessionsPanel](../../lib/features/hermes_chat/screens/widgets/hermes_chat_sessions.dart)
now stacks its title and New action at compact widths or enlarged Flutter text.
Its controls, source filter, count, lazy session rows and pagination share one
sliver scroll surface. Large headers no longer consume the entire row viewport.
A disposed-safe focus listener reveals only this panel's current focus after
layout, including focus changes and viewport/text-scale changes. This fixes a
short-window case where New was focused but remained above the viewport after
traversing the rows. Close remains outside the scroll surface.

The existing channel, owner/generation admission, pending-action fences,
acknowledgement, capability gates and mutation callbacks are unchanged. No API,
profile write, localization, dependency, fixture or upstream change was made.
The same presentation repair applies to the route-local Chat sessions sheet.

## Acceptance evidence

1. Compact/wide widths, enlarged text, reduced motion and keyboard operation:
   [five adaptive widgets](../../test/shared/widgets/app_shell_global_session_modal_adaptive_test.dart)
   use real Tab/Shift+Tab and Enter/Space at Flutter `TextScaler.linear(2)`.
   Starting sizes are 390×480, 390×700 and 1280×900; the open panel traverses
   wide, compact and short-compact sizes. Focused search, New and rows must have
   full viewport bounds; focus containment, surviving route-editor focus return
   on Escape, and Close/Space are asserted without pointer actions.
2. Owner replacement, late settlement and exact effects: the new scaled widgets
   delay both row activation and New, replace the profile away/back, resize,
   then settle. Obsolete work cannot change the active session or feature route.
   One explicit valid retry performs the intended action. Counters reject
   incidental connection/profile/model/history/pagination/approval work. The
   rerun predecessor modal/action tests cover channel replacement, endpoint,
   disconnect, capability, row removal, contact, directory, cancellation, route
   replacement, stale callbacks and partial-create recovery.
3. Fresh compiled Chromium:
   [two adaptive journeys](../../playwright/tests/regression/global-session-modal-adaptive.spec.mjs)
   start at compact and wide sizes, then resize the open panel through
   1280×700, 390×700 and 390×480 CSS viewports with real native Chromium 200%
   zoom and reduced motion. Search retains focus, controls remain in CSS viewport
   bounds, and Tab/Shift+Tab stay within the modal. Escape and Close restore a
   surviving opener. Breakpoint-disposed sidebar/tab openers are not falsely
   considered surviving: their replacements remain keyboard-reachable.
   Delayed activation is cancelled, Settings replaces the owning feature route,
   and late settlement cannot navigate or activate. A deliberate subsequent
   Space activation performs exactly one current-owner history GET. A deliberate
   compact New/Space produces exactly one session POST and one same-ID GET.
   Opening, resizing, searching and dismissing add no requests or mutations.

Browser zoom enlarges the entire rendered UI; it is not Flutter text-only
scaling. The widgets separately exercise actual 200% Flutter text scaling.
Browser replacement coverage is route/cancellation; profile/channel replacement
is widget coverage, not a live profile-switch claim.

## Executed final-source checks

Run from the repository root; all below passed:

```sh
dart format --output=none --set-exit-if-changed lib/features/hermes_chat/screens/widgets/hermes_chat_sessions.dart test/shared/widgets/app_shell_global_session_modal_adaptive_test.dart
timeout 10m flutter analyze
timeout 10m flutter test test/shared/widgets/app_shell_global_session_modal_adaptive_test.dart test/shared/widgets/app_shell_global_session_modal_test.dart test/shared/widgets/app_shell_global_session_modal_actions_test.dart test/shared/widgets/app_shell_global_session_access_test.dart test/shared/widgets/app_shell_focus_traversal_test.dart test/shared/widgets/app_shell_test.dart test/features/hermes_chat/screens/hermes_chat_session_picker_test.dart --concurrency=1
timeout 15m flutter build web --release -t lib/main_e2e.dart
timeout 6m env WING_APP_URL=http://127.0.0.1:8997/ CHROME_EXECUTABLE=/usr/bin/chromium npx playwright test --config=playwright.config.mjs playwright/tests/regression/global-session-modal-adaptive.spec.mjs playwright/tests/regression/global-session-modal.spec.mjs --workers=1 --output=build/global-session-modal-adaptive-browser
git diff --check
python <home>/.hermes/shared-skills/repo-docs/scripts/goals.py validate <repo>
```

Results: formatter unchanged; analyzer no issues; 103 focused widgets passed;
fresh release JavaScript web build passed; four Chromium journeys passed with
no retries and no captured page/layout errors. The browser suite includes the
two predecessor baseline/partial-create journeys, rerun rather than inherited.
Existing flutter_tts Wasm dry-run and Cupertino font warnings remain. No Wasm
support claim is made.

Earlier iterations exposed the header overflow, lazy offstage rows and focused
New outside the short viewport. Test corrections accounted for lazy offstage
finder traversal, Flutter's full-route dialog semantics, editor bounds and
breakpoint-disposed openers. They do not substitute for the final passing checks.
No assertions or existing tests were removed to accommodate a product failure.

## Follow-up npm verification scope

The later branch update records this focused command:

```sh
timeout 10m npm run test -- test/shared/widgets/app_shell_global_session_modal_adaptive_test.dart test/shared/widgets/app_shell_global_session_modal_test.dart test/shared/widgets/app_shell_global_session_modal_actions_test.dart test/shared/widgets/app_shell_global_session_access_test.dart test/shared/widgets/app_shell_focus_traversal_test.dart test/shared/widgets/app_shell_test.dart test/features/hermes_chat/screens/hermes_chat_session_picker_test.dart
```

`package.json` forwards these targets to `flutter test --concurrency=1`.
The retained `npm-focused-widgets.log` ends with `+103: All tests passed!`.
This is a focused rerun, not a full-suite pass, even if verification metadata
labels its canonical command as `npm run test`.

The separate `npm-full-suite.log` has no completion result. It cannot establish
that the full suite passed or failed. Keep the integrated full-suite check open.
This documentation pass inspects the logs and all 203 matching fingerprints;
it does not rerun Flutter, launch Chromium or qualify native behavior.

## Source binding and retained evidence

Ignored `.task-evidence/t_493629fd/` retains final `format.log`, `analyze.log`,
`widgets.log`, `build-web.log`, `browser.log`, and `source-fingerprints.json`.
The fingerprint manifest covers 203 source/test/manifest files; a post-browser
check found no drift. Checkout HEAD was
`1afe1307e37ee1ddfa1f7d67ad047509e99c8784` with approved predecessor dirty changes.
The freshly built `build/web/main.dart.js` SHA-256 was
`f02276f0d67d1cac77576b43f8aabda173f8ffbf2c3c49fbc94b59f24c8aec7c`.
The compiled hash is retained after build cleanup, not presented as a retained
runnable release artifact.

`implementation.patch` records this card's production delta against the saved
pre-edit dirty file. Only the shared panel, the two new regression files, this
receipt and required goals.py ledger outputs are included in the scoped local
agent branch. The panel and ledger files retain predecessor edits; unrelated
dirty paths remain untouched.

`browser/compact-adaptive-receipt.json` and `wide-adaptive-receipt.json` retain
exact synthetic requests, focus traces and six render observations each.
Final screenshots inspected directly:

- `browser/compact-panel-390-480.png`: readable title, New, Select and Close,
  strong search border/caret, active-row checkmark and readable metadata; the
  additional row is below the scroll viewport rather than overflowing it.
- `browser/wide-panel-1280-700.png`: both rows and all controls visible, readable
  labels and focused search border; no visible overflow.
- The retained filtered-row captures show the matched synthetic title and
  visible focused row. All screenshots use deterministic fixture data only.

The qualification server was stopped and newly created web/test build outputs
removed after retaining these small receipts.

## Integration and qualification limits

The scoped branch is an integration delta, not a clean standalone build.
HEAD lacks the predecessor `global_session_scope.dart` and the panel's existing
`autofocusSearch`/`inventoryFailed` contract. Shared shell/localization/channel
inputs are consumed without adding their files to this card. Merge the approved
predecessor snapshots before standalone qualification. Standalone branch build,
packaged distribution, full-suite checks, native desktop/mobile, live Agent,
screen-reader output and physical-device behavior are NOT_CHECKED.

No new owner decision was needed. Existing authority, profile isolation,
upstream immutability and red-line defaults were retained.
