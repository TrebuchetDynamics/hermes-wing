+++
schema = 1
id = "SECURITY-RETAINED-RELEASE-AUDIT-LIVE"
title = "Live checks for SECURITY-RETAINED-RELEASE-AUDIT"
short = "Live checks for SECURITY-RETAINED-RELEASE-AUDIT"
status = "open"
goal = "SECURITY"
section = "Needs decision"
rank = 58000
depends_on = ["SECURITY-RETAINED-RELEASE-AUDIT"]
touches = ["**"]
resources = []
kind = "implementation"
ownership = "worker"
scope = "Run the live checks the offline work for SECURITY-RETAINED-RELEASE-AUDIT left pending."
acceptance = ["Each check passes on the real target: - Native/device and live Agent/provider qualification were not exercised; evidence is Linux-hosted Node audit/guard only. - Named-target release signing, installation, activation, rollback and distribution remain separate qualification; no release workflow or publication was executed."]
checks = ["Live qualification by an authorized person; offline evidence does not count."]
exclusions = []
+++

- Sources: [existing goal authority](docs/product/prd.md#product-rules), [retained offline task history](todo.archive.md).
- Touches: none before conversion; ** stands for the whole repository
