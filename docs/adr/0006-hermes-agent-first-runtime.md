# Make Navivox Hermes Agent-first

Status: accepted, amended by [ADR 0007 — Build a native Hermes channel instead of a `HermesNavivoxChannel` adapter](0007-native-hermes-channel-not-navivox-channel-adapter.md)

Supersedes: [ADR 0005 — Keep Navivox Gormes-first and use Hermes Desktop as reference](0005-gormes-first-navivox-with-hermes-desktop-as-reference.md)

## Context

Navivox has been implemented around the Gormes `/v1/navivox/*` gateway contract: pairing handoff, profile contacts, config-admin, Goncho memory, run-record lookup, durable reconnect, and WebSocket turn streaming. That Gormes-first state is preserved on the pushed `gormes` branch at commit `b0b4390`.

The product direction is changing: Navivox should become a mobile/operator app for Hermes Agent itself rather than a Gormes operator app that only borrows ideas from Hermes Desktop.

Hermes Agent already exposes a native external-UI surface in `gateway/platforms/api_server.py`:

- `GET /health` and `/health/detailed`
- `GET /v1/capabilities`
- `GET /v1/models`
- `GET /v1/skills` and `/v1/toolsets`
- `GET/POST /api/sessions`
- `GET/PATCH/DELETE /api/sessions/{session_id}`
- `GET /api/sessions/{session_id}/messages`
- `POST /api/sessions/{session_id}/chat` and `/chat/stream`
- `POST /v1/runs`
- `GET /v1/runs/{run_id}` and `/events`
- `POST /v1/runs/{run_id}/approval`
- `POST /v1/runs/{run_id}/stop`

This is a better mobile-app contract than making Hermes impersonate a Gormes Navivox gateway or using ACP as the first integration path.

## Decision

Navivox mainline will target Hermes Agent's API server directly.

The first integration path is:

1. Add a typed Hermes API client and SSE decoder in `lib/core/hermes/`.
2. Add a native `HermesChannel`/`HermesChannelState` surface sized to Hermes sessions/messages, per ADR 0007, instead of adapting Hermes to the old Gormes-shaped `NavivoxChannel` interface.
3. Use `/api/sessions/{session_id}/chat/stream` for MVP session chat because it is session-history oriented.
4. Use `/v1/runs` + `/v1/runs/{run_id}/events` for approval and stop/control flows once the persistence behavior is verified.
5. Replace Gormes pairing/durable credentials with Hermes endpoint setup: base URL in shared preferences, API key only in secure storage.
6. Hide or remove Gormes-only surfaces until Hermes-native APIs exist: Gormes config-admin, Goncho memory console, profile seed, voice profile configuration, and Gormes gateway management copy.

Detailed implementation slices live in [Hermes Agent interface plan for Navivox](../product/hermes-agent-interface-plan.md).

## Consequences

- Product language shifts from Gormes gateway/profile contacts to Hermes endpoint/sessions/conversations.
- The existing Gormes implementation becomes archival/recoverable via the `gormes` branch, not the mainline runtime contract.
- Navivox should prefer server-owned Hermes session history instead of resending/mutating old context, preserving Hermes prompt-cache and conversation invariants.
- The app can keep local device speech-to-text and submit transcripts as text turns to Hermes sessions.
- Some existing screens become out of scope for MVP until Hermes exposes matching APIs.

## Rejected alternatives

- **Hermes pretends to be a Gormes Navivox gateway.** This would preserve old Dart code short-term but keep the wrong model and `/v1/navivox/*` compatibility burden.
- **ACP-first mobile app.** ACP is valuable for editor/agent-client integrations, but Hermes API server is simpler and already includes sessions, runs, approvals, and stop controls for external UIs.
- **Dual Gormes/Hermes runtime families in mainline.** This would double setup, persistence, auth, stream parsing, and domain-language complexity right as the product direction is narrowing to Hermes Agent.
