# History reconciliation — 2026-09-06

The approved history slice fixes delayed session-selection and foreground history
reads overwriting newer streaming or completed turns. The selection path captures
the transcript it started from and rejects results if that transcript or selection
has changed. The shared history reader checks caller acceptance before updating
pagination, recent turns, or the run-history snapshot. Stream-completion readers
also pass their existing run-ownership predicate into this acceptance check.

Three regression cases cover active reply preservation, completed reply
preservation, and obsolete pagination/run context. The first two failed before the
fix. The cache test was strengthened to use the actual pagination envelope and
inspect the subsequent run request; temporarily removing the cache acceptance
check made that test fail, and restoring it made it pass.

Validation on Linux:

```bash
flutter test test/core/hermes/channel/hermes_api_channel_test.dart
flutter test test/core/hermes/channel/hermes_api_channel_test.dart test/features/hermes_chat/screens test/features/hermes_chat/gateways/hermes_gateway_directory_test.dart
flutter analyze
dart format --output=none --set-exit-if-changed lib/core/hermes/channel/api_channel/hermes_api_channel_connection.dart lib/core/hermes/channel/api_channel/hermes_api_channel_sessions.dart lib/core/hermes/channel/api_channel/hermes_api_channel_messaging.dart test/core/hermes/channel/hermes_api_channel_tests/session_mutation_tests.dart
git diff --check
```

Results: 286 channel tests and 580 broader tests passed. Analysis reported no
issues; formatting and whitespace checks passed. Counts include existing local
worktree changes. No live Agent or physical phone was exercised.

Agent API contracts, credentials, capability gating, and Wing Link ownership are
unchanged. The 500-message history limit and redundant selection persistence are
separate audit items. Changes were not committed or pushed.
