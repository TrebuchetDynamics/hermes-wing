# Changelog

All notable user-visible changes will be documented here.

## Unreleased

### Changed

- Renamed the project and its internal identifiers to Hermes Wing.
- Reframed Hermes Wing as an alpha, source-distributed Hermes Agent client.
- Qualified platform, speech-recognition, privacy, and transport claims.
- Kept the active application shell Hermes-only.
- Reported optional Hermes inventory failures separately from empty results.
- Moved Hermes channel subscription and voice-loop effects out of widget build.
- Added verified Pocket Speech download progress, storage controls, voice selection, local preview, and reply-speed settings.
- Added in-app Android QR scanning for one-time `wing-cli` enrollment.

### Security

- Excluded recognized words from speech diagnostics.
- Required explicit confirmation for API keys sent over remote plaintext HTTP.
- Documented platform-dependent secure-storage guarantees and trust boundaries.

## 0.1.0

Initial experimental Hermes Agent client baseline. No signed public release was
published.
