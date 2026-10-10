# Live provider-call ceiling: unsupported, admission closed

Card `t_eb176d28`; M1 slice `PARITY-LIVE-PROVIDER-CEILING`.
Result: the inspected unmodified Agent interfaces do not establish an enforceable
maximum of three physical provider attempts across the two-phase QA workflow.
This is an implemented executable refusal qualification, NOT provider/inference
qualification. No API/config/runtime changes or provider requests were performed.

## Attribution and environment

Detached candidate `build/t_eb176d28/candidate` starts at reviewed display commit
`19e59ea10f3424c3973b317cdabdaf3a77269292`. Only this new document and additive
budget regressions in `test/tooling/desktop_live_workflow_test.py` belong to this
card. Production helper, launcher, native driver, and Dart budget tests are
unchanged predecessor work; their attribution is preserved. No shared dirty bytes
were copied. Local commit branch: `agent/wing/t_eb176d28`; exact SHA is in the
native board handoff. No main commit, push, merge, or release.

Initial isolation receipt `build/t_eb176d28/isolation.json` captures the dirty
working/untracked file hashes (including all five prepared workflow inputs), base,
and claim lock `BlueBlack:2419558`, run 1051. These are hashes of working bytes,
not a claim that the heavily staged shared checkout is clean. Tests run only in
the candidate. Shared goal/TODO updates use goals.py, not candidate source copies.

Named environment: Linux 7.0.0-31-generic, x86_64, glibc 2.39; Python 3.12.14;
Flutter 3.44.2 framework c9a6c48423, Dart 3.12.2. The existing tests also launch
owned Xvfb for predecessor display checks. Flutter's VM unit test executes the
native driver's guard; it does not launch the GTK application.

Agent evidence, read-only:

- Reference `hermes-agent/`: `158fd638da1629c8e62caf9ade1515d162def8ab`,
  describe `v0.21.4+canary.20261003T070620Z-494-g158fd638da`.
- Installed launcher resolves to `.hermes/hermes-agent/.hermes/bin/hermes`, whose
  source root is the installed Agent checkout. Installed source:
  `bc2e4d3773518f2129023383a29dc51133dc6048`, describe
  `v0.21.4+canary.20261007T070234Z-496-gbc2e4d3773`.
- These are inspected checkout identities, NOT running-gateway identity or
  freshness evidence. Hermes was not launched (the generated launcher has repair
  behavior); no personal configuration, credentials or session state were read.
- `build/t_eb176d28/source-evidence.json` records exact SHA-256 fingerprints for
  17 relevant implementation/test inputs in both checkouts. Scoped Git status
  for those inputs is empty in both; different files were traced separately.
  Root/area Agent instructions and Desktop root instructions were read first.

## Contract trace: why submissions and iterations are insufficient

Line references below use the reference checkout unless marked installed. Closest
upstream tests were inspected, not run and not modified. They are source evidence;
no fake completion is presented as actual provider qualification.

| Path | Counted or constrained | Uncovered provider closure |
| --- | --- | --- |
| `gateway/platforms/api_server_runs.py:650-719,961-967` | `/v1/runs` admits a run, applies ownership/idempotency/concurrency, constructs an Agent and starts its worker | Admission is not a durable physical-call reservation; concurrency/idempotency is not a subscription/test-use quota |
| `gateway/platforms/api_server.py:360-382,2406-2439` (installed `2379-2412`) | Request overrides are model/provider/options; max iterations comes from profile runtime config, or hosted-room iteration policy | No qualified aggregate physical-attempt counter spanning these two QA phases |
| `gateway/run.py:1615-1632` (installed `1608`) and `hermes_cli/_parser.py:290-298` | `agent.max_turns` / CLI `--max-turns` limits per-turn tool-calling iterations; `--run-budget` limits wall-clock behavior | Neither specifies three physical attempts across retries, auxiliary work and later turns; runtime config mutation is outside this card |
| `agent/turn_iteration_prep.py:383-397` (installed `402-416`) and `agent/conversation_loop.py:1501-1530,1636-1654` | Consume one iteration before an inner API retry loop | Multiple transport attempts occur inside one iteration; main-loop api_calls is not a physical provider-attempt receipt |
| `agent/turn_api_error.py:356-389` (installed `363-396`) | Configurable retry count, primary transport recovery, fallback and auto-recovery | Recovery may reset retry state; exact-model lock disables configured fallback model at construction but is not an aggregate quota |
| Installed `agent/codex_runtime.py:1303-1351` | Codex streams have their own physical attempt/reconnect loop | A failed zero-event attempt can be reissued without a new Wing submit or outer iteration |
| `gateway/platforms/api_server_runs.py:1168-1216` and `agent/turn_tool_round.py:192-210` | Approval resolves a pending request; tools then return to the Agent loop; execute_code-only iterations refund IterationBudget | Once-approval is tool permission, not a call reservation; tool continuations may call providers again without another client mutation |
| `agent/iteration_budget.py:25-56` and `agent/turn_context.py:644` (installed `645`) | In-process consume/refund; a new budget is assigned each turn | Not a persistent workflow quota; resumed app/process or next request starts independent accounting |
| `agent/turn_truncation.py:575,634-635` and `agent/turn_iteration_prep.py:389-393` | Reasoning-only recovery permits a toolless grace call | An iteration ceiling of three can still permit a fourth logical call |
| `agent/auxiliary_hooks.py:1-10`, `agent/AGENTS.md:98-104`, `agent/title_generator.py` | Separate auxiliary funnels for title/compression/vision/approval/etc.; observer events include retries/fallbacks | Auxiliary hooks are observer-only and fail-open, not a veto/quota seam; main iteration/submission counters do not cover these calls |
| `gateway/platforms/api_server_runs.py:950-959,987-999` and installed `agent/codex_runtime.py:1304-1307` | Cancellation/Stop checks can prevent future work or interrupt a worker | A client Stop cannot undo an already admitted physical attempt or prove no raced auxiliary work; never refund unknown outcomes |

Other tool/provider/plugin-specific remote work, auxiliary SDK behavior, delegated
children and third-party provider billing semantics are not comprehensively
qualified. No closed set of physical attempts has been demonstrated. Disabling a
few paths, polling metrics after calls, or estimating from prompts/token limits
cannot supply the missing authoritative atomic admission contract.

Closest inspected upstream tests:

- `tests/agent/test_iteration_budget_race.py:53-73`: exhaustion/refund behavior,
  not a physical-call quota.
- `tests/agent/test_codex_reasoning_only_streak.py:51-70`: three budgeted calls
  plus one grace call (four), explicitly disproving a simple iteration ceiling.
- `tests/agent/test_api_max_retries_config.py:34-40`: retry configuration reaches
  Agent, not aggregate workflow enforcement.
- `tests/agent/test_codex_request_transport_diagnostics.py:101-143`: one Codex
  stream invocation can perform two attempts after a zero-event transport failure.
- `tests/agent/test_auxiliary_hooks.py:43-72`: auxiliary events are distinct from
  main-call events; a raising observer does not prevent the auxiliary request.

## Wing boundary and executable regression

Production `lib/core/hermes/client/hermes_api_client.dart:455-467,508-520`
submits a session-owned run, responds to approval and stops a run directly against
Agent. It neither exposes nor implements a provider-call quota. Wing Link is not
involved. No new transport, proxy, plugin, budget setting or shadow Agent state
was introduced.

The unchanged Python `authorize()` retains
`LIVE_INFERENCE_BOUND_NOT_QUALIFIED` for otherwise valid live authorizations;
exhausted or invalid declaration counters retain `USAGE_EXHAUSTED_OR_INVALID`.
The unchanged Dart `requireQualifiedLiveBudget()` always throws before reading
`WING_LIVE_AUTH` in the prepared journey. MutationBudget counts client attempts,
not physical provider calls, and is not promoted to a billing control.

New actual-logic regressions:

1. Remaining declarations 0/1/2 and exhausted 3, repeated attempts, both public
   entry modes: exact refusal and zero operations, with network/native/prepared
   launch seams asserted untouched. Remaining sends do not authorize retries or
   continuation work because the run is never admitted.
2. Independent Python interpreters in write/verify phases, including resetting
   the verify declaration to zero: same exact refusal and zero operations. Socket
   connect, capability reads and native/prepared launch seams are trapped to fail
   if reached. No fixture server is contacted by these new tests.

Existing Dart regression executes the actual unconditional direct-invocation
guard and proves mutation-budget exhaustion/ambiguous dispatch does not refund a
slot; six focused VM tests passed unchanged. This does not qualify the native UI,
actual provider continuations, or a backend quota.

## Executed acceptance evidence

Commands ran in the detached candidate with bounded subprocess deadlines (Python
checks 120 seconds, Flutter checks 180 seconds); single-worker Flutter test.

| Exact command | Exit | Wall seconds | Observed result |
| --- | --- | --- | --- |
| `python3 -B -m unittest discover -s test/tooling -p desktop_live_workflow_test.py` | 0 | 49.169 | 31 tests OK (unittest 49.090 s) |
| `bash -n scripts/run_linux_desktop_live_workflow.sh` | 0 | 0.002 | syntax pass |
| `bash scripts/run_linux_desktop_live_workflow.sh < /dev/null` | 2 | 0.042 | expected AUTHORIZATION_REQUIRED_NO_NETWORK; zero reads/mutations/inference |
| `git diff --check` | 0 | 0.058 | attributed Python whitespace pass; repeated after adding this document |
| `flutter pub get --offline` | 0 | 3.253 | cache-only dependency setup; lock unchanged |
| `flutter test --no-pub --concurrency=1 test/tooling/desktop_live_workflow_budget_test.dart` | 0 | 21.797 | six tests pass; actual Dart guard executed |

Initial cheap checks each selected one new Python test and passed (0.001 s and
0.395 s unittest time). No failing code iterations. An initial read-only isolation
probe queried a nonexistent board events table and failed; lock was then taken
from native kanban_show, not guessed from a database schema.

Final executed inputs, SHA-256 (identical before/after Python checks; unchanged
Dart and lock also verified after offline package setup):

| Input | SHA-256 |
| --- | --- |
| Python tests | `ba222cb5ad160d4b4de57b8d091be7bcc7dd28f9caf12804778ebe6352abb81d` |
| Python helper (unchanged) | `295299f3d23505ff115ceb03fbfac3d552889c2c3dd3eb775c4de8108d39dec6` |
| Launcher (unchanged) | `ec6f4941b9e01264d9710d8a898f4c6ddf928d45658cfbb7fd94934c1e750794` |
| Dart native driver (unchanged) | `e60cf55d6d7ff13ec08948f6553e2ccc00257da4596d9f7f38203aeb8bcdbc35` |
| Dart budget tests (unchanged) | `b0ceb32a4b35df95ff08581e9ab41fb640865a5ccfe013f96e2f8f3dc8cf0a53` |
| pubspec.lock (unchanged) | `9ec3db9492cbace9de690033eead7b4fe162f2f485544813a3166b58e9ac9e85` |

Compact receipts: `build/t_eb176d28/verification.json`, `dart-verification.json`,
`source-evidence.json`, `isolation.json`. Source-run Python imports only stdlib;
launcher resolves the local support module. No packaging/dependency edits, and no
need to repeat unrelated complete gates. Formatter/analyzer NOT_RUN: no Dart
changes. Packaging/image/native GTK execution, provider usage receipts and actual
billing cost: NOT_CHECKED/unknown. No provider spending authorized or performed.

Acceptance mapping: (1) source-backed unsupported closure above; live gate stays
closed, not claimed qualified; (2) two new behavioral regressions plus actual
unchanged Dart guard tests, no-input refusal and zero operations; (3) attributed
local commit, goals.py narrow-slice executed evidence and final native same-card
review handoff are recorded in board metadata. Review approval follows handoff.

## Remaining M1 gaps and next useful independent seam

M1 stays partial and `PARITY-LIVE-WORKFLOW` stays in_progress. Real generation,
tool approval/continuation, Stop, exact live session/history restoration and model
reselection, supported three-physical-call enforcement, approved disposable QA
authentication, and protected-main integration remain unqualified. Do not enable
inference by interpreting these offline passes as authorization or provider proof.

An eligible future budget contract must reserve physical attempts atomically at
Agent authority before provider I/O, cover retries/reconnects/continuations,
auxiliary/delegated work, preserve exhaustion across both phases and restarts,
and expose a secret-free authoritative receipt. Evaluate only supported unmodified
releases; do not patch Agent, invent an API, or add a proxy to supply it.

Next independent M1 seam: credential-free actual GTK launch/teardown and
restoration smoke over the prepared native shell with all mutation transports
unsupported; this can qualify native process/UI behavior without solving or
bypassing inference admission. No new task was enqueued by this card.

Questions: none added. Existing BLK-20261007-W04 is unchanged. Default retained:
no personal credential access, runtime mutation, provider network or inference.
