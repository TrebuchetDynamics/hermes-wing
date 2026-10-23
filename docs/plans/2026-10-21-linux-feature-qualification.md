# Full-feature Linux qualification campaign

Status: planned; user-requested Linux testing scope, not permission to execute it.
Source baseline: `75f4057ceb1fc4b3808573ff50e6c728683a41e9`.

## Request and boundaries

User request, verbatim: “linux app fuññ testing of all features”. The planner
interprets this as testing every current Linux app surface and explicitly accounting
for unsupported/partial features—not implementing every missing Desktop feature.
The user explicitly chose the current `tasks/` work store for this plan.

Goal: a source-bound Linux report with complete feature/route coverage, discriminating
positive/negative/recovery checks, and honest native, live and hardware limits.
Non-goals: Agent changes, new product capabilities, other-platform qualification,
service restarts, personal credential discovery, publication or timed scheduling.
Anti-goals: claiming full Linux support from widgets/browser/Xvfb alone; counting
skips as passes; using a fixture token against a real host; silently dropping a
failed late suite; or calling missing-contract operations tested positively.
This occurrence saves docs/tasks only. All test/build/launch commands below are
planned and **UNRUN in this planning pass**.

## Evidence and planner decisions

- [Routes](../product/routes.md), [live route constants](../../lib/router/routes/app_routes.dart),
  router providers and public controls define the current surface, including nested
  Settings voice/diagnostics, Add Hermes, enrollment, local setup and legacy redirects.
- [The 50-family inventory](../product/hermes-desktop-feature-matrix.json) is an ID
  baseline, not a fresh runtime verdict. Its descriptions predate current Bot Chat
  and tab work. Current routes/code and [Bot Chat](../quality/android-canonical-bot-chat.md),
  [workspace](../quality/chat-session-workspace.md), [paged JSON](../quality/paged-session-json-export.md)
  and [local slash/timestamps](../quality/slash-catalog-contract.md) govern those subsets.
  Do not rewrite the pinned matrix or advance its runtime cells merely to match a plan.
- [The native regression adapter](../../integration_test/linux_feature_regression_test.dart)
  imports 83 local suites, but mocks storage/input and omits newer Bot Chat suites.
  [The broad launcher](../../scripts/run_linux_e2e.sh) runs only its listed targets;
  neither is a complete current inventory by itself.
- The inspected host exposes GTK, Xvfb and D-Bus tools, but its current pkg-config
  context lacks libsecret/GStreamer metadata. Node on PATH is 26.7.0; `/usr/bin/node`
  is 18.19.1, not the supported Node 22. This is a preflight observation, not proof
  that compatible private dependency bundles are absent everywhere.
- Several reusable launchers depend on a historical extracted prefix or Git helper
  objects. Some inherit broad environment dictionaries. The first task makes these
  inputs explicit and fail-closed, using current source, not stale copied app code.

**Planner's call:** choose layered, isolated qualification: shared regressions,
synthetic GTK, real isolated plugins/OS-injected input, then separately admitted
live-Agent, physical/audio/accessibility and packaged-artifact observations. Reuse
existing runners; add only missing current-feature scenarios and a small allowlisted
campaign driver. Do not build a second test framework or blanket live launcher.
A unit-only plan was rejected because it misses GTK/plugin behavior; a live-everything
first pass was rejected because several contracts are absent and real mutations,
provider costs, credentials and personal state are not authorized.

## Execution contract and receipt seam

All tasks retain Agent authority, exact owner/generation fences, no mutation replay,
secret-safe custody, capability denial, cancellation and accessible alternatives.
Use Flutter 3.44.2, Dart matching that SDK, Python 3.11+ and Node 22 when needed.
Resolve dependencies in the owned checkout without lockfile changes. A compatible
private development prefix may be reused only after validating its inputs; missing
packages/privileged installation remain explicit prerequisites, never fabricated
receipts or permission to alter the host. Never modify a shared SDK or Agent.

The proposed driver is `scripts/run_linux_feature_qualification.py`. This file
**does not exist yet**. It has fixed lanes `preflight`, `shared`, `connections`,
`chat`, `management`, `access`, `report`; no arbitrary command/target/live mode.
Task 1 owns the complete fixed registration, including these exact future targets:
`connections` → `integration_test/linux_connection_feature_qualification_test.dart`;
`chat` → `integration_test/linux_chat_feature_qualification_test.dart`;
`management` → `integration_test/linux_management_feature_qualification_test.dart`;
`access` → `integration_test/linux_access_feature_qualification_test.dart`.
`shared` includes the existing regression adapter and task 2's inventory check;
`report` delegates to task 7's proposed checker. A missing late target blocks only
that selected runtime lane; preflight and mocked driver tests do not require the
later files. The driver sets an owned `WING_LINUX_TEST_ROOT`; new GTK targets
atomically publish `feature-cases.json` there using the schema-1 case fields below.
The driver collects that file and the existing runners' validated receipts into
its lane receipt. Tasks 3–6 own their listed Dart targets/fixtures, not driver
registration; task 7 verifies each target was actually dispatched and recorded.
Preflight never launches GTK, SSH, provider calls or installers. Its exit 0 means
inspection completed; JSON `ready: false` with exact missing inputs is not native
qualification and does not permit a runtime lane. A runtime lane with `ready: false`
exits nonzero before spawning a child. This lets the offline driver tests complete
without pretending this host's missing native prerequisites are available.
Execution requires
an explicit lane, an owned output directory and a reviewed disposable dependency
prefix. It uses an allowlisted environment, isolated HOME/XDG/D-Bus/display and
synthetic fixture identities. It must fail before launch on missing/stale inputs,
inherited live opt-ins or unsafe output roots. Preserve exact subprocess exit status,
source/tool/dependency fingerprints and logs; partial runs stay incomplete.

Produces: each lane writes `<output-dir>/campaign.json` and
`<output-dir>/<lane>.json`, prints their paths and digests for the existing private
task execution report, and keeps logs under `<output-dir>/logs/`. No public task
record or committed report contains private paths. The report task resolves these
artifacts from the existing attempt reports; if missing or input-stale, it can
rerun the same fixed fixture lane itself on the final source, not wait for a
coordinator handoff or synthesize rows.

Private JSON receipts have `schema=1`, campaign source/tree and toolchain,
lane, unique case IDs, feature/route IDs, backend/input/storage kind, command/exit,
status (`pass`, `fail`, `not_run`, `unsupported`, `coverage_gap`), skip reason,
artifact/log digest and owned-process cleanup. Native rows also identify the GTK
PID and exact owner/operation counts. Unsupported rows require a passing negative
assertion; they never become positive feature support. Plain source inspection is
not a runtime row. No transcripts, secrets, private endpoints or host paths ship.
Consumes: the final checker reads those same schema-1 records; missing, duplicate,
stale-source, empty/no-terminal or boolean-as-number records fail validation. It
reports fixture completeness separately from overall Linux qualification.

Task write sets are disjoint after the driver lands. Source checks may run independently;
heavy GTK builds must serialize per build tree and respect existing host/SDK locks.
Use owned displays/ports and separate state, not a generic repository-wide exclusive
reservation. Scheduling overlap is not a product dependency. Do not run duplicate
copies of the shared full suite or invalidate prior matching receipts just for freshness.

## Planned command lanes

The new driver and future focused test files are proposed commands, not existing
interfaces. Existing candidates below were source-inspected, not executed here.

- **Shared:** `flutter pub get --offline --enforce-lockfile && flutter test --no-pub --concurrency=1`;
  changed-file format, `flutter analyze --no-pub`, a deterministic web build and
  `npm run web:e2e` under Node 22. Web is a regression guard, not native Linux proof.
  Also run the updated Linux native regression adapter under owned Xvfb; preserve
  explicit mocked-preference/storage/text-input limits.
- **Connections/plugins:** reviewed current first-run/welcome/auth/retry/saved-edit,
  feedback/two-host wrappers; `run_linux_persistence_e2e.sh`,
  `run_linux_native_input_e2e.sh`, `run_linux_secure_storage_regression.sh`,
  `run_linux_saved_endpoint_storage.sh`; managed SSH fixture requires the deliberate
  `bash scripts/run_managed_ssh_key_native.sh --lane linux --run` variant and an
  asyncssh-capable QA Python. Without `--run` it is preparation only. This fixture
  is not a real-host/private-key/chooser qualification.
- **Chat:** existing Python local-serve reads/chat/restoration and workspace
  overlay/stream runners, Stop/transcript/integrated-restart/no-inference wrappers;
  supplement current Bot Chat, API tab ownership, follow-up FIFO, local slash and
  timestamps, and paged JSON controls. Native serve attachments/tabs and missing
  clarify/send-receipt contracts retain explicit negative/unsupported checks.
- **Management:** native Persona conflict plus public Profiles/Providers/Tools/
  Schedules/Settings/Diagnostics cases over production channels with synthetic
  advertised/absent/denied contracts. Real keys/accounts/admin operations are not used.
- **Access:** shell/footer/keyboard/compact-return and status-accessibility runners,
  real isolated clipboard/file-picker paths, and negative/teardown voice cases.
  Framework key/resize injection is labeled as such; Xvfb/OS-injected input is not
  a physical keyboard, Wayland, real IME, screen reader or audio-acoustic test.

Do not invoke `run_linux_live_e2e.sh`, `run_linux_live_features_e2e.sh` or
`run_linux_live_visual.sh` by default. “No inference” is not “read-only”: the
existing live feature journey creates 51 sessions and later renames/deletes them.
The desktop live-workflow wrapper's default/native-read-only mode is bounded
capability inspection, not the complete workflow. The retired live-security
wrapper must stay retired. Release-build helpers may download dependencies and
remove build output; they are not a harmless preflight command.

## Complete feature disposition

Every listed family needs its current offered positive subset, missing/denied
capability behavior, cancellation/owner replacement and relevant failure/recovery
case. For absent products, test absence/generic recovery and retain the positive
parity gap. The final inventory also joins every composed route/alias, public
menu/overflow action, file/clipboard output and current feature supplement; a
50-row match alone cannot prove that all app actions were exercised.

| Feature | Outcome family | Fixture owner | Current result |
| --- | --- | --- | --- |
| HD-ENTRY | First-run connection choice and failure recovery | `LINUXQA-001-8163f50f` | Planned; NOT_CHECKED |
| HD-LOCAL | Local runtime discovery, bootstrap and launch | `LINUXQA-001-8163f50f` | Planned; NOT_CHECKED |
| HD-REMOTE | Explicit remote URL/token connection test | `LINUXQA-001-8163f50f` | Planned; NOT_CHECKED |
| HD-OAUTH | Remote OAuth sign-in/out and draft identity | `LINUXQA-001-800e359b` | Planned; NOT_CHECKED |
| HD-SSH | SSH connection configuration and trust | `LINUXQA-001-8163f50f` | Planned; NOT_CHECKED |
| HD-HOSTS | Saved connections and source switching | `LINUXQA-001-8163f50f` | Planned; NOT_CHECKED |
| HD-SHELL | Chat home, workspace destinations and overlays | `LINUXQA-001-cbe0b043` | Planned; NOT_CHECKED |
| HD-TABS | Concurrent panes, session/window ownership and close | `LINUXQA-001-c7841f6e` | Planned; NOT_CHECKED |
| HD-PROFILE | Profiles, Agents and scoped persona configuration | `LINUXQA-001-800e359b` | Planned; NOT_CHECKED |
| HD-PROJECT | Projects, folders and worktrees | `LINUXQA-001-800e359b` | Planned; NOT_CHECKED |
| HD-PROVIDER | Provider accounts, keys, endpoints and local model setup | `LINUXQA-001-800e359b` | Planned; NOT_CHECKED |
| HD-MODEL | Session models, defaults, reasoning and auxiliary configuration | `LINUXQA-001-800e359b` | Planned; NOT_CHECKED |
| HD-CHAT | Deliberate send, streaming and transcript/tools | `LINUXQA-001-c7841f6e` | Planned; NOT_CHECKED |
| HD-APPROVAL | Correlated approvals and expired input | `LINUXQA-001-c7841f6e` | Planned; NOT_CHECKED |
| HD-STOP | Stop presentation and backend interruption | `LINUXQA-001-c7841f6e` | Planned; NOT_CHECKED |
| HD-CLARIFY | Live clarification questions and locked answers | `LINUXQA-001-c7841f6e` | Planned; NOT_CHECKED |
| HD-QUEUE | Queued follow-ups and explicit drain ownership | `LINUXQA-001-c7841f6e` | Planned; NOT_CHECKED |
| HD-DRAFT | Composer scope, attachments and rejected submission restore | `LINUXQA-001-c7841f6e` | Planned; NOT_CHECKED |
| HD-SEARCH | Session inventory, search, management and Command Center | `LINUXQA-001-c7841f6e` | Planned; NOT_CHECKED |
| HD-RESUME | Exact identity restore, replay and reconnect | `LINUXQA-001-c7841f6e` | Planned; NOT_CHECKED |
| HD-ATTACH | Composer attachments and upload ownership | `LINUXQA-001-c7841f6e` | Planned; NOT_CHECKED |
| HD-EXPORT | Transcript export and format boundaries | `LINUXQA-001-c7841f6e` | Planned; NOT_CHECKED |
| HD-VOICE | Draft dictation, voice conversation and playback | `LINUXQA-001-cbe0b043` | Planned; NOT_CHECKED |
| HD-COMMAND | Curated slash discovery and dispatch | `LINUXQA-001-c7841f6e` | Planned; NOT_CHECKED |
| HD-SKILLS | Capabilities: skills, learning and discovery | `LINUXQA-001-800e359b` | Planned; NOT_CHECKED |
| HD-MCP | Capabilities: connectors, MCP and toolset configuration | `LINUXQA-001-800e359b` | Planned; NOT_CHECKED |
| HD-MEMORY | Memory, context engine and provider configuration | `LINUXQA-001-800e359b` | Planned; NOT_CHECKED |
| HD-SCHEDULE | Cron routines, blueprints, delivery and run history | `LINUXQA-001-800e359b` | Planned; NOT_CHECKED |
| HD-KANBAN | Optional contributed Kanban planning | `LINUXQA-001-800e359b` | Planned; NOT_CHECKED |
| HD-GATEWAY | Messaging, gateway setup, pairing and Webhooks | `LINUXQA-001-800e359b` | Planned; NOT_CHECKED |
| HD-ARTIFACTS | Artifacts destination across session outputs | `LINUXQA-001-800e359b` | Planned; NOT_CHECKED |
| HD-PREVIEW | Preview/browser, files and working panes | `LINUXQA-001-800e359b` | Planned; NOT_CHECKED |
| HD-TERMINAL | Persistent terminal and native git review | `LINUXQA-001-800e359b` | Planned; NOT_CHECKED |
| HD-BOTS | Canonical Bot Chat and bot roster | `LINUXQA-001-c7841f6e` | Planned; NOT_CHECKED |
| HD-CLOUD | Hermes Cloud connection topology | `LINUXQA-001-800e359b` | Planned; NOT_CHECKED |
| HD-ACCOUNT | Nous free-tier status, sign-in and billing | `LINUXQA-001-800e359b` | Planned; NOT_CHECKED |
| HD-SETTINGS | Settings navigation, schema fields and presentation | `LINUXQA-001-800e359b` | Planned; NOT_CHECKED |
| HD-DIAG | Diagnostics, logs and recovery | `LINUXQA-001-800e359b` | Planned; NOT_CHECKED |
| HD-UPDATE | Artifact-owned install/update and uninstall | `LINUXQA-001-cbe0b043` | Planned; NOT_CHECKED |
| HD-NATIVE | Window, keyboard, HUD, tray and native integration | `LINUXQA-001-cbe0b043` | Planned; NOT_CHECKED |
| HD-ACCESS | Accessible keyboard/focus/motion equivalents | `LINUXQA-001-cbe0b043` | Planned; NOT_CHECKED |
| HD-IMPORT | Session import overlay | `LINUXQA-001-800e359b` | Planned; NOT_CHECKED |
| HD-STARMAP | Starmap learning/history visualization | `LINUXQA-001-800e359b` | Planned; NOT_CHECKED |
| HD-GUIDE | Guided setup conversation and loading handoff | `LINUXQA-001-800e359b` | Planned; NOT_CHECKED |
| HD-PLUGINS | Bundled contributions and runtime plugin loading | `LINUXQA-001-800e359b` | Planned; NOT_CHECKED |
| HD-RADIO | Optional Radio station search, pinning and explicit playback | `LINUXQA-001-800e359b` | Planned; NOT_CHECKED |
| HD-VAULT | Agent credential vault sources, locked state and item management | `LINUXQA-001-800e359b` | Planned; NOT_CHECKED |
| HD-PLUGIN-PACKAGES | Catalog and Git plugin packages with separate Agent/Desktop halves and scoped settings | `LINUXQA-001-800e359b` | Planned; NOT_CHECKED |
| HD-SCREEN | Bot computer Screen observe/control with per-viewer lease and explicit clipboard | `LINUXQA-001-800e359b` | Planned; NOT_CHECKED |
| HD-PETS | Generate, hatch, preview, adopt or discard an Agent pet | `LINUXQA-001-800e359b` | Planned; NOT_CHECKED |

## Live and intended-platform gates — reuse, do not duplicate

These existing tasks retain their original statuses, ranks, acceptance and authority.
No live credential, host, profile, spend limit or disposable installer target was
provided. Record those missing inputs only on the affected live cells; do not block
independent fixture work or ask the owner to implement missing contracts.

- `PARITY-NATIVE-LINUX-LIVE`: aggregate Linux real-Agent/SSH/OAuth, physical audio,
  Wayland/IME/screen-reader and actual platform custody gaps. Linux evidence alone
  does not complete any original mixed-platform criterion.
- `PARITY-LIVE-WORKFLOW-LIVE` and `PARITYUPDATE-002-5c-LIVE`: actual generation,
  correlated approval, authoritative Stop/terminal recovery and canonical readback;
  absent admission/correlation/clarification contracts cannot be created by permission.
- `BACKEND-SSH-KEY-NATIVE-LIVE`, `DOC-NATIVE-FAILURE-BOUNDARY-LIVE` and
  `DOC-NATIVE-DESIGN-REVIEW-LIVE`: real SSH identity/authentication, chooser/modal/
  latency/cancellation and custody behavior. Fixture substitutes remain separate.
- `VERIFY-PERSONA-LIVE-COMPATIBILITY`: disposable deployed SOUL revision/conflict saves.
- `PARITYGAP-002-76-LIVE`: actual GTK destination/overwrite/readback plus live projected
  history. Fixture additions contribute evidence but do not waive this acceptance.
- `VERIFY-SHELL-NATIVE-INPUT`: public OS/physical-window input and persisted intent.
- `VERIFY-DESKTOP-NATIVE-DELIVERY`: exact-artifact install/upgrade/retained keyring,
  client-only removal and authorized failure/rollback on a disposable Linux target.
- Other contract-specific live tasks remain their owning goal's gates; unsupported
  OAuth, Project, vault, package, Screen, Radio, import, Pets and missing administrative
  operations are not silently enabled to fill a test matrix.

## Batch, failure guards and completion

1. `LINUXQA-001-e41e98e5` — safe/portable campaign driver and preflight; first executable slice.
2. `LINUXQA-001-dbb6605f` — current-source shared regression and native adapter completeness.
3. `LINUXQA-001-8163f50f` — native connections, isolated plugin/storage and SSH-fixture lane.
4. `LINUXQA-001-c7841f6e` — native Chat/session/Bot Chat/draft/queue/export lane.
5. `LINUXQA-001-800e359b` — native management/settings and unsupported-capability lane.
6. `LINUXQA-001-cbe0b043` — native access, lifecycle/voice-negative and platform-boundary lane.
7. `LINUXQA-001-c232368b` — complete evidence join, residual gates and truthful Linux verdict.

Tasks 2–6 consume task 1's driver/receipt schema and remain independent of each
other; the final report consumes all five results. Existing live tasks are **not**
prerequisites of offline reporting. This is a complete single planning batch, not a
rolling expansion or automatic execution chain. Future reproduced product defects
stay explicit failed cells and go to their owning task/goal; do not expand these
test tasks into arbitrary feature implementation or turn a failed test into a skip.

Pre-mortem: (1) inherited credentials trigger real writes—preflight rejects live
environment/launchers before any child starts; (2) old mocked suites omit newer
features—exact feature/route/action join and explicit Bot Chat/timestamp/JSON cases
reject incomplete coverage; (3) a process abort or stale artifact looks green—
terminal status, source/target identity, negative validator tests and owned cleanup
are mandatory. These guards belong in the driver and final checker tests.

A fixture campaign is complete only with all planned case IDs accounted for and
no unexplained skip/abort. Overall Linux qualification remains PARTIAL while any
required live/hardware/packaged cell is not checked. Do not mark PARITY met or
upgrade the pinned feature matrix from a planning artifact or an offline report.

## Backlog connection

Goal: existing `PARITY`; no focus or priority change. Saved through the
[current work store](../tasks/work-queue.md), with the original 79 deferred tasks
and external gate order preserved. The [plan index](README.md#plan-to-task-coverage)
connects this full batch. No workers, test processes, services or schedules are
started by saving it.

## Remaining held-candidate recovery

This owner-requested planning follow-up addresses four engineering holds and the
existing Files deferral. It authorizes no implementation, test run, dispatch,
service change or timer. Original sections describe their initial planning
baseline, not current runtime results. Reuse existing task IDs and retained work;
keep all acceptance, required checks, relative priority and live boundaries.

### Reconciled evidence

`MAIN-REPAIR-003` is coordinator-verified and integrated. Main was recorded green
at `84f5d66`; a newer `eff6de9f` check was still running at inspection. Green main
does not approve separate candidates. Read the latest reports and retained rejection
records; no runtime checks were executed by this planner.

During this planning pass, `2939ea05` independently integrated
[the existing recovery handoff](../tasks/review-findings-recovery.md).
It restored package, connections and accessibility task contracts; all three
workers were then observed running. Preserve their updated checks, write sets,
recovery instructions and live ownership. Do not overwrite them with this pass's
older isolated draft or requeue them. Their started work is not completed proof.

Current `scripts/support/linux_qualification_support.py` already contains native-only
package admission, guarded by plugin attribution and manifest data. Missing arbitrary
paths, links, stale roots and containment violations must remain rejected. That
repair is no longer a reason to make accessibility wait for connections.

### Plan by existing task

- **`CHECK-PACKAGES-001` — package preparation:** the resumed task reuses
  `302444a54489ec9d539f1242c7621dd2494c0971` against repaired main. Keep its
  three-file setup/documentation boundary and current required checks. Resolve
  exact locked dependencies without SDK/lockfile changes; retain real preparation
  exits separately from the complete suite's terminal results. Warm-cache success
  is not proof of a cold download. No product-test repair or Python result wrapper.
- **`LINUXQA-001-8163f50f` — connections:** the resumed task reconciles
  `efe2347a2ca1f0c193be417136336871d7acab2a` with current code and the completed
  fixture repair. Preserve its added approval-dismissal regression and every
  exact-owner/no-replay assertion. Require its registered campaign, distinct
  plugin/storage/SSH checks and normal integrated full gate; standalone or historical
  evidence is reused only when source, tool, dependency and fixture inputs match.
- **`LINUXQA-001-cbe0b043` — accessibility:** the resumed task reuses
  `1e3adcac6e3475bd86fc9362ff6839ac80484b0e`, current package validation and repaired
  fixture ports. Require actual access-lane dispatch, compact-return persistence,
  focused access checks, SSH modules together and integrated full-gate evidence.
  Standalone GTK semantics/framework input never qualify real screen readers,
  physical audio, Wayland/IME or installation. It can proceed independently of
  package setup and connections with its already-available prerequisite inputs.
- **`LINUXQA-001-800e359b` — management:** reuse
  `34ab767e1cfc2e9390989f15b03dba7794e67b82`. The latest rejected integration
  `4a907ed8a48b5bed68a575ca16e1a744de1564d7` stopped before test results on package
  preparation at base `7603dcdd`. The worker separately reports standalone GTK and
  SSH module passes but campaign refusal before dispatch. Make package setup a
  real prerequisite, consume current native-only validation and completed
  `MAIN-REPAIR-003`, then run the exact management lane on combined source. Retain
  case/source/tool/cleanup identity and unsupported rows; standalone GTK is not
  aggregate qualification. Keep the original three-file management write boundary.
- **Files browsing/download:** keep the recorded owner deferral and original
  dependency. Reconsider only when an unmodified Agent contract supplies effective
  session/profile/backend terminal-root identity, authorization and canonical
  confinement. Permission cannot supply that contract. No shell/SFTP substitute,
  always-disabled completion claim or Agent edits.

### Order, ownership and acceptance

Planner's call: preserve the three independently resumed tasks and give management
only the evidenced package-setup dependency, plus the completed main repair.
Do not add artificial dependencies on already-landed helper fixes. The existing
`LINUXQA-001-c232368b` still joins the original qualification lanes, and a child
completion does not qualify the final report or platform.

The unintegrated `aad4a590` draft is superseded by this reconciled plan; do not
import its stale task snapshots or dependency edges. The earlier `b36ece5e` fixture
proposal also remains unintegrated history: the completed main repair now owns that
work. No duplicate task is needed.

All original acceptance and checks remain mandatory. Revalidate named failures on
the actual integrated candidate, retaining exact exits, skips, remaining failures
and owned teardown. Unknown or incomplete results stay unqualified. Preserve
credential, transport, containment, cancellation, approval/Stop and no-replay
invariants; trace a remaining failure before expanding scope. Do not kill unrelated
listeners, edit shared SDKs/installed runners, alter lockfiles, or discover personal
credentials. Physical/live/package gates remain separate.

No material product question remains. This plan records recovery and preserves
Files deferral; it does not clear any validation hold or claim a runtime pass.
