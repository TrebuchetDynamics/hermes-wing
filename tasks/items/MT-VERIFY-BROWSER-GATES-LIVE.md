+++
schema = 1
id = "MT-VERIFY-BROWSER-GATES-LIVE"
title = "Live checks for MT-VERIFY-BROWSER-GATES"
short = "Live checks for MT-VERIFY-BROWSER-GATES"
status = "done"
goal = "INTEGRATION"
section = "Needs decision"
rank = 68000
depends_on = ["MT-VERIFY-BROWSER-GATES"]
touches = ["**"]
resources = []
kind = "implementation"
ownership = "worker"
scope = "Run the live checks the offline work for MT-VERIFY-BROWSER-GATES left pending."
acceptance = ["Each check passes on the real target: - Canonical live-Agent say-hi opt-in was explicitly skipped; no live Agent/provider authentication or inference qualified. - Physical Android, native desktop UI, microphone/acoustics, installation/signing/update and human platform acceptance remain separate platform/live work; only Linux-host headless Chromium/offline tooling exercised."]
checks = ["Live qualification by an authorized person; offline evidence does not count."]
exclusions = []
closure = "manual"
closure_actor = "xel"
closure_timestamp = "2026-10-22T12:20:12.055091+00:00"
closure_reason = "2026-10-22 owner decision: waived this auto-generated live follow-up to clear the owner queue. The parent task's offline acceptance remains; live evidence was not produced and is not claimed. Reopen if an authorized live window becomes available."
+++

- Sources: [accepted port scope](ROADMAP.md#flutter-port-execution-roadmap), [retained MT-VERIFY-BROWSER-GATES parent and qualifications](todo.archive.md).
- Touches: none before conversion; ** stands for the whole repository
