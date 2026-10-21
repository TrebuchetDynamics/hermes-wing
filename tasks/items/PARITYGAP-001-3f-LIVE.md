+++
schema = 1
id = "PARITYGAP-001-3f-LIVE"
title = "Live checks for PARITYGAP-001-3f"
short = "Live checks for PARITYGAP-001-3f"
status = "open"
goal = "SLASH-CATALOG"
section = "Needs decision"
rank = 77000
depends_on = ["PARITYGAP-001-3f"]
touches = ["**"]
resources = []
kind = "implementation"
ownership = "worker"
scope = "Run the live checks the offline work for PARITYGAP-001-3f left pending."
acceptance = ["Each check passes on the real target: - Physical Android IME, TalkBack, touch/keyboard and installed-device qualification remain separate; only Linux-hosted widgets and deterministic Linux Chromium were exercised. - No live Agent/provider or other native platform qualification was performed. Agent-config defaults remain explicitly unsynced; authoritative slash catalog/dispatch is unchanged and unavailable through this local control."]
checks = ["Live qualification by an authorized person; offline evidence does not count."]
exclusions = []
+++

- Touches: none before conversion; ** stands for the whole repository
