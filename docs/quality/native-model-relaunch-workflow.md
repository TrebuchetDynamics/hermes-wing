# Combined native model and session relaunch qualification

> Reference correction: [official Desktop authority](official-desktop-reference.md). Prior Desktop source citations and parity conclusions in this document are withdrawn. Wing test results remain historical behavior evidence only.


Card `t_158c055a`; goal task `VERIFY-NATIVE-MODEL-RELAUNCH`, M1.
Result: PASS for the bounded combined Linux fixture journey; exact provider/model
pair restoration is UNSUPPORTED by the inspected Agent contract. M1 remains partial.
Scope correction was recorded in card comment 536 before implementation. The
card's current guidance now explicitly accepts this supported-contract QA slice;
it does not waive the original exact-pair product requirement.

## Contract limit

Read-only Agent reference `158fd638da1629c8e62caf9ade1515d162def8ab`:
`gateway/platforms/api_server.py:3011-3043` projects model text and configuration
presence, not provider/runtime/model_config. Its capability table advertises an
explicit model POST, not a session-bound confirmed-pair GET. Nearest upstream
`tests/gateway/test_session_api.py:83-112` verifies the safe projection (inspected,
not executed). Desktop reference `withdrawn reference revision`,
`src/renderer/src/screens/Chat/Chat.tsx:370-409`, uses locally persisted overrides;
that is not authority Wing may copy. See [pair-read qualification](session-model-pair-read.md).

No fabricated GET capability, metadata runtime leak, provider inference from a
model name, catalog-default substitution, shadow lock cache or upstream edit was
introduced. The original exact-pair product requirement is not delivered. Revised
bounded acceptance (1) requires exact off-page owner/session and canonical history
restoration, with unknown provider, no catalog fallback and disabled Use when an
authoritative pair read is unsupported. The native regression checks that boundary.

## Delivered change

The [native integration target](../../integration_test/linux_desktop_daily_workflow_test.dart)
now seeds the existing `desktop-daily` scenario, rejects then acknowledges explicit
`alpha` / `alpha/model-99` for the exact session, and performs the approval/Stop
journey without resetting that scenario. Only one model write succeeds.

The second GTK process restores the real Linux preference pointer through the
production exact-owner metadata/history path. It checks restored model text and
`has_model_config`, empty confirmed-lock state, and the production picker with
unknown identity, explicit explanation, no catalog preselection and disabled
Use for session. Cancelling leaves state unchanged. Existing exact metadata,
canonical history, route-reopen, correlated approval and authoritative Stop
assertions remain. Mutation comparisons now include model writes.

The [launcher](../../scripts/run_linux_desktop_daily_workflow_e2e.sh) verifies the
combined scenario, exact model write receipts, phase-specific known/unknown pair
state, distinct actual GTK PIDs and cleanup. The prior separate model rejection
check is retained as additional evidence, not counted as combined mutations.
Predecessor workspace helper and its tests are preserved unchanged. No production
repair was required; no shared fixture or excluded source files were modified.

## Executed acceptance receipts

Linux GTK under fresh Xvfb X11, software rendering, synthetic direct HTTP/SSE
Agent API and real Linux SharedPreferences; injected synthetic endpoint store.
Base checkout `1afe1307e37ee1ddfa1f7d67ad047509e99c8784` plus preserved dirty work.
Copied input SHA-256 manifests bind evidence to that actual source, not to a clean
base or card-only commit. The isolated copy includes existing plugins, bundled
Wing Link and transitive JS fixture imports; upstream clones are excluded.

1. `timeout 700s bash scripts/run_linux_desktop_daily_workflow_e2e.sh`: exit 0.
   Native write PID 1177278; verify PID 1178601; both phases exit 0. Each runs
   `flutter test --verbose --no-pub -d linux integration_test/linux_desktop_daily_workflow_test.dart --reporter expanded`
   through its independent SDK. Both select `daily-fixture` / `default` /
   `e2e-hermes-session`. Pointer is absent from initial inventory pages; production
   restoration performs exact owner metadata and canonical history reads.
2. Combined counters unchanged across restart: 2 model attempts (1 rejection,
   1 accepted), 2 sends, 1 approval, 1 Stop, zero unexpected mutations/creates.
   Final reads: 10 inventory, 2 exact metadata, 5 history. Write confirms alpha /
   alpha/model-99; verify reports provider null, model alpha/model-99 and
   `unsupported-explicit-unknown`. This is NOT a passing exact-pair readback.
3. `timeout 60s node --test playwright/support/hermes_desktop_daily_fixture_test.mjs`:
   exit 0, 3 tests, child and public-port cleanup verified.
4. `python3 -m unittest discover -s test/tooling -p desktop_daily_workspace_test.py`:
   exit 0, 2 tests.
5. Independent source/SDK copy: `flutter analyze --no-pub`, exit 0, no issues;
   `flutter test --no-pub --concurrency=1 test/features/hermes_chat/screens/hermes_chat_model_authority_test.dart test/features/hermes_chat/screens/hermes_chat_model_restoration_test.dart test/features/hermes_chat/gateways/hermes_gateway_session_restoration_test.dart test/core/hermes/channel/hermes_api_channel_test.dart`,
   exit 0, 340 tests. Exact resolved commands in `focused-checks.json`.
6. `bash -n scripts/run_linux_desktop_daily_workflow_e2e.sh` and
   `dart format --output=none --set-exit-if-changed integration_test/linux_desktop_daily_workflow_test.dart`:
   exit 0. Scoped diff whitespace check passes; final documentation check is
   recorded in the card handoff.
7. Teardown: fixture intentionally exits 143, both Flutter launchers exit 0,
   `all_reaped: true`, `all_owned_groups_gone: true`, no surviving groups. Guarded
   native source/SDK/build root removed; focused source/SDK/build copy removed.

## Reproduction and retained evidence

Prerequisites followed the [user-space recipe](native-relaunch-workflow.md#safe-user-space-prerequisites-and-reproduction),
using `build/native-model-relaunch-prereqs` instead of the predecessor prefix.
Installed amd64 runtime compatibility was rechecked: libsecret 0.21.4-1build3,
GStreamer core 1.24.2-1ubuntu0.1, base 1.24.2-1ubuntu0.5, ORC
1:0.4.38-1ubuntu0.1. Thirteen public apt packages were downloaded/extracted,
pkg-config prefixes rewritten only in the owned extraction, and PKG_CONFIG_PATH /
LIBRARY_PATH set for compilation. No sudo/system installation, runtime loader
replacement, credentials or live inference. Package hashes/versions are retained;
owned downloaded/extracted prerequisites are removed after checks.

Compact evidence lives in
`<repo>/build/native-model-relaunch-evidence/`:
phase/final/model/teardown receipts, source/focused-source manifests, launcher and
phase logs, focused analyzer/test logs and exact command receipts. The review
handoff carries an archive of these files. Manifests include borrowed shared input;
card-only branch compilation and packaged execution are NOT_CHECKED.

Exact provider/model restart read, live Agent/provider inference, full shell,
physical input/IME, audio, accessibility assistive technology, Android, other native
platforms, service lifecycle and signed/package distribution: NOT_CHECKED.
No broader M1-met claim. Native review approval is subsequent to this handoff.

Questions: none. Defaults applied: current authoritative contract, explicit unknown
pair on restart, preserve unrelated edits, no upstream/API extension or shadow state.

## Same-card acceptance reconciliation

The resumed run reuses the unchanged native and focused-test receipts rather than
rerunning suites to address a lifecycle rejection. Executed
`python build/native-model-relaunch-evidence/verify_freshness.py` passes: both
628-entry source manifests match the current worktree with zero mismatches; the
integration target and launcher match commit
`1c577667b47620c419bd52bfc23809183aaf1f38`; distinct GTK PIDs, zero replay counters,
exact off-page metadata reads, unknown provider and teardown receipts remain valid.
The owned focused-copy and extracted-prerequisite roots remain absent.

The ledger task's done status denotes this bounded QA slice and review handoff,
not delivery of its original exact-pair title. A separate inspection evidence entry
records that limitation. M1 remains partial and its live-workflow task remains open.
Exact-pair restart remains dependent on an unmodified upstream authoritative read
contract. Native review is still required; no approval is inferred from this update.
