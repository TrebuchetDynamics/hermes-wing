# Native transcript keyboard follow-through

Task: `VERIFY-CHAT-TRANSCRIPT-NATIVE`; goal: `CHAT-FIDELITY`.
This receipt qualifies one complementary deterministic Linux GTK journey on
baseline `d121bffb24fcd0c6bc621007910332eb5c1624a9` plus this task's delta.
[Machine-readable source/request/process evidence](chat-transcript-native-keyboard-receipt.json)
records the exact executed inputs. Coordinator integration remains separate.

## Reused evidence and remaining slice

The [earlier native receipt](native-transcript-recovery.md) already qualifies four
390/1280-width, 100/200%-text reconnect/remount/Approve-once/failure-owner cases.
Those cases were not repeated or relabeled as current-binary, process-restart or
screen-reader proof. Their original source/binary identities remain their bounds.

The retained eight-file keyboard candidate was inspected read-only after checking
its former worker was inactive. Only this task's presentation, fixture and native
execution delta was adopted; old blocked-status docs/receipts were replaced with
fresh results. No train, parser, SSH, coordinator, dependency or upstream changes
were imported. The current invocation permits local execution and classifying
unrelated/environment failures rather than waiting for a baseline refresh.

## Reproduced defect and fix

The native test first reproduced a presentation defect on this baseline:
canonical reconnect removed the approval banner, but an already-open actionable
Review sheet and its focused decision controls remained visible. The API channel
already rejected retired owners; the sheet outlived its presentation owner.

`_ApprovalBanner` now owns that Review route and removes **only that route** after
its banner is disposed or its request instance changes. Removal is deferred past
build, never a blind pop of a replacement or unrelated route. Decision and
confirmation closures retain the displayed request/callback snapshot, not a
replacement widget. Read-only malformed reviews retain their explicit local
dismissal behavior; the existing dismissal regressions pass. No channel,
capability, wire, redaction, authorization or durable-state contract changed.

## Executed complementary journey

One native test at 200% text uses production `HermesApiChannel`, Chat, timeline and
approval queue with the existing deterministic HTTP/SSE function seam. Endpoint
storage, preferences and speech services are test overrides; no Agent listener,
provider, credential, actual tool execution or personal state is used.

1. At 390 logical pixels, Tab reaches Review and Space opens it. A decision has
   keyboard focus when canonical reconnect occurs. The retired sheet, banner,
   decision controls and focus disappear; exactly five canonical message IDs
   replace transient history.
2. Chat remount and compact/wide return add no mutation. Tab reaches recovered
   tool disclosure; Shift+Tab leaves and Tab returns to the same focus node.
   Space opens and closes ordered File/Web activity. Hidden synthetic result
   content never renders. Canonical reconciliation adds no mutation.
3. A second deliberate setup send obtains `run_2/request_2`. After compact/wide
   return, Enter opens Review and Space closes it without deciding. Compact
   return then permits Space to open Review and activate focused Deny once.

Exact totals: two deliberate `/v1/runs` submissions; one decision at
`/v1/runs/run_2/approval`, `request_id=request_2`, `choice=deny`; zero recovery
mutations, session creates or Stops. The receipt records every method/path/query,
synthetic submission body and SSE path. Read ordering/counts are observations,
not new protocol guarantees. Six root-window captures are hashed; four selected
final captures were loaded and inspected for disclosure focus, readable File/Web
categories, Review focus and compact Deny focus. No screenshot is committed.
Existing enlarged sidebar heading wrapping/truncation remains outside this slice.

## Reproduction, source and teardown

For the current runner, first set `WING_LINUX_DEPENDENCY_PREFIX` to a reviewed
user-owned **usr directory** as described in the
[qualification prerequisites](linux-qualification-driver.md). Retain the allocated
`AUTOWORK_PORT_BASE`; no personal endpoint or credential is accepted.

```sh
export PATH="$AUTOWORK_CACHE/flutter-3.44.2/bin:$PATH"
export PUB_CACHE="$AUTOWORK_CACHE/dart-pub-3.12.2"
flutter pub get --offline --enforce-lockfile
python3 -B integration_test/run_linux_transcript_keyboard.py
```

The current runner freezes present Wing source into an owned app copy and copies
SDK/packages and the explicit native prefix. It does not load historical helper
or application code from Git objects. No system install or missing-prerequisite
network fallback is offered. Source/configuration inputs are captured and checked
for drift. The retained execution and hashes below are historical evidence, not a
native rerun of this offline-tested portability change.

Final evidence is `$TMPDIR/transcript-keyboard-vlssiz96/`; native execution took
42.047 seconds, exit 0. Source manifest SHA-256:
`ce2e0f6a6451fdcbb31ceb020e818cf9f88de786408cf1e5a4565ad1a30f85bd`.
The linked JSON retains selected source hashes, exact requests, binary hash,
GTK PID/start ticks, driver ownership and teardown verdicts.

That historical execution loaded the authenticated-display/process helper from
Git revision `894439b76c889fed45f3c4d57b73086f1e18d479` and checked correct versus
missing/wrong Xauthority. The current runner instead uses the checked-in owned-
process helper and `xvfb-run` private authentication with TCP listening disabled;
no equivalent new native observation is inferred. HOME/XDG are isolated and
inherited display/DBus/credentials are absent. Terminal cleanup is recorded on
success and failure, and incomplete teardown preserves owned state. The VM
service still uses allocated `AUTOWORK_PORT_BASE` with DDS disabled.

Keys use `WidgetTester.sendKeyEvent` through Flutter focus in an actual GTK
process, not OS keyboard injection. Adaptive sizing uses `setSurfaceSize` plus a
matching LayoutBuilder-derived MediaQuery, not physical window resizing or OS
scaling. The Linux integration-test plugin is absent; `integrationDriver`
collects results successfully while Flutter prints its standard plugin warning.

## Final checks and explicit limits

- Nearest approval/reconnect/owner tests: 21 passed. Exact selection is the review,
  dismissal and transcript-reconnect screen tests plus
  `test/core/hermes/channel/hermes_approval_settlement_owner_test.dart`.
- `flutter analyze --no-pub`: no issues.
- `dart format --output=none --set-exit-if-changed lib test integration_test`:
  621 files, zero changes.
- Required `flutter test --no-pub --concurrency=1 test/core/hermes/ test/features/hermes_chat/`:
  terminal aggregate 2,889 passed, 9 skipped, one untouched voice timing failure.
  `continuous voice re-arms after its capture window expires` passed its one
  isolated rerun. It is recorded as unrelated under the invocation's policy,
  **not** a clean all-green aggregate or a reason to change voice behavior.
- Full `flutter test --concurrency=1`: command limit at 1,770 seconds, exit 124;
  3,072 partial passes, no reported failures, no terminal aggregate. Recorded as
  an environment failure, never a full-suite pass.
- Fresh `flutter build web --release -t lib/main_e2e.dart`: passed. Existing
  Wasm/font warnings remain; JavaScript build only, no Wasm claim.
- Default `npm run web:e2e`: command limit at 900 seconds, exit 124. First six
  specs reached 79 terminal passes; live-provider case skipped intentionally.
  Smoke was partial and screenshot spec did not complete. No failed-test markers;
  owned server stopped and assigned ports were released. This environment failure
  is not a full-browser pass and was not repeatedly rerun.
- `npm audit`: zero vulnerabilities. `git diff --check`: clean.

Logs and terminal exit files remain under task `$TMPDIR`. Node 22.22.2, system
Chromium, Flutter 3.44.2/Dart 3.12.2 and Linux GTK were exercised. Relevant native
qualification is fresh; unrelated/environment exceptions do not become supported
platform claims or hide incomplete gates. The coordinator's verification remains
separate from this local commit.

Not checked or claimed: live Agent/provider/tools, process relaunch/restoration
(the separate `VERIFY-CHAT-TRANSCRIPT-NATIVE-RESTART` task), physical keyboard,
screen reader, Android/macOS/Windows, installed/personal state, packaging or release.
