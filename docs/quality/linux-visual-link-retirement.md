# Linux visual tour: Link consumer retirement

Task: `t_85d38a1d` · Goal: `CONNECTION-PATHS` · Parent: `CONNECTION-LINK-REMOVAL`

Base: `ae18e40c629ff0b2ad7847c165cc51f9812268f8`.
Status: offline implementation; independent review and integration pending.
The exact local task commit and check argv are bound by the native card's
`finish_task.py` receipt. This document is not live qualification evidence.

## Bounded change

The retained `integration_test/linux_live_visual_test.dart` and its shell runner
now require an isolated Agent profile manifest only, not a Link manifest or CLI.
Removed Link client construction, credential persistence, profile catalog/CRUD,
local approval subprocess and profile cleanup; removed obsolete directory browser,
paired-trust/revocation and pairing-only captures. No replacement compatibility
backend, new option or dependency was added. Saved connection actions are labelled
as Agent actions rather than paired-host management.

Retained direct Agent activation, light/dark route tour, settings and voice
preferences (not acoustic evidence), session creation, synthetic chat generation,
model picker, session action/search dialogs, disconnect/reconnect and exact-session
selection. Screenshot capture still refuses visible Agent secrets and the existing
host-path pattern across Text and EditableText, and writes refusal records instead
of images. Session deletion, widget/container/channel disposal and secure-store
clearing remain in the existing finally block. D-Bus/display wrappers, isolated XDG
keyring directories and mount-aware EXIT teardown remain in the runner.

The existing capture floor of 28 is unchanged: the retained route map still has
14 routes in each of two themes, before optional lower-content/action captures.
Append mode remains the existing cumulative-manifest mode, not proof of a complete
fresh route tour. A sensitive capture can be refused; the floor does not guarantee
any particular optional dialog was captured.

Runner admission rejects absent, non-regular, symlink, foreign-owned and
non-owner-only manifests before creating output or invoking external wrappers,
matching [the profile harness](../../scripts/run_linux_live_e2e.sh). Runtime files
are not passed as Dart defines or command arguments. The runner now honours TMPDIR
for isolated keyring storage and sets the private umask before output creation.
This does not change permissions on an already-existing output directory.

## Scope and regression evidence

Callers traced: the shell runner invokes this integration target; historical Linux
visual/compact/minimalist receipts cite that runner and remain historical evidence.
There are no package/config/export changes. The new shell fixture copies and
executes the actual runner with fake Flutter, D-Bus, display, keyring and mount
wrappers, empty inherited environment and a non-secret marker manifest. It proves
Agent-only admission, isolated storage cleanup, exact Flutter and keyring failure
propagation, and fail-closed missing/directory/symlink/permission admission. The
foreign-owner predicate is source-inspected, not exercised by changing file owner.
The retirement guard rejects restoring this consumer and checks retained Agent,
privacy and teardown source markers; it is not a rendered privacy test.

Before implementation, the focused test command failed six tests: five runner
checks stopped at the obsolete Link manifest requirement, and the new retirement
guard rejected the Link import. After implementation the focused pair passed
19 tests; the full requested affected set passed 371 tests.

Executed on Linux, offline:

- Initial hash-pinned `pass_workspace.py` guard: `worker_start_admitted`, before
  the first edit, against the base above. Original tool history is admission proof;
  do not rerun the initial-only guard against the edited workspace for review.
- `flutter pub get --offline`: passed; `git diff --exit-code -- pubspec.yaml pubspec.lock`: passed.
- `bash -n scripts/run_linux_live_visual.sh`: passed.
- `dart format integration_test/linux_live_visual_test.dart test/tooling/enrollment_retirement_contract_test.dart test/tooling/linux_visual_runner_contract_test.dart`: passed.
- `flutter analyze --no-pub`: passed, no issues (6.2 seconds).
- `flutter test --no-pub --concurrency=1 --reporter expanded test/tooling/linux_visual_runner_contract_test.dart test/tooling/linux_profile_runner_contract_test.dart test/tooling/enrollment_retirement_contract_test.dart test/tooling/hermes_domain_authority_contract_test.dart test/features/profiles test/core/hermes/setup test/features/hermes_chat/gateways`: passed, 371 tests (43 seconds).

The finish gate repeats acceptance on frozen owned files and records exact results,
including formatting, shell syntax, unchanged dependency inputs and diff whitespace.

## Not checked / remaining

The live visual runner was NOT executed. No real Agent/provider, display, D-Bus,
keyring, service, screenshot, microphone, Android or installed artifact was
qualified. No credentials, personal configuration, raw user stores, upstream code,
production code, packaging or other live/security/directory harnesses were changed.
No integration, push or deployment is claimed.

The parent remains in progress. Full client/service/bundling retirement remains
open under [the removal decision](../adr/product.md#complete-removal-including-legacy).
The next bounded slice is remaining mixed feature/security consumer retirement,
with evidence-bound preservation of their independent Agent/privacy checks.
