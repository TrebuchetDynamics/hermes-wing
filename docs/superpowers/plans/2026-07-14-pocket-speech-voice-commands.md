# Pocket Speech Voice-Command Bindings Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `set_tts_voice` / `set_speech_rate` voice commands affect Pocket Speech playback, closing deviation (a) of `docs/superpowers/specs/2026-07-13-needle-router-design.md` (design approved in-session 2026-07-14).

**Architecture:** Thread optional `{voice, speed}` through `PocketSpeechEngine.synthesizeWav`; give `PocketSpeechTextToSpeechService` the same optional `TtsSettingsReader` seam the flutter_tts service has; make `ttsVoiceNamesProvider` backend-aware (Kitten static catalog / Kokoro voices.json keys / flutter_tts device voices).

**Tech Stack:** existing `pocket_speech` git dep (Kitten: `KittenCatalog.voices` + `resolveVoice`; Kokoro: `synthesizeWav(text, {voice, speed})`, voices.json keyed by voice name), Riverpod 3.

## Global Constraints

- Branch `feat/pocket-speech-commands` from current `main`. Stage only named files; never bare `git add -A`; leave the user's pre-existing dirty files untouched.
- Augment-only: default settings (`speechRate 1.0`, `ttsVoiceName null`) ⇒ byte-identical synthesis calls to today. A bad/unsupported voice name must never break speech (fallback to the engine default, mirroring flutter_tts's try/catch rule).
- No transcript logging; `flutter analyze` clean + `dart format` before every commit; TDD red→green per task.

---

### Task 1: Engine + service seam

**Files:**
- Modify: `lib/features/voice/services/tts/pocket_speech_text_to_speech_service.dart`
- Modify: `lib/features/hermes_chat/screens/hermes_chat_screen.dart` (pocket construction call ~line 50: pass `settings: () => ref.read(wingVoiceSettingsProvider)`)
- Test: `test/features/voice/pocket_speech_voice_binding_test.dart` (new)

**Interfaces:**
- Consumes: `TtsSettingsReader` typedef (exported from `lib/features/voice/services/tts/text_to_speech_service.dart`); `WingVoiceSettings.speechRate/ttsVoiceName`; pocket_speech package APIs — READ the package sources in `~/.pub-cache/git/pocket-speech-dart-*/lib/src/{kitten_tts,kokoro_tts}.dart` for the EXACT `synthesizeWav` named params of both classes before writing code.
- Produces: `PocketSpeechEngine.synthesizeWav(String text, {String? voice, double speed = 1.0})`; `PackagePocketSpeechEngine` threads both to the package — Kitten: resolve via `KittenCatalog.supportsVoice`/`resolveVoice`, unsupported ⇒ omit (engine default); Kokoro: pass `voice` when non-null else package default, `speed` always. `PocketSpeechTextToSpeechService({required engine, required audioSink, TtsSettingsReader? settings})` applies per `speak`: `speed = settings.speechRate` (already clamped 0.25–3.0 upstream; clamp again harmlessly), `voice = settings.ttsVoiceName`. `createPocketSpeechTextToSpeechService` gains and threads the same optional param.

- [ ] **Step 1: Failing test** — fake `PocketSpeechEngine` recording `(text, voice, speed)` per call; cases: (a) no settings reader ⇒ `voice == null && speed == 1.0` (back-compat); (b) reader with `speechRate: 2.0, ttsVoiceName: 'Bella'` ⇒ recorded `('hi', 'Bella', 2.0)`; (c) reader present with defaults ⇒ `(null, 1.0)` (augment-only). Write complete test code against the new signature; run: FAIL (params don't exist).
- [ ] **Step 2: Implement** per Produces; update every `implements PocketSpeechEngine` in lib/ and test/ (grep) explicitly.
- [ ] **Step 3: Run** `flutter test test/features/voice && flutter analyze lib/features/voice lib/features/hermes_chat` → green/clean.
- [ ] **Step 4: Commit** `feat(voice-commands): pocket speech applies voice and rate settings` (staged: the 3 files + any fake-engine test files updated).

---

### Task 2: Backend-aware voice-name source

**Files:**
- Modify: `lib/features/voice_commands/providers/voice_command_providers.dart`
- Test: extend `test/features/voice_commands/voice_command_providers_test.dart`

**Interfaces:**
- Consumes: `wingVoiceSettingsProvider` (`pocketSpeechTtsEnabled`, `pocketSpeechModel`, `pocketSpeechVoicePack.voicesPath`); `KittenCatalog.voices` (import `package:pocket_speech/pocket_speech.dart`; verify the symbol is exported — if not, import the concrete src path is FORBIDDEN; instead hardcode the 8 names with a comment pinning them to the package version and a test asserting `KittenCatalog`-equality if reachable).
- Produces: `ttsVoiceNamesProvider` returns, in priority order: pocket enabled + kitten ⇒ Kitten catalog names; pocket enabled + kokoro ⇒ keys parsed from the pack's `voices.json` (read file, `jsonDecode`, top-level keys; missing/unreadable ⇒ `[]`, non-caching retry per the existing empty-retry rule); pocket disabled ⇒ current flutter_tts path unchanged. Provider watches the relevant settings selects so switching TTS backend invalidates the list.

- [ ] **Step 1: Failing tests** — (a) pocket+kitten settings override ⇒ names contain 'Bella'; (b) pocket+kokoro with a temp voices.json `{"af_heart": {}, "af_bella": {}}` ⇒ `['af_heart','af_bella']`; (c) pocket disabled ⇒ falls back to flutter_tts source (existing behavior test still green). Run: FAIL.
- [ ] **Step 2: Implement.** **Step 3: Run** voice_commands suite + analyze → green. **Step 4: Commit** `feat(voice-commands): voice-name source follows active tts backend`.

---

### Task 3: Docs, fixture note, full gate

**Files:**
- Modify: `docs/superpowers/specs/2026-07-13-needle-router-design.md` (deviations: replace limitation (a) with "Pocket Speech voice/rate supported as of 2026-07-14; flutter_tts and pocket backends both honor set_tts_voice/set_speech_rate; voice candidates follow the active backend")
- Test: extend `test/features/voice_commands/spike_bank_regression_test.dart` with ONE additional case comment only if behavior changed — it did not (fixture context is explicit), so instead add a second context variant test: transcript 15 ('change the voice to nova') validated against a Kitten-style context `voiceNames: ['Bella','Jasper']` ⇒ null (fallthrough), and 'change the voice to bella'-style raw call `set_tts_voice{voice: "bella"}` against the same context ⇒ snaps to 'Bella' (case-insensitive fuzzy).

- [ ] **Step 1:** fixture additions (red not applicable — locks existing validator behavior; must pass immediately or STOP and report).
- [ ] **Step 2:** docs edit. **Step 3:** FULL gate: `flutter test` (report count) + `flutter analyze` + `flutter build apk --release` builds. **Step 4: Commit** `docs(voice-commands): pocket speech bindings close deviation (a)`. **Step 5:** report; merge decision is the user's; on-device check of "change the voice to bella" under Kitten is a user-voiced step.
