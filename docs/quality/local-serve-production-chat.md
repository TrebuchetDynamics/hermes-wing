# WING-TASK-406: local serve production chat

Status: implemented candidate; independent native exact-source review and
coordinator integration/publication remain separate. This does not close the
CONNECTION-PATHS or daily-use milestone.

## Outcome and bounded authority

The existing Linux Local **Read an already-running Hermes serve backend**
connection remains available. With an existing selected session, **Enable chat on
this session** deliberately attempts a separate authenticated ticket WebSocket.
No prompt is sent during connection, qualification, profile/session selection or
recovery. A read token alone never grants mutation authority.

The gate requires successful authenticated `POST /api/auth/ws-ticket`, a fresh
single-use ticket in the upgrade subprotocol (never a credential URL), the stable
selected `hermes-gateway-v1` protocol, `gateway.ready`, exact
`gateway.capabilities.per_session_exclusive_submit == true`, and
`client.capabilities` advertising approval server requests. These are the native
serve contracts, not invented `/v1` scopes or an administration grant. The
inspected gated serve transport authenticates a full session identity; it does
not return per-operation scope grants. Wing exposes only the inspected fixed
chat operations and treats RPC denial/absence as failure, not fallback authority.

Default loopback's static session token can authorize REST reads but cannot mint
an authenticated-session ticket. That configuration remains read-only. The user
must supply a session credential accepted by the selected unmodified backend;
Wing does not acquire credentials, discover secrets, configure authentication,
launch Agent, fall back to credential URLs, or claim all local servers support
chat. Both connection and credential remain ephemeral, never stored as a saved
gateway record. Remote, SSH, browser and Android entry paths are unchanged.

Chat uses the existing `HermesApiChannel`, turn model, composer, approval queue
and Stop controls. A deliberate text Send submits once to the captured
connection/profile/runtime session. The durable session stays explicit in the
transcript and approval origin. Ordered message/tool events update shared turns;
wrong-owner, duplicate and sequence-gap events cannot attach to another turn.
Attachments, hands-free voice, automatic follow-up drains, retrying failed turns,
session creation and management are not enabled for this bounded serve path.

Approval allows only the currently received queue/server request pair and its
advertised once choice (or deny). Session/always choices are unavailable. Idle
`request.cancel` withdraws only that request; stale instances make zero approval
requests. Owner replacement retires subscriptions/approvals before selection,
and late results cannot enter the new owner.

Stop captures the runtime/session and distinguishes a requested interrupt receipt
from authoritative `message.complete`. A closed socket or local cancellation
never manufactures a terminal turn or confirms Stop. The requested-waiting copy
is removed after an authoritative terminal event. Denial, timeout, connection
loss or sequence gap blocks another Send. **Reconcile this session without
resending** obtains a fresh ticket and lazily resumes the exact stored session,
reads canonical history and establishes the replay barrier. Recovery does not
replay Send, approval or Stop. App resume does not implicitly reconnect this
serve workflow. Persistent recovery belongs to WING-TASK-407, not this card.

## Read-only official source trace

Reference revision: `158fd638da1629c8e62caf9ade1515d162def8ab`.
No upstream/runtime source, tests, configuration or credentials were modified.

- `hermes_cli/dashboard_auth/routes.py:485-493`: ticket mint requires an
  authenticated session; the adjacent native-token contract is not implemented
  as secret acquisition here.
- `hermes_cli/web_server_chat.py:250-374`: gated authentication consumes the
  single-use ticket subprotocol and selects only the stable public protocol;
  ungated local authentication is a distinct token-URL contract, not used here.
- `tests/hermes_cli/test_dashboard_auth_ws_auth.py:115-148`: authenticated mint,
  unauthorized failure and no GET ticket mint.
- `tui_gateway/methods_voice.py:434-450` and `contracts/liveness.py`: build-enforced
  exclusive submit and per-connection server-request negotiation.
- `contracts/sessions.py:182-202`, `methods_session.py:2366-2397`: lazy stored
  session resume and exact runtime interrupt. An interrupt receipt is not a
  completed response.
- `contracts/prompt_voice.py:26-75`, `methods_prompt.py:1166-1180`: fixed text
  submit and queue-ID-scoped approval resolution with `all: false`.
- `contracts/events.py:184-203,259-292`: terminal/message and tool payloads.
- `contracts/server_requests.py:60-90`, `server_requests.py`, and
  `tests/tui_gateway/test_approval_cancelled_on_reap.py:71-85`: correlated approval
  and cancellation/deny settlement. Qualification is source inspection, not
  execution of upstream tests or real approval/inference.
- Official Desktop `apps/desktop/src/store/prompts.ts:340-406`: captured owner
  routing and server/queue identities. Wing does not copy its timeout retry;
  uncertain writes require explicit no-replay reconciliation.
- Official Desktop's `AGENTS.md` and `src/AGENTS.md` establish runtime versus
  durable identity and an independent composer on the serve backend. Wing does
  not port Electron process/credential privileges.

## Executed checks and acceptance mapping

Initial manifest-pinned `pass_workspace.py` admitted this native workspace before
any production edits. Base: `e5858ad2e06531e479e06078a09ce94959298b7f`.

Executed during implementation:

- `flutter pub get --offline --enforce-lockfile`: exit 0.
- `flutter test --no-pub --concurrency=1 test/core/hermes/client/hermes_web_lifecycle_test.dart`
  first: 13 passed, exit 0.
- `flutter gen-l10n`: exit 0; only ARB source edited manually.
- Changed Dart formatting and `flutter analyze --no-pub`: exit 0.
- Lifecycle, serve read/channel and new serve chat tests: original combined run
  24 passed; expanded serve chat target 8 passed, including real 10-second RPC
  timeout, ticket-only authorization, denial, owner replacement, exact approval,
  idle withdrawal, Stop and local close. Final acceptance repeats the focused
  transport/channel/control suite through the completion helper.
- Production read and chat widget targets: 2 passed, exit 0. The chat journey uses
  actual form, enable, Send, approval and Stop controls, not a substituted channel.
- `python3 -B integration_test/run_linux_local_serve_chat.py --self-check`: exit 0;
  altered counts and false qualification fields are rejected.
- `python3 -B integration_test/run_linux_local_serve_chat.py`: isolated Linux GTK
  build and complete deterministic-auth control journey passed, exit 0. Actual
  receipt: 15 HTTP requests, 20 RPCs, four newly minted tickets, two deliberate
  Sends, one current-request approval, one Stop, zero stale approval requests and
  zero credential saves. Canonical history and explicit recovery did not add a
  submission. First native rehearsal: 41.727 seconds. The final completion helper
  repeats the journey against its frozen final candidate and records the source
  manifest hash, native PID, command and exit code under
  `.task-evidence/t_45cc9352/native-*/verification.json`.

Send/stream/tool order and exact approval are covered by
`hermes_local_serve_chat_test.dart` and `local_serve_chat_journey.dart`.
Idle withdrawal and stale zero-request rejection use both. Captured Stop,
requested-versus-terminal, timeout, denial, gap, local cancellation and profile
replacement use channel regressions; the Linux public-control journey covers
requested-versus-terminal and uncertain reconnect without replay. Existing
lifecycle regressions retain wrong-owner/duplicate/replay/epoch coverage.

Initial analyzer findings were formatting/override annotations and a test print;
all were repaired. Widget rehearsals exposed fake-async subscription cancellation
and WebSocket-close grace timers: cancellation now runs in `tester.runAsync`, and
the widget-only wrapper pumps the close grace period after disposal. Native
execution did not require this fake-time workaround. Timed-out rehearsals are
failures, not acceptance evidence.

## Method, exclusions and delivery

Ponytail: reuse the fixed lifecycle/read client, shared channel/approval/turn models,
production form/controls, read journey and existing isolated Linux freeze/runtime
helpers. Add only the native/browser-unavailable lifecycle seam and bounded
channel adapter, not a transport registry, RPC bridge, second backend/store,
credential-discovery service or dependency. The Linux runner copies existing
user-space development packages; no system installs, live services or personal
HOME/XDG/DBus are used. Owned isolation is removed after its receipt is captured.

Implemented and deterministic Linux-qualified are not delivered/live-qualified.
The mandatory `finish_task.py` receipt binds the final checks to the exact owned
commit/ref, followed by one independent same-card native review. Coordinator
broader integration gates, merge and normal-policy publication are separate;
this worker performs none of them and does not close the canonical ledger.

NOT_CHECKED: live Agent authentication, real secret acquisition, paid/live
inference, physical keyboard/IME, screen readers, keychain, Android/physical
hardware, persistent relaunch recovery and release/distribution. Full canonical
integration suites remain coordinator-owned. Next slice is WING-TASK-407 only
after reviewed delivery of this card.
