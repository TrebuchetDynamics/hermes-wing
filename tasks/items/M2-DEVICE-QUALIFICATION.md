+++
schema = 1
id = "M2-DEVICE-QUALIFICATION"
title = "Owner: run the named-device Android death-to-completion qualification (physical device); agents prepare nothing further until then"
short = "Owner: run the named-device Android death-to-completion qualification (physical device); agents prepare nothing further until then"
status = "open"
goal = "M2"
section = "Needs decision"
rank = 19000
depends_on = ["owner-provided device and the existing admission prerequisites"]
touches = ["**"]
resources = []
kind = "implementation"
ownership = "worker"
scope = "only the admitted isolated device scenario and sanitized receipt; exclude personal credentials, unadmitted QA runtime and synthetic qualification claims."
acceptance = ["named-device receipt proves completion while absent, exact restoration and authoritative no-replay counts. A device alone does not supply missing admission."]
exclusions = []
+++

- Sources: [M2 baseline and exact scenario](docs/quality/2026-10-06-m2-continuity-baseline.md#exactly-one-future-scenario-android-m2-death-complete-01) and [BLK-20261006-W02](BLOCKERS.md#blk-20261006-w02--physical-device-run-for-m2-android-recovery).
- Ownership: owner question, not assigned by this index. Default if no answer: retain the physical-device ledger slice and unverified status. The owner selected Waydroid for independent Android QA under PARITY-MAESTRO-ANDROID-DEVICE; that setup and execution proceed without satisfying this physical-device slice. Desktop-first work proceeds independently.
- Planner decision: skip the physical-device gate under the owner's existing Waydroid-now default; do not ask that policy question again. The remaining input is a named physical Android target and permission to operate its isolated QA app, plus the unchanged engineering admission prerequisites. Device availability alone is not readiness. Continue independent Waydroid/offline work without claiming physical process-death proof or requiring the owner to design a harness.
- Touches: none before conversion; ** stands for the whole repository
