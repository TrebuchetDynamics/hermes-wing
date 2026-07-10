# Hermes compatibility contract

Navivox does not currently promise compatibility by Hermes Agent version
number. It reads `/v1/capabilities` and enables only advertised transports and
surfaces.

## Required bootstrap endpoints

- `GET /health`
- `GET /v1/capabilities`
- `GET /api/sessions`

A usable endpoint must also advertise at least one supported chat transport:

- `POST /api/sessions/{session_id}/chat/stream`, or
- `POST /v1/runs` plus `GET /v1/runs/{run_id}/events`

## Capability-gated endpoints

Navivox may use these only when advertised:

- `GET /health/detailed`
- `GET /v1/models`
- `GET /v1/skills`
- `GET /v1/toolsets`
- `POST /api/sessions`
- `PATCH /api/sessions/{session_id}`
- `DELETE /api/sessions/{session_id}`
- `GET /api/sessions/{session_id}/messages`
- `POST /api/sessions/{session_id}/fork`
- `GET /api/jobs`
- `POST /v1/runs/{run_id}/approval`
- `POST /v1/runs/{run_id}/stop`

Failure to load optional health, models, skills, toolsets, or jobs is reported
as unavailable inventory rather than as an empty inventory.

## Unsupported server surfaces

Hermes server audio/realtime audio, memory editing, configuration editing, and
jobs administration are not release-supported Navivox workflows even when a
server advertises related capabilities.
