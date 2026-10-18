# ACCOUNT: OAuth expiry, logout and revocation evidence

Source-only lifecycle map for `DOC-ACCOUNT-REVOCATION-EVIDENCE`. Start with the
[acquisition contract](account-oauth-acquisition-contract.md) and
[ACCOUNT status](../product/hermes-desktop-parity.md#statuses).
**Wing account expiry/logout/revocation remains unavailable.** The bounded subject
is the same OpenAI Codex provider sign-in, not dashboard/remote-connection OAuth,
Hermes One/cloud accounts, account provisioning, credits, wallets or general pool
administration. Acquisition success is not lifecycle qualification.

## Scope and pins

The coordinator assigned this isolated task branch; no other task or candidate was
adopted. The task checkout contained no continuation/tracker lease file; this is
not a claim of remote tracker inspection or ownership release. No live request,
credential store, installed runtime, sign-in, refresh, logout, revocation,
provisioning or wallet operation was accessed. Tests below were **read, not run**.
Only tracked source, nearest tests and sanitized repository receipts were read.

Pins obtained independently with `git rev-parse HEAD` in each checkout/subtree:

| Inspected source | Commit | Evidence ceiling |
| --- | --- | --- |
| Wing task baseline | `2ddbb51b69044c71411e32168750a9a92db4c731` | Source/callers/tests and retained receipts, not executed Flutter behavior. |
| Hermes Agent reference | `158fd638da1629c8e62caf9ade1515d162def8ab` | Read-only handler/domain source; tracked files clean. Not a deployed capability promise. |
| Official Desktop subtree | `158fd638da1629c8e62caf9ade1515d162def8ab` | Same repository, independent subtree pin; product reference, not Wing authorization. |

Upstream citations are immutable at that pin. Local Wing line ranges refer to the
baseline above. This does not silently repin the acquisition study or claim the
latest upstream; revisit on source drift.

## Authority and outcome map

OpenAI controls acceptance/invalidation of its provider grants. Agent owns local
provider state, refresh and source resolution; Desktop displays the outcome.
Authentication of a client to Agent is separate from the provider's credential.

| Outcome | Handler/model and exact source behavior | Fail-closed proof or unavailable authority |
| --- | --- | --- |
| Unapproved device code expires | [Session model/constants][U1]:44–106 and [worker][U2]:236–339 use a 900-second polling window, then set `expired` without exchanging/saving when polling returns no approval. [GC][U3]:777–782 removes old registry entries on a later start. | Narrow source branch, **not** expiry of an already-issued access/refresh grant. Deadline is checked at loop entry, not an atomic provider-approval/save cutoff; an already-issued request can finish later. GC only pops entries, not a cancellation flag on a worker-held session. No durable rollback receipt follows timeout, missing session or restart. |
| Cancel pending acquisition | `DELETE /api/providers/oauth/sessions/{session_id}?profile=…`, [poll/cancel][U4]:844–897 checks the requested profile, marks the session cancelled under its lock, then removes it. [Worker][U2]:289–339 captures profile and checks cancellation before exchange and inside the final save lock. | [Codex race tests][T1]:272–465 show cancel-during-poll stops exchange/save, but save-already-holding-lock legitimately commits before DELETE finishes. Cancel removes a session, **not** credentials or remote grants. Shared cross-profile rejection test at :226–265 uses xAI, not a Codex end-to-end login. |
| Stored access token expires | [Expiry predicate][U5]:65–67 checks a numeric JWT `exp` against current time plus skew; [resolver][U6]:589–690 refreshes when forced/expiring except in `read_only` mode. [Status][U7]:2033–2045 uses `read_only=True`. | Missing/unparseable expiry is not a verified rejection. Status can intentionally say `logged_in:true` for an expired stored singleton: [status tests][T2]:155–227 forbid status-driven adoption/refresh. Presence is not remote validation, entitlement, revocation status or a reliable expiry countdown. |
| Refresh grant rejected | [Refresh error/POST path][U8]:441–575 shapes `invalid_grant`, reused-token errors and token-endpoint 401/403 as relogin-required; 429 is quota, invalid JSON on 200 is not classified as revoked. Rotated pairs are persisted through Agent. | Rejection is **not** a remote-revocation acknowledgement. Relogin-required errors may invoke the separate CLI recovery path below; without recovery the error is re-raised. [Quota tests][T3]:394–440 cover 429 classification, not live provider revocation. |
| Remove local provider state | `DELETE /api/providers/oauth/openai-codex?profile=…`, [disconnect][U9]:725–768, calls [clear][U10]:1367–1387 inside profile scope. It deletes that provider's singleton and **all** provider pool entries in the current store and clears its active marker. Returns `ok:true, provider`, or 409 if nothing cleared. | Not exact-credential removal, all-profile/device logout, external-store deletion or remote revocation. No revision, credential ID, in-flight cancellation barrier or durable idempotency receipt is supplied. [Shared clear test][T4]:768–811 proves local pool removal and sibling-provider preservation with Anthropic, not a Codex provider-side outcome. |
| CLI logout | [CLI][U11]:2414–2498 can reset selected model configuration as well as clearing provider auth. [Regression][T4]:814–840 resets Codex configuration even if auth state was already empty. | REST disconnect does not call CLI logout or reset configuration. CLI output must not be substituted for the REST receipt or for proof that subsequent inference is impossible. No CLI command was executed. |
| Provider-side revocation / other devices | The traced [disconnect][U9], [clear][U10] and [refresh][U8] call chains contain no OpenAI revoke operation, revocation acknowledgement or all-device/session invalidation result. | **Unavailable authority.** Local deletion cannot prove invalidation of copied grants, already-authenticated clients, other profiles/devices or provider sessions. The inspected routes do not establish a barrier against in-flight login/refresh saving again or erase a client's already-held credential. |

The serve mutation handlers call [`_require_token`][U12]:452–492. Application
[loopback middleware][U13]:696–715 and [gated middleware][U14]:153–210 protect
these `/api/` routes, including poll despite its misleading handler comment.
Gated mode can verify native bearer auth as well as cookies; these are not Wing's
external data-plane operation grants. [Gate regression][T5]:24–55 asserts 401 for
missing-cookie cancel only, not every lifecycle route or per-device revocation.

## Fallback authority after expiry or local removal

These are Agent runtime behaviors, **not permitted Wing fallback procedures**.
Deleting one local store entry does not establish that every resolver is empty.

| Source/race | Exact evidence | Consequence / proof ceiling |
| --- | --- | --- |
| Named profile → root singleton/pool | [Provider state resolver/transaction][U15]:830–866 falls back to root when no profile provider block exists; [pool read][U16]:952–979 falls back when profile rows are empty. [Codex pool helper][U17]:920–941 selects a nonempty token outside cooldown, not a provider-revocation check. | Clearing profile entries does not create a root-fallback denial/tombstone or source suppression. Root may still supply credentials. [Fallback regression][T6]:152–188 explicitly resolves the global Codex pool from empty profile state, then proves profile-row precedence. This is not a post-logout live test. |
| Refresh of a borrowed root grant | [Save][U18]:174–214 and [refresh][U8]:520–563 write rotated tokens back to the source store, not a profile copy; re-read under source lock adopts a peer's rotated pair. | [Write-through tests][T7]:44–147 cover source ownership and two threads posting the stale refresh token only once. Locking/rotation consistency is not logout serialization across processes, profile-incarnation protection or remote revocation. |
| Separate Codex CLI grant | [Recovery][U19]:217–256 requires automatic-adoption policy, both token values, an unchanged observed singleton, and no known conflicting principal. [Importer/resolver][U6]:565–638 considers recovery for malformed/missing token fields, **not** the wholly absent singleton `codex_auth_missing` case. Refresh rejection can also invoke recovery ([U8]:542–556). [Policy][U20]:32–48 defaults to adoption enabled. | [Recovery tests][T8]:103–189 cover opt-out refusal, known workspace mismatch and concurrent explicit reauth winning. Unknown principal is not a proven identity match. Do not generalize recovery into unconditional post-logout CLI adoption, or opt-out into provider-wide revocation. Status reads never invoke this recovery. |
| Runtime client already holds a grant | [Client refresh][U21]:570–605 refuses a singleton token mismatch and rejects unchanged-token “refresh”; [401 recovery][U22]:391–410 permits one provider refresh attempt per turn. [Recovery ordering][U23]:646–665 can first strip stale reasoning on a specific `token_expired` response. | [Runtime tests][T9]:84–135 demonstrate that signature is not always bearer expiry: cached reasoning can cause a single retry without refreshing/benching credentials; absent reasoning stays on auth recovery. No outcome here proves immediate cessation after local logout or provider revocation. Wing must not infer revocation from a 401 string, refresh UI error or a status badge. |

No selected test establishes the combined invariant “logout succeeded, therefore
no singleton/pool/root/CLI source or in-flight worker can supply a credential.”
This is an evidence gap, not an upstream patch request or a new shadow blacklist.

## Desktop and Wing callers

- **Desktop Accounts:** [typed DTOs][D1]:79–162 distinguish optional status expiry
  from device session expiry, but carry no revocation generation, exact credential
  identity or logout barrier receipt. Codex's [status projection][U24]:372–375
  supplies `expires_at=None`, `has_refresh_token=False` and a token preview; this
  is not a secret-safe Wing lifecycle DTO.
- **Desktop Remove/Disconnect:** [caller][D2]:494–530 asks for destructive
  confirmation, sends the scoped [DELETE][D3]:322–331, checks `ok`, then refreshes
  inventory. [Nearest UI tests][D4]:154–205 use mocked Nous responses to prove
  target profile, confirmation and dismissal; they do not prove Codex remote
  revocation, post-logout fallback denial or an owner-change race during removal.
- **Desktop device expiry/cancel:** [timer][D5]:214–232 is a local display
  deadline; [flow][D6]:895–983 polls server state and [cancel][D7]:1034–1045 is
  best-effort. [Expiry tests][D8]:947–1033 use a fake Nous device flow and timers,
  not an OpenAI TTL/revocation receipt. A displayed error/idle flow is not rollback.
- **Wing:** [provider model](../../lib/core/hermes/models/hermes_provider.dart):11–50
  has presence/auth type, no OAuth expiry/revocation receipt. The
  [provider row](../../lib/features/providers/screens/providers_screen.dart):502–595
  shows host-sign-in guidance and offers Manage only for API-key auth; the
  [regression](../../test/features/providers/providers_screen_test.dart):586–608
  asserts no API-key sheet for OAuth even with provider-write capability.
  [Client](../../lib/core/hermes/client/hermes_api_client.dart):621–677 and
  [channel](../../lib/core/hermes/channel/api_channel/hermes_api_channel_providers.dart):13–135
  implement different inventory/credential/validation operations, not OAuth
  disconnect/revoke. No account route appears in the
  [router](../../lib/router/providers/app_router.dart):60–225. Connection
  disconnect/removal and [route status](../product/routes.md) do not grant provider
  logout authority.

## Fail-closed disposition and receipt limits

**Exact missing Wing authority:** selected-profile provider expiry/revocation
observation and local logout with authoritative source/fallback, in-flight and
post-commit reconciliation semantics; separately, provider-side grant revocation
with its actual scope and acknowledgement. No exact advertised operation/grants
or qualified native contract for these outcomes was established. The inspected
external [capability table][U25]:67–102 omits the serve OAuth lifecycle operations;
its [nearest regression][T10]:939–963 checks model/run contracts, not account
lifecycle. A Desktop bridge, provider-write/admin flag, API-key DELETE or stored
`configured` flag does not supply the missing authority.

Keep account navigation and OAuth lifecycle controls absent. Do not fall back to
CLI execution, direct files, credential import, borrowed grants, provisioning,
wallet actions, legacy management or Agent modification. Preserve ordinary direct
Agent authentication, read-only provider/model paths and inert legacy user data.
This follows [API/state](../adr/api-and-state.md),
[security](../adr/security-and-privacy.md), the [threat model](../security/threat-model.md)
and [Agent immutability](../adr/runtime-and-delivery.md#hard-boundary-never-modify-hermes-agent).
No new wire fields, APIs or provider policy are proposed.

Sanitized receipt inspection did not supply lifecycle proof:

| Retained repository evidence | What it can establish | What it cannot establish |
| --- | --- | --- |
| [Acquisition contract](account-oauth-acquisition-contract.md#expiry-cancellation-logout-and-revocation-are-distinct) | Source-only acquisition/cancel limits and explicitly pending lifecycle proof. | Executed expiry, remote invalidation or logout/fallback closure. |
| [Remote auth explanation](remote-auth-explanation.md#remaining-milestone-gaps) | Named fixture-based direct Agent token UI/recovery evidence. | Provider OAuth, live authentication or physical secure storage. |
| [Daily workflow preparation](live-desktop-daily-workflow.md#acceptance-and-remaining-work) | Bounded no-inference/refusal and preparation checks, with an explicitly synthetic fixture extension. | Actual provider authentication, refresh/expiry/revocation or a live Desktop daily-use receipt. |

These are inspected Markdown receipts only; private artifacts, credentials and
provider services were not opened. No earlier pass is carried forward as a fresh
execution or as lifecycle acceptance.

## Verification, review and remaining qualification

Full applicable documentation gate (no runtime changes or new tests):

- `git rev-parse HEAD`, and `git -C <reference> rev-parse HEAD` in Agent and
  Desktop: the pins above; `git -C <reference> status --short --untracked-files=no`
  checks tracked-reference cleanliness.
- `python3 "$TMPDIR/check_account_lifecycle_docs.py"`: task-local static checker
  verifies 76 immutable citation ranges against pinned Git content in 29 upstream
  files, 31 local Markdown paths/anchors, and only the two owned document changes.
  It imports no Agent code and is not a shipped tool or runtime regression test.
- `git diff --check` and `git diff --cached --check`: tracked and staged whitespace
  checks, including the new document when staged. Flutter/build/E2E gates do not
  apply to this source-only documentation slice and were not run.

Independent contract/security review: a fresh-context read-only `reviewer`
verified the candidate against pinned handlers, resolver, tests, Wing callers and
security boundaries. **Approved for documentation-only scope**, with no critical
or important findings. One minor recovery-branch line citation was source-verified
and corrected; the importer citation was also expanded to include its declaration.
This review is not an independent security audit or runtime/product acceptance.

Only Linux-host source/document inspection was exercised; no app, Flutter,
upstream suite, browser or device execution. Pending separate live qualification:
actual OpenAI expiry/rejected refresh/provider invalidation, local logout followed
by authoritative root/pool/CLI resolution checks, in-flight login/refresh and
cross-process races, other-profile/device scope, current Agent advertisement and
named-platform secure-storage/end-to-end behavior. All remain **NOT_CHECKED**;
future qualification needs a separately authorized isolated target and private
authentication, not permission from this source study.

Update triggers: changes to the pinned session/worker/clear/status/refresh/fallback
paths, policy, Desktop callers/DTOs, external capabilities, Wing gates/routes or
living ADRs. Re-trace and independently review; do not silently transfer these
conclusions to another revision or provider.

[U1]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_routers/oauth.py#L44-L106
[U2]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_routers/oauth.py#L236-L339
[U3]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_routers/oauth.py#L777-L782
[U4]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_routers/oauth.py#L844-L897
[U5]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/auth_codex.py#L65-L67
[U6]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/auth_codex.py#L565-L690
[U7]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/auth.py#L2033-L2045
[U8]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/auth_codex.py#L441-L575
[U9]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_routers/oauth.py#L725-L768
[U10]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/auth.py#L1367-L1387
[U11]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/auth.py#L2414-L2498
[U12]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_server.py#L452-L492
[U13]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_server.py#L696-L715
[U14]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/dashboard_auth/middleware.py#L153-L210
[U15]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/auth.py#L830-L866
[U16]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/auth.py#L952-L979
[U17]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/auth_codex.py#L920-L941
[U18]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/auth_codex.py#L174-L214
[U19]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/auth_codex.py#L217-L256
[U20]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/agent/credential_sources.py#L32-L48
[U21]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/agent/client_lifecycle.py#L570-L605
[U22]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/agent/turn_recovery.py#L391-L410
[U23]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/agent/turn_recovery.py#L646-L665
[U24]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_routers/oauth.py#L372-L375
[U25]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/gateway/platforms/api_server.py#L67-L102
[T1]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/hermes_cli/test_web_oauth_dispatch.py#L226-L465
[T2]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/hermes_cli/test_oauth_status_pool_observation.py#L155-L227
[T3]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/hermes_cli/test_auth_codex_provider.py#L394-L440
[T4]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/hermes_cli/test_auth_commands.py#L768-L840
[T5]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/hermes_cli/test_dashboard_oauth_endpoints_server_gate.py#L24-L55
[T6]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/hermes_cli/test_auth_profile_fallback.py#L152-L188
[T7]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/hermes_cli/test_codex_token_writethrough.py#L44-L147
[T8]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/hermes_cli/test_auth_codex_self_heal.py#L103-L189
[T9]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/agent/test_codex_token_expired_replay_recovery.py#L84-L135
[T10]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/gateway/test_api_server.py#L939-L963
[D1]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/types/hermes.ts#L79-L162
[D2]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/app/settings/providers-settings.tsx#L494-L530
[D3]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/api/config.ts#L322-L331
[D4]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/app/settings/providers-settings.test.tsx#L154-L205
[D5]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/store/onboarding.ts#L214-L232
[D6]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/store/onboarding.ts#L895-L983
[D7]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/store/onboarding.ts#L1034-L1045
[D8]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/store/onboarding.test.ts#L947-L1033
