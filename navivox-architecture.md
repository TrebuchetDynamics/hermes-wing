# Navivox Architecture

Status: planning draft
Updated: 2026-05-16

## 1. High-Level Architecture

```text
+---------------------------------------------------------------+
| Flutter Navivox app                                           |
|                                                               |
|  SetupScreen  ChatScreen  AgentsScreen  ConfigScreen  Voice   |
|       |           |            |             |           |     |
|       +-----------+------------+-------------+-----------+     |
|                           Riverpod state                      |
|                                 |                             |
|                       GatewayNavivoxChannel                   |
|                                 |                             |
|                       NavivoxGatewayClient                    |
+---------------------------------+-----------------------------+
                                  |
                                  | HTTP JSON + WebSocket JSON
                                  v
+---------------------------------------------------------------+
| Gormes Navivox channel                                        |
|                                                               |
|  /healthz                                                     |
|  /v1/navivox/status                                           |
|  /v1/navivox/sessions                                         |
|  /v1/navivox/turn                                             |
|  /v1/navivox/stream                                           |
|                                                               |
|  Auth, CORS, exposure validation, sessions, gateway fanout     |
+---------------------------------+-----------------------------+
                                  |
                                  v
+---------------------------------------------------------------+
| Gormes gateway manager and agent runtime                      |
+---------------------------------------------------------------+
```

The app is a first-party operator client. The server owns runtime behavior;
Flutter owns interaction, rendering, and local recovery state.

## 2. Current Package Layout

```text
lib/
  app.dart
  main.dart
  core/
    channel/
      gateway_navivox_channel.dart
      navivox_channel.dart
      navivox_channel_provider.dart
    gateway/
      navivox_gateway_client.dart
      navivox_gateway_protocol.dart
    protocol/
      navivox_event.dart
  features/
    agents/
      screens/agents_screen.dart
    chat/
      screens/chat_screen.dart
      widgets/approval_banner.dart
      widgets/simple_chat_adapter.dart
    config/
      screens/config_screen.dart
    servers/
      screens/setup_screen.dart
      screens/servers_screen.dart
    voice/
      services/audio_recorder.dart
      services/record_voice_capture_service.dart
      services/speech_recognizer.dart
      services/voice_capture_service.dart
      widgets/voice_morph_surface.dart
  router/
    app_router.dart
    app_routes.dart
  shared/
    widgets/app_shell.dart
```

Near-term additions should follow the same feature-first shape.

## 3. Core Responsibilities

### 3.1 Gateway Client

`NavivoxGatewayConfig` owns URL derivation:

- `healthUri` -> `/healthz`
- `statusUri` -> `/v1/navivox/status`
- `sessionsUri` -> `/v1/navivox/sessions`
- `turnUri` -> `/v1/navivox/turn`
- `streamUri` -> `/v1/navivox/stream` with `http` mapped to `ws` and `https`
  mapped to `wss`

It also owns bearer auth header creation. Tokens remain in memory or secure
local storage once that feature is added; they are never embedded in route
paths.

### 3.2 Gateway Channel

`GatewayNavivoxChannel` adapts gateway events into UI state:

- Connects after a successful status probe.
- Opens the WebSocket stream.
- Sends `start_turn` messages.
- Tracks the active session.
- Appends user, assistant, system, and tool messages.
- Converts `tool_call_started` and `tool_call_finished` into structured tool
  message state.

### 3.3 Server Channel

`internal/channels/navivox.Channel` exposes:

- `Handler(inbox)` for HTTP tests and gateway mounting.
- `Run(ctx, inbox)` for serving the configured channel.
- Gateway `Send`, `SendPlaceholder`, `EditMessage`, and `EditMessageFinal`
  methods for assistant output fanout.

The server validates Navivox config at startup and fails closed when exposure or
auth settings are unsafe.

## 4. Connection Lifecycle

```text
Operator runs gormes navivox connect-info
        |
        v
Flutter receives base URL and optional token
        |
        v
GET /healthz
        |
        v
GET /v1/navivox/status
        |
        v
Open WS /v1/navivox/stream
        |
        v
Create local server entry and navigate to chat
        |
        v
Send start_turn over stream or POST /v1/navivox/turn
        |
        v
Gormes gateway processes the turn
        |
        v
assistant_delta / assistant_message / tool_call_* / done
```

Reconnect behavior:

- The client uses bounded exponential backoff.
- UI keeps existing messages visible while reconnecting.
- A lost stream is visible as connection state, not as deleted chat history.

## 5. HTTP Turn Flow

`POST /v1/navivox/turn` accepts:

```json
{
  "request_id": "client-generated-id",
  "session_id": "optional-existing-session",
  "text": "hello",
  "metadata": {
    "client": "navivox",
    "platform": "flutter"
  }
}
```

Successful response:

```json
{
  "request_id": "client-generated-id",
  "session_id": "navivox-session-id",
  "status": "queued"
}
```

The WebSocket path uses the same message semantics for `start_turn`.

## 6. Event Model

Server events are JSON objects:

```json
{
  "type": "assistant_delta",
  "request_id": "client-generated-id",
  "session_id": "navivox-session-id",
  "text": "partial text"
}
```

Known event types:

- `pong`
- `session_started`
- `assistant_delta`
- `assistant_message`
- `tool_call_started`
- `tool_call_finished`
- `error`
- `done`

Unknown events are ignored until the app has a renderer for them.

## 7. Chat And Tool Rendering

The chat layer receives typed channel state, not wire payloads.

Message kinds:

- User text.
- Assistant text.
- System status.
- Tool call card.
- Voice message bubble.

Tool cards own:

- tool name
- tool call id
- status
- summary
- artifacts
- approval state
- redacted details

This keeps tool output inspectable without turning the transcript into a log
dump.

## 8. Agent Seed Architecture

The seed flow is a server operation. Flutter submits a short phrase and renders
the returned draft:

```text
seed text
  -> server generator
  -> agent draft
  -> editable sections
  -> validate
  -> apply
```

Draft sections:

- Agent profile.
- Prompt/instructions.
- Tool access.
- Voice defaults.
- STT/TTS provider preferences.
- Safety/escalation policy.

No generated draft is applied without operator confirmation.

## 9. Config Admin Architecture

```text
schema + redacted values
  -> local form model
  -> diff request
  -> validation request
  -> confirmation
  -> apply request
  -> reload/reconnect result
```

Rules:

- Server schema controls fields, types, validation, and secret metadata.
- Secret values are write-only.
- UI displays redacted status and source evidence.
- Changes that affect gateway exposure require explicit confirmation.

## 10. Voice Architecture

Current behavior can submit a device transcript as a text turn.

Planned voice flow:

```text
record audio
  -> local transcript when available
  -> voice run record
  -> server STT/profile
  -> agent turn
  -> server TTS/profile
  -> playback event
```

Voice run records let the UI show capture, transcript, provider, playback, and
error state as durable objects.

### 10.1 Client-local Voice run first

The first Voice run slice is client-local. Navivox records lifecycle metadata,
transcript source, pending-send/cancel/failure state, and planned STT/TTS
status while continuing to submit the final transcript through the existing
`start_turn` path.

Server voice events are future work. Planned event names are:

- `voice_run_started`
- `voice_transcript_partial`
- `voice_transcript_final`
- `voice_server_stt_complete`
- `voice_tts_ready`
- `voice_playback_started`
- `voice_playback_stopped`
- `voice_error`

These names are not active protocol until Gormes emits at least one of them.
Binary audio transport remains deferred until Voice run lifecycle,
retention/redaction policy, and a server STT/TTS event contract exist.

## 11. Router Architecture

Current router:

- Starts at `/chats`.
- Redirects to `/setup` when no gateway-backed server exists.
- Redirects away from `/setup` once a gateway-backed server exists.
- Mounts setup plus shell tabs for chat, servers, agents, and config.

Detail routes should be added only when their screens can work against the
current gateway contract.

## 12. Trust Boundaries

Sensitive data handling:

| Data | Location | Policy |
|------|----------|--------|
| Bearer token | Memory or secure local storage | Redacted in UI/logs; never in routes. |
| Gateway base URL | Local app state | Safe to show. |
| Chat text | Local cache and server session | Redact when marked private. |
| Tool output | Server event and UI card | Redact sensitive fields by default. |
| Config secrets | Server only | Write-only from app. |
| Voice audio | Future voice run storage | Retention and redaction policy required before persistence. |

Exposure handling:

- Disabled by default.
- Loopback for local mode.
- VPN validation for VPN-class modes.
- Explicit confirmation for public exposure.
- Tokens are never printed by `connect-info`.

## 13. Platform Notes

| Area | Android | iOS | Linux | Windows | macOS |
|------|---------|-----|-------|---------|-------|
| HTTP/WebSocket client | Dart IO | Dart IO | Dart IO | Dart IO | Dart IO |
| Secure token storage | Platform secure storage | Keychain | Secret service | DPAPI | Keychain |
| Local unlock | Biometric/PIN | Biometric/PIN | App PIN fallback | Windows Hello/PIN | Touch ID/PIN |
| Voice capture | Platform mic | Platform mic | System mic deps | System mic | Platform mic |
| Local STT | Platform service | Platform service | Optional fallback | Optional fallback | Platform service |

Platform support should degrade to text-only chat when voice features are not
available.

## 14. Test Architecture

Unit tests:

- URL derivation and auth headers.
- Gateway event decode.
- Channel state transitions.
- Router redirects.
- Tool card state.
- Config form validation.

Integration tests:

- Fixture HTTP gateway for Flutter setup and chat.
- In-process Go handler for `/healthz`, status, turn, and stream.

Acceptance smoke:

- Operator can connect from `connect-info`, open chat, submit one turn, and see
  streamed assistant output without telephony setup.
