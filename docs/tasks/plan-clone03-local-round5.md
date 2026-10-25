# CLONE-03 local Settings round 5 implementation plan

Status: Accepted — delegated planner choice within the existing local CLONE-03
frontier, not full Settings acceptance or PARITY qualification.

**Goal:** Port the official loaded-prompt conversation timeline fallback and its
working install-local Hide thread timeline bars setting.

**Architecture:** Reuse canonical loaded turns and the existing transcript viewport
controller, not a second history store or an indexed-history API. Add a small
presentation navigator around the existing transcript; preserve its mounted list,
composer and exact-owner fences. Settings extends the current preference owner.

**Tech stack:** Flutter/Riverpod, SharedPreferences, ARB localization.

**Spec:** [round-5 contract](../../tasks/items/PLANCLONE03LOCAL-002-8e1848c3.md),
[accepted local frontier](../plans/2026-10-21-desktop-literal-clone.md#frontera-inmediata-decidida-por-el-planificador),
[literal presentation decision](../adr/product.md#literal-presentation--owner-decision-2026-10-24).

## Working checklist

- [x] Read task, Goal, Sources, dependency and finished report in place.
- [x] Reconcile integrated consumers/tests and exact-pin source controls/asset.
- [x] Compare candidates; select one working official local fallback outcome.
- [x] Save the bounded building contract and round-6 continuation.
- [x] Fresh-context read-only builder check; settle evidence-answerable findings.
- [x] Validate local links/source bindings, native records and whitespace.
- [x] Close round 5 manually and prepare the whole batch for one planning commit.

Docs map: the accepted clone frontier owns admission; [round 4](plan-clone03-local-round4.md#implementation-follow-through--clone03backdrop-001-1b78232c)
owns Backdrop implementation evidence; this handoff owns the new researched
subset. No product implementation, backlog sweep, unrelated goal repair or new
execution authority is part of this planning pass.

## Evidence reconciliation

Wing baseline: `3e9ff40fc58ddafd410403075764a35b3f6d57d0`.
Official execution pin: `14e1e43a23761b369641208e204365cd6cb9399d`.
Read in place under the execution common directory:
`autowork-execution/slot-data/CLONE03BACKDROP-001-1b78232c/attempt-1/report.json`.
It names `089cbece146d787231739fe711196622a39f8360`, verified an ancestor of
this baseline. The [Backdrop record](../../tasks/items/CLONE03BACKDROP-001-1b78232c.md)
is already coordinator-verified closed; preserve its receipt and all historical,
manual and owner-deferred live/Files closures.

The worker report records locked preparation, generated l10n, seven-file formatting,
analysis and **274 passing tests across 17 named targets**, plus exact asset
blob/SHA and docs checks. These are attributed worker results, not tests repeated
by this planner. Native/device, screen-reader, live Agent/provider and matched
visual qualification remain unrun. Round 4's historical isolated-branch wording
is superseded by verified ancestry and current integrated consumers, not new
runtime evidence.

There is no slot-data directory/report for PLANCLONE03LOCAL-002-8e1848c3.
No ledger-edit patch exists under the Backdrop attempt; none for this planning
ID was supplied. No patch is replayed. The baseline's committed queue has only
this one open task. Native capability inspection reports prepare_api 4; read-only
preparation reports READY with an existing task-reading runner/coordinator lease.
That is not permission to dispatch work or repair unrelated legacy diagnostics.

This checkout has no `hermes-agent/`. Read the same existing source object store
as round 4, without executing Agent, inspecting user state, fetching or repinning:

```bash
GIT_NO_LAZY_FETCH=1 git -c gc.auto=0 -C "$HOME/.hermes/hermes-agent" show 14e1e43a23761b369641208e204365cd6cb9399d:apps/desktop/src/components/assistant-ui/thread/timeline.tsx
```

`D/` below means `apps/desktop/src/` at that exact pin. All selected timeline
source objects and nearest tests were readable. A broader pinned grep and a
separate `D/components/model-picker.tsx` read encountered a missing promised
object with lazy fetching disabled. No network retry was made; do not treat
that partial comparison as an exhaustive inventory or an upstream API-absence
claim. The actual Chat Font config owner below was read after a guessed
`D/store/chat-font.ts` path proved nonexistent.

## Source-bound comparison

| Outcome | Official evidence | Integrated Wing / disposition |
| --- | --- | --- |
| Theme, scale, direction, reasoning, Message Bubble | `D/app/settings/settings-manifest.ts:70-73,116-138`; round-2/3 comparisons | Current `settings_screen.dart`, `chat_preferences_provider.dart`, theme owner and nearest Settings/mounted Chat tests already implement these subsets. Prose/code directions, composer direction, reasoning disclosure and user-fill alpha have working consumers. Exclude duplicate work; full theme/catalog parity is not implied. |
| Session List Density | `D/store/session-list-density.ts`; manifest `:84-88` | `shell_preferences_provider.dart:51-117`, Settings row, `lib/features/hermes_chat/widgets/shell_session_access.dart:650-704`; storage/routing and mounted sidebar tests. Integrated, not an unlanded producer prerequisite. |
| Chat Backdrop | `D/store/backdrop.ts:1-17`; `D/components/Backdrop.tsx:1-24`; `D/app/settings/appearance-settings.tsx:915-923` | Current `backdropEnabled`/`setBackdropEnabled(bool)`, `appearance.backdrop`, `WingChatBackdrop` and the two Settings/mounted Chat regression seams are integrated. Exclude duplicate work. |
| Backdrop asset | `apps/desktop/public/ds-assets/filler-bg0.jpg`; root `LICENSE` | [Artwork owner](../../assets/desktop/README.md): blob `490969417318d35d4d4a9bd82c99beabd0d2fb39`, SHA-256 `3c112050e108ba0c98622443ede1dfafdfd97c8a823edc514d8894ef0447e9c2`, 3,871,968 bytes and full MIT notice. Decorative widget evidence is not visual/native qualification. |
| **Loaded-prompt timeline + hide preference** | `D/store/thread-timeline.ts:1-17`; manifest `:122-126`; `D/app/settings/appearance-settings.tsx:925-933`; `D/components/assistant-ui/thread/timeline.tsx:33-38,69-122,148-239`; `use-timeline-history.ts:57-59` | No rail/hide setting in Wing, but canonical `HermesChatTurn` IDs/text and `HermesTranscriptViewportController` already own loaded projection, bounded rows and measured restoration. The official no-index fallback is a working outcome, not an invented substitute. Select this one local consumer plus its control. |
| Intro Splash / Model Pricing | `D/app/chat/intro-visibility.ts:1-32`; `D/store/model-pricing.ts` | Wing's no-session guidance/empty active session are not a fresh primary draft. Its picker model carries names, not price metadata; pinned picker consumer unavailable locally. Neither is selected or simulated by a toggle. |
| Vibe Hearts / tips / tours / reactions | `D/components/chat/vibe-hearts.tsx`; `D/app/session/hooks/use-message-stream/gateway-event/message-stream.ts` reaction branch; `D/store/tips.ts`, `tours.ts`, `reactions-enabled.ts` | Hearts consume a core reaction event; the others mirror Agent display configuration. No local text-matching reaction detector, shadow config or new Agent operation is admitted. |
| Resume last session / fonts / native composition | `D/app/settings/appearance-settings.tsx:91-134`; `D/app/settings/chat-font-setting.tsx:24-116`; `D/store/zoom.ts`, `interface-mode.ts`, `tabstrip-prefs.ts`, `titlebar-app-actions.ts` | Backend config, main-process IPC or broader pane/chrome composition, not another boolean over Wing's sidebar. Exclude from this slice. |
| Technical tool payloads/diffs / embeds / Files / popout | `D/store/tool-view.ts`, `embed-consent.ts`; `D/app/settings/appearance-settings.tsx:955-976` | Current tool rows are redacted category/status summaries, not a full payload/diff consumer. Embeds reach third parties; Files retains its separate owner disposition; popout needs native-window behavior. Do not introduce any of these here. |

Current consumer/test seams inspected: `lib/features/settings/screens/settings_screen.dart`
field routing and local rows; both preference providers; `hermes_chat_layout.dart:1507-1584`;
`hermes_chat_timeline.dart:52-389`; `hermes_transcript_viewport.dart`; Chat lifecycle
refresh/owner binding; `chat_backdrop_settings_test.dart`, `hermes_chat_backdrop_test.dart`,
`session_list_density_settings_test.dart`, `hermes_transcript_viewport_test.dart` and
`hermes_chat_window_test.dart:245-335`. Existing tests are source evidence, not fresh
planning-pass results.

## Implementation handoff

Building record: [PARITYCONTINUE-001-421b2b55](../../tasks/items/PARITYCONTINUE-001-421b2b55.md).
Its provisional ID is retained after the fresh-reader correction below; its saved
contract is the implementation outcome, not an owner continuation question.
A local setting with no navigator would be fake support. A controller-only task
would not independently deliver this outcome, so storage/Settings/loaded navigation
and their tests stay together. No dependency is needed: all consumed seams are
integrated. Explicit Touches include the shared viewport/lifecycle and generated
l10n owners; no protected manifest, dependency or lockfile change is needed.

### 1. RED — install-local preference and Settings navigation

Add `thread timeline hiding persists without changing other preferences` and
`thread timeline field routes to Chat display without Agent calls` to
`test/features/settings/thread_timeline_settings_test.dart`, reusing the recording/
delayed-store and fake-channel patterns from `chat_backdrop_settings_test.dart`.
Extend `WingChatPreferences` with `hideThreadTimeline`, default false, and
`setHideThreadTimeline(bool hidden)`, new key `wing.chat.hide_thread_timeline`.
Only stored boolean true hides; absent/false/wrong-type stays visible. Hydration
never normalizes storage; choosing false removes only this key. Late hydration,
ordered saves, failed persistence/disposal, copyWith and other setters preserve
newer intent and every existing preference, including inert avatar records.

Place **Hide thread timeline bars** / **Hide the navigation bars along the right
edge of each conversation.** on existing Chat display after direction, before
reasoning (bubble remains before direction). Source copy: `D/i18n/en.ts:950-951`.
Canonical field `appearance.hide-thread-timeline` comes from the manifest; initial
field and search-result routing select Chat display even with conflicting
`page=theme`. Search includes thread/conversation/timeline/bars/rail/navigation/hide.
Retain aliases, caret/parent/breadcrumb, cancel and newer-navigation fences. Test
390/1280px, 200% text, keyboard/semantics and zero incidental Agent operations.
Generate l10n from ARB; never edit generated Dart by hand.

### 2. GREEN — working loaded-only navigation, not a new history authority

Add `HermesThreadTimeline` in `lib/features/hermes_chat/widgets/thread_timeline.dart`
and import it from `hermes_chat_screen.dart`. Compose it with `_HermesTranscriptList`
in `hermes_chat_timeline.dart`, not at the app root or over the composer/approvals.
Use `state.activeMessages`/the existing turns input; never retain a second canonical
inventory. Derive entries in canonical chronological order from nonempty text-kind
user turns with unique, nonblank Agent IDs belonging to the active session. Skip
assistant/system/tool/reasoning/attachment-only blank turns, duplicate IDs and
source-matching process notifications (`/^\[IMPORTANT: Background process [\s\S]*\]$/`).
Collapse whitespace, cap previews at 120 characters with ellipsis, and apply existing
Wing sensitive-text redaction before a preview/tooltip/semantic label. Keep previews
process-local; no logs, clipboard, prefs or diagnostics. Preserve exact transcript
and sent/copied bytes. Reuse `HermesTurnPresentationIdentity.uniqueIds` rather than
minting navigable IDs. Pure filtering/preview assertions belong in the focused
mounted test file; no speculative registry or framework.

Wide layout follows the source's right-edge short bars, active/hover emphasis and
preview tooltips, with keyboard ArrowUp/Down/Home/End and Enter/Space activation,
named navigation semantics/current entry, and a scrollable lazy rail. Fit decoration
within the existing transcript gutter, without obscuring text selection, scroll,
copy, approvals, error actions or the composer. Supply a named **Conversation
timeline** control opening a lazy list of full-size labeled prompt targets as the
accessible equivalent, including on compact layouts where tiny bars would not fit.
This is an explicit Flutter/touch adaptation of the same navigation outcome.
Hiding suppresses both navigation presentations, not the transcript or existing
Latest/reveal/load-earlier controls. Showing/hiding must not remount or reflow the
foreground, move its scroll offset or steal focus. Cancel returns to the invoking
control for the same owner; stale/closed owners must not receive focus or actions.

Extend the existing `HermesTranscriptViewportController` at its `explicitTarget`
seam: an explicit loaded unique prompt target selects a bounded window containing
that target (retain roughly the existing 100-turn budget), realizes lazy rows via
measured scrolling, then aligns the requested user row near the viewport top
(source 8px slack). Do not allocate all intervening rows or extrapolate a giant row's
height from maxScrollExtent. Keep current tool-group continuity and Latest/reset/
reading-anchor behavior. Targeting a loaded row never fetches history. Use stable
IDs, exact current owner/origin and generation, not list indices or a translated
button lookup. Latest, newer target, user scroll, hide, owner change, target removal/
duplicate, disposal and cancellation invalidate pending realization/animation.
Bound frame work and terminate missing-target attempts; never leave an endless
post-frame loop. Normal jump animation may use the source's 170ms ease-out; reduced
motion uses an immediate jump. No auto-scroll merely because a prompt streams in.

An explicit **Show earlier** timeline entry first reuses local reveal-earlier when
loaded turns are outside the render budget. Only when no local hidden turns remain
and existing `canLoadEarlierMessages` allows it may that explicit action call the
existing `onLoadEarlierMessages`/`channel.loadEarlierMessages()` once. Reuse existing
loading/disabled/error behavior and ownership gates; no auto-page loops, index probe,
new endpoint or new grant. Keep this fallback honest: it does not navigate unseen
indexed archive entries or claim indexed-history parity. The source itself retains
loaded navigation when its index fails (`use-timeline-history.ts:57-59`).

Minimal changes in `hermes_chat_lifecycle.dart` may be required: completion's
existing composer-focus scheduling already exempts reasoning disclosure; it must
also respect a keyboard-owned timeline. Same-owner loaded/streaming refresh must
not turn a pending explicit jump into an unrelated Latest jump or steal navigation
focus. Preserve all existing channel/Stop/approval/reconnect/submission behavior.
Repair an existing defect in named paths if it prevents required checks, without
weakening the oracle. No coordinator receipt, new credentials or live target is
needed; implementation workers never edit tasks/BLOCKERS/CHANGELOG.

### 3. Prove mounted behavior and bounded ownership

Add `loaded thread timeline navigates without changing chat ownership` to
`test/features/hermes_chat/screens/hermes_chat_thread_timeline_test.dart`. Reuse
`hermes_chat_window_test.dart`, `hermes_transcript_viewport_test.dart` and the
existing FakeHermesChannel; extend the fake only for a required deterministic
history/owner transition. At 390/1280px, 200% text, light/dark and reduced motion:

- Default-visible/hide/recreate, correct filtered order, bounded redacted previews,
  duplicate/blank IDs and source process-notification exclusion. No navigator for
  empty/non-user history. Test at least 10,000 loaded turns: mounted rows/rail or
  list targets stay bounded; actual first/middle/latest unique prompts can be
  reached outside the default window, including a very tall intervening row.
- Explicit loaded navigation shows the requested row, not a nearby guessed index;
  canonical state is unchanged and zero history/model/connect/create/select/send/
  Stop/approval calls occur. Show earlier locally reveals without a read; only an
  explicit eligible remote-earlier action invokes the existing fake read once.
  Pending/error cases do not loop or silently change session. Latest still returns
  to its bounded tail. Keep pre-existing row/anchor/virtualization checks unchanged.
- Capture controller/foreground element, selected/composing draft, focus, route,
  scroll and exact channel/profile/session. Preference changes and assistant stream/
  completion preserve these; no automatic focus steal while operating the timeline.
  Stale target/owner switch, duplicate or removed target, hide/dispose, new jump and
  user scroll cancel pending work. Keyboard/semantics/full-size equivalents work
  without hover, color or precise pointers. Existing valid Send/Stop/approval actions
  still act exactly once; reuse existing guards rather than duplicate every test.

Update [routes](../product/routes.md) for the field and actual loaded-only consumer,
and this handoff with exact executed offline checks plus explicit unrun/indexed/
native/live/visual limits. Run the saved task's formatting, analysis and focused
checks while iterating; its unchanged full check belongs to the runner's merged-tree
gate, not a duplicate worker invocation. Proposed tests/checks above are **unrun**
by this planner.

**Pre-mortem / invariant:** persistence cannot erase newer intent or other saved
values (Settings case); lazy jumps cannot allocate all history, land on duplicate
IDs, or affect another owner (mounted case plus existing viewport/window guards);
stream completion, hide or reduced motion cannot hijack focus or break input
(mounted keyboard/identity assertions). No Agent state or authority changes.

## Batch and continuation

One building task: **PARITYCONTINUE-001-421b2b55**, PARITY, Next, no Dependencies or
shared resources. One successor: **PLANCLONE03LOCAL-003-5699d676**, PARITY, Next,
**Plan round: 6 of 10**, depending on that entire new building batch. Two new tasks
total, below the eight-task cap; no overlap-only dependency or priority promotion.
Close **PLANCLONE03LOCAL-002-8e1848c3** manually in this same planning commit, not
with a receipt or coordinator_verified claim. Original Scope/Acceptance/Checks/
Dependencies and exclusions remain intact.

Because new building work exists and 5 < 10, no stopping question or Needs decision
item is justified. Fresh-reader review caught that the initial stopping proposal
overlooked the source's no-index fallback. The planner reread its derivation/reveal/
rail sources and current viewport/window tests; this complete fallback requires
no new operation. The provisional continuation record is revised before its first
commit; no existing accepted owner question or task closure is overwritten.

[PARITY](../../tasks/goals/PARITY.md) stays **partial**. Its source withdraws older
official parity claims. Full Settings tree/fields, other product outcomes, indexed
archive navigation, matched exact-pin visuals and Linux/Android/web/macOS/Windows
proof remain incomplete. No old deferred live/Files task is reopened or qualified.
The existing authorized runner can continue the chain autonomously to round 10;
saving this batch neither starts it nor dispatches work. Stop by moving the open
successor planning task to Needs decision through native tasks place.

## Validation boundary

Only fresh-reader review, scoped local links/source bindings, Backdrop asset
identity, native task validation and whitespace apply to this planning pass.
No Flutter/browser/native/device/Agent/provider or matched visual journey is run.
Branch-local saving is not canonical integration, publication or feature acceptance.

Fresh-context read-only builder review of the corrected saved batch found
**nothing important left**. It confirmed the complete official loaded-only
fallback, bounded target/ownership/focus oracles and the two-task dependency chain.
Building is independent of unlanded work; its successor consumes its finished
report and cannot execute in parallel with it. No worker was dispatched.

Executed on the Linux host: supplied release `ca5765d0` native
`tasks validate --worktree .` and the original contract's `cd24b45b` validator both
pass: 312 tasks, 36 goals, no drafts, three task records pending this planning
commit. Scoped Python readback passes 18 local Markdown links/source anchors,
19 readable pinned source bindings, five critical fallback/reveal/rail contracts,
exact Backdrop bytes/blob/SHA, named current/future Touches/check paths, unchanged
original contract/goal/Backdrop/BLOCKERS, manual closure, the round-6 chain and
readback byte stability. Initial readback incorrectly retried the explicitly
unavailable picker object; it now classifies that known gap without fetching.
It also caught an Intro visibility citation ending one line past EOF; corrected
to line 32 before the passing readback. Neither changed implementation or checks.
`git diff --check` passes. The temporary validator is not a product artifact.
No application platform, behavior test or matched visual comparison was exercised
**by the planning pass**. The implementation evidence below is separate.

## Implementation follow-through — PARITYCONTINUE-001-421b2b55

Implemented on the isolated task branch from Wing baseline
`101a2ad990612c791716b7f3e2367938e512a8a0`, against the unchanged official pin
`14e1e43a23761b369641208e204365cd6cb9399d`. This is worker offline evidence,
not coordinator integration, full Settings acceptance or PARITY qualification.

- Added default-visible `hideThreadTimeline` / `setHideThreadTimeline(bool)`.
  Only boolean true hides; false removes only `wing.chat.hide_thread_timeline`.
  Hydration, ordered saves, failures, disposal and other saved appearance values
  retain the existing preference owner's fences.
- Added the canonical `appearance.hide-thread-timeline` field after direction in
  Chat display, including search and conflicting-page/cancel/newer-intent routing.
- Added a lazy right-edge loaded-prompt rail and a full-size inline
  **Conversation timeline** list for keyboard/touch/semantics, also at compact
  widths. It occupies the transcript only, not the composer or another route.
  Space is reserved only for real loaded prompts, independently of hide/show:
  the existing reveal/Latest header is shared, not duplicated. Without that
  header, roomy viewports reserve 48px above the transcript; below 112px available
  height a side lane leaves transcript height intact. No empty-timeline header
  steals space from approval/error controls. Rail hit regions fit the existing
  12/24px gutters, start below the opener and are omitted below 112px height.
  The open list isolates covered transcript focus/semantics and uses closed-loop
  keyboard traversal; cancel restores the invoking control. Previews are redacted,
  whitespace-collapsed,
  capped at 120 characters and process-local. Pointer paint and assistant deltas
  reuse the derived previews rather than re-redacting all prompts.
- Explicit loaded jumps select approximately 100 turns around a unique prompt,
  realize lazy rows using measured geometry, and align with 8px slack where the
  natural scroll bounds permit. The newest prompt clamps at Latest; it does not
  fabricate blank transcript history to force a top alignment. Jumps are immediate,
  including reduced motion; completion does not steal timeline keyboard focus.
  Ambiguous boundary rows cannot make a valid jump fall back to the tail.
- New jump, scroll, hide, changed/removed/duplicate target, channel/origin/profile/
  session change and disposal invalidate pending work. Realization is capped at
  104 frame steps. Exact channel identity now participates in viewport ownership.
  Explicit **Show earlier** reveals the local window first; only then can the
  existing eligible history callback run. No index, endpoint, configuration write,
  automatic pagination or second canonical history inventory was introduced.

### Offline checks and regression scope

Linux-host Flutter widget/unit tests, not a launched native application or browser.
The named Settings cases cover defaults/wrong types, recreation, late intent,
ordered failure/disposal, preserved preferences, canonical routing/search,
keyboard/semantics at 390/1280px and 200% text, with no incidental Agent calls.
The single mounted timeline case covers filtering, bounded redacted labels,
10,000 loaded turns, first/middle/latest targets, a tall lazy row, an ambiguous
window boundary, lazy rail/list bounds, Tab → ArrowDown → Enter, 24-turn
opener/rail non-overlap at 390/600/719/1280px and an 800×80 constrained
opener-activation case, forward/backward traversal, covered-transcript semantics
exclusion, cancel and
hide/show active-marker restoration, light/wide and dark/compact presentation,
reduced motion, retained controller/foreground/draft selection/composition, stream
completion focus, exact replacement-channel/session ownership, Latest and explicit
local-before-remote earlier history. Existing viewport/window/approval/reconnect/
session-mutation guards remain in the affected run.

The retry reproduced both previously rejected integration cases unchanged:
`profile switcher stays operable above the keyboard at all sizes` and
`approval failures remain visible to the operator`. The earlier candidate's
unconditional 48px header reduced the short transcript below 64px and evicted a
pending approval from the lazy mounted range after a failed denial. Reserving space
only for loaded prompts, with a short-height side lane, repairs both. The Android
case then exposed active-marker measurement of an inactive lazy-row GlobalKey
during build; marker geometry is now coalesced after layout/unmounting. Both tests
remain unchanged and pass in the final affected run. The existing loaded-window
approval/error recovery case additionally prevents duplicating the reveal/Latest
header reservation; its oracle remains unchanged.

The added row exposed an existing reasoning Settings test's missing layout frame
after `ensureVisible`. It now waits for layout and asserts hit-testability before
tapping; no production behavior or oracle was weakened.

Executed commands (final candidate):

- `flutter pub get --enforce-lockfile`: pass; lockfile unchanged.
- `flutter gen-l10n`: pass; generated localization comes from English ARB.
- `dart format --output=none --set-exit-if-changed` on all task-named Dart paths
  plus the changed layout and two existing test helpers: pass.
- `flutter analyze --no-pub`: pass.
- The following exact affected run through `autowork-run timeout 1500`: **260 pass**.

```bash
flutter test --no-pub --concurrency=1 \
  test/features/settings/thread_timeline_settings_test.dart \
  test/features/hermes_chat/screens/hermes_chat_thread_timeline_test.dart \
  test/features/hermes_chat/presentation/hermes_transcript_viewport_test.dart \
  test/features/hermes_chat/screens/hermes_chat_window_test.dart \
  test/features/settings/chat_backdrop_settings_test.dart \
  test/features/settings/chat_user_bubble_settings_test.dart \
  test/features/settings/chat_text_direction_settings_test.dart \
  test/features/settings/chat_reasoning_settings_test.dart \
  test/features/settings/settings_subpages_test.dart \
  test/features/settings/settings_search_test.dart \
  test/features/settings/settings_screen_test.dart \
  test/router/settings_routes_test.dart \
  test/router/chat_workspace_overlay_test.dart \
  test/features/hermes_chat/screens/hermes_chat_backdrop_test.dart \
  test/features/hermes_chat/screens/hermes_chat_desktop_geometry_test.dart \
  test/features/hermes_chat/screens/hermes_chat_transcript_accessibility_test.dart \
  test/features/hermes_chat/screens/hermes_chat_transcript_reconnect_test.dart \
  test/features/hermes_chat/screens/hermes_chat_reasoning_preferences_test.dart \
  test/features/hermes_chat/screens/hermes_chat_session_mutation_owner_test.dart \
  test/features/hermes_chat/screens/android_chat_touch_layout_test.dart \
  test/features/hermes_chat/screens/hermes_chat_screen_auth_recovery_test.dart
```

Scoped Docs Sync Maintain updates this evidence owner and
[routes](../product/routes.md), leaving coordinator-owned tasks/history untouched.
Scoped Python readback passes **49 local Markdown links/anchors, 13 exact-pin
source bindings and nine critical source contracts**, documented test paths and
byte-stable readback, without fetching or repinning.
`docs.py stale .` / `docs.py check .` report no role manifest; dedicated scoped
readback supplies link/source checks rather than claiming manifest coverage.
Read-only `autowork tasks prepare --check .` reports READY/converted and
`autowork tasks validate --worktree .` passes (312 tasks, 36 goals, no drafts).
`git diff --check` passes. The unchanged full serial suite remains the runner's
merged-tree gate and was not repeated by this worker.

Independent read-only review identified and drove the boundary, keyboard and active
rail corrections above. Final focused follow-up reports those findings resolved,
with no important remaining issue identified; it does not replace the worker's
executed checks. Fixture results do not qualify indexed archive navigation,
matched exact-pin visuals, compiled browser behavior, real screen readers,
Linux/Android/web/macOS/Windows native execution or live Agent/provider use.
Those remain unrun/pending; this task does not reopen historical deferred closures.
The coordinator-owned round-6 continuation consumes this offline result after its
normal integration/review gates; this worker does not select or start it.
