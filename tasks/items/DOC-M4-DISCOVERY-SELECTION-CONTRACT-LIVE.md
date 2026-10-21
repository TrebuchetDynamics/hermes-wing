+++
schema = 1
id = "DOC-M4-DISCOVERY-SELECTION-CONTRACT-LIVE"
title = "Live checks for DOC-M4-DISCOVERY-SELECTION-CONTRACT"
short = "Live checks for DOC-M4-DISCOVERY-SELECTION-CONTRACT"
status = "open"
goal = "M4-DISCOVER"
section = "Needs decision"
rank = 54000
depends_on = ["DOC-M4-DISCOVERY-SELECTION-CONTRACT"]
touches = ["**"]
resources = []
kind = "implementation"
ownership = "worker"
scope = "Run the live checks the offline work for DOC-M4-DISCOVERY-SELECTION-CONTRACT left pending."
acceptance = ["Each check passes on the real target: - No platform/native/browser/live journey exercised. Only after an eligible authoritative install contract exists and a separately authorized isolated target is available: authenticated install/denial, exact-profile authoritative readback, failure/uncertainty/no-replay and named-platform accessible selection/consent/recovery journeys. This receipt authorizes no installation."]
checks = ["Live qualification by an authorized person; offline evidence does not count."]
exclusions = []
+++

- Sources: [existing goal authority](docs/product/hermes-desktop-parity.md#statuses), [retained offline task history](todo.archive.md).
- Touches: none before conversion; ** stands for the whole repository
