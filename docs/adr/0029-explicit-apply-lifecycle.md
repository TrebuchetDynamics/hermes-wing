# ADR 0029: Apply runtime changes explicitly

Status: accepted
Date: 2026-07-13

Administrative mutations persist atomically without silently restarting active Hermes work. Their responses include an apply disposition—`applied`, `reload_required`, or `restart_required`—and lifecycle changes occur only through an explicit server-owned apply operation.

## Consequences

- `applied` means the running service already uses the new revision.
- `reload_required` offers an explicit scoped reload that does not interrupt active runs.
- `restart_required` exposes active-work and drainability state before the operator confirms a drain and restart.
- A drain rejects new work, preserves or completes existing work according to the advertised policy, supports cancellation before restart, and emits profile-scoped SSE progress.
- Restart success requires health and capability verification at the expected revision; failure remains visible and recoverable.
- Flutter displays lifecycle state and sends intent but does not implement process-specific restart recipes.
