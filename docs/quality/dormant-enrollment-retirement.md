# Dormant enrollment retirement — t_17a16299

Historical implementation receipt for t_17a16299: no worker commit was made;
that card reserved the commit for the coordinator. The successor task context
records approved review run 151 and integrated commit
`edc9a109cc31e7c3628788c9ea24e835dfbbabcc`. The original evidence below is retained.
See [the API retirement successor](#agent-enrollment-api-retirement--t_a50d813a)
for current scope. CONNECTION-LINK-REMOVAL remains in progress; no ledger changes.

## Source and admission

Base: `96d94f5c692361dff038d9cd61c0fc140f791b9a`.
Original `pass_workspace.py` guard returned `worker_start_admitted` before the
first edit, using manifest SHA-256
`c33dc64ec7af462218c883ca7ba2cdaa3feec15e077dc863820ba672f12784bc`.
The original native workspace is the task's `db9d399dd9e886f8-e5c79c28f4794d1fa267fcde238a258c`
scratch directory. No repin, canonical edit, runtime change or upstream edit.

Final scoped fingerprint (before this receipt):
`403a66057c3f7b7746eced99cb3bc010e0faab69aebc0b5e069ca9b48865320a`.
Calculation: sorted unique changed/untracked paths plus `pubspec.yaml` and
`pubspec.lock`; SHA-256 over each UTF-8 path, NUL, and file bytes (or `<deleted>`).
Lockfile SHA-256: `f089602c321af4a65d6f1dc70b6adef724079bedc8e4f1d0496f7b8e22641c89`.
Flutter 3.44.2 / Dart 3.12.2 on Linux. Existing cached dependencies were resolved
with `flutter pub get --offline`; manifest and lockfile remained unchanged.

## Acceptance evidence

- Removed the unused enrollment controller, inspect/exchange provider wiring,
  payload parser, readiness/computer guide widgets and exclusively used transport
  classifiers. Production caller search found the controller only in its own
  provider and retired readiness widget; remaining callers were test fixtures.
- Kept `hermesConnectIntentSourceProvider` at its existing import location with
  the original platform source construction. WingApp's consume/discard flow,
  accessible generic rejection and public navigation remain unchanged.
- `test/tooling/enrollment_retirement_contract_test.dart` failed before deletion
  because the production provider still constructed `HermesEnrollmentController`;
  after deletion it passes. It guards enrollment source against management imports,
  parsing, inspect/exchange and endpoint-store wiring, and retains the ingress seam.
- Retained cold/warm/malformed rejection tests, no raw-input display, no clipboard,
  scanner, network/connect or writes, exact saved records, owner/profile/session,
  drafts, public Cancel and platform Back. Only overrides and counters for the
  deleted controller were removed. Direct entry, absent/denied capabilities and
  Android SSH/Remote/Termux order remain covered by existing tests.
- Native fixture imports and inventory were closed without removing direct Agent
  assertions. Existing `management_attempts` receipts now count forbidden
  `localWingLinkHostProvider` construction, rather than callbacks on a nonexistent
  enrollment controller. Local fixture `management` uses the same actual Link
  construction counter. These are not network-operation counts or fresh native
  qualification receipts.
- Replaced the obsolete native/Android fixture pairing journey with generic
  rejection/direct-options recovery. A widget test exercises that production
  screen through the Maestro fixture router. Android Maestro YAML was updated,
  but was not run on Android.
- Core Link service/client, API methods/models, secure store/raw records, scanner
  and platform packaging, profile/provider management and localization unchanged.
  Updated [current enrollment guidance](../getting-started.md#direct-agent-connection).

## Executed checks

All commands ran in the original task workspace, with bounded timeouts.

```text
timeout 3m flutter test --no-pub --reporter expanded test/tooling/enrollment_retirement_contract_test.dart
```

RED: failed on dormant controller construction. The first attempt could not run
without package configuration; cached offline resolution supplied it. GREEN: pass.

```text
timeout 10m flutter test --no-pub --concurrency=1 --reporter expanded test/features/enrollment test/router test/features/local_setup test/app/wing_app_connect_intent_test.dart test/app/hermes_connect_intent_stream_test.dart test/integration test/core/hermes/setup test/shared/security test/tooling/enrollment_retirement_contract_test.dart test/features/hermes_chat/gateways test/features/hermes_chat/screens/hermes_chat_saved_endpoint_edit_test.dart test/features/profiles test/features/gateway
```

Final run: 573 tests passed, 2m25s. Prior run: 572 passed, one new fixture test
failed because its lazy list item had not been scrolled into existence; fixed
with the existing `scrollUntilVisible` pattern. After the final formatting-only
change, the two new tests were rerun and passed at the fingerprint above:

```text
timeout 3m flutter test --no-pub --reporter expanded test/features/enrollment/legacy_fixture_rejection_test.dart test/tooling/enrollment_retirement_contract_test.dart
timeout 5m flutter analyze --no-pub
git diff --check
```

Final analysis: no issues (1.8s). Earlier analysis found obsolete integration
fixture overrides, then one newly unused import; all closed. Changed-file
`dart format --output=none --set-exit-if-changed` passed: 15 files, zero changes.
Current guidance's 15 relative local file links exist. No localization input
changed, so no `flutter gen-l10n` was needed.

## Skill application

Explicit task request; verified engineering router revision
`1be8e34187e34647bb83adc3a1323b26ae6f6abe`, under
`hermes-toolset/skills/engineering/upstream/skills/`:

- `test-driven-development/PROTOCOL.md`: discriminating production source guard
  before deletion, observed RED then GREEN; retained behavior tests passed.
- `deprecation-and-migration/PROTOCOL.md`: traced production, test and integration
  consumers, removed dormant code only, kept ingress and existing stored access;
  source closure and 573-test regression pass, no data migration.
- `security-and-hardening/PROTOCOL.md`: untrusted intent/share boundary discards
  rather than exchanges; preserved generic errors, no secret rendering/replay,
  secure-store assertions and exact owner/draft checks; rejection/setup/security
  suites passed. No new authentication or native authority.
- `frontend-ui-engineering/PROTOCOL.md`: retained production live-region rejection,
  Back/Cancel, compact 200% text, keyboard and Android ordering checks; same-screen
  fixture recovery passed. No redesign or native/platform support claim.
- `ponytail:ponytail`: kept the existing provider seam, deleted the obsolete
  implementation instead of adding an adapter; no dependencies or migration.

## Exact residual consumers and limits

Remaining product consumers to inspect in the next slice:
`lib/features/profiles/screens/profiles_screen.dart`,
`lib/features/profiles/widgets/profile_editor_sheet.dart`,
`lib/features/profiles/widgets/profile_directory_browser_sheet.dart`, and retained
`lib/features/local_setup/providers/local_hermes_setup_provider.dart` host provider.
`lib/features/gateway/screens/gateway_screen.dart` retains legacy compatibility
seams although its normal route no longer constructs management. The enrollment
API methods/models were residual at this receipt's base and are removed by the
successor below; `lib/core/hermes/setup/secure_hermes_endpoint_store.dart` retains
legacy raw records unchanged. `lib/main_local_setup_recovery_e2e.dart` is an old fixture
consumer. Wing Link service/installer/platform packaging, native scanner,
obsolete localization and stale historical visual/fixture controls remain separate
successors, not silently removed here.

Exercised only Linux-hosted Flutter test VM and deterministic Linux/Android
widget variants. Native Linux integration, Android Maestro/device execution,
physical secure storage, browser build/E2E and live authentication NOT_CHECKED.
No commit, integration, push, PR, deployment or release. Review approval and
coordinator-owned commit/integration remain pending; measured cost is unknown.

## Agent enrollment API retirement — t_a50d813a

Status: implemented offline; independent same-card review pending. Local task
commit is produced by `finish_task.py` and its exact SHA/ref and check results
are recorded in the native card handoff. No integration or publication by this
worker. CONNECTION-PATHS / CONNECTION-LINK-REMOVAL remains incomplete;
CONNECTION-LINK-RETIREMENT remains dependency-gated.

### Source and admission

Base: `edc9a109cc31e7c3628788c9ea24e835dfbbabcc`. Before the first file edit,
the original pinned `pass_workspace.py` command returned `worker_start_admitted`
using manifest SHA-256
`7ca5e63ec980fc622b10e9e9df5374adc38a324e2d4a2b8d026cf86cd34594c2`.
No admission replay, source repin, ledger edits or upstream edits.
Correction recorded on the card: pinned `planning_context.files` contains only
`goals.json`, not the promised TODO text. Its parent task is `in_progress`.

Scoped source fingerprint, excluding this documentary receipt:
`8d45ce76081ae77b82e12cd9cf3eef36a2a12edca7865ec5e09e2e805e117bc6`.
SHA-256 over sorted paths, each UTF-8 path followed by NUL and file bytes:
the four changed Dart files plus `pubspec.yaml` and `pubspec.lock`.
Lockfile SHA-256 remains
`f089602c321af4a65d6f1dc70b6adef724079bedc8e4f1d0496f7b8e22641c89`.
Flutter 3.44.2 / Dart 3.12.2, Linux-hosted deterministic test VM.

### Acceptance evidence and caller closure

- All Wing Dart source callers (production, tests, integration and fixture
  entrypoints) closed: inspect/exchange had no live caller; the preview and issued
  token had four model-only tests. The issued connection and epoch conversion
  helper were exclusively internal to those enrollment response models.
- Removed `inspectEnrollment`, `exchangeEnrollment`, `_postJsonUnauthenticated`,
  both enrollment URI getters, `HermesEnrollmentPreview`,
  `HermesIssuedOperatorToken`, `HermesIssuedConnection` and its preview's timestamp
  helper. Removed only the four obsolete model tests; no data migration.
- Extended the existing source guard across `lib/core/hermes`, including the
  enrollment route prefix, to prevent restoring the dead exchange elsewhere.
  Observed RED on `enrollmentInspectUri` before deletion and GREEN afterward.
- Added one authenticated POST regression asserting unchanged bearer/JSON
  headers and request body, plus failure on invalid JSON and non-object replies.
  Generic authenticated API helpers, profile/runtime/config operations,
  concurrency headers, bounded decoding and transport errors are unchanged.
- Direct entry, ingress/discard/rejection, accessible recovery, owner/profile/
  session/draft preservation and exact stored records passed in the required
  regression union. Secure store and its legacy fields are untouched.
- Existing barrel exports remain valid; no imports, fixtures, dependencies,
  platform/scanner packaging, localization, Wing Link or local_setup changes.
- Read-only Agent reference at `158fd638da1629c8e62caf9ade1515d162def8ab`:
  searches in gateway, tests and official Desktop source found no matching
  inspect/exchange route/symbol. Inspected `gateway/platforms/api_server.py`
  `_check_auth` and nearest `tests/gateway/test_api_server_bind_guard.py` tests:
  bearer authentication and loopback key requirements remain upstream authority.
  This is checkout inspection, not a current runtime qualification claim.

### Executed checks

All commands run in the admitted workspace; finish gate reruns the acceptance
commands against the final owned files before creating the local task commit.

```text
timeout 3m flutter pub get --offline
git diff --exit-code -- pubspec.yaml pubspec.lock
timeout 3m flutter test --no-pub --concurrency=1 --reporter expanded test/tooling/enrollment_retirement_contract_test.dart
timeout 10m flutter test --no-pub --concurrency=1 --reporter expanded test/core/hermes/hermes_api_test.dart test/core/hermes/setup test/shared/security test/features/enrollment test/router test/app/wing_app_connect_intent_test.dart test/app/hermes_connect_intent_stream_test.dart test/tooling/enrollment_retirement_contract_test.dart
timeout 3m flutter test --no-pub --concurrency=1 --reporter expanded test/core/hermes/client/platform/hermes_api_transport_io_test.dart test/core/hermes/client/hermes_web_read_adversarial_test.dart
timeout 3m flutter test --no-pub --concurrency=1 --reporter expanded test/core/hermes/hermes_api_test.dart --plain-name 'authenticated Agent POST rejects malformed response objects'
timeout 5m flutter analyze --no-pub
dart format --output=none --set-exit-if-changed lib/core/hermes/client/hermes_api_client.dart lib/core/hermes/client/hermes_api_config.dart test/core/hermes/hermes_api_test.dart test/tooling/enrollment_retirement_contract_test.dart
git diff --check
```

Initial RED attempt lacked package configuration; cached offline dependency
resolution succeeded without manifest/lock changes. Actual RED then failed only
the new core guard; the older feature guard passed. First GREEN union: 235 tests
passed in 1m32s. Transport/adversarial union: 38 passed in 5s, including typed HTTP
status, socket failure, size bounds and malformed read replies. The later added
authenticated POST regression passed separately (one test); the final gate reruns
the union with it included. Analysis: no issues (9.5s). Format: four files,
zero changes; diff check passed. Final gate results supersede these initial counts.
Final caller scan found retired symbol names only in the negative source guard.
The first finish gate passed 236 union tests, 38 transport/adversarial tests,
analysis and format, but its overbroad route-prefix scan also matched the retained
`wing-cli` broker test in `test/tooling/package_scripts_contract_test.dart`.
That test calls a separate CLI broker, not the Agent client; CLI/packaging
retirement is outside this card. Corrected the check to scan retired symbols
through all Dart sources and the route prefix through `lib/core/hermes` only.
No product change or validation bypass; the complete finish gate is rerun.
Scoped local documentation links are checked before commit.

### Skill application and limits

Skill application: explicit minimal-deletion request;
`ponytail:ponytail` from the verified installed skill path; delete unused code
instead of adding an adapter or migration; source guard RED/GREEN, retained
behavior tests and caller closure verify the decision.
`hermes-toolset:engineering` and the bundled engineering cycle were read as
requested; zero additional protocols applied because the accepted contract and
repository checks already define the method. No unused protocol revision claim.

Next separate slice: trace residual local_setup/Gateway compatibility consumers;
broader profile/provider, service/installer, scanner, platform packaging and
localization retirement remain outside this card. Saved legacy records remain.
Devices, native Linux UI, physical secure storage, live Agent authentication and
browser execution NOT_CHECKED. No production services or inference exercised.
Review approval, canonical integration and delivery are pending; cost unknown.
