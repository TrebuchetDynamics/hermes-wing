+++
schema = 1
id = "VERIFY-M4-LIVE-INVENTORY"
title = "Qualify scheduled-job inventory on an authenticated native Agent target"
short = "Qualify scheduled-job inventory on an authenticated native Agent target"
status = "open"
goal = "M4"
section = "Needs decision"
rank = 17000
depends_on = ["DOC-M4-SCHEDULE-INVENTORY-EVIDENCE"]
touches = ["**"]
resources = []
kind = "implementation"
ownership = "worker"
scope = "installed Linux Wing against an existing approved isolated authenticated, unmodified Agent target. No Agent changes, service changes, inference or mutations."
acceptance = ["verify exact advertised jobs/grants/profile contract, real denial, pending A-to-B read isolation and explicit B recovery with owner-scoped request receipts and zero mutations; keyboard recovery remains operable. If the contract is absent, verify unavailable/no dispatch and retain successful inventory unqualified."]
exclusions = []
+++

- Payoff: close the native/live inventory gap without treating fixtures as support.
- Sources: [source-bound inventory receipt](../../docs/quality/schedules-inventory-evidence.md#historical-browser-evidence-and-the-missing-live-oracle).
- Ownership: coordinator wing; no worker claim. Requires an existing approved target advertising the contract and authorized access; the inspected catalog omits it.
- Planner decision: skip authenticated success qualification until a disposable deployed Agent advertises the exact inventory operation and grants. The missing target/secret-safe access is external input; the missing API is not a decision the owner can waive. Retain unavailable/no-dispatch as distinct evidence, never call it successful inventory. No installation, service or schedule mutation.
- Dependencies: DOC-M4-SCHEDULE-INVENTORY-EVIDENCE (done).
- Touches: none before conversion; ** stands for the whole repository
