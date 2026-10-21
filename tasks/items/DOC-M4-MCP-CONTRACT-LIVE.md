+++
schema = 1
id = "DOC-M4-MCP-CONTRACT-LIVE"
title = "Live checks for DOC-M4-MCP-CONTRACT"
short = "Live checks for DOC-M4-MCP-CONTRACT"
status = "open"
goal = "M4-MCP"
section = "Needs decision"
rank = 35000
depends_on = ["DOC-M4-MCP-CONTRACT"]
touches = ["**"]
resources = []
kind = "implementation"
ownership = "worker"
scope = "Run the live checks the offline work for DOC-M4-MCP-CONTRACT left pending."
acceptance = ["Each check passes on the real target: - Native/live authenticated enable/disable and exact authoritative readback remain unqualified. A separately authorized isolated target can exercise them only after an unmodified Agent exposes the required exact operation, profile/platform identity, grants, concurrency and persistence/activation/retry guarantees; this documentation slice adds no write support."]
checks = ["Live qualification by an authorized person; offline evidence does not count."]
exclusions = []
+++

- Sources: [existing goal authority](docs/product/hermes-desktop-parity.md#statuses), [retained offline task history](todo.archive.md).
- Touches: none before conversion; ** stands for the whole repository
