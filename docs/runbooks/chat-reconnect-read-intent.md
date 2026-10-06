# Direct Reconnect saved-read intent

Status: implemented and independently approved in same-card review run 278.
Deterministic Linux-host widget/static checks passed. Native, browser and live
transport qualification are NOT_CHECKED by this receipt.

## Behavior

An explicit Chat Reconnect may await saved gateway metadata and secure storage.
After that read, Wing connects only if the originating screen is still mounted,
its channel and Chat owner generation are unchanged, and no newer connection-form
intent has occurred. Leaving and returning to an owner does not restore a pending
read's authority. Obsolete success and rejection are inert: no controller writes,
connect, persistence, resend or session/profile mutation.

A current storage rejection gives the existing localized secure-storage recovery
message without exposing platform error text or attempting a credential fallback.
A subsequent explicit Reconnect can try again. Duplicate Reconnect taps share the
current operation; no automatic retry or resend is added.

The form's read-intent generation advances on text changes, explicit saved
selection/preset, new connect attempts and abandonment. Edit-and-return and
same-value explicit actions count; cursor selection and credential masking do not.
This does not change normalized network-attempt staleness or the existing
[saved-list autofill intent](chat-endpoint-load-intent.md).

## Source trace and limits

- The visible `hermes-chat-error-reconnect` action in
  [the error widget](../../lib/features/hermes_chat/screens/widgets/hermes_chat_error.dart)
  reaches `_reconnect` through
  [Chat layout](../../lib/features/hermes_chat/screens/state/hermes_chat_layout.dart).
- [Direct recovery](../../lib/features/hermes_chat/screens/state/hermes_chat_connection.dart)
  preserves the directory exact-session branch before fencing the direct read.
- [Secure endpoint loading](../../lib/core/hermes/setup/secure_hermes_endpoint_store.dart)
  awaits `loadProfiles`, the secure bundle/preferences, and selected-profile
  preferences. This is a real platform-await boundary, not just network delay.
- The existing owner generation in
  [Chat](../../lib/features/hermes_chat/screens/hermes_chat_screen.dart) records
  channel, connection, endpoint, contact, profile, session and restoration changes.
  No new owner registry or domain state was introduced.
- [Form intent](../../lib/features/hermes_chat/controllers/hermes_connection_form.dart)
  adds a read generation without changing connect-attempt equivalence.

Reauthorization and disconnect-confirmation admission were not repaired. Manual
field preservation is exercised through public Update key after an authentication
notification while Reconnect's storage read is pending; the test does not bypass
a modal barrier. Form-only generation behavior is covered by controller tests,
not claimed as a separately reachable Chat recovery screen configuration.

No Agent/Wing Link/channel protocol, credential acquisition, capability gate,
packaging, module, dependency or import changes. Existing Flutter entrypoint and
part-file delivery remain unchanged. Upstream reference clones remain read-only.

## Regression evidence

[The widget regression](../../test/features/hermes_chat/screens/hermes_chat_reconnect_read_owner_test.dart)
mounts real HermesChatScreen and taps hit-tested visible Reconnect. Only the
direct endpoint store's `load` is gated; the empty directory has its own store.
Test-local fixtures preserve shared fakes.

Before repair, the public-widget run failed on disposed-controller access, stale
connects after channel/session changes, manual field replacement, and unhandled
read rejection. The final identical widget oracle rerun against captured baseline
production in an isolated task project produced 1 pass and 11 failures (exit 1).
Repaired execution of all named tests produced 59 passes (exit 0):

```sh
flutter test --concurrency=1 --reporter expanded \
  test/features/hermes_chat/screens/hermes_chat_reconnect_read_owner_test.dart \
  test/features/hermes_chat/screens/hermes_chat_screen_auth_recovery_test.dart \
  test/features/hermes_chat/screens/hermes_chat_reconnect_owner_test.dart \
  test/features/hermes_chat/controllers/hermes_connection_form_test.dart \
  test/features/hermes_chat/screens/hermes_chat_endpoint_load_intent_test.dart
flutter analyze
git diff --check
```

The new widget cases cover late success/rejection after unmount, channel
replacement and return, session change and return, and newer manual form edits;
current rejection with explicit retry; equivalent normalized saved URL; and
hit-tested duplicate taps. Named existing tests retain saved-credential URL
equivalence and directory off-page exact-session recovery. Operation-count
assertions reject stale connect, persistence, sends and session/profile mutations;
manual Update key's deliberate disconnect is counted separately. Framework
exceptions and stale storage-error feedback are rejected.

Logs, baseline source snapshots, final fingerprints, exact delta and acceptance
mapping are in `.task-evidence/t_af394f96/`. An initial test-local connect override
omitted the existing `deferSessionSelection` parameter; that harness compile error
and analyzer diagnostics were fixed and retained in the earlier logs. Final
analyzer reported no issues. Changed-file formatter, whitespace and local link
checks are recorded in the task evidence.

The full repository complete gate, native desktop interaction, browser E2E,
physical platforms, live Agent/provider behavior and distribution builds are
NOT_CHECKED. This scoped correction is not integrated daily-workflow admission.
See the [client ownership boundary](../adr/client.md#transport-qualification).
