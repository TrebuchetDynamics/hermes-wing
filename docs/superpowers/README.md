# Historical plans and specifications

These files preserve implementation and decision history. They are not the active
roadmap and must not override current ADRs, implementation, or the official Hermes
Agent documentation.

Use [ROADMAP.md](../../ROADMAP.md) for current priorities and
[the ADR index](../adr/README.md) for current architecture.

## Status index

| Document | Status | Current use |
| --- | --- | --- |
| [Android scoped auth and profiles plan](plans/2026-07-13-android-auth-profiles.md) | Superseded | Historical proposal for Agent-side contracts that were not added to supported releases. |
| [Providers and models plan](plans/2026-07-14-milestone2-providers-models.md) | Superseded | Historical proposal; current direction is adapting to Hermes model options/set. |
| [Providers and models design](specs/2026-07-14-milestone2-providers-models-design.md) | Superseded | Security and write-only-key lessons remain useful, not its routes. |
| [Multi-gateway unified chats plan](plans/2026-07-16-multi-gateway-unified-chats.md) | Foundation implemented | Historical execution detail for the one-active-channel directory. |
| [Multi-gateway unified chats design](specs/2026-07-16-multi-gateway-unified-chats-design.md) | Foundation implemented | Product rationale; current profile routing also uses verified multiplexed connections. |
| [Settings information architecture plan](plans/2026-07-17-settings-information-architecture.md) | Implemented | Historical execution record. |
| [Settings information architecture design](specs/2026-07-17-settings-information-architecture-design.md) | Implemented | Current product rationale, subject to later voice changes. |
| [Wing Link local runtime plan](plans/2026-08-05-wing-link-local-runtime.md) | Historical / partially implemented | Supervisor foundation history; current boundaries live in the runtime ADR. |
| [Wing Link multi-agent design](specs/2026-08-06-wing-link-multi-agent-management-design.md) | Superseded in part | Filesystem/profile merging and provider bridge are rejected; only the fixed profile compatibility adapter survives. |

Unchecked boxes in historical plans are not a backlog. Move remaining user-visible
work into [ROADMAP.md](../../ROADMAP.md) or a new focused plan that starts from the
current implementation and Agent contract.
