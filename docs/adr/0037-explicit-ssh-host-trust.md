# ADR 0037: Confirm SSH host identity explicitly

Status: accepted
Date: 2026-07-13

Desktop SSH connections require an explicitly trusted host key. Navivox does not reproduce Hermes Desktop's `StrictHostKeyChecking=accept-new` behavior, which silently trusts an unseen key on first connection. Android, iOS, and web do not expose SSH host capabilities.

## Trust establishment

The desktop host adapter uses the system OpenSSH client and identifies trust by canonical host plus port. Before the first authenticated connection, it presents the hostname, port, key algorithm, and SHA-256 fingerprint obtained from the candidate host. The operator may compare an independently supplied expected fingerprint and must explicitly confirm the displayed identity.

Confirmation writes only the exact accepted key to a Navivox-owned `known_hosts` file with restrictive permissions. Every probe, tunnel, health check, and approved remote host operation uses that file with strict checking. Navivox neither reads from nor modifies the user's personal `known_hosts`; system-wide administrator trust requires a separately designed policy.

A missing trusted key returns to the confirmation flow. A changed or revoked key hard-fails before authentication or forwarding and shows the old and candidate algorithms and fingerprints. Replacing trust is a separate high-emphasis action; retry never accepts the new key implicitly. Removing an endpoint removes its Navivox-owned host trust only after confirmation.

## SSH execution boundary

- OpenSSH receives an argument vector; Navivox never constructs a local shell command from connection fields.
- User-derived values are never interpolated into remote shell commands. SSH is primarily a loopback-bound tunnel to the canonical Hermes API; any bootstrap command is a fixed, reviewed host-adapter operation.
- Hermes domain operations continue through the capability-advertised API and do not fall back to remote CLI or file access.
- Authentication uses an operator-selected private key or the system SSH agent in batch mode. Navivox never imports, copies, reveals, logs, or backs up private-key material.
- Private-key paths, usernames, hostnames, fingerprints, control-socket paths, and raw SSH errors are excluded from diagnostics and analytics.
- Port forwarding binds only to loopback, requires forward setup to succeed, verifies Hermes health and capabilities, and is torn down when the endpoint changes, trust changes, or the app exits.

## Evidence

Linux, Windows, and macOS host receipts cover first-use rejection, explicit confirmation, known-key reconnect, changed-key block, deliberate rotation, cancellation, missing OpenSSH, missing key, agent authentication, loopback-only forwarding, argument-injection attempts, and endpoint removal without changes to user-global SSH files.
