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

Set `pubspec.yaml` to the release version, then dispatch with a matching alpha
tag. For example, `version: 0.1.0+1` accepts `v0.1.0-alpha.N`, where `N` is a
numeric suffix independent of the build number. The workflow rejects tags with
a different app version, tags at another revision, and existing GitHub releases.
An existing tag at the workflow's exact revision is allowed. See
[the tag validation job](../../.github/workflows/release-alpha.yml).
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

## Local artifact verification

For a read-only comparison before candidate execution, use the
[offline comparison tool](offline-release-candidate-comparison.md). Supply independent
identity and public certificate expectations. A match does not authorize the
execution gate below or establish signature validity or installed-alpha acceptance.

Use a Linux qualification environment and the complete candidate directory listed
in [`verify_release_artifacts.sh`](../../scripts/verify_release_artifacts.sh).
Include the source-bound evidence JSON files, not only archives and checksums.
Use the candidate's source checkout, tag and immutable 40-character commit ID.
Do not substitute the current HEAD unless it is the candidate's source revision.

For hosted CI candidates, also set `GITHUB_RUN_ID`, `GITHUB_RUN_ATTEMPT` and
`GITHUB_REPOSITORY` from the candidate manifests. The evidence checker compares
these fields with [`currentIdentity`](../../scripts/release_evidence.mjs).
Their local defaults (`0`, `0`, `local/hermes-wing`) do not match hosted CI evidence.
The candidate checkout supplies app version/build and dependency input digests.
Inspect the [exact input allowlist and receipt limits](../quality/2026-10-06-m6-artifact-evidence.md#exact-verifier-input-allowlist)
before admitting a candidate. Offline comparison does not authorize execution.

The verifier requires `GITHUB_SHA` and the public signing-certificate fingerprint.
It also requires the listed host tools and executable `apksigner`, supplied through
`APKSIGNER` or discovered under `ANDROID_HOME`. Inspect the script's prerequisites
before execution. It extracts and launches candidate Linux and web artifacts and
writes a verification receipt into the candidate directory. Run it only where
candidate execution is authorized; it is not a read-only documentation check.

```bash
GITHUB_SHA='<candidate source commit: 40 lowercase hex characters>' \
WING_RELEASE_CERT_SHA256='<public certificate fingerprint>' \
  npm run release:verify-artifacts -- dist v0.1.0-alpha.1
```

The tag above is an example, not the current app version. Replace it with the
candidate tag. A passing host gate exits 0 and writes
`dist/release-verification-receipt.json`. This does not complete the workflow's
separate Android emulator, Windows or macOS smoke jobs, or authorize publication.
