# Dormant Local Link controller retirement

Task: `t_af59ba53`; goal: CONNECTION-PATHS; parent continuation:
CONNECTION-LINK-REMOVAL (not closed by this slice).

## Source and admission

Base: `67f5eac7453d765b2b65029c0ee1fe49358cdaca`.
The original `pass_workspace.py` admission ran exactly once, before the first
edit, against the original isolated workspace and manifest
`pass-4003f0fd4e83de74-8a72cc54b45140f2a55350c937914ff3.json`, with SHA-256
`8b2dc9fd3b3eead4ff2db1870fc9315d39ee739dcedd3061037de309bc29aea7`.
It returned `worker_start_admitted`. Original tool history, not this receipt,
is the admission evidence. Admission was not replayed after edits.

`flutter pub get --offline` passed; before/after hashes remained:

- pubspec.yaml: `f0989f9a42f11321a0737dccfa073d506a7f4f79e543f5a0cddde08a53ce35d2`
- pubspec.lock: `f089602c321af4a65d6f1dc70b6adef724079bedc8e4f1d0496f7b8e22641c89`

## Delivered implementation

Removed the unused host factory, controller provider, installation state machine
and status enum. The existing `localLinuxSetupAvailableProvider` import seam and
native-Linux-only expression are unchanged. Direct setup screens, discovery,
Agent transport, secure stores and credentials are untouched.

Deleted the exclusively synthetic recovery entrypoint and controller-only tests.
Removed unused host overrides and vacuous construction counters from scoped
widget/native fixtures, without removing their direct authentication, denial,
Cancel/Back, owner/session, storage-isolation or no-replay assertions.
A source guard now rejects management imports/construction in local setup and
the scoped entrypoints; it is not a claim of measured network-operation counts.

Decision: delete the obsolete installation harness rather than implement another
backend. Evidence: production callers use only the availability seam; the accepted
[complete-removal ADR](../adr/product.md#complete-removal-including-legacy)
requires retirement. No dependency or abstraction was added.

Bounded caller additions identified before editing:

- `test/features/enrollment/hermes_local_setup_enrollment_test.dart`: retain real
  discovery/mutation/forbidden-read assertions instead of deleted factory counters.
- `playwright/tests/regression/local-setup-recovery.spec.mjs`,
  `playwright/local_setup_recovery.config.mjs`,
  `scripts/support/local_setup_recovery_snapshot.py`: delete the exclusively
  retired fixture's spec/config/snapshot closure.
- `playwright/tests/regression/connection-production-matrix.spec.mjs` and
  `playwright/support/connection_production_matrix_fixture.mjs`: retire obsolete
  installation cases/actions/counters, preserving direct retry, saved-edit,
  two-owner and actual management-request negative-control checks.
- `scripts/support/{direct_first_run,desktop_welcome_recovery,remote_auth_explanation,remote_connection_retry,local_setup_enrollment}_native.py`
  and their corresponding `test/tooling/*_native_test.py`: align receipt validators
  and tests with the removed construction counters. Local receipt admission now
  checks the existing direct journey's explicit retry/no-replay observations,
  rather than old installation counts. Request allowlists, process fencing,
  isolation and credential checks remain intact.

No executable caller of the deleted symbols or entrypoint remains; guard strings
and historical documentation are not callers. Fixture imports/exports and launch
references were inspected. Historical receipts were not rewritten.

## Executed checks before final commit gate

The new guard was RED against the original controller: expected no
`core/wing_link/` import, actual import found. After removal, the guard and
local-setup tests were GREEN: 13 tests passed. An earlier accidentally unscoped
invocation ran the unchanged canonical guard (2 passes); it is not RED evidence.
All edits were confined to the isolated workspace.

The required suite passed 164 tests (Flutter reporter elapsed 1m27s):

```sh
flutter test --no-pub --concurrency=1 --reporter expanded test/features/local_setup test/features/enrollment test/router test/integration test/features/hermes_chat/screens/hermes_connection_primary_entry_test.dart test/core/hermes/setup test/shared/security test/tooling/enrollment_retirement_contract_test.dart
flutter analyze --no-pub
```

Analyzer: no issues, 6.6s reported. Changed Dart files were formatted;
`git diff --check` passed. Python receipt/launcher tests passed: direct first-run
5, desktop welcome 5, remote auth explanation 3, remote retry 6, local setup 2.
Both changed JavaScript modules passed `node --check`.
Playwright `--list --reporter list` with the cached installed package discovered
11 direct matrix tests in 3 files, matching the revised aggregate guard; this
checked import/export closure only and did not launch a browser or server.

A mistakenly unscoped broad Python probe ran against unchanged canonical tests:
65 tests, one error due to missing `asyncssh` in that interpreter. It is not
candidate acceptance evidence; no package was installed and no unrelated fix
was made. Scoped candidate Python checks above passed.

The final `finish_task.py` gate repeats the required argv checks and commits only
explicit owned paths to `agent/wing/t_af59ba53`, preserving workspace HEAD. Exact
commit, final counts/durations, complete owned fingerprints and gate output are
recorded in the native review handoff. Review approval, integration and publication
are separate from this implementation receipt.

Stable production fingerprints (SHA-256):

- availability provider: `3b05b55558763e844c9a07b46d5d7d5cda1027cc51955a205b1495bd2baad96f`
- matrix entrypoint: `f7dc25f305dbf958fe349f850b0684b8f0d93abbbcc303c56401a318c71cbffc`
- negative source guard: `3d03b41f50cc3a7dee9d75fb266494718be615308e7d5360566c4055305fb368`

## Acceptance boundaries and successors

Linux and Android were exercised as deterministic widget variants, not native
GTK, Android devices or real authentication. Welcome tests retain Android SSH
first, Remote second and on-phone Termux third; direct Linux metadata discovery,
keyboard access, missing/denied explanations, Back/Cancel and raw saved records
remain covered. Owner tests retain exact origin/profile/session and unchanged
requests after navigation; store/redaction tests remain part of the passing suite.

NOT_CHECKED: browser execution, native/device/provider qualification, platform
bundles, physical secure storage, installers, services and live authentication.
JavaScript syntax and fixture closure inspection are not browser qualification.
The retained native Local launcher still has historical render-count expectations;
this card does not qualify that launcher or rewrite platform evidence.

Remaining milestone gaps: Gateway/Profiles consumers, stored management metadata
and service/packaging retirement. Those excluded successors remain unfinished.
No parent ledger, upstream runtime, platform host, installer or personal service
was changed. No push, merge, PR, deployment or service operation was performed.
