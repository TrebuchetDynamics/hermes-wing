# ADR 0026: Use HTTP commands and SSE event streams

Status: accepted
Date: 2026-07-13

The Hermes control plane uses ordinary HTTP requests for commands and queries and profile-scoped Server-Sent Events for asynchronous updates. Dashboard WebSocket behavior is not a Hermes Wing parity transport; WebSocket remains reserved for a future capability that is genuinely bidirectional, such as realtime media.

## Consequences

- Chat, runs, tasks, gateway state, and Office updates share one SSE lifecycle model.
- Event streams carry stable event IDs, typed payloads, profile identity, keepalives, and terminal events where work has a terminal state.
- Delivery is at least once: reconnect uses the last event ID or advertised cursor, clients deduplicate events, and authoritative GET endpoints reconcile gaps.
- Streams have bounded connection and idle timeouts; cancellation, profile changes, endpoint changes, and sign-out close them immediately.
- Capabilities advertise each SSE endpoint, profile requirement, resumability, event types, and terminal semantics.
- Unknown event types are ignored safely; malformed required events fail only the affected operation.
