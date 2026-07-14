# Navivox threat model

Status: alpha baseline, not an independent security assessment.

## Assets

- Hermes API keys, scoped operator tokens, endpoint identities, and Hermes One OAuth credentials
- Legacy local-wallet recovery phrases during guarded export
- Backup archives, recovery passphrases, archive handles, and restore checkpoints
- Session transcripts, prompts, tool activity, approval decisions, attachments, and context resources
- Microphone input and completed speech transcripts
- Local voice models and downloaded model metadata
- Device-backed signing keys used by Android pairing flows

## Trust boundaries

1. **Navivox process and local storage.** The app controls UI state and splits
   non-secret endpoint metadata from API keys stored through the platform
   secure-storage plugin.
2. **Operating-system services.** Speech recognition, keychain/keystore,
   backups, accessibility services, clipboard, and logs follow platform policy.
   Hardware backing is not guaranteed uniformly.
3. **Network path.** HTTPS authenticates and encrypts the remote path when
   certificates are valid. Loopback is local. Plain HTTP over LAN is observable
   and modifiable unless an external encrypted tunnel protects it.
4. **Hermes Agent server.** Hermes receives transcripts, messages, approvals,
   and API credentials and is trusted to enforce authorization, profile isolation,
   and tool policy through one machine-scoped service.
5. **Hermes One account service.** Optional account identity, cloud-agent sync,
   and backend-managed wallet operations cross a separate HTTPS boundary with
   an independent OAuth credential. Hermes chat does not depend on this service.
6. **Downloaded speech assets.** Pocket Speech assets are fetched only from
   HTTPS URLs and checked against configured SHA-256 digests.

## Current controls

- API keys, scoped operator tokens, and Hermes One OAuth credentials are not stored in shared preferences.
- Pairing payloads carry only short-lived, single-use codes; bearer tokens are excluded from URLs, QR payloads, shared text, logs, and clipboard flows.
- Hermes One OAuth credentials never transit through Hermes Agent, and backend-managed wallet secrets never reach Navivox.
- Navivox does not create, import, persist, or automatically transfer wallet recovery phrases.
- Electron client-state import is explicit and allowlisted, excludes credentials and private paths, never mutates the legacy source, and requires fresh authorization.
- Credentials and recognized words are excluded from diagnostics.
- Hermes Agent enforces domain-level read/write scopes for remote administration.
- Secret administration reports presence and accepts set/remove operations but never returns raw secret values.
- Remote plaintext HTTP with an API key requires explicit confirmation.
- Diagnostic exports bound and redact credentials, authorization headers,
  common token formats, user paths, and URL user information.
- Voice-loop results are discarded after session changes, disconnects, or app
  backgrounding.
- Capability checks prevent unsupported server operations from appearing ready.
- Offline or disconnected state never authorizes durable mutation queuing or automatic replay; reconnect refreshes scopes, profiles, revisions, and resources first.
- Profile-owned operations require explicit validated profile context; missing or conflicting context fails closed, and resource IDs cannot cross profile boundaries.
- Attachments and context folders use opaque profile-bound handles; Hermes validates upload limits and same-host path grants before resolving content.
- Official artifacts use platform release signing; direct updates require authenticated metadata and artifact verification, fail closed, and cannot run from unsigned development builds.
- Product analytics is off until explicit local opt-in, creates no pre-consent identifier, accepts only enumerated coarse fields, and deletes its identifier on opt-out.
- Localized templates keep dynamic values separate and bidirectionally isolated; translations cannot construct routes, URLs, commands, or authorization decisions.
- Backup/restore is server-owned and handle-based; portable archives exclude secrets and private paths, recovery archives require authenticated passphrase encryption, and restore validates fully before all-or-rollback apply.

## Assumptions

- The device OS, installed speech recognizer, and Hermes server are trusted.
- A user who confirms plaintext HTTP understands the external network boundary.
- A compromised device, accessibility service, keyboard, clipboard observer,
  root user, or Hermes server can access sensitive content; Navivox does not
  defend against those actors.
- Platform backups and secure-storage migration behavior depend on OS and
  plugin configuration.

## Known gaps

- No independent penetration test or formal privacy review.
- Scoped-token issuance and one-time Android enrollment remain to be implemented.
- Attachment upload, resource-handle retention, and server-workspace contracts remain to be implemented.
- Hermes One account and wallet contracts have not yet been ported to Navivox.
- Hermes Desktop does not yet provide a guarded export path for encrypted legacy local-wallet recovery phrases; Electron retirement is blocked on this data-exit path.
- The allowlisted Electron client-state importer and cross-platform migration receipts remain to be implemented.
- Android release signing has an alpha workflow, but public signed releases, authenticated update metadata, desktop signing/notarization, protected key-custody procedures, and cross-platform update receipts remain incomplete.
- The consent-gated analytics client, closed event schema, and privacy receipts remain to be implemented.
- Current Hermes backup/import creates and overlays unencrypted path-based full-home ZIP files; the versioned handle-based archive contract, encryption, inspection, and rollback-safe restore remain to be implemented.
- No ordinary-CI physical microphone test.
- On-device speech is requested but offline execution depends on platform and
  recognizer support.
- Plaintext remote HTTP remains available for trusted VPN and isolated-LAN use.
- Clipboard contents and screenshots are controlled by the operating system.

## Diagnostic policy

Never log these secrets. Diagnostic exports must not contain raw API keys,
authorization headers, wallet recovery phrases, backup passphrases, archive
handles, recognized words, transcripts, approval payloads, pairing secrets, or
private filesystem paths.
Operational diagnostics may include bounded status names, counts, timings,
confidence values, finality flags, capability names, and redacted errors.
Analytics is a separate consent boundary and cannot upload diagnostic bundles or
free-form diagnostic fields.

## Incident response

Rotate affected Hermes credentials, disconnect the endpoint, preserve only
redacted evidence, identify the exposed trust boundary, and report privately as
described in `SECURITY.md`. Release response remains best-effort while the
project has no supported public version.
