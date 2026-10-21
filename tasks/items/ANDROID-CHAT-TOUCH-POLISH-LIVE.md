+++
schema = 1
id = "ANDROID-CHAT-TOUCH-POLISH-LIVE"
title = "Live checks for ANDROID-CHAT-TOUCH-POLISH"
short = "Live checks for ANDROID-CHAT-TOUCH-POLISH"
status = "open"
goal = "PARITY"
section = "Needs decision"
rank = 74000
depends_on = ["ANDROID-CHAT-TOUCH-POLISH"]
touches = ["**"]
resources = []
kind = "implementation"
ownership = "worker"
scope = "Run the live checks the offline work for ANDROID-CHAT-TOUCH-POLISH left pending."
acceptance = ["Each check passes on the real target: - Isolated Waydroid Android public-control, real software-keyboard/Back/cancel, text-scaling and owner-switch journeys: Waydroid reports RUNNING but IP UNKNOWN, ADB lists no target, and the bounded shell probe requires root/operator access. No container restart, escalation or installation attempted. Status/probe log: $TMPDIR/waydroid-access.log. These are pending qualification, not offline blockers. - TalkBack remains UNVERIFIED. Physical Android device/native accessibility, live SSH/Agent/provider, secure-storage and acoustic outcomes were not exercised. Widget insets/platform Back and Chromium widths do not qualify Android input. - Human final visual/mockup acceptance and complete Android multi-session parity remain unqualified. Native-serve tabs (including Android SSH serve) and cross-profile background streaming retain the predecessor's explicit unsupported boundaries."]
checks = ["Live qualification by an authorized person; offline evidence does not count."]
exclusions = []
+++

- Touches: none before conversion; ** stands for the whole repository

## Completed emulator-engine composer slice

- Added `integration_test/android_chat_usability_test.dart`, reusing production
  Chat and existing deterministic regression scenarios on the Android engine.
- Five cases passed on `wing_ssh_qa` (`emulator-5554`, x86_64, isolated `.qa`
  debug package): compact header/composer at 390/480/599 logical pixels,
  retained draft during a streamed fixture response, and Enter/Space control
  traversal at 200% text with reduced motion and explicit capture cancellation.
- Command: `WING_ISOLATED_DEVICE_TEST=1 flutter test --no-pub --device-id emulator-5554 --dart-define=WING_ANDROID_CHAT_USABILITY_QA=true integration_test/android_chat_usability_test.dart`.
  Flutter 3.44.9 analysis passed; changed-file formatting passed. Android builds
  still warn that secure storage requests SDK 37 while this SDK compiles at 36.
- This runner explicitly uses framework text/key input and mocked service/storage
  seams. It does not qualify real OS IME/Back, TalkBack, physical touch, live
  Agent/SSH, secure persistence or voice. Those original acceptance cells remain
  open; do not repeat the completed composer slice as new implementation.
