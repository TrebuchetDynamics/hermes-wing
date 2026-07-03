# Navivox Documentation

Start with `../CONTEXT.md` for stable product language, then use this index to find the durable docs.

## Product

- [PRD](product/prd.md)
- [Hermes Desktop reference direction](product/hermes-desktop-reference.md)
- [Hermes Agent interface plan](product/hermes-agent-interface-plan.md)
- [Routes](product/routes.md)
- [Testing plan](product/testing-plan.md)
- [UI design](product/ui-design.md)

## Architecture

- [Architecture](architecture/architecture.md)
- [Data model](architecture/data-model.md)
- [Decision record](architecture/decision-record.md)
- [ADRs](adr/)

## Research

- [Analyst summary](research/analyst-summary.md)
- [Chat UI research](research/chat-ui-research.md)
- [Library research](research/library-research.md)

## Runbooks And Handoffs

Before any Hermes readiness completion claim, run strict readiness audit:

```bash
NAVIVOX_FAIL_ON_BLOCKERS=1 npm run hermes:readiness-audit
```

While external/deferred blockers remain, the expected result is exit 3 with
`Completion verdict: NOT COMPLETE`; do not treat proxy evidence such as passing
tests, APK hashes, configured Hermes home, workflow YAML, or dispatch-only output
as completion.

- [Hermes platform smoke checklist](runbooks/hermes-platform-smoke.md)
- [Hermes companion readiness audit](runbooks/hermes-readiness-audit.md)
- [Termux Gormes bootstrap](runbooks/termux/gormes-bootstrap.md)
- [Android setup checklist](runbooks/android/setup-checklist.md)
- [Android pairing handoff smoke](runbooks/android/pairing-handoff-smoke.md)
- [Android pairing handoff instrumentation](runbooks/android/pairing-handoff-instrumentation.md)
- [Android durable keystore smoke](runbooks/android/durable-keystore-smoke.md)
- [Android live microphone Hermes smoke](runbooks/android/live-mic-smoke.md)
- [Android release handoff](runbooks/android/release-handoff.md)
- [Android device and secret handling contracts](runbooks/shared/android-device-and-secret-contracts.md)
- [Pairing secret handling contract](runbooks/shared/pairing-secret-handling.md)
- [Web QA handoff](runbooks/web-qa/dl-mphmcspi-bb46a2.md)

## Assets

- [Setup screenshot](screenshots/setup.png)
- [Chat screenshot](screenshots/chat.png)
