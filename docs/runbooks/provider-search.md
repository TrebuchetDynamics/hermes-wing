# Owner-safe local Providers inventory search

Status: independently accepted on `t_f7239dbd`, executor70 → tester71 → reviewer72.
The canonical same-card verdict confirms the bounded slice. This is not
existing-profile compatibility mutation, live inference or full Desktop parity.

## Supported boundary

[Providers](../product/routes.md) uses literal case-insensitive containment on
already-loaded provider slugs and displayed labels only. Minimal/null labels use
the existing slug fallback. Key hints, environment names and authentication type
are not searchable. Configured providers still precede available providers, with
relative inventory order retained inside each group. No matches is distinct from
empty, unavailable, loading and error states.

Search and **Clear provider search** perform no read, mutation, validation or
inference, and persist no query. The model assignment section and full model
picker inventory are unaffected; hiding the active provider does not select a
new model or change Chat ownership. Visible management actions still pass the
original exact provider to the write-only editor; opening/cancelling never saves
or validates. OAuth keeps its host-sign-in wording. Existing exact mutation gates
are unchanged; no provider configuration authority, backend contract, Wing Link
fallback/proxy or shadow state is added.

The query belongs to the selected channel instance, gateway/host, explicit
profile and authorized provider read. Opaque widget keys never contain credentials
or endpoints. Synchronous screen-local listeners discard queries on owner loss,
including channel replacement with identical IDs and A → B → A or permission
loss/restoration before a frame. Same-authorized-owner data/required-scope updates
and explicit reads retain search. The existing channel predicate requires the
exact operation/method/path, supported schema/profile context, base grant and
every endpoint-declared grant; an independently authorized runtime-model-only
fallback stays visible without provider search. Disconnect/error/unavailable and
current load failure do not retain a private query. Existing screen generations
and opaque-owner checks prevent late old read success/failure/loading cleanup
from affecting the current owner; no shared epoch architecture is introduced.

The input, labeled clear button, provider row identity and no-match live region
remain separate semantic nodes. Tab from the input reaches clear; Enter restores
the inventory. Existing narrow/large-text layouts remain intact.

## Executor evidence and limits

Actual toolchain: Flutter 3.44.2 (`c9a6c48423`), Dart 3.12.2, Linux widget runner;
Playwright 1.61.1 with Chrome for Testing 149.0.7827.55; Node 26.5.1, not intended
Node 22. The locked scratch SDK is used, not a replacement system SDK.

- Regression-first 24 search/owner tests compiled and failed before implementation
  because the required search control was absent. Final 26 search tests include
  actual gateway roundtrip and current-failure/retry regressions.
- 817 nearby tests pass across Providers (editor, picker, presets, screen/search),
  Profiles (including directories), gateway directory, shared channel/API, Tools
  and Schedules. Exact-operation/base/additional-grant revocation, same-frame
  roundtrips, same-ID channel replacement, delayed old success/failure/loading,
  same-owner updates, minimal metadata, literal metacharacters, grouping/order,
  no-match/clear, exact editor identity and zero local-search calls are covered.
- Linux widgets at 390/1280px use 200% text and reduced motion; no overflow,
  independent semantics and real Tab/Enter clear pass. Browser journeys use
  compiled JS-release `main_e2e` with actual controls at both widths and reduced
  motion; browser 200% text is not claimed.
- Twelve selected Chromium journeys repeated three times pass (36 executions,
  retries disabled): provider/profile/tools/schedule searches at both widths and
  existing unavailable Providers/Profiles plus Tools/Schedules surfaces. Six
  provider receipts read back the four-row synthetic provider inventory and
  model assignment; one scoped provider GET and one model GET precede each search.
  Search/clear make zero subsequent API requests or mutations, and the actual
  profile/session/model summary remains unchanged.
- Localization regeneration, six-file Dart format check, locked analysis, fresh
  release build, changed Node syntax, whitespace and local document links pass.
  Initial browser selectors assumed separate visual text nodes; assertions were
  corrected to the actual semantic model summary and row groups. No production
  workaround, SDK/DOM patch, retry or timeout increase was needed.

Per-test Playwright routing adds only synthetic read capabilities/responses. The
normal fixture still reports Providers unavailable. An existing E2E-only state
summary now includes fixture profile/session and model-assignment identity for
readback; no credentials or endpoint are exposed. Production entrypoints and
Agent/Wing Link contracts are unchanged. Browser saved-owner picking is not
provisioned; the mandatory widget matrix supplies that race proof.

No live Agent/provider, native app, physical device, screen reader, Node 22,
Wasm, full repository/platform gate or release is qualified. The successful JS
build retains existing flutter_tts Wasm dry-run and Cupertino font warnings.
`t_38174cb7` remains open for supported private Codex OAuth provisioning and
requires source-bound post-slice revalidation; these fixtures do not satisfy it.

The source-bound sanitized evidence archive records task-only diffs against the
inherited dirty snapshot, input/source/build hashes, exact commands/exits and
parsed bounded receipts. A local path is not a downloadable attachment: native
attachment readback determines availability. No notification destination or
notify/wake guarantee is claimed.

## Keyboard-only compiled browser workflows

`t_8cda73dd` adds [keyboard-only journeys](../../playwright/tests/regression/provider-keyboard.spec.mjs)
at 390/1280px, executor-verified pending same-card tester/reviewer acceptance.
The earlier search journeys still use pointer entry and are not keyboard-only
proof. The new journeys use only Tab/Shift+Tab, typing, text-select-all and Enter
after connection/accessibility/reduced-motion bootstrap. They reach the actual
named editor and clear button, leave forward to Chat in the supported shell
(compact `tab` / desktop `button`), then return backward without activating it.
Focused/unfocused rendered crops accompany exact role/name/viewport traces.

Literal mixed-case slug/label searches, metacharacters, null-label slug fallback,
non-searchable auth type/environment name/masked hint, no-match versus
empty/unavailable, configured-before-available stable order, explicit clear and
continued typing pass. Hiding the active provider leaves the complete displayed
main plus two auxiliary assignments unchanged, as well as the exact fixture
profile/session/provider/model tuple. Decoded response readbacks prove exactly
one provider GET and one model GET with `profile=default`; separate bootstrap
and local-keyboard receipts prove zero subsequent reads or mutations. Page
errors are empty. The normal fixture's unsupported-provider baseline still passes.

No production defect was reproduced and no production code changed. The initial
test incorrectly asserted an unfocused native editor's dormant DOM value;
the corrected check proves restored rows first, then the empty value on actual
keyboard return and successful continued typing. No engine/DOM workaround or
focus injection was added. Two additional production `HermesApiChannel` /
`HermesApiClient` / router widget cases exercise Providers at 390/1280px with
200% text, reduced motion, scoped reads, semantic shell exposure and no overflow.

Executor checks pass: locked Flutter 3.44.2 changed-Dart nonwriting format,
analysis, 1,215 unique affected Flutter cases / 1,215 executions / zero skipped,
fresh JS-release build and 26 unique Chromium cases / 26 executions / zero
skipped, retries disabled. The six focused widget cases overlap that Flutter
suite and are not added to its total. Test accounting joins reporter identities
and excludes only hidden infrastructure, not tests named `loading`. Node 26.5.1
differs from documented 22; Playwright 1.61.1 / Chrome for Testing 149 are used.
Existing flutter_tts Wasm dry-run warnings remain. These are Linux widget and
compiled Chromium fixture results, not actual screen-reader, Android, native
desktop, live Agent/provider, Wasm, release or full milestone qualification.
The unmet real-service requirement on `t_38174cb7` is unchanged.

After a fresh `main_e2e` JS-release build, copy the fixture and build to owned
scratch storage, verify readiness/build hashes, and run the selected browser gate
against its unused loopback ports (example 9570/9571):

```bash
node --check playwright/tests/regression/provider-keyboard.spec.mjs
WING_APP_URL=http://127.0.0.1:9570/ CHROME_EXECUTABLE=/path/to/qualified/chrome \
  PLAYWRIGHT_JSON_OUTPUT_NAME=/path/to/owned-scratch/browser-results.json \
  npx playwright test --config=playwright.config.mjs \
  playwright/tests/regression/provider-keyboard.spec.mjs \
  playwright/tests/regression/provider-search.spec.mjs \
  playwright/tests/regression/profile-search.spec.mjs \
  playwright/tests/regression/inventory-keyboard.spec.mjs \
  playwright/tests/regression/tools-search.spec.mjs \
  playwright/tests/regression/schedule-search.spec.mjs \
  playwright/tests/regression/browser-surfaces.spec.mjs \
  --retries=0 --workers=1 --reporter=list,json --output=/path/to/owned-scratch/results
```

Stop only the owned fixture and verify its ports close. Source-bound receipts,
raw test enumerations, focus crops, exact commands/exits and task-only diffs are
retained in the card's sanitized local evidence archive; a path is not an upload.

## Reproduction

### Large-text keyboard return defect (t_11b62717)

The earlier browser receipts do not establish the empty-query, single
Tab/Shift+Tab roundtrip at 1280×900 with 200% text. The production-router
widget oracle failed in the original run at
[inventory_keyboard_navigation_test.dart:254](../../test/shared/widgets/inventory_keyboard_navigation_test.dart).
That run stopped on excluded shared-shell ownership without a production repair
or original-card acceptance. The governor later archived `t_11b62717` as superseded
after the separate forward repair received approval in run 98. Archival is not
completion or approval of the original card. No original assertions were changed.

Flutter 3.44.2 (`c9a6c48423`) / Dart 3.12.2 reproduced the failure in isolation:

```bash
flutter test --no-pub --concurrency=1 \
  test/shared/widgets/inventory_keyboard_navigation_test.dart \
  --plain-name 'shell keyboard semantics survive /providers at 1280.0 / 200%'
```

Exit 1: expected editor focus true, actual false. Temporary read-only focus
instrumentation, subsequently removed, captured the actual transition:

- Editor: rectangle `(277,400)-(1248,448)`, nested route scope.
- Tab: **Tools**, outer shell scope. Its sidebar rectangle moves from
  `(8,960)-(200,1064)` to `(8,454.5)-(200,558.5)`.
- Shift+Tab: **Connections**, outer shell scope, not the editor. The same editor
  focus node remains mounted at its original rectangle throughout.

At the original diagnostic checkpoint, the desktop sidebar's
[focus callback](../../lib/shared/widgets/app_shell.dart) (`528–536`) calls
`Scrollable.ensureVisible(alignment: 0.5)` inside the sidebar scroll view
(`415–460`). There is no sidebar `FocusTraversalGroup`. Flutter's default
reading-order traversal re-sorts parent-scope descendants using current rectangle
bands after that scroll. The nested route exits via `parentScope`; backward
navigation then operates in the shell scope whose geometry has changed. This is
not editor disposal, an owner reset, or a lost TextField focus-node identity.

A Providers-local traversal policy cannot order sibling shell destinations in
their enclosing scope. A correct stable shell/route boundary requires separately
authorized shared-shell work; no editor shortcut, parent-policy mutation, focus
injection, SDK change or weakened oracle was substituted.

After removing instrumentation, this exact command returned exit 1 with seven
passing cases and the same single failing wide Providers case; compact Providers
and both widths of Tools, Schedules and Profiles pass, all with 200% text and
reduced motion:

```bash
flutter test --no-pub --concurrency=1 \
  test/shared/widgets/inventory_keyboard_navigation_test.dart --reporter expanded
```

Task-local baseline hashes and raw focus/test logs are in
`/home/xel/.hermes/profiles/wing/autogoal/provider-keyboard-return/`.
No fixed-build browser acceptance is claimed: there is no authorized production
repair to build. Nearest-provider reruns, post-fix analysis, compiled-browser,
native desktop, physical screen-reader, Android, live services and full parity
are **NOT_CHECKED** for the original, now archived follow-up. Prior receipts above
remain historical evidence of their named scenarios. The forward receipt below
records the separate repair and its bounded acceptance.

Put the locked Flutter 3.44.2 SDK first on PATH. Use unused owned fixture ports,
the qualified Chromium executable and scratch output; stop only your server.

```bash
flutter gen-l10n
dart format --output=none --set-exit-if-changed \
  lib/features/providers/screens/providers_screen.dart lib/main_e2e.dart \
  lib/l10n/app_localizations.dart lib/l10n/app_localizations_en.dart \
  test/features/providers/providers_screen_test.dart \
  test/features/providers/providers_search_test.dart
flutter analyze --no-pub
flutter test --no-pub --concurrency=1 --reporter expanded \
  test/features/providers test/features/profiles \
  test/features/hermes_chat/gateways test/core/hermes/channel \
  test/core/hermes/hermes_api_test.dart test/features/tools test/features/schedules
flutter build web --release --no-pub -t lib/main_e2e.dart
node --check playwright/tests/regression/provider-search.spec.mjs
PORT=8937 HERMES_E2E_PORT=8938 node serve_web.mjs
# In another terminal:
PLAYWRIGHT_JSON_OUTPUT_NAME=/path/to/owned-scratch/browser-results.json \
WING_APP_URL=http://127.0.0.1:8937/ CHROME_EXECUTABLE=/path/to/qualified/chrome \
  npx playwright test --config=playwright.config.mjs \
  playwright/tests/regression/provider-search.spec.mjs \
  playwright/tests/regression/profile-search.spec.mjs \
  playwright/tests/regression/tools-search.spec.mjs \
  playwright/tests/regression/schedule-search.spec.mjs \
  playwright/tests/regression/browser-surfaces.spec.mjs \
  --grep 'Providers|Profiles|Tools|Schedules' --retries=0 --repeat-each=3 \
  --reporter=list,json --output=/path/to/owned-scratch/browser-output
git diff --check
```

## Forward shared-shell repair receipt (t_c5a4d301)

This separately authorized repair does not change the original blocked
`t_11b62717` contract or its diagnosis above. At implementation handoff it
awaited same-card native review. That lane subsequently approved `t_c5a4d301`
in run 98, and the live tracker records it done. Approval is limited to this
forward repair, not full Desktop parity or acceptance of either predecessor.

The profile-local journal retains `native-review-run98.md`. The reviewer reran
the four new and eight unchanged original widget cases: 12 passed, exit 0.
Formatting, analyzer and scoped checks passed. Retained browser/build evidence
was audited, not rerun in review. This documentation status update ran no tests.

The desktop shell now orders its sidebar and route traversal groups structurally.
Sidebar controls retain widget order while route controls retain reading order.
Destination focus still scrolls offscreen navigation into view. No Providers,
channel, API, identity, session-lifecycle or compact-shell code changed.

The new [shell traversal regression](../../test/shared/widgets/app_shell_focus_traversal_test.dart)
failed before the repair on the editor's immediate Tab/Shift+Tab return. After
repair all four new cases pass, including sidebar scrolling, both directions,
expanded/collapsed mode, 1280px short windows, 390px resize, 200% text, reduced
motion and disposal. Route-local spatial reading order remains distinct from
widget creation order. The original eight-case inventory oracle is byte-identical
(`a7487532f19f6d7dbff86dc2e9c1d6ccff04102f85a54393d027e4a88c042dd0`)
and all eight cases pass. Another 108 focused Providers and existing shell cases
pass, including continued search/clear without incidental calls or owner changes.

Exact focused checks:

```sh
flutter test --no-pub --concurrency=1 test/shared/widgets/app_shell_focus_traversal_test.dart test/shared/widgets/inventory_keyboard_navigation_test.dart --reporter expanded
flutter test --no-pub --concurrency=1 test/features/providers/ test/shared/widgets/app_shell_test.dart test/shared/widgets/app_shell_navigation_groups_test.dart test/shared/widgets/app_shell_desktop_parity_test.dart --reporter expanded
dart format --output=none --set-exit-if-changed lib/shared/widgets/app_shell.dart test/shared/widgets/app_shell_focus_traversal_test.dart
flutter analyze --no-pub
flutter build web --release --no-pub -t lib/main_e2e.dart
```

Five compiled deterministic Chromium journeys pass with retries disabled and one
worker: existing Provider keyboard/search targets at 390/1280px and desktop
navigation groups. Additive spec-local assertions prove immediate empty-editor
keyboard reversal and actual sidebar scroll movement at a 360px window height.
Original request-count, assignment, owner and keyboard assertions remain intact.
The freshly built artifact was copied to an owned fixture and its served JS hash
matched the build. Browser 200% text is not claimed; widgets exercise that scale.

Flutter 3.44.2 / Dart 3.12.2, Node 26.7.0 (not recommended Node 22), Playwright
1.61.1 and installed Chromium 152.0.7977.75 were exercised on Linux. Existing
flutter_tts Wasm dry-run and Cupertino font warnings remain. Task-only diffs,
baseline/final hashes, exact logs and acceptance mapping are retained under
`/home/xel/.hermes/profiles/wing/autogoal/shared-shell-keyboard-forward/`.
Native desktop, Android, physical screen reader, live Agent/provider, full suite,
full parity and release remain **NOT_CHECKED**. The governor separately archived
`t_11b62717` as superseded without completing it. `t_1c1e6f37` remains blocked;
this receipt does not change its passive-directory scope or authorize a retry.
