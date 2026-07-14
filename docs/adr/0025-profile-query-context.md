# ADR 0025: Carry profile context in the query string

Status: accepted
Date: 2026-07-13

Every profile-owned Hermes HTTP and SSE operation carries a mandatory `profile` query parameter, including `profile=default`. Machine-scoped profile-registry operations instead identify the profile they create, inspect, rename, or delete in their path or body.

## Consequences

- `/v1/capabilities` advertises the profile-context mechanism and marks profile-scoped operations.
- Missing profile context returns `profile_required`; malformed, conflicting, or unknown context fails closed without falling back to `active_profile`.
- Retries, redirects, pagination links, polling, and SSE reconnects preserve the exact profile query value.
- Profile IDs are validated before selecting profile-owned storage, credentials, adapters, sessions, or processes.
- Query context works across native HTTP clients and browser streaming without custom-header support.
