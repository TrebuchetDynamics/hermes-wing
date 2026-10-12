# Profile editor legacy approval consumer retirement

Task: `t_3ff062b1`; continuation of CONNECTION-LINK-REMOVAL / CONNECTION-PATHS.
Base: `bb3e334b3068c21f8f5039d2d9ba981a32437dd7`.
Status: local implementation and Linux deterministic checks; independent native
review and coordinator integration remain pending. The parent remains in progress.

## Admission and scope

The original `pass_workspace.py` invocation with the selected manifest and
`--manifest-sha256 4b24fefcb52b188c021a731245d961baaa2303c4063db4091fb901486fcce4d2`
returned `worker_start_admitted` before the first test or production edit.
The original tool history, not this receipt, establishes that ordering. Do not
rerun admission against the edited candidate or refresh the manifest.

Owned files only:

- `lib/features/profiles/widgets/profile_editor_sheet.dart`
- `test/features/profiles/profile_editor_sheet_test.dart`
- `test/tooling/enrollment_retirement_contract_test.dart`
- this receipt

No caller closure expansion was needed. No core Link service/transport, saved
contact/store, directory adapter, localization, dependency or upstream edits.
No user records or credentials were accessed, migrated or removed. Android
connection ordering (SSH, Remote server, Termux) is unchanged.

## Caller and error provenance

Production construction sites are
[Profiles](../../lib/features/profiles/screens/profiles_screen.dart) `_openEditor`
and [Persona](../../lib/features/soul/screens/soul_screen.dart). Both supply a
`HermesChannel`, not Link create/delete callbacks. Optional supported callbacks
and configuration/catalog controls remain reusable; their legacy retry-key
parameters are removed. Existing test callbacks with additional optional
parameters still type-check, and failure tests assert that no key is supplied.
Neither production construction site enables the configured credential form.

The direct channel trace is
[profile mutations](../../lib/core/hermes/channel/api_channel/hermes_api_channel_profiles.dart)
→ [Agent client](../../lib/core/hermes/client/hermes_api_client.dart).
Create requires the exact POST endpoint and grants. Rename/delete require their
exact endpoints, grants and nonblank revisions. The client passes `If-Match`,
verifies deletion's identity/envelope, and throws Agent status exceptions, not
Link approval/precondition types. `_runProfileMutation` reconciles on success or
412, rethrows failures and drops stale connection refreshes; it never replays a
mutation. Nearest regression suites are
[channel tests](../../test/core/hermes/channel/hermes_api_channel_test.dart) and
[client tests](../../test/core/hermes/hermes_api_test.dart).

Read-only Agent reference inspected at
`158fd638da1629c8e62caf9ade1515d162def8ab`:
`hermes_cli/web_routers/profiles.py` create/rename/delete/SOUL handlers,
`tests/hermes_cli/test_web_server_profile_unification.py` create validation,
`tests/hermes_cli/test_profiles.py` rename lifecycle, and
`tests/hermes_cli/test_web_profile_soul_writes.py` write durability.
These handlers delegate to Agent profile operations; none returns the retired
Link approval contract. The inspected dashboard response/body shapes differ from
Wing's revision/envelope contract (for example `new_name`, `content`, `ok`).
This removal does not adapt those shapes or establish live compatibility. Wing's
exact advertised-contract gates remain authoritative; missing contracts stay
unavailable, without a fallback or an upstream modification.

## Smallest complete deletion

Decision: delete the Link exception import, pending approval record, timer,
expiry handling, frozen approval state, host approval instructions and approved
retry controls. There is no supported production consumer to preserve.
Unknown approval-shaped failures use the existing generic failure UI, not a new
approval abstraction. Only Agent HTTP 412 is classified as a revision conflict.

Credential clearing formerly hidden inside `_clearPendingApproval` now stays
explicit at owner changes, cancel, disposal, successful completion and current
failure. Mutation/persona owner generations, same-frame revocation, stale async
fences and SOUL conflict reconciliation are otherwise unchanged. Every delete,
including an explicit retry, opens a fresh typed-name confirmation. Save can
never retry a failed delete. No timer, reconnect or owner restoration resubmits.

## Acceptance evidence

- Negative production dependency guard: added and run RED before production
  removal, failing on `core/wing_link/`; GREEN in the final focused suite.
- Direct create, rename, delete and SOUL: existing editor, production channel,
  client, Profiles and Persona tests pass with exact revision/identity assertions.
- Destructive retry: replacement tests cover Agent 412, Agent 403 and an unknown
  approval-shaped failure; advancing time and pressing Save issue no delete.
  Retry requires the exact name again; blank/wrong names cannot dispatch.
- Secret lifecycle: tests cover current create failures, success, cancel,
  disposal and synchronous owner loss. Late failure after owner A→B→A cannot
  display an error or replay; a stale rendered Create callback is denied.
- Owner/reconciliation protection: unchanged ownership suites exercise same-frame
  capability/grant/source loss, stale reads/writes and conflict reload/retry.
- Scope/privacy: scoped diff inspection, unchanged dependency manifests, no new
  domain state, approval token, transport or persistent storage.

Executed commands (exit 0 unless explicitly noted):

```sh
flutter pub get --offline
git diff --exit-code -- pubspec.yaml pubspec.lock
dart format lib/features/profiles/widgets/profile_editor_sheet.dart test/features/profiles/profile_editor_sheet_test.dart test/tooling/enrollment_retirement_contract_test.dart
flutter analyze --no-pub
flutter test --no-pub --concurrency=1 test/features/profiles test/features/soul test/features/gateway test/shared/widgets/app_shell_profile_footer_test.dart test/tooling/enrollment_retirement_contract_test.dart
flutter test --no-pub --concurrency=1 test/core/hermes/channel/hermes_api_channel_test.dart test/core/hermes/hermes_api_test.dart
git diff --check
```

The required suite passed 301 tests (57 seconds); the additional Agent
channel/client suite passed 435 tests (2 seconds). Analysis reported no issues
(6.3 seconds). The first editor/contract iteration had one test-only failure:
a text finder could not find Create while the button displayed a spinner.
Capturing the rendered callback before submission fixed the probe; the production
owner fence remained unchanged. The RED dependency guard's expected failure is
not a remaining validation failure. Acceptance is rerun by `finish_task.py`
against frozen owned files before its exact task-ref commit is handed to review.
That helper receipt binds the final commit; this document cannot include its own
future commit identity. Review must inspect original admission history and the
exact commit/ref, then test an independent snapshot.

## Remaining qualification and milestone gaps

Implemented: this bounded editor dependency retirement. Qualified: deterministic
Flutter unit/widget/source-contract tests on Linux only. Delivered: NOT_CHECKED;
no canonical integration, push, build, image run, deployment or live operation.
Browser, Android/device and live-provider/runtime compatibility are NOT_CHECKED.
Required independent review is pending, not approval implied by tests.

CONNECTION-LINK-REMOVAL is not closed. Directory adapters and saved management
credential APIs remain; packaging/service retirement is a later dependency.
No new task was selected or enqueued. The coordinator owns subsequent integration,
canonical ledger closure and profile-local journal reconciliation; this worker's
writes remain inside the isolated workspace and bounded file scope.
