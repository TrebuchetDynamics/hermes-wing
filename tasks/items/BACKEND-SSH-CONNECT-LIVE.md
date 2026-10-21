+++
schema = 1
id = "BACKEND-SSH-CONNECT-LIVE"
title = "Live checks for BACKEND-SSH-CONNECT"
short = "Live checks for BACKEND-SSH-CONNECT"
status = "open"
goal = "REMOTE-BACKENDS"
section = "Needs decision"
rank = 24000
depends_on = ["BACKEND-SSH-CONNECT"]
touches = ["**"]
resources = []
kind = "implementation"
ownership = "worker"
scope = "Run the live checks the offline work for BACKEND-SSH-CONNECT left pending."
acceptance = ["Each check passes on the real target: - No Android device/emulator was attached (adb devices -l was empty). Run the existing isolated Android SSH fixture journey and separate authorized controlled already-configured SSH/Agent target proof through the production form: host trust, authentication, explicit serve selection, profile/history loading, deliberate usable chat and transport-loss/no-replay behavior. SSH login or deterministic tests alone cannot qualify this outcome. - Preserve Linux full-app acceptance with a named controlled-target receipt. This run exercised Linux-hosted deterministic tests and SSH trust/authentication/cancellation, not successful native full-app forwarding. The existing key journey covers advertised API reads, not the added serve chat selection; native picker/keystore qualification remains with BACKEND-SSH-KEY-NATIVE. - Retain the task's required native/security review and qualification dependency. Independent offline code review does not close it. Review docs/quality/android-ssh-serve-offline.md for unsupported behavior: per-attempt host trust only, no durable SSH target/profile/session mapping or cold SSH relaunch; unsupported targets retain external-tunnel access."]
checks = ["Live qualification by an authorized person; offline evidence does not count."]
exclusions = []
+++

- Sources: [existing goal authority](docs/product/hermes-desktop-parity.md#statuses), [retained offline task history](todo.archive.md).
- Touches: none before conversion; ** stands for the whole repository
