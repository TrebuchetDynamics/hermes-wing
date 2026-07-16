# Needle On-Device Tool-Calling Spike — Design

**Date:** 2026-07-13
**Status:** Approved (spike; findings decide whether a real integration design follows)
**Branch:** `spike/needle` — originally never-merge; superseded 2026-07-13 by user decision
to merge the completed, gated implementation into `main` (merge `3d4152d`) ahead of the
Task 9 device evaluation. The spike remains fully dart-define-gated in default builds.

## Background

[Needle](https://huggingface.co/Cactus-Compute/needle) is a 26M-parameter, MIT-licensed
function-calling model from Cactus Compute (Simple Attention Network: encoder-decoder,
attention-only, INT4 QAT). It does one thing: map natural-language requests to structured
tool calls. It runs on the Cactus engine (v2.x), which has a Flutter binding.

Hermes Wing is remote-only for intelligence today: OS STT transcript → Hermes endpoint (SSE).
The app already runs on-device ONNX inference for TTS (`pocket_speech`), with an
established model-download pattern (SHA-256 verification, size caps, atomic replace).

## Guiding constraint (hard scope boundary)

**Needle augments Hermes; it never replaces it.** All candidate roles keep the Hermes
endpoint as the source of intelligence. Needle may only short-circuit or pre-route
simple, local, structured commands. Any design derived from this spike that removes or
degrades the Hermes path is out of scope.

## Goal & questions to answer

A time-boxed, rip-out-able experiment answering, in order:

1. **Does it run?** Needle loads and infers inside Hermes Wing on Android (alpha target) via
   the Cactus Flutter binding, coexisting with `flutter_onnxruntime` (pocket_speech TTS).
2. **Is it accurate?** Fraction of realistic voice commands mapped to the right tool with
   the right arguments, against ~10 mock Hermes Wing tools and a 20-transcript test bank.
3. **Is it fast/small enough?** End-to-end latency (transcript → tool call), APK size
   delta, model download size.
4. **Verdict:** recommend one integration role — local command router, hybrid pre-router,
   offline fallback — or "not yet, revisit when X".

## Decisions made during brainstorming

| Decision | Choice |
|---|---|
| Role of Needle | Exploratory spike first; role decided by findings |
| Where the spike lives | In-repo behind a debug flag (proves onnxruntime coexistence) |
| Spike depth | Debug screen + mic button (reuses existing `VoiceCaptureService` via `createDefaultVoiceCaptureService`; does NOT touch the Hermes voice-run path) |
| Runtime path | Vendored FFI binding file (`lib/features/needle_spike/ffi/cactus.dart`, sourced from `cactus-compute/cactus@49e12567`) plus a locally built, gitignored `libcactus_engine.so` produced by `scripts/spike/build_cactus_engine.sh` (no pub package exists for the v2 engine, so a git dependency in `pubspec.yaml` was not viable) |
| Relationship to Hermes | Augment only — never replace (user directive) |

## Architecture

- **Dependency:** vendored FFI binding file (`lib/features/needle_spike/ffi/cactus.dart`,
  sourced from `cactus-compute/cactus@49e12567`) plus a locally built, gitignored
  `libcactus_engine.so` produced by `scripts/spike/build_cactus_engine.sh`. No pub package
  exists for the v2 engine, so this replaces the `pocket_speech`-style git dependency
  originally proposed.
- **Gating:** all spike code lives under `lib/features/needle_spike/`; the debug route is
  registered only when built with `--dart-define=NEEDLE_SPIKE=true`. Builds without the
  flag ship no reachable spike UI. (The native Cactus lib lands in the APK once the
  dependency exists — measuring that delta is part of the spike.)
- **Isolation:** no imports from `needle_spike` into any other feature. The spike imports
  shared services (`VoiceCaptureService` via `createDefaultVoiceCaptureService`, download
  plumbing) but nothing imports it.

## Components

### `NeedleToolCatalog`
~10 hardcoded `CactusTool` definitions mirroring plausible Hermes Wing actions:
`navigate_to_screen`, `start_voice_run`, `stop_voice_run`, `toggle_continuous_mode`,
`send_message`, `new_session`, `switch_session`, `set_tts_voice`, `set_speech_rate`,
`show_status`. Handlers are mocks — they return a canned "would have executed X(args)"
string and never touch real app state.

### `NeedleSpikeService`
Wraps model download (reusing the SHA-256-verified pattern from
`pocket_speech_asset_download_service_io.dart`), engine init, and
`parseTranscript(String) → NeedleResult { toolCall?, latencyMs, raw }`.
Exposed via a Riverpod provider, consistent with existing feature wiring.

### `NeedleSpikeScreen`
Hidden debug screen containing:
- free-text input field;
- a bank of ~20 canned test transcripts (one tap to run);
- a mic button that reuses the existing `VoiceCaptureService` via
  `createDefaultVoiceCaptureService` (a wrapper over `SpeechRecognizer`) directly —
  not `HermesVoiceInputController`, not the voice-run submission path;
- result panel: parsed tool call, arguments, latency;
- manual scorecard: correct / wrong tool / wrong args / no call (counts only).

## Data flow

Mic or typed text → transcript string → `NeedleSpikeService.parseTranscript` → Needle
inference (fully on-device) → displayed result + manually judged scorecard tick.
Nothing reaches the Hermes endpoint. No network traffic after the one-time model download.

## Error handling & security

- Model fails to download/load or binding is incompatible → screen shows the error
  verbatim; that outcome is itself finding #1.
- Per repo security policy: transcripts are displayed but **never logged or persisted**;
  the scorecard stores only counts, never utterances.
- Download failures follow the pocket_speech pattern: temp-file atomic replace, size cap,
  checksum verification.
- The native engine's default cloud telemetry is disabled via its env-var kill switch
  before `cactus_init`; the evaluation must confirm no network traffic post-download.

## Testing

- Unit tests for `NeedleToolCatalog` (schema validity) and `NeedleSpikeService` result
  parsing (with the engine faked), mirroring existing controller test style.
- The accuracy evaluation itself is manual via the debug screen scorecard — the spike's
  product is the findings doc, not shippable code.

## Exit criteria & deliverable

The spike ends with `docs/superpowers/specs/2026-MM-DD-needle-spike-findings.md`
recording:

- load success/failure (with binding version details);
- accuracy on the 20-transcript bank (per-category: correct / wrong tool / wrong args /
  no call);
- p50/p95 latency on the test device;
- APK size delta and model download size;
- flutter_onnxruntime coexistence notes (build conflicts, runtime issues, memory);
- go/no-go recommendation per integration role, honoring the augment-only constraint.

## Pros & cons of Needle for Hermes Wing (known pre-spike)

**Pros**
- MIT license, open weights.
- Tiny: ~20–30 MB on disk vs the 500 MB Kokoro TTS model the app already manages.
- Very fast claimed inference (~6,000 tok/s prefill / ~1,200 decode on Cactus runtime).
- Exactly matches Hermes Wing's "voice command → structured action" shape.
- Fits the app's existing hybrid on-device/remote philosophy and download plumbing.
- Cactus Flutter SDK also offers on-device Whisper STT — possible future bonus.

**Cons / risks**
- Function-calling only — can never carry conversation (acceptable: augment-only).
- Brand-new model + v2 engine; Flutter binding maturity unproven (biggest risk; the
  spike's primary question).
- Adds a second native inference runtime beside onnxruntime (APK size, build complexity).
- pub.dev package lags the engine; git dependency required for now.
- NPU acceleration is gated behind a paid Pro key (CPU-only for the spike).
- 26M params: argument extraction on messy real speech may be brittle.
- Unclear story for Hermes Wing's secondary targets (web, Linux, iOS).
