+++
schema = 1
id = "LINUXQA-001-c7841f6e"
title = "Qualify Linux Chat sessions Bot Chat queues and export controls"
short = "Linux Chat and session qualification"
status = "open"
goal = "PARITY"
section = "Next"
rank = 4000
depends_on = ["LINUXQA-001-e41e98e5", "LINUXQA-001-dbb6605f"]
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
- Planner decision: The campaign genuinely depends on the platform-only package validator repair now owned by LINUXQA-001-dbb6605f, not merely overlapping writes. Preserve Chat acceptance and its three-file boundary; no shared-driver bypass.
- Consumes: Current committed campaign driver and schema-1 receipts from LINUXQA-001-e41e98e5; each task uses a fresh checkout/output directory and resolves documented compatible dependencies itself, never waits for an unpublished private handoff.
- Next action: After LINUXQA-001-dbb6605f lands, reuse Chat candidate a6d6edcbfbdc18b952faad7f8ae44b94f9339cb1 on current source, not a reimplementation of its 24 standalone cases. Run the exact Chat campaign to terminal completion, including matching-source two-process recovery. Preserve unsupported/unrun cells, all checks and live gates. Standalone GTK passes and preflight refusal are not aggregate success.
- Produces: Implement the exact target/fixture paths in touches. Under task 1 driver, atomically write feature-cases.json beneath the owned WING_LINUX_TEST_ROOT using the plan schema-1 case fields. Driver registration belongs to task 1; do not patch the shared driver from this lane.
- Blocker resolution: Required Chat campaign exits 2 before dispatch: Missing or escaping package import URI. Existing shared qualification task now owns that repair; wait for its actual result and revalidate this preserved candidate without waiving the campaign check.
