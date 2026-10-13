# Linux profile harness Link retirement

Task: `t_b9743ea7`; admitted base: `c08ccc301d2e9bcfd05186ac198f2a4c11abfcd4`.
This is one offline CONNECTION-LINK-REMOVAL slice, not parent completion or
live product qualification. Independent native review and coordinator integration
remain pending; no publication is performed by this worker.

## Delivered change and scope

[The Linux runner](../../scripts/run_linux_live_e2e.sh) now invokes only the
unchanged [real Agent profile journey](../../integration_test/linux_real_profiles_e2e_test.dart).
It requires only `WING_LIVE_PROFILE_MANIFEST`, retaining owned regular-file and
owner-only permission checks and adding explicit symlink rejection. Credentials
remain runtime-file inputs, not Flutter arguments. Display execution and the
headless `xvfb-run -a` path retain exact failure propagation.

The exclusively deprecated `integration_test/linux_live_wing_link_test.dart`
scenario is deleted: its catalog, profile creation, rename and approval-driven
deletion were Link operations injected into the profile editor. It contains no
independent Agent/security journey that needs relocation. The surviving Agent
journey still covers real provider turns, session CRUD/fork/inventories,
reconciliation, steer/stop and no replay. All other live/security harnesses,
stored data, runtimes, services, packaging and dependency manifests are unchanged.

Decision: simplify the existing entry rather than add a compatibility option or
replacement harness/backend. Historical Linux receipts describe their original
snapshots; their old two-manifest launcher descriptions are not current setup
instructions. See the [removal decision](../adr/product.md#complete-removal-including-legacy).
Other live harnesses still consume the retained Link client; client/service and
Linux bundling retirement are later slices.

## Admission and acceptance evidence

Before the first edit, the original pinned command returned exit 0 and
`worker_start_admitted`:

```text
python3 /home/xel/git/gormes/hermes-toolset/skills/autowork/scripts/pass_workspace.py --manifest /home/xel/.hermes/profiles/wing/autowork/pass-ad529d2176b234b6-bb1a6d376a2b4bc585e205ff7e72584d.json --manifest-sha256 e88956026fee051176ecb848f93c550260ff94e0819324f2477a30b5f2f22396 --workspace /home/xel/.hermes/profiles/wing/cache/scratch/autowork-passes/ad529d2176b234b6-bb1a6d376a2b4bc585e205ff7e72584d
```

The original run tool history, not this receipt or a replay, proves ordering.

[Runner regressions](../../test/tooling/linux_profile_runner_contract_test.dart)
execute a copy of the actual shell entry in an isolated fixture with fake Flutter,
a non-secret owner-only manifest, no inherited environment and no Link inputs.
They assert the exact surviving target argv, no manifest path/content in argv,
exit codes 37 and 41, absent/missing/directory/symlink rejection, and rejection of
group/other-readable permissions before Flutter. Display mode never invokes the
wrapper; headless mode invokes only a fake wrapper, never Xvfb. The unchanged
`-O` owner predicate is also inspected in the runner.

RED: the new fixture suite failed all six tests before the runner edit, with the
obsolete Link-manifest prerequisite preventing execution. GREEN: all six passed
after the edit. The [retirement guard](../../test/tooling/enrollment_retirement_contract_test.dart)
rejects restoration of the deleted target or its launcher requirements.

Executed in the isolated Linux workspace, all exit 0:

```bash
flutter pub get --offline
bash -n scripts/run_linux_live_e2e.sh
dart format test/tooling/linux_profile_runner_contract_test.dart test/tooling/enrollment_retirement_contract_test.dart
flutter analyze --no-pub
flutter test --no-pub --concurrency=1 --reporter expanded test/tooling/linux_profile_runner_contract_test.dart test/tooling/enrollment_retirement_contract_test.dart test/tooling/hermes_domain_authority_contract_test.dart test/features/profiles test/core/hermes/setup test/features/hermes_chat/gateways
git diff --exit-code -- pubspec.yaml pubspec.lock integration_test/linux_real_profiles_e2e_test.dart
git diff --check
```

Analysis: no issues, 5.8 seconds. Focused suite: 365 tests passed, 44 seconds.
The finish gate repeats acceptance against the exact owned files and returns the
local task branch/commit and check receipts in the native review handoff.

Execution correction: the first dependency/test invocation omitted the explicit
workspace and ran in canonical checkout; dependency resolution succeeded but the
new test did not exist there, so the test failed to load. Canonical tracked status
was verified clean afterward; all implementation and subsequent checks used the
explicit isolated workspace. No canonical source edits occurred.

## Qualification limits

Implemented: runner retirement and regression coverage. Qualified: Linux-hosted
offline shell fixture/source/widget checks only. Delivered: NOT_CHECKED; pending
independent review, coordinator integration and publication. Live Agent/provider,
real GTK/display/Xvfb, Android/device, packaging and installed-service behavior
were NOT_CHECKED and are not inferred from these checks. No actual credentials
were accessed; no app, provider, service or real Xvfb was started.

CONNECTION-LINK-REMOVAL stays in progress and CONNECTION-LINK-RETIREMENT stays
open. The accepted Android order (SSH, Remote server, on-phone Termux) is intent,
not shipped/device evidence. Remaining consumers and delivery/service closure
remain separate work; this card does not modify the parent ledger.
