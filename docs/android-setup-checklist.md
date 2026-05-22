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

## 5. Quick recovery checks

- `Connection refused`: confirm Gormes is running and the selected URL is reachable from the Android target.
- `401` or `403`: rerun `gormes navivox connect-info` and paste the refreshed token into Navivox.
- No Android target: rerun `flutter devices`, then start an emulator or reconnect the physical device.
