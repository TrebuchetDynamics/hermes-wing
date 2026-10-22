+++
schema = 1
id = "DOC-API-PROTOCOL-ERROR-EVIDENCE"
title = "Map profile-list protocol error precedence"
short = "Map profile-list protocol error precedence"
status = "done"
goal = "API-CONFORMANCE"
section = "Next"
rank = 20000
depends_on = ["DOC-API-DEVICE-SELF-CONFORMANCE"]
touches = ["**"]
resources = []
kind = "implementation"
ownership = "worker"
scope = "read-only source, nearest tests and sanitized receipt inspection for this outcome. Exclude implementation, upstream edits, secrets, installs and live actions."
acceptance = ["Compare code-first schema and existing dispatch tests for omitted, supported and unsupported generations with method/auth errors. Record conformance proof or the exact unexecuted check; no sockets."]
exclusions = []
closure = "manual"
closure_actor = "xel"
closure_timestamp = "2026-10-22T12:47:06.677166+00:00"
closure_reason = "2026-10-22 engineering/owner review: this proof targets the retired Wing Link service and the accepted planner decision is to skip it. Close the historical/unverified record; do not recreate handlers and do not claim conformance."
+++

- Payoff: preserve a distinct remaining proof slice after the current task.
- Sources: [API-CONFORMANCE](docs/api/wing-link.openapi.yaml), [retirement boundary](docs/adr/product.md#complete-removal-including-legacy).
- Ownership: unclaimed in this index; verify tracker and continuation leases first.
- Source status: this acceptance targets the retired Wing Link service, not a current Wing-owned API. Original criteria and dependencies are retained as unresolved historical intent, not authorization to recreate management.
- Default: retain deferred historical proof; no new API or acceptance.
- Planner decision: skip this retired-contract successor with its predecessor; retain its original criteria and dependency as historical/unverified. No new endpoint or management fallback is authorized. A surviving contract, not a generic approval to continue, is the only valid reason to reconsider this proof.
- Dependencies: DOC-API-DEVICE-SELF-CONFORMANCE; not eligible until that task is done.
- Touches: none before conversion; ** stands for the whole repository
- Reopened: Reopened after an owner-close correction: this is offline implementation work and belongs in Next, not in the device/live waiver.
