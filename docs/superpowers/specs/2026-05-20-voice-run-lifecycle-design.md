# Voice Run Lifecycle Design

Status: approved design draft
Date: 2026-05-20
Scope: Navivox Flutter app first; Gormes Navivox channel protocol later

## Goal

Deepen **Voice run** into the canonical Navivox module for one end-to-end voice interaction before adding binary audio transport or server TTS playback.

## Accepted Decisions

1. **Voice run** is the canonical domain term for one end-to-end voice interaction: capture, transcript, optional server STT, agent turn, optional server TTS, playback, cancellation, errors, and retention policy.
2. The first implementation slice is metadata/lifecycle only: no binary audio upload and no server TTS playback.
3. Server STT is represented in the model as planned state, but only `device` and `manual` transcript sources are reachable in the first slice.
4. Server TTS is represented as optional playback state, but only `unavailable` is reachable in the first slice.
5. Voice run state belongs in core protocol/channel models, not in `ChatScreen` local fields.
6. Local command parsing stays in `ChatScreen`; a detected **Local command** must not create or submit a Voice run to the **Gormes gateway**.
7. The first Voice run model is client-local. Existing transcript fallback still submits the final transcript through the current `start_turn` path.
8. Gateway event reduction for voice streams is planned now, but implementation waits until at least one server voice event exists.
9. A separate voice control plane is future work. The first slice keeps `start_turn` compatibility.
10. STT/TTS profile readiness appears first as read-only **Profile contact** capability state, not config editing UI.
11. Binary audio transport is deferred until all three are true:
    - Voice run lifecycle exists.
    - Retention/redaction policy exists.
    - Gormes exposes at least one server STT or TTS event contract.

## Current Problem

Today voice is shallow:

- `ChatScreen` owns pending voice, grace-window timers, cancellation wording, and local command branching.
- `NavivoxChannel.sendVoice` accepts only a transcript string.
- `GatewayNavivoxChannel.sendVoice` converts voice to a normal `start_turn` text message.
- `NavivoxVoiceMessage` renders duration, transcript, and confidence, but does not describe lifecycle, transcript source, STT provider state, TTS state, or retention.
- `ProfileContact.micAvailable` cannot express device STT availability, planned server STT, planned server TTS, or degraded-mode recovery.

The deletion test: deleting a future Voice run module would push capture status, transcript source, cancellation, STT/TTS state, playback state, and retention rules back into `ChatScreen`, the channel, profile contacts, and tests. That means Voice run can be a deep module.

## Proposed Module

### Voice run

A **Voice run** is product state with a small interface and a larger implementation behind it.

It should track:

- stable `voice_run_id`
- target `server_id` and `profile_id`
- optional `session_id`
- optional `request_id` once submitted
- lifecycle status
- transcript and transcript source
- confidence and duration
- STT status
- TTS/playback status
- cancellation/error reason
- retention/redaction policy marker
- timestamps for capture/submission/completion

### First-slice lifecycle

Reachable statuses in the first client-local slice:

```text
idle
  -> recording
  -> transcribing
  -> pending_send
  -> submitted
  -> completed

pending_send -> cancelled
recording/transcribing/pending_send/submitted -> failed
```

Planned statuses for later server voice events:

```text
submitted
  -> server_processing
  -> server_stt_complete
  -> agent_turn_running
  -> tts_queued
  -> tts_ready
  -> playing
  -> completed
```

### Transcript source

The model allows:

- `device` — reachable first slice.
- `manual` — reachable first slice when text fallback creates a voice-marked run manually.
- `server` — planned only until audio upload/server STT exists.

### TTS status

The model allows:

- `unavailable` — reachable first slice.
- `queued` — planned.
- `ready` — planned.
- `playing` — planned.
- `stopped` — planned.
- `failed` — planned.

## State Ownership

### Move out of ChatScreen

`ChatScreen` should stop owning the Voice run lifecycle directly. In the implementation slice, move these concepts into core state:

- pending voice capture
- grace-window status
- created-at timestamp
- submitted/cancelled/failed status
- voice transcript bubble data

### Keep in ChatScreen for now

`ChatScreen` still owns:

- Local command parsing
- command mode timer
- route/Profile contact syncing
- deciding that a Local command should not become a Voice run

## Channel Behavior

### First slice

The `NavivoxChannel` interface may gain a Voice run-oriented action, but the gateway adapter still sends the final transcript via existing `start_turn`.

No Gormes channel endpoint or WebSocket message is required for the first slice.

### Later slice

Once server voice events exist, the stream event reducer can map these planned event types into Voice run state:

- `voice_run_started`
- `voice_transcript_partial`
- `voice_transcript_final`
- `voice_server_stt_complete`
- `voice_tts_ready`
- `voice_playback_started`
- `voice_playback_stopped`
- `voice_error`

These names are planning vocabulary, not a protocol commitment for the first slice.

## Profile Contact Capability

Add read-only capability state before config editing UI:

- device STT available/unavailable
- server STT unavailable/planned/available
- server TTS unavailable/planned/available
- voice input enabled/disabled reason
- recovery action label

The UI must not expose raw provider config, secrets, or workspace paths.

## Binary Audio Transport Deferral

Do not add binary audio upload, WebSocket binary frames, HTTP multipart upload, or playback downloads until:

1. Voice run lifecycle exists in client state.
2. Retention/redaction policy is explicit.
3. Gormes has at least one server STT or TTS event contract.

This avoids a shallow hypothetical transport seam.

## Test Strategy

First client-local slice should add/update Flutter tests for:

- Voice run starts recording from mic action.
- Device transcript moves to `pending_send` during grace window.
- Grace-window cancel marks the Voice run cancelled and sends nothing to Gormes.
- Grace-window completion submits transcript through existing `start_turn` path.
- Local command transcript creates no Voice run and sends nothing to Gormes.
- Failed capture creates failed Voice run state with safe recovery copy.
- Profile contact capability disables mic with explicit reason.

Later server-event slice should add reducer tests for planned voice events only after the Gormes channel emits at least one such event.

## Non-goals

- No binary audio upload in the first slice.
- No server TTS playback in the first slice.
- No provider config editing UI in the first slice.
- No Local command grammar refactor in the first slice.
- No Gormes channel protocol change in the first slice.

## Implementation Order

1. Add Voice run model and lifecycle tests in the Flutter app.
2. Move pending voice state out of `ChatScreen` into core channel/protocol state.
3. Preserve current transcript fallback through `start_turn`.
4. Add read-only Profile contact voice capability state.
5. Plan gateway event reducer only when a real server voice event exists.
6. Add binary audio transport only after lifecycle, retention/redaction, and server event contract are present.
