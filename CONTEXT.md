# Hermes Wing Context

Hermes Wing is an independent cross-platform Flutter client for Hermes Agent, inspired by Hermes Desktop and adapted for mobile, web, and desktop. Product language, routes, tests, and docs should describe Hermes endpoints, Hermes sessions, Hermes runs, local device speech-to-text, approvals, tool progress, and platform-gated administration.

## Product language

**Hermes Wing client**:
The independent Hermes Wing Flutter application across desktop, mobile, and web.
_Avoid_: companion, Electron clone

**Capability parity**:
Equivalent user outcomes across Hermes Desktop and Hermes Wing, using platform-native implementations and hiding host capabilities where a platform cannot safely provide them.
_Avoid_: line-for-line port, widget parity

**Planning baseline**:
Hermes Desktop 0.7.3 at its frozen commit, used to keep slice acceptance criteria stable during migration.
_Avoid_: latest Desktop, retirement target

**Retirement cutoff**:
The final named Hermes Desktop version and commit whose user-capability deltas must be reconciled before Electron support ends.
_Avoid_: planning baseline, moving target

**Electron retirement gate**:
The release criterion requiring frozen-baseline capability parity on Linux, Windows, and macOS before Hermes Desktop support ends. Android, iOS, and web do not satisfy or block this gate.
_Avoid_: Linux complete, route complete

**Host capability**:
A feature that manages the machine running Hermes, such as installation, local files, processes, SSH, gateway lifecycle, or application updates. Host capabilities may be desktop-only.
_Avoid_: universal client feature

**Hermes Agent authority**:
Hermes Agent owns profiles, configuration, memory, skills, tools, schedules, Kanban, sessions, and gateway state. Clients use advertised Hermes interfaces instead of reading its files, databases, or CLI output.
_Avoid_: duplicated client backend

**Profile-explicit control plane**:
One machine-scoped Hermes API service where every profile-owned operation identifies its Hermes profile and never falls back to global active-profile state.
_Avoid_: per-profile API port, implicit active profile

**Profile context**:
The validated Hermes profile ID carried as a mandatory `profile` query parameter on profile-owned HTTP and SSE operations, including the `default` profile.
_Avoid_: profile header, active-profile fallback

**Hermes event stream**:
A profile-scoped SSE feed of typed, resumable control-plane events with stable IDs and at-least-once delivery.
_Avoid_: Dashboard socket, generic realtime channel

**Hermes resource handle**:
An opaque, profile-bound server identifier for uploaded content, an approved same-host path, or a server workspace used by attachments and context folders.
_Avoid_: client path, raw filesystem reference

**Hermes One account service**:
The optional cloud authority for account identity, cloud-agent synchronization, and backend-managed wallets. It uses its own OAuth credential and is not a Hermes endpoint or Dashboard transport.
_Avoid_: Hermes Agent account API, second control plane

**Legacy local wallet**:
A profile-scoped wallet previously created or imported by Hermes Desktop and encrypted through Electron secure storage. It is migration data requiring guarded export, not a Hermes Wing wallet subsystem.
_Avoid_: Hermes Wing wallet, portable wallet store

**Host adapter**:
A platform-specific client boundary for bootstrap and machine integration, limited to installation, process lifecycle, SSH tunnelling, secure storage, filesystem selection, updates, and window behavior.
_Avoid_: domain service

**Managed Hermes runtime**:
An external Hermes Agent installation discovered or installed by a desktop host adapter and verified through health and capabilities. It is not embedded in the Hermes Wing application package.
_Avoid_: bundled Agent, Flutter backend

**Scoped operator token**:
A revocable Hermes bearer credential whose server-enforced read/write scopes limit an enrolled client by capability domain. The legacy API server key is a compatibility superuser credential, not the default Android credential.
_Avoid_: API key, UI permission

**Capability schema version**:
The small integer describing the shape of `/v1/capabilities`, independent of the Hermes Agent release version. An absent value means version 1.
_Avoid_: Agent version, API feature level

**Domain revision**:
An opaque version of one profile-bound administrative resource used with `If-Match` to prevent concurrent clients from silently overwriting each other.
_Avoid_: file timestamp, config version

**Apply disposition**:
The server-reported state of a saved administrative revision: already applied, requiring a scoped reload, or requiring an explicit drain and restart.
_Avoid_: save succeeded, automatic restart

**Stale snapshot**:
An in-memory read model retained after disconnect and visibly labeled with its last successful refresh time. It is never treated as authorization to replay a mutation.
_Avoid_: offline source of truth, sync queue

**Client-state import**:
An explicit, previewable, idempotent migration of allowlisted non-secret Hermes Desktop preferences and connection metadata. Existing Hermes domain state is adopted through the managed runtime; credentials require fresh authorization.
_Avoid_: automatic migration, Electron data copy

**Accessible equivalent**:
A semantic, fully operable path to the same state and actions without requiring 3D or canvas interaction, pointer input, speech, motion, sound, or color alone.
_Avoid_: accessibility fallback, read-only alternative

**Release authority**:
The platform store or Hermes Wing signing identity trusted to authenticate official artifacts and update metadata. HTTPS and adjacent checksums are transport and integrity aids, not release authority.
_Avoid_: download server, checksum file

**Analytics consent**:
An explicit local opt-in to a closed set of coarse product events. It is never inferred from the build, another client, an account, or an earlier installation.
_Avoid_: anonymous by default, configured means consented

**Baseline locale set**:
The twelve locale tags supported by frozen Hermes Desktop and required in Hermes Wing before Electron retirement, including complete RTL behavior for Arabic and Hebrew.
_Avoid_: translated generated content, English-only parity

**Portable profile archive**:
A versioned Hermes Agent export of one profile's portable domain state that excludes credentials, private paths, machine state, analytics identity, and legacy wallet material.
_Avoid_: HERMES_HOME zip, full backup

**SSH host identity**:
The canonical host, port, key algorithm, and SHA-256 fingerprint explicitly trusted for one desktop SSH endpoint and stored only in Hermes Wing-owned host-key state.
_Avoid_: accept-new, SSH credential

**Managed runtime release**:
An exact Hermes Agent version and platform artifact authenticated by signed release metadata before a desktop host adapter installs or activates it.
_Avoid_: latest main, install script URL

**Canonical package matrix**:
The signed AAB/APK, APT/RPM, MSIX, and notarized DMG formats that carry official Hermes Wing releases and retirement evidence.
_Avoid_: every Electron format, generic archive release

**Detached run**:
A server-owned Hermes run that continues while Android presentation and transport are suspended, then reconciles from authoritative state on foreground resume.
_Avoid_: background queue, foreground-service run

**Filesystem grant**:
A profile- and principal-bound Hermes resource handle created from an explicit same-host native-picker selection with bounded access and retention.
_Avoid_: saved path, folder permission

**Guarded wallet export**:
A local-only, one-wallet-at-a-time Hermes Desktop exit flow that verifies and reveals a legacy recovery phrase transiently or writes it in a passphrase-encrypted file.
_Avoid_: wallet migration, recovery sync

**Device authorization**:
The RFC 8628 system-browser flow that gives one native Hermes Wing installation a client-global Hermes One OAuth credential after browser approval.
_Avoid_: device enrollment, Hermes pairing

**Pairing code**:
A short-lived, single-use enrollment secret that authorizes one scoped-token exchange after the operator reviews the endpoint and requested scopes. It is not a bearer token and may travel in a QR or `wing://connect` payload.
_Avoid_: pairing token, API key

**Tasks**:
The client destination combining Hermes Kanban work and scheduled automations.
_Avoid_: Work, jobs dashboard

**Adaptive Office**:
One Office interaction model presented as an accessible 2D experience on mobile and an interactive 3D experience on desktop.
_Avoid_: mobile 3D clone, separate Office backend

## Route language

The implemented routes remain `/hermes` and `/settings` while parity slices add the approved topology. Android navigation uses Chat, Discover, Office, Tasks, and More; More opens administrative destinations rather than representing its own route. Desktop layouts map the same routes to a navigation rail.

- `/hermes` — Hermes Agent connection, sessions, chat, runs, voice transcript submission, approvals, stop controls, and diagnostics.
- `/discover` — skills and MCP discovery.
- `/office` — the adaptive Hermes Office experience.
- `/tasks` — Kanban and Schedules.
- `/agents` — profiles, persona, and profile administration.
- `/providers` — providers, models, and task-model overrides.
- `/tools` — toolsets and MCP administration.
- `/memory` — memory entries, profile, capacity, and providers.
- `/gateway` — gateway lifecycle and messaging platforms.
- `/settings` — local application and installation preferences.

## Endpoint language

Use **Hermes endpoint** or **Hermes Agent API server** for the trusted server. One endpoint profile identifies a canonical API origin and bearer credential for capability discovery, chat, and approved administration; do not expose Dashboard as a second client transport. Use **session** for the durable conversation lane. Use **run** for streamed work with events, approvals, and stop controls.

## Voice language

Use **voice input** for speech-to-text that requests on-device recognition and fills the composer for operator review. Use **continuous voice** only for the opt-in rearming loop that submits transcripts and speaks completed Hermes replies; do not imply an always-on audio stream. Use **Pocket Speech model** for the selected Kitten or Kokoro engine and **voice pack** for its downloaded model and voices resources.

## Transcript language

Use **rich transcript** for selectable GitHub-flavored Markdown in Hermes-authored replies, including code-copy controls. User messages remain plain text, external links use an allowlist, and remote transcript media stays deferred.

## Security posture

API keys, scoped operator tokens, and unredeemed pairing codes are secrets. Endpoint URLs are non-secret metadata but still operator-controlled. Prefer loopback or HTTPS; use plaintext LAN only inside a trusted encrypted VPN or isolated network after explicit confirmation. Authorization is enforced by Hermes Agent, not hidden controls alone. Secret administration may set or remove values but never returns raw secret values. Bearer tokens must not appear in URLs, QR payloads, shared text, logs, or clipboards. Do not log credentials, pairing codes, recognized words, or transcripts.

## Example

Developer: “Does capability parity require the mobile app to install Hermes locally?”

Owner: “No. Local installation is a host capability on supported desktop platforms; mobile reaches the same Hermes outcomes through a trusted remote endpoint.”

Developer: “Should Flutter parse Hermes configuration or Kanban storage?”

Owner: “No. Hermes Agent is authoritative; Flutter uses advertised interfaces, while host adapters only manage the surrounding machine.”
