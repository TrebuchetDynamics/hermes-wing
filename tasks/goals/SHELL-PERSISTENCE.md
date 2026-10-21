+++
schema = 1
id = "SHELL-PERSISTENCE"
title = "Qualify collapse/expand persistence across desktop relaunch"
priority = 103
source = "docs/product/hermes-desktop-parity.md#reference-and-evidence-boundary"
status = "unverified"
focus = false
depends_on = []
+++

- Evidence: executed: dart format --output=none --set-exit-if-changed lib/features/settings/providers/shell_preferences_provider.dart lib/shared/widgets/app_shell.dart test/features/settings/providers/shell_preferences_provider_test.dart test/shared/widgets/app_shell_sidebar_persistence_test.dart (pass)
- Evidence: executed: flutter analyze (pass)
- Evidence: executed: flutter analyze --no-pub; flutter test --no-pub --concurrency=1 test/features/settings/providers/shell_preferences_provider_test.dart test/shared/widgets/app_shell_sidebar_persistence_test.dart test/integration/linux_shell_compact_return_runner_test.dart (9 passed); python3 -B integration_test/run_linux_shell_compact_return.py (Linux GTK/Xvfb PASS); independent native review approved exact 408887695a811a96ea7936418e2dad2965bc076e; docs/quality/shell-compact-return-native.md. Framework resize/key-event seams and disconnected draft fixture only; physical OS controls, production draft relaunch, Android and live Agent NOT_CHECKED. (pass)
- Evidence: executed: flutter test --no-pub --concurrency=1 (pass)
- Evidence: executed: flutter test --no-pub --concurrency=1 .task-evidence/graphify-desktop-wing/render_test.dart (pass)
- Evidence: executed: flutter test --no-pub --concurrency=1 test/features/settings/providers/shell_preferences_provider_test.dart test/shared/widgets .task-evidence/graphify-desktop-wing/render_test.dart (pass)
- Evidence: executed: git diff --check (pass)
- Evidence: executed: npm run test (pass)
- Evidence: executed: npm run test -- test/features/settings/providers/shell_preferences_provider_test.dart test/shared/widgets/app_shell_sidebar_persistence_test.dart (pass)
- Evidence: executed: npm run test [proc_9d65cfb39694; current worktree; 3699 passed, 9 failed] (fail)
- Evidence: executed: npm run test [proc_d670105d969e; full suite; 3711 passed, 0 failed] (pass)
- Evidence: inspection: docs/product/hermes-desktop-parity.md#reference-and-evidence-boundary (pass)
