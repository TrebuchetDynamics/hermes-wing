# Hermes Desktop Capability Parity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver Hermes Desktop user outcomes in Hermes Wing through typed Hermes Agent APIs, reviewed Wing Link operations, and platform-native Flutter implementations without duplicating Agent state.

**Architecture:** Split parity into independent vertical slices. Hermes Agent remains authoritative for sessions, profiles, memory, skills, models, providers, jobs, toolsets, and messaging configuration. Wing Link handles only fixed host-management operations. Native desktop features (windowing, logs, backup, updates, SSH/Docker/WSL launch) remain local or typed host operations and never become arbitrary command execution.

**Tech Stack:** Flutter/Dart, Riverpod, GoRouter, `HermesChannel`/`HermesApiClient`, capability schema 1, Wing Link Go service, Flutter integration tests, deterministic Hermes fixture, Playwright and Linux desktop integration tests.

## Global Constraints

- Every Agent operation requires its exact advertised method, path, authorization, and current resource identity.
- Unsupported operations stay hidden or explicitly unavailable; no simulated support, Wing-owned shadow state, arbitrary CLI, shell bridge, or Agent traffic through Wing Link.
- Provider secrets are write-only and remain in platform secure storage; never place them in argv, URLs, QR payloads, logs, diagnostics, fixtures, or responses.
- Profile, project, directory, gateway, and session identities remain explicit; no global `profile use` or `project use` side effects.
- Directory selection uses opaque, revocable Wing Link handles and canonical containment checks; clients never send arbitrary host paths.
- Mutations require revisions or an idempotent contract and must distinguish persistence success from reload/restart success.
- Every non-trivial slice adds a focused regression test, deterministic fixture coverage, and a native Linux E2E path where the feature is available on Linux.
- Hermes Desktop source is parity research only. Its Electron IPC, unrestricted filesystem access, and process-control behavior are not copied into Wing.

---

## Scope map

The requested list is deliberately split because it contains four different ownership boundaries:

1. **Agent API slices:** skills, memory, models/providers, schedules, toolsets, MCP, Soul, messaging configuration, slash commands.
2. **Wing Link/host slices:** Projects/Kanban, local install, logs, diagnostics fixes, remote host setup, SSH/Docker/WSL, update activation.
3. **Local desktop slices:** backup/import, window/install flows, updater UI, file/media presentation, web preview.
4. **Presentation parity:** accessible Office equivalent and desktop navigation/layout.

Hermes Agent 0.20 currently exposes read-only skills/toolsets/models and documented jobs APIs, while several requested mutation surfaces are not advertised in Wing’s compatibility contract. Phase 0 makes each prerequisite explicit before a mutating UI is enabled.

---

### Task 1: Freeze the parity and contract matrix

**Files:**

- Create: `docs/product/hermes-desktop-parity.md`
- Modify: `docs/product/routes.md`
- Modify: `docs/product/hermes-compatibility.md`
- Test: `test/tooling/hermes_desktop_parity_contract_test.dart`

**Interfaces:**

- Consumes: `hermes-desktop/README.md`, `hermes-desktop/src/renderer/src/screens/`, Wing route status, `HermesCapabilityDocument`, and `HermesSurfaceReadiness`.
- Produces: one table mapping every Desktop screen/action to `implemented`, `read-only`, `contract-blocked`, or `local-native`, with the required exact API or host operation named for every non-implemented action.

- [ ] **Step 1: Write the failing contract test**

```dart
void main() {
  test('parity inventory names every requested Desktop surface', () {
    final text = File('docs/product/hermes-desktop-parity.md').readAsStringSync();
    for (final term in const [
      'Skills/Discover',
      'Memory',
      'Saved models',
      'Schedules',
      'Messaging gateways',
      'Toolsets and MCP',
      'Soul/persona',
      'Kanban',
      'Backup/import',
      'Account/OAuth',
      'SSH/Docker/WSL',
      'Web preview',
      'Office',
      'Auto-updates',
      'Slash commands',
    ]) {
      expect(text, contains(term), reason: term);
    }
  });
}
```

- [ ] **Step 2: Run the contract test to verify it fails**

Run: `flutter test test/tooling/hermes_desktop_parity_contract_test.dart --concurrency=1`

Expected: FAIL because the parity matrix does not exist.

- [ ] **Step 3: Add the matrix and route/status updates**

Record the current implementation and the exact gate for every action. Do not mark a row implemented from a Desktop screenshot or source file; require a live Wing test or a documented local-native receipt.

- [ ] **Step 4: Run the contract test to verify it passes**

Run: `flutter test test/tooling/hermes_desktop_parity_contract_test.dart --concurrency=1`

Expected: PASS.

---

### Task 2: Implement schedule CRUD and delivery targets

**Files:**

- Modify: `lib/core/hermes/models/hermes_job.dart`
- Modify: `lib/core/hermes/client/hermes_api_config.dart`
- Modify: `lib/core/hermes/client/hermes_api_client.dart`
- Modify: `lib/core/hermes/channel/hermes_channel.dart`
- Modify: `lib/core/hermes/channel/hermes_api_channel.dart`
- Modify: `lib/core/hermes/channel/hermes_channel_state.dart`
- Modify: `lib/features/schedules/screens/schedules_screen.dart`
- Modify: `lib/l10n/app_en.arb`
- Test: `test/core/hermes/hermes_job_test.dart`
- Test: `test/core/hermes/channel/hermes_api_channel_tests/jobs_tests.dart`
- Test: `test/features/schedules/schedules_screen_test.dart`
- Test: `playwright/tests/regression/hermes-schedules.spec.mjs`

**Interfaces:**

- Consumes: exact Agent `/api/jobs` CRUD, pause, resume, and run-now contracts and profile query context.
- Produces: revision-aware `createJob`, `updateJob`, `deleteJob`, `pauseJob`, `resumeJob`, and `runJob` channel operations; delivery targets remain an allowlisted typed enum, never free-form URLs or commands.

- [ ] Add RED tests for malformed job payloads, missing exact capabilities, stale revisions, duplicate idempotency keys, and each mutation’s authoritative reload.
- [ ] Add bounded request models and exact URI builders; reject unsupported delivery targets before network I/O.
- [ ] Add channel methods that require the selected profile and advertise the exact method/path/scope.
- [ ] Add schedule UI for create/edit/pause/resume/run/delete and explicit reload status.
- [ ] Add fixture API handlers and Playwright coverage for the complete lifecycle.
- [ ] Run: `flutter test test/core/hermes/channel/hermes_api_channel_tests/jobs_tests.dart test/features/schedules/schedules_screen_test.dart --concurrency=1`
- [ ] Run: `npm run web:e2e -- --grep schedules` or the focused Playwright spec.

---

### Task 3: Add Skills/Discover inventory and registry operations

**Files:**

- Create: `lib/features/skills/screens/skills_screen.dart`
- Create: `lib/features/skills/models/hermes_skill_registry_item.dart`
- Create: `lib/features/skills/providers/skills_registry_provider.dart`
- Modify: `lib/router/app_routes.dart`
- Modify: `lib/router/providers/app_router.dart`
- Modify: `lib/shared/widgets/app_shell.dart`
- Modify: `lib/core/hermes/channel/hermes_channel.dart`
- Modify: `lib/core/hermes/channel/hermes_api_channel.dart`
- Modify: `lib/l10n/app_en.arb`
- Test: `test/features/skills/skills_screen_test.dart`
- Test: `test/core/hermes/channel/hermes_api_channel_tests/skills_tests.dart`
- Test: `playwright/tests/regression/hermes-skills.spec.mjs`

**Interfaces:**

- Consumes: an advertised bounded registry read operation, source URL field, install/uninstall operation, and profile-target field. The existing read-only `GET /v1/skills` remains the installed inventory fallback.
- Produces: searchable registry UI, source-link navigation, install/uninstall confirmation, and explicit profile targeting backed by Agent-owned state.

- [ ] Add RED tests proving the route remains unavailable when no registry contract is advertised and that arbitrary source URLs/profile IDs are rejected.
- [ ] Implement only the exact advertised registry schema and bounded source URL policy; do not scrape GitHub or execute install commands locally.
- [ ] Add installation progress, terminal error, and authoritative reload states.
- [ ] Add deterministic fixture registry and Playwright lifecycle coverage.
- [ ] Run focused Flutter and Playwright tests.

---

### Task 4: Add Memory entries, profile memory, capacity, and providers

**Files:**

- Create: `lib/core/hermes/models/hermes_memory.dart`
- Create: `lib/features/memory/screens/memory_screen.dart`
- Create: `lib/features/memory/widgets/memory_entry_editor.dart`
- Create: `lib/features/memory/widgets/memory_capacity.dart`
- Modify: `lib/core/hermes/client/hermes_api_config.dart`
- Modify: `lib/core/hermes/client/hermes_api_client.dart`
- Modify: `lib/core/hermes/channel/hermes_channel.dart`
- Modify: `lib/core/hermes/channel/hermes_api_channel.dart`
- Modify: `lib/router/app_routes.dart`
- Modify: `lib/router/providers/app_router.dart`
- Modify: `lib/l10n/app_en.arb`
- Test: `test/core/hermes/channel/hermes_api_channel_tests/memory_tests.dart`
- Test: `test/features/memory/memory_screen_test.dart`
- Test: `playwright/tests/regression/hermes-memory.spec.mjs`

**Interfaces:**

- Consumes: exact advertised memory list/read/write/delete/capacity/provider contracts, profile identity, revision, and bounded entry fields.
- Produces: profile-scoped memory view/edit/delete, capacity cards, provider inventory, and conflict-safe reload.

- [ ] Add RED tests for absent contracts, cross-profile access, oversized content, secret-like content redaction, and stale revisions.
- [ ] Implement the model and client only after the capability fixture contains exact operations and scopes.
- [ ] Add a route with no local persistence of Agent memory.
- [ ] Add deterministic fixture lifecycle and Linux/web E2E.
- [ ] Run focused Flutter, web E2E, and Linux native E2E.

---

### Task 5: Complete saved models and provider configuration

**Files:**

- Modify: `lib/core/hermes/models/hermes_provider.dart`
- Modify: `lib/core/hermes/models/hermes_model_assignment.dart`
- Modify: `lib/core/hermes/client/hermes_api_client.dart`
- Modify: `lib/core/hermes/channel/hermes_api_channel.dart`
- Modify: `lib/features/providers/screens/providers_screen.dart`
- Modify: `lib/features/providers/widgets/provider_credential_sheet.dart`
- Modify: `lib/features/providers/widgets/model_picker_sheet.dart`
- Modify: `lib/l10n/app_en.arb`
- Test: `test/core/hermes/channel/hermes_api_channel_tests/provider_configuration_tests.dart`
- Test: `test/features/providers/providers_screen_test.dart`
- Test: `playwright/tests/regression/hermes-providers.spec.mjs`

**Interfaces:**

- Consumes: exact Agent provider/model CRUD, OAuth, credential validation, model refresh, and assignment contracts with write-only secret fields.
- Produces: saved model CRUD, provider setup, OAuth handoff, credential-pool status, and session/profile model selection without storing raw secrets.

- [ ] Add RED tests for capability denial, empty-key edits, provider scope mismatch, secret non-disclosure, revision conflicts, and reload failures.
- [ ] Remove any controls whose exact Agent contract is absent; never parse `.env` or config files in Wing.
- [ ] Implement OAuth as a single-use external handoff with no bearer token in URLs or clipboard payloads.
- [ ] Add fixture and E2E coverage for create/edit/delete/configure/refresh.
- [ ] Run focused Flutter and browser tests plus secret-redaction checks.

---

### Task 6: Complete toolset enable/disable and MCP administration

**Files:**

- Create: `lib/core/hermes/models/hermes_mcp_server.dart`
- Modify: `lib/core/hermes/channel/hermes_channel.dart`
- Modify: `lib/core/hermes/channel/hermes_api_channel.dart`
- Modify: `lib/features/tools/screens/tools_screen.dart`
- Modify: `lib/l10n/app_en.arb`
- Test: `test/core/hermes/channel/hermes_api_channel_tests/tools_tests.dart`
- Test: `test/features/tools/tools_screen_test.dart`
- Test: `playwright/tests/regression/hermes-tools.spec.mjs`

**Interfaces:**

- Consumes: exact advertised toolset mutation and MCP discovery/configuration contracts.
- Produces: bounded toolset toggles and MCP inventory/configuration with no arbitrary command, URL, or executable fields.

- [ ] Add RED tests for missing contracts, invalid server fields, unauthorized mutation, and profile leakage.
- [ ] Implement typed allowlisted fields only after the Agent capability fixture is updated from the official contract.
- [ ] Add explicit confirmation for destructive MCP changes and reload authoritative state.
- [ ] Add deterministic fixture and E2E coverage.

---

### Task 7: Expose the standalone Soul/persona editor

**Files:**

- Create: `lib/features/soul/screens/soul_screen.dart`
- Modify: `lib/features/profiles/widgets/profile_editor_sheet.dart`
- Modify: `lib/router/app_routes.dart`
- Modify: `lib/router/providers/app_router.dart`
- Modify: `lib/l10n/app_en.arb`
- Test: `test/features/soul/soul_screen_test.dart`
- Test: `test/features/profiles/profile_editor_test.dart`
- Test: `playwright/tests/regression/hermes-soul.spec.mjs`

**Interfaces:**

- Consumes: exact profile-scoped SOUL read/write contracts and revision.
- Produces: standalone route that reuses the same profile-bound editor; reset is a fresh explicit mutation, not a local default.

- [ ] Add RED tests for profile switching, stale revision, reset confirmation, and no local shadow copy.
- [ ] Extract the existing profile editor’s shared content into the route without duplicating transport logic.
- [ ] Gate the route on the exact capability and preserve the embedded profile editor as a deep-link-safe equivalent.
- [ ] Add fixture and E2E coverage.

---

### Task 8: Add Kanban/task planning through Hermes Projects

**Files:**

- Create: `lib/core/wing_link/models/wing_link_project.dart`
- Create: `lib/core/wing_link/project_client.dart`
- Create: `lib/features/kanban/screens/kanban_screen.dart`
- Create: `lib/features/kanban/models/kanban_card.dart`
- Modify: `wing_link/internal/app/` typed project handlers
- Modify: `lib/router/app_routes.dart`
- Modify: `lib/router/providers/app_router.dart`
- Modify: `lib/l10n/app_en.arb`
- Test: `wing_link/internal/app/project_test.go`
- Test: `test/core/wing_link/project_client_test.dart`
- Test: `test/features/kanban/kanban_screen_test.dart`
- Test: `integration_test/linux_project_kanban_e2e_test.dart`

**Interfaces:**

- Consumes: fixed Wing Link project operations translating opaque directory handles into Agent-owned Hermes Projects.
- Produces: profile/project-scoped board operations with local approval, revision/idempotency checks, and no Wing-owned workdir.

- [ ] Add RED Go tests for canonical containment, revoked handles, symlink escape, identity mismatch, replayed payloads, and bounded card fields.
- [ ] Add typed project operations only; reject arbitrary CLI and paths.
- [ ] Add board UI that renders Agent-owned project/card state and never persists a second board database.
- [ ] Add Linux native E2E covering directory grant → project → board → chat context.

---

### Task 9: Add local backup/import, debug dump, log viewer, and config health

**Files:**

- Create: `lib/features/settings/services/wing_backup_service.dart`
- Create: `lib/features/settings/widgets/wing_log_viewer.dart`
- Modify: `lib/features/settings/screens/settings_diagnostics_screen.dart`
- Modify: `lib/core/wing_link/wing_link_client.dart`
- Modify: `wing_link/internal/app/` bounded diagnostics handlers
- Modify: `lib/l10n/app_en.arb`
- Test: `test/features/settings/wing_backup_service_test.dart`
- Test: `test/features/settings/settings_diagnostics_screen_test.dart`
- Test: `wing_link/internal/app/diagnostics_test.go`
- Test: `integration_test/linux_settings_e2e_test.dart`

**Interfaces:**

- Consumes: platform file pickers and fixed Wing Link diagnostics/log contracts with bounded, redacted fields.
- Produces: encrypted or secret-free export/import with explicit scope, bounded log viewer, diagnostic checks, and repair actions only where a fixed operation exists.

- [ ] Add RED tests proving credentials, bearer tokens, transcripts, host paths, and private endpoints never enter exports or logs.
- [ ] Implement backup manifest versioning and atomic restore with a preflight summary; never silently overwrite Agent state.
- [ ] Implement log pagination/filters only over an allowlisted structured log contract.
- [ ] Add Linux native E2E with temporary files and redaction assertions.

---

### Task 10: Add account/OAuth/credential pools and wallet balances

**Files:**

- Create: `lib/core/hermes/models/hermes_account.dart`
- Create: `lib/core/hermes/models/hermes_wallet.dart`
- Create: `lib/features/account/screens/account_screen.dart`
- Modify: `lib/core/hermes/client/hermes_api_client.dart`
- Modify: `lib/core/hermes/channel/hermes_api_channel.dart`
- Modify: `lib/features/providers/screens/providers_screen.dart`
- Modify: `lib/l10n/app_en.arb`
- Test: `test/core/hermes/channel/hermes_api_channel_tests/account_tests.dart`
- Test: `test/features/account/account_screen_test.dart`
- Test: `playwright/tests/regression/hermes-account.spec.mjs`

**Interfaces:**

- Consumes: exact advertised account/OAuth/credential-pool/wallet endpoints and authorization scopes.
- Produces: read-only balance/account inventory and explicit OAuth flows; credential values remain write-only.

- [ ] Add RED tests for account-origin binding, OAuth callback expiry, token non-disclosure, and balance redaction.
- [ ] Implement only when the Agent capability document advertises the exact operations.
- [ ] Add fixture and E2E coverage without provider keys or real balances.

---

### Task 11: Add typed SSH/Docker/WSL remote backends

**Files:**

- Create: `lib/core/wing_link/models/wing_link_remote_backend.dart`
- Create: `lib/features/settings/screens/remote_backend_screen.dart`
- Modify: `lib/core/wing_link/wing_link_client.dart`
- Modify: `wing_link/internal/app/` remote backend handlers
- Modify: `lib/router/app_routes.dart`
- Modify: `lib/router/providers/app_router.dart`
- Modify: `lib/l10n/app_en.arb`
- Test: `wing_link/internal/app/remote_backend_test.go`
- Test: `test/core/wing_link/remote_backend_client_test.dart`
- Test: `integration_test/linux_remote_backend_e2e_test.dart`

**Interfaces:**

- Consumes: fixed host profiles, bounded transport settings, native credential storage, and lifecycle/health operations.
- Produces: remote Hermes host registration and health/restart flows without exposing arbitrary shell, command, executable, or host-path inputs.

- [ ] Add RED tests for host allowlists, credential separation, TLS/pin validation, timeout bounds, and replay identity.
- [ ] Implement one typed backend adapter at a time: SSH, Docker, then WSL, each with a removal/authority trigger.
- [ ] Add Linux E2E using deterministic fake host adapters; live qualification remains a separate receipt.

---

### Task 12: Complete web preview, file viewer, attachments, and media workflows

**Files:**

- Create: `lib/features/hermes_chat/presentation/hermes_web_preview.dart`
- Create: `lib/features/hermes_chat/presentation/hermes_file_viewer.dart`
- Modify: `lib/features/hermes_chat/composer/hermes_chat_message_flow.dart`
- Modify: `lib/features/hermes_chat/presentation/hermes_chat_timeline.dart`
- Modify: `lib/core/hermes/models/hermes_chat_turn.dart`
- Modify: `lib/l10n/app_en.arb`
- Test: `test/features/hermes_chat/presentation/hermes_web_preview_test.dart`
- Test: `test/features/hermes_chat/presentation/hermes_file_viewer_test.dart`
- Test: `test/features/hermes_chat/presentation/inline_transcript_image_safety_test.dart`
- Test: `playwright/tests/regression/hermes-media.spec.mjs`

**Interfaces:**

- Consumes: Agent-advertised bounded attachment/media/web-preview contracts and locally approved directory handles.
- Produces: accessible previews, bounded file metadata/content only where explicitly authorized, safe image/audio handling, and no arbitrary path submission.

- [ ] Add RED tests for MIME/size/dimension limits, unsafe URLs, path containment, download cancellation, and redacted errors.
- [ ] Implement platform-native file selection and capability-gated Agent transport.
- [ ] Add Linux/web E2E for text/image attachment and preview failure paths.

---

### Task 13: Add accessible Office parity and optional 3D adapter

**Files:**

- Modify: `lib/features/office/screens/office_screen.dart`
- Create: `lib/features/office/screens/office_3d_screen.dart`
- Create: `lib/features/office/services/office_adapter.dart`
- Modify: `lib/l10n/app_en.arb`
- Test: `test/features/office/office_screen_test.dart`
- Test: `integration_test/linux_office_e2e_test.dart`

**Interfaces:**

- Consumes: existing gateway/profile/session status models and an optional local Claw3d adapter contract.
- Produces: a fully operable 2D accessible Office as the default; 3D is additive and never the only path.

- [ ] Add RED accessibility tests for keyboard/focus/semantics/reduced motion and status equivalence.
- [ ] Improve the 2D route first with search, status, session counts, and exact contact activation.
- [ ] Add 3D only behind a local capability check with an accessible equivalent and no domain state duplication.
- [ ] Add Linux E2E for both reduced-motion and optional-3D-unavailable paths.

---

### Task 14: Add updater and richer Linux desktop window/install flows

**Files:**

- Create: `lib/core/updates/wing_update_manifest.dart`
- Create: `lib/core/updates/wing_update_service.dart`
- Create: `lib/features/settings/screens/update_screen.dart`
- Modify: `linux/runner/`
- Modify: `scripts/install_linux.sh`
- Modify: `scripts/run_linux_release_build.sh`
- Modify: `lib/l10n/app_en.arb`
- Test: `test/core/updates/wing_update_service_test.dart`
- Test: `test/app/desktop_host_command_listener_test.dart`
- Test: `integration_test/linux_update_e2e_test.dart`

**Interfaces:**

- Consumes: signed/versioned update manifests and atomic local activation/rollback primitives.
- Produces: update check/download/verify/apply/rollback UI and native menu/window behavior with no unsigned activation.

- [ ] Add RED tests for signature/digest mismatch, downgrade, interrupted download, rollback, and update-channel policy.
- [ ] Implement verification before activation and preserve the currently running version until local health passes.
- [ ] Add Linux native E2E against a local signed fixture; never claim distribution support from a mock alone.

---

### Task 15: Expand the slash-command catalog and command execution

**Files:**

- Create: `lib/features/hermes_chat/composer/hermes_slash_command_catalog.dart`
- Modify: `lib/features/hermes_chat/screens/hermes_chat_screen.dart`
- Modify: `lib/features/hermes_chat/composer/hermes_chat_message_flow.dart`
- Modify: `lib/features/hermes_chat/state/hermes_chat_layout.dart`
- Modify: `lib/core/hermes/channel/hermes_channel.dart`
- Modify: `lib/l10n/app_en.arb`
- Test: `test/features/hermes_chat/composer/hermes_slash_command_catalog_test.dart`
- Test: `test/features/hermes_chat/screens/hermes_chat_slash_commands_test.dart`
- Test: `playwright/tests/regression/hermes-slash-commands.spec.mjs`

**Interfaces:**

- Consumes: an Agent command catalog/completion contract, plus local commands that Wing can execute without backend mutation.
- Produces: curated suggestions for `/fast`, `/web`, `/image`, `/browse`, `/code`, `/shell`, `/usage`, `/compact`, `/compress`, `/undo`, `/debug`, `/status`, `/model`, `/memory`, `/persona`, `/version`, and advertised skill commands.

- [ ] Add RED tests proving unknown commands are not presented as supported, skill commands remain discoverable, and terminal-only commands are not silently simulated.
- [ ] Implement catalog filtering from Agent capability/completion data; dispatch backend-owned commands through the typed Agent route.
- [ ] Keep local commands explicit and bounded; never execute arbitrary shell text from a slash command.
- [ ] Add deterministic fixture and Playwright coverage for suggestion, dispatch, error, and cancellation behavior.

---

### Task 16: Linux parity gate and evidence receipts

**Files:**

- Modify: `scripts/run_linux_e2e.sh`
- Modify: `.github/workflows/hermes-platform-smoke.yml`
- Modify: `playwright/README.md`
- Create: `docs/runbooks/linux/e2e.md`
- Test: `test/tooling/package_scripts_contract_test.dart`

**Interfaces:**

- Consumes: every completed Linux-capable slice’s deterministic fixture and native test target.
- Produces: one reproducible `npm run linux:e2e` command, bounded test receipts, and CI evidence that distinguishes fixture coverage from live Hermes/platform qualification.

- [ ] Add each completed slice to the native Linux fixture without credentials or private endpoints.
- [ ] Keep `xvfb-run`, GTK/libsecret/GStreamer preflight, timeout, and artifact behavior deterministic.
- [ ] Upload Linux E2E logs/screenshots on failure while excluding secrets, transcripts, and host paths.
- [ ] Run the complete Linux gate in CI after unit/analyze checks and before release artifact publication.
- [ ] Run: `npm run linux:e2e`, `npm run web:e2e`, `flutter analyze`, `flutter test --concurrency=1`, and `git diff --check`.

---

## Dependency order and completion rule

1. Task 1 must land before any new route or mutation is advertised.
2. Tasks 2, 3, 4, 5, 6, 7, and 15 require matching Hermes Agent capability fixtures and official contract evidence.
3. Task 8 and Task 11 require reviewed Wing Link typed operations and security tests before UI work.
4. Tasks 9, 12, 13, 14, and 16 can proceed with deterministic local fixtures but cannot upgrade platform-support claims without named-target runtime evidence.
5. Every task is complete only when its focused unit/widget tests, deterministic E2E test, security/redaction checks, docs/status update, and relevant Linux receipt pass.
6. The full Desktop feature list is not complete merely because a route renders. It is complete only when the underlying authoritative operation works, is capability-gated, reconciles server state, and has a regression test.
