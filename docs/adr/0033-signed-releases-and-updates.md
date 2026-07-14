# ADR 0033: Sign releases and verify updates

Status: accepted
Date: 2026-07-13

Every official Navivox artifact uses its platform's release-signing path. Store distribution may delegate update verification to the platform store; direct distribution requires authenticated update metadata and artifact verification before installation. Unsigned or development builds do not self-update.

## Platform requirements

- Android artifacts use the protected production signing identity or the store's managed signing service.
- macOS artifacts use Developer ID signing, hardened runtime, and notarization.
- Windows artifacts use Authenticode signing from the protected release identity.
- Linux packages use signed repository metadata or a verifiable package/detached signature; a SHA-256 file beside an artifact is not authentication by itself.

A missing, expired, revoked, mismatched, or unverifiable signature fails closed and prevents publication or installation.

## Direct-update contract

Authenticated update metadata binds the release version, channel, platform, architecture, artifact URL, byte size, and SHA-256 digest. Verification keys ship with the application; key rotation requires authorization by an already trusted key or a separately platform-signed application update. HTTPS protects delivery but does not replace signature verification.

The client accepts only its configured release channel and newer compatible versions. Rollback means pausing promotion and publishing a signed higher patch that restores known-good behavior, not silently downgrading clients. Alpha, beta, and stable channels provide staged promotion without introducing a telemetry identifier.

Downloading may occur in the background, but applying an update requires operator confirmation and must not interrupt an active run, approval, draft, migration, or lifecycle operation. A failed update keeps the currently installed version usable.

## Key custody and evidence

Signing credentials remain outside the repository and ordinary build artifacts, are available only to protected release jobs, and must not appear in logs. Official release receipts identify the source revision, platform artifact, signature/notarization result, update-metadata result, and install/upgrade smoke outcome without exposing credentials.
