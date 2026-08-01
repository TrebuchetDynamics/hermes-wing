# Changelog

All notable user-visible changes will be documented here.

## Unreleased

### Changed

- Removed duplicated page headings and counts left by the last audit: the
  Providers and Office bodies no longer repeat the page title, the Office hero
  no longer repeats the agent count, and the Tools page drops its redundant
  second scope description.
- The Voice & speech Advanced section shows one heading instead of a card
  title stacked on an identical expander title.
- The "Speak replies aloud" setting now says what it actually does: it is
  the hands-free voice consent, and the chat's hands-free switch turns it
  on and off. The Pocket Speech replies toggle now names that setting
  exactly instead of "Speak assistant replies".

- Unified the gateway-scoped screens (Agents, Providers, Tools, Schedules, Gateway) behind one empty-state pattern, and showed a neutral "Select a gateway" prompt instead of misleading unavailable/lock copy when no gateway is selected.
- Replaced the microphone icon on the Settings tab with a settings icon, removed duplicated headings on the Tools page and the Settings diagnostics row, tinted skill category tags, and colored the diagnostics connection-status dot by state.
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
- Added context-aware first-run tips: where administration lives (with the phone navigation bar), how voice dictation works (first connected chat), and how approvals work (first approval request). Each tip shows once and stays dismissed.
- Softened navigation with a motion-free 200 ms fade between destinations, and replaced full-screen loading spinners on Office, Agents, Providers, Tools, Schedules, and Gateway with pulsing skeleton lists that keep their spoken loading labels and freeze under reduced motion.
- Announced hands-free voice state to assistive technology instead of showing it only visually, and bounded TTS and microphone-cancel failures so the voice loop recovers cleanly.

### Security

- Excluded recognized words from speech diagnostics.
- Required explicit confirmation for API keys sent over remote plaintext HTTP.
- Documented platform-dependent secure-storage guarantees and trust boundaries.
- Enforced declared operator-token scopes fail-closed across session mutations, transport selection, scheduled-job reads, and gateway health reads.

## 0.1.0

Initial experimental Hermes Agent client baseline. No signed public release was
published.
