# Live Linux daily workflow: read-only qualification entry

> Reference correction: [official Desktop authority](official-desktop-reference.md). Prior Desktop source citations and parity conclusions in this document are withdrawn. Wing test results remain historical behavior evidence only.


Status: implemented read-only first slice for `t_a8a79cf5`. Actual-Agent/native
workflow qualification and protected-main delivery remain **NOT_CHECKED**.
`PARITY-LIVE-WORKFLOW` / M1 remain open. This is not a generation harness yet.

The integration target now also contains a prepared two-phase production Chat
driver: exact selection, explicit provider/model reselection, one send per phase,
correlated one-time approval, Stop and canonical run/history readbacks. It uses
the production gateway cache for restoration and checks distinct native process
IDs and hashed history/owner continuity. That branch is disabled before network
access by `requireQualifiedLiveBudget`, even when invoked directly rather than
through the launcher. It has been analyzed, not executed or qualified.

Six Dart regressions prove the transport mutation-attempt guard: no startup or
restoration writes, one model lock/send per phase, exact run/request approval and
Stop identities, denial of batch/permanent approvals, no retry after ambiguous
dispatch, and fail-closed direct native invocation. These limits are explicitly
not an inference ceiling. The supported provider-call limit and actual two-process
launch orchestration were the next slice at this receipt's source snapshot;
credentials alone cannot enable the driver. The later
[two-process receipt](live-two-process-orchestration.md) qualifies synthetic
lifecycle control, and the [display branch](live-display-isolation.md) qualifies
real X protocol authorization. That display implementation is branch-only, not
present in the shared helper. Neither receipt qualifies GTK/live Chat or the
provider-call ceiling. The later [provider-call assessment](live-provider-call-ceiling.md)
finds no supported three-physical-attempt limit in the inspected Agent interfaces.
Its branch tests qualify refusal only. The earlier uncertainty below remains the
historical scope of this preparation slice, not the current assessment result.

## Delivered behavior

Run `scripts/run_linux_desktop_live_workflow.sh` without input to receive a
sanitized JSON refusal and exit 2 before any network, snapshot, native process,
Agent mutation or inference. No credential discovery, runtime provisioning,
shared gateway restart, provider substitution or upstream patch is performed.

The entry accepts a single bounded JSON authorization document on stdin, never
secrets in arguments or an ordinary preference file. Required fields are:

- `schema`: integer 1; `mode`: `read-only` (live mode always refuses).
- `approved_disposable` and `approved_reads`: explicit booleans true supplied by
  the owner for the disposable QA target, not inferred from network location.
- `expires_at`: Unix seconds, future and at most five minutes away.
- `origin`: exact HTTP loopback `/p/<profile>` base with an explicit port;
  `profile` and `session`: explicit bounded identities.
- `provider`: `openai-codex`; `model`: `gpt-6.1-sol`.
- `api_key`: separately approved QA Agent bearer credential acquired through a
  secret-safe flow. Do not send it in chat, commit it, put it in shell history,
  or reuse a personal/management/provider credential.
- `generation_limit`: integer 3; `generations_used`: integer 0 through 2.

The last two fields validate the accepted usage declaration, not a trustworthy
persistent provider-call meter. Consequently **all live mode is refused**, even
with valid inputs: limiting three submissions alone would not bound approval/tool
continuations. There is no claim that Agent lacks a usable limiting contract;
that contract and its runtime effect have not been qualified in this slice.
Do not loosen this refusal merely because authentication becomes available.

With approved read-only inputs, the Python entry sends only one authenticated
`GET /p/<profile>/v1/capabilities`, without proxies or redirects. It bounds the
response, rejects unauthenticated/unknown schemas and requires exact methods,
paths, feature flags, declared scopes and supported profile context for session,
model, run, approval and Stop operations. Errors emit only fixed codes, never
credentials, endpoints, body contents, host paths or exception text. A passing
preflight is neither an inference test nor an approval/Stop qualification.

`--native-read-only` additionally prepares an attributed source snapshot, copies
an independent SDK, uses isolated HOME/XDG directories and an owned Xvfb display,
and runs the new integration target through production `HermesApiClient` and
`HermesTransportPolicy`. Every client mutation seam is explicitly denied. The
target reads capabilities, exact session metadata, bounded history and the
configured exact provider/model catalog; it never creates, selects or locks a
session, mounts Chat or generates. It is intentionally separate from the
predecessor's synthetic daily-workflow target. Native output is discarded to
avoid retaining backend error bodies or private input values. The receipt records
the driver process identity and verified owned-group teardown, not an actual
GTK app identity or a two-process relaunch. `read_requests_attempted` counts only
the Python preflight; native read totals are not currently instrumented.

The native target is prepared and analyzed, **not executed** in this run. Native
GTK development prerequisites and cached Go dependencies are required. No package
installation or dependency download occurs in the launcher; Go is offline and
bounded to two workers. Missing prerequisites yield a redacted failure, not a
passing desktop claim. Owned SDK/app/state copies are removed after the child
group is terminated and reaped, including timeout/descendant cleanup paths.

## Attribution and contract trace

The immutable verification source was committed Wing revision
`b9eb5b3d9f6f3a433dd36cb6271ad8ec769b2319`, plus only this card's five new
executable/test files. There were 588 frozen input files and 70 excluded dirty
tracked inputs with recorded SHA-256 hashes. All other owner changes, upstream
clones, vendor, personal runtime state and earlier synthetic fixture edits were
excluded. No predecessor code was changed or copied as an unattributed overlay.
Predecessor `t_d6467f03` / `7cf7f8b4d2c64744beb36488b780a78db3caebb4` is
reference evidence only; its synthetic outcomes are not carried forward as live
proof. Snapshot manifest binds every input to its exact hash.

Reference locations were confirmed read-only:

- Agent `hermes-agent/`, revision `158fd638da1629c8e62caf9ade1515d162def8ab`:
  `gateway/platforms/api_server.py:67-102,2537-2575` supplies capability contracts;
  `hermes_cli/config_defaults.py:3151-3165` describes API bearer bootstrap.
  `hermes_cli/auth_codex_browser.py` identifies the supported Codex browser auth
  flow; it was not invoked and no auth store was inspected.
  Nearest read-only tests: `tests/gateway/test_api_server.py:933-972` and
  `tests/gateway/test_api_server_runs.py` approval/Stop/model cases. These upstream
  tests were inspected, not executed or edited.
- Desktop `withdrawn source citation`, revision
  `withdrawn reference revision`:
  `src/shared/model-override.ts:1-17` and nearest session-model override tests
  describe complete session routing identity, not permission to duplicate its
  privileged persistence in Wing. Both clones' AGENTS.md were read first.
- Wing `lib/core/hermes/client/hermes_api_config.dart`,
  `hermes_api_client.dart`, `policy/hermes_transport_policy.dart` and nearest
  `test/core/hermes/hermes_api_test.dart` establish the production read/policy
  seam. The channel's `clientBuilder` injection and existing Chat/native fixture
  remain the future workflow seam; this first slice introduces no backend.
- Native dependency closure includes committed Wing Link source because
  `linux/CMakeLists.txt:60-84` bundles it. Package configuration, graph and plugin
  references are relocated to the copied SDK; unrelated local dependencies are
  rejected. No packaging manifest was changed. Native build/service execution
  remains NOT_CHECKED.

## Executed checks and evidence

Executed on Linux x86_64, Python 3.12.14, Flutter 3.44.2 / Dart 3.12.2. Flutter
revision `c9a6c484230f8b5e408ec57be1ef71dee1e77020`, engine
`77e2e94772b6eb43759e34ed1ad7da4674e19cab`. Dependency lock SHA-256:
`9ec3db9492cbace9de690033eead7b4fe162f2f485544813a3166b58e9ac9e85`.
The copied SDK and frozen source were used for these checks:

| Command | Result | Final duration |
| --- | --- | --- |
| `python3 -B -m unittest discover -s test/tooling -p desktop_live_workflow_test.py` | 10 passed, exit 0 | 1.059 s |
| `bash -n scripts/run_linux_desktop_live_workflow.sh` | exit 0 | 0.001 s |
| `dart format --output=none --set-exit-if-changed integration_test/linux_desktop_live_workflow_test.dart test/tooling/desktop_live_workflow_budget_test.dart` | unchanged, exit 0 | 0.045 s |
| `flutter analyze --no-pub` | no issues, exit 0 | 17.688 s |
| `flutter test --no-pub --concurrency=1 test/core/hermes/hermes_api_test.dart` | 98 passed, exit 0 | 7.822 s |
| `flutter test --no-pub --concurrency=1 test/tooling/desktop_live_workflow_budget_test.dart` | 6 passed, exit 0 | 6.332 s |
| `bash scripts/run_linux_desktop_live_workflow.sh < /dev/null` | expected exit 2; zero reads/mutations/inference | receipt |
| `git diff --check` | exit 0 | recorded separately |

The first analyzer attempt found two unnecessary null assertions in the new
Dart target. They were removed; subsequent analyzer checks passed. That failed
attempt is retained, not presented as a pass. No full integration-suite replay.
An additional analyzer attempt on the prepared driver reported an unnecessary
import and missing control-flow braces; both were repaired. Its log/checks remain
in `attempt-2-*`, and the final frozen-source checks above passed.
The canonical non-`-B` Python discovery command is also recorded separately.

Deterministic regressions exercise the actual launcher against a test-owned
loopback server: valid read-only capability discovery, unsupported operation,
redirect rejection, invalid auth/approval, exhausted budget and no-input refusal.
They assert GET-only traffic, zero mutation, redaction, bounded identity/config,
snapshot exclusion and real process-group timeout/descendant cleanup. The server
is explicitly synthetic; these passes are **not live-provider proof**.

Ignored compact evidence: `build/live-workflow-evidence/` contains exact commands,
exits, durations, source manifest, SDK/environment identities, refusal and checks.
All frozen source input hashes stayed unchanged during checks. The large copied
SDK/source/build directories were removed. Actual provider inference count: 0.
Billing cost and review duration: unknown; no paid action was attempted.

## Acceptance and remaining work

### Round-1 cleanup correction

The first review reproduced a preparation cancellation leak: SIGTERM during SDK
copy bypassed teardown, leaving an owned copy process and temporary directory.
The original ten-test results above did not cover that path.

Cancellation protection now surrounds source snapshot, SDK/package preparation,
execution and temporary-state cleanup. Nested helpers keep the same protection;
repeated SIGINT/SIGTERM cannot interrupt teardown. Every preparation subprocess
runs in its own process group with a deadline: Git metadata reads 30 seconds,
source archive 60 seconds, SDK copy 120 seconds. Launch-time cancellation is
deferred until the child identity is available without inheriting a blocked
signal mask. Groups receive TERM then KILL if necessary, and the direct child is
reaped before deleting source/SDK/state. Cancellation returns fixed
`NATIVE_CANCELLED`, exit 2; ordinary preparation failures remain redacted.

Rework executed from an immutable snapshot of the same base revision plus this
card's five owned executable/test overlays, with 588 hashed inputs and 70 excluded
dirty tracked hashes. All input hashes were unchanged after checks:

- `python3 -B -m unittest discover -s test/tooling -p desktop_live_workflow_test.py`:
  14 passed, exit 0 (5.790 seconds including process startup).
- `bash -n scripts/run_linux_desktop_live_workflow.sh`: exit 0.
- `bash scripts/run_linux_desktop_live_workflow.sh < /dev/null`: expected exit 2,
  zero reads, mutations and inference.
- `git diff --check`: exit 0 in the working repository.

New real-entry regressions use a test-owned source repository, synthetic
capability server and fake SDK/tools. They signal only the launcher during
source archive and SDK copy, verify no live descendants or owned state remain,
exercise repeated cancellation and TERM-resistant children, and prove successful
preparation cleanup. A separate regression checks spawn failure propagation and
restored signal handlers. A fake tool's success receipt in this test proves only
launcher control flow, never native Flutter or actual-Agent readiness.

Only the Python helper, Python regressions and this runbook changed in rework.
Dart/native driver bytes remain unchanged from the preceding reviewed revision;
Flutter format/analyzer/tests were not rerun for this Python-only correction.
Compact evidence is in `build/live-workflow-review-rework/`; the frozen source and
test-owned SDK/state copies were removed. No real Agent authentication, native
desktop execution or inference occurred. Live mode is still unconditionally
denied and `PARITY-LIVE-WORKFLOW` remains in_progress.

1. Implemented/exercised: real entry refuses absent/invalid/unapproved/exhausted
   inputs before network or mutation; unsupported exact operations refuse before
   mutation; deterministic redaction/isolation/teardown checks pass.
2. NOT_CHECKED; the prepared driver remains disabled, not runnable end-to-end: actual authenticated Chat,
   generation/correlated approval/authoritative Stop, two real native processes,
   exact-session restoration/explicit reselection/one intentional resumed send,
   canonical operation counts and provider-call-budget qualification.
3. Implemented: attributed local commit and truthful evidence; native review
   entry is recorded by the card transition, not implied by this document.
   Native review approval, protected PR and merged-main delivery are distinct.

Next slice: qualify a supported provider-call limit including continuations,
then enable and exercise the prepared production driver through an isolated
two-process launcher, with canonical readback and native app identities.
No automatically persisted pair or invented approval/Stop API is authorized.
The umbrella `PARITY-LIVE-WORKFLOW` stays in_progress; only the read-only preflight
subtask is marked done. M1 is not met by this receipt.

Questions (no reply = defaults apply): see `BLK-20261007-W04` in
[BLOCKERS.md](../../BLOCKERS.md). Default: no inference and no personal credential
access. Provide separately approved disposable QA authentication only through a
secret-safe flow, never through chat or ordinary logs.
