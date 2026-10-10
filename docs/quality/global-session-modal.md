# Global owner-bound session modal

> Reference correction: [official Desktop authority](official-desktop-reference.md). Prior Desktop source citations and parity conclusions in this document are withdrawn. Wing test results remain historical behavior evidence only.


Task `t_ec0f2f99`; backlog `PORT-GLOBAL-SESSION-MODAL`; goal
`PARITY-COMPOSITION`. Implementation and deterministic qualification, not a
native/live-Agent parity claim. Native same-card review is the final delivery
step for this implementation phase; independent approval follows afterward.

## Delivered behavior

- [GlobalSessionScope](../../lib/features/hermes_chat/widgets/global_session_scope.dart)
  admits one dialog through the named Sessions control or Ctrl/Command+K over
  feature routes. Search receives initial focus; Flutter closed-loop traversal
  contains Tab/Shift+Tab. Escape/Close returns focus to the surviving opener.
  Held Enter/Space repeats cannot reopen the dismissed control.
- [ShellSessionAccess](../../lib/features/hermes_chat/widgets/shell_session_access.dart)
  reuses the existing public `HermesSessionsPanel`. It does not mount Chat,
  own a second inventory, or request session data when opened/reopened.
  Loaded local search, explicit Load more, contact-scoped pins and existing
  exact operation gates remain. An advertised sessions-list endpoint is
  checked for schema, method/path, required scopes and profile-query support;
  the existing null-capability compatibility behavior is retained.
- One pending action is admitted. Exact-session activation stays over the
  feature until the channel acknowledges that ID; successful activation closes
  the dialog and routes to Chat. Owner/resource/route loss latches invalidation
  across change-away-and-back and suppresses stale callbacks/navigation.
- Empty inventory differs from a read error. Failures remain redacted and allow
  explicit current-owner activation/pagination retry. Cancel/reopen does not
  replay New, prompts or approvals. Rename/fork/delete reuse the current channel
  contracts and reconfirm owner, capability and row identity after confirmation.

Agent remains authoritative. No API, credential, backend, runtime, startup read,
profile write or dependency was added. The existing route-local Chat panel uses
this same presentation with its previous defaults.

## Source identity and ownership

Qualification used the dirty shared Wing checkout at HEAD
`1afe1307e37ee1ddfa1f7d67ad047509e99c8784`, not a clean commit build.
Approved predecessor shell/session composition was preserved. Interactive
exclusions, predecessor tests/receipts, fixture/main_e2e, localization and
unrelated Go/dependency work were consumed without editing them for this card.

Read-only references: Hermes Desktop
`withdrawn reference revision`; Hermes Agent
`158fd638da1629c8e62caf9ade1515d162def8ab`.
The composition source investigation is recorded in
[profile-footer-composition](profile-footer-composition.md#reference-actions-and-current-wing-deviations).
Agent's advertised GET `/api/sessions` and per-session messages contracts remain
unchanged; Wing uses the existing `HermesChannel` implementation.

Ignored `.task-evidence/t_ec0f2f99/source-fingerprints.json` records SHA-256 hashes
of the five production files and three new test files. The task-only local
agent-branch commit is an integration snapshot: approved predecessor changes
in shared files are retained, but unrelated dirty files are not included.
Standalone branch compilation is NOT_CHECKED; the shared shell references
predecessor localization/composition work whose local branch was absent.
The scoped dependency lookup confirmed `shellSessionSource` is available in
the working-tree localization output but absent at HEAD; this card does not
commit the predecessor localization files. Integrate the approved predecessor
snapshots before claiming the task branch builds independently.
Passing checkout/build checks below must not be attributed to a clean isolated
agent-branch build. No packaging or excluded dependency files were changed to
hide this integration boundary.

## Acceptance evidence

| Criterion | Executed evidence |
| --- | --- |
| One global panel, search focus, containment, cancellation/focus return, held Enter | `app_shell_global_session_modal_test.dart`; Chromium `global-session-modal.spec.mjs` uses named control, real Tab/Shift+Tab, Ctrl+K/Meta+K, Escape and Close/Space. Focus crops compare rendered pixels and return traversal; widgets cover held-repeat admission. |
| Loaded search, explicit pagination gates, empty/error and retry | `app_shell_global_session_modal_actions_test.dart`: zero opening/reopening reads, one failed Load more plus one explicit retry, denied list endpoint hides Load more, empty/error distinction. Modal test covers one explicit activation retry. |
| Exact once-only activation after acknowledgement | Widget tests delay acknowledgement for both Enter and Space and reject duplicate activation. Chromium requests record one exact messages GET per deliberate activation, with feature route retained before navigation. |
| Owner loss, away/back, stale settlement/callback rejection | Modal tests cover profile, endpoint, disconnect/reconnect, capabilities, row removal, contact, directory, cancellation and route loss; action tests cover channel-provider replacement/return, stale captured callbacks and rename confirmation after owner return. |
| No replay/incidental work | Widget counters cover passive composition, cancelled New/reopen and approvals/prompt sends. Browser compares request counts across opening, search, cancellation and reopening; only intentional history reads are admitted. Explicit fixture connection/bootstrap reads are separate from passive composition. |
| Validation/build/browser receipt | Commands below passed after final production edits. Final browser rerun also captures the panel screenshot. |

Tests live at
[test/shared/widgets](../../test/shared/widgets/app_shell_global_session_modal_test.dart)
and [modal action tests](../../test/shared/widgets/app_shell_global_session_modal_actions_test.dart),
with the [compiled journey](../../playwright/tests/regression/global-session-modal.spec.mjs).
Some stale callback tests intentionally invoke captured callbacks as unit oracles;
they are not substitutes for the real keyboard acceptance journeys.

## Exact executed checks

Run from the repository root:

```sh
dart format --output=none --set-exit-if-changed lib/features/hermes_chat/widgets/global_session_scope.dart lib/features/hermes_chat/widgets/shell_session_access.dart lib/features/hermes_chat/screens/widgets/hermes_chat_sessions.dart lib/features/hermes_chat/screens/state/hermes_chat_connection.dart lib/shared/widgets/app_shell.dart test/shared/widgets/app_shell_global_session_modal_test.dart test/shared/widgets/app_shell_global_session_modal_actions_test.dart
flutter analyze
flutter test test/shared/widgets/app_shell_global_session_modal_test.dart test/shared/widgets/app_shell_global_session_modal_actions_test.dart test/shared/widgets/app_shell_global_session_access_test.dart test/shared/widgets/app_shell_grouped_recents_test.dart test/shared/widgets/app_shell_profile_footer_test.dart test/shared/widgets/app_shell_focus_traversal_test.dart test/shared/widgets/app_shell_test.dart test/features/hermes_chat/screens/hermes_chat_session_picker_test.dart --concurrency=1
flutter build web --release -t lib/main_e2e.dart
WING_APP_URL=http://127.0.0.1:8977/ CHROME_EXECUTABLE=/usr/bin/chromium npx playwright test --config=playwright.config.mjs playwright/tests/regression/global-session-modal.spec.mjs --workers=1 --output=build/global-session-modal-browser
git diff --check -- lib/shared/widgets/app_shell.dart lib/features/hermes_chat/widgets/shell_session_access.dart lib/features/hermes_chat/widgets/global_session_scope.dart lib/features/hermes_chat/screens/widgets/hermes_chat_sessions.dart lib/features/hermes_chat/screens/state/hermes_chat_connection.dart test/shared/widgets/app_shell_global_session_modal_test.dart test/shared/widgets/app_shell_global_session_modal_actions_test.dart playwright/tests/regression/global-session-modal.spec.mjs docs/quality/global-session-modal.md
python <home>/.hermes/shared-skills/repo-docs/scripts/goals.py validate <repo>
```

Results: formatter unchanged; analyzer no issues; 120 widget tests passed;
fresh release E2E web build passed; final Chromium journey 1 passed, zero captured
console/page errors. Scoped diff and goal validation results are recorded in the
native handoff after execution. Earlier harness/fixture corrections and failed
iterations do not qualify the final source; final tests/build do.

Small retained evidence under ignored `.task-evidence/t_ec0f2f99/`:
`widgets.log`, `source-fingerprints.json`, `global-session-modal-receipt.json`,
`global-session-modal-semantics.txt`, `global-session-panel.png`,
`modal-opener-focused.png`, `modal-opener-unfocused.png`,
`modal-row-focused.png`, and `global-session-modal.png`.
The browser receipt contains synthetic fixture requests and keyboard focus trace,
not credentials or live transcripts. Inspected final panel screenshot at
1280×900: focused search caret/border, two readable rows, active-row checkmark,
visible Close/New/Select controls and no clipped panel content.

## Independent review correction: New recovery

The first native review reproduced duplicate creation after a successful POST
followed by a failed initial history read. `ShellSessionAccess` now offers generic
Retry only for an existing session read or an acknowledged newly created ID that
is present in authoritative channel inventory. Partial success preserves that ID
and retries `selectSession`, never `createSession`. Uncertain creation failure has
no generic Retry; no idempotency/reconciliation contract is assumed. Existing
owner, route, cancellation and reopening fences are unchanged.

New regressions use the real `HermesApiChannel`/`HermesApiClient` with deterministic
transport injection for partial success and uncertain POST failure. The compiled
Chromium keyboard New/Space → Retry/Space journey observes one POST and two
messages GETs for the same acknowledged ID before navigation to Chat.

Rework checks executed on the same dirty shared checkout:

- The seven-file formatter command above: unchanged; `flutter analyze`: no issues.
- The eight-target focused widget command above: 122 passed. Log:
  `.task-evidence/t_ec0f2f99/rework-widgets.log`.
- `flutter build web --release -t lib/main_e2e.dart`: passed. Existing
  flutter_tts Wasm dry-run and Cupertino font warnings remain; this qualifies the
  JavaScript web build, not Wasm.
- `WING_APP_URL=http://127.0.0.1:8987/ CHROME_EXECUTABLE=/usr/bin/chromium npx playwright test --config=playwright.config.mjs playwright/tests/regression/global-session-modal.spec.mjs --workers=1 --output=build/global-session-modal-rework-browser`:
  2 passed, no retries. Both original containment/cancellation journey and new
  same-ID recovery journey passed.
- Scoped `git diff --check` and `goals.py validate`: passed; executed evidence is
  registered under `PARITY-COMPOSITION` with task `PORT-GLOBAL-SESSION-MODAL` done.

Transport fixture corrections during iteration fixed required history `object`
and session identity fields; a real async event-loop turn is awaited before the
retry settlement assertion. Initial fixture/analyzer failures are not passing
evidence. No excluded file, upstream, runtime, dependency or localization changed
for the review correction. Native/live-Agent and isolated branch qualification
limits above still apply.

## Qualification limits (unchanged)

Compiled deterministic Chromium on Linux was exercised, with reduced-motion
fixture setup. Native Linux/macOS/Windows, mobile, live authenticated Agent,
screen-reader output, packaging/distribution and full-suite verification are
NOT_CHECKED. Browser semantics and widget semantics are not screen-reader
qualification. Desktop itself was inspected, not executed. This slice does not
claim full-text server search, full native parity, new multi-conversation tabs,
or native application-menu accelerators. No live/device/system/publication
change was made. Questions: none; existing owner red-line defaults retained.
