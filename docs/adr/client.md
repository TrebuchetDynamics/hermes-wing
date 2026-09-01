# Client architecture

Status: current

## Decision

Keep the Flutter client modular around small replaceable seams. Existing Riverpod providers, Hermes channel contracts, and adaptive routing are the preferred patterns because they already support production wiring and test overrides.

Share domain behavior across platforms while allowing native or adaptive presentation. Accessibility is part of the primary interaction, including an equivalent path when speech, sound, motion, pointer input, canvas, or 3D is unavailable.

Use platform-native features where practical. Voice may use exact advertised
Agent audio routes with platform processing as fallback; availability and
physical/acoustic evidence must remain explicit.

Agent chat and run traffic stays on direct authenticated Hermes Agent
transports. Remote VPS connections may use an advertised HTTPS/WebSocket
transport, but Wing Link never proxies Agent data-plane traffic. ACP is an
optional local desktop stdio transport only; Wing reuses its session, event,
and approval semantics without exposing its terminal/file toolset remotely.

## Flexible guidance

- Reuse existing seams before introducing a new abstraction or dependency.
- Libraries and route structure may change when the replacement is simpler and preserves behavior.
- Validate in proportion to the change: focused tests first, then broader platform or E2E checks when the affected behavior requires them.
- A feature may ship on one supported platform before another when availability is accurately gated and documented.
