+++
schema = 1
id = "ANDROID-CANONICAL-BOT-CHAT-LIVE"
title = "Live checks for ANDROID-CANONICAL-BOT-CHAT"
short = "Live checks for ANDROID-CANONICAL-BOT-CHAT"
status = "open"
goal = "PARITY-TABS"
section = "Needs decision"
rank = 79000
depends_on = ["ANDROID-CANONICAL-BOT-CHAT"]
touches = ["**"]
resources = []
kind = "implementation"
ownership = "worker"
scope = "Run the live checks the offline work for ANDROID-CANONICAL-BOT-CHAT left pending."
acceptance = ["Each check passes on the real target: - Isolated Android .qa device/emulator journeys; adb devices -l returned no attached targets. Android-target widget fixtures are not device execution. - Live unmodified Agent authentication, canonical lookup/create/title-conflict/concurrent-client adoption and actual managed SSH. No live inference used or authorized by this task. - Native accessibility/screen reader, IME and process-death qualification; long forever-chat/frame-bound qualification remains pending."]
checks = ["Live qualification by an authorized person; offline evidence does not count."]
exclusions = []
+++

- Touches: none before conversion; ** stands for the whole repository

## Completed Android emulator slice

- Executed `integration_test/android_bot_chat_test.dart` on the booted
  `wing_ssh_qa` x86_64 emulator, serial `emulator-5554`, using the separate `.qa`
  debug package and Flutter 3.44.9. All three journeys passed on the Android engine:
  unavailable-operation recovery preserves the ordinary draft/session; newer draft
  invalidates pending Bot navigation; native-channel fixture history opens and
  returning restores the ordinary draft without submitting a prompt.
- Exact command: `WING_ISOLATED_DEVICE_TEST=1 flutter test --no-pub --device-id emulator-5554 --dart-define=WING_ANDROID_BOT_CHAT_QA=true integration_test/android_bot_chat_test.dart`.
- This completes the deterministic Android-engine navigation slice, not the whole
  live task. Existing widget/channel scenarios were reused, not reimplemented.
  Real unmodified Agent authentication, managed SSH, concurrent-client arbitration,
  IME, screen reader, process death and long-history qualification remain pending.
- Android build passed with a dependency warning: secure storage requests SDK 37
  while this Flutter toolchain compiles the app against SDK 36. No SDK or dependency
  was silently changed. Emulator evidence does not qualify physical voice.
