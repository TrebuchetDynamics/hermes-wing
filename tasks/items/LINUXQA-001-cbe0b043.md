+++
schema = 1
id = "LINUXQA-001-cbe0b043"
title = "Qualify Linux accessibility native lifecycle and voice failure boundaries"
short = "Linux accessibility and lifecycle checks"
status = "open"
goal = "PARITY"
section = "Next"
rank = 6000
depends_on = ["LINUXQA-001-e41e98e5"]
touches = ["integration_test/linux_access_feature_qualification_test.dart", "integration_test/support/linux_access_feature_fixture.dart", "docs/quality/linux-access-qualification.md"]
resources = []
kind = "implementation"
ownership = "worker"
scope = "Reuse shell/footer/keyboard/compact-return/status/native-input fixtures and add named-control, focus/reflow/reduced-motion/contrast-regression and voice-unavailable/cancel/teardown coverage. Exercise offered native menu/clipboard/save behavior only in owned displays/state. Record framework events versus OS-injected versus physical input; inspect packaging tooling without installing/updating/removing an app. Positive real audio, screen reader, Wayland/IME and installed-artifact acceptance stay with existing live tasks."
acceptance = ["New native cases fail on lost focus after dismissal/owner replacement, unreachable enlarged-text controls or hidden keyboard actions; semantics/geometry evidence is classified separately from real screen-reader or physical input.", "Voice denial/unavailability/cancel/disposal yields safe retained text/draft and zero automatic capture/re-arm/send or stale playback callbacks; no synthetic unavailable-capture assertion is counted as positive microphone/audio qualification.", "Existing shell/persistence/footer/native-input and artifact-tooling checks record their actual window/input/storage target and cleanup, while physical/audio/packaged cells remain not-run on their existing owners."]
checks = ["python3 scripts/run_linux_feature_qualification.py --lane access --output-dir \"$TMPDIR/linux-qualification\""]
exclusions = ["No Agent/runtime/upstream edits", "No personal services, credentials, production data or live provider operations", "No installation, publication, schedule change or missing-feature implementation"]
+++

- Sources: [Full Linux qualification plan](docs/plans/2026-10-21-linux-feature-qualification.md)
- Verification status: Planned and UNRUN. Commands naming the proposed campaign driver/checker and new tests become executable only when this task or its real prerequisite implements them. This plan ran no product test, build, listener or native/live operation.
- Planner decision: Use current-source isolated fixture qualification and the existing PARITY goal. Preserve all prior completed work and live/physical/device/package gates; do not change goal focus or start execution from this planning request.
- Consumes: Current committed campaign driver and schema-1 receipts from LINUXQA-001-e41e98e5; each task uses a fresh checkout/output directory and resolves documented compatible dependencies itself, never waits for an unpublished private handoff.
- Next action: Start with the named focused regression or driver unit test in the contract. Future driver/checker/test paths are proposed artifacts, not evidence that a command was run. Resolve ordinary owned-checkout prerequisites without changing a personal service or silently using a different SDK/backend.
- Produces: Implement the exact target/fixture paths in touches. Under task 1 driver, atomically write feature-cases.json beneath the owned WING_LINUX_TEST_ROOT using the plan schema-1 case fields. Driver registration belongs to task 1; do not patch the shared driver from this lane.
