# Linux full-feature qualification verdict

**Overall Linux: PARTIAL. PARITY is not met.** This is an offline fixture evidence
join, not official Desktop parity, real-Agent, hardware or packaged-delivery
acceptance. The [50-family matrix](../product/hermes-desktop-feature-matrix.json)
and every existing live task retain their runtime classifications and acceptance.

## Evidence owners and boundaries

The [campaign plan](../plans/2026-10-21-linux-feature-qualification.md) defines the
scope. The [fixed driver](../../scripts/run_linux_feature_qualification.py) owns
isolated source/SDK/dependency capture, exact commands, terminal cases, native
process observation, logs and cleanup. The
[receipt checker](../../scripts/check_linux_feature_qualification.py) joins its
five schema-1 lanes; it does not launch an Agent, discover credentials, run an
installer or fill missing rows from historical prose.

| Lane | Existing evidence owner | Registered target and boundary |
| --- | --- | --- |
| Shared | [Shared regressions](linux-shared-regression.md) | Adapter inventory and selected native suites; preferences, secure storage, text input and file-selector seam mocked |
| Connections | [Connection/plugin qualification](linux-connection-qualification.md) | Five Add Hermes journeys; synthetic transport/storage and framework input, not all separate plugin/SSH runners |
| Chat | [Chat qualification](linux-chat-qualification.md) | 25 current Chat/Bot/tab/timestamp/JSON cases plus local-serve-read and transcript-keyboard runners; synthetic Agent, real owned chooser/file subsets |
| Management | [Management qualification](linux-management-qualification.md) | 33 rows from 12 journeys; exact synthetic grants, revisions, denial and unavailable destinations, not deployed administration |
| Access | [Access qualification](linux-access-qualification.md) | 12 cases plus compact-return persistence; framework semantics/lifecycle/input, real owned clipboard/save and preferences subsets, not physical accessibility/audio |

Earlier lane results remain historical results for their original fingerprints.
A task completion or a public documentation table is not a reusable lane artifact.
The join requires accessible original receipts, case documents, raw logs and nested
artifacts. Missing or changed inputs require the same fixed fixture lane to run
again; no synthetic case results are permitted.

## Checker contract

```sh
python3 -m unittest discover -s test/tooling \
  -p linux_feature_qualification_report_test.py -v
python3 scripts/check_linux_feature_qualification.py \
  --phase fixture --input "$TMPDIR/linux-qualification"
```

Use the [driver prerequisites](linux-qualification-driver.md#inspection) and an
owned private output directory. Run all five fixed lanes first, using the four
bounded shared batches in the [shared runbook](linux-shared-regression.md#complete-bounded-dispatch).
Separate retained locations can be joined with private `composition.json` under
that input directory: schema 1, `lanes` containing exactly the five lane names,
each with `directory`, `receipt_sha256` and `campaign_sha256`. The directory is
an owned private original location, not a relocated/rewritten receipt. The checker
verifies both digests before reading it.
Long commands use `autowork-run timeout ...`. The checker needs Python only; it
never substitutes its unit-test data for native evidence.

The checker verifies complete captured source maps and the current executed-input
closure, campaign binding, registered command vectors, exact integer exits/counts (not
booleans), terminal cases, expected case/feature/route inventories, original
case/log digests, native observation and completed owned cleanup. Shared machine
logs must reconcile starts/terminals, selected adapter registrations and observed
suite paths. Skips, missing/duplicate/nonterminal records, interrupted commands,
stale inputs, altered artifacts or a successful arbitrary wrapper fail validation.
Nested runner receipts are compared with retained artifacts and validated by their
existing evidence owners. Public actions have a second, independent source scan:
all owned `lib/**/*.dart` files (not a test-selected file list) are fingerprinted.
The ledger records named/cascade callbacks, individual menu/choice/navigation and
local-slash/option descriptors, enum members, literal iterable choices, named
collection initializers, shortcut activators, raw key references and dispatch branches by file, character offset,
line, selector and file hash. Comments and string
contents are not callback bindings. The validator compares source files and
entries bidirectionally; omitted files/entries, changed selectors, added controls,
unknown entries and unearned passing dispositions are rejected.

This is a conservative lexical inventory of the current Dart forms, **not an AST,
reachability proof or count of distinct user operations**. It deliberately includes
internal forwarding, non-action branches and other-platform variants rather than
silently excluding them. Dynamic rendering, keyboard reachability and group-level
assertions do not establish execution of an individual entry point. New UI forms
require reviewing the extractor as well as rerunning affected evidence.

Private `qualification.json` retains exact cases, failures, lane commands and
source/tool bindings. A validation error replaces any prior verdict with
`INVALID` and exits 2. A valid ledger exits 0 even when fixture coverage is
`PARTIAL`; exit 0 means evidence validation succeeded, not full coverage or Linux
support. Required real-Agent/hardware/package cells always remain `not_run` here,
so the overall Linux verdict is always `PARTIAL` and `parity_met` is false.

### Coverage interpretation

- `pass`: the named bounded fixture assertion passed, not its whole feature family.
- `unsupported`: a passing negative assertion with an explanation; never positive
  support. Native-serve tabs/attachments/clarification and frozen-snapshot JSON
  guarantees remain unavailable despite their negative cases passing.
- `fail`, `not_run`, `coverage_gap`: preserved distinctly; no relabeling as pass.
- An empty ledger cell has `coverage_gap`, no case IDs and an explicit reason.
  This is a coverage disposition, **not a fabricated runtime case**.
- Route IDs on a journey describe its context. The connection target directly
  composes Add Hermes; its `/hermes/add` metadata alone does not qualify router
  composition. `/agents` is an actual redirect; `AppRoutes.agents` aliases
  `/profiles`. `/` redirects to Chat. More is an action sheet, not a route.
- `action_groups` are bounded source-traced scenario subsets, not a public-control
  inventory. `actions` is the independent concrete entry-point ledger. Until an
  exact case/assertion binding is reviewed, each entry has `coverage_gap`, a source
  reference, an explanation and no runtime case IDs. This deliberately refuses to
  promote even a related passing group to an individual control pass. Source
  tokens are not fabricated runtime cases; no all-actions-qualified claim is made.

## Current-source execution record

The earlier attempt executed all five fixed lanes on Linux x86_64 GTK/X11 under
owned Xvfb/D-Bus, Flutter 3.44.2 / Dart 3.12.2 and Node 22.22.2. This retry retains
those original artifacts and revalidates their complete source-input equivalence,
exact dispatch, terminal inventory, digests and cleanup; it does not claim a fresh
native execution. Only non-executed report/checker inputs changed after restoring
the exact tested Chat prerequisite repair. No native lane rerun is needed for
those report-only changes. No physical device, real Agent/provider or packaged
artifact was exercised. Every selected retained command below exited 0; all owned
process groups were gone and isolated state removed.

| Lane | Verified result |
| --- | --- |
| Shared | 776 core + 350 screen + 3 delete-timer + 2 create-timer native product cases = 1,131; one host inventory case; zero skips; all 88 selected suites observed |
| Connections | Registered GTK target: four passing rows, one unsupported negative row |
| Chat | Repaired registered target: 23 passing rows, two unsupported negative rows; local-serve-read and transcript-keyboard runners both validated |
| Management | Registered target: 12 journeys, 33 rows (12 passing, 21 unsupported negative) |
| Access | Registered target: 12 passing rows; compact-return real-preference runner validated |
| Checker regressions | Nine focused Python tests; includes concrete action/file omission and source-drift negative controls |
| Driver regressions | 19 focused Python tests; no native execution inferred |
| Dart preparation/analysis | Earlier attempt's locked preparation and analysis retained as historical checks; retry checks changed-target formatting, with no SDK or package mutation |

The ledger contains 1,207 records: 1,132 shared suite cases and 75 feature rows
(51 `pass`, 24 `unsupported`). Feature rows are not a count of independent UI
tests; management emits multiple dispositions from a journey. All 50 family
cells, 15 composed-route/alias cells and 37 bounded action groups are accounted
for as bounded scenarios, **not** as exhaustive public-action qualification.
The separate source ledger has 1,431 entry-point candidates across 231 Dart files:
672 callback bindings, 137 descriptors, 213 enum members, 37 literal iterable
choices, 211 collection-initializer entries, 50 key references and 111 dispatch/
pattern branches. All 1,431 retain `coverage_gap` until exact entry-point/assertion
bindings exist; this is not 1,431 independent human actions or 1,431 executed tests. Fixture
coverage is **PARTIAL**: `HD-UPDATE`, three route contexts, five scenario subsets
and concrete public-action qualification still lack case-level evidence. No
successful wrapper hides them.

### Source equivalence and retained failures

The retry's current-input SHA-256 is:

```text
6dcbe705c5a449a5f70648eebf2685c52fe69641b3a40823cec2e9214e80b99b
```

Evidence is explicitly **composed**, not one simultaneous run. Shared, connections,
management and access retain original captured source
`0de309f3668c33e3d514b814d001c1258259e271798522065dd5fd1e9b76fafd`.
The full maps differ only in this checker, its Python regression module and the
Chat-only GTK target. None is executed/imported by those four fixed lanes; all
other source/test/harness inputs match exactly. Their original receipts were not
repinned. Chat retains its successful rerun with the repaired target; its map now
differs only in the checker and its Python regression module, neither executed by
the Chat lane. All five toolchain/package/native-dependency bindings are identical. Chat's 25
rows and the access export row also retain the actual stock MIME-cache SHA-256;
readback verified all 26 against the current public file bytes. Any other source
drift is rejected; changing the Chat target always invalidates Chat evidence.

Two unchanged Chat attempts aborted at `paged JSON GTK save keeps projection and
destination outcomes separate`: each exited 1 after ten completed tests, leaving
fifteen incomplete tests plus teardown, no feature-case artifact and both later
runners unrun. The [Chat prerequisite repair](linux-chat-qualification.md) seeds
only stock MIME cache metadata into the owned XDG data root. The fresh full Chat
lane passed afterward. The original failed receipt/log remains retained under
`retained_failures` with exact exit 1, source and log digest, explicitly excluded
from current passing coverage. The earlier attempt is also preserved privately.
No incomplete case result was synthesized.

Distinct tests can legitimately share an exception's display title. Shared
records use batch/reporter IDs; duplicate IDs and cross-batch overlap are rejected
without deleting either same-title timer result. All five original six-minute
timer cases ran unchanged. The runner's whole-suite merged-tree gate remains
separate and is not claimed by this worker or checker.

### Family dispositions

These are bounded fixture statuses, **not changes to matrix runtime support**.
`pass + unsupported` preserves both offered and unavailable subsets. Case counts
refer to matching feature rows; exact IDs and source/log bindings are in the
private ledger and linked lane owners above.

| Matrix ID | Fixture statuses | Rows |
| --- | --- | --- |
| HD-ENTRY | pass + unsupported | 2 |
| HD-LOCAL | pass + unsupported | 2 |
| HD-REMOTE | pass + unsupported | 3 |
| HD-OAUTH | unsupported | 2 |
| HD-SSH | pass + unsupported | 2 |
| HD-HOSTS | pass | 2 |
| HD-SHELL | pass | 2 |
| HD-TABS | pass + unsupported | 2 |
| HD-PROFILE | pass | 6 |
| HD-PROJECT | unsupported | 2 |
| HD-PROVIDER | pass | 5 |
| HD-MODEL | pass | 5 |
| HD-CHAT | pass | 4 |
| HD-APPROVAL | pass | 1 |
| HD-STOP | pass | 2 |
| HD-CLARIFY | unsupported | 1 |
| HD-QUEUE | pass | 2 |
| HD-DRAFT | pass | 12 |
| HD-SEARCH | pass | 2 |
| HD-RESUME | pass | 2 |
| HD-ATTACH | pass + unsupported | 2 |
| HD-EXPORT | pass + unsupported | 9 |
| HD-VOICE | pass | 7 |
| HD-COMMAND | pass | 1 |
| HD-SKILLS | pass + unsupported | 5 |
| HD-MCP | unsupported | 2 |
| HD-MEMORY | unsupported | 1 |
| HD-SCHEDULE | pass + unsupported | 5 |
| HD-KANBAN | unsupported | 1 |
| HD-GATEWAY | pass + unsupported | 5 |
| HD-ARTIFACTS | unsupported | 1 |
| HD-PREVIEW | unsupported | 1 |
| HD-TERMINAL | unsupported | 1 |
| HD-BOTS | pass | 5 |
| HD-CLOUD | unsupported | 1 |
| HD-ACCOUNT | unsupported | 1 |
| HD-SETTINGS | pass | 1 |
| HD-DIAG | pass | 1 |
| HD-UPDATE | coverage_gap | 0 |
| HD-NATIVE | pass | 3 |
| HD-ACCESS | pass | 11 |
| HD-IMPORT | unsupported | 1 |
| HD-STARMAP | unsupported | 1 |
| HD-GUIDE | unsupported | 1 |
| HD-PLUGINS | unsupported | 2 |
| HD-RADIO | unsupported | 1 |
| HD-VAULT | unsupported | 1 |
| HD-PLUGIN-PACKAGES | unsupported | 1 |
| HD-SCREEN | unsupported | 1 |
| HD-PETS | unsupported | 1 |

## Explicit offline coverage gaps

All 50 matrix families receive ledger cells. `HD-UPDATE` has no case-level runtime
record in these five lanes: current Settings is not an updater, and installer
inspection is not installation/upgrade evidence. Keep its positive feature gap
and the artifact-delivery gate; do not invent an `unsupported` test.

Current composed routes and aliases are inventoried from
[`AppRoutes`](../../lib/router/routes/app_routes.dart) and the
[router](../../lib/router/providers/app_router.dart). `/enroll`, `/setup/local`
and `/` have no four-lane journey route records. The shared adapter includes
bounded enrollment/legacy-rejection and router regressions, but that is not full
positive welcome/setup UI qualification. In particular, the selected local-setup
suite checks platform availability, not operating the composed setup UI.

The action ledger explicitly retains gaps for all positive welcome entries,
composed Local setup, the complete saved-host connect/disconnect/remove surface,
physical OS menu/window actions and install/upgrade/remove/rollback. These are
missing evidence, not missing-feature implementation authority. Other offered
subsets are mapped to their exact case IDs, including canonical Bot Chat and
rejections, session tabs/actions, FIFO, local timestamps and paged JSON consent,
refusal, cancellation, owner fencing and save. No exhaustive public-control pass
is claimed from this bounded campaign.

### Concrete public actions missing from the earlier group inventory

The earlier attempt's 37 groups omitted individual controls and could not reject
their deletion. The independent source ledger now retains these entries, among
others, without assigning unearned runtime results:

| Source owner | Concrete entries retained as unbound coverage gaps |
| --- | --- |
| [Session list](../../lib/features/hermes_chat/screens/widgets/hermes_chat_sessions.dart) | Copy ID, details, copy details; select all, cancel selection, delete selected; each menu descriptor and dispatcher separately |
| [Chat layout](../../lib/features/hermes_chat/screens/state/hermes_chat_layout.dart) | Queue manage/open originating session/copy/send now/cancel all; dictation, hands-free and emoji entry; local slash descriptors and keyboard branches |
| [Chat header](../../lib/features/hermes_chat/screens/hermes_chat_screen.dart) | Each compact overflow entry; New Session, diagnostics and disconnect; separate text/Markdown clipboard and save choices versus paged JSON |
| [Saved connections](../../lib/features/gateway/widgets/saved_connections_section.dart) | Rename, update connection, reconnect, management-profile navigation; not just connect/disconnect/remove |
| [Settings](../../lib/features/settings/screens/settings_screen.dart), [Voice](../../lib/features/settings/screens/settings_voice_screen.dart) | Separate avatar, transcript scale, spellcheck, language, command-word and voice preference controls |
| [Schedules](../../lib/features/schedules/screens/schedules_screen.dart) | All, Enabled and Disabled enum choices independently, not merely their loop's shared selection callback |
| [Model assignment](../../lib/features/providers/widgets/model_picker_sheet.dart) | Main slot and each named auxiliary-task choice, including Vision and Web extract, not merely the shared dropdown descriptor |
| [Shell destinations](../../lib/shared/widgets/app_shell_presentation.dart), [Shell](../../lib/shared/widgets/app_shell.dart) | Each destination descriptor, compact overflow, profile overlay and collapse callback |

The source manifest also includes delegated widgets and every other Dart source,
so omitting a file cannot hide its controls. Checked menu items retain their full
enum selectors; enum-generated choices, literal timestamp aliases and named
auxiliary-task collection entries are separate, not collapsed into their shared
callback/descriptor. Scenario-group passes remain useful
bounded evidence, but are not exact entry-point assertion bindings. Resolving
these explicit runtime coverage gaps is separate from validating the completeness
of this source inventory. No missing feature or live operation is implemented to
fill the ledger.

Separate connection/plugin/SSH runners described in their existing owner are not
registered targets of these five lanes. Their earlier evidence remains separate;
this join does not silently adopt inaccessible or source-stale receipts.

## Existing live, physical and package owners

These are residual cells, **not prerequisites of offline reporting**, new tasks,
closed gates or expanded live authority. No credentials, physical device, live
provider operations, personal services or disposable installer target were used.

| Existing task | Unverified cells |
| --- | --- |
| [PARITY-NATIVE-LINUX-LIVE](../../tasks/items/PARITY-NATIVE-LINUX-LIVE.md) | Actual Agent/SSH/OAuth/provider custody; microphone/acoustics, screen reader, Wayland/IME |
| [PARITY-LIVE-WORKFLOW-LIVE](../../tasks/items/PARITY-LIVE-WORKFLOW-LIVE.md), [PARITYUPDATE-002-5c-LIVE](../../tasks/items/PARITYUPDATE-002-5c-LIVE.md) | Real generation, correlated approvals, authoritative Stop/terminal and canonical readback |
| [BACKEND-SSH-KEY-NATIVE-LIVE](../../tasks/items/BACKEND-SSH-KEY-NATIVE-LIVE.md) | Real host/key authentication, encrypted-key custody and native SSH-key chooser |
| [DOC-NATIVE-FAILURE-BOUNDARY-LIVE](../../tasks/items/DOC-NATIVE-FAILURE-BOUNDARY-LIVE.md), [DOC-NATIVE-DESIGN-REVIEW-LIVE](../../tasks/items/DOC-NATIVE-DESIGN-REVIEW-LIVE.md) | Intended-target chooser/modal, latency/cancellation/custody and UX review |
| [VERIFY-PERSONA-LIVE-COMPATIBILITY](../../tasks/items/VERIFY-PERSONA-LIVE-COMPATIBILITY.md) | Deployed SOUL revision/conflict saves |
| [PARITYGAP-002-76-LIVE](../../tasks/items/PARITYGAP-002-76-LIVE.md) | Full GTK destination/overwrite/readback/owner-change and live projected-history export |
| [VERIFY-SHELL-NATIVE-INPUT](../../tasks/items/VERIFY-SHELL-NATIVE-INPUT.md) | Physical keyboard/window, OS menu activation and intended-target persisted intent |
| [VERIFY-DESKTOP-NATIVE-DELIVERY](../../tasks/items/VERIFY-DESKTOP-NATIVE-DELIVERY.md) | Exact-artifact installation/upgrade, retained keyring, client-only removal and authorized failure/rollback |

Permission cannot create missing Agent contracts. OAuth, Projects, vault, plugin
packages, Screen, Radio, import, Pets and missing administration remain gated by
actual authoritative operations; negative route recovery does not enable them.
No matrix runtime cell is advanced, no goal focus changes, and no existing live
acceptance is waived.

Revisit this owner after changes to the lane registry, case registries, adapter
imports/registration, source/tool/dependency inputs, composed routes, public
actions or the live/package evidence. Freeze and rerun changed input closures;
label reused complete evidence as composed rather than pretending simultaneous
execution. Keep private receipts and host paths outside Git.
