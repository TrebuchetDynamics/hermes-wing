# Native explicit reselection and one resumed send

> Reference correction: [official Desktop authority](official-desktop-reference.md). Prior Desktop source citations and parity conclusions in this document are withdrawn. Wing test results remain historical behavior evidence only.


Card `t_d6467f03`; goal task `VERIFY-NATIVE-RESUMED-SEND`, M1.
Qualified: bounded synthetic Linux GTK journey. Native review is the final card
handoff; approval and protected-main delivery remain subsequent steps. M1 is not met.

## Implemented journey and authority

The [native target](../../integration_test/linux_desktop_daily_workflow_test.dart)
extends the predecessor's two-process write/verify lifecycle. A fresh GTK process
restores `daily-fixture` / `default` / `e2e-hermes-session` from real isolated Linux
preferences. The session is absent from initial inventory pages; production exact
metadata and canonical history reads recover it. Before any user mutation, the
confirmed pair remains unknown; the production picker explains the missing
identity, selects no catalog default and disables Use for session. Cancel writes
nothing. These predecessor assertions remain intact.

The second process deliberately reopens the production picker, searches/selects
`alpha` / `alpha/model-99`, and presses Use for session. One acknowledged write
confirms that exact owner/session pair. One explicit composer send then creates
`run_3`; the canonical readback contains `canonical_run_3` and the synthetic reply.
Leaving/reopening Chat retains it with zero additional sends, session creation,
model writes, approval replies, Stop requests or unexpected mutations. The original
rejected/accepted model attempts, correlated approval and authoritative cancelled
Stop checks are unchanged. No production repair was required.

The [launcher](../../scripts/run_linux_desktop_daily_workflow_e2e.sh) records
checkpoint counts, validates phase deltas, retains command/duration receipts and
checks actual distinct GTK PIDs. The
[synthetic lifecycle fixture](../../playwright/support/hermes_lifecycle_fixture.mjs)
adds only the fixed `desktop-daily` third-run no-tool reply. Legacy scenarios,
first-run approval, second-run Stop and fourth-run transport failure retain their
behavior. The existing fixture regression exercises the new acknowledged lock,
submission, no-approval stream, canonical readback and unchanged sibling counts.

Read-only Agent reference `158fd638da1629c8e62caf9ade1515d162def8ab`:
`gateway/platforms/api_server.py:3011-3043` projects model text/config presence but
no confirmed provider/model snapshot; `tests/gateway/test_session_api.py:83-112`
checks safe metadata. Wing's picker caller at
`lib/features/hermes_chat/screens/state/hermes_chat_layout.dart:1291-1317` requires
explicit selection and invokes the profile/session-fenced acknowledged POST in
`lib/core/hermes/channel/api_channel/hermes_api_channel_providers.dart:172-222`.
Desktop reference `withdrawn reference revision`,
`src/renderer/src/screens/Chat/Chat.tsx:370-409`, restores local overrides; Wing does
not copy that shadow authority. See [pair-read limits](session-model-pair-read.md).
Reference tests were inspected, not executed. No upstream edits, credentials,
new APIs, persisted pair cache, profile administration or live inference.

## Executed acceptance evidence

Ubuntu Linux GTK, owned Xvfb X11, software rendering; direct synthetic HTTP/SSE,
production channel and Chat UI, injected synthetic endpoint store, real isolated
SharedPreferences. No physical keyboard/IME or whole-app startup claim.

1. `timeout 700s bash scripts/run_linux_desktop_daily_workflow_e2e.sh`: exit 0,
   first native attempt. Actual GTK PIDs 2532419 (write) and 2534523 (verify).
   Phase wall times 29.708s and 29.456s; both exit 0. Each runs
   `flutter test --verbose --no-pub -d linux integration_test/linux_desktop_daily_workflow_test.dart --reporter expanded`
   through its independent source/build/SDK copy. Exact resolved commands are in
   `phase-receipts.json`.
2. Restart and Cancel: zero deltas for all six recorded counters. Reselection:
   model attempts 2 → 3 (one newly accepted write), sends remain 2. Deliberate
   send: sends 2 → 3; model attempts remain 3. Approval replies stay 1, Stops 1,
   sessions 2, unexpected mutations 0. Route reopen: zero deltas. Final canonical
   reads include old stopped outcome and resumed reply. Final read counts:
   12 inventory, 2 exact metadata, 6 history. Counts derive from fixture readback,
   not client estimates. `continuation-receipts.json` preserves every checkpoint.
3. `timeout 60s node --test playwright/support/hermes_desktop_daily_fixture_test.mjs`:
   exit 0, 3 tests, fixture children reaped and public ports closed.
4. `python3 -m unittest discover -s test/tooling -p desktop_daily_workspace_test.py`:
   exit 0, 2 tests. `bash -n scripts/run_linux_desktop_daily_workflow_e2e.sh` and
   `dart format --output=none --set-exit-if-changed integration_test/linux_desktop_daily_workflow_test.dart`:
   exit 0.
5. Independent source/SDK copy: `flutter analyze --no-pub`, exit 0, no issues,
   22.603s; `flutter test --no-pub --concurrency=1 test/features/hermes_chat/screens/hermes_chat_model_authority_test.dart test/features/hermes_chat/screens/hermes_chat_model_restoration_test.dart test/features/hermes_chat/gateways/hermes_gateway_session_restoration_test.dart test/core/hermes/channel/hermes_api_channel_test.dart`,
   exit 0, 340 tests, 21.678s. Commands have 180s/240s timeouts; resolved paths,
   command arrays, exits and durations are retained in `checks.json`.
6. Scoped whitespace, patch roundtrip, source freshness, local links and guarded
   cleanup checks are retained with the handoff. Native teardown: launchers exit
   0; fixture intentionally exits 143; all children reaped, no owned groups remain.
   Owned native/focused source, SDK and build copies and prerequisite extraction
   are removed; compact evidence remains. No tests overlap the integration-owner
   heavy suite; its PID was observed gone before native compilation began.

## Source binding, ownership and reproduction

Executed source: base `b9eb5b3d9f6f3a433dd36cb6271ad8ec769b2319` plus borrowed dirty
predecessor inputs and this card's scoped delta. Native/focused manifests each hash
644 copied inputs including transitive fixture modules, plugin/host sources and
bundled Wing Link. Source freshness compares those hashes to the worktree; this
is qualification of that assembled snapshot, not a clean-base or branch-only build.

The integration target and launcher's original bytes equal predecessor branch
`agent/wing/t_158c055a` at `c0a64544a14c342b03134d6b65a471dcbfd12b9d`.
The local task branch is parented on that attributed dependency so its commit does
not reauthor prior hunks. The already-staged JS regression also contains pair-read
changes owned by `t_3ad70dd4`; its task-only addition is committed separately as
[native-resumed-send-fixture-test.patch](native-resumed-send-fixture-test.patch).
Apply that patch after the predecessor fixture-test changes are assembled. The
shared test file already contains the tested addition; do not apply it twice.
`task-owned.patch` in retained evidence covers all four changed executable inputs,
relative to captured original bytes, with before/after SHA-256 identities. Shared
index, main and unrelated changes are preserved. Goal/TODO updates remain shared
ledger changes, not wholesale borrowed content in this scoped implementation commit.

Toolchain observed: Flutter 3.44.2 framework c9a6c48423, Dart 3.12.2, Node v26.7.0
(not the repository's recommended Node 22), Go 1.26.1 linux/amd64. SDK/dependency
identities and lockfile hashes are in `environment.json`. User-space prerequisites
follow [the existing recipe](native-relaunch-workflow.md#safe-user-space-prerequisites-and-reproduction)
with owned prefix `build/native-resumed-send-prereqs`. Thirteen apt packages were
downloaded/extracted; package names/versions/hashes are retained. Installed runtime
compatibility was checked: libsecret 0.21.4-1build3, GStreamer core
1.24.2-1ubuntu0.1, base 1.24.2-1ubuntu0.5, ORC 1:0.4.38-1ubuntu0.1.
Only owned pkg-config prefixes and compilation library paths were set; no sudo,
system installation, personal display/preferences/runtime or loader override.

Compact evidence: `build/native-resumed-send-evidence/` (ignored), including
source manifests, checkpoint/final/model/teardown receipts, native logs, focused
logs/checks, dependency/prerequisite identities, scoped patch and original bytes.
The native review handoff retains a downloadable archive. Measured command/phase
times are reported; billing cost and independent review duration are unknown.

## Remaining qualification and delivery

NOT_CHECKED: branch-only build, full suite, live Agent/provider generation,
separately authorized live approval/Stop/restore/resumed-send, physical input,
secure enrollment, exact-pair persistence/read capability, full shell, Android,
other platforms, audio, assistive technology, packaged/signed distribution,
service lifecycle, image build/run/deployment, protected-PR merge and main ancestry.
Bundled Wing Link compilation is not packaged service execution.

Next milestone slice remains the separately authorized live daily workflow and
integration-owner protected-PR qualification; no extra card or reviewer lane was
created. Implemented and synthetic-qualified do not mean merged delivery.

Questions: none. Defaults applied: honest unknown identity, explicit reselection,
synthetic-only scope, preserve predecessor ownership, no release or live inference.
