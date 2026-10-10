# Remote authentication explanation

> Reference correction: [official Desktop authority](official-desktop-reference.md). Prior Desktop source citations and parity conclusions in this document are withdrawn. Wing test results remain historical behavior evidence only.


Card: `t_62edb5a9`. Bounded task: `CONNECTION-REMOTE-AUTH-EXPLANATION`.
Goal: `CONNECTION-PATHS` remains partial. This is not OAuth implementation or live authentication qualification.

## Implemented

The production shared connection form shows localized, selectable guidance for
Remote HTTPS and VPN before submission and after denial. It explains direct
Hermes Agent endpoint/token access, optional Wing Link pairing, separate Agent,
management and provider credentials, and unsupported browser OAuth. It states
that an OAuth-only server cannot use this flow. It does not identify 401/403 as
OAuth detection. Recovery remains an explicit retry or Back; there is no new
probe, browser launch, network operation or automatic authentication replay.
Local and SSH do not receive this explanation.

The helper has a keyboard focus stop. The scrollable form uses widget-order
traversal so enlarged fields cannot strand AppBar Back. Both additions are in
`lib/features/hermes_chat/screens/state/hermes_chat_layout.dart`. English copy is
in `lib/l10n/app_en.arb`; localization output was regenerated with
`flutter gen-l10n`, not edited by hand. The error/transport implementations are
unchanged.

## Source and authority

Read-only Desktop reference: `withdrawn reference revision`,
`withdrawn source citation`. Desktop's Electron session/cookie login
is a real parity difference, not a Wing contract. Read-only Agent reference:
`158fd638da1629c8e62caf9ade1515d162def8ab`,
`hermes-agent/gateway/platforms/api_server.py::_check_auth` and
`hermes-agent/tests/gateway/test_api_server.py::TestAuth`. Agent validates its own
bearer credential; upstream source inspection is not live authentication proof.
No reference or Agent/Wing Link contract was modified.

Inherited file baselines and the attributable increment are retained at
`.task-evidence/t_62edb5a9/baseline.json` and
`.task-evidence/t_62edb5a9/owned-final.patch`. The local agent commit is assembled
against HEAD using only this increment, not inherited file versions. Apply the
baseline-to-task patch to the integrated predecessor state when combining lanes;
the standalone HEAD-based commit is not the qualified combined application.
SSH UI, dependencies, local setup and inherited tests/harnesses remain owned by
other lanes. The shared layout/localization files are collision hotspots.

## Executed qualification

The final isolated receipt directory is
`.task-evidence/t_62edb5a9/native/attempt-ccvwjdmc/`.
`verification.json` records exact executable paths, commands, exits and durations.
`source.json` and `executed-source.tar.gz` bind the complete candidate captured
before checks: archive SHA-256
`b88b8631586fcda2c40083d2564e72ab332f5451da0999df6b4dad673a117c07`;
source-manifest SHA-256
`d4cb535cd7d405cd2e52f624faf56131d87e67870934c8eacfb9d5831e29a06c`.
The executed source hashes were unchanged after checks. Dependency manifests
cover the copied Dart/plugin, Go and native header/library closures.

Environment: Linux x86_64, Flutter 3.44.2, Dart 3.12.2, Go 1.26.1,
GTK 3.24.41, GStreamer 1.24.2, libsecret 0.21.4. Authenticated isolated Xvfb
rejects missing/wrong authority. HOME/XDG and package sources were isolated;
personal DBus, display and authentication were not inherited. Build parallelism
was bounded to two. Fixture callbacks execute in process; they open no sockets
and perform no inference. The token is an in-memory synthetic placeholder,
never a host credential. Physical keychain behavior is NOT_CHECKED.

Final commands (run inside the frozen candidate; all exit 0):

- `python3 -B -m unittest discover -s test/tooling -p remote_auth_explanation_native_test.py`: 3 tests, 0.284 seconds.
- `bash -n scripts/run_linux_remote_auth_explanation.sh`: 0.023 seconds.
- `dart format --output=none --set-exit-if-changed integration_test/linux_remote_auth_explanation_test.dart integration_test/support/remote_auth_explanation_native_fixture.dart test/features/hermes_chat/screens/hermes_remote_auth_explanation_test.dart lib/features/hermes_chat/screens/state/hermes_chat_layout.dart`: 0.235 seconds.
- `flutter analyze --no-pub`: no issues, 17.959 seconds.
- `flutter test --no-pub --concurrency=1 test/features/hermes_chat/screens/hermes_remote_auth_explanation_test.dart test/features/hermes_chat/screens/hermes_chat_remote_connection_retry_test.dart test/features/enrollment/hermes_direct_first_run_test.dart test/features/hermes_chat/screens/hermes_chat_screen_auth_recovery_test.dart`: 38 tests, 60.686 seconds.
- `flutter test --no-pub --concurrency=1 -d linux -v integration_test/linux_remote_auth_explanation_test.dart`: 4 GTK journeys, 277.805 seconds. Flutter ignores the concurrency option for device integration tests; the test file runs its journeys sequentially.

Outer invocation: `timeout 25m bash scripts/run_linux_remote_auth_explanation.sh`,
exit 0; final elapsed time 398.044 seconds. Five earlier preparation/check/build
runs exited 1: missing pkg-config headers, dangling documentation symlinks,
two test-harness analyzer findings, and linker failures diagnosed with verbose
output. The header closure is now copied from the previous enrollment lane into
owned disposable storage, with valid relative library links dereferenced and
pkg-config prefixes relocated. No sudo, system install or dependency change was
performed. These failures and their durations remain in each attempt receipt.
Large copied SDKs, native builds and app state were removed by launcher teardown.

RED evidence: `timeout 120s flutter test --no-pub --concurrency=1 test/features/hermes_chat/screens/hermes_remote_auth_explanation_test.dart`,
exit 1 in `.task-evidence/t_62edb5a9/red.log`: the explanation did not exist.
Subsequent public-widget checks demonstrated the missing helper focus stop and
200% Back traversal failure before their repairs. Final GREEN includes those
same public journeys, not a weaker internal-widget substitute.

## Acceptance mapping

1. Public welcome Remote -> Add, Remote HTTPS/VPN controls and existing Chat ->
   directory -> Add use the production WingApp/router and shared form. The
   explanation and Local exclusion are checked by
   `test/features/hermes_chat/screens/hermes_remote_auth_explanation_test.dart`.
   No Link pairing is required. Copy stays truthful about unsupported OAuth.
2. At 390/1280 logical widths and text scales 1/2, keyboard Tab/Space reaches the
   helper, transport choices, token/form fields, Connect and Back. Synthetic 403
   then 401 denials stay sanitized. Endpoint, token and connection-name drafts
   remain intact after denial; idle does not replay a request. Cancel saves
   nothing; explicit retry succeeds with the Agent token, and the saved contact
   connects. Each native journey records four connects, one save and 23 token
   reads, with zero management, mutation or forbidden-read attempts. Only
   allowlisted read routes are accepted. Existing auth/save recovery regressions
   also pass. No unsent-chat-draft relaunch or physical secret-storage claim is
   made by this new journey.
3. The frozen candidate passes analyzer, owned formatting, 38 focused Flutter
   tests, tooling checks and four actual Linux GTK journeys. Captures and the
   source archive remain available for independent native review. The scoped
   ledger task is closed via goals.py; the card then hands off to native review.
   Review approval and protected-main delivery are separate outcomes.

Visual inspection: all 16 actual GTK captures were inspected as a contact sheet,
with full-size checks of compact 100% denial, compact 200% welcome/editing,
wide 100% denial and wide 200% welcome. The helper wraps without overlap or
horizontal clipping. At 200%, fields and error/retry controls require scrolling;
keyboard journeys prove they remain reachable. The wide denial capture shows
the sanitized error, obscured token and explicit Add action. Captures use the
unmodified production theme. No taste approval is treated as a gate.

## Remaining milestone gaps

Actual install/adopt, live Agent authentication, OAuth implementation authority,
SSH native qualification, Android/web/platform qualification, physical secure
storage, combined integration gates and protected-main delivery remain
NOT_CHECKED here. `CONNECTION-SETUP-AUTH-MATRIX` and
`CONNECTION-SAVED-WORKFLOWS` are not closed. The next milestone seam is approved
native SSH or live-auth qualification, not another synthetic enrollment replay.
No push, merge, release or external contact occurred. Cost/usage is unknown.

Questions: none. Default applied: retain the supported token path and explain
OAuth unavailability; do not implement OAuth or expand authentication authority.
