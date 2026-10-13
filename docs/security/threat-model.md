# Hermes Wing threat model

Status: alpha baseline; not an independent security assessment

## Assets

- Agent API/provider credentials and native SSH authentication
- profiles, Projects, sessions, approvals, transcripts and saved owner identities
- platform secure storage and inert legacy records/credential slots
- release signing identity, application artifacts, microphone input and speech

## Trust boundaries

1. Hermes Wing device: UI state, native chooser and platform secure storage.
2. Network: direct authenticated Agent transport; private addresses grant no authority.
3. Hermes Agent: authoritative domain state, capabilities and concurrency.
4. Operating system: keychain/keystore, native SSH, speech, files and logs.
5. Android/Termux: Wing and Termux remain separate app sandboxes; any local app
   may probe loopback, so Agent authentication remains mandatory.

Wing Link client/service/installers and delivery operations are removed. Existing
personal installations and raw user data are untouched; this does not prove their
uninstallation or revoke their credentials. Missing former management operations
stay unavailable, rather than becoming a shell bridge or unauthenticated API.

## Current controls and adversarial cases

- Origin-bound credentials and HTTPS certificate validation prevent cross-origin
  reuse; changed native SSH fingerprints fail closed.
- Non-local Agent HTTP requires explicit consent on an authenticated encrypted
  VPN or isolated trusted LAN. Network location is not authorization.
- Secrets use platform secure storage, never URLs, QR, clipboards, ordinary
  preferences, argv, responses, diagnostics or logs. Provider secrets are write-only.
- Saved endpoint/profile/session identities survive upgrade. Missing Agent
  credentials require direct reauthentication; no recovery through old management.
- Retired handoffs used a single-use pairing code expiring after five minutes,
  which never contains a bearer credential, with a no-store handoff page. Legacy
  inputs are now discarded without parsing, exchange, logging, display or persistence.
- Local discovery reads only directory metadata. Chooser cancellation does not
  read credentials, change a Project, install/start Agent or claim readiness.
- Exact operation, grants, resource identity and owner/generation fences reject
  denied capabilities, stale-owner responses and changed-origin credential reuse.
- Reconnect reads authoritative state; no send, approval or configuration replay.
- Diagnostics redact credentials, paths, private endpoints, transcripts and content.
- Release checks retain exact inventory, bounded digests, signature checks and
  safe archive extraction. Fixtures never establish native/runtime qualification.

## Known gaps

No independent penetration test or formal privacy assessment has been performed.
Project assignment, host lifecycle, directory grants and peer administration remain
unavailable without individually verified Agent contracts. Native/device/live
connection, microphone/acoustic, signing and distribution qualification remain
separate from deterministic tests; deleting a service does not close those gaps.

## Incident response

Rotate affected Agent credentials through the authoritative host procedure,
reduce remote exposure, preserve only redacted evidence and report privately via
[SECURITY.md](../../SECURITY.md). Never include credentials, transcripts, provider
keys, pairing input or private paths in a report.
