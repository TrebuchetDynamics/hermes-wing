# Graph-guided shell persistence refactor

> Reference correction: [official Desktop authority](official-desktop-reference.md). Prior Desktop source citations and parity conclusions in this document are withdrawn. Wing test results remain historical behavior evidence only.


Status: implemented local presentation slice. Full Desktop parity and native
process-relaunch qualification remain open.

## Reference and scope

Graphify 0.9.80 mapped Desktop first, then Wing. The Desktop reference is
`withdrawn reference revision`. Wing started at
`b9eb5b3d9f6f3a433dd36cb6271ad8ec769b2319` with pre-existing dirty changes.
The extraction used filtered current-worktree snapshots, not pristine commits.
Hashes and selected/excluded paths are retained in the local receipt directory:
`.task-evidence/graphify-desktop-wing/`.

Only source and test code was copied. Upstream Agent, profile/runtime stores,
credentials, documentation, vendor code and build output were excluded.
Extraction used two workers with no semantic pass or LLM community labels.
Neither reference repository was changed.

| Serialized graph | Nodes | Relationships | EXTRACTED | INFERRED |
| --- | ---: | ---: | ---: | ---: |
| Desktop | 4,824 | 13,384 | 13,260 | 124 |
| Wing before refactor | 10,781 | 19,406 | 18,839 | 567 |
| Wing after refactor | 10,804 | 19,445 | 18,878 | 567 |

All four verified graphs, including the two-file CLI fixture, have unique node
IDs and no dangling relationship endpoints. Counts come from serialized JSON,
not clustering's smaller loaded graph. Every graph has nonempty JSON, report
and HTML output. Wing's HTML is an aggregated community view, not its full graph.
Offline HTML rendering was not tested.

Coverage is incomplete. Desktop scanned 816 files, with 324 yielding no symbols.
Final Wing scanned 719 files, with 33 yielding no symbols. Wing's C-header parser
reported an error in `linux/runner/my_application.h` at line 18. No missing-language
warning was reported, but this does not prove complete language coverage. Dart
extraction uses regex, not a Dart semantic analyzer.

## Graph leads checked against source

Desktop's graph establishes `Layout()` → `SidebarRecentSessions` as an extracted
call. Exact `explain` also connects the recent-session component to workspace
grouping and disclosure helpers. Its broad query was truncated, so it was not
used as a complete dependency list.

Live [Layout source](official-desktop-reference.md#withdrawn-evidence)
reads `hermes.sidebar.collapsed` at startup. Wing's former local widget field
always started expanded. The final Wing graph establishes `AppShell` →
`wingSidebarExpandedProvider` as an extracted Riverpod reference. A file-to-file
path query found no directed path. That missing path is an extraction limitation,
not evidence that Wing lacks the import.

## Delivered change

[AppShell](../../lib/shared/widgets/app_shell.dart) is now a `ConsumerWidget`.
The [shell preference controller](../../lib/features/settings/providers/shell_preferences_provider.dart)
owns only the local expansion boolean, saved as `wing.shell.sidebar_expanded`.
It reuses Riverpod and the existing SharedPreferences dependency.

- Restore the saved choice when a new provider scope starts.
- Keep immediate keyboard/pointer response while storage loads or saves.
- Prevent late loading from overwriting a newer user choice.
- Serialize writes so old asynchronous completions cannot overwrite later clicks.
- Keep the in-memory choice usable when reading or saving fails.
- Retain the preference across routes and compact/wide layout changes.

No Agent state, profile identity, connection identity, credential or transcript
is persisted by this controller. No new request, capability, transport, dependency,
profile mutation or Wing Link operation was added. Existing drafts and keyboard
focus remain mounted when the desktop sidebar is toggled.

## Executed checks

- The restore regression first failed: expected 64px, actual 250px.
- The early-click regression first failed because the loaded value overwrote it.
- The write-order regression first failed because both platform writes started together.
- `flutter test --no-pub --concurrency=1 test/features/settings/providers/shell_preferences_provider_test.dart test/shared/widgets .task-evidence/graphify-desktop-wing/render_test.dart`: 161 passed, exit 0. This includes eight new production regression tests and one local render harness.
- `flutter analyze`: exit 0, no issues.
- `dart format --output=none --set-exit-if-changed lib/features/settings/providers/shell_preferences_provider.dart lib/shared/widgets/app_shell.dart test/features/settings/providers/shell_preferences_provider_test.dart test/shared/widgets/app_shell_sidebar_persistence_test.dart`: exit 0.
- `flutter test --no-pub --concurrency=1 .task-evidence/graphify-desktop-wing/render_test.dart`: font-backed wide/compact render passed. Both images were inspected. This is Flutter widget rendering, not native or live Agent evidence.
- `python <home>/.hermes/shared-skills/graphify/scripts/test_build.py`: seven passed.
- The real two-file CLI fixture built successfully. Query, explain and path returned `run()` → `normalize()`.
- `make -C <home>/.hermes/shared-skills test`: exit 2, 27 offline suites passed and one failed. The unrelated `autogoal/scripts/test_picker_policy.py` skill-size assertion failed. No unrelated repair was made.
- The first full Flutter run was interrupted by the tool's 420-second timeout. It was not a completed suite.
- The tracked retry of `flutter test --no-pub --concurrency=1` completed: 3,664 passed, zero failed, zero skipped, exit 0. Its log and parsed counts are retained in the local `receipt.json`.

Graph build commands, source hashes, coverage warnings, traversal output, logs,
counts and screenshots remain local in `.task-evidence/graphify-desktop-wing/`.
The active profile resolved the canonical shared Graphify adapter. No installer,
hook, watcher, menu publication, remote upload or model call was used.

## Remaining parity work

### Current-worktree refresh

The continuation rebuilt Desktop first, then Wing into fresh output roots.
The original maps and manifests were not overwritten. Current code snapshots,
hashes, logs and serialized counts are local at
`.task-evidence/graphify-desktop-wing-refresh/`.

Desktop remains at the reference revision above: 4,824 nodes and 13,384
relationships (13,260 EXTRACTED, 124 INFERRED). Current Wing has 11,313 nodes
and 20,709 relationships (20,105 EXTRACTED, 604 INFERRED). Wing's snapshot
includes intervening worktree changes from other slices. These differences
are not attributed to the sidebar refactor.

Both refreshed graphs use schema 1 and Graphify 0.9.80. Required artifacts are
nonempty, node IDs are unique, and every relationship endpoint exists.
Desktop selected 816 source files and reported 324 with no symbols. Wing
selected 763 source files and reported 33 with no symbols, including the same
partially parsed C header. Dart coverage remains regex-based.

Exact traversal again returned `Layout()` → `SidebarRecentSessions` and
`AppShell` → `wingSidebarExpandedProvider`, both EXTRACTED. An exact lookup
for `toggleSidebar` returned no match in the refreshed graph; live source,
not that missing lookup, establishes its persistence behavior.

Fresh affected validation passed all eight tests with
`npm run test -- test/features/settings/providers/shell_preferences_provider_test.dart test/shared/widgets/app_shell_sidebar_persistence_test.dart`.
`flutter analyze` and the four-file formatting check also passed. The earlier
3,664-test full-suite receipt applies to its earlier source snapshot, not all
intervening changes. No additional production refactor was needed to complete
this delivered preference slice.

The two existing `SHELL-PERSISTENCE` follow-ups in `TODO.md` now name executable
native harness work and observable acceptance. Their IDs and dependencies remain
unchanged. The goal stays unverified until native relaunch is exercised.

### Subsequent full-suite result

The current-worktree `npm run test` completed with 3,699 passing tests and nine
failures, exit 1 (`proc_9d65cfb39694`). This supersedes any inference that the
current full suite is green. It does not invalidate the eight passing persistence
regressions or the earlier snapshot's full-suite receipt.

A focused rerun of `hermes_direct_first_run_test.dart` and
`app_shell_reference_fidelity_test.dart` passed all four first-run retry variants,
but reproduced the status-bar mismatch at the fidelity test's line 43: expected
26px, actual 28px. The original first-run failures remain unexplained, not fixed.
The full-run tail also shows three router-transition failures from absent controls
at `app_router_transitions_test.dart` lines 66 and 138. One additional failure
could not be identified from the retained rolling process tail.

The local `full-suite-result.json` and `failure-reproduction.log` retain the result
and its limits. No production or test edits were made during this failure triage.

### Verification repairs

The subsequent repair restores the status text's explicit line height of 1.
This returns the collapsed status bar to 26px without removing keyboard inspection
or scaled-text disclosure. Initial native connect intents now route directly to
the existing pairing step (`/enroll?step=pair`) instead of the welcome chooser.

App-level tests now use deterministic endpoint storage and channels. The theme
selection-area test opens the actual Settings route, because fresh welcome is
intentionally outside the selectable connected shell. Intent inspection is faked
and cannot issue network requests or exchange credentials.

The app/theme/fidelity/status regression command passed 29 tests. Analysis and
four-file formatting also passed. Router, first-run and preference tests passed
in a separate focused check. The earlier failed full-suite result remains history;
the post-repair full-suite result must be read from its new log, not inferred from
these focused passes. The interrupted intermediate run was cancelled after source
repairs and is not a completed suite.

The first completed post-repair full suite reported 3,708 passed and three failed.
All three reproduced stale test interactions: optional setup was not expanded
(including after returning from pairing), and a directory action expected its old
label. Tests now expand the actual disclosure and expect `Add Hermes`, retaining
the setup, live-handoff, empty-directory and no-server-setup assertions. The two
affected files passed all 72 tests. Final analysis, six-file formatting and
`git diff --check` passed. A fresh graph of the baseline plus six owned deltas is
retained in `wing-final-complete/graphify-out/` under the refresh evidence root.
The final full `npm run test` completed successfully: 3,711 passed, zero failed,
zero skipped, exit 0 (`proc_d670105d969e`). Its complete log is
`full-suite-final.log`, with parsed results in `final-repair-receipt.json`.
All six owned source hashes match the receipt in this documentation recheck.
The final repaired graph contains 11,314 nodes and 20,722 relationships:
20,118 EXTRACTED and 604 INFERRED. These counts describe the final repair graph,
not the earlier current-worktree refresh above.

The complete log confirms the 3,711-test passing summary. The receipt records
exit 0 and zero skipped tests. Its six-file hash check does not establish that
all current source, tests and dependencies match the tested snapshot. Later SSH
transport, form and production-integration changes need their own checks.
This qualifies the recorded Flutter test snapshot, not the current whole
worktree, native relaunch, Android execution, SSH integration or delivery to main.

This is the first graph-guided implementation increment, not a full project
conversion. Continue from the existing parity backlog rather than duplicating it:

1. Prove persisted expansion through actual native process relaunch. The current
   tests use fresh provider scopes and mocked platform storage.
2. Match Desktop's separate profile edit/switch controls. The passive Manage
   profiles footer remains an explicit adaptation.
3. Qualify owner-safe multi-conversation tabs and close/Stop behavior before
   exposing them. Do not copy renderer-owned run state into Agent authority.
4. Extend recents only with supported Project/session contracts. Desktop's direct
   database/cache reads and host paths are not permissible Wing API substitutes.

`PORT-SHELL-PERSISTED-STATE` advances `SHELL-PERSISTENCE`. Existing relaunch and
compact-return qualification tasks remain the goal's follow-ups. No native,
browser E2E, live provider, installation or release claim is made here.
