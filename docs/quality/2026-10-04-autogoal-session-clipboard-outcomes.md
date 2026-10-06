# Session clipboard outcome repair

Task: `t_e8790ca2`. Status: implemented and locally widget-verified; not native
clipboard qualification or Desktop workflow/restoration acceptance.

## Scope and ownership

Fresh admission found only this Wing task running in the discovered Kanban
storage, no tracked terminal jobs, and no Flutter/Dart/Playwright/fixture work in
the filtered OS census. The repository goal ledger released preceding scopes.
Continuation job `6f218a559ed2` was read back paused and was not changed.
The exact bounded lease is recorded in this task's comment thread and releases
with completion. No other task, schedule, runtime, upstream or profile settings
were mutated. No install, service, inference, browser build or native launch ran.

Owned source baselines were captured before mutation, including existing dirty
localization and gateway-switch test additions. Baselines, hashes, complete logs,
command receipts and baseline-relative diffs are under:

`/home/xel/.hermes/profiles/wing/autogoal/session-clipboard-outcomes/`

## Repair

- [Session actions](../../lib/features/hermes_chat/screens/widgets/hermes_chat_sessions.dart)
  share a small clipboard-write helper that awaits completion and catches write
  rejection without displaying or logging platform diagnostics.
- The row menu announces success only after completion; rejection shows fixed
  localized failure text. Its originating context must still be mounted.
- The details sheet closes only on success. Rejection leaves it open with an
  inline localized live-region error rather than a snackbar hidden behind the
  modal. Disposed or dismissed sheets do not navigate or emit late notices.
- One English localization key was added and outputs regenerated normally.
  The redacted summary builder and all payload semantics are unchanged.
- [Focused regression additions](../../test/features/hermes_chat/screens/hermes_chat_gateway_switch_test.dart)
  exercise compact (390px) and wide (1280px) session entry points, pending writes,
  successful completion, rejection, whole-UI disposal on either outcome, and
  sheet dismissal on either outcome while Chat remains mounted. They assert one
  explicit write, preview exclusion, no diagnostic leakage, no false success and
  no uncaught test exception. Existing successful Copy details coverage remains.

## Observed RED → GREEN

Exact focused command:

```sh
flutter test --no-pub --concurrency=1 --reporter=json test/features/hermes_chat/screens/hermes_chat_gateway_switch_test.dart --plain-name 'session clipboard'
```

1. `red.jsonl`: exit 1. Initial new wide-entry setup opened a second session
   panel, making its menu finder ambiguous. Compact cases already reproduced
   premature success and unhandled `PlatformException`. This mixed setup run is
   not presented as the clean intended RED.
2. Corrected only the new tests to use the existing wide rail, not open another
   panel. Saved the pending-success observation and asserted it after settling,
   so rejection paths also executed. No existing harness correction occurred.
   `red-corrected.jsonl`: exit 1, 4 passed / 12 failed / 0 skipped. Failures are
   intended premature-success assertions and unhandled clipboard rejection in
   both entry points, including rejection after disposal.
3. Applied the minimal production repair and generated localization.
   `green-focused.log`: exit 0, 16 passed / 0 failed / 0 skipped.
4. Added four sheet-dismissal cases, then ran the entire nearest target.
   `test-full-target.log`: exit 0, 75 passed / 0 failed / 0 skipped, including all
   20 new cases and the unchanged existing metadata/details-copy success test.
   Counts exclude hidden test-runner loading events and are parsed from JSON.

## Validation and review

Observed commands and exits:

```sh
flutter gen-l10n                                                     # 0
# Changed Dart sources only:
dart format lib/features/hermes_chat/screens/widgets/hermes_chat_sessions.dart test/features/hermes_chat/screens/hermes_chat_gateway_switch_test.dart # 0
flutter analyze                                                      # 0, no issues
flutter test --no-pub --concurrency=1 --reporter=json test/features/hermes_chat/screens/hermes_chat_gateway_switch_test.dart # 0
# Scoped owned-file whitespace check:
git diff --check -- lib/features/hermes_chat/screens/widgets/hermes_chat_sessions.dart lib/l10n/app_en.arb lib/l10n/app_localizations.dart lib/l10n/app_localizations_en.dart test/features/hermes_chat/screens/hermes_chat_gateway_switch_test.dart docs/quality/2026-10-04-autogoal-session-clipboard-outcomes.md # 0
```

Command receipts: `red-command.json`, `red-corrected-command.json`,
`green-commands.json`, `validation-commands.json`, `diff-check-command.json` and
`close.json`. Parsed test names/results: `test-results.json`.
Baseline comparisons in `baseline-checks.json` confirm the summary builder is
byte-for-byte unchanged, all prior test content is preserved, and the English
catalog differs only by the new key. Generated outputs add only that getter.
Source/diff review found no backend access, shadow state, payload expansion,
new dependency, exception logging, background read or automatic clipboard retry.
Document links and scoped whitespace were checked locally.

## Evidence ceiling and remaining gaps

Exercised: Linux Flutter widget tests with deterministic mocked platform-channel
clipboard writes. Linux physical clipboard/plugin, macOS and Windows native
clipboard, and compiled-browser clipboard runtime are **NOT_CHECKED**. Static
analysis and widget success do not upgrade those claims.

The previous source-review result remains `SOURCE_CONSISTENT_RUNTIME_WITHHELD`.
Exact provider/model restoration, private live auth, passive-resume/generation
qualification and native provisioning gates are unchanged. The existing
[auth preflight](2026-10-04-desktop-cron-0322-auth-preflight.md) and
[review validation](2026-10-04-desktop-cron-0309-review-validation.md) remain the
checkpoint; this slice neither reruns nor closes them. The integrated browser
failure at line 192 and unreached final stages remain unchanged.
