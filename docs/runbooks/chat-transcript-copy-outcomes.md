# Whole-transcript clipboard outcomes

Chat's Copy transcript action contains clipboard rejection and reports a fixed
localized failure. This receipt covers deterministic production-Chat widget tests
on the Linux Flutter test runner, not physical clipboard qualification.

## User flow

At wide widths, select Copy transcript in the header. At compact widths, open
More actions, then Copy transcript. Select Copy as text or Copy as Markdown.
Dismissal without selecting a format writes nothing. Selecting a format closes
the sheet and starts one clipboard write. Success appears only after the platform
future completes. Rejection shows “Could not copy transcript. Try again.” without
platform exception details. Reopen the action to retry explicitly; Wing does not
retry automatically. Failure releases the existing pending-action guard.

Copy retains its existing sheet-opening loaded-state snapshot and shared text or
Markdown serializer. Older unfetched history is not fetched. This change does not
alter redaction, payload bytes, file export, clipboard reads, or stale-sheet
admission rules. Pattern redaction is not complete anonymization; review copied
content before sharing it.

The existing composer ownership generation and channel identity suppress delayed
feedback after owner replacement or UI disposal. The sheet also passes its
existing owner check to the copy callback. Context-menu callers remain compatible
with the shared callback. A started system clipboard write cannot be undone;
feedback suppression is not rollback or cancellation of the write.

## Executed checks

Evidence directory:
`/home/xel/.hermes/profiles/wing/autogoal/transcript-copy-outcomes/`.
The command/exit ledger is `commands.json`; machine-parsed test results are in
`test-counts.json`. Source bindings are `red-fingerprints.json` and
`final-fingerprints.json`. Baseline owned bytes are in `baseline/`, existing-file
hashes in `baseline-hashes.json`, and the scoped repair in `task-relative.diff`.

Commands were run from the Wing root without installation or a live runtime:

- RED: `flutter test --no-pub test/features/hermes_chat/screens/hermes_chat_transcript_clipboard_test.dart --plain-name 'text reject none 390.0' --reporter=json`.
  Exit 1; `red.jsonl` contains the actual uncaught synthetic PlatformException
  through `_copyTranscript` and the absent failure notice before production edits.
- Localization: `flutter gen-l10n`. Exit 0; `gen-l10n.log`.
- Formatting: `dart format --output=none --set-exit-if-changed lib/features/hermes_chat/screens/hermes_chat_screen.dart test/features/hermes_chat/screens/hermes_chat_transcript_clipboard_test.dart lib/l10n/app_localizations.dart lib/l10n/app_localizations_en.dart`.
  Exit 0; `format-final.log`.
- Analysis: `flutter analyze --no-pub`. Exit 0; `analyze-final.log`.
- New target: `flutter test --no-pub test/features/hermes_chat/screens/hermes_chat_transcript_clipboard_test.dart --reporter=json`.
  Exit 0, 68 tests; `clipboard-final.jsonl`.
- Neighbors: `flutter test --no-pub test/features/hermes_chat/screens/hermes_chat_rich_transcript_test.dart test/features/hermes_chat/screens/hermes_chat_transcript_export_test.dart --concurrency=1 --reporter=json`.
  Exit 0, 105 tests; `neighbors-final.jsonl`.
- Scoped `git diff --check` and new-file whitespace/local-link checks:
  exit 0; `scope-checks.json` and `diff-check.log`.

Shared screen disposal was not changed; predecessor modal-intent tests were not
rerun or represented as new evidence. The task-local harness uses platform-channel
mocks, deterministic channel/directory/storage overrides, and bounded frame pumps.
Harness failures during development (callback arity, cleanup invariants and
animation timing) are not platform failures or successful qualification.

## Acceptance evidence

1. Actual RED before production edits: `red.jsonl`, `red-fingerprints.json`,
   baseline screen bytes. The recorded screen SHA-256 is
   `5a46a924f7ccd6ca293fb1c8ed1a8def326eeccd4216fbf6321b83a94bf4935c`.
2. Both formats at both widths: `clipboard-final.jsonl` and the
   [actual Chat test](../../test/features/hermes_chat/screens/hermes_chat_transcript_clipboard_test.dart).
   Delayed success/rejection, one write per activation, no premature notice,
   sanitized UI/debug output, localized live-region failure, and explicit retry
   are asserted. `test-counts.json` records the parsed outcomes.
3. Dismissal, UI/route disposal, origin/profile/session/channel replacement and
   profile roundtrip: the same new target checks no stale success or failure.
   Started writes remain recorded once; they are not claimed to be reversible.
4. Exact text/Markdown, metadata, redaction and export equivalence:
   `neighbors-final.jsonl`; inspect `task-relative.diff` for the unchanged
   serializers/export/disposal. `preservation.json` verifies that only the four
   owned existing files changed from baseline and no baseline file disappeared.
5. Format, regenerated localization, analyzer, focused targets and scoped checks:
   `commands.json`, `test-counts.json`, `scope-checks.json`. Final source, test,
   runbook and verification artifact hashes are in `final-fingerprints.json`.
6. This runbook and `journal.md` map the delivered error handling to executable
   evidence. Predecessor success cases are retained as regression coverage, not
   relabeled as newly delivered features.

## Qualification ceiling

Physical clipboard, compiled browser, native desktop app, physical Android,
screen reader, live Agent/provider, full daily-workflow/parity and release:
NOT_CHECKED. No transport, Agent, Wing Link, upstream or profile configuration
changes were made. SOURCE_CONSISTENT_RUNTIME_WITHHELD and paused continuation
remain unchanged. No commit, stage, push or dependency install was performed.

For the separate file-save behavior, see
[loaded-transcript export](chat-transcript-export.md).
