# Needle Voice-Command Router — Design

**Date:** 2026-07-13
**Status:** Implemented and merged to main; on-device smoke PASSED 2026-07-14 (Galaxy S24 Ultra: instant navigate + snackbar, session-switch guardrail, ordinary sentences flow to Hermes — all three user-verified by voice)
**Precedes:** implementation plan (docs/superpowers/plans/)
**Builds on:** docs/superpowers/specs/2026-07-13-needle-spike-design.md and
docs/superpowers/specs/2026-07-13-needle-spike-findings.md (16/20 correct, 85% tool
accuracy, p50 662 ms wall on-device, CPU-only)

## Guiding constraint (unchanged, hard)

**Augment-only.** The router may only add a local shortcut; it can never block, alter,
or replace the Hermes path. Feature OFF ⇒ behavior identical to today. Every
non-executed path delivers the transcript exactly where it would have gone anyway.

## What it does

For opted-in users, each voice transcript is first offered to Needle (~660 ms, hard
1.5 s timeout). A whitelisted match executes locally — instantly for safe actions,
after a one-tap confirmation chip for state-changing ones. Everything else (no match,
invalid args, engine failure, timeout, declined chip) flows to Hermes as today.

## Decisions

| Decision | Choice |
|---|---|
| Trigger | Every voice transcript pre-screened (no separate mic, no wake word) |
| Confirmation | Tiered: instant + snackbar for reversible; confirmation chip for state-changing; decline/timeout ⇒ transcript goes to Hermes |
| Command surface | All ten spike tools bound to real actions (see table) |
| Rollout | Runtime opt-in Settings toggle "On-device voice commands (beta)", default OFF; engine .so ships in every APK (~+4 MB, CI-built); 16 MB model downloads on enable; NEEDLE_SPIKE dart-define retires to gating only the dev eval screen |
| Architecture | New `lib/features/voice_commands/` module + one injectable seam in `HermesVoiceInputController` |

## Architecture & data flow

`lib/features/voice_commands/` owns: engine lifecycle (promoted from the spike:
`NeedleEngine`, `NativeCallQueue`, `NeedleResult`), model install service (promoted),
the real tool catalog, arg validation/snapping, `VoiceCommandRouter`, and
`CommandDispatcher`. The spike feature keeps only the dev eval screen (still behind
`NEEDLE_SPIKE`), importing shared pieces from the new module.

Flow: STT transcript → `HermesVoiceInputController` tries its injectable, nullable
seam `Future<VoiceRouteResult?> Function(String)?` → `null` ⇒ existing draft/submit
path unchanged. A `VoiceRouteResult{command, args, tier}` goes to the UI layer:
instant tier dispatches immediately with a snackbar; confirm tier renders a chip
stating exactly what will happen; decline or chip timeout sends the transcript to
Hermes as a normal message. Latency cost exists only for opt-in users.

## Command surface & tiers

| Command | Action binding | Tier |
|---|---|---|
| `navigate_to_screen` | go_router | Instant |
| `show_status` | connection-state snackbar | Instant |
| `stop_voice_run` | stop continuous/capture | Instant |
| `toggle_continuous_mode` (off) | voice settings controller | Instant |
| `toggle_continuous_mode` (on) | voice settings controller | Confirm |
| `start_voice_run` | re-arm capture | Confirm |
| `new_session` | Hermes channel | Confirm |
| `switch_session` | fuzzy-match against real session titles | Confirm |
| `set_tts_voice` | snap to installed voice list | Confirm |
| `set_speech_rate` | clamp 0.25–3.0 | Confirm |

## Guardrails (mitigating the observed 15% wrong-tool rate)

Layered, all pre-execution:
1. Tool name must exist in the catalog — else fallthrough.
2. Args schema-validated and snapped: enums by normalized/fuzzy match
   (`"settings screen"` → `settings`), numbers parsed/clamped, unknown session or
   voice names ⇒ fallthrough or the chip shows the best candidate for confirmation.
3. Engine `confidence` is ignored by design (pinned at 1.0 in the spike).
4. Confirm tier absorbs residual wrong-tool risk; the chip text names the exact effect.
5. No transcript is ever silently dropped.

Privacy invariants carry over: no transcript logging/persistence; on-device only
(`auto_handoff: false`; `CACTUS_NO_CLOUD_TELE=1` before init).

## Shipping & lifecycle

- Engine `.so` in every APK: CI runs `scripts/spike/build_cactus_engine.sh`
  (symbol-export patch included); local gitignore stays, CI builds before assemble.
- Settings section: toggle (default OFF, shared_preferences-backed), Wi-Fi-aware model
  download with progress/retry, delete-model affordance.
- Engine loads lazily on first routed transcript; resident for the app session.
- Repeated engine/parse failures (3 per session) auto-suspend routing until restart
  and surface a settings hint.

## Error handling

Any engine/parse/validation failure ⇒ fallthrough to Hermes plus a transcript-free
debug breadcrumb. Timeout 1.5 s ⇒ fallthrough. Model missing/deleted ⇒ router returns
null until re-downloaded.

## Testing

- Unit: catalog schema, validator/snapping (table-driven per tool), dispatcher against
  fake services, router timeout/fallthrough/suspend.
- Widget: confirmation chip confirm/decline/timeout paths; settings toggle + download.
- Regression fixture: the spike's 20-transcript bank replayed through the full
  validation pipeline using recorded engine outputs (fake engine), asserting expected
  tool + snapped args.
- On-device: extended Maestro flow including a confirmation-chip scenario.

## Out of scope

Hybrid pre-routing, wake words, model fine-tuning for the three paraphrase failures
(follow-up), iOS/web/Linux engines, NPU acceleration.

## Implementation deviations

- **`VoiceCommandSettingsSink` interface:** the dispatcher depends on a small
  `VoiceCommandSettingsSink` interface rather than the concrete
  `NavivoxVoiceSettingsController` from Riverpod, decoupling command dispatch from the
  Riverpod controller type and keeping the dispatcher's unit tests free of a
  `ProviderContainer`.
- **Voice toggle-on side effect (user-intent deviation):** the voice command
  `toggle_continuous_mode(enabled: true)`, once confirmed via the chip, does not just
  flip the continuous-voice setting — it also starts hands-free listening
  (`enableContinuous()`) and enables spoken replies (`speakRepliesEnabled`), exactly
  mirroring the hands-free UI switch. Rationale: "turn on continuous mode" spoken
  aloud means "start listening now"; without speak-replies the loop would silently die
  after one exchange (maybeContinue pauses when replies aren't spoken)."
- **Consecutive-timeout suspension (pileup guard):** in addition to the 3
  engine-failure auto-suspend, the router also auto-suspends after repeated
  *consecutive* timeouts, even though timeouts alone don't count as failures under the
  original rule. This prevents a slow/thermal-throttled device from repeatedly eating
  the full 1.5 s timeout on every transcript indefinitely; suspension only trips when
  timeouts pile up back-to-back, not on an isolated slow response.
- **Toggle-off pauses the controller:** the voice command
  `toggle_continuous_mode(enabled: false)` doesn't just flip the setting — it also
  pauses the live `HermesVoiceInputController` continuous loop (mirroring
  `stop_voice_run`), so the hands-free switch never renders ON-but-disabled after a
  spoken "turn off".
- **`StateProvider` from the Riverpod legacy export:** one provider in
  `lib/features/voice_commands/providers/voice_command_providers.dart` uses
  `StateProvider` from Riverpod's legacy/back-compat export rather than a Riverpod 3
  `Notifier`, matching an existing pattern already used elsewhere in this codebase
  rather than introducing a second state-management idiom for one small piece of state.
- **'British'-style voice aliases are a known limitation:** the spike-bank regression
  fixture (transcript 16, "use the british voice for speech") locks in the current
  behavior where a descriptive/aliased voice reference does not resolve unless a
  candidate voice name literally contains the spoken words. Teaching the validator
  locale-aware aliasing (e.g. "british" → `en-GB-*`) is deferred; today it correctly
  falls through to Hermes rather than guessing.
- **Pocket Speech voice/rate supported as of 2026-07-14:** both TTS backends honor
  `set_tts_voice`/`set_speech_rate`; voice candidates follow the active backend
  (Kitten catalog names / Kokoro `voices.json` keys / device voices). Pocket speed is
  clamped to the package-safe 0.5–2.0 range (narrower than the app's 0.25–3.0).
- **Engine/parse failures are fully silent by design:** the fallthrough path for
  engine and parse failures does not emit the transcript-free debug breadcrumb
  described above under "Error handling." In practice, logging even a
  transcript-free breadcrumb on every failed parse (which includes ordinary
  non-command speech that simply isn't a voice command) proved noisier than useful;
  staying silent here is safer than over-logging. Timeout and consecutive-timeout
  suspension still behave as specified.
- **Model download is not Wi-Fi-gated:** the spec's "Wi-Fi-aware" download guidance
  is not implemented — the Needle model download (~16 MB) runs regardless of
  connection type. Given the small size and low stakes of an unwanted cellular
  download, gating on Wi-Fi was judged not worth the added settings surface and
  connectivity-detection code for this alpha.
