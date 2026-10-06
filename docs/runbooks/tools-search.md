# Owner-scoped Tools inventory search

Status: independently accepted on `t_3348dc5c` through executor62 → tester63 →
reviewer64. This is a bounded M4 inventory repair, not completion of
`t_38174cb7`, full Desktop parity, live Agent generation or platform qualification.

## Supported boundary

[Tools](../product/routes.md) still requires a connected Hermes Agent and its
exact authorized skills/toolsets GET operations, including every declared grant.
Search remains case-insensitive literal containment over existing bounded skill
name/description/category and toolset name/label/description/resolved-tool metadata.
There is no new API, discovery/MCP administration, mutation, persisted search term
or Wing Link data-plane traffic. Name-only responses retain sorted chips without
inventing detailed metadata or new search support.

Search controllers and disclosure are owned by the channel client, Agent origin
and selected profile. Direct connected replacements and A → B → A transitions
start with empty queries; identical profile/host IDs on a replacement client do
not transfer ownership. Losing one inventory's exact authority discards only that
section's query. Disconnection/error removes the inventories. Returning authority
must not restore old private search text. Same-owner refresh, content updates and
replacement capability documents retain queries when the exact read remains granted.
Existing channel connection/profile/request generations still reject stale reads;
no shared-channel contract was changed.

Each nonempty search has an independent tooltip-labeled clear button: **Clear
installed skills search** or **Clear toolsets search**. Tab from the editor reaches
its clear action; Enter clears only that section and restores its sorted inventory.
Clear requires no Agent request. No matches, empty, unavailable, connection errors
and inventory-load failures remain distinct. Read failure hides data/search rather
than displaying stale results. A failed explicit refresh retains valid queries
and shows bounded feedback.

Compiled Chromium exposed semantic reparenting when filtering left one or zero
results: result labels could merge into the editor and disrupt continued typing
or remove a toolset's actionable disclosure. Explicit semantic boundaries keep
section labels, editors, result rows and no-match text separate. No duplicate clear
label, SDK patch, DOM mutation workaround, longer assertion timeout or test retry
is used in the final journey.

## Executor verification

### Keyboard-only compiled browser workflows

`t_2b24fc6c` adds [keyboard journeys](../../playwright/tests/regression/inventory-keyboard.spec.mjs)
at 390/1280px, self-verified pending same-card tester/reviewer acceptance. After
connection, reduced-motion initialization and accessibility activation, user actions
are only Tab, Shift+Tab, typing, Enter and Space. Bounded traversal records the
actual focused node and asserts exact names/roles and viewport containment; paired
renderer screenshots check a visible focus change rather than only DOM focus.
Both editors, literal no matches, independent clears, both disclosures open/close,
forward shell escape/backward return and explicit refresh are exercised.

The desktop rail was drawn but excluded by the nested route's `BlockSemantics`.
Two production-router/client widget regressions failed at 1280px (390px controls
passed). A desktop content semantic boundary in the existing shell preserves the
rail; no channel, refresh, authorization, localization or chip behavior changed.
The [route regressions](../../test/shared/widgets/inventory_keyboard_navigation_test.dart)
also exercise 200% text, reduced motion and editor Tab/Shift+Tab without overflow.
The compiled web renderer currently exposes collapsed disclosures as buttons and
expanded disclosures as tappable groups with the exact title plus **Resolved tools**.
Display-only chips export checkbox roles without a disabled attribute; they remain
non-tappable, outside Tab order and without mutation affordances. This records
browser behavior, not screen-reader qualification.

Each scoped Tools receipt records one bootstrap skills GET and one toolsets GET,
zero reads/mutations for local controls/navigation, and exactly one of each GET
on keyboard refresh, all with `profile=default`. Four decoded responses confirm
the two inventories and query retention. The locked Flutter 3.44.2/Dart 3.12.2
affected plus shared-widget/router run passes 1,213 unique cases/1,213 executions;
the four new shell cases, 75 admission cases and 59 bootstrap cases are subsets.
Fresh JS-release build and Chromium keyboard plus existing inventory/surface
journeys run with `--retries=0 --workers=1`. Commands, exits, source/build hashes,
red/green events, focus images/traces and receipts are retained on the card.
Node 26.5.1, Playwright 1.61.1 and Chrome for Testing 149.0.7827.55 were exercised,
not documented Node 22. No Android/native desktop, Wasm, live Agent/provider,
full-platform, release or screen-reader qualification is implied; `t_38174cb7`
remains unchanged and unmet.

Use the locked toolchain at
`/opt/data/cache/scratch/t_38174cb7/flutter-3.44.2/bin`, build
`lib/main_e2e.dart` with `--release --no-pub`, then run the new spec alongside
`tools-search.spec.mjs`, `schedule-search.spec.mjs` and `browser-surfaces.spec.mjs`
against an owned loopback fixture with `--retries=0 --workers=1`.

### Explicit refresh ownership

`t_389042e6` is executor-verified, pending same-card tester/reviewer acceptance.
Direct `loadToolInventory()` and `loadJobs()` reject while profile selection is
unsettled or the channel is not connected, before optional I/O, state changes or
request-generation acquisition. Authorized bootstrap reads intentionally remain
allowed before the connection/profile commits; the accepted jobs authorization
repair is `t_40a71fac` (executor87 → tester88 → reviewer89).

Tools refresh now captures the rendered owner and synchronously invalidates on
channel/host/profile/status/selecting or exact section read-authority changes.
Cached controls reject before changing local action state or issuing a read,
including same-ID selection and A → B → A without an intervening frame. Selecting
shows loading rather than old inventory/search or an actionable refresh. Late old
completions cannot clear a new spinner or restore feedback. Equivalent authorized
capability documents and same-owner inventory updates do not invalidate refresh;
partial skills-only/toolsets-only inventories retain explicit refresh/recovery.
No tool mutation, inference, generic refresh framework, implicit replay or
cancellation contract is added. Already-issued reads may finish at their original
Agent; existing channel publication generations remain unchanged.

The production-client
[admission/race/widgets](../../test/core/hermes/channel/hermes_inventory_refresh_admission_test.dart)
pass 75 cases, including cached-control red regressions and replacement-client,
partial-inventory, error/recovery and new-spinner ownership checks at390/1280px,
200% text and reduced motion. The source-bound affected run passes 1,162 unique
cases / 1,162 executions, including existing search/clear routes and the 59-case
jobs bootstrap matrix; focused runs are subsets, not additional unique cases.
Locked nonwriting format/analyze, fresh JS-release build and 16 Chromium journeys
with retries0 pass. Tools receipts retain two bootstrap inventory response
readbacks, zero search/clear reads or mutations and exactly one explicit skills
GET plus one toolsets GET. Race/owner-selection evidence is client/widget only.
Exact commands, hashes and bounded red/green/receipt evidence are retained on the
card. Node26.5.1, Chrome for Testing149.0.7827.55 and Playwright1.61.1 were exercised;
Node22, physical/native-device, Wasm and deployed Agent/provider inference remain
unqualified. Full live qualification `t_38174cb7` is unchanged and unmet.

### Predecessor search evidence

Linux Flutter widget runner: Flutter 3.44.2 (`c9a6c48423`), Dart 3.12.2. The system
Flutter 3.47.5 was not used. Browser: Playwright 1.61.1, Chrome for Testing
149.0.7827.55, Node 26.5.1 (not the intended Node 22).

- Initial regressions reproduced retained private query text on direct host,
  profile and client replacement and on grant/operation loss before repair.
- 407 tests pass: 18 new ownership/accessibility/actual-channel race widgets,
  15 existing Tools widgets, 347 shared-channel tests and 27 Schedules widgets.
  Actual-channel completers prove both old read success and failure cannot restore
  inventory/errors after host or profile roundtrips; there are no sleep-based races.
- At 390/1280px, widgets exercise 200% text and reduced motion without overflow,
  search labels, clear tooltips/semantics, Tab/Enter activation, independent clear,
  sorting and keyboard resolved-tool expansion.
- Compiled release Chromium passes six Tools/Schedules journeys three times with
  retries disabled (18 executions). Both widths prove keyboard search/clear,
  literal no matches, resolved-tool disclosure and same-owner explicit refresh.
  Each Tools receipt reads back the two original fixture inventories and their
  refreshed responses: zero search/clear reads or mutations; exactly one skills
  GET and one toolsets GET from the explicit refresh. Existing Tools browser
  surfaces and the accepted neighboring schedule-search regressions remain green.
- Localization generation, changed-Dart formatting, locked `analyze --no-pub`,
  JS syntax, release `main_e2e` build, whitespace and local document links pass.
  The JS-release build retains existing flutter_tts Wasm dry-run and Cupertino
  font warnings; this is not Wasm qualification.

The browser fixture journey does not provision saved gateway/profile selection;
owner switching is proved by the widget and actual-channel seams, not by a browser
picker journey. No physical Android, native app, real Agent/provider generation,
screen reader, full repository/platform gate or release claim is made. The card
has no notification subscription; no delivery destination has been invented.
Source hashes, bounded receipts, logs and the task-only diff against the inherited
dirty worktree are in the evidence archive recorded on the card.

Reproduction (put the qualified Flutter toolchain first on PATH):

```bash
flutter gen-l10n
dart format --output=none --set-exit-if-changed \
  lib/features/tools/screens/tools_screen.dart \
  test/features/tools/tools_search_ownership_test.dart \
  lib/l10n/app_localizations.dart lib/l10n/app_localizations_en.dart
flutter analyze --no-pub
flutter test --no-pub --concurrency=1 --reporter expanded \
  test/features/tools/tools_search_ownership_test.dart \
  test/features/tools/tools_screen_test.dart test/core/hermes/channel \
  test/features/schedules/schedules_screen_test.dart
flutter build web --release --no-pub -t lib/main_e2e.dart
node --check playwright/tests/regression/tools-search.spec.mjs
node --check playwright/tests/regression/browser-surfaces.spec.mjs
PORT=8897 HERMES_E2E_PORT=8898 node serve_web.mjs
# Use unused ports and the installed Chromium executable; do not stop other owners.
CHROME_EXECUTABLE=/path/to/qualified/chrome WING_APP_URL=http://127.0.0.1:8897/ \
  npx playwright test --config=playwright.config.mjs \
  playwright/tests/regression/tools-search.spec.mjs \
  playwright/tests/regression/browser-surfaces.spec.mjs \
  playwright/tests/regression/schedule-search.spec.mjs \
  --grep 'Tools|Schedules' --retries=0 --repeat-each=3
git diff --check
```
