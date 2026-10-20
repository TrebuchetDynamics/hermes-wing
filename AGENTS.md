# Hermes Wing Agent Guide

Hermes Wing is an independent cross-platform Flutter client for Hermes Agent
and is developed with local upstream reference checkout of Hermes Agent and its official
Desktop app under `apps/desktop/`. Hermes Agent owns all agent/domain state; Wing connects directly without a
second management service. Preserve that boundary in every design,
implementation, test, and user-facing claim.

## Start here

Before editing:

1. Run `git status --short --branch`. The worktree may contain unrelated user
   changes; never reset, clean, checkout, stage, or overwrite them.
2. Read [CONTEXT.md](CONTEXT.md) and [CONTRIBUTING.md](CONTRIBUTING.md).
3. Read [docs/adr/README.md](docs/adr/README.md) and the living ADRs relevant to
   the change. For security or trust-boundary work, also read
   [SECURITY.md](SECURITY.md) and the
   [threat model](docs/security/threat-model.md). For navigation or capability
   wording, read [docs/product/routes.md](docs/product/routes.md).
4. Inspect the live implementation and its nearest tests. Historical plans and
   generated codebase maps are leads, not current authority.

Living ADRs define hard boundaries. Live code and tests show current behavior.
Route status and runbooks describe current support. Historical specs, plans,
screenshots, and generated maps are not proof that a capability ships.

## Permanent upstream references

The official Desktop subtree is the only product reference. Prior comparisons
from the retired separate checkout are not official parity evidence. See
[reference correction](docs/quality/official-desktop-reference.md).

One read-only upstream repository provides both authoritative references:

- `hermes-agent/` → `https://github.com/NousResearch/hermes-agent`
- `hermes-agent/apps/desktop/` → `https://github.com/NousResearch/hermes-agent/tree/main/apps/desktop`

Use these clones before guessing Hermes contracts or Desktop behavior:

- Inspect `hermes-agent/` for current APIs, models, profile/configuration
  authority, session semantics, gateway behavior, CLI compatibility, and tests.
- Inspect `hermes-agent/apps/desktop/` for interaction patterns, terminology, and parity
  research. Reproduce user outcomes with Flutter and platform-native Wing
  patterns; do not port Electron internals line-for-line.
- Read each reference repository's own `AGENTS.md` before inspecting it deeply.
- Hermes Agent must never be modified: its reference checkout, installed runtime,
  copies and forks are not implementation targets. No patches, monkey-patches or
  Wing-specific Agent builds; do not request an upstream-edit exception to unblock
  missing capabilities. See the
  [hard ADR](docs/adr/runtime-and-delivery.md#hard-boundary-never-modify-hermes-agent).
- Treat the Agent checkout and its Desktop subtree as read-only reference material. Do not include them in Wing formatting,
  tests, staging, commits, searches intended only for Wing, or dependency graphs.
- Their current checkout is evidence of that checkout only. Hermes Agent remains
  authoritative at runtime, and advertised API capabilities remain more reliable
  than assumptions copied from either client.
- Never patch Wing around an apparent upstream contract until the Agent source,
  nearest upstream tests, Wing caller, and Wing regression test have been traced.

## Product language and authority

Use these names consistently:

- **Hermes Wing**: the Android, web, and desktop client. Do not call it a
  companion app or an Electron clone.
- **Hermes Agent**: the authoritative runtime for profiles, Hermes Projects,
  providers, models, configuration, memory, skills, sessions, runs, tools,
  schedules, approvals, and gateway state.
- **Hermes Agent data plane**: direct authenticated Agent API traffic for chat,
  sessions, runs, tools, approvals, and advertised administration. It does not
  transit a management proxy.
- **Hermes Project**: an Agent-owned per-profile workspace. Use it for repository
  or subfolder assignment; never create a Wing-owned profile `workdir`.
- **Directory grant**: a locally approved host root exposed through opaque
  handles, not an unrestricted saved path.
- **Capability parity**: equivalent user outcomes through platform-native
  implementation, not a line-for-line Desktop port.
- **Accessible equivalent**: a fully operable path that does not depend on 3D,
  canvas, pointer, speech, motion, sound, or color alone.
- **Detached run**: Agent-owned work that continues while Wing is suspended and
  is reconciled when Wing returns.

Saved Agent credentials and exact endpoint/profile/session identities must survive
upgrades. Legacy raw records and secure slots are inert and preserved; missing
Agent credentials require direct reauthentication. Legacy handoffs are discarded.

## Non-negotiable architecture rules

### Agent APIs and state

- Prefer an advertised Hermes Agent API. Gate behavior on the exact operation,
  required grant, and current resource identity—not a broad version or `admin`
  flag.
- Keep profile, Project, directory, and other resource identities explicit on
  requests. Never use global `profile use` or `project use` side effects.
- Server state wins after reconnect. Cached reads and drafts may remain visible,
  but Wing must not silently replay queued mutations.
- Use revisions or another authoritative concurrency check where edits can
  collide. Report persistence success separately from reload/restart success.
- Unsupported operations must be hidden or clearly explained. Never simulate
  support with unreliable local state.

### Local integration and Projects

Local discovery is metadata-only and its chooser is ephemeral, not an Agent
Project selector. Android uses explicit manual Agent preparation in the separate
Termux sandbox. Native SSH is an authenticated forward, not lifecycle authority.
Missing Project assignment, directory browsing, host lifecycle and peer management
stay unavailable until exact authoritative Agent contracts are verified. No shell
bridge, caller-selected executable/config key/path or shadow backend is allowed.

## Security and privacy

Treat credentials, pairing codes, transcripts, recognized speech, private
endpoints, host paths, and provider keys as sensitive.

- Provider secrets are write-only and require an exact advertised secret-safe Agent
  API. Never put them in argv, URLs, clipboard, responses, logs or ordinary preferences.
- Store credentials only in platform secure storage. Do not read or delete inert
  legacy management slots or raw records as part of retirement.
- Legacy intent/share input is discarded without parsing, display or persistence.
  No pairing, scanner, bootstrap or management fallback is offered.
- HTTPS validates origins/certificates; native SSH verifies the host fingerprint.
  Non-local Agent HTTP requires explicit consent on an authenticated encrypted VPN
  or isolated trusted LAN. Network location is never authorization.
- Bind retries and approvals to device, route, idempotency key, resource identity,
  and payload digest. A changed replay must fail.
- Diagnostics and audit events must be bounded, allowlisted, and path/content
  redacted.

Do not weaken validation, authorization, redaction, containment, transport, or
rollback behavior to reduce implementation effort.

## Client implementation conventions

- Reuse existing Riverpod providers, `HermesChannel` contracts, API clients,
  models, adaptive routing, and test overrides before introducing another seam.
- Keep transport/domain behavior under `lib/core/`; keep feature composition under
  `lib/features/`; put genuinely cross-feature presentation/security utilities
  under `lib/shared/`.
- Share domain behavior across platforms, but use native or adaptive presentation
  when it is simpler and preserves the outcome.
- Keep UI available without speech, sound, motion, pointer precision, canvas, 3D,
  or color-only cues. Preserve semantics, keyboard operation, focus behavior,
  readable contrast, and reduced-motion behavior where applicable.
- Prefer the smallest root-cause fix in the shared path. Inspect all callers of a
  changed contract and add the smallest regression test that proves non-trivial
  behavior.
- Do not add speculative abstractions, dependencies, fallback state, protocol
  fields, routes, or platform claims.
- Edit `lib/l10n/app_en.arb` for English copy and regenerate localization output;
  do not hand-edit `app_localizations*.dart`.
- Keep provider values, transcripts, credentials, and private endpoints out of
  test fixtures. Use deterministic fakes and redacted examples.

## Repository map

- `lib/core/hermes/`: Agent models, policies, API transport, channel state, SSE,
  reconciliation, and secure endpoint setup.
- `lib/features/`: product vertical slices and screens.
- `lib/router/`, `lib/app/`, `lib/shared/`, `lib/theme/`, `lib/l10n/`: shell,
  navigation, shared UI/policies, theming, and localization.
- `hermes-agent/`: permanent, read-only upstream Agent reference clone; not part
  of the Wing product, build, validation, or commit scope.
- `hermes-agent/apps/desktop/`: official Desktop product and UX reference inside the read-only Agent checkout.
- `test/`: Dart unit, widget, source-contract, and platform tests; mirror the
  production area when practical.
- `integration_test/`: Flutter integration flows and deterministic support code.
- `playwright/` and `serve_web.mjs`: browser E2E tests and deterministic Hermes
  fixture.
- `android/`, `ios/`, `linux/`, `macos/`, `windows/`, `web/`: platform hosts and
  native integrations.
- `docs/adr/`: living architectural guardrails; update an existing ADR before
  proposing another.
- `docs/runbooks/`, `docs/security/`, `docs/product/`: operational evidence,
  security contracts, and route status.
- `scripts/`, `.github/workflows/`, application installers: validation, smoke,
  release, and installation paths.
- `third_party/` and `vendor/`: imported code; avoid broad formatting or edits
  outside an explicit dependency task.

Toolchain: Flutter 3.44.2, Node.js 22. Initial
setup is `flutter pub get` and `npm ci`.

## Worktree and change discipline

- Preserve unrelated dirty-worktree changes. Read before editing and inspect only
  your diff before completion.
- Never use destructive Git commands, broad generated-file cleanup, or repository-
  wide formatting to solve a scoped task.
- Do not commit or stage credentials, transcripts, private endpoint URLs, generated
  Agent/runtime state, local tool state, build output, or test screenshots.
- Canonical `main` remains protected. The user explicitly authorizes isolated
  task branches/worktrees for offline Wing work and scoped local commits. Use
  the supported native isolated worker path; keep one writer per task workspace
  and preserve unrelated canonical changes. This exception supersedes the former
  blanket main-only development rule for offline task work only. No push, PR,
  deployment, live operation, concurrent canonical implementation write or admission
  bypass is authorized. Use isolated native execution, not the unsupported
  main-only executor; canonical integration follows the Autowork policy below.
  Parallel agents may investigate or review read-only.
- Offline-task commit authority covers its owned task branch only. Canonical
  local integration is authorized under the Autowork policy below after required
  checks; remote delivery still needs applicable publication authorization.
  The offline exception grants no push or PR authority; preserve remote protection and report a blocked delivery rather than bypassing it.
- Before deleting legacy branch refs, retain a verified private archive of
  unmerged commits. Branch deletion never means discarding dirty files or
  treating unqualified work as integrated.
- Local integration of verified Autowork work is authorized below. Releases,
  deployments, destructive history changes and unrelated external-system changes
  still require applicable explicit authorization.
- Keep comments focused on invariants and reasons; do not narrate obvious code.
- Update product docs when user-visible support or terminology changes. Update an
  ADR only for a cross-cutting, expensive-to-reverse decision.

## Validation

The runner's whole offline Flutter test-suite entry point is:

Full check: flutter pub get --offline --enforce-lockfile && flutter test --no-pub --concurrency=1

This prepares checkout-local package metadata from the existing dependency cache
without network access or lockfile changes. It does not replace the applicable
formatting, analysis, browser, security or native qualification gates below, and
it does not authorize live tests.

Run the smallest relevant check while iterating, then the checks proportional to
the affected boundary.

- Dart/Flutter: format changed Dart files, run `flutter analyze`, and run the
  nearest `flutter test` target.
- Localization: run `flutter gen-l10n`, then analyze and test the affected UI.
- Browser behavior: build the deterministic E2E target before Playwright.
- Security, protocol, installer, release, or cross-plane changes: run the focused
  contract tests plus the broader affected suite; compilation alone is not proof.
- Documentation-only changes: run `git diff --check` and verify changed local
  links/commands.

Full release/cross-boundary gate (not a prerequisite for every documentation or
focused local task; use the relevant checks above for those):

```bash
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze
flutter test --concurrency=1
flutter build web --release -t lib/main_e2e.dart
npm run web:e2e
npm audit
git diff --check
```

Regenerate README/landing visuals only after relevant UI changes:

```bash
npx playwright install chromium
npm run readme:assets
```

Do not claim platform, microphone, speech, acoustic, service, release, update,
rollback, or signed-distribution support without matching runtime evidence on the
named target. Deterministic fixtures and compilation do not replace physical or
platform qualification.

## Definition of done

Before reporting completion:

- confirm the change respects Agent authority and capability gating;
- review the diff for secrets, private data, host paths, shadow state, and
  unrelated edits;
- add or update the smallest regression test for non-trivial behavior;
- run and report exact relevant validation commands and failures;
- state which platforms were actually exercised; and
- note any unsupported or unverified behavior without upgrading it to a support
  claim.

<!-- autowork-local-authority:start -->
## Autowork: autonomous local progress

An Autowork invocation or recurring Autowork job authorizes routine local
repository improvement: plan, implement, test, document and make scoped local
commits. Choose reasonable reversible implementation details without waiting for
an owner, parent session or another profile to approve them. This section replaces
older owner-acknowledgement and blanket main-only development requirements for
that local work; it does not override product safety or explicit task exclusions.

- Read the current task and repository state. Repair attributable task metadata,
  links and missing backlog structure from source evidence; preserve existing
  decisions and never invent acceptance, ownership release or completed checks.
- If no task is runnable, inspect implementation, tests, docs and UI/accessibility
  for a concrete improvement. Record a bounded task with acceptance criteria and
  dependencies, then execute it. Keep a few independent ready tasks when evidence
  supports them; do not manufacture busywork or count planning as implementation.
- Separate offline implementation and tests from device, production and other
  live qualification. Complete the local task while retaining an explicit pending
  live task; never mark the combined feature qualified from offline evidence.
- Use supported isolated task branches/worktrees when needed. Keep one writer per
  workspace. A historical ACTIVE claim alone is not a permanent veto: check actual
  worker/session activity and candidate changes. Preserve prior work; adopt an
  idle candidate only after verifying it is no longer being written. If activity
  cannot be established, select non-overlapping work instead of guessing.
- The current Autowork coordinator may review and integrate its verified local
  changes into canonical main without a separate parent/owner acknowledgement.
  Serialize canonical writes, inspect fresh status, preserve unrelated dirty
  work, and use the supported integration path. Do not bypass runtime guards,
  repin evidence to hide drift, force-push, reset or discard another writer's work.
- After a repeated blocker, take a different concrete action in the same run:
  repair the local cause, execute independent work, or report one precise external
  input that is genuinely unavailable. Do not repeatedly audit the same hold.
- Run checks proportional to the change. Commit only attributable, verified work.
  Report task ID/title, actual changes, checks, commit, next task and exact remaining
  blocker. Distinguish local commit, integration, push and live acceptance.
- Existing explicit publication authority remains valid; this policy alone does
  not authorize remote publication, deployment, money movement, secret access or
  destructive/live operations. Preserve paused jobs and task-specific exclusions.
<!-- autowork-local-authority:end -->
