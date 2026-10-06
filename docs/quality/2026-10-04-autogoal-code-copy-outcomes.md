# Fenced-code clipboard outcome repair

Task: `t_74315485`. Implemented and locally widget-verified; not physical
clipboard qualification or Desktop workflow/restoration acceptance.

## Scope and ownership

Fresh admission found only this running task in the native board, no tracked
terminal processes and no competing Flutter/Dart/Playwright/fixture worker in
the filtered OS census. Continuation `6f218a559ed2` remains paused; the hourly
picker is scheduled, not an implementation owner. No schedules were changed.
The exact bounded lease and release are native card comments, as authorized by
this card; the existing goal ledger was not edited.

Dirty source baselines, SHA-256 hashes, command receipts, raw logs, parsed test
results and baseline-relative diffs are preserved under:

`/home/xel/.hermes/profiles/wing/autogoal/code-copy-outcomes/`

No commits, package installs, builds, services, runtime access, inference,
upstream changes or other profile changes occurred.

## Repair and regression coverage

[The fenced-code callback](../../lib/features/hermes_chat/presentation/hermes_rich_text.dart)
awaits the write and catches rejection without exposing or logging exception
text. Success still requires completed clipboard writing. Fixed localized
failure feedback is shown via the existing accessible snackbar. A local Builder
binds late feedback to the code action's mounted context, rather than the
longer-lived Markdown builder context. Removing code while retaining its
Markdown owner therefore suppresses late success and failure notices.

One English localization key was added and normal `flutter gen-l10n` outputs
regenerated. Code extraction, displayed payload, rendering, truncation and
selection behavior are unchanged. No automatic retries or clipboard reads exist
in this repair.

[Regression additions](../../test/features/hermes_chat/screens/hermes_chat_rich_transcript_test.dart)
cover 390px and 1280px widths, delayed success/rejection, whole-UI disposal on
either outcome, and removal of the code widget while its Markdown owner remains
mounted. Mounted and whole-UI cases use production Chat with the existing fake
channel; code-only removal uses the production rich-text widget in a localized
Scaffold. Synthetic multiline Unicode code retains leading/trailing spaces and
blank lines byte-for-byte. Assertions cover one write per explicit activation,
no premature/false success, localized live-region failure feedback, explicit
retry after failure, no diagnostic-marker leakage to UI/debug output, and no
uncaught test exception. Prior tests are preserved, including successful code
copy, long-code/large-transcript and selection-menu regressions.

## Observed RED → GREEN

Focused command (unchanged production code for RED):

```sh
flutter test --no-pub --concurrency=1 --reporter=json test/features/hermes_chat/screens/hermes_chat_rich_transcript_test.dart --plain-name 'code clipboard'
```

- `red.jsonl`: exit 1; mixed setup and behavior failures. New-test semantics
  cleanup happened too late in teardown. Not the clean intended RED.
- `red-corrected.jsonl`: exit 1; new-test debugPrint cleanup also happened too
  late. Not the clean intended RED.
- Cleanup moved into the new tests' finally block, without changing existing
  harness or tests. `red-final.jsonl`: exit 1, 4 pass / 8 fail / 0 skipped,
  zero setup-invariant failures. Six rejection cases reproduce uncaught
  PlatformException; two code-removal success cases reproduce late feedback.
- Minimal production/localization repair applied. `green-focused.log`: exit 0,
  12 pass / 0 fail / 0 skipped.
- Final assertions use the generated localization getter and also verify its
  English copy. Entire nearest target: `test-full-target.log`, exit 0,
  88 pass / 0 fail / 0 skipped, including all 12 additions.

Counts are parsed from JSON events excluding hidden runner loading tests.
`test-results.json` contains names and results. Command arrays and exact exits
are saved in `red-command.json`, `red-corrected-command.json`,
`red-final-command.json`, `green-commands.json`, `validation-commands.json`
and `diff-check-command.json`.

## Validation and review

Executed successfully:

```sh
flutter gen-l10n
dart format lib/features/hermes_chat/presentation/hermes_rich_text.dart test/features/hermes_chat/screens/hermes_chat_rich_transcript_test.dart
flutter analyze
flutter test --no-pub --concurrency=1 --reporter=json test/features/hermes_chat/screens/hermes_chat_rich_transcript_test.dart
```

The final formatter run changed no files; analyze reported no issues.
Scoped `git diff --check` and local document-link checks also passed.
Baseline-relative review confirms existing test content is byte-for-byte
preserved when the new block is removed; the English catalog differs only by
the new key, and generated outputs only add its getter. Production changes are
limited to code-action callback ownership and outcome feedback. No backend,
transport, fixture, shared harness or other clipboard surfaces were changed.

## Evidence ceiling

Exercised: Linux Flutter widget runner with deterministic platform-channel
mocks. Physical Linux clipboard/plugin, native macOS/Windows clipboard and
compiled-browser clipboard behavior are all **NOT_CHECKED**. No native app or
browser was launched; static analysis and widget tests do not upgrade those
claims.

`SOURCE_CONSISTENT_RUNTIME_WITHHELD` remains unchanged. Exact provider/model,
native auth/resume/generation and owner provisioning gates remain open. The
existing [auth preflight](2026-10-04-desktop-cron-0322-auth-preflight.md) and
[review validation](2026-10-04-desktop-cron-0309-review-validation.md) checkpoints,
browser line 192 failure and subsequent NOT_CHECKED stages are not rerun or
accepted by this slice.
