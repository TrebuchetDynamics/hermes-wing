# Android same-artifact integrated receipt gap

Backlog: `DOC-M6-INTEGRATED-RECEIPT-GAP`. Source baseline:
`555d73aa` (client-only release chain). This is a read-only contract assessment,
not an acquired candidate, executed Android journey or release authorization.
[M6](../../ROADMAP.md#m6--deliver-an-integrated-qualified-alpha) stays **unverified**.
The [2026-10-06 inventory](2026-10-06-m6-artifact-evidence.md) describes its older
service-bearing inputs; its allowlist and platform-job counts are not current.

## First missing binding

The current chain binds the signed APK to the installed single `base.apk` and a
launch/PID check. It does **not** bind any accepted M1–M5 workflow result to that
same installed artifact/process generation. That missing install-to-workflow join
comes before upgrade/recovery proof. A correct checksum plus a running process
cannot establish usable Chat, authoritative owner restoration or no replay.

Inspected current producers and consumers:

- [Release workflow](../../.github/workflows/release-alpha.yml),
  `android-artifact-smoke`: API 34 Google APIs x86_64 `pixel_6` emulator. It verifies
  the expected APK certificate and sidecar, installs the APK, pulls the single base
  package back and compares SHA-256, starts `MainActivity`, checks PID, then
  uninstalls. The emitted `android-artifact-smoke.txt` binds tag, source revision,
  run/attempt, build, artifact and manifest digests to `apk-install-launch` /
  `verified-installed-launched`. No Chat interaction, upgrade or recovery occurs.
- [Evidence consumer](../../scripts/release_evidence.mjs),
  `validateSmokeReceipt` and `qualificationIndex`: checks exact smoke fields,
  identity/digests/scenario, three client manifests (Android/Linux/web), payloads,
  auxiliary files and the host signature/archive/launch receipt. Its smoke map has
  only the Android receipt. It neither imports M1–M5 receipts nor validates their
  outcomes. The index is integrity/launch evidence, not integrated acceptance.
- [Manual Android recorder](../../scripts/record_release_qualification.mjs),
  `recordQualification`: verifies installed APK bytes, size, version/build and
  manifest identity. Its only scenarios are `physical-voice` and `server-audio`,
  with explicit manual observations. It supplies no integrated Chat/continuity,
  upgrade or rollback scenario; the aggregate does not import these receipts.
- [Private ARM64 handoff](../runbooks/android/release-handoff.md#private-release-apk-handoff):
  the isolated `com.trebuchetdynamics.hermes.wing.qa.release` package is not the
  fixed production package inspected by the current smoke/recorder. Do not relabel
  private packaging checks as production install receipts or run a production
  package operation against the paired app to bridge this gap.

## Required next evidence, not an implemented schema

One separately admitted named Android target must retain the exact candidate
identity, public signing fingerprint, APK digest, package/ABI/OS and installed-byte
readback alongside the workflow's process generation and results. Retain sensitive
owner identities and operation receipts privately; publish only sanitized bindings.
These are evidence requirements, not new Agent fields or a proposed shadow store.

- **M1:** actual output, exact profile/model/session, correlated approval,
  authoritative Stop and canonical restoration; count deliberate submissions and
  zero recovery mutations. Existing live QA authentication, grants and an
  authoritative provider-call ceiling remain prerequisites, not supplied here.
- **M2:** background/process-death generations restore that same owner and canonical
  history/status without replay; credential-denied/wrong-owner cases stay distinct.
  An emulator cannot satisfy physical process-death qualification.
- **M3–M5:** individually supported direct setup, operation/grant/readback and native
  output/accessibility results must name the same installed artifact. Explicitly
  defer unsupported operations; do not promote unavailable-state tests to parity.
- **Then upgrade/recovery:** identify a distinct trusted predecessor, compatible
  signing/package lineage and approved failure scenario; verify retained state,
  actual post-upgrade work, restored predecessor bytes/health and exact-owner
  canonical recovery without resend. Neither clean install/uninstall nor the
  retired Linux service recorder establishes this Android sequence.

No exact candidate or target was acquired or probed in this assessment. No claim
is made that receipts are absent everywhere. The missing binding is in the
inspected current producer/consumer contracts; historical fixtures keep their
original source/platform ceilings.

## Offline verification boundary

Nearest synthetic tests:
[release evidence](../../test/tooling/release_evidence_test.mjs) and
[manual recorder](../../test/tooling/record_release_qualification_test.mjs).
They exercise digest/identity/scenario rejection with synthetic files and injected
device inspection, not ADB, signing or provider execution. On Linux with Node.js
v22.22.2, `node --test test/tooling/release_evidence_test.mjs
test/tooling/record_release_qualification_test.mjs` passed 54 tests with zero
failures or skips. The input hashes and command result are retained in the task's
private verification receipt. Changed local links,
input SHA-256 fingerprints, ledger validation, archival conservation and whitespace
are checked separately. No production code, receipt schema or release gate changed.

Next: `VERIFY-M6-ANDROID-INTEGRATED` owns separately admitted same-artifact
workflow and later upgrade/recovery qualification. Missing target/candidate/live
admission keeps it in Needs decision, not a second contract audit or release run.
