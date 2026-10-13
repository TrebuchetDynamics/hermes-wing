# Dormant Flutter local host retirement

Historical implementation receipt for native card `t_3e71bbcd`, based on
`6acdc81008379bb3eb81c97a653bd378c234ad1e`. This is one bounded
[consumer-removal](../adr/product.md#complete-removal-including-legacy) slice,
not complete Wing Link removal or platform qualification.

## Change and scope

Deleted `lib/core/wing_link/local_wing_link_host.dart`,
`local_wing_link_process.dart`, `local_wing_link_platform_io.dart` and
`local_wing_link_platform_stub.dart`, plus their three exclusive host/IO/stub
unit-test files. No replacement adapter, dependency, configuration or UI was added.
The shared [retirement contract](../../test/tooling/enrollment_retirement_contract_test.dart)
now rejects restored cluster filenames, source imports/exports and type families
across `lib`, `test` and `integration_test` (excluding the guard itself).
Hermetic injections cover each production filename, an import, export,
conditional import, host, inspection and setup-result symbol; an empty tree passes.

Decision: delete the unused subprocess cluster rather than preserve an unavailable
stub. Evidence: tracked-source search for `local_wing_link`, `LocalWingLink`,
`LocalHermesInspection`, `LocalHermesSetupResult`, `localAppExecutablePath`,
`runLocalWingLink` and `startLocalWingLinkSetup` found no callers outside the
cluster and its dedicated tests (the existing retirement guard names the host).
The scan covered production, tests, integration, platform hosts, scripts,
Playwright, workflows, Go service, installer and dependency/fixture manifests;
upstream and vendor material were excluded. Post-deletion only the guard matches.

The deleted tests exercised cancellation, bounded output/timeouts, protocol and
error handling exclusively in the deleted implementation. Surviving Agent setup,
secure storage, enrollment rejection, saved connections and Link transport/client
tests remain. All secure credential APIs, stores, Agent code and service/client
transport sources are unchanged. No stored user data or personal service was read,
removed or modified.

## Admission and checks

Original mandatory `pass_workspace.py` admission ran before the first edit and
returned `worker_start_admitted`, exit 0. Pinned manifest SHA-256:
`5a874c94bdbadd358e5bf2ce98c2daaf97e99866a1cd1ccd00049193e3ada7cb`.
The original command and ordering are in run tool history and the native card
comment; this receipt is not a substitute for that history.

Executed in the isolated task workspace:

- `flutter pub get --offline`: pass; `pubspec.yaml` and `pubspec.lock` unchanged.
- `dart format test/tooling/enrollment_retirement_contract_test.dart`: pass.
- `timeout 5m flutter test --no-pub --reporter expanded test/tooling/enrollment_retirement_contract_test.dart --plain-name 'local host'`:
  expected RED before deletion (all four production files identified, injection
  test passed), GREEN afterward (two tests).
- `timeout 10m flutter analyze --no-pub`: pass, no issues, 6.1 seconds.
- `timeout 20m flutter test --no-pub --concurrency=1 --reporter expanded test/tooling/enrollment_retirement_contract_test.dart test/tooling/hermes_domain_authority_contract_test.dart test/core/wing_link test/core/hermes/setup test/features/enrollment test/features/local_setup test/features/hermes_chat/gateways`:
  pass, 245 tests, approximately 50 seconds.
- `git diff --check`: pass.
- `git diff --exit-code -- pubspec.yaml pubspec.lock`: pass.

An initial command without explicit workdir used canonical checkout; formatting
reported zero changes and the test filter matched no tests (exit 79). It is not
acceptance or RED evidence. Canonical tracked files remained clean; subsequent
checks explicitly targeted the isolated workspace. No in-scope test repair was
needed. Actual cost and independent review duration are unknown.

The scoped local commit and final acceptance-command receipt are recorded by
`finish_task.py` in the native card handoff. Its task ref preserves the admitted
base and excludes unrelated files. Independent native same-card review must verify
that receipt, original admission history, owned blobs and exact isolated inputs.
Review is pending at implementation handoff; no approval is implied here.

## Remaining boundaries

Implemented: static retirement and deterministic Linux-hosted Flutter regressions.
Qualified: the named unit/widget/source-contract tests only; no native app or
live-provider journey was exercised. Delivered: not integrated or published by
this worker; coordinator owns review-following integration and publication.

[Linux CMake](../../linux/CMakeLists.txt) still builds/bundles the Go Wing Link
binary (lines 60–84 and 133–135). This independent packaging dependency does not
import the retired Dart cluster and is explicitly outside this card. The Go
service, retained client/transport, installer, stored legacy metadata and credential
APIs remain for later bounded retirement. No packaged artifact, Android/Termux,
web E2E, live subprocess/host operation or release was checked.

`CONNECTION-LINK-REMOVAL` remains in progress and `CONNECTION-LINK-RETIREMENT`
remains open; this receipt does not close either ledger entry. Android ordering
(SSH, Remote server, then on-phone Termux) remains accepted intent, not device
proof. Next: coordinator review/integration of this slice, then the next scoped
remaining consumer retirement before delivery/service closure.
