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
- Added unified activity-ordered contacts across saved Hermes endpoints and profiles, with one active streaming channel, cached offline rows, and gateway management.
- Kept concurrent session-owned run streams attached across session and gateway switching, and reconciled detached runs after process recreation without duplicate submission.
- Added session history search, grouping, portable text/Markdown export, multi-select bulk deletion, capability-gated branching, and a redacted details sheet with token, cost, and lifecycle counters.
- Added read-only, scope-gated inventories: skills and toolsets with resolved tools, scheduled jobs, gateway health with messaging-platform states, and providers/models with a write-only credential sheet.
- Added the responsive 2D Office workspace over authoritative gateway contacts, with search and chat activation.
- Added per-gateway agent management and gateway switching from agent profiles.
- Added desktop keyboard shortcuts: Ctrl/Command+K for session history and capability-gated Ctrl/Command+N for session creation.
- Routed every screen's text through AppLocalizations, preparing the baseline locale set for translation.
- Expanded wing-cli with usage, version, model, skills, and persona commands plus polished help output.
- Added client-side model presets: save the current slot/provider/model combo under a name in the model picker, recall it with one tap, and delete it; presets stay on this device and are never sent to Hermes.
- Extended credential validation into a connection probe: the result now shows round-trip latency on success and failure, plus the provider's bounded model availability from the already-loaded catalog.
- Added a theme picker under Settings → Appearance: five palettes (Wing, Indigo, Forest, Amber, Mulberry), each with light and dark variants, plus a System/Light/Dark mode selector; the choice persists on this device.
- Announced hands-free voice state to assistive technology instead of showing it only visually, and bounded TTS and microphone-cancel failures so the voice loop recovers cleanly.

### Security

- Excluded recognized words from speech diagnostics.
- Required explicit confirmation for API keys sent over remote plaintext HTTP.
- Documented platform-dependent secure-storage guarantees and trust boundaries.
- Enforced declared operator-token scopes fail-closed across session mutations, transport selection, scheduled-job reads, and gateway health reads.

## 0.1.0

Initial experimental Hermes Agent client baseline. No signed public release was
published.
