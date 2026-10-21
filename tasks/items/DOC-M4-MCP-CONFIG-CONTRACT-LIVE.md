+++
schema = 1
id = "DOC-M4-MCP-CONFIG-CONTRACT-LIVE"
title = "Live checks for DOC-M4-MCP-CONFIG-CONTRACT"
short = "Live checks for DOC-M4-MCP-CONFIG-CONTRACT"
status = "open"
goal = "M4-MCP"
section = "Needs decision"
rank = 51000
depends_on = ["DOC-M4-MCP-CONFIG-CONTRACT"]
touches = ["**"]
resources = []
kind = "implementation"
ownership = "worker"
scope = "Run the live checks the offline work for DOC-M4-MCP-CONFIG-CONTRACT left pending."
acceptance = ["Each check passes on the real target: - No application, browser, native desktop, physical Android/device, live authentication, provider or Agent operation was exercised. After a suitable unmodified Agent advertises a bounded sanitized exact-authorized MCP config read, separately admit a disposable native/live read-refresh and auth-denial/profile-isolation-recreation journey. This source-only task authorizes no installation, config write, probe, OAuth or arbitrary command execution."]
checks = ["Live qualification by an authorized person; offline evidence does not count."]
exclusions = []
+++

- Sources: [existing goal authority](../../docs/product/hermes-desktop-parity.md#statuses), [retained offline task history](../../todo.archive.md).
- Touches: none before conversion; ** stands for the whole repository
