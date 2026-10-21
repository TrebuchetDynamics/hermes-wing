+++
schema = 1
id = "LINUXQA-001-dbb6605f"
title = "Qualify current-source shared regressions and Linux native adapter coverage"
short = "Linux shared regression qualification"
status = "open"
goal = "PARITY"
section = "Next"
rank = 2000
depends_on = ["LINUXQA-001-e41e98e5"]
touches = ["integration_test/linux_feature_regression_test.dart", "test/tooling/linux_feature_adapter_inventory_test.dart", "docs/quality/linux-shared-regression.md"]
resources = []
kind = "implementation"
ownership = "worker"
scope = "Run the documented full Dart, analysis, deterministic browser regression and isolated native-engine adapter on one current immutable source. Reconcile the adapter inventory with current suites including Bot Chat/timestamps/paged export; retain mocked storage/input limits. Fix attributable adapter/test-harness omissions, not arbitrary production features; retain failures and exact unrun inventory."
acceptance = ["Given the current suite tree, the new adapter-inventory regression detects missing current Bot Chat/local-timestamp/paged-export coverage instead of trusting the old 83-import comment.", "Given the frozen candidate and matching tool/dependency inputs, format, full analysis, full Dart suite, compiled deterministic browser suite and Linux adapter produce terminal results and exact selected-versus-recorded case IDs; failures and skips remain explicit.", "The lane records mocked preferences/secure storage/text input separately from real plugins and does not turn browser or native-engine mocks into full Linux qualification."]
checks = ["flutter test --no-pub test/tooling/linux_feature_adapter_inventory_test.dart", "python3 scripts/run_linux_feature_qualification.py --lane shared --output-dir \"$TMPDIR/linux-qualification\""]
exclusions = ["No Agent/runtime/upstream edits", "No personal services, credentials, production data or live provider operations", "No installation, publication, schedule change or missing-feature implementation"]
+++

- Sources: [Full Linux qualification plan](docs/plans/2026-10-21-linux-feature-qualification.md)
- Verification status: Planned and UNRUN. Commands naming the proposed campaign driver/checker and new tests become executable only when this task or its real prerequisite implements them. This plan ran no product test, build, listener or native/live operation.
- Planner decision: Use current-source isolated fixture qualification and the existing PARITY goal. Preserve all prior completed work and live/physical/device/package gates; do not change goal focus or start execution from this planning request.
- Consumes: Current committed campaign driver and schema-1 receipts from LINUXQA-001-e41e98e5; each task uses a fresh checkout/output directory and resolves documented compatible dependencies itself, never waits for an unpublished private handoff.
- Next action: Start with the named focused regression or driver unit test in the contract. Future driver/checker/test paths are proposed artifacts, not evidence that a command was run. Resolve ordinary owned-checkout prerequisites without changing a personal service or silently using a different SDK/backend.
