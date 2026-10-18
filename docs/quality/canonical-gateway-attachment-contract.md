# Canonical gateway attachment and recovery contract

## Verdict and scope

`PARITYUPDATE-001-aa` · `CONNECTION-PATHS` · HD-LOCAL, HD-HOSTS, HD-RESUME.
**Source contract resolved; canonical native attachment is not implemented or qualified in Wing.**

Start here: the operation table below, then the Wing incompatibilities. This is
read-only contract research under the [accepted refresh](official-desktop-parity-refresh-2026-10-18.md#gateway-attachment),
not permission to ensure/start/restart a gateway, mint a ticket, install a runtime,
change UI, or run the inspected tests. No Linux/Android runtime cell advances.

The pin supports a same-user **attach-only protocol composition**: authenticate a
live private control endpoint, identify its served profile and owner, obtain a
fresh purpose-bound grant, then attach a viewer to that existing authority. That
is a future bounded native integration, **not an advertised remote discovery API
or Wing's current bearer-token path**. Desktop's `gateway ensure --json` is not a
safe substitute: Agent can start a service/unmanaged owner and replace an old
incompatible owner; Desktop additionally requests stale-code restarts. [A1] [D1] [D2]

### Evidence identity

- Agent commit: `a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70`;
  official Desktop subtree: `cee4414aae0817b7ff45c76fbfd010dcd753ecf5`.
- Wing implementation/tests inspected at task baseline
  `2ddbb51b69044c71411e32168750a9a92db4c731`. The matrix's older global Wing
  inspection pin remains historical; these three rows link this newer study.
- References below bind **whole-file SHA-256 plus exact inclusive line ranges**.
  Missing sparse-checkout blobs were read from the official raw URL at the same
  commit into task-temporary storage and verified against the pinned Git tree's
  blob IDs. No Agent source, installed runtime or personal service was changed.
- Tests are inspected assertions, **not executed protocol/runtime evidence**.
  Upstream guides still contain older serve-child descriptions; the live pinned
  handlers/callers, not those comments, determine the dispositions below.

## Operation-by-operation disposition

| Operation / transport | Advertisement, authority and exact identity | Disposition for Wing |
| --- | --- | --- |
| Local discovery: private newline JSON control request `{protocol:1,id:1,verb:"identify"}` | `query_identify` authenticates socket metadata/peer; `discover_gateway_endpoint` validates `runtime_protocol == 1`, `session-authority-v1`, positive `authority_epoch`, nonempty `instance_id`, exactly one matching canonical home in `served_profiles`, bare loopback `api_origin`, and supervisor. `GatewayEndpoint` carries `profile_id`, `control_home`, `code_sha`; **the actual field is `control_home`, not a guessed `multiplex_home` wire key**. [A1] [A2] [T1] | No remote HTTP discovery operation is established by this private control contract. A local chooser is metadata-only, not proof that the socket serves that home. A future native reader must not turn absence/uncertainty into startup. |
| Desktop primary/pooled local resolution: `hermes [--profile P] gateway ensure --json` | Agent `ensure_gateway_runtime` may start an installed service, spawn an unmanaged gateway, or replace a runtime-protocol-incompatible owner. Desktop calls this for primary and pooled local descriptors and may invoke `gateway restart` against the **owner** profile. `authMode:'native'`, empty token and credential-free descriptor result; no owned gateway child. [A1] [D1] [D2] [T1] | **Excluded**, not an attach-only shortcut. Never copy ensure/restart/bootstrap, launch per-profile `hermes serve --port 0`, or add a second owner when a shared gateway is missing/unavailable. |
| Private control `session-ticket` | Envelope `{protocol:1,id,verb:"session-ticket",params:{profile_id,instance_id,purpose,scope?}}`; issuer requires authenticated local peer, current instance and served canonical profile. Result contains `ticket`, `expires_in_seconds:30`, instance/profile/protocol. The optional forwarded structured subject is a privileged same-user facility, not a client-selected identity escape. [A3] [A4] [T2] | **Future native boundary only**. No mint performed here; no bearer scraping, reading Agent token files, public descriptor secret, arbitrary executable or shell bridge. |
| Canonical interactive attach: WS `/api/ws` | Offer **both** `hermes-gateway-v1` and exactly one `hermes-gateway-ticket.<ticket>` subprotocol. Native gate redeems purpose `interactive`, checks loopback peer/host/client policy and absence of a nonempty Origin, chooses the served authority from the grant and stamps subject/profile/instance/capabilities/scope. Only the public protocol is selected. Wrong/expired native grants do not acquire authority through dashboard fallback. [A5] [A6] [T3] | Unimplemented native credential acquisition in Wing. The same protocol string does not make a dashboard ticket an interactive private-control grant. Never retry with a public token after native denial. |
| Native REST: `X-Hermes-Gateway-Ticket` | Fresh `native-http` grant (`http:owner`) per request; exactly one header, **no Origin header at all**, captured actual loopback socket peer, ready/consistent current owner and served set; limited restart-wait reads are special-cased. Query/body/path profile selectors must match the grant; denied redemption is 401, profile mismatch 403. Registry creation/rename/delete require distinct purposes. [A7] [D1] [T4] | Neither a remote bearer credential nor authorization for arbitrary administration. Not accepted on core `/api/ws`; plugin WS admission is a different path. Wing does not implement this per-request mint/header path. No profile mutation is admitted by this study. |
| Dashboard/remote ticket: `POST /api/auth/ws-ticket` | Auth-required dashboard session produces `{ticket,ttl_seconds:30}` from a **different issuer**. Dashboard WS gate supports its own query/subprotocol ticket and verified token flow; in gated mode token verification is distinct from legacy loopback session-token equality. REST Bearer and WS query-token shapes are not interchangeable. [A8] [A13] [T5] | Existing remote operations must be individually advertised/authorized on the connected Agent. This route is present in source, not a new Wing capability advertisement or a private native issuer. No OAuth/Cloud sign-in or credential acquisition is in scope; that is [PARITYUPDATE-003-b1](official-desktop-parity-refresh-2026-10-18.md#remote-oauth). Never copy Desktop's token-in-URL path into Wing. |
| Handshake and read discovery: `gateway.ready`, `runtime.describe` | Ready has `change_events`, `heartbeat`, `replay_epoch`, conditional `session_authority`; it is **not** a full operation/grant catalog. Canonical `runtime.describe {}` requires a nonempty actor capability set and returns instance/profile/authority epoch, `durable-admission-v1`, `event-replay-v1`, `local-cli-create-v1`, ACP capability labels and session-create fields/sources. These labels are not per-operation authorization. [A9] [A10] | Preserve exact schema/operation/grant gates. Neither a ready flag, broad admin flag nor successful REST read grants session creation, submit, controls or host lifecycle. |
| Scoped existing-session mount: canonical `session.resume {session_id,profile?,…}` | Requires `session:read`; authority authorizes matching home/actor and returns snapshot with stored/session IDs, authority/replay epochs, watermark, subscription, revision, execution generation, history, pending rows and prompts. Handler can resolve authoritative compression lineage; the caller must reconcile that result rather than invent another conversation. Desktop's **client** `session.activate` is translated to wire `session.resume`; `lazy` is stripped by its canonical adapter. [A10] [A11] [D3a] [T3] | Future read/reconciliation only; do not treat legacy `session.activate`, `lazy:true` or cached transcript as canonical support. A read/control-capable resume can refresh Agent-owned policy/hooks; it is not a promise of zero Agent-side bookkeeping. No submit, approval or cached configuration replay on reconnect. |
| Replay: `session.events.since {session_id,profile?,replay_epoch?,last_sequence?}` | Requires `session:read`; nonnegative integer cursor, string epoch if present. Snapshot/replay watermark belongs to that exact profile/session and owner epoch. Desktop fences replay to learned owner routes and waits the warm replay before activation; Agent tests reconnect using a fresh ticket, snapshot and replay. [A10] [D3] [D3b] [T3] | Keep unknown outcome blocked until authoritative reconciliation; do not use a cursor from another profile/epoch, select newest/default session, reseed a replacement or retry a mutation through another transport. Full pending-input semantics belong to PARITYUPDATE-002-5c. |
| Viewer leave: socket close / `session.detach {session_id,subscription_id,end_reason?}` | Subscription must belong to this actor/connection. Plain detach removes viewer/fanout; connection close detaches its own and sibling subscriptions and unbinds transport. Explicit `end_reason` can close an idle local conversation after the last viewer leaves; it is **not** owner shutdown. Pending approval and committed work survive a viewer leaving in inspected tests. Last-viewer departure also releases editor MCP and may end an idle ACP session under Agent policy; disconnect is not a no-op. [A10] [A11] [A9] [T6] [T6a] | Disconnect/Remove/Switch/quit must retire only Wing's viewer/forward and local restoration intent, never Stop a run or terminate the shared Agent. Do not promise immortal service lifetime: the Agent's supervisor, explicit lifecycle, drain and idle-exit policy remain authoritative. |

### Grants and identity are not interchangeable

Private `interactive` grants contain `session:create`, `session:read`,
`session:submit`, `session:control`, `session:approve`, `session:respond`.
`native-http` grants only `http:owner`; `exposure` only `transport:delegate`;
`worker-adoption` only `worker:adopt`. Dedicated native profile registry purposes
are separate. Only interactive grants may request `scope:'host'`; default scope
is **profile**. Verified transport admission, not user-supplied identity JSON,
adds operator authority; it does not remove profile, revision or generation fences.
[A3] [A4] [A10] [T7] [T7a]

Keep this identity tuple explicit; none is replaceable by a primary/default label:

- **Connection:** saved connection ID + authenticated origin/transport + attempt
  generation. Equal loopback URLs after a forward or process restart are not
  durable proof of the same owner. Desktop active source uses the descriptor's
  connection ID; Wing's saved endpoint is a separate client identity. [D4] [W8]
- **Home/profile:** `profile_id` in the private gateway contract is the canonical
  **home identity**, not Wing's profile-name ID, a Project, or the local chooser's
  folder. `control_home` identifies the multiplexer's issuing socket, not the
  secondary's session ownership. Linked profile homes must resolve to the home
  actually reserved by Agent; changed advertised homes fail, not redirect. [A1] [D1] [T10]
- **Owner:** `instance_id` changes with the process; `authority_epoch` fences
  authoritative execution state, while `replay_epoch` and sequence fence event
  replay. Code SHA difference is a separate stale-code diagnosis, not denial. [A1] [A10]
- **Session:** use the selected profile plus authoritative stored/session identity,
  subscription, revision and execution generation from the snapshot. Equal session
  IDs can exist on several profiles. Desktop rejects ambiguous client routing;
  a host-scoped request names `profile`, and Agent routes only to a currently
  served sibling, returning `4001 profile_mismatch` otherwise. Re-served profiles
  receive a new authority connection, not a cached retired owner. Profile-bound
  grants cannot select siblings even when they ask for `default`. [A10] [D3] [T7]

## Private ticket delivery and expiry

Agent stores only a ticket hash, binds it to subject/profile/instance/purpose/scope,
and atomically consumes it once. Expiry is **30 seconds**, including the exact
expiry boundary; wrong profile/purpose does not consume a still-valid grant.
Restarted owners cannot redeem the former store's ticket. [A3] [T2] [T4]

Desktop mints afresh per dial over private preload IPC. Its transient IPC URL
contains the ticket, but the renderer removes it **before** constructing WebSocket
and offers it as a subprotocol. Electron reserves a one-use **25-second** native
dial nonce bound to requesting `webContentsId`, path and WebSocket resource type
before removing Origin; interactive proxy dials intentionally are not bound to
the original host/port, whereas plugin-header dials also bind origin. This is
Electron machinery, not a reusable Wing security guarantee. [D1] [D3] [T8]

A future Wing path must pass the secret directly in a transient native channel /
WebSocket protocol list, not an actual network URL, process argv, clipboard,
ordinary preferences, logs, diagnostics or public connection descriptor. No
persisted ticket, ticket reuse after reconnect, secret-bearing raw upstream error,
or blanket Origin suppression is permissible. Existing saved Agent credentials
and exact endpoint/profile/session records remain intact. Missing credentials
require direct reauthentication, never legacy-management recovery. See the
[security ADR](../adr/security-and-privacy.md).

## Recovery verdicts: stale is not denied

| Observation | Evidence and allowed response |
| --- | --- |
| Ready, but Desktop client/owner code SHAs differ | Desktop restarts once per owner/code pair, re-ensures while restart drains, then attaches what answers. A served secondary targets the multiplexer owner (`control_home`), not its own profile. **Wing must not copy this lifecycle authority**; explain host-side recovery separately from attachment failure. [D1] [D2] [T8] |
| Cached instance/socket/pointer no longer valid | Desktop forgets descriptor and re-ensures **once**; second failure surfaces. This is not a template to re-run ensure in Wing. A future attach-only reader may rediscover the **same requested home** once without repair/start, revalidate instance/served profile, then obtain a new grant; it must not resend work. [D1] [T8] |
| Unsafe path/permissions, foreign peer or authorization refusal | Terminal refusal, not absence or permission to chmod/chown/delete/restart. Python discovery retains `inaccessible` reasons (`authorization`, `unsafe_control_*`, `control_timeout`, `invalid_control_peer`); Windows can name elevated/other-session owner boundaries. Desktop's error-string classifier is broader for ticket failures, but explicitly does not re-ensure unsafe paths. Do not use string prefixes as a Wing access policy. [A1] [A2] [T1] [T8a] |
| Unserved/deleted/parked profile or changed home | `profile_mismatch` / `profile_parked` is not a dead socket. A missing linked-profile directory is not healed by rediscovering another owner. Require deliberate selection/recovery; never fall back to launch/default profile. [A1] [T7] [T10] |
| Starting/reserved/conflict/incompatible/plain drain/update pause | Preserve uncertainty/unavailability, not ready and not another per-profile owner. `draining/restart_wait` with an endpoint is the narrow attachable exception for a parked turn; plain drain has no endpoint. Restart-wait permits only its bounded read/response/queue policy, not arbitrary administration. This study does not authorize a new queued input or an answer. [A1] [T1] [T9] |
| Remote/SSH/Cloud failure, including 401/403 | Remain on that selected topology; distinguish authentication rejection from network/stale state. Never start local Agent, reuse another origin's credentials, switch to a local default, or treat a failed remote dial as absence. Desktop resolves remote before local startup; Wing SSH is an authenticated forward, not a remote lifecycle manager. [D2] [D5] [T11] [W5] |

Caveat for any future native design: `discover_gateway_endpoint` is not perfectly
side-effect-free in the absent-owner path: `_private_lock` can narrow an upgraded
same-owner lock to 0600. Its `ensure` wrapper is substantially more mutating.
An approved attach-only Wing implementation must exclude both lock repair and
ensure/start/replace logic; source availability alone does not admit a CLI/Python
bridge. [A1] [A2]

## Current Wing caller: exact unavailable boundary

The current native-serve reader accepts only bare literal loopback HTTP origins,
uses the supplied Bearer credential for fixed `/api/profiles`, profile-scoped
session/message reads, and **POSTs `/api/auth/ws-ticket`** before each WS dial.
It already uses the two WS subprotocols without a credential in the network URL.
Chat then requires `gateway.capabilities.per_session_exclusive_submit == true`
and `client.capabilities.server_requests` containing `approval`; reads alone do
not authorize writes. These are bounded existing gates, not the canonical local
control discovery / private `interactive` ticket / native HTTP grant path. The
pinned dashboard ticket handler requires an authenticated dashboard session; bare
legacy loopback token validity alone is not that session. [W1] [A8] [W6]

There is also a concrete wire mismatch after authentication: Wing resumes with
`{profile,session_id,lazy:true}`; canonical `CanonicalResumeParams` has no `lazy`
field and dispatch rejects unknown canonical keys as `4001 invalid_params`.
Desktop's canonical adapter explicitly removes `lazy` and maps its warm
`session.activate` call to `session.resume`. Matching the WS protocol name or
passing a fixture negotiation therefore **does not establish canonical attach or
recovery compatibility**. The nearest canonical-wire regression checks unknown/
missing-key rejection (not a specifically executed Wing `lazy` case). This task
changes no caller or test. [W2] [A10] [A12] [D3a] [T12]

Wing retains origin/profile/stored/runtime/replay epoch/sequence/uncertainty and
credential in secure local recovery storage; **no authenticated canonical home,
control-home or instance identity is recorded**. Linux cold restore is gated to
Linux and requalifies the exact stored conversation. Forwarded serve acquisition
is Android-only, uses the caller-owned authenticated forward and fences loss;
temporary loopback origin/token are not durable recovery identities. A metadata
home chooser cannot fill this identity gap. Public disconnect clears recovery
and retires the reader/credentials/generations, not the Agent owner. [W3] [W4] [W5] [W7] [W9] [W10]

### Topology disposition and future bounded work

| Topology | What remains permissible / unavailable |
| --- | --- |
| Linux local, same OS user | Existing explicit direct authentication remains separate. The pin has the building blocks for an attach-only native design, but Wing needs a separately admitted bounded reader/credential-delivery and canonical snapshot/replay adapter. No ensure/start/restart, lock repair, installation, public token scraping or per-profile serve fallback. |
| Android with separately prepared Termux Agent | Separate app UID/sandbox cannot inherit same-user private socket authority. Manual preparation plus an explicitly supported authenticated loopback Agent API remains the path. No Termux external commands or filesystem access; Linux native discovery is not an Android solution. |
| Native SSH | Forward only an already configured authenticated Agent leg with reviewed host key and exact remote profile/session binding. A TCP forward does not expose the remote Unix control socket or grant ticket mint/start authority. Loss/cancel retires the captured lease/viewer; explicit reconnect reconciles, never resends. |
| Remote HTTPS / trusted VPN | Use only that Agent's advertised exact operations/grants and explicit profile selectors. Private local discovery/control-home/native-HTTP grants are **not remote administration APIs**. Preserve TLS/origin/consent policy; no local launch after failure. |
| Cloud / dashboard OAuth | Different issuer/account/cookie/connection identity and per-dial ticket path; no equivalence inferred from local native tickets. Contract work remains separately owned by PARITYUPDATE-003-b1. |

A successor may design **only existing-owner attachment and reconciliation** with
these acceptance gates: authenticated owner/home discovery without mutation;
secret-safe per-dial/per-request grants with exact purpose/scope and expiry;
profile-bound versus explicitly host-scoped multiplex tests; stale instance versus
denied/unsafe/unserved verdicts; canonical resume/replay snapshot semantics;
owner-bound cancellation; and disconnect proving no owner shutdown or duplicate
send. GUI creation, submission/control adaptation, runtime bootstrap and service
recovery are outside that bounded successor. This is a feasibility boundary, not
an approved implementation plan, new API, or need for an Agent patch.

Existing Android SSH → profiles/multi-session → canonical Bot Chat → touch
priorities, Files/slash deferrals and live owners remain unchanged. This analysis
closes no product or platform gap; the [matrix](../product/hermes-desktop-feature-matrix.md#current-product-matrix)
retains unsupported/unverified dispositions and every runtime cell.

## Documentation checks and update triggers

Required closeout gate: `git diff --check`; JSON parse of the matrix; verify every
source-ledger path/range/whole-file SHA-256 against its pin; verify changed local
links, operation-to-handler/test traces and preservation of all runtime cells.
These are the complete offline gate for this documentation-only task, not
protocol/runtime tests or the product release gate. The static verifier checked
45 pinned files / 59 ranges, 12 inherited citations in the three affected matrix
rows, 38 local links, and preservation of all 100 runtime cells. Independent
read-only review found no blocker for this documentation scope. No Flutter,
browser, Agent runtime, gateway/ticket command, SSH host or physical platform was
exercised. Native/device/live checks belong to a separately authorized successor
and are not prerequisites for existing Android work.

Revisit when the Agent pin changes, discovery/ticket admission or scope semantics
change, Desktop canonical mapping changes, or Wing's reader/recovery identity
contract changes. Rehash and retrace both handlers and nearest tests; never merely
repin hashes or promote inherited fixture receipts.

## Pinned source ledger

Ranges are inclusive; SHA-256 covers the entire file. `A`/`D`/`T` entries use the
Agent commit above; `W` entries use the Wing baseline above. Repeated references
to an ID use all listed ranges. URLs below use immutable revisions.

<!-- source-ledger:start -->
| ID | Source path | Inclusive ranges | Whole-file SHA-256 |
| --- | --- | --- | --- |
| A1 | `hermes_cli/gateway_runtime.py` | `24-161,185-235,289-333,372-495` | `0fa5838763c1f0f3798591d9b42acf1127f0595c1a38efb6d9027902cb791c59` |
| A2 | `hermes_cli/gateway_runtime_discovery.py` | `75-244` | `c8e3d10f25f3f2ffcf7ba1fc249f2decc3bc69340c29cbcec5036dff9cf18256` |
| A3 | `gateway/runtime_bootstrap.py` | `9-82` | `35b5dda25294337a6f6f6f60ab737d959136471bd7a98e91858273dbb75415f2` |
| A4 | `gateway/control_socket.py` | `335-401` | `f1af97b126ec1c32c426819f1bc2f09103fbc850792f6bc5d5d55a8bfabc18f5` |
| A5 | `gateway/run_api.py` | `281-376` | `77628713200032a963bf8c7882edcf0945e3c1343787f608050d5bcbc24735af` |
| A6 | `hermes_cli/web_server_boundary.py` | `151-166` | `3ba907a2a653d1a6646ad44b3fb07dbfd6a30cb0507d6d175a285079caca8ea5` |
| A7 | `hermes_cli/dashboard_auth/native_http.py` | `19-105,160-280` | `b99bbdabcd385239f335064ee5303092542ddc92a1ef08b89b195cbea431f6df` |
| A8 | `hermes_cli/dashboard_auth/routes.py` | `515-565` | `b88945b2586de1288875ba1da6d8923d07bf34c1c97b16861e42e7d9633fdd08` |
| A9 | `tui_gateway/ws.py` | `347-372,518-644` | `7be64287e04a5a6994f792313cf8123680c329d70f53644020e689e99015ef4f` |
| A10 | `gateway/session_controls.py` | `114-330,477-495,561-808` | `36b5c66f45d2a0108bbc6b5df6eb3df2e9837195aa1da50379a209e11b2211c1` |
| A11 | `gateway/session_authority.py` | `140-176,283-345` | `9aae73408c70b57383d60d203469473454f30421256bcc3e43765650fd61b419` |
| A12 | `tui_gateway/contracts/canonical_sessions.py` | `55-151` | `d42e0a19edaadd99c3767cbb5db4fae8b82e34d616a9ffc61f490257a86a72c0` |
| A13 | `hermes_cli/web_server_chat.py` | `200-340` | `9517bf55c0ef12927c4421108e1439e6204bb5bb8fb50cb3aa22a42cc19bd64f` |
| D1 | `apps/desktop/electron/local-gateway.ts` | `61-356,425-661` | `7051adffb36463c459048205dd82fbb1f5f25af272c8565b980873d0131d9615` |
| D2 | `apps/desktop/electron/main.ts` | `11716-11859,12215-12257` | `5f164c5048afacc77ad1ee015b80a02d203c55325ed373b40f4d5969dcb0836b` |
| D3 | `apps/desktop/src/api/client.ts` | `350-540` | `d32cbc9442865dcab9d0a8d85176c4ea71f08af5b1c6b1b29079fc8c13252c9d` |
| D3a | `apps/desktop/src/api/canonical-protocol.ts` | `278-350` | `c4bee44975226234197da59b39e8fc36ec7033b34fc0177708e6e894adfa2a3e` |
| D3b | `apps/desktop/src/app/session/hooks/use-session-actions/index.ts` | `1535-1571` | `e154ce49dea8160b81da20f94f45d345a3625fae7906f9f5ede7ea2e1202d943` |
| D4 | `apps/desktop/src/store/connections.ts` | `62-164` | `b738b618b1774b12fb0798e562fe68bb26d781657d7a166ee0ca0a58a8238584` |
| D5 | `apps/desktop/electron/primary-backend-startup.ts` | `111-164` | `f08ebbf0af5b414e52fd4dfbc8a60498251367616369445af1fe477c79a7dd7e` |
| T1 | `tests/hermes_cli/test_gateway_runtime.py` | `27-123` | `ee0999fcabc9dc4cd3aa3ea96822865494b9b400cbdb2eeea24d8565cded3bc7` |
| T2 | `tests/gateway/test_runtime_bootstrap.py` | `11-78` | `1c06d927bf78131c23825cec4f9db04f2ef619f1d874bccf1ea2d608e0dd9020` |
| T3 | `tests/gateway/test_normal_runtime_boot.py` | `37-125` | `f76e72a54deb3d883a0cd8358206a3cdcbf7b98e2d080d5efb4c637ca90ff9e3` |
| T4 | `tests/gateway/test_native_http_auth.py` | `94-179` | `2fb462ef232456ebf253ad77abce94685883de23b475bcae029f68742b529e9e` |
| T5 | `tests/hermes_cli/test_dashboard_auth_ws_auth.py` | `116-146,208-317` | `d8ea4a8a5781e7aacf1e85650e3a0c179844885646279508aae70acd469a1b71` |
| T6 | `tests/gateway/test_shared_session_controls.py` | `9-28` | `9d2825ec1c86f768285769a9021ba2cec03b6f61fdbf5b986b35d4f3042c2b27` |
| T6a | `tests/gateway/fixtures/authority_controls_peer.py` | `107-160` | `119b7dcba7c27207193e3b0ee8bdfb7535ce066b47a29c6c8343dae6b0c33206` |
| T7 | `tests/gateway/test_ticket_profile_scope.py` | `19-85` | `c5048e33c3b9ec00a1445f63ea0599de24624c0b608e12ceb10502e0c8569790` |
| T7a | `tests/gateway/test_session_operator_scope.py` | `13-125` | `ecb49eab798b05476da6174b4cd444dd804d3da292194593b9209fcf4070eb60` |
| T8 | `apps/desktop/electron/local-gateway.test.ts` | `128-293,409-433` | `cdd5997c88767be9a7812e476cde8d4cab57c97e86aecc3c3c9ece13a17a03b6` |
| T8a | `apps/desktop/electron/local-gateway-unsafe-path.test.ts` | `1-26` | `c7e5b78997497ff06d6018bfa922e89485401308045346198f65b15374f0ebb9` |
| T9 | `tests/gateway/test_restart_wait_prompt_reach.py` | `16-81,123-203` | `b16d95792428188655da119aa9d7d067b09220e4dbfc48bf5d0d5766f20cf75c` |
| T10 | `apps/desktop/electron/local-gateway-ticket-identity.test.ts` | `82-103` | `0eaf326dede32271c6ee7d1571466b828c081402419eba37c909851e6d1652e8` |
| T11 | `apps/desktop/electron/primary-backend-startup.test.ts` | `121-179` | `ef1009dc7fc8f7ea26e41f04213f96310eba437a65dd2bfaa7e6b7c91e5a8530` |
| T12 | `tests/gateway/test_canonical_wire_contract.py` | `25-56` | `9a0a0280895f81031c552b099183c19b0a5de5d8a9d701933d016492dbc1d516` |
| W1 | `lib/core/hermes/client/hermes_web_read_client.dart` | `27-320` | `02679882860915ba8c1ff90a8abaad8ccdbf9b9ae420f7c3d355714e0ccd43f3` |
| W2 | `lib/core/hermes/client/hermes_web_lifecycle.dart` | `105-181` | `d468d69c565fd142180e635e470217d18ccf8ca172ac806b3353fb3b55167090` |
| W3 | `lib/core/hermes/channel/api_channel/hermes_api_channel_serve_recovery.dart` | `14-125` | `1033e675de693546d80ae7f0a31674df316752d1440b581ea6631502a7f0235d` |
| W4 | `lib/core/hermes/setup/secure_hermes_serve_recovery_store.dart` | `7-85` | `917db7137c4609854b635ef6ab1f601ad7f6c4389a248980eecccd4ccb40a504` |
| W5 | `lib/features/hermes_chat/providers/managed_ssh_connection_controller.dart` | `64-255` | `aa22e57cf5653981eb3dbe6105cf1b85ee18507987061be4e08cdfe256eea790` |
| W6 | `test/core/hermes/channel/hermes_local_serve_chat_test.dart` | `29-96` | `ca042ac89bb4ea793b4b92833fe79f1f6d34fbac07808dedc8c2627c6d7e2c13` |
| W7 | `lib/core/hermes/channel/hermes_api_channel.dart` | `398-440,519-534` | `b05bb5b1dcbe482faf87b072aea22625265872882d6c503d38f681199d460b4a` |
| W8 | `lib/core/hermes/setup/secure_hermes_endpoint_store.dart` | `8-126` | `d98b7c53eca4f3b90d9d84dbf4d8816ef0413fa3a70991f1031e5ee2563e2175` |
| W9 | `lib/core/hermes/channel/api_channel/hermes_api_channel_sessions.dart` | `4-26` | `71ca1faeb0dad223059cd2dd46d21feca4584d273a8cab673b7c552cd582563e` |
| W10 | `lib/core/hermes/local_discovery/local_hermes_home_platform_io.dart` | `19-47` | `e06e7ad68ca0a608bf1c88b43c5f0f0d13b52d5c352016a77da01a88575f4b90` |
<!-- source-ledger:end -->

[A1]: https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/hermes_cli/gateway_runtime.py#L24-L495
[A2]: https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/hermes_cli/gateway_runtime_discovery.py#L75-L244
[A3]: https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/gateway/runtime_bootstrap.py#L9-L82
[A4]: https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/gateway/control_socket.py#L335-L401
[A5]: https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/gateway/run_api.py#L281-L376
[A6]: https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/hermes_cli/web_server_boundary.py#L151-L166
[A7]: https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/hermes_cli/dashboard_auth/native_http.py#L19-L280
[A8]: https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/hermes_cli/dashboard_auth/routes.py#L515-L565
[A9]: https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/tui_gateway/ws.py#L347-L644
[A10]: https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/gateway/session_controls.py#L114-L808
[A11]: https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/gateway/session_authority.py#L140-L345
[A12]: https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/tui_gateway/contracts/canonical_sessions.py#L55-L151
[A13]: https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/hermes_cli/web_server_chat.py#L200-L340
[D1]: https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/apps/desktop/electron/local-gateway.ts#L61-L661
[D2]: https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/apps/desktop/electron/main.ts#L11716-L12257
[D3]: https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/apps/desktop/src/api/client.ts#L350-L540
[D3a]: https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/apps/desktop/src/api/canonical-protocol.ts#L278-L350
[D3b]: https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/apps/desktop/src/app/session/hooks/use-session-actions/index.ts#L1535-L1571
[D4]: https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/apps/desktop/src/store/connections.ts#L62-L164
[D5]: https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/apps/desktop/electron/primary-backend-startup.ts#L111-L164
[T1]: https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/tests/hermes_cli/test_gateway_runtime.py#L27-L123
[T2]: https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/tests/gateway/test_runtime_bootstrap.py#L11-L78
[T3]: https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/tests/gateway/test_normal_runtime_boot.py#L37-L125
[T4]: https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/tests/gateway/test_native_http_auth.py#L94-L179
[T5]: https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/tests/hermes_cli/test_dashboard_auth_ws_auth.py#L116-L317
[T6]: https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/tests/gateway/test_shared_session_controls.py#L9-L28
[T6a]: https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/tests/gateway/fixtures/authority_controls_peer.py#L107-L160
[T7]: https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/tests/gateway/test_ticket_profile_scope.py#L19-L85
[T7a]: https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/tests/gateway/test_session_operator_scope.py#L13-L125
[T8]: https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/apps/desktop/electron/local-gateway.test.ts#L128-L433
[T8a]: https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/apps/desktop/electron/local-gateway-unsafe-path.test.ts#L1-L26
[T9]: https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/tests/gateway/test_restart_wait_prompt_reach.py#L16-L203
[T10]: https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/apps/desktop/electron/local-gateway-ticket-identity.test.ts#L82-L103
[T11]: https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/apps/desktop/electron/primary-backend-startup.test.ts#L121-L179
[T12]: https://github.com/NousResearch/hermes-agent/blob/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/tests/gateway/test_canonical_wire_contract.py#L25-L56
[W1]: https://github.com/TrebuchetDynamics/hermes-wing/blob/2ddbb51b69044c71411e32168750a9a92db4c731/lib/core/hermes/client/hermes_web_read_client.dart#L27-L320
[W2]: https://github.com/TrebuchetDynamics/hermes-wing/blob/2ddbb51b69044c71411e32168750a9a92db4c731/lib/core/hermes/client/hermes_web_lifecycle.dart#L105-L181
[W3]: https://github.com/TrebuchetDynamics/hermes-wing/blob/2ddbb51b69044c71411e32168750a9a92db4c731/lib/core/hermes/channel/api_channel/hermes_api_channel_serve_recovery.dart#L14-L125
[W4]: https://github.com/TrebuchetDynamics/hermes-wing/blob/2ddbb51b69044c71411e32168750a9a92db4c731/lib/core/hermes/setup/secure_hermes_serve_recovery_store.dart#L7-L85
[W5]: https://github.com/TrebuchetDynamics/hermes-wing/blob/2ddbb51b69044c71411e32168750a9a92db4c731/lib/features/hermes_chat/providers/managed_ssh_connection_controller.dart#L64-L255
[W6]: https://github.com/TrebuchetDynamics/hermes-wing/blob/2ddbb51b69044c71411e32168750a9a92db4c731/test/core/hermes/channel/hermes_local_serve_chat_test.dart#L29-L96
[W7]: https://github.com/TrebuchetDynamics/hermes-wing/blob/2ddbb51b69044c71411e32168750a9a92db4c731/lib/core/hermes/channel/hermes_api_channel.dart#L398-L534
[W8]: https://github.com/TrebuchetDynamics/hermes-wing/blob/2ddbb51b69044c71411e32168750a9a92db4c731/lib/core/hermes/setup/secure_hermes_endpoint_store.dart#L8-L126
[W9]: https://github.com/TrebuchetDynamics/hermes-wing/blob/2ddbb51b69044c71411e32168750a9a92db4c731/lib/core/hermes/channel/api_channel/hermes_api_channel_sessions.dart#L4-L26
[W10]: https://github.com/TrebuchetDynamics/hermes-wing/blob/2ddbb51b69044c71411e32168750a9a92db4c731/lib/core/hermes/local_discovery/local_hermes_home_platform_io.dart#L19-L47
