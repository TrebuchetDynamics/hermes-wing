+++
schema = 1
id = "DOC-M4-SCHEDULE-CONTRACT-LIVE"
title = "Live checks for DOC-M4-SCHEDULE-CONTRACT"
short = "Live checks for DOC-M4-SCHEDULE-CONTRACT"
status = "done"
goal = "M4-SCHEDULES"
section = "Needs decision"
rank = 36000
depends_on = ["DOC-M4-SCHEDULE-CONTRACT"]
touches = ["**"]
resources = []
kind = "implementation"
ownership = "worker"
scope = "Run the live checks the offline work for DOC-M4-SCHEDULE-CONTRACT left pending."
acceptance = ["Each check passes on the real target: - No browser, native UI, device, live authentication, actual schedule pause/resume, execution or delivery qualification was performed. Any later operation journey requires a separately authorized disposable target exposing a suitable unmodified authoritative contract, with exact authority and consent gates. Current contract gaps do not block this evidence-only task."]
checks = ["Live qualification by an authorized person; offline evidence does not count."]
exclusions = []
closure = "manual"
closure_actor = "xel"
closure_timestamp = "2026-10-22T12:19:58.565147+00:00"
closure_reason = "2026-10-22 owner decision: waived this auto-generated live follow-up to clear the owner queue. The parent task's offline acceptance remains; live evidence was not produced and is not claimed. Reopen if an authorized live window becomes available."
+++

- Sources: [existing goal authority](docs/product/hermes-desktop-parity.md#statuses), [retained offline task history](todo.archive.md).
- Touches: none before conversion; ** stands for the whole repository
