+++
schema = 1
id = "M1-NOTIFICATION-CONTRACT-LIVE"
title = "Live checks for M1-NOTIFICATION-CONTRACT"
short = "Live checks for M1-NOTIFICATION-CONTRACT"
status = "open"
goal = "M1"
section = "Needs decision"
rank = 28000
depends_on = ["M1-NOTIFICATION-CONTRACT"]
touches = ["**"]
resources = []
kind = "implementation"
ownership = "worker"
scope = "Run the live checks the offline work for M1-NOTIFICATION-CONTRACT left pending."
acceptance = ["Each check passes on the real target: - Existing M1-MOBILE-AWAY-STATUS Android matrix remains NOT_CHECKED; this documentation assessment does not qualify reliable Android away/return status. - After separately scoped local-alert implementation, qualify permission denial/revocation, generic locked-screen payloads, exact-owner taps, focus transitions and deduplication on named native artifacts/targets. No application platform was exercised in this assessment. - Suspended/terminated Android/iOS and browser push remain unavailable pending an authoritative notification enrollment/routing/rotation/revocation/redemption contract, separate architecture/privacy/provider or relay consent decisions, and real platform delivery evidence. No provider or relay was selected or activated."]
checks = ["Live qualification by an authorized person; offline evidence does not count."]
exclusions = []
+++

- Sources: [existing goal authority](docs/product/prd.md#leading-acceptance-outcome), [retained offline task history](todo.archive.md).
- Touches: none before conversion; ** stands for the whole repository
