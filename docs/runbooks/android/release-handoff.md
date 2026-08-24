# Android Release Handoff

Use this when handing a local Hermes Wing Android build to a trusted tester or installing it on a development device.

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
adb devices -l
adb -s <device-id> install -r build/app/outputs/flutter-apk/app-debug.apk
```

Always pin `<device-id>`. An emulator and a physical phone can be online at the
same time, and an implicit ADB target can install or inspect the wrong device.

For the physical-microphone test path, the repository helper builds a debug APK,
installs that exact artifact, verifies the package, grants microphone permission,
and launches the app:

```bash
WING_ANDROID_DEVICE_ID=<device-id> npm run android:live-mic-prep
```

The helper fails if the exact debug APK cannot be installed; it must never fall
back to launching an older release already present on the phone. Preparation is
still not proof that microphone capture, provider reply, TTS, or re-arm works.

## Release signing setup

Release builds use a keystore-backed signing config only when all signing values are supplied through ignored local properties or CI environment secrets. Never commit the keystore or passwords.

Local `android/local.properties` example:

```properties
wing.release.storeFile=/absolute/path/to/wing-release.jks
wing.release.storePassword=...
wing.release.keyAlias=wing
wing.release.keyPassword=...
```

CI/environment variable equivalents:

```text
WING_RELEASE_STORE_FILE
WING_RELEASE_STORE_PASSWORD
WING_RELEASE_KEY_ALIAS
WING_RELEASE_KEY_PASSWORD
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
- Do not ship pairing tokens, gateway URLs, logs, screenshots, or private Hermes host details inside an artifact handoff.
- Share setup separately. Configure Hermes Agent and Wing Link with an address
  the phone can reach over a trusted VPN/Tailscale network or isolated trusted
  LAN, then run non-loopback pairing:

  ```bash
  WING_HERMES_URL=http://<phone-reachable-address>:8642 \
  WING_LINK_URL=https://<phone-reachable-address>:8654 \
  wing-link pair
  ```

  Remote pairing uses TLS 1.3. In Wing choose **Connect to Hermes → Scan QR
  code** and scan from the host screen; native Wing verifies the self-signed
  broker with the reviewed SPKI pin. Browsers cannot validate that pin. For a
  pairing link already in a text message, use Android **Share → Hermes Wing**.
  The ordinary `/open` helper is loopback-only for same-host clients. Entering a
  Hermes API URL and token manually is a one-profile fallback only and does not
  import Wing Link or other Hermes profiles.

- Treat release signing keys as external secrets; do not add them to this repository or to issue reports.

## Quick smoke after install

1. Launch Hermes Wing on the Android target.
2. Confirm the setup screen opens without requiring a token in logs or screenshots.
3. Run the default pairing command with a phone-reachable trusted VPN/Tailscale
   or isolated-LAN address. Use `--local` only for same-host pairing. Verify the QR
   flow from the host screen and Android **Share → Hermes Wing** for an existing
   pairing message. Use loopback `/open` only when Wing runs on that same host,
   and manual URL/token
   entry only as a one-profile fallback.
4. Send one short text turn to confirm the installed app can reach the trusted gateway.

## Continuous voice smoke after install

Use a responsive Android target only. If ADB lists the target but `adb shell true` hangs or times out, the target is not valid for this smoke.
For the active Hermes Wing goal, follow `docs/runbooks/android/live-mic-smoke.md`
after install: connect to a configured Hermes Agent API with real provider/model
credentials, tap Speak, verify the spoken phrase becomes a Hermes text turn with
a provider-backed reply, then verify continuous voice capture → Hermes reply →
TTS → re-arm. Installing the APK is not a physical-audio receipt.

Check for an Android speech recognizer before judging Hermes Wing voice behavior:

```bash
adb -s <device-id> shell true
adb -s <device-id> shell cmd package query-services -a android.speech.RecognitionService
```

Open the active profile chat, tap the mic, grant the microphone permission prompt if Android asks, and speak a short phrase. The expected ready path is:

1. The banner shows `Continuous voice ready` before capture.
2. The mic action starts local speech-to-text capture.
3. The recognized text appears as the pending voice turn before it is sent.

If the app shows `Continuous voice unavailable: device STT unavailable`, verify microphone permission and the Android speech recognizer service before changing gateway connection settings.

## Continuous voice blocker handoff

Run id: `voice-readiness-smoke-2026-05-27`.

Latest local debug APK path:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

Run `sha256sum build/app/outputs/flutter-apk/app-debug.apk` or `npm run hermes:readiness-audit` for the current artifact hash. Treat APK hashes as artifact identity only, never as Android microphone, provider reply, TTS, or re-arm evidence.

Current live-mic blocker: a responsive emulator can cover deterministic voice-loop mechanics, but real spoken-audio evidence still requires the manual physical mic checklist in `docs/runbooks/android/live-mic-smoke.md`. Do not treat emulator boot, app install, microphone permission, APK hashes, generated audio, or transcript injection as physical microphone evidence.

What is already covered in the app:

- Android uses local `speech_to_text` capture when the platform is Android.
- Bare gateway-reported `device STT unavailable` is advisory unless paired with an explicit disabled reason.
- Runtime local STT failures switch continuous voice into an actionable unavailable state.
- Permission failures show `microphone permission denied` and tell the tester to grant microphone permission in Android App info.
- The continuous voice sheet explains that Android recognizer, microphone permission, and gateway profile STT are separate checks.

Final smoke requirement: use a responsive emulator or physical USB-debuggable Android device, install the latest local debug APK, run `adb -s <device-id> shell true`, run the speech-recognition service query against that same explicit device, grant microphone permission, then capture one short phrase from the active profile chat.
