# Hermes Wing task handoff — Desktop parity

This is a discoverable index, not a competing tracker or execution authorization.
The [goal ledger](docs/plans/2026-10-03-desktop-port-goal.md) owns continuation
leases; the [roadmap](ROADMAP.md), [PRD](docs/product/prd.md) and
[parity ledger](docs/product/hermes-desktop-parity.md) define intended outcomes
and evidence boundaries. Preserve existing card IDs and their historical status.
[BLOCKERS.md](BLOCKERS.md) records dependencies that require user action.
Engineering problems and verification gaps remain in this index and the tracker.
Read current ownership before any handoff. The latest scoped prepass read the
live Wing cards and scheduler. It indexed the completed Chat repairs below.
Those observations do not authorize a retry or prove future ownership is clear.

## Goal coverage

[`goals.json`](goals.json) owns machine-readable goal status. The Desktop goal
ledger still owns continuation leases. Statuses apply to each stated outcome,
not every platform or the entire dirty tree. Existing tests are not executed
evidence. Attributed passing receipts qualify only their bounded source/target.
Every non-met goal has an open task. Read the tracker before taking ownership.
The [documentation maintenance record](docs/quality/repo-docs-goal-bootstrap.md)
records core-document ownership and this backlog conversion.

<!-- goals:coverage:begin -->

Generated from `goals.json` by `goals.py render`. `met` requires an executed, passing check.

| Goal | Status | Evidence | Task |
| --- | --- | --- | --- |
| M1: Complete the integrated Desktop daily-use workflow | partial | executed `dart format --output=none --set-exit-if-changed lib/features/hermes_chat/messaging/approvals/hermes_approval_queue.dart test/features/hermes_chat/messaging/approvals/hermes_approval_queue_test.dart test/features/hermes_chat/screens/hermes_chat_approval_dismissal_test.dart` → pass; executed `flutter analyze --no-pub` → pass; executed `flutter analyze --no-pub (run593)` → pass; executed `flutter test --no-pub --concurrency=1 --timeout 5s test/core/hermes/channel/hermes_approval_settlement_owner_test.dart --plain-name 'dispose retires delayed approval failure=false'` → fail; executed `flutter test --no-pub --concurrency=1 test/features/hermes_chat/screens/hermes_chat_approval_dismissal_test.dart test/features/hermes_chat/messaging/approvals/hermes_approval_queue_test.dart test/features/hermes_chat/screens/hermes_chat_approval_review_test.dart` → pass; executed `flutter test --no-pub --concurrency=1 test/features/hermes_chat/screens/hermes_chat_approval_dismissal_test.dart test/features/hermes_chat/messaging/approvals/hermes_approval_queue_test.dart test/features/hermes_chat/screens/hermes_chat_approval_review_test.dart (run593: 34 pass; deterministic only, final review pending)` → pass; executed `flutter test --no-pub --concurrency=1 test/features/hermes_chat/screens/hermes_chat_approval_dismissal_test.dart test/features/hermes_chat/messaging/approvals/hermes_approval_queue_test.dart test/features/hermes_chat/screens/hermes_chat_approval_review_test.dart test/core/hermes/channel/hermes_approval_settlement_owner_test.dart (run593: exit124; inherited owner harness missing active session, current 44-test pass NOT established)` → fail; executed `git diff --check a0b60c6422446d111d70f845f8883f8ce3a3399f^ a0b60c6422446d111d70f845f8883f8ce3a3399f` → pass; executed `git diff --check a0b60c6422446d111d70f845f8883f8ce3a3399f^ a0b60c6422446d111d70f845f8883f8ce3a3399f (run593)` → pass; inspection `docs/product/prd.md#leading-acceptance-outcome` → pass | PARITY-LIVE-WORKFLOW, PARITY-NATIVE-RELAUNCH, PARITY-PAIR-READ |
| SECURITY: Preserve exact authority, isolation, privacy and no replay | partial | inspection `docs/product/prd.md#product-rules` → pass | DOC-SECURITY-CURRENT-BOUNDARY, DOC-SECURITY-REPLAY-EVIDENCE |
| CHAT-FIDELITY: Match composer/transcript controls, order and recovery | partial | inspection `docs/product/hermes-desktop-parity.md#reference-and-evidence-boundary` → pass | DOC-CHAT-FIDELITY-REFERENCE, DOC-CHAT-TRANSCRIPT-DISCLOSURE |
| PARITY: Match the remaining Desktop product outcomes explicitly | partial | inspection `docs/product/hermes-desktop-parity.md#reference-and-evidence-boundary` → pass; inspection `docs/product/hermes-desktop-ui-gap.md#current-shell-redesign-evidence` → pass | DOC-PARITY-COVERAGE, DOC-PARITY-PLATFORM-DEVIATIONS |
| PARITY-COMPOSITION: Match profile footer, grouped recents and full session modal | partial | inspection `docs/product/hermes-desktop-parity.md#reference-and-evidence-boundary` → pass | DOC-PARITY-COMPOSITION, DOC-PARITY-RECENTS-REFERENCE |
| PARITY-TABS: Provide owner-safe multi-conversation tabs and close/Stop behavior | unmet | inspection `docs/product/hermes-desktop-parity.md#reference-and-evidence-boundary` → pass | DOC-PARITY-TAB-CONTRACT, DOC-PARITY-TAB-RECONNECT-CONTRACT |
| SESSIONS: Qualify exact session search/resume/fork/rename/delete | unverified | inspection `docs/product/hermes-desktop-parity.md#statuses` → pass | DOC-SESSION-ACTIONS-EVIDENCE, DOC-SESSION-DELETE-EVIDENCE |
| SHELL-PERSISTENCE: Qualify collapse/expand persistence across desktop relaunch | unverified | inspection `docs/product/hermes-desktop-parity.md#reference-and-evidence-boundary` → pass | DOC-SHELL-COMPACT-RETURN-EVIDENCE, DOC-SHELL-PERSISTENCE-EVIDENCE |
| SLASH-CATALOG: Match supported full Desktop slash commands and completion | partial | inspection `docs/product/hermes-desktop-parity.md#statuses` → pass | DOC-SLASH-CATALOG-CONTRACT, DOC-SLASH-DENIAL-EVIDENCE |
| DESKTOP-DELIVERY: Qualify desktop windows, install and signed update/recovery | partial | inspection `docs/product/hermes-desktop-parity.md#statuses` → pass | DOC-DESKTOP-DELIVERY-EVIDENCE, DOC-DESKTOP-UNINSTALL-EVIDENCE |
| M3: Qualify trusted enrollment, profile setup and explicit Chat | partial | inspection `ROADMAP.md#m3--trusted-onboarding-into-a-useful-profile-and-workspace` → pass | DOC-M3-CONTRACT-CHECKPOINT, DOC-M3-ROLLBACK-EVIDENCE |
| M3-PROJECT: Create and assign an Agent-owned Project and enter scoped Chat | unmet | inspection `docs/product/prd.md#core-journeys` → pass | DOC-M3-PROJECT-ASSIGNMENT-CONTRACT, DOC-M3-PROJECT-CONTRACT |
| M3-PROVIDER: Manage existing-profile provider credentials and atomic model assignment | unmet | inspection `docs/adr/api-and-state.md#required-agent-owned-mutation-contract` → pass | DOC-M3-PROVIDER-CONTRACT, DOC-M3-PROVIDER-REMOVAL-CONTRACT |
| ARTIFACTS: Retrieve/preview/save supported artifacts without arbitrary paths | partial | inspection `docs/product/hermes-desktop-parity.md#statuses` → pass | DOC-ARTIFACT-CONTRACT, DOC-ARTIFACT-INERT-PREVIEW-EVIDENCE |
| M4: Qualify supported inventory and administration operation by operation | partial | inspection `ROADMAP.md#m4--discover-and-administer-supported-agent-work` → pass | DOC-M4-INVENTORY-EVIDENCE, DOC-M4-SCHEDULE-INVENTORY-EVIDENCE |
| M4-DISCOVER: Discover and install profile-targeted skills through exact contracts | unmet | inspection `docs/product/hermes-desktop-parity.md#statuses` → pass | DOC-M4-CONTRACT-CHECKPOINT, DOC-M4-DISCOVERY-SELECTION-CONTRACT |
| M4-KANBAN: Inspect and manage Agent-owned Kanban cards and outcomes | unmet | inspection `docs/product/hermes-desktop-parity.md#statuses` → pass | DOC-M4-KANBAN-CONTRACT, DOC-M4-KANBAN-PAGINATION-EVIDENCE |
| M4-MCP: Enable/disable toolsets and administer MCP safely | partial | inspection `docs/product/hermes-desktop-parity.md#statuses` → pass | DOC-M4-MCP-CONFIG-CONTRACT, DOC-M4-MCP-CONTRACT |
| M4-MEMORY: Read and manage Agent-owned memory entries/profile/capacity/providers | unmet | inspection `docs/product/hermes-desktop-parity.md#statuses` → pass | DOC-M4-MEMORY-CAPACITY-CONTRACT, DOC-M4-MEMORY-CONTRACT |
| M4-PLATFORMS: Administer messaging gateways through typed per-platform operations | unmet | inspection `docs/product/hermes-desktop-parity.md#statuses` → pass | DOC-M4-HOST-LIFECYCLE-EVIDENCE, DOC-M4-PLATFORM-CONTRACT |
| M4-SCHEDULES: Create/edit/pause/resume/run/delete scheduled jobs and delivery targets | partial | inspection `docs/product/hermes-desktop-parity.md#statuses` → pass | DOC-M4-SCHEDULE-CONTRACT, DOC-M4-SCHEDULE-DELIVERY-CONTRACT |
| M5: Qualify native output and accessible interaction | partial | inspection `ROADMAP.md#m5--safely-take-away-output-with-native-accessible-interaction` → pass | DOC-M5-ANDROID-FIXTURE, DOC-M5-LARGE-TEXT-EVIDENCE |
| DIAGNOSTICS-RECOVERY: Provide safe backup/import, logs and config diagnosis/recovery | partial | inspection `docs/product/hermes-desktop-parity.md#statuses` → pass | DOC-DIAGNOSTICS-BACKUP-CONTRACT, DOC-DIAGNOSTICS-CONTRACT |
| M6: Qualify exact artifacts, integrated install, upgrade and recovery | unverified | inspection `ROADMAP.md#m6--deliver-an-integrated-qualified-alpha` → pass; inspection `docs/quality/2026-10-06-m6-artifact-evidence.md` → pass; inspection `docs/quality/2026-10-06-m6-candidate-admission.md#required-public-inputs` → pass; inspection `docs/runbooks/offline-release-candidate-comparison.md (four source fingerprints match .task-evidence/t_bef84284/validation.json; 120 retained synthetic passes; same-card review and actual candidate unverified)` → pass; inspection `docs/runbooks/release-alpha.md#local-artifact-verification` → pass | DOC-M6-CHECKER-NODE22, DOC-M6-INTEGRATED-RECEIPT-GAP |
| OFFICE: Match Office interactions with an accessible non-spatial path | partial | inspection `docs/product/hermes-desktop-parity.md#statuses` → pass | DOC-OFFICE-ACCESSIBLE-EQUIVALENT, DOC-OFFICE-REFERENCE |
| PERSONA: Qualify standalone and embedded profile persona fidelity | unverified | inspection `docs/product/hermes-desktop-parity.md#statuses` → pass | DOC-PERSONA-CONFLICT-EVIDENCE, DOC-PERSONA-EVIDENCE |
| ACCOUNT: Qualify account/OAuth/pools/credits/wallet authority before exposure | unmet | inspection `docs/product/hermes-desktop-parity.md#statuses` → pass | DOC-ACCOUNT-CONTRACT, DOC-ACCOUNT-REVOCATION-EVIDENCE |
| API-CONFORMANCE: Verify owned code-first HTTP contract against handlers | unverified | executed `python3 .task-evidence/t_f2b5c61e/check_discovery.py; receipt: .task-evidence/t_f2b5c61e/validation.json and docs/quality/2026-10-06-wing-link-api-conformance.md (GET /meta and GET /healthz only; all 20 source hashes match; full API conformance unverified)` → pass; inspection `docs/api/wing-link.openapi.yaml` → pass | DOC-API-DEVICE-SELF-CONFORMANCE, DOC-API-PROTOCOL-ERROR-EVIDENCE |
| NATIVE-INTEGRATION: Review bounded host-local integration before privileged implementation | unverified | inspection `docs/adr/client.md#decision` → pass | DOC-NATIVE-DESIGN-REVIEW, DOC-NATIVE-FAILURE-BOUNDARY |
| REMOTE-BACKENDS: Provide typed SSH/Docker/WSL backend lifecycle outcomes | unmet | inspection `docs/product/hermes-desktop-parity.md#statuses` → pass | DOC-BACKEND-CONTRACT, DOC-BACKEND-DISCONNECT-CONTRACT |
| VOICE: Qualify actual physical capture, speech and acoustic behavior | unverified | inspection `docs/product/prd.md#core-journeys` → pass | DOC-VOICE-OUTPUT-CANCEL-EVIDENCE, DOC-VOICE-QUALIFICATION |
| GLOBAL-LOADED-SESSIONS: Open/create loaded sessions from feature routes without incidental reads | met | executed `flutter build web --release -t lib/main_e2e.dart; cwd: .task-evidence/t_d06ef06d/mirror; receipt: .task-evidence/t_d06ef06d/commands.json (build)` → pass; executed `flutter build web --release -t lib/main_e2e.dart; cwd: .task-evidence/t_d06ef06d/review-run/mirror; receipt: .task-evidence/t_d06ef06d/review-run/commands.json (build)` → pass; executed `flutter test --no-pub test/features/hermes_chat/gateways/hermes_directory_lifetime_test.dart test/core/hermes/channel/hermes_session_caller_admission_test.dart --concurrency=1 --reporter=json; cwd: .task-evidence/t_d06ef06d/mirror; receipt: .task-evidence/t_d06ef06d/commands.json (nearest)` → pass; executed `flutter test --no-pub test/features/hermes_chat/gateways/hermes_directory_lifetime_test.dart test/core/hermes/channel/hermes_session_caller_admission_test.dart --concurrency=1 --reporter=json; cwd: .task-evidence/t_d06ef06d/review-run/mirror; receipt: .task-evidence/t_d06ef06d/review-run/commands.json (nearest)` → pass; executed `flutter test --no-pub test/shared/widgets/app_shell_global_session_access_test.dart --concurrency=1 --reporter=json; cwd: .task-evidence/t_d06ef06d/mirror; receipt: .task-evidence/t_d06ef06d/commands.json (widgets)` → pass; executed `flutter test --no-pub test/shared/widgets/app_shell_global_session_access_test.dart --concurrency=1 --reporter=json; cwd: .task-evidence/t_d06ef06d/review-run/mirror; receipt: .task-evidence/t_d06ef06d/review-run/commands.json (widgets)` → pass; executed `npx playwright test --config=playwright.config.mjs playwright/tests/regression/global-session-access.spec.mjs --retries=0 --workers=1 --output=.task-evidence/t_1c1e6f37/browser-verified-final; receipt: .task-evidence/t_1c1e6f37/verified-commands.json and global-browser-verified-final-results.json` → pass; executed `npx playwright test --config=playwright.config.mjs playwright/tests/regression/global-session-access.spec.mjs --retries=0 --workers=1 --output=browser-output; cwd: .task-evidence/t_d06ef06d/mirror; receipt: .task-evidence/t_d06ef06d/commands.json (browser)` → pass; executed `npx playwright test --config=playwright.config.mjs playwright/tests/regression/global-session-access.spec.mjs --retries=0 --workers=1 --output=browser-output; cwd: .task-evidence/t_d06ef06d/review-run/mirror; receipt: .task-evidence/t_d06ef06d/review-run/commands.json (browser)` → pass; inspection `.task-evidence/t_1c1e6f37/final-hashes.json (current app_shell.dart differs; 19 other lib/test/playwright fingerprints match; see docs/runbooks/global-session-access.md#current-snapshot-limit)` → fail; inspection `.task-evidence/t_d06ef06d/source-inputs.json (later messaging, history parsing/models and channel regression edits differ from nine of 521 inputs; review-snapshot acceptance preserved; see docs/runbooks/global-session-access.md#current-snapshot-limit)` → fail; inspection `docs/runbooks/desktop-shell-reference-fidelity.md#evidence-and-exact-checks (four current source hashes match; 57-widget and two-browser passing logs inspected; remaining input attribution unverified)` → pass; inspection `docs/runbooks/desktop-shell-reference-fidelity.md#independent-review-p1-correction (four final source hashes match; focus-fix logs record 57 widget and two Chromium passes; full input attribution and independent verdict remain unverified)` → pass | — |
| M2: Recover Android owner/history after background and process death | unverified | executed `.task-evidence/t_2d1d55ab/commands.json (channel; exact argv, exit 0 and 23 passes)` → pass; executed `.task-evidence/t_2d1d55ab/owner-command.json (owner; exact argv, exit 0 and 5 passes)` → pass; executed `dart format --output=none --set-exit-if-changed integration_test/hermes_m2_observer_main.dart integration_test/support/m2_observer.dart integration_test/support/m2_metadata.dart test/tooling/m2_bootstrap_test.dart test/tooling/m2_observer_test.dart test/tooling/m2_receipt_admission_test.dart test/tooling/support/m2_fake_harness.dart test/tooling/support/m2_diagnostic_writer.dart test/tooling/support/m2_observer_cases.dart test/tooling/support/m2_receipt_admission_cases.dart test/tooling/support/m2_bootstrap_probe.dart.template` → pass; executed `dart format --output=none --set-exit-if-changed integration_test/hermes_m2_observer_main.dart integration_test/support/m2_observer.dart test/tooling/m2_observer_test.dart; receipt: .task-evidence/t_53f0d91e/validation.json (bounded deterministic tooling only; M2 unverified)` → pass; executed `dart format --output=none --set-exit-if-changed test/features/hermes_chat/screens/hermes_chat_death_completion_recovery_test.dart; receipt: .task-evidence/t_e0af7ad4/format.json` → pass; executed `dart format --output=none --set-exit-if-changed test/shared/widgets/app_shell_global_session_access_test.dart test/features/hermes_chat/gateways/hermes_directory_lifetime_test.dart test/core/hermes/channel/hermes_session_caller_admission_test.dart test/core/hermes/channel/hermes_recovery_read_admission_test.dart; cwd: .task-evidence/t_103d63ec/mirror; receipt: .task-evidence/t_103d63ec/commands.json (format; compiled deterministic only, M2 remains unverified)` → pass; executed `dart format --output=none --set-exit-if-changed test/tooling/m2_receipt_admission_test.dart` → pass; executed `dart format test/tooling/m2_receipt_admission_test.dart` → pass; executed `flutter analyze` → pass; executed `flutter analyze --no-pub` → pass; executed `flutter analyze --no-pub integration_test/hermes_m2_observer_main.dart integration_test/support/m2_observer.dart test/tooling/m2_observer_test.dart; receipt: .task-evidence/t_53f0d91e/validation.json (bounded deterministic tooling only; M2 unverified)` → pass; executed `flutter analyze --no-pub test/tooling/m2_receipt_admission_test.dart` → pass; executed `flutter analyze --no-pub; cwd: .task-evidence/t_103d63ec/mirror; receipt: .task-evidence/t_103d63ec/commands.json (analyze; compiled deterministic only, M2 remains unverified)` → pass; executed `flutter analyze; receipt: .task-evidence/t_e0af7ad4/analyze-verified.json` → pass; executed `flutter build web --release -t lib/main_e2e.dart; cwd: .task-evidence/t_103d63ec/mirror; receipt: .task-evidence/t_103d63ec/commands.json (build; compiled deterministic only, M2 remains unverified)` → pass; executed `flutter test --concurrency=1 test/tooling/m2_bootstrap_test.dart test/tooling/m2_observer_test.dart test/tooling/m2_receipt_admission_test.dart` → pass; executed `flutter test --no-pub --concurrency=1 --reporter=expanded test/core/hermes/channel/hermes_api_channel_test.dart test/core/hermes/hermes_api_test.dart; cwd: .task-evidence/t_4e4a4f7d/isolated-project; receipt: .task-evidence/t_4e4a4f7d/validation.json (nearest)` → pass; executed `flutter test --no-pub --concurrency=1 --reporter=expanded test/core/hermes/channel/hermes_recovery_read_admission_test.dart test/core/hermes/client/hermes_history_identity_test.dart test/core/hermes/channel/hermes_session_caller_admission_test.dart; cwd: .task-evidence/t_4e4a4f7d/isolated-project; receipt: .task-evidence/t_4e4a4f7d/validation.json (focused)` → pass; executed `flutter test --no-pub --concurrency=1 --reporter=expanded test/core/hermes/channel/hermes_recovery_read_admission_test.dart; cwd: .task-evidence/t_3a5135a8/isolated-project; receipt: .task-evidence/t_3a5135a8/commands.json (green.log; 18 passes; three changed source/test hashes and all retained command-log hashes match; independent same-card approval, Android and live counts unverified)` → pass; executed `flutter test --no-pub --concurrency=1 --reporter=expanded test/core/hermes/channel/hermes_recovery_read_admission_test.dart; cwd: .task-evidence/t_3a5135a8/review-398-project; receipt: .task-evidence/t_3a5135a8/review-398-validation.json (18 passes; five authored fingerprints and seven command logs match; final native approval, Android and live counts unverified)` → pass; executed `flutter test --no-pub --concurrency=1 --reporter=expanded test/core/hermes/channel/hermes_session_caller_admission_test.dart test/features/hermes_chat/screens/hermes_chat_death_completion_recovery_test.dart test/features/hermes_chat/gateways/hermes_gateway_session_restoration_test.dart test/features/hermes_chat/gateways/hermes_gateway_restoration_adversarial_test.dart test/features/hermes_chat/gateways/hermes_directory_lifetime_test.dart test/features/hermes_chat/screens/hermes_chat_session_picker_load_owner_test.dart (cwd: review-404-project; receipt: .task-evidence/t_cd72a5d5/review-404-validation.json; log: review-404-callers.log)` → pass; executed `flutter test --no-pub --concurrency=1 --reporter=expanded test/core/hermes/client/hermes_history_identity_test.dart test/core/hermes/channel/hermes_recovery_read_admission_test.dart (cwd: review-404-project; receipt: .task-evidence/t_cd72a5d5/review-404-validation.json; log: review-404-focused.log)` → pass; executed `flutter test --no-pub --concurrency=1 --reporter=expanded test/core/hermes/hermes_api_test.dart test/core/hermes/channel/hermes_api_channel_test.dart (cwd: review-404-project; receipt: .task-evidence/t_cd72a5d5/review-404-validation.json; log: review-404-nearest.log)` → pass; executed `flutter test --no-pub --concurrency=1 --reporter=expanded test/features/hermes_chat/gateways/hermes_gateway_session_restoration_test.dart test/features/hermes_chat/gateways/hermes_gateway_restoration_adversarial_test.dart test/features/hermes_chat/gateways/hermes_directory_lifetime_test.dart test/features/hermes_chat/screens/hermes_chat_death_completion_recovery_test.dart; cwd: .task-evidence/t_4e4a4f7d/isolated-project; receipt: .task-evidence/t_4e4a4f7d/validation.json (callers)` → pass; executed `flutter test --no-pub --concurrency=1 --reporter=json test/shared/widgets/app_shell_global_session_access_test.dart test/features/hermes_chat/gateways/hermes_directory_lifetime_test.dart test/core/hermes/channel/hermes_session_caller_admission_test.dart test/core/hermes/channel/hermes_recovery_read_admission_test.dart; cwd: .task-evidence/t_103d63ec/mirror; receipt: .task-evidence/t_103d63ec/commands.json (focused; compiled deterministic only, M2 remains unverified)` → pass; executed `flutter test --no-pub test/core/hermes/setup/secure_hermes_detached_run_store_test.dart test/core/hermes/channel/hermes_detached_run_store_test.dart --concurrency=1 --reporter expanded` → pass; executed `flutter test --no-pub test/features/hermes_chat/screens/hermes_chat_death_completion_recovery_test.dart --concurrency=1 --reporter expanded; receipt: .task-evidence/t_e0af7ad4/oracle-verified.json` → pass; executed `flutter test --no-pub test/features/hermes_chat/screens/hermes_chat_session_restoration_test.dart test/features/hermes_chat/gateways/hermes_gateway_session_restoration_test.dart test/features/hermes_chat/gateways/hermes_gateway_restoration_adversarial_test.dart --concurrency=1 --reporter expanded; receipt: .task-evidence/t_e0af7ad4/nearest-regressions.json` → pass; executed `flutter test --no-pub test/tooling/m2_observer_test.dart; receipt: .task-evidence/t_53f0d91e/validation.json (bounded deterministic tooling only; M2 unverified)` → pass; executed `flutter test --no-pub test/tooling/m2_receipt_admission_test.dart` → pass; executed `flutter test test/tooling/m2_bootstrap_test.dart` → fail; executed `git diff --check` → pass; executed `git diff --check -- docs/quality/2026-10-06-m2-coordinator-admission-trace.md .task-evidence/t_06c58314` → pass; executed `git diff --check -- docs/quality/2026-10-06-m2-custody-proof-review.md .task-evidence/t_321431fe (native review505; source-only integrity, not product acceptance)` → pass; executed `git diff --check -- docs/quality/2026-10-06-m2-custody-proof-review.md .task-evidence/t_321431fe (source-only integrity; .task-evidence/t_321431fe/validation.json; not M2 acceptance)` → pass; executed `git diff --check -- docs/quality/2026-10-06-m2-issuer-evidence-contract.md .task-evidence/t_620a6d33` → pass; executed `git diff --check -- docs/quality/2026-10-06-m2-receipt-handoff-contract.md .task-evidence/t_d6c8aa4f (offline proposed-contract checks only; M2 unverified)` → pass; executed `git diff --check -- docs/quality/2026-10-06-m2-refusal-continuation-preflight.md .task-evidence/t_c799c475` → pass; executed `git diff --check -- docs/quality/2026-10-06-m2-refusal-continuation-preflight.md .task-evidence/t_c799c475 TODO.md goals.json` → pass; executed `git diff --check -- docs/quality/2026-10-06-m2-runtime-caller-closure.md .task-evidence/t_481b1474` → pass; executed `git diff --check -- docs/spec.md docs/test-plan.md docs/README.md docs/quality/repo-docs-goal-bootstrap.md TODO.md goals.json` → pass; executed `git diff --check -- integration_test/hermes_m2_observer_main.dart integration_test/support/m2_observer.dart integration_test/support/m2_metadata.dart test/tooling/m2_bootstrap_test.dart test/tooling/m2_observer_test.dart test/tooling/m2_receipt_admission_test.dart test/tooling/support/m2_fake_harness.dart test/tooling/support/m2_diagnostic_writer.dart test/tooling/support/m2_observer_cases.dart test/tooling/support/m2_receipt_admission_cases.dart test/tooling/support/m2_bootstrap_probe.dart.template scripts/check_m2_default_refusal.py docs/quality/2026-10-06-m2-default-refusal.md` → pass; executed `git diff --check -- integration_test/hermes_m2_observer_main.dart integration_test/support/m2_observer.dart test/tooling/m2_observer_test.dart .task-evidence/t_53f0d91e; receipt: .task-evidence/t_53f0d91e/validation.json (bounded deterministic tooling only; M2 unverified)` → pass; executed `git diff --check -- test/tooling/m2_receipt_admission_test.dart .task-evidence/t_40dcd771` → pass; executed `git diff --no-index --check /dev/null .task-evidence/t_02e4e461/check_integrity.py` → pass; executed `git diff --no-index --check /dev/null .task-evidence/t_02e4e461/citations-initial.json` → pass; executed `git diff --no-index --check /dev/null .task-evidence/t_02e4e461/citations.json` → pass; executed `git diff --no-index --check /dev/null .task-evidence/t_02e4e461/fetch-command-failed-1.json` → pass; executed `git diff --no-index --check /dev/null .task-evidence/t_02e4e461/fetch-command-initial.json` → pass; executed `git diff --no-index --check /dev/null .task-evidence/t_02e4e461/fetch-command.json` → pass; executed `git diff --no-index --check /dev/null .task-evidence/t_02e4e461/fetch_sources.py` → pass; executed `git diff --no-index --check /dev/null .task-evidence/t_02e4e461/update_ledger.py` → pass; executed `git diff --no-index --check /dev/null .task-evidence/t_620a6d33/check_contract.py` → pass; executed `git diff --no-index --check /dev/null .task-evidence/t_620a6d33/checkout-before.json` → pass; executed `git diff --no-index --check /dev/null .task-evidence/t_620a6d33/ledger-before.json` → pass; executed `git diff --no-index --check /dev/null .task-evidence/t_620a6d33/ledger-command.json` → pass; executed `git diff --no-index --check /dev/null .task-evidence/t_620a6d33/ledger.json` → pass; executed `git diff --no-index --check /dev/null .task-evidence/t_620a6d33/selection-comparison.json` → pass; executed `git diff --no-index --check /dev/null .task-evidence/t_620a6d33/snapshot-command.json` → pass; executed `git diff --no-index --check /dev/null .task-evidence/t_620a6d33/source-snapshot.json` → pass; executed `git diff --no-index --check /dev/null .task-evidence/t_620a6d33/todo-render-delta.patch` → pass; executed `git diff --no-index --check /dev/null .task-evidence/t_620a6d33/todo-task-delta.patch` → pass; executed `git diff --no-index --check /dev/null .task-evidence/t_620a6d33/update_ledger.py` → pass; executed `git diff --no-index --check /dev/null .task-evidence/t_620a6d33/validation.json` → pass; executed `git diff --no-index --check /dev/null .task-evidence/t_620a6d33/verify-before-ledger.json` → pass; executed `git diff --no-index --check /dev/null .task-evidence/t_620a6d33/verify-command.json` → pass; executed `git diff --no-index --check /dev/null .task-evidence/t_8ce3dc30/check_integrity.py` → pass; executed `git diff --no-index --check /dev/null .task-evidence/t_8ce3dc30/ledger.json` → pass; executed `git diff --no-index --check /dev/null .task-evidence/t_8ce3dc30/snapshot-command.json` → pass; executed `git diff --no-index --check /dev/null .task-evidence/t_8ce3dc30/source-snapshot-initial.json` → pass; executed `git diff --no-index --check /dev/null .task-evidence/t_8ce3dc30/source-snapshot.json` → pass; executed `git diff --no-index --check /dev/null .task-evidence/t_8ce3dc30/update_ledger.py` → pass; executed `git diff --no-index --check /dev/null .task-evidence/t_8ce3dc30/validation.json` → pass; executed `git diff --no-index --check /dev/null .task-evidence/t_8ce3dc30/verify-command.json` → pass; executed `git diff --no-index --check /dev/null .task-evidence/t_c799c475/check_preflight.py` → pass; executed `git diff --no-index --check /dev/null .task-evidence/t_c799c475/git-before.json` → pass; executed `git diff --no-index --check /dev/null .task-evidence/t_c799c475/ledger-before.json` → pass; executed `git diff --no-index --check /dev/null .task-evidence/t_c799c475/selection-comparison.json` → pass; executed `git diff --no-index --check /dev/null .task-evidence/t_c799c475/snapshot-command.json` → pass; executed `git diff --no-index --check /dev/null .task-evidence/t_c799c475/source-snapshot.json` → pass; executed `git diff --no-index --check /dev/null .task-evidence/t_c799c475/validation.json` → pass; executed `git diff --no-index --check /dev/null .task-evidence/t_d2b9b4db/check_integrity.py` → pass; executed `git diff --no-index --check /dev/null .task-evidence/t_d2b9b4db/citations.json` → pass; executed `git diff --no-index --check /dev/null .task-evidence/t_d2b9b4db/fetch-command.json` → pass; executed `git diff --no-index --check /dev/null .task-evidence/t_d2b9b4db/fetch_citations.py` → pass; executed `git diff --no-index --check /dev/null .task-evidence/t_d2b9b4db/ledger.json` → pass; executed `git diff --no-index --check /dev/null .task-evidence/t_d2b9b4db/snapshot-command.json` → pass; executed `git diff --no-index --check /dev/null .task-evidence/t_d2b9b4db/source-snapshot.json` → pass; executed `git diff --no-index --check /dev/null .task-evidence/t_d2b9b4db/update_ledger.py` → pass; executed `git diff --no-index --check /dev/null .task-evidence/t_d2b9b4db/validation.json` → pass; executed `git diff --no-index --check /dev/null .task-evidence/t_d2b9b4db/verify-command.json` → pass; executed `git diff --no-index --check /dev/null docs/quality/2026-10-06-m2-cpu-enforcement-feasibility.md` → pass; executed `git diff --no-index --check /dev/null docs/quality/2026-10-06-m2-cpu-envelope-proof.md` → pass; executed `git diff --no-index --check /dev/null docs/quality/2026-10-06-m2-issuer-evidence-contract.md` → pass; executed `git diff --no-index --check /dev/null docs/quality/2026-10-06-m2-refusal-continuation-preflight.md` → pass; executed `git diff --no-index --check /dev/null docs/quality/2026-10-06-m2-synthetic-isolation-contract.md` → pass; executed `git show --check --format=oneline 685b39e4cc161b1827ba7f52bc4d99d12ec82d9a` → pass; executed `git show --check --format=oneline ff45432a3ef1436cb87b799a2c69a696bc6a65e1` → pass; executed `git show --format= --check 3cd0896a1af03e0f33bb39ed4cf626de93610274 (native review505; source-only integrity, not product acceptance)` → pass; executed `git show --format= --check ca76e700f60a184336f765e2b40350f4e25671d5` → pass; executed `npm run test -- --no-pub --reporter=expanded test/core/hermes/client/hermes_history_identity_test.dart test/core/hermes/channel/hermes_recovery_read_admission_test.dart test/core/hermes/hermes_api_test.dart test/core/hermes/channel/hermes_api_channel_test.dart test/core/hermes/channel/hermes_session_caller_admission_test.dart test/features/hermes_chat/screens/hermes_chat_death_completion_recovery_test.dart test/features/hermes_chat/gateways/hermes_gateway_session_restoration_test.dart test/features/hermes_chat/gateways/hermes_gateway_restoration_adversarial_test.dart test/features/hermes_chat/gateways/hermes_directory_lifetime_test.dart test/features/hermes_chat/screens/hermes_chat_session_picker_load_owner_test.dart (cwd: review-404-project; receipt: .task-evidence/t_cd72a5d5/review-404-validation.json; log: review-404-npm.log)` → pass; executed `npx --no-install playwright test --config=playwright.config.mjs playwright/tests/regression/global-session-access.spec.mjs --workers=1 --retries=0 --output=browser-output; cwd: .task-evidence/t_103d63ec/mirror; receipt: .task-evidence/t_103d63ec/commands.json (browser; compiled deterministic only, M2 remains unverified)` → pass; executed `python -c 'import runpy; r=runpy.run_path(".task-evidence/t_ccec142b/check_admission.py", run_name="repo_docs_readonly")["verify"](); print({k:r[k] for k in ("result", "source_files", "citations", "links", "m2")})'` → pass; executed `python .task-evidence/t_53f0d91e/closure.py; receipt: .task-evidence/t_53f0d91e/validation.json (bounded deterministic tooling only; M2 unverified)` → pass; executed `python .task-evidence/t_bd91fa65/check.py; receipt: .task-evidence/t_bd91fa65/validation.json (exit 0; offline-document-integrity-only; M2 unverified)` → pass; executed `python /home/xel/.hermes/shared-skills/repo-docs/scripts/goals.py validate /home/xel/git/gormes/hermes-wing` → fail; executed `python scripts/check_m2_default_refusal.py` → pass; executed `python3 -c "import ast; from pathlib import Path; [ast.parse(Path('.task-evidence/t_909a35ba', name).read_text()) for name in ('check_preflight.py', 'update_ledger.py')]; print('Python syntax PASS')"` → pass; executed `python3 -c 'import runpy; n=runpy.run_path('"'"'.task-evidence/t_8ce3dc30/check_integrity.py'"'"',run_name='"'"'review'"'"'); n['"'"'verify'"'"'].__globals__['"'"'save'"'"']=lambda *a: None; n['"'"'verify'"'"']()'` → pass; executed `python3 .task-evidence/t_02e4e461/check_integrity.py snapshot` → pass; executed `python3 .task-evidence/t_02e4e461/check_integrity.py verify` → pass; executed `python3 .task-evidence/t_02e4e461/fetch_sources.py` → pass; executed `python3 .task-evidence/t_06c58314/check_trace.py snapshot` → pass; executed `python3 .task-evidence/t_06c58314/check_trace.py verify` → pass; executed `python3 .task-evidence/t_321431fe/check_review.py snapshot (source-only integrity; .task-evidence/t_321431fe/validation.json; not M2 acceptance)` → pass; executed `python3 .task-evidence/t_321431fe/check_review.py verify (source-only integrity; .task-evidence/t_321431fe/validation.json; not M2 acceptance)` → pass; executed `python3 .task-evidence/t_40dcd771/check.py verify` → pass; executed `python3 .task-evidence/t_40dcd771/preserve_ceiling.py` → pass; executed `python3 .task-evidence/t_481b1474/check_integrity.py snapshot` → pass; executed `python3 .task-evidence/t_481b1474/check_integrity.py verify` → pass; executed `python3 .task-evidence/t_481b1474/run_checks.py` → pass; executed `python3 .task-evidence/t_620a6d33/check_contract.py snapshot` → pass; executed `python3 .task-evidence/t_620a6d33/check_contract.py verify` → pass; executed `python3 .task-evidence/t_7e4e424a/check_provenance.py snapshot` → pass; executed `python3 .task-evidence/t_7e4e424a/check_provenance.py verify` → pass; executed `python3 .task-evidence/t_8ce3dc30/check_integrity.py snapshot` → pass; executed `python3 .task-evidence/t_8ce3dc30/check_integrity.py verify` → pass; executed `python3 .task-evidence/t_8ce3dc30/check_integrity.py verify (initial attempt; verify-command.json runs[0])` → fail; executed `python3 .task-evidence/t_909a35ba/check_preflight.py closure` → pass; executed `python3 .task-evidence/t_909a35ba/check_preflight.py probe` → pass; executed `python3 .task-evidence/t_909a35ba/check_preflight.py snapshot` → pass; executed `python3 .task-evidence/t_909a35ba/check_preflight.py verify` → pass; executed `python3 .task-evidence/t_bcab1f7e/check_contract.py negative` → pass; executed `python3 .task-evidence/t_bcab1f7e/check_contract.py snapshot` → pass; executed `python3 .task-evidence/t_bcab1f7e/check_contract.py verify` → pass; executed `python3 .task-evidence/t_c799c475/check_preflight.py snapshot` → pass; executed `python3 .task-evidence/t_c799c475/check_preflight.py verify` → pass; executed `python3 .task-evidence/t_d2b9b4db/check_integrity.py snapshot` → pass; executed `python3 .task-evidence/t_d2b9b4db/check_integrity.py verify` → pass; executed `python3 .task-evidence/t_d2b9b4db/fetch_citations.py` → pass; executed `python3 .task-evidence/t_d6c8aa4f/check_contract.py snapshot (offline proposed-contract checks only; M2 unverified)` → pass; executed `python3 .task-evidence/t_d6c8aa4f/check_contract.py verify (offline proposed-contract checks only; M2 unverified)` → pass; executed `t_15da6893 analyze: cwd=/home/xel/git/gormes/hermes-wing/.task-evidence/t_15da6893/mirror; flutter analyze --no-pub; receipt=.task-evidence/t_15da6893/analyze.json/log` → pass; executed `t_15da6893 format-apply: cwd=/home/xel/git/gormes/hermes-wing; dart format test/features/hermes_chat/screens/hermes_chat_death_completion_recovery_test.dart; receipt=.task-evidence/t_15da6893/format-apply.json/log` → pass; executed `t_15da6893 format-verified: cwd=/home/xel/git/gormes/hermes-wing; dart format --output=none --set-exit-if-changed test/features/hermes_chat/screens/hermes_chat_death_completion_recovery_test.dart; receipt=.task-evidence/t_15da6893/format-verified.json/log` → pass; executed `t_15da6893 native review 444: cwd=/home/xel/git/gormes/hermes-wing/.task-evidence/t_15da6893/mirror; flutter analyze --no-pub; receipt=.task-evidence/t_15da6893/review-444-analyze.json/log; synthetic Linux widget evidence only; M2 unverified, authoritative_counts_unavailable` → pass; executed `t_15da6893 native review 444: cwd=/home/xel/git/gormes/hermes-wing/.task-evidence/t_15da6893/mirror; flutter test --no-pub test/features/hermes_chat/screens/hermes_chat_death_completion_recovery_test.dart test/features/hermes_chat/screens/hermes_chat_screen_auth_recovery_test.dart test/features/hermes_chat/screens/hermes_chat_session_restoration_test.dart test/features/hermes_chat/gateways/hermes_gateway_restoration_adversarial_test.dart --concurrency=1 --reporter expanded; receipt=.task-evidence/t_15da6893/review-444-tests.json/log; synthetic Linux widget evidence only; M2 unverified, authoritative_counts_unavailable` → pass; executed `t_15da6893 native review 444: cwd=/home/xel/git/gormes/hermes-wing; dart format --output=none --set-exit-if-changed test/features/hermes_chat/screens/hermes_chat_death_completion_recovery_test.dart; receipt=.task-evidence/t_15da6893/review-444-format.json/log; synthetic Linux widget evidence only; M2 unverified, authoritative_counts_unavailable` → pass; executed `t_15da6893 native review 444: cwd=/home/xel/git/gormes/hermes-wing; python -c 'from pathlib import Path; p=Path('"'"'.task-evidence/t_15da6893/verify_scope.py'"'"'); exec(compile(p.read_text().replace('"'"'import-closure.json'"'"','"'"'review-444-import-closure.json'"'"'), str(p), '"'"'exec'"'"'))'; receipt=.task-evidence/t_15da6893/review-444-scope.json/log; synthetic Linux widget evidence only; M2 unverified, authoritative_counts_unavailable` → pass; executed `t_15da6893 native review 444: cwd=/home/xel/git/gormes/hermes-wing; python .task-evidence/t_15da6893/review_444_verify.py; receipt=.task-evidence/t_15da6893/review-444-integrity-check.json/log; synthetic Linux widget evidence only; M2 unverified, authoritative_counts_unavailable` → pass; executed `t_15da6893 nearest: cwd=/home/xel/git/gormes/hermes-wing/.task-evidence/t_15da6893/mirror; flutter test --no-pub test/features/hermes_chat/screens/hermes_chat_screen_auth_recovery_test.dart test/features/hermes_chat/screens/hermes_chat_session_restoration_test.dart test/features/hermes_chat/gateways/hermes_gateway_restoration_adversarial_test.dart --concurrency=1 --reporter expanded; receipt=.task-evidence/t_15da6893/nearest.json/log` → pass; executed `t_15da6893 oracle-fixed: cwd=/home/xel/git/gormes/hermes-wing/.task-evidence/t_15da6893/mirror; flutter test --no-pub test/features/hermes_chat/screens/hermes_chat_death_completion_recovery_test.dart --concurrency=1 --reporter expanded; receipt=.task-evidence/t_15da6893/oracle-fixed.json/log` → pass; executed `t_15da6893 oracle: cwd=/home/xel/git/gormes/hermes-wing/.task-evidence/t_15da6893/mirror; flutter test --no-pub test/features/hermes_chat/screens/hermes_chat_death_completion_recovery_test.dart --concurrency=1 --reporter expanded; receipt=.task-evidence/t_15da6893/oracle.json/log` → fail; executed `t_15da6893 scope: cwd=/home/xel/git/gormes/hermes-wing; python .task-evidence/t_15da6893/verify_scope.py; receipt=.task-evidence/t_15da6893/scope.json/log` → pass; executed `t_59ea67ba analyze: cwd=/home/xel/git/gormes/hermes-wing/.task-evidence/t_59ea67ba/mirror; flutter analyze --no-pub` → pass; executed `t_59ea67ba channel-hydration: cwd=/home/xel/git/gormes/hermes-wing/.task-evidence/t_59ea67ba/mirror; flutter test --no-pub test/core/hermes/channel/hermes_api_channel_test.dart --plain-name 'terminal hydration failure preserves durable retry across recreation' --concurrency=1 --reporter expanded` → pass; executed `t_59ea67ba channel-lease: cwd=/home/xel/git/gormes/hermes-wing/.task-evidence/t_59ea67ba/mirror; flutter test --no-pub test/core/hermes/channel/hermes_api_channel_test.dart --plain-name 'active run lease is durable before its event stream finishes' --concurrency=1 --reporter expanded` → pass; executed `t_59ea67ba channel-process: cwd=/home/xel/git/gormes/hermes-wing/.task-evidence/t_59ea67ba/mirror; flutter test --no-pub test/core/hermes/channel/hermes_api_channel_test.dart --plain-name 'process recreation' --concurrency=1 --reporter expanded` → pass; executed `t_59ea67ba format-verified: cwd=/home/xel/git/gormes/hermes-wing; dart format --output=none --set-exit-if-changed test/features/hermes_chat/screens/hermes_chat_death_completion_recovery_test.dart` → pass; executed `t_59ea67ba nearest: cwd=/home/xel/git/gormes/hermes-wing/.task-evidence/t_59ea67ba/mirror; flutter test --no-pub test/features/hermes_chat/screens/hermes_chat_screen_auth_recovery_test.dart test/features/hermes_chat/screens/hermes_chat_session_restoration_test.dart test/features/hermes_chat/gateways/hermes_gateway_restoration_adversarial_test.dart --concurrency=1 --reporter expanded` → pass; executed `t_59ea67ba oracle-final: cwd=/home/xel/git/gormes/hermes-wing/.task-evidence/t_59ea67ba/mirror; flutter test --no-pub test/features/hermes_chat/screens/hermes_chat_death_completion_recovery_test.dart --concurrency=1 --reporter expanded` → pass; executed `t_59ea67ba scope: cwd=/home/xel/git/gormes/hermes-wing; python3 .task-evidence/t_59ea67ba/verify_scope.py` → pass; executed `t_b00feca2 analyze: cwd=/home/xel/git/gormes/hermes-wing/.task-evidence/t_b00feca2/mirror; flutter analyze --no-pub; receipt=.task-evidence/t_b00feca2/analyze.json/log` → pass; executed `t_b00feca2 format-apply: cwd=/home/xel/git/gormes/hermes-wing; dart format test/features/hermes_chat/screens/hermes_chat_death_completion_recovery_test.dart; receipt=.task-evidence/t_b00feca2/format-apply.json/log` → pass; executed `t_b00feca2 format-verified: cwd=/home/xel/git/gormes/hermes-wing; dart format --output=none --set-exit-if-changed test/features/hermes_chat/screens/hermes_chat_death_completion_recovery_test.dart; receipt=.task-evidence/t_b00feca2/format-verified.json/log` → pass; executed `t_b00feca2 native review 440: cwd=/home/xel/git/gormes/hermes-wing/.task-evidence/t_b00feca2/mirror; argv=["flutter", "analyze", "--no-pub"]; receipt=.task-evidence/t_b00feca2/review-440-analyze.json/log; deterministic only, Android/live qualification NOT_CHECKED` → pass; executed `t_b00feca2 native review 440: cwd=/home/xel/git/gormes/hermes-wing/.task-evidence/t_b00feca2/mirror; argv=["flutter", "test", "--no-pub", "test/features/hermes_chat/screens/hermes_chat_death_completion_recovery_test.dart", "test/features/hermes_chat/screens/hermes_chat_screen_auth_recovery_test.dart", "test/features/hermes_chat/screens/hermes_chat_session_restoration_test.dart", "test/features/hermes_chat/gateways/hermes_gateway_restoration_adversarial_test.dart", "--concurrency=1", "--reporter", "expanded"]; receipt=.task-evidence/t_b00feca2/review-440-tests.json/log; deterministic only, Android/live qualification NOT_CHECKED` → pass; executed `t_b00feca2 native review 440: cwd=/home/xel/git/gormes/hermes-wing; argv=["dart", "format", "--output=none", "--set-exit-if-changed", "test/features/hermes_chat/screens/hermes_chat_death_completion_recovery_test.dart"]; receipt=.task-evidence/t_b00feca2/review-440-format.json/log; deterministic only, Android/live qualification NOT_CHECKED` → pass; executed `t_b00feca2 native review 440: cwd=/home/xel/git/gormes/hermes-wing; argv=["python", "-c", "from pathlib import Path; p=Path('.task-evidence/t_b00feca2/verify_scope.py'); exec(compile(p.read_text().replace('import-closure.json','review-440-import-closure.json'), str(p), 'exec'))"]; receipt=.task-evidence/t_b00feca2/review-440-scope.json/log; deterministic only, Android/live qualification NOT_CHECKED` → pass; executed `t_b00feca2 nearest: cwd=/home/xel/git/gormes/hermes-wing/.task-evidence/t_b00feca2/mirror; flutter test --no-pub test/features/hermes_chat/screens/hermes_chat_screen_auth_recovery_test.dart test/features/hermes_chat/screens/hermes_chat_session_restoration_test.dart test/features/hermes_chat/gateways/hermes_gateway_restoration_adversarial_test.dart --concurrency=1 --reporter expanded; receipt=.task-evidence/t_b00feca2/nearest.json/log` → pass; executed `t_b00feca2 oracle: cwd=/home/xel/git/gormes/hermes-wing/.task-evidence/t_b00feca2/mirror; flutter test --no-pub test/features/hermes_chat/screens/hermes_chat_death_completion_recovery_test.dart --concurrency=1 --reporter expanded; receipt=.task-evidence/t_b00feca2/oracle.json/log` → pass; executed `t_b00feca2 scope: cwd=/home/xel/git/gormes/hermes-wing; python .task-evidence/t_b00feca2/verify_scope.py; receipt=.task-evidence/t_b00feca2/scope.json/log` → pass; executed `t_df29f3c6 analyze: cwd=/home/xel/git/gormes/hermes-wing/.task-evidence/t_df29f3c6/mirror; flutter analyze --no-pub; receipt=.task-evidence/t_df29f3c6/analyze.json/log` → pass; executed `t_df29f3c6 format-final: cwd=/home/xel/git/gormes/hermes-wing; dart format --output=none --set-exit-if-changed test/features/hermes_chat/screens/hermes_chat_death_completion_recovery_test.dart; receipt=.task-evidence/t_df29f3c6/format-final.json/log` → pass; executed `t_df29f3c6 format-verified: cwd=/home/xel/git/gormes/hermes-wing; dart format --output=none --set-exit-if-changed test/features/hermes_chat/screens/hermes_chat_death_completion_recovery_test.dart; receipt=.task-evidence/t_df29f3c6/format-verified.json/log` → pass; executed `t_df29f3c6 integrity: cwd=/home/xel/git/gormes/hermes-wing; python .task-evidence/t_df29f3c6/final_integrity.py; receipt=.task-evidence/t_df29f3c6/integrity.json/log; synthetic evidence only; M2 unverified; authoritative_counts_unavailable` → pass; executed `t_df29f3c6 ledger-ceiling-check: cwd=/home/xel/git/gormes/hermes-wing; python .task-evidence/t_df29f3c6/restore_ceiling.py; receipt=.task-evidence/t_df29f3c6/ledger-ceiling-check.json/log; synthetic evidence only; M2 unverified; authoritative_counts_unavailable` → pass; executed `t_df29f3c6 ledger: cwd=/home/xel/git/gormes/hermes-wing; python .task-evidence/t_df29f3c6/update_ledger.py; receipt=.task-evidence/t_df29f3c6/ledger.json/log; synthetic evidence only; M2 unverified; authoritative_counts_unavailable` → fail; executed `t_df29f3c6 review-451-analyze: cwd=/home/xel/git/gormes/hermes-wing/.task-evidence/t_df29f3c6/mirror; flutter analyze --no-pub; receipt=.task-evidence/t_df29f3c6/review-451-analyze.json/log; bounded review only; M2 unverified; authoritative_counts_unavailable` → pass; executed `t_df29f3c6 review-451-format: cwd=/home/xel/git/gormes/hermes-wing; dart format --output=none --set-exit-if-changed test/features/hermes_chat/screens/hermes_chat_death_completion_recovery_test.dart; receipt=.task-evidence/t_df29f3c6/review-451-format.json/log; bounded review only; M2 unverified; authoritative_counts_unavailable` → pass; executed `t_df29f3c6 review-451-integrity-final: cwd=/home/xel/git/gormes/hermes-wing; python .task-evidence/t_df29f3c6/review_451_verify.py; receipt=.task-evidence/t_df29f3c6/review-451-integrity-final.json/log; bounded review only; M2 unverified; authoritative_counts_unavailable` → pass; executed `t_df29f3c6 review-451-integrity: cwd=/home/xel/git/gormes/hermes-wing; python .task-evidence/t_df29f3c6/review_451_verify.py; receipt=.task-evidence/t_df29f3c6/review-451-integrity.json/log; bounded review only; M2 unverified; authoritative_counts_unavailable` → fail; executed `t_df29f3c6 review-451-scope: cwd=/home/xel/git/gormes/hermes-wing; python .task-evidence/t_df29f3c6/verify_scope.py; receipt=.task-evidence/t_df29f3c6/review-451-scope.json/log; bounded review only; M2 unverified; authoritative_counts_unavailable` → pass; executed `t_df29f3c6 review-451-tests: cwd=/home/xel/git/gormes/hermes-wing/.task-evidence/t_df29f3c6/mirror; flutter test --no-pub test/features/hermes_chat/screens/hermes_chat_death_completion_recovery_test.dart test/features/hermes_chat/screens/hermes_chat_screen_auth_recovery_test.dart test/features/hermes_chat/screens/hermes_chat_session_restoration_test.dart test/features/hermes_chat/gateways/hermes_gateway_restoration_adversarial_test.dart --concurrency=1 --reporter expanded; receipt=.task-evidence/t_df29f3c6/review-451-tests.json/log; bounded review only; M2 unverified; authoritative_counts_unavailable` → pass; executed `t_df29f3c6 scope-final: cwd=/home/xel/git/gormes/hermes-wing; python .task-evidence/t_df29f3c6/verify_scope.py; receipt=.task-evidence/t_df29f3c6/scope-final.json/log; synthetic evidence only; M2 unverified; authoritative_counts_unavailable` → pass; executed `t_df29f3c6 scope: cwd=/home/xel/git/gormes/hermes-wing; python .task-evidence/t_df29f3c6/verify_scope.py; receipt=.task-evidence/t_df29f3c6/scope.json/log` → pass; executed `t_df29f3c6 tests: cwd=/home/xel/git/gormes/hermes-wing/.task-evidence/t_df29f3c6/mirror; flutter test --no-pub test/features/hermes_chat/screens/hermes_chat_death_completion_recovery_test.dart test/features/hermes_chat/screens/hermes_chat_screen_auth_recovery_test.dart test/features/hermes_chat/screens/hermes_chat_session_restoration_test.dart test/features/hermes_chat/gateways/hermes_gateway_restoration_adversarial_test.dart --concurrency=1 --reporter expanded; receipt=.task-evidence/t_df29f3c6/tests.json/log` → pass; inspection `.task-evidence/t_41606eec/validation.json (13 authored fingerprints match; retained 44 tooling passes, 60 negative and four positive consumers; source refusal only, independent approval and installed/Android/live M2 unverified)` → pass; inspection `.task-evidence/t_4e4a4f7d/review-414.json (approved bounded history-admission repair; matching combined log records 539 passes; read-only review_integrity.py verifies six selected files, 441 mirror Dart files and retained logs; Android, live counts and integrated M2 remain unverified)` → pass; inspection `.task-evidence/t_53f0d91e/report.md#native-review-correction (c141d8d7; three authored branch blobs, 186 closure files and five packaging inputs match refreshed receipt; retained suite records 24 passes after six RED controls; independent final approval and Android/live qualification unverified)` → pass; inspection `.task-evidence/t_ccec142b/reviewer-round-1.md (approved source-only delivery brief; 13 fingerprints, 30 citations, four links and eleven synthetic refusal controls rechecked; APK/storage/continuity and integrated M2 unverified)` → pass; inspection `ROADMAP.md#m2--leave-and-return-without-losing-ownership` → pass; inspection `docs/quality/2026-10-06-m2-android-preflight.md` → pass; inspection `docs/quality/2026-10-06-m2-android-preflight.md#bounded-write-and-delivery-contract` → pass; inspection `docs/quality/2026-10-06-m2-continuity-baseline.md` → pass; inspection `docs/quality/2026-10-06-m2-coordinator-admission-trace.md; 25 refreshed source/report fingerprints match; source-only preparation; independent final approval unverified` → pass; inspection `docs/quality/2026-10-06-m2-counting-contract.md` → pass; inspection `docs/quality/2026-10-06-m2-forbidden-recovery-oracle.md (428 lib/test fingerprints match; retained oracle and nearest receipts record 3 and 60 passes; bootstrap-wide denial, independent final approval and Android/live counts unverified)` → pass; inspection `docs/quality/2026-10-06-m2-history-identity.md (15 production/test/runbook fingerprints and 25 command logs match; report fingerprint differs; 48 focused, 432 nearest and 63 caller passes retained; final approval and Android/live counts unverified)` → pass; inspection `docs/quality/2026-10-06-m2-issuer-evidence-contract.md (18 retained source fingerprints, document digest and local closure match; proposed F01-F10 unavailable, NOT_ADMITTED; source-only delivery, installed/Android/counting M2 unverified)` → pass; inspection `docs/quality/2026-10-06-m2-manifest-assessment-contract.md (17 retained fingerprints match; document integrity only; F01/F02 and M2 unverified)` → pass; inspection `docs/quality/2026-10-06-m2-recovery-read-admission.md (30 selected fingerprints and five log hashes match; 16 characterization and one recreation passes; three defects remain; same-card review and Android/live qualification unverified)` → pass | DOC-M2-INODE-POLICY-EVIDENCE, M2-DEVICE-QUALIFICATION |

<!-- goals:coverage:end -->

Retention and push documents remain proposals, not accepted persistence or notification goals.
Their decisions apply only if those optional features are selected; do not infer approval here.
Remaining scope follows [M1–M6](ROADMAP.md#six-outcome-milestones) and the parity ledger:
M2 credential/owner failures; M3 complete setup and individually supported writes;
M4 discovery/MCP, memory, jobs, board and host/platform administration;
M5 safe artifacts, Android copy/save/share, IME/large-text/reduced-motion/screen readers;
M6 named-platform install/upgrade/recovery/uninstall and signed distribution;
Desktop composer/transcript fidelity, Office and remaining surfaces. Each later slice
needs its own exact capability, ownership and qualification evidence.

## Now / Next

- [x] **DOC-GLOBAL-SESSIONS-CURRENT-CHECK** — Goal: GLOBAL-LOADED-SESSIONS.
  Recheck loaded-session Open/New against the changed sidebar. Payoff: qualify
  current presentation without reopening the completed `t_1c1e6f37` delivery.
  Source: [source-snapshot limit](docs/runbooks/global-session-access.md#current-snapshot-limit)
  and [historical command receipt](.task-evidence/t_1c1e6f37/verified-commands.json).
  Scope: current shell, existing focused regressions and compiled deterministic
  browser journey. Exclude live requests, installs, native qualification, upstream
  edits, new domain state and task/card transitions.
  Evidence follow-through: the [shell redesign receipt](docs/runbooks/desktop-shell-reference-fidelity.md)
  records 57 focused widget passes and two compiled Chromium journeys, including
  global Open/New. All four final source fingerprints match this inspected snapshot.
  The final manifest now includes the [P1 toggle focus correction](docs/runbooks/desktop-shell-reference-fidelity.md#independent-review-p1-correction).
  Attribute these sources to `focus-fix-tests.log` and `focus-fix-browser-tests.log`,
  not the earlier redesign logs. Rendered edge-pixel checks supplement style
  assertions; executor passes do not establish independent finish acceptance.
  Fresh follow-through: [t_d06ef06d's current-source receipt](docs/quality/2026-10-06-global-sessions-current-check.md)
  binds all 521 copied inputs and a 195-file local dependency closure. At
  acceptance, all source fingerprints and 31 integrity entries matched. Its command
  receipt records 44 shell-widget passes, nine caller/lifetime passes, a fresh
  release web build and one Chromium journey, all exit 0. These checks replace the
  incomplete historical attribution; no duplicate rerun is needed while inputs match.
  Completed acceptance: the [independent review receipt](.task-evidence/t_d06ef06d/review-run/review-validation.json)
  records approved bounded acceptance. Its retained logs record 44 shell-widget
  passes, nine caller/lifetime passes, a fresh web build and one Chromium pass.
  All 31 executor and 27 review integrity entries remain intact. Nine of the
  521 source fingerprints now differ across messaging, history parsing/models
  and channel regressions.
  The ledger preserves this completed review-snapshot task; its execution does
  not qualify those later recovery/Stop changes.
  The bounded goal is met by these executed checks, not by task closure alone.
  Native desktop, live generation, full suites and full parity remain unqualified.
  DOC-M2-AMBIGUOUS-404 is done; DOC-M2-HISTORY-IDENTITY covers current
  history work. After it settles, repeat
  affected caller checks before extending current-source qualification.
  Preserve single create, exact Open, passive observation, keyboard access,
  collapse invalidation and compact recovery. Do not weaken the oracle.
  Dependencies: PARITY-GLOBAL-SESSIONS (done). Ownership: completed t_d06ef06d;
  this documentation handoff does not claim or transition a card or start a worker.
  Verification follow-through: requested `npm run test` exited 1 with 3,386 passes
  and three shell failures: two palette/selection assertions in
  `test/shared/widgets/app_shell_reference_fidelity_test.dart` and the brand-label
  assertion in `test/shared/widgets/app_shell_test.dart`. See
  [execution log](.task-evidence/repo-docs-npm-test.log). Concurrent shell/test edits
  remain untouched; this failed full-suite run does not qualify the current shell.

These are bounded next slices within accepted goals, not claims of current leases.
They do not authorize this documentation job to execute code, tests, installs,
card changes or schedule changes. Existing card scopes and owner-only final actions
remain binding. Do not repeat unchanged failed gates or duplicate claimed work.

- [x] **DOC-M2-CONTINUITY-BASELINE** — Goal: M2. Inspect current detached-run and
  lifecycle tests against the OS-death matrix. Payoff: identify the smallest missing
  recovery oracle before device work. Source: [Android discovery](docs/quality/2026-10-03-android-qualification-discovery.md)
  and [M2](ROADMAP.md#m2--leave-and-return-without-losing-ownership).
  Scope: existing channel/store tests and a sanitized evidence handoff; no live
  target, personal app, credentials, installs or push/draft persistence changes.
  Acceptance: name covered and uncovered owner/history/replay cases and one bounded
  device scenario; deterministic tests must not be labeled OS-death evidence.
  Dependencies: none for inspection; actual device qualification needs M1 and a
  named owned target. Ownership: t_2d1d55ab; baseline delivered in
  [current-source receipt](docs/quality/2026-10-06-m2-continuity-baseline.md).
  Android M2 remains unverified; deterministic recovery is not OS-death proof.

- [x] **DOC-M2-DEATH-COMPLETE-ORACLE** — Goal: M2. Run or add one isolated
  app-level running → absent client → completed → restored-history check.
  Payoff: connect the passing channel/store baseline to the missing relaunch oracle.
  Source: [current-source baseline](docs/quality/2026-10-06-m2-continuity-baseline.md#exactly-one-future-scenario-android-m2-death-complete-01)
  and [M2](ROADMAP.md#m2--leave-and-return-without-losing-ownership).
  Scope: deterministic QA fixture, startup/restoration harness and sanitized receipt;
  exclude live inference, credentials, personal apps, installs, upstream changes,
  push and draft persistence. Do not run the production-package Maestro flow.
  Acceptance: the app restores the explicit non-default owner/session and canonical
  terminal history; counted run submissions remain one and restoration adds zero
  session creates, sends, Stop or approval responses. Record the exact command,
  source hashes and target. Fixture success is not Android OS-death, keystore,
  credential-expiry or denied-notification qualification. Identify the remaining
  named-device check from the baseline scenario without claiming it passed.
  Dependencies: DOC-M2-CONTINUITY-BASELINE (done). Deterministic preparation is
  independent of live M1 admission; actual Android qualification retains M1,
  owned-target, private-auth and consent prerequisites. Ownership: t_e0af7ad4;
  deterministic oracle delivered in [the receipt](docs/quality/2026-10-06-m2-death-completion-oracle.md).
  Android M2 remains unverified; this is not process-death or device qualification.

- [x] **DOC-M2-ANDROID-PREFLIGHT** — Goal: M2. Prepare the named-device
  death-to-completion check without launching or provisioning a target. Payoff:
  move from the passing deterministic oracle to an executable isolation contract.
  Source: [completed fixture oracle](docs/quality/2026-10-06-m2-death-completion-oracle.md)
  and [ANDROID-M2-DEATH-COMPLETE-01](docs/quality/2026-10-06-m2-continuity-baseline.md#exactly-one-future-scenario-android-m2-death-complete-01).
  Scope: inspect existing QA package/build/runner isolation, run-mode receipts and
  metadata-only observer seams. Exclude installs, device/process actions, live
  requests, credential acquisition, inference, upstream edits and notifications.
  Acceptance: produce a sanitized preflight mapping each scenario prerequisite
  to existing evidence or a precise gap. Name the smallest missing observer or
  runner slice and concrete identity/history/no-replay checks. Do not claim
  Android death, keystore durability or runtime acceptance from fixture evidence.
  Dependencies: DOC-M2-DEATH-COMPLETE-ORACLE (done). Preparation is independent of
  live M1 admission; actual execution retains named owned QA target, admitted
  unmodified Agent, private authentication and bounded generation consent.
  Ownership: delivered on `t_f5728f44`; the goal ledger marks this preparation
  done. The [preflight artifact](docs/quality/2026-10-06-m2-android-preflight.md)
  maps isolation and observer prerequisites. All 28 recorded source fingerprints
  match this snapshot. The retained receipt does not establish independent final
  approval. The QA metadata adapter remains proposed; M2 remains unverified.
  Continue with DOC-M2-COUNTING-CONTRACT below, not a duplicate preflight.

- [ ] **DOC-M3-CONTRACT-CHECKPOINT** — Goal: M3. Map the supported enrollment
  and new-profile setup journey to its isolated qualification checks. Payoff:
  prove existing setup without conflating it with unavailable Project/provider writes. Source: [M3](ROADMAP.md#m3--trusted-onboarding-into-a-useful-profile-and-workspace)
  and [mutation criteria](docs/adr/api-and-state.md#required-agent-owned-mutation-contract).
  Scope: source/test/caller trace and contract-gap receipt only; no Agent edits,
  direct-file fallback, provider mutation, secrets or expanded Wing Link adapter.
  Acceptance: identify the smallest isolated enrollment → new-profile → explicit
  Chat check with exact device/profile identity, transaction rollback and no hidden
  writes. Project and existing-profile provider contracts have separate tasks below.
  Dependencies: none for source inspection; implementation needs verified contract
  and ownership. Ownership: unclaimed in this index; verify tracker first.

- [ ] **DOC-M4-CONTRACT-CHECKPOINT** — Goal: M4-DISCOVER.
  Inspect one profile-scoped discovery catalog read before proposing UI or writes.
  Payoff: advance accepted discovery without freezing existing inventories.
  Source: [M4](ROADMAP.md#m4--discover-and-administer-supported-agent-work).
  Scope: read-only authoritative handler/test and Wing caller/regression trace;
  exclude installs, MCP mutation, generic commands and shadow inventories.
  Acceptance: supported bounded schema, exact grant/profile gate and failure
  behavior, or an evidenced unavailable operation. Remaining M4 operations stay
  individually gated. Dependencies: none for inspection. Ownership: unclaimed in
  this index; verify tracker and reference instructions before deep upstream study.

- [ ] **DOC-M5-ANDROID-FIXTURE** — Goal: M5. Repair only the two reproduced fixture
  selectors/navigation failures in the [Android discovery receipt](docs/quality/2026-10-03-android-qualification-discovery.md).
  Payoff: reach existing transcript-copy and setup accessibility exits.
  Scope: existing Maestro fixture flows, deterministic QA harness and scoped
  regressions; exclude product redesign, personal apps, provider calls and installs.
  Acceptance: both flows reach their intended exits on a named owned Android QA
  target, with clipboard/readback and share-sheet dismissal receipts; report
  TalkBack as unverified unless actually exercised. Dependencies: owned target and
  exclusive build access for execution; static fixture repair can proceed first.
  Ownership: unclaimed in this index; verify tracker first.

- [ ] **DOC-NATIVE-DESIGN-REVIEW** — Goal: Desktop bounded native integration.
  Review the [existing design](docs/plans/2026-10-03-desktop-local-integration-design.md)
  against living ADRs and exact installed-Agent contracts. Payoff: narrow the first
  local operation without copying privileged Desktop IPC. Scope: design/evidence
  only; no operation activation, upstream edits, arbitrary paths or shell access.
  Acceptance: list proposed versus already-authorized operations, fixed argument
  shapes, identity, secret acquisition, failure/recovery and removal criteria.
  Dependencies: none for source review; privileged implementation needs a separate
  security/design decision. Ownership: existing design lane; verify current lease.

- [ ] **DOC-SECURITY-CURRENT-BOUNDARY** — Goal: PRD product rules/security boundaries.
  Map current denial, containment, redaction, approval and reconnect checks to the
  [test plan](docs/test-plan.md) and [threat model](docs/security/threat-model.md).
  Payoff: prioritize missing proof before new operations. Scope: existing Wing/Go
  tests and sanitized evidence; no weakening controls, live writes or credentials.
  Acceptance: distinguish existing automation, source-bound passes and unverified
  platform guarantees; identify the smallest absent regression if any.
  Dependencies: none for inspection; test execution requires exclusive tooling.
  Ownership: unclaimed in this index; verify tracker first.

- [x] **DOC-API-CONFORMANCE** — Goal: API-CONFORMANCE. Check the
  [code-first snapshot](docs/api/wing-link.openapi.yaml) against its cited handlers
  and existing Go route/security tests. Payoff: prevent integrators mistaking a
  structural snapshot for runtime authority. Scope: offline schema/local-reference
  checks and one bounded management-route family; no API redesign, generated client,
  live server or new dependencies. Acceptance: validate with existing tooling where
  available, document unsupported checks and reconcile concrete handler/schema drift.
  Delivered on `t_f2b5c61e`, branch `agent/wing/t_f2b5c61e`:
  [discovery conformance receipt](docs/quality/2026-10-06-wing-link-api-conformance.md)
  for GET `/meta` and GET `/healthz`. All 20 source fingerprints match this snapshot.
  Retained checks cover 62 recorder responses and nine negative cases, with passing
  YAML/reference/JSON Schema and scoped Go checks. The corrected metadata schema
  requires `[1, 2]`; this is not a runtime protocol change. Complete OpenAPI standards
  validation, other management families and live transport remain NOT_CHECKED.
  The goal ledger now records this discovery slice done. The retained execution
  receipt does not establish independent native review; this index does not approve
  or transition its card. API-CONFORMANCE stays unverified. Continue with
  DOC-API-DEVICE-SELF-CONFORMANCE below, not a duplicate discovery dispatch.

- [x] **DOC-M6-ARTIFACT-EVIDENCE** — Goal: M6. Inventory source/artifact-bound receipts
  required by the [release runbook](docs/runbooks/release-alpha.md) and current CI.
  Payoff: expose missing install/upgrade/recovery proof without publishing.
  Scope: existing workflows, artifact verifier and evidence index only; no release,
  signing secrets, builds, installation or live rollback. Acceptance: identify
  candidate receipts, their source/target limits and missing M1–M5/recovery evidence.
  Include the [local verifier prerequisites](docs/runbooks/release-alpha.md#local-artifact-verification):
  candidate source revision, exact evidence/asset allowlist, signing-certificate
  fingerprint and host tooling. Distinguish host verification from separate
  Android, Windows and macOS workflow smoke receipts. Inspection is not execution.
  Dependencies: none for inventory; final qualification/publication depends on
  accepted applicable milestones and owner authority. Delivered on `t_8daadbc0`:
  [source-bound inventory](docs/quality/2026-10-06-m6-artifact-evidence.md),
  implementation checks passed; native same-card review remains pending. M6 is
  unverified. Repo-docs owns the next bounded M6 backlog entry; no new card here.

- [x] **DOC-M6-CANDIDATE-ADMISSION** — Goal: M6. Prepare the offline exact-candidate
  comparison and its negative-case oracle. Payoff: make the next qualification
  step reproducible without treating source receipts as installed-alpha proof.
  Source: [M6 inventory](docs/quality/2026-10-06-m6-artifact-evidence.md#one-bounded-next-step)
  and [local verifier admission](docs/runbooks/release-alpha.md#local-artifact-verification).
  Scope: existing `scripts/release_evidence.mjs`, evidence tests and a sanitized
  admission checklist. Exclude builds, installs, extraction, candidate execution,
  signing secrets, network requests, publication and tracker changes.
  Acceptance: map candidate revision/tag/version/build/run/repository, input and
  artifact digests, certificate identity and target receipts to existing checks.
  Run or add an isolated offline comparison oracle for matching evidence, changed
  identity/bytes and missing platform receipts. Record exact commands and source
  hashes. Synthetic checks qualify only the comparison, not M6. If public candidate
  files are unavailable, finish the checklist and oracle first; leave candidate
  and integrated install/upgrade/recovery NOT_CHECKED. Do not search private state.
  Dependencies: DOC-M6-ARTIFACT-EVIDENCE (done). Preparation needs no candidate or
  owner answer; actual candidate qualification retains its separate admission.
  Ownership: delivered on `t_15e9decd`; the goal ledger marks this bounded
  preparation done. The [admission receipt](docs/quality/2026-10-06-m6-candidate-admission.md)
  records 56 passing offline synthetic tests. Its nine source fingerprints match
  this snapshot. This is not independent final approval, public-candidate execution
  or M6 acceptance. Continue with DOC-M6-OFFLINE-CHECKER below.

- [x] **DOC-M2-COUNTING-CONTRACT** — Goal: M2. Trace the authoritative
  metadata counting source required by the proposed QA observer. Payoff: prevent
  client counters from being mistaken for proof of zero restoration mutations.
  Source: [observer contract](docs/quality/2026-10-06-m2-android-preflight.md#bounded-write-and-delivery-contract).
  Scope: read-only Agent contract/nearest-test and Wing caller trace; exclude
  Agent edits, new endpoints, observer implementation, devices, live requests,
  credentials and Wing Link data-plane routing.
  Acceptance: identify exact operation, grants, owner binding, bounds, accepted/
  rejected mutation coverage and continuous epoch semantics, or document the
  precise unavailable contract. Keep Android qualification unverified either way.
  Dependencies: DOC-M2-ANDROID-PREFLIGHT (done). The goal ledger now records
  the source-only slice on `t_0599745b` done; do not dispatch a duplicate. The
  [source-contract artifact](docs/quality/2026-10-06-m2-counting-contract.md)
  retains `authoritative_counts_unavailable`: inspected metrics, run status,
  replay occupancy and authentication audit do not supply whole-attempt accepted/
  rejected mutation counts. Its offline integrity receipt binds 46 source files
  and the document; this is not installed-runtime or Android qualification.
  The [handoff](.task-evidence/t_0599745b/handoff.json) requests completion only
  after native review. The retained receipt does not establish that review; this
  index records ledger completion, not card approval. M2 remains unverified.
  Continue with DOC-M2-RECOVERY-READ-ADMISSION below; source integrity is not
  milestone acceptance.

- [x] **DOC-M6-OFFLINE-CHECKER** — Goal: M6. Prepare one read-only candidate
  comparison entrypoint using the existing verifier exports. Payoff: turn the
  passing synthetic oracle into a reproducible offline comparison without executing
  artifacts. Source: [required public inputs](docs/quality/2026-10-06-m6-candidate-admission.md#required-public-inputs).
  Scope: bounded offline tooling and its deterministic tests; no protocol redesign,
  builds, installs, extraction, artifact execution, private state, signing secrets,
  network requests or publication.
  Acceptance: explicitly supply independently admitted identity and public certificate
  expectations; compare the published index with recomputed bindings; reject changed
  identity/bytes/certificate and missing receipts. Run an isolated synthetic oracle
  with exact exits and source fingerprints. Missing public inputs leave actual
  candidate comparison NOT_CHECKED; fixture passes do not satisfy M6.
  Dependencies: DOC-M6-CANDIDATE-ADMISSION (done). The goal ledger now records
  the bounded slice on `t_bef84284` done; do not dispatch a duplicate. The
  [delivered comparator runbook](docs/runbooks/offline-release-candidate-comparison.md)
  and [source-bound receipt](.task-evidence/t_bef84284/validation.json) record
  120 passing offline synthetic tests on Node v26.7.0. All four recorded source
  fingerprints match this snapshot. The [handoff](.task-evidence/t_bef84284/handoff.json)
  requires native same-card approval before card closure. The retained receipt
  does not establish that approval; this index does not transition the card.
  No actual public candidate, signature, installed-runtime or Node 22 qualification
  is inferred; M6 stays unverified. Continue with DOC-M6-CHECKER-NODE22 below.

- [x] **DOC-M2-RECOVERY-READ-ADMISSION** — Goal: M2. Trace one exact-owner
  status/history recovery path for the named death-to-completion scenario.
  Payoff: qualify narrower recovery prerequisites without inventing live counters.
  Sources: [counting disposition](docs/quality/2026-10-06-m2-counting-contract.md#practical-next-step-disposition)
  and [scenario](docs/quality/2026-10-06-m2-continuity-baseline.md#exactly-one-future-scenario-android-m2-death-complete-01).
  Scope: existing Agent contract/nearest tests and Wing reconciliation caller;
  read-only reference inspection and isolated Wing checks only. Exclude Agent
  edits, private deployments, credentials, live inference, device operations,
  observer implementation and new endpoints.
  Acceptance: document exact read/grant/identity and terminal-history semantics;
  run or add the smallest isolated recovery check for completed, absent, denied
  and replacement-owner results. Cite exact commands and source-bound receipts.
  These checks do not prove Android OS death or zero live mutations. Retain
  `authoritative_counts_unavailable` unless a separately admitted source proves
  the full counting contract. Record the remaining named-device proof task.
  Dependencies: DOC-M2-COUNTING-CONTRACT (done). Ownership: bounded ledger slice done on
  `t_3c5078de`; do not dispatch a duplicate. The
  [characterization receipt](docs/quality/2026-10-06-m2-recovery-read-admission.md)
  records 16 focused passes, one nearest recreation pass and clean analysis in an
  isolated mirror. All 30 selected fingerprints and five log hashes matched at
  inspection. The positive completed-status/history case is demonstrated, but
  three defects remain: ambiguous 404 clears ownership, unrelated response history
  settles the requested lease, and declared history-grant denial does not gate reads.
  Green characterization tests do not approve those outcomes. Preserve these
  [bounded repair findings](docs/quality/2026-10-06-m2-recovery-read-admission.md#precise-next-repair-findings-not-implemented-here)
  for the ordered repair slices below. The
  [independent review receipt](.task-evidence/t_3c5078de/review-validation.json)
  approves only the bounded characterization and repeats 16 focused checks, one
  nearest check and clean analysis. It does not admit unconditional recovery.
  This index reconciles existing ledger completion, not tracker state or scope.
  M2 remains unverified; no named-device or live-counting acceptance is inferred.

- [x] **DOC-M2-AMBIGUOUS-404** — Goal: M2. Retain uncertain detached-run
  ownership when status 404 cannot distinguish absence from a foreign owner.
  Payoff: prevent an ambiguous read from releasing the duplicate-send guard.
  Source: [finding 1](docs/quality/2026-10-06-m2-recovery-read-admission.md#precise-next-repair-findings-not-implemented-here)
  and [independent review](.task-evidence/t_3c5078de/review-validation.json).
  Scope: existing HTTP recovery reconciliation and its focused tests; exclude
  Agent edits, new endpoints, native RPC, live requests and device execution.
  Acceptance: the existing absent/foreign-404 characterization first demonstrates
  premature settlement; the repaired oracle retains the lease and unresolved
  guard for both indistinguishable outcomes. Exact completed/history recovery
  and denied/replacement controls still pass. Record executed commands and source
  fingerprints. Keep M2 unverified and `authoritative_counts_unavailable`.
  Dependencies: DOC-M2-RECOVERY-READ-ADMISSION (done). The goal ledger records
  this bounded slice done; do not dispatch a duplicate. Executor `t_3a5135a8` delivered the
  [bounded repair receipt](docs/quality/2026-10-06-m2-ambiguous-404.md), with
  18 focused, 78 nearest and 42 restoration passes, clean format and analysis.
  All three changed source/test hashes and retained command-log hashes match the
  inspected snapshot. The [artifact-review receipt](.task-evidence/t_3a5135a8/review-398-validation.json)
  independently records the same 18 focused, 78 nearest and 42 restoration passes,
  baseline RED, clean format and analysis. All five authored fingerprints and
  seven review log hashes match. A [scoped npm receipt](.task-evidence/t_3a5135a8/review-398-npm-validation.json)
  records 394 passes, not a full-suite run. Its log hash also matches. These receipts
  establish independent execution, not a final native approval verdict or M2 acceptance.
  This index preserves ledger completion without transitioning a card. Do not repeat
  unchanged passing checks solely to restate delivery.
  Include the loaded-session caller/lifetime regressions named in
  [the test plan](docs/test-plan.md#acceptance-records-and-gaps) when qualifying
  the changed shared channel; preserve completed review-snapshot acceptance.

- [x] **DOC-M2-HISTORY-IDENTITY** — Goal: M2. Validate response-session and
  compaction lineage before publishing history or settling a recovered lease.
  Payoff: unrelated history cannot masquerade as exact-session recovery.
  Source: [finding 2](docs/quality/2026-10-06-m2-recovery-read-admission.md#precise-next-repair-findings-not-implemented-here).
  Scope: existing history page model, HTTP parser and shared hydration callers;
  exclude upstream changes, shadow history, new APIs and live/device operations.
  Acceptance: run the wrong-history oracle before and after the repair; reject
  unrelated envelopes/rows without publication or settlement, preserve legitimate
  compaction ancestors and exact completed hydration, and pass replacement-owner
  regressions. Bind executed evidence to changed sources; do not claim Android proof.
  Dependencies: DOC-M2-AMBIGUOUS-404 (done), to serialize the shared recovery seam.
  Executor evidence: [implementation report](docs/quality/2026-10-06-m2-history-identity.md)
  and [validation receipt](.task-evidence/t_cd72a5d5/validation.json) record 48 focused,
  432 nearest and 63 caller/restoration passes, clean format and analysis. All 15
  production/test/runbook hashes and 25 command-log hashes match; the report's
  fingerprint differs. Exact-session and proven compaction pages are admitted;
  unrelated pages retain durable ownership without publication or replay.
  Review execution: [source-bound receipt](.task-evidence/t_cd72a5d5/review-404-validation.json)
  binds all 16 selected source/document fingerprints, including the current report.
  Matching logs record 48 focused and 432 nearest passes. The executor report-hash
  mismatch remains historical; current review attribution is established.
  Status: done in `goals.json`. The [independent review](.task-evidence/t_cd72a5d5/review-404.md)
  approves this scoped implementation. Matching review logs record 63 caller passes
  and 543 scoped npm passes, in addition to the focused and nearest checks above.
  M2 remains unverified; this does not qualify Android/live recovery.
  DOC-M2-HISTORY-ADMISSION below records the subsequent implementation slice.

- [x] **DOC-M2-HISTORY-ADMISSION** — Goal: M2. Enforce declared history-read
  grants without removing supported legacy baseline reads.
  Payoff: recovery reads obey the same exact-operation policy as their readiness.
  Source: [finding 3](docs/quality/2026-10-06-m2-recovery-read-admission.md#precise-next-repair-findings-not-implemented-here)
  and [API decision](docs/adr/api-and-state.md#decision).
  Scope: shared history-read admission and nearest recovery/caller tests; exclude
  new capability fields, Agent changes, credential acquisition and live requests.
  Acceptance: execute declared-denied and legacy controls; an ungranted declared
  history operation makes zero history requests and cannot settle its lease.
  Supported legacy and explicitly granted exact-owner history still hydrate;
  replacement-owner results remain fenced. Retain executed receipts and the
  separate named-device/counting prerequisites. M2 remains unverified.
  Dependencies: DOC-M2-HISTORY-IDENTITY (done). Status: done in `goals.json`
  for the bounded repair, with independent same-card approval.
  Executor evidence: [implementation report](docs/quality/2026-10-06-m2-history-admission.md)
  and [validation receipt](.task-evidence/t_4e4a4f7d/validation.json) bind six matching
  source/document hashes. Retained final logs record 64 focused, 432 nearest and
  43 caller passes, clean format and analysis. The superseded focused log is not
  used as acceptance evidence. The [independent review verdict](.task-evidence/t_4e4a4f7d/review-414.json)
  approves this slice. Its matching combined log records 539 passes; the read-only
  integrity check verifies six selected files, 441 mirror Dart files and retained
  command logs. No Android/live/M2 qualification follows. Continue with
  DOC-M2-POST-REPAIR-CALLERS, not a duplicate repair or review.

- [x] **DOC-M2-POST-REPAIR-CALLERS** — Goal: M2. Qualify current loaded-session
  callers after shared recovery repairs. Payoff: fresh compiled evidence binds
  shell Open/New and caller admission to the repaired history path.
  Sources: [caller qualification gap](docs/test-plan.md#acceptance-records-and-gaps),
  [loaded-session runbook](docs/runbooks/global-session-access.md) and
  [history-admission receipt](docs/quality/2026-10-06-m2-history-admission.md).
  Scope: isolated current-source widget/caller checks, release fixture web build
  and the existing global-session-access Chromium journey. Exclude production
  repairs, upstream edits, installs, live requests, credentials and device actions.
  Acceptance: retain exact argv, source/import/build fingerprints and passing
  shell/lifetime/caller checks plus the compiled keyboard Open/New journey.
  Assert exact scoped reads, one deliberate create and no layout-driven requests;
  retain denial/owner-replacement controls. Report Android/process-death and
  authoritative live counts as unverified, with their next bounded proof slice.
  Dependencies: DOC-M2-HISTORY-ADMISSION (done, bounded review approved). This
  task qualifies loaded-session callers; it does not reopen or approve that repair.
  Status: done in `goals.json` for this bounded execution slice. The
  [current-source report](docs/quality/2026-10-06-m2-post-repair-callers.md) and
  [command receipt](.task-evidence/t_103d63ec/commands.json) record 85 focused
  passes, clean analysis/formatting, a fresh release build and one Chromium pass.
  All 519 copied inputs and nine command-log hashes match this snapshot.
  Independent same-card final approval remains unverified; this entry does not
  transition the card or qualify M2. Continue with the credential-denial oracle,
  not a duplicate loaded-session run.

- [x] **DOC-M2-CREDENTIAL-DENIAL-ORACLE** — Goal: M2. Prove fail-closed
  recreated-client recovery when the saved owner's credential is rejected.
  Payoff: cover the accepted failure checkpoint at app level before device execution.
  Sources: [credential/owner checkpoints](docs/quality/2026-10-06-m2-continuity-baseline.md#exactly-one-future-scenario-android-m2-death-complete-01),
  [Android preflight](docs/quality/2026-10-06-m2-android-preflight.md#scenario-prerequisite-and-oracle-map)
  and [existing app-level oracle](test/features/hermes_chat/screens/hermes_chat_death_completion_recovery_test.dart).
  Scope: extend the existing isolated recreation harness with deterministic Agent
  authentication denial and later valid-owner read recovery. Reuse production
  channel/directory/store wiring and the serialized fixture store. Exclude live
  credentials, revocation, inference, devices, installs, upstream changes and new APIs.
  Acceptance: execute the added app-level test and nearest auth/recreation tests.
  Rejected credentials must not hydrate foreign history, erase unresolved ownership,
  substitute a session, send text or answer an approval. After explicit valid-owner
  recovery, only original-tuple reads may settle the lease. Count every fixture
  mutation attempt and retain exact commands and source fingerprints.
  A synthetic 401 is not real expiry/revocation, Android keystore or authoritative
  live counting evidence; retain `authoritative_counts_unavailable` and M2 unverified.
  Dependencies: DOC-M2-POST-REPAIR-CALLERS (done, execution slice only).
  Status: `done` in `goals.json` for bounded deterministic execution.
  The [delivered oracle](docs/quality/2026-10-06-m2-credential-denial-oracle.md)
  records two app-level cases, 60 nearest passes and four selected channel passes.
  All 428 recorded lib/test fingerprints match this snapshot. Retained independent
  review execution is available, but a final approval verdict is not established
  here. No product test was rerun by this documentation pass.
  Ownership: preserve t_59ea67ba and its review lane; do not duplicate execution.
  Real expiry/revocation, Android process death and live counts remain unverified.

- [x] **DOC-M2-FORBIDDEN-RECOVERY-ORACLE** — Goal: M2. Bounded HTTP 403
  recreation control delivered; the ledger records this execution task done.
  Evidence: [source-bound oracle receipt](docs/quality/2026-10-06-m2-forbidden-recovery-oracle.md)
  and `.task-evidence/t_b00feca2/oracle.json` / `nearest.json` retain three app-level
  cases and 60 nearest passes. All 428 recorded lib/test fingerprints match the
  inspected snapshot. Denied reads and public Retry retain the original lease;
  explicit authority recovery admits canonical history before settlement without
  fixture mutation replay. The [independent review execution receipt](.task-evidence/t_b00feca2/review-440-tests.json)
  records 63 passing cases and clean analysis. Its closure matches 151 local
  dependencies and 443 analyzed files in this snapshot. This pass inspects receipts,
  not a new product run.
  Ownership: preserve t_b00feca2 and its same-card review lane. Independent final
  approval, live grant revocation, Android process death and live counts remain
  unverified. Do not duplicate the completed resource-read denial control.

- [x] **DOC-M2-BOOTSTRAP-DENIAL-ORACLE** — Goal: M2. Bounded connection-bootstrap
  HTTP 401 recreation control delivered; the ledger records this task done.
  Payoff: cover required-capabilities rejection separately from resource-only denial.
  Sources: [remaining qualification](docs/quality/2026-10-06-m2-forbidden-recovery-oracle.md#remaining-qualification-and-questions)
  and [accepted recovery scenario](docs/quality/2026-10-06-m2-continuity-baseline.md#exactly-one-future-scenario-android-m2-death-complete-01).
  Scope: reuse the isolated app-level recreation harness and production connection
  path. Add one deterministic bootstrap authentication-denial control. Preserve
  completion and resource-read controls. Exclude new protocols, upstream edits,
  live credentials, devices, inference, installs and notification/platform claims.
  Acceptance: execute the app-level oracle and nearest authentication/restoration
  tests. Bootstrap denial and public Retry retain the exact durable lease and
  remembered owner, refuse substitute history and Send, and make no mutation
  attempts. Explicit original-owner authority recovery must reconcile canonical
  history before settlement. Record request attempts, commands, exits and inputs.
  Keep M2 unverified and `authoritative_counts_unavailable`; synthetic rejection
  does not qualify live revocation, secure storage or Android process death.
  Dependencies: DOC-M2-FORBIDDEN-RECOVERY-ORACLE (done, bounded execution only).
  Delivered on `t_15da6893`: [bootstrap HTTP 401 receipt](docs/quality/2026-10-06-m2-bootstrap-denial-oracle.md)
  and `.task-evidence/t_15da6893/oracle-fixed.json` / `nearest.json` retain four
  app-level cases and 60 nearest passes, with clean analysis. All 428 lib/test
  fingerprints, 151 local closure inputs and 443 analyzed files match this snapshot.
  This is inspected execution, not a new test run or independent final approval.
  Preserve the original card/review lane; do not repeat its completed control.

- [x] **DOC-M2-BOOTSTRAP-FORBIDDEN-ORACLE** — Goal: M2. Prove exact-owner
  recreation and public Retry when required capabilities reject with HTTP 403.
  Payoff: complete the bootstrap denial matrix without mistaking resource-only
  HTTP 403 or bootstrap HTTP 401 for this separate rejection control.
  Sources: [bootstrap receipt](docs/quality/2026-10-06-m2-bootstrap-denial-oracle.md#remaining-qualification-and-questions),
  [test plan](docs/test-plan.md#acceptance-records-and-gaps) and
  [accepted recovery scenario](docs/quality/2026-10-06-m2-continuity-baseline.md#exactly-one-future-scenario-android-m2-death-complete-01).
  Scope: inherited isolated app-level recreation harness and existing production
  connection path. Add one required-capabilities HTTP 403 control; preserve all
  four predecessor cases. Exclude live credentials, devices, inference, installs,
  upstream changes, new protocols, notification and platform claims.
  Acceptance: execute the oracle and nearest authentication/restoration tests.
  Count attempts before denial. Recreation and public Retry retain byte-identical
  durable ownership and remembered selection, refuse Send and foreign history,
  and attempt no mutations. Explicit original-authority restoration must admit
  canonical history before settlement. Record commands, exits and input hashes.
  Keep M2 unverified and `authoritative_counts_unavailable`; deterministic success
  is not Android process death, secure-storage or live authorization qualification.
  Dependencies: DOC-M2-BOOTSTRAP-DENIAL-ORACLE (done, bounded execution only).
  Status: done in `goals.json` for bounded deterministic execution. The
  [delivered bootstrap HTTP 403 receipt](docs/quality/2026-10-06-m2-bootstrap-forbidden-oracle.md)
  records five app-level controls and 65 total passes across the oracle and nearest
  targets. All 151 local closure inputs and 443 analyzed files match this snapshot.
  This pass inspected receipts; it did not rerun product checks or establish final
  independent approval. Preserve t_df29f3c6 and its review lane; do not duplicate
  completed denial controls. M2 and authoritative live counts remain unverified.

- [x] **DOC-M2-OBSERVER-COMPOSITION** — Goal: M2. Trace a QA-only recovery
  entrypoint that preserves production persistence and direct Agent transport.
  Payoff: prepare real process-death observation without another fixture-only
  denial control or an unqualified Android run.
  Sources: [preflight delivery contract](docs/quality/2026-10-06-m2-android-preflight.md#bounded-write-and-delivery-contract),
  [counting gap](docs/quality/2026-10-06-m2-counting-contract.md) and
  [accepted scenario](docs/quality/2026-10-06-m2-continuity-baseline.md#exactly-one-future-scenario-android-m2-death-complete-01).
  Scope: source-only composition map and one bounded observer implementation brief.
  Trace startup, channel, endpoint and secure-store injection plus the private
  metadata sink. Exclude implementation, existing owner/lifecycle edits, upstream
  changes, builds, devices, credentials, network, installs and production storage.
  Acceptance: identify exact injectable seams and complete local import closure,
  distinguish awaited secure writes from witnessed Android durability, and specify
  delayed/failed-write and wrong-owner/generation validation oracles. Preserve the
  preflight metadata allowlist and limits; document any unavailable composition
  seam instead of widening authority. Missing authoritative counting must retain
  `authoritative_counts_unavailable` and refuse qualification. Name the next
  bounded implementation slice and separately unexecuted device checks.
  Dependencies: DOC-M2-BOOTSTRAP-FORBIDDEN-ORACLE and DOC-M2-COUNTING-CONTRACT
  (both done for their bounded slices). Ownership: t_bd91fa65 delivered the
  [composition report](docs/quality/2026-10-06-m2-observer-composition.md).
  The [completion receipt](.task-evidence/t_bd91fa65/completion-receipt.json) and
  [offline validation](.task-evidence/t_bd91fa65/validation.json) establish source-only
  completion for its predecessor snapshot. The later default-refusal migration
  changes that closure; this historical binding does not qualify current sources.
  Receipt inspection is not a new product run or independent final approval.
  M2 remains unverified; retain existing review and continuation ownership.

- [x] **QA-M2-STORE-STATE-OBSERVER** — Goal: M2. Implement the conservative
  QA store/state observer through existing production injection seams.
  Payoff: prepare bounded persistence observations without replacing production
  transport or treating fixture counts as live authority.
  Sources: [exact implementation brief](docs/quality/2026-10-06-m2-observer-composition.md#exactly-one-next-implementation-brief)
  and [preflight allowlist](docs/quality/2026-10-06-m2-android-preflight.md#bounded-write-and-delivery-contract).
  Scope: only the three proposed Dart files named in the brief and task evidence.
  Preserve real endpoint, directory, cache, transport and secure-store defaults.
  Exclude production owner/lifecycle changes, upstream edits, counting endpoints,
  Android coordination, new plugins/runners, device/storage probing and live requests.
  Acceptance: execute deterministic delayed/failed-write, wrong-owner/generation,
  nested-scope same-channel, strict-schema and sink-error controls. Preserve the
  delegated coordination key and identical delegated errors. Enforce 128 events
  and 64 KiB per attempt, including wrappers, with bounded queues and readback.
  Recompute the QA import closure and reject fixture imports. Without witnessed
  pre-settlement history or admitted authoritative counts, emit typed unavailable
  evidence and refuse qualification. Do not infer admission from later UI state.
  Record exact focused test, formatter and analyzer commands plus source hashes;
  no device, durability, counting or integrated M2 pass may be inferred.
  Dependencies: DOC-M2-OBSERVER-COMPOSITION (done for source-only composition).
  Ownership: t_53f0d91e delivered the three-file adapter; its
  [completion handoff](.task-evidence/t_53f0d91e/completion-receipt.json) and
  [validation receipt](.task-evidence/t_53f0d91e/validation.json) record 24 deterministic
  passes, clean scoped analysis and formatting. Review correction `c141d8d7` rejects
  failed or unavailable history/canonical observations before synthetic admission
  advances. Six regressions first failed, then passed with the corrected validator.
  Those fingerprints describe the predecessor snapshot, not the later
  QA-M2-DEFAULT-REFUSAL migration. Its raw runtime observer and sink APIs have
  been removed; private fake diagnostics retain bounded tooling coverage.
  Done for bounded implementation, not independent final approval, Android
  durability, extraction, authoritative counts or integrated M2 acceptance.

- [x] **DOC-M2-QA-DELIVERY-ADMISSION** — Goal: M2. Trace dedicated QA package
  and private receipt-retrieval admission before named-device execution.
  Payoff: prevent source-only observer delivery from becoming a platform claim.
  Sources: [remaining observer limits](.task-evidence/t_53f0d91e/report.md#remaining--evidence-ceiling)
  and [Android preflight](docs/quality/2026-10-06-m2-android-preflight.md).
  Scope: read-only entrypoint, Gradle/manifest, plugin, runner and fixed QA sink
  trace; record a bounded delivery/extraction brief and offline integrity checks.
  Exclude source changes, installs/builds, device or private-storage probing,
  personal credentials, live inference, Agent edits and new counting authority.
  Acceptance: identify exact target/package/entrypoint isolation, plugin-delivery
  checks, attempt/generation continuity and bounded secret-safe retrieval limits.
  State which APK/device checks remain unexecuted. If no permitted retrieval or
  isolation seam exists, document that gap rather than inventing a runner.
  Preserve `history_admission_unavailable`, `authoritative_counts_unavailable`
  and M2 unverified; source checks cannot prove OS death or zero live mutations.
  Dependencies: QA-M2-STORE-STATE-OBSERVER (done for deterministic tooling).
  Completion: [delivery brief](docs/quality/2026-10-06-m2-qa-delivery-admission.md)
  and [independent review](.task-evidence/t_ccec142b/reviewer-round-1.md) verify
  bounded source-only acceptance. APK, plugins, storage, retrieval and M2 remain
  unverified. No worker or tracker transition is implied by this index.

- [x] **DOC-M2-RECEIPT-HANDOFF-CONTRACT** — Goal: M2. Define and review the
  proposed QA-only attempt/generation handoff before adapter implementation.
  Payoff: prevent in-process sink equality from becoming cross-process evidence.
  Sources: [delivery brief and next-slice proposal](docs/quality/2026-10-06-m2-qa-delivery-admission.md#exactly-one-proposed-next-slice-qa-only-continuityretrieval-adapter)
  and [scoped review](.task-evidence/t_ccec142b/reviewer-round-1.md).
  Scope: one source-backed contract artifact for typed attempt/current/prior
  generation input, fixed-key retrieval admission and separate envelope validation.
  Trace existing QA seams and record the proposed bounded write allowlist.
  Exclude implementation, transport/coordinator activation, packaging, devices,
  storage probes, credentials, network, inference and new counting authority.
  Acceptance: specify observable rejection for wrong package/target, missing
  retrieval permission, swapped generations, foreign attempts, corrupt/oversized
  or secret-bearing records and changed handoffs. A successful proposed handoff
  validates each envelope against its own generation without enumeration, writes
  or qualification. Review must distinguish independent platform evidence from
  caller assertions; keep history/counting unavailable and M2 unverified.
  Dependencies: DOC-M2-QA-DELIVERY-ADMISSION (done for source-only preparation).
  Completion: done in `goals.json` for the bounded proposal on `t_d6c8aa4f`.
  The [contract artifact](docs/quality/2026-10-06-m2-receipt-handoff-contract.md)
  and [retained receipt](.task-evidence/t_d6c8aa4f/validation.json) record 32 passing
  synthetic policy controls, matching selected inputs and scoped integrity checks.
  This pass repeats the checker read-only; it does not execute Dart or storage.
  Independent final approval remains unverified. The adapter and coordinator are
  not implemented or authorized by this proposal; M2 remains unverified.
  Continue with DOC-M2-COORDINATOR-ADMISSION-TRACE, not a duplicate contract task.

- [x] **DOC-M2-COORDINATOR-ADMISSION-TRACE** — Goal: M2. Trace the independent
  admission and exclusive ordering prerequisite for QA receipt continuity.
  Payoff: identify a source-backed next proof step without mistaking caller flags
  or same-key reads for cross-process authority.
  Sources: [independent admission](docs/quality/2026-10-06-m2-receipt-handoff-contract.md#independent-admission-distinct-from-caller-assertions)
  and [fixed-key ordering](docs/quality/2026-10-06-m2-receipt-handoff-contract.md#fixed-key-ordering-and-retention).
  Scope: existing QA entrypoint, sink, packaging and runner seams, inspected read-only;
  one source-backed admission map and bounded next proof task. Exclude adapter or
  coordinator implementation, activation, packaging edits, devices, private storage,
  credentials, network, inference, new counting authority and upstream edits.
  Acceptance: identify whether existing seams can independently bind the immutable
  attempt/generation and candidate/target/storage tuple, authorize the fixed read,
  fence competing writers and retain prior bytes before a new write. Cite exact
  sources and an offline integrity check; where absent, name the precise missing
  seam and its smallest separately reviewed proof slice. Preserve diagnostic-only
  results, unavailable history/counting and M2 unverified. Source inspection cannot
  qualify a device, storage durability or zero live mutations.
  Dependencies: DOC-M2-RECEIPT-HANDOFF-CONTRACT (done for proposal preparation).
  Completion: done in `goals.json` on `t_06c58314` for source-only preparation.
  The [source-only trace](docs/quality/2026-10-06-m2-coordinator-admission-trace.md)
  maps missing independent admission and shared-slot custody. All 25 recorded
  source/report fingerprints now match the refreshed binding. Independent final
  approval remains unverified. Its proposed custody proof is not authorized by
  this artifact; continue with DOC-M2-CUSTODY-PROOF-REVIEW, not duplicate execution.

- [x] **DOC-M2-CUSTODY-PROOF-REVIEW** — Goal: M2. Review the proposed bounded
  QA fixed-slot custody proof before implementation. Payoff: turn the completed
  admission trace into explicit proof requirements without activating transport.
  Source: [proposed next slice](docs/quality/2026-10-06-m2-coordinator-admission-trace.md#exactly-one-proposed-next-proof-slice).
  Scope: source-only design and rejection-matrix review of the stated QA allowlist.
  Exclude source/test implementation, packaging, devices, private storage, secrets,
  network, inference, new counting authority and upstream edits.
  Acceptance: identify typed authority issuance, complete caller closure, separate
  read/write rights, competing-writer refusal and immutable retention before release.
  Define deterministic success/refusal observations and an offline integrity check.
  Separate in-process enforcement from unavailable cross-process custody. Preserve
  diagnostic-only results, unavailable history/counting and M2 unverified. This
  review does not itself authorize implementation or qualify storage/device behavior.
  Dependencies: DOC-M2-COORDINATOR-ADMISSION-TRACE (done for source-only preparation).
  Completion: done in `goals.json` on `t_321431fe` for requirements review only.
  The [custody requirements](docs/quality/2026-10-06-m2-custody-proof-review.md)
  bind 38 files, 13 citation ranges and four local links. Read-only validation
  matches these inputs. Retained offline controls test artifact integrity, not
  executable custody. Independent final approval and M2 remain unverified.

- [x] **QA-M2-CUSTODY-ORDERING-ORACLE** — Goal: M2. Run or add an isolated
  deterministic custody-ordering oracle before runtime integration.
  Payoff: replace specified ordering observations with executed fake-only evidence.
  Sources: [custody requirements](docs/quality/2026-10-06-m2-custody-proof-review.md#typed-issuance-and-custody-contract)
  and [observation matrix](docs/quality/2026-10-06-m2-custody-proof-review.md#required-deterministic-observation-matrix).
  Scope: `test/tooling/` fake-only proof of registration, fixed prior read,
  byte-exact retention and explicit writer release. Reuse the existing envelope
  validator without changing it. Exclude runtime main, secure sink, production
  composition, packaging, devices, real storage, transport, secrets, network,
  new counting authority and upstream edits. This task does not activate the
  proposed coordinator or authorize migration of public runtime constructors.
  Acceptance: execute completer-controlled OBS-PAIR, OBS-REPLAY, OBS-REGISTER,
  OBS-RELEASE, OBS-READRACE, OBS-RETAINRACE and OBS-TWOWRITERS controls with
  separate inspection/readback counters. Reject premature release, competing
  registration and revoked late completion. Prove exact retained bytes precede
  the first separately authorized fake write. Run changed-file formatting,
  scoped analysis and `flutter test --no-pub test/tooling/m2_receipt_admission_test.dart`.
  Retain commands, exits and input fingerprints. Report this as an isolated
  in-process oracle, not runtime enforcement, cross-process custody or Android
  acceptance. Keep unavailable history/counting and M2 unverified; identify the
  remaining full caller-closure proof separately without expanding this task.
  Dependencies: DOC-M2-CUSTODY-PROOF-REVIEW (done for requirements review).
  Completion: done in `goals.json` on `t_40dcd771`. The
  [inspected release evidence](docs/quality/2026-10-06-m2-custody-ordering-oracle.md)
  records 18 fake-only passes. Seven selected source hashes and the authored test
  hash match; the test matches the committed branch blob. Independent final
  approval, runtime enforcement and Android M2 remain unverified. Do not repeat
  this completed oracle as a substitute for runtime caller-closure proof.

- [x] **DOC-M2-RUNTIME-CALLER-CLOSURE** — Goal: M2. Prepare complete runtime
  caller-closure proof after the isolated custody oracle.
  Payoff: identify the smallest missing executable boundary check before integration.
  Sources: [completed oracle and remaining limits](docs/quality/2026-10-06-m2-custody-ordering-oracle.md#qualification-limits-and-next-proof)
  and [custody requirements](docs/quality/2026-10-06-m2-custody-proof-review.md#complete-present-caller-closure).
  Scope: source-only trace of the QA entrypoint, observer, journal, sink, all local
  callers, imports, exports, parts and public constructors. Exclude source/test
  changes, runtime activation, installed authority, devices, secure storage access,
  packaging, transport, credentials, network and upstream edits.
  Acceptance: map every path that can construct or reach a runtime writer, identify
  fake-authority injection and bypass paths, and name the smallest executable
  no-bypass regression with an observable refusal before I/O. Distinguish existing
  tests from missing proof. Identify any required caller/test scope amendment;
  do not preserve unsafe public construction merely to avoid migration. Bind the
  report to selected source hashes and validate its local links and citations.
  Inspection does not enforce custody or qualify Android; keep M2 unverified and
  unavailable history/counting explicit. No coordinator or issuer is authorized.
  Dependencies: QA-M2-CUSTODY-ORDERING-ORACLE (done for fake-only execution).
  Ownership: completed source-only delivery by t_481b1474; see the
  [caller-closure report](docs/quality/2026-10-06-m2-runtime-caller-closure.md).
  A read-only integrity check matches 662 scanned files, four direct Dart consumers
  and 188 local dependencies. Retained artifact checks reject six isolated changes.
  This predecessor report did not execute runtime refusal or compiler closure.
  QA-M2-DEFAULT-REFUSAL now covers those bounded checks; installed custody and
  Android remain unverified.
  Independent final approval is not established by these receipts.

- [x] **QA-M2-DEFAULT-REFUSAL** — Goal: M2. Prove the actual QA bootstrap and
  public library surface refuse unadmitted runtime construction before I/O.
  Payoff: replace source-only bypass analysis with one discriminating executable
  regression slice, without admitting installed authority or positive runtime work.
  Source: [specified runtime regressions](docs/quality/2026-10-06-m2-runtime-caller-closure.md#smallest-future-executable-no-bypass-regression)
  and [caller/test amendment](docs/quality/2026-10-06-m2-runtime-caller-closure.md#required-future-amendment-and-scope-limits).
  Scope: bounded QA entrypoint/support privacy and default-refusal migration,
  existing observer/admission tests and isolated external-consumer compile probes.
  Include both existing test consumers in the engineering scope review before
  migration. Exclude installed issuer/coordinator activation, secure-plugin I/O,
  product-store migration, packaging, devices, private transport, credentials,
  network, Agent changes and live counting. This documentation pass implements none.
  Acceptance: execute REG-DEFAULT/INJECTION/API/POSITIVE against the actual boundary.
  Absent admission refuses before sink/plugin, journal, observer, channel/delegate
  construction or runApp, including delayed callbacks; all I/O counters remain zero.
  External consumers cannot construct raw sinks or inject arbitrary journals/authority;
  allowed metadata still compiles. Preserve fake-only ordering as a positive control.
  Isolated gate-removal, constructor-reopening and foreign-writer mutations must
  fail their intended invariant. Run scoped formatting, analysis, both tooling
  tests and compile probes; retain exact commands, exits and input fingerprints.
  Passing source-level refusal does not prove installed or cross-process custody,
  Android death, admitted history or authoritative counts. Keep M2 unverified.
  Dependencies: DOC-M2-RUNTIME-CALLER-CLOSURE (done for preparation).
  Delivered source-level refusal and private fake diagnostics on `t_41606eec`;
  [executed evidence](docs/quality/2026-10-06-m2-default-refusal.md).
  M2 remains unverified; installed/Android/cross-process qualification is absent.
  All 13 authored fingerprints match the retained validation receipt. Its logs
  record 44 tooling passes, 60 negative consumers, four positive controls and three
  discriminating isolated mutations. This pass inspects receipts, not new tests.
  Ownership: completed bounded delivery on t_41606eec; independent final approval
  remains unverified. Do not duplicate its review or reopen this completed slice.

- [x] **DOC-M2-REFUSAL-CONTINUATION** — Goal: M2. Reassess the named-device
  recovery prerequisites after the QA entrypoint became refusal-only.
  Payoff: identify one safe next proof without treating removed observer APIs as usable.
  Sources: [delivered refusal and limits](docs/quality/2026-10-06-m2-default-refusal.md#scope-and-predecessor-limits)
  and [named-device scenario](docs/quality/2026-10-06-m2-continuity-baseline.md#exactly-one-future-scenario-android-m2-death-complete-01).
  Scope: source-only delta of existing preflight, packaging, storage, receipt custody,
  history admission and counting prerequisites against the current public boundary.
  Exclude code/test edits, authority issuance, coordinator/transport activation,
  plugin/storage I/O, builds, installs, device actions, credentials and live requests.
  Acceptance: bind a bounded updated preflight to current sources, distinguish
  removed versus still available seams, and name exactly one missing prerequisite
  with an observable proof and explicit implementation/review limits. Preserve
  runtime `not_admitted`, `continuation_unavailable`, `qualifies=false` and the
  authoritative counting gap. Inspection must not claim Android or M2 acceptance.
  Dependencies: QA-M2-DEFAULT-REFUSAL (done for offline source-level enforcement).
  Ownership: completed source-only delivery by t_c799c475; see the
  [updated preflight](docs/quality/2026-10-06-m2-refusal-continuation-preflight.md).
  Its retained receipt records 36 source fingerprints, seven links and 25 citation
  ranges passing. Current source and document hashes match that receipt.
  This completion proves neither installed authority nor Android recovery.
  Continue with DOC-M2-ISSUER-EVIDENCE-CONTRACT below; do not repeat this preflight.

- [x] **DOC-M2-ISSUER-EVIDENCE-CONTRACT** — Goal: M2. Prepare the source-only
  installed QA issuer admission evidence contract identified by the updated preflight.
  Payoff: define independently sourced admission proof without activating runtime.
  Source: [one missing prerequisite](docs/quality/2026-10-06-m2-refusal-continuation-preflight.md#exactly-one-missing-prerequisite).
  Scope: one proposed admission dossier and fail-closed acceptance matrix only.
  Exclude code/tests/runners/manifests, authority issuance, bootstrap inputs,
  coordinators, transport selection, storage I/O, builds, installs, devices,
  credentials, live requests and upstream edits.
  Acceptance: map package/entrypoint/closure, target/storage incarnation,
  attempt/generation, freshness/revocation, separate read/write rights and exclusive
  receipt custody to independent measurement owners and exact provenance.
  Mark absent evidence UNAVAILABLE; the current refusal-only candidate must yield
  NOT_ADMITTED. Distinguish source identity from APK, installed and OS evidence.
  Keep authoritative counts and Android M2 unverified. The proposed contract
  grants no implementation or runtime rights, even after bounded document review.
  Dependencies: DOC-M2-REFUSAL-CONTINUATION (done). Source-only delivery by
  t_620a6d33: [admission evidence dossier](docs/quality/2026-10-06-m2-issuer-evidence-contract.md).
  Its document checks bind 18 source fingerprints, seven initial links and 13
  citation ranges, ten required installed facts and fifteen refusal rows.
  Current candidate is NOT_ADMITTED; no issuer or runtime rights are granted.
  Android/full M2 remain unverified; native same-card review follows delivery.

- [x] **DOC-M2-PACKAGE-PROVENANCE** — Goal: M2. Completed source-only
  F01/F02 verification brief on t_7e4e424a. Source:
  [package provenance brief](docs/quality/2026-10-06-m2-package-provenance.md).
  Scope: configured versus measured identity, mode, target and delivered closure;
  no artifact, build, device, storage or runtime operation. Retained validation
  records 31 source fingerprints and lexical closure/link checks, not APK proof.
  Independent final approval remains unverified. F01/F02 remain UNAVAILABLE;
  candidate NOT_ADMITTED and Android/full M2 remain unverified.
  Dependencies: DOC-M2-ISSUER-EVIDENCE-CONTRACT (done for source-only delivery).
  Ownership: ledger records this bounded task done; no card transition here.

- [x] **DOC-M2-MANIFEST-ASSESSMENT-CONTRACT** — Goal: M2. Delivered the
  [proposed partial-F01 contract](docs/quality/2026-10-06-m2-manifest-assessment-contract.md)
  on t_bcab1f7e. Its retained verify and altered-document receipts record exit 0;
  all 17 source/authored fingerprints match this pass's inspected snapshot.
  These checks prove document integrity, not inspector enforcement or artifact facts.
  Independent final approval remains unverified. F01/F02 remain UNAVAILABLE;
  candidate NOT_ADMITTED and Android/full M2 remain unverified.
  Dependencies: DOC-M2-PACKAGE-PROVENANCE (done for source-only delivery).
  Ownership: ledger records this bounded task done; no card transition here.

- [x] **DOC-M2-INSPECTOR-ISOLATION-PREFLIGHT** — Goal: M2. Assess the
  delivered manifest contract's tool and isolation prerequisites before implementation.
  Payoff: identify a concrete enforcement path or precise unavailable prerequisites,
  rather than mistake document checks for safe artifact measurement.
  Sources: [reviewed prerequisites](docs/quality/2026-10-06-m2-manifest-assessment-contract.md#reviewed-prerequisites-for-a-future-assessment),
  [hard bounds](docs/quality/2026-10-06-m2-manifest-assessment-contract.md#isolation-and-explicit-hard-bounds)
  and [M2 exit evidence](ROADMAP.md#m2--leave-and-return-without-losing-ownership).
  Scope: source/documentation inspection and harmless read-only tooling/OS metadata
  checks for a pinned public SDK closure, immutable input and unprivileged isolation.
  Exclude private-state searches, APK acquisition/inspection, inspector execution,
  source/tests, provisioning, installs, sudo, builds, devices, network and runtime activation.
  Acceptance: map each time/memory/process/output/parser/cleanup bound to its actual
  enforcement prerequisite. Record unavailable facts without invented pins or relaxed
  limits. Name one bounded next proof slice, not permission to execute it.
  Dependencies: DOC-M2-MANIFEST-ASSESSMENT-CONTRACT (done for source-only delivery).
  Ownership: delivered on t_909a35ba in the
  [bounded preflight](docs/quality/2026-10-06-m2-inspector-isolation-preflight.md).
  Public tool/OS metadata and launcher source were read without inspector execution.
  Full approved SDK closure, immutable input and isolation enforcement remain
  UNAVAILABLE; F01/F02 and Android/full M2 remain unverified. Native same-card
  review follows this source/metadata-only delivery.

- [x] **DOC-M2-SYNTHETIC-ISOLATION-CONTRACT** — Goal: M2. Review the proposed
  synthetic isolation/immutable-input proof before adapter implementation.
  Payoff: identify enforceable bounds or precise refusal conditions without
  confusing public metadata with sandbox qualification.
  Sources: [next proof slice](docs/quality/2026-10-06-m2-inspector-isolation-preflight.md#exactly-one-next-proof-slice)
  and [prerequisite map](docs/quality/2026-10-06-m2-inspector-isolation-preflight.md#candidate-enforcement-path-and-prerequisite-map).
  Scope: one source-only contract for deterministic public non-APK controls,
  fixed adapter/closure identity, immutable input and descendant-inclusive limits.
  Exclude adapter/source/test implementation, sandbox activation, SDK/JVM execution,
  artifact acquisition, private discovery, installs, sudo, network, devices,
  credentials and runtime authority. Do not relax predecessor limits.
  Acceptance: map each proposed control to an observable enforced bound or
  UNAVAILABLE/ISOLATION_FAILURE result. Resolve exact aggregate CPU semantics,
  scratch inode policy and kill/reap evidence before any executable follow-up.
  Preserve NOT_ADMITTED, F01/F02 UNAVAILABLE and Android/full M2 unverified.
  Dependencies: DOC-M2-INSPECTOR-ISOLATION-PREFLIGHT (done for bounded delivery).
  Ownership: source-only contract delivered on t_8ce3dc30 in the
  [synthetic proof contract](docs/quality/2026-10-06-m2-synthetic-isolation-contract.md).
  Exact CPU enforcement, additional inode-policy review and descendant kill/reap
  remain UNAVAILABLE. Document-integrity checks do not qualify isolation or APKs;
  native same-card review follows delivery, not adapter approval.

- [x] **DOC-M2-CPU-ENFORCEMENT-FEASIBILITY** — Goal: M2. Assess one exact
  cumulative CPU enforcement prerequisite before synthetic adapter execution.
  Payoff: determine whether the proposed proof can enforce its unchanged ceiling,
  rather than repeat contract preparation or mistake counter polling for enforcement.
  Sources: [CPU semantics](docs/quality/2026-10-06-m2-synthetic-isolation-contract.md#unchanged-limits-and-exact-cumulative-cpu-semantics)
  and [conditional next proof](docs/quality/2026-10-06-m2-synthetic-isolation-contract.md#exactly-one-smallest-conditional-next-proof-slice).
  Scope: source/documentation-only mechanism assessment against the delivered
  contract, including trusted-worker, descendant and termination accounting.
  Exclude implementation, control execution, SDK/JVM use, APK access, provisioning,
  installs, sudo, devices, credentials, runtime activation and relaxed limits.
  Acceptance: identify an evidenced mechanism and its enforcement assumptions,
  or document why none is established. Distinguish aggregate consumption from rate,
  per-process limits and post-exceedance observation. Preserve UNAVAILABLE and
  NOT_ADMITTED without a complete proof; Android/full M2 remain unverified.
  Dependencies: DOC-M2-SYNTHETIC-ISOLATION-CONTRACT (done for source-only delivery).
  Ownership: source-only delivery completed on t_d2b9b4db; see the
  [feasibility assessment](docs/quality/2026-10-06-m2-cpu-enforcement-feasibility.md).
  The reviewed interfaces do not establish the exact inclusive CPU budget.
  Mechanism NOT_ESTABLISHED; prelaunch UNAVAILABLE / cpu_budget_unavailable.
  No mechanism/control execution or independent final approval is established.
  Continue with DOC-M2-CPU-ENVELOPE-PROOF; no adapter execution is authorized.

- [ ] **DOC-M6-CHECKER-NODE22** — Goal: M6. Prove the delivered offline
  candidate comparator on the documented Node.js 22 baseline.
  Payoff: distinguish the retained Node v26.7.0 synthetic pass from baseline support.
  Sources: [checkout checks](docs/runbooks/offline-release-candidate-comparison.md#checkout-delivery-and-verification)
  and [candidate admission](docs/quality/2026-10-06-m6-candidate-admission.md#required-public-inputs).
  Scope: existing comparator/verifier and their isolated synthetic tests using
  already available user-space tooling. Exclude installs, public-candidate search,
  private state, artifact extraction/execution, signing, network and publication.
  Acceptance: record the actual Node version, run the runbook's three syntax checks
  and both test files on Node.js 22, and retain exits, counts and input fingerprints.
  If that runtime is absent, inspect baseline compatibility and identify the exact
  unexecuted check without relabeling another version's pass. Keep candidate,
  signatures, M1–M5 and installed recovery unverified; record their next proof slice.
  Dependencies: DOC-M6-OFFLINE-CHECKER (done). Ownership: unclaimed in this index;
  check existing tracker ownership before execution.

- [ ] **DOC-API-DEVICE-SELF-CONFORMANCE** — Goal: API-CONFORMANCE. Verify
  GET and DELETE `/v2/devices/self` against the code-first snapshot.
  Payoff: extend discovery-only conformance to one exact authorization boundary.
  Sources: [OpenAPI snapshot](docs/api/wing-link.openapi.yaml),
  [handlers](wing_link/internal/app/serve.go) and
  [nearest tests](wing_link/internal/app/serve_test.go).
  Scope: one management-route family, existing tooling, in-process disposable
  recorder fixtures and documentation corrections. Exclude live listeners,
  personal credentials, peer administration, API redesign and new dependencies.
  Acceptance: execute schema-to-handler checks for self-read/revoke, exact grants,
  pending/revoked authority and method/protocol errors. Reject an isolated incorrect
  schema copy; keep generated credentials and fixture bodies out of receipts.
  Record exact commands, source hashes and limits. Other families, full OpenAPI
  standards validation, TLS and live transport remain unverified.
  Dependencies: DOC-API-CONFORMANCE (done). Ownership: unclaimed in this index;
  verify tracker ownership before execution.

### Dependency-ordered successor slices

These distinct slices preserve two unfinished tasks per incomplete goal.
They are queued, not ready while their predecessor is unfinished.
Missing contracts remain unavailable; preparation does not authorize activation.
Do not start duplicate work or repeat completed proofs with unchanged inputs.

- [ ] **DOC-M2-CPU-ENVELOPE-PROOF** — Goal: M2. Assess the fixed single-CPU
  early-stop worst-case envelope. Payoff: test the delivered assessment's one
  conditional source-only proof seam instead of rerunning unproven controls.
  Source: [conditional proof seam](docs/quality/2026-10-06-m2-cpu-enforcement-feasibility.md#outcome-and-exactly-one-conditional-next-proof-seam).
  Scope: source-only proof for a fixed fair-class, single-CPU cpu.max construction
  and trusted closure. Exclude implementation, provisioning, kernel edits, adapter
  or control execution, SDK/APK access, devices, private state and relaxed limits.
  Acceptance: justify finite inclusive B/L/K bounds from before setup through
  teardown satisfying the unchanged inequality, or identify the first unbounded
  term. Account for replenishment and scheduler/accounting granularity. Retain
  UNAVAILABLE and NOT_ADMITTED without complete proof; M2 stays unverified.
  Dependencies: DOC-M2-CPU-ENFORCEMENT-FEASIBILITY (done for source-only delivery).
  Ownership: in_progress in goals.json; do not dispatch duplicate work.
  Verify tracker ownership and continuation leases before any continuation.

- [ ] **DOC-M2-INODE-POLICY-EVIDENCE** — Goal: M2. Assess the additional scratch
  inode-policy prerequisite. Payoff: preserve the separate admission obligation
  even if the conditional CPU proof supplies a finite envelope.
  Sources: [unchanged prerequisites](docs/quality/2026-10-06-m2-cpu-enforcement-feasibility.md#outcome-and-exactly-one-conditional-next-proof-seam)
  and [synthetic contract](docs/quality/2026-10-06-m2-synthetic-isolation-contract.md).
  Scope: source-only inode-accounting and descendant/cleanup policy review.
  Exclude adapter implementation, control execution, APKs, provisioning, private
  state, runtime activation and authority or limit changes.
  Acceptance: map the proposed additional inode policy to a reviewed bounded
  enforcement contract or UNAVAILABLE. Do not equate CPU proof with inode,
  immutable custody, cleanup or Android qualification. M2 remains unverified.
  Dependencies: DOC-M2-CPU-ENVELOPE-PROOF; not eligible until that task is done.
  Ownership: unclaimed here; verify tracker and continuation leases first.

- [ ] **DOC-SECURITY-REPLAY-EVIDENCE** — Goal: SECURITY. Map one changed-payload replay rejection.
  Payoff: preserve a distinct remaining proof slice after the current task.
  Source: [SECURITY](docs/product/prd.md#product-rules).
  Scope: read-only source, nearest tests and sanitized receipt inspection for this
  outcome. Exclude implementation, upstream edits, secrets, installs and live actions.
  Acceptance: Exact device/resource/payload binding must reject changed retries in existing Wing Link tests or receipts.
  Dependencies: DOC-SECURITY-CURRENT-BOUNDARY; not eligible until that task is done.
  Ownership: unclaimed in this index; verify tracker and continuation leases first.

- [ ] **DOC-M3-ROLLBACK-EVIDENCE** — Goal: M3. Attribute one failed new-profile setup rollback.
  Payoff: preserve a distinct remaining proof slice after the current task.
  Source: [M3](ROADMAP.md#m3--trusted-onboarding-into-a-useful-profile-and-workspace).
  Scope: read-only source, nearest tests and sanitized receipt inspection for this
  outcome. Exclude implementation, upstream edits, secrets, installs and live actions.
  Acceptance: Find source-bound cleanup and preserved existing-profile identity in existing Go tests/receipts, or name the missing proof. No profile creation.
  Dependencies: DOC-M3-CONTRACT-CHECKPOINT; not eligible until that task is done.
  Ownership: unclaimed in this index; verify tracker and continuation leases first.

- [ ] **DOC-M3-PROJECT-ASSIGNMENT-CONTRACT** — Goal: M3-PROJECT. Trace primary-folder assignment separately from creation.
  Payoff: preserve a distinct remaining proof slice after the current task.
  Source: [M3-PROJECT](docs/product/prd.md#core-journeys).
  Scope: read-only source, nearest tests and sanitized receipt inspection for this
  outcome. Exclude implementation, upstream edits, secrets, installs and live actions.
  Acceptance: Name exact Project/profile identity, approved-handle containment and revision semantics, or the absent operation. No assignment.
  Dependencies: DOC-M3-PROJECT-CONTRACT; not eligible until that task is done.
  Ownership: unclaimed in this index; verify tracker and continuation leases first.

- [ ] **DOC-M3-PROVIDER-REMOVAL-CONTRACT** — Goal: M3-PROVIDER. Trace credential removal separately from replacement.
  Payoff: preserve a distinct remaining proof slice after the current task.
  Source: [M3-PROVIDER](docs/adr/api-and-state.md#required-agent-owned-mutation-contract).
  Scope: read-only source, nearest tests and sanitized receipt inspection for this
  outcome. Exclude implementation, upstream edits, secrets, installs and live actions.
  Acceptance: Name expected revision, secret-safe errors and unknown-outcome reconciliation, or the absent operation. No credential access or writes.
  Dependencies: DOC-M3-PROVIDER-CONTRACT; not eligible until that task is done.
  Ownership: unclaimed in this index; verify tracker and continuation leases first.

- [ ] **DOC-M4-SCHEDULE-INVENTORY-EVIDENCE** — Goal: M4. Attribute one scheduled-job inventory failure journey.
  Payoff: preserve a distinct remaining proof slice after the current task.
  Source: [M4](ROADMAP.md#m4--discover-and-administer-supported-agent-work).
  Scope: read-only source, nearest tests and sanitized receipt inspection for this
  outcome. Exclude implementation, upstream edits, secrets, installs and live actions.
  Acceptance: Map Schedules owner-change and denied-read outcomes to matching widget/browser receipts or one missing oracle. Preserve Tools qualification and read-only inventory.
  Dependencies: DOC-M4-INVENTORY-EVIDENCE; not eligible until that task is done.
  Ownership: unclaimed in this index; verify tracker and continuation leases first.

- [ ] **DOC-M4-DISCOVERY-SELECTION-CONTRACT** — Goal: M4-DISCOVER. Trace catalog selection separately from search.
  Payoff: preserve a distinct remaining proof slice after the current task.
  Source: [M4-DISCOVER](docs/product/hermes-desktop-parity.md#statuses).
  Scope: read-only source, nearest tests and sanitized receipt inspection for this
  outcome. Exclude implementation, upstream edits, secrets, installs and live actions.
  Acceptance: Distinguish local selection from installation, with exact identity/grants or absent operation. No installation or shadow catalog.
  Dependencies: DOC-M4-CONTRACT-CHECKPOINT; not eligible until that task is done.
  Ownership: unclaimed in this index; verify tracker and continuation leases first.

- [ ] **DOC-M5-LARGE-TEXT-EVIDENCE** — Goal: M5. Attribute one 200-percent-text message-action journey.
  Payoff: preserve a distinct remaining proof slice after the current task.
  Source: [M5](ROADMAP.md#m5--safely-take-away-output-with-native-accessible-interaction).
  Scope: read-only source, nearest tests and sanitized receipt inspection for this
  outcome. Exclude implementation, upstream edits, secrets, installs and live actions.
  Acceptance: Identify source-bound keyboard focus and reachable copy/export controls or a missing deterministic oracle. Do not label this TalkBack or device qualification.
  Dependencies: DOC-M5-ANDROID-FIXTURE; not eligible until that task is done.
  Ownership: unclaimed in this index; verify tracker and continuation leases first.

- [ ] **DOC-M6-INTEGRATED-RECEIPT-GAP** — Goal: M6. Map one same-artifact install-to-recovery receipt gap.
  Payoff: preserve a distinct remaining proof slice after the current task.
  Source: [M6](ROADMAP.md#m6--deliver-an-integrated-qualified-alpha).
  Scope: read-only source, nearest tests and sanitized receipt inspection for this
  outcome. Exclude implementation, upstream edits, secrets, installs and live actions.
  Acceptance: Identify the first missing Android workflow binding across release receipts and M1-M5. No candidate acquisition, build, install, signing or publication.
  Dependencies: DOC-M6-CHECKER-NODE22; not eligible until that task is done.
  Ownership: unclaimed in this index; verify tracker and continuation leases first.

- [ ] **DOC-API-PROTOCOL-ERROR-EVIDENCE** — Goal: API-CONFORMANCE. Map profile-list protocol error precedence.
  Payoff: preserve a distinct remaining proof slice after the current task.
  Source: [API-CONFORMANCE](docs/api/wing-link.openapi.yaml).
  Scope: read-only source, nearest tests and sanitized receipt inspection for this
  outcome. Exclude implementation, upstream edits, secrets, installs and live actions.
  Acceptance: Compare code-first schema and existing dispatch tests for omitted, supported and unsupported generations with method/auth errors. Record conformance proof or the exact unexecuted check; no sockets.
  Dependencies: DOC-API-DEVICE-SELF-CONFORMANCE; not eligible until that task is done.
  Ownership: unclaimed in this index; verify tracker and continuation leases first.

- [ ] **DOC-NATIVE-FAILURE-BOUNDARY** — Goal: NATIVE-INTEGRATION. Review failure containment for the first bounded native operation.
  Payoff: preserve a distinct remaining proof slice after the current task.
  Source: [NATIVE-INTEGRATION](docs/adr/client.md#decision).
  Scope: read-only source, nearest tests and sanitized receipt inspection for this
  outcome. Exclude implementation, upstream edits, secrets, installs and live actions.
  Acceptance: After operation review, specify cancellation, unknown-outcome and removal criteria against living ADRs. Preparation supplies no native activation rights.
  Dependencies: DOC-NATIVE-DESIGN-REVIEW; not eligible until that task is done.
  Ownership: unclaimed in this index; verify tracker and continuation leases first.

- [ ] **DOC-PARITY-PLATFORM-DEVIATIONS** — Goal: PARITY. Index one compact adaptation against its Desktop outcome.
  Payoff: preserve a distinct remaining proof slice after the current task.
  Source: [PARITY](docs/product/hermes-desktop-parity.md#reference-and-evidence-boundary).
  Scope: read-only source, nearest tests and sanitized receipt inspection for this
  outcome. Exclude implementation, upstream edits, secrets, installs and live actions.
  Acceptance: Map one mobile adaptation to its Desktop behavior and existing task/receipt. Record the deviation without duplicating component work or claiming platform support.
  Dependencies: DOC-PARITY-COVERAGE; not eligible until that task is done.
  Ownership: unclaimed in this index; verify tracker and continuation leases first.

- [ ] **DOC-PARITY-RECENTS-REFERENCE** — Goal: PARITY-COMPOSITION. Compare grouped-recents ownership separately from profile-footer composition.
  Payoff: preserve a distinct remaining proof slice after the current task.
  Source: [PARITY-COMPOSITION](docs/product/hermes-desktop-parity.md#reference-and-evidence-boundary).
  Scope: read-only source, nearest tests and sanitized receipt inspection for this
  outcome. Exclude implementation, upstream edits, secrets, installs and live actions.
  Acceptance: Record grouping, ordering, open identity and stale-owner requirements from existing reference/current sources. No recents or tab implementation.
  Dependencies: DOC-PARITY-COMPOSITION; not eligible until that task is done.
  Ownership: unclaimed in this index; verify tracker and continuation leases first.

- [ ] **DOC-PARITY-TAB-RECONNECT-CONTRACT** — Goal: PARITY-TABS. Trace reconnect for two distinct session-owned tab runs.
  Payoff: preserve a distinct remaining proof slice after the current task.
  Source: [PARITY-TABS](docs/product/hermes-desktop-parity.md#reference-and-evidence-boundary).
  Scope: read-only source, nearest tests and sanitized receipt inspection for this
  outcome. Exclude implementation, upstream edits, secrets, installs and live actions.
  Acceptance: Name authoritative readback and zero replay for one disconnected tab while preserving the other. No tab implementation or run mutation.
  Dependencies: DOC-PARITY-TAB-CONTRACT; not eligible until that task is done.
  Ownership: unclaimed in this index; verify tracker and continuation leases first.

- [ ] **DOC-ACCOUNT-REVOCATION-EVIDENCE** — Goal: ACCOUNT. Map account expiry and logout separately from acquisition.
  Payoff: preserve a distinct remaining proof slice after the current task.
  Source: [ACCOUNT](docs/product/hermes-desktop-parity.md#statuses).
  Scope: read-only source, nearest tests and sanitized receipt inspection for this
  outcome. Exclude implementation, upstream edits, secrets, installs and live actions.
  Acceptance: Name exact fail-closed expiry/revocation proof or unavailable authority. No provisioning, wallet use or secret acquisition.
  Dependencies: DOC-ACCOUNT-CONTRACT; not eligible until that task is done.
  Ownership: unclaimed in this index; verify tracker and continuation leases first.

- [ ] **DOC-ARTIFACT-INERT-PREVIEW-EVIDENCE** — Goal: ARTIFACTS. Map hostile-content rejection for one permitted artifact type.
  Payoff: preserve a distinct remaining proof slice after the current task.
  Source: [ARTIFACTS](docs/product/hermes-desktop-parity.md#statuses).
  Scope: read-only source, nearest tests and sanitized receipt inspection for this
  outcome. Exclude implementation, upstream edits, secrets, installs and live actions.
  Acceptance: Identify inert preview and denial/cancel oracles or an absent allowed retrieval contract. Folder grants confer no artifact rights; no content requests.
  Dependencies: DOC-ARTIFACT-CONTRACT; not eligible until that task is done.
  Ownership: unclaimed in this index; verify tracker and continuation leases first.

- [ ] **DOC-CHAT-TRANSCRIPT-DISCLOSURE** — Goal: CHAT-FIDELITY. Compare one reasoning/tool transcript disclosure interaction.
  Payoff: preserve a distinct remaining proof slice after the current task.
  Source: [CHAT-FIDELITY](docs/product/hermes-desktop-parity.md#reference-and-evidence-boundary).
  Scope: read-only source, nearest tests and sanitized receipt inspection for this
  outcome. Exclude implementation, upstream edits, secrets, installs and live actions.
  Acceptance: Record reference disclosure/focus/recovery behavior and one deviation. Preserve accepted bounded transcript repairs; do not repeat composer comparison.
  Dependencies: DOC-CHAT-FIDELITY-REFERENCE; not eligible until that task is done.
  Ownership: unclaimed in this index; verify tracker and continuation leases first.

- [ ] **DOC-DESKTOP-UNINSTALL-EVIDENCE** — Goal: DESKTOP-DELIVERY. Map one Linux uninstall and retained-state evidence gap.
  Payoff: preserve a distinct remaining proof slice after the current task.
  Source: [DESKTOP-DELIVERY](docs/product/hermes-desktop-parity.md#statuses).
  Scope: read-only source, nearest tests and sanitized receipt inspection for this
  outcome. Exclude implementation, upstream edits, secrets, installs and live actions.
  Acceptance: Identify named-target uninstall proof and documented data-retention limits, or the missing procedure. No installs, service changes or deletion.
  Dependencies: DOC-DESKTOP-DELIVERY-EVIDENCE; not eligible until that task is done.
  Ownership: unclaimed in this index; verify tracker and continuation leases first.

- [ ] **DOC-DIAGNOSTICS-BACKUP-CONTRACT** — Goal: DIAGNOSTICS-RECOVERY. Trace atomic backup/import separately from diagnostics reads.
  Payoff: preserve a distinct remaining proof slice after the current task.
  Source: [DIAGNOSTICS-RECOVERY](docs/product/hermes-desktop-parity.md#statuses).
  Scope: read-only source, nearest tests and sanitized receipt inspection for this
  outcome. Exclude implementation, upstream edits, secrets, installs and live actions.
  Acceptance: Name a fixed typed restore operation and validation/rollback limits, or its absence. No backup, restore, private-file reads or secret exports.
  Dependencies: DOC-DIAGNOSTICS-CONTRACT; not eligible until that task is done.
  Ownership: unclaimed in this index; verify tracker and continuation leases first.

- [ ] **DOC-M4-KANBAN-PAGINATION-EVIDENCE** — Goal: M4-KANBAN. Map stale-owner pagination for a board read.
  Payoff: preserve a distinct remaining proof slice after the current task.
  Source: [M4-KANBAN](docs/product/hermes-desktop-parity.md#statuses).
  Scope: read-only source, nearest tests and sanitized receipt inspection for this
  outcome. Exclude implementation, upstream edits, secrets, installs and live actions.
  Acceptance: Specify bounded pagination and revocation/owner-change expected outcomes or absent authoritative pagination. No writes or shadow cards.
  Dependencies: DOC-M4-KANBAN-CONTRACT; not eligible until that task is done.
  Ownership: unclaimed in this index; verify tracker and continuation leases first.

- [ ] **DOC-M4-MCP-CONFIG-CONTRACT** — Goal: M4-MCP. Trace one MCP configuration read separately from toolset toggling.
  Payoff: preserve a distinct remaining proof slice after the current task.
  Source: [M4-MCP](docs/product/hermes-desktop-parity.md#statuses).
  Scope: read-only source, nearest tests and sanitized receipt inspection for this
  outcome. Exclude implementation, upstream edits, secrets, installs and live actions.
  Acceptance: Name profile identity, output redaction, bounds and exact grant, or the absent read. No MCP installation, config write or arbitrary commands.
  Dependencies: DOC-M4-MCP-CONTRACT; not eligible until that task is done.
  Ownership: unclaimed in this index; verify tracker and continuation leases first.

- [ ] **DOC-M4-MEMORY-CAPACITY-CONTRACT** — Goal: M4-MEMORY. Trace memory capacity/provider reads separately from entry reads.
  Payoff: preserve a distinct remaining proof slice after the current task.
  Source: [M4-MEMORY](docs/product/hermes-desktop-parity.md#statuses).
  Scope: read-only source, nearest tests and sanitized receipt inspection for this
  outcome. Exclude implementation, upstream edits, secrets, installs and live actions.
  Acceptance: Distinguish entry inventory from capacity/provider reporting and exact authorization, or absent operations. No memory writes or shadow state.
  Dependencies: DOC-M4-MEMORY-CONTRACT; not eligible until that task is done.
  Ownership: unclaimed in this index; verify tracker and continuation leases first.

- [ ] **DOC-M4-HOST-LIFECYCLE-EVIDENCE** — Goal: M4-PLATFORMS. Attribute one Wing Link host-lifecycle approval boundary.
  Payoff: preserve a distinct remaining proof slice after the current task.
  Source: [M4-PLATFORMS](docs/product/hermes-desktop-parity.md#statuses).
  Scope: read-only source, nearest tests and sanitized receipt inspection for this
  outcome. Exclude implementation, upstream edits, secrets, installs and live actions.
  Acceptance: Separate messaging-platform administration from typed host restart approval, health and rollback receipts. Name missing proof without service actions.
  Dependencies: DOC-M4-PLATFORM-CONTRACT; not eligible until that task is done.
  Ownership: unclaimed in this index; verify tracker and continuation leases first.

- [ ] **DOC-M4-SCHEDULE-DELIVERY-CONTRACT** — Goal: M4-SCHEDULES. Trace one schedule-delivery configuration operation.
  Payoff: preserve a distinct remaining proof slice after the current task.
  Source: [M4-SCHEDULES](docs/product/hermes-desktop-parity.md#statuses).
  Scope: read-only source, nearest tests and sanitized receipt inspection for this
  outcome. Exclude implementation, upstream edits, secrets, installs and live actions.
  Acceptance: Name exact job/profile identity, revision and write-only credential requirements or the absent operation. No job execution, delivery or credentials.
  Dependencies: DOC-M4-SCHEDULE-CONTRACT; not eligible until that task is done.
  Ownership: unclaimed in this index; verify tracker and continuation leases first.

- [ ] **DOC-OFFICE-ACCESSIBLE-EQUIVALENT** — Goal: OFFICE. Map keyboard focus for existing 2D Office activation.
  Payoff: preserve a distinct remaining proof slice after the current task.
  Source: [OFFICE](docs/product/hermes-desktop-parity.md#statuses).
  Scope: read-only source, nearest tests and sanitized receipt inspection for this
  outcome. Exclude implementation, upstream edits, secrets, installs and live actions.
  Acceptance: Identify source-bound keyboard activation and owner-change checks or a missing oracle. No 3D dependency, account work or new host operation.
  Dependencies: DOC-OFFICE-REFERENCE; not eligible until that task is done.
  Ownership: unclaimed in this index; verify tracker and continuation leases first.

- [ ] **DOC-PERSONA-CONFLICT-EVIDENCE** — Goal: PERSONA. Attribute persona conflict recovery separately from whitespace fidelity.
  Payoff: preserve a distinct remaining proof slice after the current task.
  Source: [PERSONA](docs/product/hermes-desktop-parity.md#statuses).
  Scope: read-only source, nearest tests and sanitized receipt inspection for this
  outcome. Exclude implementation, upstream edits, secrets, installs and live actions.
  Acceptance: Identify exact owner/revision, rejected-save messaging and preserved draft proof or missing oracle. No live saves or duplicate accepted repairs.
  Dependencies: DOC-PERSONA-EVIDENCE; not eligible until that task is done.
  Ownership: unclaimed in this index; verify tracker and continuation leases first.

- [ ] **DOC-BACKEND-DISCONNECT-CONTRACT** — Goal: REMOTE-BACKENDS. Trace bounded backend disconnect/recovery separately from launch.
  Payoff: preserve a distinct remaining proof slice after the current task.
  Source: [REMOTE-BACKENDS](docs/product/hermes-desktop-parity.md#statuses).
  Scope: read-only source, nearest tests and sanitized receipt inspection for this
  outcome. Exclude implementation, upstream edits, secrets, installs and live actions.
  Acceptance: Name fixed disconnect identity, unknown-outcome behavior and removal trigger or precise absence. No process launch, remote shell or caller paths.
  Dependencies: DOC-BACKEND-CONTRACT; not eligible until that task is done.
  Ownership: unclaimed in this index; verify tracker and continuation leases first.

- [ ] **DOC-SESSION-DELETE-EVIDENCE** — Goal: SESSIONS. Attribute one owner-bound session-delete confirmation journey.
  Payoff: preserve a distinct remaining proof slice after the current task.
  Source: [SESSIONS](docs/product/hermes-desktop-parity.md#statuses).
  Scope: read-only source, nearest tests and sanitized receipt inspection for this
  outcome. Exclude implementation, upstream edits, secrets, installs and live actions.
  Acceptance: Identify cancel/owner-change rejection and exact delete-count receipts or missing app-level oracle. No live deletion or replay.
  Dependencies: DOC-SESSION-ACTIONS-EVIDENCE; not eligible until that task is done.
  Ownership: unclaimed in this index; verify tracker and continuation leases first.

- [ ] **DOC-SHELL-COMPACT-RETURN-EVIDENCE** — Goal: SHELL-PERSISTENCE. Map wide-to-compact-to-wide preference preservation.
  Payoff: preserve a distinct remaining proof slice after the current task.
  Source: [SHELL-PERSISTENCE](docs/product/hermes-desktop-parity.md#reference-and-evidence-boundary).
  Scope: read-only source, nearest tests and sanitized receipt inspection for this
  outcome. Exclude implementation, upstream edits, secrets, installs and live actions.
  Acceptance: Identify no-extra-read adaptive-return evidence with preserved collapse intent or a missing oracle. Do not repeat process relaunch or redesign startup.
  Dependencies: DOC-SHELL-PERSISTENCE-EVIDENCE; not eligible until that task is done.
  Ownership: unclaimed in this index; verify tracker and continuation leases first.

- [ ] **DOC-SLASH-DENIAL-EVIDENCE** — Goal: SLASH-CATALOG. Map one unavailable slash action and its recovery.
  Payoff: preserve a distinct remaining proof slice after the current task.
  Source: [SLASH-CATALOG](docs/product/hermes-desktop-parity.md#statuses).
  Scope: read-only source, nearest tests and sanitized receipt inspection for this
  outcome. Exclude implementation, upstream edits, secrets, installs and live actions.
  Acceptance: Identify unsupported-action disclosure and zero-dispatch proof or a missing check. No new commands, shell dispatch or speculative routes.
  Dependencies: DOC-SLASH-CATALOG-CONTRACT; not eligible until that task is done.
  Ownership: unclaimed in this index; verify tracker and continuation leases first.

- [ ] **DOC-VOICE-OUTPUT-CANCEL-EVIDENCE** — Goal: VOICE. Prepare one speech-output cancellation scenario.
  Payoff: preserve a distinct remaining proof slice after the current task.
  Source: [VOICE](docs/product/prd.md#core-journeys).
  Scope: read-only source, nearest tests and sanitized receipt inspection for this
  outcome. Exclude implementation, upstream edits, secrets, installs and live actions.
  Acceptance: Name target/engine, pending-configuration cancellation and no-late-audio expected outcomes from existing TTS tests/runbooks. Preparation is not physical or acoustic qualification.
  Dependencies: DOC-VOICE-QUALIFICATION; not eligible until that task is done.
  Ownership: unclaimed in this index; verify tracker and continuation leases first.

### Additional bounded goal slices

These tasks cover previously grouped or implicit gaps. They do not replace
existing cards or grant privileged implementation authority. A missing contract
defers only that operation. Verification tasks must record executed results
before their goals can become `met`.

- [ ] **DOC-M3-PROJECT-CONTRACT** — Goal: M3-PROJECT. Trace one authoritative Project creation operation.
  Payoff: advance the named accepted outcome without duplicating existing repairs.
  Source: [M3-PROJECT](docs/product/prd.md#core-journeys).
  Scope: Project models/callers and upstream read-only contracts; exclude Agent edits, arbitrary paths, global selection and compatibility expansion.
  Acceptance: Record the exact operation/grant/identity/concurrency contract, or its absence, and one bounded next slice. Assignment and scoped Chat remain separately gated.
  Dependencies: none for this bounded evidence/contract slice. Any later runtime
  or privileged operation retains its own target, authority and consent gates.
  Ownership: unclaimed in this index; verify tracker/continuation leases first.

- [ ] **DOC-M3-PROVIDER-CONTRACT** — Goal: M3-PROVIDER. Recheck the existing-profile credential replacement contract.
  Payoff: advance the named accepted outcome without duplicating existing repairs.
  Source: [M3-PROVIDER](docs/adr/api-and-state.md#required-agent-owned-mutation-contract).
  Scope: Read-only contract/test/caller trace; exclude secret acquisition, provider writes, inference, restarts and direct Agent-file writes.
  Acceptance: Record supported expected-revision replacement semantics or the precise gap. Preserve separate add/remove/assignment/validation outcomes and unavailable controls.
  Dependencies: none for this bounded evidence/contract slice. Any later runtime
  or privileged operation retains its own target, authority and consent gates.
  Ownership: unclaimed in this index; verify tracker/continuation leases first.

- [ ] **DOC-M4-INVENTORY-EVIDENCE** — Goal: M4. Map one Tools inventory journey to current-source evidence.
  Payoff: advance the named accepted outcome without duplicating existing repairs.
  Source: [M4](ROADMAP.md#m4--discover-and-administer-supported-agent-work).
  Scope: Existing Tools/channel/widget/browser checks and sanitized receipt only; exclude new contracts, mutations and personal targets.
  Acceptance: Identify source-bound keyboard/search/owner-denial checks and the smallest remaining named-platform verification scenario.
  Dependencies: none for this bounded evidence/contract slice. Any later runtime
  or privileged operation retains its own target, authority and consent gates.
  Ownership: unclaimed in this index; verify tracker/continuation leases first.

- [ ] **DOC-PARITY-COVERAGE** — Goal: PARITY. Map the next uncovered Desktop outcome to a bounded port slice.
  Payoff: advance the named accepted outcome without duplicating existing repairs.
  Source: [PARITY](docs/product/hermes-desktop-parity.md#reference-and-evidence-boundary).
  Scope: Parity ledger and existing milestone/task receipts; exclude implementation, tracker changes and duplicated component tasks.
  Acceptance: Every reference outcome maps to an existing goal/task or explicit conditional contract. Keep acceptance and platform limits distinct.
  Dependencies: none for this bounded evidence/contract slice. Any later runtime
  or privileged operation retains its own target, authority and consent gates.
  Ownership: unclaimed in this index; verify tracker/continuation leases first.

- [ ] **DOC-PARITY-TAB-CONTRACT** — Goal: PARITY-TABS. Trace exact tab switching and close/Stop ownership.
  Payoff: advance the named accepted outcome without duplicating existing repairs.
  Source: [PARITY-TABS](docs/product/hermes-desktop-parity.md#reference-and-evidence-boundary).
  Scope: Read-only Desktop/Wing contracts and tests; exclude tab implementation, run mutations and arbitrary local IPC.
  Acceptance: Specify one switch/close scenario with explicit session/run identity and authoritative terminal readback. Preserve other tabs and unknown outcomes.
  Dependencies: none for this bounded evidence/contract slice. Any later runtime
  or privileged operation retains its own target, authority and consent gates.
  Ownership: unclaimed in this index; verify tracker/continuation leases first.

- [ ] **DOC-SESSION-ACTIONS-EVIDENCE** — Goal: SESSIONS. Prove one owner-bound session rename journey.
  Payoff: advance the named accepted outcome without duplicating existing repairs.
  Source: [SESSIONS](docs/product/hermes-desktop-parity.md#statuses).
  Scope: Existing channel/session-action/widget/browser paths; exclude live targets or replay.
  Acceptance: Run or add a deterministic app-level rename/cancel/owner-change check with exact request counts and authoritative reopen.
  Dependencies: none for this bounded evidence/contract slice. Any later runtime
  or privileged operation retains its own target, authority and consent gates.
  Ownership: unclaimed in this index; verify tracker/continuation leases first.

- [ ] **DOC-PERSONA-EVIDENCE** — Goal: PERSONA. Verify persona whitespace and completion receipts.
  Payoff: advance the named accepted outcome without duplicating existing repairs.
  Source: [PERSONA](docs/product/hermes-desktop-parity.md#statuses).
  Scope: Existing profile decoder/editor, actual-router tests and receipts; no live saves or duplicate accepted repairs.
  Acceptance: Match current-source hashes to same-card read/save/conflict/cancel receipts; run or add the missing app-level oracle if no matching receipt exists.
  Dependencies: none for this bounded evidence/contract slice. Any later runtime
  or privileged operation retains its own target, authority and consent gates.
  Ownership: unclaimed in this index; verify tracker/continuation leases first.

- [ ] **DOC-M4-MEMORY-CONTRACT** — Goal: M4-MEMORY. Trace one bounded profile-memory read.
  Payoff: advance the named accepted outcome without duplicating existing repairs.
  Source: [M4-MEMORY](docs/product/hermes-desktop-parity.md#statuses).
  Scope: Read-only contracts/test/caller trace; exclude memory persistence and shadow state.
  Acceptance: Record the supported schema, grant, profile identity and bounds or precise absent operation; identify one next read slice.
  Dependencies: none for this bounded evidence/contract slice. Any later runtime
  or privileged operation retains its own target, authority and consent gates.
  Ownership: unclaimed in this index; verify tracker/continuation leases first.

- [ ] **DOC-M4-SCHEDULE-CONTRACT** — Goal: M4-SCHEDULES. Trace one schedule pause/resume operation.
  Payoff: advance the named accepted outcome without duplicating existing repairs.
  Source: [M4-SCHEDULES](docs/product/hermes-desktop-parity.md#statuses).
  Scope: Existing Schedules/channel and authoritative contracts; exclude job execution, delivery credentials and generic CLI.
  Acceptance: Record exact operation/grant/revision/idempotency semantics or the gap; preserve the existing read-only inventory.
  Dependencies: none for this bounded evidence/contract slice. Any later runtime
  or privileged operation retains its own target, authority and consent gates.
  Ownership: unclaimed in this index; verify tracker/continuation leases first.

- [ ] **DOC-M4-PLATFORM-CONTRACT** — Goal: M4-PLATFORMS. Trace one messaging-platform status/admin contract.
  Payoff: advance the named accepted outcome without duplicating existing repairs.
  Source: [M4-PLATFORMS](docs/product/hermes-desktop-parity.md#statuses).
  Scope: Existing gateway contracts and reference tests; exclude peer trust expansion and lifecycle mutations.
  Acceptance: Separate health reads from one exact platform-admin operation, including local approval and stable resource authorization or an evidenced missing contract.
  Dependencies: none for this bounded evidence/contract slice. Any later runtime
  or privileged operation retains its own target, authority and consent gates.
  Ownership: unclaimed in this index; verify tracker/continuation leases first.

- [ ] **DOC-M4-MCP-CONTRACT** — Goal: M4-MCP. Trace one toolset enable/disable contract.
  Payoff: advance the named accepted outcome without duplicating existing repairs.
  Source: [M4-MCP](docs/product/hermes-desktop-parity.md#statuses).
  Scope: Tools inventory/callers and read-only Agent source/tests; exclude MCP installation, secrets and arbitrary commands.
  Acceptance: Identify exact profile/toolset identity, grant and conflict behavior or precise absent operation; discovery alone must not authorize writes.
  Dependencies: none for this bounded evidence/contract slice. Any later runtime
  or privileged operation retains its own target, authority and consent gates.
  Ownership: unclaimed in this index; verify tracker/continuation leases first.

- [ ] **DOC-M4-KANBAN-CONTRACT** — Goal: M4-KANBAN. Trace one bounded Project board read.
  Payoff: advance the named accepted outcome without duplicating existing repairs.
  Source: [M4-KANBAN](docs/product/hermes-desktop-parity.md#statuses).
  Scope: Read-only models/contracts/test trace; exclude tracker mutation, shadow cards and directory file access.
  Acceptance: Identify board/Project ownership, pagination/bounds and exact authorization or missing contract; specify one next read-only slice.
  Dependencies: none for this bounded evidence/contract slice. Any later runtime
  or privileged operation retains its own target, authority and consent gates.
  Ownership: unclaimed in this index; verify tracker/continuation leases first.

- [ ] **DOC-DIAGNOSTICS-CONTRACT** — Goal: DIAGNOSTICS-RECOVERY. Trace one redacted log/diagnostic read.
  Payoff: advance the named accepted outcome without duplicating existing repairs.
  Source: [DIAGNOSTICS-RECOVERY](docs/product/hermes-desktop-parity.md#statuses).
  Scope: Existing diagnostics and contracts; exclude restore, file copying, secret exports and generic config commands.
  Acceptance: Name allowed fields, limits, redaction and exact grant, or absent contract. Keep atomic backup/import and fixes separately gated.
  Dependencies: none for this bounded evidence/contract slice. Any later runtime
  or privileged operation retains its own target, authority and consent gates.
  Ownership: unclaimed in this index; verify tracker/continuation leases first.

- [ ] **DOC-ACCOUNT-CONTRACT** — Goal: ACCOUNT. Trace one provider OAuth acquisition contract.
  Payoff: advance the named accepted outcome without duplicating existing repairs.
  Source: [ACCOUNT](docs/product/hermes-desktop-parity.md#statuses).
  Scope: Read-only accepted parity scope and credential boundaries; exclude account provisioning, wallet transactions and secret acquisition.
  Acceptance: Document exact authority, supported private handoff, expiry/logout/revocation and fail-closed limits or precise unavailable operation. No account route without a qualified contract.
  Dependencies: none for this bounded evidence/contract slice. Any later runtime
  or privileged operation retains its own target, authority and consent gates.
  Ownership: unclaimed in this index; verify tracker/continuation leases first.

- [ ] **DOC-BACKEND-CONTRACT** — Goal: REMOTE-BACKENDS. Compare one reference backend launch with allowed Wing boundaries.
  Payoff: advance the named accepted outcome without duplicating existing repairs.
  Source: [REMOTE-BACKENDS](docs/product/hermes-desktop-parity.md#statuses).
  Scope: Read-only backend contracts/design evidence; no process launch, remote shell, caller paths or executable choice.
  Acceptance: Record whether a fixed typed operation exists and its resource/lifecycle bounds; if absent, retain unsupported status rather than invent a bridge.
  Dependencies: none for this bounded evidence/contract slice. Any later runtime
  or privileged operation retains its own target, authority and consent gates.
  Ownership: unclaimed in this index; verify tracker/continuation leases first.

- [ ] **DOC-ARTIFACT-CONTRACT** — Goal: ARTIFACTS. Trace one bounded Agent artifact retrieval operation.
  Payoff: advance the named accepted outcome without duplicating existing repairs.
  Source: [ARTIFACTS](docs/product/hermes-desktop-parity.md#statuses).
  Scope: Current media/export and read-only artifact contracts; exclude host-file enumeration, unsafe rendering and artifact requests.
  Acceptance: Specify identity/authentication/MIME/size/content bounds and inert preview oracle or absent operation. Folder grants must not imply artifact access.
  Dependencies: none for this bounded evidence/contract slice. Any later runtime
  or privileged operation retains its own target, authority and consent gates.
  Ownership: unclaimed in this index; verify tracker/continuation leases first.

- [ ] **DOC-OFFICE-REFERENCE** — Goal: OFFICE. Compare one Office contact/session activation interaction.
  Payoff: advance the named accepted outcome without duplicating existing repairs.
  Source: [OFFICE](docs/product/hermes-desktop-parity.md#statuses).
  Scope: Existing 2D Office and Desktop read-only source; exclude 3D/account dependencies and new host operations.
  Acceptance: Name reference action, current deviation, exact owner/capability/focus oracle and one bounded implementation slice preserving 2D accessibility.
  Dependencies: none for this bounded evidence/contract slice. Any later runtime
  or privileged operation retains its own target, authority and consent gates.
  Ownership: unclaimed in this index; verify tracker/continuation leases first.

- [ ] **DOC-DESKTOP-DELIVERY-EVIDENCE** — Goal: DESKTOP-DELIVERY. Inventory one Linux desktop install/update receipt gap.
  Payoff: advance the named accepted outcome without duplicating existing repairs.
  Source: [DESKTOP-DELIVERY](docs/product/hermes-desktop-parity.md#statuses).
  Scope: Existing menu/install/verifier/runbook/CI evidence; no installs, updates, signing, service restarts or publication.
  Acceptance: Identify source/artifact/target-bound activation, health and rollback proof or exact gaps; do not equate cross-compilation with runtime support.
  Dependencies: none for this bounded evidence/contract slice. Any later runtime
  or privileged operation retains its own target, authority and consent gates.
  Ownership: unclaimed in this index; verify tracker/continuation leases first.

- [ ] **DOC-SLASH-CATALOG-CONTRACT** — Goal: SLASH-CATALOG. Compare the current curated commands with an authoritative catalog.
  Payoff: advance the named accepted outcome without duplicating existing repairs.
  Source: [SLASH-CATALOG](docs/product/hermes-desktop-parity.md#statuses).
  Scope: Existing composer commands and read-only catalog/contracts; no shell dispatch or speculative command routes.
  Acceptance: Identify one supported missing completion/action, its exact authorization and regression oracle, or an unavailable catalog.
  Dependencies: none for this bounded evidence/contract slice. Any later runtime
  or privileged operation retains its own target, authority and consent gates.
  Ownership: unclaimed in this index; verify tracker/continuation leases first.

- [ ] **DOC-SHELL-PERSISTENCE-EVIDENCE** — Goal: SHELL-PERSISTENCE. Prove sidebar preference restoration after app relaunch.
  Payoff: advance the named accepted outcome without duplicating existing repairs.
  Source: [SHELL-PERSISTENCE](docs/product/hermes-desktop-parity.md#reference-and-evidence-boundary).
  Scope: Existing shell preferences/tests and deterministic owned state; exclude global startup redesign and personal desktop state.
  Acceptance: Run or add the smallest process-relaunch persistence check with source/target metadata; widget toggles alone are not relaunch proof.
  Dependencies: none for this bounded evidence/contract slice. Any later runtime
  or privileged operation retains its own target, authority and consent gates.
  Ownership: unclaimed in this index; verify tracker/continuation leases first.

- [ ] **DOC-CHAT-FIDELITY-REFERENCE** — Goal: CHAT-FIDELITY. Compare one composer control order and disclosure flow.
  Payoff: advance the named accepted outcome without duplicating existing repairs.
  Source: [CHAT-FIDELITY](docs/product/hermes-desktop-parity.md#reference-and-evidence-boundary).
  Scope: Existing Chat and read-only Desktop source/test evidence; exclude protocol changes and duplicate accepted transcript/model repairs.
  Acceptance: Specify one reference interaction and deviation with owner/capability/keyboard/recovery oracles and a bounded next port slice.
  Dependencies: none for this bounded evidence/contract slice. Any later runtime
  or privileged operation retains its own target, authority and consent gates.
  Ownership: unclaimed in this index; verify tracker/continuation leases first.

## Dependency-gated existing work

- [ ] **DOC-PARITY-COMPOSITION** — Goal: Desktop full product parity,
  footer/recents/session modal and multi-conversation tabs. Payoff: port the next
  reference behavior without mistaking global Open/New for complete composition.
  Source: [parity ledger](docs/product/hermes-desktop-parity.md).
  Scope: first source-backed comparison of profile-footer/session-modal behavior
  and one bounded implementation brief; exclude privileged host operations, tab
  mutations and duplicate global-access repairs. Acceptance: explicit reference
  actions, Wing deviations, exact owner/capability/focus oracles and a smallest
  safe implementation slice. Remaining: grouped recents, tabs/close-stop, composer,
  transcript and other surfaces. Dependencies: first daily-use receipt for the
  implementation sequence; source comparison is independent. Ownership: goal
  ledger controls continuation; no lease assigned by this index.

- [ ] **DOC-VOICE-QUALIFICATION** — Goal: PRD voice journey/physical speech.
  Prepare one current-source physical capture → reviewed transcript → explicit
  send scenario from the [microphone runbook](docs/runbooks/android/live-mic-smoke.md).
  Payoff: distinguish real device speech from simulated recognition.
  Scope: existing consented capture path and sanitized receipt; exclude app-owned
  voice models, speech logging, automatic send/replay and speculative audio routes.
  Acceptance: named device/recognizer/language, actual capture/cancel/failure
  outcomes and no retained recognized words in diagnostics. Remaining: output,
  hands-free and acoustic checks only on their named targets.
  Dependencies: approved physical target and capture consent; preparation proceeds
  without recording audio. Ownership: unclaimed; verify tracker before execution.

- [ ] **PARITY-APPROVAL-DISMISSAL** — Goal: M1. Preserve original card `t_6233c1c5`,
  **Default applied 2026-10-06 (owner gave full freedom; ask, don't block):** the refusal was the fleet's circular review-entry gate, now fixed. Re-admit card `t_6233c1c5` to native review with its existing GREEN evidence; no rework.
  now native `scheduled` for retry backoff after review-entry refusal in run 198.
  Run 201 records `retry_exhausted`; resume requires changed source, prerequisite,
  contract or supported lifecycle-route evidence, not unchanged-test replay.
  The worker demonstrated an actual
  widget RED through keyboard traversal while malformed A Review remained open,
  then delivered a queue-only repair with the identical oracle GREEN.
  Source: [dismissal runbook](docs/runbooks/chat-approval-dismissal.md) and
  profile-local `autogoal/approval-dismissal/native174-acceptance.md`.
  Payoff: stale local dismissal cannot release a replacement answer's busy guard.
  Scope remains queue dismissal and scoped tests; UI, lifecycle, transport,
  shared fakes and upstream changes remain excluded. The worker recorded 44
  focused passing tests, clean analysis and formatting. A separately requested
  `npm run test` completed with 3,104 passing tests; see profile-local
  `autogoal/approval-dismissal/native174-canonical-verification.md`.
  Delivered files match local branch `agent/wing/t_6233c1c5`, commit
  `a0b60c6422446d111d70f845f8883f8ce3a3399f`; no push or merge occurred.
  Mandatory same-card independent review and final approval remain pending.
  Review entry was rejected because the review being requested had not occurred;
  exact response: `autogoal/approval-dismissal/native174-review-entry-rejection.md`.
  Next action: governor assessment of supported same-card review entry, without
  forced closure, review waiver, replacement card or unchanged-test replay.
  This is an automated lifecycle gate, not a user dependency. The former user
  escalation remains withdrawn in
  [BLK-20261005-002](BLOCKERS.md#blk-20261005-002--resolve-the-original-narrowed-dismissal-stop-branch).
  Native UI/browser/live/packaged/integrated parity/release remain NOT_CHECKED.
  The observed keyboard focus escape remains unchanged; no duplicate Agent POST
  or universal unreachability is claimed.

- **PARITY-KEYBOARD-RETURN** (historical, superseded) — Preserve the original archived Providers-local
  card `t_11b62717` and its historical scope, not an unfixed product-defect claim.
  Source: [original diagnosis](docs/runbooks/provider-search.md#large-text-keyboard-return-defect-t_11b62717).
  The separately authorized forward repair `t_c5a4d301` is completed and approved
  in run 98; see the [forward receipt](docs/runbooks/provider-search.md#forward-shared-shell-repair-receipt-t_c5a4d301)
  and [quality follow-through](docs/quality/flutter-keyboard-follow-through.md).
  Payoff: retain truthful provenance without dispatching duplicate repairs.
  Original scope: Providers-local changes only, with shared shell/lifecycle
  excluded. Its eight-case oracle, affected tests, analysis, compiled-browser
  and same-card gates remain historical acceptance requirements, not a new lease.
  Ownership: the governor archived the original card as superseded, not done or
  approved. `t_1c1e6f37` is now done; see its receipt below. No original-card continuation, replacement
  card, automatic full-suite retry or further shell edit is authorized here.

- [x] **PARITY-GLOBAL-SESSIONS** — Original card `t_1c1e6f37` is completed and
  independently approved in run 169. Exact loaded-session Open/New Session from
  feature routes now uses passive directory observation and guarded acknowledgement.
  The [parity ledger](docs/product/hermes-desktop-parity.md) and
  [UI gap audit](docs/product/hermes-desktop-ui-gap.md) now distinguish this delivered
  slice from grouped recents, profile-footer and full session-modal gaps.
  Source: [current runbook](docs/runbooks/global-session-access.md); the
  [retained diagnostic](tools/global_session_access/README.md) describes the earlier
  withdrawn candidates, not the final delivery. The reviewer independently passed
  75 focused tests and six compiled Chromium cases, with clean analysis, formatting
  and whitespace checks; 24 scoped hashes were verified and 171 unchanged neighbor
  passes reused. Native/live/full-parity qualification remains unclaimed.
  Former escalation [BLK-20261005-001](BLOCKERS.md#blk-20261005-001--admit-the-passive-global-session-lifecycle-seam)
  remains resolved. No duplicate task, broader startup redesign or new lease is
  authorized by this index.

- [ ] **PARITY-PAIR-READ** — Goal: M1. Establish the supported authoritative read needed to
  **Default applied 2026-10-06:** implement the exact provider/model read and restore through the existing advertised Agent API, with a focused test. Only if no advertised read exists does an API extension become an owner question. Earlier "authorizes no implementation" wording is superseded.
  recover the exact confirmed session provider/model pair. Payoff: picker reopen
  must preserve identity after route return and reload, not infer it from a label.
  Source: [failed integrated receipt](docs/quality/2026-10-04-desktop-cron-0117-selector.md)
  and [source-only review](docs/quality/2026-10-04-desktop-cron-0309-review-validation.md).
  The [independent admission review](docs/quality/2026-10-04-autogoal-restoration-admission-review.md)
  closed proposal source review with `SOURCE_CONSISTENT_RUNTIME_WITHHELD`;
  it granted no implementation or runtime admission.
  Scope: session model read/restore boundary under `lib/core/hermes/` and Chat's
  picker callers; this entry authorizes no implementation or API extension.
  Exclude shadow lock state, repeated model-lock writes, weakened browser oracles
  and all upstream edits. Acceptance after contract admission and a fresh lease:
  authoritative exact owner/provider/model evidence, nearest restoration tests,
  and a fresh compiled `playwright/tests/regression/desktop-daily-workflow.spec.mjs`
  run preserving picker and final mutation-count assertions. Dependencies:
  separate exact-pair/native recovery authority review; source consistency alone
  withheld runtime approval. Ownership: no execution lease assigned here; consult
  the goal ledger and live tracker before claiming work.

- [ ] **PARITY-NATIVE-RELAUNCH** — Goal: M1. Exercise the existing two-process native
  deterministic workflow without rewriting it. Payoff: distinguish real native
  process persistence from widget remount and browser reload.
  Source: [workflow acceptance](docs/plans/2026-10-03-desktop-daily-workflow.md)
  and [recorded preflight](docs/quality/2026-10-04-desktop-cron-0322-auth-preflight.md).
  Scope: existing `scripts/run_linux_desktop_daily_workflow_e2e.sh` and
  `integration_test/linux_desktop_daily_workflow_test.dart`; owned display/state
  and evidence only after admission. No package installation, personal desktop,
  production edits or runtime/card acceptance is authorized by this entry.
  Acceptance: admitted launcher execution with captured exits, two native process
  phases, exact off-page owner/history restoration, no replay and owned cleanup.
  Dependencies/blocker: [BLK-20261005-003](BLOCKERS.md#blk-20261005-003--install-linux-desktop-build-packages-sudo)
  records missing libsecret/GStreamer development metadata and the no-install
  default; native execution also needs exclusive Flutter/display ownership.
  Ownership: no execution lease assigned here; goal ledger controls admission.
  Synthetic replies will not qualify actual inference even if this gate passes.

- [ ] **PARITY-LIVE-WORKFLOW** — Goal: M1. Qualify the complete daily-use journey on an
  **Owner question (BLOCKERS.md BLK-20261006-W01):** which isolated Agent target and credentials may this qualification use? Default if no answer: none; it stays parked, and M1's other slices proceed.
  owner-approved isolated, unmodified Agent target. Payoff: prove actual generation,
  correlated approval, authoritative Stop and exact-session restoration together.
  Source: [workflow matrix](docs/plans/2026-10-03-desktop-daily-workflow.md)
  and [unblock criteria](docs/quality/2026-10-04-desktop-cron-0322-auth-preflight.md).
  Scope: named-target verification and sanitized receipts; preserve `t_f098a32e`
  and `t_38174cb7` without claiming or transitioning them. Exclude personal
  credential discovery/copying, provider substitution, upstream patches and
  releases. Acceptance: complete workflow matrix with canonical identity/run/
  history readback, one submission per deliberate send, zero restoration replay,
  named-platform evidence and independent acceptance; fixtures are insufficient.
  Dependencies/blocker: approved target, supported private auth, exact-pair/native
  authority, native prerequisites, explicit network/cost/prompt/tool/duration/
  cleanup consent. Ownership: owner provisioning/admission required, no execution
  lease assigned. Job `6f218a559ed2` was recorded paused; resumption is a separate
  explicit action after prerequisites, not authorized by this TODO.

## Done — documentation only

- [x] **PARITY-DOC-RECONNECT-READ-INTENT** — Indexed completed repair `t_af394f96`,
  independently approved in run 278. Source:
  [direct Reconnect runbook](docs/runbooks/chat-reconnect-read-intent.md) and
  [independent review](.task-evidence/t_af394f96/independent-review.md).
  The identical baseline widget oracle failed 11 cases; the repaired suite passed
  59 tests and analysis was clean. This pass verified 13 recorded source hashes
  before updating the review status; no product tests were rerun.
  Local snapshot: `agent/wing/t_af394f96`, commit
  `de67380a120c484b14073080b1acf012769ebb6c`. No push or merge occurred.
  Native/browser/live/physical/packaged/full-suite/parity remain NOT_CHECKED.

- [x] **PARITY-DOC-ENDPOINT-LOAD-INTENT** — Indexed completed repair `t_323250d0`,
  independently approved in run 272. Source:
  [saved-endpoint intent runbook](docs/runbooks/chat-endpoint-load-intent.md).
  The reviewer independently passed 124 focused tests and clean analysis,
  formatting and whitespace checks. This pass verified all five delivered
  fingerprints before updating the runbook; no product tests were rerun.
  A conflicting generated no-commit instruction prevented its local snapshot.
  The baseline-relative patch and source-bound receipts remain available.
  Native/browser/live/physical/packaged/full-suite/parity remain NOT_CHECKED.

- [x] **PARITY-DOC-COMPLETION-FOCUS** — Corrected the stale pending-review statement
  in the [completion-focus runbook](docs/runbooks/chat-completion-focus-ownership.md).
  Card `t_64756dfb` is completed and independently approved in run 245.
  The [review receipt](.task-evidence/t_64756dfb/independent-review.md) records
  212 focused widget passes and clean analysis, formatting and whitespace checks.
  This pass inspected the live card and receipt; no product tests were rerun.
  Native/browser/live/Android/packaged/full-parity evidence remains NOT_CHECKED.

- [x] **PARITY-DOC-SESSION-SETTLEMENT** — Indexed completed caller repair
  `t_cd455c23`, independently approved in run 236. Source:
  [settlement runbook](docs/runbooks/chat-session-settlement.md).
  Old-owner create/open completion cannot show replacement feedback, refresh its
  contact or focus its composer. The reviewer passed 351 widget tests and clean
  analysis; this pass verified six source hashes and the local task branch SHA.
  No product tests were rerun. Native/browser/live/packaged/full-parity targets
  remain NOT_CHECKED; approval card `t_6233c1c5` remains parked.

- [x] **PARITY-DOC-ERROR-DETAILS-COPY** — Indexed completed repair `t_526a2fef`,
  approved by same-card review in run 158. Source:
  [error-details copy runbook](docs/runbooks/chat-error-details-copy-outcomes.md).
  Success now awaits completion; rejection has sheet-local accessible retry
  feedback; dismissal/disposal suppresses late feedback. The reviewer passed
  32 regression cases and 111 neighbors, formatting, analysis, whitespace and
  links. This pass inspected retained logs and matched all three source hashes;
  it reran no product tests. Physical clipboard, browser, screen-reader runtime,
  live Agent, full suite, packaging, integrated parity and release remain
  NOT_CHECKED. Original cards and their scope exclusions are unchanged.

- [x] **PARITY-DOC-DIAGNOSTICS-COPY** — Indexed completed repair `t_a568069e`,
  approved by same-card review in run 146. Source:
  [Diagnostics copy runbook](docs/runbooks/chat-diagnostics-copy-outcomes.md).
  Both actions now await clipboard completion, show a fixed localized modal
  failure with explicit retry, and suppress late feedback after dismissal or
  disposal. Payloads and Agent state are unchanged. The reviewer independently
  passed 143 focused widget cases, analysis, changed-file formatting, scoped
  whitespace and link checks. This documentation pass inspected retained logs
  and verified six source fingerprints; it reran no product tests. Physical
  clipboard, screen-reader runtime, browser, live Agent, packaged builds,
  full-suite/integrated parity and release remain NOT_CHECKED.

- [x] **PARITY-DOC-APPROVAL-SETTLEMENT** — Indexed completed repair `t_6209124f`,
  approved by same-card review in run 130. Source:
  [approval-settlement runbook](docs/runbooks/chat-approval-settlement.md).
  Recorded production-channel RED preceded the responder-lifetime fence. The
  reviewer independently passed 398 focused tests, analysis and scoped formatting.
  This documentation pass verified four final fingerprints and inspected logs;
  it reran no tests. Native UI, browser, live Agent, packaged builds, full suite,
  integrated parity and release remain NOT_CHECKED. Existing gates are unchanged.

- [x] **PROFILE-MUTATION-REVIEW** — Indexed completed repair `t_eb72edbe`,
  approved by same-card native review in run 119. Source:
  [mutation-owner receipt](docs/runbooks/profile-mutation-intent.md).
  The reviewer independently passed 174 focused tests, analysis and changed-file
  formatting, and verified six final fingerprints and eight affected local links.
  This documentation pass inspected the source-bound archive and approval; it
  reran no tests. Native/browser/live/integrated/full-suite/release qualification
  remains NOT_CHECKED. No new task or retry is authorized by this index.

- [x] **PARITY-DOC-EXPORT-FEEDBACK** — Indexed completed export-feedback repair
  `t_aaa10f17` and same-card approval run 106. Source:
  [exact-owner feedback receipt](docs/runbooks/chat-transcript-export.md#exact-owner-failure-feedback-repair-t_aaa10f17).
  Scope: status and evidence documentation only. Acceptance: reviewer log records
  127 focused cases passed, zero failures/skips; three final source hashes matched
  before this documentation update. No tests were rerun by the documentation pass.
  Native application, compiled browser, live workflow and full-suite qualification
  remain unverified for this repair. Existing blocked scopes remain unchanged.

- [x] **PARITY-DOC-KEYBOARD-FORWARD** — Indexed completed forward repair
  `t_c5a4d301` and native approval run 98 without changing blocked predecessors.
  Source: [forward receipt](docs/runbooks/provider-search.md#forward-shared-shell-repair-receipt-t_c5a4d301)
  and [quality follow-through](docs/quality/flutter-keyboard-follow-through.md).
  Scope: status, evidence and handoff documentation only. Acceptance: inspected
  source-bound hashes, review verdict and logs; affected links/whitespace checked.
  No fresh test, full-suite, native app, live workflow or release claim is added.

- [x] **DOC-WING-LINK-HTTP-CONTRACT** — Added and indexed the
  [code-first OpenAPI snapshot](docs/api/wing-link.openapi.yaml).
  Scope: existing Go management and ephemeral pairing-broker HTTP routes only;
  exclude API redesign, generated clients, Agent schemas and runtime qualification.
  Acceptance: YAML parsing, JSON Schema structure, local references, route/path
  parameters and cited source paths checked. Full OpenAPI validation and live
  API conformance were not executed. Go handlers remain authoritative.

- [x] **DOC-CORE-DESIGN-TEST** — Added the cross-component
  [technical design](docs/spec.md) and [test plan](docs/test-plan.md).
  Scope: current source/ADR mapping and risk-based verification instructions;
  exclude production changes, new decisions, runtime tests and qualification.
  Acceptance: source paths, affected local links/anchors and scoped whitespace
  checks pass. Existing product requirements, operating runbooks and release
  history remain their canonical owners. This is documentation completion only.

- [x] **PARITY-DOC-PIN-WRITE-ORDER** — Indexed completed card `t_c0073c10`,
  independently approved in run 69, and its
  [pin write-order runbook](docs/runbooks/chat-session-pin-write-order.md).
  The [parity ledger](docs/product/hermes-desktop-parity.md#supporting-chat-repairs)
  now includes this repair with its same-store and persistence-failure limits.
  Source-bound receipts record a lost-persistence regression, then 50 focused
  tests passed and analyzer exit 0. Same-store commits are serialized and waiting
  choices are coalesced without delaying local notifications. This index does
  not establish cross-instance ordering, physical durability, native/browser,
  live or integrated workflow acceptance.

- [x] **PARITY-DOC-TRANSCRIPT-COPY** — Indexed completed card `t_e423d707` and its
  [clipboard-outcome runbook](docs/runbooks/chat-transcript-copy-outcomes.md).
  Inspected source-bound execution logs record 68 new and 105 neighboring tests
  passed, with analyzer exit 0. Success follows completion; rejection permits
  explicit retry and suppresses stale feedback. Started writes cannot be undone.
  This pass ran no Flutter tests and establishes no physical clipboard, browser,
  native, live or integrated acceptance.

- [x] **PARITY-DOC-PIN-LIFETIME** — Indexed completed card `t_438fb753`, run 60,
  and its [pin lifetime runbook](docs/runbooks/chat-session-pin-lifetime.md).
  Source-bound receipts record an executed disposed-store regression failure,
  then 43 focused tests passed and analyzer exit 0. The fix prevents obsolete
  pending actions from initiating writes; already-started writes can settle.
  This index does not establish physical preferences, browser, native, live,
  full-suite or integrated workflow acceptance.

- [x] **PARITY-DOC-CONTRIBUTING** — Corrected contributor priorities to the accepted
  Desktop-first workflow, with mobile usability and accessibility preserved.
  Source: [product decision](docs/adr/product.md) and
  [current goal](docs/plans/2026-10-03-desktop-port-goal.md).
  Scope: contributor guidance only; no qualification or implementation mandate.
- [x] **PARITY-DOC-QUEUE-INTENT** — Indexed completed card `t_a199ad12`, run 52,
  and its [queue-dialog intent runbook](docs/runbooks/chat-queued-follow-up-intent.md).
  Verified execution receipts record 62 new and 169 neighboring widget tests
  passed, analyzer exit 0 and unchanged receipt-bound source fingerprints.
  This index does not establish browser, native, live or integrated acceptance.

- [x] **PARITY-DOC-MUTATION-INTENT** — Linked the existing session mutation repair
  from the parity ledger and docs index. This closes a documentation gap only.
  Source: [mutation-intent runbook](docs/runbooks/chat-session-mutation-intent.md)
  and [production session actions](lib/features/hermes_chat/session/hermes_chat_session_actions.dart).
  The runbook records widget regressions. Browser, native and integrated workflow
  acceptance remain unverified. No implementation work is authorized by this entry.

- [x] **PARITY-DOC-DIRECTION** — Reconciled PRD and study-index wording with the
  accepted Desktop-first direction, without promoting planned behavior to shipped
  support. Evidence: [PRD](docs/product/prd.md), [product decision](docs/adr/product.md)
  and [docs index](docs/README.md).
- [x] **PARITY-DOC-CHECKPOINT** — Reconciled current goal/roadmap/plan/parity
  summaries with the recorded provisioning pause and restored-picker failure;
  historical receipts remain intact. Evidence: [goal checkpoint](docs/plans/2026-10-03-desktop-port-goal.md),
  [parity ledger](docs/product/hermes-desktop-parity.md) and linked receipts.
- [x] **PARITY-DOC-NAVIGATION** — Corrected flat-navigation descriptions to reflect
  implemented Workflow/Utilities grouping while retaining footer/recents/sidebar
  gaps. Evidence: [UI gap audit](docs/product/hermes-desktop-ui-gap.md),
  [navigation runbook](docs/runbooks/desktop-navigation-groups.md) and
  [production presentation](lib/shared/widgets/app_shell_presentation.dart).

These completed items are documentation corrections, not runtime, card, release
or full Desktop parity acceptance. Root discovery and local-link/diff checks
validate the handoff's documentation, not the blocked behavioral gates.
