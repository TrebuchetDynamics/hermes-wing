# Linux feature harness Link retirement

Status: offline implementation receipt; independent review and canonical delivery pending.
Task: `t_3df74d63`; milestone `CONNECTION-PATHS`; parent
`CONNECTION-LINK-REMOVAL` remains in progress.
Base: `c462d6b4fd7bd00e1a24db0da5be0c4f76548bd4`.

## Split and authority

Decision: move service safety coverage rather than delete it or invent an Agent
replacement. The [complete-removal decision](../adr/product.md#complete-removal-including-legacy)
requires preserving security tests until their service is retired.

- `integration_test/linux_live_feature_journeys_test.dart` retains Agent session
  pagination, rename, pin/unpin, search, export and delete; Tools search/refresh;
  Office search/refresh/direct activation; and provider, schedule and persona
  capability-denial assertions. Tools/Office saves only Agent connection fields.
- `scripts/run_linux_live_features_e2e.sh` requires only an owner-only, owned,
  regular, non-symlink Agent manifest. Temporary preferences/config isolation,
  owner marker, guarded cleanup and failure propagation remain. Directory fixture
  setup and service prerequisites are removed.
- `integration_test/linux_live_directory_service_test.dart` contains the original
  directory service test body byte-for-byte. It retains grant cleanup, bounded
  root/child listings, file exclusion, opaque root/child handle revocation (410)
  and absence of the revoked root. Its independent imports/bootstrap have no
  Agent client or feature navigation.
- `scripts/run_linux_live_directory_service_e2e.sh` retains the original Link
  manifest/binary/isolated state requirements, owner-only manifest checks,
  canonical temporary root, synthetic child folder/private-file fixture,
  owner marker, directory-root environment and guarded cleanup. It does not
  require an Agent manifest. This is retained service safety coverage, not a
  supported setup path or new product entry.

No production code, dependencies, packaging, localization, stored user data,
credentials, upstream code or service lifecycle was changed. Existing historical
qualification receipts remain historical; this split does not requalify them.

## Acceptance evidence (Linux offline)

The pinned initial `pass_workspace.py` guard returned `worker_start_admitted`
before the first edit, using manifest hash
`8d0ccac377fb33541fbe2b0712b43d385ef4643c4b4338c4801df9282d0d255d`.
Original tool history, not this receipt, proves admission ordering.

`test/tooling/linux_feature_runner_contract_test.dart` copies and executes the
actual runner scripts with fixture Flutter/xvfb wrappers and an empty private
manifest. No credentials, providers or services are used. Both harnesses verify
setup, teardown, absent/missing/directory/symlink/group/other-access rejection and
exact Flutter (37) and wrapper (41) failure propagation. The Agent runner is
admitted without service variables; the service runner checks its original
fixture environment and fails without binary/state prerequisites.

`test/tooling/enrollment_retirement_contract_test.dart` forbids service
imports/metadata/prerequisites in the Agent harness/runner, pins surviving Agent
journey assertions and separately guards retained service security assertions.

Executed checks:

- `flutter pub get --offline`: PASS; `git diff --exit-code -- pubspec.lock`: PASS,
  lock unchanged.
- `flutter test --no-pub --concurrency=1 --reporter expanded test/tooling/linux_feature_runner_contract_test.dart`:
  RED before the split (Agent-only execution rejected for missing Link manifest;
  new service runner absent), GREEN after the split.
- `bash -n scripts/run_linux_live_features_e2e.sh scripts/run_linux_live_directory_service_e2e.sh`:
  PASS.
- `dart format integration_test/linux_live_feature_journeys_test.dart integration_test/linux_live_directory_service_test.dart test/tooling/linux_feature_runner_contract_test.dart test/tooling/enrollment_retirement_contract_test.dart`:
  PASS.
- `flutter analyze --no-pub`: PASS, no issues (16.6 seconds).
- `flutter test --no-pub --concurrency=1 --reporter expanded test/tooling/linux_feature_runner_contract_test.dart test/tooling/linux_visual_runner_contract_test.dart test/tooling/linux_profile_runner_contract_test.dart test/tooling/enrollment_retirement_contract_test.dart test/tooling/hermes_domain_authority_contract_test.dart test/features/profiles test/core/hermes/setup test/features/hermes_chat/gateways`:
  PASS, 382 tests (48 seconds reported by Flutter).
- Original directory test body compared with moved body using Python assertions:
  PASS, byte-identical.
- `git diff --check`: PASS.

The mandatory `finish_task.py` gate reruns acceptance and records the exact local
commit/ref in the native review handoff. The worker does not integrate or publish.
Cost and independent review duration are unknown at implementation handoff.

## Limits and next slice

Implemented: harness separation and offline runner/source-contract coverage.
Qualified: Linux offline fixture admission/rejection/cleanup only.
Delivered: not yet integrated or published; independent native review pending.

NOT_CHECKED: real GTK integration journeys, live Agent authentication, provider
calls, live directory service behavior after relocation, Android, other native
platforms, packaging/build/release and deployment. No live integration target was
run, as required by this card. Static analysis and runner fixtures do not prove
live service or device qualification.

Full client/service/bundling removal remains open. The next planned slice is
remaining security-recovery consumer separation, followed by last-client/service
retirement. The retained service harness must not be deleted before that service
retirement. No parent ledger closure is claimed.
