# M4 Kanban: pagination and stale-owner board reads

Task: `DOC-M4-KANBAN-PAGINATION-EVIDENCE`. **Offline source evidence only.**
Start with the [board-read contract](m4-kanban-board-read-contract.md),
[parity status](../product/hermes-desktop-parity.md#statuses) and
[accepted port plan](../../ROADMAP.md#flutter-port-execution-roadmap).
This receipt does not enable a route, issue a board request or qualify a platform.

## Verdict and pins

**Authoritative card pagination is absent on the inspected Desktop board read.**
`GET /api/plugins/kanban/board` returns a full, unbounded board projection, not a
first page. No continuation can safely be specified for it. Keep Wing board
inspection unavailable; do not manufacture pages, exhaust a board through repeated
full reads, retain shadow cards or substitute the events stream.

| Inspected checkout | `git rev-parse HEAD` result | Evidence ceiling |
| --- | --- | --- |
| Wing task baseline | `839911e6c4e91f573e98a7f7dc8a1403f404a825` | Live caller/test source and retained sanitized receipt, not a new test run. |
| Read-only Hermes Agent reference | `158fd638da1629c8e62caf9ade1515d162def8ab` | Handler, model/store, auth/mount and nearest tests; no imports or runtime data accessed. |
| Official Desktop (`apps/desktop/` in Agent) | `158fd638da1629c8e62caf9ade1515d162def8ab` | Same repository pin; caller/cache/tests, not an installed app or separate release. |

Pins were obtained with `git rev-parse HEAD`, `git -C <Agent-reference> rev-parse
HEAD` and `git -C <Agent-reference>/apps/desktop rev-parse HEAD`. The reference is
outside this isolated worktree and its status was clean. Root and relevant area
instructions were read before tracing. No credentials, board payloads, databases,
workspace contents, service logs or private endpoints were inspected.

Docs map and work checklist:

- [x] Trace the existing board-read receipt to pinned handler/model/caller/tests.
- [x] Separate card bounds/continuation from event-tail and local-cache mechanisms.
- [x] Map owner/revocation outcomes as acceptance criteria, not implemented behavior.
- [x] Inspect the sanitized [Schedules ownership receipt](../runbooks/schedule-search.md#supported-boundary)
  and nearest Wing source/tests without transferring jobs authority to cards.
- Validation and independent review are recorded under [qualification](#validation-and-qualification).

Admission: the coordinator assigned this task/branch. Read-only local execution
metadata records this task running as attempt 2 and `DOC-M4-KANBAN-CONTRACT` closed,
with its committed receipt present in this baseline. The
[continuation ledger](../plans/2026-10-03-desktop-port-goal.md) has no matching
Kanban claim. Initial worktree status was clean despite the interrupted-attempt
notice. These are local admission observations, not a live tracker lease query,
another worker's ownership release or permission to select another task.

## Bounds and continuation: actual contract

| Dimension | Pinned evidence | Missing guarantee / disposition |
| --- | --- | --- |
| Request and response | [Handler][U1]:283–363 accepts board slug, tenant, archived and two workflow filters. It returns columns/tasks, tenants, assignees, event maximum and time. | No `limit`, offset, page cursor, continuation/exhaustion flag, total or snapshot/owner envelope. There is no callable first-page or next-page contract here. |
| Count, bytes and content | [Serializer][U1]:169–193 uses `asdict(task)`; [Task model][U2]:767–813 includes body, result, workspace path, claim and failure metadata. Only latest-summary preview is clipped to 200 characters in the handler. | No server-enforced card count, response-byte bound or bounded secret/path-free metadata projection. Desktop's [narrow TS interface][U3]:1–50 does not filter the wire payload. Clipping after download cannot bound the read or establish completeness. |
| Domain helper | [Store list][U2]:1592–1623 supports an optional internal `limit`; the handler does not pass it. | Not an HTTP pagination parameter or a validated per-page budget. It supplies no continuation, exhaustion or snapshot contract. Do not expose it through a Wing adapter. |
| Ordering and consistency | Store default is `priority DESC, created_at ASC`; the handler sorts done by `completed_at DESC` (nulls last), then ID descending. Task selection and rollup/event SELECTs have no encompassing explicit snapshot transaction in this path. | Queue ties lack an explicit unique tiebreaker. Even done's tie ordering is not a snapshot/continuation fence when tasks move lanes or change priority. No proof of omission/duplicate-free traversal under concurrent change. `now` is time, not a revision. |
| Filters and work bounds | Handler computes board-wide link/comment/progress rollups, diagnostics, distinct tenants/assignees and event maximum, even when task filters narrow the result. | Tenant/workflow/archived filters are not page boundaries or access grants. No bounded server work, related-data bound or filtered snapshot revision follows. |
| Coalescing | [Wrapper][U4]:22–66 keys in-flight work by home and bound arguments, admits one worker per function/event loop and shields running work from caller disconnect. | Deduplicates identical reads only. No row/byte/queue limit, caller-grant identity, board incarnation or cancellation/revocation fence is added. A disconnected read may still finish. |
| Read effects | [Connection helper][U1]:85–100 calls initialization; [DB connection/init][U5]:668–770 can create directories/DBs and run schema/migrations in the ordinary unfenced path. | GET is not a guaranteed zero-write operation. Source-only inspection must not execute it as a supposedly harmless pagination probe. |

### Event continuation is not card pagination

The [event tail][U1]:1683–1807 accepts `since` and selects **at most 200 event
rows** ordered by event ID. It emits event batches with a cursor; without `since`
it starts at the current tail. This bounds event rows per poll, not bytes, card
inventory, historical completeness or server work for `/board`. Event payloads are
not a bounded metadata projection. The board's `latest_event_id` is a tail marker,
not an opaque page token or coherent multi-query snapshot revision.

Desktop [snapshot/cursor logic][U6]:78–138, 230–309 seeds the socket from a cached
or fetched board tail, keys remembered event cursors by connection/slug, and uses
socket generations so a late snapshot cannot reopen an abandoned selection.
[Query keys and fetch][U6]:373–389 remain connection/slug/archived scoped and fetch
the full board. [Page query][U7]:1094–1107 polls every 60 seconds; [rendering][U7]:1381–1404
can retain board data after a refresh failure. These are reference interaction
mechanisms, not card continuation, permission revalidation or same-slug incarnation
proof. No event socket was opened by this task.

## Stale-owner and revocation outcome map

The rows below are **required outcomes for a future eligible Wing read**, not
claims that either client or Agent currently implements a paginated board API.
The [API/state](../adr/api-and-state.md) and
[security decision](../adr/security-and-privacy.md) govern owner fencing. A logical
read owner includes the exact Agent connection/origin, authenticated authority,
explicit profile, board identity/incarnation, Project association/identity and
view filters, plus the local request/selection generation. These are review
concepts, **not invented wire fields or a client-owned authorization catalog**.

| Change while an initial read or hypothetical continuation is pending | Expected outcome | Evidence and absent proof |
| --- | --- | --- |
| Connection/origin/channel replacement, including A → B → A | Invalidate old pending results and continuation; neither late success nor late error may paint, clear pending state, or populate the replacement owner's inventory. Returning to A does not revive the obsolete request. | Desktop [scope guard][U6]:140–162 and connection tests below prevent some outgoing-observer refetches; query keys alone do not establish a whole in-flight lifetime fence. Wing's adjacent jobs generations are not board support. |
| Profile selection begins, changes, or same-name profile is recreated | No old-owner commit or continuation. A later explicit read must re-establish supported profile context and current authority/identity. Do not silently use launch/current profile. | [Plugin mount dependency][U8]:792–803, 927–931 binds [profile home/secret scope][U9]:277–320. That is real scoping, not per-board authorization or an echoed profile incarnation. Desktop board keys do not include a separate profile incarnation. |
| Explicit board changes; ambient current-board selection moves | Discard the old selection's results/continuation. Do not resolve a missing board into another selection or switch the server pointer to recover. | [Resolver][U1]:59–100 returns 400/404 for malformed/unknown explicit non-default slugs; omitted/empty uses ambient selection. Endpoint captures selection before coalescing. Explicit slug routing is necessary but not immutable identity. |
| Same slug removed/recreated while a read is queued or in flight | Old results and any continuation must not attach to the new board. Require authoritative incarnation evidence; a local generation or preflight existence check cannot prove an unseen server replacement. | [Store][U2]:505–523, 624–764 uses path/metadata existence, permits recreation and clears initialization cache on removal; `default` always exists by convention. No expected incarnation is checked/echoed by `/board`. Nearest recreation test covers schema recovery, not HTTP stale-owner rejection. |
| Board's Project association changes/clears; Project disappears/reappears | Invalidate the old Project-associated view/continuation; do not relabel or merge old cards into the new association. Establish current authoritative membership before a new read. | [Metadata handler][U1]:1333–1416, 1445–1465 resolves/annotates Project IDs and permits association changes. Board root is [shared across profiles][U2]:428–485; `/board` neither validates nor filters Project membership. Task `project_id` is nullable; Project annotation is not an ownership/grant fence. |
| Exact operation/grant lost, plugin disabled, auth rejected, or transport disconnected | Stop further reads/continuation immediately; invalidate pending owner and do not expose cached cards as currently authorized. No automatic resumption after same-frame loss/restoration. Fresh explicit intent and eligible authority are needed; already-issued work may finish at the original Agent. | [HTTP gates][U10]:644–727 check requests and can return auth 401 or disabled-plugin 404. No per-board/Project grant is declared in this handler, no authority epoch is bound to its response/coalescing key, and no completion-time revocation recheck is shown in this path. Request-time gates do not prove cancellation of an admitted read. |
| View filter changes, refresh supersedes a read, or an eventual page fails | Never merge across filters/request generations. If an eligible future protocol permits partial inventory, label it partial and stop at its last verified boundary; retry only under the same still-current owner/authority. | Current `/board` is a full read without page boundaries. A successful prefix, client truncation, event silence or a failed refresh cannot establish exhaustion. No partial card-page protocol is available to exercise. |

### Distinct outcomes, without inventing server statuses

- **Unavailable:** missing eligible operation, exact grant contract, safe bounded
  projection or authoritative pagination. This is Wing's current board disposition;
  issue zero board reads rather than synthesizing empty inventory.
- **Denied:** only authoritative authentication/authorization evidence supports it.
  A missing or disabled plugin may also produce 404; generic 404 does not establish
  board deletion, grant revocation or permission to select `default`.
- **Failed/unknown:** network, timeout, malformed/oversized output and server failure
  are not empty or denied. Report only sanitized, bounded failure information; no
  raw paths, task content, credentials or diagnostic payloads.
- **Empty/no match:** only a successful, eligible current-owner read can support
  the claim, scoped to its filters. Never infer it from omitted cards, failures or
  an unimplemented API. Desktop's local no-match rendering is not authorization.
- **Partial/exhausted:** unavailable as authoritative card-page outcomes on this
  route. Any future partial view must say it is partial until the actual Agent
  continuation contract proves exhaustion; no guessed token, offset or full scan.

## Nearest tests and retained receipts: inspected, not run

| Evidence source | What it actually establishes in source | Not established |
| --- | --- | --- |
| [Plugin board tests][T1]:48–110, 157–169 (`test_board_empty`, `test_create_task_appears_on_board`, `test_tenant_filter`) | Bare-router empty columns, visibility and tenant filter cases. | Production auth/profile gates, count/byte limits, pagination or revocation. |
| [Done-order tests][T2]:59–86 | Completion-time order and queue FIFO with deliberately distinct timestamps. | Equal-key traversal, concurrent lane movement, snapshot or exhaustion guarantees. |
| [Read admission][T3]:28–87 | Eight identical blocked GETs share one list call and preserve another HTTP worker. | Bounded rows/bytes/queued callers or owner/grant-loss behavior. |
| [Project tests][T4]:35–120 | Bare-router Project annotation, set/clear association and inheritance by a new task. | Reassociation of existing cards, two-profile collisions, removed/recreated Project or read membership authorization. |
| [Domain board tests][T5]:156–269 | Ambient stale-pointer fallback, recreated DB schema initialization and explicit-board task isolation. | Safe client fallback, same-slug HTTP incarnation checks or a zero-write read. |
| [Plugin-disable test][T6]:77–117 | Mocked request-time middleware blocks a disabled user plugin with 404 and does not call downstream. | A real Kanban in-flight revocation, per-board grants or response-time authority checks. |
| [Desktop connection tests][T7]:28–130 | Connection-specific slug/cache scope and outgoing-observer refetch exclusion. | Same-origin profile/Project/grant change, A → B → A in-flight response rejection or board recreation. |
| [Desktop event tests][T8]:31–152 | Wait for snapshot before socket; cached tail; selected-board late-snapshot socket suppression; no cursor lending between connections. | Card pagination, stale query-cache rejection, same-slug incarnation or revoked authority. |

Wing still has no board caller/model in the inspected `lib/core/hermes/`,
`lib/features/schedules/` or `lib/router/` paths. Adjacent jobs reads use
[exact capability/grant policy](../../lib/core/hermes/channel/hermes_channel_state.dart):264–284,
[connection/profile/selection/request fences](../../lib/core/hermes/channel/api_channel/hermes_api_channel_connection.dart):275–311
and [route owner checks](../../lib/features/schedules/screens/schedules_screen.dart):172–237.
[Schedules tests](../../test/features/schedules/schedules_screen_test.dart):195–264,
424–461 cover late old-owner success/failure and hidden controls on authority loss.
The retained [sanitized receipt](../runbooks/schedule-search.md#supported-boundary)
records same-frame ownership invalidation and zero owner-change reads/mutations.
These are jobs-only source/receipt observations, not newly executed checks or
card-specific coverage. Jobs decoding's
[client-side count cap](../../lib/core/hermes/client/hermes_api_client.dart):190–208
is not server pagination. The Agent's inspected [capability table][U11]:67–103
advertises no Kanban read; do not borrow `tasks:read` or Desktop credentials to
create one.

## Validation and qualification

Validation receipts for this docs-only slice:

- PASS: checkout pins and clean read-only reference; handler → model/store →
  Desktop/Wing caller → nearest tests and sanitized Schedules receipt trace.
- PASS: local offline target/range validator over both changed documents: 31 local
  targets/anchors, 60 pinned upstream citations and 71 attached prose ranges.
  Upstream targets were checked against the pinned checkout, not fetched online.
- Independent fresh-context `reviewer` found no contract/security corrections
  (run `72840a74-a6bb-4b53-bfde-967e6b0a037b`). It confirmed the absent pagination,
  future-only owner criteria and test ceilings; runtime/platform behavior and
  historical admission/action attestations were outside its source-only review.
  The final edit records validation/review outcomes only.
- `git diff --check` is the final whitespace gate before the scoped local commit.

No executable behavior changed, so no new tests or Flutter/browser/upstream test
runs are needed. The offline gate is this source/link/review/whitespace gate, not
runtime testing.

No board requests, mutations, global board/profile switching, task details/logs/
attachments, directory access, service actions, installs or upstream edits occurred.
No Android, web, native desktop, provider or live Agent target was exercised.
No M4 completion, platform support, security audit or remote delivery is claimed.

Pending live, **only after** a suitable unmodified advertised operation and a
separately authorized disposable target exist: bounded initial/continued read,
authoritative empty/partial/exhausted and denial outcomes, revocation during an
admitted read, connection/profile/board/Project replacement (including same-name
recreation), and an accessible target-native journey. These are separate live
qualification, not blockers to recording the absent contract or authority to run
requests now.

Revisit if the handler/model, board/Project lifetime, auth/mount, serialization,
ordering/continuation, Desktop query/socket ownership, or Wing gates change.
Re-pin and re-review the exact operation before implementation; do not patch Agent,
use direct files/DBs, invent a cursor or add a shadow inventory to fill these gaps.

## Pinned upstream sources

[U1]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/plugins/kanban/dashboard/plugin_api.py
[U2]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/kanban_db.py
[U3]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/plugins/kanban/types.ts
[U4]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_read_coalescing.py
[U5]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/kanban_db_connect.py
[U6]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/plugins/kanban/api.ts
[U7]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/plugins/kanban/board.tsx
[U8]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_server_dashboard.py
[U9]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_server_profiles.py
[U10]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_server.py
[U11]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/gateway/platforms/api_server.py
[T1]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/plugins/test_kanban_dashboard_plugin.py
[T2]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/plugins/test_kanban_board_done_order.py
[T3]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/plugins/test_kanban_read_admission.py
[T4]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/plugins/test_kanban_board_project_api.py
[T5]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/hermes_cli/test_kanban_boards.py
[T6]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/hermes_cli/test_plugin_runtime_disable_gate.py
[T7]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/plugins/kanban/api.connection-scope.test.ts
[T8]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/plugins/kanban/api.events-cursor.test.ts
