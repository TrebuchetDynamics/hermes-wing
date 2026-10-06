# Chat session-pin write order

## Delivered behavior

Rapid pin choices within one `HermesSessionPinStore` no longer start overlapping
preference commits. Pin entries and notifications still update without waiting
for persistence. A single persistence future serializes commits and coalesces
choices made during a pending commit into the latest bounded snapshot (at most
256 tokens). There is no queue retaining every intermediate snapshot.

A rejected or false-returning write settles without automatically retrying that
choice. A newer deliberate choice, whether already waiting or made later, can
start another write containing current local state. Disposal fences waiting work
and new calls; an already-started platform commit remains uncancelled and may
settle. A toggle future waits for the shared persistence drain, not a separate
commit for each intermediate choice. Persistence failure is still best-effort,
not a reported success or durable-storage guarantee.

The preference key, gateway/profile/session token schema, validation and eviction
are unchanged. Pins remain Wing-local presentation preferences; Hermes Agent
owns sessions. No caller, backend, transport, Wing Link or upstream change is
included. See the [client decision](../adr/client.md) and
[authority boundary](../adr/api-and-state.md).

The [pin-lifetime runbook](chat-session-pin-lifetime.md) is the historical receipt
for predecessor task `t_438fb753`, run 60. Its statement that that repair did not
serialize writes remains accurate for its delivered scope. This task adds
ordering and reruns its affected tests; it does not rewrite that receipt.

## Reachability and regression harness

Installed `shared_preferences` 2.5.5's legacy `setStringList` calls `_setValue`,
which updates an optimistic cache and directly returns the platform `setValue`
future. Installed `shared_preferences_platform_interface` 2.4.2 exposes
`Future<bool> setValue(...)` with no serialization requirement. Delaying commit
until that future's explicit gate is released is representable at this boundary;
this is not a claim about physical operating-system commit scheduling.

Both Chat pin controls call `toggle` unawaited: the session sheet in
`hermes_chat_connection.dart` and the wide session rail in
`hermes_chat_layout.dart`. Chat initializes/loads the store and disposes it in
`hermes_chat_screen.dart`. These callers were inspected, not changed.

The new write-order test uses the real store and a task-local platform fake.
Explicit completers control admission and commit; five-second deadlines bound
waits. Event-queue barriers only drain admitted microtasks, not elapsed-time
sleeps. Fresh-load checks reset the plugin singleton so they read committed fake
storage instead of the optimistic cache. Teardown resets the singleton and
restores the original platform. No physical preferences are accessed.

## Executed evidence — task t_c0073c10

Evidence journal: profile-local `autogoal/session-pin-write-order/`.

1. Pre-edit RED: `red.jsonl`, `red-receipt.json`, `red-counts.json`; exit 1,
   one failed regression. A pin commit was held pending, the same pin was toggled
   off and committed, then the older pin commit was released. In-memory unpin
   passed; a fresh store incorrectly read pinned (`Expected: false`, `Actual:
   true`). Baseline source SHA-256:
   `3a5411c98f946ae9b2089c9f4d431bce3baaf771db9eeb03c934972f65ea30da`.
2. GREEN: `green-final.log`, `green-final-counts.json`; exit 0. Seven new tests
   cover rapid pin/unpin, distinct sessions and gateway/profile tokens,
   coalescing, rejected/false writes with waiting and later deliberate choices,
   no automatic retry, and disposal while waiting. Maximum concurrent platform
   commits is asserted as one. Existing tests also pass: eight lifetime, two
   pin-store and 33 disclosure widget cases (50 total).
3. Only the pin store changes production behavior. `task-relative.diff` compares
   captured baseline bytes, not Git HEAD (which predates the lifetime repair).
   `final-fingerprints.json` binds source, tests, documentation and logs.
   Final store SHA-256:
   `1ed310db84959c95f81244ae949a5c97f5b7ce4c10ff86046bb685e3bd4fb769`.
4. `checks-final.json` and `final-checks.json` record commands/exits: changed-file
   formatting, analyzer, four focused test targets, scoped diff whitespace,
   new-file whitespace and local-link checks. Analyzer reports no issues.
   Existing test oracles, lifetime receipt and unrelated tracked diffs remain
   unchanged. `acceptance.json` maps each criterion to evidence and fingerprints.
5. Delivered result: settled successful same-store commits preserve the newest
   pin choices rather than allowing an older pending commit to overwrite them.
   Failure and lifetime limits below remain explicit.

## Repeat focused validation

From the repository root with the installed Flutter tools on `PATH`:

```sh
dart format --output=none --set-exit-if-changed lib/features/hermes_chat/session/hermes_session_pin_store.dart test/features/hermes_chat/session/hermes_session_pin_store_write_order_test.dart
flutter analyze --no-pub
flutter test --no-pub --reporter=json test/features/hermes_chat/session/hermes_session_pin_store_write_order_test.dart test/features/hermes_chat/session/hermes_session_pin_store_lifetime_test.dart test/features/hermes_chat/session/hermes_session_pin_store_test.dart test/features/hermes_chat/screens/hermes_chat_session_disclosure_test.dart
git diff --check -- lib/features/hermes_chat/session/hermes_session_pin_store.dart
```

## Qualification limits

No guarantee is added for failed persistence, crash durability, cancellation of
started commits, a permanently non-settling platform future, or races between
separate Chat/store instances. Coalescing deliberately does not preserve every
intermediate state. A newer explicit choice persists the current local snapshot;
there is no independent automatic retry/replay mechanism.

NOT_CHECKED: physical preference storage, compiled browser, native app interaction,
Android, screen reader, live Agent/provider, integrated daily workflow, full
repository suite, full Desktop parity and release. Evidence is from the Linux
Flutter test runner and deterministic widget tests, not platform qualification.
Native review remains a separate approval gate.
