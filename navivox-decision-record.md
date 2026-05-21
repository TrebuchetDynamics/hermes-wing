# Navivox Decision Record

Status: accepted baseline
Date: 2026-05-16
Scope: Flutter app plus Gormes `navivox` channel planning

This file is the canonical decision surface for current Navivox planning docs.
The PRD, architecture, routes, UI, library research, and testing plan may add
detail, but should not contradict the decisions below.

## 1. Product Activation

The first useful Navivox screen lets an operator connect to a Gormes host and
talk to an agent immediately, without telephony setup. Dograh's "Web Call"
lesson translates to Gormes as "connect and talk now" over the existing
HTTP/WebSocket gateway.

Scope for this activation loop:

- The operator runs `gormes navivox connect-info` on the host.
- The app accepts a base URL plus token, probes `/healthz`, then opens the
  Navivox stream.
- The primary surface is chat with optional device transcript input. Phone
  numbers, campaigns, retries, scheduling, circuit breakers, and human handoff
  stay out of scope until the local loop is excellent.

## 2. Chat UI Foundation

Navivox will use `flyerhq/flutter_chat_ui` v2 as the planned chat foundation.

Rationale:

- It is backend-agnostic, which matches the first-party Gormes gateway rather
  than a vendor-hosted chat backend.
- It has a modular `flutter_chat_core` / `flutter_chat_ui` split and a builder
  system for replacing message renderers.
- Streaming text maps cleanly to server events when stream state is owned by
  the Navivox channel/provider layer.

Navivox-specific extensions:

- `ToolCallCard`: rendered through custom message builders, never as raw logs
  inside assistant text.
- `VoiceMessageBubble`: waveform, playback, transcript, confidence, and run
  status display for voice turns.
- `AgentSwitcherMessage`: an inline system/control message for agent switch
  events and local-command confirmations. The global agent picker remains a
  sheet/menu, not a chat bubble.

Implementation boundary:

- The Flutter chat controller mirrors gateway events and local UI state.
  Agent orchestration, tools, approvals, and model calls remain server-side in
  Gormes.

## 3. App Architecture Stack

The current app uses Riverpod + GoRouter with typed Dart models. Generated
models may be added where protocol unions become large enough to justify them.

Rationale:

- Riverpod owns connection, channel, chat, config, voice, and routing state with
  testable providers.
- GoRouter owns URL-shaped routes, shell routes, redirects, and deep links.
- Typed models keep the gateway protocol explicit while the API is still small.
- Local persistence is a cache, not the source of truth. The Gormes server is
  authoritative for agents, config, sessions, tools, and voice provider
  settings.

Folder structure:

- Keep the existing feature-first plan: `core/`, `features/`, `router/`, and
  `shared/`.
- Put gateway client and event codecs under `core/gateway/`.
- Put channel state translation under `core/channel/`.
- Use `features/<feature>/{providers,screens,widgets}` for UI-facing features.

## 4. Gateway Protocol

Navivox uses HTTP for readiness and one-shot turns, plus WebSocket for live
events.

Supported current endpoints:

- `GET /healthz`: unauthenticated readiness probe.
- `GET /v1/navivox/status`: authenticated channel status.
- `GET /v1/navivox/sessions`: authenticated session list.
- `GET /v1/navivox/sessions/{session_id}`: authenticated session detail.
- `POST /v1/navivox/turn`: authenticated text turn enqueue.
- `WS /v1/navivox/stream`: authenticated bidirectional event stream.

Current client messages:

- `ping`
- `start_turn`
- `cancel_turn`
- `subscribe_session`

Current server events:

- `pong`
- `session_started`
- `assistant_delta`
- `assistant_message`
- `tool_call_started`
- `tool_call_updated`
- `tool_call_finished`
- `error`
- `done`

Rules:

- Messages are JSON objects with `type` and `request_id`.
- HTTP auth uses bearer tokens when `auth_mode` requires a token.
- `NavivoxGatewayConfig` derives `ws://` or `wss://` stream URLs from the base
  URL returned by `connect-info`.
- Tool events are structured cards with bounded summaries; raw tool arguments,
  stdout, secrets, and full logs must not be serialized as chat text.
- Binary audio transport is future work; the first voice loop can submit device
  transcripts as text while voice run records are designed.

## 5. Voice Architecture

Navivox will use server-first TTS and hybrid STT.

TTS:

- Gormes generates agent speech through configured server-side providers.
- The app plays server audio when a future voice event contract exposes it.
- Local TTS is optional and limited to short confirmations such as "Connected"
  or "Agent switched"; it is not the primary desktop TTS path.

STT:

- Local STT handles wake word and short control command detection.
- Audio plus the device transcript can be submitted to Gormes once voice run
  records and upload semantics exist.
- Text-only fallback is always valid.

## 6. Config Administration

Navivox config admin will be schema-driven, redacted, and
server-authoritative.

Flow:

```text
config.schema + redacted config.get
  -> local edits
  -> config.diff
  -> config.validate
  -> user confirmation
  -> config.apply
  -> config.reload or pending-restart result
```

Rules:

- The app never edits local config files directly.
- Secrets are write-only. Reads return status/source/redacted evidence, never
  secret values.
- Secret fields render as status indicators plus set/rotate/delete/test
  actions, gated by server role and local unlock policy.
- Sensitive or disruptive changes require explicit confirmation with exact
  before/after non-secret values.

## 7. Reachability And Trust Boundaries

- `gormes navivox connect-info` is the host-facing setup surface.
- The command prints base URLs and health URLs for the configured exposure mode.
- Token values are never printed; output only says whether a token is required.
- The channel is disabled by default.
- Local mode uses loopback.
- VPN-class modes require active Tailscale/WireGuard-style interfaces and bind
  validation.
- Public exposure requires explicit config confirmation and should remain
  exceptional.
- App logs and Gormes logs redact tokens, secret-shaped values, transcripts
  marked private, and tool output marked sensitive.

## 8. Implementation Order

Order:

1. Refresh planning docs to describe the HTTP/WebSocket gateway only.
2. Build the connect-and-talk first screen against a fixture gateway and the
   real Navivox channel handler.
3. Add natural-language agent seed creation that generates editable agent,
   profile, tool, and voice settings.
4. Render tools as first-class UI objects through `ToolCallCard`.
5. Add schema-driven safe config admin over HTTP.
6. Define voice run records and then add BYO STT/TTS provider profiles.

This order keeps the core operator loop small and proven before adding
call-center breadth.
