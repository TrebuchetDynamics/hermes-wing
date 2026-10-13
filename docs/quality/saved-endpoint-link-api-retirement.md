# Saved endpoint Agent-only contract receipt

Native card: t_d7b814f9. Parent CONNECTION-LINK-REMOVAL remains in_progress;
CONNECTION-PATHS is not closed. Candidate base:
a3b24c9e3f8110513660acb656974a6f0dedb046.
Implementation is offline and bounded; exact task commit/branch and the
finish_task.py receipt are attached to the native review handoff, not invented here.

## Original admission

Before the first test or production edit, the original guard ran:

`python3 /home/xel/git/gormes/hermes-toolset/skills/autowork/scripts/pass_workspace.py --manifest /home/xel/.hermes/profiles/wing/autowork/pass-8baaf8f945a03a58-e3a909ebc710458182f2d7b7035c8510.json --manifest-sha256 cffee4663a226fcde1f264cf20fea2da1ea375edae86c29aed69d4b6c428a89b --workspace /home/xel/.hermes/profiles/wing/cache/scratch/autowork-passes/8baaf8f945a03a58-e3a909ebc710458182f2d7b7035c8510`

Result: exit 0, worker_start_admitted. The original tool history is the
ordering authority; this receipt is not retrospective admission. No manifest
repinning or post-edit admission replay. Initial workspace was clean, detached at
the admitted base. No canonical, upstream, runtime or personal credential edits.

## Decision and delivered contract

Decision: remove all five Link fields from HermesEndpointConfig and all public
store save parameters. Preserve their old raw values only inside the existing
storage implementation, bound to saved row ID and canonical Agent endpoint.
Evidence: existing bundle/preferences serialization and rename/edit callers.
Reason: passive data preservation needs no public management authority, new
storage format, network recovery, dependency or migration service.

- Passive load reads Agent credentials only, never separate Link token slots.
- Same-owner save/saveAll/rename/edit/restart preserve historical secure bundle
  fields and existing non-secret preferences metadata. Legacy Link token slots
  remain untouched for retained row IDs; bytes are never read/copied by production.
- Secure bundle write remains the single authoritative commit. A failed write or
  unreadable raw JSON leaves previous bundle/preferences/token bytes intact.
- Explicit set replacement/deletion removes only omitted rows' old token slots.
  Existing Agent rollback-slot cleanup is unchanged; Agent keys survive migration
  in the authoritative secure bundle. No management fallback can consume old data.
- Agent origin changes do not implicitly forward an old Agent key. Same-origin
  edits preserve it; explicit new credentials and explicit clearing retain their
  existing semantics. Changed identity drops in-bundle legacy trust fields;
  retained separate token slots remain inert, not transferred operationally.
- All direct callers and fakes, including native fixture consumers found during
  full analysis, use the Agent-only contract. No changes to lib/core/wing_link,
  service/security tests, installers, packaging or localization.

## Acceptance map and replaced assertions

| Acceptance | Artifact / executed evidence |
| --- | --- |
| Agent-only public model/save contract; no management restoration | hermes_endpoint_store.dart; exact caller/fake signature migrations; analyzer; enrollment_retirement_contract_test positive scan and negative restored-field/client/import cases |
| Previously saved Agent ID/origin/key survive upgrade, saveAll and restart | legacy_endpoint_preservation_test: separate secure-bundle and legacy-preferences roundtrips; raw field comparisons and same-owner restart |
| Raw fields/metadata/token slots survive rename/edit without access exposure | same test: actual SecureHermesEndpointStore through HermesGatewayDirectory startup/reconnect/rename/edit; raw maps and preferences inspected, unrelated row compared exactly |
| Failed authoritative save preserves old access and bytes | injected secure write failure for both storage generations; directory rejected rename retains its old config; existing legacy single-endpoint failed-commit regression |
| No passive Link credential reads or client construction/network recovery | observed storage throws on token-slot reads; HttpOverrides throws on network clients during raw-backed directory journey; missing Agent credential remains null despite raw Link token |
| Explicit deletion is scoped; credentials remain secure | raw deletion leaves unrelated row unchanged; old Agent credential placement/deletion regressions; raw bundle secrets never projected to preferences |
| Origin changes cannot forward Agent credentials | changed-origin store and directory regressions; same-origin edited credential preservation retained |
| Cancel/reconnect, exact-session restoration, owner fencing, no replay | complete setup/gateway directories, affected screen/profile/editor fixtures; production browser matrix delayed-owner/rejected-auth and negative management controls |
| Consumers compile without new Link APIs | full flutter analyze --no-pub, including native integration sources |

No removed legacy assertion is counted as a waived security property:

- secure_hermes_endpoint_store_test's public Link token/identity roundtrip moves
  to raw secure/preference/slot assertions in legacy_endpoint_preservation_test.
  The pending-ID clearing setter is retired, not emulated; preservation now proves
  ordinary Agent saves cannot mutate it. Link origin normalization on load is
  retired: Agent-only load leaves the raw secure origin untouched.
- saved_endpoint_edit_store_test's public trust getters move to same-owner raw
  preservation and changed-origin raw absence tests. Agent identity/collision and
  unrelated-row expectations remain.
- Gateway directory/UI and Profiles Link-field getter expectations move to the
  raw-backed directory regression. Their existing Agent access, mutation-count,
  session-owner and non-recovery assertions remain; public exposure is prohibited
  by the API guard rather than simulated with a fake management field.
- Welcome/direct/native fixture null-Link-getter expectations become structural
  public API absence. Their Agent credential/origin, cancellation and no-mutation
  checks remain. Maestro clipboard scanning now checks the Agent credential.
- Android/Linux keyring source tests seed historical secure JSON and verify raw
  Link-token digests instead of reintroducing public setters/getters. Boolean
  assertions avoid printing generated secrets. These sources compile but were
  not run on hardware/keyrings in this card.
- Two old provider/settings grouping tests were already failing at the admitted
  base. Their obsolete grouped-host expectations now assert independent Agent
  rows, visible independent controls, and deletion of the chosen row only. This
  matches existing production host projection; no grouping behavior was added.

## Executed checks

- Cached `flutter pub get --offline` succeeded; pubspec.lock unchanged.
  Existing cached Node dependencies were linked temporarily after package-lock
  equality with the read-only source checkout; no package installation.
- RED: `flutter test --no-pub test/core/hermes/setup/legacy_endpoint_preservation_test.dart`
  before production edits exited 1: both raw-generation cases exposed forbidden
  separate token-slot reads. The changed-origin case already passed.
- GREEN focused command below passed 673 tests in 2m15s. Analyzer passed with no
  issues (2.6s). Changed Dart formatting and git diff --check passed.
- `flutter build web --no-pub --release -t lib/main_connection_production_matrix_e2e.dart`
  passed (50.7s). `WING_APP_URL=http://127.0.0.1:18995/ CHROME_EXECUTABLE=/usr/bin/chromium timeout 8m node node_modules/@playwright/test/cli.js test --config=playwright/connection_production_matrix.config.mjs`
  passed 11 tests (1.9m), without test retries. The aggregate verifier
  `node playwright/support/connection_production_matrix_fixture.mjs playwright/.matrix-results/results.json`
  passed: 11 cases, 10 boundary receipts, 5 negative controls.
- `flutter build web --no-pub --release -t lib/main_e2e.dart` passed (52.6s).
  Main fixture saved-editor keyboard suite passed 4 tests (1.1m), at 390/1280 CSS
  pixels and 1x/2x zoom, reduced motion, no retries. The temporary config below
  uses existing runner/config and serves only deterministic loopback fixtures.
- Initial matrix invocation lacked WING_APP_URL: all cases failed on the default
  wrong fixture port, not product behavior. Correct environment rerun passed.
- An initial changed-origin test expected old key forwarding; it was corrected
  to require null, per the accepted origin-isolation contract, then passed.
- Initial full analysis located additional native fixture callers; after their
  signature/raw-test migration and retaining the independently used Maestro
  fingerprint constant, full analysis passed. No safety assertion was silenced.
- The first finish gate stopped at read-only formatting verification: a renamed
  gateway test title needed wrapping. Applied dart format to that owned test and
  refreshed its scoped fingerprint before rerunning the full gate.
- A foreground finish invocation hit the tool transport's 420-second limit
  during the last browser suite, before a task ref or finish receipt existed.
  Read back the log/ref/process state, then reran the required bounded finish
  gate as a tracked background process; no unfinished commit was claimed.
- Both builds emitted existing flutter_tts WASM dry-run interop warnings and an
  absent Cupertino font-family warning; JS release builds succeeded. WASM support
  is not claimed and warning suppression/dependency changes were skipped.

Focused acceptance command:

`timeout 8m flutter test --no-pub --concurrency=1 test/core/hermes/setup test/features/hermes_chat/gateways test/features/profiles test/features/gateway test/features/providers test/features/settings test/features/local_setup test/features/enrollment test/features/hermes_chat/screens/hermes_chat_saved_endpoint_edit_test.dart test/features/hermes_chat/screens/hermes_chat_saved_connection_workflows_test.dart test/features/hermes_chat/screens/hermes_chat_remote_connection_retry_test.dart test/features/hermes_chat/screens/hermes_chat_screen_auth_recovery_test.dart test/tooling/hermes_domain_authority_contract_test.dart test/tooling/enrollment_retirement_contract_test.dart`

Main fixture temporary `.dart_tool/endpoint-browser.config.mjs` (reconstruct for review):

```js
import config from '../playwright.config.mjs';
export default {
  ...config,
  testDir: '../playwright/tests',
  testMatch: 'saved-endpoint-edit.spec.mjs',
  outputDir: '../.dart_tool/endpoint-browser-results',
  reporter: [['list']],
  webServer: {
    cwd: new URL('../', import.meta.url).pathname,
    command: 'PORT=18995 HERMES_E2E_PORT=18996 node serve_web.mjs',
    url: 'http://127.0.0.1:18995',
    reuseExistingServer: false,
    timeout: 10000,
  },
};
```

Main browser command:
`WING_APP_URL=http://127.0.0.1:18995/ CHROME_EXECUTABLE=/usr/bin/chromium timeout 5m node node_modules/@playwright/test/cli.js test --config=.dart_tool/endpoint-browser.config.mjs`

## Broader evidence, not an unqualified green claim

The exploratory command expanded the focused targets to all test/tooling:
810 passed, 5 failed. An isolated `git archive` of the exact admitted base,
using cached dependencies, independently reproduced all five failures:

- provider picker and Settings grouped-host assertions: now repaired in owned
  fixture files as described above;
- test/tooling/playwright_profile_language_contract_test.dart: old add-gateway copy;
- test/tooling/readme_assets_contract_test.dart: old README promotion copy;
- test/tooling/wing_link_docs_contract_test.dart: old Termux Link-port requirement.

The latter three are outside this store slice, remain unchanged, and are reported
as inherited failures. Required authority/retirement guards passed. This is not a
claim that the complete repository suite is green. No new follow-up card or parent
closure was created.

Baseline reproduction commands inside isolated admitted-base archive:
`flutter test --no-pub --concurrency=1 test/tooling/playwright_profile_language_contract_test.dart test/tooling/readme_assets_contract_test.dart test/tooling/wing_link_docs_contract_test.dart` (exit 1, 2 passed / 3 failed).
`flutter test --no-pub --concurrency=1 test/features/providers/providers_screen_test.dart test/features/settings/settings_screen_test.dart --name 'gateway picker shows one host|settings groups one paired host'` (exit 1, both failed).
An initial --plain-name regex attempt selected no tests (exit 79); only the corrected
--name invocation is baseline evidence.

## Remaining boundaries

Implemented: bounded Agent-only endpoint contract and inert raw preservation.
Qualified: Linux-hosted Flutter tests and deterministic Chromium fixture journeys.
NOT_CHECKED: physical Android, Linux OS keyring, other native platforms, live
provider/authentication, full release suite, signed/packaged runtime, deployment.
Delivered: NOT_CHECKED; worker makes a local task-ref commit only. Independent
native review of its exact SHA, coordinator integration and publication remain.
Parent removal, retained management service/library, packaging, localization and
related documentation retirement remain separate work. No new abstraction or
runtime migration daemon was added. Usage/cost and independent review duration
are unknown; reported durations above are actual tool outputs, not estimates.

## Scoped source fingerprints

Hashes cover the implemented source/tests, not this receipt. The finish gate binds
the receipt and these files to the exact local task commit; independent review must
verify that ref and the original pre-edit admission history.

```json
{
  "integration_test/android_secure_storage_regression_test.dart": "f9d6bdfb0380e0bf031689491587d6942a7e707e32f411d5289d2538e58c3b60",
  "integration_test/hermes_features_maestro_main.dart": "bc6aeddf52c914d9145e2fbf55e5ef565b486f2cb1ac0fc29ab14ba18990b951",
  "integration_test/linux_desktop_welcome_recovery_test.dart": "fbcd1f64887fb1205884c93c0e0b30e8a67432a6a4f2433805740997ecde70c4",
  "integration_test/linux_direct_first_run_test.dart": "7d42f6383c16929b50ac8e0e70c08c8befdd7f9f17fa6eacc8bea6e9d55dfa10",
  "integration_test/linux_remote_connection_retry_test.dart": "f0c66529169ac747c9209e64c977e3e8feafa8b345d35a14e80b970c9813a11f",
  "integration_test/linux_secure_storage_integration_test.dart": "19ef2985397fc478f393aae154b85be3a0103242797e0f81de3109a72255e5f7",
  "integration_test/support/local_setup_enrollment_native_fixture.dart": "e9d972ba245e0267e19cf4bccc8b8e5a049b7fb67ae87baacd10d9e21f497a21",
  "integration_test/support/remote_auth_explanation_native_fixture.dart": "a7f082f51b5730e7db5367fa1fa83c493c9851f83f78d59c7fb9f3492093f33e",
  "integration_test/support/remote_connection_retry_native_fixture.dart": "160a276b6cb7834c5f573481940407fc4c5f4e6c333bdf7a57233d0de5f7f9e3",
  "integration_test/support/saved_endpoint_feedback_native_fixture.dart": "2e04cad924e385492a9817738dd7977a138a873413abf6b809e00206be62e131",
  "lib/core/hermes/setup/hermes_endpoint_store.dart": "e129b4fa28377cc3e0ada14a00ed2b761e683db4255bae0db06e5ad4061922fc",
  "lib/core/hermes/setup/secure_hermes_endpoint_store.dart": "0160acac45d95fde8ca70dc8ca7f3f379c317b3e453f22a08965f1775d982735",
  "lib/features/hermes_chat/gateways/hermes_gateway_directory.dart": "8610d9af159098c4887732a58541ce0d4cc8f10d7275f925fec995344d3f113d",
  "lib/main_connection_production_matrix_e2e.dart": "96efbef3f8934e36de76282f66d5b32e0db407846ec1933b661f3e6e0f4aab3f",
  "lib/main_e2e.dart": "8e1b8af39c46d2daebaf0d77ccc123a4d2ff5123f703b181a85bb4c673e116b7",
  "test/core/hermes/setup/legacy_endpoint_preservation_test.dart": "568f098710f709e55c68cd767f30a98a2f8833ce9737de2a5e726b0d2e4b7ef1",
  "test/core/hermes/setup/saved_endpoint_edit_store_test.dart": "9a113c798ffdbbe43a4519bd772d4ff3ac5f3fbe5975926805e0b0a7e7318b08",
  "test/core/hermes/setup/secure_hermes_endpoint_store_test.dart": "fc538cb59919775f0627978056798d6d72099081f290785b0be45c0b048ff722",
  "test/features/enrollment/hermes_direct_first_run_test.dart": "b13c2cc097024d7659a0e412927cd0161036fcb11a09a699c3fd3ea43e3eb7ae",
  "test/features/enrollment/hermes_welcome_recovery_test.dart": "0d9d1a0bef7b9241c197baa6a1c2d84a1b70494849b057d583fc62507094c80c",
  "test/features/enrollment/legacy_handoff_rejection_test.dart": "974799380a415626edfaeca63fca17a307dfe33b0f8e1d482319fd3f7d30debe",
  "test/features/gateway/gateway_health_ownership_test.dart": "b7343409dda40f82549d8ae5e8c27685c0af2081f5734015167b624683d25e75",
  "test/features/gateway/gateway_screen_test.dart": "d52ecc56440ac2d498b0cea5fd7a55ed1a983974af4be4f252bc2ab1eaaf27e8",
  "test/features/hermes_chat/gateways/hermes_gateway_directory_test.dart": "79b0fcda8ba4ceafe96410685a0871ddca836c56e7576c795ab1f961eb4ae02e",
  "test/features/hermes_chat/screens/hermes_chat_remote_connection_retry_test.dart": "5c2f2f5bb951c07987b43dd51d46833ec1a3b7ef84cbb2f4e36391b2162955ad",
  "test/features/hermes_chat/screens/hermes_chat_saved_connection_workflows_test.dart": "706c23cede30a312eb037a8c86f81b6efc79fd5c5f4ac779dc3a1faefb9143ca",
  "test/features/hermes_chat/screens/hermes_chat_saved_endpoint_edit_test.dart": "da22dee1857e9d3505df92f6fa71a2f64ff6484cb97ee842ee3f89069e1d58c1",
  "test/features/hermes_chat/screens/hermes_chat_screen_auth_recovery_test.dart": "14c4b0628956e9dba7e48a452029847ee10bb4368ce6f8e445928cc57e185a32",
  "test/features/hermes_chat/support/fake_hermes_endpoint_store.dart": "2befba613823c636b2c74c44c923f5eff0612f5980b2a1eddf32099b12aaa99e",
  "test/features/local_setup/linux_direct_setup_test.dart": "c1c9ccabf889bad14e1fcc2b3f62c3f7a8b92b18bde2dc7ad96b33b0da521a81",
  "test/features/profiles/profiles_screen_test.dart": "a71287011d61be99a7cdacedfc6c2fdd20e96cf680d93c5563c2d67afbe98503",
  "test/features/providers/providers_screen_test.dart": "c84e00e43700b8685929508956369082e030d8ae47125cc63d03b9e31a289f64",
  "test/features/settings/settings_screen_test.dart": "3a9261d57e967f068e323dc1a53e0ff01aef670aa321077faa6202a134a61878",
  "test/tooling/enrollment_retirement_contract_test.dart": "63d2194172d56e556084d8d89a6da04fba49d7f15f2778dac97aaef0a2d2b541"
}
```
