# Native no-inference shell restart

Card `t_ac65a3cb`; goal task `PARITY-NATIVE-NO-INFERENCE-SMOKE`, M1.

## Contract and source boundary

Run `bash scripts/run_linux_desktop_no_inference_smoke.sh`. No arguments,
credentials, caller-selected endpoints or live mode are accepted. The source-run
QA launcher uses production `AppShell`, `HermesChatScreen`,
`HermesGatewayDirectory`, `GatewayContactCache` and `HermesApiChannel` with
synthetic in-process reads. All mutation transports are unsupported. No provider
or network fixture server is involved.

Two actual Linux GTK integration processes share one owned authenticated Xvfb
and isolated HOME/XDG preferences. The second process restores the exact saved
synthetic profile/session/history from production preferences, without reseeding
selection. Injected Flutter keyboard events cover loading Escape cancellation,
failed-read retry, wrong-session history rejection and successful Space retry.
This is native widget keyboard evidence, not physical keyboard/IME qualification.

Current Wing inputs have per-file hashes, owned/inherited attribution and dirty
status in `source.json`. Reviewed helper/test overlays come from local Git object
`894439b76c889fed45f3c4d57b73086f1e18d479`; the older dirty shared helper is not
silently used. Only this card's six paths enter its local attributed commit.
Locally prepared Flutter dependencies and that Git object are prerequisites;
packaged execution remains NOT_CHECKED.

The snapshot opens each source component without following symlinks and rejects
linked/non-regular included inputs before reading them. Nested `.pi`, `.hermes`,
`.ua`, environment files, Git/cache/build directories are excluded before
traversal. Upstream clones and personal runtime roots are never selected.
Behavioral Python regressions exercise outside-root file/directory links,
excluded nested runtime trees and retained source after subsequent shared edits.

Before any checks or build preparation, the launcher retains the entire candidate
and reviewed overlays as owner-read-only `executed-source.tar.gz`, alongside
`source.json` and `archive.json`. Archive contents are hash-checked against the
complete manifest, not reconstructed later from a drifting shared checkout.
The archive includes the manifest and every analyzed source input. At completion,
all candidate hashes (including overlays) are compared again; no missing input
is accepted. Owned driver/app/display groups are confirmed gone before ephemeral
SDK/build/preferences are deleted. The exact source bundle remains as evidence.

## Review correction

The earlier `attempt-43fqf0rj` receipt is superseded, not current acceptance
evidence. Its post-run reconstruction omitted one analyzed inherited input and
included excluded nested local tool state. Do not reuse or republish that archive.
The corrected candidate must be captured before execution, with no missing inputs
and no local runtime-state traversal. No sensitive state is inspected to repair
this defect; fresh source capture and fresh execution replace the old receipt.

## Executed corrected qualification

`timeout 30m bash scripts/run_linux_desktop_no_inference_smoke.sh` exited 0 with
`NATIVE_NO_INFERENCE_PASS` in 142.673 seconds. This revision required one native
attempt, with no retries. Linux x86_64 / GTK on kernel 7.0.0-31-generic,
Flutter 3.44.2 / Dart 3.12.2 (framework c9a6c48423) were exercised, not a live Agent.

Current evidence is `build/t_ac65a3cb/attempt-fq28lfnc/`: `source.json`,
`archive.json`, `executed-source.tar.gz`, `verification.json`, `check-*.log`,
`write.log` and `verify.log`. The base is
`b9eb5b3d9f6f3a433dd36cb6271ad8ec769b2319`; 1,065 captured inputs include
210 inherited dirty inputs, plus five separately attributed predecessor
overlays replacing existing paths. The full candidate was archived before any
check. There are no missing analyzed inputs. This document's execution report
is a post-check documentation-only delta; its pre-report bytes remain archived.

Archive size: 9,304,469 bytes; SHA-256
`3c6ff9a769d090fbc327c6b298415da339a92370654e117c09488a005f056108`.
The manifest SHA-256 is
`7a519393a4b5a5d3cd887e97079046d2c96e73621c0f36f2843ed3f1c9982bec`.
After teardown, an independent archive read compared every member's bytes with
the manifest, checked regular-file membership and excluded runtime-state names,
confirmed the archived manifest, and matched all executed candidate hashes.
The complete retained archive survived deletion of the temporary candidate.

Commands below ran in that isolated candidate; exact SDK paths, exits and
durations are retained in `verification.json`.

| Command | Exit | Seconds | Result |
| --- | --- | --- | --- |
| `bash -n scripts/run_linux_desktop_no_inference_smoke.sh` | 0 | 0.028 | syntax |
| `python3 -B -m unittest discover -s test/tooling -p desktop_no_inference_smoke_test.py` | 0 | 0.137 | 12 tests |
| `dart format --output=none --set-exit-if-changed integration_test/linux_desktop_no_inference_smoke_test.dart integration_test/support/desktop_no_inference_fixture.dart` | 0 | 0.136 | unchanged |
| `flutter analyze --no-pub` | 0 | 21.314 | no issues |
| `flutter test --no-pub --concurrency=1 test/tooling/desktop_live_workflow_budget_test.dart test/features/hermes_chat/screens/hermes_chat_session_search_resume_journey_test.dart test/shared/widgets/app_shell_global_session_modal_test.dart` | 0 | 26.984 | 23 tests |
| `python3 -B -m unittest test.tooling.desktop_live_workflow_test.BoundaryTests.test_no_auth_no_network_or_workspace test.tooling.desktop_live_workflow_test.BoundaryTests.test_live_call_ceiling_refusal_survives_remaining_and_exhausted_budget test.tooling.desktop_live_workflow_test.BoundaryTests.test_fresh_process_phase_and_reset_counter_cannot_upgrade_live_admission test.tooling.desktop_live_workflow_test.BoundaryTests.test_real_launcher_no_inputs` | 0 | 0.691 | 4 public refusal tests |
| `bash scripts/run_linux_desktop_live_workflow.sh < /dev/null` | 2 (expected) | bounded 30 s | AUTHORIZATION_REQUIRED_NO_NETWORK; zero I/O |

The canonical wrapper was also freshly exercised in the shared checkout:
`timeout 5m npm run test -- test/tooling/desktop_live_workflow_budget_test.dart test/features/hermes_chat/screens/hermes_chat_session_search_resume_journey_test.dart test/shared/widgets/app_shell_global_session_modal_test.dart`
exited 0, 23 tests. This is targeted, not a full-suite run; the frozen native
qualification above remains the source-bound acceptance receipt.

Native commands were
`flutter test --verbose --no-pub --concurrency=1 -d linux integration_test/linux_desktop_no_inference_smoke_test.dart`.
Flutter native integration ignores test concurrency; phases were sequential,
with CMake and Go bounded to two workers.

| Phase | Driver PID | GTK PID | Exit | Seconds |
| --- | --- | --- | --- | --- |
| write | 3107576 | 3112917 | 0 | 38.763 |
| verify | 3113404 | 3115753 | 0 | 38.828 |

Both phases shared authenticated Xvfb PID 3107540, display `:1`, and the same
isolated storage. Real protocol probes rejected missing/wrong authority before
launch. App process-group/executable/start-tick identity was observed while live.
All driver/app/display groups were confirmed gone before state deletion and
their `/proc` identities were independently absent afterward.

Both phases restored owner hash
`4735197aa74274d5c54c9c50bd987da294180a0b9da1d9836921b38201bbfae0`
and history hash
`fd80e7b15d758f94e8b2513ad566a17d4c94df71879190d885f5061826f314a2`.
Keyboard loading cancellation, failed-read retry and wrong-owner rejection
passed in both. Sends, creates, model writes, approvals, Stop, provider requests
and mutation attempts were zero. Provider zero is structural fixture evidence,
not a backend billing receipt.

Ten development archives were again downloaded/extracted under ignored task
scratch for missing GStreamer/libsecret headers; their hashes and versions are in
the receipt. Only user-space pkg-config/linker preparation was used. No sudo,
system/device install or dependency upgrade occurred. Temporary SDK/build/state
was removed by the runner; development-package scratch is removed at handoff.
Only cited source evidence and compact logs/receipts survive. Cost unknown; no
provider spending occurred. No predecessor helper or production Dart was edited.

Acceptance mapping: (1) real two-GTK execution with persisted synthetic exact
identities and keyboard recovery; (2) zero mutation seams plus 12 Python snapshot/
receipt tests, four public admission tests and six Dart admission guards within
the 23-test suite; (3) complete pre-check archive, per-input hashes and observed
owned-process teardown before state deletion, local attributed agent-branch
commit, goal-ledger evidence and final native review handoff. Review approval
follows the handoff and is not an inference permission.

M1 remains partial: this fixture does not qualify live inference, provider-call
ceilings, disposable QA credentials, real tool approvals/Stop, live-authoritative
restoration, packaged execution or protected-main delivery. No upstream edits,
system/device installs, release or external publication are authorized here.
Next seam: another accepted M1 recovery gap, or supported live admission contract
re-evaluation only if upstream evidence changes. No follow-up task is enqueued.

Questions: none. Default retained: credential-free synthetic reads only.
