# Android Live Microphone Hermes Smoke

Manual smoke for the remaining Android microphone + continuous voice blocker.
This is the physical-audio receipt that deterministic transcript tests and
`android:voice-smoke` cannot provide.

## Start here

Prerequisites:

- an audio-capable, responsive Android device or emulator;
- a configured Hermes Agent API server with provider/model credentials;
- a safe Android-reachable Hermes URL, usually `http://10.0.2.2:8642` for an
  emulator or a LAN/VPN/Tailscale URL for a physical device;
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

Current prep receipt (2026-07-03): after a KVM-backed `fractal_test` emulator
booted, `NAVIVOX_ANDROID_DEVICE_ID=<emulator> NAVIVOX_ANDROID_DEVICE_WAIT_SECONDS=1
NAVIVOX_ANDROID_SKIP_BUILD=1 NAVIVOX_ANDROID_HERMES_URL=http://10.0.2.2:8642
npm run android:live-mic-prep` installed/launched/granted microphone permission.
This is prep evidence only; it still does not prove spoken audio, provider
reply, TTS, or re-arm.

## Pass evidence required

Record all of the following before closing the blocker:

1. `adb devices` and `flutter devices` show the Android target online.
2. Hermes Agent API is running with real provider/model credentials.
3. Navivox `/hermes` connects to the Android-reachable Hermes URL.
4. Tap Speak, say a unique phrase aloud, and verify the spoken phrase appears as
   a Hermes text turn.
5. Verify the turn receives a provider-backed Hermes reply.
6. Enable continuous voice.
7. Verify capture → Hermes reply → TTS → re-arm for at least one second spoken
   turn.
8. Verify no API key, pairing token, bearer token, transcript secret, raw tool
   payload, or private diagnostic data appears in routes, logs, notices,
   screenshots, or diagnostics export.
9. Run strict readiness audit after recording the receipt:

   ```bash
   NAVIVOX_FAIL_ON_BLOCKERS=1 npm run hermes:readiness-audit
   ```

   If unrelated blockers remain, the expected result is exit 3 with
   `Completion verdict: NOT COMPLETE`; do not promote this Android receipt,
   passing tests, APK hashes, configured Hermes home, workflow YAML, or
   dispatch-only output to whole-goal completion.

## Do not count as completion

- `npm run android:live-mic-prep` by itself.
- `npm run android:voice-smoke`; it checks recognizer availability/permission,
  not spoken audio.
- `npm run android:hermes-voice-loop-smoke`; it proves deterministic UI loop
  mechanics with fake capture/TTS, not a physical microphone.
- Provider transcript smoke by itself; it is text/transcript-backed, not live
  Android audio.

## Failure notes

If the target flakes during install or launch, capture `adb devices`,
`flutter devices`, and the prep helper output. Known unstable-emulator symptoms
include `cmd: Failure calling service package: Broken pipe (32)` and `Unable to
start the app on the device`; those are Android package-service failures, not
microphone evidence. Do not mark the smoke failed or passed solely from a prep
failure; first determine whether Android itself is online and audio-capable.

## Update triggers

Update this runbook when `scripts/prepare_android_live_mic_smoke.sh`,
`integration_test/android_device_speech_smoke_test.dart`,
`integration_test/hermes_continuous_voice_android_smoke_test.dart`, or Hermes
voice transport behavior changes.
