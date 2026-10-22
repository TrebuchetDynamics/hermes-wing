+++
schema = 1
id = "WING-001-b3-LIVE"
title = "Live checks for WING-001-b3"
short = "Live checks for WING-001-b3"
status = "done"
goal = "REMOTE-BACKENDS"
section = "Needs decision"
rank = 75000
depends_on = ["WING-001-b3"]
touches = ["**"]
resources = []
kind = "implementation"
ownership = "worker"
scope = "Run the live checks the offline work for WING-001-b3 left pending."
acceptance = ["Each check passes on the real target:"]
checks = ["Live qualification by an authorized person; offline evidence does not count."]
exclusions = []
closure = "manual"
closure_actor = "xel"
closure_timestamp = "2026-10-22T12:20:28.484705+00:00"
closure_reason = "2026-10-22 owner decision: waived this auto-generated live follow-up to clear the owner queue. The parent task's offline acceptance remains; live evidence was not produced and is not claimed. Reopen if an authorized live window becomes available."
+++

- BACKEND-SSH-CONNECT-LIVE: actual reported installed-phone/APK failure and target Agent reachability/connectivity remain unreproduced/unverified; feedback repair does not prove connectivity.
- BACKEND-SSH-KEY-NATIVE-LIVE: approved native SSH authentication/host trust, platform secure storage/key acquisition and device recovery remain unverified. - Actual constrained Android IME/TalkBack and native presentation remain unverified. Executed Linux-hosted deterministic widgets/platform overrides and Chromium only; opt-in live/SSH cases skipped. No live credentials, personal-runtime mutation, provider spending, service restart, push or deployment attempted.
- Touches: none before conversion; ** stands for the whole repository
