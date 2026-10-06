# Chat session-pin lifetime

## Delivered behavior

Chat owns a local `HermesSessionPinStore`: it starts `load()` without awaiting
it and disposes the store when Chat leaves. Both session-picker pin actions call
`toggle()` without awaiting it. A toggle waiting for the initial preference read
must not resume as an active action after that store is disposed.

The store now checks its lifetime at entry and after asynchronous preference
acquisition. Disposal releases its retained load future and pin entries, while
`ChangeNotifier.dispose()` releases listeners. Late successful or failed reads
settle without populating or notifying the disposed store. Obsolete toggles do
not initiate preference writes. Calls to `load()` and `toggle()` after disposal
complete without reading or writing platform preferences.

A platform write that already started can still complete after disposal. This
repair does not cancel or roll back that write, serialize concurrent writes, or
change pin tokens, bounds, eviction, or gateway/profile identity. Pins remain
Wing-local presentation preferences; Hermes Agent still owns sessions. No Agent
API, Wing Link, transport, or upstream changes are involved. See the
[client lifetime boundary](../adr/client.md) and
[domain authority boundary](../adr/api-and-state.md).

## Focused regression checks

From the repository root with Flutter on `PATH`:

```sh
dart format --output=none --set-exit-if-changed lib/features/hermes_chat/session/hermes_session_pin_store.dart test/features/hermes_chat/session/hermes_session_pin_store_lifetime_test.dart
flutter analyze --no-pub
flutter test --no-pub --reporter=json test/features/hermes_chat/session/hermes_session_pin_store_lifetime_test.dart test/features/hermes_chat/session/hermes_session_pin_store_test.dart test/features/hermes_chat/screens/hermes_chat_session_disclosure_test.dart
git diff --check -- lib/features/hermes_chat/session/hermes_session_pin_store.dart
```

The lifetime test uses an isolated installed shared_preferences platform fake,
explicit read/write completers, and five-second completion deadlines, not sleeps.
It restores the original platform and resets the plugin singleton in teardown.
The real production store is exercised; no substitute store implements its logic.

## Acceptance evidence — task t_438fb753

Evidence journal: profile-local `autogoal/session-pin-lifetime/`.
Exact executed commands, including absolute Flutter tool paths, are in
`red-receipt.json` and `checks.json`. Flutter 3.44.2 / Dart 3.12.2 ran on Linux.

1. Executed pre-edit RED: `red.jsonl` and `red-receipt.json`, exit 1.
   The delayed read was settled after disposal while a real toggle awaited load.
   The future failed with “A HermesSessionPinStore was used after being disposed”
   at the original `toggle()` notification. Baseline source SHA-256:
   `d361019aa7efd9f0400046a69c885126375cc7f587808f1451ef44f248757014`.
2. Executed GREEN: `green-final.log`, exit 0; parsed `test-counts.json` records
   8 lifetime tests, 2 unchanged pin-store tests, and 33 unchanged disclosure
   widget tests: 43 passed. Cases cover disposal during load, pending toggle,
   calls after disposal, normal owner-specific pin/unpin and persistence,
   delayed read failure, persistence acquisition after disposal, and an
   already-started write settling without a second write.
3. Scoped implementation: only
   `lib/features/hermes_chat/session/hermes_session_pin_store.dart` changes
   production behavior. Lifetime guards and disposal cleanup do not change
   token validation, eviction, or remote authority. `task-relative.diff` records
   the production edit and the two new files; `final-fingerprints.json` binds
   the artifacts and checks predecessor tracked diff preservation.
4. Validation: changed-file format exit 0; `analyze.log`, exit 0, no issues;
   `green-final.log`, exit 0. Final format-check, scoped diff-check, new-file
   whitespace, and local-link results are recorded in `checks.json` and
   `final-checks.log`. An initial GREEN attempt exposed a nested-list record
   equality mistake in the new test; field-wise assertions fixed it. That
   attempt remains recorded in `green.log`, not presented as passing evidence.
5. Source-bound delivery: final production SHA-256
   `3a5411c98f946ae9b2089c9f4d431bce3baaf771db9eeb03c934972f65ea30da`.
   The profile journal's `acceptance.json` maps this receipt to the commands,
   final fingerprints, delivered lifecycle change, and qualification limits.

## Qualification limits

NOT_CHECKED: physical platform preference storage or clipboard, compiled browser,
native desktop application interaction, live Agent/provider behavior, full
Desktop daily-workflow/parity, full repository suite, and release qualification.
The Linux Flutter test runner and widget tests are not native application or
physical preference qualification. Prior clipboard receipts are predecessor
work, not new acceptance evidence for this repair.
