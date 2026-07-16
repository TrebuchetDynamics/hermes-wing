# ADR 0038: Verify managed-runtime installation and updates

Status: accepted
Date: 2026-07-13

Desktop host adapters install or update the external Hermes Agent runtime only from authenticated, version-pinned release metadata. They never execute a script streamed from a URL, fetch installer code from a mutable branch, invoke a shell command assembled from downloaded or user-provided text, hide privilege escalation, or collect an administrator password inside Hermes Wing.

## Release metadata

A signed Hermes Agent release manifest binds an exact Agent version and channel to supported platform/architecture installer artifacts, byte sizes, SHA-256 digests, source revision, compatibility metadata, and release-signing identity. The host adapter verifies the manifest before download and the complete artifact before execution. HTTPS protects transport but does not replace signature or digest verification.

Unknown keys, invalid or expired metadata, digest or size mismatches, unsupported platform/architecture, unapproved channels, mutable development references, and unrequested downgrades fail closed. Release-key rotation requires an already trusted key or a separately platform-authenticated Hermes Wing update. Official builds expose no fallback that bypasses verification; source developers may install Hermes manually outside this workflow.

## Installation boundary

- Existing supported installations are discovered and adopted in place after health and capability verification; Hermes Wing does not replace their Hermes home, profiles, configuration, credentials, or runtime merely to normalize layout.
- New installations are per-user and unprivileged by default. The selected version is staged in an owner-only temporary location, verified, installed side by side, and made active only after its health and capabilities pass.
- If an OS dependency genuinely requires elevation, Hermes Wing previews the exact reason and bounded action, then delegates authentication to the operating system's native elevation broker. Cancellation leaves the prior installation unchanged.
- Hermes Wing never receives, proxies, stores, logs, or replays an administrator password and does not add a `sudo` shim or bypass script-execution policy.
- Installer arguments are fixed and typed. User-selected locations are validated as paths and passed as arguments, never interpolated into a shell program.
- Remote SSH bootstrap follows ADR 0037 and executes only the same verified, pinned installer operation; it does not pipe remote network content into a shell.

## Update and rollback lifecycle

Runtime updates are explicit. Hermes Agent blocks new work, drains active work under ADR 0029, creates any required pre-update checkpoint, and stops only after confirmation. The host adapter installs and verifies the new runtime before switching the active version. Failed install, launch, health, capability, or compatibility checks restore the previous executable selection and restart the known-good runtime against the unchanged Hermes home.

Rollback is a signed, explicitly selected release operation, not arbitrary version execution. The previous verified runtime is retained for a bounded rollback window and removed only after the new runtime has remained healthy or the operator confirms cleanup. Hermes Wing and Hermes Agent updates remain independently versioned and must negotiate through capabilities.

## Evidence

Linux, Windows, and macOS receipts cover existing-runtime adoption, clean per-user install, signed update, tampered manifest and artifact rejection, wrong key/channel/architecture rejection, cancelled elevation, no-elevation install, injected path values, active-work drain, failed-health rollback, retained data, explicit cleanup, and successful post-install health and capability verification.
