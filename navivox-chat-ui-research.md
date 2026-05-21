# Navivox Chat UI Research

Status: planning draft
Updated: 2026-05-16
Source: current Navivox product direction and prior open-source UI survey

## 1. Decision Summary

Navivox should keep the current simple chat adapter until the connect-and-talk
loop is proven. After that, the production chat surface should become
Telegram-inspired around Gormes profiles as contacts: a dense flat profile
list, fast message scan, grouped bubbles with tails, compact timestamps, status
ticks, bottom-sheet actions, continuous voice transcript bubbles, and
first-class tool cards.

The Flutter app talks to Gormes, not directly to model providers. Any chat UI
package is only a rendering layer over `GatewayNavivoxChannel` state.

The stable contact identity is `server_id + profile_id`. A Gormes profile is an
isolated home/config/secrets/sessions/memory/skills/runtime state, not the same
thing as OpenClaw-style live multi-agent routing.

## 2. Telegram-Inspired Reference Plan

### 2.1 Verified References

Use these as current, source-backed references:

- `v_chat_bubbles` on pub.dev: strong candidate for bubble rendering because it
  supports a Telegram style preset, custom bubble types, selection mode,
  callbacks, text formatting, voice bubbles, and all Flutter target platforms.
- Flutter Material 3 docs: use current `NavigationBar`/rail patterns instead
  of legacy bottom navigation when adopting Material 3.
- Flutter `DraggableScrollableSheet`: use for Telegram-like action panels,
  server/profile switchers, transcript review, and tool detail sheets.
- `tdlib/td`: study only for Telegram client lifecycle and update ordering.
  Navivox must not add TDLib, MTProto, or Telegram network dependencies.
- `babakcode/flutter_chat`: lightweight visual reference for a Telegram-like
  Flutter chat app, useful for layout study but not a production architecture
  donor.

### 2.2 User-Supplied References To Verify Before Use

The operator also named Telware Cross-Platform, telega2,
`telegram_ios_ui_kit`, and `teleflutter`. Treat these as research leads until a
builder can verify source URL, license, maintenance state, platform support, and
API shape. Do not add them as dependencies or cite their behavior in product
contracts without that evidence.

### 2.3 Product Translation

Telegram pattern | Navivox translation
---|---
Chat list with avatars, last message, unread/status/time | Flat profile contact list keyed by `server_id + profile_id`, with server label, latest sanitized preview, health, attention count, mic affordance
Message bubbles | User/assistant/system bubbles backed by `GatewayNavivoxChannel`
Read ticks | Local send/queued/streaming/done/error state, not server read receipts
Voice message | Device transcript bubble with auto-send grace; audio playback only after voice run records
Attachment/action tray | Draggable sheet for tools, voice, profile seed, workspace roots, config, and future files
Pinned banner | Active server/profile/trust warning
Context menu | Copy, retry, inspect tool, reveal redacted fields when authorized
Search | Profile contact search first; session/message search once retention and APIs exist

## 3. Adopt

### 3.1 Profile Contact Read Model

Before visual polish, Gormes should expose a safe Navivox profile contact
summary API so Flutter does not infer contacts from raw config, doctor, and
session payloads.

Required snapshot:

- HTTP snapshot on app open/reconnect, such as `GET /navivox/contacts`.
- WebSocket updates for health, latest preview, active turn, attention, mic
  availability, and display metadata changes.
- Stale/reconnecting state when WS drops; refresh snapshot before applying
  resumed updates.

Contact summary fields:

- `server_id`
- `profile_id`
- `display_name`
- `avatar_seed`
- `latest_preview`
- `latest_preview_kind`
- `latest_preview_at`
- `health`
- `workspace_root_count`
- `workspace_roots_ok`
- `workspace_roots_warning`
- `workspace_roots_error`
- `attention_badges`
- `mic_available`
- `active_turn_state`

Rules:

- Preview text is server-sanitized, short, and redacted.
- Workspace details expose counts and health only, not raw paths.
- Local app data stays out of the API: pins, aliases, trusted-server state,
  command word, and calibration.
- Offline/unauthorized profiles remain visible with disabled send/mic affordance
  and recovery actions.

### 3.2 Bubble Renderer

Adopt `v_chat_bubbles` for the bubble layer if a builder proves the package can
wrap existing Navivox message state without taking over routing, persistence, or
backend behavior. The first use should be narrow:

- `VBubbleScope(style: VBubbleStyle.telegram)` at the chat screen boundary.
- `VTextBubble` for user and assistant text.
- `VVoiceBubble` only after voice run records define audio/playback state.
- `VCustomBubble` for `ToolCallCard`, so tools remain structured UI objects.
- Performance config for long transcripts.

The package must allow:

- External ownership of message state.
- Custom message types.
- Incremental updates for streaming text.
- Stable keys for message replacement.
- Accessible message actions.
- Desktop/web rendering without mobile-only assumptions.

Fallback: if package behavior, license, accessibility, performance, or theming
is unsuitable, keep the current simple adapter and implement local Telegram-like
widgets directly.

### 3.3 Text Streaming Renderer

Use a streaming text renderer for `assistant_delta` events only after the
channel tests prove one assistant message is updated per request. The renderer
should not create a new bubble for each delta.

## 4. Inspire From

### 4.1 Telegram-Style Apps

Useful patterns:

- A chat list is an operational dashboard, not just navigation.
- The chat screen should keep the composer always reachable.
- Presence/status belongs in small badges, not large banners unless degraded.
- Voice, attachments, search, and settings should live in sheets/drawers rather
  than taking over the main transcript.
- Media-heavy affordances are secondary for Navivox; tool and voice affordances
  are primary.

### 4.2 AI Chat Interfaces

Useful patterns:

- Event streams drive UI state.
- Tool calls are separate renderer types.
- Artifacts open in dedicated viewers.
- Approval controls are explicit and stateful.
- Errors include recovery actions.

### 4.3 Admin Interfaces

Useful patterns:

- Schema-driven forms.
- Field-level validation.
- Redacted secret status.
- Diff preview before apply.
- Confirmation for risky changes.

## 5. Skip Or Defer

Do not adopt packages that:

- Own model/provider orchestration in the Flutter app.
- Require a hosted chat backend.
- Require Firebase, MTProto, TDLib, or Telegram login for Navivox chat.
- Make tool calls plain transcript text.
- Force a single mobile-only layout.
- Add broad persistence before the product has retention rules.
- Require telephony concepts before the first local profile turn works.
- Treat profiles as local Flutter-only identities instead of server-owned
  Gormes homes.
- Make command words always-listening at the OS level.
- Allow local voice commands to approve tools or mutate profile config.

## 6. Message Types

### 6.1 Profile Contact Summary

Fields:

- `server_id`
- `profile_id`
- `display_name`
- `avatar_seed`
- `latest_preview`
- `latest_preview_kind`
- `latest_preview_at`
- `health`
- `workspace_root_count`
- `workspace_roots_ok`
- `workspace_roots_warning`
- `workspace_roots_error`
- `attention_badges`
- `mic_available`
- `active_turn_state`

Rendering:

- One flat Telegram-style list row per `server_id + profile_id`.
- Deterministic avatar, display name, small server label, timestamp, and
  attention count.
- A compact mic affordance starts continuous voice when available.
- Offline/unauthorized profiles remain visible but degraded.
- Full workspace paths and secrets never appear in the row.

### 6.2 Text Message

Fields:

- `id`
- `session_id`
- `request_id`
- `author`
- `text`
- `is_final`
- `created_at`
- `updated_at`

Rendering:

- User messages align to the trailing side.
- Assistant messages align to the leading side.
- Streaming assistant text updates in place.
- Markdown is allowed after sanitization.

### 6.3 ToolCallCard

Fields:

- `tool_call_id`
- `tool_name`
- `status`
- `summary`
- `input_preview`
- `output_preview`
- `artifacts`
- `requires_approval`
- `redaction_level`

Rendering:

```text
+-- execute_command ----------------------------+
| Status: running                                |
| Summary: checking system status                |
|                                                |
| [Inputs] [Output] [Artifacts]                  |
+------------------------------------------------+
```

Rules:

- Tool cards always start a new block.
- Tool cards stay visually distinct from ordinary prose even if implemented via
  a custom bubble adapter.
- Sensitive fields are redacted by default.
- Approval buttons render inside the card only when the event contract supports
  them; details open in a sheet.
- Voice approval commands are deferred; approval/deny requires visible UI
  controls in the first version.
- Raw JSON is behind a debug action, never the default UI.

### 6.4 Voice Message Bubble

Fields:

- `voice_run_id`
- `session_id`
- `transcript`
- `transcript_source`
- `confidence`
- `duration_ms`
- `capture_status`
- `playback_status`

Rendering:

- Shows transcript first.
- Shows a subtle mic/transcript marker for voice-originated user turns.
- Shows `Sending...` during the auto-send grace window.
- Shows waveform/playback when audio exists.
- Shows confidence only for degraded/low-confidence states.
- Allows cancellation during the grace window, not arbitrary post-send editing.
- Shows capture/transcription error as recoverable state.

### 6.5 System Message

Use for:

- Connected/disconnected status.
- Profile switch confirmation.
- Config apply result.
- Voice mode state.
- Safe errors.

System messages should be short and actionable.

## 7. Composer

Default composer:

```text
+------------------------------------------------+
| [+] Type a message...                  [mic] > |
+------------------------------------------------+
```

States:

- Default: text field, attachment/future action, mic, send.
- Voice auto-send: streaming transcript bubble plus visible `Sending...` grace
  state.
- Command mode: local command suggestions and timeout.
- Connecting: disabled send with reconnect status.
- Unauthorized: token action.
- Offline: retry action.

The composer must keep text fallback available even when voice capture fails.
Typed command-word commands are recognized only on chat composer submit. Search,
settings, and config fields treat the same text as ordinary input.

## 8. Tool Event Mapping

| Gateway Event | UI Result |
|---------------|-----------|
| `tool_call_started` | Create or update a running `ToolCallCard`. |
| `tool_call_finished` | Mark card completed/failed and attach safe summary. |
| `error` with tool context | Mark card failed when a tool id is present. |
| Future approval request | Add approve/deny controls to the card. |

## 9. Voice And Command Event Mapping

Current gateway behavior can send a device transcript as text. Continuous voice
therefore starts as app-side device STT plus normal Navivox turns, with local
command-word handling before a transcript reaches Gormes.

Local command contract:

- Default command word: `navi`.
- Custom command words are local app settings, lightly validated, and optional
  to calibrate by saying the word three times.
- Command word detection works only at utterance start while Navivox voice mode
  is active; no always-listening background command word.
- `navi` alone enters command mode for about five seconds.
- Direct commands work in one utterance: `navi mineru`, `navi cancel`,
  `navi stop`, `navi settings`, `navi help`.
- Command mode speech is discarded on timeout.
- Profile matching uses exact normalized local contact names/aliases only; no
  fuzzy auto-switch.
- Duplicate profile names across servers trigger disambiguation.
- Local aliases, pins, command word, calibration, and trusted-server state are
  local Navivox metadata.

Cancellation lifecycle:

- Capturing/transcribing: discard local bubble.
- Queued/grace window: remove before Gormes sees it.
- Sent but not active server-side: request turn cancel when supported and mark
  cancelled if accepted.
- Assistant/model response running: stop response if supported; user bubble
  remains.
- Tool approval pending: cancel pending approval/turn.
- Tool already executed or side effect started: do not claim undo; stop further
  output if possible and show side-effect-started evidence.

Future voice events should map to:

- Voice run created.
- Capture started/stopped.
- Transcript partial/final.
- Server STT complete.
- TTS audio ready.
- Playback started/stopped.
- Voice error.

## 10. Profile UI Patterns

The seed flow should feel like creating a draft profile, not filling a large
form first.

```text
Seed: [ work on mineru repo ]
      [Generate Draft]

Draft:
- Server
- Profile ID
- Display name
- Goal
- Instructions
- Tools
- Voice
- Workspace root labels/purposes
- Safety
```

The operator can edit every generated section before apply.
Actual workspace paths are never granted silently; each path is explicitly
entered or confirmed and validated by Gormes.

## 11. Config UI Patterns

Config forms are generated from server schema.

Required components:

- Section list.
- Typed field renderer.
- Secret status indicator.
- Diff viewer.
- Validation result panel.
- Confirmation sheet.
- Apply result banner.

Risk states:

- Local exposure: normal.
- VPN exposure: show interface evidence.
- Public exposure: require explicit confirmation.
- Provider or model change: show reconnect/restart impact.
- Secret change: write-only confirmation.
- Workspace root change: block or defer apply while that profile has active
  work unless Gormes reports the change is safe.

## 12. Layout Patterns

Mobile:

- Material 3 `NavigationBar` with Chats, Servers, Settings.
- Full-width chat transcript.
- `DraggableScrollableSheet` for profile/server/action switchers.
- Global voice bar when continuous voice is active outside the current chat.
- Tool card details as bottom sheet.

Desktop:

- Left rail.
- Persistent top bar.
- Status bar.
- Optional split detail panel for tool/config details.
- Keyboard-first composer.

## 13. Accessibility Requirements

- Icon buttons have text labels or tooltips.
- Status is not color-only.
- Tool cards are keyboard expandable.
- Voice auto-send has visible cancellation state during the grace window.
- Command mode has a visible timeout and suggestions.
- Secret fields announce redacted state.
- Error banners include a primary recovery action.

## 14. Acceptance For Replacing The Simple Adapter

- Existing setup-to-chat tests still pass.
- Streaming text updates one assistant bubble.
- `ToolCallCard` has widget tests for running, completed, failed, and redacted
  states.
- Voice bubble has text-only, auto-send grace, cancelled, stopped, and
  low-confidence tests.
- Chat list previews show profile avatar, display name, server label, sanitized
  preview, time, status, attention badges, workspace counts, and mic
  availability.
- Profile/server/tool sheets use `DraggableScrollableSheet` or an equivalent
  tested sheet interaction.
- Local command tests cover command word alone, direct `navi <profile>`, exact
  duplicate disambiguation, `navi cancel`, `navi stop`, timeout discard, typed
  composer command handling, and disabled voice switching.
- Mobile and desktop layouts have snapshot or widget coverage.
- The first turn still works without telephony setup.
