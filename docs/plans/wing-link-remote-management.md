# Wing Link remote management implementation plan

Status: approved design; hardening, local grants, and remote directory browsing complete; Project mutation blocked on an Agent contract

**Goal:** Extend Wing Link from setup and profile compatibility into a secure
remote management API for typed setup, provider, profile, project, and directory
selection workflows.

**Architecture:** Keep Hermes Agent authoritative. Wing talks directly to Agent
for chat and runtime data, and uses Wing Link only for reviewed host operations
or fixed compatibility operations missing from the Agent API. Directory
selection uses server-configured roots and opaque handles.

## Phase 0 — contract and safety guards

1. Add source tests that reject arbitrary CLI, config keys, paths, file listing or
   content routes, reverse proxying, `profile use`, and `project use`.
2. Version the Wing Link capability response by operation, not by a broad
   `admin=true` flag.
3. Split read, mutation, secret-write, lifecycle, and filesystem-grant scopes.
4. Keep existing profile routes backward compatible.

**Done when:** unsupported clients fail closed and every new operation has an
independent capability and authorization check.

## Phase 1 — directory roots and folder browsing

Implemented: host-local `wing-link directories grant|list|revoke`, exact
`directories:read` authorization, device-bound expiring handles, bounded root and
child-folder routes, and the capability-gated Profiles browser. Handles and
navigation state are ephemeral. Responses never contain paths, files, metadata,
or contents.

1. Add a local configuration command for granting and revoking directory roots. **Done.**
2. Persist only canonical roots with owner-only permissions; never accept a root
   from the remote browse API. **Done.**
3. Add typed root/list-directory responses using opaque handles and pagination.
   Return child folders only; never return regular file names or metadata. **Done.**
4. Revalidate canonical containment on every request and reject symlink escape,
   traversal, absolute client paths, and oversized directories. **Done.**
5. Add Flutter browsing states for loading, empty, unsupported, revoked, and
   failed handles. **Done.**

**Tests:** temporary-directory integration tests for traversal, symlinks,
revocation, pagination, regular-file omission, hidden folders, Unicode names, and
path redaction.

**Done:** a paired remote Wing client can browse approved roots and subfolders
without seeing files or learning/submitting an unrestricted host path. Selection
is intentionally not persisted until authoritative Project creation exists.

## Phase 2 — profile and Hermes Project workflow — blocked

Do not implement Project compatibility from current Desktop RPC or human-readable
CLI output. Resume only when a released Hermes Agent contract provides explicit
profile identity and bounded machine-readable Project input/output. Keep Project
creation and Project-aware Chat unavailable in the meantime; never call
`profile use` or `project use`.

Any temporary reviewed compatibility adapter must have an ADR/security approval
and a removal trigger: remove it when the minimum supported Hermes Agent release
advertises equivalent explicit-profile Project operations.

**Tests:** exact argv tests, changed-output fail-closed tests, duplicate and
rename races, deleted/revoked directory behavior, and a fake-Hermes end-to-end
fixture.

**Done when:** a user can create a profile for a repository or subfolder and the
result appears in authoritative Hermes Project inventory. Project-scoped Chat has
its own direct-Agent contract gate.

## Phase 3 — provider and model configuration

1. Read provider/model options from the current Agent API where advertised.
2. Define an allowlisted schema for non-secret defaults and per-profile model
   selection; reject arbitrary config keys.
3. Require an upstream secret-safe API or stdin-based Hermes CLI operation before
   implementing provider credential set/remove. Do not pass secrets in argv and
   do not edit `.env` directly.
4. Return only configured state and required reload disposition.
5. Run restart/reload as a separate confirmed lifecycle operation and verify the
   new Agent generation before reporting readiness.

**Tests:** unsupported-provider rejection, write-only secret behavior, secret
redaction, no-secret-in-argv, restart ordering, failed reload, and preservation
of unrelated configuration.

**Done when:** provider setup works remotely without exposing keys or making Wing
Link a general configuration editor.

## Phase 4 — platform and remote qualification

1. Qualify Linux clean install, existing-runtime adoption, reboot, VPN access,
   credential rotation, and recovery.
2. Add TLS/reverse-proxy guidance without placing TLS private keys in Wing.
3. Add another host service adapter only with native lifecycle and package
   evidence; cross-compilation alone is insufficient.
4. Run Android physical-device pairing and remote folder/project acceptance.

## Likely files

- `wing_link/internal/app/serve.go`
- `wing_link/internal/app/serve_test.go`
- `wing_link/internal/app/architecture_boundary_test.go`
- new `wing_link/internal/workspaces/` package and tests
- `lib/core/wing_link/`
- `lib/features/profiles/`
- new project/directory selection UI under `lib/features/`
- focused Dart contract and widget tests

## Validation

Run focused tests after each RED/GREEN slice, then:

```bash
(cd wing_link && go test -race ./... && go vet ./...)
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze
flutter test --concurrency=1
flutter build web --release -t lib/main_e2e.dart
npm run web:e2e
npm audit
git diff --check
```

Before shipping, independently review the exact final snapshot for path escape,
secret leakage, arbitrary command/config expansion, authorization confusion, and
Agent/Wing Link authority drift.
