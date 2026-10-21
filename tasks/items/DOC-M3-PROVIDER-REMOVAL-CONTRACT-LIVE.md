+++
schema = 1
id = "DOC-M3-PROVIDER-REMOVAL-CONTRACT-LIVE"
title = "Live checks for DOC-M3-PROVIDER-REMOVAL-CONTRACT"
short = "Live checks for DOC-M3-PROVIDER-REMOVAL-CONTRACT"
status = "open"
goal = "M3-PROVIDER"
section = "Needs decision"
rank = 49000
depends_on = ["DOC-M3-PROVIDER-REMOVAL-CONTRACT"]
touches = ["**"]
resources = []
kind = "implementation"
ownership = "worker"
scope = "Run the live checks the offline work for DOC-M3-PROVIDER-REMOVAL-CONTRACT left pending."
acceptance = ["Each check passes on the real target:"]
checks = ["Live qualification by an authorized person; offline evidence does not count."]
exclusions = []
+++

- Sources: [existing goal authority](../../docs/adr/api-and-state.md#required-agent-owned-mutation-contract), [retained offline task history](../../todo.archive.md).
- Only if an eligible unmodified Agent contract becomes available: qualify deployed removal authority, exact credential/profile incarnation and revision, concurrent CLI/API edits, preserved siblings/selection/suppressions, crash/timeout/changed-payload replay, revoked or expired requests, secret-safe errors/audits and separate persistence/activation outcomes using isolated state and explicit authorization. Current source absence leaves removal unavailable; no live removal or credential provisioning was attempted. - Native UI, Android/physical devices and live provider behavior were not exercised. Historical synthetic native removal receipts do not establish authoritative removal or remote provider-key revocation.
- Touches: none before conversion; ** stands for the whole repository
