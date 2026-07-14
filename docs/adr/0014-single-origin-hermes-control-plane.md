# ADR 0014: Use one Hermes API origin for remote clients

Status: accepted
Date: 2026-07-13

Navivox connects to one canonical Hermes Agent API origin and bearer credential for capability discovery, chat, and approved administration. Mobile and web clients must not reproduce Hermes Desktop’s separate gateway and Dashboard transports, ports, tokens, CORS policies, or SSH fallback behavior. This single-origin boundary covers the Hermes Agent control plane; the optional Hermes One account service remains a separate cloud identity authority under ADR 0019.

## Consequences

- The gateway API server’s `/v1/capabilities` document is the source of truth for every remote-safe operation.
- Hermes Agent exposes missing administration contracts through the API-server boundary while reusing authoritative domain functions; Flutter does not scrape or embed the Dashboard.
- Dashboard remains a client surface and may reuse the same domain services, but its session-token transport is not a Navivox dependency.
- A saved endpoint profile contains one normalized origin and one securely stored bearer credential.
- Unsupported administration remains hidden until its endpoint, capability declaration, authorization policy, and contract tests exist.
- Hermes One account OAuth and backend-managed wallet calls do not pass through or share credentials with the Hermes Agent origin.
