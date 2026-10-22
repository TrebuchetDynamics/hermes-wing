+++
schema = 1
id = "LINUXQA-001-e41e98e5"
title = "Build safe Linux qualification entrypoint and portable preflight"
short = "Safe Linux qualification preflight"
status = "done"
goal = "PARITY"
section = "Next"
rank = 1000
depends_on = []
touches = ["scripts/run_linux_feature_qualification.py", "test/tooling/linux_feature_qualification_runner_test.py", "integration_test/run_linux_shell_compact_return.py", "integration_test/run_linux_local_serve_reads.py", "integration_test/run_linux_transcript_keyboard.py"]
resources = []
kind = "implementation"
ownership = "worker"
scope = "Implement only the developer-test campaign driver and portability/environment seams described by the plan. Fixed lanes, current-source snapshots, explicit compatible dependency prefix, owned output/display/state and allowlisted subprocess environment; no app feature changes. Repair hard-coded private prefix use in the three named shared runners without copying historical application code."
acceptance = ["Given missing or stale dependencies, wrong SDK/Node major, unsafe output roots or inherited live opt-ins, preflight and linux_feature_qualification_runner_test.py reject before any GTK/SSH/provider/installer child starts.", "Given synthetic subprocess results, the fixed-lane driver preserves exact exits and schema-1 source/tool/case/cleanup identities; empty, interrupted or stale records cannot pass.", "Given an explicit compatible owned prefix, reusable launchers resolve it without private absolute paths; existing self-checks and new environment-isolation tests pass without changing production or Agent source."]
checks = ["python3 -m unittest discover -s test/tooling -p linux_feature_qualification_runner_test.py -v", "python3 -B integration_test/run_linux_shell_compact_return.py --self-check", "python3 scripts/run_linux_feature_qualification.py --lane preflight --output-dir \"$TMPDIR/linux-qualification\""]
exclusions = ["No Agent/runtime/upstream edits", "No personal services, credentials, production data or live provider operations", "No installation, publication, schedule change or missing-feature implementation"]
closure = "coordinator_verified"
closure_evidence = "tasks/evidence/LINUXQA-001-e41e98e5.toml"
+++

- Sources: [Full Linux qualification plan](docs/plans/2026-10-21-linux-feature-qualification.md)
- Verification status: Planned and UNRUN. Commands naming the proposed campaign driver/checker and new tests become executable only when this task or its real prerequisite implements them. This plan ran no product test, build, listener or native/live operation.
- Planner decision: Preflight exits 0 for a completed inspection even when JSON ready=false; runtime lanes exit nonzero before children when not ready. Driver unit tests use synthetic subprocess/filesystem inputs and require no installed GTK libraries, live services or Node installation. This distinction is not a runtime pass.
- Produces: Own the complete fixed driver registry now: connections -> integration_test/linux_connection_feature_qualification_test.dart; chat -> integration_test/linux_chat_feature_qualification_test.dart; management -> integration_test/linux_management_feature_qualification_test.dart; access -> integration_test/linux_access_feature_qualification_test.dart. Shared includes the existing native adapter and task-2 inventory check; report delegates to the task-7 checker. Missing late files block only the selected runtime lane, never preflight/self-checks. Collect new-target feature-cases.json and existing validated receipts; a source file merely existing is not execution.
- Next action: Start with the named focused regression or driver unit test in the contract. Future driver/checker/test paths are proposed artifacts, not evidence that a command was run. Resolve ordinary owned-checkout prerequisites without changing a personal service or silently using a different SDK/backend.
