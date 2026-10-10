# Desktop next port slice

> Reference correction: [official Desktop authority](official-desktop-reference.md). Prior Desktop source citations and parity conclusions in this document are withdrawn. Wing test results remain historical behavior evidence only.


Status: outcome mapping and one implementation contract for `t_78c1227c`,
`DOC-PARITY-COVERAGE` (goal `PARITY`). No product implementation delivered.

## Coverage resolution

Reuse the [JSON feature matrix](../product/hermes-desktop-feature-matrix.json)
and its [human view](../product/hermes-desktop-feature-matrix.md). They already
map every feature group to an existing goal and task. This receipt does not
create another all-outcome table or claim an exhaustive control census.

Executed mapping: 46 outcomes, 46 unique IDs, 46 resolved mappings, 29 unique
goals and 95 unique task IDs. All 56 distinct source/candidate paths exist.
The check also passed 13 receipt links and six scoped source fingerprints.

`python scripts/check_desktop_next_port_slice.py` checks unique HD row IDs,
JSON/Markdown agreement, goal/task ownership, TODO entry existence, source and
candidate paths, receipt links, source fingerprints and unchanged not-run cells.
Its output retains every resolved HD row and task status in
`.task-evidence/t_78c1227c/mapping.json`. A valid mapping is not proof that a task
covers every operation in its feature group. Completed documentation tasks are
not implemented features.

Conditional contracts retain the following gaps:

- HD-SHELL: `DOC-PARITY-COMPOSITION` delivered the approved brief, not its footer.
  `FINISH-DESKTOP-SHELL` delivered the restyle, not edit/switch/footer composition.
  `DOC-PARITY-RECENTS-REFERENCE` owns grouped-recents comparison, not this footer.
  Collapse relaunch belongs to `SHELL-PERSISTENCE`. Global loaded Open/New is
  already delivered under `GLOBAL-LOADED-SESSIONS`; do not port it again.
- HD-SEARCH, HD-FORK, HD-DELETE and HD-PINS: `SESSIONS` records bounded deterministic
  search/resume/fork/rename/single-delete journeys. Its met status does not prove
  bulk-delete counts, pin/group persistence or every Desktop filter. These
  remain conditional on operation-level acceptance and named-runtime evidence.
- HD-REASON, HD-CLARIFY and HD-QUEUE: their `CHAT-FIDELITY` mapping is an umbrella,
  not completed reasoning-budget, answer-protocol or queue administration parity.
  Require the exact Agent operation, current owner and no offline mutation replay
  before extending those controls. Transcript and dictation tasks are not substitutes.
- HD-OAUTH, HD-ACCOUNT, HD-SSH, HD-BACKENDS, HD-TABS, HD-PROJECT, HD-MEMORY and
  HD-KANBAN remain unsupported in the matrix. Their existing goal/task contracts
  must establish authority before exposing positive operations. Source paths and
  unavailable-state candidates do not simulate support. HD-PROVIDER and other
  administration rows require exact per-operation grants, not inventory access.
- All remaining rows retain their existing matrix goal/task mappings. Partial
  surfaces require success, failure/retry and stale-owner checks. HD-PAIR and
  HD-TRUST are Wing-specific trust outcomes, not Desktop equivalence. Native and
  physical evidence stays separate from deterministic client evidence.

## Next implementation contract

Choose exactly one slice: a passive current-profile footer with Manage Profiles
navigation, under `PARITY-COMPOSITION` / HD-SHELL. Apply the approved
[footer brief](profile-footer-composition.md#smallest-safe-implementation-slice).
This is an explicit intermediate deviation from Desktop's split edit/switch
footer, not full parity.

The current goal ledger has no corresponding footer implementation task.
`DOC-PARITY-COMPOSITION` and `FINISH-DESKTOP-SHELL` are done, and the remaining
composition task compares recents. Board inspection found the approved footer
brief card `t_6a1e03fc` done, but no footer implementation card. The stale unchecked
TODO comparison entry does not override the machine ledger's done status.
This card does not edit that entry, enqueue work or add a duplicate component task.
The contract below is ready for the next authorized implementation assignment.

## Scope

Change only `lib/shared/widgets/app_shell.dart`, its nearest shell tests,
`lib/l10n/app_en.arb` and regenerated localization output if new copy is needed,
and the later slice's support-status receipt. Add the footer below the scrollable
navigation in `_DesktopShell`. Retain the full-width status bar, utility Profiles
route and existing loaded Open/New actions. Expanded mode shows a non-editable
profile value and Manage Profiles button. Compact mode shows one named Manage
Profiles icon with profile context in its label and tooltip.

Exclude profile editing/switching, Ctrl/Cmd+P, profile inventory refresh,
running/stopped indicators, recents, full session-modal extraction, tabs,
new providers/dependencies/transports, mutations and privileged host operations.
Do not change upstreams or route Agent traffic through Wing Link.

## Sources

- [AppShell](../../lib/shared/widgets/app_shell.dart): `AppShell.build` listens to
  the current channel, `_AppShellStatus.fromState` projects display context,
  `_DesktopShell` separates scrollable navigation from the route focus group.
- [Profile selection](../../lib/features/profiles/providers/profile_selection_provider.dart):
  `effectiveSelectedProfileId` is pure display derivation. It seeds advertised
  default/first profile when explicit selection is absent, but makes no request.
- [Desktop ProfileSwitcher](official-desktop-reference.md#withdrawn-evidence):
  expanded chip edits, separate button switches, compact avatar opens the picker.
  Do not copy its list refresh or optimistic selection after failure.
- [Reference fidelity tests](../../test/shared/widgets/app_shell_reference_fidelity_test.dart),
  [focus traversal tests](../../test/shared/widgets/app_shell_focus_traversal_test.dart)
  and [navigation helpers](../../test/shared/widgets/app_shell_navigation_groups_test.dart):
  real focus-outline pixels, reversible traversal and zero-domain-call assertions.
- [Client ADR](../adr/client.md#decision), [API ADR](../adr/api-and-state.md#decision)
  and [route inventory](../product/routes.md): current architecture and destination
  authority. Navigation availability is not a synthetic domain capability.

Wing HEAD inspected: `1afe1307e37ee1ddfa1f7d67ad047509e99c8784`.
Desktop HEAD inspected: `withdrawn reference revision`.
The shared checkout includes unrelated dirty files, including the untracked
matrix and approved brief. These are attributed inputs, not this card's work.
Desktop instructions were read before scoped source inspection. `lat` is absent;
no upstream tool installation, runtime execution or upstream write occurred.

## Invariants

1. Owner: render only the current channel projection. Replacement A→B and
   disconnect must replace the footer display immediately. Do not cache a profile,
   construct a directory or revive old context after A→B→A.
2. Display: reuse `_AppShellStatus.profile` without inventing authoritative
   selection. Disconnected state uses `shellNotLoaded`. Missing names use the
   effective ID, including the existing default/first-profile display fallback.
   Test explicit, absent and default cases separately. Do not persist shadow state.
3. Privacy: apply the existing preview/redaction policy to the new value, tooltip
   and semantics. `_AppShellStatus.fromState` does not itself establish name
   redaction. Reuse `wingRedactedPreview` from
   [Wing redaction](../../lib/shared/security/wing_redaction.dart), as loaded-session
   labels already do. Bound the new label without changing profile identity.
   Do not expose credentials, endpoints or host paths in footer context.
4. Capability: Manage Profiles uses `AppRoutes.profiles` and the established route
   navigation pattern, without a profile argument. It requires no new Agent grant.
   The destination keeps its own read/write gates. Denied grants must stay denied.
5. No side effects: mounting, updating, collapsing or navigating performs no
   connect, select, create, Stop, model assignment, approval or inventory request
   from the footer. Destination-owned reads remain governed by that screen.
6. Focus: retain shell WidgetOrderTraversalPolicy and route ReadingOrderTraversalPolicy.
   Use named controls, a visible focus outline and a minimum 48px target. Keep
   Tab/Shift+Tab reversal after scroll and resize. At 2x text and 360px height,
   navigation scrolls and the footer remains reachable without overflow.
7. Recovery: navigation opens no switch/edit picker and captures no deferred
   domain intent. Back returns through existing routing and draft ownership.
   Disconnect/reconnect updates display only; it never retries a mutation.
   Do not promise new draft persistence from shell navigation.

## Observable regressions

The later implementation must add tests, not claim the existing tests cover a
footer that does not exist. Use deterministic fakes and assert these outcomes:

- Current-owner name/ID/default/unloaded display updates for A→B, disconnect and
  provider replacement, including A→B→A. Incidental domain-call counts stay zero.
- Pointer, Enter and Space navigate exactly once to `/profiles` in expanded and
  compact modes. No profile/session/model/run mutation occurs. Test denied grants.
- Footer semantics and tooltip name the navigation action, never Edit or Switch.
  Redacted display stays redacted in all three presentation channels.
- Tab/Shift+Tab reaches the control and reverses into the route editor after
  scrolling, collapse and resize. Assert actual focus painting, 48px targets and
  no layout exception at 2x text / 360px height.
- Route return preserves only the originating route's existing draft contract.
  Reconnect does not replay navigation or any domain intent.

Discriminating regression command for the later slice:

```sh
flutter test --no-pub --concurrency=1 test/shared/widgets/app_shell_reference_fidelity_test.dart test/shared/widgets/app_shell_focus_traversal_test.dart test/shared/widgets/app_shell_navigation_groups_test.dart test/shared/widgets/app_shell_global_session_access_test.dart
```

Also format changed Dart files, run `flutter gen-l10n` if localization changes,
run `flutter analyze`, and record target-runtime evidence separately. This card
runs only the nearest existing fidelity/focus tests to validate the source baseline.

## Executed evidence and limits

- `flutter test --no-pub --concurrency=1 test/shared/widgets/app_shell_reference_fidelity_test.dart test/shared/widgets/app_shell_focus_traversal_test.dart`:
  PASS, seven existing tests on Linux. Log: `.task-evidence/t_78c1227c/shell-tests.log`.
  These prove the current shell focus/layout baseline, not the proposed footer.
- `python scripts/check_desktop_next_port_slice.py`: mapping/link/fingerprint
  PASS, 46/46 mappings; result retained in `.task-evidence/t_78c1227c/mapping.json`.
- `git diff --check`, new-file whitespace checks and
  `python <home>/.hermes/shared-skills/repo-docs/scripts/goals.py validate <repo>`:
  execution results retained in `.task-evidence/t_78c1227c/ledger-checks.log`.

Scoped inspected-source SHA-256 fingerprints:

| Source | SHA-256 |
| --- | --- |
| `lib/shared/widgets/app_shell.dart` | `9a5e6a1bc9e6d56f457c429479097cf42b46ab2185986e1f5c39cdda2a1a5595` |
| `lib/features/profiles/providers/profile_selection_provider.dart` | `f7263666f71425de29011538d8bffae181820e9e75ef1c93bdde6c9ab5f0c5ad` |
| `test/shared/widgets/app_shell_reference_fidelity_test.dart` | `7c98a9ba1bde4b6bd9e1a1eaacac94852a130c5157194818101cf1481789564d` |
| `test/shared/widgets/app_shell_focus_traversal_test.dart` | `f09ee21eb2dd2c528a3af98e8c6a3060cdad2e5c753489850b2ff6e2d2b5a60c` |
| `withdrawn source citation` | `3167398843c1afa556492a8786bcded9d82cffd7ba3e1c65a29b1f291a63056d` |
| `docs/quality/profile-footer-composition.md` | `7599bd9ac35c2c8650bc4e538ffdd0617a2721ac88e071c10134578d5ee619b1` |

Native desktop, compiled browser, physical Android, live inference, screen reader,
install/update, packaging and full parity: NOT_CHECKED. No build artifacts created
by this card need retention. PARITY remains partial. No owner question is required.
The scoped prose follows the STE-inspired profile; full dictionary compliance
was not verified.
