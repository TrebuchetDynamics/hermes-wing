+++
schema = 1
id = "DOC-BACKEND-DISCONNECT-CONTRACT-LIVE"
title = "Live checks for DOC-BACKEND-DISCONNECT-CONTRACT"
short = "Live checks for DOC-BACKEND-DISCONNECT-CONTRACT"
status = "done"
goal = "REMOTE-BACKENDS"
section = "Needs decision"
rank = 25000
depends_on = ["DOC-BACKEND-DISCONNECT-CONTRACT"]
touches = ["**"]
resources = []
kind = "implementation"
ownership = "worker"
scope = "Run the live checks the offline work for DOC-BACKEND-DISCONNECT-CONTRACT left pending."
acceptance = ["Each check passes on the real target: - Run the named Android SSH fixture interruption -> explicit Retry journey in integration_test/managed_ssh_key_native_test.dart on an approved disposable Android app/device with its owned ADB-reverse mapping; verify replaced forwarding port, exact host/profile/session and zero mutations. Prepared but not executed here. - On an approved Android live-Agent target, exercise Wi-Fi/tunnel interruption and explicit Retry with uncertain work; verify authoritative readback and zero implicit Send/approval/Stop/service restart. No live Agent or physical Android target was exercised. - Physical platform secure-storage durability and native document acquisition remain unqualified; fixture substitutions are not keystore/SAF evidence. Android away/process-death proof remains with its existing separate task."]
checks = ["Live qualification by an authorized person; offline evidence does not count."]
exclusions = []
closure = "manual"
closure_actor = "xel"
closure_timestamp = "2026-10-22T12:19:38.834017+00:00"
closure_reason = "2026-10-22 owner decision: waived this auto-generated live follow-up to clear the owner queue. The parent task's offline acceptance remains; live evidence was not produced and is not claimed. Reopen if an authorized live window becomes available."
+++

- Sources: [existing goal authority](docs/product/hermes-desktop-parity.md#statuses), [retained offline task history](todo.archive.md).
- Touches: none before conversion; ** stands for the whole repository
