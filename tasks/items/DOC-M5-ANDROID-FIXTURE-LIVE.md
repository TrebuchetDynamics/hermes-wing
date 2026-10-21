+++
schema = 1
id = "DOC-M5-ANDROID-FIXTURE-LIVE"
title = "Live checks for DOC-M5-ANDROID-FIXTURE"
short = "Live checks for DOC-M5-ANDROID-FIXTURE"
status = "open"
goal = "M5"
section = "Needs decision"
rank = 37000
depends_on = ["DOC-M5-ANDROID-FIXTURE"]
touches = ["**"]
resources = []
kind = "implementation"
ownership = "worker"
scope = "Run the live checks the offline work for DOC-M5-ANDROID-FIXTURE left pending."
acceptance = ["Each check passes on the real target: - Original acceptance is not complete. Obtain a named owned disposable Android target, exclusive build/device access and the matching isolated com.trebuchetdynamics.hermes.wing.qa artifact before executing exactly these two Maestro flows. This offline worker performed no build, install, device operation or live service access. - Capture actual Android text and Markdown clipboard readback receipts and setup return-to-hub/zero-overflow receipts. Syntax and Linux-hosted widget tests do not establish those exits on Android."]
checks = ["Live qualification by an authorized person; offline evidence does not count."]
exclusions = []
+++

- Sources: [existing goal authority](ROADMAP.md#m5--safely-take-away-output-with-native-accessible-interaction), [retained offline task history](todo.archive.md).
- Acceptance reconciliation: Coordinator/human acceptance reconciliation is required: the current production Termux route no longer exposes Copy setup command or a native share sheet. The fixture now follows its existing manual guide; original share-sheet dismissal acceptance remains unmet, not waived or satisfied. Do not restore retired product behavior merely to produce that receipt. - TalkBack, native keyboard/IME and physical-device qualification remain unverified. Independent review and canonical integration are separate from this local task commit.
- Touches: none before conversion; ** stands for the whole repository
