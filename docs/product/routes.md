# Routes

Hermes Wing uses one adaptive route tree. Android currently keeps Chat, Profiles, and Settings in the compact bottom bar and places working administrative slices in More; desktop layouts map the same routes to a navigation rail. Routes are added with working vertical slices, so approved entries may remain planned until their capability lands.

| Route          | Android placement | Purpose                                                                                                                                                                                                                                                                                            | State       |
| -------------- | ----------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------- |
| `/hermes`      | Chat              | Connection, paginated Agent-owned session and transcript history, runs, voice, approvals, and diagnostics.                                                                                                                                                                                          | implemented |
| `/discover`    | Discover          | Skills and MCP discovery.                                                                                                                                                                                                                                                                          | planned     |
| `/office`      | More              | Accessible 2D workspace over authoritative gateway contacts with search, refresh, status/session counts, and exact contact activation into Chat; representative, account/wallet, and desktop 3D interactions remain gated.                                                                         | partial     |
| `/tasks`       | More              | Gateway-scoped scheduled-job inventory with refresh and recovery. Agent mutation routes are not yet advertised as exact scoped operations, so create/edit/pause/run/delete controls and Kanban remain hidden.                                                                                                                                                                  | partial     |
| `/profiles`    | Profiles              | Profile inventory and lifecycle, Agent-backed provider/model autocomplete through Wing Link during setup, plus approved child-folder browsing through device-bound opaque handles (`/agents` redirects for compatibility). Project creation remains unavailable until Hermes Agent advertises a suitable machine-readable operation; Project-aware Chat is separately gated. | partial     |
| `/soul`        | More              | Standalone profile persona editor, available only when the selected Agent advertises exact scoped SOUL read/write operations.                                                                                                                                                                  | partial     |
| `/enroll`      | (deep link)       | Guided phone/computer setup, QR/link pairing, transaction recovery, and endpoint-bound readiness checks outside the shell; advanced manual connection remains available within pairing.                                                                                                                                                                                                                                               | implemented |
| `/setup/local` | enrollment        | Platform-specific guided local setup: qualified Linux service flow or unqualified Android/Termux Tier 2 explicit bootstrap; no command bridge.                                                                                                                                                     | partial     |
| `/providers`   | More              | Capability-gated provider inventory, write-only API-key management, credential validation, runtime-model inventory, and model assignment through advertised Agent operations. OAuth providers are labeled as host sign-in rather than opening an API-key form; remote OAuth and multi-credential flows remain contract-gated.                                                            | partial     |
| `/tools`       | More              | Gateway-scoped searchable installed-skill metadata and resolved toolsets with exact-scoped refresh; mutation, MCP administration, and discovery remain contract-gated.                                                                                                                             | partial     |
| `/memory`      | More              | Memory entries, profile, capacity, and providers.                                                                                                                                                                                                                                                  | planned     |
| `/gateway`     | More              | Gateway-selected bounded health, saved-connection rename/removal, and paired-device trust/revocation for the current device; lifecycle, logs, peer administration, and messaging-platform administration remain contract-gated.                                                                      | partial     |
| `/settings`    | Settings          | Saved gateway management, appearance, supported spellcheck, voice, and redacted diagnostics; also selected by Ctrl/Command+, and bounded Linux/Windows/macOS native Settings menu commands.                                                                                                        | implemented |

Profile switching and session history remain directly reachable from Chat. More is an action sheet, not a route.

Oversized single-line plain paragraphs use a lazily rendered, grapheme-safe
reader. Selection operates on mounted chunks; use its **Copy as text** action
for an exact full-source copy without chunk boundaries. Markdown-rich messages
keep their existing rendering. This does not qualify arbitrary large Markdown
or 60-fps streaming; see the
[Linux large-text validation report](../quality/linux-e2e-2026-09-06.md#plain-line-performance-fix).

While a profile switch is pending, Send and New Chat are disabled and the current
draft is retained. Conversation operations reject writes during that transition;
late responses from a previous profile selection cannot overwrite the new one.

New Chat stops targeting the previous session as soon as creation starts. Sending
is unavailable until the new session's initial history request finishes. Delayed
creation or session-selection responses must respect a later selection; a created
session remains discoverable in history without taking over the current chat.

Session history refreshes preserve turns that arrive while a read is pending.
Superseded selection responses are rejected before updating transcript, pagination,
or run-history caches, so an invisible stale read cannot change the next prompt's
loaded context.

Computer enrollment now completes host installation and pairing before provider
configuration. A confirmed Wing Link pairing offers **Set up a profile**, opening
`/profiles?setup=new` and the transactional new-profile editor after the selected
host's authenticated profile inventory loads. The editor collects provider,
model, and a write-only credential; any required approval remains on the host.
Opening or cancelling it does not create a profile. Existing-profile compatibility
configuration remains unavailable; advertised Agent configuration APIs retain
priority. Wing Link profile management is independent of the Agent chat
connection, while chat still requires a separately enrolled Agent endpoint.

Settings keeps voice configuration on `/settings/voice`, reached through the
**Voice & speech** row. The overview contains gateway management, appearance,
and links to voice and diagnostics; it does not duplicate the voice switches.
At desktop widths, voice and diagnostics share the column beside appearance.
Profile setup suggestions open toward the available space so options remain
reachable near the bottom of a window or keyboard viewport.
