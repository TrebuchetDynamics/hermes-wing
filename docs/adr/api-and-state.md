# API and state

Status: current decision

## Decision

Hermes Wing uses two typed planes:

- Hermes Agent APIs for authoritative domain and run state; and
- Wing Link for authenticated host management and reviewed compatibility
  operations missing from the Agent API, plus the typed setup catalog read below.

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

## Provider/model setup catalog

Provider/model autocomplete in profile setup reads Hermes Agent's full advertised
inventory through Wing Link's typed `GET /v1/profiles/{id}/model-options` API.
This is an explicit setup-management exception to direct Agent administration;
it does not move chat, sessions, runs, tools, or approvals through Wing Link.

Agent remains the catalog authority. Wing Link requires its own `profiles:read`
grant, verifies the requested profile still exists, and checks Agent's exact
`model_options` capability before reading `/p/{id}/api/model/options` with the
host's separate profile credential. The locally configured Agent origin is fixed;
remote callers cannot select an upstream URL, path, command, or configuration key.
Only provider slugs/names and model IDs are returned. No domain cache, credentials,
provider URLs, restart, credential creation, or provider mutation is involved.

Unconfigured providers remain visible for setup. Catalog visibility does not
authorize a provider write: existing secret, profile setup, and capability gates
remain in force. Chat's model picker retains its configured-provider policy.
If the catalog is unavailable, setup reports the error and offers retry or manual
entry; it never substitutes a Wing-maintained list of providers or models.
