+++
schema = 1
id = "DOC-NATIVE-FAILURE-BOUNDARY-LIVE"
title = "Live checks for DOC-NATIVE-FAILURE-BOUNDARY"
short = "Live checks for DOC-NATIVE-FAILURE-BOUNDARY"
status = "done"
goal = "NATIVE-INTEGRATION"
section = "Needs decision"
rank = 60000
depends_on = ["DOC-NATIVE-FAILURE-BOUNDARY"]
touches = ["**"]
resources = []
kind = "implementation"
ownership = "worker"
scope = "Run the live checks the offline work for DOC-NATIVE-FAILURE-BOUNDARY left pending."
acceptance = ["Each check passes on the real target: - No platform was exercised at runtime. Separately scoped isolated Linux native evidence must check actual chooser cancellation/exit/modality, delayed or failed metadata IO responsiveness and outstanding-work behavior across mode changes, disposal and re-entry. Existing provider-overridden/completer tests and historical GTK receipts do not establish these guarantees. - Other named-platform behavior and any future privileged operation require their own reviewed contracts and runtime receipts. Preparation grants no native activation rights; this review does not qualify OS rollback, keyring/authentication, process cleanup or NATIVE-INTEGRATION."]
checks = ["Live qualification by an authorized person; offline evidence does not count."]
exclusions = []
closure = "manual"
closure_actor = "xel"
closure_timestamp = "2026-10-22T12:20:03.355412+00:00"
closure_reason = "2026-10-22 owner decision: waived this auto-generated live follow-up to clear the owner queue. The parent task's offline acceptance remains; live evidence was not produced and is not claimed. Reopen if an authorized live window becomes available."
+++

- Sources: [existing goal authority](docs/adr/client.md#decision), [retained parent and qualifications](todo.archive.md).
- Touches: none before conversion; ** stands for the whole repository
