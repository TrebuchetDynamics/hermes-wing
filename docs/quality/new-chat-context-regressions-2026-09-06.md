# New-chat context regressions — 2026-09-06

## Findings and changes

New-chat creation left the previous session writable while its POST was pending.
It also activated the new session before initial history finished loading. New
Chat now clears the previous send target immediately and activates the accepted
session after that history request finishes, including the existing bounded
history-failure recovery path.

Creation and branching did not participate in session-selection ordering. A late
history read could reopen an older session after New Chat, and a late create or
fork response could replace a newer selection. These operations now respect
selection ordering and profile generations. Clearing the active session also
invalidates pending selections. Accepted creations remain listed in the current
profile without overriding a later selection.

Eight focused tests cover pending creation/history, selection ordering in both
directions, delayed branching, creation rejection, cleared selection, and a
profile roundtrip. Five tests failed before their corresponding fixes.

## Validation

Run on Linux against the local worktree:

```bash
flutter test test/core/hermes/channel/hermes_api_channel_test.dart --plain-name 'new chat'
flutter test test/core/hermes/channel/hermes_api_channel_test.dart test/features/hermes_chat/screens test/features/hermes_chat/gateways/hermes_gateway_directory_test.dart
flutter analyze
dart format --output=none --set-exit-if-changed lib/core/hermes/channel/hermes_api_channel.dart lib/core/hermes/channel/api_channel/hermes_api_channel_sessions.dart test/core/hermes/channel/hermes_api_channel_tests/session_mutation_tests.dart
git diff --check
```

Results: 8 focused tests and 568 broader tests passed; analysis reported no issues;
formatting required no changes; whitespace checks passed. The worktree contains
concurrent unrelated changes; these totals describe the tested worktree.

No live Agent or phone was exercised. These tests demonstrate client routing
races, not the cause of the reported Sidon response. Project selection support
and Agent persona/workspace authority are unchanged. No API contract, credential,
capability gate, or Wing Link data-plane boundary was changed.
