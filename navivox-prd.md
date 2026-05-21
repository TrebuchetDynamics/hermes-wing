# Navivox Product Requirements

Status: planning draft
Updated: 2026-05-16
Scope: Flutter Navivox app and Gormes `navivox` HTTP/WebSocket channel

## 1. Summary

Navivox is the operator-facing Flutter app for talking to local or self-hosted
Gormes agents. Its first useful screen must let the operator connect to a
Gormes host and talk to an agent immediately, without telephony setup.

The current transport is the Gormes Navivox gateway:

- `gormes navivox connect-info` prints reachable base URLs.
- `GET /healthz` proves basic readiness.
- `GET /v1/navivox/status` proves authenticated channel readiness.
- `POST /v1/navivox/turn` enqueues a text turn.
- `WS /v1/navivox/stream` streams session and assistant events.

The app should feel like a voice-agent workbench, not a call-center suite. It
should make the core local loop excellent before adding campaigns, scheduling,
retries, circuit breakers, phone numbers, or human handoff.

## 2. Goals

- Connect to a Gormes Navivox gateway from a base URL and token.
- Let the operator send a text or device-transcribed voice turn from the first
  main screen.
- Show gateway readiness, active session state, streaming assistant text, and
  structured errors.
- Create agents from short natural-language seeds such as "screen inbound
  leads" or "triage support calls".
- Generate editable agent, profile, tool, and voice settings from the seed.
- Render tool activity as UI objects, especially `ToolCallCard`, not as text
  logs inside assistant messages.
- Make config admin easy while keeping Gormes safer than direct local file
  edits: schema-driven, redacted, server-authoritative, and explicitly
  confirmed.
- Keep voice provider/profile support BYO-friendly without blocking the first
  connect-and-talk loop.

## 3. Non-Goals

- Telephony setup in the first activation loop.
- Campaign management, retries, scheduling, circuit breakers, or human handoff.
- Direct editing of local config files from the app.
- Printing or storing raw server tokens in screenshots, logs, route URLs, or
  deep links.
- Public exposure by default.
- A generic remote terminal or server administration app as the primary product.

## 4. Personas

### 4.1 Operator

Runs Gormes locally or on a trusted host, wants to talk to an agent quickly, and
expects setup to be copy/paste simple.

### 4.2 Admin

Owns provider keys, agent policy, tool access, voice defaults, and config
changes. Needs redacted evidence and explicit confirmation before risky changes.

### 4.3 Builder

Implements Navivox slices. Needs docs that match the current HTTP/WebSocket
runtime so obsolete transport assumptions do not come back.

## 5. System Architecture

```text
Flutter Navivox app
  - SetupScreen
  - GatewayNavivoxChannel
  - Chat / Agents / Config / Voice UI
        |
        | HTTP JSON + WebSocket JSON
        v
Gormes Navivox channel
  - /healthz
  - /v1/navivox/status
  - /v1/navivox/sessions
  - /v1/navivox/turn
  - /v1/navivox/stream
        |
        v
Gormes gateway manager and agent runtime
```

Flutter owns local UX state, input capture, message rendering, and recovery
flows. Gormes owns agent orchestration, sessions, model calls, tools, config,
secrets, and provider execution.

## 6. Connection And Reachability

`gormes navivox connect-info` is the host-facing setup surface. It prints one
or more base URLs plus health URLs for the configured exposure mode. It never
prints token values.

Connection flow:

1. Operator enables the Navivox channel in Gormes config.
2. Operator starts the Gormes gateway.
3. Operator runs `gormes navivox connect-info`.
4. App receives a base URL and token when required.
5. App calls `/healthz`.
6. App calls `/v1/navivox/status`.
7. App opens `/v1/navivox/stream`.
8. App lands in chat.

Trust boundaries:

- The channel is disabled by default.
- Local mode is loopback by default.
- VPN-class modes require active VPN interface detection and bind validation.
- Public exposure requires explicit confirmation in server config.
- Bearer tokens are redacted in UI, logs, and route data.
- CORS/origin policy is server-owned.

## 7. Gateway Protocol

### 7.1 HTTP Endpoints

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| GET | `/healthz` | No | Basic process readiness. |
| GET | `/v1/navivox/status` | Yes | Channel readiness, auth mode, exposure mode, counts. |
| GET | `/v1/navivox/sessions` | Yes | List known Navivox sessions. |
| GET | `/v1/navivox/sessions/{session_id}` | Yes | Fetch one session. |
| POST | `/v1/navivox/turn` | Yes | Enqueue a text turn and return queued status. |
| WS | `/v1/navivox/stream` | Yes | Bidirectional client messages and server events. |

### 7.2 Client Messages

| Type | Required Fields | Purpose |
|------|-----------------|---------|
| `ping` | `request_id` | Keepalive and diagnostics. |
| `start_turn` | `request_id`, `text` | Submit a chat turn, optionally in an existing session. |
| `cancel_turn` | `request_id`, `session_id` | Cancel active work for a session. |
| `subscribe_session` | `request_id`, `session_id` | Receive events for an existing session. |

### 7.3 Server Events

| Type | Purpose |
|------|---------|
| `pong` | Reply to `ping`. |
| `session_started` | Confirms or announces the session id. |
| `assistant_delta` | Streaming assistant text delta. |
| `assistant_message` | Final or replaced assistant message. |
| `tool_call_started` | Begin a structured tool card. |
| `tool_call_updated` | Update status or bounded summary for a tool card. |
| `tool_call_finished` | Complete a structured tool card. |
| `error` | Safe error code/message. |
| `done` | End of the current turn stream. |

Tool events carry `tool_call_id`, `tool_name`, `status`, and a bounded
`message` summary. Raw tool arguments, stdout, secrets, and full logs are out
of scope for Navivox events.

## 8. First Useful Screen

The first post-setup screen is chat. It should show:

- Gateway state: connected, reconnecting, offline, unauthorized, or blocked by
  exposure settings.
- Active server label and base URL host.
- Active agent pill.
- Text composer.
- Voice button that can submit a local transcript as a text turn.
- Streaming assistant messages.
- Tool cards when tool events exist.

The screen must not require phone numbers, campaigns, outbound lists, or
provider-specific voice setup before the first turn.

## 9. Agent Seed Flow

The first agent creation flow starts with a short natural-language seed:

```text
screen inbound leads
triage support calls
book follow-up appointments
summarize client intake calls
```

The server should generate an editable draft containing:

- Agent name and description.
- Goal/instructions.
- Intake questions or conversation policy.
- Tool selection and tool permissions.
- Voice profile defaults.
- STT/TTS provider preferences when configured.
- Safety and escalation notes.

The draft is not applied silently. The operator reviews and confirms it.

## 10. Tools As UI Objects

Tool activity is product state, not log text.

Rules:

- `ToolCallCard` owns tool name, status, summary, inputs, outputs, artifacts,
  and approval state.
- Tool cards are expandable and redact sensitive fields by default.
- Approval controls are disabled until the gateway exposes a matching approval
  event contract.
- Raw tool JSON can exist behind a debug affordance, never as the primary UI.

## 11. Voice Runs

Voice support is staged.

Current loop:

- Device capture or local STT may produce a transcript.
- The transcript is sent through the current text turn path.

Planned voice run record:

- `voice_run_id`
- `session_id`
- local capture metadata
- transcript source and confidence
- server STT provider/profile
- TTS provider/profile
- playback state
- redaction and retention policy

BYO STT/TTS support should attach to agent or profile settings and remain
editable per agent.

## 12. Config Admin

Config admin is server-authoritative.

Required flow:

```text
schema + redacted values
  -> local edit draft
  -> server diff
  -> server validation
  -> explicit confirmation
  -> server apply
```

Requirements:

- The app never writes local config files directly.
- Secrets are write-only and displayed as status/source evidence.
- Dangerous changes show exact non-secret before/after values.
- Server validation errors map to fields.
- Applied changes report whether a restart or reconnect is required.

## 13. Data Model

Local app state may cache:

- Gateway connection records.
- Auth mode and redacted token status.
- Sessions.
- Chat messages.
- Tool calls.
- Voice run metadata.
- Agent drafts and profiles.
- Config schema and redacted config snapshots.

The server remains authoritative. Local data is safe to rebuild after a cache
clear.

## 14. Library Plan

Current app dependencies are intentionally small:

- Flutter.
- `flutter_riverpod`.
- `go_router`.
- `freezed_annotation` and `json_annotation` for future generated models.
- `uuid`, `intl`, and `path`.

Planned additions should be tied to a shipped feature:

- Chat UI package when replacing the simple current chat adapter.
- Secure storage for local tokens.
- Local auth for secret editing unlock.
- Microphone capture and STT packages for voice runs.
- Audio playback for server TTS.

Avoid broad persistence or platform packages until the workflow that needs them
is in progress.

## 15. Error Handling

User-facing error states:

- Gateway URL invalid.
- `/healthz` unavailable.
- Status request unauthorized.
- Stream refused by origin policy.
- Token required or rejected.
- Gateway inbox full.
- Session not found.
- Config schema unavailable.
- Secret mutation denied.
- Voice capture unavailable.

Error copy should include the next action and should not expose tokens or raw
provider errors.

## 16. Testing Requirements

Flutter:

- Unit tests for URL derivation and auth headers.
- Unit tests for gateway event decoding.
- Channel tests for connect, send, reconnect state, assistant deltas, final
  messages, tool card events, and safe errors.
- Router tests for setup-to-chat redirect behavior.

Go:

- `cmd/gormes` tests for `navivox connect-info`.
- `internal/channels/navivox` tests for health/status/sessions/turn/stream.
- Config validation tests for disabled, local, VPN, public, auth, CORS, and
  redaction behavior.

Integration:

- Fixture HTTP gateway for Flutter setup/chat flows.
- Real Go handler fixture for one connect-and-talk path.

## 17. Delivery Phases

### Phase 1: Documentation And Gateway Contract

- Docs name the HTTP/WebSocket path.
- CLI docs explain `connect-info`.
- Stale remote-shell transport guidance is removed or historical-only.

### Phase 2: Connect And Talk

- Setup accepts base URL and token.
- App proves health/status.
- App opens the stream.
- Operator sends a text or transcript turn.
- Assistant streaming is visible.

### Phase 3: Agent Seed

- Operator enters a short seed.
- Server returns editable agent/profile/tool/voice draft.
- Confirmed draft is applied through server APIs.

### Phase 4: Tool Objects

- Tool events render as cards.
- Approval and artifact states are explicit.

### Phase 5: Safe Config Admin

- Schema-driven editor.
- Redacted reads.
- Server diff/validate/apply.
- Restart/reconnect result.

### Phase 6: Voice Profiles

- Voice run records.
- BYO STT/TTS provider/profile settings.
- Agent-specific voice defaults.

## 18. Acceptance Criteria

- A fresh app can paste a base URL from `gormes navivox connect-info`, connect
  to a local gateway, and send a first turn.
- The app never asks for telephony setup before the first turn.
- Tool activity is represented by structured UI.
- Config changes go through server schema, diff, validation, and apply.
- Tokens and secret-shaped values do not leak into app logs, Gormes logs, route
  URLs, or screenshots.
- Public exposure is never implied as the default path.
