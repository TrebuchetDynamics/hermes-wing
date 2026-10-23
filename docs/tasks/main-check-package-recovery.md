# Recover package preparation before the full Flutter check

Task: `CHECK-PACKAGES-001`; goal: `INTEGRATION`.

## Evidence at 7603dcdd

The runner reported two crashes before any test result at
`7603dcdd97098e064c5c2a450fbd649eaa781d53`. All five bundle files were read
in place under Git-common
`autowork-execution/main-evidence/7603dcdd97098e064c5c2a450fbd649eaa781d53/`:

- `main_check.json`: `state: broken`, `result_class: INCOMPLETE`,
  `failures: null`; previous green `9ca06dca7065c3d047f2e4f909937b6147a2dcf4`.
- `main-check.log`, in full:

  ```text
  Resolving dependencies...
  Because wing depends on qr_flutter 4.1.0 which doesn't match any versions, version solving failed.
  Failed to update packages.
  ```

- `main-check.exit`: `1`.
- `main-check-reruns.log`: empty.
- `flaky_history.json`: `{}`.

The crash line is **`Failed to update packages.`** No test is known to fail
from this bundle. It is neither red-test evidence nor a flaky-test record.

At that revision, [AGENTS validation](../../AGENTS.md#validation) started with
`flutter pub get --offline --enforce-lockfile`, then ran the entire serial
Flutter suite. [Contributor setup](../../CONTRIBUTING.md#setup) instead prepared
packages with `flutter pub get` on Flutter 3.44.2. Both
`pubspec.yaml:31` and `pubspec.lock`'s `qr_flutter` entry pin 4.1.0;
`1684d76a56add2db2e9211990016af1eb04be8dc` added it and `mobile_scanner`.
The offline solver output demonstrates unavailable package resolution in that
check environment, not an invalid published version or a QR product defect.
No package-cache provisioning or dependency-resolution command was executed by
this documentation pass.

The initial maintainer inspection found no open package/check-recovery task.
[CHECK-RESULTS-001](../../tasks/items/CHECK-RESULTS-001.md) was manually closed
for a different, runner result-reader repair; preserve that closure and do not
revive its Python wrapper proposal. Both `MAIN-REPAIR` tasks are also closed.

## Bounded repair

The accepted repair uses setup-backed, locked package preparation in the
repository's `Full check:` line before the unchanged whole-suite command:

```bash
flutter pub get --enforce-lockfile && flutter test --no-pub --concurrency=1
```

Align the nearby validation wording and contributor setup so unattended workers
know that initial package preparation may download the exact locked public
packages. Offline resolution is valid only after that cache has been populated;
it is not a cold-cache bootstrap. Retain the documented Flutter 3.44.2 toolchain.
This is a setup/check contract repair, not permission to upgrade packages or the
SDK. No dependency, checksum, lockfile, installed runner or product-code change
is needed for the specified repair.

Validate locked preparation, then the existing complete offline sequence on the
prepared cache. Record actual source, SDK, exits and terminal suite results in
this page; a completed failing suite is observable check recovery, not green
main. Stop and report a concrete unavailable package source if preparation itself
cannot run; never manufacture results, bypass lock enforcement or mask child
failure. Any later test failure is separate evidence, not a named-test repair
inferred from this crash. Normal independent review and runner gates still apply.

## Retry validation at 65964148

Source: `65964148d754bef54e522ee2fd0420b4ae00495b` on
`autowork/CHECK-PACKAGES-001`; only `AGENTS.md`, `CONTRIBUTING.md` and this page
change. The [review-recovery instruction](review-findings-recovery.md#package-preparation)
requires consuming verified `MAIN-REPAIR-003`, not replaying an older rejected
assembly. Its integration `bd1bcf76bd8bf82ad81a01f3c7aa6dec9b3128e5` is an
ancestor of this baseline. The deterministic saved-access mounts and owned-port
fixtures are already present; no product or test repair was made here.

### Historical runner results, not this candidate's gate

The retained attempt-2 receipt/log
`autowork-execution/e003c1873f6b410095154df603de8696.{json,log}` was inspected
in place: `CHECK_FAILED`, exit **1**, integration
`184f5901cf1e125795659ecff04de8a79ba1b950`, 25 widget failures. Its five selected
isolated reruns did not pass; the other 20 were not rerun. That receipt is not
reusable acceptance. The [existing repair inventory](main-offline-test-repair-3f354e4e.md#failing-inventory)
records those widget cases and the separate socket group; no flaky verdict follows.

All five files in the retained runner bundle for ancestor
`7bac44af16829ee5aacfdd642bf85205967d7e4f` were inspected in place under
Git-common `autowork-execution/main-evidence/<revision>/`. It reports:

- `main_check.json`: `state: green`, `result_class: PASS`, checked revision and
  green revision both `7bac44af16829ee5aacfdd642bf85205967d7e4f`.
- `main-check.log`: preparation reached `Got dependencies!`; terminal result
  **`20:10 +4192 ~9: All tests passed!`** — 4,192 passed, 9 skipped, 0 failures.
- `main-check.exit`: **0**. For the runner's `pub get && flutter test` sequence,
  both child exits are therefore 0; separate child-exit records are not supplied.
- `main-check-reruns.log`: empty; `flaky_history.json`: `{}`.

The nine skips are the existing opt-in
[`managed_ssh_loopback_test.dart`](../../test/core/hermes/ssh/managed_ssh_loopback_test.dart)
cases, gated on `MANAGED_SSH_FIXTURE`; this task adds no skip or filter. The bundle
does not record a Flutter/Dart SDK version, so the fresh SDK observation below
must not be retroactively attributed to it. This historical pass shows that
package preparation and terminal reporting have occurred on a repaired ancestor;
it neither qualifies this candidate nor replaces its normal merged-tree gate.

### Fresh preparation and required modules

Validation reused the shared SDK/cache with:

```bash
export FLUTTER_ROOT="$AUTOWORK_CACHE/flutter-3.44.2"
export PUB_CACHE="$AUTOWORK_CACHE/dart-pub-3.12.2"
export PATH="$FLUTTER_ROOT/bin:$PATH"
```

`flutter --version --machine` exited **0**: Flutter **3.44.2**, Dart **3.12.2**,
framework `c9a6c484230f8b5e408ec57be1ef71dee1e77020`, engine
`77e2e94772b6eb43759e34ed1ad7da4674e19cab`. No SDK or installed runner was edited.

Before documentation edits, standalone
`flutter pub get --offline --enforce-lockfile` exited **0** (`Got dependencies!`)
to prepare checkout-local metadata, then the task's exact six-module command ran:

```bash
flutter test --no-pub --concurrency=1 test/features/hermes_chat/screens/hermes_connection_primary_entry_test.dart test/features/hermes_chat/screens/compact_connection_presentation_test.dart test/features/hermes_chat/screens/hermes_ssh_no_cli_test.dart test/features/hermes_chat/widgets/connection_information_help_dialog_test.dart test/features/hermes_chat/widgets/managed_ssh_generated_key_ui_test.dart test/features/enrollment/hermes_welcome_recovery_test.dart
```

It exited **0**, terminal **`00:48 +41: All tests passed!`** (41 passed, no skips
or failures), including all four formerly failing Android primary-owner variants.
These Android/Linux widget variants ran on the Linux Flutter test host, not on
a device or native application.

`flutter pub get --enforce-lockfile` then exited **0** (`Got dependencies!`),
resolving `qr_flutter` **4.1.0** in the generated package configuration along with
the locked dependencies. Preparation used `autowork-run timeout 300` (offline)
and `autowork-run timeout 600` (network-capable); neither timed out.
`git diff --exit-code -- pubspec.yaml pubspec.lock` exited **0**. The cache was
already warm, as the earlier offline success demonstrates. The network-capable
command's `Downloading packages...` heading is not proof of a cold-cache fetch or
new provisioning. No manifest, lockfile or checksum was edited.

**This candidate's complete offline gate remains runner-owned and pending.**
The worker contract prohibits running it locally. Its merged source revision,
SDK, preparation/test exits, terminal counts and any remaining failures must be
added from that new runner gate during coordinator Docs Sync closeout, separately
from both the historical aggregate and fresh preparation results above. A complete
failed suite proves reporting recovery, not a green gate; an incomplete run proves
neither. No tests were changed, filtered or repaired under this task. Independent
review and normal runner validation remain mandatory; no integration, browser,
native/device, live Agent/provider, release, parity or goal qualification follows.

## Saved ledger proposals

During the initial maintainer pass, both complete saved patches were inspected read-only,
including programmatic comparison of the long generated rows. Paths below are
relative to Git-common `autowork-execution/`:

- `slot-data/PARITYUPDATE-005-11/attempt-1/ledger-edit.patch`: only retired
  `TODO.md` generated coverage and `goals.json` priority changes. It replaces
  `MT-VERIFY-BROWSER-GATES` with its live successor, removes `PLANGAP-001-2f`
  from coverage, and removes `VERIFY-CHAT-TRANSCRIPT-NATIVE` from coverage/order.
  The adjacent report names `7f5c64c9793be0e8783302521a5e1f06f27131f6`.
- `slot-history/DOC-PARITY-TAB-CONTRACT/8/slot-data/attempt-1/ledger-edit.patch`:
  only the same browser-successor/plan-task generated coverage refresh. Its
  adjacent report names `187cdc8c4725103a16f3e34a3416b10950b7f6e8`;
  the current slot report names later `e564642df5f0273b915a2fde153ab4cd0ff786e3`.

Both task records, their archived bodies' Sources/accepted scope and the adjacent
and current worker reports were inspected. The relevant accepted sources remain
[the port roadmap](../../ROADMAP.md#flutter-port-execution-roadmap),
[inventory acceptance](../quality/shell-inventory-keyboard-qualification.md#acceptance-map),
[Android priority](../plans/2026-10-03-desktop-port-goal.md#android-ssh-multi-session-priority)
and the [parity evidence boundary](../product/hermes-desktop-parity.md#reference-and-evidence-boundary).
Both producer slots are closed. All five named completed task records remain
done; the two live successors are now also manually closed by the owner's
2026-10-22 waiver, not newly qualified. This is newer planning than the
[earlier drop disposition](held-offline-recovery.md#saved-ledger-proposals-after-migration).
**Drop both proposals**: no missing current-store edit is justified. Neither
patch was applied, no task was reopened and no closure or goal proof was changed.

## Maintainer checklist

- [x] Read the crash bundle in place and compare the open task inventory.
- [x] Inspect saved proposals against current records, Sources and worker reports.
- [x] Add one bounded check-recovery task through the native task CLI.
- [x] Validate task records, changed local links and whitespace before committing.

Maintainer validation: native `tasks validate --worktree .` passed with 296 tasks
and 36 goals; the two existing drafts are unchanged. A read-only Python check
verified all 12 new local links/Sources anchors, preserved the seven named task
closures and found no Touches overlap with running `LINUXQA-001-c7841f6e`.
`git diff --check` passed. Independent fresh-context read-only review found no
blocker; it did not run Flutter, package downloads or live checks.

That initial maintainer pass changed only task documentation and did not exercise
Flutter/browser/native/device journeys or live Agent operations. The later retry's
preparation and focused checks are recorded above; its complete gate and
coordinator closeout remain pending.
