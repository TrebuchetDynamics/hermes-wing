# Copy an exact Chat session ID

> Reference correction: [official Desktop authority](../quality/official-desktop-reference.md). Prior Desktop source citations and parity conclusions in this document are withdrawn. Wing test results remain historical behavior evidence only.


## User flow

Open a session row's **Session actions** menu and choose **Copy session ID**.
At compact widths, open **More actions → Sessions** first. The action copies only
that row's opaque ID, even when another conversation is active. It preserves the
complete string, including Unicode, whitespace, and IDs longer than the details
preview limit. No title, source, model, transcript, connection URL, or credential
metadata is appended. Treat identifiers as potentially private when sharing them.

**Copy details** remains a separate redacted summary action. Its preview-limited
ID is not a substitute for this exact-ID action. Neither action selects the row
or starts an Agent operation.

## Outcomes and ownership

The selected row shows accessible live-region feedback only after the clipboard
platform call completes: **Copied session ID.** or the fixed failure message
**Could not copy session ID. Try again.** Feedback lives inside the row so it
remains exposed while the compact Sessions modal is open. Platform exception
contents are neither displayed nor logged. Reopen the menu to explicitly retry;
Wing never retries automatically, reads the clipboard, or overlaps ID writes on
the same tile.

An open ID action is bound to the current channel, connection origin, profile,
active-session context, connection/selection state, and selected row identity and
presence. Synchronous notifications invalidate it, including a same-frame owner
roundtrip or row removal/reappearance. Changed owners must reopen the menu.
Disposing the row prevents an unsubmitted action. An explicitly submitted write
may finish after an owner change or disposal, but it cannot report success or
failure to the replacement owner. This does not undo an already-submitted OS
write. Feedback is presentation state only, not cached Agent domain state.

## Executed verification and limits

Linux Flutter widget runner with mocked `SystemChannels.platform` only:

- Clean RED on unchanged production source proved the ID action absent at both
  390 and 1280 widths, after a test-local compact-entry setup correction.
- 38 focused production `HermesChatScreen` widget tests passed: separate actions,
  exact long padded Unicode non-active ID, zero selection/state changes, delayed
  success/rejection, fixed accessible failure, explicit retry, pending-write
  disposal and origin/profile/row changes, synchronous stale menus, same-frame
  owner/row roundtrips, disposed rows, overlap exclusion, and keyboard-only entry,
  Tab/menu navigation/Enter and Escape with zero dismissal writes.
- 75 neighboring gateway-switch tests passed, including existing menu/sheet
  Copy details success, failure, dismissal and disposal coverage.
- Localization generation, changed-file formatting, analyzer, scoped diff and
  new-file whitespace checks passed. The inherited details-copy helper and summary
  implementation are preserved.

Commands from the repository root:

```sh
flutter gen-l10n
dart format lib/features/hermes_chat/screens/widgets/hermes_chat_sessions.dart test/features/hermes_chat/screens/hermes_chat_session_id_copy_test.dart
flutter analyze
flutter test --no-pub --concurrency=1 test/features/hermes_chat/screens/hermes_chat_session_id_copy_test.dart
flutter test --no-pub --concurrency=1 test/features/hermes_chat/screens/hermes_chat_gateway_switch_test.dart
git diff --check -- lib/features/hermes_chat/screens/widgets/hermes_chat_sessions.dart lib/l10n/app_en.arb lib/l10n/app_localizations.dart lib/l10n/app_localizations_en.dart
```

Physical/native/browser clipboard, real Agent inference, screen-reader runtime,
and full Desktop daily-use workflow remain NOT_CHECKED. This slice does not
accept historical restoration or native-auth gates and does not resume paused
continuation work. No build, service, install, backend, schedule, or upstream
changes are part of this verification.

See [client architecture](../adr/client.md) and
[route support](../product/routes.md). The read-only Desktop reference is
`withdrawn source citation`, whose
Copy session ID callback uses the selected `target.id`.
