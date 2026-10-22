+++
schema = 1
id = "PARITY-MAESTRO-ANDROID-DEVICE-LIVE"
title = "Live checks for PARITY-MAESTRO-ANDROID-DEVICE"
short = "Live checks for PARITY-MAESTRO-ANDROID-DEVICE"
status = "done"
goal = "PARITY"
section = "Needs decision"
rank = 23000
depends_on = ["PARITY-MAESTRO-ANDROID-DEVICE"]
touches = ["**"]
resources = []
kind = "implementation"
ownership = "worker"
scope = "Run the live checks the offline work for PARITY-MAESTRO-ANDROID-DEVICE left pending."
acceptance = ["Each check passes on the real target: - Normal authenticated ADB reachability for the selected Waydroid target; privileged diagnostics/repair, if required, need separate authority. No substitute phone required. - Review disposable target and installed .qa package; capture exact source/build/APK/flow fingerprints; actual Maestro launches and individual device exits. - Prove 3 sends, 2 decisions, 1 Stop, unchanged recovery counters and sess_1 retention; qualify earlier-history tail separately. - Prove late attachment rejection across sess_1/sess_2 and usable next pick. - Exact-artifact Android fresh welcome, keyboard Back/cancel, sanitized denial, explicit retry and saved-owner relaunch. - Other mapped Android journeys, without substituting unavailable-state checks for positive gaps. - Separate physical-device M2, TalkBack, native picker/IME, live Agent/provider and authoritative run qualification."]
checks = ["Live qualification by an authorized person; offline evidence does not count."]
exclusions = []
closure = "manual"
closure_actor = "xel"
closure_timestamp = "2026-10-22T12:20:13.821156+00:00"
closure_reason = "2026-10-22 owner decision: waived this auto-generated live follow-up to clear the owner queue. The parent task's offline acceptance remains; live evidence was not produced and is not claimed. Reopen if an authorized live window becomes available."
+++

- Sources: [existing goal authority](docs/product/hermes-desktop-parity.md#reference-and-evidence-boundary), [retained offline task history](todo.archive.md).
- Touches: none before conversion; ** stands for the whole repository
