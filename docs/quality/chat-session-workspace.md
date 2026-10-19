# Owner-safe conversation workspace

## Scope and authority

For advertised Agent API connections, the shared Chat screen retains up to 32
**visited conversation tabs** for this screen lifetime. The native-serve transport
is excluded until its exact session-switch lifecycle barrier is supported.
These are presentation identities, not another session inventory or run database. Each identity includes saved host (or direct origin), profile,
and exact Agent session ID. Draft text, attachment and text selection reuse the
bounded, process-local [composer store](../../lib/features/hermes_chat/composer/hermes_composer_draft_store.dart).
No credentials, transcripts or run state are persisted by the tab list.

Start with the [workspace composition](../../lib/features/hermes_chat/session/hermes_chat_session_workspace.dart),
[Chat screen](../../lib/features/hermes_chat/screens/hermes_chat_screen.dart), and
[existing directory restoration](../../lib/features/hermes_chat/gateways/hermes_gateway_directory.dart).
The [regression target](../../test/features/hermes_chat/screens/hermes_chat_session_workspace_test.dart)
is the public widget seam. Global session access and existing session CRUD remain
entry points; closing a tab does not delete its session or draft. Explicitly
reopening it through session access restores its presentation.

## Interaction and deliberate Desktop differences

Official reference: [Hermes Desktop at `158fd638da1629c8e62caf9ade1515d162def8ab`](https://github.com/NousResearch/hermes-agent/tree/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop).
Source inspection, not upstream runtime qualification:

- `src/app/contrib/controller.tsx:193–285` registers contributed split/group
  panes. `src/components/pane-shell/tree/model.ts:32–62` defines those groups.
  Wing intentionally uses one horizontally scrollable, touch-accessible session
  switcher, not a Desktop pane tree. A lone conversation exposes Close in the
  app bar instead of reserving another row.
- `src/sdk/index.ts:163–202` resolves the focused session's connection/profile,
  refusing ambiguous ownership. Wing's tab keys likewise never interpret a
  session ID independently of its owner.
- `src/app/hooks/use-keybinds.ts:214–225` and
  `src/components/pane-shell/tree/store.ts:510–585` route cycling by hovered,
  last-interacted/focused, then workspace group. Wing has one Chat workspace:
  Ctrl+Tab / Ctrl+Shift+Tab cycle its visited tabs; Ctrl+PageDown / Ctrl+PageUp
  provide browser-friendly alternatives. Ctrl/Command+1–9 selects by that same
  stable order (9 selects the last tab). Idle visited conversations now stay in
  this order, unlike Wing's former live-only chips.
- `src/app/chat/close-tab.ts:30–102` separates presentation close from Stop and
  respects focused surface precedence. Wing closes an idle current tab without
  deletion or an implicit New Session mutation. Running/uncertain tabs instead
  retain an explicit recovery dialog. **Stop and close** requires a captured
  interruption target, current exact advertised Stop/status authority, and
  authoritative confirmation before removal.
  Unsupported Stop stays explained, with no local-cancel substitute.
- `src/app/chat/session-tile-actions.ts:349–387` routes tile Stop through its
  captured session gateway; `src/app/session/hooks/use-prompt-actions/index.ts:686–765`
  uses the current runtime identity. Wing uses its existing interruption target
  (channel, connection generation, profile, session, stream generation, run).
  Cached composer Stop cannot resolve through a replacement conversation.

**Single-channel limitation:** Wing does not acquire Desktop's simultaneous
background-profile sockets here. Switching saved hosts/profiles reuses explicit
leave confirmation and exact directory restoration. It closes local streams,
not Agent-owned work. Dormant tabs must be reopened before close/control so
canonical state and exact authority can be checked. Advertised API same-owner
sessions retain existing independent streams and unread-completion indications;
background completion does not select a tab. Disconnected owners do not invent
run/approval state, and switching never replays approval responses or prompts. This is not
JSON-RPC adoption or a durable detached-run guarantee.

**Native-serve exclusion:** `_selectServeSession` currently retires the one native
lifecycle and loads REST history without a terminal/status barrier. History alone
cannot establish that submitted work is idle. This slice therefore hides its tab
strip, lone-tab Close and tab keyboard bindings when `isServeReadOnly` identifies
that transport, including after chat is deliberately enabled. Cached workspace
Open/Close callbacks also reject it synchronously. Existing native session access
is unchanged, not qualified as owner-safe multi-tab control. Native tabs, including
the Android SSH serve path, remain unsupported; no shadow run cache or new native
RPC contract was added. Revisit this exclusion only after exact lifecycle
restoration/reconciliation is verified.

Failed Stop keeps the tab and offers explicit reconnect; an acknowledgment alone
is not terminal confirmation. Reconciliation readiness changes do not invalidate
an otherwise unchanged close owner. Stop/status authority is checked again when
a retained action runs, not only when rendered. Real owner loss permanently
invalidates the dialog, including a same-frame roundtrip. Draft selection changes do not consume
failed-send restoration tokens; only substantive draft changes do. Owner changes
retire the old platform editing client before loading another draft, so late
IME/web editing callbacks cannot replace the new conversation's input. Explicit
desktop keyboard switching can then focus a fresh client for the chosen owner.

## Offline validation and limits

### Historical retained-candidate receipt

Recovered candidate on baseline `7bbd0cc1`: 10 focused workspace tests, the 198
required session-mutation/queued-dialog listener tests, and all 1,959 retained
Chat/router tests passed with terminal aggregates. The 31 matching channel Stop
contract tests also passed. Analysis, localization
generation, changed-file formatting and whitespace checks passed. The freshly
rebuilt default Chromium suite had 89 passes and one intentionally skipped
live-provider journey, without retries; the dedicated workspace journey passed
at both 390px and 1280px without retries. Flutter 3.44.2, Node.js 22.22.2 and
system Chromium were exercised on Linux. The web build retained existing
dependency WASM dry-run/font warnings; no WASM support is claimed.
Commands and final results are also recorded in the task report:

```sh
flutter gen-l10n
flutter test --no-pub --concurrency=1 test/features/hermes_chat/screens/hermes_chat_session_mutation_owner_test.dart test/features/hermes_chat/screens/hermes_chat_queued_dialog_intent_test.dart
flutter test --no-pub test/features/hermes_chat/screens/hermes_chat_session_workspace_test.dart
flutter analyze --no-pub
flutter test --no-pub --concurrency=1 test/features/hermes_chat/ test/router/
flutter test --no-pub test/core/hermes/channel/hermes_api_channel_test.dart --plain-name stop
flutter build web --release -t lib/main_e2e.dart
npm run web:e2e
```

The default browser runner stops its server on exit. For the dedicated journey,
start `node serve_web.mjs` separately with free `PORT`/`HERMES_E2E_PORT` values
and set matching `WING_APP_URL` before running:

```sh
npx playwright test --config=playwright.config.mjs playwright/tests/regression/chat-session-workspace.spec.mjs --retries=0
```

The [compiled fixture journey](../../playwright/tests/regression/chat-session-workspace.spec.mjs)
uses public connection, session, composer and close controls at 390/1280px,
keyboard tab switching, and deterministic Stop/status/history receipts. It checks
that the other conversation's draft/history is untouched, that unknown Stop
cannot silently close the target or resubmit its prompt, and that a second
explicit Stop closes only after exact terminal/status/history confirmation.
Fixture setup and the terminal-state gate do not call a live provider.

Fresh independent source-bound review traced owner isolation, drafts and
close/Stop, verified the native-serve unsafe-idle premise and the explicit
transport exclusion, and independently passed the focused workspace target.
Its retained-callback authority observation was corrected and independently
rechecked: removing exact status authority before a cached Stop action runs
causes no Stop dispatch. Earlier draft-generation and Stop-readiness regressions
remain covered. Stale platform editing callbacks cannot overwrite the replacement
tab. The browser journey re-enters the public editor to inspect its current value,
rather than trusting Flutter's unfocused semantic bridge. Existing compiled
overlay journeys also verified a compact composer accessible-name repair across
owner replacement at 200% text. Retained listener tests now match lazy SSH-controller
acquisition rather than expecting an unrelated extra observer; stale-owner,
cancellation, late-result and observer-release assertions remain. Browser smoke
and lifecycle journeys use the current public Sessions/Stop/model controls rather
than the retired active-session summary. Independent review is not native or live
acceptance. A direct workspace held-successful-Stop owner-roundtrip test remains
a coverage limit; the synchronous dialog fence was source-reviewed and retained
channel Stop-outcome roundtrip tests passed.

No Android device/emulator was attached (`adb devices` listed none). Isolated
Android public-control journeys remain pending, alongside native accessibility,
screen-reader and live Agent/transport qualification. Browser widths and Linux
widgets do not establish those results. Native-serve tabs and cross-owner
background streaming remain deliberate unsupported behavior, not unexecuted
passing claims. These checks were rerun on the recovered baseline rather than
reusing the held attempt's receipts; coordinator integration remains separate.

### Retained integration repair on `2ddbb51b`

This recovery reuses retained implementation `153226bf` rather than introducing
another tab system. The historical receipt above qualifies its named baseline
only; it is not acceptance for this combined candidate.

The unified compact/wide composer and current voice-mode mute/exit behavior stay
in place. The visual and semantic editor-name assertions run after explicit voice
exit, when that editor is available. Width-test registration is restored without
dropping standalone-rail or shell reading-space checks. Compact/enlarged-text
queued controls take precedence over introductory voice guidance, retaining the
original 200% queue-manager and no-exception assertions.

Cached Reconnect now rechecks the captured owner and pending state at invocation,
including same-frame owner roundtrips and a transition to native serve. Transcript
focus entry explicitly reveals its actual focused descendant in the reversed
list, preserving the whole-transcript keyboard/approval assertions. Overlay
teardown resumes only the Navigator's remembered focus when it is parked on the
root; it never targets a captured editor or displaces a live focused control.
The native editor hint and current composition remain unchanged. Browser fixtures
use the rendered Toolsets tab and profile search before selecting inventory.

That retained attempt did not complete its full gates before shared temporary
storage exhausted. Its reported 198 listener, 74 repair-focused and 11 workspace
passes qualify that candidate only, not a later baseline.

### Disk-backed qualification on `cd548599`

The inactive retained dirty candidate was recovered as an owned 30-file patch,
without restarting from the older implementation or importing coordinator files.
Dependency locks remain unchanged. All new check scratch uses an ignored,
disk-backed task directory; no shared RAM or another task's scratch was cleaned.

Independent source review found a cached composer Stop could revive after a
still-running A → B → A roundtrip. Its continuous presentation-owner epoch now
expires input on channel, connection, origin, directory contact, profile or session
loss, but not readiness-only changes. Invocation checks screen lifetime before
reading providers. The existing public regression covers the roundtrip, fresh
input after reconciliation readiness changes, and invocation after disposal.
Independent follow-up resolved that finding without another important blocker
and retraced the documented official Desktop callers at the named research pin.

The current full Chat/router command passed **1,995 cases** with a terminal
aggregate. Focused terminal receipts are 198 listener, 74 repair, 11 workspace,
128 neighboring UI/router, 31 channel Stop and 20 native-fixture cases. The current
release E2E web build succeeded; the two dedicated workspace journeys passed at
390/1280px without retries. Four rendered profile-switch/history journeys also
passed without retries using a settled public search-editor handoff and real
keyboard input; the filter result is asserted before choosing the profile.
The final rebuilt default browser gate passed **89 cases**, with one intentional
live-provider skip and no executed retries. All nine specification processes
reached terminal aggregates. The screenshot journey now follows the public
Connections section and destination before asserting the Connections screen;
no rendered outcome assertion was removed.

The full Chat/router execution captured runtime/test/browser overlay SHA-256
`13edf6680aa6ad2db798c79d65a580984ad28158f2e07678c66f2cca9369b1e3`.
Its `lib/` and `test/` overlay remains byte-identical; only the screenshot browser
journey changed afterward. The final browser-qualified overlay SHA-256 is
`be54d35f2f37887edc9838c9059090cd0deb4ebe3c377ba5ed3e14851c65043f`.
The runtime-code overlay SHA-256 remains
`ab066a7b4a1a7caafa159a803afa6c7c2340fe1ed645c8f322777054990c439d`,
matching the independently reviewed input. Both dependency lock hashes are
unchanged from the full-gate capture. These identify this baseline plus its
owned overlay, not a canonical integration receipt. Exact terminal commands,
artifact paths and the final local commit are recorded in the task report.

Native-serve tabs remain unavailable. Linux widgets and Chromium fixture journeys
do not qualify Android SSH, physical devices, native screen readers, platform IME,
speech hardware or live Agent/authentication/provider services. Those remain
separate pending qualification; no live provider spending was performed.

### Current recovery on `3d1102ee`

The retained `3b7871db` runtime/test/browser source applies without conflicts;
this baseline has no production/test/dependency-lock delta from its `cd548599`
parent. The later `d7952ec9` differs from that retained candidate only in docs
and coordinator metadata, which were not imported. Earlier branches and receipts
remain preserved; their gates are not acceptance for this recovery.

Fresh independent source review found retained tab Open/Close callbacks could
read a disposed WidgetRef after Chat unmount. Both entry points now reject an
unmounted screen before provider access. One focused public-widget regression
reproduced both errors before the correction and passes afterward. The workspace
target now passes **12 cases**, including the real native A → B → A exclusion.
The 198 listener and 74 layout/accessibility checks pass, as do 31 channel Stop
and 20 deterministic native-fixture checks. Format checks cover all 619 Dart files
with zero changes; analysis reports no issues. The current retained Chat/router
command reaches **1,996 passes**, exit 0, on the frozen corrected source.

The full offline `flutter test --concurrency=1` command also reached a terminal
aggregate, but is **not green**: 4,016 passed, 9 skipped, 3 failed. Its failures are
`plan_backlog_traceability_test.dart` (its uppercase-only task-ID matcher misses
the existing `DEV-001-c7` mapping for the Flutter MCP plan), `inventory_keyboard_navigation_test.dart` (compact Profiles
has no EditableText at the traversal assertion), and
`linux_profile_footer_native_runner_test.dart` (zero expected outline pixels).
Those observations are fresh, not the historical 44-listener failure inventory.
The task-specific stale-owner/cancellation/late-result/release and layout assertions
were retained; the remaining full-gate assertions and coordinator metadata were
not weakened or rewritten. The integration owner must reconcile those remaining gates.

Fresh web build/browser gates were not run after this full-gate blocker, and no
new commit, integration or Android/live acceptance is claimed. The current report
binds the corrected source and terminal logs under the assigned disk-backed task
scratch. Fixture ports were serialized in an unoccupied subrange of the assigned
range; an unrelated repository's listeners were left untouched.

Revisit this receipt when workspace ordering/lifetime, channel interruption,
draft generations, exact restoration, or upstream pane/keyboard/close semantics
change.
