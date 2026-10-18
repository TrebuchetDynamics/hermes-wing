# M4 schedule pause/resume: authoritative contract trace

Task: `DOC-M4-SCHEDULE-CONTRACT`. **Offline source evidence only; no operation
activated and no native/live qualification.** Start with the unchanged
[read-only inventory receipt](schedules-inventory-evidence.md),
[route status](../product/routes.md) and [API/state boundary](../adr/api-and-state.md).

## Verdict and inspected identities

Agent implements pause/resume, including the official Desktop Routines switch's
`cron.manage` RPC. Handler existence is **not** a Wing capability or write grant.
The inspected messaging API advertises neither jobs inventory nor pause/resume;
the RPC has no exact schedule-write grant, expected revision or durable idempotency
receipt. **Keep Wing's schedule mutations unavailable and its inventory read-only.**
M4-SCHEDULES remains partial. This is a contract gap, not a request to modify Agent.

Pins obtained with `git rev-parse HEAD` in Wing and `git -C <reference> rev-parse HEAD`
in Agent and its `apps/desktop/` subtree:

| Source | Inspected revision | Meaning |
| --- | --- | --- |
| Wing baseline | `165d75ecaf6218b58c158912a1456b8eadf7d1b6` | Current caller/model/test trace below. |
| Read-only Agent reference | `158fd638da1629c8e62caf9ade1515d162def8ab` | Source and tests, not a running/installed target. |
| Official Desktop subtree | `158fd638da1629c8e62caf9ade1515d162def8ab` | Same repository/commit, not a separate release. |

The coordinator assigned this isolated task branch. Its local execution status
listed this task as running; the continuation ledger contained no matching task
claim. This is not external tracker lease release, integration or later-operation
authority. No credentials, personal runtime state, service startup, network calls,
job execution, delivery configuration or generic CLI fallback were needed.

Docs map: preserve the existing inventory evidence; add this one mutation-contract
slice over Desktop caller → Agent RPC/model → tool/domain store → nearest tests,
and compare the messaging HTTP surface and current Wing caller. No product-status,
ADR, runtime or test changes are made.

## Exact Desktop operation and Agent authority

The selected outcome is **pause an existing owner's routine without deleting it**;
resume is its inverse, not Run now. Official Desktop's [`RoutineRow`][D1]:490–598
renders the switch from server `enabled`/`state`, overlays pending state, disables
while busy (and for legacy-unsafe jobs), and sends once through `requestForBot`:
`cron.manage` with `action: 'pause'` (or `'resume'`), `name: job.job_id`, and the
captured owner's explicit `profile`. It invalidates that owner's query after the
RPC resolves; a rejected promise clears the overlay and reports failure.
[`requestForBot`][D2]:217–258 routes connection-qualified owners through
`host.requestProfile`, refuses a missing routed transport, otherwise uses
`host.request`, and normalizes rejected errors. This is client routing/cache
behavior, not server concurrency or durable replay protection. In particular,
this row/routing path does not itself inspect a resolved tool-level `success:false`
result; transport resolution alone must not be copied as persistence success.

| Boundary | Verified pinned contract | Guarantee unavailable to Wing |
| --- | --- | --- |
| RPC input | [`CronManageParams`][A1]:416–434 declares `cron.manage`, `action` enum including pause/resume, `name` and optional `profile`. Other fields support other actions. [`handler`][A2]:1393–1417 forwards pause/resume as `cronjob(action=action, job_id=name)`. | No required caller/device/grant identity, expected job/profile revision or idempotency key in this input. The misleadingly named `name` can carry an ID; Wing must not invent wire fields. |
| Transport admission vs grant | [`/api/ws` entry and pre-accept guard][A3]:139–151,595–613 require enabled chat, authentication and allowed request; [request/auth helpers][A4]:197–204,377–379 enforce host/origin/client and credential checks. [`RPC dispatch`][A5]:17–42 resolves the registered method and validates params. | Neither this cron handler/model nor that dispatch declares a schedule-specific caller grant. This is not a claim that `serve` is unauthenticated, nor a complete transport security audit. Messaging bearer capabilities and RPC admission are different contracts. |
| Profile identity | [`_profile_scoped_rpc`][A2]:20–73 binds home + secret + terminal scope around this sessionless handler. [`_profile_home`][A6]:567–587 resolves explicit names, rejects a missing home (`4064`), and treats omitted/blank scope as the launch profile. | Names/homes are not profile-incarnation tokens; no expected incarnation is checked. Wing must retain explicit current owner identity, not depend on ambient launch scope or global selection. |
| Job identity | [`cronjob`][A7]:955–1041 first resolves the supplied reference. [`resolve_job_ref`][A8]:1963–1984 prefers exact ID, otherwise case-insensitive name, rejecting ambiguous names. Desktop passes `job_id`, not display text. | There is no incarnation or expected revision check. A fresh lookup/name match is not stale-edit protection; do not substitute a Wing-owned job catalog. |
| Pause commit | [`pause_job`][A8]:2152–2163 resolves the job then calls `update_job` with `enabled=false`, `state=paused`, a fresh `paused_at`, and `paused_reason` (default `None`; this RPC does not forward a reason). [`update_job`][A8]:2110–2149 merges into the current row, clears pending occurrence state for lifecycle rewrites, saves and returns the normalized row. | Pause is schedule state, not cancellation of already-running work. No Stop/rollback guarantee is established. A repeated pause changes its timestamp and may overwrite an intervening resume; it is not an original-request receipt. |
| Resume commit | [`resume_job`][A8]:2165–2203 clears pause markers, sets `enabled=true`, `state=scheduled` and computes `next_run_at`; an elapsed recurring slot stays due, otherwise it recomputes. An expired one-shot beyond the grace window raises `ValueError`. | Resume may make work due; it is not an inert UI toggle or a promise of execution/delivery. Repeated resume can recompute timing. No permission to activate it, trigger a job or handle delivery credentials follows from this trace. |
| Concurrency/persistence | [`_with_job`][A8]:1626–1637 loads and mutates under `_jobs_lock`; [`save`][A8]:1548–1621 stages/fsyncs and atomically replaces the store. [`lock`][A8]:285–335 combines RLock and file lock but explicitly degrades to in-process locking on missing backend/timeout/error. | Atomic file replacement is not compare-and-set. Pause/resume resolve (and resume calculates timing) before the update critical section. No expected revision is checked with commit; concurrent stale intent may win. Store-level `updated_at` is not a returned/checked edit revision. Do not claim unconditional cross-process serialization. |
| Result/errors | [`_job_state_result`][A7]:741–743 notifies the provider and returns `success:true` plus a [formatted row][A9]:476–526. Tool failures return `success:false`/`error` inside the RPC result; other wrapper exceptions use `5023`. Missing method/invalid params are `-32601`/`4000` at dispatch. | The result is not a durable request-status receipt. A response loss after save remains unknown; later readback shows current state, not attribution to the lost request. No automatic reconnect replay or transport fallback. Rows/errors can contain prompt preview, endpoints, paths and diagnostics; never render/log raw payloads or treat this as a bounded secret-safe receipt. |

The inspected input, handler, tool and store supply no durable request-key ledger,
changed-payload replay rejection, crash-safe response recovery or authorization-
bound receipt retrieval. JSON-RPC `id` correlates a response; it is not such a key.
Run-submission idempotency on another transport does not transfer to schedules.

## Messaging HTTP surface: implemented is not advertised

[`api_server.py`][H1]:1780–1787 registers
`POST /api/jobs/{job_id}/pause` and `POST /api/jobs/{job_id}/resume`.
The handlers at 3979–3985 share `_job_lookup_or_mutate`/`_job_response`
(3872–3886): authenticate first, require cron availability, validate a 12-character
lowercase hex job ID, invoke `_cron_pause`/`_cron_resume`, notify the provider,
and return `{"job": ...}`; missing jobs yield 404, invalid IDs 400, unavailable
cron 501, caught exceptions a redacted 500. These action handlers read no request
body, expected revision, `If-Match` or idempotency key. The [bearer check][H1]:1562–1608
uses the URL-selected profile's key; its default-listener no-key branch is for
manual/test wiring, with normal startup requiring a key. No schedule-specific grant
check is established by this path.

Crucially, the [endpoint catalog and capabilities handler][H1]:79–102,2536–2575
advertise neither jobs nor pause/resume, nor Wing's declared/granted `tasks:read`
and query-profile descriptor. The jobs handler does not consume Wing's `profile`
query contract; URL-prefix profile routing is distinct. Existing routes and bearer
authentication do not authorize probing or enabling them. No write-scope name is
invented here. A broad admin flag, jobs read grant, Desktop RPC or
`runs_idempotency` cannot fill this gap.

## Current Wing seam: preserve the read-only inventory

- [`HermesChannel`](../../lib/core/hermes/channel/hermes_channel.dart):124–127
  exposes `loadJobs`, not pause/resume. [`canReadJobs` and shared gate](../../lib/core/hermes/channel/hermes_channel_state.dart):221–222,264–285
  require supported schema, exact named `GET /api/jobs`, declared/granted
  `tasks:read`, every required scope and supported profile context when scoped.
  This is read authority only; there is no schedule mutation gate/caller here.
- [`listJobs`](../../lib/core/hermes/client/hermes_api_client.dart):190–207
  performs GET with explicit selected profile and `include_disabled=true`, keeping
  up to 128 nonempty-ID rows. [`HermesJob`](../../lib/core/hermes/models/hermes_job.dart):3–41
  contains bounded read metadata, not a mutation revision/idempotency receipt.
  RPC `job_id`/schedule text and HTTP `id`/schedule object are not interchangeable
  envelopes; this trace does not add a decoder or fallback.
- [`_reloadJobs`](../../lib/core/hermes/channel/api_channel/hermes_api_channel_connection.dart):275–310
  rejects denied/unsettled state and fences results by client, connection,
  selected profile and request generations. [`SchedulesScreen`](../../lib/features/schedules/screens/schedules_screen.dart):172–237
  fences refresh callbacks/completion by current channel/host/profile/read authority.
  These client fences prevent stale publication; they cannot prevent a stale
  mutation committing at Agent. Keep search/filter/refresh/recovery as-is and
  create/edit/pause/resume/run/delete controls absent.

## Nearest tests inspected, not executed

| Pinned test | Evidence and limit |
| --- | --- |
| [Agent RPC profile test][T1]:14–85 | Dispatches `cron.manage list` to a temporary named store, checks `scoped` and scope cleanup; unknown profile yields `4064`. It does not test pause authorization, revisions or replay. |
| [Agent tool test][T2]:305–315 | Real tool create → pause → resume checks result success and state. No transport/grant/crash/concurrent-edit proof. |
| [Agent domain tests][T3]:534–575,623–709 | Pause flags/markers, due exclusion and claim refusal; expired one-shot rejection; elapsed recurring slot retained; future/missing slot recomputed; ambiguous name refusal. These do not establish cancellation of in-flight work or idempotent request recovery. |
| [Messaging jobs tests][T4]:269–315 | HTTP pause/resume envelopes and exact function argument, with cron functions mocked. Not real persistence, profile-grant or advertised capability proof. |
| [Desktop owner test][T5]:53–70 | Switch dispatches pause with captured owner/profile and exact owner-cache invalidation. Mocked client; not Agent authorization. |
| [Wing inventory test](../../test/features/schedules/schedules_screen_test.dart):595–618 | Existing read-only rendering, paused rows, sanitized notice and absent New task. No mutation qualification. |
| [Wing admission tests](../../test/features/schedules/schedules_client_ownership_test.dart):56–94 and [bootstrap tests](../../test/core/hermes/channel/hermes_jobs_bootstrap_authorization_test.dart):155–228 | Synthetic denied schema/operation/grant/context cases issue no jobs I/O; read inventory authority cannot be promoted to writes. |

No test is added for this documentation-only task. Prior execution receipts remain
historical evidence, not reruns or live/native acceptance at this baseline.

## Review, validation and next boundary

Closeout checks: source pins and trace above, changed Markdown paths and pinned
source-anchor bounds against local trees, and `git diff --check`.
Independent fresh-context contract/security review returned **pass, no material
blockers**, verifying operation/grant separation, owner identity, concurrency,
replay/unknown outcomes, result privacy and the unchanged read-only Wing seam.
That review is source evidence only, not a security audit or runtime acceptance.

A later implementation requires an unmodified supported Agent contract establishing
the exact operation and grants, explicit current profile/job identities, an
authoritative concurrency check, safe unknown-outcome/replay reconciliation and
bounded redacted results. These are acceptance gaps, not proposed wire fields or
permission for a shell bridge, direct Agent-file write or shadow scheduler.
The already indexed `DOC-M4-SCHEDULE-DELIVERY-CONTRACT` is a separate read-only
follow-up; this task neither traces nor authorizes delivery changes.

No browser, native UI, physical device, live authentication, schedule execution or
delivery was exercised. Any eventual native/live pause/resume journey needs its
own suitable disposable target, authority and consent gates; absent guarantees
are not a failed live test. Re-pin and repeat this review when operation/models,
auth/profile routing, store concurrency, Desktop/Wing callers or living ADRs change.

## Pinned upstream sources

[D1]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/plugins/hermes-bots/cron.tsx#L490-L598
[D2]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/plugins/hermes-bots/routing.ts#L217-L258
[A1]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tui_gateway/contracts/tools_commands.py#L416-L507
[A2]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tui_gateway/methods_tools.py
[A3]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_routers/chat_ws.py
[A4]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_server_chat.py
[A5]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tui_gateway/rpc_dispatch.py#L17-L42
[A6]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tui_gateway/server.py#L567-L587
[A7]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tools/cronjob_tools.py
[A8]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/cron/jobs.py
[A9]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tools/cronjob_job_args.py#L476-L526
[H1]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/gateway/platforms/api_server.py
[T1]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/cron/test_cron_manage_profile_scope.py
[T2]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/tools/test_cronjob_tools.py#L305-L315
[T3]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/cron/test_jobs.py
[T4]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/gateway/test_api_server_jobs.py#L269-L315
[T5]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/plugins/hermes-bots/cron-owner.test.tsx#L53-L70
