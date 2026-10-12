# Connections Agent-only consumer removal

Status: implemented and fixture-checked on native card `t_41af2032`; independent
same-card review is the next phase. No commit before review, canonical integration,
publication or native/live qualification is claimed. Goal `CONNECTION-PATHS` and
parent work `CONNECTION-LINK-REMOVAL` remain open.

## Candidate and scope

Base: `d4c476d5a3ee7f540119ef9ea8cef7387ce4cf4c`, the approved Profiles
predecessor. The hash-pinned workspace start gate returned
`worker_start_admitted` before the first edit. This receipt describes only the
isolated Connections candidate, not canonical route delivery.

`GatewayScreen` no longer creates a Wing Link management client, reads metadata or
current-device trust, offers self-revocation, clears enrollment or promotes host
management instructions. Its existing direct Agent health and saved-owner
Connect/Disconnect paths remain. The dormant builder parameter is retained only
for deterministic zero-construction probes and is never invoked. No new API,
capability, shell fallback, dependency or shadow state was added.

Secure saved Agent and legacy Link fields remain intact. Unsupported lifecycle,
logs and peer administration stay hidden behind the existing missing-contract
behavior. Core Link clients, service authorization/TLS/revocation checks, stores,
enrollment, setup, Profiles and packaging are unchanged.

## Acceptance evidence

- Regression first: the new public-control test failed on the admitted production
  source with expected client constructions `0`, actual `1`.
- Opening, rebuilding after saved-config replacement, disconnect cancellation,
  confirmed disconnect and explicit reconnect perform zero screen-owned Link
  construction, request or pending-credential recovery. The same test reads back
  stored endpoint, Agent credential and all legacy fields, including the pending
  credential identity. Directory bootstrap is deliberately separate: its injected
  recovery is attempted once before mounting and returns false. No bootstrap or
  global directory-recovery removal is claimed.
- Direct refresh, basic/detailed health, exact operation/grant denial, late
  success/failure, channel/directory replacement and same-frame owner restoration
  remain covered by the gateway suite. Keyboard widgets at 390/1280 widths with
  200% text and reduced motion pass; these are Linux Flutter test fixtures, not
  native-device, browser or screen-reader qualification.
- Saved-directory restoration, cancellation, deferred selection writes, endpoint
  identity and credential persistence closure pass. No mutation replay behavior
  was introduced; the shared owner and cancellation paths are unchanged.

Executed checks (all from the isolated workspace):

- `flutter pub get`: pass; required because the fresh workspace lacked resolved
  dependencies. Both lockfiles stayed unchanged. The first `--no-pub` test launch
  failed before loading tests; it was not the behavioral RED result.
- `timeout 5m flutter test --no-pub --concurrency=1 test/features/gateway/gateway_screen_test.dart --plain-name 'legacy metadata never opens management or erases saved access'`:
  behavioral RED above, then GREEN. During test development a missing fake basic
  health seed was corrected; no production health change was needed.
- `timeout 10m flutter test --no-pub --concurrency=1 test/features/gateway`:
  pass, 72 tests; final run approximately 12 seconds.
- `timeout 10m flutter test --no-pub --concurrency=1 test/features/hermes_chat/gateways test/features/hermes_chat/screens/hermes_chat_gateway_confirmation_owner_test.dart test/features/hermes_chat/screens/hermes_chat_gateway_switch_test.dart test/core/hermes/setup/hermes_endpoint_store_test.dart`:
  pass, 257 tests, approximately 30 seconds. Production semantics and these inputs
  remained unchanged by the subsequent whitespace/test-probe/doc-only closure.
- `timeout 10m flutter analyze --no-pub`: pass, no issues; final run 1.9 seconds.
- `dart format --output=none --set-exit-if-changed lib/features/gateway/screens/gateway_screen.dart test/features/gateway/gateway_screen_test.dart`:
  pass, zero changes after formatting.
- `git diff --check`: pass. Changed local documentation links/anchors are checked
  separately before native review handoff.

Toolchain: Flutter 3.44.2, framework `c9a6c48423`, Dart 3.12.2. Checked source SHA-256:

- `lib/features/gateway/screens/gateway_screen.dart`: `ebe4de7d42087caa7901d4914f9dee7cdab8b52e57d930c4c055148dcc08ad1e`
- `test/features/gateway/gateway_screen_test.dart`: `35ef92a3814df67157bca4cabf09bb21a8773ec7049d595480cc7e26971ce1e1`
- `pubspec.lock`: `f089602c321af4a65d6f1dc70b6adef724079bedc8e4f1d0496f7b8e22641c89`
- `package-lock.json`: `f32c4b4d226bf6cef1a1f66733d4c2e065e0656d1223e89f17ceb68f42429b63`

## Method and remaining work

Skill application: engineering adapter at
`hermes-toolset/skills/engineering/SKILL.md`, pinned Addy revision
`1be8e34187e34647bb83adc3a1323b26ae6f6abe`; implement/frontend/TDD routing
verified protocol hashes. Incremental implementation removed one consumer only;
TDD proved the opening side effect before removal; frontend guidance preserved
existing health, accessible controls and tested ownership states. Review guidance
was applied as self-review of tests, boundaries and the scoped diff, not independent
approval. Git guidance preserved the isolated workspace and explicit no-commit
restriction; the coordinator owns closeout after genuine review.

The `ponytail` skill name was unavailable. The supplied full-mode rules were the
fallback: delete the consumer, reuse existing controls, add no replacement service
and retain required safety checks. No supporting skill was installed or modified.

Next remaining seams belong to the existing removal owner: global directory
pending-credential recovery, enrollment/setup, remaining management consumers and
packaging. This slice does not retire the stored credentials or qualify those
paths. Browser E2E, Linux native app, Android, live Agent/Link services, packaged
execution, full-repository release gates and protected-main delivery are
NOT_CHECKED. Review acceptance, commit and delivery remain separate gates.

Sources: [deprecation](../adr/product.md#wing-link-deprecation),
[connection requirements](../product/prd.md#connection-path-requirements),
[route support](../product/routes.md), and the retained
[health ownership runbook](../runbooks/connections-health.md).
