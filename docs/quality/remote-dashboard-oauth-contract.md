# Connection-specific remote dashboard OAuth contract

## Verdict and scope

`PARITYUPDATE-003-b1` · `ACCOUNT` · HD-OAUTH. **Source contract resolved;
Wing dashboard OAuth remains unavailable, unimplemented and unqualified.**
Start with the operation table, then the identity/cancellation and platform verdicts.
This closes the bounded [contract research](official-desktop-parity-refresh-2026-10-18.md#remote-oauth),
not the product gap. No login, browser authorization, cookie/credential acquisition,
refresh, logout, revoke, ticket mint, Agent modification or application change was performed.

Two authoritative dashboard paths exist at the pin: browser session cookies and
Agent-brokered native PKCE returning bearer tokens. Neither is an inference-provider
account flow. `/api/auth/providers` lists **dashboard login providers**, not model
providers. Keep [provider OAuth acquisition](account-oauth-acquisition-contract.md)
and [provider lifecycle](account-oauth-lifecycle-evidence.md) separate. Cloud's
portal discovery and shared-cookie cascade are another topology, not evidence that
an arbitrary Remote connection supports Cloud. Desktop exposes separate
`hermes:cloud:*` IPC operations; this study does not admit them. [A1, D4]

### Evidence identity

- Agent: `a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70`; official Desktop subtree:
  `cee4414aae0817b7ff45c76fbfd010dcd753ecf5`.
- Wing callers/tests: task baseline `bc8d991f048d5c0290392c72310076de9172092f`.
  The matrix's older global Wing pin remains historical; the OAuth row links this study.
- Read-only pinned Git blobs and live callers were inspected. Ledger ranges are
  inclusive and hashes cover **complete file bytes**, not excerpts. Sparse test
  blobs were read without checking them out. No source-current graph was available;
  direct tracing was used. Pins are checkout evidence, not a deployed release promise.
- All tests below are **inspected assertions, not executed protocol/runtime tests**.
  Comments describing encrypted storage or matching timeouts are not stronger than
  the actual implementations identified below.

## Operation-by-operation disposition

Paths below are Agent paths; an operator's normalized reverse-proxy mount may
prepend a prefix. These are observed contracts, **not instructions to call them**.
The dashboard authentication/session/ticket operations accept no Wing connection
ID, profile, Project or per-operation grant selector. Discovery `/api/status` does
accept optional `?profile=` for its separate config-scoped read; that is not an
authentication/profile grant. Dashboard Session identity and separate operation
authorization must not be conflated. [A1, A9, A10]

| Operation | Advertisement, input, authority and outcome | Nearest inspected tests / Wing disposition |
| --- | --- | --- |
| Discover `GET /api/status`; `GET /api/auth/providers` | Public status returns `auth_required`, registered provider names and `auth_flows`: gated mode advertises `cookie`, plus `native_pkce` when a session provider exists; nongated flows are empty. Provider list returns `{name,display_name,supports_password}` for interactive session providers, or 503 for none. Not an exact operation/grant catalog. [A1, A9] | Native flow status/chooser assertions [T1]; status assertion [T9]. Desktop probes these before choosing native versus embedded; all-password metadata chooses embedded even though Agent can broker password natively. Missing metadata follows Desktop compatibility logic, not Wing permission. [D4, D6] |
| Browser `GET /login`; `GET /auth/login?provider=…&next=…` | Login page is no-store. Known interactive OAuth provider starts upstream PKCE and redirects to its IdP with a server-set PKCE cookie; password provider returns to `/login`; unknown/noninteractive provider is 404. `next` is revalidated as a safe same-origin path, not an arbitrary URL. [A1, A5] | Callback/redirect helper and invalid-code rejection [T1, T10]. Wing has no embedded dashboard login/cookie client; token entry is not equivalent. |
| Native `GET /auth/native/authorize` | Query: optional `provider`, nonempty `code_challenge`, S256 `code_challenge_method`, validated loopback `redirect_uri`, optional client `state`. One session provider auto-selects; multiple render a no-store chooser before broker allocation. Server stores pending challenge/redirect/client state; PKCE cookie carries provider/broker plus upstream state/verifier. Invalid URI/method is 400, unknown provider 404, unavailable capacity 503. Password branch redirects to `/login`. [A1, A2] | Chooser/password and canonical IPv4/IPv6 authority cases [T1]. This is **authorize**, not an invented `/start`; no Wing callback/deep link is admitted. |
| Browser return `GET /auth/callback` | Requires PKCE cookie, registered cookie provider and exact nonempty upstream state; `next`/broker are read from that cookie, not callback query. Provider completes login. Ordinary path sets session cookies and redirects to safe landing. Native path instead consumes pending broker and redirects to saved loopback URI with one-use `code` plus original client `state`, **no session cookies**. PKCE/SSO guard cleared. Invalid state/code is 400; provider outage 503. [A1, A2] | Stub callback and URI roundtrip [T1], invalid-code rejection [T10]. Client must independently validate its own returned state. This handoff code is not a bearer token. |
| Browser form `POST /auth/password-login` | JSON `{provider,username,password,next?}`. Returns `{ok:true,next}` plus session cookies; with native broker cookie returns loopback code/state and clears PKCE instead. Broker provider must equal submitted provider before credential verification. Invalid credentials 401, mismatched broker provider 400, unknown provider 404, throttle 429, outage 503. [A1] | Password ordinary/native, wrong password, expired broker and cross-provider cases [T1]. Password acquisition is not added to Wing. |
| Exchange `POST /auth/native/token` | JSON `{code,code_verifier}`; returns `{access_token,refresh_token,token_type:"Bearer",expires_at,provider,user_id}` without cookies. Code is popped **before** S256 verification; bad/expired/replayed code is generic 400. No `redirect_uri` or `client_id` exchange field. [A1, A2] | Successful exchange and cookieless bearer identity [T1]. Broker single-use/TTL behavior is handler evidence; the inspected native-flow test file does not independently assert every broker failure branch. No general no-store token-response guarantee is established by these handlers. |
| Use identity `GET /api/auth/me` / authenticated REST | Gated middleware verifies bearer with dashboard session providers and does not read/set cookies or refresh that bearer. Cookie path can rotate RT and reissue cookies; outage preserves them. `me` projects user/email/display/org/provider/expiry, not tokens. Nongated `me` requires legacy session-token validation and honestly reports loopback identity. [A1, A4] | Cookieless bearer [T1], identity/middleware cases [T10]. A verified Session contains user/org/provider/issuer, not fine-grained grants or a profile binding. `TokenPrincipal.scopes` is a **different** service-token seam. [A10] |
| Refresh `POST /auth/native/refresh` | JSON `{refresh_token,provider?}`; same token payload, no cookies. Empty RT 400; all candidates reject → 401 `session_expired`; no success and provider unreachable → 503. Provider name is an **ordering hint**, not issuer binding: dispatch may try other registered session providers. Shared rotation coalesces by concrete provider instance plus RT digest. [A1, A5, A11] | Wrong/unknown hint, outage versus rejection, concurrent rotation and provider replacement [T4]. No token expiry countdown, entitlement, model readiness or cross-device logout follows from stored presence. |
| Per-dial `POST /api/auth/ws-ticket`, then WS `/api/ws` | Requires verified **Session**; returns `{ticket,ttl_seconds:30}`. Process-local, single-use ticket records user/provider/optional issuer, not connection/profile/session/path grants. Gate accepts query ticket or both subprotocols `hermes-gateway-v1` + exactly one `hermes-gateway-ticket.<ticket>`; selects only public protocol. Reuse/invalid/expired fails. [A1, A7, A8, A12] | Authenticated versus missing session/GET [T2]; expiry/single-use [T3]; paired-protocol ambiguity/reuse [T2]. Mint fresh for every dial; never cache/replay the ticket on reconnect. Not the private local control `interactive` ticket or `X-Hermes-Gateway-Ticket` contract. See [canonical attachment](canonical-gateway-attachment-contract.md). |
| Agent `POST /auth/logout` | Reads **RT cookie**, best-effort invokes registered providers' `revoke_session`, clears session/provider/PKCE cookie variants, redirects to prefix `/login`. It does **not** accept a native RT JSON body or offer a native bearer-revoke operation. [A1, A3] | Cookie rejection/identity assertions [T10] are adjacent, not logout or native revoke proof. Nous and Basic revoke are no-ops; self-hosted optionally POSTs advertised RFC7009 endpoint, ignores errors and does not check response status. [A13–A15] Local removal is not authoritative remote invalidation, browser IdP logout or termination of existing WS/runs. |

### Origins and redirects: precise restrictions, not a generic same-origin claim

The upstream IdP callback is the configured `dashboard.public_url` plus
`/auth/callback`, otherwise request `url_for` plus normalized forwarded prefix.
The native return is a **canonical HTTP loopback IP literal** (`127.0.0.1` or
`[::1]`, optional canonical port); no `localhost`, custom app scheme, HTTPS return,
userinfo, backslash, non-ASCII/control or fragment. Empty path becomes `/`;
existing path/query is retained. Client `state` is echoed, not server-validated.
Desktop binds its listener to `127.0.0.1` on an ephemeral port at `/callback`,
validates state before redeeming, answers with a token-free close page and closes
on completion/error/timeout. Its callback parser does not enforce a distinct
request path; a future Wing listener must define its exact callback admission.
[A1, A6, D6, D12, T1, T6]

HTTP Host checks use bound/operator-declared hostnames. CORS permits local HTTP(S)
localhost/127.0.0.1 origins, **not arbitrary Wing web origins**. Native endpoints do
not establish a route-local exact-Origin allowlist. The dashboard WS gate accepts
absent/non-web origins; HTTP(S) Origin is checked by hostname authority against
bound/public hosts, not exact scheme/port equality; wildcard binds accept valid
host authorities. These server rules do not relax Wing TLS, origin-bound credential
or nonlocal-HTTP consent policy. No blanket Origin stripping, credential-bearing
redirect following or custom callback scheme may be copied into Wing. [A12, A16, T2]

## Connection identity, persistence and target fencing

| Boundary | Observed guarantee and exact limit |
| --- | --- |
| Draft before Save | Registry supplies `connectionId`, label, kind and authMode; native main settles explicit trimmed ID or label-derived unique ID. Successful current completion pins returned ID into draft for Save reuse. Agent does not know this ID. [D1, D3, D4, D9, T8] |
| Cookie partition | Non-primary registry `remote` + `oauth` gets `persist:hermes-remote-oauth-conn-<sanitized-id>`; login draft and saved read must resolve to the same jar. Primary/v1, Cloud, token-mode and unmatched/invalid inputs use legacy shared jar. URL resolution uses longest base-prefix and deterministic ID tie-break, so URL alone cannot distinguish equal-URL connections. Cookies ignore port; a different port is not isolation. [D5, T5] |
| Native token identity | **Normalized base URL**, not connection ID, keys native token map/store and refresh/login epochs. Connection-specific cookie isolation does not prove per-connection native credential isolation. User/provider metadata comes from token response; it is not profile/session selection. [D4, D7] |
| Credential persistence | Desktop's native-store injection writes its token set through `encryptDesktopSecret`. Despite nearby encrypted-store comments, actual policy defaults encryption **off** and returns `encoding:'plain'` when off. Cookie jars are persistent Electron sessions; no Wing-grade secure-storage guarantee follows from them. Wing must not copy this persistence policy. [D4, D13] |
| Ephemeral handoff | Broker pending/code are in memory only (600s/120s; process restart loses them). Desktop waits **5 minutes**, not the server's 10-minute pending TTL despite its matching-timeout comment. PKCE verifier stays transient until JSON exchange; browser sees one-use code/state, not bearer/refresh tokens. Never persist codes/verifiers/tickets, put bearer credentials in URLs/argv/clipboard/preferences/logs, or expose raw upstream errors. [A1, A2, D12] |
| Browser cookies | Session AT/RT/provider cookies are HttpOnly, Lax, mount-path scoped; HTTPS adds Secure and root `__Host-` or prefixed `__Secure-` names. PKCE is 10-minute HttpOnly (HTTPS SameSite=None); its payload is base64url JSON, not encrypted custody. RT cookie's 30-day Max-Age is a browser bound, not provider lifetime; AT Max-Age is expiry-derived with 60s floor. [A3, A5] |
| Fresh dial | Desktop main mints each time and returns a ticket URL; its renderer strips the ticket only when the URL has the `native_dial` marker, so remote OAuth's query-ticket path is **not** proof of URL-free secret delivery. Wing's existing loopback reader already has a subprotocol-only dial, but not dashboard OAuth acquisition or remote native token refresh. [D4, D10, D14, W6] |

### Cancel, stale target and sign-out outcomes

- **Editor fences:** sign-in/out invalidates a prior connection test and captures
  both target sequence and login sequence. URL/auth-mode/reset/unmount invalidates
  target; late completions cannot mark another editor connected, pin its draft ID
  or post a success notice. The nearest hook test proves unmount suppression, not
  backend cancellation or remote revocation. [D1, D2, D11, T7]
- **Native fences:** main captures a URL-keyed login epoch before probing and checks
  it before opening browser and before storing tokens. Newer login/logout wins;
  refresh has its own auth epoch and single flight. Beginning login does not erase
  an otherwise valid concurrent refresh; a confirmed store or logout supersedes
  it. Other base URLs remain independent. [D4, D7, T11]
- **Cancel is not rollback:** closing embedded window before observed cookie rejects;
  native browser abandonment times out and tears down the local listener. Neither
  editor invalidation nor these handlers expose an Agent cancel/reconcile operation
  for the broker. Editor retarget alone does not cancel main's original URL-keyed
  browser/token acquisition; cookies/tokens may already have landed for that original
  target. Pending server state expires; no revoke/credential rollback is proven.
  Failed native strategy reports failure rather than opening an embedded fallback
  window automatically. [A1, A2, D1, D4, D12, T6, T7]
- **Desktop sign-out:** UI passes URL only to `oauthLogoutConnectionConfig`; no
  connection ID/kind/draft identity is passed. Main clears URL-keyed native tokens
  **before** awaiting best-effort URL-resolved cookie removal, then reports live
  cookie/native presence. It does not call Agent `/auth/logout`. UI hook nevertheless
  marks its current editor disconnected after resolved IPC without checking returned
  `connected`. Do not claim exact-draft jar erasure, complete cookie/mirror cleanup,
  server revocation or sign-out of another device. [D1, D4]
- **Reconnect/denial:** Desktop tickets use native bearer first, bounded refresh for
  structured 401 (not 403), then its cookie fallback policy; `NativeAuthChangedError`
  prevents crossing to a replacement identity's cookie jar. Generic submitted REST
  mutations are not replayed; special pre-handler cookie 401 recovery is restricted
  to read/idempotent or explicitly ticket-safe operations. This is source behavior,
  not permission for Wing automatic login, mutation replay, Cloud recovery or fallback
  to local Agent after remote failure. [D8]

Required identity for any future bounded Wing design is captured saved connection
ID + validated origin/mount/transport + attempt generation + chosen dashboard
provider/user; explicit Agent profile/session identities remain separate on domain
requests. A changed origin or identity must not inherit a previous credential.
Account storage, per-dial credentials, browser handoff and local forget versus
remote revoke must have separate receipts. These are **design admission criteria**,
not newly invented wire fields or an approved implementation task.

## Wing and platform disposition

Wing's public connection model has one optional Agent bearer key, not a cookie
partition, native OAuth token-pair schema or broker callback. API config emits
Bearer authorization; secure endpoint storage commits the endpoint set including
keys in platform secure storage, with only nonsecret compatibility metadata in
preferences. Exact-ID edits and origin collision rejection preserve other saved
rows. Existing Remote copy/test explicitly says browser OAuth and OAuth-only servers
are unsupported and distinguishes Agent tokens from management/provider keys.
The router composes no remote dashboard OAuth return route. [W1–W5, W7, W8]

The separate native-serve reader POSTs `/api/auth/ws-ticket` with the supplied bearer
and dials with two subprotocols, no network URL credential, refusing REST redirects.
It is restricted to literal loopback HTTP and does not acquire dashboard cookies
or native token pairs. A ticket fixture or generic Agent token does not establish
that the pinned dashboard's verified-Session requirement is satisfied. [W6, A1]

| Target | Feasibility / unavailable outcome under current boundaries |
| --- | --- |
| Linux desktop | Server's native loopback broker is a plausible **future** direct-Agent composition, conditional on runtime flow advertisement and separate bounded client work: private PKCE/state callback, secure-storage-only token pair, exact target fencing, rotation and honest local logout. Not implemented or qualified. Do not port Electron's optional plaintext store or cookie jar as secure storage. |
| Android | A native loopback return may be investigated only in a separate bounded task with actual browser/background/return and secure-storage evidence. The pinned server does not accept a custom-scheme/app-link redirect. No existing callback or background-listener guarantee is established; manual Termux preparation and current direct Agent authentication stay unchanged. No shared Termux filesystem/control authority is inferred. |
| Web | Current browser cannot adopt Electron partitions/native secret IPC; arbitrary deployed Wing origin is not in the inspected local CORS policy. No accepted browser-return/cookie isolation, CORS/token handoff or secure custody contract for remote OAuth is established. Keep unavailable; no proxy, permissive CORS workaround, localStorage token store or cookie scraping. |
| Other native desktop / SSH | RFC8252 source is not Windows/macOS runtime evidence. SSH forward authenticates transport/host, not dashboard account/IdP or native broker authority. Preserve the selected endpoint/profile and reviewed host key; no service startup, private control-ticket mint or topology switch. |
| Cloud / provider accounts | Portal discovery/org selection/shared cookie cascade and inference-provider acquisition/revocation remain separate owners/contracts. HD-OAUTH source resolution does not implement HD-CLOUD or provider login. |

There is **no implementation-ready connection-specific OAuth successor** admitted
here: URL-keyed native storage/logout, draft-cookie logout targeting, cancel outcome,
secret-safe error/cache policy and platform custody/return still need a separately
bounded Wing design over unmodified advertised contracts. If authoritative remote
revocation is required, the pin lacks a native revoke operation and universal provider
invalidation guarantee; keep that operation unavailable rather than simulate it.
These limits do not block existing Android SSH → profiles/multi-session → canonical
Bot Chat → touch work, deferred Files/slash work or retained live owners.

## Documentation validation and update triggers

The complete offline gate for this documentation-only change is whitespace check,
matrix JSON parse, source-ledger path/range/whole-file-hash verification against
pinned Git, changed local links, operation-to-handler/nearest-test review and
preservation of every Linux/Android runtime cell. No Flutter/Agent/browser/native
suite was executed or required by this source-only task. No platform was exercised
beyond Linux-host source/document validation. Device/browser lifecycle, secure
storage, actual deployed advertisement, authorized isolated login/refresh/cancel/
logout/revocation and Cloud/provider service behavior remain pending live work,
not failed offline checks and not qualification claims.

Independent read-only review found no critical/important documentation issue.
Verified minor corrections distinguish status read-profile scope from auth inputs
and the renderer's actual `native_dial` predicate from a guessed auth-mode check;
the policy-default owner and timeout comment now have exact ledger ranges. Review
is source accuracy evidence only, not authentication or platform acceptance.

Revisit when the Agent pin, dashboard auth advertisement/provider/redirect/refresh/
logout/ticket handlers, Desktop draft partition/native persistence/epoch policy, or
Wing connection/storage/router changes. Retrace callers **and** nearest tests;
never repin hashes alone or promote existing fixtures into authentication evidence.

## Pinned source ledger

`A`/`D`/`T` use the Agent commit above; `W` uses the Wing baseline above. Each ID
links an immutable source range; where several ranges occur, the ledger lists the
exact inspected ranges and the URL spans their outer bounds. Hashes are whole-file
SHA-256. Test references name assertion evidence only; missing cancel/native-revoke
assertions are explicit limits, not implied coverage.

<!-- source-ledger:start -->
| ID | Source path | Inclusive ranges | Whole-file SHA-256 |
| --- | --- | --- | --- |
| A1 | `hermes_cli/dashboard_auth/routes.py` | `57-379,439-617` | `b88945b2586de1288875ba1da6d8923d07bf34c1c97b16861e42e7d9633fdd08` |
| A2 | `hermes_cli/dashboard_auth/native_flow.py` | `28-158` | `7b281b1def4aa02b882e29e6c2e870a7babc3bdb575745a20d904f621df8bf38` |
| A3 | `hermes_cli/dashboard_auth/cookies.py` | `27-176` | `09f589b8725a12a0621cfb971100587c82844fcae6a32a276c586076b4c8c4c9` |
| A4 | `hermes_cli/dashboard_auth/middleware.py` | `160-241` | `4036350adce2e6711dba2a1448abe94450f80b8275df82f9acad4257c4add2cf` |
| A5 | `hermes_cli/dashboard_auth/request_utils.py` | `19-93` | `243d5a929b8b37f2694263448ff624751f81082755f1a5efda83f0e4bf062f24` |
| A6 | `hermes_cli/dashboard_auth/prefix.py` | `61-130` | `0d10b586c05b3b07cfd439cd42dd44ee75dae91ce80dd2b58ae4e8fca2a713fb` |
| A7 | `hermes_cli/dashboard_auth/ws_tickets.py` | `20-64` | `c0a1a63623df7c7291d06a85c18f583ab112fa8b73ccc6359bbdbbd938f376a7` |
| A8 | `hermes_cli/web_server_chat.py` | `200-340` | `9517bf55c0ef12927c4421108e1439e6204bb5bb8fb50cb3aa22a42cc19bd64f` |
| A9 | `hermes_cli/web_routers/status.py` | `383-405,482-522` | `91d723e7db56ae3c22c4b98eb964e01ea9e2d11d6e209f612d891a951068449b` |
| A10 | `hermes_cli/dashboard_auth/base.py` | `9-40` | `0dfe82598713fc051b9fadc4c906fe66fb5abbfa11702cb768b0bea95802ba30` |
| A11 | `hermes_cli/dashboard_auth/refresh_singleflight.py` | `25-107` | `de92d417facde1f509610c1788c11d6e3f648bfaaa95545e240bbc0612cf0f2c` |
| A12 | `hermes_cli/web_server_boundary.py` | `29-103,151-218` | `3ba907a2a653d1a6646ad44b3fb07dbfd6a30cb0507d6d175a285079caca8ea5` |
| A13 | `plugins/dashboard_auth/nous/__init__.py` | `63-70` | `f4265267fc4a5358da003586f925b959544a6b28723f65d5856982cc10e5df74` |
| A14 | `plugins/dashboard_auth/basic/__init__.py` | `139-179` | `0d9942552cbce8ec2f71c7c97b6c926d5a3236f3fb639b1c2913c8de21a0acad` |
| A15 | `plugins/dashboard_auth/self_hosted/__init__.py` | `124-143` | `445da06266065691d4936688812cd6787736cb4a4775dce196e15e62973ccb5b` |
| A16 | `hermes_cli/web_server.py` | `381-398,561-575` | `f714b6d06ab22663887ce1e7ff092c2ddc73fab7b3254b567bd1d41f0aff670b` |
| D1 | `apps/desktop/src/components/remote-setup/use-remote-oauth.ts` | `45-163` | `13a9251ef6935f198301e81d4847bfe17eef8f349966a6af4050393bfe47f015` |
| D2 | `apps/desktop/src/components/remote-setup/use-remote-setup.ts` | `140-210` | `bcd82eb02ce0310a48a3e6687d4f47909428cdd7d803a835d60ea3d48bdd8520` |
| D3 | `apps/desktop/src/app/settings/connections-registry.tsx` | `248-266,333-351` | `d5010acfb67f7a747ffeaece80c569873656c53847958fb77af5a66ba6a37585` |
| D4 | `apps/desktop/electron/main.ts` | `7090-7117,7197-7490,7638-7742,7877-7923,8127-8147,8361-8369,15601-15789` | `5f164c5048afacc77ad1ee015b80a02d203c55325ed373b40f4d5969dcb0836b` |
| D5 | `apps/desktop/electron/oauth-partition.ts` | `44-248` | `fa312be37ff8fb5b19ff27d3c53fc42f1bad025aef16a3c2a20d80b60a583d4a` |
| D6 | `apps/desktop/electron/native-oauth.ts` | `78-193` | `9f69b147b9d13a2b7997652edea1ef8077efca1e840568424ffc4527a29d619e` |
| D7 | `apps/desktop/electron/native-access-token.ts` | `25-134` | `32cc1e517e8dbc70a0dac2f0d164f2422fcdf35227262bb90e2f8e536beba47c` |
| D8 | `apps/desktop/electron/oauth-rest-request.ts` | `14-186` | `28d6184e63c6cc5df637da0b1ff0101d03fb30f0dfc4bee0a3c20e27effd8ba7` |
| D9 | `apps/desktop/electron/connection-registry.ts` | `888-914` | `a390d5a08dffec2198672bf416f7a90090ce90cc6e89589605a68c7b3962a81b` |
| D10 | `apps/desktop/src/api/client.ts` | `510-536` | `d32cbc9442865dcab9d0a8d85176c4ea71f08af5b1c6b1b29079fc8c13252c9d` |
| D11 | `apps/desktop/src/components/remote-setup/use-remote-probe.ts` | `45-84` | `868245610e8cb6085b06d68d971d783a6592712392b1a6082b97d3f9e6a9b56f` |
| D12 | `apps/desktop/electron/native-oauth-login.ts` | `41-215` | `d60b2d47071c608e53ae49e1983f727765fc1be15162c2001d05147708f9420d` |
| D13 | `apps/desktop/electron/secret-storage-policy.ts` | `47-65` | `a88c91d1fae45888dc41d12a20a0b69872359b6c9883e38b82b2c5bd3afb8302` |
| D14 | `apps/desktop/electron/connection-config.ts` | `92-98` | `df60bd8f115822b316832e63638e23030595f6c374a33fd497c43af07b0fc225` |
| T1 | `tests/hermes_cli/test_dashboard_auth_native_flow.py` | `151-209,260-372,384-394,437-469,486-729` | `89d1b3258d8c258a3a5c74aa4978e14ca8d277aaba683193627eae20ce732803` |
| T2 | `tests/hermes_cli/test_dashboard_auth_ws_auth.py` | `116-151,217-263,457-504` | `d8ea4a8a5781e7aacf1e85650e3a0c179844885646279508aae70acd469a1b71` |
| T3 | `tests/hermes_cli/test_dashboard_auth_ws_tickets.py` | `37-105` | `031e5de8e1e46b4a98c886b4ef7a43c81316400341d5a8b1766edfcfc773f235` |
| T4 | `tests/hermes_cli/test_refresh_singleflight.py` | `54-159` | `8f79e7e86283fbf763e97954ee73cafbae51b96f70ebad08e1de58c7f32bc801` |
| T5 | `apps/desktop/electron/oauth-partition.test.ts` | `24-165,168-299` | `ad0fe259d1762626b75708c58e3366e4415048c384cd16060323c23781f5499e` |
| T6 | `apps/desktop/electron/native-oauth-login.test.ts` | `51-173` | `9ba74fc9bc881fd1cd4e107c8bb75d7fc91e3e41f8f761f530882c6e13044eb1` |
| T7 | `apps/desktop/src/components/remote-setup/use-remote-setup.test.tsx` | `30-90` | `a8e58a458b40d3c9c7fcb231dcaeb7f8e5079a3a7799a40413a454d8ed6f0bff` |
| T8 | `apps/desktop/electron/connection-registry.test.ts` | `655-708` | `8ffb2278a58411ffac75700032fe29a3b0a6ae691a9452a207a6a85725c61d5b` |
| T9 | `tests/hermes_cli/test_dashboard_auth_status_endpoint.py` | `58-91` | `c7b4b98adafa797aa0ce8e6162d85f9a1e6bdcaa8f69c1a807ae10cb1424d6c1` |
| T10 | `tests/hermes_cli/test_dashboard_auth_middleware.py` | `266-314,326-350,374-413` | `393b4b53ddfa06a03f6464b6a95aae67edb4e10f32ebe519a73290a3a5602481` |
| T11 | `apps/desktop/electron/native-access-token.test.ts` | `103-224` | `5943d2b342bae9b6df117287549a1a18b8eeb42d46a0280206a45e73abe5d8e7` |
| W1 | `lib/core/hermes/setup/hermes_endpoint_store.dart` | `7-60` | `e129b4fa28377cc3e0ada14a00ed2b761e683db4255bae0db06e5ad4061922fc` |
| W2 | `lib/core/hermes/setup/secure_hermes_endpoint_store.dart` | `8-178` | `d98b7c53eca4f3b90d9d84dbf4d8816ef0413fa3a70991f1031e5ee2563e2175` |
| W3 | `lib/core/hermes/client/hermes_api_config.dart` | `133-161` | `ec818a5ee9de04b49c4657d97d0590f79d04a131c05e21e4a9783468d8e364cc` |
| W4 | `lib/features/hermes_chat/controllers/hermes_connection_form.dart` | `6-157` | `45f0de7f4a05f21c555f5fec8426d6ab76a0fd03dea53bf95916bc21a9b03233` |
| W5 | `test/features/hermes_chat/screens/hermes_remote_auth_explanation_test.dart` | `31-82` | `768095d39ebead20469dd701cf9bd484dd4ab1badf761503c1cc58c25c0c124d` |
| W6 | `lib/core/hermes/client/hermes_web_read_client.dart` | `27-75,200-320` | `02679882860915ba8c1ff90a8abaad8ccdbf9b9ae420f7c3d355714e0ccd43f3` |
| W7 | `test/core/hermes/setup/saved_endpoint_edit_store_test.dart` | `26-72` | `9a113c798ffdbbe43a4519bd772d4ff3ac5f3fbe5975926805e0b0a7e7318b08` |
| W8 | `lib/router/providers/app_router.dart` | `60-225` | `3543fa91c3c67618ae210039d245a005a343a26da8ea9249b936577e2710c119` |
<!-- source-ledger:end -->

[A1]: https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/hermes_cli/dashboard_auth/routes.py#L57-L617
[A2]: https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/hermes_cli/dashboard_auth/native_flow.py#L28-L158
[A3]: https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/hermes_cli/dashboard_auth/cookies.py#L27-L176
[A4]: https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/hermes_cli/dashboard_auth/middleware.py#L160-L241
[A5]: https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/hermes_cli/dashboard_auth/request_utils.py#L19-L93
[A6]: https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/hermes_cli/dashboard_auth/prefix.py#L61-L130
[A7]: https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/hermes_cli/dashboard_auth/ws_tickets.py#L20-L64
[A8]: https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/hermes_cli/web_server_chat.py#L200-L340
[A9]: https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/hermes_cli/web_routers/status.py#L383-L522
[A10]: https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/hermes_cli/dashboard_auth/base.py#L9-L40
[A11]: https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/hermes_cli/dashboard_auth/refresh_singleflight.py#L25-L107
[A12]: https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/hermes_cli/web_server_boundary.py#L29-L218
[A13]: https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/plugins/dashboard_auth/nous/__init__.py#L63-L70
[A14]: https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/plugins/dashboard_auth/basic/__init__.py#L139-L179
[A15]: https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/plugins/dashboard_auth/self_hosted/__init__.py#L124-L143
[A16]: https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/hermes_cli/web_server.py#L381-L575
[D1]: https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/apps/desktop/src/components/remote-setup/use-remote-oauth.ts#L45-L163
[D2]: https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/apps/desktop/src/components/remote-setup/use-remote-setup.ts#L140-L210
[D3]: https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/apps/desktop/src/app/settings/connections-registry.tsx#L248-L351
[D4]: https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/apps/desktop/electron/main.ts#L7090-L15789
[D5]: https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/apps/desktop/electron/oauth-partition.ts#L44-L248
[D6]: https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/apps/desktop/electron/native-oauth.ts#L78-L193
[D7]: https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/apps/desktop/electron/native-access-token.ts#L25-L134
[D8]: https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/apps/desktop/electron/oauth-rest-request.ts#L14-L186
[D9]: https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/apps/desktop/electron/connection-registry.ts#L888-L914
[D10]: https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/apps/desktop/src/api/client.ts#L510-L536
[D11]: https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/apps/desktop/src/components/remote-setup/use-remote-probe.ts#L45-L84
[D12]: https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/apps/desktop/electron/native-oauth-login.ts#L41-L215
[D13]: https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/apps/desktop/electron/secret-storage-policy.ts#L47-L65
[D14]: https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/apps/desktop/electron/connection-config.ts#L92-L98
[T1]: https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/tests/hermes_cli/test_dashboard_auth_native_flow.py#L151-L729
[T2]: https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/tests/hermes_cli/test_dashboard_auth_ws_auth.py#L116-L504
[T3]: https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/tests/hermes_cli/test_dashboard_auth_ws_tickets.py#L37-L105
[T4]: https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/tests/hermes_cli/test_refresh_singleflight.py#L54-L159
[T5]: https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/apps/desktop/electron/oauth-partition.test.ts#L24-L299
[T6]: https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/apps/desktop/electron/native-oauth-login.test.ts#L51-L173
[T7]: https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/apps/desktop/src/components/remote-setup/use-remote-setup.test.tsx#L30-L90
[T8]: https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/apps/desktop/electron/connection-registry.test.ts#L655-L708
[T9]: https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/tests/hermes_cli/test_dashboard_auth_status_endpoint.py#L58-L91
[T10]: https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/tests/hermes_cli/test_dashboard_auth_middleware.py#L266-L413
[T11]: https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/apps/desktop/electron/native-access-token.test.ts#L103-L224
[W1]: https://github.com/TrebuchetDynamics/hermes-wing/blob/bc8d991f048d5c0290392c72310076de9172092f/lib/core/hermes/setup/hermes_endpoint_store.dart#L7-L60
[W2]: https://github.com/TrebuchetDynamics/hermes-wing/blob/bc8d991f048d5c0290392c72310076de9172092f/lib/core/hermes/setup/secure_hermes_endpoint_store.dart#L8-L178
[W3]: https://github.com/TrebuchetDynamics/hermes-wing/blob/bc8d991f048d5c0290392c72310076de9172092f/lib/core/hermes/client/hermes_api_config.dart#L133-L161
[W4]: https://github.com/TrebuchetDynamics/hermes-wing/blob/bc8d991f048d5c0290392c72310076de9172092f/lib/features/hermes_chat/controllers/hermes_connection_form.dart#L6-L157
[W5]: https://github.com/TrebuchetDynamics/hermes-wing/blob/bc8d991f048d5c0290392c72310076de9172092f/test/features/hermes_chat/screens/hermes_remote_auth_explanation_test.dart#L31-L82
[W6]: https://github.com/TrebuchetDynamics/hermes-wing/blob/bc8d991f048d5c0290392c72310076de9172092f/lib/core/hermes/client/hermes_web_read_client.dart#L27-L320
[W7]: https://github.com/TrebuchetDynamics/hermes-wing/blob/bc8d991f048d5c0290392c72310076de9172092f/test/core/hermes/setup/saved_endpoint_edit_store_test.dart#L26-L72
[W8]: https://github.com/TrebuchetDynamics/hermes-wing/blob/bc8d991f048d5c0290392c72310076de9172092f/lib/router/providers/app_router.dart#L60-L225
