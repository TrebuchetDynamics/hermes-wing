# Changelog

All notable user-visible changes will be documented here.

## Unreleased

### Fixed

- The internal native-web lifecycle adapter now retires withdrawn approval
  requests even when no local turn is running. This is a qualification-adapter
  correction, not enabled production transport or live approval support. See the
  [design boundary](docs/spec.md#approval-withdrawal-in-the-internal-lifecycle-adapter)
  and [remaining checks](docs/test-plan.md#idle-approval-withdrawal-regression).

- Optional Local setup no longer starts inspection or setup after its controller
  is disposed. Teardown cancellation errors cannot leak into a replacement route.
  The [recovery receipt](docs/quality/local-setup-recovery.md) records focused tests
  and compiled browser fixtures, not actual installation or live authentication.

- Chat now recognizes the transport's safe network error when history pagination
  fails, so the current owner can deliberately reconnect. The
  [two-host recovery receipt](docs/quality/two-host-recovery-native.md) records
  saved-host identity collision and retry checks in Linux GTK fixtures, plus
  widget and Chromium regressions. Live authentication, managed SSH and
  protected-main delivery remain separate.

### Added

- Native SSH now offers consent-based Ed25519 key generation, reuse of an app-owned
  secure-storage key and public-only copy. Local entry adds Linux Hermes-home
  discovery and Android This phone guidance; connection Help is selectable and
  copyable. The [parent receipt](docs/quality/connection-key-generation-help.md)
  records 132 focused tests and clean analysis, not native storage, live SSH or
  an APK delivery.

- Remote HTTPS and VPN now explain Agent-token authentication and unsupported
  browser OAuth before submission and after denial. Guidance is selectable and
  keyboard reachable; enlarged-form scrolling preserves Back traversal. The
  [bounded receipt](docs/quality/remote-auth-explanation.md) records widget and
  Linux GTK fixture checks, not live authentication or delivered OAuth support.

- Fresh launch now shows a Desktop-guided welcome before the connected shell:
  settled emblem, Get Started for Local and separate SSH/Remote actions. Saved
  ownership bypasses welcome; unreadable storage stays explicit and retryable.
  Optional setup remains secondary. The [welcome receipt](docs/quality/desktop-welcome.md)
  records widget/Chromium qualification. Welcome-entry forms now retain keyboard
  Back after enlarged-text scrolling. The [recovery receipt](docs/quality/desktop-welcome-recovery.md)
  adds isolated Linux GTK retry and process restoration, not Android, physical
  keychain, live authentication or main delivery. Local requires a running Agent;
  SSH now uses Wing-managed forwarding with explicit key/password selection.

- Add Hermes now offers **Edit saved Agent connection**. An independent draft
  supports masked credential replacement/removal, read-only discovery Test,
  explicit Save and Cancel without changing the active conversation. Save retains
  the original connection ID and rejects duplicate URLs. Changed Agent identity
  drops management trust. See the [bounded editor evidence](docs/quality/saved-endpoint-edit.md):
  widgets and compiled Chromium pass; native/live and main delivery remain separate.

- Chat **Add Hermes** now opens the direct Agent form. Enrollment offers it before
  **Optional setup and pairing**, so direct Local/SSH/Remote entry does not require
  Wing Link. The [first-run receipt](docs/quality/direct-first-run.md) records Linux
  widget/Chromium qualification. The [native first-run receipt](docs/quality/direct-first-run-native.md)
  adds Linux GTK fixture evidence; live authentication, Android and main delivery remain open.
  SSH now supports attempt-scoped private-key selection, encrypted-key passphrases
  and password fallback. Reads are bounded and stale picker results are fenced.
  Native Linux/Android full-app qualification remains open.

- The desktop sidebar now remembers its local collapse/expand choice. Late loading
  cannot replace a newer click, and preference writes retain interaction order.
  Storage failures leave the in-memory choice usable. See the
  [widget qualification](docs/quality/graphify-shell-persistence.md); native process
  relaunch remains unqualified. No Agent or profile state is stored.

- Android private release testing now has an opt-in `.qa.release` app identity.
  It requires configured signing and remains separate from the paired app and
  debug QA installation. See the [private APK handoff](docs/runbooks/android/release-handoff.md#private-release-apk-handoff).
  Artifact checks do not establish device qualification or store readiness.

- Single and grouped Chat tool-summary titles now wrap at enlarged text sizes.
  The [bounded accessibility receipt](docs/quality/chat-transcript-accessibility.md)
  records keyboard disclosure and current-approval access through fixture recovery
  at 200% scaling/zoom. The later [native subset](docs/quality/native-transcript-recovery.md)
  records four Linux GTK fixture cases. Process restart, live Agent, physical input
  and screen-reader behavior remain unqualified.

- Sessions and Ctrl/Command+K now open the existing owner-bound session panel
  over feature routes. Loaded search adds no reads; pagination and management
  keep their exact gates. Keyboard focus stays inside and returns on Escape/Close.
  Activation navigates after exact-session acknowledgement; stale owners cannot
  navigate or replay mutations. See the
  [bounded modal evidence](docs/quality/global-session-modal.md), not native/live
  or screen-reader qualification.

- Chat reasoning summaries now distinguish **Thinking…** from **Thought**.
  Keyboard users can open and collapse the disclosure without completion stealing
  its focus. Reduced motion uses static activity chrome; selectable redacted content
  remains intact. See the [bounded implementation receipt](docs/quality/reasoning-disclosure-implementation.md);
  the later [recovery receipt](docs/quality/reasoning-disclosure-recovery.md) qualifies
  deterministic eviction/remount and read-only reconnect. HTTP history does not
  restore transient reasoning. The [adaptive receipt](docs/quality/reasoning-disclosure-adaptive.md)
  qualifies compact/wide keyboard return under reduced motion; native and full
  transcript parity remain unqualified.

- The desktop sidebar groups loaded sessions by source, preserving group and row
  order with named headings and exact-owner keyboard Open/New actions. Grouping
  adds no reads, persistence or disclosure controls. This is not Project/folder
  grouping. See the [bounded delivery evidence](docs/quality/grouped-recents-implementation.md).

- The desktop sidebar now keeps a passive current-profile footer below navigation
  in expanded and compact modes. **Manage profiles** supports pointer and keyboard
  navigation without changing the selected profile or reading inventory. Labels
  are redacted and bounded; edit/switch controls remain gaps.
  See the [bounded footer evidence](docs/quality/profile-footer-implementation.md).

- Wide Chat now exposes **Dictate a draft** beside attachment, with keyboard
  activation and an explicit cancel action. Results remain drafts; hands-free
  and Send stay separate. Owner/gate changes reject stale capture results.
  Cancellation discards recognition rather than finalizing it. See the
  [bounded delivery evidence](docs/quality/chat-direct-dictation.md) for browser
  capture limits and the required model-selection predecessor.

- A read-only source-checkout tool compares release candidate bindings with
  independent identity and public certificate expectations. It rejects missing or
  changed evidence without executing or writing candidate files. Signature and
  runtime qualification remain separate; see the
  [offline comparison runbook](docs/runbooks/offline-release-candidate-comparison.md).

- Wing Link can run as a persistent Linux user service with separate direct
  Hermes and acknowledged management credentials. Its private/VPN profile API
  merges Hermes-advertised rows with validated local profiles and supports
  revisioned create/clone/rename/delete without proxying Hermes traffic.
- The Profiles directory now supplements Hermes API contacts with every local
  Wing Link profile and labels topology-only rows as management-only.

### Fixed

- Desktop status fields now expose complete labeled values through keyboard
  inspection instead of truncation alone. Compact More shows wrapping status and
  updates when the current connection changes. Values remain redacted. See the
  [bounded Linux GTK evidence](docs/quality/native-status-accessibility.md).
  Live authentication, screen readers and main delivery remain separate.

- Saved Agent connection guidance and Test/Save outcomes now remain complete and
  keyboard-readable at enlarged text sizes. New outcomes receive visible focus
  and scroll into view; keyboard paging reaches longer notices. See the
  [widget and Linux GTK fixture evidence](docs/quality/saved-endpoint-feedback-accessibility.md).
  Screen readers, real-storage requalification and main delivery remain separate.

- Remote Add Hermes now separates connection success from confirmed persistence.
  Uncertain saves retain the connected draft and require explicit retry; obsolete
  consent and late storage results cannot mutate a replacement owner. See the
  [bounded retry evidence](docs/quality/remote-connection-retry.md). Native secure
  storage and live authentication are not qualified by the fixture checks.

- The shared session panel now keeps controls and rows keyboard-reachable at
  compact widths, short heights and enlarged text. Title/New stack when needed;
  focused controls scroll into view after layout and resize. Close stays separate.
  See the [bounded adaptive evidence](docs/quality/global-session-modal-adaptive.md),
  not native/live or screen-reader qualification.

- Chat saved-host rename/remove dialogs now reject consent from an obsolete
  connection owner. Late storage completion cannot clear a replacement draft;
  failures show generic errors and require explicit retry. Removal forgets only
  the device-local endpoint, not remote Agent data. See the
  [bounded regression evidence](docs/quality/saved-connection-owner-safety.md).

- The global session panel now retries only the history read when New has already
  acknowledged a session. Retry does not create a second session. Unacknowledged
  creation failure still has no generic replay; stale owners cannot retry or navigate.
  See the [bounded recovery evidence](docs/quality/global-session-modal.md#independent-review-correction-new-recovery).

- Reconnected Chat now retains persisted tool-result activity in canonical order.
  Recovered rows show category-only completed activity without tool content, preview
  or result. Recovery does not replay approval or Send actions. See the
  [bounded reconnect evidence](docs/quality/chat-transcript-reconnect.md); historical
  tool success/failure and unfinished-tool recovery remain unqualified.

- Chat filters pending approvals by their explicit profile identity both when
  displaying them and before answering. Reused profile-local session IDs no longer
  expose or activate another profile's request. Nullable-profile compatibility is
  unchanged. See the [bounded regression evidence](docs/quality/chat-transcript-order.md).

- Reasoning disclosure keeps its visible body consistent with expanded semantics
  when adaptive layout remounts the inner tile. Expansion survives compact/wide
  return; keyboard users can reach the replacement summary after old focus releases.
  See the [bounded adaptive evidence](docs/quality/reasoning-disclosure-adaptive.md).

- Chat no longer preselects a catalog default when the session's confirmed
  provider/model pair is unknown. Use for session requires an explicit choice;
  cancelling leaves the session unchanged. Exact-pair restoration remains
  unsupported by the inspected Agent reads. See the
  [bounded delivery evidence](docs/quality/session-model-pair-read.md).

- Declared history operations now require the exact method/path, supported schema,
  required grants and supported profile context before hydration or pagination.
  Denial retains unresolved ownership and refuses Send; supported legacy documents
  may still omit the baseline advertisement. See the
  [bounded implementation evidence](docs/quality/2026-10-06-m2-history-admission.md).

- History pages now reject unrelated or malformed session identities before
  transcript publication or recovered-run settlement. Compaction history requires
  fresh Agent lineage evidence; rejected reads retain durable ownership. See the
  [bounded implementation evidence](docs/quality/2026-10-06-m2-history-identity.md).

- Ambiguous run-status HTTP 404 no longer clears detached-run ownership or
  releases the duplicate-Send guard. Retry and channel recreation retain the
  exact lease until authoritative status and canonical history resolve it.
  History identity and declared history-grant gaps remain separate; see the
  [bounded repair evidence](docs/quality/2026-10-06-m2-ambiguous-404.md).

- Rapid session-pin changes in one Chat store no longer allow an older pending
  preference commit to overwrite the latest settled choice. Writes are serialized
  and waiting choices are coalesced; failed persistence remains best-effort, with
  no automatic retry or cross-instance durability guarantee. See the
  [repair evidence](docs/runbooks/chat-session-pin-write-order.md).

- Failed Hermes runs now show the redacted server or provider reason inline
  instead of repeating only “Hermes run failed.”
- Gateway status now has an explicit Disconnect action that closes the active
  connection without deleting the saved gateway or API key.
- Invalid or incomplete pairing links now offer manual gateway setup instead
  of leaving QR scanning as the only recovery path.
- Chat contacts now prefix every profile name with its gateway, so duplicate
  profiles such as “Default profile” remain distinguishable.
- Connected gateways now show their basic `/health` result when detailed health
  is unsupported or temporarily fails, instead of appearing unavailable, and
  active saved gateways can be renamed directly from the gateway screen.
- Run failures now recover redacted string, structured, and legacy failure
  details from pollable status; usage-limit and HTTP 429 errors prompt operators
  to switch provider or model instead of offering a futile retry.
- Fresh installs can open manual gateway setup instead of looping back to the
  empty agent directory.
- One-shot Speak capture now restores the live input waveform instead of
  replacing it with a static stop icon.
- Voice input now fails closed when local recognition cannot be guaranteed:
  browser STT and the transcript-logging Windows adapter are disabled, while
  Android requires an on-device recognizer before capture starts instead of
  allowing the plugin's network-capable fallback.
- Cancelling voice input now completes the active capture even when the speech
  engine emits no terminal event, and setup failures always release the mic.
- Stopping TTS during configuration or offline synthesis no longer allows late
  audio or a delayed fallback voice to start after pause or navigation.
- Android 11+ builds now declare TTS engine discovery, so continuous voice can
  speak Hermes replies and re-arm when an installed engine is available.
- Voice capture now says when the device has no offline language for speech
  recognition, instead of advising you to install a recognizer that is already
  installed. Wing asks Android for on-device-only recognition, so a missing
  language pack fails every capture, and Android reports that case distinctly.

- Hermes connection errors no longer show local filesystem paths. The chat
  transcript and diagnostics export already stripped them, but the channel's
  own redaction did not, and Agents, Providers, and Diagnostics render that
  text verbatim.
- Speech-to-text no longer strands the microphone. When Android's recognizer
  reported no speech and left its cancel pending forever, the capture timeout
  never fired: the mic spun indefinitely, no transcript arrived, and no error
  was shown. The timeout now stops waiting on the engine cancel, so capture
  always ends with a transcript or an actionable error.

### Changed

- Enlarged text no longer changes the supported composer's keyboard command order.
  Compact Send/microphone switching has no transition under reduced motion.
  See the [bounded accessibility receipt](docs/quality/chat-composer-accessibility.md)
  for text-only widget scaling, Chromium zoom and remaining qualification limits.

- Grouped Chat and Add Hermes connection entry into Local, SSH and Remote, retaining
  VPN within Remote. Existing labels and external-tunnel instructions remain;
  Wing does not manage SSH. See the
  [bounded entry evidence](docs/quality/connection-primary-entry.md).
  This earlier entry predates the native managed-forward implementation under
  Added. External-tunnel instructions are no longer the native SSH onboarding path.

- Removed Wing-managed OmniRoute installation, discovery, bundled dependencies
  and special profile setup. Existing external installations, credentials and
  Agent configuration remain untouched. Generic Agent catalog entries remain
  visible. The [historical dependency review](docs/quality/omniroute-install-review.md)
  retains earlier pin repairs and failed audits; removal does not qualify the
  remaining dependency or release gates.

- Matched the wide shell to the pinned Hermes Desktop sidebar palette, density,
  collapse control and status strip. Keyboard focus remains visible in both themes;
  compact navigation is unchanged. Later slices add a passive profile footer and
  source-grouped recents; complete shell parity remains a separate gap. See the
  [delivery boundaries](docs/runbooks/desktop-shell-reference-fidelity.md).

- The composer mic once again sends and speaks one turn; hands-free re-arming
  remains a separate switch. Desktop hands-free mode now shows the same live
  transcript, waveform, and stop surface as mobile, and voice errors are
  announced to assistive technology.
- Pocket Speech now routes Spanish replies to a selected Spanish Kokoro voice,
  advertises its English and Spanish coverage accurately, installs model/voice
  updates as one directory transaction, and stops previews when Settings closes.
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
- A running offline-voice preview can now be stopped: the spinner is a
  "Stop preview" button while the sample plays.
- Long-pressing the mic dictates into the composer for review instead of
  sending immediately, restoring the review-first path the voice tip and
  README promise; the tip now describes both gestures.

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

- Consolidated credential and local-path redaction into one implementation
  shared by the Hermes channel, the chat surfaces, and the diagnostics export.
  The three copies had already drifted once; every path now applies the union
  of their rules, so a pattern added later covers all of them.

- Excluded recognized words from speech diagnostics.
- Required explicit confirmation for API keys sent over remote plaintext HTTP.
- Documented platform-dependent secure-storage guarantees and trust boundaries.
- Enforced declared operator-token scopes fail-closed across session mutations, transport selection, scheduled-job reads, and gateway health reads.

## 0.1.0

Initial experimental Hermes Agent client baseline. No signed public release was
published.
