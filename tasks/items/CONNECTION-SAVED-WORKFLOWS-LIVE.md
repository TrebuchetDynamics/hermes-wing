+++
schema = 1
id = "CONNECTION-SAVED-WORKFLOWS-LIVE"
title = "Live checks for CONNECTION-SAVED-WORKFLOWS"
short = "Live checks for CONNECTION-SAVED-WORKFLOWS"
status = "done"
goal = "CONNECTION-PATHS"
section = "Needs decision"
rank = 11000
depends_on = ["CONNECTION-SAVED-WORKFLOWS"]
touches = ["**"]
resources = []
kind = "implementation"
ownership = "worker"
scope = "Run the live checks the offline work for CONNECTION-SAVED-WORKFLOWS left pending."
acceptance = ["Each check passes on the real target: - Requalify the final candidate through named native Linux and Android application journeys; this run exercised Linux-hosted Flutter widgets and compiled Chromium only. - Approved isolated live Hermes Agent authentication and actual Chat/provider readiness remain unexercised; deterministic discovery/history and injected denial are not live authentication or inference. - OS-native secure storage, directory/document chooser, restart persistence, physical input and screen-reader behavior require matching platform evidence; earlier native receipts retain their own frozen-source scope. - Actual manual Termux installation/start and on-phone background survival remain separately qualified, not proved by the Android-targeted setup widget fixture."]
checks = ["Live qualification by an authorized person; offline evidence does not count."]
exclusions = []
closure = "manual"
closure_actor = "xel"
closure_timestamp = "2026-10-22T12:19:31.860357+00:00"
closure_reason = "2026-10-22 owner decision: waived this auto-generated live follow-up to clear the owner queue. The parent task's offline acceptance remains; live evidence was not produced and is not claimed. Reopen if an authorized live window becomes available."
+++

- Sources: [existing goal authority](docs/product/prd.md#connection-path-requirements), [retained offline task history](todo.archive.md).
- Touches: none before conversion; ** stands for the whole repository

## Completed offline work — do not repeat

The saved-connection failure-guidance follow-up is implemented and published in
`4f397c46` and `8e0b86a4`, with clean analysis and 461 passing focused tests.
See `tasks/items/CONNECTION-SAVED-WORKFLOWS.md` for the exact checks and scope.
This task remains open for its original native/device/live acceptance; those
outcomes are not satisfied by the offline follow-up or the reported local login.

## Native Linux attempt after delivery

- Completed: production `lib/main.dart` Linux debug build from `4b1c0a94`,
  using Flutter 3.44.9 and CMake 3.22.1 after offline lockfile-enforced dependency
  resolution. This differs from the documented Flutter 3.44.2 pin.
- Completed: launched the rebuilt native application and verified its mapped
  compositor window. No Agent service was restarted or modified.
- Executed: Connections → Connect chat using the existing saved connection.
  The native application displayed the typed authentication-rejected guidance;
  profile/model inventory remained unloaded. Window launch is not connection proof.
- Next: reauthenticate the saved exact endpoint/profile in the native application,
  then repeat connection and exact-session restart recovery. Do not repeat the
  delivered failure-guidance implementation. Generation, approvals/Stop, Android,
  screen-reader and acoustic acceptance remain unverified.

## Native credential restart follow-up

- Reauthenticated the saved endpoint through the production native UI: connected
  status, exact selected profile and model inventory were visible. After normal
  process termination and relaunch, explicit Connect chat again displayed an
  authentication rejection. The personal saved-connection restart criterion is
  therefore still failing, not completed.
- Completed a narrower isolated Linux keyring check: the actual Flutter secure
  storage plugin and `SecureHermesEndpointStore.save` replace a synthetic token,
  retain exact endpoint ID/URL and inert legacy fields, and read the replacement
  in a second native process. Both write and verify phases passed on Linux/Wayland
  with Flutter 3.44.9 and GNOME Keyring. No real Agent credential or inference was
  used in that check.
- `scripts/run_linux_secure_storage_regression.sh` now supports an existing
  Wayland display as well as Xvfb, uses private TMPDIR, and preserves the lockfile.
  The integration regression now exercises replacement through the production
  store rather than only seeding a raw secure record.
- Do not repeat this isolated persistence implementation/check as a substitute
  for repairing the personal native save/restart path. Next: isolate the saved
  production connection update and its secure-storage behavior on the failing
  target. Whole-task native/Android/live acceptance remains open.
