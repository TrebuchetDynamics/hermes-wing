# Live daily-workflow retry: admission remains closed

Task: `PARITY-LIVE-WORKFLOW` / M1. This retry revalidated the assigned branch at
`9fcbe4e86da9079a83ef07c2a8e6e3097827eebf`. The native driver, authenticated
display isolation and two-process orchestration are present, but live inference
remains unconditionally disabled. No production Agent, QA credential, native
GTK journey or provider was accessed in this retry.

## Offline checks

Commands executed in this worktree:

| Command | Result |
| --- | --- |
| `python3 -B -m unittest discover -s test/tooling -p desktop_live_workflow_test.py` | Pass: 23 tests |
| `bash -n scripts/run_linux_desktop_live_workflow.sh` | Pass |
| `bash scripts/run_linux_desktop_live_workflow.sh < /dev/null` | Expected refusal (exit 2): `AUTHORIZATION_REQUIRED_NO_NETWORK`; zero reads, mutations and inference |
| `flutter pub get --offline` | Pass using local cache; no online dependency resolution |
| `flutter test --no-pub --concurrency=1 test/tooling/desktop_live_workflow_budget_test.dart` | Pass: 6 tests, including direct-invocation ceiling refusal |
| `dart format --output=none --set-exit-if-changed integration_test/linux_desktop_live_workflow_test.dart` | Pass: unchanged |
| `git diff --check` | Pass |

The first Dart test invocation lacked `.dart_tool` resolution metadata. The
cache-only `flutter pub get --offline` completed, and the final focused test run
passed; no source or lockfile change was needed.

## Remaining live acceptance

The exact unresolved admission gap is unchanged: the inspected unmodified Agent
interfaces do not authoritatively cap physical provider attempts across transport
retries, continuations and auxiliary work. Submission counters and the Wing
mutation budget are not such a ceiling. The driver's unconditional
`LIVE_INFERENCE_BOUND_NOT_QUALIFIED` guard must not be relaxed on this evidence.

Still pending are supported Agent-side call admission, separately approved
disposable QA authentication and grants, and the owner-selected disposable
target/prerequisites. Until those independent gates exist, do not run the
production two-phase journey or claim real generation, correlated approval, Stop,
relaunch restoration or canonical Agent readback. The prior receipts
[live provider-call ceiling](live-provider-call-ceiling.md),
[two-process orchestration](live-two-process-orchestration.md), and
[display isolation](live-display-isolation.md) remain authoritative for their
respective offline scopes; this retry does not repeat or upgrade their claims.
M1 remains partial and canonical-main integration/delivery remains separate.
