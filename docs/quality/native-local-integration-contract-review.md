# Bounded host-local contract review

## Scope and verdict

Task: `DOC-NATIVE-DESIGN-REVIEW`. This is source/design evidence only for the
[revised proposal](../plans/2026-10-03-desktop-local-integration-design.md), not
privileged implementation approval, independent penetration testing, coordinator
integration or native/live qualification.

**Verdict:** retain existing Linux metadata-only discovery and explicit direct
Agent authentication as the first local slice. Remove the old recommendation to
reuse retired Link inspection/setup or add a host coordinator. No new privileged
operation is admitted. Preserve existing separately gated native serve reads/chat
and recovery; do not misdescribe those shipped source seams as wholly disabled.

Docs map: the proposal is the changed planning page; living ADRs, route status,
Wing callers/tests and two read-only Agent source checkouts are the source corpus.
Stale claims were Link reuse, obsolete Desktop IPC evidence and blanket native
transport exclusion. This receipt provides the bounded replacement trace.

## Ownership and source identities

The coordinator dispatched this exact task into its isolated branch
`autowork/DOC-NATIVE-DESIGN-REVIEW`. Initial `git status --short --branch` was clean;
process inspection showed this attempt's worker/session, not another writer for
this task. This verifies the current scoped assignment, not release of any other
lane. No canonical worktree was edited. `DOC-NATIVE-FAILURE-BOUNDARY` remains a
separate dependent task; no tracker/goal/changelog file was changed.

Pins obtained with `git rev-parse HEAD` (and `git -C <source> rev-parse HEAD`):

| Source alias | Revision | Meaning |
| --- | --- | --- |
| W: Wing task baseline | `fd0289808ab5a245f67760ccf3d8d44f8ec351be` | Clean starting tree; only the two named documentation files change |
| R: read-only Agent reference | `158fd638da1629c8e62caf9ade1515d162def8ab` | Reference checkout, not latest upstream or installed runtime |
| D: official Desktop, inside R | `158fd638da1629c8e62caf9ade1515d162def8ab` | Same repository HEAD; `HEAD:apps/desktop` tree `2038178ee53e13cde6fe297daa2484a868e7d3a3` |
| I: installed Agent source | `e06df9c2eae6901f4c88f464e0ae6e753c0428b8` | PATH launcher points to this installation's managed entrypoint; no executable was invoked |

The task worktree does not contain its own `hermes-agent/` checkout; R/D were
inspected read-only at the repository's permanent reference location. I was
resolved by reading only the PATH launcher and source, not user configuration,
auth files, runtime ledgers, secure storage or process environments. Installed
source provenance does not identify a running server or prove its capabilities.
R status was clean; scoped status for the inspected I source/test files was empty.
Root and relevant area `AGENTS.md` guides were read before deep reference study.

Content spot-pins (SHA-256; source identities remain the revisions above):

| File | I | R |
| --- | --- | --- |
| `hermes_cli/subcommands/dashboard.py` | `cf78789c16e5b2e2183671711944cc230bda241726ca3420a4c0b519f7fc4193` | same |
| `hermes_cli/dashboard_auth/routes.py` | `b942890e1e4f078a801f70ae5c3c571c27383dc179e806668d104ef501e81eb2` | `942cef19f9489e049ef3cbafdc8b0f01b97850c658db5e4fcf8ca49892317d72` |
| `gateway/platforms/api_server.py` | `6a7e6fb0a0d5ea25ddc47d36a64e2c0bc50ded331d49e1c4521d801ca7189043` | `8824f7a56d471cf25b5feb203fcf204d394c217b2b91c753a50287b4e4ec8189` |

Update trigger: any source revision, selected-file drift, operation/auth model,
living ADR or route-status change invalidates implementation assumptions. Re-pin
and re-trace; do not repin old evidence as if it exercised the new runtime.

## Exact trace: authority → handler/model → tests → Wing caller

Paths in I/R/D rows are relative to the identified repository (D includes
`apps/desktop/`). W paths are Wing-relative. Symbols are durable lookup keys;
line numbers refer only to the pinned content. Tests below were **inspected,
not executed**. They do not authorize operations.

| Seam | Authoritative handler/model and observed guarantee | Nearest tests and Wing/public caller |
| --- | --- | --- |
| First metadata operation (W/OS; no Agent handler) | `lib/core/hermes/local_discovery/local_hermes_home_discovery.dart:16-48`: `inspectDefault`/`inspectSelected`; `local_hermes_home_platform_io.dart:19-47`: `resolveSymbolicLinks` then `stat`; `local_hermes_home_types.dart:3-31`: enum + ephemeral canonical path. No file contents, Agent credential or process access | `test/core/hermes/local_discovery/local_hermes_home_discovery_test.dart`: default-only inspection, invalid/missing HOME, unsupported denial, symlink retarget, post-canonicalization stat failure and redacted permission failure. `PlatformLocalConnectionPanel` at `lib/features/hermes_chat/widgets/platform_local_connection_panel.dart:56-123` calls the existing provider and chooser; generation fences late results |
| Local UI and connection boundary (W) | `PlatformLocalConnectionPanel` explicitly owns no channel/credential/process/saved path. `screens/state/hermes_chat_connection.dart:389-505`, `_connectToEndpoint`: captured attempt/form/channel/directory/store identity; serve and gateway branches separate; save failure does not claim rollback. `HermesConnectionAttempt` / `HermesConnectionForm` at `controllers/hermes_connection_form.dart:8-130` carry origin and intent, not a Hermes-home binding | `test/features/hermes_chat/widgets/platform_local_connection_behavior_test.dart`: chooser cancel/selection causes zero connects/saves, stale default/disposed picker ignored, denial sanitized, explicit connect retains existing save semantics. `platform_local_connection_panel_test.dart`: actual Local entry composition |
| Saved Agent access (W) | `lib/core/hermes/setup/secure_hermes_endpoint_store.dart:25-143`: `loadProfiles`, `saveAll`; secure bundle is authoritative; management slots inert. `hermes_endpoint_store.dart:36` `HermesEndpointConfig` is endpoint access, not Agent profile state. No claim that loading the bundle fetches only a selected row | `test/core/hermes/setup/secure_hermes_endpoint_store_test.dart`: API key never reaches preferences; secure roundtrip; failed bundle commit preserves legacy enrollment; inert Link slots preserved. Caller is existing endpoint-store provider / `_connectToEndpoint`, not metadata discovery |
| Direct API (I, contrasted with R) | `gateway/platforms/api_server.py:67-103,2511-2553`: `_CAPABILITY_ENDPOINTS`, authenticated `_handle_capabilities`; `_prepare_session_chat:3347-3405` captures exact existing session; `_handle_session_model_lock:3774-3801` parses `_session_runtime_request_from_body`, enforces/persists lock and returns accepted runtime metadata. This is separate from dashboard Session auth and not live capability evidence | I `tests/gateway/test_session_api.py:58,776,852,1063,1111`: `test_capabilities_advertises_session_control_surface`, persisted-lock chat/stream reuse, unconfirmed requests preserving the confirmed persisted lock, require-lock failure. W `lib/core/hermes/channel/hermes_api_channel.dart`, `api_channel/hermes_api_channel_providers.dart:183` and existing authorization/readiness policies remain the callers/gates; no new API or provider write is admitted |
| Official Desktop local outcome (D) | `apps/desktop/electron/preload.ts:39-46` → `main.ts:15581-15658` connection dispatch; `backend-command.ts:20-26` builds optional validated `--profile <id>` + `serve --host 127.0.0.1 --port 0`; `main.ts:13127-13285` resolves/attaches or spawns with private process token and owned child. `host-backend-attach.ts:58-116` builds token-query WS descriptors. These are Desktop privileges, not Wing contracts | D `electron/backend-command.test.ts`: profile pin/validation and legacy fallback; `local-backend-lifecycle.test.ts`: late-spawn fence, bounded shutdown, pre-claim child ownership. W maps the connection outcome through existing Local panel/form and `HermesApiChannel`, **not** Electron IPC or ledger/token acquisition |
| Installed launch candidate, not approved (I/R) | I/R `hermes_cli/subcommands/dashboard.py:15-74`: common runtime args, `serve` headless; I `main.py:2541-2565,2701-2758`: validates config, attaches/routes before runtime preparation and `start_server`. Profile invocation need not create a fresh owned child; `--isolated` controls routing. `--stop` is process-management authority, not a captured Wing-child interrupt | I/R `tests/hermes_cli/test_fast_serve_launch.py:15,29`: lean/full parser equivalence and unambiguous dispatch. **No Wing launch caller admitted.** Fixed argument shapes in source are evidence only; do not run them to qualify metadata discovery |
| Dashboard token vs Session (I/R) | I `hermes_cli/web_server.py:399-415,480-487`: process token environment/random source and REST header/Bearer comparison; `dashboard_auth/base.py:9-32`: verified interactive `Session` differs from `TokenPrincipal`. I `routes.py:517-575`: `/api/auth/me` may report token-validated synthetic loopback identity, but `_require_session` still gates ticket mint. R `routes.py:485-493` has the same Session requirement | I/R `tests/hermes_cli/test_dashboard_auth_ws_auth.py:116-148`: authenticated mint, unauthenticated rejection and no GET mint. W `lib/core/hermes/client/hermes_web_read_client.dart:203-229,289-331`: fixed POST ticket request, Authorization header, secret-free WS URL; missing Session fails rather than becoming a bootstrap path |
| Native login acquisition candidate (I/R) | I `dashboard_auth/routes.py:289-335,579-613`: native authorize/token/refresh; `_NativeTokenBody {code, code_verifier}`, `_NativeRefreshBody {refresh_token, provider}`; PKCE/native flow returns bearer material in JSON. This requires actual configured-provider login; it is not extraction of an existing process token. Authorization uses a short-lived code in a loopback callback, so this is **not** proof of a flow with no credential-like URL values whatsoever | I `tests/hermes_cli/test_dashboard_auth_native_flow.py:196,351,384,437,568`: non-loopback redirect rejection, Bearer without cookie, no loopback auth flows, PKCE advertisement, password roundtrip. **No new Wing acquisition caller admitted**; provider/callback/storage/security decision remains separate |
| Ticket transport and current fixed chat (I/R + W) | I `web_server_chat.py:250-377`, `_ws_auth_reason`; `dashboard_auth/ws_tickets.py:20-61`: 30-second one-use in-memory tickets, selected stable protocol only. Ungated static-token WS and gated provider-session query compatibility are distinct upstream branches; Wing uses neither URL fallback. W `connectLifecycleForProduct` at `hermes_web_read_client.dart:165-182` requires exclusive-submit and approval negotiation | I/R `test_dashboard_auth_ws_auth.py:225-270`: ticket subprotocol single-use, no secret protocol echo, ambiguous/missing protocol rejection, legacy-token rejection. W `test/core/hermes/channel/hermes_local_serve_chat_test.dart`: live-ticket authorization, negotiation denial, uncertain submit, exact approval and Stop; caller `api_channel/hermes_api_channel_serve_chat.dart:18-78`, `_qualifyServeChat` |
| Exact native recovery (W; upstream branches must stay distinct) | `lib/core/hermes/client/hermes_web_lifecycle.dart:117-186`: fixed lazy resume with profile/stored ID, validate returned durable/runtime IDs, replay/history/replay barrier. `models/hermes_web_reads.dart:34-64`: `HermesWebRecovery` and product authorization. `api_channel/hermes_api_channel_serve_recovery.dart` and secure native recovery store retain exact owner/uncertainty, not transcripts or queued commands | `test/core/hermes/channel/hermes_local_serve_restoration_test.dart`, plus lifecycle tests; existing [chat](local-serve-production-chat.md) and [restoration](local-serve-restoration.md) receipts trace R `tui_gateway` contracts/handlers and nearest tests. Those historical fixture receipts are not re-executed or upgraded here. No new resume mode admitted |

### Installed/reference drift and unavailable guarantees

- I and R are different revisions; parser equality does not establish whole-runtime
  compatibility. I's synthetic loopback `/api/auth/me` response is **not** a
  verified dashboard Session or new ticket acquisition guarantee.
- Official Desktop now uses headless `serve` and launch/attach orchestration, not
  the withdrawn separate app's IPC/compatibility patch. Do not copy its process
  environment, filesystem ledger, token-query URL or legacy dashboard fallback.
- Supported source shape: no-secret-query ticket transport **after** authenticated
  Session acquisition. Unavailable here: qualified Wing-owned local login,
  safe automatic bootstrap for arbitrary local Agent installations, granted
  lifecycle authority, exact effective provider/model restoration from catalog
  text, or proof that any running host advertises these operations.
- Metadata inspection has stale-result fencing but no hard IO timeout/cancellation
  or containment guarantee. No helper deadline, output limit, rollback, process
  cleanup or secure-keyring guarantee transfers to it from removed code.
- No new authoritative revision/idempotency transaction was found or invented for
  privileged administration in this slice. Missing contracts disable the affected
  operation rather than permit file/shell/config/RPC fallback.

## Acceptance checklist and independent review

- [x] Reconcile proposal with all five living ADRs, security policy, threat model
  and current route status; no ADR expansion.
- [x] Distinguish existing operations, withdrawn coordinator/Link suggestion and
  unavailable privileged operations; fixed shapes/bounds and explicit identities.
- [x] Trace installed/reference handlers, models, nearest tests and Wing callers;
  separate source guarantees from runtime advertisement and qualification.
- [x] Describe secret acquisition limits, failure/recovery and removal criteria.
- [x] Obtain independent fresh-context contract/security review and resolve findings.
- [x] Verify changed Markdown targets, revision/content pins and scoped whitespace.

Independent fresh-context `reviewer` run `af753f25-20da-4e2c-b5af-8116bb1cbafa`
checked contracts/security, source pins, links and whitespace. It found no Critical
or Important issues and one Minor overstatement: the unconfirmed-request test
returns HTTP 200 while preserving the confirmed persisted lock, not rejecting the
request. Source assertions were re-read and the wording corrected.
Follow-up `4d16e9c1` verified that sole correction and returned **APPROVE — DOCS
ONLY**, with no blocker. It bound the unchanged plan to SHA-256
`cf9effb98ea399f5d66bcb76acc5c71b9baed4e4b285858c8f79643fd94a03cd` and the
corrected receipt before this closeout bookkeeping to
`282b97d87c556f34f2ff67dac1d7c1f15d61ca4bd04023bc8e4d73f22b188f41`.
Only review/check bookkeeping was added afterward; final checks cover those bytes.
This is an independent subagent contract/security review, not a human security
audit. Historical ownership assertions were not independently attested; no runtime
or passive-recovery guarantee was judged. The separate source scout was research,
not approval.

## Validation and qualification ceiling

Documentation-only: no behavior change and no new tests. Final offline checks:

- `python3 "$TMPDIR/verify_native_review.py"`: pass; 16 local Markdown
  links/anchors and the historical Git target, R/I/D revision pins, Desktop tree,
  29 selected upstream source/test blobs, six SHA-256 spot-pins, 21 unchanged Wing
  source/test blobs and the two-document task scope verified. The temporary
  checker is task-local, not a new shipped validator or test suite.
- Independent `reviewer` / follow-up `4d16e9c1`: pass, documentation only, as above.
- `git diff --check` and `git diff --cached --check`: pass, including the new
  receipt in the staged candidate.

No SDK/package installation,
Agent invocation, credential acquisition, network request to Agent, process launch,
runtime state change, service operation or upstream edit belongs to this task.

Platforms exercised by this review: none at runtime; Linux-hosted source inspection
only. Real native chooser latency/cancellation, OS keyring behavior, installed-host
auth/capability checks, Agent-owned continuation, process death/cleanup and
Linux/macOS/Windows/Android acceptance remain separately scoped live work. Do not
mark NATIVE-INTEGRATION or the daily-use milestone qualified from this receipt.
