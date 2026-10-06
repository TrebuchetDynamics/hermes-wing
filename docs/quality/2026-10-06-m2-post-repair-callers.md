# M2 post-repair loaded-session callers — 2026-10-06

Card: `t_103d63ec`. Ledger task: `DOC-M2-POST-REPAIR-CALLERS`.
Disposition: current-source deterministic qualification, ready for native same-card
review. **M2 remains unverified; authoritative_counts_unavailable.**

## Delivered outcome

The older approved compiled loaded-session receipt on `t_d06ef06d` predates shared
history/recovery repairs. This fresh isolated release build and existing keyboard
journey qualify the loaded-session Open/New callers on the current dirty-source
snapshot, rather than attributing the older pass to changed inputs. No production,
upstream, dependency, product architecture or existing test assertion was changed.
There was no reproduced production failure and no production repair is claimed.

The source-bound mirror is `.task-evidence/t_103d63ec/mirror/`. It copies current
`lib/`, `test/`, `integration_test/`, `web/`, assets, localization/manifests and
Playwright source/helpers/configuration. It does not copy upstream checkouts,
`tools/`, private runtime state, root dependency/build caches or old build output.
Offline `flutter pub get` and `npm ci --offline --ignore-scripts` resolve existing
locked dependencies inside that mirror; no system installation or new dependency
was needed. All Flutter tests, analysis and compilation run there, never in the
shared root. The user's orphan root tester is untouched.

## Caller and authority trace

- `shell_session_access.dart:58–80,120–179` binds current channel, lifetime,
  directory/contact, exact history/create authority, settled owner and loaded row
  to synchronous and asynchronous admission. Successful exact acknowledgement,
  not navigation-first intent, returns to Chat. Same-frame replacement does not
  revive an old action.
- `hermes_api_channel_connection.dart` and `hermes_api_channel_sessions.dart` retain
  the repaired shared hydration/pagination gate. `_fetchTurns` validates exact
  history authority and owner before publishing history/offset. Open/create pass
  their existing `canAccept` fence through that shared path.
- The existing production-directory lifetime test confirms passive shell
  observation never starts/constructs a directory, including detach/reattach and
  invalidation. It exercises the real provider rather than a new shell store.
- `playwright.config.mjs` selects installed Chromium; `serve_web.mjs` serves this
  mirror's fresh `build/web` and imports the existing deterministic lifecycle
  fixture. The unchanged acceptance spec imports `flutter_semantics.mjs` and
  `inventory_keyboard.mjs`. `WING_APP_URL`, `PORT`, `HERMES_E2E_PORT` and
  `CHROME_EXECUTABLE` select the mirror-owned loopback fixture, not a live Agent.
  No shared server or port was borrowed.

[Source inputs](../../.task-evidence/t_103d63ec/source-inputs.json) bind 519 copied
files, including current localization and locked manifests. The
[local import closure](../../.task-evidence/t_103d63ec/dependency-closure.json)
traces 188 files from the web entrypoint, server, config and acceptance spec,
including Dart conditional imports/parts and all local browser helper imports.
[Build input receipt](../../.task-evidence/t_103d63ec/build-dependency-inputs.json)
adds compiler depfile input hashes and resolved package configuration/graph hashes.
[Build outputs](../../.task-evidence/t_103d63ec/build-output-hashes.json) bind all
35 fresh release output files. This is build attribution, not packaging/release
qualification. No delivery manifest change was necessary.

The capture helper initially mistook a localization documentation example for an
import. Only the task-owned closure parser was corrected to parse anchored import,
export and part statements, including conditional Dart imports. No copied source
or assertion changed, and no runtime checks failed. The corrected closure and
source/mirror integrity checks pass. Existing acceptance needed no harness repair.

## Executed commands

Exact argv, absolute cwd, exit, duration and log SHA-256 are retained in
[commands.json](../../.task-evidence/t_103d63ec/commands.json). Each command below
runs from `.task-evidence/t_103d63ec/mirror/` and exits 0:

```text
flutter pub get --offline
flutter test --no-pub --concurrency=1 --reporter=json
  test/shared/widgets/app_shell_global_session_access_test.dart
  test/features/hermes_chat/gateways/hermes_directory_lifetime_test.dart
  test/core/hermes/channel/hermes_session_caller_admission_test.dart
  test/core/hermes/channel/hermes_recovery_read_admission_test.dart
flutter analyze --no-pub
flutter build web --release -t lib/main_e2e.dart
npm ci --offline --ignore-scripts
npx --no-install playwright test --config=playwright.config.mjs
  playwright/tests/regression/global-session-access.spec.mjs
  --workers=1 --retries=0 --output=browser-output
dart format --output=none --set-exit-if-changed
  test/shared/widgets/app_shell_global_session_access_test.dart
  test/features/hermes_chat/gateways/hermes_directory_lifetime_test.dart
  test/core/hermes/channel/hermes_session_caller_admission_test.dart
  test/core/hermes/channel/hermes_recovery_read_admission_test.dart
```

Parsed focused result: **85 passed, zero failed/skipped**: 44 shell widget cases,
one production directory-lifetime case, eight production caller-admission cases,
and 32 recovery-read admission/denial/replacement controls. The shell target is
the same complete 44-case neighborhood recorded in the prior approved
`t_d06ef06d` receipt. No broad predecessor gate was replayed. Analysis reports
“No issues found”; the four scoped Dart files need no formatting changes.

The current-source denial controls include wrong history method/path/schema,
ungranted scopes and unsupported profile context; granted and omitted legacy
positive controls; canonical identity/compaction; unresolved lease persistence
through recreation; and origin/profile/session/connection replacement before
late status/history publication. Shell controls additionally retain silent late
rejection, pending single-flight, cached callback invalidation, row removal,
route/collapse/disposal and channel/lifetime change-back, disabled unsettled
states, named semantics, keyboard navigation and 200% text/reduced motion.

Compiled browser result: **one expected Chromium pass, zero unexpected, flaky or
skipped**, workers=1, retries=0. Installed runtime evidence: Flutter 3.44.2,
Dart 3.12.2, Node 26.7.0, npm 11.19.0 and Chromium 152.0.7977.75. Node differs
from the documented Node 22 default; this receipt does not qualify Node 22.

The owned server was `node serve_web.mjs` on loopback ports 46831/33693.
[Fixture receipt](../../.task-evidence/t_103d63ec/fixture.json) records argv/cwd,
owned PID and the four explicit environment overrides. Readiness was checked
before Playwright; only that fixture was terminated afterward and its exit was
retained. No live request, credential, provider inference or device action ran.

## Browser acceptance and retained predecessor

[Browser receipt](../../.task-evidence/t_103d63ec/attachments/global-session-receipt.json)
and [semantics](../../.task-evidence/t_103d63ec/attachments/global-session-semantics.txt)
retain actual requests, key/focus trace and empty page-error list. The unchanged
spec proves Tools → exact Open → Tools → deliberate New, with these boundaries:

- Open issues exactly one history GET for `synthetic-global-other`, with
  `profile=default`, `limit=500`, `offset=0`, `order=latest` and no mutation.
- New issues exactly one profile-scoped session POST and one exact created-session
  history GET. No second create, send, approval or Stop is attempted.
- Enter/Space activate exact named controls after Tab/Shift+Tab reach/escape.
  Focused/unfocused Open and New crops are retained; their rendered pixels differ.
- Collapse removes session controls; expand restores them; the 390px More →
  Settings → Chat path returns to the created session. Resize back to 1280px
  preserves that tuple. Layout/navigation adds zero API requests.

[Browser results](../../.task-evidence/t_103d63ec/browser-results.json) retain the
original six embedded attachments; extracted PNG/JSON/text bytes and hashes also
live under this card's `attachments/`. Screenshots are deterministic evidence,
not committed product assets. Focus crops show readable Open/New labels and a
subtle rendered focus treatment, not screen-reader/native-device qualification.

The [retained predecessor receipt](../../.task-evidence/t_103d63ec/retained-predecessor.json)
checks unchanged repaired production/test hashes and the exact approved
`t_4e4a4f7d` review414 log hash. Its 539 combined cases and scoped analyzer/formatter
acceptance are carried as predecessor evidence, not counted as newly executed
here. Relevant current shell/caller/denial checks are separately rerun above.

## Acceptance evidence and limits

| Criterion | Real evidence |
| --- | --- |
| 1. Current-source shell/lifetime/caller and denial/owner controls | Four exact targets, exit 0, 85 parsed passes; source/mirror equality and local import closure; scoped formatter and analyzer pass. |
| 2. Fresh compiled keyboard Open/New and compact recovery | Fresh release web build exit 0 and 35 output hashes; unchanged global-session-access spec exit 0, one Chromium case; exact request/focus/semantics receipts and owned loopback fixture cleanup. |
| 3. Scoped report/receipt, exact-task ledger and bounded handoff | This report, command/source/build receipts, final integrity validation; supported goals.py exact task/evidence updates; TODO render handoff to reserved repo-docs writer; native same-card review is the only final approval lane. |

[Validation](../../.task-evidence/t_103d63ec/validation.json) checks retained log
hashes, root tracked-file and HEAD preservation, all copied input equality,
predecessor source equality, compiled input/output attribution, extracted browser
acceptance, report links and scoped whitespace. Task-owned executable receipt
helpers are `qualify.py` and `finish.py`; they do not mutate production sources.
Reproduce integrity with `python3 .task-evidence/t_103d63ec/finish.py` from the root.
Local agent-branch/commit and ledger readback are retained in the final handoff;
no inherited edits or build/log/screenshot outputs belong in that commit. There
is no checked-out-branch commit, push, merge, release or external delivery.

NOT_CHECKED: Android/process death/keystore/notification permission, authoritative
accepted/rejected live mutation counts, native desktop, live Agent/inference,
full suites, named-device actions, release distribution and deployed runtime.
Chromium at 390px is not Android. Client/fixture request counts are not complete
server counting authority. No milestone or platform support is promoted.

Remaining proof slice: follow the existing
[Android preflight](2026-10-06-m2-android-preflight.md) for a separately admitted
named-target, same-storage process-death-to-completion observer and the
[counting contract](2026-10-06-m2-counting-contract.md) for whole-attempt,
accepted/rejected authoritative coverage. Until an existing unmodified deployed
counting surface is admitted, retain `authoritative_counts_unavailable`; do not
invent a live counter or patch Agent. This card does not allocate that device,
implement the observer or enqueue another task.

Questions: none. Default applied: existing deterministic harness and bounded
same-card review, without production changes or M2 promotion.
