# ADR 0030: Do not replay offline mutations

Status: accepted
Date: 2026-07-13

Navivox may keep already loaded read models and unsent drafts while a connection is unavailable, but it does not durably queue or automatically replay chat sends, approvals, administrative mutations, task actions, or lifecycle commands. Reconnection first refreshes authoritative profile-scoped state.

## Consequences

- Disconnected read models are visibly labeled stale with their last successful refresh time.
- Drafts remain inert and require an explicit send after reconnection.
- The in-memory busy-run follow-up queue may operate only while its endpoint, profile, session, and connection generation remain valid.
- Disconnect, profile change, endpoint change, sign-out, or app termination invalidates pending approvals and mutation queues.
- Failed or interrupted actions show a safe retry affordance but are never replayed automatically.
- The first implementation keeps stale snapshots and drafts in memory; durable offline domain caching requires a separate security and retention decision.
