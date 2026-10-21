+++
schema = 1
id = "LINUXQA-001-c7841f6e"
title = "Qualify Linux Chat sessions Bot Chat queues and export controls"
short = "Linux Chat and session qualification"
status = "open"
goal = "PARITY"
section = "Next"
rank = 4000
depends_on = ["LINUXQA-001-e41e98e5"]
touches = ["integration_test/linux_chat_feature_qualification_test.dart", "integration_test/support/linux_chat_feature_fixture.dart", "docs/quality/linux-chat-qualification.md"]
resources = []
kind = "implementation"
ownership = "worker"
scope = "Use production channels against synthetic authenticated HTTP/SSE/native fixtures for the current Chat/session/workspace surface. Reuse stream/Stop/restart helpers; add bounded public GTK cases for canonical Bot Chat, API tab ownership, queue/draft races, model/session actions, local timestamps/slash, attachment ownership and paged JSON save/overwrite/cancel. Native-serve tabs/attachments, absent clarification contracts and frozen-snapshot export remain explicit unsupported boundaries."
acceptance = ["Given a current owner and delayed or competing operations, new native cases reject wrong Bot Chat registry/hidden/history adoption, replacement-owner queue/draft writes and stale approval/Stop/attachment completions with exact operation counts.", "Given rendered controls, session search/fork/rename/delete/pin/pagination, supported tab/Bot Chat access, local slash/timestamps and each export format execute or expose their exact unsupported boundary; JSON replacement consent/refusal/cancel and destination bytes are checked separately from live projection.", "Existing streaming-under-overlay and two-process recovery remain source-bound with no replay; newer-case omissions, unknown terminal outcomes or unexercised real chooser branches remain failed/not-run cells, not synthetic success."]
checks = ["python3 scripts/run_linux_feature_qualification.py --lane chat --output-dir \"$TMPDIR/linux-qualification\""]
exclusions = ["No Agent/runtime/upstream edits", "No personal services, credentials, production data or live provider operations", "No installation, publication, schedule change or missing-feature implementation"]
+++

- Sources: [Full Linux qualification plan](docs/plans/2026-10-21-linux-feature-qualification.md)
- Verification status: Planned and UNRUN. Commands naming the proposed campaign driver/checker and new tests become executable only when this task or its real prerequisite implements them. This plan ran no product test, build, listener or native/live operation.
- Planner decision: Use current-source isolated fixture qualification and the existing PARITY goal. Preserve all prior completed work and live/physical/device/package gates; do not change goal focus or start execution from this planning request.
- Consumes: Current committed campaign driver and schema-1 receipts from LINUXQA-001-e41e98e5; each task uses a fresh checkout/output directory and resolves documented compatible dependencies itself, never waits for an unpublished private handoff.
- Next action: Start with the named focused regression or driver unit test in the contract. Future driver/checker/test paths are proposed artifacts, not evidence that a command was run. Resolve ordinary owned-checkout prerequisites without changing a personal service or silently using a different SDK/backend.
- Produces: Implement the exact target/fixture paths in touches. Under task 1 driver, atomically write feature-cases.json beneath the owned WING_LINUX_TEST_ROOT using the plan schema-1 case fields. Driver registration belongs to task 1; do not patch the shared driver from this lane.
