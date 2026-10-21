# Dormant gateway enrollment retirement — t_ca9d55fd

Status: implemented and checked offline; independent same-card review pending.
The final local task ref/SHA and repeated acceptance receipts are recorded in the
native card handoff by `finish_task.py`. This worker does not integrate or publish.
[CONNECTION-LINK-REMOVAL](../tasks/work-queue.md#current-work-queue) remains in progress;
CONNECTION-LINK-RETIREMENT is not closed.

## Source and admission

Base: `b8bcf68d80c7ca56a5a21d843f2ca17bb320846d`.
Before the first edit, the original `pass_workspace.py` command returned
`worker_start_admitted` with manifest SHA-256
`32e105c490962d9da4c778dbc87cd5143e5d24b60be222f1e17102b89a06ec13`.
The isolated native workspace is the task's
`d38c007be4a61b31-fdabcf67068c4dd79e4b4ddeade69e71` scratch directory.
No manifest repin, canonical edit, upstream/runtime edit, or admission replay.

Scoped fingerprint before this documentation file:
`fa8d54d0aa3952c9fde455f9f4e742e7f9c452bfa1aa69962f185452da6cdc0d`.
Computed over sorted changed Dart paths plus `pubspec.yaml` and `pubspec.lock`,
using SHA-256 of each UTF-8 path, NUL, and file bytes.
Lockfile SHA-256 remains
`f089602c321af4a65d6f1dc70b6adef724079bedc8e4f1d0496f7b8e22641c89`.
Toolchain: Flutter 3.44.2 / Dart 3.12.2, Linux-hosted Flutter test VM.

## Acceptance evidence and caller closure

- Removed only `clearWingLinkEnrollment`, the ignored
  `PendingWingLinkCredentialRecovery` typedef, and constructor argument
  `pendingCredentialRecovery` from
  `lib/features/hermes_chat/gateways/hermes_gateway_directory.dart`.
  Caller tracing across Wing Dart source found no production mutation caller and
  one obsolete test caller. The production provider in
  `lib/features/hermes_chat/providers/hermes_channel_provider.dart` does not inject
  recovery and needs no change.
- Correction recorded on the card: four recovery-argument injections occur across
  three test files, including two directory tests. All are removed. Other
  constructor callers, fixtures, exports, configuration, and dependencies need no
  changes; no added scope paths.
- Replaced the obsolete revocation test with public saved-directory operations:
  activate one profile, inspect another host, reconnect and refresh. All three
  saved records retain their exact config objects and credentials; no endpoint
  store save/saveAll/delete/clear occurs, and the active Agent owner is unchanged.
- Pending-record refresh/startup/foreground/timer/reconnect tests retain exact
  saved objects and restored Agent profile/session. Removed spies on the ignored
  callback; added no-saveAll/delete/clear assertions. The existing independent
  HTTP-construction trap remains intact and passes through cancelled/replaced
  startup and reconnect, proving no automatic recovery network construction.
- Profiles Cancel/create/edit/model selection/delete now assert exact saved-record
  preservation rather than callback spies. Store writes/deletes/clear remain zero;
  the actual API test still checks Agent-only origins, bearer authorization,
  revision headers and exact profile/model mutation payloads. Gateway UI keeps
  legacy controls absent, explicit disconnect/cancel/reconnect, persisted Agent
  authentication and every legacy-field retention assertion.
- Added a negative source guard across `lib`, `test`, and `integration_test`
  (excluding its own file), preventing all three retired symbols from returning.
  RED failed on `clearWingLinkEnrollment` before deletion; GREEN passes.
- Endpoint store/config/model, secure-storage implementation, legacy grouping,
  active routing, session-restoration retry/no-replay, validation and authorization
  code are unchanged. The required union includes secure-storage isolation,
  retention, owner-fencing and restoration regressions. No installed records,
  private credentials, services, or upstream repositories were accessed.

Decision: delete the unused mutation and ignored seam, retain public behavior tests
instead of inventing a replacement callback. Evidence: caller closure and inspected
constructor; reason: minimum complete retirement with no migration; check: negative
source guard and saved-state/HTTP-trap regressions. Ponytail full was supplied in the
request; no supporting skill protocols were needed beyond the accepted repository
checks and bundled engineering-cycle guidance.

## Executed checks

All commands ran in the admitted workspace. The final finish gate repeats required
acceptance commands against the same owned files before committing the task ref.

```text
timeout 3m flutter pub get --offline
git diff --exit-code -- pubspec.yaml pubspec.lock
dart format lib/features/hermes_chat/gateways/hermes_gateway_directory.dart test/features/hermes_chat/gateways/hermes_gateway_directory_test.dart test/features/profiles/profiles_screen_test.dart test/features/gateway/gateway_screen_test.dart test/tooling/enrollment_retirement_contract_test.dart
timeout 3m flutter test --no-pub --concurrency=1 --reporter expanded test/tooling/enrollment_retirement_contract_test.dart
timeout 5m flutter analyze --no-pub
timeout 10m flutter test --no-pub --concurrency=1 --reporter expanded test/features/hermes_chat/gateways test/features/profiles test/features/gateway test/core/hermes/setup test/tooling/enrollment_retirement_contract_test.dart
git diff --check
```

Offline resolution passed with manifest/lock unchanged. Source guard: observed RED,
then seven tests passed GREEN. Required union: 429 passed in 52s. Analysis: no issues
in 6.1s. Five changed Dart files formatted; diff check passed. One initial multi-file
patch validation rejected ambiguous contexts without changing files; narrowed
contexts applied successfully. No failing implementation test or analysis retries.
Local documentation links and final changed-file formatting are verified by the
finish gate. Actual review time and inference cost are unknown.

## Residual consumers and qualification limits

The excluded `enrolledGatewayIdForManagedProfile` still has the internal caller
`reconcileManagedProfileRename`; both remain unchanged pending their separate caller
trace. Legacy host grouping/projection and rename metadata preservation remain in
the directory. `lib/core/hermes/setup/secure_hermes_endpoint_store.dart` retains
legacy records; `lib/core/wing_link/`, `wing_link/`, installers/platform packaging,
scanner and obsolete localization remain outside this card. The next bounded slice
is the remaining directory managed-profile reconciliation caller trace, not a
claim that complete Link retirement or connection-path qualification is done.

Exercised: deterministic Linux-hosted Flutter VM unit/widget/source-contract tests,
including adaptive UI and fake secure storage. Native Linux UI, Android/device,
physical keychain, live Agent/provider authentication, browser build/E2E and packaged
runtime qualification NOT_CHECKED. No new imports or runtime delivery dependencies.
No main integration, push, PR, deployment, service changes, or release. Implemented
is distinct from independently reviewed, platform-qualified and delivered.
