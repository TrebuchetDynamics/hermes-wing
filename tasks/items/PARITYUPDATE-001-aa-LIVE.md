+++
schema = 1
id = "PARITYUPDATE-001-aa-LIVE"
title = "Live checks for PARITYUPDATE-001-aa"
short = "Live checks for PARITYUPDATE-001-aa"
status = "open"
goal = "CONNECTION-PATHS"
section = "Needs decision"
rank = 63000
depends_on = ["PARITYUPDATE-001-aa"]
touches = ["**"]
resources = []
kind = "implementation"
ownership = "worker"
scope = "Run the live checks the offline work for PARITYUPDATE-001-aa left pending."
acceptance = ["Each check passes on the real target: - No product platform was exercised. Named-target canonical attachment/reconnect/disconnect qualification remains separate from this source-only task; retain existing Linux/Android/SSH/remote qualification owners and require a separately admitted implementation before positive canonical-native acceptance."]
checks = ["Live qualification by an authorized person; offline evidence does not count."]
exclusions = []
+++

- Sources: [existing goal authority](docs/product/prd.md#connection-path-requirements), [retained parent and qualifications](todo.archive.md).
- Touches: none before conversion; ** stands for the whole repository
