+++
schema = 1
id = "DOC-M3-ROLLBACK-EVIDENCE-LIVE"
title = "Live checks for DOC-M3-ROLLBACK-EVIDENCE"
short = "Live checks for DOC-M3-ROLLBACK-EVIDENCE"
status = "open"
goal = "M3"
section = "Needs decision"
rank = 47000
depends_on = ["DOC-M3-ROLLBACK-EVIDENCE"]
touches = ["**"]
resources = []
kind = "implementation"
ownership = "worker"
scope = "Run the live checks the offline work for DOC-M3-ROLLBACK-EVIDENCE left pending."
acceptance = ["Each check passes on the real target: - Current new-profile whole-setup rollback and unchanged existing-profile identity remain UNVERIFIED. A separately authorized isolated failure/readback qualification requires a suitable exact unmodified Agent create/identity/outcome contract first; this documentation task authorizes no new attempt. - Native/device secure-storage and target-specific onboarding behavior remain separately unqualified; no platform was exercised by this task."]
checks = ["Live qualification by an authorized person; offline evidence does not count."]
exclusions = []
+++

- Sources: [existing goal authority](ROADMAP.md#m3--trusted-onboarding-into-a-useful-profile-and-workspace), [retained offline task history](todo.archive.md).
- Touches: none before conversion; ** stands for the whole repository
