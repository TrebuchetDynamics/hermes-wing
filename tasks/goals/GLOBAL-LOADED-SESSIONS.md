+++
schema = 1
id = "GLOBAL-LOADED-SESSIONS"
title = "Open/create loaded sessions from feature routes without incidental reads"
priority = 10
source = "docs/runbooks/global-session-access.md#verification"
status = "met"
focus = false
depends_on = []
+++

- Evidence: executed: flutter build web --release -t lib/main_e2e.dart; cwd: .task-evidence/t_d06ef06d/mirror; receipt: .task-evidence/t_d06ef06d/commands.json (build) (pass)
- Evidence: executed: flutter build web --release -t lib/main_e2e.dart; cwd: .task-evidence/t_d06ef06d/review-run/mirror; receipt: .task-evidence/t_d06ef06d/review-run/commands.json (build) (pass)
- Evidence: executed: flutter test --no-pub test/features/hermes_chat/gateways/hermes_directory_lifetime_test.dart test/core/hermes/channel/hermes_session_caller_admission_test.dart --concurrency=1 --reporter=json; cwd: .task-evidence/t_d06ef06d/mirror; receipt: .task-evidence/t_d06ef06d/commands.json (nearest) (pass)
- Evidence: executed: flutter test --no-pub test/features/hermes_chat/gateways/hermes_directory_lifetime_test.dart test/core/hermes/channel/hermes_session_caller_admission_test.dart --concurrency=1 --reporter=json; cwd: .task-evidence/t_d06ef06d/review-run/mirror; receipt: .task-evidence/t_d06ef06d/review-run/commands.json (nearest) (pass)
- Evidence: executed: flutter test --no-pub test/shared/widgets/app_shell_global_session_access_test.dart --concurrency=1 --reporter=json; cwd: .task-evidence/t_d06ef06d/mirror; receipt: .task-evidence/t_d06ef06d/commands.json (widgets) (pass)
- Evidence: executed: flutter test --no-pub test/shared/widgets/app_shell_global_session_access_test.dart --concurrency=1 --reporter=json; cwd: .task-evidence/t_d06ef06d/review-run/mirror; receipt: .task-evidence/t_d06ef06d/review-run/commands.json (widgets) (pass)
- Evidence: executed: npx playwright test --config=playwright.config.mjs playwright/tests/regression/global-session-access.spec.mjs --retries=0 --workers=1 --output=.task-evidence/t_1c1e6f37/browser-verified-final; receipt: .task-evidence/t_1c1e6f37/verified-commands.json and global-browser-verified-final-results.json (pass)
- Evidence: executed: npx playwright test --config=playwright.config.mjs playwright/tests/regression/global-session-access.spec.mjs --retries=0 --workers=1 --output=browser-output; cwd: .task-evidence/t_d06ef06d/mirror; receipt: .task-evidence/t_d06ef06d/commands.json (browser) (pass)
- Evidence: executed: npx playwright test --config=playwright.config.mjs playwright/tests/regression/global-session-access.spec.mjs --retries=0 --workers=1 --output=browser-output; cwd: .task-evidence/t_d06ef06d/review-run/mirror; receipt: .task-evidence/t_d06ef06d/review-run/commands.json (browser) (pass)
- Evidence: inspection: .task-evidence/t_1c1e6f37/final-hashes.json (current app_shell.dart differs; 19 other lib/test/playwright fingerprints match; see docs/runbooks/global-session-access.md#current-snapshot-limit) (fail)
- Evidence: inspection: .task-evidence/t_d06ef06d/source-inputs.json (later messaging, history parsing/models and channel regression edits differ from nine of 521 inputs; review-snapshot acceptance preserved; see docs/runbooks/global-session-access.md#current-snapshot-limit) (fail)
- Evidence: inspection: docs/runbooks/desktop-shell-reference-fidelity.md#evidence-and-exact-checks (four current source hashes match; 57-widget and two-browser passing logs inspected; remaining input attribution unverified) (pass)
- Evidence: inspection: docs/runbooks/desktop-shell-reference-fidelity.md#independent-review-p1-correction (four final source hashes match; focus-fix logs record 57 widget and two Chromium passes; full input attribution and independent verdict remain unverified) (pass)
