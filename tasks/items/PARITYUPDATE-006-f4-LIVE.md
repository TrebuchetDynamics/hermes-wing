+++
schema = 1
id = "PARITYUPDATE-006-f4-LIVE"
title = "Live checks for PARITYUPDATE-006-f4"
short = "Live checks for PARITYUPDATE-006-f4"
status = "open"
goal = "INTEGRATION"
section = "Needs decision"
rank = 72000
depends_on = ["PARITYUPDATE-006-f4"]
touches = ["**"]
resources = []
kind = "implementation"
ownership = "worker"
scope = "Run the live checks the offline work for PARITYUPDATE-006-f4 left pending."
acceptance = ["Each check passes on the real target: - Physical keyboard/OS-window resize and screen-reader qualification remain unverified; retained Linux GTK/Xvfb native evidence uses WidgetTester input and framework viewport resizing. - Android/other platforms, live Agent/provider transport, OS keyring, install/update/signing and release qualification remain unchanged and unverified by this deterministic fixture."]
checks = ["Live qualification by an authorized person; offline evidence does not count."]
exclusions = []
+++

- Touches: none before conversion; ** stands for the whole repository
