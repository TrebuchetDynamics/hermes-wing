# Chat approval settlement ownership

## Behavior

An approval POST belongs to the responder lifetime that admitted it. Connect,
disconnect and dispose clear responder tracking and retire that lifetime. A late
success cannot erase a replacement approval mapping, and late failure/finally
cannot release a replacement response's in-flight guard. Retired errors are
ignored by the responder; current-owner failures still report and allow explicit
retry. An acknowledged current-owner success removes its mapping.

This is local settlement fencing, not cancellation or rollback of an already
started server request. Wing does not replay approval responses on reconnect.
Agent remains authoritative and receives the exact `request_id`, run identity,
profile and original client selected when the response began. No FIFO correlation
or new transport is introduced.

## Deterministic regression

The [production-channel regression](../../test/core/hermes/channel/hermes_approval_settlement_owner_test.dart)
uses the actual `HermesApiChannel`, `HermesApiClient` and SSE decoder with injected
transport and delayed POST completion. It disconnects, reconnects to the same or
a replacement synthetic loopback origin, and registers colliding run/request
identities in the new connection. It checks replacement admission, duplicate
suppression while a newer answer is in-flight, exact request bodies and disposal.
The synthetic addresses are never contacted.

Before the repair, delayed success rejected a valid replacement answer because
its mapping had been removed. Delayed failure unlocked the newer answer's guard
and reached another POST. After the responder generation fence, the same oracles
pass. The [responder tests](../../test/core/hermes/channel/approvals/hermes_approval_responder_test.dart)
also cover identical/distinct request and run IDs, clear without re-registration,
late success/error/finally, acknowledged success and explicit same-owner retry.

```bash
flutter test --no-pub --concurrency=1 \
  test/core/hermes/channel/hermes_approval_settlement_owner_test.dart \
  test/core/hermes/channel/approvals/hermes_approval_responder_test.dart \
  test/core/hermes/channel/hermes_api_channel_test.dart \
  test/features/hermes_chat/messaging/approvals/hermes_approval_queue_test.dart \
  test/features/hermes_chat/screens/hermes_chat_approval_review_test.dart
flutter analyze --no-pub
```

This qualification is deterministic Flutter test execution on Linux, not native
UI, browser, live Agent, packaged distribution, full-suite, integrated parity or
release qualification. Those remain NOT_CHECKED for this slice.
