+++
schema = 1
id = "VERIFY-LIVE-WORKFLOW-RECOVERY-LIVE"
title = "Live checks for VERIFY-LIVE-WORKFLOW-RECOVERY"
short = "Live checks for VERIFY-LIVE-WORKFLOW-RECOVERY"
status = "done"
goal = "M1"
section = "Needs decision"
rank = 29000
depends_on = ["VERIFY-LIVE-WORKFLOW-RECOVERY"]
touches = ["**"]
resources = []
kind = "implementation"
ownership = "worker"
scope = "Run the live checks the offline work for VERIFY-LIVE-WORKFLOW-RECOVERY left pending."
acceptance = ["Each check passes on the real target:"]
checks = ["Live qualification by an authorized person; offline evidence does not count."]
exclusions = []
closure = "manual"
closure_actor = "xel"
closure_timestamp = "2026-10-22T12:20:27.530538+00:00"
closure_reason = "2026-10-22 owner decision: waived this auto-generated live follow-up to clear the owner queue. The parent task's offline acceptance remains; live evidence was not produced and is not claimed. Reopen if an authorized live window becomes available."
+++

- Sources: [existing goal authority](docs/product/prd.md#leading-acceptance-outcome), [retained offline task history](todo.archive.md).
- Actual-live prerequisite remains unqualified: PARITY-LIVE-WORKFLOW-LIVE is open and the native generation driver still unconditionally refuses LIVE_INFERENCE_BOUND_NOT_QUALIFIED. Require supported authoritative physical provider-attempt admission and the predecessor's actual completed/Stopped runs, relaunch restoration and intentional resumed send; offline predecessor closeout is not sufficient. - After predecessor actual-live qualification, use its same disposable target/profile/session and valid secret-safe read grants for bounded native reconnect and Chat route return. Compare canonical history and terminal outcomes against a fresh baseline and independently record zero added sends, creates, model writes, approval responses and Stop requests, including failed attempts. No credentials, live service or native GTK process accessed in this task. - Live failed-read Retry or delayed-owner qualification requires naturally occurring failures or separately authorized disposable fault controls; deterministic coverage does not qualify live faults. Missing canonical readback or independent mutation observations must remain inconclusive. No service disruption, new inference, replacement session, personal state or shared gateway restart is authorized.
- Touches: none before conversion; ** stands for the whole repository
