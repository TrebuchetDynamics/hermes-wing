# M4 schedule delivery configuration: authoritative contract trace

Task: `DOC-M4-SCHEDULE-DELIVERY-CONTRACT`. **Read-only offline source evidence;
no job execution, delivery, credential access or operation activation.** Start with
the [pause/resume trace](schedule-pause-resume-contract.md) and unchanged
[inventory receipt](schedules-inventory-evidence.md). The
[M4 status](../product/hermes-desktop-parity.md#statuses),
[accepted port plan](../../ROADMAP.md#flutter-port-execution-roadmap),
[route status](../product/routes.md) and
[API/state](../adr/api-and-state.md)/[security](../adr/security-and-privacy.md)
boundaries remain unchanged.

## Verdict, pins and bounded outcome

The selected operation is **change only an existing job's delivery target to
`local`, in its explicit owning profile**. This is a target setting, not platform
credential provisioning, Run now, cancellation or a test delivery.

The messaging HTTP implementation accepts `deliver` through
`PATCH /api/jobs/{job_id}`, but its capability catalog does not advertise that
operation, exact write grants, revision checks or durable replay receipts.
Desktop's typed `cron.manage` has delivery input for **creation**, not an existing
job update action. Wing has no delivery mutation caller. **Keep delivery edits
unavailable and Schedules read-only; M4-SCHEDULES remains partial.** These are Wing
admission gaps, not a claim of an upstream vulnerability or a request to patch Agent.

Pins obtained with `git rev-parse HEAD` in Wing and `git -C <reference> rev-parse
HEAD` for Agent and its official Desktop subtree:

| Checkout | Inspected revision | Evidence limit |
| --- | --- | --- |
| Wing baseline | `6d81c09d315cb212165c2e7d28053b564d6bdb48` | Caller/model/tests below; documentation-only change. |
| Read-only Agent reference | `158fd638da1629c8e62caf9ade1515d162def8ab` | Source/tests, not an installed or running target. |
| Official Desktop subtree | `158fd638da1629c8e62caf9ade1515d162def8ab` | Same repository/commit, not a separate release. |

The coordinator assigned this isolated branch; its local slot was running and the
predecessor slot was closed with an integration/check receipt. The predecessor
trace is present in this baseline. This is local task/dependency evidence, not
external tracker lease release or authority for live actions.

Docs map: add this one delivery-edit trace, link the prior contract, preserve the
inventory receipt and product status. Source corpus: HTTP handler and domain
store, typed RPC and Desktop caller, nearest tests and Wing's current read seam.
No implementation, upstream edit, installation, service, network probe, private
runtime record or credential acquisition is required.

## Exact operation, identity and persistence

All upstream references below are pinned to the inspected Agent commit.

| Boundary | Verified source contract | Missing guarantee / Wing consequence |
| --- | --- | --- |
| HTTP operation/model | [`api_server.py`][H]:1780–1787,3830–3857,3942–3964 registers PATCH; authenticates, requires cron, validates the path ID with `[a-f0-9]{12}`, parses a JSON object and filters keys through `_UPDATE_ALLOWED_FIELDS`, including `deliver`. For this slice the only body field is `deliver` with value `local`. | This is a generic update handler, not a typed secret-safe delivery configuration API. Do not send invented revision/grant fields: unknown body keys are filtered, not enforced. This description is not permission to call the route. |
| Profile identity/authentication | [Profile prefix resolver/middleware][H]:1673–1746 validates `/p/<profile>/`, scopes home/secret/terminal state and rejects an unknown/unserved profile. [Bearer validation][H]:1562–1608 uses the URL-selected profile's key; named profiles do not inherit the default key. Normal startup requires a key; the no-key default-listener branch is for manual/test wiring. | This handler does not consume Wing's `?profile=` contract. An explicit selected Agent connection and current profile are required; a name/prefix is not a profile-incarnation token. No expected incarnation or delivery-specific caller grant is checked here. Authentication is not schedule-write authorization. |
| Exact job identity | PATCH passes the exact validated path ID to `_cron_update`, imported directly from `cron.jobs.update_job` ([HTTP import][H]:1087–1098). [`_with_job`][J]:1626–1637 searches only that ID within the scoped store. | No display-name lookup on this path; no job-incarnation token or expected revision. A same-ID replacement is not detected as stale intent. Preserve the connection/profile/job tuple; never use another profile or a Wing-owned catalog as a fallback. |
| Mutation commit | [`update_job`][J]:2110–2149 merges supplied fields into the current row under `_with_job`, normalizes and saves. [Normalizers][J]:1745–1768,2029–2045 do not apply the tool's delivery-string normalizer to `deliver`. | HTTP PATCH is not the `cronjob` tool validation path. Do not infer that every target string is validated, resolved or deliverable. A delivery-only update does not invoke Run now, but the shared updater can fill missing timing metadata; this is not a guarantee of no scheduling effects. |
| Revision/concurrency | [`save_jobs`/staging][J]:1548–1637 fsync and atomically replace the store; [`_jobs_lock`][J]:285–335 uses in-process plus file locking with a documented degraded in-process path on missing backend/timeout/error. | No expected job/profile revision, `If-Match` check or compare-and-set at commit. Store `updated_at` is not a checked edit revision. Atomic replacement/locking do not reject stale user intent; do not claim unconditional cross-process serialization. |
| Response/reconciliation | [`_job_response`][H]:3872–3886 returns `{"job": ...}`, 404 for missing, redacted 500 for exceptions; update notifies the cron provider after mutation. | The returned row is not an allowlisted secret-safe or durable request receipt. No idempotency key, changed-payload rejection or original-result retrieval is established. A lost response after save remains unknown; readback gives current state, not attribution. Never replay automatically or retry through another transport. |
| Meaning of `local` | [`_resolve_single_delivery_target`][S]:609–643 returns no outward target for `local`; `origin` instead resolves origin or a home-channel fallback. [`Failure lane selection`][S]:1068–1088 uses a nonempty `failure_deliver` override separately. | Editing only `deliver` leaves that override untouched: failure notices may still route outward. `local` is not `origin`, revoke credentials, stop a job, erase prior output or cancel in-flight delivery. Persistence is not delivery success, cancellation or runtime activation qualification. |

The [capability endpoint catalog][H]:79–102 and [capabilities handler][H]:2536–2575
advertise no jobs PATCH operation or schedule-write scope/profile query descriptor.
Do not invent a scope name, promote `tasks:read` to write authority, or transfer
run-submission idempotency to schedule configuration. Broad admin/version flags,
a registered route and Desktop usage do not fill these gaps.

## Desktop and tool comparison: not interchangeable transports

- Official Desktop's [`CreateRoutineDialog`][D]:955–1055 sends `cron.manage`
  `action: 'add'`, captured owner `profile`, name, schedule and prompt. Its optional
  `deliver: 'bot-chat'` is chosen during creation; history omits it. Bot Chat output
  may cost an additional agent turn, as the source explicitly explains. This
  creation UI does not prove an existing-job delivery editor or authorize one.
- [`CronAction` / `CronManageParams`][R]:416–434 enumerate only list/add/remove/
  pause/resume, with optional `deliver` and `profile`; no update action, expected
  revision or credential field. [`cron.manage` handler][M]:1393–1418 forwards
  `deliver` only for add. Passing it on another action cannot configure delivery.
- The separate [`cronjob` tool][T]:813–840,945–1041 **does** implement update by
  resolved job ID/name. It normalizes delivery, best-effort validates explicit
  Bot Chat profiles and resolves cron-context origin through
  [`cronjob_job_args.py`][A]:247–315, then calls `update_job`. This is not the HTTP
  PATCH handler or a missing RPC action; it supplies no portable exact write grant,
  expected revision or durable request receipt. No tool/CLI fallback is admitted.

## Credential and receipt boundary

**No delivery credential is required as input for the selected `local` target
change.** `deliver` is routing metadata, not a token/password slot. The HTTP
allowlist, RPC parameters and tool signature above expose no delivery-credential
replacement/removal operation. This trace establishes neither a write-only secret
API nor credential readiness for any messaging platform. It does not inspect host
configuration, secret stores or saved credential values.

Any later credential-bearing operation must independently meet the living
[security/privacy decision](../adr/security-and-privacy.md): exact advertised
secret-safe operation and grants, explicit current owner/resource identity,
authoritative revision check, write-only secret input and bounded secret-free
output/errors. Never put secrets in `deliver`, target identifiers, URLs, argv,
clipboard, preferences or logs. No secret readback, direct file edit or shadow
credential store may substitute for an absent operation.

Sanitized receipt inspection is limited to the existing
[inventory evidence](schedules-inventory-evidence.md#one-failure-journey-mapped-to-executed-oracles)
and source/test response shapes: inventory qualification remains read-only; the
PATCH envelope is a raw job row, not a delivery-write receipt. No actual delivery
mutation receipt was acquired or fabricated. Job rows may contain prompts, origin
addresses, paths and other private metadata; errors/targets are not safe UI or
log text merely because they came from Agent. Any future receipt must separate
committed revision from runtime/reload/delivery outcomes and redact content.

## Wing caller and nearest tests inspected, not executed

Wing's [`HermesChannel`](../../lib/core/hermes/channel/hermes_channel.dart):124–127
exposes `loadJobs` only. [`canReadJobs` and shared gate](../../lib/core/hermes/channel/hermes_channel_state.dart):221–222,264–285
require exact supported GET/read grants/profile context. [`listJobs`](../../lib/core/hermes/client/hermes_api_client.dart):190–207
sends GET with selected profile and `include_disabled=true`.
[`HermesJob`](../../lib/core/hermes/models/hermes_job.dart):3–41 contains inventory
metadata, not `deliver`, a credential handle, revision or write receipt.
[`SchedulesScreen`](../../lib/features/schedules/screens/schedules_screen.dart):318–343,428–502
renders read-only inventory. No delivery setter, write gate or editor is added.

| Nearest inspected test | Evidence and limit |
| --- | --- |
| [HTTP update whitelist][HT]:212–244 and direct-function regression at 494–517 | Mocked `_cron_update` verifies field filtering, ID/update forwarding and response row; not target resolution, real persistence, revisions or grants. No delivery-edit-specific HTTP assertion in these cases. |
| [Tool delivery update][TT]:406–422 | Real create/update/readback checks list-form `deliver` becomes a canonical string. It tests the tool path, not PATCH or Desktop RPC, and proves no network delivery. |
| [Profile auth/middleware tests][PT]:46–161 | Named profile rejects the default-listener key; middleware binds profile before auth. Synthetic stores/credentials, not a delivery-write grant, stale-incarnation or live credential qualification. |
| [Wing read-only widget](../../test/features/schedules/schedules_screen_test.dart):595–618 | Inventory, sanitized notice and absent New task; no write qualification. |
| [Wing admission tests](../../test/features/schedules/schedules_client_ownership_test.dart):56–94 and [bootstrap authorization](../../test/core/hermes/channel/hermes_jobs_bootstrap_authorization_test.dart):155–228 | Denied schema/operation/grants/context issue no jobs request. Read admission cannot be promoted to delivery-write authority. |

No tests are added or executed for this documentation-only trace. Historical
fixture receipts are not reruns against these pins or native/live acceptance.

## Review, validation and next boundary

Closeout checks: checkout pins, source/caller/test comparison above, changed
Markdown targets and pinned source bounds, independent contract/security review,
and `git diff --check`. Independent fresh-context contract/security review returned
**pass, no material blockers**. Its two low-severity notes were verified against
source and addressed: narrow the profile-test citation and explicitly preserve
`failure_deliver` override semantics. Review is source evidence, not a security
audit, live qualification or coordinator integration.

A later existing-job delivery edit remains unavailable until an unmodified
supported Agent advertises the exact operation/grants, explicit current
profile/job identity, authoritative concurrency check, safe unknown-outcome/replay
recovery and bounded redacted receipts. Credential provisioning, if needed for
another target, is a separate write-only contract slice, not implied by this edit.
These are acceptance requirements, not proposed wire fields or an upstream patch
plan. The [Agent immutability boundary](../adr/runtime-and-delivery.md#hard-boundary-never-modify-hermes-agent)
continues to prohibit a shell bridge, direct store writes or a shadow scheduler.

No platform UI, physical device, live service/authentication, job execution or
actual delivery was exercised. A later live journey needs its own suitable
disposable target and explicit operation/consent gates; offline source review does
not qualify it. Re-pin this trace when handler/model, profile/auth routing, store,
Desktop/Wing caller, tests or living ADRs change.

## Pinned upstream sources

[H]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/gateway/platforms/api_server.py
[J]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/cron/jobs.py
[S]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/cron/scheduler_delivery.py
[D]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/plugins/hermes-bots/cron.tsx#L955-L1055
[R]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tui_gateway/contracts/tools_commands.py#L416-L434
[M]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tui_gateway/methods_tools.py#L1393-L1418
[T]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tools/cronjob_tools.py
[A]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tools/cronjob_job_args.py#L247-L315
[HT]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/gateway/test_api_server_jobs.py
[TT]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/tools/test_cronjob_tools.py#L406-L422
[PT]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/gateway/test_api_server_multiplex_secret_scope.py#L46-L161
