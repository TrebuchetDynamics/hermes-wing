# Desktop continuation — native model-read design review, 2026-10-04 02:25

> Reference correction: [official Desktop authority](official-desktop-reference.md). Prior Desktop source citations and parity conclusions in this document are withdrawn. Wing test results remain historical behavior evidence only.


## Result

**The existing native proposal is not yet sufficient to restore an authoritative
session provider/model pair.** Its direct-API path can restore model text but not
the confirmed pair. More importantly, the proposed native `lazy: true` resume is
a watch-mode attachment, not a general persisted-runtime read. Default cold and
eager resume can schedule an Agent-owned continuation after a crash marker; they
must not be described as passive reconciliation reads.

This is a source/design review, not independent security acceptance, a runtime
failure reproduction or implementation approval. No production or test changes,
transport migration, Agent mutation, auth provisioning or browser retry occurred.
The integrated picker restoration oracle remains intact and failed.

## Ownership and admission

The [goal ledger](../plans/2026-10-03-desktop-port-goal.md) and previous occurrence's
final session release ownership after the requested 2,402-test npm run. Fresh
`hermes cron list` shows this occurrence running and hourly autogoal completed.
Native delegation/terminal lists are empty; filtered OS QA census is empty.
One direct owner leased only this receipt and goal ledger, with wing scratch
artifacts. The native design, ROADMAP, implementation, tests and upstreams are
read-only. No process-local children or QA resources were started.

Dependency order: source review first; separately scoped design clarification
next; operation approval and runtime qualification before any privileged code.
The exposed `todo_list` tracked these phases. OMH-specific routing/accounting
wrappers were not exposed; no external executor or parallel coding lane was used.

## Indexed findings

### P1 — direct model-lock write does not imply restored-pair read

[Native proposal:77–78,91–95](../plans/2026-10-03-desktop-local-integration-design.md)
groups model selection and restoration into the initial direct-API workflow.
Its exact-operation caveat is sound, but its restoration requirement does not
explicitly separate model text, a previously acknowledged lock and current
provider/model readback. The [prior read-authority assessment](2026-10-04-desktop-cron-0147-runtime-pair.md)
correctly identifies this gap.

Fresh source inspection confirms [Agent `_session_response`:3011–3043](../../hermes-agent/gateway/platforms/api_server.py)
projects model text and presence flags, deliberately not full model configuration
or provider/runtime/lock. [Lock POST:3797–3826](../../hermes-agent/gateway/platforms/api_server.py)
returns accepted runtime only after a write. These are distinct contracts.
[Wing decoder:31–55](../../lib/core/hermes/models/hermes_session.dart) consumes model
text, not a restored confirmed pair. [Metadata-only regression](../../test/features/hermes_chat/screens/hermes_chat_model_authority_test.dart)
checks no confirmed lock, duplicate model IDs across providers, cancellation and
zero mutations; its previously executed receipt is [02:04](2026-10-04-desktop-cron-0204-authority.md),
not a test executed in this occurrence.

**Exit criterion:** any design claiming restored selection must identify an exact
authorized session read and distinguish acknowledged selection from effective or
pending runtime. Missing fields/error/revocation stay unconfirmed. No inferred
provider, durable shadow pair, synthetic runtime decoder or repeated lock POST.

### P1 — native lazy resume is not persisted pair recovery

[Proposal:113](../plans/2026-10-03-desktop-local-integration-design.md) names qualified
`lazy: true` recovery. [Native Params:182–202](../../hermes-agent/tui_gateway/contracts/sessions.py)
declares lazy, deferred and eager options but does not promise equal behavior.
[Dispatch:1052–1061](../../hermes-agent/tui_gateway/methods_session.py) first reuses a
live session in the requested profile; only absent live state reaches cold lazy.

[Cold lazy branch:906–929](../../hermes-agent/tui_gateway/methods_session.py)
is explicitly a child/watch path: child-only history, no agent, and no
`_stored_session_runtime_overrides` call. Its response calls
[`_lazy_resume_info`:2828–2836](../../hermes-agent/tui_gateway/server.py) without a
stored pair, which falls back to the profile model and may omit provider. It also
reopens the stored session and repairs history; it is not side-effect-free GET.
A warm reattach can return a session's own pair via
[`_live_session_identity`:2305–2317](../../hermes-agent/tui_gateway/server.py),
but that helper prioritizes pending switch display identity, then mirror/agent/
override. This is not the HTTP browser-lock acceptance contract.

Nearest [warm reattach tests:86–107](../../hermes-agent/tests/tui_gateway/test_resume_live_lazy_session.py)
assert override-only, built-agent and pending-switch results. They do not prove
cold lazy restoration; inspected, not executed here.

**Exit criterion:** separately qualify warm, cold lazy, deferred and eager cases
against the actual chosen transport. A warm success must not stand in for
process-death recovery. Keep stored ID, runtime ID, profile and origin explicit;
report pending/effective/confirmed identity distinctly. Native reply fields can
include private host paths, so project only reviewed bounded fields.

### P1 — cold/eager native resume may generate without a new client submit

[Cold resume:953–972 and eager:975–1033](../../hermes-agent/tui_gateway/methods_session.py)
restore runtime overrides and call `_maybe_schedule_auto_continue`. The
[auto-continue implementation:22–32,58–130](../../hermes-agent/tui_gateway/session_auto_continue.py)
defaults to enabled, checks a fresh durable crash marker and schedules an
Agent-owned continuation through `_run_prompt_submit`. The [nearest test:381–395](../../hermes-agent/tests/tui_gateway/test_auto_continue.py)
expects running state and `message.start`; inspected, not executed.

Thus zero Wing POSTs or zero `prompt.submit` frames alone would not prove zero
new generation. This is Agent behavior, not a demonstrated Wing replay bug, and
must not be patched, disabled in personal config or bypassed by Wing. The proposal's
[no-replay controls:201 and test gates:215–217](../plans/2026-10-03-desktop-local-integration-design.md)
need server-turn counts and crash-marker cases as well as client request counts.
The deferred branch carries stored overrides without a direct auto-continue call
in the inspected body, but this bounded observation does not qualify its full
hydration/build/next-turn path or select it for production.

**Exit criterion:** on an approved isolated target, prove behavior with/without a
fresh marker and with a still-live owner, counting server turns and canonical
history as well as client sends. Resolve automatic server continuation explicitly
before adopting resume as reconciliation. No global config write, marker edit,
new guessed opt-out parameter or indirect stop-after-start workaround.

### P2 — broad reads and Desktop storage cannot fill the gap

[`config.get provider`:184–189](../../hermes-agent/tui_gateway/methods_config.py)
resolves a config model and derives its provider; it is not an exact confirmed
session-lock read. [`session.status`:472–481](../../hermes-agent/tui_gateway/contracts/sessions.py)
returns rendered output text, not a structured pair contract. Do not scrape it to
invent authority. [Desktop override store:5–74](official-desktop-reference.md#withdrawn-evidence)
is explicitly Desktop-owned local SQLite routing state. Borrowing it violates
Wing's [no-shadow-state and no-Agent-file boundary](../adr/runtime-and-delivery.md).

The proposal already correctly blocks token URLs, generic RPC/config keys and
privileged Desktop storage. Keep these controls and its independent native-auth
review prerequisite; in-process locality does not manufacture missing authority.

## Executed evidence

Reference status/HEAD commands exited 0: Agent `158fd638da1629c8e62caf9ade1515d162def8ab`
clean; Desktop `withdrawn reference revision` retains existing deleted
`.claude` entries; Conduit `67a2e8de6b39d2086f59149e0f5fd8b1d44c1fe6` clean.
No Conduit source research or mutation was needed. Dirty Wing HEAD is not a
content snapshot. `lat` is absent on PATH; no install/key provisioning/wiki edit
or Desktop verification command was attempted.

Scratch: `<home>/.hermes/profiles/wing/cache/scratch/desktop-cron-0225-native-model-review/`.

- Read-only ownership/process/scheduler/time commands: exit 0.
- Python AST inspection of four actual resume branch bodies: exit 0;
  `resume-branch-source-check.json` records direct call sets and line ranges.
  It checks absence of stored-runtime restoration in cold lazy and presence of
  auto-continuation calls in cold/eager branches. This is a bounded static check,
  not an exhaustive parser run, handler execution or behavioral regression test.
- `source-before.json` pins 15 initial consumed files; `additional-source-pins.json`
  pins six subsequently inspected files. One guessed sibling path did not exist;
  source search resolved `methods_config.py` instead. No missing-file contract claim.
- Closing source/document gate is recorded in `close.json`: unchanged pinned
  content, existing local-link targets, whitespace and scoped `git diff --check`.
  No Flutter/upstream tests/builds ran; unchanged suites were not repeated.

## Next bounded checkpoint

1. **Design clarification only:** separately lease the existing native design's
   authority-map restoration row, native RPC resume/models bullets and phased
   test gates, plus ledger and a new receipt. Incorporate the three P1 requirements
   above without altering its accepted topology or enabling a transport. Validate
   local links/scoped diff; preserve ROADMAP, browser oracle and production/tests.
2. **Contract qualification remains blocked:** exact pair read and native resume
   semantics require separately reviewed authority/auth and approved isolated
   execution. Source declarations alone do not authorize an adapter or live call.
3. Native process relaunch, final integrated picker/Escape/resume/count stages,
   actual owner-selected provider inference and independent acceptance remain open.

Ownership is released after the closing gate. No services/displays/browsers or
persistent workers were launched, so no QA cleanup handle remains. This review
creates no new capability or acceptance claim.

Run summary: not_available — host accounting was not exposed.
