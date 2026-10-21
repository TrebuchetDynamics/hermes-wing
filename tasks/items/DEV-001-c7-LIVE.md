+++
schema = 1
id = "DEV-001-c7-LIVE"
title = "Live checks for DEV-001-c7"
short = "Live checks for DEV-001-c7"
status = "open"
goal = "INTEGRATION"
section = "Needs decision"
rank = 62000
depends_on = ["DEV-001-c7"]
touches = ["**"]
resources = []
kind = "implementation"
ownership = "worker"
scope = "Run the live checks the offline work for DEV-001-c7 left pending."
acceptance = ["Each check passes on the real target: - No platforms were exercised beyond Linux-hosted SDK static tooling. Native SSH/device/secure-storage/live Agent reachability and actual IME/screen-reader behavior remain unqualified here and retain existing live qualification tasks; this review grants no live access."]
checks = ["Live qualification by an authorized person; offline evidence does not count."]
exclusions = []
+++

- Sources: [existing goal authority](docs/quality/merge-train-shell-status-bar.md), [retained parent and qualifications](todo.archive.md).
- Touches: none before conversion; ** stands for the whole repository
