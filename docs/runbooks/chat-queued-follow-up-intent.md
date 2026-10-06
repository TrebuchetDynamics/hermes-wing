# Chat queued-follow-up dialog intent

Manage and Cancel All belong to the Chat owner that opened them. A root dialog
that survives an owner change cannot remove follow-ups from the replacement
conversation. Manage removes the displayed row, not whatever later occupies its
index.

## Implemented behavior

The shared queue-dialog helper retains the channel, origin, profile, active
session and gateway contact. Channel, provider and directory observers latch
owner loss synchronously. Disconnection, profile selection, unsettled restoration
or owner replacement permanently invalidates the intent. A same-frame A-B-A
transition does not revive it. Stale Manage removal does nothing; stale Cancel
All confirmation closes but does not clear the queue. Close or Keep remains
available; reopen the dialog for fresh intent.

Manage renders a bounded snapshot of the queue and finds the selected object by
identity before removal. If an automatic send already removed that row, its old
callback does not remove the next row. Shifted rows retain their identity. An
empty queue closes on removal, including when the displayed queue disappeared.
Callbacks cannot act after Manage finishes or Chat unmounts. Observers are
released on dialog completion, cancellation and Chat disposal, even while a root
dialog remains mounted.

Normal same-owner removal, Keep and Cancel All are unchanged. Cancel All still
clears the current same-owner queue, including additions after the preview;
this task does not introduce snapshot-only bulk cancellation. Queue capacity,
transport admission, session parking, ordering, attachment handling, requeue and
automatic sending are unchanged. There is no new replay or Agent/Wing Link
operation, no shadow domain state and no change to the session-mutation wrapper.

## Executed RED and GREEN

The baseline was the dirty worktree at HEAD
`ca149a82189c8c9e5abd98b376bfeae1e43f6f3f`. Saved baseline SHA-256:

- Message flow: `7c52337630fb4af6580a72266d10a1cd08159808d9959c833108c93b2512eb10`
- Screen: `7455f40c9e34e6c7710bae3b5c3b2c30a7e40632fbecf420ac49a700df61577a`

Before production edits, the new actual-widget test opened each production
dialog at 390 and 1280 pixels. It disconnected A, restored the connected channel
as B, admitted B's follow-up through a retained production composer callback,
and activated the stale dialog action. All four cases failed because B's queue
was deleted. The test did not access private screen state. This is deterministic
in-flight callback evidence, not a live Agent exploit or an offline replay. No
RangeError was observed in that RED; the proven defect was replacement deletion.

The initial harness used `pumpAndSettle` on an indefinitely streaming screen,
then tapped the outgoing compact disabled button during its animation. Those
setup failures were not accepted as defect RED. Bounded frame pumping corrected
both within the new test only. Later test-local corrections removed duplicate
Riverpod-owned directory disposal and checked exact added observers rather than
assuming unrelated rail/provider listener counts never change. No shared fake,
existing oracle, disabled errors or weakened deletion assertion was used.

Final commands, each exit 0 (test commands also used `--reporter json`):

```sh
dart format --output=none --set-exit-if-changed lib/features/hermes_chat/composer/hermes_chat_message_flow.dart lib/features/hermes_chat/screens/hermes_chat_screen.dart test/features/hermes_chat/screens/hermes_chat_queued_dialog_intent_test.dart
flutter analyze
flutter test test/features/hermes_chat/screens/hermes_chat_queued_dialog_intent_test.dart
flutter test test/features/hermes_chat/controllers/hermes_follow_up_queue_test.dart
flutter test test/features/hermes_chat/screens/hermes_chat_slash_commands_test.dart --name 'local commands cannot bypass|plain follow-up|operator can cancel|queue manager|full follow-up'
flutter test test/features/hermes_chat/screens/hermes_chat_voice_lifecycle_test.dart --plain-name 'attachment follow-up waits in the busy queue and sends next'
flutter test test/features/hermes_chat/screens/hermes_chat_screen_auth_recovery_test.dart test/features/hermes_chat/screens/hermes_chat_reconnect_owner_test.dart --concurrency=1
flutter test test/features/hermes_chat/screens/hermes_chat_session_mutation_owner_test.dart
```

Parsed results: 62 new widget tests; 15 queue-unit, 5 queue-entry, 1 attachment,
12 auth/reconnect and 136 predecessor session-mutation tests passed. Total: 231
passed, 0 failed, 0 skipped. Analyzer: no issues. Changed-file formatting: zero
changes. The predecessor wrapper still matches its saved final fingerprint;
the screen's separate four-line queue-disposal addition required fresh execution
of the predecessor tests, not reuse of their old receipt.

## Acceptance evidence

1. Executed RED: `red-confirmed.log` records four replacement-deletion failures
   before production edits, bound to the saved baseline bytes/fingerprints.
2. Stale owner/row/disposal: `green-final.log` covers both widths, profile A-B-A,
   origin/session change, selecting-profile return, channel replacement/return,
   contact replacement/return, disconnect, unmount, shifted/already-sent rows,
   disappeared queue and completed callbacks. No unintended send or uncaught
   exception is accepted by these assertions.
3. Normal management: same-owner removal through empty close, Close, Keep,
   Cancel All and same-owner additions pass at both production entry points.
   Queue unit/entry/attachment receipts verify existing admission/sending neighbors.
4. Lifetime: channel/directory listener assertions verify removal after completion,
   cancellation and root-dialog-surviving unmount. Session wrapper is byte-identical;
   its 136 tests passed with the added independent screen disposal set.
5. Validation: `verification.json` contains exact argv, exit, parsed counts and
   source SHA-256. `task-relative-production.diff`, `task-relative.diff`,
   `checks.json` and `final-fingerprints.json` bind the delta and scoped whitespace/
   local-link checks to the reviewed artifacts. Predecessor dirty changes are not
   attributed to this task.
6. Boundary: this runbook and `journal.md` map implemented behavior to execution.
   Evidence is limited to the Flutter widget runner on Linux. NOT_CHECKED:
   compiled browser, native desktop, physical Android, screen reader, live
   Agent/provider, full daily-workflow/parity and release qualification.

The Wing-local receipts live under
`/home/xel/.hermes/profiles/wing/autogoal/queued-dialog-intent/`.
No package installation, live runtime, credential access, upstream changes,
commit, staging, push or deployment was part of this repair.

Authority: [API and state](../adr/api-and-state.md),
[client architecture](../adr/client.md) and
[authorization threat model](../security/threat-model.md#authorization).
Implementation: [message flow](../../lib/features/hermes_chat/composer/hermes_chat_message_flow.dart)
and [screen lifetime](../../lib/features/hermes_chat/screens/hermes_chat_screen.dart).
Regression: [actual Chat widgets](../../test/features/hermes_chat/screens/hermes_chat_queued_dialog_intent_test.dart).

## Queued Open session failure ownership

Queued Open session now captures the existing composer-owner generation before
awaiting session selection. Failure feedback is ignored if that generation
changed, the channel disconnected, or the initiating context unmounted. The
existing screen observers advance the generation synchronously for channel,
connection, origin, contact, profile, active session and restoration changes;
returning A-B-A before a frame cannot revive the obsolete failure. This repair
adds no observers or lifecycle state and does not change Manage/Cancel All,
directory activation, selection admission or transport behavior. Same-owner
failure still uses the existing localized, redacted message and permits retry.

The [Open session widget regression](../../test/features/hermes_chat/screens/hermes_chat_queued_open_owner_test.dart)
uses the real `HermesChatScreen` at 390 and 1280 pixels: compact overflow menu
and wide Open session button, normal composer queue admission, and a test-local
channel selection gate. Before production edits, both profile-change cases
failed with an unexpected `hermes-queued-follow-up-error` on the replacement
owner. The RED command exited 1:

```sh
flutter test test/features/hermes_chat/screens/hermes_chat_queued_open_owner_test.dart --plain-name 'queued Open rejects stale profile failure' --reporter expanded
```

Final GREEN covers profile/origin/session/contact/channel replacement and
same-frame returns, disconnect/reconnect, replacement queue admission and Chat
disposal. Profile and origin replacements deliberately reuse session IDs. Tests
assert no stale queue error, no changed queue summary or composer draft after
rejection, exact retained queue rows where visible, no unintended sends and no
extra selections. Same-owner errors retain redaction and a working retry entry.
An initial same-owner harness assertion incorrectly assumed ANSI stripping;
the test was corrected to exercise the existing redaction contract with an inert
synthetic marker. No sanitizer behavior was changed or claimed.

Executed final commands, each exit 0:

```sh
dart format lib/features/hermes_chat/composer/hermes_chat_message_flow.dart test/features/hermes_chat/screens/hermes_chat_queued_open_owner_test.dart
flutter analyze
flutter test test/features/hermes_chat/screens/hermes_chat_queued_open_owner_test.dart test/features/hermes_chat/screens/hermes_chat_queued_dialog_intent_test.dart test/features/hermes_chat/controllers/hermes_follow_up_queue_test.dart test/features/hermes_chat/screens/hermes_chat_gateway_switch_test.dart test/features/hermes_chat/screens/hermes_chat_screen_auth_recovery_test.dart test/features/hermes_chat/screens/hermes_chat_reconnect_owner_test.dart --concurrency=1 --reporter expanded
```

The combined target run passed 194 tests, including 30 new Open session tests;
the analyzer found no issues. Changed Dart formatting made no further changes.
Evidence is limited to the Linux Flutter widget runner with deterministic local
channels, not a live Agent, compiled browser/native app, physical device or full
parity qualification. No shared fakes, upstream repositories, dependencies,
credentials or predecessor lifecycle code were changed for this repair.
