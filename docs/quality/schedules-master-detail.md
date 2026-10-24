# Schedules list and detail: bounded Desktop parity

Date: 2026-10-24. Official reference: NousResearch/hermes-agent
`14e1e43a23761b369641208e204365cd6cb9399d`.

## User outcome and source

The Schedules screen now presents an alphabetical selectable job list beside one
job's details when at least 820 logical pixels of content width are available.
The selected job is retained through same-owner inventory refreshes and filtering;
when it is filtered out, the first visible job supplies the detail without
rewriting the explicit selection. A changed host, profile, connection or exact
read authority discards the prior owner's selection and controls.

Source: [`apps/desktop/src/app/cron/index.tsx`](https://github.com/NousResearch/hermes-agent/blob/14e1e43a23761b369641208e204365cd6cb9399d/apps/desktop/src/app/cron/index.tsx),
`visibleJobs`/`selectedJob` derivation and the `PanelList`, `CronJobListRow` and
`CronJobDetail` composition. The pinned source was downloaded read-only for this
comparison; the installed Agent and its reference working tree were not modified.

At narrow widths or enlarged text the list opens one detail with an autofocusable
Back control. Back returns to the retained search/filter state; system Back also
returns to the list before leaving the screen. If a selected job disappears, the
compact view returns to inventory instead of opening another job implicitly.
These are Flutter accessibility adaptations of the two-pane presentation.

The existing exact-advertised `GET /api/jobs` and required grant remain the only
Agent operation. Navigation, selection and search perform no additional reads or
writes. Read-only restrictions, safe metadata bounds and generic last-error
notices are preserved. Full Cron mutation, blueprints, run history/session links
and live scheduling remain separate gaps.

## Validation

Linux Flutter widget renderer, Flutter 3.44.2 / Dart 3.12.2. Existing lockfile
unchanged. The five initial list/detail regression cases failed against the old
stacked-card composition before implementation.

- `flutter pub get --offline --enforce-lockfile`: passed.
- `dart format lib/features/schedules/screens/schedules_screen.dart test/features/schedules/schedules_master_detail_test.dart test/features/schedules/schedules_screen_test.dart`: passed.
- `flutter test --no-pub --concurrency=1 test/features/schedules`: **102 passed**, serial, no new skips.
- `flutter analyze --no-pub`: no issues.
- `git diff --check`: passed.

The focused tests cover alphabetical ordering, selected-detail changes, visible
fallback after filtering, same-owner retention, profile reset, rejection of stale
selection callbacks, keyboard row activation, compact Back at 100/200%, selected
job disappearance, existing read-grant/refresh/ownership cases and long details
at 320px/200%. The initial retained layout assertions were updated to select a job
before checking its detail and to verify the new title ordering.

These are deterministic widget checks. Compiled Chromium, native Linux, Android,
macOS/Windows and live Agent scheduling are not qualified by this receipt. The
integration owner runs the broader final-candidate checks separately.
