# Current security boundary proof map

Status: executed source-bound checks, not certification or platform qualification.
Card: `t_0ad69d39`; task: `DOC-SECURITY-CURRENT-BOUNDARY`; goal: `SECURITY`.
Execution receipt: 2026-10-07 UTC, Linux amd64, Flutter 3.44.2 / Dart 3.12.2,
Go 1.26.1. Base HEAD: `1afe1307e37ee1ddfa1f7d67ad047509e99c8784`.

## Main-delivery boundary

The approval regression is present on canonical `main` at
`205ae2d437f7cbf53a36d8e0440664e854a5fcaf`, through commit
`15362b02cdaf60a4f8e74af8d2f1ae6e8f9d300a`. Its current test bytes match that
commit. This establishes delivery of the test, not of every dirty source input
used by the historical checks below. Those checks remain bound to their recorded
source manifest. No product check was rerun for this delivery observation.
The broader `SECURITY` goal remains partial.

## Scope and authority

This receipt maps the five named boundaries to actual callers, controls and
focused tests in the shared working tree. It does not qualify every threat-model
claim. Hermes Agent remains authoritative; chat/run/approval calls go directly
to Agent. Wing Link grants and local host approvals are a separate management
boundary. No production control, capability or protocol was changed.

Only this receipt and the new
[unspent approval regression](../../wing_link/internal/approval/security_current_boundary_test.go)
are card-owned deliverables. Existing dirty files, upstream references and the
untracked approval-settlement predecessor test were read-only. Broad Go execution
includes current unrelated OmniRoute edits; it is not a clean-HEAD release test.
Supported goal-helper updates to `goals.json` / `TODO.md` are not included wholesale
in the card commit.

Source scope is recorded in the ignored local
[source manifest](../../.task-evidence/security-current-boundary/source-fingerprints.json).
Its SHA-256 is `32aec8949c8502d20aa1a7b8fa686153861826c870be000832dd1d6e526a2b70`.
This binds inspected control/caller/test bytes, including the predecessor harness;
it is not a fingerprint of the entire repository or a packaged binary.
Commands and logs below are local optional evidence; tracked source/tests and
exact commands are the durable reproduction path.

## Five-boundary map

### Denial

Claim: [test-plan risk-based scenarios](../test-plan.md#risk-based-scenarios),
management security row; [threat-model authorization](../security/threat-model.md#authorization)
and current controls for named grants/acknowledgment.

Caller/control: `wingLinkServer.requireDeviceAuthorization` in
[serve.go](../../wing_link/internal/app/serve.go) checks the exact route scope via
`Store.AuthorizeDevice` in [device.go](../../wing_link/internal/state/device.go).
`serveDirectoryRoute` in [workspaces.go](../../wing_link/internal/app/workspaces.go)
requires `directories:read`; no network location supplies authority.

Oracle: `TestDeviceScopesAreEnforcedPerRoute` allows health but rejects profile/setup
without their grants; `TestPendingCredentialCanVerifyReadsButCannotMutateBeforeAcknowledgment`
rejects pending mutation; `TestDeviceCanInspectAndRevokeOnlyItself` checks self
inspection excludes token hashes and the revoked credential stops authorizing.
These are [server tests](../../wing_link/internal/app/serve_test.go), command D1.
The title of the self-device test is not proof of every peer-administration route.
`TestRemoteDirectoryRoutesEnforceScopeAndStrictRequests` in
[route tests](../../wing_link/internal/app/workspaces_test.go), command R1, checks
missing token/scope, caller-selected path query, duplicate/invalid query, bodies
and disallowed verbs with bounded typed errors and safety headers.

Result: D1 passes three top-level tests; R1 passes its five selected top-level
route tests plus 19 subtests. No live credential or listener was used.

### Containment

Claim: [threat-model Directories and Projects](../security/threat-model.md#directories-and-projects)
and test-plan management-security revoked-root/symlink expectations.

Caller/control: `serveDirectoryRoute` delegates opaque handles to `Browser.Children`
in [browser.go](../../wing_link/internal/workspaces/browser.go). It checks device
and expiry with `record`, resolves the current grant with `Store.Resolve` in
[grants.go](../../wing_link/internal/workspaces/grants.go), opens roots with
`openRootNoSymlinks` and confines relative browsing with Go `os.Root`. The route
serializes only `Handle` / `Name` via `remoteDirectories`, never host paths/files.

Oracle: [browser tests](../../wing_link/internal/workspaces/browser_test.go)
`TestBrowserContainedSymlinkRetargetFailsClosed` rejects retargeted child/ancestor;
`TestBrowserConcurrentSymlinkRetargetNeverEscapes` never emits the outside child;
`TestBrowserRevokedRemovedExpiredAndEvictedHandlesFailClosed` rejects retired
handles. [Grant tests](../../wing_link/internal/workspaces/grants_test.go)
`TestDirectoryGrantResolveRejectsRevokedAndSymlinkReplacedRoots` rejects revoked or
replaced roots. Command C1 passes four top-level tests plus nine subtests, no skips.
R1 additionally exercises `TestRemoteDirectoryRoutesReturnHandlesAndNamesOnly`
and `TestRemoteDirectoryHandlesExpireBindToDeviceAndObserveRevocation` through
the real HTTP handler with synthetic state. This proves the named Linux temporary
filesystem cases, not all OS/filesystem race behavior or Project creation support.

### Redaction

Claim: [threat-model current controls](../security/threat-model.md#current-controls)
for bounded audit/diagnostics, and
[adversarial cases](../security/threat-model.md#adversarial-cases) audit injection.

Caller/control: `recordAudit` in [app/audit.go](../../wing_link/internal/app/audit.go)
constructs typed metadata, not request bodies. `Log.Append` / validation in
[audit.go](../../wing_link/internal/audit/audit.go) persist only fixed fields with
allowlisted operations, bounded device IDs and owner-only storage. This is rejection
before persistence, not a guarantee that arbitrary text can be safely logged.
For Dart stored errors, `_connect` uses `_safeHermesError` in
[channel errors](../../lib/core/hermes/channel/api_channel/hermes_api_channel_errors.dart),
which delegates to `wingRedactedPreview` in
[shared redaction](../../lib/shared/security/wing_redaction.dart).

Oracle: [audit tests](../../wing_link/internal/audit/audit_test.go)
`TestAuditPersistsOnlyAllowlistedBoundedFieldsOwnerOnly` and
`TestAuditRejectsSecretsPathsPairingCodesAndUnknownOperations`, command P1: two
passes and rejected data absent from disk. [Connection tests](../../test/core/hermes/channel/hermes_api_channel_tests/connection_tests.dart)
`connect redacts local filesystem paths from stored errors` and
`connect redacts and bounds secret-looking stored errors`, command F1: representative
POSIX/Windows paths and recognized token/header shapes removed; preview bounded.
These are not universal secret detection, arbitrary transcript sanitization or
native secure-storage evidence. R1's sensitive-create test also checks no
write-only provider value appears in the approval-required response.

### Approval

Claim: [threat-model current controls](../security/threat-model.md#current-controls)
and approval replay in [adversarial cases](../security/threat-model.md#adversarial-cases);
[security ADR](../adr/security-and-privacy.md#decision) one-use digest-bound local
approval, and the test-plan approval/Stop correlation row.

Caller/control: `approvalGate` in [app/approval.go](../../wing_link/internal/app/approval.go)
reserves device/method-route/key/digest through `OperationManager.ReserveIdempotent`
before `Store.Consume` / `Store.Request` in
[approval.go](../../wing_link/internal/approval/approval.go). `deleteProfile` in
[serve.go](../../wing_link/internal/app/serve.go) hashes profile ID plus supplied
revision; execution separately checks the revision. This is not proof of an
Agent-wide cross-process transactional mutation contract.

Existing oracles: [approval tests](../../wing_link/internal/approval/approval_test.go)
`TestApprovalIsDigestBoundOneUseAndPersistent`,
`TestApprovalBindsDeduplicationAndConsumptionToIdempotencyKey`, and
`TestApprovalExpiresAndStoredMetadataIsBoundedAndRedacted`. A1 passes these plus
the new regression: four top-level tests plus four new subtests. R1's
`TestSensitiveProfileMutationsWaitForHostApproval` asserts zero command/secret
execution while awaiting the local decision.

Smallest absent regression found: the existing digest test tries a changed digest
only after consumption, so a broken digest matcher could still pass. The new
`TestCurrentSecurityApprovalMismatchPreservesExactUnspentRequest` independently
changes device, route, digest and key **before** spending the approved request.
Each mismatch must return `ErrApprovalRequired`; reopening must retain the same
approved record; the exact original consumes once, then cannot consume again.

RED/GREEN sensitivity evidence: N1 uses Go's overlay on an ignored copy of Wing
approval source with the exact-request matcher disabled. All four subtests fail
with the specific oracle “mismatched … authorized an unspent approval”. G1, without
the overlay, passes the parent and all four subtests. This is an intentionally
failing negative control, not an observed production vulnerability or a production
repair. No shipped source or upstream runtime was mutated for this experiment.

### Reconnect and no replay

Claim: [test-plan streaming and reconciliation](../test-plan.md#risk-based-scenarios),
[threat-model current controls](../security/threat-model.md#current-controls), and
[API/state ADR](../adr/api-and-state.md#decision): read/reconcile, never implicitly
resend prompts, approvals or cached configuration.

Caller/control: `_connect` in [connection implementation](../../lib/core/hermes/channel/api_channel/hermes_api_channel_connection.dart)
advances generation, resets connection state, reads current inventory/history and
recovers detached ownership. `_sendText` admission and pending-run tracking in
[messaging](../../lib/core/hermes/channel/api_channel/hermes_api_channel_messaging.dart)
fence unresolved submissions. `_respondToApproval` in
[HermesApiChannel](../../lib/core/hermes/channel/hermes_api_channel.dart) validates
origin/generations/profile/run; `HermesApprovalResponder.clear/respond` in
[responder](../../lib/core/hermes/channel/approvals/hermes_approval_responder.dart)
retires old settlement ownership without replaying a POST.

Oracles: F1 executes `failed reconnect clears stale endpoint session data`,
`stale connect results cannot overwrite a newer connection`, `recent turns never
survive a reconnect: the turn cache is scoped to the connection, not the credential`,
and `connect never creates a session merely by viewing an empty gateway`.
F2 executes [pending-run test](../../test/core/hermes/channel/hermes_api_channel_tests/run_failure_tests.dart)
`reconnect during pending submission retains late run ownership` (one submission,
no late stream attach, second send denied) and [native-ID correlation tests](../../test/core/hermes/channel/hermes_api_channel_tests/native_approval_tests.dart)
`native approval request_id correlates once/deny without FIFO or replay` (no
replacement FIFO answer, no approval replay). “Native” here names Agent request-ID
semantics in fake HTTP tests; it is not a native desktop launch.

M1 executes [operation tests](../../wing_link/internal/operation/operation_test.go)
and [journal tests](../../wing_link/internal/operation/journal_test.go):
`TestDurableManagerReplaysIdempotentWorkAndCancelsByContext`,
`TestJournalReplaysSameIdempotentRequestAndRejectsChangedPayload`,
`TestJournalRecoversInterruptedOperationsWithoutPersistingPayloads`. R1's
`TestRoutineProfileCreateReplaysExactKeyWithoutApprovalOrMutation` observes one
create command after identical replay and changed replay rejection. Explicit
idempotent management retry is distinct from implicit client mutation replay.

Predecessor attribution: the existing untracked
[approval-settlement owner harness](../../test/core/hermes/channel/hermes_approval_settlement_owner_test.dart)
is not authored or committed here. F3 freshly executes its 12 tests: held approval
success/failure, exact-origin/replacement-origin reconnect, replacement idle/busy
admission, disposal and explicit correlated retry. Its previous evidence is not
substituted for these current executions.

## Exact executed commands

Go commands below run inside `wing_link`; Flutter commands run at repository root.
Go counts distinguish top-level tests from subtests rather than adding parents
and children into a purported independent-case total. All positive checks exit 0.

```bash
# D1: 3 top-level passes
 go test -p 2 -count=1 -json ./internal/app -run '^(TestDeviceScopesAreEnforcedPerRoute|TestDeviceCanInspectAndRevokeOnlyItself|TestPendingCredentialCanVerifyReadsButCannotMutateBeforeAcknowledgment)$'
# C1: 4 top-level + 9 subtest passes
 go test -p 2 -count=1 -json ./internal/workspaces -run '^(TestBrowserContainedSymlinkRetargetFailsClosed|TestBrowserConcurrentSymlinkRetargetNeverEscapes|TestBrowserRevokedRemovedExpiredAndEvictedHandlesFailClosed|TestDirectoryGrantResolveRejectsRevokedAndSymlinkReplacedRoots)$'
# P1: 2 top-level passes
 go test -p 2 -count=1 -json ./internal/audit -run '^(TestAuditPersistsOnlyAllowlistedBoundedFieldsOwnerOnly|TestAuditRejectsSecretsPathsPairingCodesAndUnknownOperations)$'
# A1: 4 top-level + 4 subtest passes
 go test -p 2 -count=1 -json ./internal/approval -run '^(TestApprovalIsDigestBoundOneUseAndPersistent|TestApprovalBindsDeduplicationAndConsumptionToIdempotencyKey|TestApprovalExpiresAndStoredMetadataIsBoundedAndRedacted|TestCurrentSecurityApprovalMismatchPreservesExactUnspentRequest)$'
# M1: 3 top-level passes
 go test -p 2 -count=1 -json ./internal/operation -run '^(TestJournalReplaysSameIdempotentRequestAndRejectsChangedPayload|TestJournalRecoversInterruptedOperationsWithoutPersistingPayloads|TestDurableManagerReplaysIdempotentWorkAndCancelsByContext)$'
# R1: 5 top-level + 19 subtest passes
 go test -p 2 -count=1 -json ./internal/app -run '^(TestRoutineProfileCreateReplaysExactKeyWithoutApprovalOrMutation|TestSensitiveProfileMutationsWaitForHostApproval|TestRemoteDirectoryRoutesReturnHandlesAndNamesOnly|TestRemoteDirectoryRoutesEnforceScopeAndStrictRequests|TestRemoteDirectoryHandlesExpireBindToDeviceAndObserveRevocation)$'
# F1: 6 passes
flutter test --concurrency=1 --reporter expanded test/core/hermes/channel/hermes_api_channel_test.dart --name 'connect redacts|failed reconnect clears|stale connect results|recent turns never survive|connect never creates a session'
# F2: 3 passes
flutter test --concurrency=1 --reporter expanded test/core/hermes/channel/hermes_api_channel_test.dart --name 'reconnect during pending submission retains late run ownership|native approval request_id correlates'
# F3: 12 passes; read-only predecessor harness
flutter test --concurrency=1 --reporter expanded test/core/hermes/channel/hermes_approval_settlement_owner_test.dart
# N1: intentional exit 1; 1 parent + 4 subtest failures
 go test -p 2 -count=1 -json -overlay=../.task-evidence/security-current-boundary/negative-overlay.json ./internal/approval -run '^TestCurrentSecurityApprovalMismatchPreservesExactUnspentRequest$'
# G1: unmodified source; 1 parent + 4 subtest passes
 go test -p 2 -count=1 -json ./internal/approval -run '^TestCurrentSecurityApprovalMismatchPreservesExactUnspentRequest$'
# Broader Go regression check: 298 top-level + 117 subtest passes, 1 skip
 go test -p 2 -count=1 -json ./...
```

The one skip is `TestOmniRouteRealInstall`; no installation was attempted.
`gofmt -w wing_link/internal/approval/security_current_boundary_test.go` ran.
No Dart source/test was changed, so no new Dart formatting/analyzer claim is made.
Focused logs and parsed initial checks live in
[local evidence](../../.task-evidence/security-current-boundary/checks.json).
The additional route/reconnect and negative/green logs are in that same folder.

Receipt validation: `python .task-evidence/security-current-boundary/check_receipt.py`
passes 45 local links/anchors and 31 unchanged scoped fingerprints, checks both
new files with `git diff --no-index --check /dev/null <file>`, and confirms
`gofmt -l wing_link/internal/approval/security_current_boundary_test.go` is empty.
The first receipt-helper execution failed because it treated Git's no-index
“files differ” exit 1 as a whitespace failure despite empty output; its assertion
was corrected to require empty output and exit 0/1, then passed. That was a helper
issue, not a control/test failure. The tracked scoped command
`git diff --check -- docs/quality/security-current-boundary.md wing_link/internal/approval/security_current_boundary_test.go`
also passes; the no-index check covers the new, untracked files it cannot inspect.

## Limits and remaining proof

- NOT_CHECKED: live Agent authentication/inference, remote Wing Link listener,
  physical/native secure storage, TLS/SPKI behavior on actual target platforms,
  native desktop process relaunch, browser/mobile journeys, service/release/update
  qualification and packaged execution. No app/service/profile/device change was
  made. Temporary synthetic test state is not personal runtime state.
- These named denial/containment/redaction/approval/reconnect seams pass; this is
  not repository-wide security completeness, penetration testing or an audit.
- The narrow approval regression gap identified above is now covered. There is
  no demonstrated production control failure in this inspected/executed slice.
  Other threats need their own precise caller/test/runtime evidence, not a new
  speculative capability or protocol.
- Existing embedded dependency audit findings remain outside this task and are
  not re-executed or closed here. The broader `SECURITY` goal remains partial.
- The proof follows [SECURITY.md](../../SECURITY.md),
  [security/privacy ADR](../adr/security-and-privacy.md), and
  [Agent immutability](../adr/runtime-and-delivery.md#hard-boundary-never-modify-hermes-agent).
  Existing test-plan/threat-model files were not edited; their owners can integrate
  these bounded references without importing stronger support claims.
