# M4 Kanban: one Project-associated board read

Task: `DOC-M4-KANBAN-CONTRACT`. **Read-only source inspection, not operation
activation, shipped board support or native/live qualification.** Start with the
[parity status](../product/hermes-desktop-parity.md#statuses),
[current routes](../product/routes.md) and [API/state boundary](../adr/api-and-state.md).

## Verdict and source identities

Official Desktop reads **`GET /api/plugins/kanban/board`** from the Agent's
Kanban plugin. A board can reference a Hermes Project, but it is **not** a
per-profile Project-owned collection. The read has no pagination or response-size
contract, no exact advertised Wing operation/grant, and no echoed board/Project
incarnation. **Keep board inspection unavailable in Wing.** This is a bounded
contract-gap result, not evidence that Hermes lacks Kanban everywhere.

Pins obtained with `git rev-parse HEAD` and `git -C <reference> rev-parse HEAD`:

| Inspected source | Revision | Evidence ceiling |
| --- | --- | --- |
| Wing baseline | `aad3ca483d7d8f3991c5436946b01ea22ec7a591` | Existing callers and regression source; only documentation changes here. |
| Unmodified Agent reference | `158fd638da1629c8e62caf9ade1515d162def8ab` | Handler, store/model and test source, not an installed runtime. |
| Official Desktop, `apps/desktop/` | `158fd638da1629c8e62caf9ade1515d162def8ab` | Same repository/revision, not separate release or executed parity evidence. |

The reference clone is at the canonical checkout's `hermes-agent/`, outside this
isolated worktree; it was inspected without modification. Its status was clean.
Root and relevant area instructions were read. No credentials, runtime databases,
board payloads, workspace files or directory grants were accessed. No service,
tracker operation, upstream test or board request was activated.

Docs map:

- Existing owners: parity/routes above, [Project creation trace](m3-project-creation-contract.md),
  [Agent immutability](../adr/runtime-and-delivery.md#hard-boundary-never-modify-hermes-agent)
  and [threat model](../security/threat-model.md).
- Source corpus: plugin board handler and SQLite models, Desktop native plugin
  caller, Wing Schedules/client/channel and nearest regression sources.
- Chosen slice: one named board snapshot, with `include_archived=false`; tenant
  and workflow filters are described only to establish their limits. Board/Project
  listing is supporting ownership evidence, not another proposed callable slice.
- Missing evidence: exact authorization, stable board-to-Project ownership,
  pagination/bounds, redacted output and side-effect-free read guarantees.
- Validation: pinned source trace, local Markdown targets and source ranges,
  independent contract/security review and `git diff --check`; no behavior change
  warrants a new executable test.

Ownership check: the coordinator assigned this branch/worktree. The baseline
[task index](../tasks/work-queue.md#current-work-queue) places this task in Next and makes
`DOC-M4-KANBAN-PAGINATION-EVIDENCE` dependent on it. The local Autowork status
records this task as running and holds the overlapping follow-up. The inspected
[continuation ledger](../plans/2026-10-03-desktop-port-goal.md) has no matching
Kanban claim. This is local admission evidence only, not a live tracker lease
check, another worker's ownership release or authority to select a new task.

## Exact authoritative trace

| Acceptance dimension | Supported at the pinned source | Missing guarantee / Wing disposition |
| --- | --- | --- |
| Operation | [Router mount][U1]:849–934 places the plugin under `/api/plugins/kanban`; [handler][U2]:283–363 takes `board`, `tenant`, `include_archived`, `workflow_template_id`, `current_step_key`. | No `project_id` filter, `limit`, offset or page cursor in this GET. No versioned response model is declared. The messaging API [capability table][U3]:67–103 does not advertise this read. Do not invent a route, operation name or grant. |
| Board authority | [Board store][U4]:428–485 deliberately resolves a root shared across profiles; selection can come from context, environment or persisted current pointer. An explicit slug is normalized/validated (1–64 characters); [resolver][U2]:59–100 rejects malformed/unknown non-default names with 400/404. `default` always exists by domain convention ([existence][U4]:505–523). | A profile query does not turn a shared board into a per-profile board. Omitted/empty board uses ambient selection; whitespace normalizes to no explicit board. Slug existence is neither authorization nor immutable identity, and delete/recreate is not fenced. Require explicit current identity before any future Wing read. |
| Project association | [Board metadata][U2]:1333–1416 resolves `project_id` against the scoped per-profile [Project DB][U5]:22–49, 114–143. `/boards` annotates the Project name; Project lookup failure becomes an empty map. Board metadata and tasks carry optional Project IDs ([task model][U4]:767–813). | The shared board's metadata does not bind a Project's owning profile/incarnation. A Project name/ID annotation is not a foreign-key authorization check. `/board` itself does not validate a Project or restrict cards to one Project; nullable task `project_id` is not proof all cards belong to the board's current association. No permission to read Project directories follows. |
| Profile context | Production [mount dependency][U1]:792–803, 927–931 binds home/secret scope through `_config_profile_scope(profile)`; [scope helper][U6]:277–320 validates explicit names and binds the requested home. | This is genuine profile scoping for Project/config resolution, not caller authorization to every board. Omitted/blank/`current` retains launch-profile semantics. Response has no profile/board/Project identity envelope, revision or incarnation. |
| Authentication vs grants | [HTTP middleware][U7]:644–727 authenticates protected API traffic and applies plugin enable/disable gates; mount also limits trusted plugin sources. | Handler declares no per-board/Project required-scope or caller-grant contract. Dashboard session/OAuth/token authentication and plugin enablement are not an advertised Wing board-read grant. `tasks:read` for scheduled jobs cannot authorize Kanban. Do not acquire or reuse another transport's credential as fallback. |
| Bounds and content | [Handler/serializer][U2]:169–193, 283–343 returns `columns[{name,tasks}]`, `tenants`, `assignees`, `latest_event_id`, `now`; `latest_summary` alone is clipped to 200 characters. [Domain list][U4]:1592–1623 can accept `limit`, but this handler does not pass one. | No task-count, total-byte, body/title/result/path/diagnostic bound or continuation/exhaustion marker. `asdict(task)` exposes the full domain row, including body, result, workspace path, claim and failure metadata; narrower Desktop types do not remove wire fields. Not a bounded secret/path-free projection. Client truncation after fetching cannot create a server bound or prove completeness. |
| Filtering and consistency | Tenant/workflow filters constrain the task SELECT; default excludes archived. Queue order is `priority DESC, created_at ASC`; done is sorted `completed_at DESC` with nulls last and ID descending ties ([handler][U2]:294–343, [domain][U4]:1592–1623). | Tenant is a filter, not an access boundary. Rollups, diagnostics, tenant/assignee enumeration and event maximum include board-wide data outside the filtered task set. Multiple SELECTs have no encompassing explicit snapshot transaction here; `latest_event_id` is an event-tail marker, not a page cursor or coherent snapshot revision. Queue ties have no explicit unique tiebreaker. |
| Read effects and failure | `_board_conn` opens the named DB and closes it. [Endpoint][U2]:344–363 resolves selection before coalescing; [coalescer][U8]:22–66 shares identical home/argument in-flight reads with one worker admission per function/event loop. | This is not a guaranteed zero-write GET: `_conn` calls `init_db`; [connection/init][U9]:668–770 can create directories/DBs, configure journaling and run schema/migrations. Initialization exceptions are logged before another connect attempt. No sanitized bounded error envelope is declared by this GET. Coalescing limits duplicate work, not rows, bytes, queued callers or snapshot drift. Source inspection must not execute the endpoint to prove a pure read. |

### Read sequence, without activating it

1. Desktop's [fixed plugin REST door][U10]:66–86 adds profile context and maps
   relative `/board` into the plugin namespace. [Kanban API][U11]:358–389 adds
   the selected slug and optional archived flag; it does not switch the Agent's
   global board pointer.
2. The Agent endpoint captures `board` or current selection before coalescing.
   The worker resolves/opens the board, lists tasks and computes link/comment/
   progress rollups plus diagnostics, latest summaries and current-run starts.
3. Serialization uses every `Task` field, adds derived data, buckets cards and
   returns the event maximum/time. No workspace file contents, attachment download
   or task-detail request is needed by this sequence; this does **not** make
   existing path-bearing metadata safe to persist or log.
4. Desktop [query][U12]:1094–1107 keys by connection/board/archived view and polls
   every 60 seconds. [Render states][U12]:1381–1404 distinguish first-load error,
   loading and empty/no-match; data can remain rendered after a refresh failure.
   The [TypeScript subset][U13]:1–50 is compile-time documentation, not response
   validation, authorization or a size limit. Connection-scoped caching is a
   reference interaction, not evidence of server identity or Wing support.

## Nearest tests inspected, not executed

| Source and cases | Evidence in test source | Ceiling |
| --- | --- | --- |
| [Plugin board tests][U14]:48–110, 157–169, `test_board_empty`, `test_create_task_appears_on_board`, `test_tenant_filter` | Bare FastAPI router gives canonical empty columns, card visibility and tenant filtering over disposable DB state. | Does not mount production authentication/profile dependency; not exact grants, Project filtering, pagination, bounded content or a zero-write read oracle. |
| [Project association tests][U15]:35–120, `test_boards_list_surfaces_project`, `test_task_on_scoped_board_inherits_project` | Board metadata exposes the selected Project; a created task inherits its ID. | One temporary home and bare router; no two-profile same-ID collision, owner drift, all-card membership or read authorization proof. Test mutation setup is inspected, never executed here. |
| [Domain isolation tests][U16]:225–269, `test_tasks_do_not_leak_across_boards`, `test_connect_without_args_uses_current` | Separate explicit board DBs isolate task lists; ambient selection affects unqualified connects. | DB routing is not HTTP caller authorization, profile ownership or slug-incarnation safety. |
| [Done-order tests][U17]:59–86 | Completion-time ordering differs from queue FIFO. | No stable paging/snapshot contract or concurrent-reader oracle. |
| [Read-admission test][U18]:28–87, `test_board_burst_preserves_http_worker_capacity` | Eight identical blocked GETs coalesce to one list call and leave another HTTP worker available. | Bare app and mocked blocking seam; not row/byte bounds, queue bound or zero DB initialization effects. |
| [Desktop connection tests][U19]:28–130 | Render keys follow active connection, remembered slug is connection-specific, outgoing observers do not refetch onto an incoming backend. | Mocked REST/socket; not server Project authorization, revoked grants or full in-flight same-slug lifetime fencing. |

## Wing caller and regression trace

There is **no board caller/model** in the inspected `lib/core/hermes/`,
`lib/features/schedules/` and `lib/router/` production paths (searched for Kanban,
board slug and Project ID). The adjacent public seam is scheduled jobs, not cards:

- [Schedules screen](../../lib/features/schedules/screens/schedules_screen.dart):19–21,
  173–227, 288–308, 535–538 is a read-only jobs surface with owner-bound refresh;
  Kanban stays hidden. [Channel contract](../../lib/core/hermes/channel/hermes_channel.dart):127
  exposes `loadJobs`, not a board operation.
- [Exact gate](../../lib/core/hermes/channel/hermes_channel_state.dart):221–222,
  264–284 requires the supported schema, `jobs GET /api/jobs`, declared and granted
  `tasks:read`, every required grant and supported profile context. This is not
  transferable board authority. [Reload](../../lib/core/hermes/channel/api_channel/hermes_api_channel_connection.dart):275–311
  captures connection/profile/selection/request generations and rejects late results.
- [Client](../../lib/core/hermes/client/hermes_api_client.dart):27, 190–208 fetches
  jobs with explicit profile and `include_disabled=true`, decodes `jobs`/`data` and
  takes at most 128. It cannot decode the board's `columns` as equivalent inventory;
  that client-side count cap is not server pagination.
- The native [fixed RPC seam](../../lib/core/hermes/client/hermes_web_read_rpc.dart):1–88
  does not expose plugin REST or generic Kanban dispatch. Existing native Chat
  qualification does not admit board inspection.

Nearest Wing regression sources (not run by this docs-only task):

| Public seam | Inspected cases | What remains unproven |
| --- | --- | --- |
| Schedules UI | [Screen tests](../../test/features/schedules/schedules_screen_test.dart):595–618, 694–766: advertised read-only inventory, unsupported read, missing `tasks:read`, sanitized failed read | Confirms intent for jobs/no New task, not a board-denial or Project-ownership oracle. |
| Jobs API | [API tests](../../test/core/hermes/hermes_api_test.dart):1746–1778: count bound and explicit disabled-job query | Not a board response bound or authoritative board capability. |

The older parity ledger includes retired Wing Link/directory-grant wording.
Current living ADRs and routes govern: no compatibility adapter, arbitrary shell,
direct database/filesystem fallback, shadow cards or Agent patch. A metadata-only
board read would not itself confer directory access; directory/content operations
retain their own opaque-grant boundary. This receipt does not revise product
status, create a board route or mark M4-KANBAN met.

## One next read-only slice

Follow-up evidence is now recorded in the
[pagination and stale-owner receipt](m4-kanban-pagination-evidence.md). It records
absent authoritative pagination and expected owner/revocation outcomes, not a new
callable operation or live qualification. The original handoff below is retained
as the scope of that follow-up.

Use the already indexed **`DOC-M4-KANBAN-PAGINATION-EVIDENCE`**, subject to its own
coordinator admission; do not start it here. Trace a proposed first-page read
across endpoint/profile/board/Project identity changes, grant loss and same-slug
board recreation against pinned handlers/models and nearest caller tests.
Determine whether an unmodified advertised surface offers authoritative limits,
stable ordering, continuation/exhaustion and a coherent snapshot, or record each
as unavailable. The inspected `/board` supplies none of those paging guarantees;
no invented cursor, client-side slicing or repeated full-board scans may fill them.

Acceptance for that evidence slice: distinguish unavailable/denied/failed/empty/
partial data; reject old-owner results and continuation after identity or authority
loss; record a safe bounded metadata projection or its absence. These are review
criteria, not new wire fields or implementation authorization. Exclude tracker
mutation, board switching, task detail/logs/attachments, directory file access,
credential acquisition and privileged/runtime operations.

## Validation and qualification ceiling

- PASS: source pins and handler → model/store → nearest tests → Desktop/Wing
  caller trace, 16 local Markdown targets/anchors, 19 pinned source targets and
  48 prose source ranges checked against the inspected trees. These are offline
  source checks only; the final staged `git diff --check` is the whitespace gate.
- Independent fresh-context `reviewer` approved the substantive receipt as bounded
  source-only contract/security evidence, with no findings or required corrections
  (run `f4dfc27b-c6ba-471d-8b26-4011eec5e052`). The final edit records validation and
  review outcomes only. This is task review, not a security audit or live acceptance.
- No Flutter, upstream executable test, browser, native app, Android/device,
  provider or live Agent operation was exercised. No platform support is added.
- Pending live: authenticated bounded board reads/denials, exact Project/board
  ownership and accessible target-native inspection, **only after** an eligible
  unmodified operation and separately admitted disposable target exist. This is
  not an offline blocker or permission to activate anything now.
- Revisit on changes to board models/handler/mount/auth/profile scoping, Project
  association, pagination/serialization, Desktop caller/cache behavior or Wing
  gates. Re-pin and independently review; do not transfer this result to an
  uninspected Agent release.

## Pinned upstream sources

[U1]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_server_dashboard.py
[U2]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/plugins/kanban/dashboard/plugin_api.py
[U3]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/gateway/platforms/api_server.py#L67-L103
[U4]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/kanban_db.py
[U5]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/projects_db.py
[U6]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_server_profiles.py#L277-L320
[U7]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_server.py#L644-L727
[U8]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_read_coalescing.py#L22-L66
[U9]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/kanban_db_connect.py#L668-L770
[U10]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/api/plugins.ts#L66-L86
[U11]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/plugins/kanban/api.ts#L358-L389
[U12]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/plugins/kanban/board.tsx
[U13]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/plugins/kanban/types.ts#L1-L50
[U14]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/plugins/test_kanban_dashboard_plugin.py
[U15]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/plugins/test_kanban_board_project_api.py#L35-L120
[U16]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/hermes_cli/test_kanban_boards.py#L225-L269
[U17]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/plugins/test_kanban_board_done_order.py#L59-L86
[U18]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/plugins/test_kanban_read_admission.py#L28-L87
[U19]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/plugins/kanban/api.connection-scope.test.ts#L28-L130
