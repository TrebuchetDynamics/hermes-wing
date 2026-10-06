# Chat surface-readiness clipboard outcomes

Task: `t_20794e26`. Implemented and verified in the Linux Flutter widget runner;
not physical clipboard qualification or Desktop workflow/restoration acceptance.

## Scope and ownership

The native card records the exact bounded lease/release. Admission found the
other running card in a different workspace, no competing Flutter/Dart/Playwright
worker, and continuation `6f218a559ed2` paused. The hourly picker remained scheduled;
no schedule was changed. Inherited dirty files were preserved. No commits, builds,
package installs, services, live requests/inference, upstream changes, shared
harness changes, or other profile changes were made.

Baselines, SHA-256 hashes, baseline-relative diffs, raw command logs, command/exit
receipts, parsed results and the local journal are under:

`/home/xel/.hermes/profiles/wing/autogoal/surface-copy-outcomes/`

## Repair

[The production dialog](../../lib/features/hermes_chat/screens/widgets/hermes_chat_status.dart)
now awaits `Clipboard.setData` before its existing success snackbar. Rejection is
caught without logging or displaying platform exception details. Fixed localized
failure text is shown inside the dialog with live-region semantics, where it
remains accessible despite modal semantics excluding the underlying Scaffold.
A dialog-local StatefulBuilder holds only the failure notice, not domain state.
The next explicit activation clears the notice and makes one fresh write; there
is no automatic retry or clipboard read. Mounted/current-route checks suppress
late results after dismissal or full-UI disposal.

The summary generator, sanitized payload bytes and bounds, readiness policy,
dismissal controls, Agent authority and unrelated copy actions are unchanged.
One English localization key was added and normal localization outputs generated.

[The new production Chat tests](../../test/features/hermes_chat/screens/hermes_chat_surface_clipboard_test.dart)
exercise 390px and 1280px widths with delayed platform-channel writes, success,
rejection, explicit successful retry, dismissal retaining Chat, and full-UI
disposal for both outcomes. Assertions check exact original summary payload,
no premature/false success, no late feedback or uncaught exception, localized
live-region failure, no diagnostic-marker leakage, one write per activation,
no automatic retry and unchanged fake Agent state/mutation call lists.

## Executed RED and GREEN

Commands and exact exits are recorded in `*-command.json`; full logs in `*.log`.
JSON-event counts exclude hidden loading tests.

- `red`: unchanged production callback; focused delayed-success tests at both
  widths fail only because success appeared before the write completed. Exit 1:
  0 pass / 2 fail. This is the clean defect reproduction.
- `green`: initial await/catch implementation; exit 1, 10 pass / 2 fail. The
  existing snackbar's failure text was excluded by modal accessibility semantics.
  This prompted in-dialog live-region feedback, not weakened assertions.
- `green-accessible` and final focused verification: exit 0, 12 pass / 0 fail.
- Required neighboring suites: exit 0, 122 pass / 0 fail.
- Initial analyzer found one unnecessary import in the new test; it was removed.
  Final analyzer reports no issues.

Final checks:

```sh
flutter gen-l10n
dart format --output=none --set-exit-if-changed lib/features/hermes_chat/screens/widgets/hermes_chat_status.dart test/features/hermes_chat/screens/hermes_chat_surface_clipboard_test.dart
flutter analyze
flutter test --no-pub --concurrency=1 --reporter=json test/features/hermes_chat/screens/hermes_chat_surface_clipboard_test.dart
flutter test --no-pub --concurrency=1 --reporter=json test/features/hermes_chat/screens/hermes_chat_rich_transcript_test.dart test/core/hermes/hermes_surface_readiness_authorization_test.dart
```

Scoped `git diff --check`, new-file whitespace checks and local document-link
checks pass. Baseline-relative checks verify only the scoped method and the new
localization key/getters changed in existing files; unrelated tracked diffs match
the admission snapshot. No full-suite rerun was performed.

## Evidence ceiling

Exercised: Linux Flutter widget runner, production Chat, deterministic fake Agent
and mocked `SystemChannels.platform`. Physical Linux/plugin clipboard, native
macOS/Windows clipboard, and compiled-browser clipboard are **NOT_CHECKED**.
No app build, native interaction, browser service or real clipboard was launched.

`SOURCE_CONSISTENT_RUNTIME_WITHHELD` is unchanged. Exact provider/model and native
auth/resume/generation admission remain outside this slice. The existing
[auth preflight](2026-10-04-desktop-cron-0322-auth-preflight.md) and
[review validation](2026-10-04-desktop-cron-0309-review-validation.md) checkpoints,
browser restoration line 192 and subsequent NOT_CHECKED stages are retained.
Continuation remains paused; this repair does not accept or resume those gates.
