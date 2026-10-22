+++
schema = 1
id = "LINUXQA-001-dbb6605f"
title = "Qualify current-source shared regressions and Linux native adapter coverage"
short = "Linux shared regression qualification"
status = "done"
goal = "PARITY"
section = "Next"
rank = 2000
depends_on = ["LINUXQA-001-e41e98e5"]
touches = ["integration_test/linux_feature_regression_test.dart", "test/tooling/linux_feature_adapter_inventory_test.dart", "docs/quality/linux-shared-regression.md", "scripts/run_linux_feature_qualification.py", "scripts/support/linux_qualification_support.py", "test/tooling/linux_feature_qualification_runner_test.py", "docs/quality/linux-qualification-driver.md"]
resources = []
kind = "implementation"
ownership = "worker"
scope = "Run the documented full Dart, analysis, deterministic browser regression and isolated native-engine adapter on one current immutable source. Reconcile the adapter inventory with current suites including Bot Chat/timestamps/paged export; retain mocked storage/input limits. Fix attributable adapter/test-harness omissions, not arbitrary production features; retain failures and exact unrun inventory. Own the demonstrated driver prerequisites in the added paths: stock native-only package and bundled SDK metadata validation, desktop source closure, owned fixture-port propagation and bounded complete native-batch dispatch. Preserve URI/root containment, dependency freshness, full selected inventory, exact exits and cleanup. No manifests, lockfile or plugin changes."
acceptance = ["Given the current suite tree, the new adapter-inventory regression detects missing current Bot Chat/local-timestamp/paged-export coverage instead of trusting the old 83-import comment.", "Given the frozen candidate and matching tool/dependency inputs, format, full analysis, full Dart suite, compiled deterministic browser suite and Linux adapter produce terminal results and exact selected-versus-recorded case IDs; failures and skips remain explicit.", "The lane records mocked preferences/secure storage/text input separately from real plugins and does not turn browser or native-engine mocks into full Linux qualification."]
checks = ["python3 -m unittest discover -s test/tooling -p linux_feature_qualification_runner_test.py -v", "flutter test --no-pub test/tooling/linux_feature_adapter_inventory_test.dart", "python3 scripts/run_linux_feature_qualification.py --lane shared --output-dir \"$TMPDIR/linux-qualification\""]
exclusions = ["No Agent/runtime/upstream edits", "No personal services, credentials, production data or live provider operations", "No installation, publication, schedule change or missing-feature implementation"]
closure = "coordinator_verified"
closure_evidence = "tasks/evidence/LINUXQA-001-dbb6605f.toml"
+++

- Sources: [Full Linux qualification plan](docs/plans/2026-10-21-linux-feature-qualification.md)
- Verification status: Planned and UNRUN. Commands naming the proposed campaign driver/checker and new tests become executable only when this task or its real prerequisite implements them. This plan ran no product test, build, listener or native/live operation.
- Planner decision: Technical recovery within this task, not an acceptance waiver. Latest report establishes prerequisite-only commit abebaae77fcc586e2af06617e7bb6a8c3a852c38 and unfinished adapter/inventory/doc work. Add omitted prerequisite scope and finish implementation; native-only metadata needs positive and escaping/stale negative tests. No report-only retry, replacement task, fabricated pass or weakened containment.
- Consumes: Current committed campaign driver and schema-1 receipts from LINUXQA-001-e41e98e5; each task uses a fresh checkout/output directory and resolves documented compatible dependencies itself, never waits for an unpublished private handoff.
- Next action: Recover retained commit abebaae77fcc586e2af06617e7bb6a8c3a852c38 and inspect preserved dirty/untracked implementation in its old task worktree before restoring attributable work onto current base. Complete the inventory regression, Linux adapter and linux-shared-regression.md. Preserve out-of-scope dirty Android adapter edits; trace any necessary shared import correction before proposing an extension. Complete driver repairs and required checks on one immutable candidate. Investigate two retained gateway Back native failures against current base; no skipped cases or silent exclusions. Cancelled/incomplete 776-case evidence is not a pass; reuse source-bound checks only for matching inputs.
- Blocker resolution: report.json does not match worker commit/files or reports failure: a check did not pass; retained report and prerequisite-only commit abebaae77fcc586e2af06617e7bb6a8c3a852c38 inspected. Corrected omitted prerequisite scope/touches for same-task implementation continuation, preserving dirty work, reports and all acceptance rather than a report-only resume.
- Pending live: PARITY-NATIVE-LINUX-LIVE / VERIFY-SHELL-NATIVE-INPUT: real Linux keyring/preferences persistence, native chooser/clipboard, OS/physical input, Wayland/IME, screen-reader and microphone/acoustic qualification remain unverified. This campaign exercised GTK/X11/Xvfb and headless Chromium with the documented deterministic storage/input/picker seams, not physical devices or other platforms.
- Pending live: PARITY-LIVE-WORKFLOW-LIVE / BACKEND-SSH-KEY-NATIVE-LIVE: authorized actual Agent/provider/SSH/OAuth workflow remains separate. Browser regression/hermes-live-say-hi.spec.mjs case 'Hermes Wing sends a say-hi turn through the live Hermes Agent' was explicitly skipped because no live target was configured; it is not a fixture pass.
- Pending live: VERIFY-DESKTOP-NATIVE-DELIVERY: exact packaged-artifact installation, upgrade, retained keyring custody and rollback require the existing separately authorized disposable-target qualification.
