+++
schema = 1
id = "LANDING-PAGES-QUALITY-LIVE"
title = "Live checks for LANDING-PAGES-QUALITY"
short = "Live checks for LANDING-PAGES-QUALITY"
status = "open"
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
+++

- Sources: [existing goal authority](docs/plans/2026-10-12-wing-landing-onboarding.md#existing-agent-onboarding-outcome), [retained offline task history](todo.archive.md).
- Touches: none before conversion; ** stands for the whole repository
