+++
schema = 1
id = "WING-TASK-408-LIVE"
title = "Live checks for WING-TASK-408"
short = "Live checks for WING-TASK-408"
status = "open"
goal = "PARITY-COMPOSITION"
section = "Needs decision"
rank = 14000
depends_on = ["WING-TASK-408"]
touches = ["**"]
resources = []
kind = "implementation"
ownership = "worker"
scope = "Run the live checks the offline work for WING-TASK-408 left pending."
acceptance = ["Each check passes on the real target: - Android remains unqualified. - Compact saved-host Settings entry is not independently exercised in the native HTTP/SSE matrix; its attempted test extension hit unrelated shell-control availability before reaching the new entry. - No live Agent/provider, physical keyboard, or physical-device qualification was performed."]
checks = ["Live qualification by an authorized person; offline evidence does not count."]
exclusions = []
+++

- Sources: [existing goal authority](docs/product/hermes-desktop-parity.md#reference-and-evidence-boundary), [retained offline task history](todo.archive.md).
- Owner order: leave these checks until after the other pending work. Existing target, authentication and authorization requirements still apply; deferral does not mark any check passed or authorize live actions.
- Touches: none before conversion; ** stands for the whole repository
