# API and state

Status: current

## Decision

Hermes Wing communicates through advertised, typed Hermes interfaces. Capability discovery determines which optional operations the client offers.

Keep profile-owned work explicitly associated with a profile. Prefer normal request/response APIs for commands and queries and event streams for live work, but follow the authoritative Hermes contract when it provides an equivalent supported mechanism.

Server state wins after reconnects or interruptions. Cached reads and drafts may remain visible, but the client must not silently replay mutations. A retry that could change state requires fresh user intent or an idempotent server contract.

Use opaque server handles instead of exposing arbitrary remote filesystem paths. Use revisions or another server-supported concurrency check where concurrent edits could overwrite one another. Apply disruptive runtime changes explicitly rather than hiding restarts inside an ordinary save.

## Flexible guidance

- Exact paths, query parameters, event formats, and schema versions belong to the negotiated API contract, not this decision.
- Partial feature availability is acceptable when unsupported operations fail clearly and independently.
- Transport details may evolve if authentication, profile context, error handling, and reconnection behavior remain sound.
