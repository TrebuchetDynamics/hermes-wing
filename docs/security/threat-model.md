# Navivox threat model

Status: alpha baseline, not an independent security assessment.

## Assets

- Hermes API keys and endpoint identities
- Session transcripts, prompts, tool activity, and approval decisions
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
   and API credentials and is trusted to enforce authorization and tool policy.
5. **Downloaded speech assets.** Pocket Speech assets are fetched only from
   HTTPS URLs and checked against configured SHA-256 digests.

## Current controls

- API keys are not stored in shared preferences.
- API keys and recognized words are excluded from diagnostics.
- Remote plaintext HTTP with an API key requires explicit confirmation.
- Diagnostic exports bound and redact credentials, authorization headers,
  common token formats, user paths, and URL user information.
- Voice-loop results are discarded after session changes, disconnects, or app
  backgrounding.
- Capability checks prevent unsupported server operations from appearing ready.

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
- No signed public release or documented release-key custody process.
- No ordinary-CI physical microphone test.
- On-device speech is requested but offline execution depends on platform and
  recognizer support.
- Plaintext remote HTTP remains available for trusted VPN and isolated-LAN use.
- Clipboard contents and screenshots are controlled by the operating system.

## Diagnostic policy

Never log or export raw API keys, authorization headers, recognized words,
transcripts, approval payloads, pairing secrets, or private filesystem paths.
Operational diagnostics may include bounded status names, counts, timings,
confidence values, finality flags, capability names, and redacted errors.

## Incident response

Rotate affected Hermes credentials, disconnect the endpoint, preserve only
redacted evidence, identify the exposed trust boundary, and report privately as
described in `SECURITY.md`. Release response remains best-effort while the
project has no supported public version.
