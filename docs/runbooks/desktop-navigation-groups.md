# Desktop navigation groups

> Reference correction: [official Desktop authority](../quality/official-desktop-reference.md). Prior Desktop source citations and parity conclusions in this document are withdrawn. Wing test results remain historical behavior evidence only.


Task `t_1083781a` separates existing working destinations in the production shell. This is the regrouping portion of [Desktop next-gaps rank 4](../analysis/2026-10-03-desktop-port-next-gaps.md), not full sidebar parity or daily-workflow qualification.

## Behavior and boundaries

At widths of 600 logical pixels and above:

- Workflow contains Chat, Office and Schedules, in that order.
- Utilities contains Providers, Connections, Tools, Profiles, Persona and Settings.
- Expanded headings and a divider visibly separate the groups. Named semantic groups remain available in icon-only mode; every destination remains a named button with exact selected state. Chromium exposes that state as `aria-current="true"`.
- Utilities sit toward the bottom when space permits. Both groups share a scroll area at short heights. Keyboard focus scrolls its destination into view; the collapse control stays outside that scroll area.
- Expanded remains the default. Collapse choice is volatile shell presentation state, retained across route/channel changes and compact resizing, not persisted across app restart.
- Compact navigation remains Chat / Profiles / Connections / More, with its original More ordering and imperative push/back behavior. More can change the displayed page without replacing the root route-information URL.

Grouping, collapse and navigation do not call channel domain operations. Feature screens can still perform their existing capability-gated reads or lifecycle behavior when mounted. Neither this slice nor its tests assert that routing preserves all feature drafts: the shell's toggle and channel update preserve its current child; navigating to another route still follows that route's existing lifecycle.

The read-only [Desktop Layout reference](../quality/official-desktop-reference.md#withdrawn-evidence) at `withdrawn reference revision` pins Office/Schedules and places utilities and the profile switcher in its footer. Wing deliberately keeps Profiles and Persona as explicit utility routes rather than replacing them with Desktop's profile-footer editor. Chat remains navigation, not a New Chat creation action. Global recents, global profile-picker placement, Discover, Memory and Kanban remain out of scope. No Agent/Wing Link contract, grant or operation has been enabled.

## Verification

Focused production-shell widgets use actual GoRouter routes and a call-recording fake channel:

```sh
flutter gen-l10n
dart format lib/shared/widgets/app_shell.dart lib/shared/widgets/app_shell_presentation.dart test/shared/widgets/app_shell_navigation_groups_test.dart test/shared/widgets/app_shell_desktop_parity_test.dart
flutter analyze
flutter test --no-pub --concurrency=1 test/shared/widgets/app_shell_navigation_groups_test.dart test/shared/widgets/app_shell_desktop_parity_test.dart test/shared/widgets/app_shell_test.dart
```

Coverage includes all nine destinations in expanded/icon-only mode, exact selected semantics including Settings detail routes, Tab/Shift+Tab/Enter/Space, group boundaries, channel replacement, current-child draft/state preservation under toggling, unchanged status bar, compact More access, and 900×360 at 200% text with reduced motion and keyboard scrolling. The RED run failed on missing Workflow semantics before implementation.

Compiled JS-release browser checks use the existing synthetic fixture and strict keyboard actor, with no shared helper/config/server changes:

```sh
flutter build web --release -t lib/main_e2e.dart
# First verify both chosen ports are free; start only a task-owned fixture server.
PORT=18767 HERMES_E2E_PORT=18768 node serve_web.mjs
CHROME_EXECUTABLE=/usr/bin/chromium WING_APP_URL=http://127.0.0.1:18767 npx playwright test playwright/tests/regression/desktop-navigation-groups.spec.mjs playwright/tests/regression/persona-keyboard.spec.mjs playwright/tests/regression/connections-keyboard.spec.mjs --retries=0 --workers=1
```

The browser run passed 19 tests: one focused grouping/collapse/390px recovery journey, twelve existing Persona journeys and six existing Connections journeys. The focused journey navigates all nine desktop routes in both modes, checks group-scoped selected state, rendered keyboard focus changes, unchanged Chat owner and GET-only traffic. Existing Persona/Connections request-count, failure, owner and focus oracles remain intact. Exact obsolete desktop shell names were updated in Profile, Inventory and Provider keyboard targets as well; those three targets were not executed here. Rendered shell readback confirms plain Chat, Persona and Connections button names without the former `Tab N of 9` suffix.

Toolchain: Flutter 3.44.2 / Dart 3.12.2, system Chromium and Node v26.7.0 (repository recommends Node 22). Web build succeeded with pre-existing flutter_tts Wasm dry-run and missing Cupertino font-family warnings; this was not a Wasm build.

Raw logs, parsed results, baseline-relative diff and hashes are in the executor's profile-local `autogoal/desktop-navigation-groups/` evidence directory. No full unchanged suite was rerun. Native desktop, physical Android, screen-reader and live Agent/provider qualification are **NOT_CHECKED**. Browser viewports and widget execution are not those platform qualifications. No full Desktop parity or independent review acceptance is implied.

## Forward traversal repair receipt (t_c5a4d301)

Implementation is verified pending required same-card native review. This is a
new authorization of the existing shell focus seam, not a rewrite of the
accepted navigation grouping or either blocked predecessor's scope.

The sidebar and route now form separate traversal groups under a widget-order
shell boundary. Sidebar widget order stays stable when destination focus calls
`ensureVisible`; the route keeps its own reading-order policy. All nine routes,
selected semantics, collapse/expand, scrolling, status/channel observation and
compact navigation composition remain unchanged. No directory/session startup,
global recents, domain operations or new ownership state is introduced.

The [new four-case regression](../../test/shared/widgets/app_shell_focus_traversal_test.dart)
includes a pre-repair RED for immediate editor keyboard reversal, post-repair
GREEN, spatial route-local ordering, forward/backward reversibility, visible
keyboard-scrolled destinations, expanded/collapsed mode, 1280×900 and 1280×360
with 200% text and reduced motion, 390px resize and disposal. The original
eight-case inventory oracle remains byte-identical and now passes. The 108-case
focused Providers/existing shell gate passes with no assertions removed.

A fresh JS-release deterministic build passes five focused Chromium journeys:
Provider keyboard/search at 390/1280px and desktop navigation groups. Narrow
additive Provider assertions check single-key escape/return and visible Settings
after actual short-window sidebar movement. Existing request-count and full
profile/session/model assignment assertions are retained. Browser 200% text,
native desktop, Android, physical screen reader, live Agent/provider, full suite,
full parity and release are **NOT_CHECKED**.

The [Provider forward receipt](provider-search.md#forward-shared-shell-repair-receipt-t_c5a4d301)
records exact focused Flutter commands and toolchain limits. Raw logs, owned
browser results, baseline-relative diff, source hashes and acceptance mapping
are in `<home>/.hermes/profiles/wing/autogoal/shared-shell-keyboard-forward/`.
Required native review, not this executor receipt, owns final closure.
