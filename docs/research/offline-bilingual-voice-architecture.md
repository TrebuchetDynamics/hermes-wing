# Offline bilingual mobile voice architecture (Android/Flutter)

Status: archived, not adopted
Scope: historical offline STT/TTS and full-duplex research

> Hermes Wing no longer ships or loads app-owned voice models. Current voice
> input uses device speech recognition, and speech output is available only
> through Agent synthesis when advertised. The design below is retained only as
> historical research.

Boundary considered by this research: **Wing owns audio; Hermes Agent receives completed text only**

## Recommendation in one page

Build an app-owned, full-duplex audio subsystem below Flutter rather than extending the current platform-recognizer loop into an audio pipeline. Keep the existing fail-closed recognizer generations and lifecycle as the control-plane contract, but put capture, playback, audio processing, VAD, streaming STT, endpointing, and local TTS in one Android native engine. Flutter receives typed state/transcript events; Hermes Agent receives only a final text turn.

Use this order:

1. **Baseline/probe phase:** retain Android on-device `SpeechRecognizer` and current TTS, add capability/provenance reporting and physical-device acoustic benchmarks. This is a compatibility baseline, not proof of a named model or reliable offline code-switching. Android explicitly warns that the ordinary recognizer may stream audio to remote servers, while also exposing separate APIs to test/create an on-device recognizer and request model downloads.[30]
2. **Owned offline STT phase:** integrate a C++/ONNX streaming recognizer behind Dart FFI. `sherpa-onnx` is the most practical first integration candidate because it documents local processing, Android and Flutter support, streaming transducers, VAD, and TTS in one runtime.[20] Prefer a **joint bilingual streaming transducer** for the selected pair; the project already publishes at least one Chinese-English streaming Zipformer transducer, demonstrating the packaging/interface pattern.[21]
3. **Full-duplex phase:** Wing captures continuously while it renders TTS, processes the microphone through hardware AEC when trustworthy or WebRTC APM when Wing owns the render reference, then runs VAD and streaming ASR. WebRTC APM contains AEC, NS, and AGC and is designed to process near-end and reverse/render streams frame by frame near the audio HAL.[18][19]
4. **Owned TTS/model-pack phase:** move primary TTS to chunked local synthesis so Wing owns the exact output PCM, can cancel generation/playback immediately, and can feed the far-end signal to software AEC. `sherpa-onnx` lists bilingual/multilingual VITS and Kokoro models, and its native TTS callback can emit PCM incrementally and stop generation when the callback returns zero.[23][26]

Do not relay raw audio to Hermes by default. Do not call a platform plugin a model. Report wrapper, selected OS service, and actual app-owned model separately.

## Concrete 2026 candidate decision

No reviewed upstream source demonstrates genuine intra-utterance English↔Spanish code-switching. Automatic language identification, choosing a monolingual model between utterances, and preserving two languages inside one utterance are separate capabilities. Wing must not advertise code-switching until a physical-device mixed-language corpus passes.[1][8][9]

### STT shipping baseline

Use multilingual Whisper through `whisper.cpp` as the first owned offline recognizer:

| Tier        |                           Model | Approximate model file | Role                            |
| ----------- | ------------------------------: | ---------------------: | ------------------------------- |
| Compact     |  Whisper Tiny Q5_1 multilingual |                32.2 MB | Low-memory fallback             |
| Recommended |  Whisper Base Q5_1 multilingual |                59.7 MB | First shipping/benchmark target |
| Quality     | Whisper Small Q5_1 multilingual |               190.1 MB | Optional higher-accuracy pack   |

The published quantized model files establish these approximate download sizes.[35][52] Keep one multilingual model loaded with automatic language selection; never route a live utterance between `.en` and Spanish-only models. Whisper partials are rolling re-decodes rather than true cached streaming, so use VAD, a short rolling window, stable-prefix commitment, and a final endpoint decode. Trigger barge-in from post-AEC VAD before waiting for transcript text. `sherpa-onnx` remains the preferred integration/runtime framework if its Whisper path meets the same benchmarks, and the preferred long-term home for a true EN/ES streaming transducer. Its published catalog does not currently provide a stock joint Spanish-English Zipformer.[5][20][21]

Vosk is suitable only for explicit monolingual/profile mode: its small English and Spanish models are separate.[6][7] Moonshine's Spanish checkpoint is non-streaming and non-commercially licensed; SenseVoice lacks Spanish; Parakeet-TDT 0.6B v3 is approximately 714 MB even at Q8 and lacks mature Android/Flutter integration.[8][9][10] None is a better default today.

### TTS packs

| Tier                 |                                  Model |            Approximate assets | Role                                               |
| -------------------- | -------------------------------------: | ----------------------------: | -------------------------------------------------- |
| Quality bilingual    | Supertonic 3 via sherpa-onnx callbacks |                        398 MB | Same voice style across EN/ES; optional large pack |
| Compact bilingual    |                       Quantized Kokoro | 80–92 MB plus selected voices | Preferred storage/quality compromise               |
| Compact English      |                 Kitten micro/nano FP32 |                      41/56 MB | English-only pack                                  |
| Experimental minimum |                       Kitten Nano INT8 |                         25 MB | English-only; upstream reports reliability issues  |
| Compatibility        |                           Platform TTS |              Device-dependent | Zero-download fallback                             |

Supertonic 3 is the best natural bilingual experiment, not an automatic default: its weights are OpenRAIL-M, its public ONNX graph set is about 398 MB, Android RAM and time-to-first-audio are not published, and official open-source support is ending.[37][38][48] Use sherpa-onnx's incremental PCM callback and cancellation interface rather than whole-WAV synthesis.[47] Quantized Kokoro is the more plausible default download if Pocket Speech validates its graph contract and Spanish frontend; its Spanish quality and same-conversation voice consistency still require listening tests.[36][42][43] Piper remains a low-end option only if GPL-3.0 product policy and per-voice licenses are acceptable.[40][44]

## Target component boundary

```text
Android microphone
  -> AudioRecord/Oboe capture
  -> AEC + NS (+ conservative AGC)
       ^ reverse/render PCM from Wing-owned TTS playback
  -> mono/resample/model framing
  -> VAD + pre-roll ring
  -> streaming bilingual ASR
  -> endpoint policy
  -> partial/final text events
  -> Flutter voice state machine
  -> final reviewed text only
  -> Hermes Agent text API

Hermes reply text
  -> sentence/chunk planner
  -> local streaming TTS
  -> Wing PCM queue / AudioTrack or Oboe
  -> speaker
       \-> exact render reference to software AEC
```

### Ownership rules

- The Android/native engine owns the microphone and speaker streams, audio session IDs, DSP state, model instances, PCM rings, and native worker threads.
- Dart owns conversation/session generations, consent, visible states, transcript review, Hermes requests, and cancellation policy.
- Every native callback carries immutable `voiceSessionId`, `captureGeneration`, and (for playback) `speechGeneration`. Dart rejects stale events exactly as it does today.
- The offline path sends text only. A separate capability-gated Hermes audio path
  may upload bounded WAV audio only when the connected Agent advertises the exact
  audio endpoint; supported Agent 0.20 currently advertises `audio_api: false`,
  so this is implemented client plumbing rather than qualified runtime evidence.
- The real-time audio callback only timestamps/copies bounded PCM into lock-free/single-producer rings. Resampling, ONNX inference, JSON, allocation, logging, disk, and Dart method-channel work happen off that callback.

## Capture and audio processing

### Android path

Start with `AudioRecord` using `MediaRecorder.AudioSource.VOICE_COMMUNICATION`, which Android defines as tuned for VoIP/voice communications. Also probe `VOICE_RECOGNITION`; use `UNPROCESSED` only for a controlled software-APM path because Android says it falls back to `DEFAULT` when raw capture is unavailable.[14]

At runtime record a non-sensitive capability record:

- source requested and source actually opened;
- sample rate/channel/format and frames per burst;
- hardware AEC/NS/AGC availability and enabled state;
- route (`speaker`, wired, USB, Bluetooth SCO) and route changes;
- underrun/overrun counts and processing latency;
- engine/model IDs and quantization, but no words or PCM.

Android's AEC, NS, and AGC effects attach to an `AudioRecord` by audio-session ID; each has an `isAvailable()` probe, and Android notes an effect may already be inserted by the platform based on the selected audio source.[15][16][17] Therefore:

- probe and inspect before enabling;
- never assume availability means quality;
- do not stack platform AEC and WebRTC AEC by default;
- keep per-device/route benchmark results, because OEM behavior differs;
- on route change, stop at a generation barrier, rebuild both capture/render streams and DSP, then re-arm.

Use 48 kHz at the hardware boundary when it matches the device fast path, then resample once to the model rate (commonly 16 kHz) after APM. Android cautions that capture and playback callbacks/clocks are not guaranteed to be synchronized even at the same nominal sample rate, so the software-AEC path needs bounded drift compensation rather than assuming sample-perfect clocks.[33]

Oboe/AAudio is optional initially. It is useful when measured callback latency or glitches justify native duplex I/O, but the Android low-latency guidance is aimed partly at games and its `exclusive` recommendation is not universally compatible with communications routing. Benchmark `AudioRecord`/`AudioTrack` first; adopt Oboe by evidence, not fashion.

### AEC/NS/AGC policy

**Phase 1:** prefer the Android communication capture path plus available platform AEC/NS. It is the only practical option while platform TTS owns the speaker PCM.

**Phase 2:** when Wing owns TTS PCM, evaluate WebRTC APM as a deterministic software path. Feed rendered PCM to `ProcessReverseStream()` before/alongside the corresponding near-end frames to `ProcessStream()` and place APM as close to hardware as practical, as the WebRTC interface directs.[19]

Suggested order:

```text
render PCM -> reverse-stream AEC reference
mic PCM -> AEC -> NS -> conservative gain control -> VAD -> ASR
```

AGC is optional: aggressive gain can amplify stationary noise and destabilize VAD. Begin disabled or conservative, measure clipping/noise-floor effects, and enable per route only when it improves recognition. AEC quality is the gating dependency for barge-in: transcript fingerprint suppression remains a last-line heuristic, not acoustic echo cancellation evidence.

## VAD, barge-in, and endpointing

Run VAD **after** echo/noise processing. Keep a 200–300 ms pre-roll ring so a start decision does not clip initial phonemes. `sherpa-onnx` exposes Silero and TEN VAD integrations.[22] Silero's own project describes an approximately 2 MB model, 8/16 kHz support, and sub-millisecond processing for a 30+ ms chunk on one CPU thread (desktop-class claim; verify on target phones).[34]

Initial tunables, to be benchmarked rather than treated as constants:

- input frames: 10 or 20 ms into APM; aggregate to the VAD/model-required chunk;
- speech start: 100–200 ms of confident activity, with pre-roll;
- ordinary endpoint: 500–800 ms trailing non-speech after established speech;
- short-command endpoint: 300–500 ms only when ASR is stable and confidence is adequate;
- minimum accepted speech: about 150–250 ms, except explicitly supported one-word commands;
- maximum utterance: 20–30 s, then finalize/prompt rather than grow memory indefinitely;
- partial publication: at most every 50–100 ms and only when text changes.

Use separate decisions:

1. **Acoustic speech start** opens/continues the ASR segment.
2. **Interruption decision** stops TTS quickly when post-AEC VAD plus non-echo ASR evidence indicates near-end speech.
3. **Endpoint decision** finalizes only after trailing-silence, maximum-duration, explicit stop, or model endpoint rules.
4. **Submission decision** sends only a nonblank final transcript after native teardown ownership is established.

During TTS, use a stricter two-stage barge-in trigger: post-AEC VAD starts a candidate, then a meaningful ASR partial (including short exact words) stops playback. Stop/invalidate TTS synchronously before awaiting engine cleanup. Continue capture through the stop so the interruption is not clipped. If the evidence remains echo/noise and no valid partial appears, discard the candidate and continue playback.

The streaming recognizer interface should expose `acceptWaveform`, `inputFinished`, `isReady`, `decode`, `getResult`, `isEndpoint`, and `reset`. Those operations directly match sherpa-onnx's native `OnlineStream`/`OnlineRecognizer` APIs.[24][25] Keep endpoint policy in Wing even if the model provides `isEndpoint`, so product limits, VAD, explicit stop, and fail-closed lifecycle remain one auditable state machine.

## Bilingual language ID and code-switching

### Preferred strategy: joint bilingual model

Use one model/tokenizer trained for the exact language pair and code-switch domain. This avoids an utterance-level language classifier making the wrong irreversible choice halfway through a sentence. A model pack declares:

- BCP-47 language pair and supported scripts;
- whether within-utterance code-switching was in training/evaluation data;
- tokenizer/normalization rules;
- expected output script and punctuation;
- ASR architecture, model revision, quantization, and license;
- pair-specific quality benchmark results.

Do not infer code-switch support merely because a model is multilingual. Evaluate mixed-language error rate and switch-boundary errors explicitly.

### If no suitable joint streaming model exists

Use a tiered policy:

1. retain 1–2 s of normalized post-AEC audio in RAM;
2. run a small LID classifier after enough speech, with hysteresis and an `unknown` state;
3. start the most likely monolingual streaming recognizer and replay retained audio;
4. permit at most one switch before finalization unless benchmarks prove more is stable;
5. optionally re-score the completed utterance with an offline multilingual model on high-tier devices.

Running two recognizers in parallel is a high-end fallback because it roughly doubles decoder work and complicates score calibration. Whisper can identify language and is multilingual, but its standard sequence-to-sequence inference is not the preferred low-latency streaming interface.[3] `whisper.cpp` supports Android, quantization, CPU inference, and Vulkan, but its documented microphone stream is explicitly a naive repeated-transcription example; treat it as an offline re-scorer or benchmark challenger unless a true incremental integration meets latency/power targets.[1]

Android 14-era recognizer intents expose language detection and language switching controls, including an allowed-language list.[31] These are provider capabilities, not proof of a bundled model, code-switch accuracy, or offline execution. They are useful only in the platform compatibility phase after `checkRecognitionSupport()` and on-device availability checks.

## Local TTS

The primary barge-in-capable backend should provide:

- chunked PCM callback with sample rate;
- time-to-first-audio metric;
- synchronous cancellation token/generation invalidation;
- bounded `stop()`/dispose;
- deterministic voice/model identity;
- language/voice coverage declared by the pack;
- no network access.

Synthesize sentence-sized chunks (not an entire long answer), keeping only a small PCM queue. Begin the next sentence ahead of playback but cap look-ahead memory. On barge-in, invalidate generation, stop synthesis through its native callback, flush the output queue, stop the track, and continue mic capture. The sherpa-onnx TTS callback contract supports incremental samples and cancellation, and its catalog includes bilingual Chinese-English VITS and multilingual Kokoro examples.[23][26]

Keep platform TTS as a separately labeled fallback. It can be locally installed yet still has OEM-dependent voice provenance and generally does not give Wing a clean render PCM reference. Consequently, full-duplex software AEC is not claimed on that path.

## Native/Flutter model interface

Prefer one native library and a narrow FFI API over pushing 10 ms PCM messages through Flutter platform channels.

```text
voice_engine_create(config, modelPaths) -> handle
voice_engine_start_capture(handle, sessionId, captureGeneration)
voice_engine_start_tts(handle, speechGeneration, utf8Text, voiceId)
voice_engine_cancel_tts(handle, speechGeneration)
voice_engine_stop_capture(handle, captureGeneration)
voice_engine_poll_event(handle) -> typed event
voice_engine_destroy(handle)
```

Typed events:

- `captureReady`, `speechStart`, `speechEnd`;
- `partial(text, stablePrefix, language, timings)`;
- `final(text, languageSegments, timings)`;
- `endpoint(reason)`;
- `ttsStarted`, `ttsProgress`, `ttsStopped`, `ttsCompleted`;
- `routeChanged`, `overrun`, `recoverableError`, `terminal`.

All events are tagged with immutable IDs. Native teardown emits `terminal` only after callbacks and audio ownership for that generation are closed. A replacement capture waits for that terminal barrier. This preserves Wing's existing fail-closed semantics while removing process-global platform recognizer ambiguity from the owned path.

Use one high-priority audio thread and separate bounded workers for APM/feature extraction, ASR, and TTS. Warm model sessions before first listening where memory allows. Limit ONNX inter/intra-op threads based on measured core count and thermals; more threads are not automatically faster on mobile.

## Hardware acceleration

Baseline every pack on CPU with int8/quantized models and ARM NEON/XNNPACK-style kernels. Add accelerators only behind a per-model, per-device benchmark gate:

- ONNX Runtime Mobile provides an Android runtime; its NNAPI execution provider can target CPU/GPU/NPU on Android 8.1+, with Android 9+ recommended by ONNX Runtime.[28]
- Android has deprecated NNAPI in Android 15 and recommends alternatives such as the LiteRT GPU runtime for performance-critical workloads.[27] Therefore NNAPI must not be the architectural dependency.
- `whisper.cpp` advertises quantization, CPU-only inference, Android, and Vulkan support.[1] Vulkan remains an opt-in challenger because driver startup, unsupported operations, memory copies, and thermal behavior can erase gains.

At install/first run, run a short non-speech model microbenchmark (no microphone data), cache the selected execution provider keyed by device build + app/model version, and fall back to CPU on crash, unsupported op, timeout, or slower result. Never download executable accelerator code in a model pack.

## Downloadable model packs

Ship a tiny/no-model app plus an optional minimal language-pair pack, depending on store constraints. A pack manifest should contain:

```json
{
  "schema": 1,
  "packId": "asr-<pair>-<revision>-int8",
  "engineAbi": "wing-voice-v1",
  "kind": "asr|vad|tts|lid",
  "languages": ["<BCP-47>", "<BCP-47>"],
  "codeSwitch": "trained|unsupported|unknown",
  "files": [{ "path": "model.onnx", "bytes": 0, "sha256": "..." }],
  "modelRevision": "immutable upstream revision",
  "quantization": "int8|fp16|fp32",
  "license": { "spdx": "...", "noticePath": "NOTICE" },
  "minimumRamMb": 0,
  "recommendedTier": "low|mid|high"
}
```

Download transactionally to app-private storage: explicit user choice and size disclosure; HTTPS; bounded size/free-space checks; temporary directory; verify a signed manifest plus every SHA-256; reject path traversal/symlinks/executables; fsync/atomic rename; load/warm/health-check; then activate. Retain one known-good pack for rollback and use a lock/refcount so active sessions cannot observe deletion.

For Play-distributed builds, Play Asset Delivery offers install-time, fast-follow, and on-demand asset packs and restricts them to assets rather than executable code.[29] Use PAD only when its Play dependency is acceptable; retain the signed HTTPS pack route for F-Droid/direct distribution. Store private model state in app-internal storage, which Android documents as app-sandboxed and removed on uninstall.[32]

## Privacy and network policy

- Raw and processed PCM live only in bounded RAM rings by default and are zeroed/released on stop where practical.
- No PCM, VAD features, embeddings, or transcript partials go to Hermes Agent. Send only the user-approved/final text turn.
- No raw words in logs, crash breadcrumbs, benchmark receipts, filenames, analytics, or diagnostics. Record durations, state names, confidence bins, model IDs, and error codes only.
- Debug audio capture is a separate developer-only build capability with explicit per-run consent, a visible indicator, short retention, app-private storage, and a delete action; it is off in release builds.
- Model downloading is separated from inference. Offline voice must continue with networking disabled after packs are installed.
- Declare microphone use clearly, request only `RECORD_AUDIO`, and stop capture on background/permission/route uncertainty unless a separately designed foreground-service mode has explicit user value and disclosure.
- Treat model files and manifests as untrusted input: bounds-check parsers, pin engine ABI, verify signatures/hashes, and surface licenses.

## Fallback matrix

| Failure                                                 | Default action                                              | Optional user choice                                         |
| ------------------------------------------------------- | ----------------------------------------------------------- | ------------------------------------------------------------ |
| Joint bilingual pack absent                             | Offer download; keep text input                             | Explicit platform on-device recognizer if verified available |
| Pack corrupt/incompatible                               | Roll back to last-known-good; disable owned engine          | Re-download over approved network                            |
| Accelerator fails/slower                                | Retry same pack on CPU                                      | None needed                                                  |
| Hardware AEC unavailable/poor while platform TTS speaks | Use push-to-talk or half-duplex; do not claim barge-in      | Download owned TTS + enable benchmarked software AEC         |
| WebRTC APM initialization/route rebuild fails           | Stop capture/playback and pause fail closed                 | Retry after route change                                     |
| Bilingual confidence ambiguous                          | Show partial as uncertain; finalize with joint model policy | User edits text before send                                  |
| Local TTS voice unavailable                             | Silent text reply                                           | Explicit platform TTS fallback, labeled device-dependent     |
| Offline STT cannot meet real-time/thermal gate          | Push-to-talk with bounded offline batch decode              | Explicit network STT opt-in, never silent fallback           |
| Hermes unreachable                                      | Keep final transcript in composer, not an auto-replay queue | User sends after reconnect                                   |

A network recognizer is never an implicit fallback. If ever added, it needs a separate consent setting, obvious active-state disclosure, retention/provider documentation, and a no-audio-to-Hermes distinction.

## Benchmark and proof plan

### Test matrix

Use at least three physical Android tiers (low/mid/high), current and oldest supported API levels, built-in speaker/mic, wired/USB, and representative Bluetooth routes. Run:

- quiet near-field, far-field, reverberant room;
- stationary/non-stationary noise at several SNRs;
- TTS playback at low/medium/high volume;
- true double-talk at different user/TTS level ratios;
- each language alone, accents, names/numbers, and within-utterance code-switching;
- short answers (`yes`, `no`, stop commands), long dictation, pauses, false starts;
- route changes, calls/notifications/audio focus, screen lock/background, permission revoke;
- 30-minute sustained alternating STT/TTS for thermal and leak behavior.

Use licensed/purpose-built corpora plus a consented pair-specific code-switch set. Keep evaluation audio out of normal app telemetry.

### Metrics

**Recognition:** WER per alphabetic language, CER per character-based language, mixed error rate (MER) for code-switch data, switch-boundary error, named-entity/number accuracy, partial revision rate, language-segment accuracy, no-speech false accept/reject.

**Endpoint/barge-in:** speech-start miss/clipping, endpointer latency from acoustic speech end, premature endpoint rate, TTS-stop latency from acoustic interruption start and from first meaningful partial, true interruption recall, false interruption rate during TTS-only playback, time from interruption to final text.

**AEC/audio:** echo return loss enhancement (ERLE) in single-talk, residual echo recognition rate, double-talk near-end attenuation, clipping, noise-floor change, overruns/underruns, route rebuild time. A deterministic callback fixture cannot establish any of these acoustic facts.

**Performance:** cold/warm model load, peak/proportional-set memory, package/storage bytes, ASR real-time factor, p50/p95/p99 partial and endpoint latency, TTS time to first PCM, TTS synthesis RTF, CPU/GPU/NPU utilization, energy per minute, temperature/thermal throttling, and 30-minute stability.

**TTS quality:** pair-native listener preference/MOS where feasible, intelligibility/word error from a held-out recognizer, pronunciation test set, code-switch pronunciation, first-audio latency, glitches, and cancellation tail.

**Privacy:** airplane-mode functional run after install; packet capture proving no audio/inference traffic; filesystem scan proving no PCM/temp residue; log/diagnostic scan proving no words; corrupt/oversize/path-traversal pack tests.

### Provisional engineering gates

Tune these after baseline data; they are proposed product gates, not sourced industry standards:

- p95 streaming ASR RTF < 0.7 and no sustained run above 1.0 on the target tier;
- p95 changed-partial latency < 250 ms;
- p95 endpoint latency < 800 ms with < 1% premature endpoints on the product set;
- p95 playback stop < 200 ms from confirmed interruption;
- > 95% true barge-in recall and <1 false stop per 10 minutes of TTS-only playback in the defined acoustic matrix;
- zero audio overruns and no unbounded memory growth in a 30-minute run;
- offline packet capture shows zero inference/audio network requests;
- accelerator selected only if it improves p95 latency or energy materially without a quality regression;
- quality thresholds are pair/model specific and must beat or match the measured Android on-device baseline before becoming default.

### Evidence ladder

1. Unit tests: generations, stale callbacks, endpoint logic, echo heuristics, pack verification, fallback policy.
2. Native deterministic tests: recorded PCM into APM/VAD/ASR; exact expected callback ownership and cancellation.
3. Android instrumentation: real native library, model pack, audio route setup, release build contamination check.
4. Wired acoustic loop fixture: repeatable speaker-to-mic latency/AEC scenarios.
5. Physical human smoke: unique bilingual phrases, TTS, genuine spoken barge-in, second re-armed turn.
6. Multi-device benchmark report with build fingerprint, route, pack hash, aggregate metrics, and no transcript contents.

Only levels 4–6 support acoustic AEC/barge-in claims. The existing deterministic recognizer fixture remains valuable lifecycle evidence but is not physical microphone, speaker, AEC, language-model, or thermal evidence.

## Phased delivery

### Phase 0 — instrument and preserve fail-closed behavior

- Add engine/service/model provenance and route/DSP capability diagnostics without words.
- Establish physical-device baseline and benchmark harness.
- Keep current on-device recognizer path and current controller generation barriers.
- Do not market code-switching or acoustic barge-in yet.

**Exit:** reproducible physical baseline, no-secret receipt, lifecycle tests green.

### Phase 1 — owned streaming bilingual STT, push-to-talk/half-duplex

- Native C++/ONNX engine via FFI, CPU int8 baseline.
- Joint bilingual pack where available; Silero/TEN VAD and Wing endpoint policy.
- Signed transactional pack manager and offline/privacy tests.
- Keep platform TTS; pause/duck it for capture if AEC is not proven.

**Exit:** pair-specific quality/latency gates pass offline on target devices; Hermes sees text only.

### Phase 2 — app-owned streaming TTS and full-duplex audio

- Chunked local TTS with cancel callback and PCM playback owned by Wing.
- Evaluate platform communication AEC against WebRTC APM with exact render reference.
- Implement continuous capture, double-talk, barge-in, route rebuild barriers.

**Exit:** acoustic fixture plus physical-device true/false barge-in gates pass; no raw-audio network traffic.

### Phase 3 — acceleration and broader packs

- Per-pack CPU/NNAPI/Vulkan/LiteRT challenger benchmarks; cached safe selection and CPU fallback.
- Additional language pairs/voices, optional high-tier offline rescoring.
- Play Asset Delivery integration for Play builds while retaining signed direct packs.

**Exit:** accelerator improves measured latency/energy, pack rollback/update receipts pass, pair-specific quality cards published.

## Sources

[1] https://github.com/ggml-org/whisper.cpp — whisper.cpp repository
[3] https://github.com/openai/whisper — OpenAI Whisper repository
[14] https://developer.android.com/reference/android/media/MediaRecorder.AudioSource — Android MediaRecorder.AudioSource
[15] https://developer.android.com/reference/android/media/audiofx/AcousticEchoCanceler — Android AcousticEchoCanceler
[16] https://developer.android.com/reference/android/media/audiofx/NoiseSuppressor — Android NoiseSuppressor
[17] https://developer.android.com/reference/android/media/audiofx/AutomaticGainControl — Android AutomaticGainControl
[18] https://webrtc.googlesource.com/src/+/main/modules/audio_processing/g3doc/audio_processing_module.md — WebRTC Audio Processing Module
[19] https://webrtc.googlesource.com/src/+/main/api/audio/audio_processing.h — WebRTC AudioProcessing API
[20] https://k2-fsa.github.io/sherpa/onnx/index.html — sherpa-onnx documentation
[21] https://k2-fsa.github.io/sherpa/onnx/pretrained_models/online-transducer/index.html — sherpa-onnx online transducer models
[22] https://k2-fsa.github.io/sherpa/onnx/vad/index.html — sherpa-onnx VAD
[23] https://k2-fsa.github.io/sherpa/onnx/tts/index.html — sherpa-onnx TTS
[24] https://raw.githubusercontent.com/k2-fsa/sherpa-onnx/master/sherpa-onnx/csrc/online-recognizer.h — sherpa-onnx OnlineRecognizer API
[25] https://raw.githubusercontent.com/k2-fsa/sherpa-onnx/master/sherpa-onnx/csrc/online-stream.h — sherpa-onnx OnlineStream API
[26] https://raw.githubusercontent.com/k2-fsa/sherpa-onnx/master/sherpa-onnx/csrc/offline-tts.h — sherpa-onnx OfflineTts API
[27] https://developer.android.com/ndk/guides/neuralnetworks — Android Neural Networks API
[28] https://onnxruntime.ai/docs/execution-providers/NNAPI-ExecutionProvider.html — ONNX Runtime NNAPI EP
[29] https://developer.android.com/guide/playcore/asset-delivery — Play Asset Delivery
[30] https://developer.android.com/reference/android/speech/SpeechRecognizer — Android SpeechRecognizer
[31] https://developer.android.com/reference/android/speech/RecognizerIntent — Android RecognizerIntent
[32] https://developer.android.com/privacy-and-security/security-best-practices — Android security best practices
[33] https://developer.android.com/ndk/guides/audio/audio-latency — Android audio latency
[34] https://github.com/snakers4/silero-vad — Silero VAD
[5] https://k2-fsa.github.io/sherpa/onnx/pretrained_models/whisper/export-onnx.html — sherpa-onnx Whisper models
[6] https://alphacephei.com/vosk/models — Vosk model catalog
[7] https://github.com/alphacep/vosk-api — Vosk API
[8] https://github.com/moonshine-ai/moonshine — Moonshine Voice
[9] https://huggingface.co/nvidia/parakeet-tdt-0.6b-v3 — Parakeet-TDT model card
[10] https://github.com/NVIDIA/NeMo-Speech.cpp — NeMo-Speech.cpp
[35] https://github.com/ggml-org/whisper.cpp/blob/master/models/README.md — whisper.cpp model sizes
[36] https://huggingface.co/hexgrad/Kokoro-82M — Kokoro model card
[37] https://github.com/supertone-inc/supertonic — Supertonic repository
[38] https://huggingface.co/Supertone/supertonic-3 — Supertonic 3 model card
[40] https://github.com/OHF-Voice/piper1-gpl — Piper repository
[42] https://huggingface.co/hexgrad/Kokoro-82M/blob/main/VOICES.md — Kokoro voices
[43] https://github.com/thewh1teagle/kokoro-onnx — quantized Kokoro ONNX variants
[44] https://github.com/OHF-Voice/piper1-gpl/blob/main/docs/VOICES.md — Piper voices
[47] https://github.com/k2-fsa/sherpa-onnx/blob/master/flutter/sherpa_onnx/lib/src/tts.dart — sherpa-onnx Flutter TTS callback API
[48] https://github.com/supertone-inc/supertonic/blob/main/flutter/README.md — Supertonic Flutter example
[52] https://huggingface.co/ggerganov/whisper.cpp — quantized whisper.cpp model files
