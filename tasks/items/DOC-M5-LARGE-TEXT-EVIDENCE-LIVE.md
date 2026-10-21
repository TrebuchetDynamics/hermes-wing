+++
schema = 1
id = "DOC-M5-LARGE-TEXT-EVIDENCE-LIVE"
title = "Live checks for DOC-M5-LARGE-TEXT-EVIDENCE"
short = "Live checks for DOC-M5-LARGE-TEXT-EVIDENCE"
status = "open"
goal = "M5"
section = "Needs decision"
rank = 53000
depends_on = ["DOC-M5-LARGE-TEXT-EVIDENCE"]
touches = ["**"]
resources = []
kind = "implementation"
ownership = "worker"
scope = "Run the live checks the offline work for DOC-M5-LARGE-TEXT-EVIDENCE left pending."
acceptance = ["Each check passes on the real target: - Named owned Android target and matching isolated QA artifact are still needed for actual clipboard readback, Android system 200% text, keyboard/CJK IME and TalkBack focus/actions; no device, browser or native runtime journey ran in this source-inspection task. - Android save/share remains unsupported by the current native saver gate; injected supported-saving fixtures do not qualify it. Existing fixture share-sheet acceptance reconciliation remains unchanged."]
checks = ["Live qualification by an authorized person; offline evidence does not count."]
exclusions = []
+++

- Sources: [existing goal authority](../../ROADMAP.md#m5--safely-take-away-output-with-native-accessible-interaction), [retained offline task history](../../todo.archive.md).
- Touches: none before conversion; ** stands for the whole repository
