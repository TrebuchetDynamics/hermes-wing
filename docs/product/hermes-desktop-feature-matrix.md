# Hermes Desktop feature verification matrix

> Reference correction: [official Desktop authority](../quality/official-desktop-reference.md). Prior Desktop source citations and parity conclusions in this document are withdrawn. Wing test results remain historical behavior evidence only.


Status: current feature-group inventory with attributed retained evidence.
This update changes documentation only. No app, device or test suite ran here.
This is a feature-group matrix, not certification of a 1:1 port or an exhaustive
list of every control. Expand each group into operation-level assertions before
claiming complete coverage. [PRD](prd.md) owns intent and
[the parity ledger](hermes-desktop-parity.md) owns current product differences.

## Reference and result rules

Reference checkout: `withdrawn reference revision`.
The [historical feature study](hermes-desktop-feature-study.md) uses older pins.
Its details are leads, not proof of this checkout or current Wing support.
Source paths below identify reference feature locations. They do not establish
connected-Agent authority. Inspect nearest implementation/tests before porting.

The [machine-readable matrix](hermes-desktop-feature-matrix.json) owns row IDs and
candidate mappings. The current Wing scope is an inventory assessment, not a
fresh execution verdict. `partial` includes implemented subsets with missing
behavior or qualification. `unsupported` identifies an absent managed surface or
contract. `unverified` requires source/runtime clarification. `wing-specific`
identifies additional trust/enrollment behavior, not a Desktop feature match.

Android flow paths are **candidates**, not full coverage declarations. Helper
flows and unsupported-state assertions cannot prove the corresponding positive
feature. Linux case hints identify existing native Flutter counterparts. They
are not Maestro YAML execution and do not guarantee every row's operations.
Android/native Linux cells below retain **not_run** from the original
syntax/preflight pass. They are not fresh environment probes. Later native
install/launch attempts do not prove rendered Maestro interaction. See
[BLOCKERS](../../BLOCKERS.md) for the separate target-access record.
Historical receipts remain separately attributed. The later
[approval/attachment fixture slice](../quality/android-approval-attachment-fixture.md)
repairs HD-APPROVAL, HD-STOP, HD-RESUME and HD-ATTACH candidate controls. Seven
Flutter widget passes do not change the Android cells: startup failed before launch,
and every Android assertion remains NOT_CHECKED. Earlier-history pagination and
other mapped feature journeys remain separate coverage gaps.

## Platform drivers

- **Android:** actual Maestro CLI against a named disposable QA installation.
- **Native Linux desktop:** existing Flutter integration tests on an owned display.
  Maestro's supported platforms do not list native GTK/Linux desktop apps.
- **Linux-hosted Chromium:** Maestro web is beta and may test Flutter web semantics.
  This is web qualification, not native desktop qualification. No Maestro-web
  Wing flow ran here. Keep existing Playwright journeys as a separate evidence lane.

Sources: [Maestro supported platforms](https://docs.maestro.dev/get-started/supported-platform)
and [web support](https://docs.maestro.dev/get-started/supported-platform/web-browser).
Linux as a host OS is not the same as a supported native-app target.

## Current product matrix

The following subsets use the operation-scoped [routes](routes.md) and parity
ledger, with direct source/test inspection for linked newer slices. A receipt
link records another executor's checks and their source/platform limits. It is
not a fresh passing check on the present dirty worktree. Full parity remains
partial even when a narrow implementation slice is done.

Inventory: **46 groups** — 35 partial, 8 unsupported, 1 unverified, 2 wing-specific. These are not a completion percentage.

| ID / Desktop outcome | Reference | Wing scope and current subset | Remaining parity gap | Evidence / goal |
| --- | --- | --- | --- | --- |
| HD-ENTRY — Welcome and three connection paths | [source](../quality/official-desktop-reference.md#withdrawn-evidence) | **partial**: Exact Local/SSH/Remote primary labels, nested HTTPS/VPN and owner-safe cancel/back. | Native bootstrap and managed SSH/OAuth remain separate gaps. | [connection-entry-labels](../quality/connection-entry-labels.md)<br>Goal: `CONNECTION-PATHS` |
| HD-LOCAL — Local detect/adopt/install/update | [source](../quality/official-desktop-reference.md#withdrawn-evidence) | **partial**: Platform local-setup route and readiness guidance. | Full Desktop detect/adopt/install/update lifecycle is not qualified on all targets. | [route/parity inventory](routes.md)<br>Goal: `M3` |
| HD-REMOTE — Remote token connection and readiness | [source](../quality/official-desktop-reference.md#withdrawn-evidence) | **partial**: Direct authenticated Agent endpoint and independent management enrollment. | Desktop browser OAuth and full remote recovery need separate exact contracts/evidence. | [route/parity inventory](routes.md)<br>Goal: `CONNECTION-PATHS` |
| HD-OAUTH — Remote dashboard OAuth sign-in/out | [source](../quality/official-desktop-reference.md#withdrawn-evidence) | **unsupported**: No qualified Desktop remote dashboard OAuth flow. | Advertised OAuth acquisition, callback, logout and secure credential lifecycle. | [route/parity inventory](routes.md)<br>Goal: `ACCOUNT` |
| HD-SSH — Managed SSH trust/forward/reconnect | [source](../quality/official-desktop-reference.md#withdrawn-evidence) | **unsupported**: Externally created SSH tunnel with explicit local Agent URL instructions. | Managed host trust, authentication, forwarding, cancellation and reconnect. | [route/parity inventory](routes.md)<br>Goal: `REMOTE-BACKENDS` |
| HD-BACKENDS — Docker and WSL lifecycle | [source](../quality/official-desktop-reference.md#withdrawn-evidence) | **unsupported**: No managed Docker/WSL surface. | Reviewed fixed lifecycle operations and matching native execution. | [route/parity inventory](routes.md)<br>Goal: `REMOTE-BACKENDS` |
| HD-HOSTS — Saved connection name/edit/test/remove | [source](../quality/official-desktop-reference.md#withdrawn-evidence) | **partial**: Connections inventory, edit/remove and explicit Agent connect/disconnect. | Desktop saved-workflow fidelity and per-host conversation ownership qualification. | [route/parity inventory](routes.md)<br>Goal: `CONNECTION-PATHS` |
| HD-PAIR — Pairing expiry/refusal/trust recovery | [source](../quality/official-desktop-reference.md#withdrawn-evidence) | **wing-specific**: Wing Link enrollment and pairing recovery. | Wing extension, not a substitute for the three Desktop connection paths. | [route/parity inventory](routes.md)<br>Goal: `M3` |
| HD-TRUST — Separate Agent and management trust/revocation | [source](../quality/official-desktop-reference.md#withdrawn-evidence) | **wing-specific**: Independent Agent and Wing Link credentials and own-device revocation. | Wing extension; exact trust failures and physical-device qualification remain separate. | [route/parity inventory](routes.md)<br>Goal: `SECURITY` |
| HD-SHELL — Sidebar grouping/collapse/profile footer/recents | [source](../quality/official-desktop-reference.md#withdrawn-evidence) | **partial**: Adaptive sidebar, passive profile footer, source-grouped loaded recents and global Sessions modal. | Project/folder recents differ from source grouping. Footer model/group controls, relaunch persistence and complete shell fidelity remain gaps. | [profile-footer-implementation](../quality/profile-footer-implementation.md)<br>[grouped-recents-implementation](../quality/grouped-recents-implementation.md)<br>[global-session-modal](../quality/global-session-modal.md)<br>Goal: `PARITY-COMPOSITION` |
| HD-TABS — Concurrent chat tabs and close/Stop ownership | [source](../quality/official-desktop-reference.md#withdrawn-evidence) | **unsupported**: No owner-safe Desktop multi-conversation tab bar. | Concurrent owner-bound tabs, close/Stop and reconnect behavior. | [route/parity inventory](routes.md)<br>Goal: `PARITY-TABS` |
| HD-PROFILE — Profile lifecycle and switching | [source](../quality/official-desktop-reference.md#withdrawn-evidence) | **partial**: Scoped profile inventory/lifecycle and transactional new-profile setup. | Complete Desktop profile editing/switching plus native/live qualification. | [route/parity inventory](routes.md)<br>Goal: `M3` |
| HD-PROJECT — Project/repository assignment and scoped Chat | [source](../quality/official-desktop-reference.md#withdrawn-evidence) | **unsupported**: Approved opaque child-folder browsing; no qualified Project-aware Chat. | Authoritative Project creation/selection and workspace-scoped conversations. Persona directory flow is not Project coverage. | [route/parity inventory](routes.md)<br>Goal: `M3-PROJECT` |
| HD-PROVIDER — Provider credential CRUD/validation | [source](../quality/official-desktop-reference.md#withdrawn-evidence) | **partial**: Capability-gated inventory, secret-safe key CRUD/validation and model operations. | OAuth, multi-credential pools and full provider parity; unavailable mutations stay hidden. | [route/parity inventory](routes.md)<br>Goal: `M3-PROVIDER` |
| HD-MODEL — Exact session provider/model selection/restoration | [source](../quality/official-desktop-reference.md#withdrawn-evidence) | **partial**: Exact provider/model picker and session-bound selection surfaces. | Full live daily workflow, exact relaunch restoration and all provider-catalog edge cases. | [route/parity inventory](routes.md)<br>Goal: `M1` |
| HD-REASON — Reasoning effort and context budget | [source](../quality/official-desktop-reference.md#withdrawn-evidence) | **partial**: Existing reasoning-effort/model controls where advertised. | Complete reference effort/context-budget behavior. Thinking/Thought disclosure is tracked under HD-CHAT, not proof of effort controls. | [route/parity inventory](routes.md)<br>Goal: `CHAT-FIDELITY` |
| HD-CHAT — Send/stream/Markdown/code/tool transcript | [source](../quality/official-desktop-reference.md#withdrawn-evidence) | **partial**: Streaming transcript, Markdown/code/tool rendering and keyboard Thinking/Thought disclosure. | Full reference transcript/composer fidelity, transport qualification and live generation. | [reasoning-disclosure-implementation](../quality/reasoning-disclosure-implementation.md)<br>Goal: `M1` |
| HD-APPROVAL — Approve once/session/deny and stale correlation | [source](../quality/official-desktop-reference.md#withdrawn-evidence) | **partial**: Correlated gated approval controls and stale-owner settlement handling. | Actual live-provider/native approval recovery and every reference interaction. | [route/parity inventory](routes.md)<br>Goal: `M1` |
| HD-STOP — Authoritative Stop and post-Stop recovery | [source](../quality/official-desktop-reference.md#withdrawn-evidence) | **partial**: Explicit run Stop and uncertain/terminal reconciliation states. | Authoritative live terminal outcome and post-disconnect/relaunch qualification. Local stream teardown is not Stop. | [route/parity inventory](routes.md)<br>Goal: `M1` |
| HD-CLARIFY — Agent questions and user answer protocol | [source](../quality/official-desktop-reference.md#withdrawn-evidence) | **unverified**: Human-request contract and complete Desktop question interaction not requalified here. | Inspect exact operation/correlation and add matching end-to-end response coverage. | [route/parity inventory](routes.md)<br>Goal: `CHAT-FIDELITY` |
| HD-QUEUE — Queued messages/edit/remove/cancel ownership | [source](../quality/official-desktop-reference.md#withdrawn-evidence) | **partial**: Explicit follow-up draft/queue behavior in the existing composer. | Desktop queued-message placement, editing/removal and owner-safe recovery. | [route/parity inventory](routes.md)<br>Goal: `CHAT-FIDELITY` |
| HD-DRAFT — Draft isolation across session/host changes | [source](../quality/official-desktop-reference.md#withdrawn-evidence) | **partial**: Volatile owner-scoped composer drafts and invalidation across selection/recovery. | Cross-host/navigation/relaunch persistence and complete reference draft semantics. | [route/parity inventory](routes.md)<br>Goal: `M2` |
| HD-SEARCH — Session pagination/search/filter metadata | [source](../quality/official-desktop-reference.md#withdrawn-evidence) | **partial**: Loaded metadata/preview filtering, explicit pagination and exact-owner activation. | Not full server transcript search. Native/live session search remains unqualified. | [session-search-resume-journey](../quality/session-search-resume-journey.md)<br>Goal: `SESSIONS` |
| HD-RESUME — Exact session resume/history/reconnect/relaunch | [source](../quality/official-desktop-reference.md#withdrawn-evidence) | **partial**: Explicit authoritative reopen with stale history rejection. | Automatic exact-session relaunch and detached-run/live recovery are different outcomes. | [session-search-resume-journey](../quality/session-search-resume-journey.md)<br>Goal: `M1` |
| HD-FORK — Session branch and rename | [source](../quality/official-desktop-reference.md#withdrawn-evidence) | **partial**: Confirmed owner-bound fork, server-returned child history and gated rename. | Live/native qualification, all branch metadata and automatic child relaunch restoration. | [session-fork-journey](../quality/session-fork-journey.md)<br>Goal: `SESSIONS` |
| HD-DELETE — Single/bulk session delete with cancel/counts | [source](../quality/official-desktop-reference.md#withdrawn-evidence) | **partial**: Scoped single/bulk deletion with confirmation and stale-owner guards. | Reference management fidelity and authoritative live/native mutation readback. | [route/parity inventory](routes.md)<br>Goal: `SESSIONS` |
| HD-PINS — Session pin/group/filter persistence | [source](../quality/official-desktop-reference.md#withdrawn-evidence) | **partial**: Loaded-row pins/contact scope, filtering and source grouping. | Reference Project/folder groups and process-relaunch persistence. | [route/parity inventory](routes.md)<br>Goal: `SESSIONS` |
| HD-ATTACH — Attachments/media and picker owner races | [source](../quality/official-desktop-reference.md#withdrawn-evidence) | **partial**: Text/image attachments and owner-safe picker/upload handling. | All Desktop media/file types, native pickers and exact artifact access boundaries. | [route/parity inventory](routes.md)<br>Goal: `ARTIFACTS` |
| HD-PREVIEW — Web preview/file viewer/artifact access | [source](../quality/official-desktop-reference.md#withdrawn-evidence) | **partial**: Bounded transcript media; no full reference web/file preview qualification. | Advertised preview/artifact access and native/browser isolation. | [route/parity inventory](routes.md)<br>Goal: `ARTIFACTS` |
| HD-EXPORT — Copy/save/share text and Markdown transcript | [source](../quality/official-desktop-reference.md#withdrawn-evidence) | **partial**: Text/Markdown transcript copy/save/share surfaces. | Native clipboard/export dialogs, permissions and all reference formatting. | [route/parity inventory](routes.md)<br>Goal: `M5` |
| HD-VOICE — Capture/language/speech/cancel/permission failure | [source](../quality/official-desktop-reference.md#withdrawn-evidence) | **partial**: Wide draft dictation, compact menu, language/settings and separate hands-free controls. | Physical/native audio is unqualified. Cancel discards recognition rather than Desktop finalize-on-stop. | [chat-direct-dictation](../quality/chat-direct-dictation.md)<br>Goal: `VOICE` |
| HD-COMMAND — Full slash command catalog/completion | [source](../quality/official-desktop-reference.md#withdrawn-evidence) | **partial**: Supported composer slash commands and explicit completion. | Full advertised command catalog and reference completion/argument behavior. | [route/parity inventory](routes.md)<br>Goal: `SLASH-CATALOG` |
| HD-SOUL — Standalone and profile persona editor/revision conflicts | [source](../quality/official-desktop-reference.md#withdrawn-evidence) | **partial**: Exact-scoped revision-aware profile persona editor and recovery. | Full reference persona behavior and live/native conflict qualification. | [route/parity inventory](routes.md)<br>Goal: `PERSONA` |
| HD-SKILLS — Installed skills and Discover/install/uninstall | [source](../quality/official-desktop-reference.md#withdrawn-evidence) | **partial**: Searchable installed-skill metadata and resolved toolsets. | Discover/install/uninstall remain gated. Inventory tests do not prove mutation support. | [route/parity inventory](routes.md)<br>Goal: `M4-DISCOVER` |
| HD-MCP — Toolset enable/disable and MCP administration | [source](../quality/official-desktop-reference.md#withdrawn-evidence) | **partial**: Read-only toolset metadata and exact-scoped inventory refresh. | MCP administration and toolset mutations need authoritative operation contracts. | [route/parity inventory](routes.md)<br>Goal: `M4-MCP` |
| HD-MEMORY — Memory entries/profile/capacity/providers | [source](../quality/official-desktop-reference.md#withdrawn-evidence) | **unsupported**: No shipped memory route. | Entry/profile/capacity/provider UI and advertised read/write operations. | [route/parity inventory](routes.md)<br>Goal: `M4-MEMORY` |
| HD-SCHEDULE — Schedule inventory and create/edit/run/delete | [source](../quality/official-desktop-reference.md#withdrawn-evidence) | **partial**: Gateway-scoped schedule inventory and read-only refresh/filtering. | Create/edit/pause/run/delete stay hidden until exact scoped operations are advertised. | [route/parity inventory](routes.md)<br>Goal: `M4-SCHEDULES` |
| HD-KANBAN — Agent-owned cards and planning workflow | [source](../quality/official-desktop-reference.md#withdrawn-evidence) | **unsupported**: No Agent-owned planning/card board surface. | Authoritative card/Project operations and owner-bound board interactions. | [route/parity inventory](routes.md)<br>Goal: `M4-KANBAN` |
| HD-GATEWAY — Gateway health/lifecycle/messaging platform admin | [source](../quality/official-desktop-reference.md#withdrawn-evidence) | **partial**: Saved connections, bounded Agent health and own Wing Link trust/revocation. | Gateway lifecycle/logs, peer administration and messaging-platform setup. | [route/parity inventory](routes.md)<br>Goal: `M4-PLATFORMS` |
| HD-OFFICE — Office contacts/3D/representative interactions | [source](../quality/official-desktop-reference.md#withdrawn-evidence) | **partial**: Accessible 2D gateway-contact workspace with exact contact activation. | Desktop 3D, representative management and associated account interactions. | [route/parity inventory](routes.md)<br>Goal: `OFFICE` |
| HD-ACCOUNT — Account/OAuth/pools/credits/wallet | [source](../quality/official-desktop-reference.md#withdrawn-evidence) | **unsupported**: No account/OAuth/pools/credits/wallet route. | Exact external account/provider authority and secure OAuth/credential contracts. | [route/parity inventory](routes.md)<br>Goal: `ACCOUNT` |
| HD-SETTINGS — Appearance/language/voice/spellcheck/privacy | [source](../quality/official-desktop-reference.md#withdrawn-evidence) | **partial**: Appearance, spellcheck, voice, Connections link and redacted diagnostics. | Desktop Settings organization, complete preferences and platform-specific persistence. | [route/parity inventory](routes.md)<br>Goal: `PARITY` |
| HD-DIAG — Logs/config diagnosis/debug dump/backup/import | [source](../quality/official-desktop-reference.md#withdrawn-evidence) | **partial**: Bounded redacted diagnostics and local settings. | Full log/config health/fix, debug dump and atomic backup/import behavior. | [route/parity inventory](routes.md)<br>Goal: `DIAGNOSTICS-RECOVERY` |
| HD-UPDATE — Install/signed updates/rollback/uninstall | [source](../quality/official-desktop-reference.md#withdrawn-evidence) | **partial**: Existing desktop installation/build and native command surfaces. | Signed distribution/update activation, local health and rollback qualification. | [route/parity inventory](routes.md)<br>Goal: `DESKTOP-DELIVERY` |
| HD-NATIVE — Menus/window/zoom/fullscreen/shortcuts | [source](../quality/official-desktop-reference.md#withdrawn-evidence) | **partial**: Bounded native menu and settings commands. | Installed window/zoom/fullscreen/shortcut behavior on each named platform. | [route/parity inventory](routes.md)<br>Goal: `NATIVE-INTEGRATION` |
| HD-ACCESS — Keyboard/focus/large text/reduced motion/non-spatial path | [source](../quality/official-desktop-reference.md#withdrawn-evidence) | **partial**: Adaptive semantics, keyboard focus, reduced-motion and non-spatial equivalents. | Full keyboard/large-text/screen-reader qualification on actual Android and native desktop targets. | [route/parity inventory](routes.md)<br>Goal: `M5` |

## Android and native Linux qualification candidates

These are nearest candidates, not positive-operation coverage claims. A screen
tour, persona directory or inventory flow cannot prove Project creation, provider
mutation or scheduled-job execution. Unavailable-state tests remain distinct.
Current widget/browser test paths for seven newly inspected groups are also
listed in the JSON matrix. Their platform is not inferred from the host OS.

| ID | Android flow candidates | Linux native counterpart | Android / native Linux result |
| --- | --- | --- | --- |
| `HD-ENTRY` | [local_setup_accessibility.yaml](../../scripts/maestro/fixture/local_setup_accessibility.yaml) | [Flutter native suite](../../integration_test/linux_maestro_flows_test.dart): screen tour | not_run / not_run |
| `HD-LOCAL` | [computer_setup.yaml](../../scripts/maestro/fixture/computer_setup.yaml) | **gap** | not_run / not_run |
| `HD-REMOTE` | [gateway_connection.yaml](../../scripts/maestro/fixture/gateway_connection.yaml) | [Flutter native suite](../../integration_test/linux_maestro_flows_test.dart): screen tour | not_run / not_run |
| `HD-OAUTH` | **gap** | **gap** | not_run / not_run |
| `HD-SSH` | **gap** | **gap** | not_run / not_run |
| `HD-BACKENDS` | **gap** | **gap** | not_run / not_run |
| `HD-HOSTS` | [gateway_connection.yaml](../../scripts/maestro/fixture/gateway_connection.yaml) | [Flutter native suite](../../integration_test/linux_maestro_flows_test.dart): screen tour | not_run / not_run |
| `HD-PAIR` | [pairing.yaml](../../scripts/maestro/fixture/pairing.yaml) | [Flutter native suite](../../integration_test/linux_maestro_flows_test.dart): pairing invalid expired used | not_run / not_run |
| `HD-TRUST` | [gateway_trust.yaml](../../scripts/maestro/fixture/gateway_trust.yaml) | [Flutter native suite](../../integration_test/linux_maestro_flows_test.dart): device revocation | not_run / not_run |
| `HD-SHELL` | [visual_review.yaml](../../scripts/maestro/fixture/visual_review.yaml) | [Flutter native suite](../../integration_test/linux_maestro_flows_test.dart): screen tour | not_run / not_run |
| `HD-TABS` | **gap** | **gap** | not_run / not_run |
| `HD-PROFILE` | [switch_chat.yaml](../../scripts/maestro/profiles/switch_chat.yaml)<br>[create_setup_delete.yaml](../../scripts/maestro/profiles/create_setup_delete.yaml)<br>[provider_model_chat.yaml](../../scripts/maestro/profiles/provider_model_chat.yaml) | **gap** | not_run / not_run |
| `HD-PROJECT` | [soul_directories.yaml](../../scripts/maestro/fixture/soul_directories.yaml) | **gap** | not_run / not_run |
| `HD-PROVIDER` | [providers.yaml](../../scripts/maestro/fixture/providers.yaml) | [Flutter native suite](../../integration_test/linux_maestro_flows_test.dart): provider mutations | not_run / not_run |
| `HD-MODEL` | [switch_chat.yaml](../../scripts/maestro/profiles/switch_chat.yaml)<br>[create_setup_delete.yaml](../../scripts/maestro/profiles/create_setup_delete.yaml)<br>[provider_model_chat.yaml](../../scripts/maestro/profiles/provider_model_chat.yaml) | **gap** | not_run / not_run |
| `HD-REASON` | **gap** | **gap** | not_run / not_run |
| `HD-CHAT` | [approvals_recovery.yaml](../../scripts/maestro/fixture/approvals_recovery.yaml) | [Flutter native suite](../../integration_test/linux_maestro_flows_test.dart): screen tour | not_run / not_run |
| `HD-APPROVAL` | [approvals_recovery.yaml](../../scripts/maestro/fixture/approvals_recovery.yaml) | **gap** | not_run / not_run |
| `HD-STOP` | [approvals_recovery.yaml](../../scripts/maestro/fixture/approvals_recovery.yaml) | **gap** | not_run / not_run |
| `HD-CLARIFY` | **gap** | **gap** | not_run / not_run |
| `HD-QUEUE` | **gap** | **gap** | not_run / not_run |
| `HD-DRAFT` | [draft_isolation.yaml](../../scripts/maestro/fixture/draft_isolation.yaml) | [Flutter native suite](../../integration_test/linux_maestro_flows_test.dart): draft ownership | not_run / not_run |
| `HD-SEARCH` | [sessions.yaml](../../scripts/maestro/fixture/sessions.yaml) | [Flutter native suite](../../integration_test/linux_maestro_flows_test.dart): session pagination | not_run / not_run |
| `HD-RESUME` | [approvals_recovery.yaml](../../scripts/maestro/fixture/approvals_recovery.yaml) | **gap** | not_run / not_run |
| `HD-FORK` | [session_branch_qa.yaml](../../scripts/maestro/session_branch_qa.yaml)<br>[session_metadata_qa.yaml](../../scripts/maestro/session_metadata_qa.yaml) | **gap** | not_run / not_run |
| `HD-DELETE` | [sessions.yaml](../../scripts/maestro/fixture/sessions.yaml) | [Flutter native suite](../../integration_test/linux_maestro_flows_test.dart): session pagination | not_run / not_run |
| `HD-PINS` | [chat_groups.yaml](../../scripts/maestro/fixture/chat_groups.yaml) | [Flutter native suite](../../integration_test/linux_maestro_flows_test.dart): session pagination | not_run / not_run |
| `HD-ATTACH` | [attachment_picker_race.yaml](../../scripts/maestro/fixture/attachment_picker_race.yaml) | [Flutter native suite](../../integration_test/linux_maestro_flows_test.dart): attachments and schedule | not_run / not_run |
| `HD-PREVIEW` | **gap** | **gap** | not_run / not_run |
| `HD-EXPORT` | [transcript_export.yaml](../../scripts/maestro/fixture/transcript_export.yaml) | [Flutter native suite](../../integration_test/linux_maestro_flows_test.dart): clipboard exports | not_run / not_run |
| `HD-VOICE` | [microphone_denied.yaml](../../scripts/maestro/fixture/microphone_denied.yaml)<br>[voice_language.yaml](../../scripts/maestro/fixture/voice_language.yaml) | **gap** | not_run / not_run |
| `HD-COMMAND` | [composer_commands.yaml](../../scripts/maestro/fixture/composer_commands.yaml) | **gap** | not_run / not_run |
| `HD-SOUL` | [soul_directories.yaml](../../scripts/maestro/fixture/soul_directories.yaml) | [Flutter native suite](../../integration_test/linux_maestro_flows_test.dart): screen tour | not_run / not_run |
| `HD-SKILLS` | [tools_inventory_qa.yaml](../../scripts/maestro/tools_inventory_qa.yaml) | [Flutter native suite](../../integration_test/linux_maestro_flows_test.dart): screen tour | not_run / not_run |
| `HD-MCP` | **gap** | **gap** | not_run / not_run |
| `HD-MEMORY` | **gap** | **gap** | not_run / not_run |
| `HD-SCHEDULE` | [schedules.yaml](../../scripts/maestro/fixture/schedules.yaml) | [Flutter native suite](../../integration_test/linux_maestro_flows_test.dart): attachments and schedule | not_run / not_run |
| `HD-KANBAN` | **gap** | **gap** | not_run / not_run |
| `HD-GATEWAY` | [gateway_connection.yaml](../../scripts/maestro/fixture/gateway_connection.yaml) | [Flutter native suite](../../integration_test/linux_maestro_flows_test.dart): screen tour | not_run / not_run |
| `HD-OFFICE` | [office_workspace_qa.yaml](../../scripts/maestro/office_workspace_qa.yaml) | [Flutter native suite](../../integration_test/linux_maestro_flows_test.dart): screen tour | not_run / not_run |
| `HD-ACCOUNT` | **gap** | **gap** | not_run / not_run |
| `HD-SETTINGS` | [settings.yaml](../../scripts/maestro/fixture/settings.yaml)<br>[spellcheck.yaml](../../scripts/maestro/fixture/spellcheck.yaml) | [Flutter native suite](../../integration_test/linux_maestro_flows_test.dart): screen tour | not_run / not_run |
| `HD-DIAG` | **gap** | **gap** | not_run / not_run |
| `HD-UPDATE` | **gap** | **gap** | not_run / not_run |
| `HD-NATIVE` | **gap** | **gap** | not_run / not_run |
| `HD-ACCESS` | [local_setup_accessibility.yaml](../../scripts/maestro/fixture/local_setup_accessibility.yaml) | **gap** | not_run / not_run |
## Retained evidence, not fresh platform qualification

- Earlier logged `npm run test` completed with **3,501 passed, zero failed**, exit **0**.
  This was the shared dirty worktree, not an isolated/pinned source snapshot.
  The [receipt](../../.task-evidence/parity-flow-matrix/npm-test-result.json) and
  [log](../../.task-evidence/parity-flow-matrix/npm-test.log) are retained.
  A passing Dart suite does not qualify Android device or native Linux flows.

- A later direct `npm run test` completed with **3,504 passed, zero failed**, exit **0**.
  Its exited process and summary were recovered for this update in the
  [direct-run receipt](../../.task-evidence/parity-matrix-refresh/direct-npm-result.json).
  Subsequent source edits are not qualified by that run.
- Maestro CLI `2.4.0` was available outside PATH in the syntax pass. Its absolute executable ran.
- All **58 YAML files** under `.maestro/` and `scripts/maestro/` passed
  `maestro check-syntax` individually. That includes helpers and live-target flows.
  Syntax does not validate selectors, API contracts, assertions or device behavior.
- `adb devices -l` found only an unauthorized Android target. No app install,
  launch, clearState or device flow was performed.
- `bash scripts/run_linux_e2e.sh` exited **2** at prerequisite discovery. libsecret
  and GStreamer development metadata are missing. No native build/launch ran.
- Neither the original matrix pass nor this documentation update changed product
  code, test flows, personal app data, SSH trust or runtime. Other workers
  delivered the attributed implementation slices above.

Retained evidence: [flow inventory](../../.task-evidence/parity-flow-matrix/flow-inventory.json),
[per-file syntax results and hashes](../../.task-evidence/parity-flow-matrix/syntax-results.json),
and [target preflights](../../.task-evidence/parity-flow-matrix/preflights.json).
See the [execution runbook](../runbooks/desktop-feature-qualification.md).

## Acceptance of a 1:1 port

A passing syntax or fixture suite is insufficient. Each supported operation needs
an executed matching-platform flow, exact owner/resource identity, recovery
behavior and authoritative effect readback. Unsupported Desktop outcomes remain
open parity gaps even when their unavailable-state test passes.

Capture source/build/flow fingerprints, target/driver identity, exact commands,
exit codes, per-flow pass/fail/not-run results and redacted screenshots/logs.
Prove correlated approvals, authoritative Stop and exact session/model restoration.
Count deliberate submissions and recovery mutations to detect replay.
Separate fixture behavior from live inference, native plugins and physical input.
Compare navigation, wording, interaction and recovery against Desktop. Record
compact layout, Settings organization, external SSH and 2D Office deviations.
Do not certify 1:1 fidelity through a feature count or screenshot similarity.

## Remaining delivery

The machine-readable matrix separates `existing_task_ids` from open
`remaining_task_ids`. Completed investigation slices are not the remaining
implementation backlog. Each row also names both platform qualification tasks.
A bounded session goal marked met in the ledger does not qualify its native/live
variants or the broader Desktop outcome. Those gaps stay with platform and daily
workflow goals. Preserve the ledger's current task IDs, status and priority.


Retain existing feature tasks rather than creating a duplicate port backlog.
PARITY-MAESTRO-ANDROID runs and repairs mapped QA flows. PARITY-NATIVE-LINUX
executes/adapts their native Flutter counterparts and records unmatched operations.
These tasks do not replace M1 live daily-use, M2 physical recovery or individual
contract-gated feature tasks. [Root TODO](../../TODO.md#now--next) owns execution
scope, dependencies and existing owner-question IDs.
