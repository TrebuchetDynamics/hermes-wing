# Owner-safe local Profiles inventory search

Status: independently accepted on `t_ca0bbb3d` after executor67 → tester68 →
reviewer69. This bounded M3 inventory slice does not complete
`t_38174cb7`, Desktop parity, live Agent generation or platform qualification.

## Supported boundary

[Profiles](../product/routes.md) searches only the already-loaded bounded Agent
or Wing Link inventory. Literal case-insensitive containment matches profile ID,
display name, description and model; descriptions are also rendered on cards.
Null/name-only fields retain the existing model fallbacks. Filtering preserves
inventory order and exact row identities/revisions. Search and clear make no
requests, select no profile, and do not persist a query or fetch extra metadata.
No matches is distinct from empty, unavailable, loading and error states.

The hidden active profile remains the actual Chat owner. Only the existing
explicit Chat action changes that owner. Creation/setup/editor callbacks receive
the full inventory, not search results: clone choices and duplicate-name checks
are not relaxed. Existing native lifecycle and reviewed transactional Wing Link
new-profile operations remain gated as before; no new operation, grant, provider
configuration authority, shadow state or Agent traffic through Wing Link is added.

Search belongs to the current management host, channel/client and inventory
source. Host/client/source transitions, enrollment loss and exact read-authority
loss discard it before another owner's results render. A → B → A, including
same-frame notifications, does not restore private query text. Same-owner
inventory/capability updates and explicit Wing Link reloads retain search.
Native operation gates require every endpoint-declared scope, as well as the
exact method/path, explicit base scope and supported schema. Losing an additional
required grant hides the native inventory and discards its query, even if that
grant is restored before a frame. An authorized Wing Link fallback remains
independent; still-authorized same-owner updates (including wildcard grants)
retain search.
Wing Link 401/403 reads hide stale inventory and discard the query on retry.
Existing load generations reject old success and failure after host/source/client
changes; no global epoch framework is introduced. Credentials are compared
privately for source identity, never placed in widget keys or diagnostic output.

**Search profiles** and the independent **Clear profile search** tooltip/button
are labeled controls. Tab from the editor reaches clear; Enter restores the full
inventory. Explicit semantic containers keep the editor, profile identity/selection,
row actions and no-match announcement separate, including one/zero results in
compiled Flutter web. No DOM/SDK patch, retry or increased timeout is needed.

## Executor evidence and limitations

Toolchain: Flutter 3.44.2 (`c9a6c48423`), Dart 3.12.2, Linux widget runner;
Playwright 1.61.1 with Chrome for Testing 149.0.7827.55; actual Node 26.5.1,
not intended Node 22. The system Flutter SDK was not used.

- Regression-first local-search tests failed before implementation. A further
  401/403 reload regression failed before read-authority handling was repaired.
- Tester66 found an incomplete pre-existing native predicate: it checked only
  the base grant, not all declared required grants. Executor67 added durable
  visible/same-frame revocation regressions (both failed before the fix), then
  tightened the existing screen-local predicate; no adapter contract changed.
- 633 tests pass across Profiles (catalog/editor/directories/screen/ownership),
  gateway directory/restoration, shared channel, Tools and Schedules. Completers
  cover late Wing Link success/failure and same-frame host roundtrips; native and
  compatibility source/client/authority transitions, literal metadata/null fields,
  exact Chat/rename targeting and unfiltered editor inventory are covered.
- Linux widgets at 390/1280px use 200% text and reduced motion, check no overflow,
  semantic search/clear labels and Tab/Enter operation. Existing profile lifecycle,
  setup, capability negatives and neighboring inventory behavior pass.
- Nine compiled release Chromium journeys repeated three times pass (27 executions,
  retries disabled): profile search at both widths, existing Profiles-unavailable
  check, Tools search/surfaces and Schedules search/surfaces. Six profile receipts
  read back the original synthetic inventory and prove zero search/clear requests
  or mutations and unchanged default-profile selection. Each profile journey has
  one explicit bootstrap inventory GET, before search starts.
- Localization generation, six changed-Dart format checks, locked analysis,
  release `main_e2e` build, changed Node syntax, whitespace and local document
  targets pass. JS-release build retains existing flutter_tts Wasm dry-run and
  Cupertino font warnings; this is not Wasm qualification.

The browser adds a per-test read-only synthetic profile capability and bounded
response, not a live Agent claim. A guarded E2E-only callback re-selects the
already-default profile to load inventory before search; normal connection and
production behavior are unchanged. Saved owner-picker switching is not provisioned
in this browser fixture; widget ownership/race coverage supplies that evidence.
No real Agent/provider, native app, Android device, screen reader, Node 22,
full repository/platform gate or release is qualified. The card has zero inspected
notification subscriptions; no delivery destination or notification promise.

The source-bound evidence archive on the card records hashes, task-only diffs
against inherited dirty snapshots, bounded receipts and exact commands/exits.
Attachment/download availability must be confirmed by native attachment readback;
a workspace artifact path alone is not a downloadable attachment claim.

## Keyboard-only compiled browser workflows

`t_2e679eff` adds test/evidence-only coverage, executor-verified pending same-card
tester → reviewer acceptance. No production focus defect was reproduced and no
production, localization, Agent contract or management authority was changed.
The [strict keyboard journeys](../../playwright/tests/regression/profile-keyboard.spec.mjs)
reuse the [bounded actual-focus actor](../../playwright/support/inventory_keyboard.mjs).
Only permitted connection/accessibility/reduced-motion and already-default inventory
loading hooks run during bootstrap. Afterwards Tab/Shift+Tab alone reach the editor,
independent clear and named shell Chat destination; typing, Ctrl/Command+A and Enter
perform local edits/clears. Row Chat controls may be traversed but never activated;
neither shell navigation nor profile/setup/edit/destructive actions are activated.

- Literal mixed-case ID/name/description/metacharacter/model queries and null-name
  ID fallback pass. No-match feedback remains distinct from empty, unavailable,
  loading and error. Two keyboard clears restore full stable order and the active
  marker; subsequent typing, forward shell escape and backward return pass.
- Each 390/1280px journey has one explicit bootstrap inventory GET and exact
  response/revision readback. Profiles is a **machine/management-host-scoped**
  administrative collection, not a profile-query-scoped resource: the receipt
  records its exact fixture origin, `/api/profiles`, empty query, `profiles:read`
  and `profile_scoped:false`. Profile-owned bootstrap reads retain their explicit
  `profile=default` query. Local keyboard actions issue zero extra reads/mutations.
- Hiding the active row leaves the actual state-summary tuple unchanged at each
  literal query and on completion: `default / e2e-hermes-session / null / null`
  (profile/session/assigned provider/model). Nulls are actual readback because this
  fixture does not advertise model-assignment inventory, not inferred identity or
  invented provider grants. Both journeys have empty page-error lists.
- Exact role/name/focus traces and six decoded RGB focus/unfocus crop pairs prove
  visible editor, clear and shell focus. Mobile shell Chat is a `tab`; the wide
  shell exposes the button `Chat Tab 1 of 9`. No pointer action, locator focus/fill,
  DOM focus/click/event injection or state callback is used during the workflow.
- The [actual-client/router widget seam](../../test/shared/widgets/inventory_keyboard_navigation_test.dart)
  now includes Profiles at 390/1280px, 200% text and reduced motion, with explicit
  inventory bootstrap, keyboard traversal/return, unchanged owner and no overflow.
  Profiles uses a 1400px-high viewport, matching the new browser journeys; this
  does not claim arbitrary-height or native platform qualification.
- Locked nonwriting changed-Dart format, `flutter analyze --no-pub`, fresh
  JS-release `main_e2e` build, changed JS syntax and whitespace checks pass.
  Required affected Flutter suite: **1,217 unique / 1,217 executions / zero skipped**;
  57 hidden infrastructure completions excluded by protocol metadata only. The
  focused eight widget cases overlap this suite and are not added to its total.
  Profiles/provider keyboard/search, shared inventory keyboard, Tools/Schedules
  search and browser-surfaces: **28 unique / 28 executions / zero skipped**, retries
  disabled, one worker. Exact identities, all API bootstrap/user receipts and
  source-bound hashes/diffs are retained in the executor archive.

The initial widget test incorrectly required a profile query; tracing the existing
client/channel regression and read-only upstream collection confirmed machine scope.
That test-premise failure is not regression-first repair evidence. Widget assertions
were also corrected for duplicated shell labels and lazy row mounting at 200% text;
the named Profiles viewport above is the exercised target. No production fix was
manufactured. Existing ownership/A-B-A/revocation/additional-scope/late-result,
unfiltered editor/duplicate/clone, native gates and Wing Link fallback tests pass.

Toolchain remains Flutter 3.44.2/Dart 3.12.2, Playwright 1.61.1, Chrome149.0.7827.55
and actual Node26.5.1 (not documented22; no upgrade). Existing flutter_tts Wasm
dry-run warnings remain. Evidence is deterministic Linux widgets and compiled
JS-release Chromium only, not real Agent/provider generation, native desktop,
Android, screen reader, Wasm, release, complete M3/M5 or full parity. Actual-service/
native qualification `t_38174cb7` remains unchanged and unmet. Workspace archives
are not attachment/upload claims; native attachment availability must be read back.

For this slice, after a fresh locked build start an owned copy of `serve_web.mjs`,
its lifecycle support and `build/web` in scratch; verify both listener readiness
and served JS hashes, then run the following with the owned app URL and qualified
Chromium configured. Stop only that fixture and verify its ports close.

```bash
dart format --output=none --set-exit-if-changed \
  test/shared/widgets/inventory_keyboard_navigation_test.dart
flutter analyze --no-pub
flutter test --no-pub test/core/hermes test/features/providers \
  test/features/profiles test/features/gateway test/features/tools \
  test/features/schedules test/features/office \
  test/features/hermes_chat/providers/hermes_channel_provider_test.dart \
  test/shared/widgets test/router --concurrency=1 --reporter json
flutter build web --release --no-pub -t lib/main_e2e.dart
node --check playwright/tests/regression/profile-keyboard.spec.mjs
npx playwright test --config=playwright.config.mjs \
  playwright/tests/regression/profile-keyboard.spec.mjs \
  playwright/tests/regression/provider-keyboard.spec.mjs \
  playwright/tests/regression/profile-search.spec.mjs \
  playwright/tests/regression/provider-search.spec.mjs \
  playwright/tests/regression/inventory-keyboard.spec.mjs \
  playwright/tests/regression/tools-search.spec.mjs \
  playwright/tests/regression/schedule-search.spec.mjs \
  playwright/tests/regression/browser-surfaces.spec.mjs \
  --retries=0 --workers=1 --reporter=list,json
git diff --check
```

## Reproduction

Put the locked Flutter 3.44.2 toolchain first on PATH. Use unused server ports and
the installed qualified Chromium executable; stop only the server you started.

```bash
flutter gen-l10n
dart format --output=none --set-exit-if-changed \
  lib/features/profiles/screens/profiles_screen.dart lib/main_e2e.dart \
  lib/l10n/app_localizations.dart lib/l10n/app_localizations_en.dart \
  test/features/profiles/profiles_screen_test.dart \
  test/features/profiles/profiles_search_ownership_test.dart
flutter analyze --no-pub
flutter test --no-pub --concurrency=1 --reporter expanded \
  test/features/profiles test/features/hermes_chat/gateways \
  test/core/hermes/channel test/features/tools test/features/schedules
flutter build web --release --no-pub -t lib/main_e2e.dart
node --check playwright/tests/regression/profile-search.spec.mjs
PORT=8927 HERMES_E2E_PORT=8928 node serve_web.mjs
# In another terminal:
PLAYWRIGHT_JSON_OUTPUT_NAME=/path/to/owned-scratch/browser-results.json \
WING_APP_URL=http://127.0.0.1:8927/ CHROME_EXECUTABLE=/path/to/qualified/chrome \
  npx playwright test --config=playwright.config.mjs \
  playwright/tests/regression/profile-search.spec.mjs \
  playwright/tests/regression/browser-surfaces.spec.mjs \
  playwright/tests/regression/tools-search.spec.mjs \
  playwright/tests/regression/schedule-search.spec.mjs \
  --grep 'Profiles|Tools|Schedules' --retries=0 --repeat-each=3 --reporter=list,json
git diff --check
```
