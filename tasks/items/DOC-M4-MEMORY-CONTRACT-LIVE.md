+++
schema = 1
id = "DOC-M4-MEMORY-CONTRACT-LIVE"
title = "Live checks for DOC-M4-MEMORY-CONTRACT"
short = "Live checks for DOC-M4-MEMORY-CONTRACT"
status = "open"
goal = "M4-MEMORY"
section = "Needs decision"
rank = 40000
depends_on = ["DOC-M4-MEMORY-CONTRACT"]
touches = ["**"]
resources = []
kind = "implementation"
ownership = "worker"
scope = "Run the live checks the offline work for DOC-M4-MEMORY-CONTRACT left pending."
acceptance = ["Each check passes on the real target: - No platform was exercised. Authenticated bounded memory reads/denials, profile isolation/recreation, owner-change recovery and accessible target-native inspection require a suitable unmodified authoritative operation and a separately admitted disposable target; not authorized or qualified by this source-only task."]
checks = ["Live qualification by an authorized person; offline evidence does not count."]
exclusions = []
+++

- Sources: [existing goal authority](../../docs/product/hermes-desktop-parity.md#statuses), [retained offline task history](../../todo.archive.md).
- Touches: none before conversion; ** stands for the whole repository
