# Repository work queue

`tasks/` is the authoritative repository work store. It tracks Wing engineering
work, not Hermes Agent profiles, Projects, sessions or runtime state.
The owner approved migration from `TODO.md` / `goals.json` on 2026-10-21.
Those two files are retired, not compatibility views or editable fallbacks.

## Current work queue

Current store counts and explicit waivers can be inspected without mutation using
`python scripts/report_task_status.py` (`--json` for structured output). Task
closure is not product/runtime acceptance. The current clone execution section
records the new pin, literal appearance and all five platform targets. Existing
live-task rows below preserve remaining outcomes even where their tasks were
closed by owner waiver; they are not a list of currently open task statuses.


- [Master plan: literal Desktop clone](../plans/2026-10-21-desktop-literal-clone.md):
  official-source comparison, 50 feature families and 16 implementation packages.
  This is the current owner-requested product direction, not a runtime parity
  verdict or task-admission receipt. Existing task contracts remain authoritative.

- [Complete pending-work checklist](pending-complete.md): owner-requested execution
  order and historical 86-task snapshot, annotated with current store counts. Existing task records
  remain authoritative; the checklist is a consolidated view, not another queue.

- [Task records](../../tasks/items/): one TOML-frontmatter Markdown file per stable ID.
- [Goal records](../../tasks/goals/): accepted outcomes, priority, focus and evidence.
- `tasks/evidence/` contains source-bound close receipts when the engine creates them.
- [Plan-to-task coverage](../plans/README.md#plan-to-task-coverage) maps retained plans
  to these records; plan checkboxes do not dispatch work.

Use the supported Autowork CLI from the repository root:

```bash
autowork tasks list .
autowork tasks show TASK-ID .
autowork tasks why TASK-ID .
autowork tasks validate --worktree .
```

Replace `TASK-ID` with an existing exact ID. `list` reads committed intent;
`--worktree` on supported inspection commands includes pending edits.
Change task/goal records through `autowork tasks`, not handwritten TOML or a
second queue. The native CLI resolves references inside task notes from the
repository root (for example `docs/plans/example.md#heading`), not from
`tasks/items/`; preserve that convention when maintaining `Sources:`.
Use `autowork tasks --help` and the relevant subcommand's help
for the installed interface. Planning records intent; it does not start workers,
resume schedules, authorize live access or certify product acceptance.

## Goals

### Owner-requested pending-work summary

This table summarizes the existing task records; it is not a second execution
queue or a completion receipt. Keep each task's original acceptance and gates.
The owner confirmed the local connection issue resolved; do not select it again
as an unresolved defect without new evidence.

| Task | Remaining outcome | Current gate and completed subset |
| --- | --- | --- |
| [ANDROID-CANONICAL-BOT-CHAT-LIVE](../../tasks/items/ANDROID-CANONICAL-BOT-CHAT-LIVE.md) | Bot Chat and per-profile sessions against a real Agent on Android | Emulator available; three deterministic Android-engine journeys delivered in `47d793a1`. Real Agent authentication, managed SSH, arbitration and native lifecycle/accessibility remain unqualified. |
| [ANDROID-CHAT-TOUCH-POLISH-LIVE](../../tasks/items/ANDROID-CHAT-TOUCH-POLISH-LIVE.md) | OS keyboard, Back, large text and mobile accessibility | Emulator available; five composer/accessibility engine cases delivered in `980f6fc1`. Framework input is not real IME/Back or TalkBack qualification. |
| [DOC-VOICE-QUALIFICATION-LIVE](../../tasks/items/DOC-VOICE-QUALIFICATION-LIVE.md) | Real microphone input and acoustic voice behavior | Physical device, capture/permission consent and acoustic checks; emulator results cannot close this task. |
| [PARITY-LIVE-WORKFLOW-LIVE](../../tasks/items/PARITY-LIVE-WORKFLOW-LIVE.md) | Generation, approvals, authoritative Stop and exact recovery | Disposable authenticated QA target, exact grants and supported provider-call admission remain required. |
| [VERIFY-DESKTOP-NATIVE-DELIVERY](../../tasks/items/VERIFY-DESKTOP-NATIVE-DELIVERY.md) | Install, update and client-only uninstall with retained data | Approved disposable Linux target and artifact/recovery evidence; a local build or launch is not delivery qualification. |
| [FILES-TERMINAL-BROWSE](../../tasks/items/FILES-TERMINAL-BROWSE.md) | Bounded file browser and read-only previews | Safe Agent root/authentication/containment contract remains unverified. Positive implementation is deferred; no shell or Agent modification substitute. |
| [FILES-TERMINAL-DOWNLOAD](../../tasks/items/FILES-TERMINAL-DOWNLOAD.md) | Explicit verified file download to the device | Depends on `FILES-TERMINAL-BROWSE` and its authoritative root/access guarantees. |

Do not repeat the delivered emulator slices as new feature implementation. Mark
the full tasks done only after their remaining acceptance has executed successfully.

Goal status and sources live in the [goal records](../../tasks/goals/), linked
by each task's `goal` field. Preserve unmet and unverified outcomes even when
an offline implementation is done. Native/device, live-Agent and delivery gates
remain separate and require their own executed evidence. Missing contract fields
remain visible drafts, not implicit permission to execute.

## Migration and history

The supported `autowork migrate` transaction preserved all 281 task IDs and
36 goals, task statuses and goal assignments, open sections, priority and selection
order. All 79 open tasks were in Needs decision. This is migration evidence, not
new implementation, runnable-work admission or live qualification.

Seven migrated tasks retain missing-check drafts; no commands were invented to
make them executable. `M2-DEVICE-QUALIFICATION` also retains its original
owner-provided-device/admission prerequisite as an unresolved dependency. Keep
these records in Needs decision until accepted evidence supplies the missing
contract; migration does not remove that gate.

The [frozen archive](../../todo.archive.md) retains completed task bodies and
original receipts unchanged. Its original links and old command transcripts are
historical; do not treat them as current operating instructions. Earlier queue
snapshots remain available in Git history (`git log --all -- TODO.md goals.json`).
Historical scripts bound to those snapshots, including
`check_desktop_next_port_slice.py`, are not current-store validators.

## Documentation owners

[The docs index](../README.md#document-ownership) maps accepted requirements,
current design, verification and operational guidance. [Contributor setup](../../CONTRIBUTING.md)
owns supported development commands. Use Python 3.11+ for the tooling test that
reads TOML task records; the native Autowork validator owns complete store-schema
validation, while the plan regression checks plan IDs, body isolation and backlinks.
