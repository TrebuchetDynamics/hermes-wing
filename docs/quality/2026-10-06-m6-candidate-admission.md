# M6 offline exact-candidate admission

Task: DOC-M6-CANDIDATE-ADMISSION / t_15e9decd. This delivers a runnable,
isolated comparison oracle and an admission checklist, not an installed alpha.
M6 remains **unverified**. Public candidate comparison, signatures, device/service
execution, integrated M1–M5, install, upgrade, rollback and uninstall are
**NOT_CHECKED**. No public candidate was supplied or searched for in private state.

## Safe offline oracle

From the Wing checkout, with Node available, run:

```bash
TMPDIR=/home/xel/.hermes/profiles/wing/cache/scratch node --test test/tooling/release_evidence_test.mjs
node --check test/tooling/release_evidence_test.mjs
node --check scripts/release_evidence.mjs
python .task-evidence/t_15e9decd/check_admission.py
```

The nearest suite passed 26 tests before changes; the extended suite passed 56.
The fixtures write explicitly synthetic bytes and JSON only into disposable
profile-cache directories, cleaned by test hooks. Fixture smoke result strings
are schema examples, never observations. No archive is opened, artifact executed,
build tool invoked, network contacted, live Agent/device touched, or production
CLI `emit`/`aggregate` called. Imported `main(['verify', 'android', fixture])`
uses the actual certificate comparison seam; it reads public checkout locks and
version and runs read-only Git identity discovery. Its environment values are
synthetic and restored after the test. No signing key or real certificate is used.

The test import closes directly over [release_evidence.mjs](../../scripts/release_evidence.mjs)
and Node built-ins only. Production imports, runtime packaging and distribution
are unchanged; checkout tests do not prove packaged execution. New tests reuse
existing fixtures, exports and schema; no new product CLI or schema was added.

## Required public inputs

Before separately authorized public-candidate comparison, obtain:

- An independently reviewed immutable source revision (40 lowercase hex), exact
  alpha tag, version, build number, CI run ID and attempt, repository identity,
  and selected target/architecture. Do not derive trusted expectations solely
  from the candidate under examination or silently use the current dirty HEAD.
- A source checkout at that candidate revision, with `pubspec.lock`,
  `package-lock.json`, `wing_link/go.mod` and `wing_link/go.sum`. Candidate-specific
  `pubspec.yaml` provides version/build for the existing verify seam.
- The complete public candidate directory from the predecessor's
  [exact verifier input allowlist](2026-10-06-m6-artifact-evidence.md#exact-verifier-input-allowlist),
  including all four manifests, ten artifacts, generated Android bootstrap,
  checksum sidecars, three platform smoke receipts, host receipt and published
  `release-qualification-index.json`.
- The independently admitted **public** Android certificate SHA-256 fingerprint.
  Never request keystore/password/key material for comparison.
- Admission for only the declared architectures/scenarios. A macOS receipt may
  name one available native architecture, not both. Other architectures/platforms
  retain their own runtime qualification requirements.

Use existing imported `readJson`, `verifyManifest`, `qualificationIndex`, and
`digest` on read-only candidate files. Compare the supplied index with the index
recomputed from those files and independent expectations; the function generates
an index but does **not** read or validate an already published index by itself.
The oracle proves this comparison through emitted JSON round-trip/deep equality
and independent hashes. The existing certificate verify seam additionally needs
candidate-bound identity/version/lock inputs and the public certificate expectation;
see [local verification context](../runbooks/release-alpha.md#local-artifact-verification).
The safe command above exercises fixtures, not arbitrary public candidate inputs.
No new candidate-facing command is claimed or authorized here.

## Admission checklist and discriminating checks

All implementation checks below refer to
[the current comparison module](../../scripts/release_evidence.mjs) and
[the executable tests](../../test/tooling/release_evidence_test.mjs).

| Required comparison | Current seam and exact rejection | Executed oracle / limit |
| --- | --- | --- |
| Revision, tag, version, build, run ID, run attempt, repository | `verifyManifest` lines 86–103 compares every supplied expected field; `qualificationIndex` lines 135–145 applies it to all target manifests. `validateIdentity` validates manifest syntax/tag-version coherence. | Seven independent expected-field changes fail with `identity mismatch: <field>` in both paths; matching emitted manifests pass. Always supply all seven fields: a partial expected object compares only its entries. |
| Target and inventory | `validateManifest` lines 65–85 requires exact target schema/input/artifact inventory; `verifyManifest` checks target. | Existing malformed/schema/inventory/symlink negatives retained. Four manifests and ten artifacts are covered by the matching index. `source_dirty` is a recorded flag, deliberately omitted from index expectations; clean-source release admission is separate. |
| Dependency locks | `verifyManifest` hashes each required input against manifest size and SHA-256. | Each of the four dependency inputs independently receives a same-size byte mutation and fails `input mismatch: <name>`. |
| Android generated bootstrap | `verifyManifest` reads `android-termux-bootstrap.json` from candidate dist for manifest input `assets/config/termux_bootstrap.json`, not the verifier checkout. | Same-size mutation fails at that exact input binding. It does not prove bootstrap/device execution. |
| Artifact bytes | `verifyManifest` hashes all target artifact files. | All ten artifact files independently receive same-size mutations and fail `artifact mismatch: <name>`. Fixture digests are compared before/after to rule out size-only rejection. |
| Manifest/index/receipt/auxiliary bindings | `qualificationIndex` hashes manifests, validates platform receipts, hashes host-listed auxiliary files; output carries bindings. | Emitted index is read back, compared with recomputed output, and every output file binding independently hashed. Changed Wing Link checksum sidecar fails `host receipt bytes mismatch`. Hashing sidecars is not independent validation of their checksum text. |
| Independent Android certificate expectation | `main` verify branch lines 212–222 compares normalized `WING_RELEASE_CERT_SHA256` against verified Android manifest signing identity. | Imported real verify path passes a matching uppercase colon-separated synthetic expectation and rejects changed/empty expectations with `signing identity mismatch`. No signing/toolchain commands run. `qualificationIndex` alone cannot enforce an independently supplied certificate expectation. |
| Host/manifest certificate agreement | `qualificationIndex` lines 161–166 compares host certificate, tag and revision to candidate identity/manifest. | Changed host certificate fails `host receipt identity mismatch`. This tests consistency, not a cryptographic signature or independent trusted certificate. |
| Android receipt | `android-artifact-smoke.txt`, `validateSmokeReceipt` lines 117–134: identity, APK digest, manifest digest, `apk-install-launch`, emulator, success. | Missing file fails ENOENT at the exact receipt path; existing wrong digest/identity/attempt/claim/duplicate/failure tests retained. Does not qualify AAB/store/physical voice. |
| macOS receipt | `wing-link-macos-smoke.txt`: native `binary-version`, one allowed Darwin binary, exact digest/identity. | Missing file fails ENOENT at its exact path. Does not qualify the other architecture, Flutter macOS app, or services. |
| Windows receipt | `wing-link-windows-smoke.txt`: native `binary-version`, exact Windows binary digest/identity. | Missing file fails ENOENT at its exact path. Does not qualify Flutter Windows app or services. |
| Host receipt | `release-verification-receipt.json`, `qualificationIndex` lines 161–183: exact schema, ten required checks, exact file inventory and bytes. | Missing file fails ENOENT at its exact path; removed check fails `host checks incomplete`; changed auxiliary bytes fail at host stage. Receipt declarations are assertions of prior work, not replayed launch/signature evidence. |

Read JSON and files with existing bounded, non-symlink digest checks. Any mismatch,
missing receipt, unexpected field or incomplete trusted expectation means no
admission; do not repair receipts to manufacture a match. Matching synthetic
fixtures qualify only these comparison mechanics, never the candidate's provenance,
signing custody, publication authority or truth of runtime observations.

## Separate runtime admission

Offline match is a prerequisite, not permission to extract/execute or publish.
The [predecessor's integrated gap table](2026-10-06-m6-artifact-evidence.md#integrated-m1m5-and-recovery-gaps)
remains applicable: host archive/signature/Linux/web/version smoke and Android APK
install/launch cannot establish real M1 generation/approval/Stop/reconnect,
M2 OS death-to-completion, M3 trusted setup, M4 operation-specific authority, or
M5 installed native output/accessibility. Those outcomes require exact-candidate,
named-target evidence and precise deferrals for unsupported contracts.

Actual install, safe upgrade from a distinct verified predecessor, failure-driven
rollback/health/session recovery, and uninstall/data disposition each need separate
admission and observations on that same candidate. Linux version execution is not
service lifecycle; APK smoke cleanup is not integrated uninstall qualification.
No Flutter, device, service, packaged runtime, physical voice or full release gate
was exercised in this slice.

## Source-bound acceptance evidence

[Baseline receipt](../../.task-evidence/t_15e9decd/baseline.json) records the existing
safe suite (26 passed, exit 0). [Oracle receipt](../../.task-evidence/t_15e9decd/oracle.json)
records the extended suite (56 passed, exit 0). [Validation receipt](../../.task-evidence/t_15e9decd/validation.json)
records exact syntax/whitespace commands, exits, local links/anchors, source hashes,
import closure, predecessor freshness and criterion mapping. The
[checker](../../.task-evidence/t_15e9decd/check_admission.py) performs only scoped
read-only checks and writes its task-owned validation receipt.

Predecessor run 364 / commit `1d0352df92a3d5ed68f146e199394bee3c06df37`
and its [22-source inventory](../../.task-evidence/t_8daadbc0/source-inventory.json)
remain historical source-only evidence. Current comparison finds 20 source hashes
unchanged: this task changed the evidence test; `release-alpha.md` already differed
at task start and was read in its current form, not overwritten. Its predecessor
22-link/anchor check is historical, not re-executed or claimed current wholesale.
The production comparison module is unchanged. No predecessor suite was rerun.

Criterion 1: public inputs, each field/digest/certificate/receipt mapping and
separate runtime requirements are above. Criterion 2: matching and discriminating
negative oracles actually passed; public candidate/runtime remain NOT_CHECKED.
Criterion 3: task-owned validation captures syntax, scoped whitespace including
untracked files, links/anchors and hashes; only the named goals task is marked
done, M6 stays unverified. Shared TODO rendering is left to the active repo-docs
writer. Criterion 4: the authorized local agent-only commit contains only this
test and checklist; its branch/SHA and unchanged shared HEAD/index are recorded
in task-owned bookkeeping and the native handoff. Criterion 5: implementation is
submitted to native same-card review; only that review lane can approve closure.
