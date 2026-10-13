# Assembled Agent-only client retirement closure

Task: `t_532f359f`. Implementation receipt, pending independent native review.
This does not close CONNECTION-LINK-REMOVAL or authorize service retirement.

## Candidate and scope

Admitted base: `b2076d7e1832a9ecb2f587ca0ca179559e9d3d62`.
Before the first edit, the original `pass_workspace.py` command returned
`worker_start_admitted` with manifest SHA-256
`54d422d45e3648321a61f7106fafd33007fcf63673caa491cf3d0db345235566`.
The exact command and original workspace are in the native run history; this
receipt is not a substitute for that pre-edit evidence.

Owned files are this receipt and
[the retirement contract test](../../test/tooling/enrollment_retirement_contract_test.dart).
No production, storage, service, packaging, localization, upstream, dependency
manifest or lockfile changes. Scope reaches all production Dart callers,
including app, router, shared code and every `lib/main*.dart` entrypoint; sentinel
fixtures are temporary files within the test, not product fixtures or exports.

The source scan at the admitted base found 209 production Dart files: seven in
retained `lib/core/wing_link/`, and 202 outside it. Outside that subtree, the only
`WingLink`, `wingLink` or `wing_link` identifiers are in
[secure endpoint storage](../../lib/core/hermes/setup/secure_hermes_endpoint_store.dart).
They retain historical raw fields and token slots; they do not import, export or
construct the service client. No residual production consumer was found.
Service implementation, standalone service tests, installer and platform delivery
remain deliberately outside this slice.

Decision: extend the existing recursive source-contract helper pattern, not add
an analyzer dependency. The global guard rejects management import/export URIs
(including basename, relative, package and conditional forms), `WingLink` runtime
symbols and `wingLinkClient` builder references. It excludes only the exact
retained subtree, not similarly named feature directories. Secure storage is
scanned identically to every other consumer; it has no file-level exemption.

Synthetic sentinels demonstrate rejection of 12 directive/construction/type/builder
snippets, acceptance of inert raw-record storage, exclusion of the retained
implementation and rejection of a lookalike feature subtree. Path sentinels cover
POSIX, Windows and mixed root/file separators, with exact retained-subtree
exclusion and non-retained/lookalike/storage rejection. These fixtures never
edit production files or access personal Agent/provider state. This is a
conservative textual anti-restoration guard, not a Dart semantic security audit;
renamed or deliberately obfuscated dependencies require source review.

## Review rework

Round-one review of `6f8809e4f8b522cb51709d73491972aa7e112792` found that
the slash-only exclusion incorrectly scanned retained implementation on Windows.
The preserved reviewer probe reproduced this on Linux (exit 1); it is path-shape
simulation, not Windows runtime qualification. The exclusion now normalizes both
root and file separators before the same exact subtree comparison. Storage is
still scanned; no runtime or production change was needed.

Before rework, the task ref still named that reviewed commit and both owned files
matched its blobs. Original admission was read back from session
`20261013_061445_e3f59e`, messages 14926–14927; it was not rerun against edits.
The new separator regression and focused setup suite passed all 70 tests.
Rework found workspace npm dependencies absent and the canonical installation at
Playwright 1.61.1 rather than locked 1.62.1. That installation was not reused;
`timeout 5m npm ci --offline --ignore-scripts` restored the exact workspace lock
from existing cache (three packages, zero audit vulnerabilities). The installed
Chromium executable remained available; no network or system install was needed.
The mandatory frozen finish gate repeats the full named acceptance; its exact
commit, command results and browser replay counts belong to the native handoff.

## Executed acceptance

Host: Linux; Flutter 3.44.2, Dart 3.12.2, Node 26.7.0.
Flutter matches the repository requirement; Node differs from the requested 22.
Chromium uses the already-installed Playwright browser. No package/system install
or host service was needed. Matching dependency manifests/locks and installed npm
lock entries were checked before reuse; local Dart resolution used
`flutter pub get --offline --enforce-lockfile`. All four manifests/locks remained
identical to the admitted base after compilation and browser execution.

| Check | Observed result |
| --- | --- |
| `dart format --output=none --set-exit-if-changed test/tooling/enrollment_retirement_contract_test.dart` | Pass |
| `timeout 5m flutter analyze --no-pub` | Pass, no issues |
| `timeout 15m flutter test --no-pub --concurrency=1 test/tooling/enrollment_retirement_contract_test.dart test/core/hermes/setup` | Pass, 70 tests after review rework (69 originally) |
| `timeout 15m flutter build web --release -t lib/main_e2e.dart` | Pass, JavaScript release build |
| `PORT=18867 HERMES_E2E_PORT=18868 WING_APP_URL=http://127.0.0.1:18867/ timeout 25m npm run web:e2e` | Pass, 47 browser tests; one live-provider test skipped |
| `git diff --check` and changed local document links | Required again by the scoped finish gate; exact result in native handoff |

The final scoped `finish_task.py` gate repeats all acceptance commands against the
frozen owned candidate. Its exact task ref, full commit, check results and elapsed
time belong in the native handoff, avoiding a self-referential commit receipt.

The browser runner was inspected before invocation. It rebuilds the E2E target,
uses one worker and one retry, runs eight named suites in separate processes,
refuses occupied ports and stops its own fixture server on exit. Both fixture
listeners bind only loopback. No browser test required a retry in the initial run.
The live-provider smoke is intentionally skipped without live environment input;
it is not a passing live test. The runner overwrites its JSON report per suite,
so aggregate results come from the complete runner log, not the last JSON file.

Compilation reports existing `flutter_tts` WebAssembly dry-run incompatibilities
and an absent Cupertino font family warning. The requested JavaScript build
succeeds; this is not WebAssembly qualification.

[Secure endpoint regressions](../../test/core/hermes/setup/secure_hermes_endpoint_store_test.dart),
[legacy preservation](../../test/core/hermes/setup/legacy_endpoint_preservation_test.dart)
and [saved edits](../../test/core/hermes/setup/saved_endpoint_edit_store_test.dart)
exercise credential isolation, failed-write preservation, raw-field retention and
owner fencing with deterministic storage fakes. Browser suites exercise direct
entry, unsupported controls, CORS/SSE, approvals/cancel/deny, Stop, session browsing,
reload preferences, diagnostics and responsive controls. These results prove the
existing compiled fixture journeys, not every possible upgrade/reconnect path.

## Remaining gates

Implemented: a repository-wide production consumer denial guard and adversarial
sentinels, with no user data mutation. Qualified: deterministic Chromium on Linux
and focused Dart storage/retirement tests only. Delivered: not integrated or
published by this worker; independent same-card review and coordinator delivery
remain pending.

Native Android/Linux UI, real secure-storage backends, real Agent/provider access,
physical speech/acoustics, WebAssembly and Node 22 are NOT_CHECKED. Browser results
must not be promoted to those claims. Service/packaging removal stays gated by
parent acceptance and the existing owner gates under
[complete removal including legacy](../adr/product.md#complete-removal-including-legacy).
Next slice: CONNECTION-LINK-RETIREMENT after those gates; no service was stopped,
uninstalled or modified here.
