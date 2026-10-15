# Android Release Handoff

Use this when handing a local Hermes Wing Android build to a trusted tester or installing it on a development device.

## Exact release evidence

The release workflow emits `android-release-evidence.json` after dependency
resolution and APK/AAB creation. It records actual
input digests, source dirty status, version/build, toolchain, workflow run and
attempt, signing certificate identity, and separate APK/AAB digests. There is no generated host-service bootstrap metadata or binary in the release.

The emulator smoke pulls the installed single base APK back through Android's
package manager identity and checks its digest against the artifact being tested.
Split/store installations are rejected by this smoke and remain unqualified.
APK install/launch evidence never qualifies the AAB, physical microphone, acoustic
quality, or service lifecycle.

Before publication, `release-qualification-index.json` hashes all three client
build manifests (Android, Linux and web), payloads, auxiliary files, the host
verification receipt and the Android emulator smoke receipt. Missing or mismatched
required receipts fail publication. This binds integrity and launch evidence, not
same-artifact M1–M5, upgrade or recovery acceptance; see the
[Android integrated receipt gap](../../quality/m6-android-integrated-receipt-gap.md).
Historical manual receipts are not imported into this index; opt-in sanitized
physical/server-audio receipts remain a separate manual evidence chain. See the
[live microphone runbook](live-mic-smoke.md). No signed release or hosted workflow
was executed to validate this new evidence path locally.

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

## Private release APK handoff

For direct phone testing, use an optimized ARM64 APK rather than a debug APK or
store AAB. A private signing key is sufficient; it is not a production/store
signing identity. Retain the approved private key for future updates and keep
its password and keystore outside the repository and artifacts.

Supply the four `WING_RELEASE_*` signing values through the secret-safe local
build environment, then set `WING_PRIVATE_RELEASE_TEST=1`. This selects the
separate `com.trebuchetdynamics.hermes.wing.qa.release` app ID and fails configuration
if no signing configuration is available. It does not replace the paired app or
the `.qa` debug installation.

```bash
WING_PRIVATE_RELEASE_TEST=1 flutter build apk --release --split-per-abi \
  --target-platform android-arm64 -t lib/main.dart
```

Before handoff, verify the exact app ID, ARM64 ABI, version, signature against the
approved private key's public certificate, and ZIP integrity. Verify that the
app is not debuggable, contains native AOT app code, and has no debug kernel
bundle. Compilation and signature checks are not Android device qualification.
Never include signing secrets, configured endpoints, or paired state in the APK
or attachment. Store publication remains a separate authorization and workflow.

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
- Share setup separately through the [direct Agent guide](../../getting-started.md#direct-agent-connection).
  The app offers no service bootstrap or pairing mode. Never include credentials,
  private host details or handoff payloads with a release artifact.

- Treat release signing keys as external secrets; do not add them to this repository or to issue reports.

## Quick smoke after install

1. Launch Hermes Wing on the Android target.
2. Confirm the setup screen opens without requiring a token in logs or screenshots.
3. Follow the [direct Agent guide](../../getting-started.md#direct-agent-connection):
   prepare an authenticated Agent API and choose SSH, Remote server or manual
   Termux preparation as appropriate. Wing offers no pairing or QR handoff.
4. Only with separately approved QA authentication, exact grants and an
   authoritative provider-call budget, send one short text turn to confirm the
   installed app can reach the selected Agent. Otherwise record Chat as not checked.
   A successful reply alone does not close the integrated receipt gap above.

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

- Android uses the hosted `speech_to_text` package for platform capture.
- Bare gateway-reported `device STT unavailable` is advisory unless paired with an explicit disabled reason.
- Runtime local STT failures switch continuous voice into an actionable unavailable state.
- Permission failures show `microphone permission denied` and tell the tester to grant microphone permission in Android App info.
- The continuous voice sheet explains that Android recognizer, microphone permission, and gateway profile STT are separate checks.

Final smoke requirement: use a responsive emulator or physical USB-debuggable Android device, install the latest local debug APK, run `adb -s <device-id> shell true`, run the speech-recognition service query against that same explicit device, grant microphone permission, then capture one short phrase from the active profile chat.
