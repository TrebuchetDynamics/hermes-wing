# CLONE-03 local Settings round 2 implementation plan

> For agentic workers: use test-driven-development and the repository's native
> isolated worker/review path for the implementation task. This planning pass
> neither implements nor dispatches it.

**Status:** Accepted — bounded delegated planner choice within existing CLONE-03
local-control scope, not owner acceptance of whole Settings or parity.

**Goal:** Add the official local Message Bubble transparency outcome, preserving
existing defaults, preferences and Chat ownership.

**Architecture:** Extend the existing Riverpod chat preference and Settings
master/detail; apply the preference only to user-turn fill in the mounted
timeline. No Agent operation, new backend or native window integration.

**Tech stack:** Flutter/Riverpod, SharedPreferences and generated ARB localization.

**Spec:** [current planning contract](../../tasks/items/PLAN-CLONE03-LOCAL-ROUND2.md),
[accepted local frontier](../plans/2026-10-21-desktop-literal-clone.md#frontera-inmediata-decidida-por-el-planificador)
and [literal presentation decision](../adr/product.md#literal-presentation--owner-decision-2026-10-24).

## Working checklist

- [x] Read task, Goal/Sources/Dependencies and finished batch reports.
- [x] Compare current callers/tests with the exact official pin; exclude duplicates.
- [x] Save one building task and required round-3 continuation through native tasks.
- [x] Fresh-reader builder check and resolve material questions.
- [x] Native-store validation, local links/source bindings and diff check.
- [x] Manual closure recorded; single planning commit prepared, without implementation.

## Evidence reconciliation

Baseline: Wing `d010234a`; official source:
`14e1e43a23761b369641208e204365cd6cb9399d`. Source reads used local
`git -c gc.auto=0 -C "$HOME/.hermes/hermes-agent" show PIN:path` only;
no fetch, checkout, repin, runtime or user-state access.

The execution common directory's
`autowork-execution/slot-data/CLONE03-LOCAL-NEXT/attempt-{1,2}/report.json`
was read in place. Attempt 1 (`3cbb8a13`) reports 192+28 focused passes and
an incomplete full check (exit 124), not a full-gate pass. Attempt 2
(`6d3b6b5e479e5b5e27f963337ca70fbab16c5831`) reports 243 deterministic cases
across 23 targets, analysis and JavaScript web compilation, with the full gate
reserved for the runner. That commit is an ancestor of this baseline.
The current [task](../../tasks/items/CLONE03-LOCAL-NEXT.md) is already
coordinator-verified closed; preserve its receipt and contract, not replay an old
candidate or synthesize another receipt. No slot/report exists for round 2 itself.

[Prior follow-through](plan-clone03-local-frontier.md#retry-reconciliation--c26b43ea)
already records direction-sensitive extent caching, Auto/LTR paragraph flow,
code-link focus semantics and corrected connection/reasoning fixtures.
Theme, saved text scale, Auto/RTL/LTR and reasoning collapse are delivered.
The only other open task at inspection is UI-DRIFT-REPAIR-001, a separate
connection/overlay fixture repair; it does not deliver Message Bubble.
No round-2 ledger-edit proposal was found; the two retained ledger-edit patches
found by name belong to other tasks and are not inputs to this planning trigger.

## Source-bound comparison

`D/` below means `apps/desktop/src/` at the exact pin above.

| Outcome | Official source | Wing evidence at planning / disposition |
| --- | --- | --- |
| Theme/text scale | `D/app/settings/settings-manifest.ts:70-73` | `settings_screen.dart` Theme/Typography and `chat_preferences_provider.dart:24-31,155-160`; existing theme/scale tests. Exclude delivered controls and larger font/theme catalogs. |
| Text direction/reasoning collapse | `D/app/settings/settings-manifest.ts:117-121,135-138` | `settings_screen.dart:87-88,233-247,728-785`, `chat_preferences_provider.dart:24-32,162-170`; direction/reasoning Settings and mounted-Chat tests. Exclude delivered controls. |
| **Message Bubble** | `D/app/settings/settings-manifest.ts:116`, `appearance-settings.tsx:362-387,877-894`, `i18n/en.ts:1007-1008` | Missing control/field/preference. `hermes_chat_timeline.dart:1121-1148` uses a fixed user fill with an independent border; it is a direct local consumer, not an Agent domain. Select this one outcome. |
| Value/default/persistence | `D/store/user-bubble-transparency.ts:4-9,17-39`; `apps/shared/src/translucency.ts` constants and `clampIntensity`; nearest upstream clamp tests `D/store/translucency.test.ts:67-76` | Reuse `chat_preferences_provider.dart:52-145` touched-field hydration/ordered saves. New install-local key, no migrations or other-key writes. There is no dedicated upstream user-bubble-transparency test at this pin; do not invent one. |
| Fill-only rendering | `D/styles.css:468-474`; `D/components/assistant-ui/thread/user-message.tsx:76-77` | Existing user fill alpha is multiplied, not the subtree or foreground; keep outline, geometry and assistant/error surfaces. `hermes_chat_desktop_geometry_test.dart:15-76` is the existing consumer seam. |
| Other Appearance rows | `D/app/settings/settings-manifest.ts:55-145` | Larger window/native, new interaction and other controls are not this batch. No empty tree branches, inline editor, native translucency, renderer overlay peeking or speculative work. |

The reference's caption is **Message Bubble**: “How see-through your own
messages are. Solid at 0; only the outline remains at 100.” Canonical field:
`appearance.user-bubble`, page `chat-display`.
Renderer overlay peeking is explicitly unported/unqualified here; the Flutter
adaptation preserves the control's local fill outcome, not Electron mechanics.

## Planner's calls and implementation steps

Selected [CLONE03BUBBLE-001-57d0863e](../../tasks/items/CLONE03BUBBLE-001-57d0863e.md).
This is one independently reviewable user outcome; a picker without its consumer
would be false support. Its nine-file write set contains three functional owners,
three localization inputs/outputs, two test seams and this evidence owner.
No speculative provider, storage service, dependency or new route is needed.

1. **RED:** add the task's named persistence/control case in
   `test/features/settings/chat_user_bubble_settings_test.dart`; run that target
   to demonstrate the missing outcome before implementation. Reuse the direction
   Settings test's deterministic provider/fake-channel patterns.
2. Add `userBubbleTransparency` and
   `setUserBubbleTransparency(double value)` to the existing preference owner.
   Store an integer under `wing.chat.user_bubble_transparency`. Missing,
   wrong-type or non-finite storage means 0; finite numeric values round then
   clamp to 0..100. Do not normalize storage during hydration. An explicit 0
   removes only this new key. This is the planner's defensive decoding choice
   for a new Wing key, not a legacy Desktop-storage migration.
3. Add only the named, localized step-1 percentage slider and
   `appearance.user-bubble` to the existing Chat display, field resolver/search
   maps. Reuse field precedence and navigation-revision fences. Test keyboard
   and semantics adjustment at 390/1280px, 200% text, search/cancel/stale result.
4. At the existing user-turn decoration, return the original theme fill exactly
   at 0; otherwise use `base.a * (1 - value / 100)` as its alpha. Never wrap
   content in Opacity. At 100 the outline remains; no text/action/border/error
   alpha change. No inline-edit surface exists in Wing; do not introduce one.
5. Extend `hermes_chat_desktop_geometry_test.dart` with the task's named mounted
   consumer case. Reuse the direction test's retained controller/focus/selection/
   composition and fake-channel call guards. Cover intermediate value and
   endpoints, light/dark themes and unchanged assistant/error surfaces.
6. Generate l10n from `app_en.arb`, run named-file format, analysis, the exact
   regression inventory and required checks in the task. Record actual results
   here. The unchanged full check remains required under current runner
   ownership; focused passes never substitute for it. Commit code/tests/docs
   coherently under the later worker contract, not during planning.

Rejected: repeat direction/reasoning (already delivered); port all Appearance
(too broad and includes native/new interactions); add only a slider (fake support);
implement native glass to preview the bubble (unnecessary new authority/scope).

### Review focus and pre-mortem

- Untouched/default storage: no eager write or migration; persistence case pins it.
- Malformed/non-finite/out-of-range input: safe bounded value, no storage rewrite
  until explicit choice; same focused case.
- Late hydration or rapid choice: newer value wins without clobbering saved
  scale/direction/reasoning/theme/avatar data; same persistence seam.
- Fill-only change: alpha must not fade text/actions/border or alter theme RGB,
  geometry or assistant/error surfaces; mounted consumer case.
- Focus/ownership drift: no controller replacement, navigation hijack or channel
  mutation; mounted consumer and Settings field/search cases plus existing guards.

**Invariant:** existing preference bytes/values, exact resource identity,
draft/focus and no-replay behavior survive; unsupported operations stay absent.

## Batch and continuation

- Building task: **CLONE03BUBBLE-001-57d0863e**, PARITY / Next, depends on the already-integrated
  CLONE03-LOCAL-NEXT preference/Settings producer, not on overlap or an owner input.
- Successor: **PLANCLONE03LOCAL-001-84ad1ad6**, PARITY / Next, kind plan,
  **Plan round: 3 of 10**, depends on **every new building task** (the one above).
- Current plan: PLAN-CLONE03-LOCAL-ROUND2, round 2 of 10; close manually in this
  same planning commit. This is not coordinator verification.
- Preserve UI-DRIFT-REPAIR-001 and the owner's Now order. Its shared Settings file
  is possible merge work, not a producer dependency. Shared-resource/protected-path
  and hot-file admission remain the scheduler's responsibility.

[PARITY](../../tasks/goals/PARITY.md) remains **partial**. Its source's historical
reference evidence is withdrawn; the accepted clone plan still requires the
remaining Settings tree/fields, other Desktop outcomes, paired visual comparisons
and Linux/Android/web/macOS/Windows-specific proof. Existing native/live closures
and owner deferrals remain untouched, not converted to qualification.
One new building outcome is supported and 2 < 10, so there is no stopping
condition and no invented owner-only question or Needs decision dependency.
With the existing authorized runner the chain may continue autonomously to round
10; saving this plan neither starts a runner nor dispatches a worker.
Stop it by moving **PLANCLONE03LOCAL-001-84ad1ad6** to Needs decision through native tasks place.

## Planning validation boundary

At planning, all new behavior tests/checks above were **proposed/unrun**. That
pass exercised source inspection, task consistency and documentation only. The
[implementation follow-through](#implementation-follow-through) records the later
worker's actual offline evidence separately from remaining qualification.

Fresh-context read-only builder review found **nothing important left** and
confirmed the control/consumer seam, bounded write set and round/dependency edge.
Its two notes were checked: the obsolete validator release no longer exists, so
the current planning record now names the supplied available CLI; overlay peeking
is renderer behavior, distinct from native translucency, and wording now says so.
No product contract or Acceptance was changed.

Executed: supplied CLI capabilities reports prepare_api 4; tasks prepare reports
READY with a current task-reading runner. The supplied CLI's
`tasks validate --worktree .` reports 306 tasks, 36 goals and no drafts.
The read-only Python consistency check passes 7 local links/anchors, 15 exact-pin
line bindings plus normalization semantics, manual closure provenance, preservation
of the original Scope/Acceptance/Dependencies/exclusions/order, and the two-task
PARITY round-3 chain. `git diff --check` passes. Branch-local saving is not
canonical integration, dispatch or goal/platform qualification; committed-store
selection is checked separately after the planning commit.

## Implementation follow-through

`CLONE03BUBBLE-001-57d0863e` implemented this bounded local outcome in
`6eabe961e7a7d63137d0efab0e539be730e94273`, now integrated and coordinator-verified
closed at the round-3 baseline `3eda8d50`. The check inventory below is the original
worker evidence, not a fresh run or platform qualification.
Appearance > Chat display now offers **Message Bubble**, a localized, named
0–100% slider with step-1 keyboard and semantics adjustment. Search and the
canonical `appearance.user-bubble` field open Chat display even when `page=theme`;
cancel and stale search results retain the existing navigation-revision fence.

`WingChatPreferences.userBubbleTransparency` stores an integer under
`wing.chat.user_bubble_transparency`. Missing, wrong-type and non-finite values
read as 0; finite numeric values round then clamp. Hydration writes nothing,
explicit 0 removes only this key, and early choices/ordered saves preserve the
existing scale, spellcheck, direction, reasoning, theme and retired-avatar records.
Only the user-turn fill's existing alpha is multiplied by `(1 - value / 100)`;
0 returns the original theme color exactly and 100 retains the outline. No
subtree opacity, Agent call, new owner, resource identity or draft mutation is added.

Executed offline with Flutter 3.44.2 / Dart 3.12.2 on the Linux host:

- `flutter pub get --enforce-lockfile` and `flutter gen-l10n`: passed; no manifest
  or lockfile changes, and localization outputs generated rather than hand-edited.
- The named persistence and field cases first failed because the slider was absent;
  the mounted consumer case first failed at 37 because the fill was unchanged.
  The final two focused files pass **7 cases**, including malformed storage,
  untouched hydration, delayed reads/writes, 390/1280px at 200% text, keyboard and
  exported semantics adjustment, and light/dark mounted draft/owner invariants.
- The task's exact 14-target regression inventory through `autowork-run timeout
  1200 flutter test --no-pub --concurrency=1`: **178 passed**, including existing
  direct-copy/context-menu, rich-transcript, field aliases, parent/caret,
  Settings overlay, direction and composer guards.
- Named-file formatting and `autowork-run timeout 1200 flutter analyze --no-pub`:
  passed. A deprecated test-only semantics API was replaced with the binding's
  public semantics-action entry point; no production gate was weakened.
- Scoped Docs Sync Maintain: document readback, local links/anchors, exact-pin
  source bindings, native task validation, repeat-pass byte stability and
  `git diff --check`: passed. No task records or shared history were edited.
- Fresh-context read-only review found no important correctness or acceptance gap.

These are deterministic tests, not browser UI, screen-reader runtime, native GTK,
Android, macOS/Windows, physical-input, live Agent/provider or paired Desktop visual
qualification. Renderer overlay peeking, native glass and an inline-edit composer
remain excluded and unqualified. The runner owns the unchanged full suite; focused
passes do not replace it. `PLANCLONE03LOCAL-001-84ad1ad6` is reconciled in the
[round-3 handoff](plan-clone03-local-round3.md#batch-and-continuation), which saves
the next local outcome and manually closes that planning activity without dispatch.
Whole Settings/CLONE-03/PARITY acceptance remains partial.
