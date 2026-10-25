# CLONE-03 local Settings round 4 implementation plan

Status: Accepted — delegated planner choice within the existing local CLONE-03
frontier, not whole Settings acceptance or qualification of PARITY.

**Goal:** Port the official install-local Chat Backdrop toggle and its working
bundled-image Chat consumer.

**Architecture:** Extend the existing Chat preference owner and Window layout
page. Compose a small decorative widget around the existing Chat pane, keeping
the foreground subtree stable across preference changes. Bundle the exact-pin
image with attribution; do not fetch artwork at runtime or add dependencies.

**Tech stack:** Flutter/Riverpod, SharedPreferences, bundled assets, ARB l10n.

**Spec:** [round-4 contract](../../tasks/items/LINUXQA-005-8d795764.md),
[accepted local frontier](../plans/2026-10-21-desktop-literal-clone.md#frontera-inmediata-decidida-por-el-planificador),
[literal presentation decision](../adr/product.md#literal-presentation--owner-decision-2026-10-24).

## Working checklist

- [x] Read Goal, Sources, Dependencies and finished density report in place.
- [x] Reconcile integrated source/tests, exact-pin controls and remaining proof.
- [x] Select one working local outcome, with complete bounded task and successor.
- [x] Fresh-context builder check; resolve evidence-answerable questions.
- [x] Check local links/source bindings, native task validation and whitespace.
- [x] Close round 4 manually and prepare the whole batch for one planning commit.

## Evidence reconciliation

Wing baseline: `a96abfc0bd68e3b02199193879c710da44857c74`.
Official execution pin: `14e1e43a23761b369641208e204365cd6cb9399d`.
The execution common directory's
`autowork-execution/slot-data/LINUXQA-004-5c6015fe/attempt-1/report.json`
was read in place. It names `3143c0f640bf914238222e6fdec7c2dfcbbb9166`,
confirmed an ancestor of this baseline, and records locked preparation, generated
l10n, formatting, analysis and **117 focused passes across 11 targets**.
Those are the worker's reported results, not new tests run by this planner.
The [density task](../../tasks/items/LINUXQA-004-5c6015fe.md) is already
coordinator-verified closed. Preserve its receipt and all historical/manual and
owner-deferred live/Files closures. The round-3
[implementation follow-through](plan-clone03-local-round3.md#implementation-follow-through--linuxqa-004-5c6015fe)
is now integrated, rather than merely a task-branch candidate; its original
reported test results and unrun qualification remain unchanged.

There is no slot-data directory/report for LINUXQA-005-8d795764. Neither this
planning ID nor the density attempt has a saved ledger-edit patch. No unrelated
patch is replayed. At inspection this planning task is the sole open record;
empty queue is not goal completion. Native store preparation reports prepare_api
4, READY and a task-reading authorized runner; unrelated legacy diagnostics are
not a mandate for a backlog sweep.

This isolated checkout has no `hermes-agent/`. As in round 3, inspect only the
existing read-only source clone's pinned objects, never user state or runtime:

```bash
GIT_NO_LAZY_FETCH=1 git -c gc.auto=0 -C "$HOME/.hermes/hermes-agent" show 14e1e43a23761b369641208e204365cd6cb9399d:apps/desktop/src/store/backdrop.ts
```

`D/` below means `apps/desktop/src/` at that exact pin; no fetch or repin.

## Source-bound comparison

| Outcome | Official evidence | Current Wing / disposition |
| --- | --- | --- |
| Theme, transcript scale, direction, reasoning, Message Bubble | `D/app/settings/settings-manifest.ts:70-73,116-138` | Delivered by `settings_screen.dart`, `chat_preferences_provider.dart`, theme owner and nearest Settings/mounted Chat tests; exclude duplicate work and preserve saved values. |
| Session List Density | `D/store/session-list-density.ts`; `D/app/settings/settings-manifest.ts:84-88` | Integrated `shell_preferences_provider.dart:55-140`, Window layout/field mappings, `shell_session_access.dart:519-702`; storage/routing tests in `session_list_density_settings_test.dart` and mounted row case in `app_shell_global_session_access_test.dart`. Do not reopen. |
| **Chat Backdrop** | `D/store/backdrop.ts:1-17`; `D/components/Backdrop.tsx:1-24`; `D/app/settings/appearance-settings.tsx:915-923`; `D/app/chat/index.tsx:748-760`; `D/styles.css:598-620` | No matching preference/control/bundled asset/Chat consumer. Existing Window layout can host it; `_buildChatPane` in `hermes_chat_layout.dart:1104-1264` owns a stable foreground conversation/composer. Select this one local outcome. |
| Asset and copy | `apps/desktop/public/ds-assets/filler-bg0.jpg`; root `LICENSE`; `D/i18n/en.ts` keys `backdropTitle`, `backdropDesc`; `D/app/settings/settings-manifest.ts:105` | Bundle exact bytes and full MIT notice; use **Chat Backdrop** / **The faint statue image behind the conversation.** Canonical field `appearance.backdrop`, existing Window layout page. |
| Intro Splash (not selected) | `D/store/intro-splash.ts`; `D/app/chat/intro-visibility.ts` and nearest test | Wing's `_buildTranscriptArea` returns no-session guidance for null active session and prompt suggestions for an empty active session (`hermes_chat_layout.dart:1520-1552`). These are not the source's fresh primary draft; do not relabel hiding suggestions as the full intro outcome. |
| Resume last session / fonts (not local substitutes) | `D/app/settings/appearance-settings.tsx:89-135`; round-3 font comparison | Resume uses backend `display.resume_last_session` and sparse config save, not a renderer bool. Chat Font is also profile-backed. Do not replace either with shadow local configuration. |
| In-App Tips / UI Scale (not selected) | `D/store/tips.ts` (`mirrorDisplayToggle`); `D/store/zoom.ts` | Tips mirrors Agent display configuration; zoom is main-process-owned IPC. Neither is a reason to invent local-only authority. |
| Other Chat display controls | `D/store/tool-view.ts`; round-3 comparison | Wing still presents redacted tool summaries (`hermes_chat_timeline.dart:690-788`), not a full technical payload/diff consumer. Do not add no-op switches or treat Markdown diff fences as file-edit diffs. |

The decorative source asset is 3,871,968 bytes, Git blob
`490969417318d35d4d4a9bd82c99beabd0d2fb39`, SHA-256
`3c112050e108ba0c98622443ede1dfafdfd97c8a823edc514d8894ef0447e9c2`.
The pinned root LICENSE is MIT, copyright 2025 Nous Research; no separate notice
was found in the pinned Desktop public tree. Preserve that full notice with the
copied asset. This is source/attribution inspection, not a new legal decision.

## Planner's calls and handoff

One preference/control/working decorative consumer is one reviewable outcome.
Splitting off the asset or a control-only switch would not produce an independently
useful feature. Expected paths cover existing preference, Settings and Chat
owners, a small widget, localization/generated outputs, bundled image/notice,
asset registration, two public regression seams and current route/evidence docs.
`pubspec.yaml` is explicitly a protected Touch, limited to registering one asset;
no dependency or lockfile change is needed. These are delegated engineering calls,
not new product acceptance or platform qualification.

### 1. RED — persistence and Settings routing

Add `chat backdrop persists locally without changing existing preferences` and
`chat backdrop field routes to Window layout without Agent calls` in
`test/features/settings/chat_backdrop_settings_test.dart`. Reuse the recording/
delayed-store pattern from `chat_user_bubble_settings_test.dart` and public
Settings/fake-channel harnesses; no real endpoints, credentials or private data.

Extend `WingChatPreferences` with `backdropEnabled`, default false, and controller
`setBackdropEnabled(bool enabled)` using new install-local `wing.chat.backdrop_enabled`.
Only stored boolean true enables it; absent, false and wrong-type values mean off.
Hydration must not normalize storage. Explicit off removes only this new key.
Retain new intent through late hydration, serialize saves, tolerate failed storage
and start no writes after disposal. Preserve every existing key/value and all other
fields through hydration/copyWith and other preference setters. Only this new field
is added; no migration or general preference-framework refactor.

On the existing Window layout page, place the localized toggle after density.
Bind `appearance.backdrop` in initial field routing and search-result routing,
labels and topics (`backdrop`, `background`, `statue`). Field wins over `page=theme`;
retain the navigation revision fence, aliases, parent/caret and cancel behavior.
Test 390/1280px, 200% text, keyboard/semantics and zero incidental Agent calls.
Do not add any other Window layout or native-window control.

### 2. GREEN — exact bundled art and decorative consumer

Copy the pinned image byte-for-byte into `assets/desktop/filler-bg0.jpg` using
read-only `git show`, register that exact asset in `pubspec.yaml`, and add
`assets/desktop/README.md` with original repository/path, execution pin, blob,
SHA-256 and full root MIT copyright/permission/warranty notice. No recompression,
new download, runtime URL, user-selected file or upstream modification.

Add `WingChatBackdrop` in
`lib/features/hermes_chat/widgets/chat_backdrop.dart` and import it from
`hermes_chat_screen.dart` (layout is a part of that library). Compose it only in
the existing connected Chat pane around `_buildChatPane`'s foreground, not the
application root, Settings, sidebar, connection form or restoration guidance.
Keep a stable foreground child/slot whether on or off: switching must never remount
composer, transcript, controller or action owners.

Follow the reference's static top-left statue treatment: clip to the pane, scale
the art to at least the pane width and approximately 160% viewport height, faint
opacity 0.025, light-mode inversion/dark-mode non-inversion and difference blending
against the Chat surface. Implement with Flutter-native compositing; never dim or
filter foreground text/controls. Treat the scoped pane rather than Electron's
window as the adaptive viewport and record that difference. Use a layout-derived
image decode-size hint so a large bundled image is not repeatedly decoded at full
resolution for a small pane. Off mounts no Image and does not request a decode;
normal Flutter caching suffices, with no extra global image state.

The decoration is excluded from semantics and pointer/focus traversal; no timer,
animation or interaction. Foreground text contrast and controls remain readable
and usable in both themes and at 200% text. A failed asset decode must leave the
foreground usable and be caught by the regression checks, not hidden as success.
Generate localization output from `lib/l10n/app_en.arb`, never hand-edit it.

### 3. Prove mounted behavior and run exact checks

Add `local chat backdrop changes decoration without changing chat ownership` in
`test/features/hermes_chat/screens/hermes_chat_backdrop_test.dart`, reusing
`hermes_chat_reasoning_preferences_test.dart`,
`hermes_chat_desktop_geometry_test.dart` and the deterministic FakeHermesChannel.
At 390/1280px and 200% text, light/dark: default/off has no image; on loads the
bundled asset with the specified clipped decorative treatment. Test that its
semantics tree adds no label/action and taps/keyboard still reach the unchanged
foreground. Record controller, focus, selected/composing draft, scroll position,
route and exact channel/session owner; toggle on/off while mounted and receive
loaded/streamed updates without remount, state loss, focus movement or incidental
reads/connects/creates/selects/sends/Stop/approval/model operations. Existing valid
foreground actions must still act exactly once; retain existing stale-owner and
approval/Stop guards. Check the asset's bytes/registration against the pinned
blob and notice, not only the existence of a switch.

Update the [route owner](../product/routes.md) for `appearance.backdrop` and this
document with actual offline checks and explicit unrun qualifications. Repair an
existing defect in the named paths if it blocks the required checks, without
weakening them. No coordinator receipt, external input, credentials or live target
is required. Implementation workers never edit tasks or BLOCKERS/CHANGELOG.
The saved task supplies exact formatting, analysis, focused and full-suite checks;
run focused checks while iterating and report preparation failures separately
from test results. The admitted worker contract reserves the unchanged full check
for the coordinator's merged-tree gate; workers do not run it.

**Pre-mortem / invariant:** delayed persistence must not erase a newer choice or
any unrelated preference (storage case); the art must not intercept input, add
screen-reader noise or reduce foreground contrast (mounted decoration case);
repaint must not remount Chat or revive stale actions (mounted identity assertions
plus existing owner/approval/Stop regressions). No Agent/domain authority changes.

## Batch and continuation

Building: [CLONE03BACKDROP-001-1b78232c](../../tasks/items/CLONE03BACKDROP-001-1b78232c.md).
It has no prerequisite task: its consumed Window layout, Chat and preference seams
are already integrated. Density's closed task is evidence, not an unlanded producer.
Do not add overlap/preferred-order dependencies or a fictitious shared resource.

Successor: [PLANCLONE03LOCAL-002-8e1848c3](../../tasks/items/PLANCLONE03LOCAL-002-8e1848c3.md),
**Plan round: 5 of 10**, depending on the only new building task above.
Close **LINUXQA-005-8d795764** manually in this same planning commit. Two new tasks
are below the eight-task cap, all under PARITY. Because there is supported building
work and 4 < 10, no stop question or Needs decision item is justified this round.

[PARITY](../../tasks/goals/PARITY.md) remains **partial**. Its
[source](../product/hermes-desktop-parity.md#reference-and-evidence-boundary)
withdraws earlier official-parity evidence. Full Settings tree/fields, other product
outcomes, matched exact-pin visual comparisons and Linux/Android/web/macOS/Windows
proof remain incomplete. Neither this local toggle nor historical closures settle
those gaps. Do not reopen owner-deferred live/Files work or mark the goal met.
The existing authorized runner may continue autonomously up to round 10; saving
this batch does not start it or dispatch work. Stop the chain by moving the open
planning task to Needs decision through native tasks place.

## Validation boundary

All behavior tests and implementation steps above are **proposed/unrun** by this
planning pass. Only read-only source inspection, builder review, scoped links/
source bindings, native ledger validation and whitespace checks apply here.
No Flutter/browser/native/device/Agent/provider execution or qualification, network
exercise, push or deployment is performed. Branch-local saving is not canonical
integration, publication, dispatch or platform/visual acceptance.

Fresh-context read-only builder review found **nothing important left**. It
confirmed exact asset bytes/notice, working local scope, stable mounted identity,
protected manifest coverage and the two-task chain. No new tasks can execute in
parallel: building is independent of unlanded work, while planning consumes its
finished implementation/evidence.

Executed validation: supplied CLI `tasks validate --worktree .` passes with
310 tasks, 36 goals, no drafts and three task records pending commit. Scoped
readback passes 10 local Markdown links/anchors, 10 pinned source ranges, exact
asset size/blob/SHA, current/future check-path bindings, manual closure provenance,
preserved original contract and the two-task PARITY chain. The initial source
readback found two citation end lines beyond EOF; they were corrected to 17/24
before the passing check. `docs.py check .` finds no role manifest and performs
no mapped-role checks; it does not replace scoped validation. `git diff --check`
passes. No behavior tests or platform journeys were executed in this pass.

## Implementation follow-through — CLONE03BACKDROP-001-1b78232c

Implemented on the isolated task branch from `5f82649add308b1699f57fd86ab9ebecada0697b`;
coordinator integration and qualification remain separate. The preceding validation
boundary describes the historical planning pass, not this implementation's checks.

- `WingChatPreferences.backdropEnabled` defaults off. Only stored boolean true
  enables it; hydration never writes. Explicit off removes only
  `wing.chat.backdrop_enabled`. Existing copy/hydration/serialized saves retain
  newer intent and unrelated values, including after storage failure/disposal.
- Window layout places localized **Chat Backdrop** after density. The canonical
  `appearance.backdrop` field outranks a conflicting page; search includes
  background/statue and retains cancellation/navigation-revision fences.
- `WingChatBackdrop` wraps only the connected Chat pane. Foreground occupies an
  unchanged slot while art is mounted only on. The bundled square image is
  top-left, clipped, at least pane-width and 160% pane-height, with a layout/DPR
  decode hint. Opacity is 0.025; light mode inverts, dark does not. Difference
  compositing uses the opaque Chat surface, never the foreground. The pane is
  the adaptive viewport rather than the entire Electron window. A local Material
  preserves empty-chat ListTile ink. There is no new Agent operation or image state.
- Exact bytes and the complete pinned MIT notice are bundled in
  [the artwork owner](../../assets/desktop/README.md); only that asset is registered.

### Offline evidence

Executed on the Linux host with Flutter 3.44.2's widget/test renderer, not a native
application or browser/device journey:

- `flutter pub get --enforce-lockfile`: pass; no lockfile/dependency changes.
- `flutter gen-l10n`: pass; generated localization outputs come from ARB.
- The task's exact seven-file `dart format --output=none --set-exit-if-changed`
  command: pass, zero changes.
- `autowork-run flutter analyze --no-pub`: pass, no issues.
- The following complete named-target check: **274 passed**, no failures/skips.

```bash
autowork-run timeout 900 flutter test --no-pub --concurrency=1 \
  test/features/settings/chat_backdrop_settings_test.dart \
  test/features/settings/session_list_density_settings_test.dart \
  test/features/settings/chat_user_bubble_settings_test.dart \
  test/features/settings/chat_text_direction_settings_test.dart \
  test/features/settings/chat_reasoning_settings_test.dart \
  test/features/settings/chat_text_scale_settings_test.dart \
  test/features/settings/settings_subpages_test.dart \
  test/features/settings/settings_search_test.dart \
  test/features/settings/settings_screen_test.dart \
  test/router/settings_routes_test.dart \
  test/router/chat_workspace_overlay_test.dart \
  test/features/hermes_chat/screens/hermes_chat_backdrop_test.dart \
  test/features/hermes_chat/screens/hermes_chat_desktop_geometry_test.dart \
  test/features/hermes_chat/screens/hermes_chat_reasoning_preferences_test.dart \
  test/features/hermes_chat/screens/hermes_chat_text_direction_test.dart \
  test/features/hermes_chat/screens/hermes_chat_session_mutation_owner_test.dart \
  test/shared/widgets/app_shell_global_session_access_test.dart
```

The two new Settings cases prove storage/type/default/removal, recreation,
late hydration, ordered delayed saves, failure/disposal, preservation through other
setters, deep-link precedence, search/cancel/stale results, keyboard and semantics
at 390/1280px and 200% text. The new mounted Chat case covers both themes at those
sizes/scales, actual bundled-image decoding, decorative treatment/exclusions,
controller/focus/selected-composing draft/transcript/scroll/route/channel/session
identity, loaded/streaming updates, zero incidental recorded operations and one
valid foreground Send. Existing stale-owner/approval/Stop checks are retained.
Initial RED runs found the missing preference API, Settings field and decoration.
The broader check exposed the ColoredBox/empty-prompt ink assertion; using Material
resolved it before the final passing check, without changing existing tests.

Exact Git blob/SHA-256 checks pass. Scoped readback verifies asset registration,
complete pinned MIT notice, local Markdown links/anchors and exact-pin source
bindings. `docs.py check .` reports no role manifest (no mapped-role validation);
scoped readback is the content/link check. `git diff --check` passes.

**Not run:** full serial suite (coordinator merged-tree gate), compiled web/browser,
native Linux/Android/macOS/Windows execution, physical-device/screen-reader/live
Agent/provider checks, and matched exact-pin visual comparisons. Widget evidence
does not qualify native/live/visual support, all Settings, CLONE-03 or PARITY.
No upstream runtime, network service, credentials, inference, publication or
owner-deferred live/Files work was exercised. Docs Sync scoped Maintain updates
this evidence owner, routes and artwork provenance; task/history ownership remains
with the coordinator and final docs closeout with the docs maintainer.
