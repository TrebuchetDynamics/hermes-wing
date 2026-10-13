# Linux security journey retirement

Task: `t_3122ffd1`, a bounded continuation of CONNECTION-LINK-REMOVAL.
Parent remains in_progress. This is offline Linux fixture evidence, not current
product setup guidance or live service/device qualification.

## Source and decision

Admitted base: `439d3ddbc6f0c96a25188b234f16415ea0b9797b`.
The original `pass_workspace.py` invocation succeeded before the first edit,
using manifest SHA-256
`a4edebd8bc6db24986405fb1d21a195aabc5c9d10857cb07c1cff7ce5172e97c`.
Its exact command/order is retained in the native run tool history; this document
is not a substitute for that history.

Decision: delete `integration_test/linux_live_security_recovery_test.dart` and
reuse existing isolated Go security tests, rather than add another live harness.
The old `scripts/run_linux_live_security_e2e.sh` unconditionally refuses with
exit 2 and points to the offline retained-service runner. It does not read
manifests, parse credentials, launch a display, pair or revoke any installed
service. Former destructive opt-in cannot revive the journey.

Reference trace across tracked sources found only the old runner and historical
[Linux E2E receipt](linux-e2e-2026-09-06.md) referring to the deleted target/old
command. The historical receipt is preserved; its command now fails explicitly.
No production, dependencies, localization, packaging, upstream or user stores
change. Accepted authority remains in the
[retirement decision](../adr/product.md#complete-removal-including-legacy).

## Assertion preservation map

Original line numbers below refer to the admitted base's deleted integration
file. Service tests stay in `wing_link/`, not in product qualification.

| Original assertion / behavior | After retirement |
| --- | --- |
| Lines 26–29 destructive opt-in; runner owner-only manifests | Old runner refuses every input before access. Contract executes absent/invalid opt-in, missing/absent/directory/invalid-content manifests and owner-only/group/other permissions. There is no surviving live manifest consumer. |
| Lines 35–85 Agent/Link metadata projection, directory activation, GTK setup | Retired fixture coupling, not a service guarantee. Agent credentials and user stores are untouched. Existing Agent ownership/storage tests run independently. |
| Lines 105–114 cancel confirmation then current-device read | Retired UI expectation. No revoke is performed by the retired entrypoint, even with former opt-in; manifest/state bytes stay unchanged. Service fixtures verify acknowledged credentials before revocation. No replacement cancel dialog is claimed. |
| Lines 115–132 self revoke and denial | `TestDeviceCanInspectAndRevokeOnlyItself` exercises HTTP self-read/delete and rejects authorization after revoke; `TestDeviceCredentialCanBeRevokedIndividually` proves peer authorization survives. `TestDeviceScopesAreEnforcedPerRoute` checks HTTP 401 for insufficient authorization. These compose service denial coverage, not a rerun of the deleted client's exact post-revoke GET. |
| Lines 133–137 Agent connected; Link metadata removed from fake store | Retired UI/store expectation. No surviving service harness constructs an Agent endpoint or writes Link metadata into it. Existing Agent setup/gateway tests cover ownership, saved credentials and no replay. |
| Lines 139–159 pair process / local handoff shape | No installed pair subprocess survives. `TestPairingAdvertiseHostUsesLoopbackForExplicitLocalMode`, `TestSameDeviceOutputContainsOnlyOpenURL`, `TestPairOpenURLIsServedByThePairingBroker` cover loopback selection and `/open` output with isolated fixtures. |
| Lines 160–179 status 200, no-store, bounded HTML and extracted link | `TestPairOpenURLIsServedByThePairingBroker` and `TestPairOpenPageIsSecureResponsiveAndLaunchesWing` preserve status, no-store and secret-free handoff content. Expiry/method/escaping tests remain selected. `TestDecodeJSONRejectsBodyBeyondLimit` preserves service input bounds. The 65,536-character limit was a guard on this deleted harness's HTML parser; no surviving runner fetches/parses HTML, so there is no equivalent consumer or new unbounded parser. |
| Lines 180–195 QR/paste/pairing controls, clipboard and fresh fake-store token | Retired product expectations, not supported UI. No clipboard or product pairing input survives. `TestPairingBrokerInspectsAndExchangesOnce` checks isolated issuance, pending acknowledgment and exact idempotent replay; `TestPairingBrokerRejectsWrongOriginAndCode` checks admission denial. |
| Lines 196–204 new-client read, cleanup revoke, pair exit and GTK exception | Retired product/process expectations. Service tests use temporary stores and defer broker/response cleanup. The offline runner has no installed credential to revoke, no clipboard/display and no scratch directory to clean. Wrapper regression tests verify exact failure codes 37/41; Go fixtures enforce a 60-second package timeout. |

## Execution

Environment: Linux amd64, Flutter 3.44.2 (framework `c9a6c48423`),
Dart 3.12.2, Go 1.26.1. Cached dependency resolution used
`flutter pub get --offline`; `pubspec.lock` remained unchanged.

Discriminating RED: new retirement guard failed because the old integration file
existed. Runner contract failed on old exit behavior and missing offline runner.
GREEN: the retirement and runner tests passed after the scoped change.

Final acceptance is executed through `finish_task.py` with explicit owned files:

```bash
bash -n scripts/run_linux_live_security_e2e.sh scripts/run_linux_live_retained_security_service_e2e.sh
dart format --output=none --set-exit-if-changed test/tooling/linux_security_runner_contract_test.dart test/tooling/enrollment_retirement_contract_test.dart
timeout 180s flutter analyze --no-pub
timeout 180s flutter test --no-pub --concurrency=1 --reporter expanded test/tooling/linux_security_runner_contract_test.dart test/tooling/linux_feature_runner_contract_test.dart test/tooling/linux_visual_runner_contract_test.dart test/tooling/linux_profile_runner_contract_test.dart test/tooling/enrollment_retirement_contract_test.dart test/tooling/hermes_domain_authority_contract_test.dart test/features/profiles test/core/hermes/setup test/features/hermes_chat/gateways
timeout 180s bash scripts/run_linux_live_retained_security_service_e2e.sh
git diff --exit-code -- pubspec.lock
git diff --check
```

The retained runner executes fixed Go app/state tests with `GOPROXY=off` and
`GOTOOLCHAIN=local`: no downloads, personal runtime or external service target.
Go fixture loopback brokers are temporary test listeners, not installed service
start/restart. Deterministic shell wrappers exercise the actual scripts without
starting GTK, Flutter integration or a service. Their failures are not real
provider failures.

The native review handoff records final command results, exact finish branch/SHA
and original admission. The SHA is recorded there rather than self-embedded in
its own commit. No review approval, main integration or publication is implied.

## Remaining gaps

NOT_CHECKED: live GTK, provider, Android, installed service, packaging and release
behavior. No personal state or credentials were read or mutated. The last-client
slice and subsequent service/packaging retirement remain open; retained service
security tests must stay until that service is actually retired. Independent
same-card review and coordinator delivery remain pending.
