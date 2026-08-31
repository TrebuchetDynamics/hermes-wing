# Security and privacy

Status: current decision

## Decision

A pairing handoff may carry a random single-use pairing code in a QR code,
`wing://connect` intent, explicit Android share, or the ephemeral local handoff
page, which must use `Cache-Control: no-store`. The code expires after
five minutes, never contains a bearer credential, and must not be persisted,
analyzed, included in diagnostics, or written to ordinary logs. Explicit paste is a
user-initiated fallback, not background clipboard monitoring; the app drops the
raw text immediately after parsing.

Wing and Termux remain separate app sandboxes and share only authenticated
loopback sockets. Any local app can probe loopback, so Agent and Wing Link
authentication remain mandatory. The explicit Android bootstrap command is
non-secret; provider credentials and pairing codes never enter it.

Hermes API keys, Wing Link control tokens, provider credentials, and exchanged
bearer credentials remain forbidden in URLs, QR payloads, clipboards, shared
text, command arguments, and ordinary preferences. Credentials belong in
platform secure storage, and Hermes Agent and Wing Link credentials remain
separate.

Wing Link permits cleartext HTTP only on loopback. Non-loopback listeners use TLS
1.3 with an owner-only persistent host identity bundle containing the preserved
Ed25519 host root and an Android-compatible RSA TLS key. Native clients verify the exact reviewed RSA TLS
SPKI fingerprint even when platform trust accepts the certificate;
browsers require normally trusted HTTPS and cannot bypass certificate validation.
Fingerprint change or host-key loss requires explicit re-pairing. Network location
is not authorization.

Each device receives a named bearer credential with exact, least-privilege grants
and independent expiry, usage metadata, and revocation. The host console is the
root of trust. A remote device may inspect and revoke only itself; it cannot list
peers, expand its grants, approve operations, or rotate host identity. Sensitive
and trust-tier operations require a short-lived, digest-bound, one-use local
approval. Idempotency keys bind retries to the same device, route, and payload
digest so approval or network replay cannot execute a changed request.

Provider credentials are write-only. New-profile setup may use the released
stdin-driven `hermes auth add` contract over HTTPS or an authenticated encrypted
VPN; existing-profile credential mutation remains blocked. Never place provider
secrets in argv, logs, diagnostics, responses, or ordinary preferences.

Folder selection is limited to locally approved roots. Use opaque handles,
canonical containment checks, symlink-escape prevention, bounded child-folder
listings, revocation, and path-redacted diagnostics. Wing Link never returns file
entries, file metadata, or file contents.

Security-sensitive compatibility adapters must be narrow, typed, testable, and
removable when Hermes Agent provides the authoritative API. Never expose arbitrary
shell, CLI, config keys, executable paths, or host paths. Wing Link supports only
its current and immediately previous protocol generation. Its local audit log is
bounded and allowlisted and excludes request bodies, credentials, pairing codes,
host paths, and content.

See [SECURITY.md](../../SECURITY.md) and the [threat model](../security/threat-model.md).
