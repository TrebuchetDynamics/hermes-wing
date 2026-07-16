# Hermes Wing threat model

Status: alpha baseline, not an independent security assessment.

## Assets

- Hermes API keys, scoped operator tokens, endpoint identities, and Hermes One OAuth credentials
- Legacy local-wallet recovery phrases during guarded export
- Backup archives, recovery passphrases, archive handles, and restore checkpoints
- SSH host trust, private-key paths, and forwarded Hermes traffic
- Hermes Agent release manifests, installer artifacts, runtime selection, and elevation boundary
- Hermes Wing package identity, repository metadata, signing lineage, maintainer scripts, and upgrade state
- Session transcripts, prompts, tool activity, approval decisions, attachments, context resources, and filesystem grants
- Microphone input and completed speech transcripts
- Local voice models and downloaded model metadata
- Device-backed signing keys used by Android pairing flows
- Optional endpoint-bound push-registration tokens and notification metadata

## Trust boundaries

1. **Hermes Wing process and local storage.** The app controls UI state and splits
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
- Native Hermes One sign-in uses an allowed-origin system-browser RFC 8628 flow with generic device labels, server-paced polling, no code clipboard/logging, and a client-global credential in platform secure storage.
- Hermes One OAuth credentials never transit through Hermes Agent, and backend-managed wallet secrets never reach Hermes Wing.
- Hermes Wing does not create, import, persist, or automatically transfer wallet recovery phrases.
- Legacy recovery export remains local to final Hermes Desktop, verifies one wallet at a time, offers only timed manual reveal or authenticated passphrase-encrypted output, and prohibits clipboard, QR, bulk, remote, and cloud transfer.
- Electron client-state import is explicit and allowlisted, excludes credentials and private paths, never mutates the legacy source, and requires fresh authorization.
- Credentials and recognized words are excluded from diagnostics.
- Hermes Agent enforces domain-level read/write scopes for remote administration.
- Secret administration reports presence and accepts set/remove operations but never returns raw secret values.
- Provider API keys are write-only: no endpoint, log, error body, or capability field ever returns a stored provider key; presence is reported only as a `configured` boolean plus a masked last-4-character hint.
- Remote plaintext HTTP with an API key requires explicit confirmation.
- Diagnostic exports bound and redact credentials, authorization headers,
  common token formats, user paths, and URL user information.
- Voice-loop results are discarded after session changes, disconnects, or app
  backgrounding.
- Android backgrounding performs no implicit stop or mutation, invalidates local approval/queue state, uses no run-keeping foreground service, and reconciles authoritative server state on resume.
- Capability checks prevent unsupported server operations from appearing ready.
- Offline or disconnected state never authorizes durable mutation queuing or automatic replay; reconnect refreshes scopes, profiles, revisions, and resources first.
- Profile-owned operations require explicit validated profile context; missing or conflicting context fails closed, and resource IDs cannot cross profile boundaries.
- Attachments and context folders use opaque profile-bound handles; same-host filesystem grants originate in native pickers, are least-privilege and expiring, revalidate anchored containment, and never return paths.
- Official artifacts use platform release signing; direct updates require authenticated metadata and artifact verification, fail closed, and cannot run from unsigned development builds.
- Product analytics is off until explicit local opt-in, creates no pre-consent identifier, accepts only enumerated coarse fields, and deletes its identifier on opt-out.
- Localized templates keep dynamic values separate and bidirectionally isolated; translations cannot construct routes, URLs, commands, or authorization decisions.
- Backup/restore is server-owned and handle-based; portable archives exclude secrets and private paths, recovery archives require authenticated passphrase encryption, and restore validates fully before all-or-rollback apply.
- Desktop SSH requires explicit first-use fingerprint confirmation, app-owned strict host-key state, hard failure on key changes, argument-vector execution, and loopback-only forwarding.
- Desktop runtime installation verifies signed version-pinned metadata and complete artifacts, defaults to per-user installation, delegates elevation to the OS, activates only healthy runtimes, and retains a verified rollback target.
- Canonical platform packages are signed, preserve stable application and secure-storage identity, contain no Hermes runtime, perform no network install scripts, and preserve Hermes data on ordinary uninstall.

## Assumptions

- The device OS, installed speech recognizer, and Hermes server are trusted.
- A user who confirms plaintext HTTP understands the external network boundary.
- A compromised device, accessibility service, keyboard, clipboard observer,
  root user, or Hermes server can access sensitive content; Hermes Wing does not
  defend against those actors.
- Platform backups and secure-storage migration behavior depend on OS and
  plugin configuration.

## Known gaps

- No independent penetration test or formal privacy review.
- Scoped-token issuance, one-time Android enrollment, and scoped profile
  administration are implemented on the server and Flutter client (milestone 0
  and Profiles/Agents); the on-device enrollment/administration receipt and
  TalkBack/200%-scale accessibility receipt are still pending, so those parity
  rows remain `implementing`, not `validated`. Known residual notes: the API
  server's `/api/cron/fire` route is authorized by a purpose-built NAS-minted
  JWT rather than the operator-scope check (stronger, but an audited exception);
  operator enrollment uses a store-global failed-attempt lockout matching the
  messaging-pairing model (a denial-of-enrollment lever acceptable for a
  single-owner install), a completed/expired code retry counts toward that
  lockout, and expired/consumed enrollment rows are not yet pruned.
- Attachment upload, resource-handle retention, server-workspace contracts, and picker-originated filesystem grant enforcement remain to be implemented.
- Hermes One device authorization, refresh/revocation, account sync, and backend-managed wallet contracts have not yet been ported to Hermes Wing; web PKCE and browser token storage lack implementation receipts.
- Hermes Desktop does not yet provide ADR 0042's guarded export path for encrypted legacy local-wallet recovery phrases; Electron retirement is blocked on the cross-platform data-exit receipts.
- The allowlisted Electron client-state importer and cross-platform migration receipts remain to be implemented.
- Android release signing has an alpha workflow, but public signed releases, authenticated update metadata, desktop signing/notarization, protected key-custody procedures, and cross-platform update receipts remain incomplete.
- The consent-gated analytics client, closed event schema, and privacy receipts remain to be implemented.
- Server-advertised, endpoint-opt-in, content-redacted run notifications and their token lifecycle remain to be designed and implemented; no notification is required for detached-run correctness.
- Current Hermes backup/import creates and overlays unencrypted path-based full-home ZIP files; the versioned handle-based archive contract, encryption, inspection, and rollback-safe restore remain to be implemented.
- The Flutter desktop SSH host adapter and cross-platform trust, rotation, injection, and forwarding receipts remain to be implemented; Hermes Desktop currently uses automatic `accept-new` first trust.
- Hermes Agent signed release metadata and the verified cross-platform runtime installer/updater remain to be implemented; Hermes Desktop currently downloads mutable `main` installer scripts, pipes the Unix script into a shell, and brokers `sudo` passwords itself.
- Canonical AAB/APK, APT/RPM, MSIX, and notarized DMG pipelines and their migration, upgrade, uninstall, identity, and package-script receipts remain incomplete.
- No ordinary-CI physical microphone test.
- On-device speech is requested but offline execution depends on platform and
  recognizer support.
- Plaintext remote HTTP remains available for trusted VPN and isolated-LAN use.
- Clipboard contents and screenshots are controlled by the operating system.

## Diagnostic policy

Never log these secrets. Diagnostic exports must not contain raw API keys,
authorization headers, wallet recovery phrases, wallet-export passphrases,
backup passphrases, archive handles, SSH hosts, usernames, fingerprints, push-registration tokens,
notification routing identifiers, recognized words, transcripts, approval
payloads, pairing or device-authorization codes, or private filesystem paths.
Operational diagnostics may include bounded status names, counts, timings,
confidence values, finality flags, capability names, and redacted errors.
Analytics is a separate consent boundary and cannot upload diagnostic bundles or
free-form diagnostic fields.

## Incident response

Rotate affected Hermes credentials, disconnect the endpoint, preserve only
redacted evidence, identify the exposed trust boundary, and report privately as
described in `SECURITY.md`. Release response remains best-effort while the
project has no supported public version.
