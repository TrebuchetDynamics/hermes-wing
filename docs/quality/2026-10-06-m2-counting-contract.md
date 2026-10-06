# M2 authoritative restoration mutation counting contract — 2026-10-06

Card: `t_0599745b`. Ledger task: `DOC-M2-COUNTING-CONTRACT`.
Disposition: **authoritative_counts_unavailable** remains mandatory for the proposed
QA observer. Android M2 remains **unverified**. This document resolves the
source-contract prerequisite; it does not implement or qualify an observer.

## Result and evidence ceiling

The inspected unmodified Agent checkout exposes health metrics, exact-run status,
optional run idempotency, native event replay/occupancy and authentication audit
logging. None supplies the required whole-attempt accepted **and rejected**
mutation ledger with complete transport/owner coverage and closed intervals.
A healthy server, unchanged daily total, unchanged transcript, unchanged replay
occupancy or one known run is not proof of zero restoration mutations.

Wing HEAD: `4acdb4e1f51262ccfdca5174776eed1e3ef65188`.
Agent reference HEAD: `158fd638da1629c8e62caf9ade1515d162def8ab`.
The bounded dirty-source fingerprints, not either HEAD alone, bind this analysis:
`.task-evidence/t_0599745b/source-snapshot.json`. This is evidence of that checkout
only. Installed-runtime versions, advertised runtime capabilities, grants and
live counters are **NOT_CHECKED**. Agent source/tests were read, never imported,
executed, patched or used to inspect personal state/databases/logs.

The reference location is the repository's read-only `hermes-agent/` clone.
Desktop and Conduit behavior are not counting authorities and were not inspected
or changed in this slice. Existing unrelated dirty files, retained tester and
shared build/display/fixture resources were left alone. No builds, suites,
network, devices, credentials or inference were used.

The requirement comes from the [Android preflight](2026-10-06-m2-android-preflight.md),
particularly lines 126–135 and 156–178: separate client attempts from server
accepted/rejected operations; cover replacement sessions, alternate transports
and wrong-owner attempts; preserve a continuous authoritative epoch and closed
observation intervals. The [API/state ADR](../adr/api-and-state.md) requires exact
operation/grant/identity admission and prohibits silent mutation replay. This
analysis introduces no new API, grant, transport or domain authority.

## Existing surface trace

All code citations below are repository-relative. Tests are inspection evidence,
not new test passes. Absence claims are bounded to these concrete registries,
handlers and callers, not all possible deployments, plugins or Agent surfaces.

| Candidate | Advertised/registered gate → auth → handler/output | Counting guarantee and precise limitation |
| --- | --- | --- |
| HTTP health | `hermes-agent/gateway/platforms/api_server.py:67–102` advertises `health_detailed` as `GET /health/detailed`; `_http_route_table` at lines 1745–1754 registers it; `_require_auth` at lines 989–996 calls `_check_auth`; `_handle_health_detailed` at lines 2456–2499 returns live adapter metrics plus runtime readiness/platform metadata | `metrics_today` has `day`, `requests`, `messages`, `tokens`, `latency_p95_ms`. `api_server` includes active/stored run gauges and request/heartbeat timestamps. Not a classified attempt ledger. Full response is not a bounded metadata-only M2 receipt: it also includes host/port, PID and runtime platform fields; no M2-specific payload cap or closed-window cursor. Do not collect the raw response into QA evidence. |
| HTTP run status/idempotency | Same capability table names `runs`, `run_status`, `run_events`, `run_stop`, `run_approval`; `hermes-agent/gateway/platforms/api_server_runs.py:234–248` registers the run routes and advertises idempotency properties; exact-owned status path at lines 1023–1061 | Exact run execution/ownership status, optionally durable for keyed submissions, is useful recovery evidence after separate admission. No read enumerates accepted/rejected operations across the whole attempt. Status can include output/error/usage; not a safe raw metadata receipt. Durable reservation scope is not a counting epoch. |
| Native replay occupancy | `hermes-agent/tui_gateway/contracts/sessions.py:734–750` declares `session.events.stats` with `ProfileParams` and six integer result fields; `hermes-agent/tui_gateway/methods_session.py:2601–2605` registers and calls `event_replay.replay_stats()` | `sessions`, `events`, `bytes`, `max_per_session`, `max_bytes_per_session`, `max_bytes_process` are process-wide retained ring occupancy/caps. Handler does not use profile/session/run/device/credential parameters to filter counts. There is no mutation classification, rejection count, interval or epoch in this result. |
| Native replay watermark | `hermes-agent/tui_gateway/contracts/sessions.py:721–731` declares `session.events.since`; `hermes-agent/tui_gateway/methods_session.py:2584–2598` returns frames, latest sequence, truncation, count, epoch and open requests for a session | Epoch identifies in-process event sequence numbering, not an accepted/rejected operation ledger. Outgoing events only; no complete incoming mutation/rejection recording. Session-only replay misses replacement sessions, other profiles/transports and sessionless operations. Frames/open requests can contain sensitive content; do not log them as metadata. |
| Authentication audit | `hermes-agent/hermes_cli/dashboard_auth/audit.py:24–66` defines login/session/ticket/token events and appends JSON lines; WS auth producer `hermes-agent/hermes_cli/web_server_chat.py:269–365` emits selected accept/reject events | Authentication events, not domain-operation accounting. Best-effort writes swallow write failures after a warning; no completeness, sequence, closed interval, bounded count read, per-attempt alias or continuous epoch. Carries user/IP/path fields; personal logs are excluded, not a fallback observation source. |
| Shared metrics / diagnostics | `hermes-agent/tui_gateway/contracts/config_free_tier_control.py:225–239` declares `shared_metrics.status`; `hermes-agent/tui_gateway/methods_shared_metrics.py:37–45` reads consent. `hermes-agent/tui_gateway/contracts/config_free_tier_control.py:158–178` declares `diagnostics.share_nous`; `hermes-agent/tui_gateway/methods_config.py:504–539` collects/redacts/uploads a debug bundle | Shared-metrics status returns `enabled/send/decided`, not operation counts. Diagnostics is an upload action with an `ok`/URL/id/expiry/error envelope, not a local read-only ledger; bounded bundle inputs do not create mutation completeness. Neither may be invoked for this task or used to infer zero replay. |

### HTTP daily metrics are not admission counters

`hermes-agent/gateway/platforms/api_server.py:1286–1293` initializes per-adapter
in-memory daily metrics to zero. Lines 1412–1420 reset them at UTC day rollover;
1439–1456 construct the snapshot. `_record_api_metrics` at lines 1466–1475 adds
one request/message and usage tokens, bounds latency samples to
`API_SERVER_LATENCY_SAMPLE_LIMIT` (512), then publishes status.

The decisive producers are:

- `hermes-agent/gateway/platforms/api_server_runs.py:952–996`: recording happens
  after the structured run's worker returns, before terminal result classification.
  Early stop/shutdown returns and exception paths do not record that completion.
  Consequently even an accepted run can be absent from the daily total while
  running, or after an early/exceptional outcome. A run that completes while Wing
  is absent can increase it without any restoration mutation.
- `hermes-agent/gateway/platforms/api_server.py:4370–4380`: the shared `_run_agent`
  path records only when usage is returned. OpenAI-compatible and session-chat
  routes in `_http_route_table` at lines 1769–1776 are distinct submission paths;
  this aggregation does not label them separately.
- `_admit_api_agent_request` at
  `hermes-agent/gateway/platforms/api_server.py:956–979` rejects bad auth/draining
  before handler dispatch; `_handle_runs` at
  `hermes-agent/gateway/platforms/api_server_runs.py:620–688` can reject parse,
  input, selection, idempotency or capacity before executing any worker.
  `_handle_create_session`, Stop and approval handlers do not call the metrics
  recorder at their mutation boundary.

Nearest tests:
`hermes-agent/tests/gateway/test_api_server.py:333–362` asserts completed buffered
runs are not active and explicitly calling the recorder increments/publishes
metrics. Lines 826–861 assert detailed health serialization after explicitly
recording usage. Lines 937–972 check discovery and durable/in-memory idempotency
advertisement. These are not acceptance/rejection or closed-window ledger tests.

### Identity, authorization, bounds and epoch matrix

| Dimension | Actual inspected contract | M2 accounting implication |
| --- | --- | --- |
| HTTP credential/profile | `hermes-agent/gateway/platforms/api_server.py:1562–1608` resolves URL-selected profile key and constant-time Bearer validation; lines 1720–1743 reject unknown prefixes and bind profile scope. Health/capabilities use API-key auth, not named-device per-operation grants. | A profile-scoped credential authorizes a read but does not make adapter-global metrics per-profile/per-device/per-attempt. No origin, session or run identity is returned with daily accounting. The URL/TLS peer is origin authority, not a counter binding. |
| Run grants/owner | `hermes-agent/gateway/platforms/api_server_runs.py:352–381` uses API key or room-grant permission (`dispatch/status/stop/approve`). Scope hashes profile/key, or room/home/authority/authority-epoch/member/target-install/target-profile claims. Lines 1023–1054 require exact run ownership; foreign/ownerless runs return 404. `hermes-agent/gateway/platforms/api_server_room_grants.py:91–108` validates signed permission/horizon plus revoked/current grant state. | These are authorization namespaces, not observer identity/coverage acknowledgements. No Wing device ID or whole disposable-credential attempt ledger is supplied. Room authority epoch is not a mutation ledger epoch. A denied wrong-owner operation leaves no ledger count in these reads. |
| Run retention/durability | `hermes-agent/gateway/platforms/api_server_run_idempotency.py:53–84` implements optional keyed reservations, 24-hour retention and an advertised in-memory fallback. `hermes-agent/gateway/platforms/api_server_runs.py:395–418` hydrates owned records and marks stale nonterminal owners interrupted. Ordinary terminal status/stream TTLs are 3600/300 seconds at `hermes-agent/gateway/platforms/api_server.py:4385–4386`. | Durability is conditional and bounded, not an exhaustive append-only history. Missing run is not a zero-mutation receipt. Do not transfer idempotency to native RPC or unkeyed/other-route submissions. |
| Native credential/origin | `hermes-agent/hermes_cli/web_routers/chat_ws.py:139–151` gates enabled chat, WS auth and host/origin/client allowance; lines 595–613 pass server-authenticated identity into WS transport. `hermes-agent/hermes_cli/web_server_chat.py:250–374` covers gated single-use ticket/internal/provider-verified session auth and legacy mode. `hermes-agent/tui_gateway/ws.py:1–4` shares the stdio RPC dispatcher. | Authentication at transport admission is not operation-specific counting authority. No M2 observer grant is declared. No new credential acquisition or unsafe query-token use is recommended; deployed native auth remains separately admitted, NOT_CHECKED here. |
| Native registry/handler | `hermes-agent/tui_gateway/server.py:882–893` registers handlers; `hermes-agent/tui_gateway/rpc_dispatch.py:17–42` normalizes, selects contract, validates params and dispatches. Stats handler has no `_profile_scoped` decorator and uses process globals. | A `profile` field in the schema does not imply a per-profile count. Generic RPC errors and server-request responses are not a classified mutation ledger. |
| Native bounds/epoch | `hermes-agent/tui_gateway/event_replay.py:22–35` assigns a random process epoch and caps replay at 512 events/session, 64 retained sessions, 4 MiB/session and 64 MiB/process. Lines 67–128 stamp outgoing session events, discard oversized frames and evict FIFO; lines 168–178 return occupancy. | Eviction makes occupancy nonmonotonic. Epoch changes on process restart and says nothing about HTTP counts or mutation rejection. Even an untruncated ring is not complete operation coverage. No atomic closed interval spanning submission/death/relaunch exists in these APIs. |

Native nearest tests:
`hermes-agent/tests/tui_gateway/test_tui_gateway_event_replay.py:119–189` assert
bounded occupancy, FIFO eviction, sequence monotonicity and truncation—not domain
mutation completeness. WS credential tests at
`hermes-agent/tests/hermes_cli/test_dashboard_auth_ws_auth.py:265–317` assert
legacy/invalid/expired credentials fail and verified identity succeeds.
`hermes-agent/tests/hermes_cli/test_dashboard_auth_audit.py:26–55` checks JSON lines
and token-field stripping, not reliable mutation accounting. No test ran here.

## Required operation coverage versus available evidence

Each row needs two separately classified authoritative integers (accepted and
rejected), not merely the indicated outcome or client-observed attempt. All
required count pairs below are **UNSUPPORTED by the inspected counting reads**.

| Required class | Existing outcome seam / nearest evidence | Why zero cannot be inferred |
| --- | --- | --- |
| Deliberate submission and run starts | Auth/admission wrapper → `_handle_runs` → `_execute_run`; `hermes-agent/tests/gateway/test_api_server_runs.py:1447–1558` tests invalid/capacity rejection without consuming a key, duplicate reuse and changed-payload conflict | Daily metrics record worker returns, not arrivals/acceptance/rejections. Key reuse can prevent duplicate execution without recording a second attempted mutation. No whole-attempt total. |
| Session creates, including replacement session | `hermes-agent/gateway/platforms/api_server.py:3145–3191` authenticates, validates then atomically inserts. Separate advertised `POST /api/sessions`; native `session.create` is a different transport | No accepted/rejected session-create fields in health/stats. A run-specific filter misses a new session entirely; this slice does not qualify native session-create accounting. |
| Chat/completion sends | HTTP registry lists session chat, stream, completions and responses; native `prompt.submit`/server-request responses use the RPC transport | Shared HTTP worker usage may increase one daily aggregate; no per-route count or rejected-send count. Native RPC/stdio is not included by these HTTP recorder call sites. |
| Stop | `hermes-agent/gateway/platforms/api_server_runs.py:1253–1274` owned grant check, terminal no-op, inactive rejection or provisional stopping status | Terminal no-op still represents a restoration mutation attempt. No accepted/rejected Stop counter; returning completed status does not prove Stop was never requested. |
| Approval responses | `hermes-agent/gateway/platforms/api_server_runs.py:1168–1216` checks owner/approve grant, exact request/choice/scope, resolves pending request, emits `approval.responded` only after success | Success event is not complete rejected-attempt accounting; expired/wrong requests and malformed choice return early. Native server-request response frames take a separate path at `hermes-agent/tui_gateway/rpc_dispatch.py:53–58`. |
| Wrong owner, wrong profile, denied credentials | `hermes-agent/tests/gateway/test_api_server_runs.py:1207–1248` tests ownerless and foreign run get/Stop 404; grant approval restrictions at lines 1957–1989; HTTP key validator returns 401 | Authorization tests prove denial conditions in fakes, not presence of an authoritative rejection counter. No observer may turn auth/network/404 failure into zero. |
| Unknown non-read operations / alternate transports | HTTP route table includes PATCH/DELETE/fork/model and other actions; WS/stdio uses its own handler registry | Neither inspected read classifies all non-read methods or records unknown/rejected operations. Outgoing events/session history are not exhaustive incoming operation ledgers. Replacement tuples must remain visible to counting even when expected-run history matches. |

## Wing caller and predecessor boundaries

- `lib/core/hermes/channel/api_channel/hermes_api_channel_connection.dart:51–68`
  reads discovery and gates optional detailed health on exact advertised operation.
  `lib/core/hermes/client/hermes_api_client.dart:58–71` implements these reads.
  `lib/core/hermes/models/hermes_health.dart:30–44` parses status/readiness/platform
  state, not `metrics_today` or a mutation ledger. Existing Wing health handling
  therefore does not already expose the proposed counter source.
- `lib/core/hermes/client/hermes_api_client.dart:355–438` sends scoped run start,
  reads status, subscribes events, responds approval and stops. `startRun` does
  not supply an Idempotency-Key here; no optional upstream durability guarantee
  should be silently attributed to it.
- `lib/core/hermes/channel/api_channel/hermes_api_channel_messaging.dart:2092–2182`
  reconciles the exact endpoint/profile/session/run, validates run/session IDs,
  hydrates canonical history before removing terminal leases and retains uncertain
  ownership. These are recovery outcomes, not an independent counting authority.
  Its 404 lease policy is not accepted completion/count evidence for the future
  death-to-completion scenario.
- `lib/core/hermes/client/hermes_web_lifecycle.dart:197–253` treats native epoch and
  replay as reconciliation watermarks; no stats/count read supplies M2 coverage.
  `lib/core/hermes/client/hermes_web_read_rpc.dart:36–59` exposes fixed ping/list
  reads, not a general diagnostic RPC bridge.
- `scripts/qualify_hermes_web_lifecycle.py:120–137` allowlists lifecycle assertion
  booleans and typed failures. It is not an authoritative ledger. Do not run it
  or borrow its authentication/runtime resources for this source task.
- The [deterministic death-completion oracle](2026-10-06-m2-death-completion-oracle.md)
  counts every intercepted fixture method using `runStarts/sessionCreates/otherMutations`:
  `test/features/hermes_chat/screens/hermes_chat_death_completion_recovery_test.dart:66–81`
  and lines 434–445. Those fixture counts remain legitimate fixture evidence only.
  They cannot establish accepted/rejected server counts on an unmodified deployment.
  Historical predecessor test/analyzer receipts were not rerun or promoted to a
  current runtime pass; no full import-closure or package equivalence claim is made.

## Practical next-step disposition

Keep `authoritative_counts_unavailable`; do not build a purported live M2
counting adapter out of these reads. The exact missing contract is an existing,
separately admitted metadata-only authoritative operation that supplies:

1. Exact operation/schema and required authorization, with server-owned binding
   to the whole disposable attempt/credential and explicit owner dimensions.
2. Accepted/rejected counters for every class above, including wrong/replacement
   owners and alternate transports; unknown mutation and incomplete coverage fail.
3. Continuous ledger epoch, complete-coverage evidence and atomic closed-window
   boundaries across death/relaunch, with explicit reset/loss/error behavior.
4. Bounded integers/records/bytes and safe alias-only output without content,
   raw identities, credential material or private endpoints/host paths.

None of those complete guarantees is supplied by the inspected candidate schemas.
A separately authorized offline admission pass may examine an already-existing
contract in the selected unmodified deployment if one is advertised, without
assuming this checkout describes it. Until admitted, the planned observer may
only refuse live counting qualification; fixture validation is still fixture
validation. If no such existing source is available, leave the zero-mutation
Android acceptance criterion unverified. Do not patch Agent, invent endpoints,
add shadow server state, tail personal logs, proxy through Wing Link, or relax
accepted/rejected coverage. Exact-run status/history may later be admitted for
their narrower recovery guarantees; that does not admit the counting requirement.

The future [named-device scenario](2026-10-06-m2-continuity-baseline.md#exactly-one-future-scenario-android-m2-death-complete-01)
remains unchanged. Devices, live counters, live M1, process death, keystore,
notification denial, expiry/revocation, packaged runtime, APK/entrypoint identity,
build/install, push and provider inference are **NOT_CHECKED**. No import or
packaging edit occurred; source fingerprints do not qualify runtime delivery.

## Acceptance evidence and executed checks

Task-owned evidence lives under `.task-evidence/t_0599745b/`:
`check_contract.py`, `source-snapshot.json`, `handoff.json`, `validation.json`.
Executed offline from the Wing repository:

```text
python3 .task-evidence/t_0599745b/check_contract.py snapshot
python3 .task-evidence/t_0599745b/check_contract.py verify
```

Snapshot exited 0, binding 46 explicitly selected source/requirement/ledger files
and both checkout revisions. Verification checks local links/anchors, source-line
ranges, sanitized JSON receipts, unchanged fingerprints/revisions, shared ledger
bytes and task-owned whitespace. Exact totals and document SHA-256 are in
`validation.json`; these are document-integrity results, not Android passes.
The first verification exited 1 because the secret-pattern check matched
`sk-evidence` inside the task-owned directory name. Requiring a word boundary
for the key prefix corrects that false positive without permitting actual key
values. The corrected checker was rerun; `iteration.json` retains the failure
classification and the sanitizer's positive/negative controls.
The checker also executes:

```text
git diff --no-index --check /dev/null docs/quality/2026-10-06-m2-counting-contract.md
git diff --check -- docs/quality/2026-10-06-m2-counting-contract.md .task-evidence/t_0599745b
```

A no-index exit 1 with empty diagnostics means added-file difference, not a
whitespace failure; tracked scoped whitespace check must exit 0. The verifier
fails on any diagnostic, stale fingerprint, broken link/range or unsafe JSON.

| Acceptance item | Delivered evidence |
| --- | --- |
| 1. Contract, grants, identity, bounds, epoch, full mutation-class coverage | Existing surface/identity/coverage matrices above; exact handler/registry/caller/nearest-test ranges; 46 scoped hashes and checkout revisions. Precise unsupported guarantees, not synthetic live totals. |
| 2. One practical permissible disposition, no authority expansion | `authoritative_counts_unavailable` and narrowly scoped future existing-contract admission above; Android/runtime NOT_CHECKED; no observer, new route or Agent/Wing Link change. |
| 3. Actual offline checks and safe ledger handoff | Snapshot/verify commands and receipts; local completion handoff for repo-docs; native same-card review requested only after worker checks. Independent review remains the native lane's responsibility, not asserted here. |

`goals.py next` was used read-only and returned this task `in_progress`, M2
`unverified`. The selection/preflight reserves shared ledger writes for repo-docs
job `ba15b4ed8db6`; no release was observed. No shared task/evidence mutation or
TODO render ran. `handoff.json` records local slice completion for its next pass:
close only this documentation task while retaining unverified M2 and representing
remaining Android qualification. Never record document-integrity passes as M2
executed acceptance; the helper may otherwise auto-promote all-done goals.

No commit, stage, branch or index mutation ran. The card's acceptance paragraph
requests an agent commit but its later explicit execution contract prohibits
commits; the reversible default is an uncommitted review artifact, with commit
publication held rather than assuming permission. Branch/SHA for a new commit:
**NOT_CREATED**. Native review, not a replacement card, is the next lifecycle step.
No owner questions are necessary for this bounded source result.
