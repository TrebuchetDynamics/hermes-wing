# Hermes Desktop Reference For Navivox

Status: superseded for runtime direction by [ADR 0006](../adr/0006-hermes-agent-first-runtime.md), amended by [ADR 0007](../adr/0007-native-hermes-channel-not-navivox-channel-adapter.md), and replaced operationally by the [Hermes Agent interface plan](hermes-agent-interface-plan.md). Still useful as historical UX reference.

Former status: accepted reference direction
Reference: `fathah/hermes-desktop` cloned at `/tmp/hermes-desktop` during the 2026-06-03 planning session

## Historical decision

This section records the superseded 2026-06 Gormes-first decision. The active runtime direction is Hermes Agent-first: Navivox now targets Hermes Agent API endpoints through a native `HermesChannel` and `/hermes` UI.

Historical decision: Navivox stayed Gormes-first, with the Flutter operator app targeting trusted local or self-hosted Gormes gateways and Gormes Profile contacts. Hermes Desktop was reference material for app shape, not a near-term runtime target. Navivox could borrow product patterns from Hermes Desktop while preserving the Gormes `/v1/navivox/*` HTTP/WebSocket boundary, Pairing handoff, Profile contact model, Run record evidence model, config-admin safety model, and Goncho memory console.

## Reference Behaviors Worth Learning From

Hermes Desktop is an Electron/React shell for Hermes Agent. The patterns worth studying are:

- chat as the primary workspace;
- profile switching and profile management close to chat;
- sessions, models, providers, memory, tools, skills, schedules, gateway, and settings as operator surfaces;
- local or remote gateway setup made understandable for non-terminal operation;
- streaming assistant work rendered as product UI with tool progress and usage evidence;
- simple navigation that keeps day-to-day chat, memory, tools, and gateway status nearby.

These are product and UX lessons. The old warning against speaking Hermes Agent protocols is superseded by ADR 0006/0007; current mainline does speak Hermes Agent's API server directly.

## Navivox Shape

Historical Gormes-first route vocabulary respected Gormes domain terms:

| Hermes Desktop surface | Gormes-first Navivox interpretation |
| --- | --- |
| Chat | existing Profile contact Transcript surface |
| Sessions | Gormes `/v1/navivox/sessions` and Run record evidence, once UI wiring is complete |
| Profiles | existing Profile contacts and Profile seed flows, not generic Hermes profiles |
| Models / Providers | Gormes config-admin model/provider settings where advertised |
| Memory | Goncho memory overview/search/detail/action APIs through Gormes |
| Tools / Skills | Gormes tool activity, approvals, and capability-gated operator surfaces |
| Gateway | Gormes Navivox gateway management, Pairing handoff, durable reconnect readiness |
| Settings | local app settings plus Gormes capability/config affordances |

## Historical boundary rules

These boundary rules are superseded for mainline runtime direction. Preserve them only when maintaining the legacy Gormes branch/path.

- Gormes remained the runtime and gateway family for the then-current Navivox plan.
- Hermes Desktop could inform navigation, visual hierarchy, and operator surface prioritization.
- Hermes Agent wire-protocol clients were deferred until ADR 0006 changed runtime scope.
- Gormes-specific domain concepts stayed Gormes-specific when data came from Gormes.
- `Profile contact`, `Pairing handoff`, `Run record`, `Voice readiness`, `Gateway identity`, and Gormes config-admin language stayed stable for legacy Gormes surfaces.

## Hermes Protocol Spikes

This section is historical. ADR 0006 explicitly reopened Hermes runtime support and ADR 0007 chose a native Hermes channel, so Hermes protocol code now belongs in `lib/core/hermes/` and `/hermes`.

The 2026-06-03 Hermes runtime spike was removed from production code after the Gormes-first decision was accepted; later Hermes Agent-first work superseded that removal with a production Hermes client/channel.

## Next Gormes-First Slices Inspired By Hermes Desktop

1. Improve the Profile contact chat surface using Hermes Desktop's chat-first ergonomics.
2. Wire Gormes sessions and Run records into a discoverable operator evidence surface.
3. Make profile switching/profile seed flows feel closer to Hermes Desktop's profile management while preserving Gormes Profile contact semantics.
4. Prioritize Models/Providers through Gormes config-admin rather than a separate Hermes settings model.
5. Keep the Gateway surface focused on Pairing handoff, Gateway identity, durable reconnect readiness, and safe exposure status.
