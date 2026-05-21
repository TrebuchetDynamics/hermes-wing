# Navivox Context

Navivox is the operator-facing Flutter app for talking to trusted local or self-hosted Gormes profiles. This context keeps product language stable while architecture work deepens modules around the connect-and-talk loop.

## Language

**Navivox**:
The Flutter operator app that connects to a Gormes gateway and presents profile chat, voice input, tool activity, and safe config flows.
_Avoid_: generic chat client, server admin panel

**Gormes gateway**:
The server-side Navivox endpoint that owns agents, sessions, tools, config, secrets, provider execution, and the HTTP/WebSocket event stream.
_Avoid_: backend, remote shell

**Profile contact**:
A flat chat-list identity made from one `server_id` plus one `profile_id`.
_Avoid_: agent, user account, thread

**Transcript surface**:
The chat area that shows user turns, assistant turns, tool activity, safety notices, approval prompts, voice transcript bubbles, the composer, and message action sheets for the active **Profile contact**.
_Avoid_: generic message list, log viewer, terminal output

**Command word**:
The local prefix, default `navi`, that marks a message or utterance as a Navivox command.
_Avoid_: wake word, hotword

**Local command**:
A typed message or voice utterance that starts with the command word and is handled by Navivox without being sent as a Gormes turn.
_Avoid_: chat message, server command, tool call

**Operator intent**:
A local Navivox UI action emitted by the **Transcript surface**, such as send text, submit voice transcript, forward message, or inspect tool activity. The app shell or screen decides how that intent affects routing, the active **Profile contact**, or the **Gormes gateway**.
_Avoid_: callback, command, server event

**Voice run**:
One end-to-end Navivox voice interaction, from capture through transcript, optional server STT, agent turn, optional server TTS, playback, cancellation, errors, and retention policy.
_Avoid_: audio blob, transcript string, voice message

## Relationships

- **Navivox** connects to one or more **Gormes gateways**.
- A **Gormes gateway** reports zero or more **Profile contacts**.
- A **Profile contact** is the target for chat turns and voice turns.
- The **Transcript surface** renders the active **Profile contact** conversation, keeps tool activity distinct from ordinary assistant text, and owns composer/action-sheet behavior.
- A **Local command** uses the **Command word** and produces a local intent for Navivox to execute.
- The **Transcript surface** emits **Operator intents** upward instead of owning Gormes gateway calls or route changes.
- A **Voice run** is product state, not just a transcript string; it may produce a Gormes turn and later playback state.
- A **Local command** may switch the active **Profile contact**, cancel or stop work, open settings, or show help.
- A **Local command** is not a Gormes turn and must not be forwarded to the **Gormes gateway** as chat text.

## Example dialogue

> **Dev:** "If the operator types `navi mineru`, should the Gormes gateway receive that as chat text?"
> **Domain expert:** "No. That is a **Local command**. Navivox should parse it locally, switch to the matching **Profile contact**, and send nothing to the gateway."

## Flagged ambiguities

- "profile", "agent", and "contact" can drift together. Resolved: use **Profile contact** for the `server_id + profile_id` chat-list identity; use agent only for server-owned runtime behavior.
- "wake word" can imply always-listening audio. Resolved: use **Command word** for the local prefix active only in Navivox text or voice command mode.
- "message list" can imply a passive log. Resolved: use **Transcript surface** for the active chat UI area because it renders tool activity, safety notices, approval prompts, and voice transcript bubbles as product state.
- "voice message" can imply a single rendered bubble. Resolved: use **Voice run** for the full lifecycle and reserve voice bubble wording for Transcript surface rendering.
