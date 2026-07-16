# Publish an alpha release

The manual `Publish alpha release` workflow creates a release-signed Android
APK, a Linux x64 archive, SHA-256 checksum files, and a GitHub prerelease.

Configure these GitHub Actions secrets before dispatching it:

- `WING_RELEASE_KEYSTORE_BASE64`
- `WING_RELEASE_STORE_PASSWORD`
- `WING_RELEASE_KEY_ALIAS`
- `WING_RELEASE_KEY_PASSWORD`

Encode the existing release keystore as one base64 line; do not create a new
identity for each build and never commit the keystore or passwords. Record key
custody and recovery outside this repository.

Dispatch with a new tag matching `v*-alpha.*`, for example
`v0.1.0-alpha.1`. The workflow refuses an existing release tag and publishes
only after both platform builds succeed.

Before dispatching, verify the current commit with the commands in
`CONTRIBUTING.md` and complete the physical Android microphone receipt when the
release claims microphone support. After publishing, install both artifacts on
clean targets and verify their published SHA-256 checksums.
