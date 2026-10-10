# Passive profile footer implementation

Status: executor-verified for `t_82b3229c` / `PORT-PROFILE-FOOTER`,
`PARITY-COMPOSITION`; same-card native review follows this implementation handoff.
This is an intermediate Desktop composition slice, not full profile-footer parity.

## Delivered boundary

[AppShell](../../lib/shared/widgets/app_shell.dart) now keeps a fixed footer below
scrollable desktop navigation. Expanded mode shows a passive Profile label/value
and Manage profiles button. Compact mode exposes one named navigation icon with
current-profile context in its tooltip and semantics. The full-width status bar,
utility Profiles destination and loaded Open/New actions remain in place.

The footer derives its value from the existing `_AppShellStatus.profile` on each
current-channel build. It redacts before bounding the new value to 80 characters
plus ellipsis; the same safe value reaches the tooltip and action semantics.
Disconnected state is Not loaded. Explicit profile names/IDs and the existing
absent-selection default/first-ID display fallback are unchanged. This display
fallback is not a profile selection or an authoritative profile inventory.

Manage profiles uses `context.go(AppRoutes.profiles)` without a profile argument.
It does not connect, construct a directory, read inventory, select, edit, create,
Stop, assign a model or answer an approval. The destination keeps its own exact
read/write gates. No providers, transports, backend operations or localization
files changed. `chatProfileManage` already exists in committed localization.
The shared redaction import is existing Dart client source; no new runtime or
packaging dependency is introduced.

A nested WidgetOrderTraversalPolicy group keeps layout-built scrollable navigation
before the fixed footer, retaining the shell's WidgetOrder policy and route-local
ReadingOrder policy. The button uses the existing focus-outline style and standard
visual density. Compiled Chromium exposed a 40px semantic target under desktop
density; the fix makes its real button target at least 48px, not just outer padding.

## Acceptance evidence

[New footer regressions](../../test/shared/widgets/app_shell_profile_footer_test.dart)
and the [updated boundary oracle](../../test/shared/widgets/app_shell_focus_traversal_test.dart)
prove the following on Linux Flutter widget execution:

- Current name, blank-name ID, missing-profile ID, absent selection with default,
  first-profile fallback and empty/disconnected display update from current state.
  A→B→A, endpoint replacement and provider replacement ignore obsolete notifications.
  Passive directory construction throws in the harness; incidental domain calls stay zero.
- Dummy path/token content is redacted in the actual value, tooltip and semantics;
  long names are bounded in expanded and compact modes. Profile identity is unchanged.
- Pointer, Enter and Space each navigate exactly once in both modes to a real
  ProfilesScreen. Denied read/write grants still expose no search, creation or
  edit affordance. State remains unchanged; reconnect does not replay navigation.
- Tab and Shift+Tab reverse Settings→footer→route editor after scroll, collapse,
  expand and resize. Real painted focus pixels are checked, not only ButtonStyle.
  Both outer and Material target sizes are at least 48px. At 2x text / 360px height,
  navigation scrolls and the fixed footer remains reachable without layout exceptions.
- Returning through ordinary go routing retains only the existing route's draft
  contract: the harness route-local editor is recreated empty. No shell draft
  persistence is added or claimed. Existing loaded-session ownership tests still pass.

The new tests ran before production edits and failed for the absent footer
(`.task-evidence/t_82b3229c/red.log`). Test-harness teardown/override corrections,
layout/traversal fixes and the compiled-browser density finding were repaired
before final checks; early failures are not acceptance evidence.

Executed final commands (all exit 0):

```sh
flutter test --no-pub --concurrency=1 test/shared/widgets/app_shell_reference_fidelity_test.dart test/shared/widgets/app_shell_focus_traversal_test.dart test/shared/widgets/app_shell_navigation_groups_test.dart test/shared/widgets/app_shell_global_session_access_test.dart test/shared/widgets/app_shell_profile_footer_test.dart
dart format --output=none --set-exit-if-changed lib/shared/widgets/app_shell.dart test/shared/widgets/app_shell_focus_traversal_test.dart test/shared/widgets/app_shell_profile_footer_test.dart
flutter analyze
flutter build web --release -t lib/main_e2e.dart
node .task-evidence/t_82b3229c/verify-footer.mjs
git diff --check
python <home>/.hermes/shared-skills/repo-docs/scripts/goals.py validate <repo>
```

The shell command passed 63 tests, including nine new footer tests. Formatting
reported zero changes; analyzer reported no issues. Logs are retained under
`.task-evidence/t_82b3229c/`: `shell-tests.log`, `format.log`, `analyze.log`,
`web-build.log` and `browser.log`. The JavaScript web build succeeded; its
flutter_tts Wasm dry-run warnings and Cupertino font warning do not establish Wasm support.

The scratch browser harness used the compiled deterministic E2E entrypoint,
existing `scopedInventory(page, [])` fixture helper for explicit profile query
context, and cached Chromium. That helper adds no profile inventory or management
grant. Bootstrap uses the existing E2E connect hook; subsequent footer activation
uses physical Enter/Space or pointer input. Expanded Enter, compact Space and
compact pointer navigate to Profiles without added domain requests; the complete
owner summary stays identical. `browser-result.json` records requests, owner,
errors and keyboard traces; its incidental requests and errors are empty.

Light expanded/compact, 900×360 short expanded/compact and dark 1280×900 screenshots
were captured and visually inspected. Focused/unfocused rendered crops differ and
keyboard escape/inverse return succeeds. Footer labels, fixed placement and focus
outline are legible; navigation scrolls above the footer without clipping it.
Browser short-height evidence is at normal text scale; 2x text evidence is from
widgets, not an asserted browser zoom equivalence. Images are `expanded.png`,
`compact.png`, `expanded-short.png`, `compact-short.png`, `dark.png` plus focus
crops under the same ignored evidence directory. The owned fixture listeners on
18867/18868 were stopped and both ports checked closed. The newly created
`build/web` output is deleted after capture; owner README assets remain untouched.

## Source binding and limits

Base Wing HEAD: `1afe1307e37ee1ddfa1f7d67ad047509e99c8784`.
Final scoped SHA-256:

| Source | SHA-256 |
| --- | --- |
| `lib/shared/widgets/app_shell.dart` | `1e64f3a12a824a3f2437a9651a874065c45f8187042a390f17e9a01f7678135a` |
| `test/shared/widgets/app_shell_profile_footer_test.dart` | `077041f03540c65083ccbea9c9af67ea63ebfff9f59a3b793887092204fb6b40` |
| `test/shared/widgets/app_shell_focus_traversal_test.dart` | `635437e514659a7efe76e5cc67367624e7a4ad4ab373ba0c4cf998f5449efde6` |

The approved inputs were local `docs/quality/profile-footer-composition.md` and
`docs/quality/desktop-next-port-slice.md`, plus TODO's target task contract.
Desktop's read-only ProfileSwitcher source was inspected after its AGENTS.md;
`lat` is unavailable and the reference was not modified. Its chip edits, separate
button switches and compact avatar opens a picker. Wing deliberately does none
of those in this slice. No Agent contract or upstream implementation changed.

Remaining gaps: true split edit/switch footer, global profile shortcut, running/
stopped grouping, full session-modal extraction, recents, tabs and collapse
relaunch persistence. `PARITY-COMPOSITION` remains partial. Native desktop,
physical Android, live Agent/provider inference, screen reader, packaging,
install/update and full parity are NOT_CHECKED. Full repository test/E2E/Go/audit
suites were not run for this bounded presentation-only change.

Shared dirty files, including localization, fixture, ledger and human documentation,
are excluded from the authored commit. Goals are updated only through the helper;
its task completion is implementation evidence, not independent review approval.
No publication, system modification, personal runtime or device action occurred.

Questions: none. Existing no-system-change, no-unauthorized-device-action and
no-publication defaults remain applied.
