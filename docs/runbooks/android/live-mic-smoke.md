# Android Live Microphone Hermes Smoke

Required manual smoke for Android physical microphone + continuous voice evidence.
This is the physical-audio receipt that deterministic transcript tests,
`android:voice-smoke`, and `android:hermes-voice-loop-smoke` cannot provide.
The automated Hermes voice-loop receipt remains a useful no-human regression
gate, but strict goal closeout must keep the Android physical-mic blocker open
until this real spoken-audio/provider/TTS/re-arm receipt is captured.

## Start here

Prerequisites:

- an audio-capable, responsive physical Android device; emulators can exercise
  prep/regression helpers but cannot close this live-mic receipt;
- a configured Hermes Agent API server with provider/model credentials;
- a safe Android-reachable Hermes URL, usually a LAN/VPN/Tailscale URL for the
  physical device (`http://10.0.2.2:8642` is emulator-only prep context, not a
  final live-mic receipt URL);
- a debug APK build or permission to let the prep helper build one.

Prepare the target:

```bash
npm run android:live-mic-prep
```

or target a specific device and endpoint hint:

```bash
NAVIVOX_ANDROID_DEVICE_ID=<device-id> \
NAVIVOX_ANDROID_HERMES_URL=<android-reachable-hermes-url> \
npm run android:live-mic-prep
```

The prep helper installs/launches Navivox and grants `RECORD_AUDIO`. It is not a
pass receipt.

Current prep receipt (2026-07-04): `flutter emulators --launch fractal_test`
crashed with exit `-6`, but directly launching the AVD with
`/usr/lib/android-sdk/emulator/emulator -avd fractal_test -no-snapshot
-no-boot-anim -gpu swiftshader_indirect -no-window` brought `emulator-5554`
online long enough for `npm run android:live-mic-prep` to build, install,
launch, and grant microphone permission. The emulator log also reported
`pulseaudio: Failed to initialize PA context`; treat this as prep evidence only.
It still does not prove physical spoken audio, provider reply, TTS, or re-arm.

## Pass evidence required

Record all of the following before claiming the required physical-mic evidence:

1. `adb devices` and `flutter devices` show a physical Android target online;
   an `emulator-*` target is not accepted for the live-mic receipt.
2. Hermes Agent API is running with real provider/model credentials.
3. Navivox `/hermes` connects to the Android-reachable Hermes URL.
4. Tap Speak, say a unique phrase aloud, and verify the spoken phrase appears as
   a Hermes text turn.
5. Verify the turn receives a provider-backed Hermes reply.
6. Enable continuous voice.
7. Verify capture → Hermes reply → TTS → re-arm for at least one second spoken
   turn. The second spoken phrase must be different from the first so the receipt
   proves a distinct re-armed capture, not a replayed transcript.
8. Verify the audio was spoken aloud into the Android microphone path, not
   injected through synthetic/generated transcript or host playback tooling.
9. Verify no API key, pairing token, bearer token, transcript secret, raw tool
   payload, or private diagnostic data appears in routes, logs, notices,
   screenshots, or diagnostics export.
10. Record the manual receipt only after all observations above are true:

   ```bash
   NAVIVOX_ANDROID_DEVICE_ID=<device-id> \
   NAVIVOX_ANDROID_HERMES_URL=<android-reachable-hermes-url> \
   NAVIVOX_ANDROID_SPOKEN_PHRASE='<unique spoken phrase>' \
   NAVIVOX_ANDROID_PROVIDER_REPLY='<observed provider reply excerpt>' \
   NAVIVOX_ANDROID_SECOND_SPOKEN_PHRASE='<different second spoken phrase after re-arm>' \
   NAVIVOX_ANDROID_PHYSICAL_DEVICE_OBSERVED=true \
   NAVIVOX_ANDROID_PHYSICAL_MIC_OBSERVED=true \
   NAVIVOX_ANDROID_TTS_OBSERVED=true \
   NAVIVOX_ANDROID_REARM_OBSERVED=true \
   NAVIVOX_ANDROID_NO_SECRET_LEAKS=true \
   NAVIVOX_ANDROID_SYNTHETIC_AUDIO_USED=false \
   npm run android:live-mic-receipt
   ```

   This writes `build/receipts/android-live-mic-smoke.json`; the helper strips
   URL userinfo, query strings, fragments, and copied route/path state from the
   recorded Hermes URL, records the current git `HEAD`, records Android device properties from
   `adb shell getprop`, records installed Navivox package/version details from
   `pm path` and `dumpsys package`, and rejects secret-looking or overlong spoken
   phrases/provider reply excerpts; keep each manual evidence value to 240
   characters or less. The helper and audit require an explicit physical-device
   and physical-mic manual observation gate, reject emulator targets for this
   live-mic receipt, require `NAVIVOX_ANDROID_SYNTHETIC_AUDIO_USED=false`,
   require the receipt path labels `physical_android_microphone`,
   `local_device_stt_to_hermes_text`, `provider_backed_hermes_text_reply`, and
   `tts_observed_before_rearm`, require the second spoken phrase to differ from
   the first, require the provider reply excerpt to differ from both spoken
   phrases, require the receipt `head_sha` to match the current git `HEAD`,
   require non-empty manufacturer/model/SDK/fingerprint device properties plus
   `android_target_type=physical_device` and `device_properties.is_emulator=false`,
   require the expected Navivox package to be installed with version metadata and
   `RECORD_AUDIO` granted, and validate the required fields/caveats while still
   treating unrelated blockers as open.
11. Run strict readiness audit after recording the receipt:

   ```bash
   NAVIVOX_FAIL_ON_BLOCKERS=1 npm run hermes:readiness-audit
   ```

   If unrelated blockers remain, the expected result is exit 3 with
   `Completion verdict: NOT COMPLETE`; do not promote this Android physical-mic
   receipt, passing tests, APK hashes, configured Hermes home, workflow YAML, or
   dispatch-only output to whole-goal completion. If the physical-mic receipt is
   absent, strict readiness must keep the real spoken Android receipt blocker
   open even when the deterministic Android voice-loop receipt is current.

## Do not count as completion

- `npm run android:live-mic-prep` by itself.
- `npm run android:voice-smoke`; it checks recognizer availability/permission,
  not spoken audio.
- `npm run android:hermes-voice-loop-smoke`; it is the no-human automated
  Android voice-loop gate, but it proves deterministic UI loop mechanics with
  fake capture/TTS, not a physical microphone.
- Provider transcript smoke by itself; it is text/transcript-backed, not live
  Android audio.
- Synthetic/generated host audio playback, emulator audio routes, or speech-capture
  tests by themselves; they can help debug recognizer plumbing, but they do not
  prove physical-device mic evidence unless the audio actually travels through a
  physical Android microphone/STT path and TTS/re-arm is observed. Direct
  transcript injection remains non-physical automated evidence.

## Failure notes

If the target flakes during install or launch, capture `adb devices`,
`flutter devices`, and the prep helper output. Known unstable-emulator symptoms
include `cmd: Failure calling service package: Broken pipe (32)`, `Unable to
start the app on the device`, Flutter emulator launcher exit `-6`, and emulator
logs such as `pulseaudio: Failed to initialize PA context`; those are Android
startup/audio-driver/package-service failures, not microphone evidence. When the
Flutter launcher crashes but the SDK emulator is otherwise available, try the
headless direct-launch form above to reach prep, then still require the manual
physical-audio checklist. Do not mark the smoke failed or passed solely from a
prep failure; first determine whether Android itself is online and audio-capable.

## Update triggers

Update this runbook when `scripts/prepare_android_live_mic_smoke.sh`,
`integration_test/android_device_speech_smoke_test.dart`,
`integration_test/hermes_continuous_voice_android_smoke_test.dart`, or Hermes
voice transport behavior changes.
