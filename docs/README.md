# Hermes Wing Docs

Hermes Wing is an independent cross-platform Flutter client for Hermes Agent,
adapted for mobile, web, and desktop. Hermes Agent remains authoritative for
agent state; Wing Link is its authenticated remote management plane, not a chat
proxy or second backend.

Use the [official Hermes Agent documentation](https://hermes-agent.nousresearch.com/docs/)
for current Agent installation, CLI, provider, profile, and gateway behavior.
The Wing documents below describe only this client's integration and evidence.

## Current product and architecture

- [Architecture decision records](adr/README.md)
- [Product requirements](product/prd.md)
- [Wing Link remote management](product/wing-link.md)
- [Wing Link implementation plan](plans/wing-link-remote-management.md)
- [Hermes compatibility](product/hermes-compatibility.md)
- [Gateway, profile, and Project management](product/gateway-profile-management.md)
- [Routes](product/routes.md)
- [Hermes Desktop capability parity ledger](product/hermes-desktop-parity.md)
- [Android Hermes setup](runbooks/android-hermes-setup.md)
- [Alpha release runbook](runbooks/release-alpha.md)
- [Threat model](security/threat-model.md)
- [Evidence matrix](quality/evidence-matrix.md)
- [Hermes readiness audit](runbooks/hermes-readiness-audit.md)

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
- [Offline bilingual mobile voice architecture](research/offline-bilingual-voice-architecture.md)
