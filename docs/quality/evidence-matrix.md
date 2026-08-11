# Hermes Wing evidence matrix

This ledger records the strongest evidence available for each capability without promoting deterministic tests into physical or production proof. Run `dart run scripts/check_evidence_matrix.dart` before release handoff. Receipt-bearing rows become stale after 90 days by default and must be refreshed against behaviorally equivalent source and artifacts.

Classification meanings:

- **battle-tested:** repeated representative production use with durable failure evidence.
- **qualified:** deterministic coverage plus intended-platform behavioral receipts.
- **deterministically tested:** repeatable automated tests without intended-platform qualification.
- **build/device-smoke tested:** compilation, packaging, installation, launch, or a narrow runtime seam.
- **prototype/partial:** implementation exists but product, contract, or evidence gaps remain.
- **unverified physical/acoustic:** deterministic substitutes do not prove the physical claim.
- **planned only:** no production implementation.

| ID | Capability | Classification | Source identity | Artifact or receipt identity | Platform | Evidence date UTC | Limitations |
| --- | --- | --- | --- | --- | --- | --- | --- |
| release-apk | Universal release APK | build/device-smoke tested | worktree-2026-08-09 | sha256:a1baefd9d807069391249c98761f621ec781d6e8b7083272ce77a58efc055e36 | Android universal | 2026-08-09 | Build, ZIP, install, and launch evidence only; unsigned distribution and upgrade rollback remain open |
| core-api-chat | Hermes HTTP and SSE chat core | qualified | worktree-2026-08-09 | tests:hermes-api-channel-and-real-gateway-maestro | Web and Android | 2026-08-09 | Covered gateway and scenarios only; no representative production fleet evidence |
| detached-runs | Concurrent and detached run ownership | qualified | worktree-2026-08-09 | tests:detached-run-store-and-physical-maestro | Android | 2026-08-09 | Current-head process-death soak across Android versions remains open |
| transcript-events | Transcript, reasoning, tools, usage, approvals | deterministically tested | worktree-2026-08-09 | tests:rich-transcript-approval-diagnostics | Flutter | 2026-08-09 | Selected device flows exist but authoritative-final dropped-chunk reconciliation remains planned |
| sessions | Session search, metadata, export, and selected mutations | qualified | worktree-2026-08-09 | receipt:session-metadata-and-concurrency-maestro | Android | 2026-08-09 | Resource projects, pinning, and current-source full matrix remain open |
| profiles | Profiles and persona administration | prototype/partial | worktree-2026-08-09 | none | Android and Hermes API | 2026-08-09 | Agent contracts and removal of Wing Link domain fallbacks remain incomplete |
| providers | Providers and models | prototype/partial | worktree-2026-08-09 | none | Android and Hermes API | 2026-08-09 | Read-only and client-local paths exist; authoritative write-only administration is incomplete |
| tools-skills | Tools and installed skills inventory | qualified | worktree-2026-08-09 | receipt:tools-inventory-maestro | Android | 2026-08-09 | Qualification covers read-only inventory; mutations and MCP administration are absent |
| schedules | Schedule inventory | prototype/partial | worktree-2026-08-09 | none | Android and Hermes API | 2026-08-09 | Read-only fail-closed UI exists; compatible live inventory and mutations remain open |
| gateway | Detailed gateway health | qualified | worktree-2026-08-09 | receipt:gateway-status-maestro | Android | 2026-08-09 | Covers bounded read-only and unsupported states, not lifecycle or configuration mutations |
| office | Accessible two-dimensional Office | qualified | worktree-2026-08-09 | receipt:office-workspace-maestro | Android | 2026-08-09 | Basic directory and chat activation only; task activity and representative actions remain open |
| wing-link | Wing Link bootstrap and runtime supervision | prototype/partial | worktree-2026-08-09 | none | Go and Android Termux | 2026-08-09 | Deterministic Go tests exist; signed clean adopt repair rollback device receipt is absent |
| continuous-voice | Continuous voice lifecycle ownership | qualified | worktree-2026-08-09 | receipt:waydroid-continuous-voice-maestro | Android Waydroid | 2026-08-09 | Fixture-driven lifecycle proof; not microphone, acoustic echo, or speech-quality evidence |
| microphone-capture | Native Android microphone capture | build/device-smoke tested | worktree-2026-08-09 | tests:voice-engine-contracts-and-native-runtime | Android | 2026-08-09 | Controlled physical microphone routing has not been observed |
| whisper-silero | Offline Whisper and Silero runtime | build/device-smoke tested | worktree-2026-08-09 | receipt:waydroid-and-samsung-fixture-runtime | Android arm64 and Waydroid | 2026-08-09 | Fixture and silent PCM prove native runtime, not WER, code switching, or live microphone behavior |
| pocket-speech | Offline Kokoro and Pocket Speech runtime seam | prototype/partial | worktree-2026-08-09 | none | Android Waydroid | 2026-08-09 | Synthesis returns a complete WAV before chunking; listening quality and first-audio latency are unverified |
| model-installer | Transactional offline model packs | deterministically tested | worktree-2026-08-09 | tests:voice-model-pack-installer | Dart IO | 2026-08-09 | No physical low-storage or interrupted-network recovery matrix |
| pcm-playback | Generation-owned native PCM playback | build/device-smoke tested | worktree-2026-08-09 | receipt:waydroid-and-samsung-pcm-smoke | Android | 2026-08-09 | Ownership seam is covered; audibility, route matrix, underruns, and cancellation latency remain open |
| acoustic-aec | Acoustic echo cancellation effectiveness | unverified physical/acoustic | worktree-2026-08-09 | none | Physical Android | 2026-08-09 | Platform AEC attachment and a disabled probe do not prove ERLE, leakage, or double-talk behavior |
| bilingual-quality | English Spanish and code-switch recognition quality | unverified physical/acoustic | worktree-2026-08-09 | none | Physical Android | 2026-08-09 | No controlled WER, CER, mixed-language token error rate, or genuine intra-utterance switch corpus |
| voice-performance | Voice latency, memory, battery, and thermals | unverified physical/acoustic | worktree-2026-08-09 | none | Physical Android | 2026-08-09 | No sustained low, mid, and high device benchmark |
| accessibility | Accessibility and large text | prototype/partial | worktree-2026-08-09 | none | Flutter and Android | 2026-08-09 | Widget semantics and scale tests exist; current TalkBack and keyboard receipts are incomplete |
| desktop-hosts | Linux Windows and macOS host parity | prototype/partial | worktree-2026-08-09 | none | Desktop hosts | 2026-08-09 | Historical build receipts exist; signed packages, host E2E, and updater rollback remain incomplete |
| hermes-server-audio | Hermes server realtime audio | planned only | worktree-2026-08-09 | none | Hermes API | 2026-08-09 | Current architecture intentionally sends final text and performs TTS locally |
