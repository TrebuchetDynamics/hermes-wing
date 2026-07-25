# Publish an alpha release

The manual `Publish alpha release` workflow creates release-signed Android
APK and Play Store AAB artifacts, Linux x64 and static web archives, SHA-256
checksum files, and a GitHub prerelease.

Configure these GitHub Actions secrets before dispatching it:

- `WING_RELEASE_KEYSTORE_BASE64`
- `WING_RELEASE_STORE_PASSWORD`
- `WING_RELEASE_KEY_ALIAS`
- `WING_RELEASE_KEY_PASSWORD`

Encode the existing release keystore as one base64 line; do not create a new
identity for each build and never commit the keystore or passwords. Record key
custody and recovery outside this repository.

Set `pubspec.yaml` to the release version, then dispatch with a new matching
alpha tag—for example, `version: 0.1.0+1` requires `v0.1.0-alpha.1`. The
workflow rejects mismatched or existing tags before starting platform builds
and publishes only after all platform builds succeed. Use the APK for
sideloading, the AAB for Play Store uploads, and extract the web archive onto a
static host.

Before dispatching, verify the current commit with the commands in
`CONTRIBUTING.md` and complete the physical Android microphone receipt when the
release claims microphone support. After publishing, install the Android and
Linux artifacts on clean targets, smoke the extracted web archive on its target
host, and verify every published SHA-256 checksum.
