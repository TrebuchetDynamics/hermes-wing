# Client architecture

> Reference correction: [official Desktop authority](../quality/official-desktop-reference.md). Prior Desktop source citations and parity conclusions in this document are withdrawn. Wing test results remain historical behavior evidence only.


Status: current

## Decision

Keep the Flutter client modular around small replaceable seams. Existing Riverpod providers, Hermes channel contracts, and adaptive routing are the preferred patterns because they already support production wiring and test overrides.

The owner-accepted priority is a 1:1 Hermes Desktop product port in Flutter, not
merely equivalent outcomes. Follow Desktop feature coverage, navigation, wording,
interaction/state transitions and recovery by default; see [product boundaries](product.md).
The earlier interview baseline was desktop-first on Flutter desktop and wide web.
The [current Android priority](../plans/2026-10-03-desktop-port-goal.md#android-ssh-multi-session-priority)
now leads delivery with Android SSH, profile/bot multi-session chat and touch-first
polish. Desktop fidelity and cross-platform regression requirements remain intact. Full local Desktop functionality is the target;
remote mode may expose a smaller exact-capability-gated subset. Wide web is a
fidelity baseline, not a grant of desktop-local process/filesystem authority.
Share domain behavior across platforms. Native implementation is not a line-for-line
Electron port, but responsive/native product differences must be recorded explicitly
in the [parity ledger](../product/hermes-desktop-parity.md) and
[UI audit](../product/hermes-desktop-ui-gap.md), not silently substituted as parity.
Accessibility remains primary, including an operable equivalent when speech, sound,
motion, pointer input, canvas or 3D is unavailable.

Shell parity remains unverified against the official Desktop reference.
Inspect `hermes-agent/apps/desktop/` before selecting a shell source or claiming
parity; follow the [reference policy](../quality/official-desktop-reference.md).
Do not use the withdrawn Layout comparison as implementation authority.
The [first-wave receipt](../quality/2026-10-03-desktop-port-first-wave.md) preserves
local collapse/expand implementation and bounded source/test evidence, not runtime
or card acceptance. The next milestone is the
[daily-use workflow](../plans/2026-10-03-desktop-daily-workflow.md): local connect,
explicit profile/model/session, actual generation, correlated approval,
authoritative stop, leave/relaunch and exact-session restoration without duplicate
sends. Copy session ID and shell composition/persistence support this flow; they
are not the leading outcome. Navigation and multi-run tabs remain separate gaps.

Full local functionality requires a separately designed bounded native integration
and security review before any privileged implementation. Define each operation's
fixed executable/argument shape, typed bounds, exact identity/authorization,
secret-safe acquisition, lifecycle/recovery and removal trigger; no arbitrary
shell, caller-selected config keys/paths, direct Agent-file/database writes or
shadow domain state. This decision does not approve that design, implement native
integration, expand Wing Link compatibility, enable internal native-web clients
or copy Desktop privileged IPC. Existing
[runtime rules](runtime-and-delivery.md) and
[security boundaries](../security/threat-model.md) remain binding. Missing operations
stay unavailable until their individual reviewed contract/evidence gates pass.

Wing uses direct Agent connections. The host-management client/service and
compatibility catalog are removed; missing Agent operations remain unavailable.
No replacement backend, shell bridge or cached management authority is permitted.

Use platform-native features where practical. Voice may use exact advertised
Agent audio routes with platform processing as fallback; availability and
physical/acoustic evidence must remain explicit.

Agent chat and run traffic stays on direct authenticated Hermes Agent
transports. Remote VPS connections may use an advertised HTTPS/WebSocket
transport, but Wing Link never proxies Agent data-plane traffic. ACP is an
optional local desktop stdio transport only; Wing reuses its session, event,
and approval semantics without exposing its terminal/file toolset remotely.

## Transport qualification

Keep advertised HTTP and native dashboard REST/WebSocket contracts separate.
Qualify each selected surface's operation, origin, authentication/acquisition,
profile/session/run identity, human-request protocol, Stop and reconnect behavior;
similar paths or shared Agent internals do not make credentials or grants
interchangeable. Native request qualification includes per-connection negotiation,
exact request correlation, acknowledged settlement, open-request recovery and
stale/cancelled-response rejection. No FIFO guesses or approval replay.

Local stream teardown, Stop requested and authoritative terminal outcome are
different states. Reconcile canonical status/history after disconnect and retain
uncertain ownership until resolved; a native socket is not a durable detached-run
guarantee. Preserve exact remembered sessions and owner/generation fences across
async reads and preference writes without creating replacement domain state.

Production uses `HermesApiChannel`. Its Linux loopback serve read connection has
an explicit fixed-chat entry requiring separate session-ticket authentication,
exclusive-submit and server-request negotiation, and captured runtime/stored
session ownership. REST reads alone never authorize Send, approval or Stop;
legacy local tokens remain read-only when ticket authentication is unavailable.
Other native-web operations remain internal qualification. See the
[bounded chat receipt](../quality/local-serve-production-chat.md). The
[restoration receipt](../quality/local-serve-restoration.md) bounds Linux cold
startup and explicit socket-loss Retry to a secure exact-owner pointer and a
settled canonical history/replay barrier, never a mutation replay or detached-run
durability claim. The
[four-repository study](../analysis/understand-anything/README.md) informs the
[bounded delivery plan](../plans/2026-10-03-study-follow-through.md), not a
transport migration or new capability.

The Android gateway-login candidate adds a separate HTTPS-only constructor and
explicit channel entry over these same fixed native session/ticket contracts.
Normal certificate validation and WSS are mandatory; the local reader's loopback
restriction remains unchanged. PKCE access/refresh credentials use dedicated
origin-scoped secure slots, never direct API endpoint records. Unknown submission
outcomes retain exact recovery pointers and never authorize resends. See
[the enrollment candidate](../product/enrollment.md#android-gateway-sign-in-candidate).

## Flexible guidance

- Reuse existing seams before introducing a new abstraction or dependency.
- Libraries and route structure may change when the replacement is simpler and preserves behavior.
- Validate in proportion to the change: focused tests first, then broader platform or E2E checks when the affected behavior requires them.
- A feature may ship on one supported platform before another when availability is accurately gated and documented.
