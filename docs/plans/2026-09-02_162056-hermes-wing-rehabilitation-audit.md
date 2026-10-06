# Hermes Wing rehabilitation audit and verified-slice roadmap

> Historical planning record. Findings, status, commands, and proposals below
> describe the dated snapshot, not current support or authorization to expand
> Wing Link. Follow the [living ADRs](../../docs/adr/README.md) and
> [current route status](../../docs/product/routes.md) before acting on this record.

Status: audit baseline complete; Slices 1-3 verified; next slice P0-002 run-id-only approvals

## Baseline and evidence rules

- Repository: `<repository-root>`
- Branch: `main`
- HEAD: `5cd4400e582590e6d1d6337a2bbfc32291b36f0e`
- Worktree: substantially dirty before this audit. The baseline included modified Flutter, localization, docs, test, asset, and Wing Link files plus untracked plans/specs. Those changes are pre-existing and must not be reset, cleaned, overwritten, staged, or attributed to this audit.
- Upstream references: `hermes-agent/` and `hermes-desktop/` are read-only evidence. A route found in either source is not a supported Wing contract unless the connected Agent advertises the exact operation with compatible semantics and authorization.
- Historical plans, specs, screenshots, and receipts are leads. Current code, current tests, living ADRs, advertised capabilities, and fresh executable receipts are the authority.

Commands captured before editing:

```text
pwd
# <repository-root>

git rev-parse --show-toplevel
# <repository-root>

git branch --show-current
# main

git worktree list
# <repository-root>  5cd4400e [main]

git rev-parse HEAD
# 5cd4400e582590e6d1d6337a2bbfc32291b36f0e
```

The exact initial `git status --short` is retained in the session transcript. It included 40 modified files and two untracked artifacts before this file was created.

## Current topology by concern

| Concern | Current owner and flow | Primary evidence |
| --- | --- | --- |
| Application shell and routes | One GoRouter shell composes adaptive feature routes; enrollment and local setup sit outside the authenticated shell. | `lib/router/providers/app_router.dart`, `docs/product/routes.md` |
| Agent channel ownership | A Riverpod singleton supplies one `HermesApiChannel`; the immutable `HermesChannelState` projection drives features. | `lib/features/hermes_chat/providers/hermes_channel_provider.dart`, `lib/core/hermes/channel/hermes_api_channel.dart`, `lib/core/hermes/channel/hermes_channel_state.dart` |
| Agent transport and serialization | `HermesApiClient` owns endpoint methods, bounded request time, JSON decoding, and SSE decoding over platform transports. | `lib/core/hermes/client/hermes_api_client.dart`, `lib/core/hermes/client/platform/`, `lib/core/hermes/sse/hermes_sse_event_decoder.dart` |
| Connection lifecycle | Connect invalidates prior generations, checks health/capabilities/sessions, starts optional reads concurrently, and rejects stale completions. Disconnect clears active transport state. | `lib/core/hermes/channel/api_channel/hermes_api_channel_connection.dart:4-184`, `lib/core/hermes/channel/api_channel/hermes_api_channel_sessions.dart:4-13` |
| Session/run identity | Active stream maps and detached leases key server-owned work; recent-turn cache keys include origin, connection generation, profile, and session. | `lib/core/hermes/channel/hermes_api_channel.dart:65-87,110-122`, `lib/core/hermes/channel/api_channel/hermes_api_channel_messaging.dart` |
| Streaming and reconciliation | Direct chat and runs consume SSE, preserve reasoning/tool turns, validate supplied run/session IDs, and reconcile canonical session history. | `lib/core/hermes/channel/api_channel/hermes_api_channel_messaging.dart`, `lib/core/hermes/reconciliation/hermes_text_reconciliation.dart` |
| Profile scope | Profile query context is accepted only when capability metadata declares it; client selection never calls global `profile use`. | `lib/core/hermes/channel/hermes_api_channel.dart:129-160`, `lib/core/hermes/channel/api_channel/hermes_api_channel_profiles.dart` |
| Secure endpoint storage | Agent and Wing Link endpoints/credentials are persisted through the endpoint-store seam and secure implementation; pairing stages then acknowledges the Wing Link credential. | `lib/core/hermes/setup/hermes_endpoint_store.dart`, `lib/core/hermes/setup/secure_hermes_endpoint_store.dart`, `lib/features/enrollment/providers/hermes_enrollment_provider.dart` |
| Wing Link management | Flutter client calls a separately authenticated management origin; Go service owns pairing, lifecycle, diagnostics, directory grants, and reviewed fixed compatibility operations. | `lib/core/wing_link/wing_link_client.dart`, `wing_link/`, `docs/adr/runtime-and-delivery.md` |
| Reconnect and lifecycle | The gateway directory and chat screen observe app lifecycle. Server state refreshes; mutations are not queued for replay. Detached-run leases block unsafe duplicate sends. | `lib/features/hermes_chat/gateways/hermes_gateway_directory.dart`, `lib/features/hermes_chat/screens/state/hermes_chat_lifecycle.dart`, channel regression tests |
| Diagnostics and redaction | One shared redactor feeds channel error text, chat surfaces, and diagnostics export. Slice 1 restored exact pairing-code exclusion at this seam. | `lib/shared/security/wing_redaction.dart`, `lib/features/hermes_chat/diagnostics/hermes_diagnostics_export.dart`, redaction tests |
| UI failure/recovery | Chat error widgets classify raw error strings heuristically and offer retry/reconnect/reauthorize actions. Enrollment intentionally collapses inspection/exchange errors to non-secret generic states. | `lib/features/hermes_chat/screens/widgets/hermes_chat_error.dart`, `lib/features/enrollment/screens/hermes_enrollment_screen.dart` |
| Platform behavior | Shared domain logic is Flutter; IO/web transports and native integrations vary. Current docs call Android experimental, web/Linux text-first, and other native targets build-tested only. | `lib/core/hermes/client/platform/`, `README.md:370-384`, platform runbooks |
| Tests/evidence | Unit/widget suites cover channel races, SSE, secure stores, redaction, enrollment, and feature states; Playwright uses a deterministic Agent fixture. Physical/device claims remain separate. | `test/`, `integration_test/`, `playwright/`, `docs/quality/evidence-matrix.md` |

## Authority map

| Domain/outcome | Authority | Wing behavior | Contract status |
| --- | --- | --- | --- |
| Profiles, Projects, providers, models, configuration, sessions, runs, messages, tools, skills, memory, schedules, approvals, gateway state | Hermes Agent | Direct authenticated Agent data-plane request only when exact capability is advertised. | Mixed: sessions/runs/models/skills/toolsets are advertised in the studied API; jobs and profile/provider administration routes are not automatically supported. |
| Setup, pairing, host lifecycle, health, bounded diagnostics, directory grants | Wing Link | Separate management endpoint and credential. Never accept the Agent credential. | Shipped in bounded slices described by current docs/tests. |
| Profile CLI compatibility | Hermes Agent delegated through Wing Link | Fixed executable and argument shape; no shell; bounded output/time; no shadow inventory; new-profile secret bytes only through stdin. | Temporary reviewed adapter with a removal trigger. |
| Project creation and Project-aware Chat | Hermes Agent | Unavailable until exact machine-readable operations and explicit session context exist. No `project use`, hidden cwd, arbitrary path, or Wing-local substitute. | Contract-gated. |
| Client drafts, active route, presentation preferences | Hermes Wing | Local presentation state only; never authoritative Agent domain state. | Local by design. |

A paired host always retains two independent origins and credentials: Wing → Agent for the data plane and Wing → Wing Link for the management plane.

## End-to-end flow traces

### Setup and pairing

1. Local operator installs/adopts Hermes and Wing Link using the reviewed installer/runbook.
2. Wing Link creates a five-minute single-use handoff containing a code, never a bearer token.
3. `HermesEnrollmentPayload` parses one allowlisted `wing://connect` shape, normalizes origins, and retains the code only in controller-private state.
4. Enrollment inspection presents bounded label/origin/scope/expiry data.
5. Confirmation exchanges once, verifies Agent health and Wing Link identity, saves separate credentials through the endpoint store, acknowledges the pending Wing Link credential, then activates the saved gateway.
6. Reconnect reloads secure endpoint configuration and authoritative Agent state.

Evidence: `lib/features/enrollment/models/hermes_enrollment_payload.dart`, `lib/features/enrollment/providers/hermes_enrollment_provider.dart`, enrollment tests, `docs/runbooks/android-hermes-setup.md`.

### Direct chat/run

1. Selected endpoint is normalized into `HermesApiConfig`.
2. Connect checks health, capability metadata, authoritative sessions, optional inventories, and active detached leases.
3. Send validates active session and exact advertised transport.
4. Run transport records the exact session/run ownership and durable lease before consuming SSE.
5. Event handlers reject explicit mismatched run/session IDs and preserve reasoning/tool boundaries.
6. A terminal event, stream loss, or status reconciliation fetches canonical session messages only for the owning tuple.
7. Disconnect cancels local observation; it does not silently replay the mutation. Durable leases conservatively block duplicates until server state resolves.

Evidence: `lib/core/hermes/channel/api_channel/hermes_api_channel_connection.dart`, `hermes_api_channel_messaging.dart`, `hermes_api_channel_sessions.dart`, and `test/core/hermes/channel/hermes_api_channel_test.dart`.

## Hermes Desktop outcome inventory

Desktop is used only for outcome language and interaction evidence. Flutter must not copy Electron IPC, host filesystem/process access, SQLite, CLI mutation, or Dashboard WebSocket assumptions.

| Desktop outcome | Wing disposition | Evidence/next proof |
| --- | --- | --- |
| Reliable streamed chat with canonical-final repair | Adapted and high priority; keep identity and tool/reasoning boundaries strict. | Channel reconciliation code/tests; add browser lifecycle proof. |
| Session rail/history, resume, rename, fork, delete | Partially adapted through exact Agent session endpoints. | Channel/session widget tests; bounded pagination remains a planned improvement. |
| Clear local/remote setup and recoverable verification warnings | Adapt pattern without Desktop host mechanisms. | Enrollment/setup screens and current runbooks. |
| Approvals and stop bound to a running task | Architecture is stronger than Desktop heuristics, but the current Agent event shape leaves Wing decisions disabled (P0-002). | Repair against the exact run-id-only event before claiming parity. |
| Provider/model management | Adapt only advertised typed Agent operations; never Desktop file/config access. | Current model options/session lock are supported; general provider CRUD remains gated. |
| Tools/skills/MCP hierarchy | Adapt information hierarchy only when exact contracts exist. | Current installed inventory is read-only. |
| Diagnostics/status summary | Adapt bounded redacted status; no raw logs, paths, URLs, or secret-bearing bundles. | Slice 1 restores pairing-code exclusion; Wing Link service diagnosis/remediation remains incomplete. |
| Blocking clarification/question response | Contract-gated. Desktop/TUI can answer/skip, but no exact advertised external Agent operation was found for Wing. | Do not emulate Desktop IPC; require an advertised run-scoped event/response contract. |
| Repository/subfolder context | Contract-gated. Desktop offers per-session context folders; Wing correctly exposes browse-only opaque directory handles today. | Require fixed Agent Project creation/assignment using a reviewed handle-to-path translation. Never accept arbitrary paths. |
| 3D Office/host SSH/Docker/local CLI | Defer or exclude. Preserve accessible 2D outcomes and Wing trust boundaries. | Living ADRs and parity docs. |

The local Desktop `lat` binary was unavailable. `npx lat.md search` and exact `locate` were used against the reference knowledge graph; the generated vector cache was removed immediately and the Desktop clone was verified clean. Relevant outcomes included provisional sessions, no OAuth fallback, session-scoped model selection, onboarding, sidebar navigation, and chat rendering performance.

## Hermes Agent contract inventory

Upstream `hermes-agent/gateway/platforms/api_server.py` registers and advertises the external API-server surface. Current source locations include route registration near lines 2226-2272 and capability serialization near lines 3313-3421. Nearest upstream tests include `hermes-agent/tests/gateway/test_api_server.py`, `test_api_server_runs.py`, and `test_session_api.py`.

| Contract | Upstream status in studied checkout | Wing use |
| --- | --- | --- |
| `GET /health`, `GET /v1/capabilities` | Registered external API; capabilities document is the feature authority. | Mandatory connection/bootstrap. |
| `GET/POST /api/sessions`; session detail/update/delete/messages/fork/chat/stream/model | Registered and listed in capability serialization. | Exact methods are separately gated; Wing must not infer writes from reads. |
| `POST /v1/runs`; status/events/approval/steer/stop | Registered and advertised. | Preferred structured run path when exact endpoints/scopes are present. |
| `GET /v1/models`, `/v1/skills`, `/v1/toolsets` | Advertised read surfaces in the studied upstream checkout. | Optional inventories; failure remains distinct from authoritative empty. |
| Registered but unadvertised API-server routes, including `/api/jobs` CRUD/admin and response retrieval/deletion | Route existence is not external contract support; current capability metadata says jobs administration is false. | Wing gates these off unless an installed Agent explicitly advertises the exact compatible operation. |
| Desktop Dashboard/FastAPI-only routes | Internal/first-party or a separate Desktop surface unless API-server capabilities advertise them. | Not a Wing contract. |
| Profile/provider/Project administration proposals | Route existence elsewhere is insufficient. | Hidden/unavailable unless the connected API advertises the exact compatible operation or Wing Link has the reviewed fixed adapter. |

## Connection and API failure matrix

Current internal representation is usually `HermesChannelState.status == error` plus a bounded redacted `String? errorMessage` (`hermes_channel_state.dart:15-52`; `hermes_api_channel_connection.dart:173-183`). Chat UI reclassifies strings heuristically (`hermes_chat_error.dart:20-78,495-534`). Rows marked **gap** need a typed failure model rather than more string matching.

| Failure | Detection today | Retry / reload rule | Current user recovery | Logging/redaction and proving test |
| --- | --- | --- | --- | --- |
| Malformed endpoint | `HermesApiConfig.fromBaseUrl` throws before I/O; connect catches it. | Safe after user edits; full connect reload. | Generic connect details. **Gap:** no typed invalid-endpoint state. | Shared redaction; channel test “connect reports invalid Hermes base URLs without HTTP”. |
| Unreachable host | IO/web transport exception. | Safe bounded connect retry; reload all server state. | “unreachable” by string heuristic. **Gap:** not typed. | Bounded redacted error; add transport-to-failure mapping tests. |
| DNS failure | Socket/client exception. | Safe bounded connect retry; full reload. | Usually classified as unreachable by known text. **Gap:** platform-string dependent. | No raw endpoint in diagnostics; add IO error mapping test. |
| Connection refused | Socket/client exception. | Safe bounded connect retry; full reload. | Usually unreachable. **Gap:** platform-string dependent. | Same. |
| Timeout | Client `requestTimeout` bounds JSON requests; stream has idle timeout. | Safe connect/read retry; never replay a mutation automatically. | Usually network/stream recovery. **Gap:** request phase is not typed. | `hermes_api_test.dart` bounds never-completing requests; stream idle channel test. |
| TLS validation failure | Platform handshake/client exception. | No automatic trust bypass; user fixes cert/trust. Full reload. | Unreachable/generic by string. **Gap:** must distinguish certificate failure. | Redacted details; add platform transport test where injectable. |
| TLS pin mismatch | Wing Link transport/identity verification. | Never retry as trusted; explicit re-pair only. | Enrollment generic failure. **Gap:** UI does not name identity mismatch. | Wing Link transport/enrollment tests; never log pin-associated private origin. |
| Missing credential | Request has no Authorization; server may return 401. | User supplies credential; full reconnect. | Auth recovery if status text includes 401. **Gap:** no typed missing-credential precondition. | Credential stays out of state diagnostics; channel auth test needed. |
| Invalid/revoked credential | HTTP 401/403/419. | No blind retry; update/re-enroll then reload. | Reauthorize action via string heuristic. **Gap:** revoked vs wrong credential not typed. | Redactor tests cover bearer values. |
| Wrong profile-bound credential | Named profile request rejects credential. | Select correct credential/re-pair; reload profile/session state. | Generic auth recovery. **Gap:** profile mismatch not explicit. | Add multiplex credential regression against fixture. |
| Unsupported Agent version/schema | Capability schema parser marks unsupported. | No retry loop; upgrade Agent or Wing. | Connection may complete but required operations remain unavailable. **P1 gap:** explicit unsupported-version state/action absent. | Capability-schema tests exist. Add connection/UI test. |
| Required capability unavailable | Exact endpoint gate rejects locally. | No automatic retry; refresh after Agent change. | Unsupported transport/action text. | Existing exact endpoint/scope tests. |
| Malformed JSON | `_decodeObject`/model parser throws. | Reads may retry; mutations must not be replayed unless contract confirms idempotency. Reload authoritative state. | Generic bounded error. **Gap:** schema failure not typed. | Parser tests cover many models; add connection malformed-body mapping. |
| Additive schema drift | Unknown fields ignored where parsers are designed for it. | Continue; reload normally. | No error. | Capability additive-field tests. |
| Breaking schema drift | Parser/required contract fails closed. | Upgrade/repair; no mutation replay. | Generic error. **Gap:** typed incompatible-schema state. | Add exact parser/connection test for required field drift. |
| Unexpected HTTP status | Platform transport throws a sanitized `StateError` string from `hermesApiHttpStatusMessage`. | Read/connect retries may be offered by class; mutation outcome must be reconciled, not replayed. | Auth/429/network/generic inferred from text. **Gap:** the numeric status is lost before channel state. | HTTP/client tests plus UI heuristic tests. |
| SSE disconnect | Stream close/error handling. | Reconcile run status/history; retain lease if uncertain; no prompt replay. | Reconnect/refresh action. | Extensive channel run-failure tests. |
| Partial stream termination | Missing terminal event triggers status/history recovery. | Same; provisional transcript retained on failure. | Run active or stream dropped. | Direct/run dropped-stream tests. |
| Duplicate events | Tool calls key by run/call ID; text reconciliation handles canonical final. | Ignore/update idempotently; reload final history. | Normally invisible. | Tool-call and canonical-final tests. **Gap:** explicit duplicate text-event invariant should remain in queue. |
| Out-of-order events | Terminal guards and ownership checks reject stale events. | Reconcile authoritative final; no mutation replay. | Normally invisible or recovery error. | Lifecycle/run tests; add focused permutation coverage if absent. |
| Stale session/run identity | Explicit mismatched IDs rejected; generation checks drop stale callbacks. | Retain exact lease conservatively; reload matching session. | Run-active/reconnect message. | Mismatched run/session and stale-generation tests. |
| Reconnect during active run | Detached lease/status/events/history flow. | Reattach exact run; no prompt replay. | Duplicate send remains blocked until resolved. | Channel detached-run tests. Browser/app lifecycle evidence remains incomplete. |
| Server restart | Run status not found releases process-local lease then refreshes history. | Safe authoritative reload; never resend. | Reconnect/history result. | “reconnect releases a detached run missing after server restart”. |
| Profile disappearance/rename | Profile refresh/selection guards. | Reload profile list and clear stale profile-owned state. | Current UI must prompt another selection. **Gap:** explicit disappearance UI test needed. | Profile mutation/selection tests cover local races, not all remote disappearance cases. |
| Empty vs failed inventory | Optional-resource error map distinguishes failed from empty. | Retry the read only; keep core connection. | Feature-specific empty/error states. | “connect distinguishes failed optional inventory from empty”. |
| Wing Link up, Agent down | Separate origins/credentials. | Agent reconnect only; management diagnostics may remain available. | README/runbook recovery describes separate services. **Gap:** deterministic split-plane UI test needed. | Gateway/settings tests plus new fixture state. |
| Agent up, Wing Link down | Direct data plane remains usable. | Do not route through Link; management actions unavailable. | Continue chat; restart Link separately. | README lines 308-319; add split-plane widget/E2E test. |

Automatic retries are allowed only for bounded reads/connect checks. Mutations, prompts, approvals, stop, secret writes, and lifecycle operations are never silently queued or replayed. Server state wins after reconnect.

## Prioritized findings

### Confirmed defects

#### P0-001 — pairing handoff codes escaped the shared diagnostics/error redactor (remediated in this slice)

- User impact: a single-use pairing secret embedded in a `wing://connect?...&code=...` string could survive into copied diagnostics, error details, or another consumer of the shared redactor.
- Root cause: `wingRedactSensitiveText` lacked an exact Wing handoff query-field rule.
- RED evidence: the focused diagnostics test emitted the full synthetic code and failed with exit 1.
- GREEN implementation: `lib/shared/security/wing_redaction.dart` now identifies only structured Wing connect handoffs and redacts every exact decoded `code` field. Duplicate fields, encoded field names, mixed-case handoffs, code-like non-secret fields, ordinary URLs, and surrounding punctuation are covered in `test/shared/security/wing_redaction_test.dart`; `test/features/hermes_chat/diagnostics/hermes_diagnostics_redaction_test.dart` covers the operator export path.
- Policy: `docs/security/threat-model.md:29-40,53-54` already requires this behavior, so no ADR or policy rewrite was needed.

#### P0-002 — current Agent run approvals reach Wing but cannot be answered

- User impact: a tool-gated run can block indefinitely because Approve and Deny are disabled; operation details and concurrent run identity can also be lost.
- Root cause: current Agent `approval.request` events have `run_id`, `choices`, `command`, and `description` but no approval id (`hermes-agent/gateway/platforms/api_server.py:7766-7785`). Wing's core responder supports run-id-only decisions, but the banner/sheet require a non-empty approval id; the event parser drops command, description, and choices.
- Evidence: `lib/core/hermes/channel/api_channel/hermes_api_channel_messaging.dart:1247-1268`, `lib/core/hermes/channel/approvals/hermes_approval_responder.dart:53-99`, `lib/features/hermes_chat/screens/widgets/hermes_chat_status.dart:431-433,493-558,658-660`, and the contradictory disabled-control widget test in `test/features/hermes_chat/screens/hermes_chat_approval_review_test.dart:86-107`.
- Next slice: use the exact current upstream event fixture, preserve bounded safe detail/choices, enable run-id-only decisions, and dedupe on the complete connection/profile/session/run identity.

#### P0-003 — preferred `/v1/runs` chat omitted prior session history — remediated and independently approved

- User impact: ordinary follow-up turns can be persisted under one session but sent to the model without the prior transcript, breaking core multi-turn chat continuity.
- Root cause: Wing prefers advertised runs and sends only the current input plus `session_id` (`lib/core/hermes/channel/api_channel/hermes_api_channel_messaging.dart:145-167`; `lib/core/hermes/client/hermes_api_client.dart:290-307`). Agent initializes empty history and only fills it from explicit history, `previous_response_id`, or multi-message input (`hermes-agent/gateway/platforms/api_server.py:7612-7655`). Its durable DB reload is intentionally skipped when the session lease is acquired immediately (`hermes-agent/run_agent.py:8878-8893`).
- Implemented path: plain authoritative user/assistant history is sent through the Agent-supported `conversation_history` field; structured/tool history fails over to the advertised direct session stream rather than being flattened. Stop acknowledgement now reloads authoritative history before releasing the run lease, and history cache keys are bound before asynchronous I/O so an old connection cannot overwrite a reconnected snapshot. Final independent review approved the exact snapshot with no Critical, Important, or Minor findings.

#### P0-004 — browser cross-origin stream requests use a header Agent CORS rejects

- User impact: a deployed web Wing can pass health/capability reads yet fail every cross-origin session/run stream at browser preflight.
- Root cause: Wing attaches `Cache-Control: no-cache` to both SSE requests and the web XHR forwards it (`lib/core/hermes/client/hermes_api_client.dart:238-255,329-339`; `lib/core/hermes/client/platform/hermes_api_transport_web.dart:40-57`). Current Agent allows only Authorization, Content-Type, and Idempotency-Key request headers (`hermes-agent/gateway/platforms/api_server.py:1117-1120`). Agent also omits PATCH from allowed methods, blocking advertised cross-origin session rename.
- Next slice: reproduce with the deterministic web target and real preflight behavior. Remove only unnecessary browser request headers Wing controls; classify Agent's PATCH CORS omission as an upstream contract blocker rather than weakening browser security.

#### P0-005 — Android rejected the tunneled Agent HTTP URL — remediated in the NetBird slice

- The prior setup generated `http://<vpn-ip>:8642` while Android network security permitted cleartext only for loopback/emulator, so management pairing could succeed but the direct Agent data plane could not connect.
- Android now permits transport to literal VPN addresses at the OS layer. Wing's existing enrollment and connection policies still require explicit user confirmation before sending an Agent credential to non-local HTTP; Wing Link independently rejects non-loopback HTTP and retains TLS 1.3 plus SPKI pinning.
- Deterministic contract, endpoint-policy, and enrollment suites pass. Physical pair → health/capabilities/chat over NetBird remains an explicit qualification limit, not a claimed receipt.

#### P0-006 — enabled release installation is integrity-only despite the signing ADR

- `README.md:214-218` advertises `install-wing-link.sh --release`. The script downloads a checksum manifest beside the binary from the same release origin and has no project-held signature chain (`install-wing-link.sh:316-325,381-416`). Production trust keys are empty (`wing_link/internal/release/release_keys.go:5-13`).
- This contradicts `docs/adr/runtime-and-delivery.md:45-49`, which requires signature plus digest and says empty keys make updating unavailable. README later correctly states there are no signed packages.
- Disposition: label this path integrity-only/unqualified or disable it until a project-held authenticity chain exists. Do not weaken the ADR.

#### P0-007 — pairing issues all management scopes with no expiry

- The security ADR claims exact least-privilege grants and independent expiry, but pairing grants all nine control scopes and stages the bearer with lifetime zero; expiration is set only for positive lifetimes.
- Evidence: `docs/adr/security-and-privacy.md:34-40`, `wing_link/internal/app/pair.go:672-682`, `wing_link/internal/state/device.go:88-100,123-126`.
- Disposition: this is a trust-boundary decision. Do not silently narrow current devices or change grants without a migration/authorization design; retain as P0 for a dedicated security slice.

#### P0-008 — the dirty bootstrap pin has no matching qualified capability fixture

- Current dirty setup pins Agent `afc3d9d34c9c3b01fa2e1332d2c66a5b5fabae3f`; the only fixture is source-derived 0.20.0 commit `d2c6af3…`.
- Evidence: `wing_link/internal/app/bootstrap.go:26`, `assets/config/termux_bootstrap.json:1`, `test/fixtures/hermes_agent/v0.20.0-2026.8.3/metadata.json:2-10`, and `docs/runbooks/hermes-agent-release-compatibility.md:3-20,59-61`.
- Disposition: run the release audit and capture reviewed live capabilities before upgrading compatibility/support claims. The mismatch is not by itself proof of runtime incompatibility.

#### P0 contract blocker — upstream multiplex run/response stores are not profile-scoped

- A valid profile credential plus a known foreign run/response id may access a listener-global registry because status/events/approval/steer/stop look up only by id. Wing cannot repair server authorization client-side.
- Evidence: adapter-global registries at `hermes-agent/gateway/platforms/api_server.py:1546-1566` and run handlers near `8022-8122` in the studied checkout.
- Disposition: do not claim profile-multiplex run isolation against this checkout. Require an upstream Agent authorization fix and tests; consider a Wing capability/qualification block for multiplexed runs after a separate trust-boundary decision.

#### P1-001 — connection failures lose typed cause and safe recovery policy

- User impact: malformed URL, DNS, refusal, timeout, TLS validation, authentication, and schema failures can collapse to generic or platform-string-dependent copy, so recovery may be wrong or missing.
- Root cause: channel state stores only `String? errorMessage`; connect catches every error into that string; UI classifies with substring matching.
- Exact evidence: `lib/core/hermes/channel/hermes_channel_state.dart:15-52`, `lib/core/hermes/channel/api_channel/hermes_api_channel_connection.dart:173-183`, `lib/features/hermes_chat/screens/widgets/hermes_chat_error.dart:20-78,495-555`.

#### P1-002 — sessions and transcripts silently stop at one Agent page

- Session inventory is a bare `GET /api/sessions`; Agent defaults to 50 and returns `has_more` (Wing: `hermes_api_client.dart:122-129`; Agent: `api_server.py:4238-4256,4293-4302`).
- Session messages are a bare latest-page read; Agent caps that page at 500 (Wing: `hermes_api_client.dart:186-195`; Agent: `api_server.py:4505-4551`).
- User impact: older sessions and transcript turns become unreachable after reconnect while remaining authoritative on Agent.
- Next slices: model page metadata at the current client/channel seam; add explicit load-more paths and loaded-history-only search wording. Do not create a shadow transcript database.

#### P1-003 — successful session creation can be reported as failed after hydration

- The create POST succeeds before a separate message-history GET; a GET failure escapes before local publication, and UI retry can create another session.
- Evidence: `lib/core/hermes/channel/api_channel/hermes_api_channel_sessions.dart:85-104`; existing test `session_mutation_tests.dart:1115-1149` confirms the durable-post/failing-read sequence.
- Next slice: publish the accepted session with empty turns, then treat hydration as an independent recoverable read, matching the living ADR's persistence-vs-reload rule.

#### P1-004 — unsupported schema and split-plane outages lack explicit recovery proof

- Unsupported capability schemas are gated per operation but can still look connected (`hermes_api_channel_connection.dart:24-27,89-162`).
- Agent-up/Link-down and Link-up/Agent-down are documented, but no single visible deterministic test proves healthy-plane continuity.
- Next slices: explicit unsupported-version UI and asymmetric-outage E2E without routing Agent traffic through Wing Link.

#### P1-005 — run-stream liveness and terminal recovery are not durable

- Agent emits SSE comment keepalives every 30 seconds; Wing drops comment-only frames and resets its idle timer only on decoded events. A healthy but quiet tool/model period can therefore become a false stream timeout (Agent `api_server.py:8066-8072`; Wing `hermes_sse_event_decoder.dart:208-235`, `hermes_api_channel_messaging.dart:444-458,1604-1617`).
- Reattach accepts `run.completed` without retaining event output, removes the detached lease before canonical message hydration, and completes partial local text when that read fails. A transient read failure therefore loses the retry handle (`hermes_api_channel_messaging.dart:1681-1685,1760-1796`).
- Pending approval payloads exist only in one-shot run SSE; status preserves only `waiting_for_approval`. Disconnect cannot recover the prompt. This needs an upstream replay/query contract; client retries alone are unsafe.

#### P1-006 — capabilities and profile context can drift

- Named-profile runtime model routing is resolved dynamically, but the mirrored `/p/{profile}/v1/capabilities` reports listener-cached model metadata and exposes no current profile/prefix/auth semantics (Agent `api_server.py:3228-3246,3324-3430`).
- The capability document has no explicit schema version or general scope/grant model. Wing's conservative v1 fallback is necessary but not proof of semantic compatibility.
- Add qualification tests that compare mirrored capabilities with profile-local behavior; do not infer profile state from a listener-global model label.

### Hypotheses requiring reproduction

- **P0-H1 cross-profile detached-run isolation:** an approved design names cross-profile switch/detach/reattach as the prior principal gap (`docs/superpowers/specs/2026-09-01-chat-run-reliability-session-history-design.md:36-43`). Current dirty-worktree channel changes and fresh tests may already address it. Treat as unconfirmed until the exact current snapshot and browser lifecycle path are exercised.
- **P1-H2 profile removal while selected:** generation guards prevent stale local responses, but a remote rename/removal between reconnect phases may leave generic recovery. Add a failing test before changing code.
- **P1-H3 duplicate/out-of-order text deltas:** canonical-final repair is covered, but verify exact duplicate event IDs and permutations against upstream event semantics before changing reconciliation.

## Documentation audit

| Document | Classification | Evidence/action |
| --- | --- | --- |
| `AGENTS.md`, `CONTEXT.md`, living ADRs | Accurate current guardrails | Authority and two-plane rules agree. Preserve. |
| `README.md` | Mixed: substantially improved onboarding, but `--release` wording is ambiguous against the signing ADR | Lines 214-218 advertise latest-alpha installation; lines 381-382 correctly say no signed packages. The shell path verifies a checksum downloaded from the same release origin, not project-held authenticity. Label it integrity-only/unqualified or block it until a signing chain exists. |
| `docs/product/hermes-compatibility.md` | Stale for the current dirty bootstrap pin | It documents/fixtures Agent 0.20.0 commit `d2c6af3…`, while the dirty bootstrap pins `afc3d9d…`. The release-audit runbook requires a reviewed live capability capture for the intended release; this is a qualification blocker, not proof of incompatibility. |
| `docs/product/wing-link.md` | Ambiguous wording | Lines 61-68 call approved-folder browsing current, then say “directory selection” is not shipped. Clarify browsing vs Project assignment after confirming UI behavior. |
| `docs/product/gateway-profile-management.md` | Stale/contradictory provider wording | Lines 71-74 say Wing Link has no provider configuration adapter and remote provider-key mutation is blocked; current ADR/docs allow the narrow transactional new-profile stdin adapter. This file is already dirty; reconcile carefully with its owner change rather than overwrite. |
| `docs/product/prd.md` | Aspirational core journeys clearly separated from current status, but status may lag | Current status line says directory navigation planned while Wing Link docs/routes claim approved browsing shipped. Verify and reconcile. |
| `docs/product/hermes-desktop-parity.md` | Incomplete evidence granularity | “implemented” means focused tests, not named-platform qualification. Keep evidence vocabulary explicit. |
| `docs/runbooks/hermes-readiness-audit.md` | Correctly historical-labelled | Do not use dated receipts as current evidence. |
| Android/Termux runbooks | Transport-policy contradiction remediated; physical qualification still absent | Android permits the VPN Agent transport only behind Wing’s explicit non-local HTTP credential confirmation, while Wing Link remains HTTPS/pinned. Termux remains Tier 2/best-effort. Physical NetBird/Tailscale pair → health/capabilities/chat and the dirty Agent pin still require qualification. |
| `docs/adr/security-and-privacy.md` | Correct authority, but contradicted least-privilege/expiry claim | Pairing currently issues every management scope with zero lifetime. Preserve the decision; repair implementation in a dedicated migration-aware security slice. |
| `CONTEXT.md` | Ambiguous/aspirational Project flow; contradicted Agent-audio input precedence | Directory browsing exists but Project assignment is unavailable; production voice input remains device STT while Agent TTS output precedence ships. |
| `docs/quality/evidence-matrix.md` and testing runbooks | Stale and weakly enforced | Rows lag live reconciliation/provider/directory behavior; cited aliases and artifact names are not reproducible, and the checker validates shape/date rather than source/artifact truth. Create a versioned claim ledger and resolvable receipt checks. |
| Historical `.hermes/plans/`, `docs/superpowers/specs/`, and Desktop UI gap studies | Historical/design leads needing inline labels | Preserve; do not silently present them as current shipped architecture. Several screenshots/spec paths are absent or predate the current navigation/reasoning UI. |

No ADR change is needed for P0-001: the security decision already requires the behavior; the implementation drifted from it.

## Evidence matrix

| Claim | Evidence available now | What it proves | What it does not prove |
| --- | --- | --- | --- |
| Channel race/reconciliation behavior | Current channel suite passes 230 tests; expanded API plus real IO transport suites pass 101 tests; scoped analysis, formatting, and diff checks are clean. | Deterministic current-snapshot behavior for exact identities, authoritative plain run history, structured-history fallback, pending and acknowledged Stop, ambiguous-submission blocking, typed HTTP rejection identity, reconnect-generation isolation, detach/reconcile, approvals, and profile scoping. | Browser lifecycle, physical Android suspension, or production Agent/provider reliability. |
| Shared redaction | Fresh shared + diagnostics suites: 45 tests passed after Slice 1. | Secret/header/path patterns plus exact Wing pairing-code fields, duplicates, encoded names, case, punctuation, and non-Wing boundaries. | Arbitrary future secret shapes or code-bearing formats outside the reviewed Wing handoff. |
| Agent contract | Upstream API-server route/capability source and tests plus Wing capability fixtures. | Source shape of the checked-out upstream and Wing's parser expectations. | Runtime advertisement by another installed release or production deployment. |
| Browser behavior | Existing deterministic Playwright fixture/runbooks. | Local Chromium behavior only when freshly run. | Native secure storage, TLS pinning on Android, physical microphone, production network behavior. |
| Android/Termux | Runbooks and historical receipts. | Procedure and prior evidence labels. | Current device/service/acoustic qualification. |
| Release quality | Complete gate exists in AGENTS/CONTRIBUTING. | Required commands. | Passing state until freshly run on the final snapshot. |

## Slice 1 receipt — P0-001 pairing-code redaction

- **Selection:** direct pairing-secret exposure outranked broader reliability changes because it crossed the shared UI/clipboard/diagnostics boundary and had one narrow authoritative seam.
- **RED:** `flutter test test/features/hermes_chat/diagnostics/hermes_diagnostics_redaction_test.dart --plain-name "a Wing pairing handoff code is excluded from diagnostics"` failed with exit 1 and printed the complete synthetic marker in the Active session field.
- **Review-driven hardening:** the first greedy regex passed the tracer but independent review reproduced duplicate-field leakage and false matches. Subsequent reviews reproduced legal raw-query, adjacent-handoff, malformed-prefix, and lookalike-scheme compositions. Each was converted into a persistent boundary assertion before the matcher was replaced with exact decoded query-field processing over complete candidate schemes.
- **Final focused GREEN:** the shared plus diagnostics suites pass 45 tests. The matrix covers first/later/duplicate code fields, percent-encoded field names, malformed values, raw colon/slash values, mixed case, wrappers, adjacent real handoffs, unrelated URI schemes in both composition orders, ordinary HTTPS code queries, and the public diagnostics export.
- **Static checks:** changed Dart files format cleanly; scoped analysis reports no issues; current full `flutter analyze` reports no issues; scoped `git diff --check` passes.
- **Broader chronology:** the channel suite passed 220 tests and one pre-final full-suite retry passed 1,413 tests before concurrent worktree changes. The latest broad run is not green evidence for this snapshot: while it was running, unowned P0-003 history edits appeared and produced a missing-parameter compile failure; after more concurrent edits landed, the isolated pre-existing lifecycle test `stale stopped run cleanup cannot clear a newer active run` still failed by unexpectedly selecting direct session SSE and making only one stop call. This campaign did not edit those run/history files.
- **Independent review:** fresh exact-snapshot review found no Critical, Important, or Minor issue; its full adversarial matrix passed and the scoped assessment is **SHIP**.
- **Platform qualification:** deterministic Flutter tests on the Linux host only. No browser, Android/device, TLS deployment, microphone, systemd, release, or production-Agent claim follows from this slice.

## Slice 2 receipt — P0-003 authoritative run history and stop lifecycle

- **Selection:** ordinary follow-up turns on the preferred runs transport could reach the model without prior session context, violating core chat continuity while appearing to remain in one session.
- **Agent contract:** the checked-out Agent explicitly accepts `conversation_history`, validates it as role/content message objects, and gives it precedence over `previous_response_id` (`hermes-agent/gateway/platforms/api_server.py:7623-7647`). Runtime capability advertisement remains mandatory.
- **Initial implementation adopted from concurrent work:** Wing retains a bounded connection/profile/session-owned snapshot of the raw authoritative messages, sends only plain user/assistant text history to `/v1/runs`, and falls back to advertised direct session streaming for structured/tool history rather than flattening it.
- **RED 1:** the existing public lifecycle regression `stale stopped run cleanup cannot clear a newer active run` failed: only `run_1` was stopped and the second send selected direct session SSE. Root cause was releasing local run state without rebuilding the authoritative run-history snapshot after acknowledged Stop.
- **GREEN 1:** acknowledged Stop now invalidates and reloads authoritative session history before releasing its detached lease. A failed reload leaves runs unavailable instead of reusing stale context. The regression now also proves the second run receives the refreshed canonical history.
- **RED 2:** `stale stopped-run history cannot replace a reconnected snapshot` expected the new connection's history but observed `stale first connection`. `_fetchTurns` derived its cache key after awaiting HTTP, so the old client could write into the new connection generation.
- **GREEN 2:** the request profile and generation-bearing cache key are captured before asynchronous I/O. The public reconnect race now passes and the stale result remains isolated under its initiating generation.
- **Independent review sequence:** round 1 found pending-Stop and stale failed-run history defects; later rounds exposed immediate-retry/reconnect marker loss, lease-admission invalidation, ambiguous accepted responses, and string-parsed HTTP status identity. Each finding was reproduced or converted into a public regression before remediation.
- **Review fixes:** explicit Stop and pending admission are generation-bound and survive reconnect; every late accepted run retains exact endpoint/profile/session/run ownership; matching accepted mutations invalidate pre-run history; failed reloads stay fail-closed; missing IDs and lost responses block duplicates; real transports preserve sanitized typed HTTP status codes so definitive non-408 4xx rejections remain retryable while 408/5xx/transport ambiguity does not.
- **Final focused GREEN:** the complete Hermes channel suite passes 230 tests; the expanded API plus real IO transport suites pass 101 tests. Nine scoped Dart files format cleanly, five analyzed targets report no issues, and scoped diff whitespace checks pass.
- **Independent final review:** **SHIP** with no Critical, Important, or Minor findings.
- **Broader/browser qualification:** deterministic web build passed. The last Playwright run passed 9/11 and reproducibly failed unrelated not-found and standalone-persona route copy assertions; it is not a green browser claim for this snapshot.
- **Platform qualification:** deterministic Flutter and Chromium tests on the Linux host only; no production Agent, mobile lifecycle, or physical network claim.

## Slice 3 receipt — NetBird compatibility

- **Confirmed finding:** Hermes Wing's direct Agent and pinned Wing Link transports were already overlay-provider neutral. Wing Link mislabeled the shared `100.64.0.0/10` range as Tailscale, so default NetBird IPv4 worked only incidentally; custom NetBird ranges and IPv6 lacked safe automatic Agent binding.
- **RED → GREEN 1:** an explicit NetBird/default-range classifier regression initially failed to compile against the Tailscale-specific helper. Production terminology is now provider-neutral and both the Go CLI and Flutter connection UI name NetBird.
- **RED → GREEN 2:** a custom private NetBird candidate could not be selected ahead of ordinary LAN. Fixed, bounded `netbird status --ipv4` and `--ipv6` probes now establish provider identity; outputs must be a single trusted, local, global-unicast IP before selection and automatic Agent binding.
- **RED → GREEN 3:** dual-stack NetBird initially produced a false ambiguity. Selection now prefers the provider's IPv4 address and falls back to its ULA IPv6 address when IPv4 is unavailable.
- **RED → GREEN 4:** oversized and timed-out provider probes were initially ignored, which could fall through to an unrelated LAN address. Both now fail closed. Distinct simultaneous NetBird and Tailscale addresses also fail closed with an explicit `WING_HERMES_URL`/`WING_LINK_URL` recovery path.
- **RED → GREEN 5:** the packaged Android network policy rejected the non-local Agent HTTP URL produced for an encrypted VPN. Android now permits the transport, while Wing's explicit cleartext-credential confirmation remains mandatory and Wing Link's non-loopback HTTP rejection is unchanged.
- **Independent review finding / RED → GREEN 6:** explicit managed-service `serve --listen` recovery still ran automatic discovery first, so a dual-overlay ambiguity prevented the documented override. The parser now honors environment/CLI listener selection before discovery; a regression proves the discovery callback is never invoked.
- **Independent review finding / RED → GREEN 7:** NetBird returns exit zero with no output when a requested address family is unavailable. The original probe rejected that real single-stack response. Successful zero-byte output now means only that optional family is absent; IPv4-only and IPv6-only regressions model the released CLI contract, while timeouts, oversized output, and nonempty malformed output still fail closed.
- **Security boundary:** no listener admission was widened. Every candidate remains subject to the existing local-interface and trusted private/CGNAT policy; non-loopback Wing Link still requires TLS 1.3, pinning, a named scoped credential, and authorization. Explicit origins remain non-mutating, and network location is never authorization.
- **Current verification:** `go test ./... -count=1` passes all Wing Link packages. The focused NetBird connection UI test passes; its full 10-test file passes in isolation. Android/docs/distribution contracts pass 18 tests. Android transport-policy, Agent endpoint-policy, API, and enrollment suites pass 126 tests. Scoped Flutter analysis reports no issues; localization regeneration succeeds; a debug APK builds successfully (with existing compile-SDK/Kotlin migration warnings). Scoped shell syntax and diff whitespace checks pass.
- **Qualification limit:** no physical NetBird or Tailscale network was exercised. Source-backed behavior covers default/custom private IPv4, NetBird ULA IPv6, and deterministic ambiguity handling on the Linux test host; browser clients still require normally trusted HTTPS.
- **Independent review:** final exact-snapshot verdict **SHIP**, with zero Critical, Important, or Minor findings after the explicit-listener and real single-stack CLI-contract defects were remediated.

## Vertical slice queue

1. **P0-001 pairing-code redaction — completed and independently approved.**
   - RED observed on the diagnostics export path; GREEN covers the shared and diagnostics seams.
   - No policy/ADR change: implementation now satisfies the existing rule.
2. **P0-003 restore multi-turn context on preferred run transport — completed and independently approved.**
   - Source-backed plain history, structured fallback, accepted-run invalidation, pending/acknowledged Stop ownership, and reconnect-generation regressions are green.
3. **NetBird compatibility — completed and independently approved.**
   - Provider-aware bounded discovery covers default/custom private NetBird IPv4 and ULA IPv6; unsafe output and distinct dual-overlay ambiguity fail closed without widening listener admission.
4. **P0-002 answer current run-id-only approvals.**
   - Real upstream event fixture, bounded details/choices, full identity dedupe, channel-to-widget proof.
5. **P0-004 Web cross-origin SSE preflight.**
   - Deterministic Chromium reproduction before changing headers; upstream PATCH CORS stays a contract blocker.
6. **P1 session creation persistence-vs-hydration.**
   - Publish accepted session before recoverable history read; prevent duplicate-create retry affordance.
7. **P1 session/transcript pagination.**
   - Model server page metadata and explicit load-more without shadow state.
8. **P1 typed connection failures and unsupported-schema recovery.**
   - One typed case per RED → GREEN slice, not a big-bang failure-model rewrite.
9. **P1 split-plane asymmetric outage and browser lifecycle proofs.**
   - Keep direct Agent chat independent from Wing Link.
10. **Documentation reconciliation.**
   - Clarify folder browsing vs Project creation, narrow new-profile provider setup, release integrity vs authenticity, and current Agent fixture qualification without overwriting pre-existing dirty edits.

## Risks and contract blockers

- The current worktree contains substantial unowned changes, including channel, docs, generated localization, UI, tests, and Go. Every edit must target an untouched or fully inspected file and every diff review must distinguish this campaign's paths from the pre-existing baseline.
- Hermes Project creation and Project-aware Chat remain contract-gated. Do not parse human CLI output, expose paths, invoke `project use`, or route chat through Wing Link.
- General provider/profile/SOUL administration remains unavailable unless exact operations are advertised or covered by the narrow reviewed adapter.
- A passing deterministic suite does not qualify physical Android lifecycle, microphone routing, AEC, audible speech, signed distribution, service reliability, TLS deployment, or production Agent behavior.
- Connection-failure typing can sprawl. Implement one public behavior per RED → GREEN slice and keep raw platform exceptions behind the transport/channel boundary.
- Security redaction is defense in depth, not permission to store or log raw pairing handoffs. Enrollment must continue dropping raw input after parsing and never expose the controller-private code.
- The advertised Agent API server listens over plain HTTP and supplies no TLS context. Remote Wing → Agent traffic therefore requires a separately reviewed TLS 1.3 reverse proxy or encrypted tunnel; direct LAN/Internet exposure is unsupported.
- Public run SSE is single-consumer and non-replayable. A disconnected pending approval cannot be reconstructed from current status alone, and run creation has no client idempotency key/list handle. These are upstream contract blockers; Wing must fail closed rather than replay a prompt.
- Linux/systemd qualification, rollback-to-healthy-predecessor, protocol N/N-1 artifact interoperability, Agent-audio input precedence, platform workflow artifact names, and evidence-matrix semantics all need dedicated verified slices. Current phrase/date contract tests do not prove those claims.
- Physical Android NetBird/Tailscale pairing, trusted-HTTPS browser CORS, Linux systemd restart/rollback, Windows/macOS/iOS runtime, acoustic voice, signed release, and production reliability were not exercised in this audit.
