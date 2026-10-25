# CLONE-03 local Settings round 6 implementation plan

Status: Accepted — delegated planner choice within the existing local CLONE-03
frontier, not full Settings or PARITY acceptance.

**Goal:** Port the official Tool Call Display control and its working result-only
Technical fallback over already loaded tool turns.

**Architecture:** Extend the existing local preference owner and grouped transcript
activity, with a small bounded result-presentation widget. Agent turns remain the
only data source. Product mode retains today's category/status-only presentation.

**Tech stack:** Flutter/Riverpod, SharedPreferences, English ARB generation.

**Spec:** [round-6 contract](../../tasks/items/PLANCLONE03LOCAL-003-5699d676.md),
[accepted frontier](../plans/2026-10-21-desktop-literal-clone.md#frontera-inmediata-decidida-por-el-planificador),
[product boundary](../adr/product.md#literal-presentation--owner-decision-2026-10-24),
[security boundary](../security/threat-model.md#current-controls-and-adversarial-cases).

## Working checklist

- [x] Read Goal, Sources, dependency, both finished attempts and current consumers.
- [x] Compare exact-pin controls and complete relevant fallbacks without fetching.
- [x] Select one non-duplicate working local outcome; retain qualification gaps.
- [x] Save building contract and round-7 successor, close this plan manually.
- [x] Fresh-context read-only builder check; resolve evidence-answerable findings.
- [x] Validate saved records, local links/source bindings and whitespace.

Docs map: round 5 owns timeline implementation evidence; this handoff owns only
Tool Call Display's next local subset. No backlog sweep, execution, repin, new
Agent operation or qualification is authorized by this planning pass.

## Evidence reconciliation

Wing baseline: `6105c5297bf54951f768cb4daba53a9e96a367a6`.
Official pin: `14e1e43a23761b369641208e204365cd6cb9399d`.
Read reports in place under the execution common directory's
`autowork-execution/slot-data/PARITYCONTINUE-001-421b2b55/`:

- `attempt-1/report.json` names `6e3c01ba4915a6618c9156754aebbe5b216c5901`
  and 247 passing tests; it is not the final integrated result.
- `attempt-2/report.json` names `928711fd95cd3610d62b79f653bf82e672fc7b99`,
  an ancestor of this baseline. It records locked preparation, generated l10n,
  formatting, analysis, **260 passing fixture tests across 21 modules**, scoped
  links/source checks and whitespace. The record is coordinator-verified done;
  preserve its receipt. These are attributed results, not tests rerun here.
- The second attempt includes unchanged short-viewport profile-switcher and failed
  approval regressions; [round-5 follow-through](plan-clone03-local-round5.md#implementation-follow-through--paritycontinue-001-421b2b55)
  explains its integrated layout/marker repairs.
- There is no slot/report directory or slot record for this planning ID. Neither
  timeline attempt contains a ledger-edit patch; its closed slot reports
  `ledger_edit_dropped: null`. No saved patch for this entry was supplied or replayed.

Current `chat_preferences_provider.dart`, `settings_screen.dart:86-100,352-366,824-845`,
`hermes_chat_timeline.dart:129-162`, `thread_timeline.dart:9-151`, the viewport and
lifecycle consumers, and the named Settings/mounted timeline tests implement the
loaded-only outcome. Exclude it and delivered theme/scale/direction/reasoning/
Message Bubble/density/backdrop. The timeline test exercises 10,000 loaded turns,
keyboard, ownership and draft preservation; source inspection is not fresh execution.

[PARITY](../../tasks/goals/PARITY.md) remains **partial**. Its source withdraws older
reference claims. Indexed archive navigation, the complete Settings tree, matched
exact-pin visuals, compiled browser, native Linux/Android/macOS/Windows, real
assistive technology and live Agent/provider/authentication proof remain separate.
Preserve all historical/manual and owner-deferred live/Files closures.

No reference clone exists inside this worktree. Read existing pinned objects from
the same read-only object store used by round 5:

```bash
GIT_NO_LAZY_FETCH=1 git -c gc.auto=0 -C "$HOME/.hermes/hermes-agent" show 14e1e43a23761b369641208e204365cd6cb9399d:apps/desktop/src/components/assistant-ui/tool/fallback.tsx
```

`D/` below means `apps/desktop/src/` at that exact pin. Do not fetch, repin,
execute Agent or inspect user state. `D/components/model-picker.tsx` remains an
unavailable promised object (`f6b9f1c58ec40fb5e7da48777a55561a88ebaa0e`, exit 128
with lazy fetch disabled), not evidence that a pricing fallback does not exist.
The guessed `D/store/vibe-hearts.ts` does not exist; the actual owner
`D/store/vibe-hearts-enabled.ts` was read instead.

## Source-bound comparison and planner calls

| Outcome | Exact-pin evidence | Disposition |
| --- | --- | --- |
| Delivered local outcomes | Manifest, stores and round-5 comparison; integrated providers/Settings/mounted tests | Do not duplicate. Loaded timeline is not indexed archive parity. |
| **Tool Call Display / result-only fallback** | `D/app/settings/settings-manifest.ts:129`; `appearance-settings.tsx:1025-1040`; `D/store/tool-view.ts:7-41`; `D/components/assistant-ui/tool/fallback.tsx:121-196,451,526-538,781`; `fallback.test.ts:40-50` | Select one coherent local setting plus working consumer. `technicalTrace(undefined, result)` renders Result only; missing args are omitted, not invented. No new Agent operation is required. |
| Tool render bound | `D/components/assistant-ui/tool/fallback-model/format.ts:68-82` | Source retains 20,000 payload characters plus a truncation notice. Wing uses the stricter total display bound below and must keep privacy/bounded work; do not port its full-output Copy escape hatch. |
| Intro Splash | `D/store/intro-splash.ts`; `D/app/chat/intro-visibility.ts:13-32` and complete nearest test | Only an empty primary fresh draft qualifies. Wing no-session guidance and active empty sessions (`hermes_chat_layout.dart:1521-1554`) are not that consumer. No fake toggle over either. |
| Pricing | `D/store/model-pricing.ts`; unavailable picker object above; Wing `hermes_model_options.dart:8-119` | Current picker inventory contains model names, not token prices. Do not invent a price catalog or assert exhaustive source absence. |
| Reactions / tips / tours / hearts | Complete stores `reactions-enabled.ts`, `tips.ts`, `tours.ts`, `display-toggles.ts`; `vibe-hearts-enabled.ts`, `D/components/chat/vibe-hearts.tsx` | First three mirror Agent config; hearts consume the core reaction event. No text-matching detector, reconnect config replay or replacement Agent state. |
| Fonts / resume / window scale | `D/app/settings/chat-font-setting.tsx:24-116`; `appearance-settings.tsx:91-134`; `D/store/zoom.ts` | Config autosave or main-process authority, not this local subset. |
| Diffs / embeds / native composition | `D/store/tool-view.ts`; complete tool fallback; previous round's comparison | No diff parser, terminal, media/URL launch, embed consent, Files or native-window work in this batch. |

**Planner's choice:** result-only Technical fallback, not raw transport expansion,
a dead toggle or a complete tool renderer port. Current `HermesToolCall` has
`name/status/preview/result`, but no arguments. API event projection
`hermes_api_channel_messaging.dart:1425-1485` already populates transient string
results; history reconciliation (`hermes_api_channel_connection.dart:504-519` and
serve reads) and native-web lifecycle often provide status only. Missing result is
an honest unavailable state; never fetch it or relabel `preview` as Arguments.
The official scalar-result test proves this is a real fallback, not a fabricated
Wing-only feature. No new protocol/model/transport field is admitted.

Current `_ToolActivityGroup` (`hermes_chat_timeline.dart:721-826`) deliberately
shows only categories/status. Its existing rich-transcript tests at `:410-437` and
`:529-641` must remain unchanged and pass in default Product mode. Raw tool names,
previews, commands and clipboard/export content stay suppressed in both modes.
Privacy-safe result disclosure is an explicit opt-in presentation, not permission
to display secrets or a claim of full inputs/output coverage.

## Implementation handoff

One building task, no unlanded producer prerequisite or shared resource. Preference,
Settings and consumer belong together: neither a preference-only nor a widget-only
change delivers a working official outcome. Use the named existing seams; do not
restructure the transcript or add a second store of tool results.

### 1. RED — local control and routing

Add `tool display persists without changing existing preferences` and
`tool display field routes to Chat display without Agent calls` in
`test/features/settings/tool_display_settings_test.dart`, reusing recording/delayed
storage and fake-channel patterns from `thread_timeline_settings_test.dart`.

Extend `WingChatPreferences` with `WingToolDisplay { product, technical }`,
`toolDisplay` and `setToolDisplay(WingToolDisplay)`. Key `wing.chat.tool_display`:
only string `technical` enables Technical; absent/invalid/other types mean Product.
Hydration never normalizes storage; choosing Product removes only this key.
Preserve late-intent, ordered-save/failure/disposal fences, copyWith and all other
saved preferences, including inert avatar records.

Canonical field `appearance.tool-view` opens Chat display even with conflicting
`page=theme`; search includes tool/display/technical/product/payload/result/output.
Use **Tool Call Display** with Product / Technical choices. Truthful localized
copy must say Technical shows available redacted loaded results, not full input/
historical output. Place after Hide thread timeline bars, before reasoning.
Preserve aliases, caret/parent/breadcrumb, cancel/newer navigation and focus.
Test at 390/1280px and 200% text with keyboard/semantics and zero Agent calls.
Generate localization from English ARB, never edit generated Dart by hand.

### 2. GREEN — explicit, private, bounded loaded-result disclosure

Add a small `tool_result_disclosure.dart` widget under Chat widgets; import it from
`hermes_chat_screen.dart` and compose it inside the existing single/grouped activity
rows. Read the preference at the existing transcript consumer seam. Product output
must remain byte/behavior equivalent to today's safe summary. In Technical, an
explicit **Tool payload** disclosure, collapsed by default, shows **Result** only
when the current unique tool turn has a nonblank loaded result. Missing results
show fixed localized unavailable copy, never inferred success, fake Arguments,
preview-as-input or a read/refresh button. Existing status/error/approval semantics
and tool order/group continuity stay intact.

Treat result as untrusted content. Render plain noninteractive text, not Markdown,
ANSI, links, HTML, media, commands, file actions or automatic Copy. Reuse shared
redaction and add only the narrow presentation sanitizer needed here. Required
policy: before parsing/formatting/redaction reject source strings above 65,536
UTF-16 code units with fixed oversized copy; bound JSON traversal to depth 16 and
1,000 values, failing closed to fixed unavailable copy if exceeded. For object/
array-looking input, malformed JSON fails closed; valid JSON is traversed to remove
case-insensitive credential/auth/token/secret/password/cookie/API-key fields
(including underscore/hyphen variants) before formatting. Redact scalar leaves
and plain strings with `wingRedactSensitiveText`; additionally suppress URI/URL
and private-address literals in this new result surface. Do not weaken or bypass
shared redaction for pretty JSON. After sanitization/formatting, paint at most
20,000 characters with an honest localized truncation marker, never a full-output
clipboard escape. Do not persist/log/cache raw or derived results outside the
canonical turns and bounded mounted presentation. Do work only for the opened
current result, memoized against its exact owner/ID/value, not on every assistant
delta or for every collapsed historical row. No eager decoding of all tool history.

Disclosure identity binds channel/origin/profile/session and unique turn ID, not
list index/tool name. Changed owner, duplicate/blank ID, removal, Product mode or
disposal closes and drops derived content. Running→completed/failed updates keep
current status and only the same owner's explicit disclosure intent. A focus
return after collapse must not target a replacement owner. Saved mode changes
must not remount the transcript/composer, jump scroll or steal focus. Reuse the
viewport owner identity and existing guards; bounded edits in the named seams may
repair defects that block required checks without weakening them.

### 3. Prove mounted behavior and preserve existing privacy defaults

Add `technical tool results stay explicit bounded and owner scoped` in
`test/features/hermes_chat/screens/hermes_chat_tool_display_test.dart`. Exercise
actual mounted Chat and existing fake tool turns, not an isolated callback:

- Default Product and all existing rich-transcript category/status/privacy/copy
  guards stay unchanged. Technical still hides raw name/preview/commands; results
  remain absent from whole-transcript clipboard/export. Setting/recreation has a
  real working result consumer, not a toggle-only test.
- Single/grouped, running/completed/failed/status-only turns; explicit keyboard/
  touch/semantics disclosure at 390/1280px, 200% text and reduced motion. Assert
  redacted scalar and formatted JSON, nested quoted credential fields, paths,
  URLs/private addresses, malformed/deep/large inputs, precise source/render bounds
  and missing results without inventing inputs or fetching. Use neutral sentinels,
  no real credentials/transcripts/private endpoints. Sanitizer assertions may live
  in this same focused test file; no separate security framework.
- Capture foreground/controller, selected/composing draft, scroll, route and exact
  owner. Toggle modes, stream unrelated assistant deltas, complete/fail a tool,
  replace owner with reused IDs, remove/duplicate IDs and dispose; no leaked stale
  disclosure, focus theft, eager processing, history/read/send/Stop/approval calls
  or replay. Retain viewport/window/timeline/approval/reconnect guards.

Update [routes](../product/routes.md) and this handoff with actual offline results
and the explicit result-only/transient/redacted subset; historical inputs, diffs,
matched visual/native/live/full-Settings/PARITY qualification remain unproved.
All proposed behavioral tests above are **unrun by planning**. Task Checks own the
exact preparation/l10n/format/analyze/focused commands. The full serial suite is
the runner merged-tree gate, not a duplicate worker invocation.

**Pre-mortem / invariant:** mode writes cannot erase other values/newer intent
(Settings cases); disclosure cannot leak secrets/URLs, decode unbounded input or
silently export raw data (mounted sanitizer and existing privacy/copy guards);
reused turn IDs or streaming cannot cross owners, remount input or steal focus
(mounted ownership assertions plus existing viewport/window guards). No Agent
state, authority, protocol or history behavior changes.

## Batch and continuation

Building: [CLONE03TOOLVIEW-001-ee4f6811](../../tasks/items/CLONE03TOOLVIEW-001-ee4f6811.md),
PARITY, Next, no Dependencies or resources. Successor:
[PLANCLONE03LOCAL-004-a183f257](../../tasks/items/PLANCLONE03LOCAL-004-a183f257.md),
PARITY, Next, Plan round **7 of 10**, depending on that one building task.
Two new tasks total, below the eight-task cap; no promotion above Now or
scope/overlap-only dependency. Close PLANCLONE03LOCAL-003-5699d676 manually in the
same planning commit, retaining its contract. Round 6 < 10 plus new building work
requires this single round-7 planning successor. No stop question or Needs decision item is warranted for this supported
fallback. PARITY remains partial. No closure, waiver or receipt for any other task
is changed. Saving does not dispatch work; the existing authorized runner owns
execution and can continue to round 10. To stop, move the successor to Needs
decision using native tasks place.

## Planning validation and limits

Fresh-context read-only builder review of the saved records found **nothing
important left**: the loaded scalar-result fallback, existing safe Product oracles,
input/traversal/render bounds and named write set support implementation without
missing external inputs. The one low-severity source wording finding was corrected:
Desktop's 20,000-character payload limit adds its notice; Wing's planned total
paint bound is deliberately stricter. Building and its evidence-consuming successor
are sequential, not parallel. No implementation worker was dispatched.

Executed on the Linux host, planning only:

- Supplied `ca5765d0` CLI `capabilities`: prepare_api **4** with native tasks verbs;
  `tasks prepare --check .`: **READY**, converted store, task-reading runner and
  existing coordinator lease. No force, installation or runtime-state edit.
- Supplied CLI `tasks validate --worktree .`: **pass**, 314 tasks, 36 goals,
  no drafts; exactly three attributable task records pending this planning commit.
- `python3 docs/tasks/.check-round6.py` (temporary scoped readback): **pass**, 18
  local Markdown links/source anchors, 19 readable exact-pin bindings and critical
  fallback contracts, preserved original plan contract/notes and goal/timeline/
  BLOCKERS bytes, manual closure/no receipt, two-task round-7 chain, bounded
  Touches/check paths, integrated timeline ancestry and byte-stable readback.
  The temporary checker is not a product artifact. The unavailable model-picker
  object is explicitly excluded, not silently fetched or counted readable.
- `python3` with the installed Docs Sync `scripts/docs.py stale .` and `check .`:
  no `docs/roles.json` manifest; no manifest coverage claimed. Dedicated scoped
  readback above checks this batch's links and sources instead.
- `git diff --check`: **pass**; final scoped diff reviewed for unrelated changes,
  secrets, fabricated authority/qualification and accidental implementation.

The first native add input was refused because JSON contained both Sources and
notes; Sources was moved into the literal notes before either record was created.
No failed write or patch was forced through. No application platform was exercised:
no Flutter tests/builds, browser, native/device, live Agent/provider, screen-reader
or matched visual check ran in this pass. Proposed implementation checks remain
unrun. Local planning commit, canonical integration, dispatch and publication are
separate; PARITY is not qualified by this manual closure.
