# Exact-artifact Linux service observations

`scripts/record_linux_service_qualification.mjs` records local manual observations
without installing, starting, stopping, updating, or removing services. No live
service qualification was performed while implementing it. Its public output
contains artifact/manifest digests, a random sequence identifier, fixed observation
booleans, phase, timestamp, and limitations; it excludes host paths and logs.

The recorder currently covers Linux amd64. Supply a candidate release set and a
distinct previously verified release set, each containing both Linux and Wing
Link manifests and their artifacts. It checks all artifact bytes, reads only the
fixed `bundle/wing` archive member without extracting paths, and compares the
active application and Wing Link bytes with the expected generation. Active
installation symlinks are resolved locally. The previous verification and service
health observations remain explicit operator assertions, not inferred signatures.

Set these local inputs (paths are never exported):

- `WING_RELEASE_EVIDENCE_DIR`: candidate artifact directory.
- `WING_PREVIOUS_RELEASE_EVIDENCE_DIR`: previously verified artifact directory.
- `WING_LINUX_ACTIVE_WING` and `WING_LINUX_ACTIVE_WING_LINK`: exact active binaries.
- `WING_LINUX_QUALIFICATION_SEQUENCE`: one random 32-character lowercase hex ID.
- `WING_LINUX_QUALIFICATION_DIR`: local output directory, default
  `build/receipts/linux-service`.

After each independently performed operation, run
`node scripts/record_linux_service_qualification.mjs PHASE` in this order:
`install`, `start`, `restart`, `health`, `failed-activation-rollback`, `uninstall`.
Each phase requires `WING_LINUX_PHASE_OBSERVED=true`,
`WING_LINUX_NO_SECRET_LEAKS=true`, and
`WING_LINUX_PREVIOUS_VERIFIED_OBSERVED=true`. Failed activation additionally
requires `WING_LINUX_ACTIVATION_FAILURE_OBSERVED=true` and
`WING_LINUX_PREVIOUS_HEALTH_RESTORED=true`, and the active files must match the
previous generation. Uninstall requires both active files to be absent and
`WING_LINUX_SERVICE_ABSENT_OBSERVED=true` plus
`WING_LINUX_FILES_REMOVED_OBSERVED=true`.

Run `node scripts/record_linux_service_qualification.mjs complete` only after all
six phase files exist. It revalidates ordered identities and generation-specific
bytes recorded at observation time and writes a separate index hashing every
phase receipt. Missing, duplicate, failed, reordered, or mixed-generation phases
fail. Existing phase/index files are immutable: use a fresh sequence for another
qualification attempt. These manual receipts are not automatically published by
the alpha release workflow and do not establish signed distribution support.
