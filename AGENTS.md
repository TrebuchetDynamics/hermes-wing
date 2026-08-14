# Hermes Wing Project Context

Hermes Wing is an independent cross-platform Flutter client for Hermes Agent. Read `CONTEXT.md`, the relevant ADRs under `docs/adr/`, and `CONTRIBUTING.md` before changing architecture or product language.

## Rules

- Hermes Agent remains authoritative for profiles, configuration, memory, skills, sessions, tools, schedules, and gateway state. Because supported Hermes Agent releases cannot be changed for Wing, Wing Link may delegate the bounded profile compatibility operations defined by the runtime decision to the installed Hermes CLI.
- Keep Wing Link limited to installation/adoption, pairing, scoped credentials, lifecycle, secure bootstrap, health, diagnostics, and fixed `hermes profile list|create|rename|delete` commands. Pairing may resolve listed profiles with fixed `hermes --profile <id> config env-path`, enable `gateway.multiplex_profiles`, and restart the active gateway before issuing verified `/p/<id>` connections. Never expose arbitrary CLI execution, invoke `hermes profile use`, or bridge other Hermes domains.
- Preserve unrelated dirty-worktree changes and add the smallest regression test for non-trivial behavior.
- Never commit credentials, transcripts, private endpoint URLs, generated state, or local tool artifacts.
- Do not claim platform, speech, acoustic, release, or signed-distribution support without matching runtime evidence.

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
