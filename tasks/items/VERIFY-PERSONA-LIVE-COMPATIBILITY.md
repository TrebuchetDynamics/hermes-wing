+++
schema = 1
id = "VERIFY-PERSONA-LIVE-COMPATIBILITY"
title = "Qualify Persona revision-aware saves and conflict recovery against an authorized deployed Agent"
short = "Qualify Persona revision-aware saves and conflict recovery against an authorized deployed Agent"
status = "open"
goal = "PERSONA"
section = "Needs decision"
rank = 16000
depends_on = ["VERIFY-PERSONA-NATIVE-CONFLICT"]
touches = ["**"]
resources = []
kind = "implementation"
ownership = "worker"
scope = "production standalone Persona and Profiles modal on a named disposable QA profile, through exact advertised Agent SOUL read/write operations and supported private authentication. No personal profile/credential discovery, provider inference, Agent edits, compatibility adapter or new draft mechanism."
acceptance = ["verify the deployed operation/path/grants and profile context; deliberate ordinary save persists exact text; a real concurrent revision change rejects the stale save, loads authoritative newer text and permits only a deliberate retry at the new revision. Prove exact owner and write counts with sanitized server readback; native fixtures alone do not qualify this task. Android, physical IME and screen-reader coverage remain separately unqualified."]
checks = ["current five-target Persona regressions plus an explicitly authorized bounded native/live journey with source, toolchain, target and operation receipts."]
exclusions = []
+++

- Payoff: distinguish the passing synthetic GTK recovery from actual server revision/concurrency enforcement.
- Sources: [native qualification boundary](../../docs/quality/persona-native-conflict.md#retained-failures-and-qualification-boundary), [PERSONA](../../docs/product/hermes-desktop-parity.md#statuses).
- Ownership: unclaimed. Required external input: an authorized disposable deployed Agent target with supported private authentication and exact revision-aware SOUL read/write grants. No such live access was supplied by the synthetic native run.
- Planner decision: skip deployed mutation qualification until the owner supplies an authorized disposable Agent/profile and private authentication permitting bounded SOUL read/write plus a controlled concurrent revision change. Read-only access is insufficient for this task. Preserve the already-passing synthetic native predecessor; do not repeat it as a substitute or touch a personal profile. Never request tokens in chat or infer mutation consent from successful login.
- Touches: none before conversion; ** stands for the whole repository
