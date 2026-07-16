# ADR 0012: Keep domain authority in Hermes Agent

Status: accepted
Date: 2026-07-13

Hermes Agent is the sole authority for profiles, configuration, memory, skills, tools, schedules, Kanban, sessions, and gateway state. Flutter clients use capability-advertised HTTP, SSE, or WebSocket contracts and must not reproduce Electron’s direct config parsing, state-database access, or CLI-output parsing in Dart.

## Consequences

- Missing parity contracts are added to Hermes Agent before their Flutter surfaces.
- `HermesChannel` remains the Flutter application seam and can grow by cohesive capability areas without introducing another service locator.
- Desktop host adapters are limited to installation, process lifecycle, SSH tunnelling, secure storage, filesystem selection, application updates, and window integration.
- Bootstrap may discover an existing installation, invoke the official installer, or start Hermes, but Hermes Wing packages do not embed Python or Hermes Agent and domain operations move through Hermes interfaces once the service is available.
- Contract tests must cover capability discovery, authorization, payloads, errors, and streaming behavior before parity is claimed.
