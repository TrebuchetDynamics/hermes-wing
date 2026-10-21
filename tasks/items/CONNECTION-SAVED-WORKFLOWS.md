+++
schema = 1
id = "CONNECTION-SAVED-WORKFLOWS"
title = "Complete and prove owner-safe Local/Remote and saved-connection workflows"
status = "done"
goal = "CONNECTION-PATHS"
+++

- Archived: [frozen task history](todo.archive.md)

## Delivered follow-up — saved-connection failure guidance

- Completed and published to `main`: `4f397c46` and `8e0b86a4`.
- Connections, Providers, Tools and Schedules now show typed authentication,
  endpoint, response, network, TLS and timeout recovery guidance without raw
  transport text. Superseded activations and replaced owners cannot publish an
  old result; exceptions before connecting keep generic guidance rather than
  inheriting another connection's authentication error.
- Executed on Linux with Flutter 3.44.9: `flutter analyze --no-pub` passed;
  `flutter test --no-pub --concurrency=1 test/features/gateway test/features/providers test/features/schedules test/features/tools test/shared/widgets/wing_gateway_switch_test.dart test/features/hermes_chat/gateways`
  passed all 461 tests. Changed-file formatting and `git diff --check` passed.
- Do not reimplement this delivered follow-up. These are offline widget/unit
  results, not native microphone, Android, live inference or full workflow proof.
- Remaining live qualification stays open under `CONNECTION-SAVED-WORKFLOWS-LIVE`.
