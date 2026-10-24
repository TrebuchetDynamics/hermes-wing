+++
schema = 1
id = "LINUXQA-002-a4c6f5a3"
title = "Restore the rendered transcript corner regression for accepted Desktop styling"
short = "Repair stale transcript corner test"
status = "open"
goal = "PARITY"
section = "Now"
rank = 1000
depends_on = []
touches = ["test/features/hermes_chat/screens/hermes_chat_rich_transcript_test.dart"]
resources = []
kind = "implementation"
ownership = "worker"
scope = "Reproduce the recorded compact Desktop corner failure on current source; reconcile any repair already landed during Files verification. Update only the stale rendered user/assistant radius expectations to the accepted 3.2px/0px treatment traced in the plan. Keep both assertions and all surrounding transcript behavior; do not revert production styling or suppress a test. This is a Linux test prerequisite, not new feature work."
acceptance = ["The existing test message surfaces use the compact Desktop corner treatment in hermes_chat_rich_transcript_test.dart checks rendered user radius 3.2 and assistant radius 0, matching the pinned official token/classes and current production implementation; the whole transcript target passes.", "A temporary private mutation returning either rendered radius to 20 is rejected by the corrected test; restore exact production source and gate the final candidate. No production style change, skipped case or weaker assertion ships."]
checks = ["flutter pub get --enforce-lockfile", "flutter test --no-pub --concurrency=1 test/features/hermes_chat/screens/hermes_chat_rich_transcript_test.dart", "dart format --output=none --set-exit-if-changed test/features/hermes_chat/screens/hermes_chat_rich_transcript_test.dart", "flutter analyze --no-pub", "git diff --check"]
exclusions = ["No production/UI change, Agent edits, credentials, live operation, service change or publication", "Do not edit or restore the active Files candidate"]
+++
- Sources: docs/plans/2026-10-21-linux-feature-qualification.md#current-linux-app-retest
