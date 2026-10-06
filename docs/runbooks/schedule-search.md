# Local schedule search and filtering

Status: local search/filtering independently accepted on `t_8547edd8`
(executor59 → tester60 → reviewer61). The route-local ownership repair on
`t_1c295a52` was independently accepted through executor84 → tester85 → reviewer86.
The shared bootstrap authorization repair `t_40a71fac` was independently accepted
through executor87 → tester88 → reviewer89. The explicit inventory admission repair
`t_389042e6` is executor-verified, pending same-card tester/reviewer acceptance.
None of these slices completes
full Linux/native/web qualification `t_38174cb7` or
qualifies real Agent generation.

## Supported boundary

[Schedules](../product/routes.md) continues to require a connected Agent and the
exact authorized jobs GET operation with `tasks:read`. Search is local,
case-insensitive literal containment over the same bounded metadata shown on
cards: name (120 characters), job ID (128), schedule (160). Raw `last_error`,
timestamps and diagnostics are not searched. There is no regular-expression
execution, persisted query, new backend contract or job mutation.

All/Enabled/Disabled use `HermesJob.enabled`, independently of the existing Agent
status mapping. An enabled error or paused job retains its Error or Paused label.
The existing enabled/next-run/name ordering is unchanged. Clear filters resets
both local controls; no matches is distinct from no jobs, unavailable reads,
loading and read failure. Exact channel replacement, host/profile change, selecting
transition, connection-status change or loss of exact jobs-read authority resets
filters and local refresh/failure state, including loss/restoration before a frame.
Same-owner refresh and equivalent capability-document replacement preserve them. Unsupported,
disconnected or failed inventory does not expose valid search/filter controls.
Existing channel connection/profile/request generations reject delayed old reads.

Refresh, pull and Retry callbacks carry the rendered owner identity and recheck
the current provider channel plus fresh authorization before reading or accepting
a completion. A cached old-owner callback cannot refresh either the removed or
replacement owner. Pending old completions cannot clear a new spinner or restore
failed inventory; the new owner can refresh immediately. Already-issued reads may
finish at the original Agent: no cancellation or rollback is claimed. Controls
and owner changes themselves issue no jobs read or mutation.

Clear filters remains an enabled idempotent local action while the inventory is
available and keeps a stable focus destination. Compiled Chromium reproduced a
clear/re-edit defect when the focused button disabled itself: browser blur could
remove the search editor's input listeners while Flutter still considered search
focused. Keeping the action enabled avoids that focus restoration race. The
browser journey checks repeated clear followed immediately by a new query; it
refocuses the editor before inspecting its native editing value. No SDK patch,
DOM mutation workaround, retry or increased assertion timeout is used.

## Verification

### Keyboard-only compiled browser workflows

`t_2b24fc6c` adds [keyboard journeys](../../playwright/tests/regression/inventory-keyboard.spec.mjs)
at 390/1280px, self-verified pending same-card tester/reviewer acceptance. After
the existing connection/reduced-motion/accessibility bootstrap, only Tab,
Shift+Tab, typing, Enter and Space perform user actions. Exact focused names/roles,
viewport containment, paired rendered-focus images and bounded forward shell
escape/backward return are asserted. Search, literal no matches, All/Enabled/Disabled,
idempotent clear and re-edit are followed by refresh success, sanitized failure
and explicit keyboard Retry. The intended **Disabled** filter and **EVENING** query
survive success/failure/recovery; only **Evening review** returns. Failure removes
editors/cards and shows **Schedules unavailable** / **Schedules could not be loaded
from Hermes.**, not fixture transport details or no-match/empty feedback.

Each receipt records one bootstrap jobs GET, zero local-control/navigation reads
or mutations, then exactly three explicit jobs GETs for success/failure/Retry.
Every jobs read carries `profile=default&include_disabled=true`; decoded response
readbacks have statuses 200/200/503/200. Existing admission/ownership/partial Tools
and jobs bootstrap regressions remain passing. The desktop shell's nested route
had hidden the preceding navigation rail from semantics; the minimal shared
boundary repair and production-router/client red/green tests are described in the
[Tools keyboard evidence](tools-search.md#keyboard-only-compiled-browser-workflows).

The locked Flutter 3.44.2/Dart 3.12.2 affected plus shared-widget/router run passes
1,213 unique cases/1,213 executions, including (not adding) the 75 admission,
59 bootstrap and four new shell cases. The source-bound fresh JS-release build and
Chromium new keyboard plus existing search/surface journeys use retries0/workers1;
commands/exits, hashes, traces/focus images and receipts are retained on the card.
Node 26.5.1 differs from documented Node 22. These are deterministic Linux widgets
and compiled Chromium browser viewports, not native desktop/Android, deployed
Agent/provider, Wasm, actual screen-reader or full-platform evidence. Full live
qualification `t_38174cb7` remains unchanged and unmet.

Ownership repair executor evidence (`t_1c295a52`): 69 new cases (62 route-owner
widgets and seven production-client widgets), with 51 failures/18 passes against
the inherited screen before repair. Final affected suites pass 1,029 unique cases,
including all 96 schedule cases, shared channel/client/provider and neighboring
inventory/ownership tests. Widgets at 390/1280px with 200% text and reduced motion
exercise labeled search/clear/progress/Retry and keyboard activation without overflow.
Fresh JS-release Chromium passes 16 unique schedule/Tools/browser-surface journeys;
the two schedule journeys exercise success, sanitized failure and explicit Retry
on profile `default`, with one bootstrap GET, zero local-control requests/mutations
and three explicit jobs GETs (`include_disabled=true`) each. Provider replacement
and same-frame races are widget/client evidence, not browser or deployed-Agent
qualification. Source/build hashes, exact commands and red/green logs are retained
in the card evidence archive. The attachment CLI refused this worker context;
evidence is retained locally, not a confirmed downloadable attachment or notification.

Connection and explicit profile-selection bootstrap now reuse `canReadJobs`, the
same exact policy as production `loadJobs`: supported schema, exact named GET
`/api/jobs`, declared/granted `tasks:read`, all additional required grants and
supported required `profile` query context when the operation is profile-scoped.
A genuinely unscoped advertisement does not acquire a new context requirement.
Broad admin/version flags grant nothing. Denied optional reads issue zero jobs
requests, publish no invented read error and keep the connection usable; the route
shows unavailable controls, not an authorized empty inventory. Authorized requests
retain explicit profile identity and `include_disabled=true`, the 128-job decoder
bound and existing sanitized optional failure/explicit Retry behavior. Bootstrap
does not require already-settled connection/selection state. Existing generation
and request ownership fences remain unchanged; already-issued reads may finish
at their original Agent. Explicit `channel.loadJobs()` and `loadToolInventory()`
now reject unsettled selection and non-connected state before inventory I/O,
error/inventory publication or request-generation acquisition. Bootstrap retains
its intentionally different admission timing while the connection/selection is pending.
No other inventory policy, mutation, implicit retry or selection side effect was
added. Full source-bound live revalidation remains pending.

Explicit admission evidence on `t_389042e6`:
[`hermes_inventory_refresh_admission_test.dart`](../../test/core/hermes/channel/hermes_inventory_refresh_admission_test.dart)
records production channel/client GETs during completer-paused profile-list,
session-list and optional-bootstrap phases, including same-ID selection and A → B → A.
The inherited channel issued jobs/skills/toolsets reads and two state publications
while selecting; the repaired calls reject with a meaningful state error and zero
extra I/O. Existing completion generations already fence late success/failure
after selection, reconnect, disconnect and disposal; they were not changed.
The necessary Tools caller repair is described in the
[Tools runbook](tools-search.md#explicit-refresh-ownership).

Executor's locked Flutter 3.44.2 / Dart 3.12.2 checks pass: changed-Dart nonwriting
format, `flutter analyze --no-pub`, 1,162 unique affected cases / 1,162 executions
(`--no-pub --concurrency=1 --reporter json`), including 75 new cases and the accepted
59-case bootstrap matrix. Counts identify cases by source file plus test name;
focused runs overlap and are not added to this total. Actual-channel widgets at
390/1280px exercise 200% text and reduced motion without overflow. A fresh
`flutter build web --release --no-pub -t lib/main_e2e.dart` and 16 unique Chromium
schedule-search/tools-search/browser-surfaces journeys / 16 executions pass with
retries disabled. Four decoded receipts show one bootstrap jobs read per schedule
journey, zero search/filter/clear reads or mutations, and three explicit jobs GETs
with `profile=default&include_disabled=true` for success/failure/Retry; Tools reads
exactly its two inventories on explicit refresh. Race/denied-admission evidence
is client/widget, not browser owner-selection or deployed-Agent evidence.
Source/build hashes, exact commands and red/green events are retained in the card
evidence. Node 26.5.1 / Chrome for Testing 149.0.7827.55 / Playwright 1.61.1 were
exercised, not documented Node 22. Existing Wasm dry-run/font warnings remain;
no native-device, real Agent/provider inference, Wasm, full-platform gate or release
qualification is implied. Independent acceptance of this repair remains pending.

Bootstrap regression evidence is in
[`hermes_jobs_bootstrap_authorization_test.dart`](../../test/core/hermes/channel/hermes_jobs_bootstrap_authorization_test.dart):
production client request recording for denied connect/select, enrolled-path
selection with unsupported context, scoped/unscoped admission, every required
grant, bounded authorized inventory, optional failures and stale success/failure
after disconnect/reconnect/profile A-B-A/disposal. Actual-channel Schedules widgets
at 390/1280px with 200% text and reduced motion reuse unavailable/error/success and
explicit Retry controls. The existing compiled Chromium schedule/Tools/browser
journeys check exact authorized request receipts; the unauthorized capability
matrix and replacement races are client/widget evidence, not browser/live Agent
qualification. Retained card evidence records exact commands, red/green test events
and source/build hashes. Node 26.5.1 was exercised, not documented Node 22; no
physical/native-device, Wasm or deployed Agent qualification is implied.

For the bootstrap repair, run the commands below with `--no-pub` on analyze/test/build,
include `test/features/schedules` plus `test/core/hermes`, the channel-provider test
and neighboring Tools/Providers/Profiles/Connections/Office tests, and format the
changed shared inventory part plus `hermes_jobs_bootstrap_authorization_test.dart`.
The current browser invocation also includes `tools-search.spec.mjs` and all
`browser-surfaces.spec.mjs` journeys with retries disabled. No ARB changed, so
localization regeneration was not required for this repair.

Predecessor search/filter evidence follows (not a fresh full-platform qualification):

Executor used the existing isolated Flutter 3.44.2 / Dart 3.12.2 toolchain,
Node 26.5.1, Playwright 1.61.1 and Chrome for Testing 149.0.7827.55 on Linux.
Node 22, physical Android, native authenticated Agent generation and browser
screen-reader/Tab traversal are not qualified here. Keyboard activation and
semantics are proved by the Linux Flutter widget runner; compiled Chromium uses
keyboard text entry and semantic pointer activation of filters/clear.

- Initial search regression failed before implementation (no search field).
- 27 schedule widget tests plus the shared channel directory pass: 374 tests.
  Coverage includes bounded/literal name/ID/schedule matches, error exclusion,
  enabled/paused/error combinations, clear/sorting, same-owner replacement,
  gateway/profile resets, grant/capability loss, disconnected/loading/failure and
  empty states, refresh/races, and actual channel delayed old-read success/failure.
- Widget search/filter/clear semantics and Space/Enter activation pass at 390 and
  1280 pixels with 200% text; existing 320-pixel long-card checks also pass.
- Compiled Chromium at 390/1280 pixels checks exact full card metadata, no matches,
  combination, clear/re-edit and refresh. Each journey observes zero search/filter
  API requests, zero mutations and exactly one explicit refresh GET. Bounded
  receipts and source hashes are preserved in the local evidence archive referenced
  by this card's handoff; downloadable card attachment delivery was not confirmed.
  These are synthetic fixtures, not real jobs.
- Analyze, changed-Dart formatting, localization generation, release web build,
  JavaScript syntax, diff whitespace and changed-document links pass.
  The final web build reports existing flutter_tts Wasm dry-run warnings;
  this is JS-release evidence, not Wasm qualification.

Relevant commands, with the qualified Flutter toolchain first on PATH:

```bash
flutter gen-l10n
dart format --output=none --set-exit-if-changed \
  lib/features/schedules/screens/schedules_screen.dart \
  test/features/schedules/schedules_screen_test.dart \
  lib/l10n/app_localizations.dart lib/l10n/app_localizations_en.dart
flutter analyze
flutter test test/features/schedules/schedules_screen_test.dart \
  test/core/hermes/channel --concurrency=1 --reporter expanded
flutter build web --release -t lib/main_e2e.dart
node --check playwright/tests/regression/schedule-search.spec.mjs
node --check playwright/tests/regression/browser-surfaces.spec.mjs
PORT=9140 HERMES_E2E_PORT=9141 node serve_web.mjs
# In another terminal, use the installed Chromium executable and unused ports.
CHROME_EXECUTABLE=/path/to/qualified/chrome WING_APP_URL=http://127.0.0.1:9140/ \
  npx playwright test playwright/tests/regression/schedule-search.spec.mjs \
  playwright/tests/regression/browser-surfaces.spec.mjs --grep Schedules \
  --workers=1 --retries=0 --repeat-each=3
git diff --check
```

All listed final checks return exit 0. Earlier browser actor experiments failed
on query-bearing URLs, merged/announced semantics text, and clear/editor focus;
the final test retains exact inventory and zero-network assertions. Browser Tab
experiments were not accepted as keyboard evidence. No instruction files,
Agent/reference/runtime files, credentials or unrelated worktree changes were
modified, staged or committed. Source hashes and the executor-only diff against
the inherited worktree are preserved in the card evidence.
