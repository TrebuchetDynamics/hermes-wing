# Repository work queue

`tasks/` is the authoritative repository work store. It tracks Wing engineering
work, not Hermes Agent profiles, Projects, sessions or runtime state.
The owner approved migration from `TODO.md` / `goals.json` on 2026-10-21.
Those two files are retired, not compatibility views or editable fallbacks.

## Current work queue

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
second queue. Use `autowork tasks --help` and the relevant subcommand's help
for the installed interface. Planning records intent; it does not start workers,
resume schedules, authorize live access or certify product acceptance.

## Goals

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
