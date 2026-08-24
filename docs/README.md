# Hermes Wing Docs

Hermes Wing is an independent cross-platform Flutter client for Hermes Agent,
adapted for mobile, web, and desktop. Hermes Agent remains authoritative for
agent state; Wing Link is its authenticated remote management plane, not a chat
proxy or second backend.

Use the [official Hermes Agent documentation](https://hermes-agent.nousresearch.com/docs/)
for current Agent installation, CLI, provider, profile, and gateway behavior.
The Wing documents below describe only this client's integration and evidence.

## Start here

- [Android and remote-host setup](runbooks/android-hermes-setup.md)
- [Hermes Agent compatibility](product/hermes-compatibility.md)
- [Wing Link remote management](product/wing-link.md)
- [Security policy](../SECURITY.md) and [threat model](security/threat-model.md)

Use these first when installing, pairing, troubleshooting a connection, or
checking whether a Hermes Agent release exposes the routes Wing needs.

## Product and architecture

- [Architecture decision records](adr/README.md)
- [Product requirements](product/prd.md)
- [Wing Link implementation plan](plans/wing-link-remote-management.md)
- [Gateway, profile, and Project management](product/gateway-profile-management.md)
- [Routes](product/routes.md)
- [Hermes Desktop capability parity ledger](product/hermes-desktop-parity.md)

## Operations and qualification

- [Alpha release runbook](runbooks/release-alpha.md)
- [Android release handoff](runbooks/android/release-handoff.md)
- [Evidence matrix](quality/evidence-matrix.md)
- [Hermes readiness audit](runbooks/hermes-readiness-audit.md)
- [Hermes platform smoke](runbooks/hermes-platform-smoke.md)
- [Hermes Agent release compatibility audit](runbooks/hermes-agent-release-compatibility.md)
- [Android live microphone smoke](runbooks/android/live-mic-smoke.md)

## Historical plans and comparison studies

These documents preserve decision history. They are not current setup guides or
authority for Hermes Agent behavior; current ADRs and implementation win when a
historical plan differs.

- [Hermes Desktop complete feature study](product/hermes-desktop-feature-study.md)
- [Hermes Desktop UI gap audit](product/hermes-desktop-ui-gap.md)
- [Implementation plans and superseded designs](superpowers/)

## Research recommendations

- [Hermes WebUI feature and architecture study](product/hermes-webui-feature-study.md) — long-run chat, recovery, session, onboarding, and operations lessons with authority-safe Wing dispositions
- [Buzz UX and archived Nostr research](research/buzz-nostr-lessons.md) — Nostr control transport deferred
- [Matrix messaging lessons for Wing and Wing Link](research/matrix-messaging-lessons.md)
- [Archived offline bilingual mobile voice research](research/offline-bilingual-voice-architecture.md) — not adopted; Wing does not ship or load app-owned voice models
