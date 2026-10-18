# Notification contract proposal

Status: **Proposed** architecture; assessment only for `M1-NOTIFICATION-CONTRACT`.
No enrollment, relay, push SDK, credentials, delivery support, or new Agent
endpoint is implemented by this document. This closes the bounded contract
assessment, not notification implementation or M1.

## Assessment scope and verdict

The [accepted priority](prd.md#user-demand-emphasis) is reliable away/return,
status, then opt-in alerts. No delivery owner was named in the existing proposal;
`TODO.md` listed this task unassigned at baseline. The worker dispatch owns only
this bounded assessment, not delivery work. The
[away/return handoff](../quality/android-away-return-status.md) leaves its Android
matrix `NOT_CHECKED`; this assessment does not upgrade that dependency's live
qualification or authorize delivery before reliable status.

Evidence is the read-only official Hermes Agent checkout at
`158fd638da1629c8e62caf9ade1515d162def8ab`, including its official
`apps/desktop` subtree (`2038178ee53e13cde6fe297daa2484a868e7d3a3`). This is
that checkout, not latest upstream, a connected Agent's capability advertisement,
or executed platform evidence. Wing source was inspected at baseline
`c15c1d9ba6b7572cdafd10acc7990304edd4ba92`.

**Verdict:** the smallest reference-backed candidate is a **local, opt-in native
completion alert while Wing is alive and receives authoritative run events**.
It needs no relay, device enrollment or new Agent backend. It is not suspended
Android/iOS delivery. No suitable device enrollment, token rotation, notification
routing/redemption or revocation contract was found in the inspected REST/RPC
catalogs. Remote wake/delivery therefore remains unavailable, not an invitation
to invent routes, reuse a browser-controller ticket or modify Agent.

### Operation-to-source/test map

Classification: **Shipped API** means an advertised/registered operation in the
pinned unmodified Agent source, not runtime qualification. **Source-only** means
client/native behavior in the official reference, not an advertised Agent API or
Wing implementation. **Unavailable** means no suitable contract found within
this bounded inspection. Nearest tests below were **read, not executed**.

| Operation | Classification and exact authority | Source and nearest test evidence |
| --- | --- | --- |
| Discover operations | **Shipped API:** `GET /v1/capabilities`; consume the actual endpoint method/path, supported schema and every required scope. Never infer notification grants from run visibility. | [REST catalog/auth/features][agent-catalog], [capability handler][agent-capabilities]; [test_capabilities_advertises_plugin_safe_contract][test-capabilities]. The pinned document advertises bearer auth, not notification enrollment scopes. |
| Observe completion/attention | **Shipped API:** `GET /v1/runs/{run_id}` and `GET /v1/runs/{run_id}/events` (`run_status`, `run_events`, with their feature flags). Run reads require authenticated profile/owner scope. Status may use a room grant's `status` permission; SSE uses API-key auth, not that room permission. Neither authorizes enrollment or a decision. | [Run authentication/scope][agent-run-auth], [owned status/SSE handlers][agent-run-reads]; [explicit session status][test-run-session], [completed event][test-run-completed], [missed-event replay][test-run-replay], [foreign/unstamped owner rejection][test-run-owner]. SSE replay is not notification deduplication. |
| Re-read tap target | **Shipped API:** `GET /api/sessions/{session_id}` and `GET /api/sessions/{session_id}/messages` are registered and advertised; use the current exact Agent/profile/session/run and fresh read authority. Read access is not approval/Stop/send permission. | [REST route table][agent-routes], [REST catalog][agent-catalog]; the capabilities test above covers advertisement generally, not an exact-owner notification tap. Wing's [recovery read-admission regressions](../../test/core/hermes/channel/hermes_recovery_read_admission_test.dart) are the nearest caller guard, not OS tap tests. |
| Emit local OS alert | **Source-only:** Desktop completion calls `dispatchNativeNotification` → `hermes:notify` IPC. Master/kind preferences, focus checks, reconnect baseline suppression and a one-second kind/session throttle gate dispatch. No Agent enrollment operation or notification-specific grant is involved. | [Completion emitter][desktop-completion], [native preferences/dispatcher][desktop-dispatch], [focus/preferences/baseline/throttle tests][test-desktop-dispatch]. This proves a reference path to assess, not delivery while a renderer is stopped. |
| Deliver and focus | **Source-only:** Electron native `Notification` for non-Linux and asynchronous `org.freedesktop.Notifications` D-Bus for Linux. Body click carries a durable focus ID back to the source renderer, with primary-window navigation fallback if it closes. Runtime action callbacks stay source-owned. | [IPC delivery/click][desktop-ipc], [Linux presenter][desktop-linux]; [source-window/fallback tests][test-desktop-ipc], [bounded Linux delivery tests][test-desktop-linux], [existing remote-tab focus test][test-desktop-focus]. These do not establish Wing exact-host/profile tap safety or any Android/iOS/web push support. |
| Enroll/rotate/revoke device; resolve opaque delivery handle | **Unavailable:** no matching notification operation, request schema or grant in the inspected REST catalog/route table or generated Desktop RPC method catalog. `groups.peer.revoke`, room grants and browser-control registration belong to other protocols, not push registration. | [REST catalog][agent-catalog], [route registration][agent-routes], [generated RPC catalog][rpc-catalog]. No matching notification-contract test was identified; source search absence is bounded to this pin/scope, not all plugins, account services or future releases. |
| Wake a suspended/terminated mobile or browser client | **Unavailable for Wing:** no verified Agent-to-device delivery contract or Wing push integration. An active Desktop socket plus local OS presentation is not APNs, FCM or Web Push. | Desktop dispatch/IPC evidence above; Wing `pubspec.yaml`, `web/index.html` and native runner sources contain no notification integration in this inspection. There is no platform delivery test to claim as passed. |

Wing must retain its existing [transport policy](../../lib/core/hermes/policy/hermes_transport_policy.dart)
(lines 19–41, 78–96): exact endpoints, features, schema, all declared scopes and
supported profile context. The pinned REST catalog does not declare a new
notification scope; do not invent one or interpret bearer possession as relay
consent. [Detached recovery](../../lib/core/hermes/channel/api_channel/hermes_api_channel_messaging.dart)
(`_recoverDetachedRun`) checks the full saved owner and response run/session IDs;
failed status/history reads retain uncertainty. Reuse that boundary, not a new
notification status cache.

### Smallest candidate — Proposed, not implemented

Limit a first implementation proposal to **native desktop, app alive**, one
completion category on an already-authorized observed run. Suppress OS alerts
while focused; keep the existing foreground status/unread path independent.
Observe through the current direct Agent channel; never request notification
permission as a prerequisite for Chat, start a poller/foreground service to keep
a phone alive, or claim delivery after suspension, force-stop or termination.
An attention category can follow only for an authoritative current request;
connection loss, timeout or an optimistic UI transition is not completion.

Platform inventory is deliberately narrow: official Desktop has Linux D-Bus and
non-Linux Electron presenter source. Wing has no local-notification integration
qualified here on Linux, Windows or macOS; Android, iOS and browser delivery are
also unimplemented/unqualified by this assessment. Selecting a platform adapter
and any dependency is later scoped implementation, not approval from this map.

Privacy adaptations are mandatory, explicit differences from Desktop:

- Start **off**, ask deliberately, and honor OS denial without retry loops.
  Desktop's source defaults enabled; do not copy that default as consent.
- Use generic localized completion/attention text only. Desktop's completion
  emitter includes up to 140 characters of reply text; attention titles can name
  sessions. Neither is acceptable lock-screen content for Wing. No transcripts,
  session titles, paths, endpoint/profile/session/run IDs or credentials enter OS text,
  payloads, analytics or logs.
- For local presentation use a bounded opaque local notification reference to an
  existing owner, not a bearer, deep-link URL or new run store. Resolve it only
  on deliberate tap; missing/evicted references fail unavailable. The remote
  handle protocol below is not required for this local-only candidate.
- Deduplicate by exact owner plus authoritative run/outcome (and request identity
  for future attention), not Desktop's one-second kind/session throttle. Bound
  and expire local presentation metadata; never let it become replay authority.
  Persistent dedupe or cold-start tap storage requires separate privacy design;
  do not claim restart guarantees from volatile state.
- A tap is navigation only, after direct authenticated identity/grant revalidation;
  it outranks automatic viewport restoration but cannot retarget by name/recency.
  No automatic host switch on ambiguous identity, send/create/retry/Stop/approval
  or clarification response. Desktop's notification approval buttons are not
  admitted by Wing's PRD; keep decisions in the reviewed foreground flow.

Existing [resume/unread handling](../../lib/features/hermes_chat/screens/state/hermes_chat_lifecycle.dart)
(lines 4–56, 139–160) and [foreground/background-session tests](../../test/features/hermes_chat/screens/hermes_chat_gateway_switch_test.dart)
(completed, failed and approval cases at lines 1058–1247) remain the usable path
without notifications. Their background session is not OS background execution.

### Required future tests — not run or qualified

Review basis: [PRD notification requirements](prd.md#user-demand-emphasis) and the
[payload](#payload-and-lifetime), [tap](#tap-resolution-and-replay) and
[qualification gates](#implementation-and-qualification-gates) retained below.
No test is added for this documentation-only assessment.

| Public seam | Required acceptance before claiming delivery |
| --- | --- |
| Opt-in / OS permission result | Off, denied, dismissed and later revoked permission produce no alert/enrollment or automatic retry. Chat, authoritative status, unread access and explicit recovery stay operable, including keyboard/accessibility paths. |
| OS presenter / lock-screen payload | Capture the actual serialized title/body/extras and locked-screen output; only generic localized text and an opaque reference are present. Assert no content, owner IDs, private endpoints or credentials; verify previews, diagnostics and logs too. |
| Channel outcome → presenter | Replay the same event, reconnect replay, repeated reconciliation and duplicate tap yield at most one alert per exact run/outcome and no mutation. Distinct runs/owners must not collapse; disconnect remains unknown. Test bounded metadata expiry and reject stale callback generations; do not claim process-restart dedupe unless separately implemented and tested. |
| Tap → existing navigation/read boundary | Same session ID on two Agents/profiles, A→B→A owner replacement, revoked grants, missing/deleted target, offline read and expired reference all fail closed without metadata leakage or guessed fallback. A valid deliberate tap opens only the exact owner after reads, defeats automatic restoration and makes zero send/create/approval/Stop/retry calls. Duplicate taps stay navigation-only. |
| Named native artifact / device | Exercise opt-in/denial, locked-screen privacy, focus/background transitions and tap with exact artifact identity. Record actual termination limitations. Physical Android/iOS suspended delivery, token rotation and APNs/FCM/Web Push remain separate future checks, not coverage from Desktop mocks. |

### Missing contract for away-mobile delivery

The exact missing authority is an advertised authenticated notification contract
that binds **device + intended Agent + explicit grants + provider/relay identity +
token revision**, supports atomic token replacement and independent revocation,
and resolves bounded opaque handles to the exact current resource only for the
authenticated intended device. It must specify expiry, replay/idempotency,
retention/deletion and denial behavior. None of those notification operations or
grants is established by the pinned catalogs. A provider delivery channel and
real suspended/terminated-platform behavior also need separate evidence.

The following retained remote architecture is **Proposed and conditional** on
that contract and privacy/trust review, not a selected service. Hermes Agent
remains authoritative for sessions, runs, approvals and clarifications. An
optional advertised Agent plugin/account service could own enrollment/routing;
an explicitly consented relay could transport minimal delivery data. No paid
relay is selected, no credentials are collected, and no Wing Link or replacement
management backend participates. Provider/operator consent, self-hosted trust,
architecture approval and real platform qualification remain future decisions
and checks, not offline blockers to this completed assessment.

## Enrollment and trust

Enrollment requires explicit opt-in, an authenticated Agent connection, exact
advertised enrollment/routing operations and grants, and OS notification
permission. Show the relay operator and normalized public origin before consent;
offer a self-hosted operator with the same contract and security requirements.
Permission denial leaves chat and foreground status usable and creates no
background retry loop.

Generate a separate per-device enrollment credential; never reuse Agent or inert
legacy management bearer credentials. Store it and the platform delivery token
only in secure storage. The enrollment service binds the device, intended Agent, exact grants,
relay identity, and token revision. Token rotation replaces the previous token
atomically. A relay change requires new consent and enrollment, then revokes the
old registration and pending handles. Device revocation is independent of other
devices and invalidates its credentials, tokens, and unresolved handles.

Native relay connections require HTTPS, reviewed origin binding, TLS and pin
policy, and explicit trust review for identity changes. A custom relay URL does
not bypass these requirements. Reject URL credentials, query strings, fragments,
origin-changing authentication redirects, and script-injected credentials.
Browser clients require normally trusted HTTPS and cannot implement native TLS
pin overrides. No embedded WebView login or broad navigation trust is proposed.
Exact platform trust provisioning remains an implementation gate.

## Payload and lifetime

The application payload contains only a cryptographically random opaque routing
handle and one category: `approval_pending`, `completed`, `failed`, or
`background_activity`. Use generic localized lock-screen text. No prompt,
transcript, recognized speech, tool arguments, profile names, private hostnames,
provider values, credentials, or raw session/run IDs enter the payload. Transport
delivery tokens remain private service metadata and are not application payload.

Proposed bounds: 256-bit random handles, maximum five-minute lifetime, at most
one pending handle per device/resource/category, and at most 64 unresolved
handles per device. Routing state is a temporary reference to Agent state, not
a transcript or parallel run store. Expire and delete the routing record at its
deadline, revocation, or redemption. Delivery failures do not extend lifetime.
Do not back up payloads, tokens, credentials, or routing records. Logs contain
only allowlisted aggregate category/outcome counters, never handles or resource
identity. Retention and operational rate limits require privacy review.

## Tap resolution and replay

Notification receipt, preview rendering, background fetching, and OS delivery
acknowledgment must not redeem the handle or mutate Agent state. A deliberate tap
authenticates the enrolled device and requests one bounded redemption. Bind
redemption to device, intended Agent, relay registration revision, handle, and a
client idempotency key. Only a retry of that same redemption may recover its
short-lived result; another device or different replay gets no resource details.
Wrong-device, revoked, expired, unknown, and already-consumed handles fail closed.
Apply bounded attempts per credential and device; repeated failure never starts
an automatic retry loop. Do not put handles in shared URLs, browser history,
clipboards, analytics, diagnostics, or exported text.

The trusted routing authority returns a reference to the intended Agent resource
only after authentication. Wing uses direct authenticated Agent reads to verify
current profile/session/run identity and grants. A tap is explicit navigation and
outranks automatic viewport restoration. It does not interrupt a run, submit
text, retry work, answer an approval, or send a clarification.

Deleted sessions show an unavailable-target message and explicit session
selection. Missing Agent connections require deliberate direct connection
selection/authentication; never try a similarly named host or session. Offline,
denied-grant, relay-outage, and expired cases offer bounded retry or foreground
navigation without leaking target metadata. A retry rechecks the same target and cannot silently become a mutation
after reconnect. Subsequent approval/clarification requires user review and the
exact direct Agent operation; the relay never transports decision content.

## Implementation and qualification gates

These gates apply to the conditional remote-delivery design above, not as
enrollment prerequisites for the local app-alive candidate.

- Advertised Agent/plugin enrollment, routing, revocation, and lookup contracts,
  with explicit scopes and stable resource identity; no endpoint names are
  invented here.
- Reviewed privacy/retention policy, relay operator and self-hosted trust model,
  credential rotation, revocation, deletion, and rate-limit tests.
- Platform credentials and integration validated separately for Android and iOS;
  permission denial, token rotation, wrong-device and expired handles, duplicate
  taps, locked-screen privacy, process termination, foreground return, and
  background delivery tested on named physical targets.
- Exact built-artifact identity attached to delivery receipts. Simulator,
  deterministic fixture, or compilation results cannot qualify APNs/FCM delivery.

Any missing remote-delivery gate keeps remote notifications unavailable. The
local-only candidate instead needs its scoped implementation and future tests
above; it is not shipped by this assessment. See the historical
[implementation plan](../superpowers/plans/2026-09-04-provenance-and-notifications.md),
[API decision](../adr/api-and-state.md), and
[security decision](../adr/security-and-privacy.md).

## Assessment verification and refresh

This assessment uses source/test inspection and documentation integrity checks
only; no Agent, Desktop, provider, relay or notification delivery was launched.
Recheck the map when the official reference pin/catalog, Wing status/owner policy,
platform adapter or privacy requirements change. Do not transfer these findings
to a different runtime's grants without capability discovery.

Pinned source links below use the same official Agent revision throughout:

[agent-catalog]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/gateway/platforms/api_server.py#L67-L102
[agent-capabilities]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/gateway/platforms/api_server.py#L2537-L2575
[agent-routes]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/gateway/platforms/api_server.py#L1745-L1793
[agent-run-auth]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/gateway/platforms/api_server_runs.py#L352-L381
[agent-run-reads]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/gateway/platforms/api_server_runs.py#L1022-L1104
[test-capabilities]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/gateway/test_api_server.py#L939-L963
[test-run-session]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/gateway/test_api_server_runs.py#L522-L549
[test-run-completed]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/gateway/test_api_server_runs.py#L628-L653
[test-run-replay]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/gateway/test_api_server_runs.py#L734-L787
[test-run-owner]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/gateway/test_api_server_runs.py#L1208-L1254
[desktop-completion]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/app/session/hooks/use-message-stream/index.ts#L1107-L1112
[desktop-dispatch]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/store/native-notifications.ts#L45-L266
[test-desktop-dispatch]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/store/native-notifications.test.ts#L70-L302
[desktop-ipc]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/electron/notification-ipc.ts#L16-L125
[desktop-linux]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/electron/notification-linux.ts#L5-L31
[test-desktop-ipc]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/electron/notification-ipc.test.ts#L42-L132
[test-desktop-linux]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/electron/notification-linux.test.ts#L206-L350
[test-desktop-focus]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/app/contrib/hooks/notification-focus.test.tsx#L64-L110
[rpc-catalog]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/shared/src/gateway-contract.openrpc.json
