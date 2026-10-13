# Android live Maestro management-profile retirement

Task: `t_b5d4752a`, bounded implementation under CONNECTION-LINK-REMOVAL.
Base: `939c5074cf83791b20a9c744a01c43946c89472e`.
Status: offline implementation; independent native review and canonical integration
remain pending. CONNECTION-PATHS and the removal ledger remain open.

## Retired consumer

Decision: delete `scripts/maestro/gateway_profiles_qa.yaml`, not replace it with
simulated Agent administration. It created/renamed a real profile through obsolete
management controls and left a deletion approval for host cleanup.
`scripts/run_android_maestro_regression.sh` no longer selects that flow, generates
or validates `WING_QA_PROFILE_FIXTURE`, lists/rejects Wing Link approvals, or lists
and deletes Hermes profiles. With Maestro as its last command, Bash returns the
suite status directly, including failure.

The existing `android:maestro-regression` package entry remains unchanged. The
remaining 13 flows retain their original order, from
`.maestro/real-gateway-regression.yaml` through `scripts/maestro/chat_ux_qa.yaml`.
Explicit device selection, gateway/profile labels, session branching, selection,
metadata, concurrent sessions, process recovery, and unsupported capability checks
remain. The provider/model flow's assertions are unchanged; its comment now
correctly describes absent mutation controls rather than Link provider creation.
No production transport, credentials, stored user data or service packaging changed.

The package tooling contract retains canonical syntax-command references for
current flows. The [readiness audit](../runbooks/hermes-readiness-audit.md) no longer
advertises the removed flow as a current invocation. Historical qualification and
discovery receipts were not rewritten.

## Acceptance evidence

Original pre-edit admission ran successfully with:

```text
python3 /home/xel/git/gormes/hermes-toolset/skills/autowork/scripts/pass_workspace.py --manifest /home/xel/.hermes/profiles/wing/autowork/pass-8d76296c40528b26-b1f7f8a053774dbcae4d379a5f128813.json --manifest-sha256 b9a53dd905b38f40de65a569b56391409fd4f8253cbc06bfc1e57682097930ef --workspace /home/xel/.hermes/profiles/wing/cache/scratch/autowork-passes/8d76296c40528b26-b1f7f8a053774dbcae4d379a5f128813
```

Result: `worker_start_admitted`, exit 0, before the first edit. Original tool
history, not this receipt alone, is the admission evidence.

`test/tooling/enrollment_retirement_contract_test.dart` adds two regressions:

- The obsolete flow must be absent; runner and all selected flows cannot restore
  management/fixture dependencies. Provider/model fail-closed assertions remain.
- A temporary copied runner uses a fake Maestro and PATH sentinels for `wing-link`
  and `hermes`. Four combinations (status 0/17, default/explicit device) assert
  exact argv, unchanged ordered flow list and gateway/profile identity, exact
  suite exit status, and zero sentinel calls. No real CLI or device is used.

RED: the two tests failed on the original runner/flow (obsolete file still present;
successful fake suite incorrectly returned cleanup failure). GREEN: both passed
after retirement. Discrimination: deliberately appended `wing-link approvals list`
to the edited runner; both tests failed, one on the forbidden dependency and one
on the sentinel call. Removed that mutation; both returned GREEN. A temporary
Dart raw-string omission caused a compile failure while extending assertions and
was corrected before the discriminating check and final validation.

Executed offline on Linux:

```text
bash -n scripts/run_android_maestro_regression.sh
dart format test/tooling/enrollment_retirement_contract_test.dart test/tooling/package_scripts_contract_test.dart
timeout 5m flutter analyze --no-pub
timeout 5m flutter test --no-pub --concurrency=1 test/tooling/package_scripts_contract_test.dart test/tooling/enrollment_retirement_contract_test.dart
git diff --check
```

Shell syntax, formatting and analysis passed; focused suite passed 43 tests.
The finish-task gate reruns these checks against the final owned bytes (formatting
in check-only mode), along with local documentation link/anchor validation. Its
native handoff records the exact commit and task ref without self-referential
commit identifiers in this file.

Setup notes: an initial filtered test accidentally targeted the canonical checkout
and matched no tests; no live commands ran. The isolated snapshot initially lacked
package configuration. `flutter pub get --offline` resolved the existing lockfile
from cached dependencies; no dependencies or manifests changed. Subsequent tests
ran in the admitted workspace.

## Remaining qualification

Maestro syntax: NOT_CHECKED, `maestro` is not installed on PATH.
Android/device execution, live authentication, SSH/Termux, real provider turns,
service removal and packaging qualification: NOT_CHECKED and outside this slice.
No live regression runner, service or actual profile operation was executed.
This is not physical Android acceptance or delivery to canonical `main`/`origin/main`.
The next removal seam remains packaging/runtime dependency closure under the
[existing retirement decision](../adr/product.md#complete-removal-including-legacy).
Independent review and coordinator integration are required before ledger closure.
