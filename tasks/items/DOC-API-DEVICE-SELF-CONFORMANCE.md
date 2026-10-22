+++
schema = 1
id = "DOC-API-DEVICE-SELF-CONFORMANCE"
title = "Verify device-self read/revoke schema and authorization against handlers"
short = "Verify device-self read/revoke schema and authorization against handlers"
status = "open"
goal = "API-CONFORMANCE"
section = "Next"
rank = 19000
depends_on = ["DOC-API-CONFORMANCE"]
touches = ["**"]
resources = []
kind = "implementation"
ownership = "worker"
scope = "one management-route family, existing tooling, in-process disposable recorder fixtures and documentation corrections. Exclude live listeners, personal credentials, peer administration, API redesign and new dependencies."
acceptance = ["execute schema-to-handler checks for self-read/revoke, exact grants, pending/revoked authority and method/protocol errors. Reject an isolated incorrect schema copy; keep generated credentials and fixture bodies out of receipts. Record exact commands, source hashes and limits. Other families, full OpenAPI standards validation, TLS and live transport remain unverified."]
exclusions = []
+++

- Payoff: extend discovery-only conformance to one exact authorization boundary.
- Sources: [2026-08-24-wing-link-hardening](docs/superpowers/plans/2026-08-24-wing-link-hardening.md) (historical planning context); [OpenAPI snapshot](docs/api/wing-link.openapi.yaml), [retirement boundary](docs/adr/product.md#complete-removal-including-legacy).
- Historical inputs: `wing_link/internal/app/serve.go` and `wing_link/internal/app/serve_test.go` were removed at 963b9b5b; use immutable Git history for the archived contract, not nonexistent current handlers.
- Source status: this acceptance targets the retired Wing Link service, not a current Wing-owned API. Original criteria and dependencies are retained as unresolved historical intent, not authorization to recreate management.
- Default: retain deferred historical proof; no new API or acceptance.
- Planner decision: skip retired-service proof; keep the original acceptance as historical/unverified, not current implementation work. Accepted complete Link retirement already forbids recreating these handlers. No new user decision is needed to avoid that work; only an explicitly accepted surviving contract could reopen it. Do not mark conformance passed or invent a replacement API.
- Dependencies: DOC-API-CONFORMANCE (done). Ownership: unclaimed in this index; verify tracker ownership before execution.
- Touches: none before conversion; ** stands for the whole repository
- Reopened: Reopened after an owner-close correction: this is offline implementation work and belongs in Next, not in the device/live waiver.
