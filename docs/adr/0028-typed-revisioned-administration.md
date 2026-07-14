# ADR 0028: Use typed, revisioned administration

Status: accepted
Date: 2026-07-13

Remote administration uses typed domain resources and atomic mutations, not generic configuration paths or environment-variable names. Reads return a domain revision; updates require that revision through `If-Match`, and secret fields expose only presence plus set/remove operations.

## Consequences

- Profiles, providers, models, skills, tools, memory, tasks, gateway, and settings validate domain-specific request and response schemas.
- Missing `If-Match` on a revisioned mutation returns `428 revision_required`; a stale revision returns `412 revision_conflict` without applying any part of the mutation.
- Successful persistence produces a new revision before restart/reload side effects are reported.
- Secret reads return presence and safe metadata only; set/remove responses never echo secret values.
- Generic remote `get-config`, `set-config`, `get-env`, and `set-env` operations are not advertised.
- Concurrent clients reconcile the latest resource after conflicts instead of silently overwriting each other.
