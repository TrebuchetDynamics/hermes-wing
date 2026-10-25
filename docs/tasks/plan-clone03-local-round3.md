# CLONE-03 local Settings round 3 implementation plan

Status: Accepted — delegated planner choice inside the existing local CLONE-03
frontier, not owner acceptance of whole Settings or qualification of PARITY.

**Goal:** Port the official install-local Session List Density control and its
sidebar consumer, without introducing Agent operations or changing stored data.

**Architecture:** Reuse Settings master/detail, add one working Window layout
child, and add a density preference alongside the existing shell preference owner.
Only the non-full-panel `ShellSessionAccess` rows consume it. Do not change the
existing bool-valued `wingSidebarExpandedProvider` contract or the global session
panel, and do not create another session inventory or shell.

**Tech stack:** Flutter/Riverpod, SharedPreferences, generated ARB localization.

**Spec:** [round-3 contract](../../tasks/items/PLANCLONE03LOCAL-001-84ad1ad6.md),
[accepted local frontier](../plans/2026-10-21-desktop-literal-clone.md#frontera-inmediata-decidida-por-el-planificador),
[literal presentation decision](../adr/product.md#literal-presentation--owner-decision-2026-10-24).

## Working checklist

- [x] Read Goal, Sources, Dependencies and finished Message Bubble report in place.
- [x] Reconcile current code/tests, exact-pin sources and remaining goal proof.
- [x] Save one building task plus exactly one round-4 successor through native tasks.
- [x] Fresh-reader builder check; resolve material questions from evidence.
- [x] Validate native store, changed links/source bindings and whitespace.
- [x] Close round 3 manually; prepare the whole batch for one planning commit.

## Evidence reconciliation

Wing baseline: `3eda8d50`. Official execution pin:
`14e1e43a23761b369641208e204365cd6cb9399d` (not current remote HEAD).
The execution common directory's
`autowork-execution/slot-data/CLONE03BUBBLE-001-57d0863e/attempt-1/report.json`
was read in place. It names commit `6eabe961e7a7d63137d0efab0e539be730e94273`,
an ancestor of this baseline, and records locked preparation, generated l10n,
analysis, named-file formatting and **178 focused passes across 14 targets**.
The worker report leaves the full-suite gate to the runner and records native/device,
browser UI, runtime screen-reader and paired visual qualification as unrun.
The [building record](../../tasks/items/CLONE03BUBBLE-001-57d0863e.md) is already
coordinator-verified closed; preserve it and its receipt. Its
[follow-through](plan-clone03-local-round2.md#implementation-follow-through)
has been reconciled from pending integration to integrated using the ancestor
check/current closed record, without changing its original test results.
There is no slot-data directory/report for this round-3 planning ID, and no saved
ledger-edit patch for it or the Message Bubble task. No patch is being replayed.
At inspection round 3 is the only open task. Preserve all historical/manual and
owner-deferred live/Files closures; absence of open work is not goal completion.

Reference checkout discovery matters: this isolated worktree has no
`hermes-agent/`; the canonical reference's object at the execution hash cannot
resolve the pinned Settings path. The same existing read-only clone used by the
accepted round-2 plan resolves it. Reproduce source reads without fetch/checkout:

```bash
git -c gc.auto=0 -C "$HOME/.hermes/hermes-agent" show 14e1e43a23761b369641208e204365cd6cb9399d:apps/desktop/src/store/session-list-density.ts
```

Read source objects and repository instructions only, never Agent user state or
runtime. `D/` below means `apps/desktop/src/` at that exact pin.

## Source-bound comparison

| Outcome | Official source | Current Wing evidence / disposition |
| --- | --- | --- |
| Theme, text scale, direction, reasoning, Message Bubble | `D/app/settings/settings-manifest.ts:70-73,116-121,135-138` | `settings_screen.dart:75-97,232-270,735-835`; `chat_preferences_provider.dart:19-65,172-208`; scale/direction/reasoning/bubble Settings tests and mounted Chat tests. Delivered; do not duplicate or alter saved values. |
| **Session List Density** | `D/app/settings/settings-manifest.ts:84-88`; `appearance-settings.tsx:506-510,733-749`; `i18n/en.ts:957-961` | No density control/preference. `ShellSessionAccess._sessionRow` at `shell_session_access.dart:636-714` renders only the loaded title with independent pin control. Select this one working local outcome. |
| Local persistence/default | `D/store/session-list-density.ts:1-18`; nearest upstream `session-list-density.test.ts` | Compact/Comfortable/Detailed, default and invalid values Compact. `shell_preferences_provider.dart:1-60` owns only the independent bool sidebar expansion preference; extend alongside it, not by replacing its public value type. |
| Row content | `D/app/chat/sidebar/session-row-details.ts:1-47`, nearest `session-row-details.test.ts`; `session-row.tsx:573-595` | `HermesSession` already exposes model, messageCount, optional toolCallCount and preview (`lib/core/hermes/models/hermes_session.dart:5-98`). Comfortable adds loaded metadata; Detailed adds preview only for a titled session. Never fetch missing fields. |
| Window layout child | `D/app/settings/appearance-subpages.ts:1-8` | `settings_screen.dart:23-29,75-97,159-186,561-571` currently has Theme/Typography/Chat display. Add Window layout between Typography/Chat display with only the working density control, canonical `appearance.session-density`, field-over-page precedence and existing search revision fence. No empty/native rows. |
| Chat Font (rejected) | `D/themes/chat-font.ts`; `D/app/settings/chat-font-setting.tsx:24-116`, its nearest test | Profile-backed `desktop.font_family`, sparse Agent config save and rollback: not an install-local preference. Do not pretend support by adding a local font picker. |
| Other Chat display controls (not selected) | `D/store/tool-view.ts`; `D/app/settings/settings-manifest.ts:122-139` | Wing tool activity is summary-only (`hermes_chat_timeline.dart:690-788`), with no full input model. No current thread navigation bars; `Hide code diffs` targets file-edit tool rows, not arbitrary Markdown diff fences. These require distinct consumers/contracts; do not disguise them as trivial switches. |

The density copy is **Session List Density** / “Choose how much context appears
beneath session titles in the sidebar.” Choices: **Compact**, **Comfortable**,
**Detailed**. Window layout is a local presentation page, not native-window
management authority. The original source also supports git-branch metadata;
Wing's session model does not expose it. Omit that absent component and record
this bounded subset; do not add a protocol field, host path or fabricated branch.
Reference virtual-row estimates (28/45/63) are implementation details, not Flutter
hit-target constraints; retain accessible targets and text-scale-driven height.

## Planner's calls and handoff

One control, persistence and functioning sidebar consumer are one reviewable
outcome. Nine expected files cover three functional owners, ARB plus two generated
outputs, two test seams and this evidence owner. A control-only task would be fake
support; broad shell/virtualization rewrites or all Appearance would exceed scope.
These are delegated engineering choices, not new owner product decisions.

1. **RED:** add `session density persists locally without changing existing preferences`
   and `session density field routes to Window layout without Agent calls` in
   `test/features/settings/session_list_density_settings_test.dart`. Reuse the
   recording/delayed storage and fake-channel patterns in
   `chat_user_bubble_settings_test.dart`, not real endpoints or user data.
2. Add `WingSessionListDensity { compact, comfortable, detailed }` and
   `wingSessionListDensityProvider` with a controller exposing
   `setDensity(WingSessionListDensity density)` in
   `shell_preferences_provider.dart`. Store the enum name under new install-local
   `wing.shell.session_list_density`. Absent, unknown or wrong-type storage means
   Compact without hydration writes; explicit Compact removes only this new key.
   Guard late hydration/disposal and serialize saves so newer intent wins. Reuse
   current injectable `loadPreferences`/`loaded` patterns. Leave the existing
   bool provider, keys, saved theme/avatar/Chat data and session pins intact.
3. Add only the localized Window layout page and density selector to existing
   Settings, matching official order/copy. Canonical field beats `page=theme`;
   search uses the existing target maps/revision fence. Use adaptive keyboard/
   semantics-operable controls, with no overflow at 390/1280px and 200% text.
   Parent still opens Theme, caret only expands, and old aliases retain meaning.
   Generate localization outputs from `lib/l10n/app_en.arb`.
4. Watch the density only in the existing non-full-panel sidebar consumer.
   Compact keeps today's title/pin/selection behavior and no added metadata.
   Comfortable adds a subordinate metadata line below the title containing
   available sanitized model leaf, positive message count, positive non-null tool
   count, joined with a middle dot in that order. Localize counts; skip absent,
   empty or zero components. Detailed adds a separate sanitized single-line
   preview only when a nonblank own title and nonblank preview exist. Normalize
   whitespace before bounded `wingRedactedPreview` (model max 80, preview max 160),
   never bypass existing redaction. Keep title fallback unchanged. Do not infer
   git branches, fetch content or render links/images from these plain strings.
   Rows may grow naturally at large text; do not shrink targets to source CSS
   heights. Pinned/recent rows consume the same choice; global full-panel session
   search and Chat rail keep their current behavior.
5. Extend `test/shared/widgets/app_shell_global_session_access_test.dart` with
   `local session density changes only loaded sidebar row context`. Reuse its
   `Harness`, loaded channel, pin store, route draft and `noIncidentalWork` guards.
   Cycle all choices on mounted pinned/recent rows at 200% text, including sparse
   data, untitled sessions, redacted values and updates while mounted. The same
   row buttons/keys and selected semantics remain reachable; draft controller,
   focus/selection/composition, route and exact channel owner stay unchanged.
   Capture a callback, change owner away/back and prove the old action still
   cannot act. Density itself triggers zero reads/connects/creates/selects/
   sends/Stop/approval/model calls. Existing valid clicks must still select the
   exact session once. Add no automatic scrolling, focus or replay.
6. Run the task's exact checks, recording actual offline results and remaining
   platform/visual limitations here. Fix a defect in the named paths that blocks
   those checks without weakening them. The runner retains its unchanged full
   check; focused evidence never substitutes for whole-suite results. Do not edit
   task files from the implementation worker.

**Pre-mortem / invariant:** late storage must not overwrite new intent or unrelated
preferences (storage case); metadata/preview must not leak paths/content or invent
missing fields (mounted row case using existing redaction); density repaint must
not remount ownership/actions/drafts or revive stale callbacks (mounted case plus
existing shell owner guards). No new session/domain state, APIs or authority.

## Batch and continuation

Save one PARITY building task for the handoff above with no task dependency:
all consumed Settings/shell/model seams are already integrated baseline, and
Message Bubble is not its producer. Add no edge for overlap or preferred order.
Save exactly one PARITY successor plan, **Plan round: 4 of 10**, depending on every
new building task (the one here).
Close **PLANCLONE03LOCAL-001-84ad1ad6** manually in the same planning commit;
manual planning completion is not implementation verification or a goal receipt.
Allocated by native CLI: building task
[LINUXQA-004-5c6015fe](../../tasks/items/LINUXQA-004-5c6015fe.md) and successor
[LINUXQA-005-8d795764](../../tasks/items/LINUXQA-005-8d795764.md).
The allocator retained its LINUXQA prefix; these contracts are local feature
implementation and planning respectively, not Linux qualification.

[PARITY](../../tasks/goals/PARITY.md) stays **partial**. Its
[source](../product/hermes-desktop-parity.md#reference-and-evidence-boundary)
withdraws historical official-parity evidence; the accepted clone still lacks
full Settings tree/fields, other product outcomes, matched visual comparisons and
Linux/Android/web/macOS/Windows-specific proof. Do not reopen owner-deferred live
or Files closures. This round has building work and 3 < 10, so no stop question
or Needs decision item is justified. With the existing authorized runner the
chain can continue autonomously up to round 10; saving neither starts a runner nor
dispatches work. Stop by moving the new planning task to Needs decision through
native tasks place.

## Validation boundary

Behavior tests above are **proposed/unrun** in this planning-only pass. Only source,
links, task consistency, fresh-reader builder review and whitespace are checked.
No Flutter/browser/native/device/provider execution, inference, network access,
push, deployment or goal/platform qualification occurs here. The supplied CLI
reports prepare_api 4 and tasks prepare --check reports READY with a task-reading
runner. Existing unrelated prepare diagnostics are not a backlog-sweep mandate;
the native validator is the required ledger gate for this bounded batch.
The current planning record's validator release path was absent on disk; its
Checks now name the supplied available CLI, preserving all other requirements.

Fresh-context read-only builder review found **nothing important left**: the
control is source-supported/local-only, loaded fields suffice, the missing branch
component is explicitly omitted, and there are no inaccessible inputs or forbidden
prerequisites. The building task is independent; the successor waits for its
finished evidence. This is a planning review, not executed behavior proof.

Executed on the final batch: supplied CLI `tasks validate --worktree .` passes
with 308 tasks, 36 goals and no drafts (three task records pending commit).
A read-only Python consistency check passes 18 local Markdown links/anchors,
13 exact-pin source ranges, current building check paths, the two-task PARITY
chain, manual closure provenance, unchanged Scope/Acceptance/Dependencies/order/
authorization and the Message Bubble ancestor binding. Its initial source-range
check caught a citation starting after the font config constant; the citation was
corrected to line 24 and the complete check rerun successfully. The shared
`docs.py check .` reports no role manifest and performs no mapped-role checks;
this is not substituted for the scoped check. `git diff --check` passes.
Branch-local saving is not canonical integration, dispatch or goal/platform
qualification; committed-store selection is checked after the planning commit.

## Implementation follow-through — LINUXQA-004-5c6015fe

The task-branch candidate adds the independent `WingSessionListDensity`
Notifier and install-local `wing.shell.session_list_density` preference. Compact
is the absent/invalid default and explicit Compact removes only this key;
hydration writes nothing. Ordered saves preserve newer intent, failed storage
leaves the local choice usable, and disposed owners start no new writes. The
existing bool sidebar provider and saved appearance/Chat/pin values are unchanged.

Settings now has a working **Window layout** child between Typography and Chat
display. `appearance.session-density` selects it even with `page=theme`, and
search uses the existing navigation revision fence. Localized wrapping choice
chips support keyboard operation and semantics at 390/1280px and 200% text in
widget tests. The [route owner](../product/routes.md) records the new field/page.

Only loaded, non-full-panel `ShellSessionAccess` rows consume density. Compact
retains the existing title/pin/selection behavior. Comfortable adds available
model leaf and positive localized message/tool counts; Detailed also adds a
whitespace-normalized, redacted, bounded one-line preview for nonblank titled
sessions. Model text is redacted before extracting the leaf so discarded prefixes
cannot bypass path/credential redaction; the leaf is bounded to 80 and preview
to 160 before the existing ellipsis. Rows grow with text scale, without fixed
source CSS heights. The absent git-branch field remains omitted. No inventory,
Agent reads/mutations, full-panel search, Chat rail or protocol fields were added.

Actual offline checks on this candidate (Flutter widget tests on the Linux host,
not a native app run):

- `flutter pub get --enforce-lockfile`: pass; no manifest/lockfile changes.
- `flutter gen-l10n`: pass; generated Dart outputs come from the ARB.
- `dart format --output=none --set-exit-if-changed` on the five task Dart
  source/test paths: pass, zero changes.
- `flutter analyze --no-pub`: pass, no issues.
- The following named serial regression group: **117 passed**, including the
  two new Settings/storage cases and one mounted-sidebar case. The latter
  preserves pinned/recent controls, selected semantics, route/channel owner,
  draft controller/value/selection/composition and focus while cycling densities
  and receiving loaded updates; stale owner-away/back actions remain rejected and
  a current click selects exactly once. Mock preferences reset per sidebar test
  so an earlier collapse cannot leak into later owner-fencing cases.

```bash
autowork-run flutter test --no-pub --concurrency=1 \
  test/features/settings/session_list_density_settings_test.dart \
  test/features/settings/providers/shell_preferences_provider_test.dart \
  test/features/settings/chat_user_bubble_settings_test.dart \
  test/features/settings/settings_subpages_test.dart \
  test/features/settings/settings_search_test.dart \
  test/features/settings/settings_screen_test.dart \
  test/router/settings_routes_test.dart \
  test/router/chat_workspace_overlay_test.dart \
  test/shared/widgets/app_shell_global_session_access_test.dart \
  test/shared/widgets/app_shell_desktop_parity_test.dart \
  test/shared/widgets/app_shell_focus_traversal_test.dart
```

- Scoped documentation readback/local links and exact-pin source bindings: pass.
  The shared Docs Sync checker reports no `docs/roles.json`; it does not replace
  this scoped readback. `git diff --check`: pass.
- Fresh-context read-only review found one disposal-test masking gap; the final
  regression now disables simulated storage failure and proves no writes occur
  after disposal, including late hydration. No product-code findings were raised.

The runner still owns the unchanged full merged-tree gate; these focused passes
are not a substitute. Native Linux/Android/macOS/Windows, browser interaction,
physical-device/live-Agent/provider, runtime screen-reader and exact-pin paired
visual qualification were not run. Local commit is not coordinator integration,
publication, full Settings/CLONE-03/PARITY acceptance or platform qualification.
Round 4 can reconcile this bounded result after integration and choose its next
source-supported local slice; preserve owner-deferred live/Files closures.
