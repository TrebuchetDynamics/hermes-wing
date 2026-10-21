+++
schema = 1
id = "PARITY-NATIVE-LINUX-LIVE"
title = "Live checks for PARITY-NATIVE-LINUX"
short = "Live checks for PARITY-NATIVE-LINUX"
status = "open"
goal = "PARITY"
section = "Needs decision"
rank = 71000
depends_on = ["PARITY-NATIVE-LINUX"]
touches = ["**"]
resources = []
kind = "implementation"
ownership = "worker"
scope = "Run the live checks the offline work for PARITY-NATIVE-LINUX left pending."
acceptance = ["Each check passes on the real target: - Real Agent/provider/SSH/OAuth operation/grant authority, inference and authoritative approval/terminal cancellation remain separately unqualified. - Android/device and Wayland/other-IME/screen-reader qualification were not exercised; native X11 fixture results are not substitutes. - Physical microphone/acoustic routing, actual speech and audio hardware remain unqualified; unavailable capture assertions do not qualify positive voice support. - OS keyring, saved-credential upgrade/readback and signed installer/service/update/rollback acceptance need separately authorized platform checks."]
checks = ["Live qualification by an authorized person; offline evidence does not count."]
exclusions = []
+++

- Sources: [accepted port scope](ROADMAP.md#flutter-port-execution-roadmap), [retained PARITY-NATIVE-LINUX parent and qualifications](todo.archive.md).
- Touches: none before conversion; ** stands for the whole repository
