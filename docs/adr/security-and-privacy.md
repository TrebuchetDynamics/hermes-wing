# Security and privacy

Status: current

## Decision

Credentials and enrollment secrets belong in platform secure storage. Do not place bearer credentials in URLs, QR payloads, logs, analytics, shared text, or ordinary preferences. Keep non-secret endpoint metadata separate from secrets.

Prefer revocable scoped authorization. When an older Hermes release requires a full-access compatibility credential, label that authority clearly, require explicit operator review, and keep it separate from Wing Link credentials.

Use loopback or authenticated encrypted transport where possible. Plaintext private-network use requires explicit operator confirmation and an encrypted VPN or similarly isolated trusted network; network location alone is never authorization.

Analytics remains opt-in and content-free. Wing does not take custody of wallet recovery phrases. SSH host identity, filesystem access, backups, account authorization, and release artifacts require an explicit trusted authority or user-approved platform mechanism.

## Flexible guidance

- Use platform-standard security mechanisms rather than prescribing one implementation for every OS.
- Add checks in proportion to risk, but never simplify away trust-boundary validation, secret handling, data-loss prevention, consent, or accessible operation.
- Security-sensitive compatibility paths should be narrow, visible, testable, and removable when the authoritative API becomes available.

See [SECURITY.md](../../SECURITY.md) and the threat model for operational detail.
