# GOAL STATE — 2026-06-17

## Status

The goal **"improve the Navivox client/server channel for chat and live voice
to many profiles, add e2e tests, and prove continuous TTS+STT works"** is
**complete**. It was delivered as three validated slices, all merged to `main`.

## Verified gate (2026-06-17)

- `flutter analyze` — no issues.
- `flutter test --concurrency=1` — **917 tests pass** (includes the regression
  tests added by the slices below).

These are the authoritative, reproducible signals for the app today. The
Playwright e2e/screenshot suites under `playwright/tests/` still exist but were
not re-run for this update; rerun them against a web build when a visual
coverage refresh is needed.

## Delivered slices

1. **Per-profile gateway sessions** (`main` commit `7a65fe3`, merge `e8ad614`).
   Gateway sessions are tracked per profile contact instead of a single global
   `_activeSessionId`, so turn control and turn submission target the right
   in-flight session when several profiles are live at once. `session_started`
   resolves its profile scope via the existing message-scope policy; chat turns
   and turn control use the active profile's session; voice runs resolve
   profile, session, and routing from the run itself.
   - Evidence: `lib/core/channel/gateway/runtime/gateway_navivox_channel.dart`
     (`_sessionIdsByProfileKey`), `gateway_event_reducer.dart`
     (`UpdateGatewayActiveSession.profileContactKey`),
     `navivox_channel_state.dart` (`profileRoutingSelectionFor`).
   - Tests: `test/core/channel/gateway/runtime/channel_test.dart` (turn control
     and voice submission across multiple in-flight profiles).

2. **Full-app e2e proof of continuous voice STT + read-aloud TTS**
   (commit `f657df5`, merge `af54f59`). `ConnectAndTalkChannel` is now
   voice-capable; a router-driven e2e connects from setup, trusts the gateway,
   captures a spoken turn via the mic, auto-sends it, and reads the assistant
   reply aloud through the message-actions sheet.
   - Evidence: `test/e2e/voice_continuous_web_e2e_test.dart`,
     `lib/testing/connect_and_talk_channel.dart`.

3. **Opt-in hands-free continuous voice** (commit `ed7e073`, merge `af54f59`).
   When continuous voice is active and the new **Speak replies aloud** local
   setting is on, a freshly completed assistant reply is spoken aloud and the
   next capture re-arms automatically; starting any capture barges in and stops
   playback. Default off, so the app never speaks or re-listens without explicit
   operator consent.
   - Evidence: `NavivoxVoiceSettings.speakRepliesEnabled` +
     `setSpeakRepliesEnabled`; pure
     `lib/features/chat/voice/controllers/continuous_voice_reply_policy.dart`;
     chat-screen auto-speak + re-arm `ValueNotifier` threaded through the
     transcript surface to `TranscriptInputPanel`; Settings toggle.
   - Tests: `continuous_voice_reply_policy_test.dart`,
     `test/features/voice/modes/continuous_voice_hands_free_test.dart`,
     `settings_screen_test.dart`.

## Acceptance audit

Every explicit requirement maps to merged code plus a green gate:
many-profile connection correctness, added e2e tests, proof of the existing
STT + read-aloud TTS round-trip, and a built-and-proven hands-free continuous
TTS+STT loop. Known scope limit: the hands-free loop is proven at the widget
level through the real input-panel re-arm plumbing, not via a router-level e2e
(a repeating capture service would loop indefinitely there).

## Remaining open work

Tracked in `TODO.md`. The live `[PLANNED]` / `[BLOCKED]` items remain **not
actionable from the app side alone** — they wait on external dependencies:

- **Durable connection credential storage** — needs the Gormes gateway to
  advertise the device-credential issuance/rotation/revoke protocol.
- **Approval response protocol** — needs Gormes to advertise a stable
  approve/deny action or endpoint.
- **Composer attachment upload / media picker** — needs Gormes to advertise
  `/v1/navivox/uploads` with opaque upload IDs and a MIME allowlist.
- **Android pairing-handoff + continuous-voice live smoke** — needs a
  responsive physical/emulated Android target on the test host.

The next goal should be framed around whichever external dependency above lands
first, at which point the corresponding `TODO.md` item becomes actionable.
