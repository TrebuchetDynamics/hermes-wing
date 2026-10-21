# SSH failure feedback through owned cleanup

## Scope

Status: Accepted

The owner required code-first diagnosis and useful, non-silent SSH failures.
The current request adds missing plans and task coverage, not implementation or
live reproduction. Reuse **WING-001-b3**, the previously saved but unqueued task;
append it after existing Next priorities. No duplicate SSH implementation task,
new diagnostics screen, transport support or Agent change is admitted.

## Source-backed gap

Rechecked Wing `d13b748a4d5b8d5a580f2e0735fbb08387cb2238`. The earlier mechanism
remains present despite intervening edits: advertised API bootstrap publishes a
typed Agent error; unsuccessful controller adoption joins cancellation/teardown,
which clears channel state; `false` reaches generic SSH presentation. Explicit
Android serve failure follows the same loss of classification. This is not proof
that every attempt is silent. The supplied screenshot already displayed a generic
error, and the phone's underlying connection failure remains unknown.

Read these existing seams and all callers before editing:

- [controller](../../lib/features/hermes_chat/providers/managed_ssh_connection_controller.dart)
- [API connection](../../lib/core/hermes/channel/api_channel/hermes_api_channel_connection.dart)
- [serve reads](../../lib/core/hermes/channel/api_channel/hermes_api_channel_serve_reads.dart)
- [panel](../../lib/features/hermes_chat/widgets/managed_ssh_connection_panel.dart)
- [form](../../lib/features/hermes_chat/widgets/managed_ssh_connection_form.dart)
- [forwarding contract](../security/managed-ssh-forward-contract.md#forwarding-and-lifecycle)

Current tests establish rejection/cleanup and generic copy, not production-channel
classification reaching visible UI after cleanup. Existing 320px/200%-text form
coverage proves navigation/validation, not a new terminal summary being revealed
or deliberate retry becoming reachable when the user scrolled away.

## Smallest complete implementation

1. Add a RED composed production-channel test: verified fake SSH forward plus
   deterministic Agent 401/403 rejection, held then settled cleanup, real localized
   panel/form. Require an Agent-authentication explanation and zero success calls.
2. Preserve only an allowlisted stage/category for the captured current attempt
   before cleanup clears it. Deliver it after owned teardown to the still-current
   panel. Reuse `ManagedSshFailure`/`HermesConnectionFailureKind`; no raw exceptions,
   error-string parsing, global last-error cache or new protocol. If a return
   contract changes, update every caller/test together; keep cleanup joined.
3. Reuse the summary/live region above Connect. Reveal a new owned terminal failure
   with the minimum scroll/focus coordination. Retain non-secret fields, clear
   attempt secrets/key selection as today and allow retry only after cleanup.
   Reuse accurate localization; edit English ARB and regenerate if copy changes.
4. Add explicit serve rejection, incompatible selected surface, SSH auth/timeout,
   proven storage denial, unknown fallback, positive-ready and stale/cancel cases.
   Storage denial is classified at the storage operation, never from arbitrary text.

## Acceptance and verification

- A completed unsuccessful current acquired attempt has persistent localized,
  non-color-only feedback and a deliberate next action; no false connected state
  or indefinite busy state once owned cleanup settles.
- Both API and explicit serve authentication failures survive teardown as Agent
  failures, not invented SSH diagnoses. Unknown remains safely generic.
- At 320x480 and 200% text, reduced available height and scroll-up-during-pending,
  the actual terminal feedback and retry are visible/reachable without test-side
  `ensureVisible` fabricating success. Check bounds/hit testing, live-region
  semantics, keyboard retry with fresh credentials and no overflow.
- Positive configured fixtures reach exact profile/history and call success once;
  deliberate retry starts one attempt. Zero automatic redial, protocol fallback,
  remote probe, prompt/approval/Stop replay, inference or service command.
- Cancel/dispose/mode/route/controller-owner replacement and late results cannot
  repaint or disconnect a new owner. Changed/denied host keys still fail closed;
  secrets/private endpoints/paths stay out of feedback, logs and fixtures.

Planned commands, **not product-test passes from this planning task**:

```sh
flutter test --no-pub --concurrency=1 test/features/hermes_chat/widgets/managed_ssh_connection_panel_test.dart test/features/hermes_chat/widgets/managed_ssh_connection_form_test.dart test/features/hermes_chat/providers/managed_ssh_serve_reads_test.dart test/features/hermes_chat/providers/managed_ssh_serve_test.dart test/features/hermes_chat/providers/managed_ssh_session_recovery_test.dart test/features/hermes_chat/screens/hermes_ssh_no_cli_test.dart test/features/hermes_chat/screens/hermes_connection_primary_entry_test.dart test/core/hermes/ssh/
flutter analyze --no-pub
git diff --check
```

Run `flutter gen-l10n` only if copy changes; format explicitly changed Dart files.
Shared channel/lifecycle edits also require affected broader channel/Chat tests.
Native SSH, secure storage, actual IME/TalkBack, installed APK and live Agent
reachability remain with the existing authorized native/live tasks. Feedback
repair is not a claim that the reported phone now connects.

## Backlog connection

`WING-001-b3` in [work queue](../tasks/work-queue.md#current-work-queue) owns this implementation under
`REMOTE-BACKENDS`, dependent on completed `BACKEND-SSH-CONNECT`. Existing
`BACKEND-SSH-CONNECT-LIVE` and `BACKEND-SSH-KEY-NATIVE-LIVE` retain external proof;
no duplicate device tasks or new live authorization. The
[plan-to-task coverage](README.md#plan-to-task-coverage) indexes the plan; the
central queue and `goals.json` own scheduling. No worker was dispatched here.
