# Merge-train shell status-bar repair

Task: `t_cd815647`; goal task: `MT-APP-SHELL-STATUS-BAR` (INTEGRATION).

## Sources and reproduction

Historical train evidence: `~/.hermes/fleet-governor/merge-train/2026-10-07.md`
line 9 and `2026-10-07.log` lines 1291–1754. That evidence reported candidate
Flutter failure and base success; both browser attempts failed for missing
Chromium. Neither browser attempt establishes browser success.

This run reconstructed exact snapshots with `git archive`, without commits:

- Base commit: `1afe1307e37ee1ddfa1f7d67ad047509e99c8784`.
- Candidate tree (not a commit): `f0bbb356c023a12074216fe88f9c99d57d45f15a`.
- Unchanged test blob in both: `670dac26a502353c6eb49c453d081da9fd545f6a`.
- Base shell blob: `aaa8c89165fb4518ee1a23183cce277e34a9c4be`.
- Candidate shell blob: `5b66eaab80185af2ce0a6b3d9ee73ae8ebff6d2c`.

Owned scratch root: `~/.hermes/cache/scratch/t_cd815647/`. Commands below
ran in `base/`, `candidate/`, or the shared repository as indicated.
`source-manifest.json` records the exact relevant Git blobs and shared SHA-256
values; `dirty-baseline.json` records pre-edit dirty file hashes.

After `flutter pub get` in each snapshot (both exit 0), this command reproduced
the historical distinction:

```sh
flutter test --concurrency=1 test/shared/widgets/app_shell_test.dart
```

- Base: exit 0, 16 tests; `base-shell.log`.
- Candidate: exit 1, 15 passed and one failed; `candidate-shell.log`.
- Failure: line 382, global `find.text('Default')` found two Text widgets, one
  keyed `desktop-profile-value` in the new footer and one in the status bar.

## Root cause and repair

The profile-footer composition adds a legitimate second profile label. The
unchanged status-bar test incorrectly treated that label as globally unique.
There was no missing status-bar row or transport/domain defect.

The only code edit is in `test/shared/widgets/app_shell_test.dart`: assert exactly
one connection, profile, and model value inside `app-shell-status-bar`, then
assert exactly one profile value inside `desktop-profile-footer` and no widget
exception. This preserves strict cardinality and prevents a footer from masking
a missing status-bar profile row. No `findsWidgets`, skipped assertion, removed
footer, production change, or localization change is used.

Repaired test SHA-256:
`223fc423912d7e6ca3db5d58750fc089bf82a92582005f183a645394263c0207`.
It is identical in the repaired historical candidate and current shared tree.

## Ownership and identity

The current shared tree is not the historical candidate. It includes later
adaptive disclosure work and unrelated dirty/untracked changes. This receipt
qualifies each snapshot separately, not a new combined commit/tree.

Hotspot: `lib/shared/widgets/app_shell.dart`. Existing interactive footer/focus
hunks remain owned baseline. Native card comment 485 records coordination;
there was no other running Wing board card at discovery. The four protected
paths (shell, session access, focus traversal test, global-session browser test)
were hashed before work and confirmed unchanged after the repair. No edits to
those paths, shared index, HEAD, branches, references, services, or profiles.
No commit, push, or merge.

## Executed checks

In repaired `candidate/` and in the shared repository:

```sh
dart format --output=none --set-exit-if-changed test/shared/widgets/app_shell_test.dart
flutter test --concurrency=1 test/shared/widgets/app_shell_test.dart test/shared/widgets/app_shell_focus_traversal_test.dart test/shared/widgets/app_shell_grouped_recents_test.dart test/shared/widgets/app_shell_profile_footer_test.dart test/features/hermes_chat/widgets
flutter analyze
```

All exit 0. Candidate focused suite: 60 tests, `repaired-focused.log`.
Shared suite: 60 tests, `shared-focused.log`; analyzer logs:
`candidate-analyze.log` and `shared-analyze.log`, both report no issues.
Scoped `git diff --check -- test/shared/widgets/app_shell_test.dart`: exit 0.

Full historical-candidate gate: `flutter test --concurrency=1` was attempted in
an archive without Git metadata. Its unrelated release-workflow test failed
because `git status` could not run. The foreground tool killed that attempt at
its 420-second limit; its shutdown errors are not shell regressions. An initial
background retry was cancelled to repair this archive-only prerequisite.
These interrupted attempts do not establish a full-suite pass or terminal count.

Only the isolated candidate then received local Git metadata: `git init -q`,
read-only object alternates to the original repository, detached HEAD at the
exact base, and `git read-tree f0bbb356c023a12074216fe88f9c99d57d45f15a` into its
own index. No new commit and no shared-index operations. The release-workflow
focused test then passed (exit 0; `release-harness.log`). The exact candidate
input source plus the one test repair was checked by the full gate.

Flutter preparation also regenerated `app_localizations.dart` and
`app_localizations_en.dart` from the candidate's unchanged ARB input (58 added
generated lines). These generated changes are not additional authored repairs;
their SHA-256 values are in `source-manifest.json`. The candidate checkout diff
contains only those two generated files and the repaired test.

Final full gate: `flutter test --concurrency=1` in prepared `candidate/`, exit 0,
3555 tests passed in 10:22; `repaired-full-final.log`. This is the repaired
historical candidate, not the later current shared tree. It does not waive the
new combined-tree gate or the historical browser failures.

## Remaining gates

No shell behavior changes, so no new compiled-browser behavior qualification was
required for this test-only repair. No browser, native desktop UI, or physical
platform was exercised by this run. Historical missing-Chromium failures remain
failures, not waived gates. The existing integration owner must capture a new
combined source tree and rerun the canonical train gates, including compiled
browser journeys and request/no-incidental-mutation assertions.

The requested INTEGRATION goal was absent from the live ledger. Its narrowly
source-bound integration verification entry was registered through the existing
`goals.py` load/dump/normalize functions (the CLI has no add-goal operation), then
`add-task` registers this repair and `MT-RERUN-TRAIN`. The latter is a ledger
handoff to the existing integration owner, not a new board lane or merge action.
INTEGRATION remains partial until the remaining train gates pass.
