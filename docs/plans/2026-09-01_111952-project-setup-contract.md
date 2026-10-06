# Hermes Project Setup Contract Implementation Plan

> Historical planning record. Findings, status, commands, and proposals below
> describe the dated snapshot, not current support or authorization to expand
> Wing Link. Follow the [living ADRs](../../docs/adr/README.md) and
> [current route status](../../docs/product/routes.md) before acting on this record.

> **For Hermes:** Execute this plan with strict RED→GREEN slices and fresh independent review after each coherent artifact.

**Goal:** Make a paired Wing client able to select an approved host folder and create an authoritative, profile-scoped Hermes Project without exposing arbitrary host paths or introducing Wing-owned workspace state.

**Architecture:** Implement the authority contract before the UI mutation. Hermes Agent remains the Project authority; Wing Link may only translate a device-bound opaque directory handle inside fixed, typed, bounded, per-profile Project operations. Wing continues to send chat directly to Hermes Agent, and project-aware Chat remains unavailable until Agent separately advertises an explicit session/project input.

**Tech Stack:** Go 1.26 Wing Link service, Flutter 3.44/Dart 3.12 with Riverpod, Hermes Agent CLI as a fixed compatibility target, existing Wing Link operation journal/idempotency/approval patterns, Flutter widget/unit tests and Go tests.

---

## Baseline and decisions

- The current working tree is heavily modified. Preserve every unrelated change; stage only exact files from each slice.
- Current Wing already browses locally approved roots and child folders using opaque handles in `lib/features/profiles/widgets/profile_directory_browser_sheet.dart`.
- The current UI deliberately provides no Select action and explains that Project creation is unavailable.
- Hermes Agent currently owns per-profile Projects in `$HERMES_HOME/projects.db` and exposes fixed CLI operations under `hermes project`; its public HTTP capability document does not advertise Project administration.
- Do not add `terminal.cwd`, `repos.json`, raw paths, `profile use`, or `project use` to Wing.
- Initial scope is deliberately small: list Projects and create one Project with one selected folder as primary. Multi-folder editing, archive/restore, and Project-aware Chat follow later.

## Acceptance criteria

1. An authorized paired device can list Projects for an explicit profile through a typed, bounded compatibility operation.
2. It can create one Project for an explicit profile from one valid opaque directory handle and make that folder primary.
3. The remote request and response never contain an absolute host path.
4. Every lookup revalidates device binding, grant status, canonical containment, and directory existence immediately before execution.
5. The adapter invokes only a fixed executable and fixed argument shape; no shell, caller-selected executable, arbitrary flags, or global active-profile/project mutation.
6. A repeated identical request with the same idempotency key returns the same durable result; a changed payload fails.
7. Unsupported protocol generations, missing capabilities/scopes, revoked handles, wrong-device handles, and stale handles fail closed.
8. Wing shows Select/Create only when exact Project capabilities and grants are present; otherwise the current honest unavailable state remains.
9. Creating a Project refreshes authoritative Project inventory. Wing stores no Project copy beyond ordinary in-memory read state.
10. Chat does not silently acquire Project context. A separate advertised direct-Agent session contract is required.

## Task 1: Freeze the typed Wing Link contract

**Objective:** Specify the smallest list/create Project compatibility surface and its security invariants before production code.

**Files:**
- Modify: `docs/adr/runtime-and-delivery.md`
- Modify: `docs/product/gateway-profile-management.md`
- Modify: `docs/product/hermes-compatibility.md`
- Modify: `docs/product/wing-link.md`
- Modify: `ROADMAP.md`
- Test: `test/tooling/wing_link_docs_contract_test.dart`

**Steps:**
1. Add a failing docs-contract test requiring exact operation names, grants, explicit profile identity, opaque-handle input, path-free output, idempotency binding, and the no-Chat-context boundary.
2. Run `flutter test test/tooling/wing_link_docs_contract_test.dart` and verify RED because the contract language is absent.
3. Update the living runtime ADR first, expanding the reviewed compatibility exception only to Project list and single-primary-folder Project create.
4. Update product docs and roadmap to match the ADR exactly; do not describe multi-folder mutation as shipped.
5. Run the focused test and `git diff --check`; verify GREEN.
6. Independently review the exact staged snapshot for boundary widening, contradictions, and unsupported claims before committing.

## Task 2: Add bounded Project models and validation in Wing Link

**Objective:** Define path-free public request/response types and strict validation.

**Files:**
- Create or modify the nearest existing Project model file under `wing_link/internal/state/` or `wing_link/internal/operation/` after tracing neighboring patterns; do not create a new package if an existing operation model fits.
- Test: matching `*_test.go` beside the implementation.

**Contract shape:**
- List input: explicit validated `profile_id`.
- Create input: explicit `profile_id`, bounded Project display name, optional bounded slug only if required by the existing CLI contract, opaque `directory_handle`, and required idempotency key.
- Response: stable Project ID/slug/name and opaque folder identity or display label only; never a resolved path.

**Steps:**
1. Write table-driven failing tests for valid input and rejection of empty/oversized names, malformed profile IDs, malformed handles, unknown fields where strict decoding applies, and invalid idempotency keys.
2. Run the nearest Go test and verify RED.
3. Implement minimal bounded models using existing validation/error conventions.
4. Run the focused Go test and verify GREEN.
5. Refactor only duplication introduced by this slice and rerun the test.

## Task 3: Revalidate and resolve opaque handles internally

**Objective:** Translate an authorized opaque handle to a canonical host directory only inside the fixed operation.

**Files:**
- Modify: nearest directory-grant resolver under `wing_link/internal/` found by tracing `listDirectoryRoots` and child-directory handlers.
- Test: matching directory/grant tests.

**Steps:**
1. Write failing tests for valid same-device resolution and failure on revoked grant, wrong device, expired/stale handle, missing directory, regular file, traversal, and symlink escape.
2. Assert that public errors and audit data contain no absolute path.
3. Run the focused Go test and verify RED.
4. Add the smallest internal resolver/revalidation seam reusable by the Project operation; do not expose it as a generic path API.
5. Run the focused tests and verify GREEN.

## Task 4: Implement the fixed Hermes Project adapter

**Objective:** Invoke Hermes Project list/create with a fixed, profile-explicit argument vector and bounded machine-readable parsing.

**Files:**
- Modify: the existing Wing Link Hermes compatibility adapter package used for profile operations.
- Test: matching adapter tests using deterministic fake executable/process seams already present in the package.

**Steps:**
1. Confirm the pinned supported Hermes release's exact CLI output and available machine-readable mode from source/tests; if no stable machine-readable create/list output exists, stop and revise the contract rather than scraping prose.
2. Write failing adapter tests that capture argv and stdin and prove:
   - explicit `--profile <id>` placement;
   - fixed `project list/create` operation;
   - no shell;
   - no `project use` or `--use`;
   - resolved path appears only in the host-local child argv and never in returned payload/logs;
   - timeout, output size, malformed output, and partial failure are bounded.
3. Run focused tests and verify RED.
4. Implement list/create only.
5. Run focused tests and verify GREEN.
6. If upstream lacks stable JSON output, open/record the Hermes Agent contract blocker and do not ship a fragile parser.

## Task 5: Add authorization, operation journal, and capability advertisement

**Objective:** Expose Project operations through Wing Link with exact grants and durable replay behavior.

**Files:**
- Modify: Wing Link capability metadata and route registration files discovered from current profile operation routes.
- Modify: `wing_link/internal/operation/journal.go` only if its current generic binding cannot represent the new payload/resource identity.
- Modify: relevant approval/authorization code only where exact new grants are registered.
- Test: route, authorization, journal, and state tests nearest those files.

**Steps:**
1. Write failing tests for exact read/write grants, protocol-generation gating, resource/payload digest binding, identical replay, changed replay rejection, and path-redacted audit events.
2. Run focused Go tests and verify RED.
3. Register exact capabilities, for example distinct Project list and create operation IDs; avoid a broad `admin` or generic command grant.
4. Wire list/create through the internal handle resolver and fixed adapter.
5. Run focused Go tests and verify GREEN.
6. Run `(cd wing_link && go test ./...)`.

## Task 6: Add Flutter Project models and Wing Link client methods

**Objective:** Parse and call the exact path-free Project contract from Wing.

**Files:**
- Create: `lib/core/wing_link/models/wing_link_project.dart` if no neighboring model is suitable.
- Modify: `lib/core/wing_link/wing_link_client.dart`
- Modify: `lib/core/protocol/serialization/wing_json.dart` only if existing bounded helpers need reuse.
- Test: `test/core/wing_link/wing_link_client_test.dart`
- Test: `test/core/protocol/serialization/wing_json_test.dart` only for any new shared parser behavior.

**Steps:**
1. Write failing client tests for list/create requests, exact explicit fields, capability/scope failure, bounded parsing, unknown/malformed response rejection, and absence of host paths.
2. Run focused Flutter tests and verify RED.
3. Implement minimal immutable models and client methods using existing client/error patterns.
4. Run focused tests and verify GREEN.
5. Format only changed Dart files.

## Task 7: Turn folder browsing into Project creation when authorized

**Objective:** Add one end-to-end UI tracer: select an approved folder, name a Project, create it, and show the authoritative result.

**Files:**
- Modify: `lib/features/profiles/widgets/profile_directory_browser_sheet.dart`
- Create or modify: a focused Project creation sheet under `lib/features/profiles/widgets/` only if composition cannot remain small.
- Modify: `lib/features/profiles/screens/profiles_screen.dart`
- Modify: `lib/l10n/app_en.arb`
- Regenerate: Flutter localization outputs via `flutter gen-l10n`.
- Test: `test/features/profiles/profile_directory_browser_sheet_test.dart`
- Test: `test/features/profiles/profiles_screen_test.dart`

**Steps:**
1. Write one failing widget test proving a valid folder can be selected only when exact create capability and grant are injected, and that submission sends only profile ID, Project name, opaque handle, and idempotency key.
2. Run the focused test and verify RED.
3. Implement the minimal selection/create flow and refresh Project inventory after success.
4. Run the focused test and verify GREEN.
5. Write a second failing test proving unsupported/unauthorized clients retain the unavailable message and expose no Select/Create control or mutation call.
6. Implement minimal gating and verify GREEN.
7. Add focused tests for retry/replay UX, revoked-handle failure, keyboard traversal, large text, and redacted errors one behavior at a time.
8. Run `flutter gen-l10n`, format changed Dart files, and run both focused profile test files.

## Task 8: Add Project inventory without Project-aware Chat

**Objective:** Let users see authoritative Projects for the selected profile while preventing accidental global selection or implied Chat support.

**Files:**
- Modify: `lib/features/profiles/screens/profiles_screen.dart` or add the smallest profile-detail composition already consistent with current route patterns.
- Modify: localization source and regenerate.
- Test: `test/features/profiles/profiles_screen_test.dart`

**Steps:**
1. Write a failing widget test for explicit per-profile Project inventory and primary-folder label without exposing paths.
2. Verify RED, implement minimal read-only presentation, then verify GREEN.
3. Write a failing test proving tapping a Project does not call global `project use`, mutate profile selection, or open Chat without the direct Agent session capability.
4. Implement the explicit unavailable explanation and verify GREEN.

## Task 9: Verification, review, and shipping

**Objective:** Qualify the complete artifact honestly and preserve unrelated work.

**Focused commands:**
- `flutter test test/tooling/wing_link_docs_contract_test.dart`
- `flutter test test/core/wing_link/wing_link_client_test.dart`
- `flutter test test/features/profiles/profile_directory_browser_sheet_test.dart`
- `flutter test test/features/profiles/profiles_screen_test.dart`
- `(cd wing_link && go test ./...)`

**Relevant complete gate:**
- `dart format --output=none --set-exit-if-changed lib test integration_test`
- `flutter analyze`
- `flutter test --concurrency=1`
- `(cd wing_link && go test ./...)`
- `flutter build web --release -t lib/main_e2e.dart`
- `npm run web:e2e`
- `npm audit`
- `git diff --check`

**Steps:**
1. Review `git status --short --branch` and the exact diff; confirm no unrelated files, secrets, private paths, generated runtime state, or upstream-clone edits are staged.
2. Run the focused commands, then the relevant complete gate.
3. Build/install the exact Android artifact and exercise the paired-phone flow if shipping the feature; deterministic widget/web fixtures do not prove physical-device networking or secure-storage behavior.
4. Obtain fresh independent review of the exact final snapshot after the last code/test/localization/docs change.
5. Commit selectively, push, and require green CI before calling the feature shipped.

## Follow-up contract, not part of this implementation

Project-aware Chat requires a separate direct Hermes Agent capability that accepts explicit profile ID and Project ID (or another authoritative Project-bound session identity) when creating/opening a session. Plan that only after the Agent advertises it. Do not route chat through Wing Link and do not emulate it with `terminal.cwd`, global `project use`, or Wing-local state.

## Risks and blockers

- The pinned Hermes CLI may not provide stable machine-readable Project output. That blocks a safe compatibility adapter unless Hermes Agent adds JSON output or an advertised HTTP contract.
- Project paths currently exist in Agent-owned Project records. Wing Link must redact them from remote responses and replace them with opaque identity/display data.
- Directory handles are ephemeral; creation must revalidate immediately and surface revocation cleanly.
- A Project create may succeed while the client disconnects. Durable idempotency/replay must distinguish success from retry without executing twice.
- Existing working-tree changes are extensive. Every stage/review/commit must use exact paths and inspect the staged snapshot.
