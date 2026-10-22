+++
schema = 1
id = "CONNECTION-CRON-ADMISSION-LIVE"
title = "Live checks for CONNECTION-CRON-ADMISSION"
short = "Live checks for CONNECTION-CRON-ADMISSION"
status = "done"
goal = "CONNECTION-PATHS"
section = "Needs decision"
rank = 10000
depends_on = ["CONNECTION-CRON-ADMISSION"]
touches = ["**"]
resources = []
kind = "implementation"
ownership = "worker"
scope = "Run the live checks the offline work for CONNECTION-CRON-ADMISSION left pending."
acceptance = ["Each check passes on the real target: - The separate hermes-toolset admission contract/repair and independent review must establish full-lifecycle fencing, overlap rejection, stale/crashed-owner recovery, and failure cleanup. - Exercise installed native admission, verify checked local commit and worker release, then perform the separately gated one-occurrence cron canary. Keep the job paused until these proofs exist."]
checks = ["Live qualification by an authorized person; offline evidence does not count."]
exclusions = []
closure = "manual"
closure_actor = "xel"
closure_timestamp = "2026-10-22T12:19:29.998996+00:00"
closure_reason = "2026-10-22 owner decision: waived this auto-generated live follow-up to clear the owner queue. The parent task's offline acceptance remains; live evidence was not produced and is not claimed. Reopen if an authorized live window becomes available."
+++

- Sources: [existing goal authority](docs/product/prd.md#connection-path-requirements), [retained offline task history](todo.archive.md).
- Owner decision: The cron canary was retired without completion. Its legacy mention below grants no canary execution or schedule resumption; independent admission obligations remain unverified.
- Touches: none before conversion; ** stands for the whole repository
