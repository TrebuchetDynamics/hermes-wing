# Hermes Wing Project Context

Hermes Wing is an independent cross-platform Flutter client for Hermes Agent.
Read `CONTEXT.md`, the relevant ADRs under `docs/adr/`, and `CONTRIBUTING.md`
before changing architecture or product language.

## Rules

- Hermes Agent remains authoritative for profiles, Projects, providers,
  configuration, memory, skills, sessions, tools, schedules, and gateway state.
- Wing talks directly to Agent for chat and advertised domain APIs. Wing Link is
  the authenticated remote management plane for host setup, pairing, lifecycle,
  health, diagnostics, directory grants, and reviewed typed compatibility
  operations missing from supported Agent APIs.
- Every Wing Link compatibility operation uses a fixed executable and argument
  shape, bounded output, no shell, no shadow state, and explicit authorization.
  Never expose arbitrary CLI, config keys, executable paths, host paths, or
  `profile use`/`project use`.
- Directory navigation is rooted in local grants and opaque handles. Wing Link is
  a folder picker: it returns child folders only and never enumerates file names,
  file metadata, or file contents.
- Provider secrets are write-only and may not appear in argv, logs, diagnostics,
  or responses. Preserve the current fail-closed block until Hermes offers a
  secret-safe noninteractive contract.
- Preserve unrelated dirty-worktree changes and add the smallest regression test
  for non-trivial behavior.
- Never commit credentials, transcripts, private endpoint URLs, generated state,
  or local tool artifacts.
- Do not claim platform, speech, acoustic, release, or signed-distribution support
  without matching runtime evidence.

## Validation

Run the checks relevant to the change; the complete gate is:

```bash
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze
flutter test --concurrency=1
flutter build web --release -t lib/main_e2e.dart
npm run web:e2e
npm audit
```
