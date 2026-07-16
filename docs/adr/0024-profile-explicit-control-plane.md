# ADR 0024: Make the Hermes control plane profile-explicit

Status: accepted
Date: 2026-07-13

Local and remote Hermes Wing clients use one machine-scoped Hermes API service. Every profile-owned operation identifies its Hermes profile explicitly; API behavior must not depend on the machine’s mutable `active_profile` file or on a separate listener, port, or credential per profile.

## Consequences

- Hermes Wing profile selection is client context and does not mutate the CLI’s active profile.
- Sessions, runs, tasks, schedules, gateway state, skills, tools, memory, and configuration are bound to a validated profile identity.
- Missing, unknown, malformed, or conflicting profile context fails closed for profile-owned operations.
- Resource identifiers cannot be used to cross profile boundaries; isolation tests cover list, read, mutation, events, and cancellation.
- Hermes Agent’s profile-multiplexing foundation becomes the server topology instead of Desktop’s per-profile port allocator.
- The exact HTTP profile-context encoding is advertised by capabilities and shared by request/response and streaming contracts.
