# Android Device And Secret Contracts

Use safe device endpoints such as `http://127.0.0.1:<port>` for host-loopback and `http://10.0.2.2:<port>` for Android emulator access. For physical devices prefer LAN, VPN, or Tailscale addresses.

Run `gormes navivox connect-info` to generate local connection details, but Do not paste tokens into logs, docs, screenshots, issues, or chat transcripts. Treat this as the pairing secrets contract.

For Android local install and voice checks, use:

```sh
adb install -r build/app/outputs/flutter-apk/app-debug.apk
adb shell cmd package query-services -a android.speech.RecognitionService
```

Keep Android recognizer, microphone permission, and gateway profile STT as separate checks. A healthy smoke reaches `Continuous voice ready`.
