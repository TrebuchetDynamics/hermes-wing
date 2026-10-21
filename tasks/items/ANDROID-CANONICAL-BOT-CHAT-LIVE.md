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
