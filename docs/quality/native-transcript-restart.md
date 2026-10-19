# Native transcript restart without mutation replay

Task: `VERIFY-CHAT-TRANSCRIPT-NATIVE-RESTART`; goal: `CHAT-FIDELITY`.
This is bounded deterministic Linux GTK evidence, not live Agent qualification.

## Change and contract

The existing [target](../../integration_test/linux_transcript_recovery_test.dart),
[fixture](../../integration_test/support/transcript_recovery_native_fixture.dart)
and [launcher](../../scripts/run_linux_transcript_recovery.sh) now run write and
verify in **two distinct native processes using one unchanged application bundle**.
The historical [mounted-process receipt](native-transcript-recovery.md) remains
historical; its archive-dependent reproduction is superseded by this launcher.

The production fix preserves a failed tool when Agent emits `tool.completed`
with boolean `error: true`. Previously it was labeled completed. The nearest
[regression](../../test/features/hermes_chat/screens/hermes_chat_transcript_reconnect_test.dart)
failed with `(read_file, completed)` before the fix and now retains failed/read
followed by running/web. Read-only upstream checkout
`158fd638da1629c8e62caf9ade1515d162def8ab`,
`gateway/platforms/api_server_runs.py` (`_FIXED_EVENT_FIELDS`) and
`tests/gateway/test_api_server_runs.py`
(`test_tool_completed_event_includes_redacted_bounded_result_preview`) confirm
the wire flag. No Agent source, API, credentials or persisted disclosure state
was changed.

## Executed recovery

Four viewport cases per process: 390/1280 logical pixels, text scales 1/2,
reduced motion, traditional focus highlighting. Write performs one deliberate
synthetic send per case, reconnects to canonical history and leaves an approval
visible. Production channel lease persistence writes only the synthetic run owner;
real Linux `GatewayContactCache` preferences retain selection. Verify creates a
fresh channel and recovers through status/history/SSE reads, not another send.

- Both processes retain exact canonical IDs: `canonical-user`,
  `canonical-commentary`, `canonical-read`, `canonical-web`, `canonical-answer`.
- File/Web canonical categories remain ordered; recovered Code/Browser activity
  remains failed/running in order. Tab/Enter opens both groups after screen
  remount and compact/wide return. Hidden tool-result context is not shown.
- Verify has no Approve once, Deny or Review controls. No approval is serialized
  into client state for restart. The recovered stream contains current tool
  events, not a retired request.
- Closing the event stream exercises the actual 30-second idle-expiry path while
  status remains running. The assistant becomes failed, the last tool remains
  running, and the exact durable lease remains unresolved. No successful terminal
  outcome is inferred from missing activity.
- Final request counters are checked **after** widget/container/channel teardown.
  Each write case has one `POST /v1/runs`; every verify case has zero mutations.
  Across recovery: zero sends, creates, model writes, decisions and Stops.
  PATCH/PUT/DELETE/POST-stream are recorded and rejected without socket fallback.

Exact request origins, methods, paths, route-specific pagination and complete
setup bodies are retained in eight per-viewport receipts. The synthetic origin
`http://127.0.0.1:8642` is never contacted or bound; this is an injected transport,
not an HTTP authentication test. Recovery admits only GET health/capabilities,
session inventory, exact-session messages and run status, plus GET event SSE.

## Source, build and process evidence

Final evidence: `$TMPDIR/transcript-restart-6ucxrrlt/` (task scratch, not committed).
`verification.json`, `source.json`, `build.log`, `write.log`, `verify.log`, eight
viewport receipts, two terminal receipts and two bundle manifests are retained.
No transcript, key or personal endpoint is included in the committed evidence.

- Native write PID **2815277**, verify PID **2827414**; each is observed through
  `/proc` with its process group, start ticks and matching executable digest.
- Owned Xvfb PID **2815124**; missing/wrong authority rejected. Both application
  groups and the display group are reaped before isolated HOME/XDG state deletion.
- Build once: `flutter build linux --debug --no-pub -t integration_test/linux_transcript_recovery_test.dart --dart-define=INTEGRATION_TEST_SHOULD_REPORT_RESULTS_TO_NATIVE=false`.
  Launch the same bundle twice. Each binding terminal receipt says `passed: true`,
  `tests: 1`, with its actual PID and phase; both child exit codes are zero.
- Source manifest SHA-256:
  `9d44b0053cfe3696d353f49d3cc4732163e8276abcde3b7243e5e09d71f80447`.
  Current task source is fingerprinted before build and after both processes;
  no historical product overlay or missing predecessor archive is used.
- Identical 19-file bundle manifest SHA-256:
  `826343c700c821c8231bcff4cb1642ca4bbc2b312318bcf328510dbca3072b6d`.
  Includes the Dart kernel, runner, assets, engine and bundled plugin libraries,
  not just the small GTK executable. Kernel SHA-256:
  `23505126b48ef120231f311d4bad0e1922eacc0e75ae12e6086fcca31cfb74a8`.
- The existing authenticated display/process supervisor is loaded read-only from
  pinned revision `894439b76c889fed45f3c4d57b73086f1e18d479`; its hash, SDK tool
  hashes and package configuration/graph/plugin fingerprints are in the receipt.

## Validation and reproduction

With Flutter 3.44.2, resolved packages, Xvfb, xdpyinfo and native development
libraries provisioned, from this isolated worktree:

```sh
flutter pub get
python3 -B -m unittest discover -s test/tooling -p transcript_recovery_native_test.py
bash -n scripts/run_linux_transcript_recovery.sh
timeout --kill-after=10s 1400s env -u DISPLAY bash scripts/run_linux_transcript_recovery.sh
```

The launcher takes no arguments or credentials, installs nothing, and writes
owned state/evidence under `$TMPDIR`. It uses this task worktree's own build
output and ordinary Flutter SDK locks; no other worktree or SDK lock is removed.
An optional already-provisioned `$AUTOWORK_CACHE/linux-dev-noble-20261007/root`
sysroot is reused. Otherwise normal developer compiler-prefix inputs apply.
The fixture opens no network listener; Xvfb disables TCP. No live service is restarted. The debug VM service is confined to
`AUTOWORK_PORT_BASE + 1` (20401 in this run), checked from both native logs;
process teardown removes that listener. Set `AUTOWORK_PORT_BASE` to your reserved
100-port range before reproducing.

Final scoped results: receipt tests **4 passed**; fixture transport regression
and chat/approval modules **15 passed**; native launcher **passed, 186.477s**;
`flutter analyze --no-pub`, Dart formatting and `git diff --check` **passed**.
The offline full Flutter gate passed **4,045 tests, 9 skipped** before review-only
harness hardening; changed harness modules were rerun afterward. Release web E2E
build and default browser suites passed (**89 passed, 1 opt-in live test skipped**),
and `npm audit` found zero vulnerabilities. Browser checks used system Chromium
and Node 24.19.0, not a Node 22 toolchain qualification. Existing web Wasm-dry-run
and CupertinoIcons warnings remain; no Wasm/font support claim is added.

## Evidence boundary

Exercised: native Linux x86_64 GTK under authenticated Xvfb, production channel
recovery and Chat presentation over deterministic transport; Linux preferences;
headless Chromium release-web regression gate. The isolated GTK environment
emits an ATK embedding warning; physical assistive technology is not qualified.
Native input is Flutter key-event
injection. `ensureVisible`/reversed-list positioning prepares the lazy viewport
before Tab/Enter; this is not a whole-journey keyboard-only scrolling claim.

Not qualified: physical Android/mobile or screen readers, physical keyboard,
full saved-endpoint/application-shell startup, OS secure-storage recovery,
actual Agent/provider/tool execution, authentication, notifications, signed
packages or other native platforms. The file-backed **test-only** lease store
contains synthetic owner metadata, never transcripts or disclosure state. Canonical
history is fetched independently in each process; active tool statuses come from
Agent-style SSE replay, not invented history status fields. No overall
CHAT-FIDELITY completion, remote delivery or coordinator integration is implied.
