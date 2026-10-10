# Hermes Wing task archive

> Reference correction: [official Desktop authority](docs/quality/official-desktop-reference.md). Prior Desktop source citations and parity conclusions in this document are withdrawn. Wing test results remain historical behavior evidence only.


Completed task history moved verbatim from [TODO.md](TODO.md).
This archive does not queue work or qualify the current working tree.
Task states and executed evidence remain in [goals.json](goals.json).

## Backlog separation after private release packaging

The sections below preserve the original task order and section context.
Only checked completion records move here; open tasks stay in TODO.

### Now / Next

- [x] **VERIFY-GLOBAL-SESSION-MODAL-ADAPTIVE** — Goal: PARITY-COMPOSITION.
  Keep the delivered panel usable at compact/wide widths and large text.
  Payoff: preserve feature-route session access without precise pointer input.
  Sources: [modal limits](docs/quality/global-session-modal.md#qualification-limits-unchanged)
  and [client accessibility decision](docs/adr/client.md#decision).
  Scope: existing modal/panel and nearest widget/browser regressions; repair
  exposed overflow and focus defects. Exclude new APIs, tabs, profile writes,
  native/device qualification and screen-reader support claims.
  Acceptance: 200% text and reduced motion keep search, rows and Close/New controls
  readable. Real Tab/Shift+Tab and Enter/Space operate visible controls after resize;
  Escape restores surviving focus. Owner replacement rejects obsolete activation
  without incidental reads or mutations. Run focused widgets, analyze and a fresh
  compiled Chromium journey with source-bound receipts.
  Delivery: [adaptive receipt](docs/quality/global-session-modal-adaptive.md)
  records shared-panel stacking/scroll/focus repairs, 103 focused widget passes
  and four compiled Chromium journeys. All 203 input fingerprints match this
  snapshot; retained logs confirm results, not new product execution or approval.
  The [npm follow-up](docs/quality/global-session-modal-adaptive.md#follow-up-npm-verification-scope)
  also passes 103 focused tests; the separate full-suite log has no completion result.
  Native/live, screen readers and standalone-branch build remain unqualified.
  Dependencies: PORT-GLOBAL-SESSION-MODAL (done). Delivered t_493629fd; no duplicate dispatch.

- [x] **VERIFY-CHAT-TRANSCRIPT-ORDER** — Goal: CHAT-FIDELITY. Delivered canonical
  reasoning/commentary/tool/answer order and adaptive keyboard qualification.
  Source and acceptance evidence: [streamed-order receipt](docs/quality/chat-transcript-order.md).
  Scope: existing timeline, queue profile fence and focused widget/browser checks;
  no new Agent events or capabilities. Retained final logs record 129 widget passes,
  clean analysis, a fresh JavaScript build and two compiled Chromium journeys.
  Explicit-profile approval display/activation rejects reused session IDs;
  nullable-profile compatibility is unchanged. Eleven retained input hashes match.
  This pass inspects receipts, not new product execution or independent approval.
  History reconnect, enlarged-text whole-transcript and native/live remain gaps.
  Dependencies: VERIFY-CHAT-DISCLOSURE-ACCESSIBILITY (done).
  Ownership: delivered t_b9368977; existing done ledger status preserved.

- [x] **VERIFY-CHAT-TRANSCRIPT-RECONNECT** — Goal: CHAT-FIDELITY. Delivered
  canonical tool-result ordering and retired-approval focus after reconnect/remount.
  Source: [bounded reconnect receipt](docs/quality/chat-transcript-reconnect.md).
  Scope delivered: shared history projection and widget/Chromium regressions.
  Recovered categories use canonical IDs without tool text, preview or result.
  Retained logs confirm 391 focused passes in both isolated and shared workspaces,
  clean analysis, a release web build and two Chromium journeys. Ten available
  selected hashes match; the removed generated build cannot be rehashed.
  Recovery causes zero mutations. Historical tool outcomes, unfinished invocations,
  reasoning recovery, enlarged text and native/live remain unqualified.
  Dependencies: VERIFY-CHAT-TRANSCRIPT-ORDER (done).
  Ownership: delivered t_2fe70cc9; existing done ledger status preserved.

- [x] **VERIFY-CHAT-TRANSCRIPT-ACCESSIBILITY** — Goal: CHAT-FIDELITY. Keep streamed
  and recovered tool/approval rows readable and keyboard-operable at enlarged text.
  Payoff: extend isolated reasoning/composer access to the supported whole transcript.
  Sources: [accessibility requirement](docs/adr/client.md#decision),
  [streamed-order limits](docs/quality/chat-transcript-order.md#acceptance-mapping-and-remaining-limits)
  and [verification scenarios](docs/test-plan.md#risk-based-scenarios).
  Scope: existing timeline/approval widgets and nearest widget/browser regressions;
  repair exposed overflow, focus or owner defects. Exclude new APIs/events,
  upstream edits, native/live execution and screen-reader qualification.
  Acceptance: at 200% widget text scaling and separately Chromium whole-render zoom,
  reasoning, grouped tools and current approval actions remain readable/reachable
  through compact/wide return and authoritative reconnect. Owner replacement hides
  obsolete actions; no prompt, approval or Stop replays. Run focused widgets,
  analyze and a freshly compiled Chromium journey with exact request receipts.
  Delivered evidence: [accessibility receipt](docs/quality/chat-transcript-accessibility.md)
  records two widget tests and two compiled Chromium journeys at 200% scaling/zoom.
  All eight selected input hashes match this snapshot; no test was rerun here.
  Native/live and screen-reader checks remain separate; CHAT-FIDELITY stays partial.
  Dependencies: VERIFY-CHAT-TRANSCRIPT-RECONNECT (done); completed slice, no redispatch.
  Ownership: delivered t_42880105; existing done ledger status preserved.

- [x] **MT-APP-SHELL-STATUS-BAR** — Goal: INTEGRATION. Repaired the test's global
  profile-label uniqueness assumption without changing production behavior.
  Sources and acceptance evidence: [source-bound receipt](docs/quality/merge-train-shell-status-bar.md).
  The repaired historical candidate passed 3555 Flutter tests. This does not
  qualify the later combined tree or waive the historical browser failures.
  Scope: the status-bar test only. Ownership: delivered t_cd815647; preserve review.

- [x] **PORT-PROFILE-FOOTER** — Goal: PARITY-COMPOSITION. Delivered a passive
  current-profile footer with Manage profiles navigation in expanded/compact shells.
  Sources: [implementation receipt](docs/quality/profile-footer-implementation.md),
  [composition brief](docs/quality/profile-footer-composition.md#smallest-safe-implementation-slice)
  and [bounded contract](docs/quality/desktop-next-port-slice.md#next-implementation-contract).
  Scope: current-channel display and navigation only; no inventory reads, profile
  mutations, edit/switch pickers, recents, tabs or backend changes.
  Acceptance evidence: retained 63 shell widget passes and compiled Chromium
  navigation with unchanged owner and zero incidental domain requests. Three
  scoped source/test fingerprints match. This is not new execution or native parity.
  Dependencies: DOC-PARITY-COMPOSITION and DOC-PARITY-COVERAGE (done).
  Ownership: completed ledger delivery on `agent/wing/t_82b3229c`; independent
  final review approval is not established by this documentation pass.

- [x] **PORT-GROUPED-RECENTS** — Goal: PARITY-COMPOSITION. Show keyboard-operable
  grouped recent sessions in the desktop sidebar using Agent-owned loaded rows.
  Payoff: deliver the next remaining composition outcome without duplicating Open/New.
  Sources: [parity requirement](docs/product/hermes-desktop-parity.md#reference-and-evidence-boundary),
  [UI gap](docs/product/hermes-desktop-ui-gap.md#current-source-backed-gaps)
  and DOC-PARITY-RECENTS-REFERENCE below.
  Scope: existing shell/session projections, nearest widget tests and a compiled
  browser journey. Exclude raw host-path grouping, direct files/database reads,
  shadow domain state, speculative APIs, tabs and profile mutation.
  Acceptance: group/order only with supported current-owner metadata identified
  by the comparison. Enter/Space opens the exact row once. Owner replacement,
  reconnect and collapse/resize reject stale actions without incidental reads,
  session creation or submissions. Run nearest shell tests, `flutter analyze`
  and a compiled deterministic browser check; record any unavailable grouping.
  Dependencies: DOC-PARITY-RECENTS-REFERENCE (done).
  Delivery: [executor receipt](docs/quality/grouped-recents-implementation.md) records
  72 shell widget passes, clean analysis and one fresh compiled Chromium pass.
  Ten retained source hashes match this snapshot. Source grouping is implemented;
  Project grouping, disclosure, native/live and screen-reader parity are not claimed.
  Ownership: t_8181e7ae delivered this bounded slice; preserve its review lane.
  Independent same-card approval is not established by this documentation pass.


- [x] **PORT-GLOBAL-SESSION-MODAL** — Goal: PARITY-COMPOSITION. Delivered
  owner-bound session-panel access over feature routes through Sessions and
  Ctrl/Command+K. Source: [modal receipt](docs/quality/global-session-modal.md).
  Eight scoped source/test hashes and branch files match this snapshot. Retained
  execution records 120 focused widget passes and a compiled Chromium keyboard
  journey with exact acknowledgement, focus return and no captured errors.
  This pass inspected receipts; it did not rerun product checks or infer final
  independent approval. Standalone branch compilation, native/live and screen-reader
  qualification remain unchecked. No new API, profile write or shadow inventory.
  Dependencies: DOC-PARITY-COMPOSITION (done). Existing implementation slice stays
  done; VERIFY-GLOBAL-SESSION-MODAL-ADAPTIVE queues distinct remaining coverage.

- [x] **VERIFY-GROUPED-RECENTS-RECOVERY** — Goal: PARITY-COMPOSITION. Add
  adversarial disclosure and adaptive-return checks after grouped recents ships.
  Payoff: reject hidden or obsolete row actions without incidental domain reads.
  Sources: [recents oracles](docs/quality/grouped-recents-reference.md#observable-acceptance-oracles-for-implementation)
  and [parity requirement](docs/product/hermes-desktop-parity.md#reference-and-evidence-boundary).
  Scope: nearest shell widget/browser tests and smallest exposed Wing fixes.
  Exclude upstream changes, new grouping metadata, native/device qualification,
  profile mutations, tabs and persistence changes.
  Acceptance: hide and restore a group, collapse and resize back, then replace
  the owner while Open is pending. Old actions never navigate or mutate the new
  owner. Real Enter/Space and reverse focus traversal reach visible rows only.
  Run nearest shell tests, analyzer and a compiled deterministic browser journey;
  record exact read/action counts and remaining platform gaps.
  Dependencies: PORT-GROUPED-RECENTS (done); Section: Done.
  Baseline: source-group headings are not collapsible. Test existing sidebar
  collapse/return first; do not describe group disclosure as shipped behavior.
  Delivery: [recovery receipt](docs/quality/grouped-recents-recovery.md) records
  eight new widget cases, 71 focused passes and one compiled Chromium journey.
  Existing sidebar collapse/resize supplies hide/return; group disclosure remains
  absent. Late old-owner results add no navigation or incidental requests.
  Ownership: completed bounded delivery on `t_1e01f86b`; no independent approval
  or native/live qualification is inferred from receipt inspection.

- [x] **VERIFY-GROUPED-RECENTS-NATIVE** — Goal: PARITY-COMPOSITION. Keep loaded
  recents keyboard-operable through native Linux hide/return and owner replacement.
  Payoff: prove the delivered sidebar outcome on the actual desktop target.
  Sources: [recovery receipt](docs/quality/grouped-recents-recovery.md#gaps-and-defaults),
  [composition requirement](docs/product/hermes-desktop-parity.md#reference-and-evidence-boundary)
  and [native prerequisites](docs/quality/native-relaunch-workflow.md#safe-user-space-prerequisites-and-reproduction).
  Scope: existing production shell/channel projections, isolated native integration
  harness and smallest exposed Wing fixes. Exclude live inference, group disclosure,
  Project metadata, upstream edits, personal preferences and system installs.
  Acceptance: launch native Flutter Linux with owned QA state; keyboard Open selects
  the exact loaded row once. Hidden rows leave focus traversal. Collapse/resize
  return remains usable at enlarged text; a pending old-owner Open cannot navigate
  after replacement. Bind source/build/platform receipts and exact read/mutation
  counts. No incidental New, Send, approval or Stop. Run nearest tests and analysis.
  Dependencies: VERIFY-GLOBAL-SESSION-MODAL-ADAPTIVE (done). Section: Done.
  Delivery: [native receipt](docs/quality/grouped-recents-native.md) records six
  native phases, 18 focus assertions, 10 exact-row selection completions, zero
  mutations, 71 focused passes and owned teardown. Physical input and live Agent
  remain unverified. Ownership: bounded delivery on `t_3a6bafe4`; native review
  approval follows the same-card handoff and is not implied by this index.

- [x] **CONNECTION-REMOTE-AUTH-STORAGE-RETRY** — Goal: CONNECTION-PATHS.
  Prove explicit Remote authentication/save retry without stale-owner effects.
  Sources: [bounded delivery](docs/quality/remote-connection-retry.md) and
  [CONN-3/5/6](docs/product/prd.md#connection-path-requirements).
  Scope: existing connection consent, secure-save settlement, E2E-only storage
  controls and nearest public-control regressions. Excludes OAuth, managed SSH,
  live credentials and physical secure-storage qualification.
  Acceptance: rejected auth is sanitized; uncertain persistence retains a connected
  editable draft. Explicit retry saves once; late results cannot disconnect or
  close a replacement owner. Retained executor evidence records 18 retry cases,
  88 combined connection/storage cases, 58 directory cases and four Chromium
  journeys with no mutations or page errors. Nine tested source fingerprints match.
  Dependencies: none recorded in the goal ledger. Section: Done.
  Ownership: bounded delivery on `t_96242625`; receipt inspection does not imply
  independent approval or completion of CONNECTION-SETUP-AUTH-MATRIX.

- [x] **PARITY-MAESTRO-ANDROID** — Goal: PARITY. Execute and repair mapped
  Android fixture journeys on an authorized disposable QA target.
  Map actual per-operation assertions to stable HD-* row IDs and current Wing
  subsets. A candidate helper or unavailable-state pass does not close a positive
  feature gap. Reuse retained widget/browser evidence without calling it device proof.
  Payoff: prove feature behavior through real mobile controls, not YAML syntax.
  Sources: [matrix](docs/product/hermes-desktop-feature-matrix.md),
  [runbook](docs/runbooks/desktop-feature-qualification.md).
  Scope: existing feature/profile Maestro wrappers, QA fixture and nearest flows.
  Add missing assertions and smallest production fixes exposed by discriminating
  regressions. Keep live/provider and unsupported positive operations separate.
  Acceptance: per-flow commands/exits and per-feature pass/fail/not-run receipts
  bind the app/build/source/flow. Verify isolated `.qa` identity before clearState.
  Prove exact effects, owner races and no replay. Run relevant format/analyze/tests
  for changed Dart. No personal device/app reset or secret copying.
  Delivered: [bounded fixture receipt](docs/quality/android-approval-attachment-fixture.md)
  records repaired approval/recovery and deferred attachment controls, seven Flutter
  widget passes and four mocked wrapper passes. Android startup failed before launch.
  This completed slice does not satisfy its original full-device acceptance. The
  remaining device assertions and other feature journeys belong to the successor.
  Dependencies: none. Ledger status: done; no card transition is made here.

- [x] **CONNECTION-PRIMARY-ENTRY** — Goal: CONNECTION-PATHS. Present Local,
  SSH and Remote as the primary connection choices. Payoff: match Desktop entry
  without implying managed SSH already works. Sources:
  [CONN-1](docs/product/prd.md#connection-path-requirements),
  [source comparison](docs/product/desktop-connection-paths.md) and
  [current regression](test/features/hermes_chat/screens/hermes_chat_screen_auth_recovery_test.dart).
  Scope: existing Chat/enrollment entry, adaptive routing, English ARB and nearest
  tests. Reuse local setup and direct endpoint forms. Keep VPN within Remote and
  an explicit external-tunnel path while managed SSH is unavailable. Exclude
  process execution, remote bootstrap, new API fields and credential migration.
  Acceptance: wide/compact keyboard widgets and a freshly compiled fixture
  journey reach all three primary choices, local setup, Remote/VPN and the
  correctly labeled SSH fallback. Cancel/back preserve the active conversation.
  Dependencies: none. Native SSH is tracked by REMOTE-BACKENDS, not this entry.
  Delivered: [entry receipt](docs/quality/connection-primary-entry.md) records
  13 widget passes and four compiled Chromium journeys. The ledger task is done;
  native/live qualification and shortened labels remain separate. This pass
  inspected retained logs, not a new product test run. No card is transitioned.
  Default applied: group VPN under Remote without removing its connectivity.

- [x] **CONNECTION-ENTRY-LABELS** — Goal: CONNECTION-PATHS. Match the primary
  Local, SSH and Remote labels. Payoff: close the documented terminology delta
  without implying managed SSH is available. Sources:
  [CONN-1](docs/product/prd.md#connection-path-requirements),
  [delivery limit](docs/quality/connection-primary-entry.md#delivered-boundary).
  Scope: existing connection labels in English ARB, generated localization output
  and nearest widget/browser assertions. Preserve nested VPN and external-tunnel
  guidance. Exclude subprocesses, new connection authority and unrelated copy.
  Acceptance: regenerated labels appear in primary order at wide/compact sizes;
  focused connection widgets and a freshly compiled Chromium entry journey pass.
  SSH instructions still require a trusted external tunnel; cancel/back retain
  the original owner without mutations. Format and analysis pass.
  Dependencies: CONNECTION-PRIMARY-ENTRY (done). Section: Done.
  Delivery: [entry-label receipt](docs/quality/connection-entry-labels.md) on
  `t_68412445` records RED at both widths, 13 widget passes, analysis and four
  fresh compiled Chromium journeys. Same-card review follows implementation.

- [x] **CONNECTION-SAVED-HOST-OWNER-SAFETY** — Goal: CONNECTION-PATHS.
  Public saved-host rename/remove cancellation, stale consent, delayed storage
  settlement, redacted storage failure and explicit retry. Ten new widget
  regressions and two fresh compiled Chromium journeys pass; the nearest suite
  passes 122 tests. [Receipt](docs/quality/saved-connection-owner-safety.md).
  Section: Done. Native same-card review handoff follows on `t_90ae659f`.

- [x] **FINISH-DESKTOP-SHELL** — Goal: PARITY-COMPOSITION. Prove the remaining
  inventory keyboard regression against the committed wide-shell restyle.
  Payoff: retain keyboard operation across feature routes without repeating delivery.
  Sources: [shell receipt](docs/runbooks/desktop-shell-reference-fidelity.md),
  [shell tests](test/shared/widgets/app_shell_test.dart) and
  [inventory keyboard regression](test/shared/widgets/inventory_keyboard_navigation_test.dart).
  Scope: `app_shell*.dart` and nearest tests; exclude Agent state, new reads,
  unrelated Chat changes and platform support claims.
  Acceptance: focused shell and inventory keyboard tests pass, analysis is clean,
  and a fresh compiled browser journey retains navigation and Open/New.
  Delivery boundary: commit `1afe1307` already implements the restyle and bounded
  focus correction. Its exact-tree receipt records 3,469 Flutter passes and two
  Chromium journeys, but excludes the untracked inventory keyboard test above.
  Completion: [inventory qualification](docs/quality/shell-inventory-keyboard-qualification.md)
  on `t_65ce1e31` records eight inventory and 73 shell widget passes, clean
  analysis and two Chromium journeys after a fresh JS-release build. Retained
  logs and the harness match the receipt. No production repair was needed.
  Do not repeat this completed check or infer full composition/native parity.
  Dependencies: none. Ownership: bounded delivery complete in goals.json;
  independent final approval is not established by this documentation pass.

- [x] **FIX-GATEWAY-KEYBOARD-390** — Goal: PARITY. Restore keyboard operation
  at 390px with 200% text. Payoff: keep compact Gateway controls reachable.
  Follow-up execution: the [full Dart receipt](.task-evidence/desktop-connection-docs/npm-test-result.json)
  records 3,489 passes and six failures in this harness, covering success/failure/
  unsupported health at both 390px and 1280px with 200% text. Four cases miss the
  semantic element and two miss fallback text. Trace fixture, ownership and layout
  before choosing a repair. Preserve the task ID and cover both widths.
  Source: [held-back regression](test/features/gateway/gateway_keyboard_client_test.dart).
  Scope: Gateway presentation and the existing keyboard harness; exclude transport,
  credentials and unrelated shell work. Trace the missing finder before changing UI.
  Acceptance: the named regression passes through visible controls at the specified
  size/text scale; nearest Gateway tests and analysis pass.
  Completion: [fixture repair receipt](docs/quality/gateway-keyboard-bootstrap-repair.md)
  on `t_d8c47dfc` freshly reproduces six failures, then passes all six after
  correcting the history envelope and asserting connected/bootstrap admission.
  No production UI or transport repair was needed; 68 nearest Gateway tests and
  analysis pass. Dependencies: none. Ownership: executor-verified, same-card
  native review is the final delivery step; approval follows separately.


- [x] **DOC-GLOBAL-SESSIONS-CURRENT-CHECK** — Goal: GLOBAL-LOADED-SESSIONS.
  Recheck loaded-session Open/New against the changed sidebar. Payoff: qualify
  current presentation without reopening the completed `t_1c1e6f37` delivery.
  Source: [source-snapshot limit](docs/runbooks/global-session-access.md#current-snapshot-limit)
  and [historical command receipt](.task-evidence/t_1c1e6f37/verified-commands.json).
  Scope: current shell, existing focused regressions and compiled deterministic
  browser journey. Exclude live requests, installs, native qualification, upstream
  edits, new domain state and task/card transitions.
  Evidence follow-through: the [shell redesign receipt](docs/runbooks/desktop-shell-reference-fidelity.md)
  records 57 focused widget passes and two compiled Chromium journeys, including
  global Open/New. All four final source fingerprints match this inspected snapshot.
  The final manifest now includes the [P1 toggle focus correction](docs/runbooks/desktop-shell-reference-fidelity.md#independent-review-p1-correction).
  Attribute these sources to `focus-fix-tests.log` and `focus-fix-browser-tests.log`,
  not the earlier redesign logs. Rendered edge-pixel checks supplement style
  assertions; executor passes do not establish independent finish acceptance.
  Fresh follow-through: [t_d06ef06d's current-source receipt](docs/quality/2026-10-06-global-sessions-current-check.md)
  binds all 521 copied inputs and a 195-file local dependency closure. At
  acceptance, all source fingerprints and 31 integrity entries matched. Its command
  receipt records 44 shell-widget passes, nine caller/lifetime passes, a fresh
  release web build and one Chromium journey, all exit 0. These checks replace the
  incomplete historical attribution; no duplicate rerun is needed while inputs match.
  Completed acceptance: the [independent review receipt](.task-evidence/t_d06ef06d/review-run/review-validation.json)
  records approved bounded acceptance. Its retained logs record 44 shell-widget
  passes, nine caller/lifetime passes, a fresh web build and one Chromium pass.
  All 31 executor and 27 review integrity entries remain intact. Nine of the
  521 source fingerprints now differ across messaging, history parsing/models
  and channel regressions.
  The ledger preserves this completed review-snapshot task; its execution does
  not qualify those later recovery/Stop changes.
  The bounded goal is met by these executed checks, not by task closure alone.
  Native desktop, live generation, full suites and full parity remain unqualified.
  DOC-M2-AMBIGUOUS-404 is done; DOC-M2-HISTORY-IDENTITY covers current
  history work. After it settles, repeat
  affected caller checks before extending current-source qualification.
  Preserve single create, exact Open, passive observation, keyboard access,
  collapse invalidation and compact recovery. Do not weaken the oracle.
  Dependencies: PARITY-GLOBAL-SESSIONS (done). Ownership: completed t_d06ef06d;
  this documentation handoff does not claim or transition a card or start a worker.
  Verification follow-through: requested `npm run test` exited 1 with 3,386 passes
  and three shell failures: two palette/selection assertions in
  `test/shared/widgets/app_shell_reference_fidelity_test.dart` and the brand-label
  assertion in `test/shared/widgets/app_shell_test.dart`. See
  [execution log](.task-evidence/repo-docs-npm-test.log). Concurrent shell/test edits
  remain untouched; this failed full-suite run does not qualify the current shell.

These are bounded next slices within accepted goals, not claims of current leases.
They do not authorize this documentation job to execute code, tests, installs,
card changes or schedule changes. Existing card scopes and owner-only final actions
remain binding. Do not repeat unchanged failed gates or duplicate claimed work.

- [x] **DOC-M2-CONTINUITY-BASELINE** — Goal: M2. Inspect current detached-run and
  lifecycle tests against the OS-death matrix. Payoff: identify the smallest missing
  recovery oracle before device work. Source: [Android discovery](docs/quality/2026-10-03-android-qualification-discovery.md)
  and [M2](ROADMAP.md#m2--leave-and-return-without-losing-ownership).
  Scope: existing channel/store tests and a sanitized evidence handoff; no live
  target, personal app, credentials, installs or push/draft persistence changes.
  Acceptance: name covered and uncovered owner/history/replay cases and one bounded
  device scenario; deterministic tests must not be labeled OS-death evidence.
  Dependencies: none for inspection; actual device qualification needs M1 and a
  named owned target. Ownership: t_2d1d55ab; baseline delivered in
  [current-source receipt](docs/quality/2026-10-06-m2-continuity-baseline.md).
  Android M2 remains unverified; deterministic recovery is not OS-death proof.

- [x] **DOC-M2-DEATH-COMPLETE-ORACLE** — Goal: M2. Run or add one isolated
  app-level running → absent client → completed → restored-history check.
  Payoff: connect the passing channel/store baseline to the missing relaunch oracle.
  Source: [current-source baseline](docs/quality/2026-10-06-m2-continuity-baseline.md#exactly-one-future-scenario-android-m2-death-complete-01)
  and [M2](ROADMAP.md#m2--leave-and-return-without-losing-ownership).
  Scope: deterministic QA fixture, startup/restoration harness and sanitized receipt;
  exclude live inference, credentials, personal apps, installs, upstream changes,
  push and draft persistence. Do not run the production-package Maestro flow.
  Acceptance: the app restores the explicit non-default owner/session and canonical
  terminal history; counted run submissions remain one and restoration adds zero
  session creates, sends, Stop or approval responses. Record the exact command,
  source hashes and target. Fixture success is not Android OS-death, keystore,
  credential-expiry or denied-notification qualification. Identify the remaining
  named-device check from the baseline scenario without claiming it passed.
  Dependencies: DOC-M2-CONTINUITY-BASELINE (done). Deterministic preparation is
  independent of live M1 admission; actual Android qualification retains M1,
  owned-target, private-auth and consent prerequisites. Ownership: t_e0af7ad4;
  deterministic oracle delivered in [the receipt](docs/quality/2026-10-06-m2-death-completion-oracle.md).
  Android M2 remains unverified; this is not process-death or device qualification.

- [x] **DOC-M2-ANDROID-PREFLIGHT** — Goal: M2. Prepare the named-device
  death-to-completion check without launching or provisioning a target. Payoff:
  move from the passing deterministic oracle to an executable isolation contract.
  Source: [completed fixture oracle](docs/quality/2026-10-06-m2-death-completion-oracle.md)
  and [ANDROID-M2-DEATH-COMPLETE-01](docs/quality/2026-10-06-m2-continuity-baseline.md#exactly-one-future-scenario-android-m2-death-complete-01).
  Scope: inspect existing QA package/build/runner isolation, run-mode receipts and
  metadata-only observer seams. Exclude installs, device/process actions, live
  requests, credential acquisition, inference, upstream edits and notifications.
  Acceptance: produce a sanitized preflight mapping each scenario prerequisite
  to existing evidence or a precise gap. Name the smallest missing observer or
  runner slice and concrete identity/history/no-replay checks. Do not claim
  Android death, keystore durability or runtime acceptance from fixture evidence.
  Dependencies: DOC-M2-DEATH-COMPLETE-ORACLE (done). Preparation is independent of
  live M1 admission; actual execution retains named owned QA target, admitted
  unmodified Agent, private authentication and bounded generation consent.
  Ownership: delivered on `t_f5728f44`; the goal ledger marks this preparation
  done. The [preflight artifact](docs/quality/2026-10-06-m2-android-preflight.md)
  maps isolation and observer prerequisites. All 28 recorded source fingerprints
  match this snapshot. The retained receipt does not establish independent final
  approval. The QA metadata adapter remains proposed; M2 remains unverified.
  Continue with DOC-M2-COUNTING-CONTRACT below, not a duplicate preflight.

- [x] **DOC-SECURITY-CURRENT-BOUNDARY** — Goal: SECURITY. Completed bounded source-bound proof.
  Source: [security boundary receipt](docs/quality/security-current-boundary.md).
  Acceptance evidence: named denial, containment, redaction, approval, changed-replay
  and reconnect checks are recorded as passing. The unspent-approval regression
  includes a failing negative control. Full security/platform qualification is not implied.
  Dependencies: completed ledger dependencies. Ownership: delivered proof; existing
  done status is preserved without a task or card transition.

- [x] **DOC-API-CONFORMANCE** — Goal: API-CONFORMANCE. Check the
  [code-first snapshot](docs/api/wing-link.openapi.yaml) against its cited handlers
  and existing Go route/security tests. Payoff: prevent integrators mistaking a
  structural snapshot for runtime authority. Scope: offline schema/local-reference
  checks and one bounded management-route family; no API redesign, generated client,
  live server or new dependencies. Acceptance: validate with existing tooling where
  available, document unsupported checks and reconcile concrete handler/schema drift.
  Delivered on `t_f2b5c61e`, branch `agent/wing/t_f2b5c61e`:
  [discovery conformance receipt](docs/quality/2026-10-06-wing-link-api-conformance.md)
  for GET `/meta` and GET `/healthz`. All 20 source fingerprints match this snapshot.
  Retained checks cover 62 recorder responses and nine negative cases, with passing
  YAML/reference/JSON Schema and scoped Go checks. The corrected metadata schema
  requires `[1, 2]`; this is not a runtime protocol change. Complete OpenAPI standards
  validation, other management families and live transport remain NOT_CHECKED.
  The goal ledger now records this discovery slice done. The retained execution
  receipt does not establish independent native review; this index does not approve
  or transition its card. API-CONFORMANCE stays unverified. Continue with
  DOC-API-DEVICE-SELF-CONFORMANCE below, not a duplicate discovery dispatch.

- [x] **DOC-M6-ARTIFACT-EVIDENCE** — Goal: M6. Inventory source/artifact-bound receipts
  required by the [release runbook](docs/runbooks/release-alpha.md) and current CI.
  Payoff: expose missing install/upgrade/recovery proof without publishing.
  Scope: existing workflows, artifact verifier and evidence index only; no release,
  signing secrets, builds, installation or live rollback. Acceptance: identify
  candidate receipts, their source/target limits and missing M1–M5/recovery evidence.
  Include the [local verifier prerequisites](docs/runbooks/release-alpha.md#local-artifact-verification):
  candidate source revision, exact evidence/asset allowlist, signing-certificate
  fingerprint and host tooling. Distinguish host verification from separate
  Android, Windows and macOS workflow smoke receipts. Inspection is not execution.
  Dependencies: none for inventory; final qualification/publication depends on
  accepted applicable milestones and owner authority. Delivered on `t_8daadbc0`:
  [source-bound inventory](docs/quality/2026-10-06-m6-artifact-evidence.md),
  implementation checks passed; native same-card review remains pending. M6 is
  unverified. Repo-docs owns the next bounded M6 backlog entry; no new card here.

- [x] **DOC-M6-CANDIDATE-ADMISSION** — Goal: M6. Prepare the offline exact-candidate
  comparison and its negative-case oracle. Payoff: make the next qualification
  step reproducible without treating source receipts as installed-alpha proof.
  Source: [M6 inventory](docs/quality/2026-10-06-m6-artifact-evidence.md#one-bounded-next-step)
  and [local verifier admission](docs/runbooks/release-alpha.md#local-artifact-verification).
  Scope: existing `scripts/release_evidence.mjs`, evidence tests and a sanitized
  admission checklist. Exclude builds, installs, extraction, candidate execution,
  signing secrets, network requests, publication and tracker changes.
  Acceptance: map candidate revision/tag/version/build/run/repository, input and
  artifact digests, certificate identity and target receipts to existing checks.
  Run or add an isolated offline comparison oracle for matching evidence, changed
  identity/bytes and missing platform receipts. Record exact commands and source
  hashes. Synthetic checks qualify only the comparison, not M6. If public candidate
  files are unavailable, finish the checklist and oracle first; leave candidate
  and integrated install/upgrade/recovery NOT_CHECKED. Do not search private state.
  Dependencies: DOC-M6-ARTIFACT-EVIDENCE (done). Preparation needs no candidate or
  owner answer; actual candidate qualification retains its separate admission.
  Ownership: delivered on `t_15e9decd`; the goal ledger marks this bounded
  preparation done. The [admission receipt](docs/quality/2026-10-06-m6-candidate-admission.md)
  records 56 passing offline synthetic tests. Its nine source fingerprints match
  this snapshot. This is not independent final approval, public-candidate execution
  or M6 acceptance. Continue with DOC-M6-OFFLINE-CHECKER below.

- [x] **DOC-M2-COUNTING-CONTRACT** — Goal: M2. Trace the authoritative
  metadata counting source required by the proposed QA observer. Payoff: prevent
  client counters from being mistaken for proof of zero restoration mutations.
  Source: [observer contract](docs/quality/2026-10-06-m2-android-preflight.md#bounded-write-and-delivery-contract).
  Scope: read-only Agent contract/nearest-test and Wing caller trace; exclude
  Agent edits, new endpoints, observer implementation, devices, live requests,
  credentials and Wing Link data-plane routing.
  Acceptance: identify exact operation, grants, owner binding, bounds, accepted/
  rejected mutation coverage and continuous epoch semantics, or document the
  precise unavailable contract. Keep Android qualification unverified either way.
  Dependencies: DOC-M2-ANDROID-PREFLIGHT (done). The goal ledger now records
  the source-only slice on `t_0599745b` done; do not dispatch a duplicate. The
  [source-contract artifact](docs/quality/2026-10-06-m2-counting-contract.md)
  retains `authoritative_counts_unavailable`: inspected metrics, run status,
  replay occupancy and authentication audit do not supply whole-attempt accepted/
  rejected mutation counts. Its offline integrity receipt binds 46 source files
  and the document; this is not installed-runtime or Android qualification.
  The [handoff](.task-evidence/t_0599745b/handoff.json) requests completion only
  after native review. The retained receipt does not establish that review; this
  index records ledger completion, not card approval. M2 remains unverified.
  Continue with DOC-M2-RECOVERY-READ-ADMISSION below; source integrity is not
  milestone acceptance.

- [x] **DOC-M6-OFFLINE-CHECKER** — Goal: M6. Prepare one read-only candidate
  comparison entrypoint using the existing verifier exports. Payoff: turn the
  passing synthetic oracle into a reproducible offline comparison without executing
  artifacts. Source: [required public inputs](docs/quality/2026-10-06-m6-candidate-admission.md#required-public-inputs).
  Scope: bounded offline tooling and its deterministic tests; no protocol redesign,
  builds, installs, extraction, artifact execution, private state, signing secrets,
  network requests or publication.
  Acceptance: explicitly supply independently admitted identity and public certificate
  expectations; compare the published index with recomputed bindings; reject changed
  identity/bytes/certificate and missing receipts. Run an isolated synthetic oracle
  with exact exits and source fingerprints. Missing public inputs leave actual
  candidate comparison NOT_CHECKED; fixture passes do not satisfy M6.
  Dependencies: DOC-M6-CANDIDATE-ADMISSION (done). The goal ledger now records
  the bounded slice on `t_bef84284` done; do not dispatch a duplicate. The
  [delivered comparator runbook](docs/runbooks/offline-release-candidate-comparison.md)
  and [source-bound receipt](.task-evidence/t_bef84284/validation.json) record
  120 passing offline synthetic tests on Node v26.7.0. All four recorded source
  fingerprints match this snapshot. The [handoff](.task-evidence/t_bef84284/handoff.json)
  requires native same-card approval before card closure. The retained receipt
  does not establish that approval; this index does not transition the card.
  No actual public candidate, signature, installed-runtime or Node 22 qualification
  is inferred; M6 stays unverified. Continue with DOC-M6-CHECKER-NODE22 below.

- [x] **DOC-M2-RECOVERY-READ-ADMISSION** — Goal: M2. Trace one exact-owner
  status/history recovery path for the named death-to-completion scenario.
  Payoff: qualify narrower recovery prerequisites without inventing live counters.
  Sources: [counting disposition](docs/quality/2026-10-06-m2-counting-contract.md#practical-next-step-disposition)
  and [scenario](docs/quality/2026-10-06-m2-continuity-baseline.md#exactly-one-future-scenario-android-m2-death-complete-01).
  Scope: existing Agent contract/nearest tests and Wing reconciliation caller;
  read-only reference inspection and isolated Wing checks only. Exclude Agent
  edits, private deployments, credentials, live inference, device operations,
  observer implementation and new endpoints.
  Acceptance: document exact read/grant/identity and terminal-history semantics;
  run or add the smallest isolated recovery check for completed, absent, denied
  and replacement-owner results. Cite exact commands and source-bound receipts.
  These checks do not prove Android OS death or zero live mutations. Retain
  `authoritative_counts_unavailable` unless a separately admitted source proves
  the full counting contract. Record the remaining named-device proof task.
  Dependencies: DOC-M2-COUNTING-CONTRACT (done). Ownership: bounded ledger slice done on
  `t_3c5078de`; do not dispatch a duplicate. The
  [characterization receipt](docs/quality/2026-10-06-m2-recovery-read-admission.md)
  records 16 focused passes, one nearest recreation pass and clean analysis in an
  isolated mirror. All 30 selected fingerprints and five log hashes matched at
  inspection. The positive completed-status/history case is demonstrated, but
  three defects remain: ambiguous 404 clears ownership, unrelated response history
  settles the requested lease, and declared history-grant denial does not gate reads.
  Green characterization tests do not approve those outcomes. Preserve these
  [bounded repair findings](docs/quality/2026-10-06-m2-recovery-read-admission.md#precise-next-repair-findings-not-implemented-here)
  for the ordered repair slices below. The
  [independent review receipt](.task-evidence/t_3c5078de/review-validation.json)
  approves only the bounded characterization and repeats 16 focused checks, one
  nearest check and clean analysis. It does not admit unconditional recovery.
  This index reconciles existing ledger completion, not tracker state or scope.
  M2 remains unverified; no named-device or live-counting acceptance is inferred.

- [x] **DOC-M2-AMBIGUOUS-404** — Goal: M2. Retain uncertain detached-run
  ownership when status 404 cannot distinguish absence from a foreign owner.
  Payoff: prevent an ambiguous read from releasing the duplicate-send guard.
  Source: [finding 1](docs/quality/2026-10-06-m2-recovery-read-admission.md#precise-next-repair-findings-not-implemented-here)
  and [independent review](.task-evidence/t_3c5078de/review-validation.json).
  Scope: existing HTTP recovery reconciliation and its focused tests; exclude
  Agent edits, new endpoints, native RPC, live requests and device execution.
  Acceptance: the existing absent/foreign-404 characterization first demonstrates
  premature settlement; the repaired oracle retains the lease and unresolved
  guard for both indistinguishable outcomes. Exact completed/history recovery
  and denied/replacement controls still pass. Record executed commands and source
  fingerprints. Keep M2 unverified and `authoritative_counts_unavailable`.
  Dependencies: DOC-M2-RECOVERY-READ-ADMISSION (done). The goal ledger records
  this bounded slice done; do not dispatch a duplicate. Executor `t_3a5135a8` delivered the
  [bounded repair receipt](docs/quality/2026-10-06-m2-ambiguous-404.md), with
  18 focused, 78 nearest and 42 restoration passes, clean format and analysis.
  All three changed source/test hashes and retained command-log hashes match the
  inspected snapshot. The [artifact-review receipt](.task-evidence/t_3a5135a8/review-398-validation.json)
  independently records the same 18 focused, 78 nearest and 42 restoration passes,
  baseline RED, clean format and analysis. All five authored fingerprints and
  seven review log hashes match. A [scoped npm receipt](.task-evidence/t_3a5135a8/review-398-npm-validation.json)
  records 394 passes, not a full-suite run. Its log hash also matches. These receipts
  establish independent execution, not a final native approval verdict or M2 acceptance.
  This index preserves ledger completion without transitioning a card. Do not repeat
  unchanged passing checks solely to restate delivery.
  Include the loaded-session caller/lifetime regressions named in
  [the test plan](docs/test-plan.md#acceptance-records-and-gaps) when qualifying
  the changed shared channel; preserve completed review-snapshot acceptance.

- [x] **DOC-M2-HISTORY-IDENTITY** — Goal: M2. Validate response-session and
  compaction lineage before publishing history or settling a recovered lease.
  Payoff: unrelated history cannot masquerade as exact-session recovery.
  Source: [finding 2](docs/quality/2026-10-06-m2-recovery-read-admission.md#precise-next-repair-findings-not-implemented-here).
  Scope: existing history page model, HTTP parser and shared hydration callers;
  exclude upstream changes, shadow history, new APIs and live/device operations.
  Acceptance: run the wrong-history oracle before and after the repair; reject
  unrelated envelopes/rows without publication or settlement, preserve legitimate
  compaction ancestors and exact completed hydration, and pass replacement-owner
  regressions. Bind executed evidence to changed sources; do not claim Android proof.
  Dependencies: DOC-M2-AMBIGUOUS-404 (done), to serialize the shared recovery seam.
  Executor evidence: [implementation report](docs/quality/2026-10-06-m2-history-identity.md)
  and [validation receipt](.task-evidence/t_cd72a5d5/validation.json) record 48 focused,
  432 nearest and 63 caller/restoration passes, clean format and analysis. All 15
  production/test/runbook hashes and 25 command-log hashes match; the report's
  fingerprint differs. Exact-session and proven compaction pages are admitted;
  unrelated pages retain durable ownership without publication or replay.
  Review execution: [source-bound receipt](.task-evidence/t_cd72a5d5/review-404-validation.json)
  binds all 16 selected source/document fingerprints, including the current report.
  Matching logs record 48 focused and 432 nearest passes. The executor report-hash
  mismatch remains historical; current review attribution is established.
  Status: done in `goals.json`. The [independent review](.task-evidence/t_cd72a5d5/review-404.md)
  approves this scoped implementation. Matching review logs record 63 caller passes
  and 543 scoped npm passes, in addition to the focused and nearest checks above.
  M2 remains unverified; this does not qualify Android/live recovery.
  DOC-M2-HISTORY-ADMISSION below records the subsequent implementation slice.

- [x] **DOC-M2-HISTORY-ADMISSION** — Goal: M2. Enforce declared history-read
  grants without removing supported legacy baseline reads.
  Payoff: recovery reads obey the same exact-operation policy as their readiness.
  Source: [finding 3](docs/quality/2026-10-06-m2-recovery-read-admission.md#precise-next-repair-findings-not-implemented-here)
  and [API decision](docs/adr/api-and-state.md#decision).
  Scope: shared history-read admission and nearest recovery/caller tests; exclude
  new capability fields, Agent changes, credential acquisition and live requests.
  Acceptance: execute declared-denied and legacy controls; an ungranted declared
  history operation makes zero history requests and cannot settle its lease.
  Supported legacy and explicitly granted exact-owner history still hydrate;
  replacement-owner results remain fenced. Retain executed receipts and the
  separate named-device/counting prerequisites. M2 remains unverified.
  Dependencies: DOC-M2-HISTORY-IDENTITY (done). Status: done in `goals.json`
  for the bounded repair, with independent same-card approval.
  Executor evidence: [implementation report](docs/quality/2026-10-06-m2-history-admission.md)
  and [validation receipt](.task-evidence/t_4e4a4f7d/validation.json) bind six matching
  source/document hashes. Retained final logs record 64 focused, 432 nearest and
  43 caller passes, clean format and analysis. The superseded focused log is not
  used as acceptance evidence. The [independent review verdict](.task-evidence/t_4e4a4f7d/review-414.json)
  approves this slice. Its matching combined log records 539 passes; the read-only
  integrity check verifies six selected files, 441 mirror Dart files and retained
  command logs. No Android/live/M2 qualification follows. Continue with
  DOC-M2-POST-REPAIR-CALLERS, not a duplicate repair or review.

- [x] **DOC-M2-POST-REPAIR-CALLERS** — Goal: M2. Qualify current loaded-session
  callers after shared recovery repairs. Payoff: fresh compiled evidence binds
  shell Open/New and caller admission to the repaired history path.
  Sources: [caller qualification gap](docs/test-plan.md#acceptance-records-and-gaps),
  [loaded-session runbook](docs/runbooks/global-session-access.md) and
  [history-admission receipt](docs/quality/2026-10-06-m2-history-admission.md).
  Scope: isolated current-source widget/caller checks, release fixture web build
  and the existing global-session-access Chromium journey. Exclude production
  repairs, upstream edits, installs, live requests, credentials and device actions.
  Acceptance: retain exact argv, source/import/build fingerprints and passing
  shell/lifetime/caller checks plus the compiled keyboard Open/New journey.
  Assert exact scoped reads, one deliberate create and no layout-driven requests;
  retain denial/owner-replacement controls. Report Android/process-death and
  authoritative live counts as unverified, with their next bounded proof slice.
  Dependencies: DOC-M2-HISTORY-ADMISSION (done, bounded review approved). This
  task qualifies loaded-session callers; it does not reopen or approve that repair.
  Status: done in `goals.json` for this bounded execution slice. The
  [current-source report](docs/quality/2026-10-06-m2-post-repair-callers.md) and
  [command receipt](.task-evidence/t_103d63ec/commands.json) record 85 focused
  passes, clean analysis/formatting, a fresh release build and one Chromium pass.
  All 519 copied inputs and nine command-log hashes match this snapshot.
  Independent same-card final approval remains unverified; this entry does not
  transition the card or qualify M2. Continue with the credential-denial oracle,
  not a duplicate loaded-session run.

- [x] **DOC-M2-CREDENTIAL-DENIAL-ORACLE** — Goal: M2. Prove fail-closed
  recreated-client recovery when the saved owner's credential is rejected.
  Payoff: cover the accepted failure checkpoint at app level before device execution.
  Sources: [credential/owner checkpoints](docs/quality/2026-10-06-m2-continuity-baseline.md#exactly-one-future-scenario-android-m2-death-complete-01),
  [Android preflight](docs/quality/2026-10-06-m2-android-preflight.md#scenario-prerequisite-and-oracle-map)
  and [existing app-level oracle](test/features/hermes_chat/screens/hermes_chat_death_completion_recovery_test.dart).
  Scope: extend the existing isolated recreation harness with deterministic Agent
  authentication denial and later valid-owner read recovery. Reuse production
  channel/directory/store wiring and the serialized fixture store. Exclude live
  credentials, revocation, inference, devices, installs, upstream changes and new APIs.
  Acceptance: execute the added app-level test and nearest auth/recreation tests.
  Rejected credentials must not hydrate foreign history, erase unresolved ownership,
  substitute a session, send text or answer an approval. After explicit valid-owner
  recovery, only original-tuple reads may settle the lease. Count every fixture
  mutation attempt and retain exact commands and source fingerprints.
  A synthetic 401 is not real expiry/revocation, Android keystore or authoritative
  live counting evidence; retain `authoritative_counts_unavailable` and M2 unverified.
  Dependencies: DOC-M2-POST-REPAIR-CALLERS (done, execution slice only).
  Status: `done` in `goals.json` for bounded deterministic execution.
  The [delivered oracle](docs/quality/2026-10-06-m2-credential-denial-oracle.md)
  records two app-level cases, 60 nearest passes and four selected channel passes.
  All 428 recorded lib/test fingerprints match this snapshot. Retained independent
  review execution is available, but a final approval verdict is not established
  here. No product test was rerun by this documentation pass.
  Ownership: preserve t_59ea67ba and its review lane; do not duplicate execution.
  Real expiry/revocation, Android process death and live counts remain unverified.

- [x] **DOC-M2-FORBIDDEN-RECOVERY-ORACLE** — Goal: M2. Bounded HTTP 403
  recreation control delivered; the ledger records this execution task done.
  Evidence: [source-bound oracle receipt](docs/quality/2026-10-06-m2-forbidden-recovery-oracle.md)
  and `.task-evidence/t_b00feca2/oracle.json` / `nearest.json` retain three app-level
  cases and 60 nearest passes. All 428 recorded lib/test fingerprints match the
  inspected snapshot. Denied reads and public Retry retain the original lease;
  explicit authority recovery admits canonical history before settlement without
  fixture mutation replay. The [independent review execution receipt](.task-evidence/t_b00feca2/review-440-tests.json)
  records 63 passing cases and clean analysis. Its closure matches 151 local
  dependencies and 443 analyzed files in this snapshot. This pass inspects receipts,
  not a new product run.
  Ownership: preserve t_b00feca2 and its same-card review lane. Independent final
  approval, live grant revocation, Android process death and live counts remain
  unverified. Do not duplicate the completed resource-read denial control.

- [x] **DOC-M2-BOOTSTRAP-DENIAL-ORACLE** — Goal: M2. Bounded connection-bootstrap
  HTTP 401 recreation control delivered; the ledger records this task done.
  Payoff: cover required-capabilities rejection separately from resource-only denial.
  Sources: [remaining qualification](docs/quality/2026-10-06-m2-forbidden-recovery-oracle.md#remaining-qualification-and-questions)
  and [accepted recovery scenario](docs/quality/2026-10-06-m2-continuity-baseline.md#exactly-one-future-scenario-android-m2-death-complete-01).
  Scope: reuse the isolated app-level recreation harness and production connection
  path. Add one deterministic bootstrap authentication-denial control. Preserve
  completion and resource-read controls. Exclude new protocols, upstream edits,
  live credentials, devices, inference, installs and notification/platform claims.
  Acceptance: execute the app-level oracle and nearest authentication/restoration
  tests. Bootstrap denial and public Retry retain the exact durable lease and
  remembered owner, refuse substitute history and Send, and make no mutation
  attempts. Explicit original-owner authority recovery must reconcile canonical
  history before settlement. Record request attempts, commands, exits and inputs.
  Keep M2 unverified and `authoritative_counts_unavailable`; synthetic rejection
  does not qualify live revocation, secure storage or Android process death.
  Dependencies: DOC-M2-FORBIDDEN-RECOVERY-ORACLE (done, bounded execution only).
  Delivered on `t_15da6893`: [bootstrap HTTP 401 receipt](docs/quality/2026-10-06-m2-bootstrap-denial-oracle.md)
  and `.task-evidence/t_15da6893/oracle-fixed.json` / `nearest.json` retain four
  app-level cases and 60 nearest passes, with clean analysis. All 428 lib/test
  fingerprints, 151 local closure inputs and 443 analyzed files match this snapshot.
  This is inspected execution, not a new test run or independent final approval.
  Preserve the original card/review lane; do not repeat its completed control.

- [x] **DOC-M2-BOOTSTRAP-FORBIDDEN-ORACLE** — Goal: M2. Prove exact-owner
  recreation and public Retry when required capabilities reject with HTTP 403.
  Payoff: complete the bootstrap denial matrix without mistaking resource-only
  HTTP 403 or bootstrap HTTP 401 for this separate rejection control.
  Sources: [bootstrap receipt](docs/quality/2026-10-06-m2-bootstrap-denial-oracle.md#remaining-qualification-and-questions),
  [test plan](docs/test-plan.md#acceptance-records-and-gaps) and
  [accepted recovery scenario](docs/quality/2026-10-06-m2-continuity-baseline.md#exactly-one-future-scenario-android-m2-death-complete-01).
  Scope: inherited isolated app-level recreation harness and existing production
  connection path. Add one required-capabilities HTTP 403 control; preserve all
  four predecessor cases. Exclude live credentials, devices, inference, installs,
  upstream changes, new protocols, notification and platform claims.
  Acceptance: execute the oracle and nearest authentication/restoration tests.
  Count attempts before denial. Recreation and public Retry retain byte-identical
  durable ownership and remembered selection, refuse Send and foreign history,
  and attempt no mutations. Explicit original-authority restoration must admit
  canonical history before settlement. Record commands, exits and input hashes.
  Keep M2 unverified and `authoritative_counts_unavailable`; deterministic success
  is not Android process death, secure-storage or live authorization qualification.
  Dependencies: DOC-M2-BOOTSTRAP-DENIAL-ORACLE (done, bounded execution only).
  Status: done in `goals.json` for bounded deterministic execution. The
  [delivered bootstrap HTTP 403 receipt](docs/quality/2026-10-06-m2-bootstrap-forbidden-oracle.md)
  records five app-level controls and 65 total passes across the oracle and nearest
  targets. All 151 local closure inputs and 443 analyzed files match this snapshot.
  This pass inspected receipts; it did not rerun product checks or establish final
  independent approval. Preserve t_df29f3c6 and its review lane; do not duplicate
  completed denial controls. M2 and authoritative live counts remain unverified.

- [x] **DOC-M2-OBSERVER-COMPOSITION** — Goal: M2. Trace a QA-only recovery
  entrypoint that preserves production persistence and direct Agent transport.
  Payoff: prepare real process-death observation without another fixture-only
  denial control or an unqualified Android run.
  Sources: [preflight delivery contract](docs/quality/2026-10-06-m2-android-preflight.md#bounded-write-and-delivery-contract),
  [counting gap](docs/quality/2026-10-06-m2-counting-contract.md) and
  [accepted scenario](docs/quality/2026-10-06-m2-continuity-baseline.md#exactly-one-future-scenario-android-m2-death-complete-01).
  Scope: source-only composition map and one bounded observer implementation brief.
  Trace startup, channel, endpoint and secure-store injection plus the private
  metadata sink. Exclude implementation, existing owner/lifecycle edits, upstream
  changes, builds, devices, credentials, network, installs and production storage.
  Acceptance: identify exact injectable seams and complete local import closure,
  distinguish awaited secure writes from witnessed Android durability, and specify
  delayed/failed-write and wrong-owner/generation validation oracles. Preserve the
  preflight metadata allowlist and limits; document any unavailable composition
  seam instead of widening authority. Missing authoritative counting must retain
  `authoritative_counts_unavailable` and refuse qualification. Name the next
  bounded implementation slice and separately unexecuted device checks.
  Dependencies: DOC-M2-BOOTSTRAP-FORBIDDEN-ORACLE and DOC-M2-COUNTING-CONTRACT
  (both done for their bounded slices). Ownership: t_bd91fa65 delivered the
  [composition report](docs/quality/2026-10-06-m2-observer-composition.md).
  The [completion receipt](.task-evidence/t_bd91fa65/completion-receipt.json) and
  [offline validation](.task-evidence/t_bd91fa65/validation.json) establish source-only
  completion for its predecessor snapshot. The later default-refusal migration
  changes that closure; this historical binding does not qualify current sources.
  Receipt inspection is not a new product run or independent final approval.
  M2 remains unverified; retain existing review and continuation ownership.

- [x] **QA-M2-STORE-STATE-OBSERVER** — Goal: M2. Implement the conservative
  QA store/state observer through existing production injection seams.
  Payoff: prepare bounded persistence observations without replacing production
  transport or treating fixture counts as live authority.
  Sources: [exact implementation brief](docs/quality/2026-10-06-m2-observer-composition.md#exactly-one-next-implementation-brief)
  and [preflight allowlist](docs/quality/2026-10-06-m2-android-preflight.md#bounded-write-and-delivery-contract).
  Scope: only the three proposed Dart files named in the brief and task evidence.
  Preserve real endpoint, directory, cache, transport and secure-store defaults.
  Exclude production owner/lifecycle changes, upstream edits, counting endpoints,
  Android coordination, new plugins/runners, device/storage probing and live requests.
  Acceptance: execute deterministic delayed/failed-write, wrong-owner/generation,
  nested-scope same-channel, strict-schema and sink-error controls. Preserve the
  delegated coordination key and identical delegated errors. Enforce 128 events
  and 64 KiB per attempt, including wrappers, with bounded queues and readback.
  Recompute the QA import closure and reject fixture imports. Without witnessed
  pre-settlement history or admitted authoritative counts, emit typed unavailable
  evidence and refuse qualification. Do not infer admission from later UI state.
  Record exact focused test, formatter and analyzer commands plus source hashes;
  no device, durability, counting or integrated M2 pass may be inferred.
  Dependencies: DOC-M2-OBSERVER-COMPOSITION (done for source-only composition).
  Ownership: t_53f0d91e delivered the three-file adapter; its
  [completion handoff](.task-evidence/t_53f0d91e/completion-receipt.json) and
  [validation receipt](.task-evidence/t_53f0d91e/validation.json) record 24 deterministic
  passes, clean scoped analysis and formatting. Review correction `c141d8d7` rejects
  failed or unavailable history/canonical observations before synthetic admission
  advances. Six regressions first failed, then passed with the corrected validator.
  Those fingerprints describe the predecessor snapshot, not the later
  QA-M2-DEFAULT-REFUSAL migration. Its raw runtime observer and sink APIs have
  been removed; private fake diagnostics retain bounded tooling coverage.
  Done for bounded implementation, not independent final approval, Android
  durability, extraction, authoritative counts or integrated M2 acceptance.

- [x] **DOC-M2-QA-DELIVERY-ADMISSION** — Goal: M2. Trace dedicated QA package
  and private receipt-retrieval admission before named-device execution.
  Payoff: prevent source-only observer delivery from becoming a platform claim.
  Sources: [remaining observer limits](.task-evidence/t_53f0d91e/report.md#remaining--evidence-ceiling)
  and [Android preflight](docs/quality/2026-10-06-m2-android-preflight.md).
  Scope: read-only entrypoint, Gradle/manifest, plugin, runner and fixed QA sink
  trace; record a bounded delivery/extraction brief and offline integrity checks.
  Exclude source changes, installs/builds, device or private-storage probing,
  personal credentials, live inference, Agent edits and new counting authority.
  Acceptance: identify exact target/package/entrypoint isolation, plugin-delivery
  checks, attempt/generation continuity and bounded secret-safe retrieval limits.
  State which APK/device checks remain unexecuted. If no permitted retrieval or
  isolation seam exists, document that gap rather than inventing a runner.
  Preserve `history_admission_unavailable`, `authoritative_counts_unavailable`
  and M2 unverified; source checks cannot prove OS death or zero live mutations.
  Dependencies: QA-M2-STORE-STATE-OBSERVER (done for deterministic tooling).
  Completion: [delivery brief](docs/quality/2026-10-06-m2-qa-delivery-admission.md)
  and [independent review](.task-evidence/t_ccec142b/reviewer-round-1.md) verify
  bounded source-only acceptance. APK, plugins, storage, retrieval and M2 remain
  unverified. No worker or tracker transition is implied by this index.

- [x] **DOC-M2-RECEIPT-HANDOFF-CONTRACT** — Goal: M2. Define and review the
  proposed QA-only attempt/generation handoff before adapter implementation.
  Payoff: prevent in-process sink equality from becoming cross-process evidence.
  Sources: [delivery brief and next-slice proposal](docs/quality/2026-10-06-m2-qa-delivery-admission.md#exactly-one-proposed-next-slice-qa-only-continuityretrieval-adapter)
  and [scoped review](.task-evidence/t_ccec142b/reviewer-round-1.md).
  Scope: one source-backed contract artifact for typed attempt/current/prior
  generation input, fixed-key retrieval admission and separate envelope validation.
  Trace existing QA seams and record the proposed bounded write allowlist.
  Exclude implementation, transport/coordinator activation, packaging, devices,
  storage probes, credentials, network, inference and new counting authority.
  Acceptance: specify observable rejection for wrong package/target, missing
  retrieval permission, swapped generations, foreign attempts, corrupt/oversized
  or secret-bearing records and changed handoffs. A successful proposed handoff
  validates each envelope against its own generation without enumeration, writes
  or qualification. Review must distinguish independent platform evidence from
  caller assertions; keep history/counting unavailable and M2 unverified.
  Dependencies: DOC-M2-QA-DELIVERY-ADMISSION (done for source-only preparation).
  Completion: done in `goals.json` for the bounded proposal on `t_d6c8aa4f`.
  The [contract artifact](docs/quality/2026-10-06-m2-receipt-handoff-contract.md)
  and [retained receipt](.task-evidence/t_d6c8aa4f/validation.json) record 32 passing
  synthetic policy controls, matching selected inputs and scoped integrity checks.
  This pass repeats the checker read-only; it does not execute Dart or storage.
  Independent final approval remains unverified. The adapter and coordinator are
  not implemented or authorized by this proposal; M2 remains unverified.
  Continue with DOC-M2-COORDINATOR-ADMISSION-TRACE, not a duplicate contract task.

- [x] **DOC-M2-COORDINATOR-ADMISSION-TRACE** — Goal: M2. Trace the independent
  admission and exclusive ordering prerequisite for QA receipt continuity.
  Payoff: identify a source-backed next proof step without mistaking caller flags
  or same-key reads for cross-process authority.
  Sources: [independent admission](docs/quality/2026-10-06-m2-receipt-handoff-contract.md#independent-admission-distinct-from-caller-assertions)
  and [fixed-key ordering](docs/quality/2026-10-06-m2-receipt-handoff-contract.md#fixed-key-ordering-and-retention).
  Scope: existing QA entrypoint, sink, packaging and runner seams, inspected read-only;
  one source-backed admission map and bounded next proof task. Exclude adapter or
  coordinator implementation, activation, packaging edits, devices, private storage,
  credentials, network, inference, new counting authority and upstream edits.
  Acceptance: identify whether existing seams can independently bind the immutable
  attempt/generation and candidate/target/storage tuple, authorize the fixed read,
  fence competing writers and retain prior bytes before a new write. Cite exact
  sources and an offline integrity check; where absent, name the precise missing
  seam and its smallest separately reviewed proof slice. Preserve diagnostic-only
  results, unavailable history/counting and M2 unverified. Source inspection cannot
  qualify a device, storage durability or zero live mutations.
  Dependencies: DOC-M2-RECEIPT-HANDOFF-CONTRACT (done for proposal preparation).
  Completion: done in `goals.json` on `t_06c58314` for source-only preparation.
  The [source-only trace](docs/quality/2026-10-06-m2-coordinator-admission-trace.md)
  maps missing independent admission and shared-slot custody. All 25 recorded
  source/report fingerprints now match the refreshed binding. Independent final
  approval remains unverified. Its proposed custody proof is not authorized by
  this artifact; continue with DOC-M2-CUSTODY-PROOF-REVIEW, not duplicate execution.

- [x] **DOC-M2-CUSTODY-PROOF-REVIEW** — Goal: M2. Review the proposed bounded
  QA fixed-slot custody proof before implementation. Payoff: turn the completed
  admission trace into explicit proof requirements without activating transport.
  Source: [proposed next slice](docs/quality/2026-10-06-m2-coordinator-admission-trace.md#exactly-one-proposed-next-proof-slice).
  Scope: source-only design and rejection-matrix review of the stated QA allowlist.
  Exclude source/test implementation, packaging, devices, private storage, secrets,
  network, inference, new counting authority and upstream edits.
  Acceptance: identify typed authority issuance, complete caller closure, separate
  read/write rights, competing-writer refusal and immutable retention before release.
  Define deterministic success/refusal observations and an offline integrity check.
  Separate in-process enforcement from unavailable cross-process custody. Preserve
  diagnostic-only results, unavailable history/counting and M2 unverified. This
  review does not itself authorize implementation or qualify storage/device behavior.
  Dependencies: DOC-M2-COORDINATOR-ADMISSION-TRACE (done for source-only preparation).
  Completion: done in `goals.json` on `t_321431fe` for requirements review only.
  The [custody requirements](docs/quality/2026-10-06-m2-custody-proof-review.md)
  bind 38 files, 13 citation ranges and four local links. Read-only validation
  matches these inputs. Retained offline controls test artifact integrity, not
  executable custody. Independent final approval and M2 remain unverified.

- [x] **QA-M2-CUSTODY-ORDERING-ORACLE** — Goal: M2. Run or add an isolated
  deterministic custody-ordering oracle before runtime integration.
  Payoff: replace specified ordering observations with executed fake-only evidence.
  Sources: [custody requirements](docs/quality/2026-10-06-m2-custody-proof-review.md#typed-issuance-and-custody-contract)
  and [observation matrix](docs/quality/2026-10-06-m2-custody-proof-review.md#required-deterministic-observation-matrix).
  Scope: `test/tooling/` fake-only proof of registration, fixed prior read,
  byte-exact retention and explicit writer release. Reuse the existing envelope
  validator without changing it. Exclude runtime main, secure sink, production
  composition, packaging, devices, real storage, transport, secrets, network,
  new counting authority and upstream edits. This task does not activate the
  proposed coordinator or authorize migration of public runtime constructors.
  Acceptance: execute completer-controlled OBS-PAIR, OBS-REPLAY, OBS-REGISTER,
  OBS-RELEASE, OBS-READRACE, OBS-RETAINRACE and OBS-TWOWRITERS controls with
  separate inspection/readback counters. Reject premature release, competing
  registration and revoked late completion. Prove exact retained bytes precede
  the first separately authorized fake write. Run changed-file formatting,
  scoped analysis and `flutter test --no-pub test/tooling/m2_receipt_admission_test.dart`.
  Retain commands, exits and input fingerprints. Report this as an isolated
  in-process oracle, not runtime enforcement, cross-process custody or Android
  acceptance. Keep unavailable history/counting and M2 unverified; identify the
  remaining full caller-closure proof separately without expanding this task.
  Dependencies: DOC-M2-CUSTODY-PROOF-REVIEW (done for requirements review).
  Completion: done in `goals.json` on `t_40dcd771`. The
  [inspected release evidence](docs/quality/2026-10-06-m2-custody-ordering-oracle.md)
  records 18 fake-only passes. Seven selected source hashes and the authored test
  hash match; the test matches the committed branch blob. Independent final
  approval, runtime enforcement and Android M2 remain unverified. Do not repeat
  this completed oracle as a substitute for runtime caller-closure proof.

- [x] **DOC-M2-RUNTIME-CALLER-CLOSURE** — Goal: M2. Prepare complete runtime
  caller-closure proof after the isolated custody oracle.
  Payoff: identify the smallest missing executable boundary check before integration.
  Sources: [completed oracle and remaining limits](docs/quality/2026-10-06-m2-custody-ordering-oracle.md#qualification-limits-and-next-proof)
  and [custody requirements](docs/quality/2026-10-06-m2-custody-proof-review.md#complete-present-caller-closure).
  Scope: source-only trace of the QA entrypoint, observer, journal, sink, all local
  callers, imports, exports, parts and public constructors. Exclude source/test
  changes, runtime activation, installed authority, devices, secure storage access,
  packaging, transport, credentials, network and upstream edits.
  Acceptance: map every path that can construct or reach a runtime writer, identify
  fake-authority injection and bypass paths, and name the smallest executable
  no-bypass regression with an observable refusal before I/O. Distinguish existing
  tests from missing proof. Identify any required caller/test scope amendment;
  do not preserve unsafe public construction merely to avoid migration. Bind the
  report to selected source hashes and validate its local links and citations.
  Inspection does not enforce custody or qualify Android; keep M2 unverified and
  unavailable history/counting explicit. No coordinator or issuer is authorized.
  Dependencies: QA-M2-CUSTODY-ORDERING-ORACLE (done for fake-only execution).
  Ownership: completed source-only delivery by t_481b1474; see the
  [caller-closure report](docs/quality/2026-10-06-m2-runtime-caller-closure.md).
  A read-only integrity check matches 662 scanned files, four direct Dart consumers
  and 188 local dependencies. Retained artifact checks reject six isolated changes.
  This predecessor report did not execute runtime refusal or compiler closure.
  QA-M2-DEFAULT-REFUSAL now covers those bounded checks; installed custody and
  Android remain unverified.
  Independent final approval is not established by these receipts.

- [x] **QA-M2-DEFAULT-REFUSAL** — Goal: M2. Prove the actual QA bootstrap and
  public library surface refuse unadmitted runtime construction before I/O.
  Payoff: replace source-only bypass analysis with one discriminating executable
  regression slice, without admitting installed authority or positive runtime work.
  Source: [specified runtime regressions](docs/quality/2026-10-06-m2-runtime-caller-closure.md#smallest-future-executable-no-bypass-regression)
  and [caller/test amendment](docs/quality/2026-10-06-m2-runtime-caller-closure.md#required-future-amendment-and-scope-limits).
  Scope: bounded QA entrypoint/support privacy and default-refusal migration,
  existing observer/admission tests and isolated external-consumer compile probes.
  Include both existing test consumers in the engineering scope review before
  migration. Exclude installed issuer/coordinator activation, secure-plugin I/O,
  product-store migration, packaging, devices, private transport, credentials,
  network, Agent changes and live counting. This documentation pass implements none.
  Acceptance: execute REG-DEFAULT/INJECTION/API/POSITIVE against the actual boundary.
  Absent admission refuses before sink/plugin, journal, observer, channel/delegate
  construction or runApp, including delayed callbacks; all I/O counters remain zero.
  External consumers cannot construct raw sinks or inject arbitrary journals/authority;
  allowed metadata still compiles. Preserve fake-only ordering as a positive control.
  Isolated gate-removal, constructor-reopening and foreign-writer mutations must
  fail their intended invariant. Run scoped formatting, analysis, both tooling
  tests and compile probes; retain exact commands, exits and input fingerprints.
  Passing source-level refusal does not prove installed or cross-process custody,
  Android death, admitted history or authoritative counts. Keep M2 unverified.
  Dependencies: DOC-M2-RUNTIME-CALLER-CLOSURE (done for preparation).
  Delivered source-level refusal and private fake diagnostics on `t_41606eec`;
  [executed evidence](docs/quality/2026-10-06-m2-default-refusal.md).
  M2 remains unverified; installed/Android/cross-process qualification is absent.
  All 13 authored fingerprints match the retained validation receipt. Its logs
  record 44 tooling passes, 60 negative consumers, four positive controls and three
  discriminating isolated mutations. This pass inspects receipts, not new tests.
  Ownership: completed bounded delivery on t_41606eec; independent final approval
  remains unverified. Do not duplicate its review or reopen this completed slice.

- [x] **DOC-M2-REFUSAL-CONTINUATION** — Goal: M2. Reassess the named-device
  recovery prerequisites after the QA entrypoint became refusal-only.
  Payoff: identify one safe next proof without treating removed observer APIs as usable.
  Sources: [delivered refusal and limits](docs/quality/2026-10-06-m2-default-refusal.md#scope-and-predecessor-limits)
  and [named-device scenario](docs/quality/2026-10-06-m2-continuity-baseline.md#exactly-one-future-scenario-android-m2-death-complete-01).
  Scope: source-only delta of existing preflight, packaging, storage, receipt custody,
  history admission and counting prerequisites against the current public boundary.
  Exclude code/test edits, authority issuance, coordinator/transport activation,
  plugin/storage I/O, builds, installs, device actions, credentials and live requests.
  Acceptance: bind a bounded updated preflight to current sources, distinguish
  removed versus still available seams, and name exactly one missing prerequisite
  with an observable proof and explicit implementation/review limits. Preserve
  runtime `not_admitted`, `continuation_unavailable`, `qualifies=false` and the
  authoritative counting gap. Inspection must not claim Android or M2 acceptance.
  Dependencies: QA-M2-DEFAULT-REFUSAL (done for offline source-level enforcement).
  Ownership: completed source-only delivery by t_c799c475; see the
  [updated preflight](docs/quality/2026-10-06-m2-refusal-continuation-preflight.md).
  Its retained receipt records 36 source fingerprints, seven links and 25 citation
  ranges passing. Current source and document hashes match that receipt.
  This completion proves neither installed authority nor Android recovery.
  Continue with DOC-M2-ISSUER-EVIDENCE-CONTRACT below; do not repeat this preflight.

- [x] **DOC-M2-ISSUER-EVIDENCE-CONTRACT** — Goal: M2. Prepare the source-only
  installed QA issuer admission evidence contract identified by the updated preflight.
  Payoff: define independently sourced admission proof without activating runtime.
  Source: [one missing prerequisite](docs/quality/2026-10-06-m2-refusal-continuation-preflight.md#exactly-one-missing-prerequisite).
  Scope: one proposed admission dossier and fail-closed acceptance matrix only.
  Exclude code/tests/runners/manifests, authority issuance, bootstrap inputs,
  coordinators, transport selection, storage I/O, builds, installs, devices,
  credentials, live requests and upstream edits.
  Acceptance: map package/entrypoint/closure, target/storage incarnation,
  attempt/generation, freshness/revocation, separate read/write rights and exclusive
  receipt custody to independent measurement owners and exact provenance.
  Mark absent evidence UNAVAILABLE; the current refusal-only candidate must yield
  NOT_ADMITTED. Distinguish source identity from APK, installed and OS evidence.
  Keep authoritative counts and Android M2 unverified. The proposed contract
  grants no implementation or runtime rights, even after bounded document review.
  Dependencies: DOC-M2-REFUSAL-CONTINUATION (done). Source-only delivery by
  t_620a6d33: [admission evidence dossier](docs/quality/2026-10-06-m2-issuer-evidence-contract.md).
  Its document checks bind 18 source fingerprints, seven initial links and 13
  citation ranges, ten required installed facts and fifteen refusal rows.
  Current candidate is NOT_ADMITTED; no issuer or runtime rights are granted.
  Android/full M2 remain unverified; native same-card review follows delivery.

- [x] **DOC-M2-PACKAGE-PROVENANCE** — Goal: M2. Completed source-only
  F01/F02 verification brief on t_7e4e424a. Source:
  [package provenance brief](docs/quality/2026-10-06-m2-package-provenance.md).
  Scope: configured versus measured identity, mode, target and delivered closure;
  no artifact, build, device, storage or runtime operation. Retained validation
  records 31 source fingerprints and lexical closure/link checks, not APK proof.
  Independent final approval remains unverified. F01/F02 remain UNAVAILABLE;
  candidate NOT_ADMITTED and Android/full M2 remain unverified.
  Dependencies: DOC-M2-ISSUER-EVIDENCE-CONTRACT (done for source-only delivery).
  Ownership: ledger records this bounded task done; no card transition here.

- [x] **DOC-M2-MANIFEST-ASSESSMENT-CONTRACT** — Goal: M2. Delivered the
  [proposed partial-F01 contract](docs/quality/2026-10-06-m2-manifest-assessment-contract.md)
  on t_bcab1f7e. Its retained verify and altered-document receipts record exit 0;
  all 17 source/authored fingerprints match this pass's inspected snapshot.
  These checks prove document integrity, not inspector enforcement or artifact facts.
  Independent final approval remains unverified. F01/F02 remain UNAVAILABLE;
  candidate NOT_ADMITTED and Android/full M2 remain unverified.
  Dependencies: DOC-M2-PACKAGE-PROVENANCE (done for source-only delivery).
  Ownership: ledger records this bounded task done; no card transition here.

- [x] **DOC-M2-INSPECTOR-ISOLATION-PREFLIGHT** — Goal: M2. Assess the
  delivered manifest contract's tool and isolation prerequisites before implementation.
  Payoff: identify a concrete enforcement path or precise unavailable prerequisites,
  rather than mistake document checks for safe artifact measurement.
  Sources: [reviewed prerequisites](docs/quality/2026-10-06-m2-manifest-assessment-contract.md#reviewed-prerequisites-for-a-future-assessment),
  [hard bounds](docs/quality/2026-10-06-m2-manifest-assessment-contract.md#isolation-and-explicit-hard-bounds)
  and [M2 exit evidence](ROADMAP.md#m2--leave-and-return-without-losing-ownership).
  Scope: source/documentation inspection and harmless read-only tooling/OS metadata
  checks for a pinned public SDK closure, immutable input and unprivileged isolation.
  Exclude private-state searches, APK acquisition/inspection, inspector execution,
  source/tests, provisioning, installs, sudo, builds, devices, network and runtime activation.
  Acceptance: map each time/memory/process/output/parser/cleanup bound to its actual
  enforcement prerequisite. Record unavailable facts without invented pins or relaxed
  limits. Name one bounded next proof slice, not permission to execute it.
  Dependencies: DOC-M2-MANIFEST-ASSESSMENT-CONTRACT (done for source-only delivery).
  Ownership: delivered on t_909a35ba in the
  [bounded preflight](docs/quality/2026-10-06-m2-inspector-isolation-preflight.md).
  Public tool/OS metadata and launcher source were read without inspector execution.
  Full approved SDK closure, immutable input and isolation enforcement remain
  UNAVAILABLE; F01/F02 and Android/full M2 remain unverified. Native same-card
  review follows this source/metadata-only delivery.

- [x] **DOC-M2-SYNTHETIC-ISOLATION-CONTRACT** — Goal: M2. Review the proposed
  synthetic isolation/immutable-input proof before adapter implementation.
  Payoff: identify enforceable bounds or precise refusal conditions without
  confusing public metadata with sandbox qualification.
  Sources: [next proof slice](docs/quality/2026-10-06-m2-inspector-isolation-preflight.md#exactly-one-next-proof-slice)
  and [prerequisite map](docs/quality/2026-10-06-m2-inspector-isolation-preflight.md#candidate-enforcement-path-and-prerequisite-map).
  Scope: one source-only contract for deterministic public non-APK controls,
  fixed adapter/closure identity, immutable input and descendant-inclusive limits.
  Exclude adapter/source/test implementation, sandbox activation, SDK/JVM execution,
  artifact acquisition, private discovery, installs, sudo, network, devices,
  credentials and runtime authority. Do not relax predecessor limits.
  Acceptance: map each proposed control to an observable enforced bound or
  UNAVAILABLE/ISOLATION_FAILURE result. Resolve exact aggregate CPU semantics,
  scratch inode policy and kill/reap evidence before any executable follow-up.
  Preserve NOT_ADMITTED, F01/F02 UNAVAILABLE and Android/full M2 unverified.
  Dependencies: DOC-M2-INSPECTOR-ISOLATION-PREFLIGHT (done for bounded delivery).
  Ownership: source-only contract delivered on t_8ce3dc30 in the
  [synthetic proof contract](docs/quality/2026-10-06-m2-synthetic-isolation-contract.md).
  Exact CPU enforcement, additional inode-policy review and descendant kill/reap
  remain UNAVAILABLE. Document-integrity checks do not qualify isolation or APKs;
  native same-card review follows delivery, not adapter approval.

- [x] **DOC-M2-CPU-ENFORCEMENT-FEASIBILITY** — Goal: M2. Assess one exact
  cumulative CPU enforcement prerequisite before synthetic adapter execution.
  Payoff: determine whether the proposed proof can enforce its unchanged ceiling,
  rather than repeat contract preparation or mistake counter polling for enforcement.
  Sources: [CPU semantics](docs/quality/2026-10-06-m2-synthetic-isolation-contract.md#unchanged-limits-and-exact-cumulative-cpu-semantics)
  and [conditional next proof](docs/quality/2026-10-06-m2-synthetic-isolation-contract.md#exactly-one-smallest-conditional-next-proof-slice).
  Scope: source/documentation-only mechanism assessment against the delivered
  contract, including trusted-worker, descendant and termination accounting.
  Exclude implementation, control execution, SDK/JVM use, APK access, provisioning,
  installs, sudo, devices, credentials, runtime activation and relaxed limits.
  Acceptance: identify an evidenced mechanism and its enforcement assumptions,
  or document why none is established. Distinguish aggregate consumption from rate,
  per-process limits and post-exceedance observation. Preserve UNAVAILABLE and
  NOT_ADMITTED without a complete proof; Android/full M2 remain unverified.
  Dependencies: DOC-M2-SYNTHETIC-ISOLATION-CONTRACT (done for source-only delivery).
  Ownership: source-only delivery completed on t_d2b9b4db; see the
  [feasibility assessment](docs/quality/2026-10-06-m2-cpu-enforcement-feasibility.md).
  The reviewed interfaces do not establish the exact inclusive CPU budget.
  Mechanism NOT_ESTABLISHED; prelaunch UNAVAILABLE / cpu_budget_unavailable.
  No mechanism/control execution or independent final approval is established.
  Continue with DOC-M2-CPU-ENVELOPE-PROOF; no adapter execution is authorized.

#### Dependency-ordered successor slices

- [x] **DOC-M2-CPU-ENVELOPE-PROOF** — Goal: M2. Delivered the fixed single-CPU
  early-stop worst-case envelope. Payoff: test the delivered assessment's one
  conditional source-only proof seam instead of rerunning unproven controls.
  Source: [conditional proof seam](docs/quality/2026-10-06-m2-cpu-enforcement-feasibility.md#outcome-and-exactly-one-conditional-next-proof-seam).
  Scope: source-only proof for a fixed fair-class, single-CPU cpu.max construction
  and trusted closure. Exclude implementation, provisioning, kernel edits, adapter
  or control execution, SDK/APK access, devices, private state and relaxed limits.
  Acceptance: justify finite inclusive B/L/K bounds from before setup through
  teardown satisfying the unchanged inequality, or identify the first unbounded
  term. Account for replenishment and scheduler/accounting granularity. Retain
  UNAVAILABLE and NOT_ADMITTED without complete proof; M2 stays unverified.
  Dependencies: DOC-M2-CPU-ENFORCEMENT-FEASIBILITY (done for source-only delivery).
  Ownership: done in goals.json for source-only delivery on `t_02e4e461`.
  The [delivered assessment](docs/quality/2026-10-06-m2-cpu-envelope-proof.md)
  identifies `B_setup` as the first unestablished term. Document integrity is not
  CPU enforcement or independent approval. Do not dispatch duplicate work.

- [x] **DOC-SECURITY-REPLAY-EVIDENCE** — Goal: SECURITY. Completed bounded source-bound proof.
  Source: [security boundary receipt](docs/quality/security-current-boundary.md).
  Acceptance evidence: named denial, containment, redaction, approval, changed-replay
  and reconnect checks are recorded as passing. The unspent-approval regression
  includes a failing negative control. Full security/platform qualification is not implied.
  Dependencies: completed ledger dependencies. Ownership: delivered proof; existing
  done status is preserved without a task or card transition.

- [x] **DOC-PARITY-PLATFORM-DEVIATIONS** — Goal: PARITY. Indexed compact Profiles
  management access against the Desktop picker outcome.
  Payoff: record the mobile adaptation without claiming platform parity.
  Sources: [compact receipt](docs/quality/compact-desktop-outcome.md) and
  [PARITY](docs/product/hermes-desktop-parity.md#reference-and-evidence-boundary).
  Scope: source comparison and existing navigation checks only; no product changes.
  Acceptance evidence: retained two passing Linux-hosted Flutter widget checks
  prove selected mobile Profiles navigation and wide/compact return. All eight
  source fingerprints match. Mobile keyboard, real destination recovery,
  Android/native runtime and full parity remain NOT_CHECKED.
  Dependencies: DOC-PARITY-COVERAGE (done).
  Ownership: completed ledger delivery on `agent/wing/t_1f328b2e`; this pass
  inspects evidence and does not establish independent final review approval.

- [x] **DOC-PARITY-RECENTS-REFERENCE** — Goal: PARITY-COMPOSITION. Compared
  grouping metadata, ordering and exact-owner opening separately from the footer.
  Payoff: supply the bounded implementation contract for loaded recents.
  Sources: [recents comparison](docs/quality/grouped-recents-reference.md#bounded-port-grouped-recents-contract)
  and [PARITY-COMPOSITION](docs/product/hermes-desktop-parity.md#reference-and-evidence-boundary).
  Scope: source comparison and existing regressions; no grouped-recents product code.
  Acceptance evidence: the receipt records eight existing exact-Open and lifetime
  widget passes, not grouping or disclosure execution. The next slice groups
  loaded rows by exact source, not unsupported Project/folder metadata.
  Dependencies: DOC-PARITY-COMPOSITION (done).
  Ownership: completed ledger comparison; independent final review is not
  established by this documentation pass. The later PORT-GROUPED-RECENTS delivery
  is recorded above; this comparison remains historical preparation evidence.

- [x] **DOC-CHAT-TRANSCRIPT-DISCLOSURE** — Goal: CHAT-FIDELITY. Delivered one reasoning disclosure comparison.
  Source: [comparison receipt](docs/quality/chat-transcript-disclosure.md).
  Acceptance evidence: source comparison identifies active/completed summary divergence;
  the receipt records one passing initial-collapse/pointer-reveal regression.
  Keyboard, re-collapse, focus and recovery remain unproven; implementation follows
  in PORT-CHAT-TRANSCRIPT-DISCLOSURE. No full transcript parity is established.
  Dependencies: DOC-CHAT-FIDELITY-REFERENCE (done). Ownership: delivered on t_0de1df01;
  existing done ledger status preserved, not independently accepted by this pass.

- [x] **DOC-SESSION-DELETE-EVIDENCE** — Goal: SESSIONS. Prove one owner-bound session-delete confirmation journey.
  Payoff: qualify delete without treating one action as complete session parity.
  Source: [delete journey receipt](docs/quality/session-delete-journey.md).
  Scope: Production Chat screen/channel/client with deterministic HTTP recording.
  Acceptance: Retained logs record three passing delete/reconnect, Cancel and
  same-ID profile-replacement journeys, 136 mutation-owner passes and five
  channel-delete passes. The receipt also records three selected ownership passes
  and two client passes. Reconnect adds no mutation.
  Dependencies: DOC-SESSION-ACTIONS-EVIDENCE is done. Section: Done.
  Ownership: delivered on `agent/wing/t_3634d69c`; already done in goals.json.
  This documentation pass inspects receipts and does not rerun product tests.

- [x] **DOC-SESSION-FORK-JOURNEY** — Goal: SESSIONS. Prove owner-bound branch creation and authoritative reopen.
  Payoff: qualify branch creation without treating it as complete session parity.
  Source: [branch journey receipt](docs/quality/session-fork-journey.md).
  Scope: Production Chat screen/channel/client with deterministic HTTP recording.
  Acceptance: Retained logs record three branch/reopen, Cancel and same-ID owner
  replacement passes. Confirmation creates one child and reads its history;
  reconnect/reopen uses only GET and displays changed authoritative fixture history.
  The receipt also records 136 mutation-owner, ten channel and one client passes.
  Dependencies: DOC-SESSION-DELETE-EVIDENCE is done. Section: Done.
  Ownership: delivered by `t_36a391f7`; already done in goals.json.
  This documentation pass matches scoped source hashes and inspects the journey log.

- [x] **DOC-SESSION-SEARCH-RESUME-QUALIFICATION** — Goal: SESSIONS. Qualify exact session search and resume.
  Payoff: prove loaded-row search and authoritative reopen without repeating mutation journeys.
  Source: [search/resume receipt](docs/quality/session-search-resume-journey.md).
  Scope: Production Chat screen/channel/client with deterministic HTTP recording.
  Acceptance: Retained logs record four journey passes and 111 nearest passes.
  Search and clear preserve selection until deliberate row selection; reconnect
  and explicit reopen read changed fixture history. Late same-profile and same-ID
  old-profile history cannot replace the current owner. Every request is GET.
  Dependencies: none. Section: Done.
  Ownership: delivered by `t_8866900e`; already done in goals.json.
  This pass matches six source hashes and inspects retained logs, not new execution.
  Full-text/corpus-wide search, native/live support and complete parity remain unqualified.

#### Additional bounded goal slices

- [x] **DOC-PARITY-COVERAGE** — Goal: PARITY. Delivered the
  [next-port mapping](docs/quality/desktop-next-port-slice.md) on
  `agent/wing/t_78c1227c`, matching the ledger's done status.
  Scope: 46 feature-group mappings and one passive-footer implementation contract.
  Acceptance evidence: `python scripts/check_desktop_next_port_slice.py` passes
  for mappings, local links and six scoped fingerprints. This is not runtime parity.
  Remaining: grouped recents, full composition and existing platform/feature slices.
  Ownership: completed mapping delivery; no new lease or review verdict.

- [x] **DOC-SESSION-ACTIONS-EVIDENCE** — Goal: SESSIONS. Prove one owner-bound session rename journey.
  Payoff: qualify rename without treating one action as complete session parity.
  Source: [rename journey receipt](docs/quality/session-rename-journey.md).
  Scope: Production Chat screen/channel/client with deterministic HTTP recording.
  Acceptance: Retained logs record three passing rename/reopen, Cancel and same-ID
  profile-replacement journeys, 136 mutation-owner passes and three channel passes.
  Dependencies: none. SESSIONS is met only for its recorded deterministic journeys; complete Desktop parity remains unqualified.
  Ownership: delivered on `agent/wing/t_afa78f46`; task is already done in goals.json.
  This documentation pass inspects retained evidence and does not rerun product tests.

- [x] **DOC-CHAT-FIDELITY-REFERENCE** — Goal: CHAT-FIDELITY. Completed source comparison of wide draft dictation.
  Source: [composer receipt](docs/quality/chat-fidelity-reference.md).
  Acceptance evidence: seven scoped fingerprints match; the receipt records five
  focus passes and two selected dictation passes. No wide direct action is implemented.
  Dependencies: none. Ownership: delivered on t_98e84581; ledger status preserved.

- [x] **PORT-CHAT-DIRECT-DICTATION** — Goal: CHAT-FIDELITY. Delivered a keyboard-operable wide draft microphone beside attachment.
  Source: [delivery receipt](docs/quality/chat-direct-dictation.md) and
  [six-oracle contract](docs/quality/chat-fidelity-reference.md#bounded-next-port-slice).
  Acceptance evidence: nine artifact fingerprints match the inspected checkout;
  retained logs record 109 widget passes and a JavaScript release build. Wide and
  compact browser receipts record keyboard recovery with zero mutation requests.
  Capture is controlled in widgets; browser capture, physical audio, native runtime
  and standalone branch execution are not qualified. Cancellation discards results,
  unlike Desktop finalize-on-stop. No full composer/transcript parity is claimed.
  Dependencies: DOC-CHAT-FIDELITY-REFERENCE (done); assemble the approved model-selection
  predecessor before this card for a clean build. Ownership: delivered on t_f2f5b956;
  existing done ledger status preserved, independent final approval not inferred.

- [x] **PORT-CHAT-TRANSCRIPT-DISCLOSURE** — Goal: CHAT-FIDELITY. Delivered active/completed reasoning summaries and keyboard disclosure.
  Source: [implementation receipt](docs/quality/reasoning-disclosure-implementation.md).
  Scope: timeline, completion-focus guard, localization and nearest widget/browser regressions;
  no new Agent events, protocols or persistence.
  Acceptance evidence: executor reports 91 transcript passes and one compiled Chromium
  journey for status, Enter/Space, completion focus and exact-owner replacement.
  Five scoped branch files match this snapshot. Retained intermediate widget/build
  logs do not establish those final passes. The later recovery receipt retains a
  passing baseline rerun, not a rewrite of those historical logs.
  Dependencies: DOC-CHAT-TRANSCRIPT-DISCLOSURE (done). Ownership: delivered on t_8c01bd65;
  done ledger status preserved, independent final approval not inferred.

- [x] **VERIFY-CHAT-DISCLOSURE-RECOVERY** — Goal: CHAT-FIDELITY. Delivered bounded reasoning disclosure recovery evidence.
  Payoff: qualify recovery separately from the summary-label repair.
  Sources: [comparison recovery limits](docs/quality/chat-transcript-disclosure.md#finding-and-smallest-discriminating-oracle)
  and [delivery receipt](docs/quality/reasoning-disclosure-recovery.md).
  Scope: existing viewport/timeline and nearest widget/browser tests. Preserve unique
  row identity, selectable redacted content and authoritative reconciliation. Exclude
  backend changes, new persistence, upstream edits and unrelated transcript controls.
  Acceptance: exercise owner switch, row eviction and read-only reconnect; stale
  reasoning never appears in a replacement owner, summary focus stays predictable,
  and restoration causes zero sends/approvals. Record whether expansion is retained
  or resets for each supported case, with passing named tests and a browser journey.
  Completion evidence: retained final logs record 100 widget passes, clean analysis,
  a completed JavaScript build and two Chromium journeys. Eight source fingerprints
  match. Mounted updates retain expansion/focus; eviction/remount and owner replacement
  reset it. HTTP reconnect removes transient reasoning; recovery sends no mutations.
  Dependencies: PORT-CHAT-TRANSCRIPT-DISCLOSURE (done). Ownership: delivered on t_0b5660ab;
  existing done ledger status preserved, independent final approval not inferred.

- [x] **VERIFY-CHAT-DISCLOSURE-ADAPTIVE** — Goal: CHAT-FIDELITY. Delivered bounded compact/wide reasoning keyboard recovery.
  Payoff: preserve the delivered outcome without pointer input or animation.
  Sources: [client accessibility decision](docs/adr/client.md#decision) and
  [implementation limits](docs/quality/reasoning-disclosure-implementation.md#visual-evidence-and-limits).
  Scope: nearest transcript/layout widget and compiled-browser tests plus minimal
  exposed Wing fixes. Exclude audio, backend changes, durable expansion and native claims.
  Acceptance: open/collapse with keyboard at compact and wide widths, change width
  during an active reasoning row, then complete it under reduced motion. Verify
  reachable summary focus, readable status, no stale content, no overflow and zero
  incidental sends/approvals. Run named widget/browser checks and retain final logs.
  Completion evidence: [adaptive receipt](docs/quality/reasoning-disclosure-adaptive.md)
  and retained final logs record 101 widget passes, clean analysis, a fresh JavaScript
  build and three Chromium journeys. All six source fingerprints match. Expansion
  survives width-boundary remount; replacement summary focus remains reachable.
  Native/live and screen-reader qualification remain unverified.
  Dependencies: VERIFY-CHAT-DISCLOSURE-RECOVERY (done). Ownership: delivered on t_e3589e12;
  existing done ledger status preserved, independent final approval not inferred.

- [x] **PORT-CHAT-COMPOSER-ORDER** — Goal: CHAT-FIDELITY. Qualified the existing supported wide-composer order.
  Payoff: continue the accepted composer-fidelity outcome after disclosure recovery.
  Sources: [ChatInput control-order comparison](docs/quality/chat-fidelity-reference.md#source-bound-comparison)
  and [remaining composer gap](docs/product/hermes-desktop-parity.md#reference-and-evidence-boundary).
  Scope: one existing wide-composer control group in Chat layout, localization if
  needed, and nearest widget/browser tests. Recheck the cited reference against live
  callers before editing. Preserve compact usability, exact gates and draft ownership.
  Exclude new folder/context/quick-ask capabilities, audio engines, protocols and native IPC.
  Acceptance: supported controls follow the source-backed order with named keyboard
  traversal and visible focus. Disabled/loading/Stop states remain actionable or
  explained; layout changes cause no sends, model writes or approvals. Execute
  focused widgets and one compiled-browser journey, retaining exact source-bound logs.
  Completion evidence: [composer qualification](docs/quality/chat-composer-order.md)
  records six new named traversal/loading/Stop widgets, 59 focused widget passes,
  clean analysis, a fresh JavaScript build and one keyboard-only Chromium journey.
  Traversal/recovery makes zero mutations; explicit Send/Stop makes one request each.
  Existing order required no production change. Native/live and full parity remain unverified.
  Dependencies: VERIFY-CHAT-DISCLOSURE-ADAPTIVE (done).
  Ownership: delivered on t_1aee2792; native same-card review follows handoff.

- [x] **VERIFY-CHAT-COMPOSER-ORDER-RECOVERY** — Goal: CHAT-FIDELITY. Prove the reordered wide controls survive adaptive return and owner replacement.
  Payoff: preserve composer keyboard order without admitting stale draft or model actions.
  Sources: [composer comparison](docs/quality/chat-fidelity-reference.md#source-bound-comparison)
  and [fidelity requirement](docs/product/hermes-desktop-parity.md#reference-and-evidence-boundary).
  Scope: the control group delivered by PORT-CHAT-COMPOSER-ORDER, nearest widget/browser
  tests and minimal exposed Wing fixes. Preserve compact composition and exact gates.
  Exclude new capabilities, physical audio, native IPC, backend changes and upstream edits.
  Acceptance: use Tab/Shift+Tab and Enter/Space before and after compact/wide return;
  replace the owner during a pending action and verify no stale draft, focus or model
  mutation. Record active-run Stop behavior separately from capture cancellation.
  Execute named widget tests and one compiled-browser journey with request receipts.
  Completion evidence: [adaptive recovery receipt](docs/quality/chat-composer-order-recovery.md)
  records seven new widgets, 68 focused passes and one compiled Chromium journey.
  All seven source fingerprints match; retained final logs confirm the reported checks.
  Adaptive return and pending-owner rejection preserve the draft and focus boundary;
  explicit Send/Stop each issue one request, with zero incidental mutations.
  No production correction was needed; native/live and large-text access remain unverified.
  Dependencies: PORT-CHAT-COMPOSER-ORDER (done).
  Ownership: delivered on t_9e45aaf2; native same-card review follows handoff.

- [x] **VERIFY-CHAT-COMPOSER-ACCESSIBILITY** — Goal: CHAT-FIDELITY.
  Delivered stable widget-order traversal and reduced-motion compact switching.
  Source: [enlarged-text receipt](docs/quality/chat-composer-accessibility.md).
  All eight fingerprints match this snapshot. Retained final logs confirm seven
  widget passes, a fresh web build and one Chromium journey at native 200% zoom.
  Widgets separately exercise 200% text-only scaling, adaptive return, exact Stop
  and zero incidental mutations. This pass inspects receipts, not new execution
  or independent final approval. Native, physical audio and screen-reader support
  remain unqualified. Dependencies: VERIFY-CHAT-COMPOSER-ORDER-RECOVERY (done).
  VERIFY-CHAT-DISCLOSURE-ACCESSIBILITY advances the remaining transcript slice.

- [x] **VERIFY-CHAT-DISCLOSURE-ACCESSIBILITY** — Goal: CHAT-FIDELITY. Keep reasoning
  disclosure readable and keyboard-operable with large text and reduced motion.
  Payoff: extend the supported transcript's accessible equivalent beyond default text size.
  Sources: [client accessibility decision](docs/adr/client.md#decision),
  [adaptive disclosure receipt](docs/quality/reasoning-disclosure-adaptive.md)
  and [verification gaps](docs/test-plan.md).
  Scope: existing reasoning summary/body, adaptive layout and nearest widget/browser
  regressions; repair exposed Wing layout/focus defects only. Exclude new transcript
  capabilities, backend changes, upstream edits and native/screen-reader support claims.
  Acceptance: enlarged text at compact/wide widths remains readable without overflow.
  Tab/Shift+Tab and Enter/Space reach and operate the named disclosure under reduced
  motion. Retain current-owner expansion on adaptive return; reject obsolete-owner
  focus without incidental Agent mutations. Run focused widgets, analyze and one
  compiled-browser journey with source-bound receipts.
  Completion: [source-bound receipt](docs/quality/reasoning-disclosure-accessibility.md)
  and retained final logs confirm two focused widgets, 98 nearest-test passes,
  clean analysis, a JavaScript build and one Chromium journey at 200% zoom.
  All 215 retained input fingerprints match; the removed generated build cannot
  be rehashed. No production correction was needed. Widget text scaling and browser
  zoom remain distinct; native/live and screen-reader support are not qualified.
  Dependencies: VERIFY-CHAT-COMPOSER-ACCESSIBILITY (done).
  Ownership: delivered t_5a14d085; this reconciliation does not infer final approval.

### Dependency-gated existing work

- [x] **DOC-PARITY-COMPOSITION** — Goal: PARITY-COMPOSITION. Delivered the
  [profile-footer/session-modal comparison](docs/quality/profile-footer-composition.md)
  on `agent/wing/t_6a1e03fc`, matching the ledger's done status.
  Scope: source comparison and one bounded passive-footer brief only.
  Acceptance evidence: recorded deterministic shell and route-local shortcut checks;
  no footer, global switcher or full session-modal implementation is claimed.
  The later PORT-PROFILE-FOOTER slice is delivered. Grouped recents and full
  composition retain their separate tasks. Ownership: completed comparison
  delivery; no new lease or review verdict.

- [x] **PARITY-APPROVAL-DISMISSAL** — Goal: M1. The ledger records the
  original-card review handoff on `t_6233c1c5` done. Do not redispatch the historical
  review-entry retry instructions or reopen this task.
  Source: [dismissal runbook](docs/runbooks/chat-approval-dismissal.md) and the
  [goal ledger](goals.json). Payoff: stale local dismissal cannot release a
  replacement answer's busy guard.
  Scope: original queue dismissal and scoped tests; exclude transport, shared
  fakes, upstream changes and complete workflow acceptance.
  Acceptance evidence: the runbook retains the keyboard-driven widget RED and
  queue-only GREEN. The ledger also preserves the later combined-run timeout;
  [test-plan follow-through](docs/test-plan.md#acceptance-records-and-gaps) distinguishes
  that harness failure from the subsequently repaired owner regression.
  Dependencies: none in goals.json. Ownership: delivered original card;
  independent final approval is not established by task status alone.
  No duplicate Agent POST, repaired modal focus containment, native/browser/live,
  packaged or integrated M1 qualification is claimed.

- **PARITY-KEYBOARD-RETURN** (historical, superseded) — Preserve the original archived Providers-local
  card `t_11b62717` and its historical scope, not an unfixed product-defect claim.
  Source: [original diagnosis](docs/runbooks/provider-search.md#large-text-keyboard-return-defect-t_11b62717).
  The separately authorized forward repair `t_c5a4d301` is completed and approved
  in run 98; see the [forward receipt](docs/runbooks/provider-search.md#forward-shared-shell-repair-receipt-t_c5a4d301)
  and [quality follow-through](docs/quality/flutter-keyboard-follow-through.md).
  Payoff: retain truthful provenance without dispatching duplicate repairs.
  Original scope: Providers-local changes only, with shared shell/lifecycle
  excluded. Its eight-case oracle, affected tests, analysis, compiled-browser
  and same-card gates remain historical acceptance requirements, not a new lease.
  Ownership: the governor archived the original card as superseded, not done or
  approved. `t_1c1e6f37` is now done; see its receipt below. No original-card continuation, replacement
  card, automatic full-suite retry or further shell edit is authorized here.

- [x] **PARITY-GLOBAL-SESSIONS** — Original card `t_1c1e6f37` is completed and
  independently approved in run 169. Exact loaded-session Open/New Session from
  feature routes now uses passive directory observation and guarded acknowledgement.
  The [parity ledger](docs/product/hermes-desktop-parity.md) and
  [UI gap audit](docs/product/hermes-desktop-ui-gap.md) now distinguish this delivered
  slice from grouped recents, profile-footer and full session-modal gaps.
  Source: [current runbook](docs/runbooks/global-session-access.md); the
  [retained diagnostic](tools/global_session_access/README.md) describes the earlier
  withdrawn candidates, not the final delivery. The reviewer independently passed
  75 focused tests and six compiled Chromium cases, with clean analysis, formatting
  and whitespace checks; 24 scoped hashes were verified and 171 unchanged neighbor
  passes reused. Native/live/full-parity qualification remains unclaimed.
  Former escalation [BLK-20261005-001](BLOCKERS.md#blk-20261005-001--admit-the-passive-global-session-lifecycle-seam)
  remains resolved. No duplicate task, broader startup redesign or new lease is
  authorized by this index.

- [x] **PARITY-PAIR-READ** — Goal: M1. Deliver the contract-absence fallback
  without inventing session identity. Payoff: prevent an inferred provider/model
  from appearing confirmed after restoration.
  Source: [bounded delivery receipt](docs/quality/session-model-pair-read.md).
  Scope delivered: existing Chat picker and production-path regression; fixture
  GET now matches Agent metadata. No Agent/API extension, shadow lock cache,
  automatic model write or weakened integrated assertion was introduced.
  Acceptance evidence: 358 focused Flutter passes, clean analysis/formatting,
  three fixture tests and a fresh JS-release build. Unknown identity remains
  unselected until deliberate choice; Cancel preserves the session.
  The unchanged daily cases fail the exact-pair assertion at both widths.
  Later resumed-send and final mutation-count assertions are NOT_CHECKED.
  Completion is bounded delivery, not exact-pair restoration or full M1 parity.
  Dependencies: no further dispatch for this completed slice. Native/live
  qualification remains in the existing M1 tasks; supported exact-pair reads
  remain required before claiming restoration parity. Ownership: ledger done;
  this maintenance pass changes no native card or review verdict.

- [x] **PARITY-NATIVE-RELAUNCH** — Goal: M1. Delivered two real native Linux
  process phases under Xvfb with isolated preferences and exact off-page history.
  Source: [bounded native receipt](docs/quality/native-relaunch-workflow.md).
  Scope delivered: owned source/SDK/build copies, bounded compilation, independent
  locks, phase counters and verified child cleanup. No system install or Agent edit.
  Acceptance evidence: distinct GTK PIDs; two submissions, one approval, one Stop
  and zero unexpected mutations. All 628 final native input fingerprints match.
  Retained logs confirm both phases and 56 focused regressions passed. The focused
  manifest predates two helper/test refinements; it is not full final-tree proof.
  Model selection was tested separately, not persisted through restart. Full-shell
  startup, live inference and independent final approval remain unverified.
  Dependencies: completed slice; no redispatch. Ownership: delivered t_eb5c693d,
  matching existing done ledger status. BLK-20261005-003 is resolved for the safe
  user-space prerequisite path; system packages remain unchanged.

- [x] **VERIFY-NATIVE-MODEL-RELAUNCH** — Goal: M1. Delivered combined native
  model acknowledgment, approval/Stop and exact off-page session restart.
  Source: [combined receipt](docs/quality/native-model-relaunch-workflow.md).
  Scope delivered: native fixture and launcher only; no production repair or Agent edit.
  Acceptance evidence: two distinct GTK processes, unchanged mutation counters,
  exact history, clean analysis and 340 focused passes. Both 628-input manifests
  match the inspected snapshot. These are retained receipts, not new test runs.
  Exact-pair restoration is not delivered: the authoritative read is unsupported.
  Restart retains model text with unknown provider identity, no preselection and
  disabled confirmation. Cancel makes no mutation. M1 remains partial.
  Dependencies: completed slice, no redispatch. Ownership: delivered t_158c055a;
  the goal ledger already marks it done. No review verdict changes here.


### Done — documentation only

- [x] **FIX-APPROVAL-SETTLEMENT-OWNER** — Goal: M1. The ledger records the
  test-harness repair on `t_9cc17611` done, not a new responder implementation.
  Source: [executor receipt](.task-evidence/t_9cc17611/receipt.md) and
  [regression](test/core/hermes/channel/hermes_approval_settlement_owner_test.dart).
  Scope: explicit session admission, valid history identity and bounded test waits;
  production authority, response lifetime fencing and replay policy are unchanged.
  Acceptance evidence: retained logs record 12 owner and 405 neighboring passes,
  with clean analysis. The inspected test blob matches the receipt.
  Dependencies: none; ownership: delivered by the existing card.
  This pass reruns no Flutter tests and asserts no independent review, live,
  browser, native or complete M1 acceptance.

- [x] **PARITY-DOC-RECONNECT-READ-INTENT** — Indexed completed repair `t_af394f96`,
  independently approved in run 278. Source:
  [direct Reconnect runbook](docs/runbooks/chat-reconnect-read-intent.md) and
  [independent review](.task-evidence/t_af394f96/independent-review.md).
  The identical baseline widget oracle failed 11 cases; the repaired suite passed
  59 tests and analysis was clean. This pass verified 13 recorded source hashes
  before updating the review status; no product tests were rerun.
  Local snapshot: `agent/wing/t_af394f96`, commit
  `de67380a120c484b14073080b1acf012769ebb6c`. No push or merge occurred.
  Native/browser/live/physical/packaged/full-suite/parity remain NOT_CHECKED.

- [x] **PARITY-DOC-ENDPOINT-LOAD-INTENT** — Indexed completed repair `t_323250d0`,
  independently approved in run 272. Source:
  [saved-endpoint intent runbook](docs/runbooks/chat-endpoint-load-intent.md).
  The reviewer independently passed 124 focused tests and clean analysis,
  formatting and whitespace checks. This pass verified all five delivered
  fingerprints before updating the runbook; no product tests were rerun.
  A conflicting generated no-commit instruction prevented its local snapshot.
  The baseline-relative patch and source-bound receipts remain available.
  Native/browser/live/physical/packaged/full-suite/parity remain NOT_CHECKED.

- [x] **PARITY-DOC-COMPLETION-FOCUS** — Corrected the stale pending-review statement
  in the [completion-focus runbook](docs/runbooks/chat-completion-focus-ownership.md).
  Card `t_64756dfb` is completed and independently approved in run 245.
  The [review receipt](.task-evidence/t_64756dfb/independent-review.md) records
  212 focused widget passes and clean analysis, formatting and whitespace checks.
  This pass inspected the live card and receipt; no product tests were rerun.
  Native/browser/live/Android/packaged/full-parity evidence remains NOT_CHECKED.

- [x] **PARITY-DOC-SESSION-SETTLEMENT** — Indexed completed caller repair
  `t_cd455c23`, independently approved in run 236. Source:
  [settlement runbook](docs/runbooks/chat-session-settlement.md).
  Old-owner create/open completion cannot show replacement feedback, refresh its
  contact or focus its composer. The reviewer passed 351 widget tests and clean
  analysis; this pass verified six source hashes and the local task branch SHA.
  No product tests were rerun. Native/browser/live/packaged/full-parity targets
  remain NOT_CHECKED; approval card `t_6233c1c5` remains parked.

- [x] **PARITY-DOC-ERROR-DETAILS-COPY** — Indexed completed repair `t_526a2fef`,
  approved by same-card review in run 158. Source:
  [error-details copy runbook](docs/runbooks/chat-error-details-copy-outcomes.md).
  Success now awaits completion; rejection has sheet-local accessible retry
  feedback; dismissal/disposal suppresses late feedback. The reviewer passed
  32 regression cases and 111 neighbors, formatting, analysis, whitespace and
  links. This pass inspected retained logs and matched all three source hashes;
  it reran no product tests. Physical clipboard, browser, screen-reader runtime,
  live Agent, full suite, packaging, integrated parity and release remain
  NOT_CHECKED. Original cards and their scope exclusions are unchanged.

- [x] **PARITY-DOC-DIAGNOSTICS-COPY** — Indexed completed repair `t_a568069e`,
  approved by same-card review in run 146. Source:
  [Diagnostics copy runbook](docs/runbooks/chat-diagnostics-copy-outcomes.md).
  Both actions now await clipboard completion, show a fixed localized modal
  failure with explicit retry, and suppress late feedback after dismissal or
  disposal. Payloads and Agent state are unchanged. The reviewer independently
  passed 143 focused widget cases, analysis, changed-file formatting, scoped
  whitespace and link checks. This documentation pass inspected retained logs
  and verified six source fingerprints; it reran no product tests. Physical
  clipboard, screen-reader runtime, browser, live Agent, packaged builds,
  full-suite/integrated parity and release remain NOT_CHECKED.

- [x] **PARITY-DOC-APPROVAL-SETTLEMENT** — Indexed completed repair `t_6209124f`,
  approved by same-card review in run 130. Source:
  [approval-settlement runbook](docs/runbooks/chat-approval-settlement.md).
  Recorded production-channel RED preceded the responder-lifetime fence. The
  reviewer independently passed 398 focused tests, analysis and scoped formatting.
  This documentation pass verified four final fingerprints and inspected logs;
  it reran no tests. Native UI, browser, live Agent, packaged builds, full suite,
  integrated parity and release remain NOT_CHECKED. Existing gates are unchanged.

- [x] **PROFILE-MUTATION-REVIEW** — Indexed completed repair `t_eb72edbe`,
  approved by same-card native review in run 119. Source:
  [mutation-owner receipt](docs/runbooks/profile-mutation-intent.md).
  The reviewer independently passed 174 focused tests, analysis and changed-file
  formatting, and verified six final fingerprints and eight affected local links.
  This documentation pass inspected the source-bound archive and approval; it
  reran no tests. Native/browser/live/integrated/full-suite/release qualification
  remains NOT_CHECKED. No new task or retry is authorized by this index.

- [x] **PARITY-DOC-EXPORT-FEEDBACK** — Indexed completed export-feedback repair
  `t_aaa10f17` and same-card approval run 106. Source:
  [exact-owner feedback receipt](docs/runbooks/chat-transcript-export.md#exact-owner-failure-feedback-repair-t_aaa10f17).
  Scope: status and evidence documentation only. Acceptance: reviewer log records
  127 focused cases passed, zero failures/skips; three final source hashes matched
  before this documentation update. No tests were rerun by the documentation pass.
  Native application, compiled browser, live workflow and full-suite qualification
  remain unverified for this repair. Existing blocked scopes remain unchanged.

- [x] **PARITY-DOC-KEYBOARD-FORWARD** — Indexed completed forward repair
  `t_c5a4d301` and native approval run 98 without changing blocked predecessors.
  Source: [forward receipt](docs/runbooks/provider-search.md#forward-shared-shell-repair-receipt-t_c5a4d301)
  and [quality follow-through](docs/quality/flutter-keyboard-follow-through.md).
  Scope: status, evidence and handoff documentation only. Acceptance: inspected
  source-bound hashes, review verdict and logs; affected links/whitespace checked.
  No fresh test, full-suite, native app, live workflow or release claim is added.

- [x] **DOC-WING-LINK-HTTP-CONTRACT** — Added and indexed the
  [code-first OpenAPI snapshot](docs/api/wing-link.openapi.yaml).
  Scope: existing Go management and ephemeral pairing-broker HTTP routes only;
  exclude API redesign, generated clients, Agent schemas and runtime qualification.
  Acceptance: YAML parsing, JSON Schema structure, local references, route/path
  parameters and cited source paths checked. Full OpenAPI validation and live
  API conformance were not executed. Go handlers remain authoritative.

- [x] **DOC-CORE-DESIGN-TEST** — Added the cross-component
  [technical design](docs/spec.md) and [test plan](docs/test-plan.md).
  Scope: current source/ADR mapping and risk-based verification instructions;
  exclude production changes, new decisions, runtime tests and qualification.
  Acceptance: source paths, affected local links/anchors and scoped whitespace
  checks pass. Existing product requirements, operating runbooks and release
  history remain their canonical owners. This is documentation completion only.

- [x] **PARITY-DOC-PIN-WRITE-ORDER** — Indexed completed card `t_c0073c10`,
  independently approved in run 69, and its
  [pin write-order runbook](docs/runbooks/chat-session-pin-write-order.md).
  The [parity ledger](docs/product/hermes-desktop-parity.md#supporting-chat-repairs)
  now includes this repair with its same-store and persistence-failure limits.
  Source-bound receipts record a lost-persistence regression, then 50 focused
  tests passed and analyzer exit 0. Same-store commits are serialized and waiting
  choices are coalesced without delaying local notifications. This index does
  not establish cross-instance ordering, physical durability, native/browser,
  live or integrated workflow acceptance.

- [x] **PARITY-DOC-TRANSCRIPT-COPY** — Indexed completed card `t_e423d707` and its
  [clipboard-outcome runbook](docs/runbooks/chat-transcript-copy-outcomes.md).
  Inspected source-bound execution logs record 68 new and 105 neighboring tests
  passed, with analyzer exit 0. Success follows completion; rejection permits
  explicit retry and suppresses stale feedback. Started writes cannot be undone.
  This pass ran no Flutter tests and establishes no physical clipboard, browser,
  native, live or integrated acceptance.

- [x] **PARITY-DOC-PIN-LIFETIME** — Indexed completed card `t_438fb753`, run 60,
  and its [pin lifetime runbook](docs/runbooks/chat-session-pin-lifetime.md).
  Source-bound receipts record an executed disposed-store regression failure,
  then 43 focused tests passed and analyzer exit 0. The fix prevents obsolete
  pending actions from initiating writes; already-started writes can settle.
  This index does not establish physical preferences, browser, native, live,
  full-suite or integrated workflow acceptance.

- [x] **PARITY-DOC-CONTRIBUTING** — Corrected contributor priorities to the accepted
  Desktop-first workflow, with mobile usability and accessibility preserved.
  Source: [product decision](docs/adr/product.md) and
  [current goal](docs/plans/2026-10-03-desktop-port-goal.md).
  Scope: contributor guidance only; no qualification or implementation mandate.
- [x] **PARITY-DOC-QUEUE-INTENT** — Indexed completed card `t_a199ad12`, run 52,
  and its [queue-dialog intent runbook](docs/runbooks/chat-queued-follow-up-intent.md).
  Verified execution receipts record 62 new and 169 neighboring widget tests
  passed, analyzer exit 0 and unchanged receipt-bound source fingerprints.
  This index does not establish browser, native, live or integrated acceptance.

- [x] **PARITY-DOC-MUTATION-INTENT** — Linked the existing session mutation repair
  from the parity ledger and docs index. This closes a documentation gap only.
  Source: [mutation-intent runbook](docs/runbooks/chat-session-mutation-intent.md)
  and [production session actions](lib/features/hermes_chat/session/hermes_chat_session_actions.dart).
  The runbook records widget regressions. Browser, native and integrated workflow
  acceptance remain unverified. No implementation work is authorized by this entry.

- [x] **PARITY-DOC-DIRECTION** — Reconciled PRD and study-index wording with the
  accepted Desktop-first direction, without promoting planned behavior to shipped
  support. Evidence: [PRD](docs/product/prd.md), [product decision](docs/adr/product.md)
  and [docs index](docs/README.md).
- [x] **PARITY-DOC-CHECKPOINT** — Reconciled current goal/roadmap/plan/parity
  summaries with the recorded provisioning pause and restored-picker failure;
  historical receipts remain intact. Evidence: [goal checkpoint](docs/plans/2026-10-03-desktop-port-goal.md),
  [parity ledger](docs/product/hermes-desktop-parity.md) and linked receipts.
- [x] **PARITY-DOC-NAVIGATION** — Corrected flat-navigation descriptions to reflect
  implemented Workflow/Utilities grouping while retaining footer/recents/sidebar
  gaps. Evidence: [UI gap audit](docs/product/hermes-desktop-ui-gap.md),
  [navigation runbook](docs/runbooks/desktop-navigation-groups.md) and
  [production presentation](lib/shared/widgets/app_shell_presentation.dart).

These completed items are documentation corrections, not runtime, card, release
or full Desktop parity acceptance. Root discovery and local-link/diff checks
validate the handoff's documentation, not the blocked behavioral gates.

## Private release documentation maintenance receipt

Mode: Bootstrap + Maintain. Trigger: HEAD advanced from `1afe1307` to
`bdb3284a0a669140bcd6f49b4ffe03078cbdd592`, adding opt-in private Android
release packaging. The monitor reported no broken-path drift. The latest
connection, grouped-recents and adaptive-panel branch outcomes already have
current documentation owners; no worker or card action occurs in this pass.

The spec, test plan, changelog and docs index now explain the isolated
`.qa.release` identity and required signing. The existing release handoff owns
the build procedure. The Gradle guard and nearest source-contract test were
inspected. The retained private-release receipt reports a successful ARM64
build and artifact checks. Its Gradle and Android manifest fingerprints match
this checkout. This is receipt inspection, not a new build, Android launch,
whole-tree attribution or store qualification.

| Core role | Canonical owner | Outcome |
| --- | --- | --- |
| README | `README.md` | unchanged_verified for alpha orientation, setup and navigation. |
| PRD | `docs/product/prd.md` | unchanged_verified for accepted Desktop-first intent and qualification limits; packaging does not change requirements. |
| ADRs | `docs/adr/README.md` and five living decisions | unchanged_verified for current authority and delivery boundaries; no new decision. |
| Spec | `docs/spec.md` | maintained for private package identity and signing guard. |
| Owned HTTP API | `docs/api/wing-link.openapi.yaml` | unchanged_verified for manual code-first ownership; packaging adds no HTTP operation. |
| Test plan | `docs/test-plan.md` | maintained for source-contract versus artifact versus named-device checks. |
| Operations | `docs/getting-started.md`, setup/release runbooks and `docs/runbooks/android/release-handoff.md` | unchanged_verified for relevant setup and existing private-release procedure. |
| Changelog | `CHANGELOG.md` | maintained with the implemented Unreleased packaging option; no publication inferred. |

All applicable core owners exist; none needs creation. Existing BLOCKERS
entries, owner answers and defaults are preserved. No new owner question is
needed for these documentation corrections.

### Goal backlog and archive conservation

`TODO.md` updates existing `DOC-M6-INTEGRATED-RECEIPT-GAP` with the private
artifact boundary. No duplicate task is added, closed, reopened or claimed.
`goals.json` adds inspection evidence for M6 through the supported helper;
M6 remains unverified. Existing met outcomes retain their attributed passing
receipts, not qualification of the entire dirty tree.

Coverage: 35 goals — 2 met, 17 partial, 9 unmet and 7 unverified.
All 146 ledger tasks have one matching full body in the live backlog or archive.
Every non-met goal has at least two remaining slices. The helper's first open
candidate is `PARITY-MAESTRO-ANDROID-DEVICE`; current tracker ownership and
actual target availability must be checked before execution. The bounded
`VERIFY-NATIVE-RESUMED-SEND` is also dependency-ready in Next.
No autonomous worker was started.

This new root archive preserves 99 checked task bodies verbatim, including
78 done ledger tasks and 21 earlier historical documentation records. Exact
block multiplicity was checked before removal from TODO. All 68 open task
bodies and continuations remain, except the explicit M6 evidence addition and
final trailing-blank-line cleanup. The archive contains no unchecked task.
TODO links this archive near the top. Completed ledger history is unchanged.

### Verification and limits

Executed canonical commands:

```bash
python ~/.hermes/shared-skills/repo-docs/scripts/goals.py fmt .
python ~/.hermes/shared-skills/repo-docs/scripts/goals.py validate .
python ~/.hermes/shared-skills/repo-docs/scripts/goals.py render .
python ~/.hermes/shared-skills/repo-docs/scripts/goals.py next .
git diff --check
```

The canonical sequence prints `ok`; diff whitespace checks pass. The inline
offline oracle resolves 800 local links, anchors and goal sources across core,
affected and archive documents. It excludes 55 optional local receipt links.
Its first pass incorrectly stripped underscores from heading identifiers;
correcting the oracle resolves four false failures without editing history.
A repeated canonical cycle preserves TODO, goals and archive bytes.
Exact block conservation and ledger/body/checkbox checks pass separately.

Mechanical review checks changed sentences, table structure and protected
identifiers. Language/meaning review preserves signing versus runtime proof,
paired versus isolated identity, fallback versus private guard, and implemented
versus published status. The STE-inspired profile applies only to new prose.
Full ASD-STE100 dictionary compliance was not verified.

API YAML parsing was not run because the Python YAML module is absent; no
installation is authorized. Full OpenAPI conformance, product tests, builds,
Android/native interaction, live requests, installs, releases and network
checks were not run. Signed artifacts still need target-specific install,
upgrade and recovery evidence. Other agents' dirty source/tests, BLOCKERS
entries, cards and schedules remain outside this pass.

Concurrent repository activity advanced HEAD to `b9eb5b3d` and staged existing
fleet changes during this pass. This worker did not stage, commit or merge.
The corrected docs remain present; the live/archive conservation check was
rerun after that activity. The archive is a new unstaged documentation file.

## Merge follow-through: private signing and native prerequisites

Mode: Bootstrap + Maintain. The monitor reports HEAD advancing from
`bdb3284a0a669140bcd6f49b4ffe03078cbdd592` to
`b9eb5b3d9f6f3a433dd36cb6271ad8ec769b2319`, with zero path drift.
`git diff bdb3284a0a669140bcd6f49b4ffe03078cbdd592..b9eb5b3d9f6f3a433dd36cb6271ad8ec769b2319 --exit-code`
exits 0: the merge adds no tree change over the preceding packaging commit.
Existing dirty fleet changes and current task ownership remain intact.

The root README incorrectly said no signed app package existed. README and
PRD now distinguish the privately signed isolated Android test APK from public
signed distribution. The retained private-release receipt records build exit 0,
verified signature/ZIP/AOT, non-debuggable output and no device execution.
Its Gradle and Android manifest fingerprints match. This pass inspected that
receipt; it did not build, distribute or launch an APK.

TODO's PARITY-NATIVE-LINUX entry now reflects the resolved user-space build
prerequisite in BLK-20261005-003. It links the existing reproduction procedure,
requires renewed compatibility checks and preserves the no-system-install rule.
This is not all-feature Linux qualification or permission to change the host.

| Core role | Canonical owner | Outcome |
| --- | --- | --- |
| Orientation | `README.md` | maintained: private signing versus public availability. |
| Requirements | `docs/product/prd.md` | maintained: implemented packaging versus unqualified device/release outcomes. Accepted scope is unchanged. |
| Decisions | `docs/adr/README.md` and five living ADRs | unchanged_verified for current ownership and relevant authority/delivery boundaries. No new decision. |
| Design | `docs/spec.md` | unchanged_verified: existing private package/signing design matches Gradle. |
| Owned HTTP API | `docs/api/wing-link.openapi.yaml` | unchanged_verified for manual code-first ownership; packaging changes no HTTP contract. Full schema/runtime conformance was not rerun. |
| Verification | `docs/test-plan.md` | unchanged_verified: source, artifact and named-device checks remain distinct. |
| Operations | `docs/getting-started.md`, `docs/runbooks/release-alpha.md`, `docs/runbooks/android/release-handoff.md` and focused runbooks | unchanged_verified for inspected setup, signing and user-space reproduction boundaries. |
| History | `CHANGELOG.md` | unchanged_verified: implemented packaging is already Unreleased; a merge is not publication. |

All applicable core owners exist; none needs creation. BLOCKERS and its recorded
answers/defaults are unchanged. No new owner question is needed.

Goal coverage remains 35 goals: 2 met, 17 partial, 9 unmet and 7 unverified.
All 33 non-met goals retain at least two remaining slices. The two met goals
retain attributed executed passing evidence; no goal is promoted by this pass.
The existing goals.json is current and unchanged after canonical normalization.
No task is added, closed or claimed. Only PARITY-NATIVE-LINUX's prerequisite
context changes. The next helper candidate is PARITY-MAESTRO-ANDROID-DEVICE;
check actual device availability and tracker ownership before execution.
No autonomous worker is started.

Executed checks: `python3 ~/.hermes/shared-skills/repo-docs/scripts/goals.py fmt .`
→ `validate .` → `render .` each prints `ok`. `goals.py next .` identifies the
existing candidate. `git diff --check` passes. The inline offline check resolves
808 local links, anchors and goal sources across 19 core/coordination/history
files; 55 optional local receipt links are excluded. All 146 ledger tasks have
one matching body and checkbox in TODO or the archive. There are no checked
live entries or unchecked archive entries. No historical block is moved.
A second canonical cycle leaves TODO, goals, archive and BLOCKERS byte-identical.
Exact prior archive bytes and completed-block multiplicity are preserved.
All live task continuations survive normalization unchanged after the scoped repair.
Root links expose TODO and the archive; the new receipt heading occurs once.

Mechanical review checks the changed prose, table structure and protected
identifiers. Language/meaning review preserves private/public signing, artifact
versus runtime proof, and resolved prerequisites versus feature qualification.
The STE-inspired profile applies only to changed prose. Full ASD-STE100
dictionary compliance was not verified. Product tests, builds, device/native
interaction, API conformance, installs, releases and network checks were not run.
The remaining named-device install/upgrade/recovery gap stays with the existing
M6 tasks; the overall daily-use workflow and full Desktop parity remain partial.

## Completed native continuation and panel tasks

The ledger marks both tasks done. The retained native receipts are indexed in
[resumed send](docs/quality/native-resumed-send.md) and
[global session panel](docs/quality/global-session-modal-native.md).
The original unchecked task bodies below are preserved verbatim as history;
they are not queued work or current ownership claims.

- [ ] **VERIFY-NATIVE-RESUMED-SEND** — Goal: M1. Re-select a model explicitly
  after native restart and send once to the restored exact session.
  Payoff: prove the supported continuation path without pretending pair persistence.
  Sources: [combined receipt limits](docs/quality/native-model-relaunch-workflow.md#contract-limit)
  and [workflow matrix](docs/plans/2026-10-03-desktop-daily-workflow.md#acceptance-matrix).
  Scope: extend the existing native fixture/launcher and nearest model/channel tests;
  repair reproduced Wing defects only. Exclude Agent changes, shadow pair state,
  system installs, live inference, personal data and credential enrollment.
  Acceptance: restart alone adds zero mutations; Cancel leaves unknown identity;
  deliberate pair selection produces one acknowledged write, then one deliberate
  send to the same profile/session. Canonical history includes the resumed reply.
  Route reopening adds no sends, creates, model writes, approvals or Stop requests.
  Run bounded native and nearest regression checks with input/count/cleanup receipts.
  Dependencies: VERIFY-NATIVE-MODEL-RELAUNCH (done); queued in Next.
  Ownership: unclaimed in this index; check current tracker leases before execution.

- [ ] **VERIFY-GLOBAL-SESSION-MODAL-NATIVE** — Goal: PARITY-COMPOSITION.
  Keep feature-route session access usable in an isolated Linux Flutter app.
  Payoff: prove the delivered adaptive panel beyond deterministic Chromium.
  Sources: [adaptive limits](docs/quality/global-session-modal-adaptive.md#integration-and-qualification-limits)
  and [client decision](docs/adr/client.md#decision).
  Scope: existing shell/panel, native integration harness and smallest exposed
  Wing presentation repairs. Exclude new APIs, live inference, credentials,
  privileged installation, physical devices and screen-reader support claims.
  Acceptance: real keyboard search, exact Open/New, Escape/Close and compact/wide
  resize keep controls reachable at enlarged text and reduced motion. Pending
  owner replacement rejects stale activation/navigation; opening and resize add
  no reads or mutations. Run bounded Linux integration and nearest regression
  checks; retain input/platform/focus/request and cleanup receipts.
  Dependencies: VERIFY-GROUPED-RECENTS-NATIVE (done); Section: Now.
  Ownership: unclaimed in this index; check tracker leases before execution.

## 2026-10-07 live-workflow preparation documentation receipt

Mode: Bootstrap + Maintain. Scope: Wing documentation, TODO and goal ledger only.
The monitor changed agent branches at unchanged HEAD
`b9eb5b3d9f6f3a433dd36cb6271ad8ec769b2319`, with zero listed path drift.
Inspection started at `agent/wing/t_a8a79cf5` / `6b45b38d` and
`agent/wing/t_d6467f03` / `7cf7f8b4`. The live-workflow branch advanced during
this pass to `8bdae36cd40bccbf5b7fd6056d395606f01f58db`; its concurrent ledger
receipts and dirty source/documents are preserved, not attributed to this pass.

### Correction and evidence boundary

[Spec](docs/spec.md), [test plan](docs/test-plan.md) and
[documentation navigation](docs/README.md) now expose the separate
[live-workflow preparation](docs/quality/live-desktop-daily-workflow.md).
The entry has read-only authorization/preflight and a prepared production Chat
driver. The driver refuses before network access until provider-call limits across
continuations are qualified. Mutation counters do not prove an inference ceiling.
Authentication alone does not enable the journey. Actual-Agent/native workflow,
independent acceptance and protected-main delivery remain unverified.

Retained first-slice logs record ten Python regressions, 98 client tests and six
mutation-budget tests passing. Its source manifest matches 551 of 588 current
inputs and three of five overlays. The Python helper/test were superseded by the
cleanup correction. That correction records 14 passing Python regressions for
cancellation during preparation, repeated signals, descendant teardown and fake-
tool success. All five rework overlay hashes match; 553 of 588 full input hashes
match. These are inspected historical receipts, not product tests rerun here or
qualification of the entire dirty tree. No native or live inference occurred.

### Core-role coverage

| Role | Canonical path | Outcome |
| --- | --- | --- |
| README | `README.md` | unchanged_verified for purpose, setup and navigation; `docs/README.md` maintained for the new evidence link. |
| PRD | `docs/product/prd.md` | unchanged_verified for accepted Desktop-first intent and the still-unqualified live milestone. |
| ADR | `docs/adr/README.md` and five living decisions | unchanged_verified for authority, native-operation boundaries and history; no new decision. |
| Spec | `docs/spec.md` | maintained for read-only preparation, disabled driver and owned cancellation cleanup. |
| Owned HTTP API | `docs/api/wing-link.openapi.yaml` | unchanged_verified for manual code-first ownership; YAML syntax passes, standards/runtime conformance not run. |
| Test plan | `docs/test-plan.md` | maintained for guard/cancellation scenarios, retained checks and source-binding limits. |
| Runbook | `docs/getting-started.md`, `docs/runbooks/android-hermes-setup.md`, `docs/runbooks/release-alpha.md` | unchanged_verified for inspected prerequisites, command references and recovery/publication limits; no operation executed. |
| Changelog | `CHANGELOG.md` | unchanged_verified for Unreleased versus baseline history; no routine documentation-churn entry or new release claim. |

All applicable core owners exist. No missing core owner needs creation. Existing
owner questions remain in `BLOCKERS.md`; this pass adds no new question or decision.

### Goal handoff and verification

`TODO.md` updates PARITY-LIVE-WORKFLOW with the delivered preparation and the next
budget/orchestration implementation slice. No duplicate task is added or closed.
`goals.json` receives one M1 inspection entry through `goals.py evidence`; focus
remains M1. Coverage: 35 goals, 149 tasks; two met, 17 partial, nine unmet and seven
unverified. All 33 non-met goals have unfinished tasks; both met goals retain
executed passing evidence. The smallest helper-eligible task remains
PARITY-LIVE-WORKFLOW, in_progress in the ledger. Existing tracker ownership is not
changed or a new worker dispatched. Its read-only recovery successor remains
queued behind completion of the live workflow.

Executed checks: `python3 <home>/.hermes/shared-skills/repo-docs/scripts/goals.py fmt .`
then `validate .` then `render .` print `ok`; `goals.py next .` selects the live
workflow. A repeated cycle leaves TODO, goals and archive byte-identical.
`git diff --check` and branch whitespace checks pass. Offline checks resolve 567
local links/anchors across 19 core/affected documents; 26 optional local evidence
references are excluded. Open task bodies cover every unfinished ledger task.
All 67 unrelated open bodies and continuations are unchanged. Existing archive
prefix bytes are preserved; no historical task is moved in this pass. BLOCKERS
bytes are unchanged. `/usr/bin/python3` with installed PyYAML parses OpenAPI 3.1.0
and 20 paths. This is syntax, not standards validation or runtime conformance.

Mechanical review checks changed Markdown, punctuation and protected identifiers.
Language/meaning review applies the STE-inspired profile to this pass's prose.
It preserves prepared/executed, synthetic/live and qualified/delivered distinctions.
Full ASD-STE100 dictionary compliance is not verified. Repository checks are offline
on Linux. Product tests/builds, API runtime checks, devices, network requests,
credential acquisition, installs and release operations are not run by this pass.

## 2026-10-07 owned-display documentation receipt

Mode: Bootstrap + Maintain; documentation, TODO and helper-managed goals only.
The branch digest changed at unchanged HEAD
`b9eb5b3d9f6f3a433dd36cb6271ad8ec769b2319`; listed path drift was zero.
Inspection follows `agent/wing/t_a8c770c8` at
`19e59ea10f3424c3973b317cdabdaf3a77269292`, after orchestration predecessor
`1749a739873d01acc965f61d2f2318a6d466a8d4`. Existing dirty and staged work is
preserved. No worker, tracker, schedule, commit or external operation is started.

### Correction and source boundary

The [display receipt](docs/quality/live-display-isolation.md) is copied verbatim
from the branch for durable navigation. Spec, test plan, preparation summary and
TODO distinguish completed synthetic orchestration and real X protocol admission
from the still-unqualified production GTK/live journey. The shared helper/test
match the orchestration predecessor, not the display branch. Documentation imports
no implementation. Carry the exact branch source through integration before any
credential-bearing execution; do not label the shared tree display-qualified.

Read-only checks match all six verification input hashes to that branch. The
retained `build/t_a8c770c8/verification.json` records 29 passing tests, clean shell
syntax, expected no-input refusal with zero operations and passing whitespace.
Real Xvfb admission accepts correct authorization and rejects empty/wrong auth;
TCP access is rejected. Synthetic driver/app phases share owner-only auth/state,
and teardown precedes deletion. These are inspected executor results, not tests
rerun here, GTK/live qualification or hostile same-UID isolation. The machine
receipt and narrative record different successful run durations; neither is
relabelled as this pass's execution. Inference remains disabled pending qualified
provider-call limits and separate QA authentication. M1 remains partial.

### Core-role coverage

| Role | Canonical owner | Outcome |
| --- | --- | --- |
| README | `README.md` | unchanged_verified for orientation/setup; `docs/README.md` maintained for evidence navigation. |
| PRD | `docs/product/prd.md` | unchanged_verified for accepted Desktop-first intent and unqualified live acceptance. |
| ADR | `docs/adr/README.md` and five living records | unchanged_verified for authority and existing boundaries; no new decision. |
| Spec | `docs/spec.md` | maintained for synthetic runner and branch-only display evidence. |
| Owned HTTP API | `docs/api/wing-link.openapi.yaml` | unchanged_verified for manual code-first ownership; syntax checked, runtime conformance not executed. |
| Test plan | `docs/test-plan.md` | maintained for admission/denial, teardown and exact-source limits. |
| Runbook | `docs/getting-started.md`, `docs/runbooks/android-hermes-setup.md`, `docs/runbooks/release-alpha.md` | unchanged_verified for inspected prerequisites and recovery/publication limits; no operation executed. |
| Changelog | `CHANGELOG.md` | unchanged_verified; this evidence correction introduces no product release or notable shipped feature. |

All applicable core owners exist; none needs creation. Existing owner questions
and defaults remain in `BLOCKERS.md`; this pass adds no new question or resolution.

### Completed bounded slices now indexed in history

These records add missing prose for tasks already done in the ledger. They do
not change status, reopen delivery, assert review approval or queue work.

- [x] **PARITY-LIVE-WORKFLOW-PREFLIGHT** — Goal: M1. Delivered read-only
  authorization/preflight and a disabled prepared production Chat driver.
  Source: [preparation receipt](docs/quality/live-desktop-daily-workflow.md).
  Scope: launcher, production-client readiness and deterministic guards only.
  Acceptance evidence: retained launcher/client/mutation-guard checks; no actual
  Agent generation or native readiness execution. Ownership: delivered on
  `t_a8a79cf5`; already done in `goals.json`. Dependencies: none recorded.

- [x] **PARITY-LIVE-TWO-PROCESS** — Goal: M1. Delivered internal isolated
  write/verify orchestration with fail-closed inference and teardown handling.
  Source: [runner receipt](docs/quality/live-two-process-orchestration.md).
  Scope: fixed Python preparation/process runner and synthetic lifecycle tests.
  Acceptance evidence: 23 retained passing regressions, distinct driver/app groups,
  shared state and refusal preserving state on unconfirmed cleanup. No GTK/live
  or protected-main qualification. Ownership: delivered on `t_2e1f363d`;
  already done in `goals.json`. Dependencies: none recorded.

- [x] **PARITY-LIVE-DISPLAY-ISOLATION** — Goal: M1. Delivered authenticated
  owned X display admission, denial and cancellation cleanup on its isolated branch.
  Source: [display receipt](docs/quality/live-display-isolation.md).
  Scope: ephemeral Xauthority, fixed Xvfb/xdpyinfo admission and focused tests.
  Acceptance evidence: 29 retained passing tests with real X protocol checks;
  six branch input hashes match. Not GTK, live inference or shared-tree delivery.
  Dependencies: PARITY-LIVE-TWO-PROCESS. Ownership: delivered on `t_a8c770c8`;
  already done in `goals.json`.

### Goal handoff and documentation verification

`TODO.md` updates PARITY-LIVE-WORKFLOW's remaining scope without changing its
in_progress ownership or adding duplicate open work. `goals.json` receives one
M1 inspection entry through `goals.py evidence`; existing execution evidence and
focus M1 are preserved. Coverage: 35 goals, 151 tasks; 2 met, 17 partial, 9 unmet,
7 unverified. All 33 non-met goals have at least two unfinished slices. Both met
goals retain executed passing evidence. The helper selects PARITY-LIVE-WORKFLOW,
already in_progress; its successor VERIFY-LIVE-WORKFLOW-RECOVERY remains queued
behind completion. This pass assigns no lease and dispatches no worker.

Executed offline checks: `python ~/.hermes/shared-skills/repo-docs/scripts/goals.py fmt .`
→ `validate .` → `render .` all pass; validation prints `ok`.
`git diff --check` passes. Local links/anchors, task-body coverage, met evidence,
branch fingerprints and append-only archive preservation are checked.
The repeated canonical cycle preserves TODO/goals/archive bytes. All 67 unrelated
open task bodies and continuations remain unchanged; no historical body is moved.
The three completed records above fill existing ledger gaps. System Python with
installed PyYAML parses OpenAPI 3.1.0 with 20 paths; this is syntax only.

Mechanical review checks scoped Markdown, punctuation and protected identifiers.
Language/meaning review applies the STE-inspired profile and preserves branch/shared,
synthetic/live, inspected/executed and qualification/delivery distinctions.
Full ASD-STE100 dictionary compliance is not verified. Repository checks run offline
on Linux. Product tests/builds, standards-level API validation, native/device/live
journeys, network requests, credentials, installs and release actions are not run.

## 2026-10-07 provider-call documentation receipt

Mode: Bootstrap + Maintain; Wing documentation, TODO and goals only. The monitor
reports changed agent branches at unchanged HEAD
`b9eb5b3d9f6f3a433dd36cb6271ad8ec769b2319` and zero listed path drift.
The newest branch, `agent/wing/t_eb176d28` at
`894439b76c889fed45f3c4d57b73086f1e18d479`, completes the offline provider-call
assessment and executable refusal slice. Its document is copied verbatim to
[the retained report](docs/quality/live-provider-call-ceiling.md). No branch source
or test changes are copied into the shared tree. Existing dirty work and all
BLOCKERS entries remain unchanged.

The inspected unmodified Agent interfaces do not establish an enforceable three-
physical-attempt ceiling across retries, grace calls, tool/approval continuations,
auxiliary work and phase restarts. This is a bounded source assessment, not a claim
about every future Agent release. Retained machine receipts record 31 Python passes,
six unchanged Dart guard passes, shell syntax success and expected no-input refusal
with exit 2 and zero operations. All six executor fingerprints match exact branch
bytes. Shared helper/tests differ; these passes cannot qualify the shared tree.
This documentation run does not rerun product tests, launch GTK or call providers.
The live driver remains disabled, and authentication alone cannot enable it.

### Core-role coverage

| Role | Canonical owner | Outcome |
| --- | --- | --- |
| README | `README.md` | unchanged_verified for purpose/setup; `docs/README.md` maintained for evidence navigation. |
| PRD | `docs/product/prd.md` | unchanged_verified for accepted Desktop-first intent and unqualified live acceptance. |
| ADR | `docs/adr/README.md` and five living decisions | unchanged_verified for current authority and boundaries; no new decision. |
| Spec | `docs/spec.md` | maintained for completed budget assessment, branch refusal and remaining live qualification. |
| Owned HTTP API | `docs/api/wing-link.openapi.yaml` | unchanged_verified for manual code-first ownership; YAML syntax checked, full schema/runtime conformance not run. |
| Test plan | `docs/test-plan.md` | maintained for exact refusal scenarios and branch/shared source-binding limits. |
| Runbooks | `docs/getting-started.md`, `docs/runbooks/android-hermes-setup.md`, `docs/runbooks/release-alpha.md` | unchanged_verified for inspected setup and recovery limits; no operational action. |
| Changelog | `CHANGELOG.md` | unchanged_verified; offline budget qualification is not a new product feature or release. |

All applicable core owners already exist. No new owner question or decision is
needed. Existing authentication and device questions/defaults remain in BLOCKERS.
The preparation report now links the later assessment without rewriting its
historical uncertainty. No source, tests, instructions, installs, cards, schedules,
worker dispatch or external delivery change occurs.

### Completed bounded slice indexed in history

- [x] **PARITY-LIVE-PROVIDER-CEILING** — Goal: M1. Completed supported-contract
  tracing and executable refusal when a physical provider-call ceiling is unavailable.
  Source: [budget boundary report](docs/quality/live-provider-call-ceiling.md).
  Scope: two additive Python regressions on the isolated branch; predecessor
  helper/launcher/native driver remain unchanged. Acceptance evidence: retained
  31 Python passes and six Dart guard passes, exact refusal before external I/O,
  and six matching branch fingerprints. No backend quota, GTK/live qualification,
  main integration or independent approval is inferred. Dependencies: none in
  ledger. Ownership: delivered on `t_eb176d28`; already done in `goals.json`.

### Goal handoff

Root `TODO.md` updates PARITY-LIVE-WORKFLOW's current assessment without changing
its in_progress ownership. `goals.json` receives one M1 inspection entry through
`goals.py evidence`. New task PARITY-NATIVE-NO-INFERENCE-SMOKE is the independent
implementation/qualification seam: real two-process GTK shell restoration with
credential-free fixtures and every mutation transport unsupported. Its completed
predecessors are the display and refusal slices. It does not repeat budget tracing
or authorize live inference. VERIFY-LIVE-WORKFLOW-RECOVERY remains dependent on
the existing live workflow; no task is closed or claimed by this pass.

Coverage: 35 goals, 153 tasks; 2 met, 17 partial, 9 unmet and 7 unverified.
All 33 non-met goals retain at least two unfinished slices. Both met goals retain
executed passing journey evidence; no goal is promoted. Focus remains M1.
`goals.py next .` selects PARITY-LIVE-WORKFLOW, already in_progress. The smallest
independent new candidate is PARITY-NATIVE-NO-INFERENCE-SMOKE, subject to tracker
ownership. This records queued work, not a started autonomous worker.

### Verification and preservation

Executed offline checks: `python <home>/.hermes/shared-skills/repo-docs/scripts/goals.py fmt .`
→ `validate .` → `render .` pass; validation prints `ok`.
`git diff --check` and `git show --format= --check agent/wing/t_eb176d28` pass.
The local path/anchor check resolves 579 references across core/affected owners,
excluding 26 optional local-artifact links. System Python parses OpenAPI 3.1.0
with 20 paths; this is YAML syntax, not standards or handler conformance.
The expanded check resolves 650 local references, with 34 optional artifacts
excluded. An initial checker incorrectly required historical archived checkboxes
to be checked and failed on a preserved native-panel block. The corrected check
uses ledger status and archive location, preserving the original historical body.
All 153 bodies are present in the proper live/history owner; live checkboxes match.
Two-slice coverage, met evidence and branch fingerprints pass.
All 67 unrelated open task bodies/continuations are byte-identical. The one edited
live body retains its ownership and acceptance. No body is moved from TODO.
Existing archive prefix bytes are preserved; the missing completed record above
is added once. A second canonical cycle preserves TODO/goals/archive bytes.

Mechanical review checks scoped Markdown, punctuation and protected identifiers.
Language/meaning review applies the STE-inspired profile to the added receipt and
changed prose. It preserves assessment versus enforcement, branch versus shared,
fixture versus live and qualification versus main-delivery distinctions.
The branch report is preserved verbatim, not restyled. Full ASD-STE100 dictionary
compliance is not verified. Repository checks run offline on Linux. Product tests,
builds, native/device/live journeys, external links, credentials, installs, API
standards/runtime conformance and release procedures are not executed.



## Native no-inference smoke monitor follow-through

Mode: Bootstrap + Maintain. The changed branch `agent/wing/t_ac65a3cb` at
`05c027ee632b4597620396961e2172a300443650` records a GTK restart run.
The current [same-card report](docs/quality/native-no-inference-smoke.md#review-correction)
supersedes that run: the post-run archive omitted an analyzed input and captured
excluded local tool state. The corrected source captures inputs before execution
and rejects linked inputs. Fresh corrected qualification is not yet recorded.
This pass inspects evidence only; it does not rerun or approve the product checks.

### Historical task body

The ledger already marks PARITY-NATIVE-NO-INFERENCE-SMOKE done. The original
queued body below is preserved verbatim, including its historical checkbox and
ownership. It is not current queued work or proof that corrected acceptance passed.
The correction remains on the existing card; this pass does not reopen a gate,
claim a task or add a duplicate. M1 remains partial with its two unfinished tasks.

- [ ] **PARITY-NATIVE-NO-INFERENCE-SMOKE** — Goal: M1.
  Launch and relaunch the prepared production shell in credential-free Linux GTK QA.
  Payoff: qualify native process/UI restoration independently of missing live-call
  admission, without another budget investigation or personal authentication.
  Sources: [remaining native seam](docs/quality/live-provider-call-ceiling.md#remaining-m1-gaps-and-next-useful-independent-seam)
  and [owned display](docs/quality/live-display-isolation.md).
  Scope: prepared Linux launcher/driver, production shell/channel and deterministic
  fixture with every mutation transport unsupported; add a bounded no-inference
  scenario and nearest regressions. Integrate only the attributed display/refusal
  inputs into the QA candidate. Exclude live Agent/provider traffic, credentials,
  Agent edits, personal state, installs, new budget APIs, proxying and release.
  Acceptance: two real GTK processes use the same owned authenticated display and
  isolated state. Restore exact synthetic owner/session/history with keyboard-
  operable loading/error recovery. Record zero sends, creates, model writes,
  approval responses, Stop or provider requests. Live/direct invocation still
  refuses. Retain exact source/process/request receipts and confirmed teardown
  before state deletion; a fixture pass does not complete the live milestone.
  Dependencies: PARITY-LIVE-DISPLAY-ISOLATION and PARITY-LIVE-PROVIDER-CEILING (done).
  Section: Now. Ownership: unclaimed here; verify tracker leases before execution.
  Remaining: actual generation/approval/Stop, authoritative live restoration,
  supported provider-call enforcement and protected-main delivery.


### Concurrent corrected receipt and final maintenance result

The same-card report gained fresh corrected evidence during this pass. The
[corrected qualification](docs/quality/native-no-inference-smoke.md#executed-corrected-qualification)
replaces the uncertainty recorded at initial inspection above. Retained
`attempt-fq28lfnc` logs record two passing GTK phases, 12 snapshot tests,
23 focused Flutter tests, four public refusal tests and clean analysis. This
pass reruns none of those product checks and does not claim review approval.

The offline archive check verifies its SHA-256, the archived manifest and all
1,065 source inputs against the manifest and executed hashes. Membership contains
only regular files and excludes runtime-state names. Distinct GTK phase receipts
match owner/history fingerprints, record keyboard cancellation/error retry and
wrong-owner rejection, and record zero mutations. Teardown precedes state deletion.
Shared helper/tests differ from reviewed overlays; documentation also changed
since source capture. Qualification belongs to that frozen synthetic Linux
candidate, not the shared tree, packaged app, physical keyboard/IME or live Agent.
The superseded archive remains unusable as current evidence.

Core-role outcomes:

| Role | Canonical owner | Outcome |
| --- | --- | --- |
| README | `README.md` | unchanged_verified for orientation/setup; `docs/README.md` maintained for corrected evidence navigation. |
| PRD | `docs/product/prd.md` | unchanged_verified for accepted Desktop-first intent and remaining live acceptance. |
| ADR | `docs/adr/README.md` and five living decisions | unchanged_verified for ownership and boundaries; no architectural decision changed. |
| Spec | `docs/spec.md` | maintained for source-capture correction and frozen synthetic qualification limits. |
| Owned HTTP API | `docs/api/wing-link.openapi.yaml` | unchanged_verified for manual code-first ownership and YAML syntax; standards/runtime conformance not executed. |
| Test plan | `docs/test-plan.md` | maintained for corrected retained checks and exact-source/platform limits. |
| Operations | `docs/getting-started.md`, setup/release runbooks; `docs/runbooks/desktop-feature-qualification.md` | qualification runbook maintained with the credential-free command, prerequisites, expected signal and recovery limits; other inspected procedures unchanged_verified. |
| Changelog | `CHANGELOG.md` | unchanged_verified; QA qualification is not a newly shipped product capability or release. |

All applicable core owners exist; none needs creation. Existing owner questions
and defaults remain in `BLOCKERS.md`. No new owner question is necessary.
Changed files in this pass: the docs index, spec, test plan, qualification runbook,
root `TODO.md`, `goals.json` and `todo.archive.md`. Other agents' source/report
changes are not this pass's implementation. No installs, commits, pushes, cards,
schedules, external actions or autonomous workers are started.

Backlog: PARITY-NATIVE-NO-INFERENCE-SMOKE's original body is archived verbatim,
with its historical checkbox clearly labeled. Its ledger status was already done;
this pass changes no task status and adds no task. M1 receives failure inspection
for the superseded receipt and passing inspection for the corrected source-bound
receipt, not fabricated fresh runtime evidence. M1 stays partial. The concurrent
PORT-SHELL-PERSISTED-STATE task and its in_progress ownership are preserved.
Coverage at final inspection: 35 goals and 154 tasks; 2 met, 17 partial, 9 unmet
and 7 unverified. Every non-met goal has at least two unfinished slices. The two
met goals retain executed passing receipts with their existing snapshot limits.
Focus remains M1. `goals.py next .` selects PARITY-LIVE-WORKFLOW, already in_progress;
VERIFY-LIVE-WORKFLOW-RECOVERY remains its dependent successor. The first unclaimed
eligible fallback is PARITY-MAESTRO-ANDROID-DEVICE, subject to current tracker
ownership and named-target checks. Nothing is dispatched by this index update.

Verification: the canonical `python <home>/.hermes/shared-skills/repo-docs/scripts/goals.py fmt .`
→ `validate .` → `render .` passes; validation prints `ok`.
Scoped `git diff --check -- TODO.md goals.json docs/spec.md docs/test-plan.md docs/README.md docs/runbooks/desktop-feature-qualification.md`
passes. Offline checks resolve 593 local links/anchors across core and affected
owners, excluding 27 optional local artifact references. System Python parses
OpenAPI 3.1.0 with 20 paths. The tool-kernel YAML attempt lacked PyYAML; the
existing system interpreter succeeds without installing a dependency.
Archive-prefix bytes and exact moved-block multiplicity are preserved. All 68
unrelated open bodies/continuations remain byte-identical. A second canonical
cycle checks TODO/goals/archive byte stability. Product builds/tests, native
launches, physical devices, live requests, external links, API standards/runtime
conformance and release operations are not executed by this documentation pass.

Mechanical review checks changed Markdown, punctuation, task IDs and command
literals. Language/meaning review applies the STE-inspired profile to changed
prose and preserves synthetic/live, frozen/shared and qualified/delivered boundaries.
Full ASD-STE100 dictionary compliance is not verified. Repository verification
uses the offline checks above; language review is not runtime acceptance.


Final verification addendum: the task-body check caught the concurrently added
PORT-SHELL-PERSISTED-STATE ledger entry without a full TODO body. This pass adds
that body with its existing in_progress ownership, accepted scope and concrete
provider/widget checks. It creates no ledger task and changes no worker status.
The repaired body/status check passes for all 154 tasks. The final local-link check
resolves 596 references, with 27 optional artifacts excluded. Both ledger cycles
print `ok` and preserve TODO/goals/archive bytes. All 68 earlier unrelated open
bodies remain exact, as do the archive prefix and moved block multiplicity.

`git diff --no-index --check /dev/null todo.archive.md` returns 1 with no
whitespace diagnostics because the untracked file differs from the empty input.
The initial guard incorrectly treated that difference exit as a failure. A
separate check of appended archive lines finds no trailing whitespace. The scoped
tracked-doc `git diff --check` returns 0. No product test failure is inferred from
these documentation-check corrections. No secrets or source files are edited.


## Native denied-read restart documentation receipt

Mode: Bootstrap + Maintain; documentation and goal backlog only. The monitor
reports changed agent branches at unchanged HEAD `b9eb5b3d`, with zero listed
drift. This pass follows `agent/wing/t_3e074d68` at `358f645c` and preserves
other agents' staged, unstaged and untracked work. No worker, card or schedule
is started or changed.

The [native recovery report](docs/quality/native-no-inference-auth-recovery.md)
records four Linux GTK processes, including synthetic 401/403 restart denial.
Production saved-owner restoration and public Tab/Space Retry retain exact
identity; cancelled valid/foreign history and wrong-owner Retry cannot settle.
Retained logs confirm 83 focused Flutter passes, 14 snapshot regressions, four
admission guards, clean analysis and four passing native phases. Every phase
records zero mutation/provider/management counters. This pass inspects those
executor results; it does not rerun product tests or claim review approval.

Offline archive inspection verifies all 1,067 final input hashes, including
five reviewed overlays, against archived bytes and executed hashes. The archived
manifest and archive digest match the retained verification receipt. Three current
inputs differ: the two shared live helper/test predecessors and the post-check
recovery report. All four changed integration/helper/test inputs match the frozen
candidate. These results qualify that candidate, not the whole current tree.
The first archive comparison incorrectly used inherited hashes for overlaid
inputs and failed. Applying the manifest's reviewed overlay hashes passes;
no evidence archive or product input was changed to obtain that result.

Spec, test plan, evidence navigation and qualification runbook now expose the
completed synthetic denied-read checks. The runbook correctly describes four
phases and both required local predecessor Git objects. Workflow policy no
longer lists completed no-inference smoke as open work. Root TODO links completed
recovery to history instead of queuing duplicate qualification.

| Core role | Canonical owner | Outcome |
| --- | --- | --- |
| Orientation | `README.md` | unchanged_verified for inspected setup and limits; `docs/README.md` maintained for recovery navigation. |
| Requirements | `docs/product/prd.md` | unchanged_verified for Desktop-first intent and remaining live acceptance. |
| Decisions | `docs/adr/README.md` and living records | unchanged_verified for relevant ownership/recovery boundaries; no new decision. |
| Design | `docs/spec.md` | maintained for bounded synthetic restart denial and retry evidence. |
| Owned HTTP API | `docs/api/wing-link.openapi.yaml` | unchanged_verified for code-first ownership and YAML syntax; standards/runtime conformance not executed. |
| Verification | `docs/test-plan.md` | maintained for explicit denial, cancellation and wrong-owner expected outcomes with retained execution limits. |
| Operations | `docs/getting-started.md`, `docs/runbooks/android-hermes-setup.md`, `docs/runbooks/release-alpha.md` | unchanged_verified for inspected setup and operation limits; `docs/runbooks/desktop-feature-qualification.md` maintained for the four-phase launcher. |
| History | `CHANGELOG.md` | unchanged_verified; test-only qualification is not a new product feature or release. |

All applicable core owners exist; none needs creation. Existing `BLOCKERS.md`
questions/defaults remain unchanged. No new owner question is needed.

### Completed task body added from existing ledger and execution receipt

This entry was missing from both TODO and history. It is reconstructed from the
existing done ledger record and inspected final execution, not copied from a
lost original task or a newly closed card.

- [x] **PARITY-NATIVE-AUTH-RESTART** — Goal: M1.
  Prove credential-free native restart read-denial and explicit retry retain exact
  owner without replay. Payoff: keyboard recovery does not replace a saved session
  or apply cancelled/foreign history after restart.
  Sources: [final native receipt](docs/quality/native-no-inference-auth-recovery.md)
  and predecessor [smoke receipt](docs/quality/native-no-inference-smoke.md).
  Scope: existing no-inference GTK launcher, integration test, in-process fixture
  and tooling regressions; exclude production changes, live credentials/inference,
  upstream edits, packaged qualification and release actions.
  Acceptance: retained `timeout 30m bash scripts/run_linux_desktop_no_inference_smoke.sh`
  exited 0 in the frozen candidate; four phases preserve exact owner/history,
  expose explicit denial Retry and record zero mutations. Source archive and
  executed hashes match; teardown is recorded before state deletion.
  Dependencies: PARITY-NATIVE-NO-INFERENCE-SMOKE, already done.
  Ownership: delivered on t_3e074d68; existing ledger status done is preserved.
  Remaining milestone gap: actual generation, approvals/Stop, live-authoritative
  restoration, supported provider-call ceiling and protected-main delivery.

Root `goals.json` receives inspection evidence only; its prior executed records
and all task statuses remain intact. M1 stays partial and retains primary focus.
Coverage: 35 goals, 155 tasks; 2 met, 17 partial, 9 unmet, 7 unverified. All 33
non-met goals retain at least two unfinished slices; both met goals retain
executed passing evidence. No goal is promoted and no task is added or reopened.
The first helper-eligible task is PARITY-LIVE-WORKFLOW, already in_progress;
its ordered recovery successor remains queued. The first unclaimed fallback is
PARITY-MAESTRO-ANDROID-DEVICE, subject to actual tracker/target checks. Nothing
is dispatched here. The missing completed history body is the only task-body repair.

Executed documentation checks on Linux: `python3 <home>/.hermes/shared-skills/repo-docs/scripts/goals.py fmt .`
then `validate .` then `render .` exit 0; validation prints `ok`. `next . --json`
confirms the above order. Offline checks resolve 613 local links/anchors across
20 core/affected owners, excluding 28 optional local artifacts. Goal-source,
met-evidence and two-slice checks pass. System Python parses OpenAPI 3.1.0 with
20 paths. Scoped `git diff --check` and the monitored branch whitespace check pass.
Final verification passes: all 168,107 pre-existing archive bytes remain an
exact prefix, all 69 open task bodies/continuations remain unchanged, and the
missing completed body occurs exactly once. All 155 task bodies are discoverable.
The repeated fmt → validate → render cycle prints `ok` and leaves TODO, goals
and archive byte-identical. BLOCKERS remains byte-identical. New receipt and
navigation links/anchors pass; added prose has no trailing whitespace.

Mechanical review checks changed Markdown, punctuation and protected commands.
Language/meaning review applies the STE-inspired profile and preserves synthetic
versus live, frozen versus shared, and qualification versus delivery limits.
Full ASD-STE100 dictionary compliance is not verified. Product tests/builds,
native launches, physical input/devices, live requests, external links, installs,
API standards/runtime conformance and release procedures are not run here.

## Sidebar persistence completion reconciliation

The ledger marks PORT-SHELL-PERSISTED-STATE done. The
[implementation receipt](docs/quality/graphify-shell-persistence.md) records
widget qualification, not native process relaunch. The original task body below
is preserved verbatim, including its former unchecked state and ownership.

- [ ] **PORT-SHELL-PERSISTED-STATE** — Goal: SHELL-PERSISTENCE.
  Restore the Desktop sidebar choice through local Riverpod preferences.
  Payoff: keep the deliberate presentation choice when the shell is recreated.
  Sources: [shell parity requirement](docs/product/hermes-desktop-parity.md#reference-and-evidence-boundary),
  `lib/features/settings/providers/shell_preferences_provider.dart` and
  `test/shared/widgets/app_shell_sidebar_persistence_test.dart`.
  Scope: shell presentation preferences, AppShell composition and nearest provider/
  widget tests. Exclude Agent/profile state, credentials, startup redesign and
  personal desktop preferences.
  Acceptance: saved collapse/expand restores through public shell controls. A late
  preference read must not replace a newer deliberate choice. Failed storage must
  leave the shell usable. Run the provider and sidebar-persistence widget tests;
  separate process-relaunch qualification remains in the existing evidence task.
  Dependencies: none. Section: Now. Ownership: already in_progress in goals.json;
  preserve the concurrent worker's ownership and check its tracker before action.

## Native bootstrap recovery documentation receipt

Mode: Bootstrap + Maintain; documentation, TODO and goals only. The monitor
changed its agent-branch digest at unchanged HEAD
`b9eb5b3d9f6f3a433dd36cb6271ad8ec769b2319`, with zero listed path drift.
The newest inspected branch is `agent/wing/t_e662982c` at
`8504956fefb7f52ac8bae8e21543306266b0f0f5`.

Spec, test plan, navigation, workflow policy and the qualification runbook now
record the [bootstrap-denied successor](docs/quality/native-no-inference-bootstrap-recovery.md).
The runbook corrects four processes to six and names the current required
predecessor Git object. Required-capabilities 401/403 precedes usable inventory
and history. Saved ownership survives repeated denial and deliberate keyboard
Retry restores canonical history after synthetic authority returns. These are
frozen-source Linux GTK fixture results, not live authentication or inference.

This pass verifies the retained source/archive digests and all 1,068 executed
input hashes against archived members. Its first comparison used inherited
pre-overlay hashes and failed on an intentionally overlaid helper test. Comparing
against the executed hash map succeeds. Four scoped bootstrap harness inputs
match the current worktree. Retained logs and verification record six passing
native phases, 88 focused Flutter tests, 15 tooling tests and four admission
guards, with zero mutation/provider/management counts. Product tests are not
rerun here. Source overlays do not qualify the entire shared worktree.

Concurrent shell completion is also reconciled. The
[sidebar receipt](docs/quality/graphify-shell-persistence.md) records implemented
local choice persistence and widget checks, not native relaunch. All four scoped
source/test fingerprints match; retained logs confirm the 161 focused and 3,664
full-suite results reported by that executor. Test plan, navigation and Unreleased
history expose this bounded change. Existing spec and parity wording is preserved.
The stale unchecked PORT-SHELL-PERSISTED-STATE body moves verbatim to this archive.
Its former checkbox and ownership wording are historical, not current state.
Archive prefix bytes and exact block multiplicity are preserved. All other live
entries and their continuations remain unchanged by that migration.

| Core role | Canonical owner | Outcome |
| --- | --- | --- |
| README | `README.md` | unchanged_verified for setup and orientation; `docs/README.md` maintained for evidence navigation. |
| PRD | `docs/product/prd.md` | unchanged_verified for accepted goals and qualification limits. |
| ADR | `docs/adr/README.md` and five living decisions | unchanged_verified for current boundaries and history; no new decision. |
| Spec | `docs/spec.md` | maintained for bootstrap denial and bounded recovery evidence. |
| Owned HTTP API | `docs/api/wing-link.openapi.yaml` | unchanged_verified for manual code-first ownership and YAML syntax; schema/runtime conformance not executed. |
| Test plan | `docs/test-plan.md` | maintained for bootstrap recovery and sidebar persistence scenarios. |
| Runbook | `docs/getting-started.md`, setup/release runbooks and `docs/runbooks/desktop-feature-qualification.md` | qualification runbook maintained; other core operations owners unchanged_verified for inspected prerequisites and limits. |
| Changelog | `CHANGELOG.md` | maintained for implemented Unreleased sidebar persistence, not release publication. |

All applicable core owners exist; none needs creation. Existing BLOCKERS entries
and defaults are preserved. No new owner question is needed. Live qualification,
physical input, packaged execution and protected-main delivery remain separate gaps.

Root `goals.json` retains focus M1 and existing statuses. Coverage is 35 goals:
2 met, 17 partial, 9 unmet and 7 unverified, with 156 tasks. Both met goals retain
executed passing evidence. Every non-met goal has at least two unfinished slices.
Root `TODO.md` retains 68 open task bodies and no stale completion checkbox.
No task is added, claimed or closed by this pass. Existing native bootstrap
completion remains done; shell completion is reconciled, not reopened.
The next helper-eligible task is PARITY-LIVE-WORKFLOW, already in_progress.
Ownership, separate QA authentication and the missing supported provider-call
ceiling still govern execution. VERIFY-LIVE-WORKFLOW-RECOVERY is its queued
successor; no worker is started.

Executed documentation checks:
`python3 <home>/.hermes/shared-skills/repo-docs/scripts/goals.py fmt .` →
`validate .` → `render .` prints `ok`. A repeated cycle preserves goals/TODO/archive
bytes. `goals.py next .` selects the live workflow. `git diff --check` and
`git show --format= --check agent/wing/t_e662982c` pass. Offline local links and
anchors, task-body status, met evidence, two-slice coverage and archive conservation
checks pass. `/usr/bin/python3` parses OpenAPI 3.1.0 YAML with 20 paths.
This is syntax, not full standards or runtime conformance.

Mechanical review checks changed prose structure, punctuation and protected
identifiers. Language/meaning review applies the STE-inspired profile to changed
prose and preserves synthetic/live, implementation/qualification/delivery and
failure/retry limits. Full ASD-STE100 dictionary compliance is not verified.
Only offline documentation checks run on Linux. Builds, product tests, devices,
network links, live requests, installs and release operations are not executed.
No source, tests, cards, schedules, commits, pushes or external systems change.

## Direct first-run worktree documentation receipt

Mode: Bootstrap + Maintain; documentation, root TODO and helper-managed goals only.
The monitor reports changed agent branches at unchanged HEAD
`b9eb5b3d9f6f3a433dd36cb6271ad8ec769b2319` and zero listed path drift.
Newest branch `agent/wing/t_98b85c1b` at `c7899719a9aa9c5619412a9977804917eec46a49`
attributes pre-existing connection files. It does not deliver or qualify the later
unstaged enrollment change. No card, schedule, source or test is changed here.

README, getting-started, product/route/enrollment summaries, the living product
record's implementation note, spec and test plan now distinguish committed pairing
entry from current in-progress direct entry. Chat Add/connect-another opens the
existing endpoint form. Enrollment offers Add Hermes before optional setup/pairing,
and the form links back to optional enrollment. Older-build manual instructions
remain available. Accepted requirements and trust boundaries do not change.
No passing first-run receipt was verified. Regression file presence is inspection,
not executed qualification, native/Android/live support or protected-main delivery.

Scoped source fingerprints inspected in this pass:

- `lib/features/enrollment/screens/hermes_enrollment_screen.dart`:
  `8ef9628cee151b2737954d79821573af466822de173b0d1ff9be2ac84b845764`.
- `lib/features/hermes_chat/screens/hermes_chat_screen.dart`:
  `79ad8648db2375ba691aac47fefcbb7defc38860a936e8456a445084d664146b`.
- `lib/features/hermes_chat/screens/state/hermes_chat_layout.dart`:
  `0f5eed485e25f18b105249a92550f876248867fc856a9f92beb6524537af7243`.
- `test/features/enrollment/hermes_direct_first_run_test.dart`:
  `0f5feb0e6525ab5fca8d35c79671ee3f263ce2b646705fd3e3b76669164ee5bc`.
- `playwright/tests/regression/direct-first-run.spec.mjs`:
  `dc1cc21e63a0ab4b62ca17b07066adffe9f2361b6746917458558167f862c8d5`.

| Core role | Canonical owner | Outcome |
| --- | --- | --- |
| Orientation | `README.md` | maintained for development versus older-build direct entry. |
| Requirements | `docs/product/prd.md` | maintained implementation status; accepted CONN requirements unchanged. |
| Decisions | `docs/adr/README.md` and five living records | product implementation note maintained; decision and other relevant boundaries unchanged_verified. No new ADR. |
| Design | `docs/spec.md` | maintained for in-progress route composition, not a new transport. |
| Owned HTTP API | `docs/api/wing-link.openapi.yaml` | unchanged_verified for code-first ownership and YAML syntax; no route change or standards/runtime conformance execution. |
| Verification | `docs/test-plan.md` | maintained for added but unexecuted first-run regressions and missing qualification. |
| Operations | `docs/getting-started.md`, `docs/runbooks/android-hermes-setup.md` and release runbooks | getting-started and optional Android setup orientation maintained with older-build fallback; other core procedures unchanged_verified for inspected prerequisites and limits. No operational action. |
| History | `CHANGELOG.md` | unchanged_verified; no qualified new product delivery or release inferred from the in-progress slice. |

All applicable core owners exist; none needs creation. Existing BLOCKERS entries
and defaults remain unchanged. No new owner question is required. Managed SSH,
full saved-connection/setup qualification and the integrated live journey remain
open under existing tasks.

During the pass, a concurrent writer registered M1-DIRECT-FIRST-RUN as in_progress
in goals.json without its full TODO body. This pass supplies that missing body,
without registering a duplicate or changing status. CONNECTION-SAVED-WORKFLOWS
adds current inspection context; its owner and open acceptance remain intact.
PARITY-NATIVE-BOOTSTRAP-RESTART was already done but had no full task body in live
TODO or history. The reconstructed completion entry below uses the existing ledger
and retained execution receipt, not a lost original body or a newly closed card.
No live body is moved. Pre-existing archive bytes remain an exact prefix.

- [x] **PARITY-NATIVE-BOOTSTRAP-RESTART** — Goal: M1.
  Retain exact saved ownership through native restart bootstrap 401/403 and
  deliberate keyboard Retry. Payoff: authentication denial cannot select a
  fallback session or replay mutations.
  Sources: [native receipt](docs/quality/native-no-inference-bootstrap-recovery.md)
  and [test plan](docs/test-plan.md#native-relaunch-and-canonical-transcript-recovery).
  Scope delivered: synthetic native fixture, driver and receipt validation;
  no production repair, Agent changes, live authentication/inference or publication.
  Acceptance evidence: retained `timeout 30m bash scripts/run_linux_desktop_no_inference_smoke.sh`
  returned NATIVE_NO_INFERENCE_PASS. Six GTK phase receipts record zero mutation,
  provider and management counters. Logs confirm 88 focused Flutter, 15 tooling
  and four admission passes. The retained archive digest matches its verification
  record. These are inspected executor results, not product checks rerun here.
  Dependencies: PARITY-NATIVE-AUTH-RESTART (done). Ownership: delivered t_e662982c;
  existing ledger completion preserved. Physical input, packaged/native-live
  qualification and main delivery remain NOT_CHECKED.
  Remaining M1 gap: actual generation/approval/Stop and authoritative restoration
  with supported provider-call limits, separate QA authentication and main delivery.

Root goals.json retains primary focus M1. Coverage: 35 goals, 157 tasks;
2 met, 17 partial, 9 unmet and 7 unverified. All 33 non-met goals retain at least
two unfinished slices. Both met goals retain executed passing journey evidence.
This pass promotes no goal and adds no ledger task. TODO supplies one existing
in-progress body and updates one existing workflow body. History supplies one
existing completed body. All 157 task bodies are discoverable between live TODO
and this archive; live TODO retains only unfinished entries.
The first helper-eligible task is M1-DIRECT-FIRST-RUN, already in_progress;
PARITY-LIVE-WORKFLOW is also in_progress. The first open fallback is
PARITY-MAESTRO-ANDROID-DEVICE. Eligibility is not tracker ownership or dispatch.
No worker is started.

Executed documentation checks on Linux:
`python3 <home>/.hermes/shared-skills/repo-docs/scripts/goals.py fmt .` →
`validate .` → `render .` prints `ok`. Offline local links/anchors, task-body
coverage/status, two-slice coverage and the met evidence rule pass.
`git diff --check` and `git show --format= --check agent/wing/t_98b85c1b` pass.
System Python parses OpenAPI 3.1.0 YAML with 20 paths; syntax is not runtime
conformance. Repeated helper checks preserve TODO/goals/archive bytes.
The archive prefix and unrelated open-task bodies/continuations remain unchanged.
BLOCKERS remains byte-identical. Concurrent ledger registration is retained,
not attributed to this pass.

Mechanical review checks changed Markdown, punctuation and protected identifiers.
Language/meaning review applies the STE-inspired profile to changed prose. It
preserves optional management, committed/development state, inspection/execution
and qualification/delivery limits. Full ASD-STE100 dictionary compliance is not
verified. No product tests/builds, native launch, physical devices, live requests,
network link checks, installs, API standards/runtime conformance or release action
runs in this documentation pass.


## Direct first-run qualification follow-through

Historical task wording below is preserved verbatim, including its former open
checkbox and in-progress ownership. The ledger now records completion. The
[source-bound receipt](docs/quality/direct-first-run.md) and retained logs prove
bounded widget/Chromium qualification, not main delivery or native/live behavior.

- [ ] **M1-DIRECT-FIRST-RUN** — Goal: M1. Promote direct Local/SSH/Remote
  connection before optional management setup and pairing.
  Payoff: a fresh user reaches Agent without installing or authenticating Wing Link.
  Sources: [accepted direction](docs/adr/product.md#decision),
  [CONN-1](docs/product/prd.md#connection-path-requirements) and
  [first-run checks](docs/test-plan.md#connection-path-verification).
  Scope: existing enrollment/Chat routing, endpoint form, localization and nearest
  public-route widget/browser regressions. Exclude managed SSH implementation,
  new OAuth authority, Agent changes, personal credentials and host installation.
  Acceptance: compact/wide keyboard users reach Local/SSH/Remote without a pairing
  detour. Auth rejection requires explicit retry; management absence/failure does
  not prevent direct Agent access. Record zero management requests and mutations
  on the Agent-only fixture path. Optional pairing retains its trust checks.
  Run `flutter test --concurrency=1 test/features/enrollment/hermes_direct_first_run_test.dart`,
  analyze and a freshly compiled `direct-first-run.spec.mjs` browser journey.
  Retain source-bound results; fixtures do not qualify live authentication or native SSH.
  Current snapshot: primary access and regression files exist; no passing first-run
  receipt was verified in this docs pass. Qualification and main delivery remain open.
  Dependencies: CONNECTION-SAVED-HOST-OWNER-SAFETY (done). Section: Now.
  Ownership: concurrently registered in_progress; preserve the existing worker and
  check actual tracker ownership before any action. Do not dispatch duplicate work.

## Documentation verification receipt

Mode: Bootstrap + Maintain; Wing documentation, TODO and helper-managed goals only.
The monitor changed the agent-branch set at unchanged HEAD
`b9eb5b3d9f6f3a433dd36cb6271ad8ec769b2319`; listed path drift was zero.
The newly completed `agent/wing/t_98b85c1b` at
`046267501ae884fde73e5a0ea1dae02353d5c8c8` supplies the first-run change.
All 15 selected source/lock fingerprints match the current inspected snapshot.
Retained logs record 123 focused widget passes, four dedicated widget passes,
ten compiled Chromium journeys, clean analysis and a fresh JS-release build.
Six browser traces contain no management requests or mutations. Earlier failed
browser attempts remain visible in the original receipt. This pass inspects those
results; it runs no product tests and does not qualify the whole dirty worktree.
Node 26, not the documented Node 22, executed the retained browser checks.

README, onboarding, enrollment, PRD status, the living product decision, routes,
spec, test plan and connection comparison no longer call this bounded slice
wholly unqualified. The docs index links its evidence. CHANGELOG records the
implemented change as Unreleased, not delivered to protected main. Requirements,
Agent ownership, separate management credentials and optional pairing trust are
unchanged. Managed SSH remains planned; current SSH requires an external trusted
tunnel. Native/live and Android qualification, combined gates and main delivery
remain separate gaps. No new owner question arises; existing BLOCKERS and their
defaults remain byte-identical.

| Core role | Canonical owner | Outcome |
| --- | --- | --- |
| README | `README.md` | maintained for first-run qualification limits. |
| PRD | `docs/product/prd.md` | maintained for implemented versus qualified status; acceptance unchanged. |
| ADR | `docs/adr/README.md` and five living decisions | product decision status maintained; other boundaries unchanged_verified. |
| Spec | `docs/spec.md` | maintained for source-bound direct entry and recovery evidence. |
| Owned HTTP API | `docs/api/wing-link.openapi.yaml` | unchanged_verified for manual code-first ownership and parsed YAML syntax; runtime conformance unverified. |
| Test plan | `docs/test-plan.md` | maintained for passing bounded checks and separate native/live gaps. |
| Runbook | `docs/getting-started.md`, setup/release runbooks | direct setup guide maintained; remaining inspected operational limits unchanged_verified. |
| Changelog | `CHANGELOG.md` | maintained with the implemented Unreleased entry; no release invented. |

All applicable core owners already exist; none needs creation. No new ADR or API
operation is introduced. Full API standards/runtime conformance and operational
release procedures are not executed. No source, test, install, card, schedule,
upstream, external-system, commit or push action occurs.

Root `TODO.md` archives M1-DIRECT-FIRST-RUN's exact 1,662-byte body, preserving its
historical checkbox and ownership. The existing M1-DIRECT-FIRST-RUN-NATIVE gains
its missing full body; it remains in_progress, not newly dispatched. No ledger
task is added or closed. All unrelated live entries and continuations remain
verbatim. Archive prefix bytes and moved-block multiplicity are conserved.
Root `goals.json` retains primary milestone M1 and all recorded evidence.
Coverage: 35 goals, 158 tasks; 2 met, 17 partial,
9 unmet and 7 unverified. Every non-met goal has at least two unfinished
slices; both met goals retain executed passing evidence. The helper's smallest
eligible task is M1-DIRECT-FIRST-RUN-NATIVE, already in_progress. Eligibility does
not establish current tracker ownership. The remaining M1 gap is native direct
entry plus actual generation/approval/Stop/relaunch and read-only recovery.
No autogoal worker is started.

Executed documentation checks on Linux:
`python <home>/.hermes/shared-skills/repo-docs/scripts/goals.py fmt .` →
`validate .` → `render .` prints `ok`. Repeating the cycle preserves goals,
TODO and archive bytes. Offline checks verify local links/anchors, all goal-source
paths, task checkbox/body coverage, two-slice coverage and met-goal evidence.
`git diff --check` passes. `/usr/bin/python3` parses OpenAPI 3.1.0 YAML with
20 paths; syntax is not API conformance. Receipt fingerprints and retained test
logs are inspected, not new runtime execution.

Mechanical review checks changed Markdown, punctuation and protected identifiers.
Language/meaning review applies the STE-inspired profile to changed prose. It
preserves accepted intent, optional management, qualification versus delivery,
read-only recovery and platform limits. Full ASD-STE100 dictionary compliance is
not verified. Product tests/builds, native launches, physical devices, live or
network requests, installs and release actions are not run in this pass.



## Native direct first-run completion

Historical task body from root TODO. Its unchecked box and in-progress wording
record the previous handoff, not current ownership. The native receipt and ledger
now record completion at the tested source fingerprint.

- [ ] **M1-DIRECT-FIRST-RUN-NATIVE** — Goal: M1. Qualify public direct
  Local/SSH/Remote entry and explicit read-denial recovery in isolated Linux GTK.
  Payoff: desktop keyboard users reach Agent without mandatory management setup.
  Sources: [accepted entry requirements](docs/product/prd.md#connection-path-requirements),
  [completed widget/browser slice](docs/quality/direct-first-run.md) and
  [native integration target](integration_test/linux_direct_first_run_test.dart).
  Scope: isolated production-router/Chat entry, deterministic Agent fixture,
  adaptive keyboard navigation and source-bound native evidence. Exclude inference,
  personal credentials, managed SSH implementation, host setup and shared services.
  Acceptance: public entry reaches Local/SSH/Remote at compact/wide widths and
  enlarged text. Synthetic read denial requires explicit retry; exact-owner recovery
  adds no Agent mutations or Wing Link requests. Optional pairing remains reachable.
  Run the isolated `scripts/run_linux_direct_first_run.sh` harness and retain its
  source manifest, native logs and focused regression results. Fixture results do
  not qualify actual Agent authentication, physical input or protected-main delivery.
  Dependencies: M1-DIRECT-FIRST-RUN (done). Section: Now.
  Ownership: ledger in_progress; preserve the existing worker. Check actual tracker
  ownership before any action; do not dispatch duplicate work.


## Native direct first-run qualification follow-through

Mode: Bootstrap + Maintain; Wing documentation, TODO and goals only. The monitor
reports changed agent branches at unchanged HEAD
`b9eb5b3d9f6f3a433dd36cb6271ad8ec769b2319`, with zero listed path drift.
The newest branch is `agent/wing/t_95a5ae74` at `45a80e42`. Its
[native receipt](docs/quality/direct-first-run-native.md) records four passing
Linux GTK production-router/Chat journeys at 390/1280px and 1x/2x text. Retained
logs confirm 17 focused Flutter passes, five launcher passes and clean analysis.
The executed archive digest matches the receipt. All five owned inputs and all
754 candidate input hashes match this inspected snapshot. Four native traces
record zero management, mutation and forbidden-read attempts. This pass inspects
receipts and source binding, not a fresh product run or independent approval.

The guides, current route status, spec, test plan, product status and Unreleased
entry now distinguish completed deterministic GTK first-run qualification from
remaining live authentication, Android, managed SSH and main delivery. The docs
index no longer calls the implemented primary-entry redesign planned. Optional
management remains separate. No accepted requirement or API boundary changes.
The launcher depends on attributed inherited inputs and a retained Git object;
its own-files agent commit alone is not a standalone launcher checkout.

| Core role | Canonical owner | Outcome |
| --- | --- | --- |
| README | `README.md` | maintained for bounded native first-run evidence; docs navigation also maintained. |
| PRD | `docs/product/prd.md` | maintained for implementation/qualification status, not new requirements. |
| ADRs | `docs/adr/README.md` and five living decisions | product status maintained; accepted decisions and other boundaries unchanged_verified. |
| Spec | `docs/spec.md` | maintained for native entry/recovery and launcher dependency limits. |
| Owned HTTP API | `docs/api/wing-link.openapi.yaml` | unchanged_verified for manual code-first ownership; schema/runtime conformance not run. |
| Test plan | `docs/test-plan.md` | maintained for GTK scenarios and separate actual-auth/storage limits. |
| Operations | `docs/getting-started.md`, `docs/runbooks/android-hermes-setup.md`, `docs/runbooks/release-alpha.md` | getting-started evidence maintained; existing setup/release procedure boundaries unchanged_verified. |
| Changelog | `CHANGELOG.md` | existing Unreleased entry maintained for bounded GTK qualification, not publication. |

All applicable core owners already exist. None needs creation. Root BLOCKERS
entries/defaults remain byte-identical; no new owner question is required.
Root TODO archives M1-DIRECT-FIRST-RUN-NATIVE verbatim after matching its done
ledger status to the retained receipt. Its historical unchecked box is labelled
as such. Archive prefix bytes and block multiplicity are preserved. All 68
unrelated live task blocks and continuations remain verbatim. TODO adds a full
body for the existing in-progress M1-NATIVE-CONNECTION-SAVE-RETRY successor.
No task ID is added to goals, reopened, claimed or dispatched by this pass.

Root goals remains byte-identical after canonical maintenance. M1 stays partial
and remains the primary milestone. Coverage: 35 goals and 159 tasks; two met,
17 partial, nine unmet and seven unverified. All 33 non-met goals have at least
two unfinished slices. Every unfinished ledger task has one live TODO body.
Both met goals retain executed passing journey evidence. The helper next task is
M1-NATIVE-CONNECTION-SAVE-RETRY, already in_progress; preserve its worker. The
remaining live integrated milestone is PARITY-LIVE-WORKFLOW, also in_progress.
This is queued/owned work, not observed new dispatch, merge or milestone acceptance.

Executed offline checks: `python3 <home>/.hermes/shared-skills/repo-docs/scripts/goals.py fmt .`
then `validate .` then `render .` print `ok`; `goals.py next .` selects the native
save-retry task. `git diff --check` passes. Local checks resolve 719 links/anchors
across core owners, status, coordination and native evidence. All goal-source
paths resolve. Archive conservation and live task coverage pass. An initial
whole-TODO comparison used a Python variable overwritten by the edit loop and
failed; the corrected exact per-task comparison passes for all unrelated blocks.
A repeated canonical cycle verifies byte stability for TODO, goals and archive.

Mechanical review checks changed sentence structure, punctuation and protected
identifiers. Language/meaning review applies the STE-inspired profile and preserves
synthetic/live, injected/physical, candidate/commit and qualification/delivery
limits. Full ASD-STE100 dictionary compliance is not verified. Repository checks
are offline on Linux. Product tests/builds, native launches, devices, live/network
requests, installs, API standards/runtime checks and release operations are not run.

## Native direct connection retry completion

Historical task body from root TODO; its checkbox and ownership wording describe
the prior queue state. The ledger and retained passing GTK receipt now record
completion of this bounded synthetic slice, not live authentication or M1.

- [ ] **M1-NATIVE-CONNECTION-SAVE-RETRY** — Goal: M1. Keep native direct
  connection authentication and uncertain-save recovery explicit and owner-bound.
  Payoff: desktop users can recover without losing a connected draft or retargeting
  a replacement host/profile/session.
  Sources: [connection requirements](docs/product/prd.md#connection-path-requirements),
  [completed native first-run check](docs/quality/direct-first-run-native.md) and
  [shared Remote retry behavior](docs/quality/remote-connection-retry.md).
  Scope: public production-router/Chat controls with isolated Linux GTK, synthetic
  auth/read denial and injected endpoint-save failures. Reuse existing channel,
  secure-store and owner fences. Exclude inference, personal credentials, managed
  SSH, host setup, shared services and claims of physical secure-storage support.
  Acceptance: explicit retry recovers the exact initiating owner, pending saves
  cannot duplicate attempts, and late results cannot mutate a replacement owner.
  Preserve the draft after uncertain persistence. Record zero implicit Agent
  mutations and Wing Link requests, native logs, source hashes and focused tests.
  Extend or add the smallest isolated native integration check and launcher.
  Dependencies: none. Section: Now.
  Ownership: ledger in_progress; preserve the existing worker and check tracker
  ownership before any action. Do not dispatch duplicate work.


## Native Remote retry qualification follow-through

Mode: Bootstrap + Maintain. Scope: Wing documentation, root TODO and helper-managed
goals only. The monitor reports changed agent branches at unchanged HEAD
`b9eb5b3d9f6f3a433dd36cb6271ad8ec769b2319`, with zero listed path drift.
The inspected branch is `agent/wing/t_2d93a7e9` at `81312871d51446cc105ebf3ad9b39d6d69b50bdc`.
Existing dirty/staged work and BLOCKERS entries remain intact.

### Correction and source boundary

Spec, test plan, parity summary and docs navigation now expose the completed
[native retry qualification](docs/quality/remote-connection-retry-native.md).
They no longer describe Remote auth/save recovery as only widget/Chromium evidence.
Retained logs confirm four Linux GTK journeys, 33 focused Flutter passes and clean
analysis. Each layout covers four delayed-save cases. Injected endpoint storage,
logical keys and assisted scrolling do not qualify physical keychain/input,
live authentication, Android or main delivery. This pass inspects executor evidence;
it does not rerun product checks or infer independent approval.

The retained source archive digest matches the receipt. Of 759 candidate inputs,
757 match this inspected snapshot. Two later inputs differ:
`scripts/support/remote_connection_retry_native.py` and
`test/tooling/remote_connection_retry_native_test.py`. Their added Go-module isolation
and regression checks are not qualified by the earlier native result. Both Dart
native inputs and all production inputs retain their recorded hashes. Do not reuse
this result as qualification of the full current tree or a standalone branch build.

### Core-role coverage

| Role | Canonical owner | Outcome |
| --- | --- | --- |
| README | `README.md` | unchanged_verified for orientation/setup; `docs/README.md` maintained for evidence navigation. |
| PRD | `docs/product/prd.md` | unchanged_verified for Desktop-first intent and connection acceptance limits. |
| ADRs | `docs/adr/README.md` and five living decisions | unchanged_verified for authority, optional management and existing history; no new decision. |
| Spec | `docs/spec.md` | maintained for bounded native auth/save recovery evidence. |
| Owned HTTP API | `docs/api/wing-link.openapi.yaml` | unchanged_verified for manual code-first ownership; YAML syntax checked, not standards/runtime conformance. |
| Test plan | `docs/test-plan.md` | maintained for native scenarios and exact source-binding limits. |
| Runbooks | `docs/getting-started.md`, `docs/runbooks/android-hermes-setup.md`, `docs/runbooks/release-alpha.md` | unchanged_verified for inspected prerequisites and recovery limits; no operational action. |
| Changelog | `CHANGELOG.md` | unchanged_verified; qualification adds no production behavior or release. |

All applicable core owners exist; none needs creation. No new owner question arises.
Existing BLOCKERS questions and defaults are preserved. No requirement or API changes.

### Goal handoff and preservation

Root `TODO.md` removes the stale unchecked body for the already-done
M1-NATIVE-CONNECTION-SAVE-RETRY. The body above is archived verbatim, including
historical ownership. Exact moved-block multiplicity, the pre-existing archive
prefix and all 68 unrelated open bodies/continuations are preserved.
No task is added, claimed, reopened or closed by this pass. Root `goals.json`
retains focus M1 and 159 tasks across 35 goals: two met, 17 partial, nine unmet
and seven unverified. All 33 non-met goals retain at least two unfinished slices.
Both met goals retain executed passing evidence. No goal is promoted here.
The helper first returns PARITY-LIVE-WORKFLOW, already in_progress; do not dispatch
another worker. The next open helper candidate is PARITY-MAESTRO-ANDROID-DEVICE;
current ownership must be checked before execution. The smallest queued native
composition slice is VERIFY-PROFILE-FOOTER-NATIVE. Eligibility is not observed
execution. No worker, card, schedule or protected-main delivery is changed.

### Documentation verification

Executed on Linux: `python3 ~/.hermes/shared-skills/repo-docs/scripts/goals.py fmt .`,
then `validate .`, then `render .`; validation prints `ok`. A repeated canonical
cycle preserves TODO/goals/archive bytes. Coverage, task checkbox consistency,
the met rule and exact archive conservation pass. Offline checks resolve 698 local
links/anchors across 19 core/affected owners; 26 optional local artifact links are
excluded from availability checks. `/usr/bin/python3` with existing PyYAML parses
OpenAPI 3.1.0 and 20 paths. `git diff --check` and
`git show --format= --check agent/wing/t_2d93a7e9` pass.

Mechanical review checks scoped Markdown, sentence structure, punctuation and
protected literals. Language/meaning review applies the STE-inspired profile and
preserves synthetic/live, logical/physical, historical/current and qualification/
delivery distinctions. Full ASD-STE100 dictionary compliance is not verified.
Repository checks are separate from language review. Product tests/builds, native
launches, live/network requests, devices, API standards/runtime conformance and
release operations are not run. No source/test changes or installs occur here.

## Native retry dependency-isolation rerun

Bootstrap + Maintain follows the monitor's changed agent-branch digest at unchanged
HEAD `b9eb5b3d9f6f3a433dd36cb6271ad8ec769b2319`, with zero listed drift.
The inspected branch is `agent/wing/t_2d93a7e9` at
`142ffb46307aa74de84f535b103de908f043652f`. This pass changes documentation and
TODO only. Existing staged/dirty implementation, ledger ownership and BLOCKERS
entries are preserved. No worker, card, schedule or external state is changed.

### Correction and evidence boundary

The [final native retry receipt](docs/quality/remote-connection-retry-native.md)
now records an executed rerun with isolated Go dependencies for the bundled
Wing Link build. Spec, test plan and parity summary remove the stale statement
that these launcher changes have no native qualification. Retained logs confirm
six Python regressions, clean analysis, 33 focused Flutter passes and four Linux
GTK journeys. This pass inspects those logs; it reruns no product checks.
Physical input, keychain behavior, Android, live authentication and main delivery
remain unqualified.

The source, Dart-package and Go-module archive digests match the final receipt.
All 17239 archived Dart files and 677 Go files match their manifests. The launcher,
Python regressions, two native Dart inputs and Wing Link lockfiles match the
executed candidate. Of 759 recorded source inputs, 751 match the current snapshot.
Eight later Chat/storage/localization files differ. The final rerun therefore
qualifies its archived candidate, not the entire current worktree. The earlier
archive receipt remains unchanged as historical evidence.

### Core-role coverage

| Role | Canonical owner | Outcome |
| --- | --- | --- |
| README | `README.md`, `docs/README.md` | unchanged_verified for orientation, direct entry and evidence navigation. |
| PRD | `docs/product/prd.md` | unchanged_verified for accepted Desktop-first and connection requirements. |
| ADRs | `docs/adr/README.md` and five living decisions | unchanged_verified for authority and optional management boundaries; no new decision. |
| Spec | `docs/spec.md` | maintained for the qualified dependency-isolation rerun and source limits. |
| Owned HTTP API | `docs/api/wing-link.openapi.yaml` | unchanged_verified for manual code-first ownership; YAML syntax checked, not standards/runtime conformance. |
| Test plan | `docs/test-plan.md` | maintained for final logs, dependency provenance and later source differences. |
| Runbooks | `docs/getting-started.md`, `docs/runbooks/android-hermes-setup.md`, `docs/runbooks/release-alpha.md` | unchanged_verified for inspected prerequisites and recovery limits; no operational action. |
| Changelog | `CHANGELOG.md` | unchanged_verified; this rerun adds no production behavior or release. |

All applicable core owners exist; none needs creation. No new owner question
arises. Existing questions and defaults remain in root BLOCKERS without edits.
No requirement, API or release claim is expanded.

### Goal handoff and preservation

Root `TODO.md` adds the missing full entry for M1-SAVED-ENDPOINT-EDIT, already
in_progress in `goals.json`. It defines public read-only Test, explicit Save,
cancellation and stale-owner outcomes without claiming the unfinished source
passes. No task ID, status or ownership is changed. All 68 original live task
bodies and continuations remain verbatim with their original multiplicity.
The archive retains its pre-existing prefix exactly; no task body moves here.

Root `goals.json` stays byte-identical after the canonical helper cycle and
retains focus M1. Coverage: 35 goals, 160 tasks; two met, 17 partial, nine unmet
and seven unverified. All 33 non-met goals retain at least two unfinished slices.
Both met goals retain executed passing evidence. All 160 task IDs have one full
body in the appropriate live/archive owner. No goal is promoted here.
The helper first returns M1-SAVED-ENDPOINT-EDIT, already in_progress, followed by
the existing live-workflow owner. The first open helper candidate remains
PARITY-MAESTRO-ANDROID-DEVICE; tracker ownership still needs checking. The smallest
queued native composition slice is VERIFY-PROFILE-FOOTER-NATIVE. No dispatch is
observed or requested by this pass.

### Verification

Executed on Linux: `python3 ~/.hermes/shared-skills/repo-docs/scripts/goals.py fmt .`,
then `validate .`, then `render .`; each exits 0 and validation prints `ok`.
A repeated canonical cycle preserves TODO, goals and archive bytes. Exact original
live-body and archive-prefix preservation pass. Offline checks resolve 734 local
links/anchors across core/affected owners and TODO; 26 optional local-artifact links
are excluded from availability checks. The phone tutorial's explicit HTML anchor
resolves after the checker accounts for HTML IDs; no link repair is needed.
Existing system PyYAML parses OpenAPI 3.1.0 and 20 paths without an install.
`git diff --check` and `git show --format= --check agent/wing/t_2d93a7e9` pass.

Mechanical review checks scoped Markdown, punctuation and protected literals.
Language/meaning review applies the STE-inspired profile to changed prose and
preserves synthetic/live, physical/logical, candidate/current and qualification/
delivery limits. Full ASD-STE100 dictionary compliance is not verified.
Repository checks are separate from language review. Product builds/tests,
native launches, live/network requests, devices, API standards/runtime conformance
and release procedures are not run in this documentation pass.

## Saved connection editor completion follow-through

Bootstrap + Maintain follows `agent/wing/t_c7e40011` at `589e0a703ef6bcfc2ac85398c59fc533ecb44b9b`.
Shared HEAD remains `b9eb5b3d`; the monitor lists zero path drift.
The saved editor is implemented and qualified through widgets and compiled
Chromium fixtures, not native/live authentication or main delivery.
The ledger already marks M1-SAVED-ENDPOINT-EDIT done. Its original unchecked
body below is historical wording, not active ownership or a queued task.

### Original completed task body

- [ ] **M1-SAVED-ENDPOINT-EDIT** — Goal: M1. Edit a saved Agent endpoint and test
  its connection through explicit, owner-safe public controls.
  Payoff: repair a saved connection without replacing another host's state.
  Sources: [CONN-5](docs/product/prd.md#connection-path-requirements),
  [connection design](docs/spec.md#connection-path-design) and
  [verification matrix](docs/test-plan.md#connection-path-verification).
  Scope: existing saved-endpoint controls, secure endpoint store and nearest
  widget/browser regressions. Exclude Agent writes, managed SSH, OAuth,
  credential copying, personal app state and Wing Link requirements.
  Acceptance: explicit Test uses read-only Agent requests and does not select a
  host, create a session or send a prompt. Cancel, failure, disposal, changed
  draft and replacement owner reject obsolete results. Explicit Save reports
  persistence separately from readiness and retains recoverable input on error.
  Run `test/features/hermes_chat/screens/hermes_chat_saved_endpoint_edit_test.dart`,
  analysis and a freshly compiled public-control browser journey. Record native
  and physical secure-storage gaps separately; existing source is not a pass.
  Dependencies: none in the current ledger. Section: Now.
  Ownership: ledger in_progress; preserve the existing worker. Do not redispatch.

### Documentation and goal-gap result

Spec, connection verification, parity status, setup instructions, navigation and
Unreleased history now distinguish implemented saved edit/Test from native/live
qualification. No accepted requirement, API operation or architecture changes.
The source trace confirms a separate client, a 20-second loading timeout, exact-ID
save, URL collision rejection and changed-identity management-trust invalidation.
A changed URL does not reuse the old credential; unauthenticated discovery remains
possible where Agent allows it. Test success does not establish inference readiness.

Retained final logs confirm 93 combined widget passes, 166 client/directory passes,
clean analysis, a JavaScript build and four compiled Chromium journeys. The early
`focused.log` failure is historical, not the final suite result. Of 611 manifest
entries, 610 match the inspected tree; only generated `playwright/results.json`
differs. The removed build cannot be rehashed. These are inspected executor receipts,
not product checks rerun here or independent approval. Native Linux editor/storage,
Android, live authentication, the combined gate and main delivery remain separate.

| Core role | Canonical owner | Outcome |
| --- | --- | --- |
| README | `README.md`, `docs/README.md` | orientation unchanged_verified; evidence navigation maintained. |
| PRD | `docs/product/prd.md` | unchanged_verified for accepted Desktop-first and CONN-1 through CONN-6 intent. |
| ADRs | `docs/adr/README.md` and five living decisions | unchanged_verified for authority/security boundaries; no new decision. |
| Spec | `docs/spec.md` | maintained for saved-editor flow and qualification limits. |
| Owned HTTP API | `docs/api/wing-link.openapi.yaml` | unchanged_verified for manual code-first ownership; YAML syntax checked, not standards/runtime conformance. |
| Test plan | `docs/test-plan.md` | maintained for retained editor checks and remaining platform proof. |
| Runbooks | `docs/getting-started.md`, `docs/runbooks/android-hermes-setup.md`, `docs/runbooks/release-alpha.md` | direct-connection repair maintained; optional setup/release prerequisites unchanged_verified. |
| Changelog | `CHANGELOG.md` | maintained for implemented Unreleased editor behavior, not publication. |

All applicable core owners exist; none needs creation. Existing BLOCKERS questions
and defaults remain unchanged. No new owner question arises.

Root `TODO.md` archives the completed M1-SAVED-ENDPOINT-EDIT body verbatim and adds
the missing full entry for the existing M1-SAVED-ENDPOINT-EDIT-NATIVE task.
CONNECTION-SAVED-WORKFLOWS and CONNECTION-SETUP-AUTH-MATRIX now point to delivered
first-run/editor subsets and preserve the separate native owner. No task is added
to the ledger, closed, reopened or claimed. The archive prefix and completed-block
multiplicity are preserved. All 66 unrelated live task bodies and continuations
remain exact. Root `goals.json` remains helper-managed and retains focus M1.
Coverage: 35 goals, 161 tasks; two met, 17 partial, nine unmet and seven unverified.
All 33 non-met goals have at least two unfinished slices. Both met goals retain
executed passing journey evidence; no goal is promoted by this pass.

The first helper candidate is M1-SAVED-ENDPOINT-EDIT-NATIVE, already in_progress,
then the existing live-workflow owner. The first open candidate is
PARITY-MAESTRO-ANDROID-DEVICE. VERIFY-PROFILE-FOOTER-NATIVE remains a smaller queued
native composition slice. Eligibility does not establish tracker ownership.
No worker, card or schedule is started or changed.

### Verification

Executed offline on Linux:
- `python3 <home>/.hermes/shared-skills/repo-docs/scripts/goals.py fmt .`
- `python3 <home>/.hermes/shared-skills/repo-docs/scripts/goals.py validate .`
- `python3 <home>/.hermes/shared-skills/repo-docs/scripts/goals.py render .`
- `python3 <home>/.hermes/shared-skills/repo-docs/scripts/goals.py next . --json`
- `git diff --check`
- `git show --format= --check agent/wing/t_c7e40011`

The canonical cycle exits 0 and validation prints `ok`. Repetition preserves TODO,
goals and archive bytes. Static checks resolve 701 core/affected local links and
anchors, excluding 26 optional local-artifact links from availability checks.
Task coverage/status, goal-source paths, the met rule, two-slice coverage and exact
archive/live-body preservation pass. System PyYAML parses OpenAPI 3.1.0 with 20
paths; this is syntax only. No dependencies or validation framework are installed.

Mechanical review checks changed Markdown, punctuation, sentence structure and
protected identifiers. Language/meaning review applies the STE-inspired profile
and preserves saved/active identity, read/persistence/readiness, cancellation and
synthetic/native/live boundaries. Full ASD-STE100 dictionary compliance is not
verified. Repository checks are separate from language review. Product tests,
builds, native launches, live/network requests, devices, API standards/runtime
conformance and release procedures are not run in this documentation pass.


## Native saved connection editor completion follow-through

The original task body below is preserved verbatim from TODO.md. Its unchecked
box and in_progress wording describe the former state, not a new assignment.
The ledger already records M1-SAVED-ENDPOINT-EDIT-NATIVE done. The
[native receipt](docs/quality/saved-endpoint-edit-native.md) qualifies the frozen
synthetic Linux GTK candidate with fake endpoint storage. Real platform storage
and restart remain unqualified and belong to the already-owned
M1-SAVED-ENDPOINT-REAL-STORAGE successor. M1 remains partial.

### Original task body

- [ ] **M1-SAVED-ENDPOINT-EDIT-NATIVE** — Goal: M1. Qualify saved Agent endpoint
  edit and read-only Test through the public native controls without inference.
  Payoff: prove connection repair works in Linux, not only browser fixtures.
  Sources: [implemented editor and retained checks](docs/quality/saved-endpoint-edit.md),
  [CONN-5](docs/product/prd.md#connection-path-requirements) and
  [connection verification](docs/test-plan.md#connection-path-verification).
  Scope: isolated Linux production editor/channel/store and nearest regressions.
  Exclude personal app state, live inference, managed SSH, OAuth, Agent writes
  and new Wing Link authority. Use approved disposable test identities only.
  Acceptance: public keyboard Edit/Test/Cancel/Save retain the exact saved ID
  and active host/profile/session. Denial, timeout, storage failure, draft edit,
  disposal and owner replacement cannot settle stale feedback. Verify one direct
  capabilities read per explicit Test and zero session/run/management mutations.
  Exercise compact/wide and enlarged text, then restart and read back the saved
  endpoint through real platform secure storage. If storage cannot be exercised,
  report that precise unqualified gap rather than substituting injected evidence.
  Record exact commands, source binding and teardown in the native receipt.
  Dependencies: M1-SAVED-ENDPOINT-EDIT (done). Section: Now.
  Ownership: ledger in_progress; preserve the existing worker. Do not redispatch.

### Maintenance receipt

Mode: Bootstrap + Maintain; documentation, TODO and goals only. The monitor
reports a changed agent-branch digest, unchanged HEAD
`b9eb5b3d9f6f3a433dd36cb6271ad8ec769b2319` and zero listed path drift.
The inspected new branch is `agent/wing/t_f18c95fe` at
`dcd983d657ca8c26f99b3ad1f11915bc87266280`. Existing dirty source, staged
changes, owner questions and unrelated task bodies are preserved.

Design, test-plan, parity, setup and evidence navigation now distinguish the
completed synthetic native editor check from real platform storage and restart.
Retained final executor logs confirm four Linux GTK journeys and 51 focused Dart
passes. The source archive digest and all 767 archived/executed/current input
hashes match. Six recorded check exits are zero. This pass inspects those results,
not a fresh app run or independent review. Fake endpoint storage does not qualify
physical keychain, restart persistence, live authentication, Android or main delivery.
Compact 200% off-screen notice readability remains explicitly unqualified.

| Core role | Canonical owner | Outcome |
| --- | --- | --- |
| README | `README.md` | unchanged_verified for orientation/setup; `docs/README.md` maintained for native evidence navigation. |
| PRD | `docs/product/prd.md` | unchanged_verified for accepted connection scope and leading live workflow acceptance. |
| ADRs | `docs/adr/README.md` and five living decisions | unchanged_verified for applicable boundaries and status; no new architectural decision. |
| Spec | `docs/spec.md` | maintained for bounded GTK editor evidence and storage/visual limits. |
| Owned HTTP API | `docs/api/wing-link.openapi.yaml` | unchanged_verified for manual code-first ownership and YAML syntax; schema/runtime conformance not executed. |
| Test plan | `docs/test-plan.md` | maintained for executed native scenarios, exact source binding and remaining gaps. |
| Runbooks | `docs/getting-started.md`, `docs/runbooks/android-hermes-setup.md`, `docs/runbooks/release-alpha.md` | getting-started maintained for native evidence limits; other owners unchanged_verified for inspected references and procedure boundaries. |
| Changelog | `CHANGELOG.md` | unchanged_verified for existing implemented editor entry; qualification follow-through is not a new feature or release. |

All applicable core owners exist. No missing owner needs creation. No product,
API or release intent is invented. BLOCKERS entries and defaults are unchanged;
no new owner question is needed.

TODO archives M1-SAVED-ENDPOINT-EDIT-NATIVE's original body verbatim and replaces
its stale unchecked entry with M1-SAVED-ENDPOINT-REAL-STORAGE's missing full body.
The successor was already in_progress in goals.json. Its ownership is preserved;
this pass does not dispatch it. No duplicate task is added or task status changed.
The archive prefix and moved block multiplicity pass exact preservation checks.
All 68 unrelated live task bodies and their continuations remain byte-identical.
Goal evidence adds one inspection receipt. Focus remains M1; coverage remains
35 goals and 162 tasks: 2 met, 17 partial, 9 unmet and 7 unverified. All 33 non-met
goals retain at least two unfinished slices. Both met goals retain executed passing
evidence. M1 remains partial. The helper selects M1-SAVED-ENDPOINT-REAL-STORAGE,
but it is already owned; no new worker is started. Live workflow recovery remains
a separate queued successor and still requires its prerequisites.

Executed checks:

- `python <home>/.hermes/shared-skills/repo-docs/scripts/goals.py fmt .`
- `python <home>/.hermes/shared-skills/repo-docs/scripts/goals.py validate .`
- `python <home>/.hermes/shared-skills/repo-docs/scripts/goals.py render .`
- `python <home>/.hermes/shared-skills/repo-docs/scripts/goals.py next .`
- `git diff --check`
- `git show --format= --check agent/wing/t_f18c95fe`

The canonical cycle passes and validation prints `ok`. Offline checks resolve
781 local links/anchors across core/affected documents, excluding 26 optional
local-artifact links. All 69 live task entries match the ledger; all completed
bodies remain in the archive. Goal-source paths, the met rule, two-slice coverage,
source archive binding and archive/live-body conservation pass. System PyYAML
parses OpenAPI 3.1.0 with 20 paths. This is syntax, not schema or runtime proof.
A repeated canonical cycle checks byte stability of TODO, goals and archive.

Mechanical review checks changed Markdown, punctuation and protected identifiers.
Language/meaning review applies the STE-inspired profile to changed prose. It
preserves current versus historical source, fake versus real storage, local
persistence versus readiness, and qualification versus main delivery. Full
ASD-STE100 dictionary compliance is not verified. Repository checks are separate
from language review. Product tests, builds, installs, native launches, live/network
requests, device actions, API standards/runtime conformance and releases are not
run in this documentation pass.


## Saved connection secure persistence follow-through

Bootstrap + Maintain follows `agent/wing/t_d83a3347` at
`49d435a52746499a759f2510828be9e1d008de11`, at unchanged main HEAD
`b9eb5b3d9f6f3a433dd36cb6271ad8ec769b2319`. The monitor lists zero path drift.
Existing dirty source, staged changes and BLOCKERS entries are preserved.

### Original task body

The body below is preserved verbatim from root TODO. Its unchecked box and
in_progress wording describe the former state. The ledger already records
M1-SAVED-ENDPOINT-REAL-STORAGE done; this historical entry queues no work.

- [ ] **M1-SAVED-ENDPOINT-REAL-STORAGE** — Goal: M1. Qualify saved connection
  repair and restart through isolated Linux platform secure storage.
  Payoff: prove that the edited connection survives a new process, not only a fake store.
  Sources: [native editor qualification and storage gap](docs/quality/saved-endpoint-edit-native.md#delivery-and-remaining-milestone-gaps),
  [CONN-5](docs/product/prd.md#connection-path-requirements) and
  [connection verification](docs/test-plan.md#connection-path-verification).
  Scope: public production editor and endpoint store, isolated Linux Secret Service,
  disposable HOME/XDG/DBus and owned native processes. Preserve personal app state,
  shared services and credentials. Exclude live inference, managed SSH, OAuth,
  Agent writes and additional Wing Link authority.
  Acceptance: repair through public Edit/Test/Cancel/Save, retain the original ID
  and same-label peer, then restart and read back the saved endpoint through real
  platform secure storage. Distinguish persistence from readiness. Storage failure,
  explicit retry and delayed owner replacement must not affect another conversation.
  Opening, cancellation and restart must not replay Test or Agent mutations.
  Record exact commands, source binding, isolated service identity and teardown.
  Keep compact/enlarged-text off-screen disclosure readability explicit.
  Dependencies: M1-SAVED-ENDPOINT-EDIT-NATIVE (done). Section: Now.
  Ownership: ledger in_progress; preserve the existing worker. Do not redispatch.

### Maintenance receipt

The later [storage report](docs/quality/saved-endpoint-storage-native.md) and retained
executor logs confirm two passing compiled Linux GTK processes, five Python tests,
23 focused Dart tests and clean analysis. Public editor Save repairs the original
ID and preserves same-label peers. Real Secret Service CreateItem denial retains
the draft; explicit retry and canonical secure readback pass after restart.
Production FlutterSecureStorage/libsecret and native SharedPreferences are used
inside disposable private DBus/GNOME Keyring state. No network, Agent interaction,
inference or mutation is qualified. Both phases and recorded teardown checks pass.

This pass verifies the retained source archive digest. Of 772 executed input hashes,
771 match the inspected tree. The later saved-editor input differs during the
separately owned feedback-accessibility slice. Evidence qualifies the frozen
candidate, not that changed editor or every keyring failure mode. Historical
fake-store receipts remain unchanged. Compact off-screen notice readability,
physical input, screen readers, Android, live authentication and main delivery
remain separate gaps. These are inspected executor receipts, not fresh app tests.

Design, test-plan, parity, setup and evidence navigation now expose this bounded
real-storage result instead of describing all secure persistence as unqualified.
No product requirement, architectural decision, HTTP contract or release changes.

Core-role coverage:

- README: `README.md`, unchanged_verified for orientation and setup; `docs/README.md` maintained for evidence navigation.
- PRD: `docs/product/prd.md`, unchanged_verified for accepted connection scope and live workflow acceptance.
- ADRs: `docs/adr/README.md` and five living decisions, unchanged_verified for authority and existing boundaries; no new decision.
- Spec: `docs/spec.md`, maintained for real-storage evidence and frozen-source limits.
- Owned HTTP API: `docs/api/wing-link.openapi.yaml`, unchanged_verified for manual code-first ownership and YAML syntax; schema/runtime conformance not executed.
- Test plan: `docs/test-plan.md`, maintained for denied-save retry, two-process secure persistence and remaining feedback qualification.
- Runbooks: `docs/getting-started.md`, maintained for named-backend evidence limits; `docs/runbooks/android-hermes-setup.md` and `docs/runbooks/release-alpha.md`, unchanged_verified for inspected setup references and operation boundaries.
- Changelog: `CHANGELOG.md`, unchanged_verified for implemented editor history; qualification follow-through is not a new feature or release.

All applicable core owners exist; none needs creation. BLOCKERS entries and defaults
remain unchanged. No new owner question is required. No worker, card or schedule
is started or changed.

Root TODO archives M1-SAVED-ENDPOINT-REAL-STORAGE's original body verbatim and
adds the missing full entry for M1-SAVED-ENDPOINT-FEEDBACK-ACCESSIBILITY. The
successor is already in_progress in goals.json; its existing ownership is retained.
No duplicate task, goal promotion or task-status change occurs. All 68 unrelated
live task bodies and continuations remain byte-identical. Archive prefix and moved
block multiplicity pass exact preservation checks. Root navigation discovers TODO
and its canonical archive. All unfinished ledger tasks have full live bodies.

Root goals.json retains focus M1 and 163 tasks across 35 goals: 2 met, 17 partial,
9 unmet and 7 unverified. Both met goals retain executed passing evidence.
All 33 non-met goals retain at least two unfinished slices. M1 remains partial.
The helper's next candidate is M1-SAVED-ENDPOINT-FEEDBACK-ACCESSIBILITY, already
owned, not a new dispatch. Its acceptance covers readable compact/enlarged-text
failure and explicit retry guidance. Live workflow/recovery remains separately owned
or queued and does not become qualified through storage evidence.

Executed offline checks on Linux:

- `python <home>/.hermes/shared-skills/repo-docs/scripts/goals.py fmt .`
- `python <home>/.hermes/shared-skills/repo-docs/scripts/goals.py validate .`
- `python <home>/.hermes/shared-skills/repo-docs/scripts/goals.py render .`
- `python <home>/.hermes/shared-skills/repo-docs/scripts/goals.py next .`
- `git diff --check`
- `git show --format= --check agent/wing/t_d83a3347`

The canonical cycle passes and validation prints `ok`. Offline checks resolve
773 local links/anchors across 19 core/affected documents, excluding 34 optional
local-artifact links. Goal-source paths, live-body coverage, the met rule and
archive conservation pass. System PyYAML parses OpenAPI 3.1.0 with 20 paths.
This is syntax, not schema or runtime proof. A repeated canonical cycle checks
byte stability of TODO, goals and archive.

Mechanical review checks scoped Markdown, punctuation, short sentence structure
and protected identifiers. Language/meaning review applies the STE-inspired profile
to changed prose. It preserves fake versus real storage, frozen versus later source,
persistence versus readiness and qualification versus delivery. Full ASD-STE100
dictionary compliance is not verified. Repository checks are separate from language
review. Product tests, builds, installs, native launches, live/network requests,
physical devices, API standards/runtime conformance and releases are not run in
this documentation pass.

## Saved connection feedback accessibility follow-through

The following completed task body is preserved verbatim from TODO.md. Its
unchecked box and in-progress wording are historical; goals.json and the retained
[feedback receipt](docs/quality/saved-endpoint-feedback-accessibility.md) establish
the completed bounded slice. This archive does not queue work.

- [ ] **M1-SAVED-ENDPOINT-FEEDBACK-ACCESSIBILITY** — Goal: M1. Qualify readable
  saved-connection Test/Save feedback at compact width and 200% text.
  Payoff: keyboard users can read failure and retry guidance, not only reach actions.
  Sources: [real-storage evidence and visual limits](docs/quality/saved-endpoint-storage-native.md#visual-limits-and-remaining-work),
  [CONN-5](docs/product/prd.md#connection-path-requirements) and
  [connection verification](docs/test-plan.md#connection-path-verification).
  Scope: public saved-row editor, existing localized Test/Save guidance and focused
  widget/native regressions. Preserve production store ownership and inherited
  harnesses; use isolated state. Exclude live inference, managed SSH, OAuth,
  Agent mutation, personal app/keyring state and new management authority.
  Acceptance: compact/wide and 100/200% text allow keyboard users to reveal and
  read complete Test/Save denial and retry feedback without clipped guidance.
  Explicit retry succeeds only for the initiating saved row. Cancel, delayed
  settlement and owner replacement cannot emit obsolete feedback or change the
  active conversation. Record actual renders, exact checks and source binding;
  distinguish driver keys from physical input and persistence from readiness.
  Dependencies: M1-SAVED-ENDPOINT-REAL-STORAGE (done). Section: Now.
  Ownership: ledger in_progress; preserve the existing worker. Do not redispatch.

### Documentation checks and remaining outcome

Bootstrap + Maintain starts from changed agent branches at unchanged HEAD
`b9eb5b3d9f6f3a433dd36cb6271ad8ec769b2319`; the newest inspected branch is
`agent/wing/t_263cb8bd` at `9f84b77197a83f4fc08a61ee3251c5456f380533`.
The monitor lists zero drift findings. Existing dirty code, staged changes and
BLOCKERS entries are preserved. No new owner question arises.

Spec, test plan, parity guidance, getting-started instructions, docs navigation
and Unreleased history now expose the delivered readable feedback correction.
Retained logs confirm 33 focused Dart tests, four tooling tests, clean analysis
and four Linux GTK fixture journeys. All 778 source fingerprints match the
inspected tree; the retained source archive digest matches. This pass reruns no
product checks and does not establish independent review or main delivery.

Core-role map: README (`README.md`), PRD (`docs/product/prd.md`) and living ADRs
(`docs/adr/README.md` and five decisions) are unchanged_verified for inspected
intent, ownership and support boundaries. Spec (`docs/spec.md`), verification
(`docs/test-plan.md`), local operations (`docs/getting-started.md`) and history
(`CHANGELOG.md`) are maintained. Owned HTTP API (`docs/api/wing-link.openapi.yaml`)
is unchanged_verified for manual code-first ownership and YAML syntax only.
Setup/release runbooks retain their scope and recovery limits. All applicable
core owners exist; none needs creation. Full API conformance remains unverified.

TODO removes the already-done M1-SAVED-ENDPOINT-FEEDBACK-ACCESSIBILITY body.
Its exact bytes and multiplicity are preserved above, after the unchanged archive
prefix. All 68 unrelated unchecked bodies and continuations remain unchanged.
TODO also adds the missing full entry for existing in-progress
M1-NATIVE-APPROVAL-RESTORATION; no ledger task is added, closed or duplicated.
All 69 unfinished ledger tasks now have matching live bodies. Every non-met goal
retains at least two unfinished slices. Ledger focus remains M1: 35 goals and
164 tasks, with two met, 17 partial, nine unmet and seven unverified. Existing
passing evidence is retained; this documentation pass promotes no product goal.

Executed commands: `python <home>/.hermes/shared-skills/repo-docs/scripts/goals.py fmt .`
→ `validate .` → `render .`, with validation printing `ok`, and `git diff --check`.
A repeated cycle preserves TODO/goals/archive bytes. Offline checks resolve 754
local links and 159 Markdown anchors across inspected owners and current evidence.
Goal-source paths resolve. Installed system Python parses OpenAPI 3.1.0 YAML
with 20 paths; this is syntax, not schema or runtime conformance.
`goals.py next .` selects M1-NATIVE-APPROVAL-RESTORATION, already in_progress.
Do not redispatch it or the already-owned PARITY-LIVE-WORKFLOW. The first listed
open fallback is PARITY-MAESTRO-ANDROID-DEVICE; selection still requires tracker
ownership and milestone eligibility checks. No worker or card is changed.

Mechanical review checks changed prose, punctuation and protected literals.
Language/meaning review applies the STE-inspired profile and preserves synthetic
versus live, source-bound versus current, and qualification versus delivery limits.
Full ASD-STE100 dictionary compliance is not verified. Repository checks run
offline on Linux. Product tests, builds, device actions, live authentication,
physical input, screen readers and release operations are not run. Later editor
real-storage qualification and the integrated live M1 journey remain gaps.

## Native transcript approval follow-through — 2026-10-08

The following exact TODO body is historical. Its unchecked checkbox and former
in_progress wording are preserved, not current ownership. The current ledger
marks M1-NATIVE-APPROVAL-RESTORATION done. Retained source-bound GTK logs and
[the delivery receipt](docs/quality/native-transcript-recovery.md) establish its
synthetic reconnect/approval slice, not live M1 acceptance or main delivery.

- [ ] **M1-NATIVE-APPROVAL-RESTORATION** — Goal: M1. Qualify native keyboard
  approval and recovered transcript ownership without replay.
  Payoff: restore an exact conversation and operate only its current approval.
  Sources: [leading acceptance outcome](docs/product/prd.md#leading-acceptance-outcome),
  [daily workflow](docs/plans/2026-10-03-desktop-daily-workflow.md) and
  [native restoration verification](docs/test-plan.md#native-relaunch-and-canonical-transcript-recovery).
  Scope: production Chat approval/transcript recovery and focused Linux GTK fixture
  qualification; preserve Agent authority, profile/session isolation and existing
  harnesses. Exclude live inference, personal state, Agent modifications and new APIs.
  Acceptance: native keyboard controls reveal the recovered transcript and current
  approval for the exact owner. Cancel, delayed settlement and owner replacement
  reject obsolete approval results. Restoration adds no send, creation or approval
  replay. Record exact executed checks, source binding and mutation counters;
  distinguish synthetic input from live generation and physical input.
  Dependencies: none in the ledger. Section: Now.
  Ownership: ledger in_progress; preserve the existing worker. Do not redispatch.


### Documentation reconciliation receipt

Mode: Bootstrap + Maintain, starting from the changed agent-branch digest at
unchanged shared HEAD `b9eb5b3d9f6f3a433dd36cb6271ad8ec769b2319`.
The inspected branch is `agent/wing/t_912b8858`, commit
`fcff3d30f0ce97c95e16f6048d01ed139c7498c5`. Monitor path drift is zero.
The branch delivers six additive qualification files, not a production repair.
Existing dirty source, staged changes and owner questions remain intact.

Spec, test plan, parity/UI-gap summaries, navigation and the existing Unreleased
accessibility entry now expose the bounded native subset. Retained final logs
confirm four tooling passes, 15 focused passes, clean analysis and one Linux GTK
test containing four width/text-scale cases. Native request receipts record five
deliberate setup sends, five decision attempts and 23 reads per case, with zero
creates/Stops and zero recovery mutations. Failed decision attempts are counted.
The source archive and manifest SHA-256 values match the delivery report. All 783
archived execution inputs match both the manifest and this inspected worktree.
These are inspected executor results, not new product execution, independent
review approval, standalone-branch qualification or protected-main delivery.
No screenshot or physical-input verdict is added by this documentation pass.

Core-role coverage:
- Orientation: `README.md`, unchanged_verified for inspected setup and direct/optional
  connection boundaries; `docs/README.md`, maintained for evidence navigation.
- Requirements: `docs/product/prd.md`, unchanged_verified for Desktop-first intent,
  real-generation acceptance, exact capabilities and qualification limits.
- Decisions: `docs/adr/README.md` and its five living records, unchanged_verified
  for authority, isolation and accessibility boundaries. No new decision is needed.
- Design: `docs/spec.md`, maintained for native reconnect/approval evidence and limits.
- Owned HTTP API: `docs/api/wing-link.openapi.yaml`, unchanged_verified for manual
  code-first ownership. YAML syntax passes for OpenAPI 3.1.0 with 20 paths;
  standards/schema and runtime conformance are not executed.
- Verification: `docs/test-plan.md`, maintained for observable native scenarios,
  inspected logs, source binding and separate process-restart/live acceptance.
- Operations: `docs/getting-started.md`, `docs/runbooks/android-hermes-setup.md`
  and `docs/runbooks/release-alpha.md`, unchanged_verified for inspected prerequisites,
  direct versus optional management and operation/recovery limits. No operation runs.
- History: `CHANGELOG.md`, maintained to qualify an existing Unreleased accessibility
  entry with native subset evidence, not a new feature or released version.
All applicable core owners exist; none needs creation. No new owner question arises.
Existing BLOCKERS entries/defaults remain unchanged, not newly resolved.

Root `TODO.md` removes the already-done M1-NATIVE-APPROVAL-RESTORATION body.
Its exact bytes and multiplicity are preserved above, after the unchanged archive
prefix. All 67 unrelated live bodies and continuations remain unchanged.
VERIFY-CHAT-TRANSCRIPT-NATIVE keeps its open status and adds the completed overlapping
subset as evidence to avoid duplicate work. The broader task is not closed.
TODO adds the missing full entry for existing in-progress M1-NATIVE-STOP-RECOVERY.
No ledger task is added, closed or claimed. All 69 unfinished ledger tasks have
live bodies. `goals.json` stays byte-identical and retains focus M1: 35 goals and
165 tasks; two met, 17 partial, nine unmet and seven unverified. All 33 non-met
goals retain at least two unfinished slices. Both met goals retain executed
passing evidence; documentation inspection promotes no product goal.

Executed offline commands: `python <home>/.hermes/shared-skills/repo-docs/scripts/goals.py fmt .`
→ `validate .` → `render .`, with validation printing `ok`, and `git diff --check`.
`git show --format= --check agent/wing/t_912b8858` also passes. Local checks resolve
782 links and 160 Markdown anchors across 20 inspected core/affected owners;
26 optional local-artifact links are excluded from availability checks, not receipt
inspection. Goal-source paths, met evidence, two-slice coverage, task status and
archive conservation pass. A repeated canonical cycle preserves TODO/goals/archive
bytes. `goals.py next .` selects M1-NATIVE-STOP-RECOVERY, already in_progress.
It is not an unclaimed task or permission to redispatch. Broader transcript-native
qualification remains an open bounded slice; check current tracker ownership.
No worker, card, schedule, install, source or test change is made here.

Mechanical review checks scoped Markdown, punctuation, short added sentences and
protected identifiers. Language/meaning review applies the STE-inspired profile
and preserves failed attempts versus acknowledgments, synthetic versus live,
reconnect versus process restart, and qualification versus delivery. Full ASD-STE100
dictionary compliance is not verified. Repository checks run offline on Linux.
Product tests/builds, native launches, network calls, device actions, screen readers,
physical input, live authentication/inference and release procedures are not run.
Process restart, broader native transcript acceptance and the live M1 journey
remain gaps. No owner question needs adding in this pass.

## Native keyboard Stop follow-through — 2026-10-08

### Completed task body

The following body is preserved verbatim from TODO.md. Its unchecked box and
in-progress wording are historical. The ledger already marks the task done,
and the final Linux GTK receipt confirms its bounded synthetic acceptance.

- [ ] **M1-NATIVE-STOP-RECOVERY** — Goal: M1. Qualify keyboard Stop failure
  and authoritative recovery in native Linux without replay.
  Payoff: keep the exact run usable when Stop fails or its owner changes.
  Sources: [leading acceptance](docs/product/prd.md#leading-acceptance-outcome),
  [daily workflow](docs/plans/2026-10-03-desktop-daily-workflow.md) and
  [native approval predecessor](docs/quality/native-transcript-recovery.md).
  Scope: production Chat/channel Stop and isolated Linux GTK fixture qualification;
  repair reproduced Wing defects with nearest regressions. Exclude live inference,
  Agent changes, personal state, new APIs, system installation and release.
  Acceptance: keyboard Stop addresses only the exact current run. Failed or
  uncertain settlement permits explicit reconciliation/retry, never automatic
  mutation replay. Delayed old-owner results cannot stop or overwrite replacement
  state. Record canonical terminal readback, exact requests, source binding and
  owned-process teardown. Distinguish fixture input from live or physical use.
  Dependencies: none in the ledger. Section: Now.
  Ownership: ledger in_progress; preserve the existing worker. Do not redispatch.

### Maintenance receipt

Mode: Bootstrap + Maintain. The monitor changed the agent-branch digest at
unchanged HEAD `b9eb5b3d9f6f3a433dd36cb6271ad8ec769b2319`, with zero listed drift.
The completed branch `agent/wing/t_a7ab04dd` at `73335a1e` supplies the trigger.
Existing staged/dirty source, documentation and BLOCKERS edits are preserved.

The final [Stop receipt](docs/quality/native-stop-recovery.md) supersedes its
historical failed harness attempts. Retained verification and terminal logs
confirm five tooling tests, 335 focused Flutter tests, clean analysis and one
Linux GTK target containing four compact/wide, 100/200% text cases. Each case
records 68 reads, four explicit submissions, three deliberate Stop attempts,
zero session creates, zero approval decisions and zero recovery mutations.
Archive and source-manifest digests match. All 788 executed source hashes match
both the manifest and this inspected tree. This is inspected executor evidence,
not a new product run, independent review approval or protected-main delivery.

Core-role coverage:
- Orientation: `README.md`, unchanged_verified for setup and direct/optional
  connection boundaries; `docs/README.md`, maintained for Stop evidence navigation.
- Requirements: `docs/product/prd.md`, unchanged_verified for Desktop-first intent,
  live-generation acceptance and exact-capability/qualification limits.
- Decisions: `docs/adr/README.md` and its five living records, unchanged_verified
  for Agent authority, isolation, accessibility and delivery boundaries.
- Design: `docs/spec.md`, maintained for uncertain/failed Stop ownership and recovery.
- Owned HTTP API: `docs/api/wing-link.openapi.yaml`, unchanged_verified for manual
  code-first ownership. YAML syntax passes for OpenAPI 3.1.0 with 20 paths.
  Standards/schema and runtime conformance are not executed.
- Verification: `docs/test-plan.md`, maintained for observable native Stop scenarios,
  inspected logs, source binding and separate live/relaunch acceptance.
- Operations: `docs/getting-started.md`, `docs/runbooks/android-hermes-setup.md`
  and `docs/runbooks/release-alpha.md`, unchanged_verified for inspected prerequisites
  and recovery limits. No setup, release or service operation runs.
- History: `CHANGELOG.md`, unchanged_verified. No new runtime feature or release
  is implemented by this pass, so no routine documentation entry is added.
All applicable core owners exist; none needs creation. Existing BLOCKERS questions
and defaults remain unchanged. No new owner question arises.

Root `TODO.md` archives the stale unchecked M1-NATIVE-STOP-RECOVERY body after
inspecting its existing done ledger state and passing final receipt. Its exact
bytes and multiplicity are preserved above, after the unchanged archive prefix.
All 68 other live task bodies and continuations remain unchanged. No task is
added, claimed or closed. Root `goals.json` retains focus M1: 35 goals and 165
tasks; two met, 17 partial, nine unmet and seven unverified. All 33 non-met goals
retain at least two unfinished slices. Both met goals retain executed passing
evidence. Concurrent independent-review evidence additions are preserved, not
promoted here to review approval or product qualification.

Executed repository checks:
- `python <home>/.hermes/shared-skills/repo-docs/scripts/goals.py fmt <repo>`, then `validate` and `render` with the same absolute repository path: all print `ok`.
- `goals.py next` with that absolute path: PARITY-LIVE-WORKFLOW, already in_progress.
  Preserve its ownership. Supported QA authentication and provider-call admission
  remain prerequisites; the dependent VERIFY-LIVE-WORKFLOW-RECOVERY stays queued.
- `git diff --check` and `git show --format= --check agent/wing/t_a7ab04dd`: pass.
- Offline checks across 20 inspected core/affected owners: 1,049 local paths and
  275 Markdown anchors pass. Sixty-three optional local-artifact links are excluded
  from shipped-dependency availability checks, not from receipt inspection.
- Goal sources, met evidence, two-slice coverage, live task status, exact archive
  conservation and repeated canonical-cycle byte stability pass.

Mechanical review checks scoped Markdown, punctuation and protected identifiers.
Language/meaning review applies the STE-inspired profile. It preserves failed
attempts versus acknowledgment, synthetic versus live, recovery versus process
relaunch, and qualification versus delivery. Full ASD-STE100 dictionary compliance
is not verified. Repository checks run offline on Linux. Product tests/builds,
native launches, network calls, devices, physical input, screen readers, live
inference, API standards/runtime conformance and release procedures are not run.
Live authentication/generation, real tools/Stop, integrated process-relaunch
recovery and protected-main delivery remain open. No worker or schedule is started.

## Native status accessibility follow-through — 2026-10-08

Mode: Bootstrap + Maintain; Wing documentation, TODO and goals only. The changed
agent-branch digest points to `agent/wing/t_4a9f2ee8` at
`b832870d6205acede576c1427424fff3abc26be0`. Shared HEAD remains
`b9eb5b3d9f6f3a433dd36cb6271ad8ec769b2319`; monitor path drift is zero.
Existing dirty source, staged changes, owner questions and task ownership remain
intact. No source/test, card, schedule or upstream changes occur in this pass.

Design, verification, navigation and Unreleased history now expose the
[native status repair](docs/quality/native-status-accessibility.md). Desktop fields
support keyboard expansion into complete labeled values. Compact More uses the
same wrapping widget and follows current-channel changes while open. Redaction
precedes display and semantics. Recovery does not present cached identity as
current. Inspection adds no domain operation.

Retained `build/t_4a9f2ee8/evidence/attempt-yvyh4r9l/verification.json` and logs
confirm clean analysis, 25 focused widget passes and one GTK test containing four
journeys at 390/1280 logical widths and 100/200% text. All five phases appear in
each journey. All seven mutation counters remain zero. Source archive and manifest
digests match the report; all 794 archived inputs match executed fingerprints and
this inspected tree. These are inspected executor results, not new product runs,
independent approval, physical input, live authentication or main delivery.

Core-role coverage:
- Orientation: `README.md`, unchanged_verified for direct setup and optional Wing
  Link boundaries; `docs/README.md`, maintained for status evidence navigation.
- Requirements: `docs/product/prd.md`, unchanged_verified for accepted Desktop-first
  intent, live daily-use acceptance and explicit platform limits.
- Decisions: `docs/adr/README.md` and relevant living records, unchanged_verified
  for authority/accessibility boundaries. No new decision or historical rewrite.
- Design: `docs/spec.md`, maintained for keyboard status and current-owner More.
- Owned HTTP API: `docs/api/wing-link.openapi.yaml`, unchanged_verified for manual
  code-first ownership and management-plane separation. No API change. Standards
  validation and runtime conformance are not executed.
- Verification: `docs/test-plan.md`, maintained for observable status scenarios,
  retained results, source binding and remaining live/platform gaps.
- Operations: `docs/getting-started.md`, `docs/runbooks/android-hermes-setup.md`
  and `docs/runbooks/release-alpha.md`, unchanged_verified for inspected setup,
  recovery and release limits. No operational procedure is executed.
- History: `CHANGELOG.md`, maintained for the implemented Unreleased status repair,
  not a published release or protected-main delivery.
All applicable core owners exist; no missing owner needs creation. Existing
BLOCKERS questions and defaults remain unchanged. No new owner question arises.

Root `TODO.md` adds the missing full entry for the already-registered
M1-NATIVE-INTEGRATED-RESTART. It retains `in_progress` ownership and excludes live
inference. No task is added to or closed in `goals.json`; M1-STATUS-ACCESSIBILITY
was already done and had no stale live body to move. All 68 existing live task
bodies and continuations remain unchanged. The archive is append-only; its earlier
prefix bytes remain unchanged. No task block is moved or reconstructed as an
original historical body.

Root `goals.json` retains focus M1: 35 goals and 167 tasks; two met, 17 partial,
nine unmet and seven unverified. All 33 non-met goals retain at least two unfinished
slices. Both met goals retain executed passing evidence. All 69 unfinished ledger
tasks now have full live entries. The helper's first candidate is
M1-NATIVE-INTEGRATED-RESTART, already in_progress; preserve its ownership.
PARITY-LIVE-WORKFLOW is also owned and retains its separate QA-authentication and
provider-call-admission limits. This receipt does not dispatch either task.

Executed repository checks:
- `python <home>/.hermes/shared-skills/repo-docs/scripts/goals.py fmt <repo>`, then `validate` and `render` with the same absolute path: all print `ok`.
- `python <home>/.hermes/shared-skills/repo-docs/scripts/goals.py next <repo> --json`: selects the integrated restart first, already in_progress.
- `git diff --check` and `git show --format= --check agent/wing/t_4a9f2ee8`: pass.
- Offline link checks across 20 core/affected owners resolve 670 local targets and
  154 Markdown anchors. Twenty-six optional local-artifact links are excluded
  from shipped-dependency availability checks, not receipt inspection.
- Goal-source paths, met evidence, two-slice coverage, full live-task coverage,
  append-only archive preservation and repeated canonical-cycle byte stability pass.

Mechanical review checks changed Markdown, punctuation and protected identifiers.
Language/meaning review applies the STE-inspired profile to changed prose. It
preserves keyboard versus physical input, fixture versus live, current versus
cached identity and qualification versus delivery. Full ASD-STE100 dictionary
compliance is not verified. Repository checks run offline on Linux. Product
suites/builds, native launches, network requests, devices, screen readers, live
inference, API standards/runtime conformance and release actions are not run.
The combined restart and live daily-use milestones remain unfinished; standalone
status qualification does not complete them.

## Integrated native restart completed task — 2026-10-08

The following body is preserved verbatim from TODO.md. Its unchecked box and
in_progress wording are historical: the ledger now records this slice done.
See [the executed fixture receipt](docs/quality/native-integrated-daily-restart.md).
Live M1 acceptance remains partial.

- [ ] **M1-NATIVE-INTEGRATED-RESTART** — Goal: M1. Qualify one credential-free
  native approval, Stop and exact-session restart workflow. Payoff: prove the
  combined recovery sequence instead of repeating isolated control checks.
  Sources: [daily-use acceptance](docs/product/prd.md#leading-acceptance-outcome),
  [native approval recovery](docs/quality/native-transcript-recovery.md),
  [native Stop recovery](docs/quality/native-stop-recovery.md) and
  [status accessibility](docs/quality/native-status-accessibility.md).
  Scope: existing production Wing shell/channel and isolated synthetic Agent
  fixtures; repair reproduced Wing defects with regression tests. Preserve personal
  runtime, credentials and application storage. No live inference, upstream edits,
  service changes or release actions.
  Acceptance: execute one Linux GTK sequence with correlated approval, authoritative
  Stop outcome, two distinct processes, exact restored owner/history and one deliberate
  resumed send. Explicitly reselect the model where authoritative pair restoration
  is unsupported. Prove zero restart/recovery mutations and retain source-bound
  command results and counters. Fixtures do not satisfy live-generation acceptance.
  Dependencies: no ledger predecessor; reuse completed native evidence rather than
  reopening it. Ownership: already `in_progress` in goals; consult continuation
  ownership before work and do not dispatch a duplicate.

## Integrated native restart follow-through — 2026-10-08

Mode: Bootstrap + Maintain; documentation, TODO and goals only. The changed
agent-branch digest points to `agent/wing/t_e168b601` at
`4f0c12ada2f9d5cf450fc5cd6bd47172784bef40`. Shared HEAD remains
`b9eb5b3d9f6f3a433dd36cb6271ad8ec769b2319`; monitor drift is zero.
Existing dirty source, staged changes, concurrent backlog entries and BLOCKERS
questions remain intact. No source/test, card, schedule or upstream edits occur.

Design, verification, parity, daily-use planning, workflow policy and navigation
now expose the [integrated restart receipt](docs/quality/native-integrated-daily-restart.md).
The production router/shell and HTTP/SSE channel pass synthetic compact/wide GTK
sequences with correlated approval, uncertain Stop, canonical recovery and two
processes per width. Both widths use 200% text and reduced motion. Restart and
route return add no mutations. One resumed send follows deliberate model reselection.
Router navigation and helper scrolling mean this is not an entirely keyboard-only
journey. Fixture execution does not establish live authentication or inference.

Retained `build/t_e168b601/evidence/attempt-a6jtfh8g/verification.json` and terminal
logs confirm five tooling tests, 376 targeted Flutter passes, clean analysis and
four passing native invocations. All six branch files match the inspected tree.
Source archive and manifest digests match the report. All 1,296 executed input
hashes match the archived bytes; before maintenance, eight documentation inputs
already differed from the current tree. These are inspected executor results,
not tests rerun here, independent approval or whole-current-tree qualification.
The removed native executable cannot be independently rehashed in this pass.

Core-role coverage:
- Orientation: `README.md`, unchanged_verified for direct setup and optional
  management boundaries; `docs/README.md`, maintained for evidence navigation.
- Requirements: `docs/product/prd.md`, unchanged_verified for accepted intent and
  live daily-use acceptance. Synthetic qualification does not close that requirement.
- Decisions: `docs/adr/README.md` and relevant living records, unchanged_verified
  for authority, accessibility and delivery boundaries. No new architectural choice.
- Design: `docs/spec.md`, maintained for the combined bounded native evidence.
- Owned HTTP API: `docs/api/wing-link.openapi.yaml`, unchanged_verified for manual
  code-first ownership; YAML syntax passes, not standards or runtime conformance.
- Verification: `docs/test-plan.md`, maintained for observable combined recovery
  outcomes, retained execution, source limits and remaining live/platform gaps.
- Operations: `docs/getting-started.md`, `docs/runbooks/android-hermes-setup.md`,
  `docs/runbooks/desktop-feature-qualification.md` and `docs/runbooks/release-alpha.md`,
  unchanged_verified for inspected setup, target prerequisites and recovery limits.
- History: `CHANGELOG.md`, unchanged_verified. This qualification-only slice adds
  no production behavior or published release and needs no documentation-churn entry.
All applicable core owners exist; none needs creation. Existing owner questions
and defaults remain unchanged. No new owner question is needed.

Root `TODO.md` removes the stale unchecked M1-NATIVE-INTEGRATED-RESTART body
only after appending it verbatim to `todo.archive.md`. Its checkbox/ownership text
is explicitly historical. Exact block multiplicity and all previous archive bytes
are preserved. All 70 unrelated open task bodies and continuations remain unchanged.
Root `goals.json` is helper-maintained and byte-identical: 35 goals, 169 tasks;
two met, 17 partial, nine unmet and seven unverified. All 33 non-met goals retain
at least two unfinished slices. All 70 unfinished tasks have full live entries.
Both met goals retain executed passing evidence. No task is added, closed or
claimed here; the integrated restart task was already done. Focus remains M1.
The next helper candidate is PARITY-LIVE-WORKFLOW, already in_progress; preserve
its ownership. VERIFY-LIVE-WORKFLOW-RECOVERY remains its ordered queued successor.
QA authentication and provider-call admission remain separate live prerequisites.
No worker is started, and no protected-main delivery is inferred.

Executed repository checks:
- `python3 <home>/.hermes/shared-skills/repo-docs/scripts/goals.py fmt <repo>`, then `validate` and `render` with the same absolute path: each prints `ok`.
- `python3 <home>/.hermes/shared-skills/repo-docs/scripts/goals.py next <repo>`: selects PARITY-LIVE-WORKFLOW.
- `git diff --check` and `git show --format= --check agent/wing/t_e168b601`: pass.
- Offline checks across 20 core/affected owners resolve 824 local targets and
  168 Markdown anchors. Twenty-six optional local-artifact links are excluded
  from shipped-dependency availability checks, not receipt inspection.
- `/usr/bin/python3` with installed PyYAML parses OpenAPI 3.1.0 and 20 paths.
  This is syntax evidence only; no dependency is installed.
- Goal-source paths, met evidence, two-slice coverage, full live-task coverage,
  exact archive conservation and repeated canonical-cycle byte stability pass.

Mechanical review checks scoped Markdown, punctuation, line wrapping and protected
identifiers. Language/meaning review applies the STE-inspired profile to changed
prose, preserving fixture/live, acknowledgment/canonical recovery, explicit model
choice/authoritative pair restoration and qualification/delivery boundaries.
Full ASD-STE100 dictionary compliance is not verified. Repository checks run
offline on Linux. Product suites/builds, native launches, network calls, physical
input, screen readers, devices, live inference, API standards/runtime conformance
and release procedures are not run. Remaining milestone gaps are supported live
authentication/generation and enforceable call admission, authoritative model-pair
readback and protected-main delivery. Do not repeat the completed synthetic slice.

## Desktop-guided welcome follow-through — 2026-10-08

The task below was already done in goals.json. Its stale unchecked live entry
is preserved verbatim as historical wording, not queued work. Retained executor
logs confirm 41 widgets and four compiled Chromium journeys passed. Native/Android
recovery and protected-main delivery remain separate.

### Original P0 task body

- [ ] **PORT-DESKTOP-WELCOME** — Goal: CONNECTION-PATHS. Show Desktop-guided
  welcome before the connected shell. Payoff: replace the delivered profile/gateway
  empty state with the reference experience, not another Wing-specific chooser.
  Sources: [port-wide acceptance](docs/product/prd.md#port-wide-fidelity-acceptance),
  [welcome gap](docs/product/hermes-desktop-ui-gap.md#current-source-backed-gaps),
  [Desktop Welcome](docs/quality/official-desktop-reference.md#withdrawn-evidence)
  and [reference verification](docs/test-plan.md#reference-fidelity-verification).
  Scope: Flutter first-launch routing, empty-directory/enrollment presentation,
  shared styling, English localization and nearest widget/browser regressions.
  Reuse existing channel/storage and preserve concurrent connection-worker changes.
  Exclude managed SSH implementation, Agent edits, personal state, system installs
  and release actions. Unsupported local/native actions stay explicit.
  Acceptance: fresh isolated launch follows the reference hero, visual hierarchy,
  Get Started and SSH/Remote entry. Supported direct connect works without Wing Link
  requests, pairing or management credentials. Connected content and selected
  navigation agree. Pin the reference, exercise keyboard/compact/enlarged-text states,
  run affected Flutter checks and a freshly compiled browser journey, and retain
  reference/Wing captures with explicit deviations. Direct-entry receipts alone
  do not close this task. Dependencies: none. Section: Now. Ownership: unclaimed
  here; check live cards and exact file reservations before editing.


### Maintenance receipt

Mode: Bootstrap + Maintain; Wing documentation, TODO and goals only. The monitor
changed the agent-branch digest at unchanged HEAD
`b9eb5b3d9f6f3a433dd36cb6271ad8ec769b2319` with zero listed path drift.
The latest welcome branch is `agent/wing/t_9f4e6557` at `df5ff2ac`.
Its final follow-through makes the baseline-relative integration patch whitespace-clean;
it does not independently qualify a standalone branch or protected-main delivery.

README, getting-started steps, spec, route/parity/UI-gap summaries, test plan,
docs navigation and Unreleased history now describe the Desktop-guided welcome
in the development worktree instead of only the older Add Hermes chooser.
Fresh entry resolves secure saved ownership before exposing the shell. Get Started
opens Local; SSH still requires an external trusted tunnel. Optional setup remains
secondary. The supplied APK's earlier parity failure remains historical, not repaired.

Retained executor logs confirm clean analysis, 41 focused widgets and four compiled
Chromium journeys. This pass inspects those logs, not new product execution.
The candidate manifest has 569 inputs: 565 match the current tree; later changes
in `lib/app/wing_app.dart`, `lib/shared/widgets/app_shell.dart`,
`test/app/wing_app_connect_intent_test.dart` and `test/theme/wing_theme_test.dart`
prevent whole-current-tree qualification. Native/Android welcome recovery, actual
local setup/live authentication, managed SSH and main delivery remain open.

Core-role coverage:
- README: `README.md` — maintained for current development entry and evidence limits.
- PRD: `docs/product/prd.md` — unchanged_verified for accepted fidelity and connection requirements.
- ADRs: `docs/adr/README.md` and five living records — unchanged_verified for relevant boundaries; no new decision.
- Spec: `docs/spec.md` — maintained for the actual first-entry gate and welcome behavior.
- Owned HTTP API: `docs/api/wing-link.openapi.yaml` — unchanged_verified for manual code-first ownership; YAML syntax only, not full conformance.
- Test plan: `docs/test-plan.md` — maintained for retained checks, source differences and remaining native/Android proof.
- Runbooks: `docs/getting-started.md` — maintained for public welcome controls; `docs/runbooks/release-alpha.md` — unchanged_verified for inspected release prerequisites and limits.
- Changelog: `CHANGELOG.md` — maintained for implemented Unreleased welcome, not an invented release.

All applicable core owners exist; none needs creation. Existing BLOCKERS questions
and defaults are unchanged. This pass needs no new owner decision.

`TODO.md` removes the already-done PORT-DESKTOP-WELCOME body only after preserving
it verbatim above. PORT-DESKTOP-WELCOME-RECOVERY gains the predecessor's receipt,
retains its original acceptance and moves to Now through `goals.py section`.
No duplicate task is added or completed task reopened. All 68 other live task
blocks and continuations are unchanged. The existing archive bytes remain an exact
prefix, and the moved block occurs once. Root TODO links this root archive.

`goals.json` retains focus CONNECTION-PATHS and records inspection evidence only.
Coverage: 35 goals and 169 tasks; two met, 17 partial, nine unmet, seven unverified.
Each of the 33 non-met goals has at least two unfinished tasks. Both met goals
retain executed passing checks; no goal is promoted by this pass. The helper's
first candidate is in-progress CONNECTION-SAVED-WORKFLOWS; do not duplicate it.
The first open eligible slice is PORT-DESKTOP-WELCOME-RECOVERY. Eligibility is not
tracker ownership or worker execution. No worker is started.

Executed offline repository checks on Linux:
- `python <home>/.hermes/shared-skills/repo-docs/scripts/goals.py fmt <repo>`, then `validate` and `render` with that absolute path: pass; validation prints `ok`.
- `python <home>/.hermes/shared-skills/repo-docs/scripts/goals.py next <repo> --json`: separates the in-progress candidate from the first open recovery task.
- `python <home>/.hermes/profiles/wing/cache/scratch/repo-docs-welcome/check.py`: 840 local links and 170 anchors across 22 owners pass. Twenty-six optional local-artifact links are excluded from shipped-dependency availability checks.
- The same check verifies source paths, met evidence, two-slice coverage, all 69 live tasks, exact archive conservation, unrelated task preservation and unchanged BLOCKERS bytes.
- `/usr/bin/python3` with installed PyYAML parses OpenAPI 3.1.0 and 20 paths; syntax only, no dependency install.
- `git diff --check` and `git show --format= --check agent/wing/t_9f4e6557`: pass.
- A repeated fmt/validate/render cycle preserves TODO, goals and archive bytes.

Mechanical review checks changed Markdown, punctuation, line wrapping and protected
identifiers. Language/meaning review applies the STE-inspired profile to changed
prose. It preserves development/delivery, fixture/live, saved/connected and
external-tunnel/managed-SSH distinctions. Full ASD-STE100 dictionary compliance
is not verified. Repository checks do not establish native or Android runtime,
physical accessibility, live inference, complete API schema/runtime conformance
or release qualification. Product suites/builds, network calls, installs, devices,
release procedures, source/tests, cards and schedules are not run or changed here.

## Linux welcome recovery follow-through — 2026-10-08

The completed recovery task below moves from the live backlog. Its full body
is preserved verbatim. Linux fixture qualification does not close Android,
physical keychain, live authentication or protected-main delivery.

### Completed task body

- [x] **PORT-DESKTOP-WELCOME-RECOVERY** — Goal: CONNECTION-PATHS. Preserve the
  welcome-to-connected flow through cancellation, failure and saved-owner relaunch.
  Payoff: qualify the ported experience rather than only a static welcome image.
  Sources: [reference verification](docs/test-plan.md#reference-fidelity-verification)
  and [qualification procedure](docs/runbooks/desktop-feature-qualification.md#safety-and-prerequisites).
  Scope: predecessor's production route/UI, existing owner-fenced channel and
  isolated native Linux/Android fixture flows. Repair reproduced Wing defects with
  regression tests; preserve personal apps and runtime. No live inference, upstream
  edits, system installs, publication or personal credential use.
  Acceptance: Back/cancel and sanitized connection failure preserve the proper
  welcome state; deliberate Retry connects once. Saved-owner relaunch restores the
  correct screen/navigation without mutation replay. Exercise Linux and an authorized
  disposable Android target separately, identifying exact source/artifact and captures.
  Record unrun targets explicitly. Dependencies: PORT-DESKTOP-WELCOME (done). Section: Now.
  The predecessor is done with [widget/Chromium evidence](docs/quality/desktop-welcome.md).
  Linux GTK recovery and fresh-process restoration pass at the exact candidate in
  [the recovery receipt](docs/quality/desktop-welcome-recovery.md); Android is NOT_CHECKED
  (no authorized disposable ADB target). CONNECTION-PATHS remains partial for
  broader setup/auth, managed SSH, remaining platforms and protected-main delivery.
  Ownership: t_636ced72; implementation complete, native review handoff is final.

### Maintenance receipt

Mode: Bootstrap + Maintain; Wing documentation, TODO and goals only. The changed
agent-branch digest leads to `agent/wing/t_636ced72` at `65cdb368`, with unchanged
HEAD `b9eb5b3d9f6f3a433dd36cb6271ad8ec769b2319` and zero listed path drift.
The final branch commit makes its integration patch whitespace-clean. It does
not qualify a standalone branch or deliver the candidate to protected main.
Existing source, index, owner questions and unrelated task bodies are preserved.

README, design, verification, getting-started, parity/UI-gap summaries, navigation
and Unreleased history now describe completed Linux welcome recovery instead of
queuing it as wholly unqualified. The welcome-entry form's widget-order traversal
keeps keyboard Back reachable after scrolling enlarged fields. Public controls
support cancellation, sanitized denial and one deliberate retry. No Agent API,
Wing Link operation, accepted requirement or credential boundary changes.

Retained terminal logs confirm clean analysis, 34 focused widget passes, four
native write journeys, one separate-process restoration and four rebuilt Chromium
journeys. All 808 native inputs and 60 additional browser inputs match the current
source. This pass inspects retained results; it reruns no product test or app.
The endpoint store is synthetic, while contact/session preferences use isolated
Linux storage. Android, physical keychain, live authentication, screen readers,
whole-chat fidelity and main delivery remain unqualified. The prior supplied APK
failure remains historical, not repaired by this development candidate.

Core-role coverage:
- README: `README.md` — maintained for native welcome evidence and limits.
- PRD: `docs/product/prd.md` — unchanged_verified for accepted fidelity and direct-connection intent.
- ADRs: `docs/adr/README.md` and five living records — unchanged_verified for relevant authority/accessibility boundaries; no new decision.
- Spec: `docs/spec.md` — maintained for welcome-only focus behavior and fixture restoration limits.
- Owned HTTP API: `docs/api/wing-link.openapi.yaml` — unchanged_verified for manual code-first ownership; YAML syntax only, not schema/runtime conformance.
- Test plan: `docs/test-plan.md` — maintained for inspected native/browser results and remaining Android/physical/live checks.
- Runbooks: `docs/getting-started.md` — maintained for recovery evidence; `docs/runbooks/release-alpha.md` — unchanged_verified for inspected prerequisites and release limits.
- Changelog: `CHANGELOG.md` — maintained for the implemented Unreleased focus repair, not a fabricated release.

All applicable core owners exist; none needs creation. Root `BLOCKERS.md` remains
byte-identical. Existing owner questions/defaults remain authoritative; no new
question or privileged action is needed for this documentation correction.

Root `TODO.md` removes the already-done PORT-DESKTOP-WELCOME-RECOVERY body only
after appending it verbatim above. PARITY-MAESTRO-ANDROID-DEVICE gains explicit
welcome cancellation, denial, retry and exact-artifact relaunch acceptance. This
reuses the existing Android task, not a duplicate or a new device authorization.
All 67 unrelated live task bodies and continuations remain unchanged. Archive
prefix bytes and exact moved-block multiplicity are preserved. Root TODO links
this archive. The archive never queues work.

Root `goals.json` remains helper-maintained. A concurrent writer adds two passing
CONNECTION-PATHS command references for the same retained native run and branch
whitespace check. Existing evidence is preserved; this pass does not claim those
commands as its own product execution. Coverage: 35 goals, 169 tasks; two met,
17 partial, nine unmet and seven unverified. All 33 non-met
goals retain at least two unfinished tasks; all 68 unfinished tasks have full live
entries. Both met goals retain executed passing evidence. No task is added,
claimed or closed by this pass, and no goal is promoted from receipt inspection.
Focus remains CONNECTION-PATHS. The first helper candidate is in-progress
CONNECTION-SAVED-WORKFLOWS; preserve its ownership. The first eligible open slice
is CONNECTION-SETUP-AUTH-MATRIX. Eligibility is not dispatch, review or delivery.

Executed offline repository checks on Linux:
- `python ~/.hermes/shared-skills/repo-docs/scripts/goals.py fmt <repo>`, then `validate` and `render` with that absolute path: pass; validation prints `ok`.
- `python ~/.hermes/shared-skills/repo-docs/scripts/goals.py next <repo> --json`: separates in-progress work from the first eligible open matrix slice.
- `python <home>/.hermes/profiles/wing/cache/scratch/repo-docs-welcome-recovery/check.py`: 848 local links and 168 anchors across 23 owners pass. Twenty-six optional local-artifact links are excluded from shipped-dependency availability checks.
- The same check verifies goal-source paths, met evidence, two-slice coverage, all 68 live tasks, archive prefix/multiplicity, 67 unrelated task bodies and unchanged BLOCKERS bytes.
- `/usr/bin/python3` with installed PyYAML parses OpenAPI 3.1.0 and 20 paths. This is syntax only; no dependency is installed.
- `git diff --check` and `git show --format= --check agent/wing/t_636ced72`: pass.
- A repeated fmt/validate/render cycle preserves TODO, goals and archive bytes.

Mechanical review checks changed Markdown, punctuation, line wrapping and protected
identifiers. Language/meaning review applies the STE-inspired profile to changed
prose, preserving fixture/live, synthetic endpoint/physical keychain, retained
execution/new execution and qualification/delivery distinctions. Full ASD-STE100
dictionary compliance is not verified. Product suites/builds, native launches,
network calls, devices, API standards/runtime conformance, installs and release
procedures are not run. No source/test, upstream, card, worker or schedule changes.

## Two-host recovery completion follow-through — 2026-10-08

The ledger marks CONNECTION-TWO-HOST-RECOVERY done. Retained terminal logs
confirm four Linux GTK fixture journeys, 86 ownership widget passes and six
Chromium regressions. This pass inspects receipts, not new product execution.
The original live task below preserves its former checkbox and ownership wording
as history, not an unfinished task or current lease.

- [ ] CONNECTION-TWO-HOST-RECOVERY — Preserve the selected saved host when profile/session IDs collide.
  Goal: CONNECTION-PATHS. Section: Next. Status: in_progress.
  Scope: production saved-host selection and explicit retry, with isolated Linux
  fixture and nearest owner-fencing regressions. Exclude managed SSH, live
  authentication, inference and personal runtime changes.
  Acceptance: delayed old-host success/failure cannot replace the selected host
  or draft. Deliberate retry restores exact owner-bound history without mutation
  replay. Exercise keyboard controls in compact and wide native Linux layouts.
  Sources: [connection requirements](docs/product/desktop-connection-paths.md);
  [native qualification receipt](docs/quality/two-host-recovery-native.md).
  Dependencies: none in the ledger. Ownership: existing card `t_e40e9669`;
  preserve its lease and read the tracker before any handoff. This index entry
  restores the existing ledger task body, not a new task or completion claim.


Mode: Bootstrap + Maintain. Scope: Wing documentation, TODO and helper-managed
goals only. The monitor changed the agent-branch digest at unchanged HEAD
`b9eb5b3d9f6f3a433dd36cb6271ad8ec769b2319`, with zero listed drift.
The inspected completion is `agent/wing/t_e40e9669` at `f4accbd4`.
Existing source/test, staged changes, ownership and BLOCKERS entries are preserved.

Core-role coverage:
- README: `README.md`, unchanged_verified for orientation and supported setup.
- PRD: `docs/product/prd.md`, unchanged_verified for accepted intent and CONN-1–6.
- ADR: `docs/adr/README.md` and five living decisions, unchanged_verified for boundaries and current status. No new decision is needed.
- Spec: `docs/spec.md`, maintained for owner-bound saved selection and explicit recovery.
- Owned HTTP API: `docs/api/wing-link.openapi.yaml`, unchanged_verified for manual code-first ownership. Wing consumes Agent APIs, not a competing Agent schema.
- Test plan: `docs/test-plan.md`, maintained for executed frozen-candidate qualification and later input differences.
- Runbook: `docs/getting-started.md`, `docs/runbooks/android-hermes-setup.md` and `docs/runbooks/release-alpha.md`, unchanged_verified for inspected prerequisites and recovery limits. The existing two-host report owns reproduction.
- Changelog: `CHANGELOG.md`, maintained for the implemented network-error recovery correction, not a release claim.

All applicable core owners already exist. Navigation in `docs/README.md` and
`docs/quality/repo-docs-goal-bootstrap.md` now links the completion. No new owner
question is needed. Existing authentication/device/risk questions and defaults
remain in BLOCKERS; this pass does not re-evaluate privileged access.

The retained final verification receipt is
`.task-evidence/t_e40e9669/attempt-h_ds5dpw/verification.json`.
Terminal summaries confirm one dedicated widget pass, 86 combined widget passes,
four GTK fixture journeys, clean analysis and six Chromium passes. Receipt
metadata records ten successful checks and teardown, not new execution here.
The source archive digest matches. All four dedicated Dart inputs match; 867 of
878 recorded inputs match the inspected tree. Eleven later source/test/localization,
dependency and report inputs differ. This receipt cannot qualify the whole current
worktree, managed SSH, live authentication, physical input or main delivery.

`TODO.md` removes only the stale completed CONNECTION-TWO-HOST-RECOVERY body.
Its exact bytes occur once more in the append-only archive; all 68 unrelated live
task bodies and continuations remain unchanged. No task is added, closed, claimed
or dispatched. `goals.json` already records completion and passing executed evidence;
helper maintenance preserves its status and CONNECTION-PATHS focus. Coverage:
35 goals, 170 tasks; two met, 17 partial, nine unmet and seven unverified.
Every non-met goal retains at least two unfinished tasks; all 68 unfinished tasks
have full live entries. The first helper candidate is in-progress
CONNECTION-SAVED-WORKFLOWS. The first eligible open slice is
CONNECTION-SETUP-AUTH-MATRIX. Eligibility is not worker dispatch or delivery.

Executed offline checks on Linux:
- `python ~/.hermes/shared-skills/repo-docs/scripts/goals.py fmt <repo>`, then `validate` and `render` with that absolute path: pass; validation prints `ok`.
- `python ~/.hermes/shared-skills/repo-docs/scripts/goals.py next <repo> --json`: confirms focused in-progress work and the next open matrix slice.
- `python <home>/.hermes/profiles/wing/cache/scratch/repo-docs-two-host/check.py`: local links/anchors, goal-source paths, met evidence, two-slice coverage, live bodies, archive conservation and unchanged BLOCKERS pass. Final check: 915 local links and 173 anchors pass across 23 owners; 34 optional local-artifact links are excluded from shipped-dependency availability checks.
- `git diff --check`: pass. A second fmt/validate/render cycle preserves TODO, goals and archive bytes.

Mechanical review checks changed Markdown, punctuation, wrapping and protected
identifiers. Language/meaning review applies the STE-inspired profile to changed
prose. It preserves synthetic/live, frozen/current, retained/new execution and
qualification/delivery distinctions. Full ASD-STE100 dictionary compliance is not
verified. Product tests/builds, native launches, network requests, API standards
or runtime conformance, installs, releases and device actions are not run here.
No source/test, upstream, card, worker or schedule changes.

## Optional Local setup recovery follow-through — 2026-10-08

Bootstrap + Maintain starts from changed agent branches at unchanged HEAD
`b9eb5b3d9f6f3a433dd36cb6271ad8ec769b2319`, with zero monitor path drift.
Branch `agent/wing/t_6117d698` at `947dd3f824087509c060454495b484906be9f63e`
repairs disposed-controller operations and teardown cancellation errors.
All seven branch files match this snapshot. The retained Chromium report confirms
four passing keyboard journeys: missing/existing installation at 390/1280px,
2x Flutter text and reduced animations. Each receipt records six inspections,
five deliberate setup starts, three cancellations and zero network mutations or
page errors. Typed host operations and the landing router are synthetic.
The executor report records 22 focused test passes and clean analysis; this pass
neither reruns those checks nor independently confirms their terminal summaries.
Of 605 recorded source inputs, 596 match; nine later SSH/localization inputs differ.
The result qualifies the frozen candidate, not the whole current dirty tree.

Design, test plan, navigation and Unreleased history now expose the controller
repair and bounded setup qualification. Root TODO narrows
CONNECTION-SETUP-AUTH-MATRIX to reuse the delivered screen checks and preserve
CONNECTION-LOCAL-ENROLLMENT-NATIVE's existing in-progress ownership. Production
routing/native fixture composition, actual installation/adoption, authentication
and protected-main delivery remain separate. No requirement or API is changed.

Core-role map:
- README: `README.md`, unchanged_verified for orientation and setup; `docs/README.md` maintained for evidence navigation.
- PRD: `docs/product/prd.md`, unchanged_verified for accepted direct-connection intent and remaining acceptance.
- ADRs: `docs/adr/README.md` and five living records, unchanged_verified for applicable boundaries; no new decision.
- Spec: `docs/spec.md`, maintained for disposal fencing and qualification limits.
- Owned HTTP API: `docs/api/wing-link.openapi.yaml`, unchanged_verified for manual code-first ownership; YAML 3.1.0 syntax with 20 paths passes, not standards/runtime conformance.
- Test plan: `docs/test-plan.md`, maintained for synthetic setup evidence and routing/native/live gaps.
- Runbooks: `docs/getting-started.md`, `docs/runbooks/android-hermes-setup.md`, `docs/runbooks/release-alpha.md`, unchanged_verified for inspected prerequisites and limits; no operational action.
- Changelog: `CHANGELOG.md`, maintained for the implemented Unreleased controller fix, not a release.
All applicable core owners exist; none needs creation. Existing BLOCKERS questions
and defaults remain unchanged. No new owner question is required.

Root `TODO.md` and helper-managed `goals.json` retain 35 goals and 174 tasks:
two met, 17 partial, nine unmet and seven unverified. Every non-met goal has at
least two unfinished slices. All 71 unfinished tasks have unique full live bodies;
no completed task body remains live. No task is added or its status changed.
Focus remains CONNECTION-PATHS. First helper candidate:
CONNECTION-SAVED-WORKFLOWS, already in_progress. First eligible open slice:
CONNECTION-SETUP-AUTH-MATRIX; its production-routing subset already has a worker
ownership claim. Eligibility does not establish writer availability or dispatch.

Offline checks run on Linux: canonical `goals.py fmt` → `validate` → `render`
with `<repo>` prints `ok`; `next --json` confirms the
ordering above. Local checking resolves 708 links/anchors across 20 core/affected
owners, excluding 26 optional local-artifact references. Goal-source paths,
met evidence and task coverage pass. `git diff --check` and
`git show --format= --check agent/wing/t_6117d698` pass. A second canonical cycle
checks TODO/goals/archive byte stability. Archive changes are append-only;
no task blocks move and all existing live task continuations are preserved.

Mechanical review checks changed Markdown, wrapping, punctuation and protected
identifiers. Language/meaning review applies the STE-inspired profile to changed
prose and preserves synthetic/live, frozen/current and qualification/delivery
limits. Full ASD-STE100 dictionary compliance is not verified. Product tests,
builds, native launches, devices, network requests, installs, release operations
and API standards/runtime conformance do not run in this documentation pass.

## Completed production key-authentication implementation

Original task body follows verbatim. Historical in-progress wording describes
the earlier comparison, not current ownership. Fresh parent verification passed
72 focused Flutter regressions and full analysis. Seven isolated Python harness
checks pass. Native Linux/Android chooser and full-app qualification remain open
under BACKEND-SSH-KEY-NATIVE. No claim of delivery to main.

- [ ] **BACKEND-SSH-KEY-AUTH** — Goal: REMOTE-BACKENDS. Add private-key
  authentication to the production SSH form on Linux and Android.
  Payoff: use a deliberate key choice instead of requiring a server password.
  Scope: existing form, controller, native picker and ephemeral transport input.
  Default: attempt-scoped key/passphrase only; no persistence, automatic key
  discovery, personal key copying, remote bootstrap or Agent changes.
  Acceptance: native file/document selection reaches existing private-key callbacks;
  encrypted-key passphrase entry, cancellation, invalid/oversized/unsupported keys,
  sanitized failure and password fallback pass production-control regressions.
  Preserve explicit host trust, separate Agent token and owner-safe cleanup.
  Sources: [Desktop key trace](docs/product/desktop-connection-paths.md#private-key-ux-desktop-reference-and-wing-adaptations),
  [test cases](docs/test-plan.md#ssh-private-key-qualification).
  Dependencies: none; transport key callbacks already exist. Section: Now.
  Ownership: in_progress in the ledger; preserve the current worker and verify
  its live lease before any dispatch. Do not start a duplicate key-auth slice.

  Current graph comparison: key/password controls and deliberate key selection
  now exist in the development worktree. Complete the existing form/helper rather
  than create another SSH seam. Later live source already adds bounded key reads
  and a picker-generation fence outside the pinned graph. Verify those controls,
  encrypted-key recovery and compact keyboard regressions instead of duplicating
  the new implementation. The
  focused comparison run failed three tests while source changed concurrently;
  rerun against the completed candidate. See the
  [pinned comparison](docs/quality/graphify-wing-recomparison.md).
  Ledger status is in_progress; preserve its existing worker ownership. This
  refresh does not close the task or grant native/live qualification.


## Completed native production Local enrollment

Original task body follows verbatim. Its unchecked box and in-progress wording
are historical. The ledger now records this bounded slice done; retained Linux
GTK and focused terminal logs confirm the qualification. Actual host setup, live
authentication, Android and protected-main delivery remain separate.

- [ ] **CONNECTION-LOCAL-ENROLLMENT-NATIVE** — Goal: CONNECTION-PATHS. Qualify
  optional Local setup through production enrollment routing and native Linux
  consent recovery without host mutations.
  Payoff: prove the real enrollment composition rather than repeat an isolated
  Local setup screen check. Reuse the delivered controller and harness behavior.
  Scope: production enrollment/router composition and an isolated Linux fixture
  with synthetic typed host operations. Exclude actual installation, personal
  runtime changes, credential discovery, inference and upstream edits.
  Acceptance: public keyboard controls reach optional Local setup; Cancel/Back
  perform no setup, explicit Run setup starts exactly once, Stop fences late
  results, inspection-only retry does not rerun setup, and explicit Continue
  returns through the intended production route. Preserve direct Agent entry
  without mandatory pairing. Record exact source, target, operations and exits.
  Sources: [delivered setup recovery](docs/quality/local-setup-recovery.md),
  [connection verification](docs/test-plan.md#connection-path-verification).
  Dependencies: none. Section: Next. Ownership: in_progress in the ledger;
  preserve the existing worker and verify its lease. Do not dispatch a duplicate.

## Native Local enrollment follow-through — 2026-10-08

Mode: Bootstrap + Maintain. Documentation, TODO and goals only. The changed
branch `agent/wing/t_4c7cb087` at `341073e9` delivers native production enrollment
qualification at unchanged main HEAD `b9eb5b3d9f6f3a433dd36cb6271ad8ec769b2319`.
The monitor lists zero path drift. Earlier Local-controller and two-host branch
changes already have maintained design, verification and Unreleased owners.
No source, tests, cards, schedules, credentials or BLOCKERS entries change.

The [native enrollment report](docs/quality/local-setup-enrollment-native.md)
records the real WingApp/router and production Local screen, not the earlier
minimal browser router. Retained complete terminal summaries confirm 26 focused
passes, four Linux GTK journeys and no analyzer issues. Receipt metadata separately
records all six check exits, isolated teardown, native process identity and exact
operation counters. Each journey records 12 inspections, six setup starts, four
cancellations and zero management attempts, Agent mutations or forbidden reads.
The setup runner, storage and HTTP authority are synthetic. No actual installer,
adoption, restart, authentication or provider inference is qualified.

The executed archive and source-manifest SHA-256 values match their retained
receipt. Of 849 source inputs, 847 match this snapshot. The later
`managed_ssh_key_selection.dart` and its test differ. Dependency identities are
retained executor metadata, not freshly requalified toolchains. Passing this
candidate does not qualify the full current tree, Android, screen-reader output,
live authentication, release packaging or protected-main delivery.

| Core role | Canonical owner | Outcome |
| --- | --- | --- |
| Orientation | `README.md` | unchanged_verified for inspected setup/navigation. `docs/README.md` maintained for the new bounded evidence link. |
| Requirements | `docs/product/prd.md` | unchanged_verified for accepted direct-Agent connection and optional management intent. |
| Decisions | `docs/adr/README.md` and five living records | unchanged_verified for ownership, local references and existing boundaries. No new decision. |
| Design | `docs/spec.md` | maintained for production enrollment fixture qualification and remaining live/installation gaps. |
| Owned HTTP API | `docs/api/wing-link.openapi.yaml` | unchanged_verified for manual code-first ownership. No handler/contract change in this slice. Full schema/runtime conformance not run. |
| Verification | `docs/test-plan.md` | maintained for exact native scenarios, retained terminal results and current-source limits. |
| Operations | `docs/getting-started.md`, `docs/runbooks/android-hermes-setup.md`, `docs/runbooks/release-alpha.md` | unchanged_verified for inspected setup, recovery and release boundaries. No host operation runs. |
| History | `CHANGELOG.md` | unchanged_verified. The prior implemented controller/network fixes are already recorded. This qualification adds no new product feature or release. |

All applicable core owners exist. No missing owner needs creation. No new owner
question is required. Existing BLOCKERS questions and defaults remain unchanged.
`TODO.md` removes the completed CONNECTION-LOCAL-ENROLLMENT-NATIVE body and narrows
CONNECTION-SETUP-AUTH-MATRIX to remaining setup/auth work. The original completed
body is appended verbatim above, once, with historical-state context. Existing
archive bytes remain an exact prefix. All other live task bodies and continuations
are preserved except the intentional matrix-status correction. No new tasks are
needed or booked. No existing task status, priority, focus or ownership is changed.

`goals.json` remains byte-identical after canonical maintenance. Coverage is 35
goals: two met, 17 partial, nine unmet and seven unverified, with 174 task records.
Both met goals retain executed passing journey evidence. All 33 non-met goals
have at least two unfinished slices. All 69 live bodies correspond to unfinished
ledger tasks. Goal source paths exist. CONNECTION-PATHS remains partial and focused.
The helper first selects in-progress CONNECTION-SAVED-WORKFLOWS. Its first open
focused successor is CONNECTION-SETUP-AUTH-MATRIX, subject to actual writer/lease
availability. Eligibility does not prove a worker is free or started.

Executed offline checks: `python <home>/.hermes/shared-skills/repo-docs/scripts/goals.py fmt <repo>`
then the same helper's `validate <repo>` prints `ok`,
then `render <repo>`. `next` inspects existing eligibility.
`git diff --check` passes. Local path/anchor checks resolve 700 references across
core owners, navigation, coordination and the new report. Optional ignored receipt
links are treated separately. A first approximate anchor checker collapsed spaces
incorrectly. Correct GitHub-style slug handling resolves all reported anchors.
Archive conservation, live task/goal coverage and repeated byte stability pass.

Mechanical review checks scoped punctuation, sentence structure and identifiers.
Language/meaning review applies the STE-inspired profile and preserves synthetic
versus live qualification, explicit consent and separate pairing. Full ASD-STE100
dictionary compliance is not verified. Repository checks run offline on Linux.
Product tests, builds, devices, API standards/runtime checks, external links,
installs and release procedures are not executed in this documentation pass.

## Remote authentication explanation follow-through — 2026-10-08

Mode: Bootstrap + Maintain, documentation and goal backlog only. The monitor's
changed agent branches lead to `agent/wing/t_62edb5a9` at
`60f239b1c27419992cc4e5c70320c4b44ccf4771`; shared HEAD remains
`b9eb5b3d9f6f3a433dd36cb6271ad8ec769b2319`. No path drift was supplied.
The [delivery receipt](docs/quality/remote-auth-explanation.md) records selectable,
keyboard-reachable guidance for Agent-token authentication and unsupported browser
OAuth. A 401/403 denial is not sign-in-method detection. Recovery requires an
explicit retry or cancellation, without extra probes or management requests.

Source inspection confirms the shared layout and localized copy. Retained complete
logs confirm three tooling passes, clean formatting and analysis, 38 focused Flutter
passes and four Linux GTK fixture journeys. All 855 source-manifest inputs match
this inspected snapshot. The source archive and manifest digests also match the
receipt. This is inspected frozen-candidate evidence, not a new product execution
or qualification of the entire current tree. Live authentication, OAuth support,
physical keychain, Android and protected-main delivery remain separate gaps.

| Core role | Canonical owner | Outcome |
| --- | --- | --- |
| README | `README.md` | unchanged_verified for orientation, alpha boundaries and navigation to the connection guide. |
| PRD | `docs/product/prd.md` | unchanged_verified for CONN-3 unsupported-OAuth requirements and separate live qualification. |
| ADRs | `docs/adr/README.md` and its five living decisions | unchanged_verified for Agent authority and optional management boundaries; no new decision. |
| Spec | `docs/spec.md` | maintained for shared authentication guidance and keyboard traversal. |
| Owned HTTP API | `docs/api/wing-link.openapi.yaml` | unchanged_verified for manual code-first ownership; no API change, standards/runtime conformance not executed. |
| Test plan | `docs/test-plan.md` | maintained for attributed widget/native fixture checks and remaining target gaps. |
| Runbooks | `docs/getting-started.md`, `docs/runbooks/android-hermes-setup.md`, `docs/runbooks/release-alpha.md` | connection guide maintained; optional pairing and release procedures unchanged_verified for inspected boundaries. |
| Changelog | `CHANGELOG.md` | maintained for implemented Unreleased guidance, not OAuth support or publication. |

All applicable core owners exist. None needs creation. The docs index now links
the new explanation receipt. `TODO.md` narrows CONNECTION-SETUP-AUTH-MATRIX so
workers reuse completed guidance rather than repeat its copy or synthetic journey.
Its ledger title retains the original composite contract, not a claim that every
part remains missing. CONNECTION-REMOTE-AUTH-EXPLANATION is already done in the
ledger and has no live body to move. No task is added, reopened or transitioned.
Existing BLOCKERS questions and defaults remain unchanged. No new owner question
is required by this correction.

`goals.json` covers 35 goals: two met, 17 partial, nine unmet and seven unverified.
There are 175 task records, with 69 unfinished tasks and matching live bodies.
Each non-met goal retains unfinished work, and both met goals retain executed
passing journey evidence. CONNECTION-PATHS remains partial and focused. The
selector first returns in-progress CONNECTION-SAVED-WORKFLOWS. The first eligible
open successor is CONNECTION-SETUP-AUTH-MATRIX, subject to actual writer/lease
availability. This pass starts no worker and changes no card or schedule.

Executed repository checks: `python <home>/.hermes/shared-skills/repo-docs/scripts/goals.py fmt <repo>`,
then `validate <repo>` prints `ok`, then
`render <repo>`. Concurrent workers appended three
passing evidence entries and refreshed generated coverage during this pass.
Those additions are preserved, not treated as formatter drift or new checks run
by this pass. Repeat stability is checked after rereading that advancement.
`git diff --check` passes. Offline checks resolve 710 local paths/anchors across
19 core, navigation, coordination and receipt documents, excluding 26 optional
local-artifact references. All goal-source paths exist. The archive receives only
this new receipt; earlier bytes remain an exact prefix. No task body is moved.

Mechanical review checks scoped punctuation, sentences and protected identifiers.
Language/meaning review applies the STE-inspired profile to new prose and preserves
token versus management/provider credentials, denial versus OAuth detection and
synthetic versus live execution. Full ASD-STE100 dictionary compliance is not
verified. Product tests, builds, live requests, API conformance, external links,
installation and release procedures are not executed in this documentation pass.


## Production connection browser completion follow-through — 2026-10-08

Completed live task body, preserved verbatim from TODO.md:

- [ ] **CONNECTION-PRODUCTION-BROWSER-MATRIX** — Goal: CONNECTION-PATHS.
  Prove production-router Local and Remote saved-owner recovery together in Chromium.
  Payoff: verify real onboarding composition rather than isolated placeholder routes.
  Scope: dedicated entrypoint, browser fixtures/spec and nearest regression; active
  card `t_b47919e4` owns this slice. Preserve its live lease and frozen evidence.
  Acceptance: public entry at compact/wide enlarged text exercises explicit Local
  consent/cancel/retry, Remote auth/save failure and saved-host collisions; delayed
  results cannot replace owner and no mutations replay. Direct paths send zero Link
  requests. Existing Link setup fixtures qualify only retained legacy behavior,
  not the replacement Linux discovery or Android phone setup. Coordinate the Local
  layout/l10n change with the parent before any root-cause edits.
  Sources: card `t_b47919e4`, [CONN-1–6](docs/product/prd.md#connection-path-requirements),
  [verification](docs/test-plan.md#connection-path-verification).
  Dependencies: CONNECTION-LOCAL-ENROLLMENT-NATIVE (done). Section: Now.
  Ownership: in_progress; no duplicate dispatch. Native/live qualification and
  protected-main delivery remain separate.


Bootstrap + Maintain followed agent branch `agent/wing/t_b47919e4` at
`ab38655f1705470310dc9f0b1cfe359621d7b71d`. HEAD remains
`b9eb5b3d9f6f3a433dd36cb6271ad8ec769b2319`; the monitor lists zero drift.
The ledger already marks CONNECTION-PRODUCTION-BROWSER-MATRIX done. Complete
retained logs confirm 64 Flutter tests, clean analysis, a JavaScript build and
14 Chromium journeys. Those checks were not rerun here. Of 693 manifest entries,
682 match and 11 differ. This is frozen-candidate evidence, not current-tree
qualification. The existing CONNECTION-SETUP-AUTH-MATRIX successor retains
installation, live/native and replacement-Local gaps; no duplicate task is added.

The spec now describes the existing native Dart SSH adapter instead of saying
it is absent or requiring an OpenSSH executable. SSH success remains separate
from Agent readiness. Native full-app/live SSH and saved relaunch remain unqualified.

Core-role map: README.md (orientation), docs/product/prd.md (requirements),
docs/adr/README.md and living decisions (architecture), docs/api/wing-link.openapi.yaml
(owned manual code-first HTTP snapshot), CHANGELOG.md (history), and
docs/getting-started.md with docs/runbooks/desktop-feature-qualification.md and
docs/runbooks/release-alpha.md (operations): unchanged_verified for role ownership
and scoped evidence boundaries. docs/spec.md (design) and docs/test-plan.md
(verification): maintained. All applicable owners exist; no empty or duplicate
document is created. The retained deprecated Link API still owns an HTTP contract;
Wing does not own Agent HTTP. Complete handler conformance remains a queued gap.

Goal snapshot: 35 goals — 2 met, 17 partial, 9 unmet, 7 unverified. Every non-met
goal has at least two unfinished tasks. No goal is promoted by documentation checks.
TODO.md and goals.json remain the discoverable human and machine owners;
todo.archive.md owns completed prose. Existing owner questions in BLOCKERS.md
remain unchanged. No new owner decision is needed for this correction.

Final ledger snapshot: 178 tasks, 71 unfinished. Every unfinished ledger ID has
one live TODO body; no completed ledger task remains in the live backlog.
CONNECTION-SETUP-AUTH-MATRIX is updated; CONNECTION-PRODUCTION-BROWSER-MATRIX
is archived, not reopened. No task is added and goals.json stays byte-identical.
The selector first returns in-progress CONNECTION-LINK-REMOVAL, then the existing
connection workflow. The first eligible open task is CONNECTION-SETUP-AUTH-MATRIX;
eligibility does not establish writer availability or dispatch.

Executed checks: `python <home>/.hermes/shared-skills/repo-docs/scripts/goals.py fmt <repo>`,
then `validate <repo>` prints `ok`, then
`render <repo>`. `git diff --check` passes.
An offline Python path/anchor check resolves 797 local links across 17 core,
navigation and coordination documents, excluding 35 optional local-artifact links.
All goal-source paths exist. Archive prefix and moved-block multiplicity checks pass.
All open bodies remain byte-identical except the stated successor evidence addition.
The second fmt/validate/render pass leaves TODO, goals and archive byte-identical.

Mechanical review covers scoped punctuation, sentences and protected literals.
Language/meaning review applies the STE-inspired profile to the changed prose.
It preserves SSH versus Agent readiness and frozen fixture versus live qualification.
Full ASD-STE100 dictionary compliance is not verified. Product tests/builds,
API handler conformance, external links, install and release procedures are not run.

## Official reference navigation repair — daily pass 2026-10-09

Mode: Bootstrap + Maintain, documentation and goal backlog only. The monitor
changed only its day marker, with HEAD `b9eb5b3d9f6f3a433dd36cb6271ad8ec769b2319`
and no listed path drift. Static inspection nevertheless found a broken README
acknowledgment link, `[Hermes Desktop](withdrawn source)`. It now points to the
official Nous Research `hermes-agent/apps/desktop` application. The client ADR
also instructed readers to use a withdrawn Layout revision. It now explicitly
requires a new official-source comparison and leaves shell parity unverified.
Historical Wing receipts, accepted architecture and existing work remain intact.

The read-only Agent checkout has origin `https://github.com/NousResearch/hermes-agent`,
HEAD `158fd638da1629c8e62caf9ade1515d162def8ab` and Desktop subtree
`2038178ee53e13cde6fe297daa2484a868e7d3a3`. Its own README and development guide
identify the official Desktop app. This is local provenance inspection, not a
live-upstream freshness check or product execution.

Core-role coverage: README.md maintained; docs/adr/client.md maintained within
the existing living ADR set. docs/product/prd.md, docs/spec.md, docs/test-plan.md,
docs/api/wing-link.openapi.yaml, CHANGELOG.md, docs/getting-started.md and
setup/release runbooks are unchanged_verified for ownership, scoped reference
boundaries and local navigation. All applicable owners exist. No new core owner,
release entry or architectural decision is required. The retained legacy Wing
Link HTTP contract remains applicable until retirement. Agent HTTP is not owned
by Wing. This pass does not establish complete API or product conformance.

Goal-gap snapshot: 35 goals, 182 tasks, 75 unfinished task bodies; 2 met,
17 partial, 9 unmet and 7 unverified. Every non-met goal retains at least two
unfinished slices. Met records contain executed passing checks; no goal is
promoted or task closed here. TODO.md and goals.json stay byte-identical after
fmt/validate/render. No task is added or duplicated. CONNECTION-PATHS focus and
active ownership are retained. The selector first returns in-progress
CONNECTION-LINK-REMOVAL; the first eligible open task is
CONNECTION-OFFICIAL-DESKTOP-PORT. Eligibility is not a file lease or dispatch.
BLOCKERS.md remains unchanged; no new owner question is needed.

Executed checks on Linux: `python3 <home>/.hermes/shared-skills/repo-docs/scripts/goals.py fmt <repo>`,
then `validate` and `render` with the same absolute repository argument and fresh
`--expected-revision` tokens. Each exits 0; validation prints `ok`.
`python3 .task-evidence/repo-docs-daily-20261009/check_docs.py <repo>`
passes 758 local link/anchor checks across 19 core/navigation/coordination owners,
excluding 26 documented optional local-artifact links. The same check passes in
a detached, pinned candidate containing current nonignored documentation and
source inputs, with no build or local evidence artifacts. The initial docs-only
candidate correctly detected three development-source links missing from HEAD;
the final candidate includes those real nonignored source files, not stand-ins.
This qualifies the prospective working snapshot, not the already committed tree.
OpenAPI YAML parsing with `/usr/bin/python3` passes: version 3.1.0, 20 paths.
Syntax does not establish schema or handler conformance. `git diff --check` passes.
Archive prefix conservation and repeated canonical-cycle byte stability are
checked separately; no task bodies or historical records move in this pass.

Mechanical review covers scoped Markdown, punctuation and protected literals.
Language/meaning review applies the STE-inspired profile, preserving reference
withdrawal and qualification limits. Full ASD-STE100 dictionary compliance is not
verified. Product tests/builds, devices, network links, live qualification,
API runtime conformance, installs and release actions are not run.

### Requested verification follow-up

The subsequent verification request required `npm run test`. package.json maps
that command to `flutter test --concurrency=1`. The foreground attempt was
interrupted by the tool's 420-second limit; its shutdown stream errors do not
establish an application defect. A background retry completed with exit 0:
`13:45 +3866 ~8: All tests passed!` (3866 passed, 8 skipped).
The retained full log is `.task-evidence/repo-docs-daily-20261009/npm-test-retry.log`;
the recorded exit is in `npm-test-retry.exit` beside it. No application source or
test was changed to obtain this result. Concurrent work remains present, so this
run does not qualify a frozen source manifest, platform parity or live behavior.

The scratch documentation checker also ran again with exit 0, and
`python3 -m py_compile .task-evidence/repo-docs-daily-20261009/check_docs.py`
passed. The latest navigation snapshot has 765 local links/anchors, 26 optional
artifact exclusions and 75 unfinished task bodies, with no reported errors.
This is a separate snapshot from the earlier 758-link check, not a replacement
for its historical result. `git diff --check` passes.


## Direct Agent documentation retirement follow-through — 2026-10-09

Mode: Bootstrap + Maintain. Monitor HEAD: `15362b02cdaf60a4f8e74af8d2f1ae6e8f9d300a`.
That commit adds an unspent-approval binding regression, not a new capability.
The existing security receipt remains historical; no Go check is rerun and no
security or official Desktop parity goal is promoted.

The accepted product ADR requires removal of Wing Link from current-user setup
and navigation. The guide still recommended installation, pairing and management
approval commands. The PRD still described an optional management plane. These
were contradictions with an accepted decision, not unanswered owner questions.

README.md, CONTRIBUTING.md, docs/README.md, docs/getting-started.md and
 docs/product/prd.md now distinguish direct Agent use from deprecated retained
code. The first-chat guide keeps client build commands, direct connection,
saved-connection repair and explicit recovery. It removes the legacy installer,
pairing walkthrough and management troubleshooting. Android same-phone setup
remains unqualified. The docs index no longer promotes Link installation,
profile management or its API as current-user entry points. Historical runbooks,
receipts, security contracts and personal paired state remain untouched.
This is documentation retirement, not implemented consumer removal.

Core-role map:
- Orientation: README.md and docs/README.md — maintained.
- Requirements: docs/product/prd.md — maintained.
- Architecture: docs/adr/README.md and five living decisions — unchanged_verified.
- Design: docs/spec.md — unchanged_verified for inspected ownership and boundaries.
- Owned API: docs/api/wing-link.openapi.yaml — unchanged_verified; retained manual
  code-first contract, not current-user setup. Agent HTTP is not Wing-owned.
- Verification: docs/test-plan.md — unchanged_verified for qualification limits.
- Operations: docs/getting-started.md — maintained; qualification/release runbooks
  remain unchanged_verified for inspected prerequisites and recovery boundaries.
- History: CHANGELOG.md — unchanged_verified; no runtime feature or release added.
All applicable owners exist; no duplicate document is created. CONTRIBUTING.md
is maintained for the retained-code boundary. Broader API/platform proof is open.

TODO.md updates only CONNECTION-LINK-RETIREMENT's documentation continuation.
Its CONNECTION-LINK-REMOVAL dependency and unclaimed ownership remain unchanged.
No task is added, closed or claimed. All other live task bodies and continuations
remain byte-identical. goals.json and BLOCKERS.md remain byte-identical.
No new owner question is required. No worker, card, schedule or external action.

Goal snapshot: 35 goals, 186 tasks, 79 unfinished bodies; 2 met, 17 partial,
9 unmet, 7 unverified. Every non-met goal retains two unfinished slices; met
records retain executed passing checks. CONNECTION-PATHS focus is preserved.
The selector first returns in-progress CONNECTION-LINK-REMOVAL. Its first eligible
open slice is CONNECTION-OFFICIAL-DESKTOP-PORT, subject to actual file leases.
Its smallest next check is the scoped official connection comparison and nearest
production-control regression on the frozen implementation candidate. This
checker does not dispatch a worker or qualify that workflow.

Authored in a detached worktree pinned to monitor HEAD with exact canonical
baselines. Integration compares all target baselines under the shared Git ledger
lock and requires exact authored bytes. Candidate validation includes actual
current maintained dependencies, not ignored build or evidence artifacts. Its
ledger snapshot is not a competing authority or an implementation admission rule.

Executed Linux checks:
- `python3 .task-evidence/repo-docs-daily-20261009/check_docs.py <repo>`
  passes 774 links/anchors across 19 owners, excluding 26 optional local artifacts;
  all 79 unfinished ledger tasks have bodies. The same check passes against
  `.task-evidence/repo-docs-head-20261009/candidate`, an artifact-free candidate,
  not a committed-checkout qualification.
- `python3 <home>/.hermes/shared-skills/repo-docs/scripts/goals.py fmt <repo>`,
  then `validate` and `render` with the same absolute target and fresh
  `--expected-revision` tokens: exit 0; validation prints `ok`. A repeated cycle
  preserves TODO, goals and BLOCKERS bytes.
- `/usr/bin/python3` parses retained API YAML: OpenAPI 3.1.0, 20 paths. Syntax
  does not establish schema or handler conformance.
- Scoped `git diff --check` and baseline-to-candidate whitespace checks pass.
  The guide has no installer, pairing, approval CLI or Link URL commands.

The archive receives only this append; earlier bytes remain an exact prefix.
No task body or historical receipt moves. Mechanical review covers scoped Markdown,
punctuation and protected commands. Language/meaning review applies the
STE-inspired profile, preserving direct/legacy, fixture/native/live and
qualification/delivery distinctions. Full ASD-STE100 dictionary compliance is not
verified. Product tests/builds, network links, installed-runtime checks, deploys
and release actions are not run. Source/packaging retirement, native installation,
live authentication and protected-main delivery remain with existing owners.

## Idle approval withdrawal documentation follow-through — 2026-10-09

Bootstrap + Maintain inspected monitor HEAD `69fe5e3761747e7abeb9aae754a047b05ef335a7`
and approval commit `8866604b0b6492ac96025b79603ae566eec16c1c`. Spec, test plan and
Unreleased history now identify idle request withdrawal as an internal adapter
correction, not enabled production transport. WING-TASK-406 retains production
wiring and zero-stale-response acceptance after WING-TASK-405. Its body now carries
the candidate input, smallest lifecycle check and complete relevant input closure.
No task was added, closed, claimed or promoted. Canonical goals authority does not
require a code candidate to carry byte-identical ledger files.

All applicable core owners exist. Maintained: `docs/spec.md`, `docs/test-plan.md`
and `CHANGELOG.md`. Unchanged verified for this delta: `README.md`,
`docs/product/prd.md`, `docs/adr/README.md` and living decisions, and the operation
owners `docs/getting-started.md` and `docs/runbooks/release-alpha.md`.
`docs/api/wing-link.openapi.yaml` remains the owned retained legacy contract;
this client-only delta changes no HTTP API. Schema/runtime qualification was not
rerun. No missing owner requires creation. BLOCKERS and existing decisions remain
unchanged; there is no new owner question.

`TODO.md` updates only WING-TASK-406 outside generated coverage. `goals.json`
retains focus CONNECTION-PATHS and all task state. Coverage remains two met,
17 partial, nine unmet and seven unverified goals, with two unfinished slices
for every non-met goal. All 79 open/in-progress IDs have one live body; completed
history remains in `todo.archive.md`. No historical body moved. The selector
first lists in-progress CONNECTION-LINK-REMOVAL; the first eligible open task is
CONNECTION-OFFICIAL-DESKTOP-PORT. Writer availability still requires lease checking.
No worker was dispatched. Production wiring, named-target qualification and main
delivery remain distinct gaps; earlier settlement/browser passes do not qualify
these changed source inputs.

Executed documentation checks, repository root unless specified:
- `python .task-evidence/repo-docs-daily-20261009/check_docs.py <repo>`
  and the same checker against the private pinned candidate: exit 0, no errors.
  Each checks 19 owners, 777 local links/anchors and all live task bodies;
  26 intentional optional artifact links are excluded. The first candidate check
  failed on three untracked production-source dependencies. Exact source bytes
  were then included in its dependency closure, not build or scratch artifacts.
- `python <home>/.hermes/shared-skills/repo-docs/scripts/goals.py fmt <repo>`
  → `validate` → `render`: exit 0; validation prints `ok`. Repeating the cycle
  preserves exact TODO, ledger and archive bytes.
- `git diff --check -- docs/spec.md docs/test-plan.md CHANGELOG.md TODO.md`: exit 0.
  Baseline-relative no-index whitespace checks pass for all four authored files.
  Integration compares exact canonical baselines under the shared advisory lock;
  unrelated dirty and staged changes remain untouched.

The STE-inspired profile applies only to changed wording. Mechanical review
checks Markdown and protected literals. Meaning review preserves internal versus
production, source versus executed proof and qualification versus delivery.
Full ASD-STE100 dictionary compliance was not verified. This pass runs no product
suite, build, installation, live request, device, release or upstream modification.
Private candidate inputs and next-selection output remain optional ignored scratch.

## Approval regression main-delivery follow-through — 2026-10-10

Bootstrap + Maintain, documentation and backlog only. The monitored main HEAD is
`205ae2d437f7cbf53a36d8e0440664e854a5fcaf`. The unspent approval regression from
`15362b02cdaf60a4f8e74af8d2f1ae6e8f9d300a` is delivered on main. Exact test bytes
match that commit. The security receipt now separates this delivery observation
from its historical dirty-source test runs. Those runs are not fresh qualification
of main, the current worktree, official Desktop parity or live security behavior.

TODO corrects VERIFY-OMNIROUTE-NODE22-CLOSURE's stale Needs decision dependency:
FIX-NPM-AUDIT is open in Next, with the owner policy already resolved. Compatible
remediation remains unfinished; security gates and recorded failures are retained.
No task is added, claimed, closed or reopened. All other TODO bytes, all ledger
objects, focus, ownership and BLOCKERS entries remain unchanged.

Core-role coverage: README.md (orientation), docs/product/prd.md (requirements),
docs/adr/README.md and five living decisions (architecture), docs/spec.md (design),
docs/api/wing-link.openapi.yaml (retained manual code-first HTTP contract),
docs/test-plan.md (verification), docs/getting-started.md and setup/release runbooks
(operations), and CHANGELOG.md (history) are unchanged_verified for inspected
ownership, relevant boundaries and local links. All applicable owners exist;
none needs creation. The security receipt is maintained. No API schema/runtime
conformance, product behavior or release claim is advanced by these checks.

Root TODO.md and goals.json retain 35 goals and 186 tasks: two met, 17 partial,
nine unmet and seven unverified. All 79 live task bodies exist exactly once;
every non-met goal retains at least two unfinished slices. CONNECTION-PATHS
focus remains accepted. CONNECTION-LINK-REMOVAL is the helper's first in-progress
entry; CONNECTION-OFFICIAL-DESKTOP-PORT is its first open eligible slice. Existing
writer leases must still be checked before execution. No worker was dispatched.

Executed checks:
- `python .dart_tool/repo-docs-maintain-205ae2d/.maintenance-check.py <repo>`
  and the same checker against the private detached candidate: exit 0; 20 owners,
  820 local links/anchors, all live task bodies and met-rule/two-slice checks pass.
  Twenty-eight optional artifact links are excluded. Initial candidate validation
  exposed four untracked source dependencies; exact current bytes completed its
  dependency closure. No build or scratch artifact was copied to satisfy a link.
- `python <home>/.hermes/shared-skills/repo-docs/scripts/goals.py fmt <repo>`
  then validate and render: exit 0, validate prints `ok`. Repetition preserves
  exact TODO, goals and archive bytes. Ledger bytes remain equal to baseline.
- `git diff --check -- TODO.md docs/quality/security-current-boundary.md`: exit 0.
  Shared-lock integration compares exact canonical baselines before writing.
  The archive retains its entire original prefix; no completed entry is moved.

Mechanical and language/meaning review apply the STE-inspired profile to changed
prose, retaining protected identifiers, owner decisions and source/delivery limits.
Full ASD-STE100 dictionary compliance was not verified. Product tests, builds,
installs, live requests, devices, operational actions and upstream edits are not
run. The next security check belongs to the existing audit-remediation owner:
inspect both current dependency locks and qualify a compatible fix on its exact
candidate. This documentation pass does not rerun audits or waive known risk.


## Direct connection prerequisite correction — 2026-10-09

Bootstrap + Maintain follows the monitor's removal of agent branch refs at unchanged
main HEAD `205ae2d437f7cbf53a36d8e0440664e854a5fcaf`. Ref absence is not implementation,
review or delivery evidence. The accepted CONNECTION-PATHS focus remains unchanged.

README.md still required NetBird/Tailscale for a private-network pairing walkthrough
that the direct getting-started guide no longer recommends. It also claimed that the
Wing guide installed Agent. README now requires a reachable authenticated Agent and
trusted transport, treats VPN connectivity as optional, and points installation and
provider setup to official Agent guidance. Browser HTTPS/CORS and native transport
review remain required. Same-phone Android installation remains unqualified.
The retained Android setup runbook now consistently says deprecated, not optional
supported management setup. Its historical procedure and commands are preserved.

TODO.md refines only CONNECTION-LINK-RETIREMENT's documentation continuation.
Its scope, acceptance, sources, dependency on CONNECTION-LINK-REMOVAL and ownership
are unchanged. No task is added, claimed, completed or reopened. No missing core
owner needs creation. Core-role coverage:
- README.md: maintained for direct setup prerequisites and guide responsibility.
- docs/product/prd.md: unchanged_verified for direct-use intent and acceptance limits.
- docs/adr/README.md and five living decisions: unchanged_verified for ownership and
  applicable deprecation, transport and runtime boundaries; no new decision.
- docs/spec.md: unchanged_verified for the relevant direct/retained implementation map.
- docs/api/wing-link.openapi.yaml: unchanged_verified as retained manual code-first
  HTTP documentation; YAML syntax passes, schema/runtime conformance not run.
- docs/test-plan.md: unchanged_verified for relevant qualification and no-replay limits.
- docs/getting-started.md and docs/runbooks/release-alpha.md: unchanged_verified;
  docs/runbooks/android-hermes-setup.md maintained for legacy status only.
- CHANGELOG.md: unchanged_verified; no runtime feature or release is introduced.
All applicable core owners exist. Root BLOCKERS.md and owner answers are unchanged;
no new question is needed. No worker, schedule, card, runtime or upstream is modified.

Root goals.json remains byte-identical. Coverage is two met, 17 partial, nine unmet
and seven unverified goals, with 186 tasks and 79 unfinished bodies. Every non-met
goal retains at least two unfinished slices. The first helper-eligible entry remains
in-progress CONNECTION-LINK-REMOVAL; the first eligible open slice remains
CONNECTION-OFFICIAL-DESKTOP-PORT. Actual file leases must be checked by its executor.
Its next check is the official connection source comparison and nearest production
entry regression on the exact frozen candidate, not another documentation receipt.
No goal gains product evidence from this pass.

Authoring used the existing detached checkout pinned to monitor HEAD, with exact
canonical document baselines and refreshed maintained dependencies. Shared-lock
integration required unchanged targeted baselines and exact candidate bytes.
The candidate ledger is a validation snapshot, not a competing canonical authority
or a requirement that implementation input carry byte-identical bookkeeping.

Executed Linux documentation checks:
- `python .dart_tool/repo-docs-maintain-205ae2d/.maintenance-check.py <repo>`
  and the same checker against `.dart_tool/repo-docs-maintain-205ae2d`: exit 0,
  20 owners, 820 local links/anchors, 28 optional-artifact exclusions and all 79 live
  bodies. Two-slice and executed-met-rule checks pass. This is artifact-free candidate
  validation, not committed-checkout or product qualification.
- `python <home>/.hermes/shared-skills/repo-docs/scripts/goals.py fmt <repo>`
  then validate and render, each with a fresh expected-revision token: exit 0;
  validate prints `ok`. Two cycles preserve TODO, goals, BLOCKERS and archive bytes.
- `git diff --check -- README.md TODO.md docs/runbooks/android-hermes-setup.md`:
  exit 0. Baseline-relative whitespace checks pass. All unrelated live task bytes
  are preserved. This archive entry is append-only; no historical task is moved.
- `/usr/bin/python3` with `yaml.safe_load` parses OpenAPI 3.1.0 and 20 paths.
  Syntax parsing does not establish standards-schema or handler conformance.

Mechanical review covers changed Markdown, sentence structure and protected
commands. STE-inspired meaning review preserves direct/legacy, connectivity/security
and implemented/qualified/delivered distinctions. Full ASD-STE100 dictionary
compliance was not verified. Product suites/builds, network requests, devices,
installs, operational actions and release checks are not run. Consumer retirement,
replacement Local/SSH qualification and live authentication remain existing gaps.


## OmniRoute retirement documentation follow-through — 2026-10-10

The committed retirement removes the embedded installer and dependency inputs.
This is source inspection, not a fresh passing audit or full security closure.
FIX-NPM-AUDIT is already done in the canonical ledger; its stale unchecked body
is preserved below without reopening it. The scheduled predecessor card still
names removed inputs. Its existing owner must reconcile that route; this pass
changes no cards. VERIFY-OMNIROUTE-NODE22-CLOSURE carries the missing current-candidate
checks under the same ID. Historical failures and owner decisions remain intact.

Preserved live entry (verbatim):

- [ ] **FIX-NPM-AUDIT** — Goal: SECURITY. Resolve the ledger's high/critical
  dependency-audit failures. Payoff: restore the declared security gate.
  Sources: [package manifest](package.json), [lockfile](package-lock.json) and
  [developer gate](CONTRIBUTING.md#required-checks).
  Scope: root manifest/lock and the separate embedded manifest/lock under
  `wing_link/internal/app/omniroute_assets/`; exclude suppression, unrelated upgrades
  and production operations. The [current installer review](docs/quality/omniroute-install-review.md#current-patched-closure--2026-10-06)
  records a passing root audit and four embedded high findings at that historical
  snapshot. The later [owner decision](BLOCKERS.md#blk-20261007-006--remaining-npm-audit-highs-with-no-published-fix)
  records five embedded high findings, zero critical; no new audit runs in this pass.
  Preserve the patched OmniRoute/Next pins; the suggested OmniRoute downgrade
  reintroduces the direct ACP advisory. Confirm findings on both current locks.
  The [selector repair receipt](docs/quality/chat-new-session-selector-repair.md)
  records 28 smoke/speech browser passes after fixing the exact Chat new-session
  selector. That harness slice is delivered; embedded audit closure and broader
  acceptance remain unfinished. Do not repeat the repaired selector work.
  Acceptance: `npm audit --audit-level=high` and
  `npm audit --prefix wing_link/internal/app/omniroute_assets --audit-level=high`
  pass; the rebuilt deterministic web target passes relevant E2E checks, and
  changed embedded dependencies pass the installer consumer and Go checks.
  This documentation pass runs no audit or install.
  Owner decision: [BLK-20261007-006](BLOCKERS.md#blk-20261007-006--remaining-npm-audit-highs-with-no-published-fix)
  is resolved: temporarily retain known risk and investigate compatible fixes.
  Dependencies: no unanswered policy decision; a compatible repair remains unproved.
  Ownership: existing remediation card is retained; check its retry/lease state
  before dispatch. Section: Next. Preserve reviewed pins and release security gates.
  If no compatible fix exists, record the remaining findings without claiming
  acceptance passed. Other SECURITY work continues. No incompatible override,
  suppression, release or audit waiver follows from temporary risk acceptance.

### Scoped maintenance verification

Mode: Bootstrap + Maintain. The main-only policy uses a pinned filesystem
candidate, not a branch worktree. Baseline is
`92beb1dcddbf2be638ac7819f3a636ec25ba75e2`; exact current documentation dependencies
and baseline bytes are retained in ignored `.task-evidence/repo-docs-omniroute-retirement/`.
This optional local receipt is not a fresh-checkout documentation dependency.

Core roles: README (`README.md`), PRD (`docs/product/prd.md`), ADR index and living
decisions (`docs/adr/`), retained manual code-first API
(`docs/api/wing-link.openapi.yaml`) and operation owners (`docs/getting-started.md`,
existing focused runbooks) are unchanged_verified for this retirement delta.
Spec (`docs/spec.md`), verification (`docs/test-plan.md`) and change history
(`CHANGELOG.md`) are maintained. All applicable owners exist; no duplicate or
missing core document was created. These outcomes do not establish full parity.

Updated `TODO.md` keeps the existing security successor and archives the stale
ledger-done entry verbatim. `goals.json` is unchanged. There are 2 met, 17 partial,
9 unmet and 7 unverified goals. Every non-met goal has an open/in-progress task;
all 78 live task IDs have complete existing bodies. Connection focus remains
unchanged. The first eligible open slice is CONNECTION-OFFICIAL-DESKTOP-PORT;
active connection writers and the retirement owner still require ownership
reconciliation before dispatch. This pass starts no worker.

Executed twice, each command exited 0:
- `python <home>/.hermes/shared-skills/repo-docs/scripts/goals.py fmt <repo>`
- `python <home>/.hermes/shared-skills/repo-docs/scripts/goals.py validate <repo>` (prints `ok`)
- `python <home>/.hermes/shared-skills/repo-docs/scripts/goals.py render <repo>`

Revision tokens guarded each invocation. Ledger/TODO bytes are unchanged on the
second pass. Programmatic added-link/anchor checks pass for 15 links in canonical
and artifact-free candidate inputs. Exact TODO replacement/removal checks and
append-only archive checks preserve unrelated bodies and the full moved block.
Scoped `git diff --check` passes for the seven changed documentation paths.
No product, build, audit, native, live or delivery check ran. The existing Dart
documentation contract was inspected, not executed under this no-test-suite scope.

Applied the STE-inspired profile to new prose only. Mechanical review checked
sentence structure and protected literals; meaning review kept source retirement,
historical failures, queued qualification and committed delivery distinct.
Full ASD-STE100 dictionary compliance was not verified. Historical installer
receipt bytes remain unchanged except for the explicit scope notice.
No new owner question is needed; the scheduled predecessor's removed inputs are
an engineering-routing issue for its existing owner, not new authorization.
