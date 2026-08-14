# Security and privacy

Status: current decision

## Decision

Credentials and enrollment secrets belong in platform secure storage. Never put
bearer credentials in URLs, QR payloads, logs, analytics, shared text, command
arguments, or ordinary preferences. Keep Hermes Agent and Wing Link credentials
separate.

Current Wing Link transport is authenticated HTTP on loopback plus a selected or
automatically discovered local private-LAN/Tailscale interface. Non-loopback
plaintext requires explicit client review; use a trusted HTTPS reverse proxy or
encrypted VPN for remote operation. Network location is not authorization.

Use least-privilege scopes for read, mutation, secret-write, lifecycle, and
filesystem grants. A compatibility full-access Hermes key must be clearly labeled
and separately reviewed.

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
shell, CLI, config keys, executable paths, or host paths.

See [SECURITY.md](../../SECURITY.md) and the [threat model](../security/threat-model.md).
