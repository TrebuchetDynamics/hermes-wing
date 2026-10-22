+++
schema = 1
id = "PARITYUPDATE-006-f4-LIVE"
title = "Live checks for PARITYUPDATE-006-f4"
short = "Live checks for PARITYUPDATE-006-f4"
status = "done"
goal = "INTEGRATION"
section = "Needs decision"
rank = 72000
depends_on = ["PARITYUPDATE-006-f4"]
touches = ["**"]
resources = []
kind = "implementation"
ownership = "worker"
scope = "Run the live checks the offline work for PARITYUPDATE-006-f4 left pending."
acceptance = ["Each check passes on the real target: - Physical keyboard/OS-window resize and screen-reader qualification remain unverified; retained Linux GTK/Xvfb native evidence uses WidgetTester input and framework viewport resizing. - Android/other platforms, live Agent/provider transport, OS keyring, install/update/signing and release qualification remain unchanged and unverified by this deterministic fixture."]
checks = ["Live qualification by an authorized person; offline evidence does not count."]
exclusions = []
closure = "manual"
closure_actor = "xel"
closure_timestamp = "2026-10-22T12:20:23.504534+00:00"
closure_reason = "2026-10-22 owner decision: waived this auto-generated live follow-up to clear the owner queue. The parent task's offline acceptance remains; live evidence was not produced and is not claimed. Reopen if an authorized live window becomes available."
+++

- Touches: none before conversion; ** stands for the whole repository
