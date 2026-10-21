+++
schema = 1
id = "PARITY"
title = "Match the remaining Desktop product outcomes explicitly"
priority = 102
source = "docs/product/hermes-desktop-parity.md#reference-and-evidence-boundary"
status = "partial"
focus = false
depends_on = []
+++

- Evidence: executed: bash -n scripts/run_android_maestro_features.sh (pass)
- Evidence: executed: dart format --output=none --set-exit-if-changed integration_test/hermes_features_maestro_main.dart integration_test/support/maestro/interaction_fixture.dart test/integration/maestro_approval_attachment_controls_test.dart (pass)
- Evidence: executed: dart format --output=none --set-exit-if-changed test/features/gateway/gateway_keyboard_client_test.dart (pass)
- Evidence: executed: docs/quality/android-approval-attachment-fixture-receipt.json: two explicit-device Maestro attempts exited 1 before launch; Android assertions NOT_CHECKED (fail)
- Evidence: executed: flutter analyze (pass)
- Evidence: executed: flutter analyze > .task-evidence/gateway-keyboard-analyze.log 2>&1 (pass)
- Evidence: executed: flutter test --concurrency=1 test/features/gateway/gateway_keyboard_client_test.dart > .task-evidence/gateway-keyboard-after.log 2>&1 (pass)
- Evidence: executed: flutter test --concurrency=1 test/features/gateway/gateway_keyboard_client_test.dart > .task-evidence/gateway-keyboard-before.log 2>&1 (fail)
- Evidence: executed: flutter test --concurrency=1 test/features/gateway/gateway_keyboard_client_test.dart test/features/gateway/gateway_screen_test.dart test/features/gateway/gateway_health_ownership_test.dart test/features/gateway/gateway_health_loader_ownership_test.dart (pass)
- Evidence: executed: flutter test --concurrency=1 test/features/gateway/gateway_screen_test.dart test/features/gateway/gateway_health_ownership_test.dart test/features/gateway/gateway_health_loader_ownership_test.dart > .task-evidence/gateway-keyboard-nearest.log 2>&1 (pass)
- Evidence: executed: flutter test --concurrency=1 test/integration/maestro_approval_attachment_controls_test.dart test/integration/maestro_feature_fixture_test.dart (pass)
- Evidence: executed: flutter test --no-pub --concurrency=1 --reporter=expanded test/shared/widgets/app_shell_test.dart test/shared/widgets/app_shell_desktop_parity_test.dart --name 'bottom tabs navigate to Profiles and retain selection|compact resize retains mobile navigation and desktop choice' (pass)
- Evidence: executed: flutter test --no-pub --concurrency=1 test/shared/widgets/app_shell_reference_fidelity_test.dart test/shared/widgets/app_shell_focus_traversal_test.dart (pass)
- Evidence: executed: git diff --check (pass)
- Evidence: executed: maestro check-syntax scripts/maestro/fixture/approvals_recovery.yaml (pass)
- Evidence: executed: maestro check-syntax scripts/maestro/fixture/attachment_picker_race.yaml (pass)
- Evidence: executed: npm run test -- --reporter expanded; receipt: .task-evidence/desktop-connection-docs/npm-test-result.json (fail)
- Evidence: executed: npm run test; receipt: .task-evidence/connection-entry-labels/verification-npm-test-result.json (pass)
- Evidence: executed: npm run test; receipt: .task-evidence/parity-flow-matrix/npm-test-result.json (3501 passed, zero failed; shared worktree, not native Linux or Android device qualification) (pass)
- Evidence: executed: python -m unittest test/tooling/android_maestro_features_wrapper_test.py -v (pass)
- Evidence: executed: python .task-evidence/repo-docs-maintain/check_official_reference.py <repo>; reference removal only, official parity NOT_CHECKED (pass)
- Evidence: executed: python .task-evidence/t_1f328b2e/check_receipt.py (pass)
- Evidence: executed: python <home>/.hermes/shared-skills/repo-docs/scripts/goals.py validate <repo> (pass)
- Evidence: executed: python scripts/check_desktop_next_port_slice.py (pass)
- Evidence: executed: python ~/.hermes/shared-skills/repo-docs/scripts/goals.py validate <repo> (pass)
- Evidence: executed: timeout 180s flutter analyze (pass)
- Evidence: executed: timeout 60s env XDG_CACHE_HOME="$PWD/.task-evidence/t_be855c75/reviewer-maestro-cache" "$HOME/.maestro/bin/maestro" check-syntax scripts/maestro/fixture/approvals_recovery.yaml (pass)
- Evidence: executed: timeout 60s env XDG_CACHE_HOME="$PWD/.task-evidence/t_be855c75/reviewer-maestro-cache" "$HOME/.maestro/bin/maestro" check-syntax scripts/maestro/fixture/attachment_picker_race.yaml (pass)
- Evidence: inspection: docs/analysis/official-desktop-graphify.md#bounded-knowledge-study-and-planning-consequences (pass)
- Evidence: inspection: docs/analysis/terminal-files-feasibility.md (pass)
- Evidence: inspection: docs/plans/README.md (all retained plans target official hermes-agent/apps/desktop; previous parity evidence remains withdrawn) (pass)
- Evidence: inspection: docs/product/hermes-desktop-feature-matrix.md (feature-group mappings, not 1:1 qualification) (pass)
- Evidence: inspection: docs/product/hermes-desktop-feature-matrix.md#current-product-matrix (current subsets and attributed receipts; no fresh runtime qualification) (pass)
- Evidence: inspection: docs/product/hermes-desktop-parity.md#reference-and-evidence-boundary (pass)
- Evidence: inspection: docs/product/hermes-desktop-ui-gap.md#current-shell-redesign-evidence (pass)
