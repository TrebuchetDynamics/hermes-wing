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

## Legacy branch reconciliation

The retained `wt/android-ssh-reconnect` dirty candidate was reviewed against
current main. Profile-path bootstrap, forwarded-owner recovery, typed Agent
failures and SSH retry routing are already implemented by newer main code.
Do not reimport its older controller/panel: doing so would regress host-pin checks,
bootstrap-loss fencing and disconnect-before-forward-release ordering.

The additional opt-in SSH credential persistence/reconnect/forget implementation
is not accepted as complete: it lacks current owner fencing, explicit save outcome
and real process-restart evidence. Its original tracked delta and untracked tests
are preserved in the private branch-cleanup archive, not shipped as support.
If resumed, adapt it to the current secure target/trust/recovery stores; retain
API/serve separation and require explicit consent, stale-save rejection and
two-process Android Keystore verification. The path-profile regression was rescued
separately onto current main. This task's live acceptance remains open.
