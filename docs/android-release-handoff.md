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

## Release app bundle handoff

Only build a release bundle after signing, versioning, and tester scope are agreed:

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
