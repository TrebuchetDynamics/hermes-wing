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

[AGENTS validation](../../AGENTS.md#validation) currently starts with
`flutter pub get --offline --enforce-lockfile`, then runs the entire serial
Flutter suite. [Contributor setup](../../CONTRIBUTING.md#setup) instead prepares
packages with `flutter pub get` on Flutter 3.44.2. Both
`pubspec.yaml:31` and `pubspec.lock`'s `qr_flutter` entry pin 4.1.0;
`1684d76a56add2db2e9211990016af1eb04be8dc` added it and `mobile_scanner`.
The offline solver output demonstrates unavailable package resolution in that
check environment, not an invalid published version or a QR product defect.
No package-cache provisioning or dependency-resolution command was executed by
this documentation pass.

The open task inventory contains no package/check-recovery owner.
[CHECK-RESULTS-001](../../tasks/items/CHECK-RESULTS-001.md) was manually closed
for a different, runner result-reader repair; preserve that closure and do not
revive its Python wrapper proposal. Both `MAIN-REPAIR` tasks are also closed.

## Bounded repair

Restate the repository's `Full check:` line to use setup-backed, locked package
preparation before the unchanged whole-suite command:

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

## Saved ledger proposals

At the same revision, both complete saved patches were inspected read-only,
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

Only task documentation is changed here. Flutter tests, browser/native/device
journeys and live Agent operations were not exercised; check recovery remains
implementation work for `CHECK-PACKAGES-001`.
