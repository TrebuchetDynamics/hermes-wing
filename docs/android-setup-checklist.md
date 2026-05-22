# Android Setup Checklist

Use this checklist when installing or running Navivox on Android for a local or self-hosted Gormes gateway.

## 1. Confirm Android tooling

From the Navivox repository root, confirm Flutter can see the Android toolchain:

```bash
flutter doctor
flutter doctor --android-licenses
flutter devices
```

If `flutter devices` does not list a target, start an emulator or connect a USB-debuggable Android device before running the app.

## 2. Run Navivox on the selected target

Replace `<device-id>` with an ID from `flutter devices`:

```bash
flutter run -d <device-id>
```

## 3. Pick the reachable Gormes URL

On the Gormes host, print the current setup values:

```bash
gormes navivox connect-info
```

Choose the base URL based on the Android target:

- Android emulator: use `http://10.0.2.2:<port>` for a gateway running on the host machine.
- USB-connected physical device with ADB reverse: run `adb reverse tcp:<port> tcp:<port>`, then use `http://127.0.0.1:<port>` in Navivox.
- Physical device without ADB reverse: use the host LAN, VPN, or Tailscale URL printed by `gormes navivox connect-info`.

## 4. Keep pairing values private

Paste the reachable base URL and pairing token into Navivox only. Do not paste tokens into issues, logs, screenshots, or chat transcripts.

## 5. Continuous voice smoke

After building a debug APK, install it on the selected Android target:

```bash
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

Before using a target for voice validation, confirm ADB shell and Android speech recognition are responsive:

```bash
adb shell true
adb shell cmd package query-services -a android.speech.RecognitionService
```

Then launch Navivox, connect to the trusted Gormes gateway, and open the chat for the active profile. Tap the mic, grant the microphone permission prompt if Android shows one, and confirm the continuous voice banner reaches `Continuous voice ready` instead of `Continuous voice unavailable: device STT unavailable`.

If `adb shell` hangs or the speech-recognition query prints no recognition service, do not treat that target as a valid STT smoke result. Retry with a responsive emulator image, a physical Android device with Google speech services enabled, or the actual Termux device that will run Gormes.

## 6. Quick recovery checks

- `Connection refused`: confirm Gormes is running and the selected URL is reachable from the Android target.
- `401` or `403`: rerun `gormes navivox connect-info` and paste the refreshed token into Navivox.
- No Android target: rerun `flutter devices`, then start an emulator or reconnect the physical device.
- Continuous voice still reports `device STT unavailable`: confirm microphone permission is granted and Android has an enabled speech recognition service.
