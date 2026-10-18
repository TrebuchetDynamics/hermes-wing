# ACCOUNT: OpenAI Codex OAuth acquisition contract

Source-only evidence for `DOC-ACCOUNT-CONTRACT`. Start with the
[ACCOUNT status](../product/hermes-desktop-parity.md#statuses) and
[credential boundary](../adr/security-and-privacy.md).
**Wing OAuth acquisition remains unavailable; no account route is admitted.**
This traces one official Desktop outcome, not account provisioning, secret
acquisition, credential-pool administration, credits or wallet transactions.
The separate `DOC-ACCOUNT-REVOCATION-EVIDENCE` task retains lifecycle qualification.

## Scope and source identities

The coordinator assigned this isolated task slot, branch and baseline; no other
work was selected or adopted. The inspected reference is read-only and its tracked
files were clean. No Agent, Desktop, installed runtime or user state was changed.
No sign-in page, credential store, provider service or live operation was opened.

Pins obtained with `git rev-parse HEAD` in Wing and `git -C <reference> rev-parse
HEAD` in Agent and its `apps/desktop` subtree:

| Source | Commit | Evidence ceiling |
| --- | --- | --- |
| Wing task baseline | `9264ad4b6849387fbc1f7d713032caf8e58f3be8` | Caller/model/test source, not executed Flutter behavior. |
| Hermes Agent reference | `158fd638da1629c8e62caf9ade1515d162def8ab` | Authoritative handler source at this checkout, not a deployed capability promise. |
| Official Desktop subtree | `158fd638da1629c8e62caf9ade1515d162def8ab` | Product flow within the same Agent repository, not a separate API authority. |

Upstream links below are immutable at that pin. Wing links are local and line
numbers refer to the baseline. Neither pin asserts latest upstream. Historical
parity wording does not override the living ADRs or establish runtime support.
The [API-key contract trace](m3-provider-credential-contract.md) is complementary,
not OAuth admission evidence.

## Authority and private handoff

**Authority:** OpenAI authorizes the subscription/device grant. The unmodified
Agent `hermes serve` backend owns the login session, exchanges and stores the
provider tokens, and reports progress. Official Desktop owns display and browser
launch, not token custody. This is **provider sign-in**, not authentication of
Wing to Agent and not Hermes One/cloud account login.

| Step | Exact source contract | Supported source behavior and limit |
| --- | --- | --- |
| Desktop entry | [Accounts picker][desktop-picker], `startManualProviderOAuth(provider.id, profile)`; [typed API][desktop-api] lines 315–373 | Explicit provider selection starts the shared onboarding overlay. Calls carry captured connection/profile scope, not a new Wing backend. |
| Start | `POST /api/providers/oauth/openai-codex/start?profile=…`; [start handler][start-handler], [Codex starter][codex-starter] | Requires `_require_token`, validates a supplied named profile, accepts the catalog's `device_code` flow and creates an [in-memory random session][session-state]. No start request model/revision/idempotency key is declared; Desktop sends `{}`. The starter waits up to 10 seconds for a display code; 500/504 is not proof that no worker exists or no credential can later commit. |
| Authenticate the caller | [`_require_token`][auth-gate] lines 452–492; [loopback middleware][loopback-middleware] lines 696–715; [gated middleware][gated-middleware] lines 160–210 | Loopback uses the serve session header or legacy Bearer token; gated mode requires a verified session on the request. Poll's “no auth” handler comment does **not** bypass application authentication. These credentials are not interchangeable with a provider grant or Wing's external Agent token. No per-device/provider-grant authorization is established here. |
| Obtain display handoff | [Codex request/poll/exchange][codex-worker] lines 210–286; [response types][oauth-types] lines 115–162 | Worker requests a device authorization from the fixed OpenAI issuer. Start returns `session_id`, `flow`, `user_code`, `verification_url`, `expires_in`, `poll_interval`. The URL is the fixed HTTPS OpenAI Codex device page; provider bearer/refresh tokens, device-auth ID, authorization code and verifier are not returned in this start/poll shape. The displayed code/session ID remain sensitive. |
| Browser and progress | [Desktop flow][desktop-flow] lines 875–986; `GET /api/providers/oauth/openai-codex/poll/{session_id}?profile=…`, [poll handler][poll-cancel] | Desktop opens the verification page, displays the flow and polls. OpenAI approval is exchanged server-side using the authorization code/verifier. Poll checks provider and profile and returns status/error/expiry, not a credential. `approved` means the worker's save returned, not model readiness, inference, revocation status or a Wing connection. |
| Commit | [worker save][codex-worker] lines 289–339; [`_save_codex_tokens`][codex-save] lines 174–214; [`_store_provider_state`][active-provider] | Saves to Agent-owned auth state in the captured profile scope. Fresh login uses `set_active=True`, sets the auth-store active provider, and syncs the singleton-seeded pool entry plus matching legacy aliases; this is not a pure display-only operation or an exact-ID credential addition. No combined provider/model configuration transaction is promised. |

**Supported private handoff in the reference:** a user-visible device code and
verification page, with the provider token exchange and custody staying on the
Agent host. This is an architectural shape, **not a Wing-supported acquisition
procedure**. The Desktop types also allow `pkce`, but this provider's handler is
device-code only; `POST …/submit` always rejects with 400. Its
[`OAuthSubmitBody` model][submit-model] is not evidence of an available callback
or code-import operation. Do not invent a Wing deep link or paste/import flow.

No no-store response/header guarantee, durable requester/device binding,
profile-incarnation fence, expected revision, or crash-safe idempotent
acquisition receipt was established by this route trace. Raw exception strings
can reach `error_message`/start errors, and the catalog's
[Codex status projection][status-card] includes a truncated token preview, with
`expires_at=None` and `has_refresh_token=False` regardless of the stored pair.
Do not reuse those fields as a secret-safe Wing DTO or a refresh/expiry promise.
The [security ADR](../adr/security-and-privacy.md) forbids copying provider tokens
into URLs, clipboard, argv, logs, preferences or Wing responses. This study
exports no code, token fragment, private endpoint or user path.

## Expiry, cancellation, logout and revocation are distinct

| Outcome | Inspected guarantee | Not established / unavailable |
| --- | --- | --- |
| Device-code expiry | [Worker deadline][codex-worker] uses a 900-second window and reports `expired` if no approval arrives. [Session GC][start-handler] removes entries older than 15 minutes on a later start. [Desktop display timer][desktop-expiry] uses returned `expires_in`. | Not provider access-token expiry or revocation. GC only pops registry entries; it does not mark an already-held worker session cancelled. In-memory sessions do not survive backend restart. A lost session/timeout is not a rollback receipt. |
| Explicit cancel | `DELETE /api/providers/oauth/sessions/{session_id}?profile=…`, [handler][poll-cancel] marks cancelled under the session lock before removal. Worker checks before polling/exchange/save and captures profile before removal; the final check and save share that lock. | If save already holds the lock, cancellation may finish **after** commit; success means session removed, not credentials removed or remotely revoked. Missing session returns `ok:false`. Desktop cancellation is best-effort and cannot establish rollback. |
| Stored token expiry/refresh | [`_codex_access_token_is_expiring` and save][codex-save]; [runtime refresh/resolver][refresh-resolver] lines 441–690: JWT expiry inspection; Agent-owned runtime refresh and rotated-token writeback. [`get_codex_auth_status`][codex-status] is pool-first and resolves with `read_only=True`. | Status may report an expired stored singleton as `logged_in:true`; it is not remote validation or proof of entitlement. [Status tests][status-tests] explicitly preserve that state and prohibit status-driven refresh/CLI adoption. Do not infer a reliable expiry countdown from the status card. |
| Local disconnect/logout | `DELETE /api/providers/oauth/openai-codex?profile=…`, [disconnect handler][disconnect-handler] requires token and calls [`clear_provider_auth`][clear-auth]. It removes the provider singleton and **all** that provider's pool entries from the current auth store, clearing its active marker; 409 means nothing was cleared. [CLI logout][cli-logout] can additionally reset selected model configuration. [Desktop UI][desktop-disconnect] confirms removal and checks `ok`. | Not exact-credential removal, all-profile logout, cancellation of pending sign-ins, clearing another CLI's store, or a provider-side revocation call. The REST handler does not invoke CLI logout's config reset; do not substitute one for the other. |
| Remote revocation | [Refresh error handling][refresh-resolver] distinguishes invalid/reused grants and 401/403 from 429 quota errors. | No OpenAI revoke operation or authoritative revocation acknowledgement was found on this acquisition/disconnect path. Local deletion cannot revoke copies or terminate existing provider sessions. Runtime recovery may consult a separate CLI grant ([resolver][refresh-resolver]); status reads do not. Do not claim that reauthentication guidance or local removal proves revocation. |

This table supplies acquisition limits only. The dependent revocation evidence task
must separately trace source fallback, in-flight grants, other profiles/devices and
provider-side invalidation before lifecycle support is proposed. Nothing here
requests or performs logout, revocation, token refresh or credential acquisition.

## Nearest tests and Wing caller

All tests below were **read, not executed**. No new test is appropriate for this
document-only change; mocks/source review do not qualify actual authentication.

| Seam | Nearest evidence inspected | Evidence ceiling |
| --- | --- | --- |
| Session scope and cancellation | [`test_web_oauth_dispatch.py`][dispatch-tests] lines 167–465: profile status/start capture (MiniMax), cross-profile poll/cancel rejection (xAI), real cancel endpoint during Codex poll and atomic Codex final-save/delete race | Shared-route scope tests are not a Codex end-to-end grant. Codex final-save race expressly allows save-before-delete. |
| Worker transport and response bounds | [device-login retry tests][retry-tests] lines 58–86; [body-cap tests][body-tests] lines 48–73 | Scripted transport tests cover bounded transient retries and oversized auth-response rejection; not live OpenAI approval, provider TTL or durable replay. |
| Caller authentication | [server-gate regression][gate-test] lines 24–55 | Missing-cookie cancel returns 401 in gated mode. This file does not execute every acquisition step or prove per-device authorization. |
| Persistence/status/local deletion | [Codex save test][save-test] lines 328–347; [status tests][status-tests] lines 155–227; [shared clear test][clear-test] lines 768–811 | Save does not write the separate CLI store. Status does not spend/adopt tokens; initial pool materialization is not a byte-identical/no-write guarantee. Shared clear test uses Anthropic, not a live Codex revocation. |
| Official Desktop owner continuity | [onboarding-owner tests][owner-tests] lines 119–174 | Captured connection/profile survives foreground changes; cancel and late start target original owner. The parameterized fake `pkce` branch is not Codex PKCE support. |
| Wing presentation | [provider model](../../lib/core/hermes/models/hermes_provider.dart) lines 11–50; [provider row](../../lib/features/providers/screens/providers_screen.dart) lines 502–595; [English copy](../../lib/l10n/app_en.arb) lines 544–547; [OAuth regression](../../test/features/providers/providers_screen_test.dart) lines 586–608 | Only `auth_type == oauth` yields host-sign-in guidance. Manage is API-key-only; test asserts no credential sheet. This is not an OAuth launcher or host provisioning feature. |
| Wing dispatch and routes | [provider client](../../lib/core/hermes/client/hermes_api_client.dart) lines 621–677; [provider channel](../../lib/core/hermes/channel/api_channel/hermes_api_channel_providers.dart) lines 13–135; [router](../../lib/router/providers/app_router.dart) lines 60–225 | Existing inventory/Set/Remove/Validate calls are different operations, with no OAuth start/poll/cancel/exchange caller. No account route is registered. Existing API-key gates must not be interpreted as OAuth permission. |

## Fail-closed disposition

The external Agent API [capability table][external-capabilities] lines 67–102
advertises model options and session/run operations, **not** the serve OAuth routes
above; `admin_config_rw` is false. The nearest
[capability regression][external-test] lines 939–963 checks model/run contracts,
not OAuth. Desktop's private bridge and serve authentication do not advertise
these operations to Wing or qualify a native RPC substitute.

Therefore the precise unavailable Wing operation is **start a selected-profile
OpenAI Codex device-code acquisition on the connected Agent, privately display its
handoff, reconcile its commit/cancel outcome and manage its lifecycle**. No exact
advertised external operation, grants or qualified private handoff/reconciliation
contract was established. Broad provider-write/admin permission, model catalog
visibility, a stored `configured` flag, or Desktop route existence is insufficient.

Keep OAuth acquisition and account navigation absent. Do not use API-key Set,
provider DELETE, CLI execution, direct-file access, borrowed credentials, a token
import, legacy pairing, a management proxy or Agent modifications as a fallback.
Preserve ordinary direct Agent authentication and read-only provider/model paths.
A future unmodified contract needs exact operation/grants and explicit current
profile/provider/requester identity, secret-safe handoff/errors, authoritative
commit/cancel reconciliation and independently qualified expiry/logout semantics
before implementation or exposure; these are admission requirements, not proposed
wire fields. See [API/state](../adr/api-and-state.md) and
[Agent immutability](../adr/runtime-and-delivery.md#hard-boundary-never-modify-hermes-agent).

## Verification and review

Offline checks passed on the document candidate:

- `git rev-parse HEAD` and `git -C <reference> rev-parse HEAD`: pins above;
  `git -C <reference> status --short --untracked-files=no`: no tracked changes.
- `python3 "$TMPDIR/check_account_contract.py"`: 33 immutable citation ranges
  across 20 upstream files match pinned Git content; 13 local Markdown
  paths/anchors resolve; only this document is changed. The checker is a temporary
  task artifact, not a shipped validation tool or runtime test.
- `git diff --no-index --check /dev/null docs/quality/account-oauth-acquisition-contract.md`
  and `git diff --check`: no whitespace errors.

Only Linux-host source/document checks were exercised. No Flutter, upstream test
suite or browser/native app was run. Android, native secure storage, live Agent advertisement, actual provider
sign-in/refresh, concurrency across processes, OpenAI expiry/revocation and all
platform end-to-end outcomes remain **NOT_CHECKED**. Future live qualification
requires a separately selected isolated target and explicit authority/consent;
this report grants none.

Independent contract/security review: a fresh-context `reviewer` inspected the
candidate, pinned handlers/models/tests, Wing callers and ADR/security boundaries.
Disposition: **approved for this documentation-only slice**, with no critical or
important findings. Two minor citation gaps were verified and corrected: include
loopback application middleware for poll authentication, and extend the shared
clear-test range through its pool-removal/preserved-provider assertions. This is
not an independent security audit, provider-policy opinion or product acceptance.

Update triggers: changes to the pinned OAuth handler/session model, auth gates,
Codex persistence/status/refresh/clear behavior, official Desktop onboarding,
external capability advertisement, Wing provider caller/routes or living ADRs.
Re-run the trace and independent review; do not silently repin old conclusions.

[desktop-picker]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/app/settings/providers-settings.tsx#L155-L197
[desktop-api]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/api/config.ts#L315-L373
[session-state]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_routers/oauth.py#L44-L106
[start-handler]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_routers/oauth.py#L777-L816
[codex-starter]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_routers/oauth.py#L502-L524
[auth-gate]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_server.py#L452-L492
[loopback-middleware]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_server.py#L696-L715
[gated-middleware]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/dashboard_auth/middleware.py#L160-L210
[codex-worker]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_routers/oauth.py#L171-L339
[oauth-types]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/types/hermes.ts#L115-L162
[desktop-flow]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/store/onboarding.ts#L875-L986
[poll-cancel]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_routers/oauth.py#L844-L896
[codex-save]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/auth_codex.py#L65-L214
[active-provider]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/auth.py#L868-L873
[submit-model]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_models.py#L256-L258
[status-card]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_routers/oauth.py#L372-L375
[desktop-expiry]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/store/onboarding.ts#L221-L232
[refresh-resolver]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/auth_codex.py#L441-L690
[codex-status]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/auth.py#L2033-L2045
[status-tests]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/hermes_cli/test_oauth_status_pool_observation.py#L155-L227
[disconnect-handler]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_routers/oauth.py#L725-L768
[clear-auth]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/auth.py#L1367-L1387
[cli-logout]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/auth.py#L2414-L2498
[desktop-disconnect]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/app/settings/providers-settings.tsx#L494-L530
[dispatch-tests]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/hermes_cli/test_web_oauth_dispatch.py#L167-L465
[retry-tests]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/hermes_cli/web_routers/test_codex_device_login_transient_retry.py#L58-L86
[body-tests]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/hermes_cli/test_auth_codex_bounded_body.py#L48-L73
[gate-test]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/hermes_cli/test_dashboard_oauth_endpoints_server_gate.py#L24-L55
[save-test]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/hermes_cli/test_auth_codex_provider.py#L328-L347
[clear-test]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/hermes_cli/test_auth_commands.py#L768-L811
[owner-tests]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/store/onboarding-owner.test.ts#L119-L174
[external-capabilities]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/gateway/platforms/api_server.py#L67-L102
[external-test]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/gateway/test_api_server.py#L939-L963
