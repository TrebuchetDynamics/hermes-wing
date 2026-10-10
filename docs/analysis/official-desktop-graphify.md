# Official Desktop Graphify analysis

Status: fresh structural graph verified; connection and shell/chat source reviews delivered. The first bounded Wing SSH request refactor is implemented and parent-verified with 52 targeted passing tests and a nine-file format check. Whole-app revamp and native parity remain unfinished.

## Source and scope

Repository: [Nous Research Hermes Agent](https://github.com/NousResearch/hermes-agent/tree/main/apps/desktop).
Committed revision: `158fd638da1629c8e62caf9ade1515d162def8ab`.
Scopes: `apps/desktop`, `apps/shared`, `tui_gateway`.
A Git archive provided immutable committed inputs. Binary assets, packaging, build directories and ignored/untracked files were excluded. No upstream files were changed.
The snapshot is not a claim of latest live main or released behavior.

## Executed extraction

Graphify `0.9.80`, code-only extraction with two workers and no semantic or model-label pass.
The selected manifest contains 3,736 source/manifests/documentation files; the extractor processed 3,709 code files. It reported 436 code files with no extracted symbols. Empty extraction is not complete semantic coverage.

Serialized graph:

- 31,246 unique nodes.
- 109,393 relationships: 106,185 `EXTRACTED` and 3,208 `INFERRED`.
- All relationship endpoints resolve to serialized node IDs.
- Snapshot and selected upstream file hashes matched the retained manifest after extraction.
- Schema version 1. JSON, report and HTML artifacts are nonempty.
- Clustering's loaded graph reported 104,913 edges. That is not substituted for the serialized relationship count.
- HTML is an aggregated view of 554 communities and 4,653 cross-community edges, not a full node-level browser render. Offline rendering was not qualified.

Artifacts are local under `.task-evidence/official-desktop-graphify/`: `source-manifest.json`, `graph-receipt.json`, extraction/cluster/query logs and `map/graphify-out/{graph.json,GRAPH_REPORT.md,graph.html}`.
The interrupted build had already completed extraction. With no remaining Graphify process, clustering was resumed separately using `graphify cluster-only ... --no-label`; it exited 0. The original wrapper did not return a captured success status, so it is not reported as a passing full-wrapper run.

## Graph traversal checked against source

`graphify explain JsonRpcGatewayClient --graph ...` found the class in `apps/shared/src/json-rpc-gateway.ts`, plus Desktop imports, inheritance, replay and heartbeat test relationships.
An ambiguous short-name path was rejected. Retrying with exact node IDs returned:

`requestGatewayForAgent()` ← contains ← `gateway.ts` → imports → `HermesGateway` → inherits → `JsonRpcGatewayClient`.

Source inspection of `apps/desktop/src/api/client.ts` confirms the shared import and `HermesGateway extends JsonRpcGatewayClient`. It also defines profile/connection request scope for REST settings. Thus the official architecture is not simply all-REST or all-JSON-RPC. Each operation must be traced to its actual authority and transport.
The broad connection query was truncated and selected test symbols as starting nodes; it is discovery only, not proof of a complete connection path.

## Bounded knowledge study and planning consequences

The follow-up report is retained at
`.task-evidence/official-desktop-knowledge/REPORT.md` with `receipt.json` and query
logs. Those ignored files are optional evidence, not fresh-checkout dependencies.
This section preserves their useful findings in maintained documentation.
The study used the same pinned revision and code-only graph above. Its receipt
reports fresh source-hash verification and successful graph queries, not upstream
test execution or runtime qualification. The extracted inheritance edge is not
proof of an end-to-end request lifecycle.

Source paths below are relative to the read-only `hermes-agent/` checkout:

- Bootstrap: `apps/desktop/src/main.tsx` initializes i18n, query and platform
  wiring. `src/app/index.tsx` delegates shell composition to the contribution
  controller. Controller imports identify seams; deeper behavior is not traced.
- Pane reactivity: `apps/desktop/src/app/contrib/surfaces.tsx` scopes subscriptions
  to sidebar, terminal and status surfaces. Keep Wing provider subscriptions near
  the affected pane; add a regression before claiming unrelated panes avoid rebuilds.
- Ownership: `apps/desktop/src/store/gateway.ts` routes by connection and normalized
  profile, matches primary ownership and releases secondary request leases in
  `finally`. Preserve endpoint/profile ownership rather than visible selection alone.
- Replay: `apps/shared/src/json-rpc-gateway.ts` handles timeout/abort, disconnect,
  incoming requests, monotonic session sequences and live-event holding during replay.
  Trace its callers before implementing equivalent Dart behavior.
- Acceptance leads: `apps/desktop/src/app/session/hooks/warm-resume-replay-barrier.test.tsx`
  covers warm activation, socket loss, cold resume, REST races and background refresh.
  These assertions were inspected, not executed or translated into Wing tests.
- Stop: `apps/desktop/src/app/session/hooks/use-prompt-actions/index.ts` clears
  pending interaction UI and interrupts the captured session, with success/failure
  recovery. Local UI cleanup is not authoritative cancellation.
- Expired approvals: `apps/desktop/src/app/session/hooks/use-message-stream/gateway-event/input-requests.approval-timeout.test.ts`
  supplies timeout explanation and settings-action scenarios. Do not leave an
  expired request operable; qualify each supported transport separately.
- Launch: `apps/desktop/electron/backend-serve-support.ts` probes installed runtime
  support and narrowly falls back for legacy installs. Do not infer permission for
  generic CLI operations or personal service changes.

The next useful vertical trace is send → stream → input request → Stop → disconnect
→ resume, with connection/profile/durable/runtime/lineage identity kept distinct.
Use the [daily-use plan](../plans/2026-10-03-desktop-daily-workflow.md#official-lifecycle-source-trace)
and existing connection, matrix and tabs tasks, not a duplicate research backlog.
Settings persistence, native IPC authorization, update rollback, profiles, Projects,
tool rendering, slash dispatch, contribution loading, keyboard/focus and accessibility
still require deeper semantic reading. These are coverage gaps, not missing-feature
claims or blanket parity results.

Wing Link remains deprecated and is not required by this port. The report's
retained management-boundary wording does not reverse the current product decision.
Agent remains authoritative and immutable; Wing owns native client integration.

## First architectural increment

The existing Wing SSH controller imports its submission model from the form widget. This couples connection orchestration to presentation.
The implemented refactor moves that ephemeral request to `lib/core/hermes/ssh/ssh_connection_request.dart`, uses `SshConnectionRequest`, and makes the controller entry explicit as `connectSsh`. The production form/panel and callers migrated together. No compatibility alias, protocol-field rename, new backend or automatic runtime mutation was introduced.
Behavior tests must retain key/password forwarding, separate Agent authentication, explicit host review, cancellation and secret cleanup. The request representation must redact secrets and private target data.
This is an idiomatic Flutter counterpart to the official machine/renderer/backend separation, not a claim that its type has the same wire shape as an upstream request.

## Remaining review and qualification

Connection/auth/lifecycle and shell/chat/session source reviews are retained as ignored evidence in `connection-analysis.md` and `shell-chat-analysis.md` beside the graph manifest. Parent recomputed all their selected upstream hashes successfully; the Wing SSH controller hash changed as expected with the request refactor. Selected shared heartbeat constants and official overlay routing were independently read back. These remain bounded source observations, not executed upstream tests.

The ordered architecture work is: qualify the existing native transport against headless serve; preserve explicit connection/profile and stored/runtime session identities; compose chat-preserving route overlays; then adapt composer, approvals and multi-session workspace behavior. Production REST/SSE is not automatically switched or renamed into JSON-RPC compatibility. Official Stop uses `session.interrupt`; this does not change the existing REST channel's advertised run cancellation operation. The internal native lifecycle now processes official event-envelope `request.cancel` while idle, removes only the matching owned approval, and refuses a response to the withdrawn request. Parent executed the three native read/lifecycle targets: 50 tests passed; `flutter analyze --no-pub` passed; two changed files passed formatting and scoped whitespace checks. These are deterministic loopback-fixture results, not live Agent/native auth qualification. Earlier full-suite attempts timed out and remain incomplete. Production routing is unchanged.

Settings and Profiles now use nonopaque, modal workspace overlays from shell navigation and all three chat-local command/Manage callers. Close/Back/Escape returns to the retained chat; direct deep links retain normal disconnected entry behavior. Parent verified 79 initial router/shell tests and inspected compact/wide widget renders. Follow-up integration passed 35 overlay/auth tests and 54 profile-picker/open-order tests. The profile tests now inspect the mounted route rather than the unchanged underlying imperative navigation URL. This is widget-level behavior, not browser URL/history or native qualification.

The pre-follow-up full `npm run test` exited 1: 3,845 passed, 8 skipped, 13 failed. The stale Local/setup interactions and Profiles modal semantics were repaired without weakening auth or mutation assertions. The shared Local journey fixture was updated instead of retaining a duplicated test-local implementation. Final integrated `npm run test` exited 0: 3,866 passed, 8 skipped, 0 failed. The 24 changed source/test hashes matched before and after that run; this is not a whole-worktree stability claim. Parent analysis, 105 affected tests, scoped formatting and whitespace checks passed. Whole-app architecture revamp, official transport production adoption, native device qualification and visual parity remain unfinished.
No upstream tests, live Agent generation or Android/native platform behavior ran as part of graph extraction. The graph does not establish parity, runtime support, UI fidelity or successful migration to the official JSON-RPC contract.
