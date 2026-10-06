# Current loaded-session sidebar qualification

Task: `t_d06ef06d` / `DOC-GLOBAL-SESSIONS-CURRENT-CHECK`.
Goal: `GLOBAL-LOADED-SESSIONS`.

## Result and boundary

Executor verification passes for the current expanded sidebar, its passive
loaded-session observer, and the compiled deterministic Chromium Open/New journey.
The previous four-hash attribution gap is replaced with a compared current input
snapshot and fresh execution, not inferred away from historical approval.
No production, shared test, fixture, configuration or predecessor receipt changed.
Independent final acceptance belongs to this card's native same-card review lane;
that is not native desktop execution. The goal ledger remains unverified pending
that lane and the reserved repo-docs handoff below.

Baseline: HEAD `4acdb4e1f51262ccfdca5174776eed1e3ef65188` plus current dirty inputs.
[Source input manifest](../../.task-evidence/t_d06ef06d/source-inputs.json) binds
521 copied inputs. Every copied byte matched both the current source and disposable
mirror before execution and after the checks. The
[import closure](../../.task-evidence/t_d06ef06d/dependency-closure.json) traverses
195 local import/export/part inputs from the seven widget, channel, lifetime,
compiled-app, browser, config and server roots, including conditional imports.
No missing local dependency or unhashed closure member was found. This is a bounded
local dependency-closure check, not certification of all third-party package bytes.

## Retained evidence versus fresh evidence

[Historical comparison](../../.task-evidence/t_d06ef06d/historical-comparison.json):

- `t_1c1e6f37/final-hashes.json`: 21 of 24 entries match. The changed entries are
  `app_shell.dart`, `docs/product/routes.md`, and the global-session runbook.
  All 19 non-shell `lib/test/playwright` entries match. Its
  `verified-commands.json` records exit 0 for widgets-final, analyzer-final,
  build-verified-final and global-browser-verified-final. These are historical
  execution only; their complete transitive inputs were not recorded there.
- `desktop-shell-fidelity/redesign-manifest.json`: all four final source entries
  match. Its focus-fix fields record widget/build/browser exits 0. Inspected
  `focus-fix-tests.log` ends at 57 passed; `focus-fix-build.log` says Built build/web;
  `focus-fix-browser-tests.log` records two passes, including the global journey.
  Those logs and hashes do not bind all callers, browser helpers, package inputs,
  assets or compiled delivery. No historical run is substituted for a fresh check.

The retained logs remain in their original directories, untouched. Fresh runs
below supply the missing source/build/browser attribution.

## Bounded attribution matrix

All paths in this table are keys in source-inputs.json. Transitive code is bound
by dependency-closure.json; package/assets/platform inputs are additionally bound
by source-inputs.json, resolved package manifest hashes by toolchain.json, and the
fresh web output by build-output-hashes.json.

| Input seam | Current contract inspected | Executed attribution |
| --- | --- | --- |
| `lib/shared/widgets/app_shell.dart`, desktop style and presentation | Lines 388–480: traversal groups; scrollable expanded-only ShellSessionAccess; collapse disposes it | 44 widget cases and compiled browser journey |
| `lib/features/hermes_chat/widgets/shell_session_access.dart` | Lines 35–99: passive lifetime plus synchronous generation/resource invalidation; 120–179: original channel, canAccept, acknowledged exact selection before router.go | Exact Open/Create, delayed single-flight, loss/change-back and keyboard cases |
| `lib/features/hermes_chat/providers/hermes_channel_provider.dart`, `hermes_directory_lifetime.dart` | Factory attaches/detaches provider-owned directory; passive provider does not read/start eager directory | Fresh lifetime case; shell construction/read counters |
| `lib/features/hermes_chat/gateways/hermes_gateway_directory.dart`, gateway contact/cache and endpoint stores | Restoration and active-contact authority stay directory-owned; preferred-session restore passes current admission, not global selection side effects | Fresh lifetime test and compiled direct API channel; wider restoration suites NOT_RERUN |
| `lib/core/hermes/channel/hermes_channel.dart`, `hermes_api_channel.dart`, state, session extension, client/models/policy and transitive parts | Public create/select propagate canAccept; select guards history/cache admission; create rechecks before write, metadata/history admission and selection; exact capabilities gate surface | Eight fresh API caller-admission cases; compiled real API channel journey |
| `test/shared/widgets/app_shell_global_session_access_test.dart`, three imported support fakes | Real shell/router; deterministic delayed channel, passive directory sentinel, exact identity/count/semantics assertions unchanged | 44 pass, 0 fail/skip |
| `test/features/hermes_chat/gateways/hermes_directory_lifetime_test.dart`, `test/core/hermes/channel/hermes_session_caller_admission_test.dart` | Actual provider factory plus actual production API channel under deterministic transports | 9 pass, 0 fail/skip |
| `lib/main_e2e.dart`, app/router/theme/localization/shared and feature dependency closure | Real HermesApiChannel override; explicit fixture/bootstrap hooks; no provider inference | Fresh release web compilation then browser, not source-only widget evidence |
| `playwright/tests/regression/global-session-access.spec.mjs`, `flutter_semantics.mjs`, `inventory_keyboard.mjs`, `playwright.config.mjs` | Exact scoped history/create request shapes, keyboard-only actions, visible renderer focus difference, unchanged owner after layout recovery | One Chromium pass, retries=0, workers=1 |
| `serve_web.mjs`, `hermes_lifecycle_fixture.mjs` | Same deterministic loopback fixture; own two free ports; server serves mirror build/web, no shared listener | Owned server readiness, browser request receipt and cleanup |
| `pubspec.yaml/lock`, `package.json/lock`, analyzer/localization configuration, `assets/`, `web/` | Explicit copied packaging/asset inputs; local Dart config and build; read-only cached npm dependency reuse | Offline pub get then build; all copied inputs remained byte-identical |

## Exact fresh checks

Cwd for every Flutter/Playwright command:
`.task-evidence/t_d06ef06d/mirror` under this project.
[Command receipt](../../.task-evidence/t_d06ef06d/commands.json) records full argv,
exit codes, elapsed time and sanitized logs:

1. `flutter pub get --offline`: exit 0. Task-local Dart configuration; no shared
   `.dart_tool` or build link. The package lock stayed unchanged.
2. `flutter test --no-pub test/shared/widgets/app_shell_global_session_access_test.dart --concurrency=1 --reporter=json`:
   exit 0; parsed 44 pass, zero failed/skipped. Hidden loading records are excluded.
3. `flutter build web --release -t lib/main_e2e.dart`: exit 0; fresh build/web.
4. `npx playwright test --config=playwright.config.mjs playwright/tests/regression/global-session-access.spec.mjs --retries=0 --workers=1 --output=browser-output`:
   exit 0; one expected pass, zero unexpected/skipped/flaky, one attempt.
   Environment sets task-owned PORT/HERMES_E2E_PORT, WING_APP_URL and
   CHROME_EXECUTABLE=/usr/bin/chromium; exact ports are in fixture.json.
5. `flutter test --no-pub test/features/hermes_chat/gateways/hermes_directory_lifetime_test.dart test/core/hermes/channel/hermes_session_caller_admission_test.dart --concurrency=1 --reporter=json`:
   exit 0; 9 pass, zero failed/skipped.

[Widget summary](../../.task-evidence/t_d06ef06d/widget-summary.json) and
[nearest summary](../../.task-evidence/t_d06ef06d/nearest-summary.json) retain every
case name/result. [Browser summary](../../.task-evidence/t_d06ef06d/browser-summary.json)
retains parsed result counts. [Toolchain](../../.task-evidence/t_d06ef06d/toolchain.json)
records observed Flutter, Dart, Node, Chromium and Playwright versions. Node differs
from the recommended Node 22. Build warnings include flutter_tts Wasm incompatibility
and missing Cupertino font-family assets; release JavaScript compilation succeeded.
No Wasm support claim is made.

## Acceptance-to-evidence map

1. Complete bounded attribution: source-inputs.json, dependency-closure.json,
   historical-comparison.json, input-comparison.json, postcheck.json and
   build-output-hashes.json bind source, tests, helpers, package/assets and compiled
   output. Historical passes are quoted but not reused as current proof.
2. Discriminating current oracle: widget-summary.json proves acknowledgement before
   navigation, single-flight Open/Create, exact row selection, owner/contact/lifetime/
   route/collapse invalidation (including change-back), disabled/capability-loss cases,
   selected named semantics, short-window 200% text/reduced-motion keyboard operation
   and compact recovery. nearest-summary.json supplies real caller/lifetime checks.
   The unchanged compiled browser assertions at lines 35–80 pass for Tools → exact
   profile/session Open → Tools → one create → collapse/expand → 390px More/Settings/
   Chat → 1280px return, unchanged owner and no layout-induced requests.
3. Sanitized reproducible receipts: verify.py recreates the isolated fresh widget/
   build/browser path, refuses to overwrite an existing mirror, and records exact
   argv/exits. record.py compares inputs, traverses dependencies, extracts counts
   and compares historical manifests. The initial record.py invocation incorrectly
   parsed JavaScript `export default` as an import and exited 1; its collector-only
   correction excluded that syntax, then passed. No product assertion was changed,
   waived or rerun to cure that collector failure. Inline Playwright attachments
   were decoded from the actual result JSON; the runner was then extended to retain
   those inline bodies automatically. This collector extension was syntax-checked,
   not another browser execution. Integrity/local-link/JSON/whitespace checks and
   mirror disposal are recorded in final-validation.json and integrity.json.

[Actual browser request/focus receipt](../../.task-evidence/t_d06ef06d/browser-artifacts/global-session-receipt.json)
contains only deterministic fixture identities and requests. Explicit connection
bootstrap does perform its existing reads; zero incidental reads means none from
loaded-session painting/focus and later layout changes, not zero connection reads.
Open adds exactly one scoped history GET. New adds exactly one scoped POST and one
scoped history GET for its returned ID. The browser sees no other mutation and no
page error. Focused/unfocused PNG pairs and the final semantics snapshot are retained
beside that receipt. PNG inequality is the existing rendered-focus assertion, not
an independent contrast or screen-reader certification.

## Isolation, cleanup and remaining ceilings

Only this report and sanitized task-local receipts are deliverables. The mirror
copied explicit current public source/package/assets only: no .git, upstream
clones, existing evidence trees, private runtime state or credentials. Cached
user-space dependencies were reused. Own fixture was terminated/reaped; both ports
were checked closed. Retained flutter_tester PID 96817 was not signaled; shared
build/.dart_tool resources were not touched. Disposable generated mirror was removed
after input and compiled-output recording. Reproduction needs a new mirror.

No Dart product/harness source changed, so fresh formatter/analyzer passes are not
claimed; this scope used Python syntax and documentation/receipt validation.
Native desktop, Android, physical devices, speech, screen readers, live Agent/provider
inference, installed runtime delivery, full suites, full daily workflow and full
Desktop parity are NOT_CHECKED. No product failure was observed in this bounded
oracle; no production repair or follow-up task was opened.

## Reserved repo-docs handoff

Do not render shared TODO or normalize unrelated goals during this task. This card
owns its report/evidence, not the shared renderer. Exact current task was inspected:
`DOC-GLOBAL-SESSIONS-CURRENT-CHECK` is in_progress, depends on
`PARITY-GLOBAL-SESSIONS`; goal `GLOBAL-LOADED-SESSIONS` remains unverified.
After independent same-card review, the reserved writer should use the supported
`goals.py task <repo> DOC-GLOBAL-SESSIONS-CURRENT-CHECK done` and add executed-pass
evidence for commands 2–5 above with the exact mirror cwd/argv and commands.json
reference, then reconcile only this goal's current-snapshot wording through its
supported workflow. Do not promote native/full-parity support. Do not render TODO
as part of this card. No goals.json or TODO.md edit was made here.

Fresh sanitized logs use `.txt` to respect the repository's `*.log` ignore rule.
The first agent-branch helper attempt refused an ignored `.log`; no ref was created.
The receipt files were renamed; stdout trailing whitespace was normalized for
version control. No assertions, counts or substantive output changed; no tests
were rerun for this packaging correction.

The task's explicit local agent-branch receipt mechanism is the sole commit
exception: only this report/sanitized evidence, never shared HEAD/index or dirty
product files. Its verified branch/SHA are supplied on the native review handoff;
no push, deployment, release or final approval is implied.

Questions: none. Defaults applied: existing assertions unchanged, focused fresh
checks instead of historical inference, shared goal rendering reserved to repo-docs.
