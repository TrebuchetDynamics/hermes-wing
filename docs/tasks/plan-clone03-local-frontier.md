# CLONE-03 local Settings frontier

Status: Accepted — bounded planner-selected implementation within the existing
[owner direction](../adr/product.md#literal-presentation--owner-decision-2026-10-24),
not acceptance of the whole clone or a product/platform qualification.

## Brief and authority

[PLAN-CLONE03-LOCAL-FRONTIER](../../tasks/items/PLAN-CLONE03-LOCAL-FRONTIER.md)
requests exactly one missing, official, local Settings outcome under
[PARITY](../../tasks/goals/PARITY.md). Reuse Wing's Settings master/detail and
preferences; preserve saved values, navigation intent, focus and Agent authority.
No implementation, live work, network access, dependency installation or reference
modification belongs to this planning pass.

Docs map: the existing [clone plan](../plans/2026-10-21-desktop-literal-clone.md#backlog-connection)
owns the package inventory; its [plan index](../plans/README.md#plan-to-task-coverage)
owns the summary mapping; this bounded handoff owns the newly researched slice.
This invocation permits writes only in `tasks/items/`, `tasks/goals/`,
`BLOCKERS.md`, `CHANGELOG.md` and `docs/tasks/`. Therefore the two `docs/plans/`
summaries are deliberately **not** edited here. Their pending-admission prose is
stale for this bounded slice, not evidence against the native records below.
The implementation successor owns updating those two summaries without changing
other packages' disposition or historical receipts. This limitation is recorded,
not represented as already satisfying the old mapping acceptance item.

## Source binding and delivered work

Wing baseline: `61e47dbf`; official source pin:
`14e1e43a23761b369641208e204365cd6cb9399d` (not a claim about current remote HEAD).
The checkout-local reference is older and lacks this object. The pin was read
from an existing local Agent Git object store, without fetching or checking out
another revision. Reproduce the source reads using:

```bash
git -c gc.auto=0 -C "$HOME/.hermes/hermes-agent" show 14e1e43a23761b369641208e204365cd6cb9399d:apps/desktop/src/store/text-direction.ts
```

Read source objects only: do not execute Agent, inspect its user state, modify
its working files, fetch, repin, or install anything. `D/` below abbreviates
`apps/desktop/src/` at that exact pin; all line ranges are source-inspected.

| Control / navigation | Official action and state | Wing caller and test evidence at baseline | Local authority / disposition |
| --- | --- | --- | --- |
| Appearance navigation | `D/app/settings/constants.ts:733-737` has no Agent config keys for Appearance; `D/app/settings/appearance-subpages.ts:1-8` lists General, Theme, Typography, Window layout, Chat display, Pet; `D/app/settings/index.tsx:133-148` replaces URL selection; `D/app/settings/subpages.ts:108-139` gives a setting target precedence over page. | `lib/features/settings/screens/settings_screen.dart:23-25,75-116,176-229,367-425`; `test/features/settings/settings_subpages_test.dart:12-232`; `test/router/settings_routes_test.dart:112-135`. Theme/Typography, caret-only expansion, parent selection and stale-search fencing already exist. | UI-local navigation; extend the existing supported subset, never add empty branches. |
| Theme | `D/app/settings/settings-manifest.ts:70`; `D/app/settings/appearance-settings.tsx:573-666` selects mode/theme. | `lib/features/settings/screens/settings_screen.dart:558-660`; `test/features/settings/settings_screen_test.dart:645-708`; `test/features/settings/settings_subpages_test.dart:96-128`. Existing Wing mode/palette keys remain intact. | Existing install-local preference; **exclude delivered controls** and full Desktop theme catalog from new work. |
| Chat text size | `D/app/settings/settings-manifest.ts:72`; `D/app/settings/appearance-settings.tsx:689-703` invokes the local scale setter. | `lib/features/settings/screens/settings_screen.dart:663-722`; `lib/features/settings/providers/chat_preferences_provider.dart:24-29,46-53,79-84`; `test/features/settings/chat_text_scale_settings_test.dart:12-72` preserves saved 1.37 and persists 1.5. | Existing install-local preference; **exclude** scale reimplementation, rounding or migration. |
| Text direction — chosen missing outcome | `D/app/settings/appearance-settings.tsx:536-539,897-912` offers Auto/RTL/LTR and calls `setTextDirection`; `D/app/settings/settings-manifest.ts:117-121` puts it in Chat display. `D/store/text-direction.ts:18-44` persists an install-local reading preference, removes the key for Auto, and returns no forced direction for Auto. | Only theme and chat-text-scale are field targets (`settings_screen.dart:75-85,203-220,501-513`); `chat_preferences_provider.dart:6-20` has spellcheck/scale only. `lib/features/hermes_chat/screens/state/hermes_chat_layout.dart:2713-2734` has the existing composer; `lib/features/hermes_chat/presentation/hermes_rich_text.dart:16-35,89-157,361-407` renders prose/code without a preference. No open task covers text direction. | **New install-local presentation preference, no Agent operation or grant.** Add the functioning control, search/link routing and actual prose/composer consumers together. |

The pinned manifest generates the canonical field ID `appearance.text-direction`
(`D/app/settings/settings-manifest.ts`, `settingId` / `SETTING_IDS`); use that ID,
with `tab=config:appearance&page=chat-display`. Do not replace Wing's already
supported `theme` / `chat-text-scale` aliases or change their saved links.

Pinned consumers: `D/app/chat/composer/index.tsx:174,1178`,
`D/components/assistant-ui/thread/user-message-text.tsx:152-158`,
`D/components/assistant-ui/thread/message-parts.tsx:446-459`, and
`D/components/assistant-ui/thread/user-edit-composer.tsx:98,890`.
`D/components/assistant-ui/thread/text-direction.test.tsx:148-209` proves Auto
removes the override, explicit directions apply live, code stays LTR, and content
receives no injected bidi controls. Wing has no corresponding inline-edit composer;
do not build one for this slice.

Finished evidence read in place under the execution common directory's
`autowork-execution/slot-data/`:

- No slot/report exists for this planning ID or a CLONE03 implementation batch.
  Delivered Settings behavior is traced to current code/tests, not an invented
  prior-worker report. Commits `c734f9f0`, `ad666107` and `d025d40c` explain the
  existing subpages/search/URL work.
- `MAIN-REPAIR-001/attempt-1/report.json`: Settings overlay and traceability fixture
  repair, 174 focused passes; production behavior unchanged. Its unrelated failure
  inventory is not a current-main result or a reason to duplicate Settings work.
- `WING-TASK-408/attempt-1/report.json`: 24 isolated GTK and 42 Chromium overlay
  journeys, with explicit Android/live limitations. Do not repeat or relabel these
  as proof for the new preference.
- `PLANGAP-001-2f/attempt-1/report.json`: hash-ID plan traceability parser already
  present; evidence-only task, with full suite timing out rather than qualifying
  parity. No parser rewrite is needed here.

## Planner's calls and implementation handoff

Selected: [CLONE03-LOCAL-NEXT](../../tasks/items/CLONE03-LOCAL-NEXT.md).
One coherent outcome spans Settings, its preference owner and existing Chat
consumers; splitting off a control with no working consumer would create fake
support. The bounded cross-feature write set is intentional.

1. Start by adding the failing behavioral case named in the task. Extend
   `WingChatPreferences` with `auto` / `rtl` / `ltr`, using a new
   `wing.chat.text_direction` install-local key. Missing/invalid values decode as
   Auto; untouched Auto must not write the key; choosing Auto removes only that
   key. Preserve every existing key/value and guard async hydration against a
   newer user choice. Reuse current provider/storage seams, not another backend.
2. Add only Chat display with its working Text direction row to the existing
   Appearance children. Localized Auto/Right to left/Left to right choices use
   adaptive Flutter controls with semantics and keyboard operation. Extend the
   existing field resolver/search target mapping rather than another Settings
   shell or manifest framework. A field target beats a disagreeing page; unknown
   targets, cancel and newer navigation retain their present behavior.
3. Apply explicit direction to user/assistant prose, lists/quotes and the current
   draft composer, not the entire application, shell, metadata or connection
   forms. Keep fenced/inline code LTR. Reuse `HermesRichText`; preserve safe links,
   inline-image containment, virtualization, selection and exact copied/submitted
   text. Do not inject bidi characters. Auto means **no new forced override** and
   restores Wing's existing default rendering. This slice does not claim to have
   qualified Desktop's CSS first-strong algorithm in Flutter, add a new math
   renderer, inline message editor or change the app locale.
4. Extend the nearest Settings/router and Chat tests; use deterministic fake
   channels. Check reload, rapid choice before hydration, empty/malformed stored
   values, live updates without replacing draft/controller/selection/composition,
   code isolation, keyboard reachability, 390/1280 widths and 200% text. Keep
   existing full-location/focus/Stop/no-replay guards. Add only focused tests for
   changed behavior, reusing existing broad coverage.
5. Update the existing clone-plan Backlog connection and plan-index row to name
   this planning ID and the implementation owner for **this subset only**.
   Retain the full clone's pending work, old receipts and deferred live/native
   closures. Record actual offline checks and limits in this handoff; do not
   mark PARITY met or manufacture acceptance/verification receipts.

Rejected alternatives: repeat Theme/Typography/search (already delivered); build
all Appearance controls (not one outcome and includes native/network work); add
language/global UI scale/font catalog (larger dependencies and default changes);
implement only a direction picker (no user outcome without consumers).

Pre-mortem / invariants: new storage must not overwrite scale/theme/retired avatar
preferences; scoped direction must not reverse code or shell; Settings search or
preference hydration must not replace newer navigation or draft intent. The
new focused cases and existing Settings/router/rich-transcript guards cover these.
No new API, credentials, device, network call, product decision or coordinator
receipt is an implementation prerequisite. A pre-existing defect in the named
paths that prevents the required checks may be fixed without weakening them.

## Backlog connection and continuation

- Current plan: `PLAN-CLONE03-LOCAL-FRONTIER`, manually closed by DOCS-MAINTAINER;
  this is not coordinator verification or goal qualification.
- Next implementation: `CLONE03-LOCAL-NEXT`, PARITY, Next, no prerequisites.
- Continuation: `PLAN-CLONE03-LOCAL-ROUND2`, PARITY, Next, depends on that entire
  new building batch (one implementation). Default current round is 1 of 10;
  the successor records **Plan round: 2 of 10**. The current invocation's explicit
  rolling-planning rule supersedes the entry's older no-successor-plan instruction.
  It does not broaden the product slice or change its Acceptance.

PARITY remains partial: the goal source and clone execution table still require
other Desktop outcomes, paired visual evidence and target-specific/live proof.
No stopping condition applies in this round: one new building task exists and
round 1 is below 10. No stop question or new owner-only task is invented. The
successor re-reads the finished report, current code and remaining goal proof;
it must not turn old task closures or this saved plan into parity evidence.
With the existing authorized runner, the chain can continue within the round
limit; saving this batch does not dispatch work or start a runner. To stop it,
move `PLAN-CLONE03-LOCAL-ROUND2` to Needs decision through `autowork tasks place`.

## Validation boundary

This is source-based planning only. Implementation checks in the task are
**proposed/unrun**, including localization generation, analysis and Flutter tests.
The planning closeout runs native task validation, source/path/line and local-link
checks, and `git diff --check`. No platform runtime, provider, physical device,
full Flutter suite or Desktop visual comparison is exercised by this pass.

Fresh-context, read-only builder review found **nothing important left**: the
pinned source and current provider/renderer/composer seams support the task,
there is no duplicate, and the continuation correctly depends on the sole
implementation. Source availability, explicit Auto scope and deferred mapping
writes are not reasons for a worker to wait. The reviewer flagged that the
current plan was still open during review; native manual closure is required
before committing this batch; that closure is now recorded through the native CLI.
This is a planning review, not feature validation.

Executed planning validation: native `tasks validate --worktree .` returned
`ok: true`, 303 tasks, 36 goals and no drafts. The read-only Python check passed
6 local links/anchors, 37 cited source ranges, pinned control/state relationships,
unchanged original Scope/Acceptance/Checks/Dependencies and exclusions, manual
closure, the two-task PARITY batch and its round/dependency edge. `git diff --check`
passed. During validation, the temporary checker was corrected to use the
repository's heading-slug convention, and a router-test citation end was corrected
from 141 to the actual final line 135. Neither required a product/test-code edit.


## Implementation follow-through — 2026-10-24

`CLONE03-LOCAL-NEXT` now adds the working Chat display child and canonical
`appearance.text-direction` search/deep-link field. Auto/RTL/LTR is an install-local
reading preference; prose, lists/quotes, reasoning and the draft composer update
live while code remains LTR. Auto removes only the direction key and leaves
Wing's previous automatic rendering in place. Draft text, controller, selection,
composition and channel ownership remain intact; the shell keeps its direction.

Preference hydration now merges only fields touched before loading, and writes
only changed preference fields. This prevents an early direction choice from
clobbering an existing text scale or spellcheck preference. Existing theme/avatar
records are preserved. No Agent operation or configuration write is introduced.

The exact four reference files named above were read from the pinned GitHub raw
source after the local object lookup failed; no checkout, fetch or reference edit
was used. Their Auto persistence, explicit direction, code isolation and field
routing agree with the implementation's bounded scope.

Executed locally with Flutter 3.44.2 / Dart 3.12.2:

- Locked warm-cache `flutter pub get --offline --enforce-lockfile`: passed, no
  lockfile changes. `flutter gen-l10n` generated the localization outputs.
- The new named persistence case initially failed because the control was absent.
- The two new direction test targets passed all **9** cases, including malformed
  preferences, a newer choice before hydration, 390/1280px at 200% text, keyboard
  operation, field precedence/search and mounted Chat draft/code isolation.
- The broader requested Settings/router/transcript/composer/viewport/plan run
  completed with 223 passes and one plan-mapping failure: listing the subset as
  the full clone's primary task required a backlink that the bounded task does
  not own. The table now retains full-clone admission as pending and names the
  admitted subset in its explanation. No task record or guard was changed.
- The final targeted rerun passed **27** cases:
  `flutter test --no-pub --concurrency=1
  test/features/settings/chat_text_direction_settings_test.dart
  test/features/hermes_chat/screens/hermes_chat_text_direction_test.dart
  test/tooling/plan_backlog_contract_test.dart
  test/tooling/plan_backlog_traceability_test.dart`.
- `flutter analyze --no-pub`: no issues after correcting two test style notices.
- Changed Dart formatting, Markdown local links and `git diff --check`: passed.

The coordinator owns the integrated whole-suite and web build/browser gate. This
implementation record does not claim native GTK, Android, macOS/Windows, physical
input, paired visual parity or complete Settings/CLONE-03/PARITY acceptance.
