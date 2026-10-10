# Hermes Wing delivery roadmap

## North star

Prioritize a 1:1 Hermes Desktop product port through Flutter, using desktop and
wide web as the Desktop-first fidelity baseline while preserving mobile usability.
Desktop feature coverage, navigation, terminology, interactions and recovery
behavior define the target. The accepted local target is full Desktop functionality
through a separately designed bounded native integration; remote mode may expose
a smaller, explicitly capability-gated subset. This is a target, not implemented
native integration or an expansion of existing fixed-operation safety rules.
Platform-native implementation may differ;
record every product deviation and capability gap explicitly. Desktop parity
takes precedence over new Wing-specific management features. Existing milestone
evidence, blockers and acceptance requirements remain unchanged; this priority
does not close cards or qualify a platform. Agent owns domain state; Wing Link
remains in the current host-management implementation but is deprecated. Remove
its product dependencies, then retire its packaging without deleting paired state
or pretending unsupported Agent operations exist. Linux Local discovery and
Android guided same-phone setup replace management-first onboarding.
[Product boundaries](docs/adr/product.md) and [routes](docs/product/routes.md) define
delivery order, not deadlines; deferred capabilities are not completed parity.

## Baseline and evidence boundaries

Snapshot 2026-10-01: source/board inspected; dirty work is not a commit/release/platform qualification.

| Evidence level | Current baseline and limits |
| --- | --- |
| Implementation present | The production [channel provider](lib/features/hermes_chat/providers/hermes_channel_provider.dart) composes `HermesApiChannel`: direct advertised Agent sessions/chat/runs/tools/approvals/stop, not native-web qualification clients. [Routes](docs/product/routes.md) distinguish partial profile/provider/tool/job/host surfaces from planned discovery, memory and Kanban. Availability still depends on the connected host. |
| Independently reviewed UI slices | Long-conversation bounded projection, deliberate older-turn reveal and reading recovery: [runbook](docs/runbooks/chat-long-conversation.md), [widget regressions](test/features/hermes_chat/screens/hermes_chat_window_test.dart), [Chromium journey](playwright/tests/regression/chat-window.spec.mjs). Searchable session-model picker, including confirmed identity on reopen: [runbook](docs/runbooks/chat-session-model-picker.md), [Chat regressions](test/features/hermes_chat/screens/hermes_chat_session_picker_test.dart), [Chromium journey](playwright/tests/regression/session-model-picker.spec.mjs). Same-card acceptance: `t_ae9facdb` executor21 → tester22 → reviewer23; `t_fdcc4c0e` revision26 → tester27 → reviewer28. These are baseline, not next features. |
| Implemented/self-tested, unaccepted | Exact remembered-session recovery beyond inventory page one: [runbook](docs/runbooks/chat-session-restoration.md), [real client/directory regression](test/features/hermes_chat/gateways/hermes_gateway_session_restoration_test.dart), [storage race tests](test/features/hermes_chat/gateways/gateway_selection_write_race_test.dart), [Chromium journey](playwright/tests/regression/session-restoration.spec.mjs). `t_f098a32e` is in triage: the native lifecycle gate refused the executor→tester transition. No independent tester/reviewer acceptance; route wording describes implementation, not approval. |
| Internal experimental, blocked | Native-web lifecycle `t_43937159`: [qualification report](docs/runbooks/hermes-web-lifecycle-qualification.md) records 49 deterministic tests but actual idle interrupt RPC `5032` and harness exit 1. No accepted native cancellation, product authorization/registration, real generation or Android evidence. Internal read qualification is not production integration; see [release compatibility](docs/runbooks/hermes-agent-release-compatibility.md#internal-native-web-read-qualification-not-a-production-connection). |
| Named-platform historical evidence | The [evidence matrix](docs/quality/evidence-matrix.md) contains older Android/gateway/Waydroid receipts with source-specific limits. They do not qualify today's dirty tree. Recent reviewed UI slices exercised Linux widget runner + compiled Flutter Chromium at 390/1280px, not physical Android or native desktop apps. |
| Release readiness | Still open. [Security policy](SECURITY.md#supported-versions) promises no supported release; [alpha runbook](docs/runbooks/release-alpha.md) describes gates, not proof of publication. Current artifact, signing, integrated runtime and distribution evidence must be collected in M6. |

Links are evidence; board IDs are traceability; reference pins are not remote-latest claims.

## Study adoption

The completed [four-repository source study](docs/analysis/understand-anything/README.md)
informs current delivery through the [scoped follow-through plan](docs/plans/2026-10-03-study-follow-through.md).
Retain its readiness/reporting consistency invariant and historical receipts; the
owner's Desktop-first priority below supersedes its proposed delivery order, not
its evidence boundaries. This is not new capability or a native-web migration.
Scans, curated graphs and analysis-tool tests are not Wing runtime qualification.
Existing cards, blockers and independently accepted receipts below retain their
status; this adoption closes no milestone.

## Current delivery order

The accepted order is connection prerequisites, then **reliable away-and-return
chat, visible job status, and notifications**. Deliver small usable improvements
individually. The [user-demand acceptance](docs/product/prd.md#user-demand-emphasis)
and [workflow policy](docs/product/autogoal-workflows.md#user-demand-sequencing)
supersede the older Now/Next ordering below. Keep CONNECTION-PATHS focus until the
current connection slice is reconciled; this document does not dispatch work.

Reuse existing M1 recovery implementation and fixtures. The bounded Android
successor is M1-MOBILE-AWAY-STATUS: qualify authoritative return/status through
production controls in isolated Waydroid, repairing only demonstrated gaps.
This is not live inference or physical-device process-death qualification.
M1-NOTIFICATION-CONTRACT follows with one supported-contract assessment; the
notification architecture remains proposed, not enabled infrastructure.
Voice and mobile Kanban remain later user-demand signals with existing owners.

## Now / Next / Later

The following detail retains historical receipts and dependencies. Its old
selection order is superseded by Current delivery order above.

- **Now — Desktop daily-use workflow:** execute the accepted
  [daily-workflow plan](docs/plans/2026-10-03-desktop-daily-workflow.md): local
  connect → explicit profile/model/session → actual Chat generation → correlated
  approval/authoritative stop → leave/relaunch → exact-session recovery with zero
  duplicate sends. Desktop/wide-web fidelity leads; compact/mobile remains usable.
  Begin with the production `HermesApiChannel` native deterministic harness and
  isolate reproduced gaps before producer edits. Fixture replies do not satisfy
  actual generation. Native integration needs a separate design/security gate;
  this priority does not enable local privileged operations or broaden Wing Link.
  The previous local sidebar toggle remains implemented and locally verified,
  with independent source review and 2,397 passing parent tests attributed to the
  [first-wave receipt](docs/quality/2026-10-03-desktop-port-first-wave.md).
  Its runtime/card acceptance is not observed. Copy session ID and shell polish
  are supporting slices, not substitutes for the complete workflow.
  Continuation ownership remains in the
  [goal ledger](docs/plans/2026-10-03-desktop-port-goal.md). Job `6f218a559ed2`
  has a recorded 10-minute cadence and local output, but the
  [latest recorded preflight](docs/quality/2026-10-04-desktop-cron-0322-auth-preflight.md)
  paused it for missing provisioning; no automatic resume is authorized. This is
  documented status, not a live scheduler check. The [root handoff](TODO.md)
  indexes blocked next gates, not newly authorized implementation work.
- **Existing open work (status preserved):** finish exact-session restoration acceptance on `t_f098a32e` without
  reimplementation or waived review, then real production Chat qualification and
  full Linux/native and compiled-web validation on `t_38174cb7`, including
  loaded-transcript save and production Chat fixtures. The parallel bounded
  M1/M4 jobs/health/Persona readiness correction is implemented with
  regression-first tests and parent reruns of 212 focused tests plus a clean
  analyzer; [receipt](docs/plans/2026-10-03-study-follow-through.md#executed-bounded-receipt).
  Independent source review found and then confirmed resolution of the Persona
  context edge, with no further scoped findings. Reports now enforce the existing exact
  operation/all-grants/profile-context gate; no endpoints, writes or action
  permissions were added. The restoration/gateway-switch matrix also passed 116
  tests in independent worker execution and parent rerun, without closing its
  native handoff/same-card or browser/runtime gates. Historical Now wording reported
  independent review for M1's deterministic Chat slice and browser export; M1's
  card wording below still records pending review. Preserve the attributed receipts,
  not a new acceptance claim. Actual Agent inference must use the
  owner's selected `gpt-6.1-sol` / `openai-codex` on a disposable target.
  Local-model inference has stopped. Earlier reports found no Codex credentials
  on the isolated target and requested supported private OAuth provisioning;
  freshly recheck authorized target/auth and native build prerequisites rather
  than treating that historical state as permanent impossibility. No personal
  credential scanning/copying or provider substitution. Live qualification is not
  yet accepted. Native-web gates remain conditional. The same-card status of
  `t_19a425b2` is inconsistent across historical receipts; exact card/receipt
  readback is required before any new acceptance claim.
- **Next — Workflow-supporting Desktop composition and Chat fidelity:** after
  the first daily-workflow receipt, source-trace pinned/footer
  navigation, profile switching, sidebar recents and session-modal access, then
  composer, transcript and tab interactions using the
  [parity ledger](docs/product/hermes-desktop-parity.md) and
  [UI gap audit](docs/product/hermes-desktop-ui-gap.md). Port supported presentation
  independently of missing administration contracts; record every difference.
  Full tabs/close-stop behavior needs exact Agent identity and terminal readback;
  a current-session status pill is not tab parity. Responsive layouts are explicit
  deviations, never replacement parity goals. In parallel retain M2 Android continuity
  on a named target, then M5 native output and
  accessibility, isolated M3 trusted setup and separate M6 release lifecycle
  qualification. Installation/update/rollback runtime evidence remains a subsequent
  outcome, not a blocker for bounded Linux/web validation. M4 supported reads stay
  available; missing Project/provider/push/admin contracts block only their subparts.
- **Later — Remaining Desktop surfaces and qualified distribution:** Discover,
  memory, Kanban, complete provider/schedule/tool/gateway administration, Office
  interactions and native install/update behavior remain gaps until their exact
  contracts and named-platform evidence exist. Continue remaining M4 administration
  and M5 output/native polish where each
  contract is qualified, then integrated M6 alpha. Accessibility starts now;
  voice/acoustic and optional Office/3D/account expansion follow reliable text.

Dependency spine: **M1 → M2 → M6**. Existing M3 setup, M4 reads and M5 export/
accessibility may proceed independently; new operations pass individual gates.
M6 integrates accepted applicable outcomes and names deferrals. No cards created here.

## Six outcome milestones

### M1 — Connect and complete real work reliably

- **Outcome:** supported local connection → explicit profile/model/session →
  real generated text → correlated tool/approval → authoritative stop → leave and
  relaunch into exactly the same session with canonical recovery, without cross-owner data
  or duplicate sends. **Status:** existing advertised Agent path implemented;
  integrated current-target qualification and conditional native-web migration open.
  `t_19a425b2` adds a self-tested [production Chat fixture journey](docs/runbooks/chat-production-journey.md)
  through compiled Chromium at 390/1280px: correlated approval/denial, terminal
  Stop versus acknowledgment, unavailable transport/explicit reconnect, canonical
  history and a subsequent prompt without replay. Independent same-card acceptance
  is pending; fixed fixture output is not real Agent/provider or Android evidence.
  Revision regressions also isolate rejected cross-session run cleanup from
  transcript admission, including terminal and uncertain rollback outcomes.
  Volatile cleanup ownership also gates later explicit owner selection until
  authoritative terminal/history reconciliation; local cancellation is not proof.
  Native approval regressions/fixture receipts use Agent's exact `request_id`,
  with stale-request conflicts and no in-flight/answered response reuse; this is
  deterministic client evidence, not actual scoped-auth/provider qualification.
- **Next slice / seam:** exercise existing [HermesChannel](lib/core/hermes/channel/hermes_channel.dart)
  and channel provider; fix reproduced gaps, preserving reviewed transcript/picker.
  Selected native-web mode needs a typed production adapter/auth flow after gates.
- **Dependencies:** disposable target and generation consent below. Native-web
  additionally needs authority/acquisition selection and supported cancellation;
  its internal opt-in is not an authorization or a replacement for `/v1` discovery.
- **Exit evidence:** channel tests reject stale profile/session frames and unknown
  submit replay; compiled Chromium regression preserves the existing path; actual
  unmodified Agent + Flutter journey proves generated output, controlled harmless
  tool/approval, authoritative stop and reconnect. Record named Android target
  and selected web/desktop targets separately; socket closure is not server stop.
  Use the [compatibility qualification checklist](docs/runbooks/hermes-agent-release-compatibility.md).

### M2 — Leave and return without losing ownership

- **Outcome:** Android background/death/relaunch reconciles the right Agent-owned
  conversation/run without resend; status works with notification permission denied.
- **Status / next slice:** current-source process-death qualification is open.
  Start with one running→completed relaunch journey on the existing advertised
  run mode, using [chat lifecycle](lib/features/hermes_chat/screens/state/hermes_chat_lifecycle.dart)
  and [secure detached-run store](lib/core/hermes/setup/secure_hermes_detached_run_store.dart).
- **Dependencies:** M1 run mode + named Android target; native live-session resume
  is not durable detached work. Draft/attachment durability needs a [retention decision](docs/product/continuity-retention-proposal.md);
  push separately needs the [notification contract](docs/product/notification-contract-proposal.md).
- **Exit evidence:** store/channel tests plus Android background, forced death,
  relaunch, expired/revoked credential and wrong-owner cases show canonical history
  and zero duplicate sends. Qualify push separately: denied permission, generic
  lock-screen text, expired/wrong-device handles and explicit tap navigation to
  the exact tuple; no tap sends text or answers approval. No permanent socket claim.

### M3 — Trusted onboarding into a useful profile and workspace

- **Profiles, directories, and Projects:** approved directory handles expose
  child folders only. Project-aware Chat remains gated on an exact authoritative
  Agent contract, with mutation hidden until an exact route and grant are available.
  File listing, preview, reading, or editing through Wing Link is not authorized;
  Agent-owned artifact retrieval is a separate, individually gated operation.
- **Outcome:** pair, choose/create a profile, configure supported provider/model
  setup, and enter authoritative Project/persona context without hidden host writes.
- **Status / next slice:** setup exists; Project creation/chat and existing-profile
  compatibility writes remain gated. Qualify enrollment→new-profile→explicit Chat
  through [Profiles](lib/features/profiles/screens/profiles_screen.dart) and
  [Wing Link setup](docs/product/wing-link.md), not a second provider screen.
- **Dependencies:** separate credentials, approved roots; Project operations/chat
  and SOUL read/write require individual authority. Existing-profile provider
  add/replace/remove/assignment needs [transaction criteria](docs/adr/api-and-state.md#required-agent-owned-mutation-contract),
  not new-profile rollback. Catalog read does not grant writes.
- **Exit evidence:** profile/provider/directory/SOUL widget and Go boundary tests;
  Chromium setup and named Android secure-input/pairing journeys; isolated actual
  setup receipt. For supported Project/provider writes prove conflict, identity
  recreation, revocation and unknown-outcome reconciliation; distinguish saved,
  validated and activated. No implicit inference/restart on existing-profile save.

### M4 — Discover and administer supported Agent work

- **Outcome:** equip a profile and inspect/manage its memory, scheduled work,
  Kanban and host/platform status without confusing unavailable with empty.
- **Status / next slice:** skill/toolset/job inventory and health exist; discovery/
  MCP mutation, memory and Kanban are conditional ([routes](docs/product/routes.md),
  [parity ledger](docs/product/hermes-desktop-parity.md)). First conditional slice:
  bounded profile-scoped discovery catalog search/selection through existing
  [Tools](lib/features/tools/screens/tools_screen.dart); defer only that operation
  if unavailable. Preserve [Schedules](lib/features/schedules/screens/schedules_screen.dart)
  and [Connections](lib/features/gateway/screens/gateway_screen.dart) independently.
- **Bounded inventory evidence:** `t_3348dc5c` repairs owner-scoped local Tools
  search and adds independent accessible clear actions without extra reads or
  mutations. Executor verification passes 407 Tools/channel/Schedules tests and
  six compiled Chromium Tools/Schedules journeys repeated three times at
  390/1280px, retries disabled. [Runbook](docs/runbooks/tools-search.md) records
  semantic-input/disclosure and stale-read evidence; same-card acceptance passed
  executor62 → tester63 → reviewer64. This does not provide discovery/MCP APIs, actual Agent
  generation or completion of the full-platform qualification card.
- **Dependencies:** individual exact operations/grants/current resources for
  discovery catalog/install/remove, MCP config/toolset changes, memory entry/profile/
  capacity/provider reads and writes, job CRUD/pause/run/delivery, board/task reads
  and mutations, Agent messaging-platform admin and Wing Link host lifecycle.
  Host trust expansion/peer administration remains local; no second dispatcher.
- **Exit evidence:** per-operation decode/auth/conflict/revocation tests, inventory
  widgets (including [schedule refresh](test/features/schedules/schedules_screen_test.dart)),
  Chromium and named Android journeys, then isolated authoritative readback of
  each actual mutation/job result. Linux service actions additionally need real
  systemd-user health/rollback receipts. Missing contracts precisely defer their
  operation; they do not freeze the already-supported inventory.

### M5 — Safely take away output, with native accessible interaction

- **Outcome:** native read/copy/export and supported artifact save/preview, operable
  without speech, pointer precision, motion, sound, color, canvas or 3D.
- **Status / next slice:** loaded-transcript copy and bounded media already exist
  ([rich-transcript tests](test/features/hermes_chat/screens/hermes_chat_rich_transcript_test.dart));
  browser loaded-transcript UTF-8 text/Markdown export passed same-card independent
  review with download-event/readback evidence at 390/1280px. Linux GTK export has
  six executor native readback/cancel/owner-change checks. On `t_38174cb7`, the
  original input suite passes on a named real IBus X11/GTK target, the repaired
  Markdown viewport passes the original ten-case native profile stress matrix,
  and the locked-toolchain unit/widget suite passes. Disposable live-service
  authorization is resolved, but the owner-selected Codex model still needs
  supported private target authentication; complete live results and same-card
  independent acceptance remain open
  ([export runbook](docs/runbooks/chat-transcript-export.md)). This is
  not M5 completion or release/save/share qualification on other platforms. Next,
  qualify Android copy/save/share and focus/IME/TalkBack on the existing text path.
  Add typed artifact retrieval/preview only after its own allowed contract.
- **Dependencies:** artifact identity/auth/MIME/size/content bounds; folder-only
  directory grants confer no artifact access, but safe Agent-owned artifact content
  is not forbidden. Reuse media/native export seams, never arbitrary host paths.
- **Exit evidence:** hostile/inert preview and redaction tests; explicit OS save/share
  denial/cancel, large output, keyboard/CJK IME, 200% text, reduced motion and
  TalkBack receipts on named Android; corresponding browser/native desktop checks
  only on targets exercised. Keep [message-action accessibility](test/features/hermes_chat/screens/hermes_chat_message_actions_a11y_test.dart).
  Voice needs separate physical microphone/acoustic receipts; Office keeps its 2D
  equivalent. Account/wallet/3D additions cannot bypass separate authority gates.

### M6 — Deliver an integrated, qualified alpha

- **Outcome:** a person installs a verified artifact, completes the supported
  workflow, upgrades safely and can recover/uninstall. **Status:** not release-ready.
- **Next slice / seam:** one source/artifact-bound Android alpha using existing
  [release tooling](docs/runbooks/release-alpha.md) and [Android handoff](docs/runbooks/android/release-handoff.md).
- **Dependencies:** accepted applicable M1–M5, channel/signing custody/publication
  permission. Document deferrals: no full-parity claim, but scoped alpha may proceed.
- **Exit evidence:** complete repository gate below plus exact-artifact Android
  install/upgrade/rollback/uninstall and integrated connect/profile/chat/tool/
  approval/stop/death/recovery/export/accessibility receipts. Separate actual backend,
  browser, Linux/macOS/Windows host, service, physical voice and store delivery
  evidence; neither cross-compilation nor an APK launch qualifies them all.

## Existing three executable qualification briefs

The daily-use workflow above is the leading implementation/qualification target;
these existing briefs preserve open cards, not the old shell-polish priority order.
Every implementation/revision follows **executor → tester → reviewer on the same
card**. Default scopes/serializes after overlap checks; no worker start is promised.

1. **Recover exact-session review (`t_f098a32e`).** Triage/lifecycle blocked.
   Owner resolves the native handoff gate; default verifies routing, executor preserves delivery.
   Tester proves the [runbook failure/race/browser matrix](docs/runbooks/chat-session-restoration.md#deterministic-verification),
   including page-two reload/exact IDs/zero mutations; reviewer accepts or requests
   revision. No reimplementation, waived review or duplicate card.
2. **Prove M1's production journey.** Deterministic production-client slice
   `t_19a425b2` is implemented/self-tested, pending tester → reviewer on that card;
   see its [reproduction and limits](docs/runbooks/chat-production-journey.md).
   Real inference remains input-gated: disposable backend/model/network/
   cost consent + target. Default/owner selects mode; executor uses channel/enrollment/
   Chat with regressions for observed gaps, proving generation/tool/approval/stop/
   reconnect. Tester repeats; reviewer accepts named targets only. Native-web first
   passes the checkpoint below; no RPC bridge/synthetic grants/test-cookie login.
3. **Prove M2's Android relaunch.** Target/input blocked. After supported M1 run
   evidence, executor uses existing store/lifecycle across background/death/relaunch;
   tester proves tuple/history/no resend, reviewer accepts the Android receipt.
   Durable drafts/push have separate consent/contracts; no backend-wide freeze.

## Blockers and the smallest unblock choices

- **Native interruption:** keep `t_43937159`'s unmet gate. Choose a supported
  unmodified provider-free path, or authorize one disposable initialization-only
  target/network policy. No generation consent or synthetic-agent acceptance implied.
- **Conditional native-web authority/acquisition:** owner selects whether one
  gated dashboard host/account may authorize restricted fixed-chat operations,
  defining authority/expiry/logout/revocation/fail-closed limits and its supported
  platform credential flow. Review necessary ADR changes separately; no universal
  PKCE demand, fixture-cookie login or reusable-token URL fallback.
- **Real generation:** name a disposable provider/model, harmless input/tool,
  allowed network and billing ceiling. Provide secrets through supported private
  secure input, never roadmap/card metadata, argv, diagnostics or URLs.
- **Android:** name device/emulator, OS/API and access for death/secure-store/pin/
  TalkBack/background receipts; 390px Chromium is not an Android device.
- **Only when relevant:** physical mic/acoustic target for voice; relay contract,
  operator and delivery credentials for push; signing/store accounts/channel and
  publication authorization for distribution. None blocks text-only UI work.

**One contract-selection checkpoint per conditional operation:** trace unmodified
Agent handler/tests + Wing caller/regression; implement a verified allowed contract
or precisely defer the missing operation/authority. Revisit on changed evidence/
decision only, not repeated diagnostic cards. Projects/provider writes/MCP/discovery/
memory/jobs/Kanban/host/platform admin/artifacts pass independently.

Hard boundaries: exact operation/grant/resource gates, explicit identity/concurrency;
server wins, no offline mutation replay. No Agent edits/arbitrary CLI/config/path/
shadow state/Wing Link data-plane proxy. Separate credentials, fail-closed native pins,
browser HTTPS trust and local approvals remain; see [API/state](docs/adr/api-and-state.md),
[security](docs/adr/security-and-privacy.md), [runtime](docs/adr/runtime-and-delivery.md).

## Milestone and release evidence gate

Supply revision/diff, artifact digest, SDK/tools, target/OS, commands/results and
sanitization; separate fixture/Agent/Android/physical/service/store evidence. Recent
UI used Flutter 3.47.5 / Dart 3.13.4, not intended Flutter 3.44.2; record each SDK.
Old [matrix rows](docs/quality/evidence-matrix.md) do not qualify current source.

Integrated M6 gate is exactly [CONTRIBUTING required checks](CONTRIBUTING.md#required-checks):

```bash
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze
flutter test --concurrency=1
(cd wing_link && go test ./...)
flutter build web --release -t lib/main_e2e.dart
npm run web:e2e
npm audit
git diff --check
```

Follow CONTRIBUTING for relevant visual regeneration. This docs-only rewrite needs
link/anchor/diff checks, not runtime suites; no product milestone or release completed.

## Historical leads, not an active backlog

[August do/test](docs/plans/2026-08-10_193813-wing-next-do-test-roadmap.md),
[Conduit receipts](docs/superpowers/plans/2026-09-04-conduit-adaptation-roadmap.md) and
[audit remediation](docs/superpowers/plans/2026-08-17-audit-remediation.md) are historical, not
current device/tool/debt availability or priority. Verify code; living ADRs/code/review
override planning. No speculative refactor milestone.
