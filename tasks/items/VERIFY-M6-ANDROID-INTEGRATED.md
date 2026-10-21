+++
schema = 1
id = "VERIFY-M6-ANDROID-INTEGRATED"
title = "Qualify same-artifact Android workflow, upgrade and recovery on an admitted target"
short = "Qualify same-artifact Android workflow, upgrade and recovery on an admitted target"
status = "open"
goal = "M6"
section = "Needs decision"
rank = 20000
depends_on = ["DOC-M6-INTEGRATED-RECEIPT-GAP"]
touches = ["**"]
resources = []
kind = "implementation"
ownership = "worker"
scope = "separately admitted candidate and disposable named Android target; bind installed artifact/package/process identity to applicable M1–M5 outcomes, then a distinct verified predecessor and approved upgrade/failure/recovery sequence. Preserve paired/personal apps, credentials and Agent state. No release, deployment, upstream edits, invented contracts or unapproved inference is authorized here."
acceptance = ["exact source/tag/certificate/artifact and installed-byte readback; named target/OS/ABI/package/process generations; applicable workflow receipts and exact-owner canonical restoration with zero replay. Upgrade and recovery must retain expected state, restore trusted bytes/health and verify canonical owner. Unsupported operations remain explicit gaps; fixtures never qualify M6."]
checks = ["source/artifact-bound admitted Android journeys, sanitized operation counts and readbacks; relevant regression and integration gates for any fixes."]
exclusions = []
+++

- Payoff: prove installed daily use and retained-state recovery, not just APK launch.
- Sources: [M6](../../ROADMAP.md#m6--deliver-an-integrated-qualified-alpha), [first missing binding](../../docs/quality/m6-android-integrated-receipt-gap.md#first-missing-binding).
- External gates: admitted signed candidate and distinct trusted predecessor, disposable target/package and bounded failure/recovery authority; approved QA authentication, exact grants and authoritative provider-call ceiling for live work. No candidate acquisition, install or live action occurred in the predecessor.
- Ownership: coordinator wing; not dispatched. Default: keep M6 unverified and continue independent offline work until those inputs are available.
- Planner decision: skip the live installed-target gate, not independent build and artifact work. Required owner input is disposable Android target/package authority for bounded install/upgrade/failure/recovery and, where needed, secret-safe QA authentication with the existing provider-use ceiling. Candidate, predecessor, signature/source binding and same-artifact receipt preparation are engineering prerequisites, not a request for the owner to build the release. Preserve physical-device and live-authentication distinctions; no spending waiver.
- Touches: none before conversion; ** stands for the whole repository
