+++
schema = 1
id = "LANDING-PAGES-QUALITY-LIVE"
title = "Live checks for LANDING-PAGES-QUALITY"
short = "Live checks for LANDING-PAGES-QUALITY"
status = "done"
goal = "LANDING-ONBOARDING"
section = "Needs decision"
rank = 45000
depends_on = ["LANDING-PAGES-QUALITY"]
touches = ["**"]
resources = []
kind = "implementation"
ownership = "worker"
scope = "Run the live checks the offline work for LANDING-PAGES-QUALITY left pending."
acceptance = ["Each check passes on the real target: - Authorized CI execution with its pinned Flutter 3.44.6 and any Pages publication/public CDN freshness readback were not performed. Coordinator integration and publication remain separate from this local commit. - Actual browser-chrome zoom, screen readers, physical devices and real-device/field performance remain unqualified; automated text scaling/effective-viewport reflow and focused semantic/contrast guards are not full accessibility certification. - Authenticated first reply and combined real-Agent/provider workflows remain with existing CONNECTION-SETUP-AUTH-MATRIX and PARITY-LIVE-WORKFLOW owners; this task creates no duplicate live QA requirement."]
checks = ["Live qualification by an authorized person; offline evidence does not count."]
exclusions = []
closure = "manual"
closure_actor = "xel"
closure_timestamp = "2026-10-22T12:20:08.396233+00:00"
closure_reason = "2026-10-22 owner decision: waived this auto-generated live follow-up to clear the owner queue. The parent task's offline acceptance remains; live evidence was not produced and is not claimed. Reopen if an authorized live window becomes available."
+++

- Sources: [existing goal authority](docs/plans/2026-10-12-wing-landing-onboarding.md#existing-agent-onboarding-outcome), [retained offline task history](todo.archive.md).
- Touches: none before conversion; ** stands for the whole repository
