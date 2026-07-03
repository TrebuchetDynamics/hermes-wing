# Android Release Handoff

Use this when handing a local Navivox Android build to a trusted tester or installing it on a development device.

## Debug APK for local testers

Build a debug APK from the repository root:

```bash
flutter build apk --debug
```

The local artifact is:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

Install directly through Flutter when the target appears in `flutter devices`:

```bash
flutter install -d <device-id>
```

Or install the APK with ADB:

```bash
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

## Release signing setup

Release builds use a keystore-backed signing config only when all signing values are supplied through ignored local properties or CI environment secrets. Never commit the keystore or passwords.

Local `android/local.properties` example:

```properties
navivox.release.storeFile=/absolute/path/to/navivox-release.jks
navivox.release.storePassword=...
navivox.release.keyAlias=navivox
navivox.release.keyPassword=...
```

CI/environment variable equivalents:

```text
NAVIVOX_RELEASE_STORE_FILE
NAVIVOX_RELEASE_STORE_PASSWORD
NAVIVOX_RELEASE_KEY_ALIAS
NAVIVOX_RELEASE_KEY_PASSWORD
```

If any value is missing, Gradle falls back to Flutter's debug signing config so local `--release` smoke builds can still run. Do not distribute a release artifact built with that fallback.

## Release app bundle handoff

Only build a release bundle after release signing values, versioning, and tester scope are agreed:

```bash
flutter build appbundle --release
```

The release bundle path is:

```text
build/app/outputs/bundle/release/app-release.aab
```

## Safety boundaries

- Use debug APKs only for local development and a trusted tester.
- Do not ship pairing tokens, gateway URLs, logs, screenshots, or private Gormes host details inside an artifact handoff.
- Share setup values separately with `gormes navivox connect-info` and paste tokens into Navivox only.
- Treat release signing keys as external secrets; do not add them to this repository or to issue reports.

## Quick smoke after install

1. Launch Navivox on the Android target.
2. Confirm the setup screen opens without requiring a token in logs or screenshots.
3. Paste a reachable Gormes base URL and token from `gormes navivox connect-info`.
4. Send one short text turn to confirm the installed app can reach the trusted gateway.

## Continuous voice smoke after install

Use a responsive Android target only. If ADB lists the target but `adb shell true` hangs or times out, the target is not valid for this smoke.
For the active Hermes companion goal, follow `docs/runbooks/android/live-mic-smoke.md` after install: connect to a configured Hermes Agent API with real provider/model credentials, tap Speak, verify the spoken phrase becomes a Hermes text turn with a provider-backed reply, then verify continuous voice capture → Hermes reply → TTS → re-arm. Installing the APK is not a physical-audio receipt.

Check for an Android speech recognizer before judging Navivox voice behavior:

```bash
adb shell true
adb shell cmd package query-services -a android.speech.RecognitionService
```

Open the active profile chat, tap the mic, grant the microphone permission prompt if Android asks, and speak a short phrase. The expected ready path is:

1. The banner shows `Continuous voice ready` before capture.
2. The mic action starts local speech-to-text capture.
3. The recognized text appears as the pending voice turn before it is sent.

If the app shows `Continuous voice unavailable: device STT unavailable`, verify microphone permission and the Android speech recognizer service before changing Gormes gateway settings.

## Continuous voice blocker handoff

Run id: `voice-readiness-smoke-2026-05-27`.

Latest local debug APK:

```text
build/app/outputs/flutter-apk/app-debug.apk
sha256 453e746d9773b466a7393ec73713943a49276f4bee4465d18a3d083e5cb5ab0a
```

Current host blocker: ADB lists no Android devices, and `flutter devices` lists only Linux desktop and Chrome. The available `fractal_test` Android emulator cannot boot on this host because x86_64 emulation requires KVM access and the current user does not have `/dev/kvm` permission. Do not treat this host as valid evidence for microphone permission prompts, Android speech recognizer availability, or real STT capture until a responsive Android target is connected or KVM access is fixed.

What is already covered in the app:

- Android uses local `speech_to_text` capture when the platform is Android.
- Bare gateway-reported `device STT unavailable` is advisory unless paired with an explicit disabled reason.
- Runtime local STT failures switch continuous voice into an actionable unavailable state.
- Permission failures show `microphone permission denied` and tell the tester to grant microphone permission in Android App info.
- The continuous voice sheet explains that Android recognizer, microphone permission, and gateway profile STT are separate checks.

Final smoke requirement: use a responsive emulator or physical USB-debuggable Android device, install the latest local debug APK, run `adb shell true`, run the speech-recognition service query, grant microphone permission, then capture one short phrase from the active profile chat.
