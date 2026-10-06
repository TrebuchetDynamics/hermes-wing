# Host verification — 2026-10-03

## Verdict and provenance

**PASS:** full Wing Link Go suite, npm dependency audit, focused activation/rollback and service-boundary tests, and installer/release contract tests.

**HOLD:** exact-artifact Linux systemd-user lifecycle and recovered-service rollback qualification. The passing tests below do not establish a running predecessor after rollback, signed distribution, or production update availability.

Source: local working checkout at revision `ca149a82189c8c9e5abd98b376bfeae1e43f6f3f`, with existing unrelated dirty changes preserved. Date in the filename is the requested local task date; environment/provenance capture returned `2026-10-04T00:50:10Z` (UTC). All commands were observed in this session; the initial two checks ran independently, not chained by success. This is working-tree evidence, not evidence for an immutable release artifact or CI run. Concurrent work elsewhere in the tree is not covered by these receipts.

Observed platform/toolchain: Linux x86_64; `go version go1.26.1 linux/amd64`; Node `v26.7.0`; npm `11.19.0`. Node differs from the documented Node 22 toolchain: this run does not prove Node 22 behavior.

No personal runtime was installed, restarted, or changed. No upstream source was edited; no external publication, release signing custody, or production key changes were performed. Test-created binaries, temporary roots, loopback servers, and ephemeral fixture keys are not production artifacts or credentials. Only this report is owned for repository edits. Logs below omit the checkout's absolute test-loader paths; test names, results, times and exits are retained.

## Exact observed receipts

Commands are relative to the repository root unless the working directory is explicitly `wing_link/`.

### Full Go suite

Working directory: `wing_link/`. Command: `go test ./...`. Exit: **0**. Scope: every Wing Link package, including app, authorization/approval, audit, host execution, operation journal, protocol, release, state and directory grants. Complete output:

```text
?   github.com/TrebuchetDynamics/hermes-wing/wing-link [no test files]
ok  github.com/TrebuchetDynamics/hermes-wing/wing-link/internal/app 15.915s
ok  github.com/TrebuchetDynamics/hermes-wing/wing-link/internal/approval 0.228s
ok  github.com/TrebuchetDynamics/hermes-wing/wing-link/internal/audit 0.148s
ok  github.com/TrebuchetDynamics/hermes-wing/wing-link/internal/hostexec 0.113s
ok  github.com/TrebuchetDynamics/hermes-wing/wing-link/internal/operation 3.624s
ok  github.com/TrebuchetDynamics/hermes-wing/wing-link/internal/protocol 0.004s
ok  github.com/TrebuchetDynamics/hermes-wing/wing-link/internal/release 0.178s
ok  github.com/TrebuchetDynamics/hermes-wing/wing-link/internal/state 2.406s
ok  github.com/TrebuchetDynamics/hermes-wing/wing-link/internal/workspaces 0.646s
```

### Dependency audit

Command: `npm audit`. Exit: **0**. Scope: this checkout's npm dependency graph, not Go dependencies, Flutter dependencies, runtime security, or an independent security assessment. Complete output:

```text
found 0 vulnerabilities
```

### Uncached focused updater qualification

Working directory: `wing_link/`. Exact command:

```bash
go test -count=1 -v ./internal/release -run 'TestApply(FailsClosedBeforeNetworkWhenTrustedKeyMapEmpty|StagesOwnerOnlyAndActivatesAtomically|RollsBackOnRestartFailure|RollsBackOnHealthFailure|RollbackOnFirstActivationRemovesCurrentLink|RejectsDigestSizeAndInterruptFailuresWithoutActivating)$|TestActivationRollsBackWhenDirectorySyncFails$'
```

Exit: **0**. Complete output:

```text
=== RUN   TestApplyFailsClosedBeforeNetworkWhenTrustedKeyMapEmpty
--- PASS: TestApplyFailsClosedBeforeNetworkWhenTrustedKeyMapEmpty (0.00s)
=== RUN   TestApplyStagesOwnerOnlyAndActivatesAtomically
--- PASS: TestApplyStagesOwnerOnlyAndActivatesAtomically (0.01s)
=== RUN   TestApplyRejectsDigestSizeAndInterruptFailuresWithoutActivating
=== RUN   TestApplyRejectsDigestSizeAndInterruptFailuresWithoutActivating/digest_mismatch
=== RUN   TestApplyRejectsDigestSizeAndInterruptFailuresWithoutActivating/size_short
=== RUN   TestApplyRejectsDigestSizeAndInterruptFailuresWithoutActivating/size_overlong
=== RUN   TestApplyRejectsDigestSizeAndInterruptFailuresWithoutActivating/interrupted_body
--- PASS: TestApplyRejectsDigestSizeAndInterruptFailuresWithoutActivating (0.00s)
    --- PASS: TestApplyRejectsDigestSizeAndInterruptFailuresWithoutActivating/digest_mismatch (0.00s)
    --- PASS: TestApplyRejectsDigestSizeAndInterruptFailuresWithoutActivating/size_short (0.00s)
    --- PASS: TestApplyRejectsDigestSizeAndInterruptFailuresWithoutActivating/size_overlong (0.00s)
    --- PASS: TestApplyRejectsDigestSizeAndInterruptFailuresWithoutActivating/interrupted_body (0.00s)
=== RUN   TestApplyRollsBackOnRestartFailure
--- PASS: TestApplyRollsBackOnRestartFailure (0.00s)
=== RUN   TestActivationRollsBackWhenDirectorySyncFails
--- PASS: TestActivationRollsBackWhenDirectorySyncFails (0.00s)
=== RUN   TestApplyRollsBackOnHealthFailure
--- PASS: TestApplyRollsBackOnHealthFailure (0.00s)
=== RUN   TestApplyRollbackOnFirstActivationRemovesCurrentLink
--- PASS: TestApplyRollbackOnFirstActivationRemovesCurrentLink (0.00s)
PASS
ok  github.com/TrebuchetDynamics/hermes-wing/wing-link/internal/release 0.034s
```

Scope and distinction: `internal/release/updater_test.go` creates an owner-only temporary layout, signs its own catalog with an ephemeral Ed25519 key, and supplies fixed text payload bytes (`wing-link linux binary payload 1.2.4`), not an executable Wing Link release. Restart and health are injected callbacks. These tests genuinely exercise digest/size verification, staging, atomic links, failure refusal and restored link targets; they do not restart a native service or prove a healthy recovered predecessor.

### Uncached service-boundary tests

Working directory: `wing_link/`. Exact command:

```bash
go test -count=1 -v ./internal/app -run 'Test(ExternalServiceHealthUsesLoopbackHTTPForRemoteTLSOrigin|EnsureManagedWingLinkServiceReusesHealthyService|WingLinkSystemdUnitPersistsExactServiceBoundaries|InstallCurrentServiceTargetUsesVersionedRelativeSymlink|ServeListenAddressesKeepLoopbackSeparate|EnsureExternalWingLinkServiceVerifiesLoopbackHealth|VerifyWingLinkHealthDoesNotFollowRedirects|EnsureExternalWingLinkServiceRejectsManagedMode)$'
```

Exit: **0**. Complete output:

```text
=== RUN   TestEnsureExternalWingLinkServiceVerifiesLoopbackHealth
--- PASS: TestEnsureExternalWingLinkServiceVerifiesLoopbackHealth (0.00s)
=== RUN   TestVerifyWingLinkHealthDoesNotFollowRedirects
--- PASS: TestVerifyWingLinkHealthDoesNotFollowRedirects (5.01s)
=== RUN   TestEnsureExternalWingLinkServiceRejectsManagedMode
--- PASS: TestEnsureExternalWingLinkServiceRejectsManagedMode (0.00s)
=== RUN   TestExternalServiceHealthUsesLoopbackHTTPForRemoteTLSOrigin
--- PASS: TestExternalServiceHealthUsesLoopbackHTTPForRemoteTLSOrigin (0.00s)
=== RUN   TestEnsureManagedWingLinkServiceReusesHealthyService
--- PASS: TestEnsureManagedWingLinkServiceReusesHealthyService (0.00s)
=== RUN   TestWingLinkSystemdUnitPersistsExactServiceBoundaries
--- PASS: TestWingLinkSystemdUnitPersistsExactServiceBoundaries (0.00s)
=== RUN   TestInstallCurrentServiceTargetUsesVersionedRelativeSymlink
--- PASS: TestInstallCurrentServiceTargetUsesVersionedRelativeSymlink (0.00s)
=== RUN   TestServeListenAddressesKeepLoopbackSeparate
--- PASS: TestServeListenAddressesKeepLoopbackSeparate (0.00s)
PASS
ok  github.com/TrebuchetDynamics/hermes-wing/wing-link/internal/app 5.016s
```

Scope: real temporary symlink operations and loopback HTTP fixture servers; unit text and injected setup callbacks. No `systemctl` lifecycle was performed by these focused cases.

### Linux receipt validator tests

Command: `node --test test/tooling/linux_service_qualification_test.mjs`. Exit: **0**. Complete output:

```text
✔ all lifecycle phases bind the expected artifact generation (2.613155ms)
✔ rollback must restore predecessor bytes and observed health (0.52974ms)
✔ uninstall requires absent files and explicit service observations (0.37556ms)
✔ sequence rejects missing, duplicate, changed and failed phases (0.700834ms)
ℹ tests 4
ℹ suites 0
ℹ pass 4
ℹ fail 0
ℹ cancelled 0
ℹ skipped 0
ℹ todo 0
ℹ duration_ms 64.291238
```

Scope: validator acceptance/refusal on synthetic manifests and hashes. Setting fixture observation booleans is not a lifecycle observation.

### Installer and release contracts

Command:

```bash
flutter test test/tooling/wing_link_distribution_contract_test.dart test/tooling/release_workflow_contract_test.dart --reporter expanded
```

Exit: **0**. Final real log: `00:03 +24: All tests passed!`.

Observed named cases include release interruption restoring an existing Wing Link, default build/setup dispatch, source archive version fallback, real source-build install/identical-byte reuse/stale-file repair, probe-failure preservation, interruption before/after adoption, conflicting-mode refusal, canonical Termux metadata, and fixture Termux loopback setup. Release contracts invoke Node tests for release evidence, manual qualification, Linux service qualification, CI gates/receipts, and platform artifact identity; they check workflow wiring and the verifier's rejection of an incomplete artifact directory. Repeated parallel progress lines are not separate cases.

Scope and distinction: the source-build success case executes a real locally built ELF and validates reuse/repair in a temporary prefix. Several other installer cases replace Go, curl, candidate executables or movement commands with deterministic fakes and injected failures. Those cases establish installer control flow, not release download, real Agent setup, physical Termux, production systemd, signing, publication, or exact-release rollback.

## Inspected executable surfaces and remaining gap

- [`install-wing-link.sh`](../../install-wing-link.sh): explicit `--build --prefix DIR` avoids setup; default mode silently enables setup. Never run its default or `--setup` on a personal runtime for this gate. It verifies a candidate `version` probe, compares actual bytes, and preserves an existing executable on transactional installation failure. This is installer rollback, not service recovery.
- [`service_linux.go`](../../wing_link/internal/app/service_linux.go): real managed installation writes the fixed `hermes-wing-link.service` unit and calls `systemctl --user daemon-reload`, `enable --now`, and `restart`. Changing `HOME` alone does not isolate an already connected user service manager; a throwaway Linux VM/user manager is required before exercising this path.
- [`updater.go`](../../wing_link/internal/release/updater.go), `activate` / `restoreLinks`: on restart or health failure the implementation restores/syncs `current` and `previous` symlinks. It does **not** call restart and health again after restoration. The health-failure regression expects one restart and one health callback. Thus recovered-service health is a specific unproven condition, not something to infer from `ErrUpdateRolledBack`.
- [`update.go`](../../wing_link/internal/app/update.go): the normal management route fails closed when production keys are absent or activation is unconfigured. Do not bypass that gate or change production keys to generate a passing receipt.
- [`record_linux_service_qualification.mjs`](../../scripts/record_linux_service_qualification.mjs) and [its runbook](linux-service-receipts.md): executable exact-byte recorder, **not** lifecycle automation. It requires a distinct candidate/predecessor release identity, matching Wing/Linux manifests and files, and the actual active Wing and Wing Link bytes. Its six phases are `install`, `start`, `restart`, `health`, `failed-activation-rollback`, `uninstall`, then `complete`. Health, previous verification, secret review and service absence remain truthful manual assertions.
- [`verify_release_artifacts.sh`](../../scripts/verify_release_artifacts.sh): full multi-platform release verifier needs complete artifact sets, immutable source identity and an expected Android certificate fingerprint. It cannot be truthfully satisfied by a local Wing Link build alone. Verification uses a public fingerprint, not signing-key custody; missing actual artifacts remain a prerequisite, not permission to manufacture evidence.

No inspected script performs an end-to-end isolated native systemd lifecycle/rollback automatically. The safe, executable automated subset has been run above. No exact-artifact `manual-native-service` phase receipt was emitted, because its observations were not performed.

## Remaining executable recommendation

### Repeatable automated subset (safe without personal runtime)

From the repository root, repeat the exact commands above. For an uncached full Go rerun use `(cd wing_link && go test -count=1 ./...)`. Run `npm audit` independently and repeat the Node/Flutter installer contracts under documented Node 22 before claiming that toolchain. These are executable now; they remain contract evidence.

### Native lifecycle gate (requires disposable Linux/systemd environment)

Use a throwaway Linux amd64 VM with a dedicated unprivileged account and its own actual systemd-user manager; do not use the host's personal user bus, Agent home, config, credentials or service. Transfer local read-only candidate and distinct previously verified predecessor release sets with matching manifests; no publication or private signing keys are needed. Keep all service traffic loopback-only, state owner-only, and use only an unmodified Agent release if Agent is needed. Run the real installation/start/restart/health operations there and independently compare active binaries and permissions.

After each observed operation, the existing recorder can be executed from the checkout with explicit local inputs (environment paths remain local):

```bash
# Supply actual verified release directories and active binary locations locally:
# WING_RELEASE_EVIDENCE_DIR, WING_PREVIOUS_RELEASE_EVIDENCE_DIR,
# WING_LINUX_ACTIVE_WING_LINK, WING_LINUX_ACTIVE_WING,
# WING_LINUX_QUALIFICATION_DIR (owned disposable output directory).
export WING_LINUX_QUALIFICATION_SEQUENCE="$(node -e "process.stdout.write(require('node:crypto').randomBytes(16).toString('hex'))")"
# Set the required observation flags only after independently observing that phase.
node scripts/record_linux_service_qualification.mjs install
node scripts/record_linux_service_qualification.mjs start
node scripts/record_linux_service_qualification.mjs restart
node scripts/record_linux_service_qualification.mjs health
node scripts/record_linux_service_qualification.mjs failed-activation-rollback
node scripts/record_linux_service_qualification.mjs uninstall
node scripts/record_linux_service_qualification.mjs complete
```

This is a recorder command sequence, not an installer or executable failure-injection harness. Do not run it as a batch with pre-set `true` flags. Follow the linked runbook's per-phase flags. The rollback phase must observe failure and subsequently healthy predecessor **process bytes**, not only a restored disk link; uninstall must observe the absent service and both absent active files. A manual corrective restart is not proof of automatic updater recovery and must be recorded separately.

To qualify the updater itself without production signing custody requires a separately reviewed isolated integration harness using its existing injected test-key/catalog and restart/health seams with actual executable candidate/predecessor bytes and a disposable service manager. Such a harness is not present in the inspected scripts and was not created under this report-only scope. Do not call a fake callback or manually swapped symlink an exact-artifact updater qualification. Until that harness/authorized native execution and the recovered-health gap are addressed, the native automatic lifecycle/rollback gate remains **HOLD**.
