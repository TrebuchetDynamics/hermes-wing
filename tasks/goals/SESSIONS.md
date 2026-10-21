+++
schema = 1
id = "SESSIONS"
title = "Qualify exact session search/resume/fork/rename/delete"
priority = 3
source = "docs/product/hermes-desktop-parity.md#statuses"
status = "met"
focus = false
depends_on = []
+++

- Evidence: executed: dart format --output=none --set-exit-if-changed test/features/hermes_chat/screens/hermes_chat_session_delete_journey_test.dart (pass)
- Evidence: executed: dart format --output=none --set-exit-if-changed test/features/hermes_chat/screens/hermes_chat_session_fork_journey_test.dart (pass)
- Evidence: executed: dart format --output=none --set-exit-if-changed test/features/hermes_chat/screens/hermes_chat_session_rename_journey_test.dart (pass)
- Evidence: executed: dart format --output=none --set-exit-if-changed test/features/hermes_chat/screens/hermes_chat_session_search_resume_journey_test.dart (pass)
- Evidence: executed: dart format --output=none --set-exit-if-changed test/features/hermes_chat/screens/hermes_chat_session_search_resume_journey_test.dart 2>&1 | tee .task-evidence/t_8866900e/format.log (pass)
- Evidence: executed: dart format test/features/hermes_chat/screens/hermes_chat_session_search_resume_journey_test.dart (pass)
- Evidence: executed: flutter analyze (pass)
- Evidence: executed: flutter analyze 2>&1 | tee .task-evidence/t_8866900e/analyze-final.log (pass)
- Evidence: executed: flutter analyze 2>&1 | tee .task-evidence/t_8866900e/analyze.log (fail)
- Evidence: executed: flutter test --concurrency=1 test/core/hermes/channel/hermes_api_channel_test.dart --name 'fork|session mutation ownership' (pass)
- Evidence: executed: flutter test --concurrency=1 test/core/hermes/channel/hermes_api_channel_test.dart --name 'latest session selection|stale session history' (pass)
- Evidence: executed: flutter test --concurrency=1 test/core/hermes/channel/hermes_api_channel_test.dart --name 'latest session selection|stale session history' 2>&1 | tee .task-evidence/t_8866900e/channel-selection.log (pass)
- Evidence: executed: flutter test --concurrency=1 test/core/hermes/channel/hermes_api_channel_test.dart --name 'session mutation ownership|deleteSession' (pass)
- Evidence: executed: flutter test --concurrency=1 test/core/hermes/channel/hermes_api_channel_test.dart --plain-name 'session mutation ownership' (pass)
- Evidence: executed: flutter test --concurrency=1 test/core/hermes/channel/hermes_api_channel_test.dart --plain-name deleteSession (pass)
- Evidence: executed: flutter test --concurrency=1 test/core/hermes/channel/hermes_session_caller_admission_test.dart --name 'open caller' (pass)
- Evidence: executed: flutter test --concurrency=1 test/core/hermes/channel/hermes_session_caller_admission_test.dart --name 'open caller' 2>&1 | tee .task-evidence/t_8866900e/channel-open.log (pass)
- Evidence: executed: flutter test --concurrency=1 test/core/hermes/hermes_api_test.dart --name 'deletes a session over DELETE|rejects an unconfirmed delete response' (pass)
- Evidence: executed: flutter test --concurrency=1 test/core/hermes/hermes_api_test.dart --plain-name 'forks a session over POST' (pass)
- Evidence: executed: flutter test --concurrency=1 test/features/hermes_chat/screens/hermes_chat_gateway_switch_test.dart --name 'session search|session source filter|header selects an older session' (pass)
- Evidence: executed: flutter test --concurrency=1 test/features/hermes_chat/screens/hermes_chat_gateway_switch_test.dart --name 'session search|session source filter|header selects an older session' 2>&1 | tee .task-evidence/t_8866900e/filtering.log (pass)
- Evidence: executed: flutter test --concurrency=1 test/features/hermes_chat/screens/hermes_chat_session_delete_journey_test.dart (pass)
- Evidence: executed: flutter test --concurrency=1 test/features/hermes_chat/screens/hermes_chat_session_fork_journey_test.dart (pass)
- Evidence: executed: flutter test --concurrency=1 test/features/hermes_chat/screens/hermes_chat_session_fork_journey_test.dart 2>&1 | tee .task-evidence/t_36a391f7/journey.log (initial run; retained as journey-initial.log) (fail)
- Evidence: executed: flutter test --concurrency=1 test/features/hermes_chat/screens/hermes_chat_session_mutation_owner_test.dart (pass)
- Evidence: executed: flutter test --concurrency=1 test/features/hermes_chat/screens/hermes_chat_session_rename_journey_test.dart (pass)
- Evidence: executed: flutter test --concurrency=1 test/features/hermes_chat/screens/hermes_chat_session_rename_journey_test.dart test/features/hermes_chat/screens/hermes_chat_session_mutation_owner_test.dart (pass)
- Evidence: executed: flutter test --concurrency=1 test/features/hermes_chat/screens/hermes_chat_session_search_resume_journey_test.dart (pass)
- Evidence: executed: flutter test --concurrency=1 test/features/hermes_chat/screens/hermes_chat_session_search_resume_journey_test.dart 2>&1 | tee .task-evidence/t_8866900e/journey-initial.log (pass)
- Evidence: executed: flutter test --concurrency=1 test/features/hermes_chat/screens/hermes_chat_session_search_resume_journey_test.dart 2>&1 | tee .task-evidence/t_8866900e/journey.log (pass)
- Evidence: executed: flutter test --concurrency=1 test/features/hermes_chat/screens/hermes_chat_session_settlement_owner_test.dart (pass)
- Evidence: executed: flutter test --concurrency=1 test/features/hermes_chat/screens/hermes_chat_session_settlement_owner_test.dart 2>&1 | tee .task-evidence/t_8866900e/settlement-owner.log (pass)
- Evidence: executed: git diff --check -- goals.json TODO.md (pass)
- Evidence: executed: git diff --no-index --check /dev/null docs/quality/session-delete-journey.md (pass)
- Evidence: executed: git diff --no-index --check /dev/null docs/quality/session-fork-journey.md (pass)
- Evidence: executed: git diff --no-index --check /dev/null docs/quality/session-rename-journey.md (pass)
- Evidence: executed: git diff --no-index --check /dev/null docs/quality/session-search-resume-journey.md (pass)
- Evidence: executed: git diff --no-index --check /dev/null test/features/hermes_chat/screens/hermes_chat_session_delete_journey_test.dart (pass)
- Evidence: executed: git diff --no-index --check /dev/null test/features/hermes_chat/screens/hermes_chat_session_fork_journey_test.dart (pass)
- Evidence: executed: git diff --no-index --check /dev/null test/features/hermes_chat/screens/hermes_chat_session_rename_journey_test.dart (pass)
- Evidence: executed: git diff --no-index --check /dev/null test/features/hermes_chat/screens/hermes_chat_session_search_resume_journey_test.dart (pass)
- Evidence: executed: git diff-tree --check f84e8ebde582e626669492856464a31b44de1d4b^ f84e8ebde582e626669492856464a31b44de1d4b (pass)
- Evidence: executed: git show --format= --check 222be4ee4068a00aa553a1dceddc52b21a52ffed (pass)
- Evidence: executed: git show --format= --check agent/wing/t_36a391f7 (pass)
- Evidence: executed: python <home>/.hermes/shared-skills/repo-docs/scripts/goals.py validate . (pass)
- Evidence: inspection: docs/product/hermes-desktop-parity.md#statuses (pass)
