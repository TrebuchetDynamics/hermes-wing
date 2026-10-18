# SSH shared API profile correction

## Contract and boundary

Read-only Agent reference: `d923a5eb487a17c0a68801bba9ef0f56c81040a8`.
`gateway/platforms/api_server.py` resolves `/p/{profile}` in
`_resolve_request_profile`, rejects unknown/unserved profiles, enters the selected
profile scope, and mirrors native routes on the shared listener. The nearest
upstream tests are `tests/gateway/test_api_server_profile_prefix_misdelivery.py`
and `test_api_server_multiplex_secret_scope.py`: another profile's key is denied;
there is no fallback to the root profile. Source inspection, not an upstream
runtime qualification. No Agent source or installed runtime was modified.

Wing previously always exposed the forwarded Agent URI at root. SSH login could
succeed while Agent authentication went to the wrong profile. The optional
**Agent API profile** field now accepts only a literal bounded lowercase profile
ID, builds `/p/{profile}` internally and leaves the fixed TCP destination at
`127.0.0.1:<Agent port>`. Blank retains root compatibility. Arbitrary URLs,
paths, encoded delimiters, whitespace and query/fragment syntax are rejected.
This is connection routing, not creation or global selection of an Agent profile.

The existing API client's path scoping is reused. Channel bootstrap now prefers
the explicit URL profile over a capability document's root/default query identity;
otherwise a query-context capability document could reject the prefixed bootstrap
or mislabel its owner. No extra profile query is added to a prefixed URL.

## Persistence and trust

- Legacy five/seven-field SSH target records remain root records without rewriting
  on load. Eight-field records add only an explicit API profile, preserving the
  old field positions. Serve-mode records cannot carry an API prefix.
- Recovery JSON adds an optional `agentProfile`; absent means root. Matching and
  uncertain-run ownership include the prefix. The historical root run-owner hash
  input is unchanged. Root and different prefixes cannot import each other's
  conversation or uncertainty fence.
- Host trust remains exact SSH host/port, not API profile. A changed fingerprint
  still fails closed, including after profile changes.
- Editing the profile or loading saved settings clears the prior Agent token.
  Authentication is deliberately reacquired; no password, private key or Agent
  token is added to saved destinations/recovery. No protocol/root retry occurs
  after Agent denial.

## Verification and limits

Flutter 3.44.9 / Dart 3.12.2 was explicitly selected; offline enforced-lockfile
resolution succeeded without lockfile changes (repository documentation names
3.44.2). New model, storage and form/controller slices were exercised RED then
GREEN; the prefixed recovery regression exposed the channel-bootstrap root-ID
bug before its correction.

- `flutter gen-l10n`: passed; output regenerated, not hand-edited.
- `flutter analyze --no-pub lib`: passed.
- Full `flutter analyze --no-pub`: blocked by an existing top-level `testWidgets`
  outside `main` in `test/features/hermes_chat/screens/hermes_chat_layout_width_test.dart:59`
  on base `f249e3dd`; this unrelated file is unchanged.
- Broader `test/core/hermes` plus SSH provider/form/panel/saved-target suites:
  1,056 passed, 9 opt-in SSH tests skipped. Subsequent added denial coverage and
  stronger root hash/selected-owner assertions: 59 focused tests passed.
- Real disposable loopback SSH fixture: 9 passed, including explicit profile path
  observed at the forwarded HTTP server, password/key authentication, host-key
  refusal, cancellation and lease teardown. No personal host/credential used.
- `flutter build web --release --no-pub -t lib/main_e2e.dart`: passed. Existing
  flutter_tts Wasm dry-run warnings do not qualify Wasm support.
- `git diff --check`: passed.

Execution was Linux-hosted Flutter unit/widget and disposable native SSH/HTTP,
not physical Android, a deployed Agent multiplexer or real model generation.
APK build, main integration and remote publication belong to the parent delivery.
Existing sanitized SSH/Agent error presentation is unchanged; this correction does
not broaden error reporting or expose raw upstream exceptions.
