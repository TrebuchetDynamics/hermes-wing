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

## Current controls

- Bearer credentials are excluded from pairing QR payloads and ordinary
  preferences; Wing Link and Agent credentials are separate.
- Wing Link uses fixed operations and argument vectors, no shell, bounded input
  and output, and pending-token acknowledgment before mutation.
- Profile compatibility delegates list/create/rename/delete to Hermes CLI without
  retaining a shadow profile inventory.
- Plain non-loopback HTTP requires explicit warning; remote deployments should use
  HTTPS or an encrypted VPN.
- Diagnostics redact credentials, authorization headers, transcripts, and paths.
- Reconnect refreshes authoritative state; Wing does not queue or replay mutations.
- Capability checks keep unsupported operations hidden or explicitly unavailable.

## Required controls for planned remote management

### Directories and Projects

- Directory roots are granted locally, stored owner-only, and revocable.
- Remote APIs use opaque handles; clients cannot submit absolute paths or `..`.
- Every lookup revalidates canonical containment and blocks symlink escape.
- Listings contain child folders only—never regular file names, metadata, or
  contents—and are bounded, paginated, and path-redacted.
- A selected directory becomes an Agent-owned per-profile Hermes Project; Wing
  Link stores no duplicate profile-to-path mapping.

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

## Known gaps

- No independent penetration test or formal privacy review.
- No shipped directory/project or existing-profile configuration API. A
  new-profile description, allowlisted provider, bounded model string, and
  credential may be supplied only through the transactional bounded Wing Link setup operation;
  credential bytes reach Hermes only through stdin.
- Current persistent Wing Link service management is Linux/systemd-user only.
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
