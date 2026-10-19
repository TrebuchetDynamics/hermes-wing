# Native Linux mapped fixture qualification

Task: `PARITY-NATIVE-LINUX`. The [current receipt](native-linux-parity-receipts.json)
owns execution status, exact names, source/bundle fingerprints, exits and cleanup.
This is GTK debug source-run evidence with deterministic services—not Android
Maestro, full official Desktop parity, a signed package or live Agent/provider
qualification. No matrix row is closed by this receipt.

## Reconciled source

Baseline: `66939153b4d3e91796145009edb8b3de7ff1a247`. Only the native-owned delta
from historical commit `20552926` was recovered. Its earlier Chat/parser/SSH
assembly and historical runtime receipt were not imported. Current header, voice,
transcript and other merged fixes remain intact. The assigned baseline, not a
missing coordinator handoff, is the authority for this execution.

The one production correction is native Linux Escape during active Chat preedit:
return the event to GTK before Flutter's default dismissal consumes it. The
production-composer native case reproduces retained `u00e9` preedit without the
correction and checks exact text, collapsed composition and zero Send afterward.
This is not a synthetic cancellation or SDK patch. Other platform paths remain
unchanged; no other IME/backend is thereby qualified.

Existing native fixtures were reconciled without weakening their outcomes:
HTTP Stop targets the exact hit-testable composer key; persistence reads actual
FormField state and opens the current Settings Chat category before Voice; Linux
Local asserts Add Hermes and the selected Local choice rather than a phone page.
The approval/Deny/Stop case separately observes an absent composer while offline,
an enabled composer and actionable unsent draft after recovery, three submitted
turns, two approval decisions, one Stop and the same session. Fixture status
toggles are not a transport reconnect. Real HTTP/channel reconnect is separate.

## Bounded HD-* mapping

Reference: the [current matrix](../product/hermes-desktop-feature-matrix.md),
Agent snapshot `a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70`, Desktop tree
`cee4414aae0817b7ff45c76fbfd010dcd753ecf5`. This task does not execute that reference
or certify complete group fidelity. Each receipt names the actual scenario, not
merely a containing file. An unavailable-state success cannot close its positive
operation gap.

| Native scenario | Topic/subset | Explicit remaining gap |
| --- | --- | --- |
| Pagination/search/pin/delete and cancellation | HD-SEARCH loaded metadata/session management | Full transcript search, Command Center, complete fork/rename behavior |
| Exact text/Markdown clipboard | HD-EXPORT loaded transcript | Official full-history JSON and unfetched history |
| Legacy-input rejection/direct recovery | HD-ENTRY rejection only | Full welcome/install/guide hierarchy |
| Read-only gateway | HD-GATEWAY unavailable administration | Messaging/Webhooks, peer and service lifecycle remain unsupported |
| Provider/model conflict and grant revocation | HD-PROVIDER, HD-MODEL synthetic UI gates | Real advertised mutation contracts, OAuth, credentials and inference |
| Session/profile draft and deferred-picker ownership | HD-DRAFT, HD-ATTACH volatile drafts | Durable restart drafts, cross-host/native upload, actual picker permissions |
| Review/Deny/Stop/fresh Approve once/status recovery | HD-APPROVAL, HD-STOP fixture UI | Transport reconnect and authoritative Agent terminal cancellation |
| Attachment cancellation/type/size rejection and schedule read recovery | HD-ATTACH, HD-SCHEDULE | All official file types and schedule mutation/delivery/history |
| Light/dark screen tour | HD-SHELL smoke only | Cannot close actions, routes, visual fidelity or accessibility rows |
| X11 keyboard, GTK Unicode Chat preedit and window lifecycle | HD-NATIVE, HD-ACCESS bounded input | Wayland, all IMEs, other text fields/platforms and screen readers |
| Two-process preferences/UI readback | HD-SETTINGS; HD-SEARCH local preferences | Agent-owned Projects, full session-management parity or actual speech |

The broad HTTP target checks production channel behavior against an owned
synthetic HTTP server, including canonical history and repeated reconnect without
duplicate mutations. Separate native input/export targets use real X11 keys and
GTK choosers/save, exact saved bytes, cancel and changed-owner refusal. Do not
infer those native behaviors from injected picker/clipboard cases.

## Owned execution and reproducibility

Use Flutter 3.44.2 / Dart 3.12.2 and Node 22. Cached compatible Ubuntu Noble
libsecret/GStreamer/ORC development packages are extracted under a user-owned
prefix; installed runtime versions must be rechecked against the
[prerequisite procedure](native-relaunch-workflow.md#safe-user-space-prerequisites-and-reproduction).
No system package change, native plugin removal, Agent edit, personal runtime
operation, credential export or live provider spending is involved.

Each invocation owns HOME, XDG state/runtime, D-Bus, TMPDIR and an Xvfb display.
Only matching marked processes are signalled, via pidfds. Normal exit and SIGTERM
share ownership-checked cleanup. SIGTERM/outer timeout records exit 124, remaining
resources and state removal in an abort receipt; an internal deadline records 124
in its ordinary failed run receipt. Neither can become an aggregate pass. The
negative harness controls check actual timeout cleanup of a sleeping child and
private display-auth/state files, plus preservation of an unrelated fixture.

Fixture listeners use the assigned range: HTTP offsets 10/11, core listeners
20–79, and a temporary TCP port-zero allocator at 80–99 for Flutter internals.
Explicit out-of-range TCP binds fail closed. This is invocation instrumentation,
not replacement GTK/GStreamer libraries or a modified Flutter/Agent runtime.
Allocator source/binary and execution-tool hashes are retained with receipts.
Exact executed tool sources are archived inside the JSON, not relabeled as newer
bytes. A later harness-only shared-deadline pidfd-drain correction is separately
fingerprinted and regression-tested (one-at-a-time readiness, real signal/state
cleanup and unrelated-process preservation). The native code, builds and accept
policy are unchanged; the finalizer verifies that restriction and independently
reapplies the current policy to every retained native receipt.

Prepare a fresh, short, disk-backed `TMPDIR` (D-Bus Unix socket length matters),
the versioned caches/prefix and an allocated `AUTOWORK_PORT_BASE`. `env.sh` expects
`AUTOWORK_CACHE/flutter-3.44.2`, `node-22.22.2` and
`linux-dev-noble-20261007/root`; prepare those without changing the system runtime.
From Wing root:

```bash
mkdir "$TMPDIR/parity-native"
cp -R docs/quality/native-linux-parity-tools/. "$TMPDIR/parity-native/"
gcc -shared -fPIC -Wall -Werror -pthread \
  -o "$TMPDIR/parity-native/bounded_bind.so" \
  "$TMPDIR/parity-native/bounded_bind.c" -ldl
source "$TMPDIR/parity-native/env.sh"
python3 "$TMPDIR/parity-native/validate_native_harness.py"
status=0
timeout --signal=TERM --kill-after=15s 1770s \
  python3 "$TMPDIR/parity-native/run_native.py" \
  > "$TMPDIR/parity-native/native-execution.log" 2>&1 || status=$?
printf '%s\n' "$status" > "$TMPDIR/parity-native/native-execution.exit"
python3 docs/quality/native-linux-parity-tools/finalize_receipts.py
```

The driver runs `env -u DISPLAY bash scripts/run_linux_e2e.sh`, then every full
mapped name separately with `--plain-name` and JSON test events. It requires all
nine broad invocations (including both preferences phases), positive unskipped
counts, successful terminal events and exactly the requested named case/PID.
Zero/missing/skipped/wrong-case results cannot pass. Source and tool bytes must
remain unchanged. Do not run targets concurrently against one build tree.

## Current native result

The complete broad launcher passed nine target invocations / **59 unskipped case
executions**, including both preferences phases. Twenty separately named
compact/wide GTK launches each passed exactly their intended case with a distinct
native PID. These are **79 case executions**, not 79 distinct feature outcomes;
the named subset deliberately rechecks the broad Maestro cases. All recorded
process/display/state cleanup passed. All 883 source inputs stayed unchanged;
fixture runtime was Node v22.22.2. Exact identities are in the JSON receipt.

The task's full core-Hermes/Chat command passed **2,895 tests, nine skips** on an
owned detached scratch checkout with all 670 lib/test/integration source inputs
verified byte-identical. Its separate build tree avoided concurrent GTK build
writes; the fixed-port native transport target had already finished. This is
unit/widget evidence, not additional native-platform qualification.

## Supplemental browser disposition

The deterministic web build ran on the byte-identical source snapshot using Node
22.22.2 / system Chromium 152.0.7977.75. The default browser command passed 75
cases, then stopped on two unchanged `chat-tts.spec.mjs` assertions:
`Agent speech stops when starting a new session (390px)` and
`mobile Agent speech controls stay reachable`. Each also failed once in isolation
and on a clean detached baseline checkout. Both builds have byte-identical
`main.dart.js` (SHA-256 `880c24eb1a0644641f93da4d00978accc662a135b1f295b95e81ff15d7c74eef`).
These are unrelated failures, not native task blockers or passing browser cases.
Later default lifecycle/live-smoke/smoke/screenshot specs did not run after the
stop. No full browser-suite acceptance is claimed; no live URL/key was supplied.

## Evidence boundaries

The final whole-repository Flutter offline gate passed **4,050 tests, nine skips**
(`flutter test --no-pub --concurrency=1 --reporter expanded`, exit 0). Analysis
reported no issues; formatting checked 624 Dart files without changes. The task's
complete core-Hermes/Chat command, analysis, formatting and whitespace checks are
recorded separately from native results. Unchanged-test failures are
isolated/baseline-checked under the task policy; host/tool/time/package failures
are environment results, not fictional passing cases or product blockers.

Widths are Flutter view overrides inside real GTK processes, not physical device
or reference-visual acceptance. GTK Unicode cancellation qualifies only this Chat
composer through X11. No browser, Android, OS keyring, live authentication/SSH/
provider, physical microphone/acoustics, screen reader, signed installer or full
HD-* group is qualified. Unsupported operations remain gaps after read-only passes.
