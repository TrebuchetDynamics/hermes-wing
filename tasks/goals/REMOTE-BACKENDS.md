+++
schema = 1
id = "REMOTE-BACKENDS"
title = "Provide typed SSH/Docker/WSL backend lifecycle outcomes"
priority = 107
source = "docs/product/hermes-desktop-parity.md#statuses"
status = "unmet"
focus = false
depends_on = []
+++

- Evidence: executed: .task-evidence/parallel-key-native/venv/bin/python -m unittest test/tooling/managed_ssh_key_native_test.py -v; 7 pass; preparation only, native execution NOT_CHECKED (pass)
- Evidence: executed: flutter analyze --no-pub; no issues, key implementation plus native harness (pass)
- Evidence: executed: npm run test -- --no-pub test/features/hermes_chat/screens/hermes_ssh_no_cli_test.dart test/features/hermes_chat/screens/hermes_chat_remote_connection_retry_test.dart test/features/hermes_chat/screens/hermes_connection_primary_entry_test.dart test/features/hermes_chat/widgets/managed_ssh_connection_panel_test.dart test/features/hermes_chat/widgets/managed_ssh_connection_form_test.dart test/features/hermes_chat/ssh_keys test/features/hermes_chat/providers/managed_ssh_provider_test.dart test/features/hermes_chat/widgets/managed_ssh_host_key_dialog_test.dart test/core/hermes/ssh/managed_ssh_test.dart; parent-tests.log: 72 pass; fixture/widget only, native qualification open (pass)
- Evidence: executed: python .task-evidence/local-key-help-integration/verify.py; frozen-source analyzer clean and focused union 132 pass; native storage/auth NOT_CHECKED (pass)
- Evidence: inspection: docs/product/desktop-connection-paths.md#private-key-ux-desktop-reference-and-wing-adaptations; Desktop 2ed89070bc6c9e8231a37bb55df8a7722a3776b8; path selection, OpenSSH arguments, saved config, Wing ephemeral key callbacks; no runtime qualification (pass)
- Evidence: inspection: docs/product/desktop-connection-paths.md#ssh-is-managed-host-access-in-desktop (pass)
- Evidence: inspection: docs/product/hermes-desktop-parity.md#statuses (pass)
- Evidence: inspection: docs/quality/graphify-wing-recomparison.md [pinned Graphify 0.9.80 snapshot; partial key UI; native qualification open] (pass)
