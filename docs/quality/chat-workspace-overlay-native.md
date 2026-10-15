# Native Linux Chat workspace overlays

WING-TASK-408 remains in progress. This bounds production router/shell behavior
on the Linux GTK engine. The focus follow-through fixes chat-local return focus;
it does not complete Desktop parity or live daily-use acceptance.

## Exercised behavior

`integration_test/linux_chat_workspace_overlay_test.dart` now runs 36 journeys:
Settings and Profiles via shell and slash suggestions, Settings via Tab completion,
and Profiles via the profile picker's Manage action, at 390 and 1280 logical pixels.
Each is dismissed by
keyboard-activated Close, Escape or Flutter's `handlePopRoute` Back seam. Every
journey uses 200% Flutter text scaling. Rendered shell controls open the modal;
Close autofocus and Tab/Shift+Tab return are asserted before dismissal.

The original Chat state and composer controller must remain mounted. The exact
return URL (query and fragment included), unsent draft, session identity and
rendered synthetic transcript must survive. The existing fake channel must record
zero connect/disconnect, Send, Stop, session creation/selection or profile selection
calls, and the fake endpoint store must record zero saves. All 24 chat-local
journeys assert automatic composer focus return, without tapping Chat. Slash
commands intentionally consume their command text; shell and Manage preserve the
unsent draft. Shell journeys also assert automatic semantic focus return to the
originating control: compact More for Settings, compact Profiles, or the wide
Settings/Manage profiles control. No Tab, tap or focus request intervenes after
dismissal. `shell_focus_restored` records this assertion for those twelve journeys;
`composer_focus_restored: false` means composer return is not expected for shell
entry, not a failed focus assertion.

This uses the existing in-memory test channel and endpoint store, with mocked
preferences. It does **not** exercise HTTP/SSE or credentials. The separate
[browser receipt](chat-workspace-overlay-browser.md) covers synthetic HTTP/SSE
stream completion and same-endpoint/session replacement in compiled Chromium.
Neither receipt substitutes for actual Agent or provider qualification.

## Runner and checks

```bash
flutter pub get --offline --enforce-lockfile
flutter analyze --no-pub
flutter test --no-pub --concurrency=1 \
  test/router/chat_workspace_overlay_test.dart \
  test/integration/linux_chat_workspace_overlay_runner_test.dart
python3 -B integration_test/run_linux_chat_workspace_overlay.py
```

The runner reuses `run_linux_shell_compact_return.py`: frozen source and package
manifests, a private Flutter SDK/package layout, isolated HOME/XDG directories,
no inherited D-Bus, private copied native dependencies and Xvfb with TCP disabled.
It validates all 36 typed journey receipts, observes the actual app PID under
the test driver, hashes the executable and checks process-group teardown and
isolated-state removal. Its existing local prerequisite is the native dependency
bundle described by that shared runner; this is not a portable installer.

The initial Flutter 3.44.2/Dart 3.12.2 isolated GTK run passed twelve shell journeys.
The runner confirmed owned-process teardown and state removal. Analyzer and the
25 focused router/receipt tests passed. Locked offline package resolution passed.
The first analyzer attempt exposed an incorrect test-only state getter; it was
corrected to the existing `activeMessages` API before execution.

A native negative control changed only retained `push` to replacing `go` and
rebuilt the Linux app. The first compact Settings journey failed at the mounted
Chat assertion; subsequent journeys were not reached. Exact production source
was restored before the final native run. This detects workspace destruction,
not every possible focus or ownership bug.

## Chat-local focus follow-through

The expanded GTK run passed all 36 typed journeys on Flutter 3.44.2/Dart 3.12.2,
with owned-process teardown and isolated-state removal. The initial expanded run
failed at the first compact slash Settings return-focus assertion; the focused
widget regression reproduced the same defect before the fix. Chat-local callers
now provide the existing composer focus node to the shared overlay opener, which
awaits return and only requests focus while its originating Chat route is current
and mounted. No new provider, domain state or transport is involved.

The expanded harness initially exposed a receipt publication race: the observer
read a newly created empty file before JSON was written. The Dart test now writes
a sibling pending file and renames it atomically. That interrupted run remains
failed; only the subsequent complete run qualifies the matrix.

## Keyboard shell-entry follow-through

The twelve shell journeys now reach Settings and Profiles with Tab and activate
with Enter. Compact Settings first traverses More and then its Settings action.
The existing bounded shell traversal helper asserts semantic focus; the native
test also requires the target to intersect the viewport before activation. No
pointer click, programmatic focus or `ensureVisible` is used for shell entry.
Bootstrap and draft entry still use fixture setup and `enterText`; these are not
fully keyboard-only journeys.

On the isolated candidate based on `2494e135`, all 36 GTK journeys passed with
Flutter 3.44.2/Dart 3.12.2: twelve keyboard-shell and 24 retained chat-local cases.
The runner verified the app PID, typed receipts, unchanged frozen source and
dependency manifests, owned-process teardown and isolated-state removal.
Analyzer, locked offline dependency resolution and 28 focused router/receipt/shell
navigation tests passed. Independent read-only native-source review approved the
two changed test/runner files. Production code and dependencies are unchanged.

A rebuilt native negative control omitted Enter in the shell activation helper.
The first compact Settings journey failed because More never opened and its
Settings action was absent. The exact approved source was restored byte-for-byte;
the passing frozen-source receipt above remains bound to those restored bytes.
This detects missing activation, not every possible traversal or focus regression.

## Shell return-focus follow-through

On the isolated candidate based on `c7fd0340`, all 36 GTK journeys passed with
Flutter 3.44.2/Dart 3.12.2, including twelve shell return-focus assertions across
Close, Escape and framework Back. The typed receipt distinguishes shell focus
from composer focus. App PID, unchanged frozen source/dependency manifests,
owned-process teardown and isolated-state removal were verified. Analyzer, locked
offline dependency resolution and 28 focused router/receipt/shell tests passed.
Independent read-only native-source review approved the two changed test files.
No production fix was necessary; the existing navigator already restores focus.
A rebuilt native negative control explicitly requested composer focus after modal
dismissal. The first compact Settings/Close shell-focus assertion failed as
expected. Exact approved source was restored byte-for-byte; the passing frozen
source manifest matches the restored candidate. This checks focus theft, not
physical keyboard or screen-reader behavior.

## Shared browser-focus fix: GTK requalification

The shared overlay opener now seeds the caller-owned return focus before push
for browser history recovery, while preserving its mounted/current-route guard.
On source `285bec1c`, `python3 -B integration_test/run_linux_chat_workspace_overlay.py`
passed all 36 GTK journeys on Flutter 3.44.2/Dart 3.12.2. This rerun covers the
changed production focus path: twelve keyboard-shell return-focus cases and
24 chat-local slash, native Tab-completion and Manage cases, at both widths and
200% text, with zero fixture mutations. No native test or production code changed
in this requalification.

The retained runner receipt verifies all 800 frozen source inputs, dependency
manifests, app PID, process-group teardown and isolated-state removal. Locked
offline package resolution, analyzer and 30 focused router/receipt/shell-navigation
tests also passed. The runner's negative receipt self-check passed; the earlier
native workspace-destruction, missing-activation and focus-theft controls above
remain historical experiments, not new mutation runs for this source.

## Native production HTTP/SSE through Settings

The next WING-TASK-408 slice uses
`integration_test/linux_chat_workspace_stream_test.dart` with an ephemeral IPv4
loopback `HttpServer`, the unmodified default `HermesApiChannel`/`HermesApiClient`
and native HTTP transport. There is no injected transport or in-memory channel.
The fixture reuses the session-chat capability, history envelopes and
`assistant.delta` / `[DONE]` protocol from the existing channel regressions.
It advertises only session chat streaming and rejects unexpected requests or an
invalid/duplicate Send. Endpoint persistence and preferences remain test fakes;
no credential or personal Agent state is loaded.

Six GTK journeys cover Settings at 390/1280 logical pixels and 200% text with
keyboard-activated Close, Escape and framework `handlePopRoute` Back. Shell entry
uses Flutter pointer taps (compact More → Settings or wide Settings); this new
matrix does not claim keyboard-only entry. Each rendered Send starts one HTTP/SSE
request. A first flushed chunk is rendered in Chat before Settings opens; a second
is released and consumed only while Settings remains visible. The client must
still report streaming before terminal release. Completion then reconciles the
exact canonical assistant ID/text/status through HTTP history while the modal is
still open. This is progressive synthetic streaming, not a single terminal burst.
After dismissal the same mounted Chat/controller, next unsent draft, endpoint,
session and full return URL survive, with the final reply rendered. Each journey
requires exactly one Send, two history reads, zero unexpected requests and zero
endpoint saves.

This exposed a real completion-focus defect: Chat's nested `ModalRoute` remains
current beneath the root overlay. Scheduled completion focus could therefore move
to the hidden composer; Enter could send its retained draft instead of activating
Close, and Escape would not dismiss Settings. The shared scheduled-focus helper
now also requires the visible GoRouter location to be Chat. Its existing
mounted/current-route, owner and reasoning-disclosure guards remain intact, and
standalone widget hosts without GoRouter keep their existing behavior. Two new
router widget regressions failed before this three-line fix and pass afterward.
Native assertions check actual composer focus as well as Close semantics after
settling the completion frame, before any compensating input.

```bash
python3 -B integration_test/run_linux_chat_workspace_stream.py --self-check
python3 -B integration_test/run_linux_chat_workspace_stream.py
python3 -B integration_test/run_linux_chat_workspace_overlay.py
flutter analyze --no-pub
flutter test --no-pub --concurrency=1 \
  test/router/chat_workspace_overlay_test.dart \
  test/integration/linux_chat_workspace_overlay_runner_test.dart \
  test/core/hermes/client/platform/hermes_api_transport_io_test.dart \
  test/core/hermes/channel/hermes_api_channel_test.dart \
  test/features/hermes_chat/screens/hermes_chat_composer_focus_test.dart \
  test/features/hermes_chat/screens/hermes_chat_completion_focus_owner_test.dart \
  test/features/hermes_chat/screens/hermes_reasoning_disclosure_accessibility_test.dart \
  --reporter expanded
```

On the isolated candidate based on `97d1ae4f`, locked offline package resolution,
formatting, analyzer and all 401 focused tests passed. Flutter 3.44.2/Dart 3.12.2
passed the six streaming journeys and requalified the existing 36 in-memory GTK
journeys. Both runners verified the native PID, source/dependency identity,
process-group teardown and isolated-state removal. The streaming wrapper reuses
`run_linux_shell_compact_return.py` isolation, frozen source archives and atomic
receipt publication; malformed-receipt self-checks run through the existing Dart
runner-test target. It is an intentional separate native gate, not part of the
default browser suite.

Local receipts under `.task-evidence/` (not committed): streaming
`overlay-native-sse-408/native-4y9xsc1w/verification.json`, existing matrix
`overlay-native-408/native-hd6vtjin/verification.json`. Both source manifests hash
to `dcedc10819ad2b75f0377dc0a37272fa729749cf568c99a0c773cdb7cfa091f7`
and match all 802 current frozen inputs. Removing only the new visible-route guard
and rebuilding GTK failed the first compact completion-under-overlay focus
assertion (`overlay-native-sse-408/native-xkckttqo/native.log`). Exact source was
restored before both final passing GTK runs. This negative control detects the
reproduced focus theft, not arbitrary transport or ownership defects.

Initial harness attempts also failed: Send needed a render frame, next-draft
input needed explicit composer activation, an async server callback could not
use guarded widget expectations, and semantics disposal had to precede test-end
verification. An attempted reuse of the traversal helper's `pumpAndSettle` waited
until stream idle timeout; streaming now uses only bounded frame pumps. These
attempts remain failed receipts and do not qualify behavior.

## Native Profiles streaming follow-through

The same synthetic session-chat fixture now runs twelve GTK journeys:
Settings/Profiles × 390/1280 logical pixels × Close/Escape/framework Back, all at
200% text. Profiles opens through its rendered compact tab or wide manage action.
Both flushed chunks, streaming-before-release, canonical completion under the
modal, retained workspace/controller/draft/owner/URL, and completion focus checks
are unchanged. The receipt validator now requires each destination explicitly;
its malformed-proof self-check is exercised by the existing runner-test target.
There is no production code change or new dependency.

This deliberately qualifies retention beneath the capability-limited Profiles
surface only. The synthetic server advertises session chat, not profiles inventory;
this does not qualify populated Profiles, selecting a new profile or switching an
active run's owner. Planner's call: leave live qualification under the existing
PARITY-LIVE-WORKFLOW external gates and extend this independent WING-TASK-408 native
fixture rather than retry unavailable authentication or provider-budget contracts.

Commands executed on the candidate based on `ce51499c`:

```bash
flutter pub get --offline
python3 -B integration_test/run_linux_chat_workspace_stream.py --self-check
python3 -B integration_test/run_linux_chat_workspace_stream.py
flutter analyze --no-pub
flutter test --no-pub --concurrency=1 \
  test/router/chat_workspace_overlay_test.dart \
  test/integration/linux_chat_workspace_overlay_runner_test.dart --reporter expanded
```

All twelve native journeys, 30 focused tests, analysis and runner self-check passed.
Flutter 3.44.2/Dart 3.12.2 and the unchanged lockfile were used. The runner verified
native process identity, source/dependencies, teardown and isolated-state removal.
Local receipt: `overlay-native-profile-sse-408/native-g560b0oi/verification.json`
under `.task-evidence/`; source manifest SHA-256
`e5079c51dbde273f477c741a0fa447690f1914ef1fb0f751890f8e761e746847`.
The initial attempt failed before GTK launch because the fresh worktree lacked
package configuration; offline package resolution repaired it without lockfile
changes. That failed receipt remains retained, not reclassified as passed.

Independent native-source review approved Dart blob
`73080c8f52e2b896c190825ad5adb5f57dbd52cb` and runner blob
`7171f747b666980efa926ba1ff7c4db925532e91`, checked the production Profiles route
and shell callers, and reran the receipt self-check. No required fixes. The reviewer
did not run a second GTK gate. No new mutation control or full suite was run for
this matrix extension; the earlier focus-defect negative control remains historical
evidence, not a fresh Profiles-specific mutation run.

## Native populated Profiles and active-run replacement

The production HTTP/SSE fixture now advertises the existing synthetic profile-read
contract, including both required and granted `profiles:read` scopes and mandatory
query context. An explicit default-profile inventory bootstrap precedes UI input;
that deliberate read accounts for a third original-session history read. No Agent,
provider, credential, production code or dependency was changed.

Eighteen GTK journeys cover 390/1280 logical pixels and 200% text. Twelve retain
the existing Settings/Profiles completion matrix, now with populated Profiles;
the Profiles cases require the rendered Coding profile and its Chat action. Six
additional cases tap that rendered action while two progressive chunks have been
consumed and the original stream is still pending. The new profile/session and
canonical coding history must settle before the synthetic server closes its old
stream. Reopened Profiles and Close/Escape/framework Back must retain the new
owner, exact full Chat URL and same mounted workspace, exclude the old reply, and
issue only the original deliberate Send. Each requires exactly one replacement
history read, zero unexpected requests and zero endpoint saves. This does not
assert that the old draft belongs to the replacement profile.

Planner's call: reuse the existing WING-TASK-408 native fixture and leave the
already-separated PARITY-LIVE-WORKFLOW authentication/provider-ceiling gates open.
No live inference or repeated live preflight is needed for this bounded slice.

Executed checks: `flutter analyze --no-pub`; the same two-target focused
`flutter test --no-pub --concurrency=1` command above (30 passed); runner self-check;
and the isolated native runner (18 passed on Flutter 3.44.2/Dart 3.12.2).
The unchanged lockfile and native PID/source/dependency/teardown checks passed.
Source-bound local receipt: `overlay-native-profile-sse-408/native-4cpioeh_/verification.json`,
manifest SHA-256 `3aef8a9f1f6dfaaaf79d920f7944d289ff63f3b02563653cfe7c1e11161ec214`.
Independent native-source re-review approved Dart blob
`4d6a093fc2ed66e13696da24d8d3d59bddebe707` and runner blob
`6951560a3ce94af91424a91ae04de19aff7151c9` after the missing-scope fixture correction.

A temporary production mutation made Coding profile selection a no-op. The rebuilt
native test failed its exact replacement-owner barrier in
`overlay-native-profile-sse-408/native-hp28jkbo/native.log`; the production file was
restored byte-for-byte. Earlier harness failures retained missing advertised scopes,
a two-versus-three history-read expectation, and an offscreen tap before the scroll
frame settled. The final test settles scrolling and requires a hit-testable action;
no assertion or production guard was bypassed.

This qualifies new-owner retention after **server-side stream closure**, not Flutter
consumption of cancelled old terminal events, switch-back/detached recovery,
automatic focus after owner-changing actions, saved-secret isolation or live Agent.
The explicit replacement cancels its old client subscription. Physical keyboard,
OS resizing, Android, full-suite and fresh browser checks were not performed.

## Native saved-host replacement during streaming

The production HTTP/SSE matrix now includes three wide (1280 logical pixels,
200% text) saved-host replacement journeys, alongside the eighteen existing
Settings/Profiles journeys. Seeded empty-credential endpoints use distinct
synthetic loopback origins. The rendered original contact, Settings → Connections
→ replacement host → Connect chat controls select canonical replacement history
while the original server stream remains pending. Only then does the fixture
complete and read back the original reply. Reopened Settings and Close, Escape or
framework Back retain the replacement Chat/history without stale reply controls.
Only the original deliberate Send writes; the replacement server receives no
mutations, and endpoint storage receives no saves.

The journey reproduced an unbounded loading-list layout inside Connections' parent
scrollable. `WingSkeletonList` now shrink-wraps its bounded placeholder rows; the
new nested-scrollable regression failed before the fix. All five production callers
retain the same loading semantics and reduced-motion behavior.

Executed on Flutter 3.44.2/Dart 3.12.2:

```bash
flutter analyze --no-pub
dart format --output=none --set-exit-if-changed integration_test/linux_chat_workspace_stream_test.dart lib/shared/widgets/wing_skeleton.dart test/shared/widgets/wing_skeleton_test.dart
flutter test --no-pub --concurrency=1 test/shared/widgets/wing_skeleton_test.dart test/router/chat_workspace_overlay_test.dart test/integration/linux_chat_workspace_overlay_runner_test.dart --reporter expanded
python3 -B integration_test/run_linux_chat_workspace_stream.py
git diff --check
```

All 34 focused tests and 21 GTK journeys pass. Native receipt:
`overlay-native-connection-sse-408/native-zd900q3u/verification.json` under local
`.task-evidence/`; manifest SHA-256
`71343c6b7af8c032980dd22debec0073e0ad899afaaf999b7724db69f38483e9`.
All 802 frozen inputs match the candidate. The runner verifies native PID,
dependencies, process-group teardown and isolated-state removal. Earlier selector,
layout and interrupted attempts remain failed/unqualified receipts. Independent
native-source review approved all four changed implementation/test blobs and ran
the strict receipt self-check; it did not duplicate native execution.

Planner's call: keep the existing live authentication/provider-ceiling gates on
PARITY-LIVE-WORKFLOW and deliver this independent WING-TASK-408 slice. Compact
saved-contact Chat lacks shell navigation during streaming and hides local command
suggestions; no programmatic navigation substitutes for its unavailable controls.
Compact connection switching, saved-secret isolation, cancelled old terminal-event
consumption and detached recovery remain unqualified. The retained Chat assertion
concerns the replacement workspace across its reopened modal, not original workspace
identity across an explicit host change. No fresh browser/full-suite/device check
or live Agent inference was performed.

## Compact Settings during active saved-contact Chat

The existing Chat overflow menu now includes Settings, reusing the shared retained
workspace opener and composer return-focus guard. This restores a rendered compact
path while a saved-contact stream hides the normal shell navigation and local
command suggestions. It does not add a route, capability, Agent request or saved
state. Three router regressions cover menu Tab/Enter selection and automatic return
focus after Close, Escape and framework Back at 390 logical pixels and 200% text.
The menu is opened by pointer; these checks are not a wholly keyboard-only journey.

The production HTTP/SSE GTK matrix now passes all 24 journeys at 390/1280 logical
pixels and 200% text, including three newly enabled compact saved-host switches.
The replacement canonical history settles before original-server completion;
reopened Settings and each dismissal retain the new host without stale reply
controls, replacement writes or endpoint saves. Only each original deliberate
Send writes. The fixture uses distinct loopback origins and no saved credentials.

Executed on Flutter 3.44.2/Dart 3.12.2:

```bash
dart format --output=none --set-exit-if-changed lib/features/hermes_chat/screens/hermes_chat_screen.dart test/router/chat_workspace_overlay_test.dart integration_test/linux_chat_workspace_stream_test.dart
flutter analyze --no-pub
flutter test --no-pub --concurrency=1 test/router/chat_workspace_overlay_test.dart test/integration/linux_chat_workspace_overlay_runner_test.dart test/shared/widgets/wing_skeleton_test.dart test/features/hermes_chat/screens/hermes_chat_completion_focus_owner_test.dart test/features/hermes_chat/screens/hermes_chat_composer_focus_test.dart test/features/hermes_chat/screens/hermes_chat_saved_connection_workflows_test.dart test/features/hermes_chat/screens/hermes_chat_profile_switch_test.dart --reporter expanded
python3 -B integration_test/run_linux_chat_workspace_stream.py
```

All 77 focused tests pass. Native receipt:
`overlay-native-connection-sse-408/native-r0fmvhxx/verification.json` under local
`.task-evidence/`. The runner records frozen source/dependencies, native PID and
binary hash, and verifies process-group teardown and isolated-state removal.
Independent native-source review approved the four implementation/test blobs.
The rebuilt `lib/main_e2e.dart` also passes all 42 compiled Chromium overlay cases
with `--retries=0`, using the locked Playwright install and loopback-only fixture:

```bash
flutter build web --no-pub --release --no-wasm-dry-run -t lib/main_e2e.dart
node node_modules/@playwright/test/cli.js test --config=playwright.config.mjs playwright/tests/regression/chat-workspace-overlay.spec.mjs --retries=0
```

Earlier interrupted native attempts remain unqualified; a current test invocation
also named a nonexistent extra target and was corrected before the passing union.

Planner's call: adopt the idle unfinished compact candidate, preserve the existing
PARITY-LIVE-WORKFLOW authentication/provider-ceiling gates, and finish this bounded
WING-TASK-408 slice without restarting inference or changing original budgets.
Next: deterministic saved-secret isolation through explicit saved-host replacement.

## Remaining acceptance

Saved-secret isolation, cancelled old-terminal consumption and Android remain
unqualified. Native HTTP/SSE through Settings, populated Profiles and compact/wide
saved-host replacement is bounded to these synthetic session-chat matrices, not live Agent, provider inference,
authentication, saved secrets or detached-run persistence.
The separate browser receipt qualifies
its bounded shell focus, replacement-owner and late-completion cases; it is not
native evidence. The chat-local composer and GTK shell focus matrices are separate.
Surface size and input use Flutter integration seams, not physical window resizing,
an OS keyboard/IME, OS Back or screen-reader qualification.
No live Agent, provider inference, personal preferences, keyring or services were
used. The full Flutter and full browser suites were not rerun; focused router,
Chat-screen/shell and compiled overlay suites cover this change. See the separate
[browser receipt](chat-workspace-overlay-browser.md) for its distinct HTTP/SSE scope.
