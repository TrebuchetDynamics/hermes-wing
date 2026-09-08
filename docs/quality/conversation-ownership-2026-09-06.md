# Conversation ownership — 2026-09-06

The approved slice strengthens ownership in the existing Hermes channel. It does
not change Agent APIs, credentials, capability authorization, or Wing Link.

Profile selection now publishes its pending state. Send and New Chat are disabled
during the transition, and the composer retains its draft. Conversation requests
use a shared guard that captures connection and profile generations, rejects new
work during selection, and rejects stale completions after switching away and
back. Rename completions additionally check that no newer rename owns the result.

Five channel cases cover successful/failed profile transitions, rename/delete
completions after a profile roundtrip, and overlapping rename responses. One
widget test verifies disabled Send and draft preservation. Transition and rename
tests exposed failures before the corresponding fixes. The first delete fixture
was rejected for an invalid response; its corrected response verifies the guard.

Validation on Linux:

```bash
flutter test test/core/hermes/channel/hermes_api_channel_test.dart test/features/hermes_chat/screens/hermes_chat_profile_switch_test.dart
flutter test test/core/hermes/channel/hermes_api_channel_test.dart test/features/hermes_chat/screens test/features/hermes_chat/gateways/hermes_gateway_directory_test.dart
flutter analyze
dart format --output=none --set-exit-if-changed lib/core/hermes/channel/hermes_api_channel.dart lib/core/hermes/channel/hermes_channel_state.dart lib/core/hermes/channel/api_channel/hermes_api_channel_sessions.dart lib/core/hermes/channel/api_channel/hermes_api_channel_messaging.dart lib/features/hermes_chat/composer/hermes_chat_message_flow.dart test/core/hermes/channel/hermes_api_channel_tests/lifecycle_race_tests.dart test/features/hermes_chat/screens/hermes_chat_profile_switch_test.dart
git diff --check
```

The focused suite passed 288 tests and the broader suite passed 577 tests.
Analysis initially found a missing-braces lint, which was corrected. These totals
include other local worktree changes and are not counts of newly added tests.

No phone or live Agent was exercised. History reconciliation, incomplete-history
transport eligibility, and redundant selection persistence remain separate audit
items. No commit or push was performed for this slice.
