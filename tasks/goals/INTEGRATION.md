+++
schema = 1
id = "INTEGRATION"
title = "Source-bound merge-train integration verification"
priority = 101
source = "docs/quality/merge-train-shell-status-bar.md"
status = "partial"
focus = false
depends_on = []
+++

- Evidence: executed: cd <home>/.hermes/cache/scratch/t_cd815647/base && flutter pub get (pass)
- Evidence: executed: cd <home>/.hermes/cache/scratch/t_cd815647/base && flutter test --concurrency=1 test/shared/widgets/app_shell_test.dart (pass)
- Evidence: executed: cd <home>/.hermes/cache/scratch/t_cd815647/candidate && dart format --output=none --set-exit-if-changed test/shared/widgets/app_shell_test.dart (pass)
- Evidence: executed: cd <home>/.hermes/cache/scratch/t_cd815647/candidate && flutter analyze (pass)
- Evidence: executed: cd <home>/.hermes/cache/scratch/t_cd815647/candidate && flutter pub get (pass)
- Evidence: executed: cd <home>/.hermes/cache/scratch/t_cd815647/candidate && flutter test --concurrency=1 (pass)
- Evidence: executed: cd <home>/.hermes/cache/scratch/t_cd815647/candidate && flutter test --concurrency=1 test/shared/widgets/app_shell_test.dart [unrepaired f0bbb356c023a12074216fe88f9c99d57d45f15a] (fail)
- Evidence: executed: cd <home>/.hermes/cache/scratch/t_cd815647/candidate && flutter test --concurrency=1 test/shared/widgets/app_shell_test.dart test/shared/widgets/app_shell_focus_traversal_test.dart test/shared/widgets/app_shell_grouped_recents_test.dart test/shared/widgets/app_shell_profile_footer_test.dart test/features/hermes_chat/widgets (pass)
- Evidence: executed: cd <home>/.hermes/cache/scratch/t_cd815647/candidate && flutter test --concurrency=1 test/tooling/release_workflow_contract_test.dart (pass)
- Evidence: executed: cd <repo> && dart format --output=none --set-exit-if-changed test/shared/widgets/app_shell_test.dart (pass)
- Evidence: executed: cd <repo> && flutter analyze (pass)
- Evidence: executed: cd <repo> && flutter test --concurrency=1 test/shared/widgets/app_shell_test.dart test/shared/widgets/app_shell_focus_traversal_test.dart test/shared/widgets/app_shell_grouped_recents_test.dart test/shared/widgets/app_shell_profile_footer_test.dart test/features/hermes_chat/widgets (pass)
- Evidence: executed: cd <repo> && git diff --check -- test/shared/widgets/app_shell_test.dart (pass)
- Evidence: executed: cd <repo> && git diff --check -- test/shared/widgets/app_shell_test.dart docs/quality/merge-train-shell-status-bar.md goals.json TODO.md (pass)
- Evidence: executed: python <home>/.hermes/shared-skills/repo-docs/scripts/goals.py validate <repo> (pass)
