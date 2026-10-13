# Client compatibility authority retirement

Task: `t_ff3851fe`; parent work: CONNECTION-LINK-REMOVAL / CONNECTION-PATHS.
Base: `9b3581557d7929a51165c39290c6c09eb5501fbf`.
Status: offline implementation verified; independent native review pending.
No canonical integration or publication is claimed by this receipt.

## Change and scope

Deleted the unused `lib/core/hermes/hermes_domain_authority.dart` and its enabled
client profile-compatibility flag. A pre-edit Dart source search found only the
flag declaration and its source-contract test, with no production import or
caller. No replacement authority, fallback, dependency or configuration was added.

The domain source guard now separates Agent-only public Profiles/provider/directory
controls from the still-retained Link client/service safety contract. It preserves
Agent create/rename/delete assertions, no Link construction or profile-loader
fallback, pending credential verification and bounded service compatibility checks.
The enrollment guard scans all production Dart sources for the retired file,
imports/references and flag. Its hermetic test injects each violation independently
and checks an empty tree after removal. Existing retirement assertions remain.

Only the deleted file, the two tooling guards and this receipt are owned. Stored
Agent credentials, legacy records, service/client implementation, localization,
packaging and upstream sources are unchanged.

Decision: delete dormant authorization rather than replace it; the absence of
production callers and the [complete-removal decision](../adr/product.md#complete-removal-including-legacy)
justify deletion. Keep service safety assertions until service retirement.

## Admission and acceptance evidence

The original pre-edit admission ran successfully before the first test edit:

```text
python3 /home/xel/git/gormes/hermes-toolset/skills/autowork/scripts/pass_workspace.py --manifest /home/xel/.hermes/profiles/wing/autowork/pass-c1afb91cfb59c065-df60c2acb01447db908ed7179d891cfa.json --manifest-sha256 fe830ce359bb0e853263969e50a766369ffe0b60b34e23ce76998292157f031f --workspace /home/xel/.hermes/cache/scratch/autowork-passes/c1afb91cfb59c065-df60c2acb01447db908ed7179d891cfa
```

Result: exit 0, `worker_start_admitted`. Original tool history is the evidence of
ordering; this receipt is not a substitute for that history.

Executed on Linux Flutter VM with deterministic fixtures:

- `flutter pub get --offline`: pass; `git diff --exit-code -- pubspec.yaml pubspec.lock`: pass, manifests unchanged.
- `dart format test/tooling/hermes_domain_authority_contract_test.dart test/tooling/enrollment_retirement_contract_test.dart`: pass, no formatting changes.
- Before deleting the production file, `flutter test --no-pub --concurrency=1 --reporter expanded test/tooling/enrollment_retirement_contract_test.dart`: expected red, exactly the new production guard failed on `lib/core/hermes/hermes_domain_authority.dart`; the injected file/import/flag test passed.
- After deletion, `flutter analyze --no-pub`: pass, no issues (6.2 seconds).
- `flutter test --no-pub --concurrency=1 --reporter expanded test/tooling/hermes_domain_authority_contract_test.dart test/tooling/enrollment_retirement_contract_test.dart test/features/profiles test/features/gateway test/features/hermes_chat/gateways test/core/hermes/setup`: pass, 429 tests (1 minute 3 seconds reported by the runner).
- `git diff --check`: pass.

The mandatory `finish_task.py` gate reruns the acceptance argv and publishes only
these four owned paths to `agent/wing/t_ff3851fe`; its exact commit/check receipt
belongs in the native review handoff. The workspace HEAD remains the admitted base.

## Remaining milestone gaps

CONNECTION-LINK-REMOVAL and CONNECTION-LINK-RETIREMENT remain open/in progress.
This removes one dormant client artifact, not the retained Link runtime,
credential APIs, remaining consumers, localization or delivery dependencies.
The next bounded consumer/runtime/localization slice needs its own evidence.

Native/device/provider journeys, Android SSH, Remote server and on-phone Termux,
packaged execution, browser E2E and service removal are NOT_CHECKED here. Their
accepted ordering (Android SSH first, Remote server second, on-phone Termux third)
is unchanged. No live runtime, device qualification or delivery claim follows
from these fixture/source-contract tests. Review, canonical integration and remote
publication remain separate gates owned by the coordinator.
