# Navivox Decision Record

Status: historical Gormes baseline plus active Hermes-first amendments
Date: 2026-07-03
Scope: Flutter app, active Hermes Agent companion surface, and preserved legacy Gormes `navivox` channel planning

This file records durable product/architecture decisions. The original
Gormes-first baseline remains below for preserved legacy paths; ADR 0006 and ADR
0007 amend mainline direction to a native Hermes Agent runtime. Current Hermes
implementation evidence lives in `lib/core/hermes/channel/hermes_api_channel.dart:19`,
`lib/features/hermes_chat/screens/hermes_chat_screen.dart:42`, and
`lib/core/hermes/policy/hermes_surface_readiness.dart:27`.

## 1. Product Activation

Active Hermes-first decision: the fresh-install first useful screen is `/hermes`.
It lets an operator connect to a trusted local, LAN, VPN, or self-hosted Hermes
Agent API server, create/select a Hermes session, send text, and submit local
STT voice transcripts without telephony setup. Voice remains device STT ->
Hermes text; Hermes realtime/server audio is not implemented.

Preserved legacy Gormes decision: the first useful Gormes path lets an operator
connect to a Gormes host and talk to an agent immediately, without telephony
setup. Dograh's "Web Call" lesson translates to Gormes as "connect and talk now"
over the existing HTTP/WebSocket gateway.

Scope for the active Hermes activation loop:

- The operator enters a Hermes endpoint base URL plus optional API key.
- The app probes `/health` and `/v1/capabilities`, then loads or creates a
  Hermes session through `/api/sessions`.
- Chat streams through `/api/sessions/{session_id}/chat/stream`, with `/v1/runs`
  controls only when capabilities advertise a safe run transport.
- The primary surface is Hermes session chat with optional local device
  transcript input. Phone numbers, campaigns, retries, scheduling, circuit
  breakers, human handoff, server realtime audio, config admin, memory UI, jobs
  admin, messaging gateways, persona/SOUL, attachments/media, files/context
  folders, and raw diagnostics/log export stay out of the current MVP unless a
  later source-backed decision changes that. Multi-endpoint/profile management
  is in the Hermes connect MVP as local saved endpoint profiles with per-profile
  API keys kept in secure storage.

Scope for the preserved Gormes activation loop:

- The operator runs `gormes navivox connect-info` on the host.
- The app accepts a base URL plus token, probes `/healthz`, then opens the
  Navivox stream.
- The primary legacy surface is chat with optional device transcript input.

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
- Binary audio transport is deferred; the first voice loop submits device
  transcripts as text while Voice run lifecycle state is designed.

## 5. Voice Architecture

Navivox will use server-first TTS and hybrid STT.

TTS:

- Gormes generates agent speech through configured server-side providers.
- The app plays server audio when a future voice event contract exposes it.
- Local TTS is optional and limited to short confirmations such as "Connected"
  or "Agent switched"; it is not the primary desktop TTS path.

STT:

- Local STT handles wake word and short control command detection.
- Audio plus the device transcript can be submitted to Gormes once Voice run
  lifecycle state and upload semantics exist.
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
6. Define Voice run lifecycle state and then add BYO STT/TTS provider profiles.

This order keeps the core operator loop small and proven before adding
call-center breadth.
