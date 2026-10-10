# Grouped recents: metadata and exact-owner opening

> Reference correction: [official Desktop authority](official-desktop-reference.md). Prior Desktop source citations and parity conclusions in this document are withdrawn. Wing test results remain historical behavior evidence only.


Status: source-backed comparison for `t_6fe8c9a6`,
`DOC-PARITY-RECENTS-REFERENCE` / `PARITY-COMPOSITION`.
This card delivers the next implementation contract, not grouped-recents code.
Existing Open/New behavior is retained; broad composition remains partial.

## Reference and evidence boundary

Wing HEAD inspected: `1afe1307e37ee1ddfa1f7d67ad047509e99c8784`.
Desktop reference: local `withdrawn source citation`, origin
`withdrawn source`, HEAD
`withdrawn reference revision`.
Agent reference HEAD: `158fd638da1629c8e62caf9ade1515d162def8ab`.
These pins describe the inspected checkouts, not remote-latest or deployed APIs.
The scoped Desktop renderer/cache/test files have no diff from that HEAD.
Wing is a dirty shared checkout: its HEAD does not describe all live source.
Card-local SHA-256 fingerprints bind the inspected inputs, including dirty ones.

[Wing instructions](../../AGENTS.md), [context](../../CONTEXT.md),
[contribution rules](../../CONTRIBUTING.md),
[Desktop instructions](official-desktop-reference.md#withdrawn-evidence) and
[Agent instructions](../../hermes-agent/AGENTS.md) were read before inspection.
`lat` is absent; direct source lookup replaced upstream semantic lookup.
Neither upstream was executed or changed. No installs, secrets or live actions
were used. The [client ADR](../adr/client.md#decision),
[API ADR](../adr/api-and-state.md#decision) and
[runtime boundary](../adr/runtime-and-delivery.md#read-only-upstream-references)
remain binding. Folder grouping cannot bypass the
[threat model](../security/threat-model.md#directories-and-projects).

The [parity ledger](../product/hermes-desktop-parity.md#reference-and-evidence-boundary)
and [UI gap](../product/hermes-desktop-ui-gap.md#current-source-backed-gaps)
keep grouped recents separate from the already delivered passive footer and
loaded-session access. The earlier [footer comparison](profile-footer-composition.md)
is historical source/test evidence, not a fresh execution by this card.
The [footer delivery](profile-footer-implementation.md) and
[loaded-access runbook](../runbooks/global-session-access.md) supply context only;
the existing footer, full session modal and multi-run tabs are outside this slice.

## Desktop grouping, ordering and open identity

[SidebarRecentSessions](official-desktop-reference.md#withdrawn-evidence)
provides the following inspected behavior:

- `RecentSession` carries `id`, `title` and optional `contextFolder` (lines 28–32).
  `groupSessionsByWorkspace` (117–147) trims the folder string, groups by that
  entire path and derives a display basename. Empty bindings go to Chats.
  Equal basenames do not merge different paths. This is not an Agent Project ID.
- Pinned IDs are Desktop localStorage presentation state. Pinned rows are removed
  from ordinary grouping (471–481). Presentation order is Pinned, Projects, Chats
  (791–918). Projects appear in first-encounter order; rows retain their incoming
  order within each group. There is no date or source grouping in this component.
- Page size is 30. Opening reads cache then syncs; visible lists refresh on focus,
  a 60-second timer and current-session changes, throttled to five seconds.
  Scroll proximity loads cached pages; append deduplicates by ID (298–455).
  The initial effect cancels late application. Do not infer a universal stale-owner
  fence from it: periodic `refresh` applies its awaited result without that same
  cancellation check, and the profile-change effect calls it separately (457–464).
- Section/folder disclosure is persisted. Row traversal uses visibility-dependent
  tabindex. The outer collapsed wrapper is aria-hidden; rows activate the exact
  `s.id` on click, Enter or Space (726–918). Those are inspected handlers, not
  executed keyboard or screen-reader qualification.

The local ordering source is
[session-cache](official-desktop-reference.md#withdrawn-evidence):
`syncSessionCache` queries visible sessions by `started_at DESC`, attaches folder
bindings and sorts by `startedAt` descending (129–215). A renderer comment about
resume reordering does not establish last-activity sorting on this local path.
Its [nearest test](official-desktop-reference.md#withdrawn-evidence),
“on first sync, ingests all sessions and generates titles” (363–388), explicitly
asserts descending start time; “reads and writes only the explicitly selected
Local profile” (391–420) checks cache isolation. These tests were inspected only.

Folder bindings come from Desktop's own
[context-folder store](official-desktop-reference.md#withdrawn-evidence)
(lines 4–23, 78–95): a Desktop-created table in the profile database, not an
advertised Agent Project/session contract. Wing must not copy that storage,
read the database or derive arbitrary host paths.
[IPC routing](official-desktop-reference.md#withdrawn-evidence) (2820–2868) selects
local, Remote or SSH implementations with connection/profile context.
[Remote sessions](official-desktop-reference.md#withdrawn-evidence) (271–325)
request `order=recent` and deliberately return `contextFolder: null`.
The [remote test](official-desktop-reference.md#withdrawn-evidence) (421–435)
asserts that missing folder binding. Do not describe Desktop Project grouping
as universally available across its backends. The test is not newly executed here.

[Layout](official-desktop-reference.md#withdrawn-evidence)
passes connection/profile/current/loading/resuming IDs into the sidebar and
`handleResumeSession` as `onSelect` (749–763). That callback (627–668) first
finds a live run by connection/profile/session; otherwise it guards duplicate
resume by session ID, reads messages with connection/profile, mints a run and
navigates to Chat. Wing must preserve the exact location outcome, not port run
minting, optimistic late navigation or Desktop IPC.

## Current Wing metadata and callers

| Concern | Current source and supported boundary |
| --- | --- |
| Loaded inventory | [ShellSessionAccess](../../lib/features/hermes_chat/widgets/shell_session_access.dart) renders `state.sessions` directly (239–271), in its existing order. It observes channel and directory lifetime without constructing a directory. [AppShell](../../lib/shared/widgets/app_shell.dart) mounts it only in the expanded scrollable sidebar (448–483). |
| Group keys | [HermesSession](../../lib/core/hermes/models/hermes_session.dart) exposes exact `source`, `id`, optional title/model, `startedAt`, `lastActive` and lineage parent (5–80). It exposes no context-folder binding, opaque Project ID, Project label or per-row host/profile. All rows belong to the current channel owner; metadata must not be used to invent another owner. |
| Authoritative projection | The inspected [Agent API](../../hermes-agent/gateway/platforms/api_server.py), `_session_response` (3011–3043), includes source/timestamps/lineage and pin flags, but no context folder or Project ID. `_handle_list_sessions` (3091–3143) requests last-active ordering and backfilled pins. Wing's model does not decode those pin flags. That source is not a capability advertisement from the connected Agent. |
| Inventory order | [API client](../../lib/core/hermes/client/hermes_api_client.dart), `listSessionsPage` (126–150), sends profile context and bounded limit/offset, not a new sort query. Page decoding preserves returned order. [Channel sessions](../../lib/core/hermes/channel/api_channel/hermes_api_channel_sessions.dart), `_loadMoreSessions` (239–279), appends previously unseen IDs; creation/fork can append rows too. Loaded order is not a guarantee of globally complete chronology. |
| Existing local presentation | [Chat session widgets](../../lib/features/hermes_chat/screens/widgets/hermes_chat_sessions.dart) already filter by exact source, derive redacted source labels (1426–1446), and separately group pins/dates using `lastActive`, with title/ID tie ordering (1365–1415). Those helpers are private to Chat. Its date groups and contact-scoped pin state are not available as shell owner metadata. Do not mount Chat or read its pin store to fake sidebar Project grouping. |
| Open authority | [Channel state](../../lib/core/hermes/channel/hermes_channel_state.dart) (133–145) gates the exact history/create operations, including an existing null-capability branch. [History fetch](../../lib/core/hermes/channel/api_channel/hermes_api_channel_connection.dart) (334–421) rechecks authorization and request generations before history/pagination/cache admission. Its null/unsupported-capability check can reject a call that a shell visibility compatibility branch permits. Grouping must not broaden either policy. |

The shell's only action seam is `_activate` (120–195): exact loaded ID →
`channel.selectSession(id, canAccept: current)` → acknowledged matching active ID
with no error → `/hermes`. It admits one pending action; failure retains the
feature route with generic localized feedback. New remains a separate explicit
create action, requiring its existing gate and a newly acknowledged ID.
[HermesApiChannel](../../lib/core/hermes/channel/hermes_api_channel.dart)
delegates to `_selectSession`; that implementation captures connection/profile/
selection generations, checks the known ID, recovers detached runs and admits
history only while the caller is current (57–131 in channel sessions).
An explicit Open may perform existing history/recovery reads. “Zero incidental
reads” means no reads caused by presentation, not zero requests for explicit Open.

Other implicated callers were traced without changing their contracts:
[session actions](../../lib/features/hermes_chat/session/hermes_chat_session_actions.dart)
`_selectSession` serves the route-local picker/rail, including callbacks from
[connection state](../../lib/features/hermes_chat/screens/state/hermes_chat_connection.dart)
and [layout](../../lib/features/hermes_chat/screens/state/hermes_chat_layout.dart).
[Chat screen](../../lib/features/hermes_chat/screens/hermes_chat_screen.dart)
cycles/selects ordinals through that action (654–691).
[Gateway directory](../../lib/features/hermes_chat/gateways/hermes_gateway_directory.dart)
restores/activates contacts; its fallback can create sessions (1117–1144), so
it is not a substitute for exact shell Open.
[Queued follow-up flow](../../lib/features/hermes_chat/composer/hermes_chat_message_flow.dart)
opens an explicit queued session (345–373); it is not a new recents submission path.
No shared channel API change is needed for the proposed presentation slice.

## Bounded PORT-GROUPED-RECENTS contract

Default applied for the next slice: source-grouped loaded rows, explicitly labeled
as grouping by source, not Projects/workspaces. This is a reversible intermediate
product deviation, not Desktop folder-grouping parity. Source is supported today;
Project/folder grouping remains unavailable until an authoritative exact-owner
session-to-Project display contract is advertised and separately reviewed.
Do not invent an API, infer paths from titles/model/source/lineage, or attach
Wing Link directory grants to sessions. Optional date grouping is possible from
parsed timestamps, but is not this default: avoid introducing a second recency
sort or calendar boundary while the loaded window remains incomplete.

Limit the implementation to the existing shell/session presentation seam, nearest
widgets, localized copy as needed, and a compiled deterministic browser journey.
Use a pure projection of the current owner's loaded `HermesSession` rows:

- Group by exact nonblank source; whitespace-only/missing sources use an Unknown
  source bucket. Keep distinct nonblank identities distinct, even when redaction
  or normalized display labels collide. Never use a display label as an open ID.
- Order groups by first appearance in the current loaded list; retain row order
  within each group. Do not mutate `state.sessions`, sort by model/title, promote
  the selected row or claim full recent-history completeness. Use existing bounded
  redacted preview conventions for group/row labels, tooltips and semantics.
- Keep the current Open/New controls and `_activate` admission path. No new read,
  refresh timer, cache, directory construction, paging-on-scroll, pin persistence,
  rename/delete/fork menu, session creation or submission is caused by grouping.
  Full search/pins/pagination/management stay in Chat. Tabs/footer are excluded.
- Any group disclosure is volatile presentation state, reset on owner loss;
  hiding rows removes them from traversal/semantics and invalidates their captured
  callbacks and late navigation, including collapse then re-expand. Do not persist
  folder strings, credentials or domain state. Reuse ordinary Flutter buttons.

Ownership remains `_identity` (shell lines 58–99): channel instance, directory
lifetime/instance, active contact, activation/restoration, connection status and
origin, profile selection, unreconciled run, history/create availability.
Invalidate synchronously on any loss/change-back and row removal; identical IDs
at replacement owners cannot revive old intent. Preserve `_settled`, generation
checks, one pending action and route-observer invalidation. Reconnect reprojects
server state; it does not replay selection, New, prompts or approvals. Ordinary
same-owner row updates may change display, not manufacture ownership transitions.
Sidebar collapse, compact resize and disposal remove controls and invalidate the
old widget lifetime; resize-back reprojects loaded rows without fetching.

## Observable acceptance oracles for implementation

These three oracles require new grouping tests and browser evidence; existing
passes below do not qualify an unimplemented grouping UI.

1. Projection: interleaved two-source rows plus blank/custom sources produce
   first-encounter groups and stable in-group order, with each loaded ID present
   once. Equal titles/redacted labels do not merge identities. Same-owner append,
   removal and metadata updates reproject without changing the active tuple.
   Missing Project metadata exposes no Project/path grouping. All incidental
   read/connect/select/create/model/approval/submission counters remain zero.
2. Exact action and recovery: Tab/Shift+Tab reach named selected rows; Enter and
   Space each call Open once for that exact owner/ID, including identical titles
   and active/nonactive rows. Pending duplicates cannot navigate early; failure
   stays on the feature with explicit retry. A→B→A, disconnect/reconnect,
   contact/directory/channel/lifetime replacement, capability loss, row removal
   and route departure reject cached callbacks and late success/error. Open never
   creates/submits. Explicit history/recovery requests retain exact profile/ID.
3. Presentation lifetime: at short height and 2x text, focused rows scroll into
   view and shell/route traversal reverses with visible focus. Group disclosure,
   sidebar collapse and compact resize remove hidden controls from focus/semantics
   and reject in-flight callbacks. Expand/resize-back makes only current loaded
   rows available with zero new requests. Run nearest shell tests, `flutter analyze`
   and a freshly built deterministic Chromium journey; record native/live and
   screen-reader limits separately.

## Executed evidence and acceptance mapping

Command executed on Linux, exit 0, eight existing widget tests passed:

```sh
flutter test --no-pub --concurrency=1 test/shared/widgets/app_shell_global_session_access_test.dart --name 'production shell opens exact nonactive and active loaded rows once|late open rejected after (profile|disconnect|removed|collapse|channel) including change-back|rendered callback cannot revive after same-frame row removal|named selected semantics, keyboard, collapse and compact resize'
```

[Existing test target](../../test/shared/widgets/app_shell_global_session_access_test.dart)
uses deterministic channels/directories and real shell/router composition. Selected
cases prove current exact Open, late owner/disconnect/removal/collapse/channel
rejection, synchronous row-removal invalidation and keyboard/collapse/resize
behavior. The keyboard case uses Enter for Open and Space for explicit New;
it does not prove Space opens grouped rows. Explicit read request identity,
group disclosure, grouping/order oracles and a compiled grouping journey require
later tests. Fakes do not establish deployed Agent authorization or native UI.

Retained evidence: ignored `.task-evidence/t_6fe8c9a6/`, including
`shell-tests.log`, `source-fingerprints.json`, `check_receipt.py`,
`receipt-check.log` and `ledger-checks.log`.
Document-integrity checks: `python .task-evidence/t_6fe8c9a6/check_receipt.py`
(local links/anchors, whitespace, pinned source hashes), `git diff --check`, and
`python <home>/.hermes/shared-skills/repo-docs/scripts/goals.py validate <repo>`.
Exact results are retained in those logs and the goal ledger; failures must not
be converted into passes without execution.

Acceptance (1) maps to the pinned Desktop contract and Wing metadata/caller table;
(2) maps to the lifetime contract, three future oracles and eight executed current
regressions; (3) maps to document-integrity/ledger checks and the scoped local
agent-branch commit recorded in the native review handoff. Only
`DOC-PARITY-RECENTS-REFERENCE` is finished; `PORT-GROUPED-RECENTS` stays open and
`PARITY-COMPOSITION` remains partial. No product behavior ships through this card.

Native Flutter desktop, compiled browser, physical Android, live Agent/provider,
screen reader, full suite/analyzer/build, packaging and full parity: NOT_CHECKED
by this documentation slice. No release/native build or copied checkout was created.
No owner question is needed. Existing no-system-change, no unauthorized device
and no publication defaults remain in effect.
