# Chat error-details copy outcomes

Scope: the shared error-details sheet reached from Chat run errors and connection
errors. This is a clipboard feedback repair, not native clipboard qualification.

## Behavior

- Copy sends the existing displayed redacted preview, bounded at 1200 characters
  by the existing preview helper. Payload construction and redaction are unchanged.
- Pending writes do not report success. Completed writes retain the existing
  “Copied redacted Hermes error details” feedback.
- Denied writes show “Could not copy diagnostics. Try again.” inside the sheet
  as a semantic live region. Copy is the explicit retry action; no automatic retry
  occurs. Platform exception details are neither displayed nor logged.
- Settlement after Close, Back, or UI disposal cannot report success or failure
  in the remaining UI. The route-current check covers the closing transition.

## Executed evidence

Task: t_526a2fef. Repository evidence: `.task-evidence/t_526a2fef/`.

1. Before production edits, `flutter test
   test/features/hermes_chat/screens/hermes_chat_error_clipboard_test.dart
   --plain-name 'clipboard success none'` exited 1. `red.log` records four
   premature-success failures through actual HermesChatScreen Details buttons:
   both callers at widths 390 and 1280. Original source SHA-256:
   `0186dec51a045e2b5d013fb79032669bbc2f35b7b0d060955f678b71b9942717`.
2. `flutter test
   test/features/hermes_chat/screens/hermes_chat_error_clipboard_test.dart`
   exited 0; `green-final.log` records 32 passing cases. Coverage includes delayed
   success/rejection, exact displayed and copied bounded/redacted payload,
   sheet-local live-region failure, explicit retry, no automatic retry, one write
   per tested activation, suppression after Close/Back/disposal, no uncaught
   exception or platform-marker leakage, and unchanged fake Agent state.
3. `flutter test
   test/features/hermes_chat/screens/hermes_chat_rich_transcript_test.dart
   test/features/hermes_chat/screens/hermes_chat_screen_auth_recovery_test.dart
   test/features/hermes_chat/screens/hermes_chat_surface_clipboard_test.dart`
   exited 0: 111 neighboring tests (`neighbors.log`).
4. Changed-file `dart format --output=none --set-exit-if-changed` and
   `flutter analyze` exited 0 (`format.log`, `analyze.log`). Initial test harness
   failures (semantic handle cleanup and an overbroad platform-marker matcher)
   and the corrected unused test import are retained in separate evidence logs.
5. Scoped whitespace, local links, source hashes, and byte-identical content
   outside the function are checked in `scope.log` and `acceptance.json`.
   Independent read-only review found no blocking implementation findings;
   native same-card approval is a separate gate.

The [implementation](../../lib/features/hermes_chat/screens/widgets/hermes_chat_error.dart)
and [regression test](../../test/features/hermes_chat/screens/hermes_chat_error_clipboard_test.dart)
use existing Flutter delivery/import seams; no new runtime module or dependency
was added. Tests mock platform-channel settlement, not real OS clipboard writes.

NOT_CHECKED: browser runtime, native physical clipboard, screen-reader runtime,
live Agent, full suite, integrated parity, packaging/build/deployment/release,
keyboard activation and overlapping pending Copy presses. No clipboard reads,
upstream changes, commits, or changes to predecessor blocked scopes were made.
