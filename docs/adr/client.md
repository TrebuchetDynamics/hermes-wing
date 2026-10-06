# Client architecture

Status: current

## Decision

Keep the Flutter client modular around small replaceable seams. Existing Riverpod providers, Hermes channel contracts, and adaptive routing are the preferred patterns because they already support production wiring and test overrides.

The owner-accepted priority is a 1:1 Hermes Desktop product port in Flutter, not
merely equivalent outcomes. Follow Desktop feature coverage, navigation, wording,
interaction/state transitions and recovery by default; see [product boundaries](product.md).
The accepted interview baseline is desktop-first on Flutter desktop and wide web,
with mobile usability preserved. Full local Desktop functionality is the target;
remote mode may expose a smaller exact-capability-gated subset. Wide web is a
fidelity baseline, not a grant of desktop-local process/filesystem authority.
Share domain behavior across platforms. Native implementation is not a line-for-line
Electron port, but responsive/native product differences must be recorded explicitly
in the [parity ledger](../product/hermes-desktop-parity.md) and
[UI audit](../product/hermes-desktop-ui-gap.md), not silently substituted as parity.
Accessibility remains primary, including an operable equivalent when speech, sound,
motion, pointer input, canvas or 3D is unavailable.

Use [Desktop Layout](../../hermes-desktop/src/renderer/src/screens/Layout/Layout.tsx)
at `2ed89070bc6c9e8231a37bb55df8a7722a3776b8` as the shell source reference.
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

Wing Link remains the current host-management plane, not the product organizing
principle. Prioritize direct Agent connection and Desktop fidelity over new
Wing-specific management features; existing dependencies are not removed or made
optional by this decision.

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

Production currently uses `HermesApiChannel`; native-web clients remain internal
qualification, not an enabled production adapter or authorization flow. The
[four-repository study](../analysis/understand-anything/README.md) informs the
[bounded delivery plan](../plans/2026-10-03-study-follow-through.md), not a
transport migration or new capability.

## Flexible guidance

- Reuse existing seams before introducing a new abstraction or dependency.
- Libraries and route structure may change when the replacement is simpler and preserves behavior.
- Validate in proportion to the change: focused tests first, then broader platform or E2E checks when the affected behavior requires them.
- A feature may ship on one supported platform before another when availability is accurately gated and documented.
