+++
schema = 1
id = "CONNECTION-CRON-CANARY"
title = "Qualify one reviewed implementation canary before resuming the existing 15-minute cron"
short = "Qualify one reviewed implementation canary before resuming the existing 15-minute cron"
status = "open"
goal = "CONNECTION-PATHS"
section = "Needs decision"
rank = 7000
depends_on = ["CONNECTION-CRON-ADMISSION"]
touches = ["**"]
resources = []
kind = "implementation"
ownership = "worker"
scope = "preserve and finish the current Wing candidate; reconcile existing connection owners; update/read back the existing paused job prompt; qualify one manually triggered occurrence and gated schedule resumption. Use an existing eligible CONNECTION-PATHS implementation task, not duplicate product work."
acceptance = ["observe safe admission, relevant passing checks, independent review, a scoped implementation commit on canonical main and worker release. Existing chat work, documentation-only commits and job status `ok` do not count. Resume only after all canary evidence passes; read back enabled state and cadence and inspect the first scheduled occurrence. A hard refusal pauses and notifies."]
checks = ["retain exact job/task/run/commit and check receipts; inspect the implementation diff, release proof, scheduler readback and first scheduled result. No fresh worker or scheduler mutation is authorized by this task's creation."]
exclusions = []
+++

- Readiness: CANCELLED by owner; retired without completion. Never dispatch.
- Owner decision: retire this canary task without claiming completion. The historical acceptance below is not an active continuation or restart instruction. No canary, runner, schedule change or automatic resumption is authorized. Qualify one implementation canary before restarting the existing cron.
- Payoff: recurring work produces checked port commits, not status-only success.
- Sources: [accepted restart plan](../../docs/plans/2026-10-03-desktop-port-goal.md#cron-restart-interview) and [connection frontier](../../docs/plans/2026-10-03-desktop-port-goal.md#current-connection-frontier).
- Graph evidence: partial; source-bound job inspection establishes a paused 15-minute job, not installed admission, live ownership or an executed canary.
- Ownership: unclaimed coordination task; use the existing job and native task graph. No substitute cron writer, Agent changes, push, release or paid inference.
- Current product direction: Wing Link is deprecated, not merely optional. Retained legacy tasks and receipts describe existing code, not permission to expand it. Implement direct/native replacements or explicit unavailable-capability behavior. Do not erase paired state or label removal as feature qualification. Preserve active workers and coordinate exact source ownership before dispatch.
- Dependencies: CONNECTION-CRON-ADMISSION. Current candidate release and reconciled connection frontier are required before selecting the implementation canary.
- Touches: none before conversion; ** stands for the whole repository
