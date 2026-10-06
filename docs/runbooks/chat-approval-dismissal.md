# Chat approval dismissal ownership

Status: executor-verified deterministic regression and queue repair on
`t_6233c1c5`; independent same-card review remains required. This is not native
application, browser, live Agent, or release qualification.

## Reproduced path

The real `HermesChatScreen` widget retains malformed request A's Review sheet
through a channel disconnect/reconnect. The queue resets, then receives valid
request B. The modal barrier blocks pointer access to B, but the reset/rebuild
moves keyboard focus into the background route. Ordinary Tab reaches B's
**Approve once** button; Enter starts one delayed channel answer while A's sheet
is still present. No private callback, forced focus, barrier removal, or direct
queue call is used to admit B.

Before the repair, tapping the retained A **Dismiss** removes B's responding
indicator before its answer settles. The discriminating oracle fails with
`stale A must not release B`. This proves lost UI queue admission/busy ownership,
not a duplicate approval POST to Hermes Agent. The production channel/responder
has separate authorization, correlation, and duplicate-network admission guards.

After the repair, A's stale dismissal leaves B's busy indicator and disabled
answer button intact until B settles. The deterministic channel sees exactly
one invocation. The keyboard-focus behavior is unchanged: this repair is confined
to queue dismissal and does not claim to repair modal focus containment.

## Dismissal contract

`HermesApprovalQueue.dismiss` requires the exact displayed request instance still
to be queued, rather than merely an equal identity key. A same-key replacement
after reset cannot be removed by an old captured callback. An answering request
cannot be locally dismissed. Dismissing a different current malformed request
removes only that prompt and never settles another answer's busy marker.

Dismissal performs no Agent request. Existing successful/error answer settlement,
explicit retry, reset, disposal, and authoritative exact-turn Stop behavior stay
separate. Started requests are not cancelled, replayed, or undone.

## Additional investigated paths

- Channel rebinding runs `watch`/`reset` and retains A's sheet. In the exercised
  deterministic flow B is pointer-blocked and Tab remains in the sheet; B is
  answered only after A Dismiss. This is a bounded control, not universal
  keyboard unreachability.
- The real profile picker admits a switch and resets the queue synchronously
  before awaiting selection. A may arrive and open Review while selection is
  delayed. Completing selection while the sheet remains does not reset A again;
  A stays the queue head until Dismiss. The exercised Tab traversal and
  Ctrl+K/Ctrl+N do not invoke background actions in this control.
- `clearPending` clears pending requests but deliberately preserves an ongoing
  answer. Its callers are disconnect/contact-change actions behind modal UI,
  with contact departure confirmation where applicable. Queue controls prove
  subsequent stale dismissal cannot release that preserved answer. No new
  real-screen reachability claim is made for these contact-change paths.
- `dismissStoppedTurn` requires the exact channel, connection, profile, session,
  and non-null run. A malformed request with neither approval nor run identity
  cannot match a normal owned run. The queue regression proves a run-less
  malformed prompt remains; the existing Review widget test exercises actual
  Stop on a correlated approval and a subsequent run. No hidden Stop callback
  is invoked through an open sheet.

## Validation

Run from the repository root:

```sh
flutter test --no-pub --concurrency=1 \
  test/features/hermes_chat/screens/hermes_chat_approval_dismissal_test.dart \
  test/features/hermes_chat/messaging/approvals/hermes_approval_queue_test.dart \
  test/features/hermes_chat/screens/hermes_chat_approval_review_test.dart \
  test/core/hermes/channel/hermes_approval_settlement_owner_test.dart
flutter analyze --no-pub
dart format --output=none --set-exit-if-changed \
  lib/features/hermes_chat/messaging/approvals/hermes_approval_queue.dart \
  test/features/hermes_chat/messaging/approvals/hermes_approval_queue_test.dart \
  test/features/hermes_chat/screens/hermes_chat_approval_dismissal_test.dart
```

The four-target run passes 44 tests; analysis reports no issues and scoped format
reports zero changes. Queue controls include stale/absent dismissal, same-key
replacement, different owners, current malformed dismissal, preservation of an
ongoing answer, delayed success/error and explicit retry, disposal, reset,
`clearPending`, and exact-turn invalidation. The widget regression is run with
the Linux target-platform variant in Flutter's test harness, not a native window.

Profile-local `autogoal/approval-dismissal/native174-*` receipts hold command
outputs, the original widget RED, the final identical-oracle isolated RED/GREEN,
source fingerprints, scoped diff, and preservation manifest. The isolated RED
uses the original queue only in a copy; the working tree is never temporarily
reverted. Early harness compilation/animation failures are not counted as RED.

Native UI/browser/live/full-suite/packaged/integrated parity/release:
`NOT_CHECKED`. Linux native build prerequisite `BLK-20261005-003` does not block
these deterministic tests. Agent API and upstream source inspections are contract
context only; no upstream code or backend authority was changed.
