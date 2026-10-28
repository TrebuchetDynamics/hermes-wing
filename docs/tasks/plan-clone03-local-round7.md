# CLONE-03 local Settings round 7 — reconciliation and stop

Status: Accepted — delegated planning disposition within the existing local
frontier, not acceptance of full Settings or PARITY.

**Goal:** Reconcile Tool Call Display and identify at most one further working
local-only official outcome; preserve remaining proof if none is ready.
**Spec:** [current planning contract](../../tasks/items/PLANCLONE03LOCAL-004-a183f257.md),
[round 6](plan-clone03-local-round6.md#batch-and-continuation),
[accepted frontier](../plans/2026-10-21-desktop-literal-clone.md#frontera-inmediata-decidida-por-el-planificador).

## Working checklist and docs map

- [x] Read Goal, Sources, dependency, both finished reports and integrated consumers/tests.
- [x] Compare pinned controls and complete relevant fallbacks without fetch/execution.
- [x] Reconcile delivered outcomes; select stop rather than duplicate or dead control.
- [x] Save one PARITY Needs decision task and one stop question; no successor plan.
- [x] Fresh-context read-only builder review and final scoped readback.
- [x] Native validation, links/source bindings and whitespace; save with one planning commit.

Round **7 of 10**. This is the single named planning trigger, not a backlog sweep.
The existing round-6 owner retains implementation evidence; this document owns
only the new comparison and stopping disposition. Task records use native tasks
commands; no product/test/asset/manifest/CI implementation is part of this pass.

## Finished batch and integration

Wing baseline: `57faa450d5fe3ac3f6dc8bd5d7d82a65fe27c172`.
Official pin: `14e1e43a23761b369641208e204365cd6cb9399d` (unchanged).
Reports were read in place in the execution common directory under
`autowork-execution/slot-data/CLONE03TOOLVIEW-001-ee4f6811/`:

- `attempt-1/report.json`: candidate `23cfbc0d3aa6ab3082cdcc5d249047b6cd6b850c`,
  reported 322 tests across 18 modules. This is not final acceptance: the
  [round-6 follow-through](plan-clone03-local-round6.md#implementation-follow-through--clone03toolview-001-ee4f6811)
  records the integration-found quoted-credential leak and reproduced repair.
- `attempt-2/report.json`: candidate `289fe75fcab17b36678d54ed43571ffd5ce56538`,
  locked preparation, generated l10n, formatting, analysis and the same exact
  18-module inventory with **322 passing tests, no failures/skips**, including
  quoted credentials, spaced paths and non-finite JSON regressions. These are
  attributed Linux-host Flutter widget results, not rerun here.
- The [existing receipt](../../tasks/evidence/CLONE03TOOLVIEW-001-ee4f6811.toml)
  names integration `9af7642212b51d65db8c220b62cbe7d4035b8428`, pass/review passed.
  Both final candidate and integration are ancestors of this baseline (each
  `git merge-base --is-ancestor ... HEAD` returned 0). The dependency is already
  coordinator-verified done; its contract, receipt and closure remain untouched.
- Its closed slot has `ledger_edit_dropped: null`. There is no slot-data directory
  or slot record for PLANCLONE03LOCAL-004-a183f257. No saved task-file patch was
  supplied for this entry and none was replayed. No worker or candidate for that
  planning ID was found waiting to land.

Current code corroborates the bounded delivery:
`chat_preferences_provider.dart:16-226` owns Product/Technical persistence;
`settings_screen.dart:89-95,245-263,839-880` routes/searches `appearance.tool-view`;
`hermes_chat_timeline.dart:129-132,742-877` composes single/grouped explicit
payload disclosure; `tool_result_disclosure.dart:9-242` owns lazy bounded sanitized
plain Result presentation. The two named cases in
`test/features/settings/tool_display_settings_test.dart:23,165` and the mounted
case in `test/features/hermes_chat/screens/hermes_chat_tool_display_test.dart:16`
pin that behavior, preference preservation, bounds and owner/focus guards.
No Arguments, full historical payload retention, diff renderer or new read API
was added. Product privacy/copy defaults remain the existing oracle.

Exclude delivered theme, transcript scale, direction, reasoning, Message Bubble,
density, backdrop, loaded timeline and Tool Call Display from new work. Loaded
bars are not indexed archive navigation; loaded Result is not full tool parity.

## Pinned comparison and complete fallback findings

`D/` means `apps/desktop/src/` at the exact pin above, read from the existing
read-only reference object store. No clone is present inside this worktree.
Use only existing objects, for example:

```bash
GIT_NO_LAZY_FETCH=1 git -c gc.auto=0 -C "$HOME/.hermes/hermes-agent" show 14e1e43a23761b369641208e204365cd6cb9399d:apps/desktop/src/store/tool-view.ts
```

| Candidate | Pinned evidence | Current consumer / disposition |
| --- | --- | --- |
| Tool Call Display | `D/store/tool-view.ts`; complete `D/components/assistant-ui/tool/fallback.tsx`, especially `technicalTrace` and `ToolPayloadDisclosure` | Result-only fallback is already delivered. Do not schedule it again because Arguments/history remain absent. |
| Hide code diffs | Same complete fallback: `inlineDiffFromResult`, `isFileEditTool`, `summaryOnly`, `showPayload`, completed diff-less edit suppression and error-detail fallback | Wing `HermesToolCall` has name/status/preview/result only; activity remains category/status plus sanitized Result, not an inline file-edit/diff consumer. Hiding all tool results or Markdown diff fences is not this outcome. Building the separate renderer is beyond this bounded control frontier. |
| Intro Splash | Complete `D/store/intro-splash.ts`, `D/app/chat/intro-visibility.ts` and its complete test | Official fallback requires an empty primary fresh draft with neither active nor selected session. Wing `hermes_chat_layout.dart:1521-1554` returns no-session guidance or an active-session suggestion state. Neither is that draft. A guidance-hiding toggle would be false parity; fresh-draft composition is prerequisite work for a later frontier, not an owner-supplied input. |
| Model Pricing | Complete `D/store/model-pricing.ts`; pinned picker object remains unavailable | Wing `lib/core/hermes/models/hermes_model_options.dart:8-119` holds names/selection metadata, no prices. Do not invent a price catalog or claim no official fallback exists. |
| Tips / tours / reactions / hearts | Complete `D/store/tips.ts`, `tours.ts`, `reactions-enabled.ts`, `display-toggles.ts`, `vibe-hearts-enabled.ts` and `D/components/chat/vibe-hearts.tsx` | First three mirror profile-routed Agent configuration; hearts consume the core reaction event. No mirror/reconnect replay, local text detector or pretend consumer is admitted here. |
| Interface Mode / Tab Strip / App Actions | Complete `D/store/interface-mode.ts`, `tabstrip-prefs.ts`, `titlebar-app-actions.ts` | Mode shadows rather than overwrites preferences and has session reveals; tab default resolves per-zone choice; actions move Settings/Layout/HUD together. Wing `shell_preferences_provider.dart:5-132` owns sidebar/density only; `app_shell.dart:60-245` has adaptive navigation/overlay ownership, not that pane-zone/titlebar cluster. A tab-hiding or Settings-button-only switch would not implement these complete outcomes. Their shell composition belongs to later CLONE-02/10 work. |
| Chat font / resume / window scale | Complete `D/app/settings/chat-font-setting.tsx`, `D/store/zoom.ts`; `D/app/settings/appearance-settings.tsx:91-134` resume autosave | Config autosave/profile fences or main-process IPC, not install-local substitutes. No new Agent/config/native operation in this batch. |
| Embeds / Files / popout / translucency / pets | Complete `D/store/embed-consent.ts`; pinned manifest and appearance wiring; retained round-6 comparison | Embeds involve third-party content/consent; the other controls require separate Files/native/composition/pet consumers. Do not schedule fake toggles, reopen Files closures or call local decorative avatars the full pet system. |

`D/components/model-picker.tsx` failed with lazy fetching disabled (exit 128,
promised blob `f6b9f1c58ec40fb5e7da48777a55561a88ebaa0e`). A bounded pinned grep
for tab/action/reaction consumers also stopped on unavailable promised blob
`42f76a6a021e285592fc9e5f80d76014ebceeb5d`; its partial output is not exhaustive
source evidence. Neither failure authorizes fetching, repinning, an owner-input
requirement or a conclusion that the missing source lacks a fallback. The
positive store/fallback reads and current Wing consumers above support this
narrow disposition without resolving either missing object.

## Planner decision and remaining proof

**Planner's call:** stop this rolling local-control chain. Rejected alternatives:
repeating Tool Call Display would duplicate integrated work; adding a toggle over
an absent/different consumer would simulate parity; expanding into a fresh-draft,
pane/titlebar, tool renderer or privileged operation port is not one more bounded
control over the current local subset. This is not a claim that all future local
Settings work is impossible or that engineering facts need owner answers.

[PARITY](../../tasks/goals/PARITY.md) remains **partial**. Its
[source boundary](../product/hermes-desktop-parity.md#reference-and-evidence-boundary)
withdraws older reference claims. The accepted complete Settings tree, indexed
archive and complete tool renderer/inputs/history, matched exact-pin visuals,
compiled browser, actual Linux/Android/macOS/Windows, real assistive technology
and live Agent/provider/authentication proof remain distinct unfinished outcomes.
Preserve historical/manual and owner-deferred live/Files closures; this question
neither reopens them nor grants credentials, spending, device/service access,
publication, new capabilities or goal qualification.

One open owner-only continuation record,
[PARITYCONTINUATION-001-f26b9bbd](../../tasks/items/PARITYCONTINUATION-001-f26b9bbd.md),
retains that proof/continuation under PARITY in **Needs decision**, with the single
question in [BLOCKERS](../../BLOCKERS.md#q-planclone03local-004-a183f257--planning-stopped):

> Should PARITY planning continue beyond this completed bounded local Settings
> subset into the already accepted shell/fresh-draft prerequisite frontier
> (CLONE-02/04), or remain paused pending a specifically selected qualification
> campaign?

No independent building task supported by this inspected subset is saved. Thus
**one new task total**, zero new building tasks, **no successor planning task**,
even though 7 < 10. No rank is promoted above the owner's Now tasks and no overlap
is converted into a product dependency. Manually close only the current planning
activity in this same commit. No receipt/waiver/qualification is written. The
existing runner receives this saved disposition; this pass starts no runner,
dispatch, implementation or schedule. Continuing needs a scoped answer, not an
automatic round reset; moving a future plan to Needs decision stops its selection.

**Pre-mortem / invariants:** duplicate implementation is prevented by final-candidate
ancestry plus current-consumer readback; empty queues cannot erase remaining proof
because the goal stays partial and the continuation task stays open; source-cache
holes cannot become invented authority or owner inputs because they remain
explicitly uninspected and no unavailable source is counted as proof of absence.

## Delegated continuation — 2026-10-28

The user subsequently asked all runners with tasks to work and delegated routine
engineering decisions. Under that delegation, select the already accepted
CLONE-02/04 shell/fresh-draft prerequisite frontier, prioritizing CLONE-02 where
current evidence supports it, rather than selecting a live qualification campaign.
The continuation choice is resolved by manual closure of
[PARITYCONTINUATION-001-f26b9bbd](../../tasks/items/PARITYCONTINUATION-001-f26b9bbd.md).
A separate bounded worker-owned planning record,
[LINUXQA-006-0ca2ba5b](../../tasks/items/LINUXQA-006-0ca2ba5b.md), carries this next
frontier. It must verify current consumers and the unchanged exact reference pin,
then save at most one nonduplicate local building slice with concrete oracles.

The earlier round-7 disposition and stopped Settings chain remain historical
facts; this explicit later decision is not an automatic round reset. PARITY stays
partial, and the remaining proof listed above and all prior live/Files closures
remain unchanged. This decision neither qualifies a platform nor grants access,
spending, upstream changes, publication or deployment. Ordinary local planning
returns to the existing runner without a second owner interview or queue hold.

## Planning validation and limits

Executed on the Linux host, planning only:

- Supplied release `ca5765d0` CLI `capabilities`: prepare_api **4**;
  `tasks prepare --check .`: **READY**, converted store, task-reading runner and
  existing coordinator lease. Existing unrelated drift diagnostics are unchanged;
  no installation, conversion, activation or runtime-state edit was needed.
- Fresh-context read-only builder review: **nothing important left**. It found
  no duplicated work, invented engineering input or qualification claim. The one
  intended wait is the owner's scoped continuation choice; no independent new
  building lane is specified or admitted by the owner-only task.
- Supplied CLI `tasks validate --worktree .`: **pass**, 315 tasks, 36 goals,
  no drafts; only the new continuation and manually closed planning records are
  pending. Task writes used native `add`/`done`, with the earlier read's
  `record_revision` on closure. The temporary literal JSON input was removed.
- `python3` scoped in-memory readback: **pass**, 16 local Markdown links/source
  anchors and 20 readable exact-pin source bindings; one new owner-only PARITY
  task, no successor, manual closure with original contract/body preserved,
  unchanged goal/dependency/receipt and all prior BLOCKERS content preserved.
  Both unavailable promised objects above are excluded from readable bindings.
- Installed Docs Sync `scripts/docs.py stale .` and `check .`: exit 0,
  no `docs/roles.json` manifest; no manifest coverage claimed. Dedicated scoped
  readback supplies this batch's link/source coverage.
- `git diff --check`: **pass**. Scoped diff review retains only the two task
  records, this evidence owner and the one BLOCKERS section; no secrets, user
  state, receipt edits, unrelated changes or implementation are included.

Only Linux-host source inspection and local documentation/ledger maintenance were
exercised. No Flutter tests,
browser/native/device run, live Agent/provider request or matched visual comparison
is executed by planning. Prior 322-test results are attributed above, not fresh
platform qualification. Local commit is separate from canonical integration and
publication; saving a Needs decision task does not make it executable.
