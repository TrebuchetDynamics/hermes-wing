# API and state

Status: current decision

## Decision

Hermes Wing uses two typed planes:

- Hermes Agent APIs for authoritative domain and run state; and
- Wing Link for authenticated host management and reviewed compatibility
  operations missing from the Agent API.

Capability discovery determines which operations Wing offers. A broad version or
`admin` flag is insufficient: mutations require the exact operation,
authorization, and current resource identity.

Server state wins after reconnect. Cached reads and drafts may remain visible,
but Wing never silently replays a mutation. Destructive, secret, filesystem, and
lifecycle operations require fresh intent or an idempotent contract.

Host folder selection uses server-issued opaque handles rooted in locally approved
directories. Results contain child folders only, never file entries. Clients
never send arbitrary absolute paths. Every lookup revalidates canonical
containment and grant status.

Profile-to-folder assignment uses Agent-owned Hermes Projects. Profile, project,
and directory identities remain explicit on every request; no operation changes a
global active profile or project as a side effect.

Use revisions or another authoritative concurrency check where edits can collide.
Report reload/restart requirements separately from persistence success.
