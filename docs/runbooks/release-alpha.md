# Publish an alpha release

The manual `Publish alpha release` workflow creates release-signed Android
APK and Play Store AAB artifacts, Linux x64 and static web archives, SHA-256
checksum files, and a GitHub prerelease.

Configure these GitHub Actions secrets before dispatching it:

- `WING_RELEASE_KEYSTORE_BASE64`
- `WING_RELEASE_STORE_PASSWORD`
- `WING_RELEASE_KEY_ALIAS`
- `WING_RELEASE_KEY_PASSWORD`
- `WING_RELEASE_CERT_SHA256` — the pinned public SHA-256 fingerprint of the
  production Android signing certificate

Encode the existing release keystore as one base64 line; do not create a new
identity for each build and never commit the keystore or passwords. Record key
custody and recovery outside this repository.

Set `pubspec.yaml` to the release version, then dispatch with a new matching
alpha tag—for example, `version: 0.1.0+1` requires `v0.1.0-alpha.1`. The
workflow rejects mismatched or existing tags before starting platform builds.
Before publication it downloads the exact candidate files, enforces their
allowlist, verifies every checksum, verifies the APK/AAB signing certificate,
rejects unsafe archives, launches the Linux bundle and packaged web client,
installs and launches the APK on an emulator, and runs the native Windows and
available macOS Wing Link binary. Publication consumes only the resulting
verified artifact bundle and includes `release-verification-receipt.json` plus
the Android, macOS Wing Link, and Windows Wing Link smoke receipts.
Use the APK for sideloading, the AAB for Play Store uploads, and extract the web
archive onto a static host.

Before dispatching, verify the current commit with the commands in
`CONTRIBUTING.md` and complete the physical Android microphone receipt when the
release claims microphone support. The generic Linux archive and checksums are
alpha integrity evidence, not the signed APT/RPM release authority required for
a canonical release. The Android/Termux Wing Link binary and the non-native
macOS architecture receive checksum and format verification but still require
matching-device runtime receipts before those platform claims advance.

To repeat the host-side gate locally after collecting all candidate files:

```bash
WING_RELEASE_CERT_SHA256='<public certificate fingerprint>' \
  npm run release:verify-artifacts -- dist v0.1.0-alpha.1
```
