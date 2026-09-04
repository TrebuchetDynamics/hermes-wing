# Hermes Wing Agent Guide

Hermes Wing is an independent cross-platform Flutter client for Hermes Agent
and is developed with local upstream reference clones of Hermes Agent and
Hermes Desktop. Hermes Agent owns agent/domain state; Wing Link is the
authenticated host management plane. Preserve that boundary in every design,
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

Two full upstream repositories are cloned inside this worktree for development
reference:

- `hermes-agent/` → `https://github.com/NousResearch/hermes-agent`
- `hermes-desktop/` → `https://github.com/fathah/hermes-desktop`

Use these clones before guessing Hermes contracts or Desktop behavior:

- Inspect `hermes-agent/` for current APIs, models, profile/configuration
  authority, session semantics, gateway behavior, CLI compatibility, and tests.
- Inspect `hermes-desktop/` for interaction patterns, terminology, and parity
  research. Reproduce user outcomes with Flutter and platform-native Wing
  patterns; do not port Electron internals line-for-line.
- Read each reference repository's own `AGENTS.md` before inspecting it deeply or
  proposing changes within it.
- Treat both directories as read-only reference material unless the user
  explicitly requests an upstream change. Do not include them in Wing formatting,
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
- **Wing Link**: the authenticated remote management plane for host setup,
  pairing, lifecycle, health, diagnostics, directory grants, and reviewed typed
  compatibility operations. It is not a proxy, shell bridge, or second backend.
- **Hermes Agent data plane**: direct authenticated Agent API traffic for chat,
  sessions, runs, tools, approvals, and advertised administration. It does not
  transit Wing Link.
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

A paired host has two independent connections and credentials:

1. Wing → Hermes Agent for the data plane.
2. Wing → Wing Link for host management.

Never merge these credentials, route Agent traffic through Wing Link, or create
shadow copies of Agent-owned domain state.

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

### Wing Link

Every compatibility operation must have:

- a fixed executable and argument shape;
- no shell and no caller-selected executable, command, config key, URL, or host
  path;
- typed and bounded input, output, duration, and errors;
- exact authorization and stable resource identity;
- no shadow domain state; and
- a removal trigger for when Hermes Agent exposes the authoritative API.

The current profile compatibility adapter is limited to profile
list/create/rename/delete and transactional **new-profile** setup: description,
allowlisted provider, bounded model string, stdin-only provider credential, and
bounded readiness probing. During fixed pairing bootstrap it may also resolve
listed profile credentials through `hermes --profile <id> config env-path`,
enable profile multiplexing, and restart the active gateway before verifying
`/p/<id>` connections. These narrow operations do not authorize existing-profile
provider/config mutation, general configuration, sessions, messages, tools,
schedules, or arbitrary CLI.

Wing Link supports only the current and immediately previous protocol generation.
Lifecycle and update work must preserve transactional activation, local health
checks, digest/signature verification, and rollback behavior.

### Directories and Projects

- Directory navigation starts at locally approved, revocable roots.
- Remote clients use opaque handles; they never submit or receive arbitrary
  absolute host paths.
- Revalidate canonical containment and grant status on every lookup; prevent
  symlink escape.
- Return bounded child-folder listings only—never file names, file metadata, or
  file contents.
- Translate an approved handle into a path only inside a fixed Project operation.
  Hermes Agent remains the Project authority.

## Security and privacy

Treat credentials, pairing codes, transcripts, recognized speech, private
endpoints, host paths, and provider keys as sensitive.

- Provider secrets are write-only. They may use an advertised secret-safe Agent
  API or the reviewed transactional new-profile path that sends credential bytes
  through stdin. Existing-profile compatibility secret mutation remains blocked.
- Never place secrets in argv, URLs, QR payloads, clipboards, shared text,
  ordinary preferences, responses, logs, diagnostics, screenshots, fixtures, or
  audit request bodies.
- Store credentials only in platform secure storage. Hermes Agent and Wing Link
  credentials remain separate.
- Pairing handoffs carry only a random single-use code, never a bearer token. The
  code expires after five minutes, must not be persisted or analyzed, and any
  handoff page must send `Cache-Control: no-store`.
- Explicit paste is a user action, not background clipboard monitoring; discard
  raw handoff text immediately after parsing.
- HTTP is loopback-only. Wing Link may bind loopback plus at most one local
  private-LAN, NetBird, or Tailscale interface; every non-loopback listener
  requires TLS 1.3 and authenticated device credentials. Native clients pin the reviewed TLS
  key's SHA-256 SPKI fingerprint; a changed or missing pin fails closed and
  requires explicit re-pairing. Network location is never authorization.
- Remote devices may inspect and revoke only themselves. Permission expansion,
  peer administration, host identity rotation, sensitive writes, destructive
  actions, and install/update approval remain local trust decisions.
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
- `lib/core/wing_link/`: Flutter-side Wing Link models and client boundary.
- `lib/features/`: product vertical slices and screens.
- `lib/router/`, `lib/app/`, `lib/shared/`, `lib/theme/`, `lib/l10n/`: shell,
  navigation, shared UI/policies, theming, and localization.
- `wing_link/`: Go host-management service and CLI. Keep it outside Agent domain
  ownership.
- `hermes-agent/`: permanent, read-only upstream Agent reference clone; not part
  of the Wing product, build, validation, or commit scope.
- `hermes-desktop/`: permanent, read-only upstream Desktop reference clone for
  parity and UX research; not part of the Wing product, build, or commit scope.
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
- `scripts/`, `.github/workflows/`, `install-wing-link.sh`: validation, smoke,
  release, and installation paths.
- `third_party/` and `vendor/`: imported code; avoid broad formatting or edits
  outside an explicit dependency task.

Toolchain: Flutter 3.44.2, Node.js 22, and Go 1.26 for Wing Link changes. Initial
setup is `flutter pub get` and `npm ci`.

## Worktree and change discipline

- Preserve unrelated dirty-worktree changes. Read before editing and inspect only
  your diff before completion.
- Never use destructive Git commands, broad generated-file cleanup, or repository-
  wide formatting to solve a scoped task.
- Do not commit or stage credentials, transcripts, private endpoint URLs, generated
  Agent/runtime state, local tool state, build output, or test screenshots.
- Do not commit, push, create branches, or modify external systems unless the user
  explicitly asks.
- Keep comments focused on invariants and reasons; do not narrate obvious code.
- Update product docs when user-visible support or terminology changes. Update an
  ADR only for a cross-cutting, expensive-to-reverse decision.

## Validation

Run the smallest relevant check while iterating, then the checks proportional to
the affected boundary.

- Dart/Flutter: format changed Dart files, run `flutter analyze`, and run the
  nearest `flutter test` target.
- Wing Link: run `gofmt` on changed Go files and `(cd wing_link && go test ./...)`.
- Localization: run `flutter gen-l10n`, then analyze and test the affected UI.
- Browser behavior: build the deterministic E2E target before Playwright.
- Security, protocol, installer, release, or cross-plane changes: run the focused
  contract tests plus the broader affected suite; compilation alone is not proof.
- Documentation-only changes: run `git diff --check` and verify changed local
  links/commands.

Complete gate:

```bash
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze
flutter test --concurrency=1
(cd wing_link && go test ./...)
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

- confirm the change respects Agent/Wing Link authority and capability gating;
- review the diff for secrets, private data, host paths, shadow state, and
  unrelated edits;
- add or update the smallest regression test for non-trivial behavior;
- run and report exact relevant validation commands and failures;
- state which platforms were actually exercised; and
- note any unsupported or unverified behavior without upgrading it to a support
  claim.
