# Hermes Wing threat model

Status: alpha baseline; not an independent security assessment

## Assets

- Hermes Agent and Wing Link credentials
- provider keys and setup secrets
- profiles, projects, sessions, approvals, and transcripts
- approved host folder names and opaque directory handles
- runtime installers, service control, and release identity
- microphone input and speech transcripts

## Trust boundaries

1. **Hermes Wing device** — UI state and platform secure storage.
2. **Network** — two authenticated connections: direct Agent data and Wing Link
   management. Private address space is not an authorization boundary.
3. **Hermes Agent** — authoritative agent and project state.
4. **Wing Link host process** — privileged management and approved filesystem
   access on the Agent host.
5. **Operating system** — keychain/keystore, speech, files, services, and logs.
6. **Android/Termux boundary** — Wing and Termux remain separate app sandboxes
   sharing only authenticated loopback sockets. Any local app may probe loopback,
   so network location never replaces Agent or Wing Link authentication.

## Current controls

- A pairing handoff may carry a random single-use pairing code in a QR code,
  `wing://connect` intent, explicit Android share, or the ephemeral local handoff
  page, which must use `Cache-Control: no-store`. The code expires after
  five minutes, never contains a bearer credential, and must not be persisted,
  analyzed, included in diagnostics, or written to ordinary logs.
- Explicit paste is a user-initiated fallback, not background clipboard
  monitoring; the app drops the raw text immediately after parsing.
- The release-pinned Android bootstrap command is non-secret. Provider
  credentials and pairing codes never enter the command, argv, or installer logs.
- Hermes API keys, Wing Link control tokens, provider credentials, and exchanged
  bearer credentials remain forbidden in URLs, QR payloads, clipboards, shared
  text, command arguments, and ordinary preferences. Wing Link and Agent
  credentials remain separate.
- Wing Link uses fixed operations and argument vectors, no shell, bounded input
  and output, and pending-token acknowledgment before mutation.
- Profile compatibility delegates list/create/rename/delete to Hermes CLI without
  retaining a shadow profile inventory.
- HTTP is loopback-only. Non-loopback Wing Link uses TLS 1.3 and native clients
  pin the durable host identity's SHA-256 SPKI fingerprint; browsers require a
  normally trusted certificate.
- Named device credentials have exact scopes and independent revocation. A remote
  device can inspect and revoke only itself; the host console administers trust.
- Sensitive operations consume a short-lived local approval bound to requester,
  route, idempotency key, and payload digest. Changed payload replay is rejected.
- Diagnostics and bounded local audit events redact credentials, authorization
  headers, pairing codes, transcripts, and paths and never retain request bodies.
- Reconnect refreshes authoritative state. Wing does not queue mutations offline;
  explicit retries replay the same durable operation instead of executing twice.
- Current/previous protocol negotiation keeps stale or future operations hidden or
  explicitly unavailable.

## Required controls for remote management

### Directories and Projects

- Directory roots are granted locally, stored owner-only, and revocable.
- Remote APIs use opaque handles; clients cannot submit absolute paths or `..`.
- Every lookup revalidates canonical containment and blocks symlink escape.
- Listings contain child folders only—never regular file names, metadata, or
  contents—and are bounded, paginated, and path-redacted.
- Browsing state and handles are ephemeral and are not persisted by Wing.
- Project creation remains unavailable until Hermes Agent advertises an explicit,
  machine-readable operation. Wing Link stores no duplicate profile-to-path mapping.

### Providers and configuration

- Provider/config fields are allowlisted and typed; arbitrary keys are rejected.
- Provider credentials are write-only and never returned or logged.
- Secret mutation must not place values in process arguments or edit `.env`
  directly; it remains blocked until Hermes provides a safe contract.
- Reload/restart is separately confirmed and health-verified.

### Authorization

- Separate scopes cover reads, mutations, secret writes, lifecycle, root grants,
  and directory browsing.
- Destructive actions require fresh confirmation and stable resource identity.
- Revocation takes effect without deleting Agent profiles, Projects, or host data.
- No route accepts arbitrary commands, executables, URLs, config keys, or paths.

### Adversarial cases

- **Stolen device:** revoke that named credential locally without rotating peers;
  its self-revoke route cannot affect other devices.
- **LAN impersonation:** TLS and the reviewed SPKI pin fail before response parsing;
  network locality grants no authority.
- **Host-key loss or rotation:** stored pins fail closed and users must perform a
  new explicit pairing review. Identity is never silently replaced.
- **Stale or future client:** protocol negotiation permits only N/N-1 and returns a
  typed upgrade requirement before mutation.
- **Approval replay:** approval and operation records bind device, route, revision,
  idempotency key, and payload digest and are one-use or terminal.
- **Audit injection:** events use allowlisted enums and bounded sanitized strings;
  callers cannot append generic request data.
- **Update compromise:** catalogs require an approved Ed25519 key and artifacts
  require exact size and SHA-256. Failed restart/health restores `previous`; an
  empty trusted-key set disables updates before network access.

## Known gaps

- No independent penetration test or formal privacy review.
- Approved folder browsing is shipped, but Project creation, Project-aware Chat,
  and existing-profile configuration remain unavailable. A new-profile
  description, allowlisted provider, bounded model string, and
  credential may be supplied only through the transactional bounded Wing Link setup operation;
  credential bytes reach Hermes only through stdin.
- Qualified persistent Wing Link service management is Linux/systemd-user only.
  Android/Termux foreground and detached processes are Tier 2 best-effort and may
  be suspended or killed by Android.
- Public signed packages, desktop signing/notarization, and authenticated updates
  are incomplete.
- Current Hermes Agent 0.20 does not advertise Wing's proposed scoped enrollment,
  profile HTTP administration, or HTTP audio routes.
- Physical microphone, echo cancellation, and barge-in require device evidence.

## Incident response

Rotate affected credentials, revoke Wing Link directory grants, stop remote
exposure if needed, preserve only redacted evidence, and report privately through
[SECURITY.md](../../SECURITY.md). Never include credentials, transcripts, provider
keys, pairing codes, or private paths in a report.
