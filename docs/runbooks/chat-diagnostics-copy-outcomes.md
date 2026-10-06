# Chat Diagnostics copy outcomes

## Behavior

Open Chat Diagnostics from the compact header's More actions menu or the wide
header's Diagnostics button. Copy diagnostics still writes the existing bounded,
sanitized [diagnostics snapshot](../../lib/features/hermes_chat/diagnostics/hermes_diagnostics_export.dart).
Copy raw log status writes only the existing deferred-status explanation. It does
not enable raw log export.

Both actions wait for the platform clipboard write before showing their existing
success notice. A rejected write shows the fixed localized message, “Could not
copy diagnostics. Try again.”, as a live region inside the dialog. Platform error
codes, messages and details are not displayed or logged. The user may explicitly
activate either action again; no automatic retry or clipboard read is added.

A result arriving after dismissal, including during the closing animation, or
after UI disposal cannot show success or failure in the remaining UI. This is a
dialog-local ownership check, not a change to connection or Agent lifecycles.
Payload construction and [diagnostics redaction rules](../security/threat-model.md)
are unchanged. Agent and Wing Link authority remain separate.

## Bounded widget evidence

Task: `t_a568069e`. Evidence directory: `.task-evidence/t_a568069e/` at repository
root (local execution artifacts, not release evidence).

Before production changes, run:

```bash
flutter test --concurrency=1 test/features/hermes_chat/screens/hermes_chat_diagnostics_clipboard_test.dart --plain-name 'clipboard success none' --reporter expanded
```

`red.log` records exit 1 and four failures on “Success must await the clipboard
write”: both actions at actual MediaQuery widths 390 and 1280. The production
connection file's SHA-256 at RED was
`740a5e6123c291f692498e07a9e07d52e5c51f71286d86c35a251547bac3c299`.
`connection-before.txt` preserves that source, including inherited unrelated
reconnect and session-guard edits. Initial test-only sizing was corrected before
this RED; no production edit preceded the recorded four-failure reproduction.

After the dialog-local repair, run:

```bash
dart format --output=none --set-exit-if-changed lib/features/hermes_chat/screens/state/hermes_chat_connection.dart test/features/hermes_chat/screens/hermes_chat_diagnostics_clipboard_test.dart
flutter analyze
flutter test --concurrency=1 test/features/hermes_chat/screens/hermes_chat_diagnostics_clipboard_test.dart --reporter expanded
flutter test --concurrency=1 test/features/hermes_chat/screens/hermes_chat_surface_clipboard_test.dart test/features/hermes_chat/screens/hermes_chat_rich_transcript_test.dart test/features/hermes_chat/screens/hermes_chat_screen_auth_recovery_test.dart --reporter expanded
git diff --check -- lib/features/hermes_chat/screens/state/hermes_chat_connection.dart test/features/hermes_chat/screens/hermes_chat_diagnostics_clipboard_test.dart docs/runbooks/chat-diagnostics-copy-outcomes.md
```

`green.log` records 32 passing actual-screen cases: two actions, two widths,
success/rejection, and open/closing/dismissed/disposed lifetimes. Tests use delayed
`SystemChannels.platform` writes, exact snapshot/deferred-summary equality, no
premature notice, modal live-region failure, explicit successful retry with one
write per activation, no automatic retry, no error-detail leakage, and no uncaught
late error or stale notice. They assert unchanged fake Agent state and no connect,
session-create, profile-select, approval-response or voice-send calls.
`neighbors.log` records 111 passing cases across the three existing targets.
`analyze.log` records no analyzer issues. The acceptance receipt stores scoped
fingerprints, preservation checks and exact command outcomes.

These are Linux-hosted Flutter widget tests with deterministic platform-channel
mocks. Browser execution, physical/native clipboard behavior, screen-reader
runtime, live Agent calls, full-suite/integrated parity, packaging, builds,
deployment and release remain NOT_CHECKED. Same-card review approval is separate
from implementation verification.
