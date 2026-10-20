# Compact Chat usability

## Scope

Preserve official Desktop's Chat-home hierarchy and one action/state owner
(`hermes-agent/apps/desktop/DESIGN.md`, Information architecture), adapting
presentation for touch rather than adding product capabilities.

- Below 600 logical pixels, keep secondary header actions in the existing named
  overflow menu, matching the compact shell breakpoint (previously 480).
- Compact composers retain attachment, draft dictation, secondary voice settings,
  Live voice and Send, without a second hands-free microphone or separate Live
  voice row. Draft dictation still requires explicit Send; Live voice retains its
  consent and interruption lifecycle. Stop remains pinned outside scrolling model
  metadata. Wide presentation is unchanged.
- Suppress the introductory voice-tip banner on phones. Voice actions remain
  discoverable by named controls and the existing secondary menu.
- No transport, authentication, capability, session ownership or mutation replay
  behavior changes.

## Verification

Flutter 3.44.9 / Dart 3.12.2 was selected explicitly; the documentation pin is
3.44.2, not available in the observed local SDK inventory. Offline enforced-lockfile
resolution passed with no dependency changes. Node 22.23.3 was used for Chromium.

- New compact-header/composer regressions failed on the original implementation at
  390/480/599 widths, then passed after the changes.
- `flutter analyze --no-pub`: passed.
- Changed-file `dart format --output=none --set-exit-if-changed`: passed.
- Focused `flutter test --no-pub --concurrency=1` union: 140 passed, covering compact
  geometry, 200% text, keyboard traversal, draft retention, session model selection,
  workspace close ownership, disconnect, draft dictation and Live voice lifecycle.
- Broader feature sweep initially reported 1,952 passes and five failures; all
  five affected cases were repaired and passed in the final focused union. A
  subsequent full feature attempt ended during Flutter listener cleanup with a
  missing temporary directory after 464 passes; its zero process exit does not
  establish full-suite completion. No full-suite pass is claimed.
- `flutter build web --release --no-pub -t lib/main_e2e.dart`: passed; existing TTS
  Wasm dry-run warnings remain, not Wasm qualification.
- Compiled Chromium `hermes-smoke.spec.mjs`: 8 passed using system Chromium.
- `flutter build apk --debug --no-pub --target-platform android-arm64 -t lib/main.dart`
  with `WING_ISOLATED_DEVICE_TEST=1`: passed. Existing secure-storage compile-SDK
  warning remains (plugin requests 37; build uses 36).
- Debug QA update installation was observed in Android package metadata. Captures
  did not establish loaded updated Chat: launch capture showed splash and later
  captures encountered other user applications. Device rendering, keyboard-open
  posture and physical voice remain unqualified. No private screenshots ship.

This receipt does not claim full Desktop parity, physical voice qualification,
60-fps performance or signed-distribution readiness.

## Android Chat touch polish — task-local candidate

Task: **ANDROID-CHAT-TOUCH-POLISH**, baseline `83fcbc03`. The retained tab
prerequisite is already integrated; its [workspace receipt](chat-session-workspace.md)
remains authoritative about unsupported native-serve tabs, including Android SSH.
This section qualifies only the bounded presentation changes below, not the
complete Android multi-session outcome or coordinator integration.

### Observed problems and changes

The [accepted UI Taste direction](../plans/2026-10-03-desktop-port-goal.md#ui-taste-chat-refinement)
and official [Desktop design contract at `158fd638`](https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/DESIGN.md)
are source references, not an executed Desktop screenshot comparison. Desktop
keeps Chat primary, overlays short-lived, hierarchy flat and focus intent-owned.
The read-only upstream checkout at that revision was inspected; it was not changed.

Matched production-widget baseline/candidate renders show:

- The profile picker's fixed heading/search/footer left its selected row clipped
  at 320×480/200% text with an IME inset. At 844×390/200%, fixed chrome overflowed.
  [ChatProfilePicker](../../lib/features/hermes_chat/widgets/chat_profile_picker.dart)
  now scrolls heading, search, selected identity, rows and Manage together.
  Manage follows the loaded rows rather than floating at the foot of a mostly
  empty sheet. This deliberate touch adaptation also works at wide sizes.
- Filtering/Clear keeps the focused search visible; only explicit row navigation
  reveals a row. Independent review caught an intermediate Clear regression;
  the matching-query/Clear bounds assertion reproduced it before correction.
- The [Sessions modal](../../lib/features/hermes_chat/screens/state/hermes_chat_connection.dart)
  previously extended its scrolling viewport to y=820 with a keyboard boundary
  of y=540. Its entire existing panel now excludes the IME through bottom padding.
  Both modal routes retain system safe areas, not just favorable button placement.

Theme/shared controls, typography/palettes, transcript/composer geometry, owner
fences, Agent calls, approvals, Stop and unsupported-operation behavior are
unchanged. No Bot inventory or transport success is fabricated. Search still uses
loaded inventory; opening either picker adds no Agent read or mutation.

### Source-bound visual evidence

The [focused public-widget target](../../test/features/hermes_chat/screens/android_chat_touch_layout_test.dart)
provides optional captures via `WING_TOUCH_CAPTURE=<task scratch>/candidate` and
`WING_TOUCH_FONT_ROOT=<Flutter SDK>/bin/cache/artifacts/material_fonts`.

- Matrix: 320×480, 390×844, 844×390 and 1280×900; default light/dark;
  normal/200% text; reduced motion; 24px top/bottom system padding; simulated
  140px IME on short surfaces and 280px otherwise.
- Each side has 161 PNGs: idle, multiline draft, switcher, no-match, revealed
  selected row, revealed Manage, streaming/tools, current approval, failure and
  disconnected states in all 16 combinations, plus the Sessions keyboard state.
- Scratch `baseline/`, `candidate/`, `comparison.png` and `visual-manifest.json`
  bind images to production/test/theme SHA-256 values. Baseline production is
  exactly `83fcbc03`; a scratch **capture-only** harness suppresses assertions to
  retain known broken renders. That process is not a passing test receipt.
  Candidate captures run the real assertions without suppression.
- Widget captures load SDK Roboto as the system-font substitute, including
  capture-only ListTile/Chip font resolution. All geometry/tokens remain
  production values. Insets are simulated reserved space, not a painted Android
  keyboard. These are isolated production Chat widgets, not full Android shells.
- Source-bound image review confirms removal of constrained-picker overflow and
  exposes the row/Manage through scrolling. Wide light/dark retain the same
  controls; approval/running/error states remain labeled and unchanged. Short
  200% layouts still require ordinary scrolling to read full cards; no action
  relies on hover, drag dismissal or color alone. This is not visual pre-approval
  or a general parity verdict.

### Fresh offline checks

Flutter 3.44.2 / Dart 3.12.2; Node 22.22.2; Linux widget runner and system Chromium.
No dependency/lockfile changes. Final results:

- `flutter pub get --offline --enforce-lockfile`: passed.
- `flutter test --no-pub test/features/hermes_chat/screens/android_chat_touch_layout_test.dart`:
  two focused scenarios passed. Profile coverage exercises all 16 combinations,
  48px/hit-testable rows and Manage, search visibility, nonzero browsed transcript
  offset, draft/selection and caller-focus retention on simulated platform Back,
  and zero incidental decisions/sends/Stop/profile selections.
- Nearest union (`flutter test --no-pub --concurrency=1`): **290 passed** across
  the touch target and existing composer/transcript/reasoning accessibility,
  profile/session picker, session workspace, width/mobile, approval dismissal,
  session-mutation owner and queued-dialog intent files. Existing keyboard,
  wide-layout, owner/race and replay assertions remain intact.
- Isolated negative controls detected removing Sessions keyboard padding
  (820 > 540) and profile route safe-area protection (sheet top 0 < 24).
  Both protections were restored and the focused target passed again.
- Changed-file formatting, `flutter analyze` and `git diff --check`: passed.
- `flutter build web --release -t lib/main_e2e.dart`: passed. Existing dependency
  Wasm/font warnings do not establish Wasm qualification.
- Fresh Chromium with `--retries=0`: **eight passed** — four rendered profile
  owner-switch/overlay-history cases at 390/1280px (idle and active run), two
  owner-bound workspace/draft/uncertain-Stop cases and two lifecycle cases
  (authoritative Stop; session search/bulk-selection without deletion).
  Commands use the existing `chat-workspace-overlay.spec.mjs` with
  `--grep 'Profiles rendered owner switch'`, then `chat-session-workspace.spec.mjs`
  and `hermes-lifecycle.spec.mjs`. Owned fixture ports were stopped afterward.

Independent final review is recorded with the task report. The full Flutter
suite is reserved for the runner's merged-tree gate, not claimed here.

### Pending Android/live qualification

Waydroid reports running, but IP is UNKNOWN and ADB lists no target. The bounded
shell probe fails with “needs root access”; no system escalation, container
restart or installation was attempted. Isolated Waydroid public-control,
real IME/Back, text-scaling and owner-switch journeys remain **pending live**.
TalkBack is **unverified**. Physical devices, live SSH/Agent/provider behavior,
secure storage and acoustic outcomes were not exercised. Browser widths and
simulated platform Back do not qualify Android input. Native-serve tabs and
cross-profile background streaming retain the workspace receipt's limitations.

Revisit this evidence when picker layout, focus/reveal behavior, insets, ownership
or shared theme/control geometry changes.
