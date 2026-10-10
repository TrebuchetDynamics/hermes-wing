# Hermes Wing test plan

The only Desktop product reference is [Nous Research Hermes Desktop](https://github.com/NousResearch/hermes-agent/tree/main/apps/desktop),
locally `hermes-agent/apps/desktop/`. Prior separate-app comparisons are
[withdrawn as official parity evidence](quality/official-desktop-reference.md).
Existing Wing test results do not establish parity with this corrected reference.

Status: verification strategy, not an execution receipt.
[Product requirements](product/prd.md) own product acceptance. This plan owns
verification methods. The [evidence matrix](quality/evidence-matrix.md) records
qualification; individual receipts must identify the source, target and limits.

## Away-and-return status verification

This planned matrix implements [user-demand acceptance](product/prd.md#user-demand-emphasis),
not a passing receipt. M1-MOBILE-AWAY-STATUS reuses production recovery and existing
fixtures, then qualifies only the missing Android status/return interactions.
Use the isolated QA app in Waydroid. Keep physical process-death qualification
under M2-DEVICE-QUALIFICATION and actual provider access under existing live tasks.

- Suspend Wing while the fixture's Agent-owned run remains running, then changes
  to completed or failed. Return through production controls and read canonical
  history/outcome for the same host/profile/session/run.
- Disconnect while absent. Show unknown/disconnected status rather than false
  completion. Explicit Retry restores authoritative status without mutation replay.
- Keep approval-needed status actionable only under current exact-owner grants.
  Replacing the connection/profile while reads are pending rejects late old-owner
  results and never replays an approval.
- Assert zero incidental send/create/approval/Stop calls during suspension,
  restoration and status refresh. One deliberate action permits only its intended
  request. Check compact controls, enlarged text and permission/error messaging.
- Record exact APK/source, Android environment, commands, request counts and
  outcomes. Existing Linux GTK or Chromium passes do not qualify Android.

M1-NOTIFICATION-CONTRACT assesses supported notification operations after this
slice. No APNs/FCM/relay integration is approved by this matrix. Real delivery,
permission denial, privacy and exact-owner tap behavior need their own subsequent
reviewed platform checks.

## Idle approval withdrawal regression

For the internal `HermesWebLifecycle`, receive a correlated approval, then process
an ordered `request.cancel` while no local turn is running. The matching request
must disappear. A later response attempt must send no approval mutation. Repeat
for a running turn and preserve profile/session/sequence rejection.
`test/core/hermes/client/hermes_web_lifecycle_test.dart` contains the idle and
running withdrawal regressions at `8866604b`. Their existence is source evidence,
not an executed pass in this documentation run. Production-control wiring and
isolated Linux workflow qualification remain with WING-TASK-406, after its
transport predecessor. Do not transfer earlier lifecycle or settlement receipts
to changed tests without checking the complete relevant input closure.

## Profiles consumer-removal verification

[The isolated candidate](quality/profiles-agent-only-follow-through.md) reports
focused widget success, scoped analysis success and full-analysis failure.
Retained rework output confirms the previously failing pending-credential probe
now passes. Independent review approved the same isolated correction. Preserve
that regression when assembling the combined candidate. Capture its dependency
closure, repair the missing fixture/import inputs and retire excluded legacy
fallback expectations through their existing owners. The smallest next check is
the pending-recovery probe and focused Profiles/editor targets on that assembled
source, not a repeat of unchanged branch qualification. Count directory recovery
callbacks too. Assert zero
Link constructions/requests under absent or denied Agent access, exact native
operation paths and rejection of late results after owner replacement. Then run
full analysis and existing combined-source/browser gates. GTK, Android, live
authentication and main delivery require separate evidence.

## Terminal working-directory files (planned)

[FILES-1 through FILES-4](product/prd.md#terminal-working-directory-files)
require separate Linux and Android qualification; no feature execution is claimed.
The [feasibility study](analysis/terminal-files-feasibility.md) contains executed
static source checks, not HTTP integration or native save evidence.

- Test the exact compatible `serve` connection and actual file authentication.
  Messaging-API-only connections must report file access as unsupported. Distinguish
  missing routes from 401/403 denial, timeout, malformed responses and server errors.
- Use two profiles with distinct session directories, including a secondary profile
  on one process. Default-cwd must not substitute the launch profile. Verify the
  selected backend; unsupported container/cloud targets must not show host files.
- Establish the server's canonical read boundary before enabling strict root access.
  Test symlinks pointing outside the selected root and disallowed absolute/relative
  paths. A UI prefix check or hidden parent button is not passing containment evidence.
- Verify file credentials stay in authenticated headers, not URLs or external-browser
  handoffs. Do not treat successful SSH authentication as HTTP authorization.

- Browse the authoritative selected terminal root and nested folders with keyboard
  and touch. Empty, denied, missing-root and disconnected states are explicit.
- Switch host/profile/session during listing or preview: old-owner results must
  not appear in the new context. Traversal and symlink escape must fail closed.
- Open bounded text and oversized/binary/active-content examples: supported text
  is selectable, unsupported previews are explained, and nothing executes.
- Deliberately download text and binary files through each platform's save picker;
  read back the saved bytes and compare with the selected source. Test Unicode
  and hostile filenames, destination conflicts, cancellation, permission denial,
  transfer interruption and explicit retry. No false success or silent overwrite.
- Verify browse/read/download performs no prompt submission, terminal directory
  change, Agent file mutation, Wing Link request or content/credential logging.

## Mobile reference scenarios

The [Hermes Mobile study](quality/hermes-mobile-reference-study.md) is source-only
evidence. The scenarios below are planned checks, not executed results.
Use existing channel, lifecycle and transcript fixtures. Preserve current task
dependencies and platform qualification boundaries.

| Scenario | Observable expected outcome | Disposition |
| --- | --- | --- |
| Grouped tools include errors and a running last item | Recovery preserves canonical ordering and error identity. Expanding the group remains keyboard-operable. | Existing CHAT-FIDELITY native/restart task acceptance. |
| Activity becomes stale during disconnect/restart | The UI does not infer successful completion. Canonical recovery retires obsolete approvals and sends zero mutations. | Existing CHAT-FIDELITY recovery acceptance. |
| Suspended timers and repeated foreground transitions | Requests remain bounded and old-owner results cannot replace the current origin/profile/session. Separate probe and inventory freshness. | Candidate regression refinement of existing lifecycle behavior, not a new battery claim. |
| Partial diagrams, malformed fences, table copy and code wrap | Source remains readable, controls work with keyboard and enlarged text, and copied content is exact. Rendering remains bounded. | Conditional on selecting the proposed renderer features. |
| Notification tap targets expired or replaced work | Revalidation rejects obsolete work and generic lock-screen text exposes no private content. No decision replays after reconnect. | Proposal only; follow the notification contract before implementation. |

Do not claim physical Android sleep, notification delivery or energy savings from
fixtures. Measure those outcomes on the named device and exact source if selected.

## Scope and environments

Test the Flutter client and Wing Link without modifying Hermes Agent.
Use deterministic, redacted fakes for unit, widget and browser regressions.
Exclude upstream reference clones from Wing formatting, test scope and builds.

- Flutter unit/widget tests exercise shared behavior and provider overrides.
  They do not establish native plugin, screen-reader or physical-device behavior.
- Waydroid is the selected Android QA environment: Android runs in a Linux
  container. Use the isolated `.qa` app, authenticated ADB and the
  [Android fixture procedure](runbooks/desktop-feature-qualification.md#android-maestro-fixture-run).
  Wing owns reversible user-space connectivity and tooling preparation; do not
  ask the owner to supply a physical phone for these checks. Record exact APK,
  source, target, driver, assertions and per-flow exits. Running Waydroid or an
  ADB listing alone does not qualify app behavior. Keep physical-device process
  death, secure storage, speech and hardware outcomes separate.
- Chromium tests use the compiled `lib/main_e2e.dart` target and deterministic
  fixture. Fixture generation is not actual provider inference.
- Native integration tests require platform tooling, isolated owned preferences
  and a real app launch. Widget remount is not process relaunch.
  For sidebar persistence, the provider and shell regressions cover restoration,
  early interaction, ordered writes, storage failure and adaptive return.
  See the [graph-guided refactor receipt](quality/graphify-shell-persistence.md).
  Its final repair log records 3,711 passing Flutter tests. The six owned file
  hashes match the retained receipt, but this is not a full current-tree manifest.
  Subsequent SSH changes need separate integration and named-platform checks.
  Native acceptance still requires two app processes sharing isolated preferences,
  followed by a separate wide-to-compact-to-wide keyboard/draft check.
- Live Agent/provider tests need an approved isolated target, supported private
  authentication, exact grants and consent for network use and bounded mutations.
  Do not use personal credentials or bypass authorization. The owner selected a
  disposable local QA Agent/profile for the daily-use milestone. Wing owns its
  implementation and QA. The [owner update](plans/2026-10-03-desktop-daily-workflow.md#owner-update--wing-implementation-and-qa)
  defines the three-generation limit, separately authorized test access and no
  unapproved metered spending. Target selection is not authentication or execution
  evidence. Keep native, fixture and live outcomes separate.
- Physical microphone, speech, accessibility and service/release checks require
  matching target receipts. Compilation is not runtime qualification.

## Android private release verification

The [private APK handoff](runbooks/android/release-handoff.md#private-release-apk-handoff)
uses the isolated `.qa.release` identity, not the paired app or debug `.qa` app.
[`android_private_release_test.dart`](../test/tooling/android_private_release_test.dart)
checks the opt-in flag, suffix and required signing guard in the Gradle source.
This source-contract test does not inspect an APK or launch Android.

For the exact artifact, verify package, ARM64 ABI, version, approved public signing
certificate, ZIP integrity, native AOT code and absence of debuggable/kernel output.
A missing signing configuration must reject private-release configuration rather
than fall back to the debug key. Inspect the retained private-release receipt only
for its attributed build. Changed source inputs need new qualification evidence.
Install, launch, upgrade and recovery on a named Android target remain separate;
a signed private APK does not qualify an AAB or publication. The existing M6
same-artifact receipt task owns this gap.

## Risk-based scenarios

### Reference fidelity verification

Compare each product slice with its pinned Desktop screen/component, not just an
API outcome. Capture matching states and viewports for welcome, navigation, Chat,
sessions, profiles and settings. Record differences in layout, hierarchy, wording,
interaction and recovery separately from functional passes. These comparisons are
planned requirements, not checks executed by this documentation pass.

For fresh isolated app storage, first launch must show Desktop-guided welcome
before the connected shell. Verify primary connection actions, unsupported-action
explanations, keyboard focus, compact layout, enlarged text, Back, cancellation,
sanitized errors and explicit retry. No Wing Link request or credential is required.
After connection, screen title, content and selected destination must agree.
Relaunch with a saved owner must restore the appropriate state without sends or
other mutation replay. Preserve existing owner-fencing regressions.

The [welcome receipt](quality/desktop-welcome.md) records 41 focused widget passes
and four compiled Chromium journeys at 390/1280px with normal/200% text. They
exercise keyboard entry, cancellation, sanitized 401, explicit Retry and saved-owner
reload with zero Agent mutations and Wing Link requests. This is inspected executor
evidence for its frozen candidate, not a new product run or native qualification.
Of 569 recorded inputs, 565 still match; four later app/shell/test inputs differ.
Do not apply that result to the entire current worktree. The
[welcome recovery receipt](quality/desktop-welcome-recovery.md) separately records
34 focused widgets, four native Linux write journeys, fresh-process restoration
and four rebuilt Chromium journeys. Welcome-only widget-order traversal repairs
keyboard Back at enlarged text. The endpoint store is synthetic; preferences are
isolated Linux storage. Android, physical keychain and live authentication remain
unqualified. These are inspected retained results, not product checks rerun here.

Qualify this against the exact Android handoff artifact on an authorized disposable
target and against native Linux independently. Widget/browser connection receipts
and signing checks cannot establish delivered welcome parity. Retain the reference
pin, source/artifact identity, captures, exact commands and observed differences.

Use the [Desktop feature matrix](product/hermes-desktop-feature-matrix.md) to map
feature IDs to Android Maestro candidates and native Linux Flutter counterparts.
The [execution runbook](runbooks/desktop-feature-qualification.md) defines safe QA
targets, commands and per-feature receipts. Syntax, fixture, native and live
results remain separate. The matrix has explicit missing-flow cells and does not
claim complete per-operation coverage or current 1:1 acceptance.

The [approval/attachment fixture receipt](quality/android-approval-attachment-fixture.md)
records seven Linux-hosted Flutter widget passes and four mocked wrapper checks.
Approval controls submit three turns, two decisions and one Stop; reconnect retains
the session without changing those counts. Deferred attachment completion after
owner replacement stages nothing for either session, and a subsequent pick works.
The earlier-history tail is not covered by these new widgets. Android startup
failed before launch on the unreachable enrolled target. All actual Android
assertions remain NOT_CHECKED; PARITY-MAESTRO-ANDROID-DEVICE owns their execution.

| Area | Observable expected outcome | Existing check or owner |
| --- | --- | --- |
| Connection and authorization | Invalid/revoked authority is rejected; unsupported and failed optional resources are not presented as empty supported data. | `test/core/hermes/`; [readiness audit](runbooks/hermes-readiness-audit.md) |
| Profile/session ownership | A late old-owner result cannot change the replacement profile, session, draft or history. An off-page remembered session is restored by identity, not inventory position. | `test/features/hermes_chat/gateways/`; `test/features/hermes_chat/screens/`; [daily-use matrix](plans/2026-10-03-desktop-daily-workflow.md#acceptance-matrix) |
| Streaming and reconciliation | History/run readback resolves missing or interrupted delivery; reconnect produces no implicit resend. Unknown outcomes stay fenced until reconciliation. | `test/core/hermes/`; [platform smoke](runbooks/hermes-platform-smoke.md) |
| Approval and Stop | Responses remain correlated to the actual request/run. Stale/repeated actions cannot answer a replacement request. Stop needs an authoritative terminal outcome. | [daily-use matrix](plans/2026-10-03-desktop-daily-workflow.md#acceptance-matrix); `playwright/tests/regression/desktop-daily-workflow.spec.mjs` |
| Session/queue mutation | A confirmation acts on its original owner and displayed object, not a replacement session or mutable row index. | [mutation runbook](runbooks/chat-session-mutation-intent.md); [queue runbook](runbooks/chat-queued-follow-up-intent.md) |
| Clipboard and preferences | Success is reported only after clipboard settlement; rejection is contained. Same-store settled pin commits preserve the latest deliberate choice without automatic retry. | [clipboard runbook](runbooks/chat-transcript-copy-outcomes.md); [pin-order runbook](runbooks/chat-session-pin-write-order.md) |
| Sidebar presentation persistence | Fresh provider scopes restore the saved expansion choice. Late loading cannot overwrite a newer click; serialized writes retain interaction order. Failed storage leaves the shell usable. Native relaunch needs a separate check. | [widget receipt](quality/graphify-shell-persistence.md); `test/features/settings/providers/shell_preferences_provider_test.dart`; `test/shared/widgets/app_shell_sidebar_persistence_test.dart` |
| Management security | Grants, revisions, local approvals and idempotency bind the exact device/resource/payload. Changed replay, revoked roots and symlink escape fail closed. | `wing_link/internal/`; [threat model](security/threat-model.md) |
| Retired OmniRoute integration | Former CLI flag/command, discovery route/capability and special profile setup are unavailable without installer/network/service actions; no bundled npm assets or release component remain. Generic Agent catalog entries and historical audit data remain valid. | `wing_link/internal/app/omniroute_retirement_test.go`; `wing_link/internal/protocol/retirement_test.go`; `test/tooling/omniroute_retirement_test.mjs`; `test/features/profiles/profile_catalog_test.dart` |
| Accessibility and adaptation | Keyboard-only operation, focus, readable text, large text and reduced motion remain usable across wide and compact layouts. No action requires sound, color, speech or canvas alone. | `test/shared/`; `test/features/`; [daily-use matrix](plans/2026-10-03-desktop-daily-workflow.md#acceptance-matrix) |
| Release and recovery | Candidate artifacts match their digests and required signatures; activation/recovery evidence belongs to the actual named platform. | [alpha release runbook](runbooks/release-alpha.md); [evidence matrix](quality/evidence-matrix.md) |

Existing test directories are coverage entry points, not proof that every scenario
is automated or passing. Inspect the nearest tests and receipts before advancing
a claim. The daily-use matrix defines more specific failure and boundary cases.

## SSH private-key qualification

The later [generation/Help receipt](quality/connection-key-generation-help.md)
records a clean full analyzer and 132 passing focused-union tests, including
production generated-key consent, public-only clipboard, secure-store readback,
reuse, failure and stale-operation fencing. It does not qualify real keyrings or
clipboard plugins. Native checks must additionally prove generated identity
persistence across process restart, deliberate saved-key selection, fail-closed
keyring denial and public-only clipboard through the real platform implementations.


The [Desktop key trace](product/desktop-connection-paths.md#private-key-ux-desktop-reference-and-wing-adaptations)
separates inspected upstream behavior from Wing's implemented key UI. The current
development form exposes deliberate key/password selection and encrypted-key input.
Fresh parent verification passed 72 focused Flutter tests. This includes production
controls, bounded reads, cancellation, encrypted keys and separate Agent auth.
The result is scoped to those tests, not native picker or device qualification.
The [pinned graph comparison](quality/graphify-wing-recomparison.md) records source
gaps and a focused run with 31 passes and three failures during concurrent edits.
That run does not qualify the final snapshot. Keep bounded reads, stale-picker
fencing, enlarged-text keyboard reachability and encrypted-key recovery explicit.

For native key-UI qualification, test deliberate Linux file selection and Android document
selection independently. Cover cancellation, unreadable/revoked selection,
oversized input, malformed or unsupported keys, encrypted keys, wrong passphrase,
correct passphrase, explicit password fallback and secret cleanup. Invalid input
must not authenticate. Stale picker or host-trust results must not revive an old
attempt. A successful SSH connection must still authenticate separately to Agent.
Never display or capture private-key contents, passphrases or private host paths.

Full-app qualification must run on both native Linux and Android against the
owner-approved host using Wing's own managed form, not an external OpenSSH tunnel.
Record device-to-host reachability, reviewed host key, SSH authentication, Agent
readiness, profile/model selection, canonical history, disconnect and deliberate
reconnect per target. Keep changed-key rejection and zero mutation replay explicit.
Generation/approval/Stop tests retain their existing isolated-target and usage
limits. Terminal login on the server itself cannot qualify either application.
Both native key-UI journeys remain NOT_CHECKED. The executable preparation harness
is `scripts/run_managed_ssh_key_native.sh`, with integration controls in
`integration_test/managed_ssh_key_native_test.dart`. Seven Python preparation tests
passed using the isolated QA venv. The harness uses a supplied document to exercise
the real transport, so it cannot qualify the operating system chooser. No live
provider or owner-host application test ran.

## Connection-path verification

Wing Link is deprecated. Replacement acceptance requires zero Wing Link requests,
installation prompts, pairing credentials or CLI QR prerequisites through Local,
SSH and Remote. Linux Local must inspect the default Hermes home and accept an
explicit alternate directory without reading secrets or treating existence as
readiness. Android Local must provide on-phone setup, explicit consent and return
recovery, then a separate authenticated Agent check. Neither path may patch Agent,
copy personal credentials or silently replay installation/mutations.
Retirement tests must preserve existing Agent endpoint/session ownership and
paired state. Features whose only implementation uses Wing Link must either move
to an exact advertised Agent contract or explain unavailability. Native chooser,
phone setup, lifecycle and full-app connection checks remain separate from mocks.

This matrix covers [CONN-1 through CONN-6](product/prd.md#connection-path-requirements).
It describes required checks, not executed results. The
[source comparison](product/desktop-connection-paths.md) records implemented
three-primary-path grouping, four transport modes and development managed SSH.
Private-key production-control regressions pass; native live SSH qualification remains open.
The [entry receipt](quality/connection-primary-entry.md) records 13 widget passes
and four compiled Chromium journeys for grouping, keyboard access and owner-safe
cancel/back. Retained logs were inspected, not rerun in this documentation pass.
These checks do not qualify native setup, managed SSH or live authentication.
The later [first-run receipt](quality/direct-first-run.md) separately records
123 focused widget passes, four dedicated widget passes and ten compiled Chromium
journeys on Linux. Public-route keyboard entry, auth-denial/explicit-retry and
optional-management recovery pass. All 15 selected source/lock fingerprints match
this inspected snapshot; six browser traces contain no management requests or
mutations. This pass inspects retained logs, not a new product run. Node 26 ran
those checks, not the documented Node 22. The
[native first-run receipt](quality/direct-first-run-native.md) adds four passing
Linux GTK production-router/Chat journeys at 390/1280px and 1x/2x text. Retained
logs record 17 focused Flutter passes and five launcher regressions. Native traces
record zero management, mutation and forbidden-read attempts through synthetic
denial, explicit keyboard retry and owner replacement. All 754 candidate input
hashes match this inspected snapshot; this is source binding, not a fresh product
run. Injected endpoint storage does not qualify physical secure storage. Live
authentication, Android, the broader combined gate and main delivery remain open.
The [saved-host receipt](quality/saved-connection-owner-safety.md) records 122
focused widget passes and two freshly compiled Chromium journeys at 390/1280px.
Four selected source/test fingerprints match this snapshot; the removed generated
web artifact cannot be rehashed. Retained logs confirm clean analysis and a
JavaScript build. These are inspected executor receipts, not product checks rerun
here or independent approval. Tests cover public rename/remove cancellation, stale
consent, delayed settlement, sanitized storage failure, explicit retry and disposal.
The browser distinguishes saved readiness from explicit session selection, with
zero Agent mutations. The later [Remote retry receipt](quality/remote-connection-retry.md) records
18 focused retry cases, 88 combined connection/storage cases, 58 directory cases
and four freshly compiled Chromium journeys at 390/1280px. Nine source/test and
localization fingerprints match this snapshot; the report itself changed only to
clarify screenshot retention. Authentication rejection, uncertain save, explicit
retry and replacement-owner fencing are covered. Injected storage faults are not
physical keychain evidence; successful retries use browser persistence. Local
setup/enrollment, full OAuth and live authentication remain open. Saved endpoint
editing/testing has separate bounded evidence below. The separate [native retry receipt](quality/remote-connection-retry-native.md)
records four passing Linux GTK journeys and 33 focused Flutter passes. Each layout
covers four delayed-save cases: success/error crossed with draft edit or owner
replacement. Traces record zero Agent mutations, forbidden reads or management
attempts. Logical keyboard events, injected storage and assisted scrolling do not
qualify physical input, keychain persistence, Android or live authentication.
Final retained logs confirm these results after Go-dependency isolation was added;
this documentation pass reruns no product check. Six Python regressions also pass.
The rerun archives the bundled Wing Link build's Go modules and uses an owned,
offline module cache with read-only lockfiles. All 677 archived Go files match their
manifest. Of 759 recorded source hashes, 751 match the inspected snapshot. Eight
later Chat/storage/localization inputs differ, so this result does not qualify the
whole current worktree. Main delivery and the combined gate remain separate.
The [saved editor receipt](quality/saved-endpoint-edit.md) records 93 combined
connection/storage widget passes, 166 client/directory passes, clean analysis,
a JavaScript build and four compiled Chromium keyboard journeys. Retained final
logs and browser results confirm those outcomes; this pass reruns no product tests.
Dedicated widgets exercise actual 200% text scaling. Browser zoom separately
covers 390/1280px at 100/200%, with reduced motion. Tests cover exact-ID Save,
URL collision, unchanged-identity credential retention, changed-identity trust
invalidation, explicit retry, denial, timeout, cancellation and late-owner fencing.
Each explicit Test uses only direct capabilities discovery. Opening/testing/
cancelling leave the active conversation unchanged and issue no Agent mutations.
Of 611 retained manifest entries, 610 match this snapshot. Only generated
`playwright/results.json` differs; no production/test/lock input differs.
The removed compiled artifact cannot be rehashed. The separate
[native editor receipt](quality/saved-endpoint-edit-native.md) records four passing
Linux GTK journeys at 390/1280 logical widths and 100/200% text, plus 51 focused
Dart passes and four launcher regressions. Retained final logs confirm these
results. All 767 archived input hashes match the inspected worktree. This pass
reruns no product checks. Public logical keyboard controls cover draft Cancel,
discovery 403, explicit successful Test retry, cancelled late 500 settlement,
exact-ID Save, same-label peer preservation and blank credential replacement on
reopen. Each journey records three discovery GETs and zero active reads,
connect/disconnect changes or mutation attempts. Fake endpoint storage does not
qualify physical secure storage or restart persistence. Compact 200% notices can
be off-screen while actions remain reachable. Their assertions passed, but visual
readability of off-screen notices was not checked. Physical input, Android,
live authentication, main delivery and the complete M1 journey remain open.
M1-SAVED-ENDPOINT-EDIT-NATIVE is done for this bounded synthetic result.
The later [real-storage receipt](quality/saved-endpoint-storage-native.md) records
two passing Linux GTK processes through production FlutterSecureStorage/libsecret
and native SharedPreferences. Four width/text-scale cases cover public Cancel,
exact-ID Save, same-label peers, actual Secret Service CreateItem denial, explicit
retry and secure credential readback after restart. Reopened replacement fields
are blank, ordinary preferences contain no credential markers, and additional
Agent reads, connections and mutations remain zero. Retained logs confirm five
Python tests, 23 focused Dart tests, clean analysis and both native phases.
The source archive digest matches. Of 772 executed input hashes, 771 match this
inspected tree; the editor has changed during the separately owned feedback slice.
Do not apply the result to that later editor or every keyring failure mode.
M1-SAVED-ENDPOINT-REAL-STORAGE is done for its named Linux backend and frozen
candidate. The later
[feedback accessibility receipt](quality/saved-endpoint-feedback-accessibility.md)
records 33 focused Dart passes, four tooling passes, clean analysis and four
Linux GTK fixture journeys. Complete help and Test/Save outcomes remain
keyboard-readable at 390/1280 logical widths and 100/200% Flutter text, with
reduced motion. Focus reveals new notices; keyboard paging reaches their end.
Explicit retries preserve drafts, while pending Cancel and owner replacement
reject obsolete feedback. Retained final logs confirm these checks; this pass
reruns no product tests. All 778 recorded input hashes match the inspected tree
and the source archive digest matches.
M1-SAVED-ENDPOINT-FEEDBACK-ACCESSIBILITY is done for this bounded result.
The native journey uses fake storage and injected keys; it does not requalify
the earlier real-storage result against this editor. Physical input, screen
readers, Android, live authentication and protected-main delivery remain gaps.
The [two-host recovery receipt](quality/two-host-recovery-native.md) records four
passing Linux GTK fixture journeys at 390/1280 logical widths and 100/200% text,
86 combined ownership widget passes and six Chromium owner regressions.
Retained terminal logs confirm those results; this pass reruns no product checks.
Public keyboard selection covers colliding profile/session IDs, cancelled delayed
success/failure, return to the same host, network pagination failure, denied
bootstrap and explicit Retry. Canonical recovery retains the selected host and
draft, with zero mutation or management attempts. All four dedicated Dart inputs
match the receipt. Of 878 recorded inputs, 867 match the inspected worktree;
eleven later source/test/localization/dependency/report inputs differ. The executed
source archive digest matches. This result qualifies that frozen candidate, not
the whole current tree. Live authentication, physical keychain, managed SSH,
Android, screen readers and protected-main delivery remain unqualified.
CONNECTION-TWO-HOST-RECOVERY is done for this bounded slice, not the full
connection setup/authentication matrix.

The [optional Local setup receipt](quality/local-setup-recovery.md) records 22
focused tests and four compiled Chromium keyboard journeys using synthetic typed
host operations. Retained browser results confirm all four journeys passed at
390/1280px with 2x Flutter text and reduced animations. Cancel starts no setup;
Run setup starts once; Stop and route disposal reject late outcomes. Check again
only inspects, private process output stays absent, and verified completion waits
for explicit Continue. The controller also rejects new operations after disposal
and contains teardown cancellation errors.
All seven branch files match the inspected snapshot. Of 605 inventoried inputs,
596 match; nine later SSH/localization inputs differ. The frozen candidate, not
the whole current tree, owns this result. The separate
[native enrollment receipt](quality/local-setup-enrollment-native.md) closes the
production-routing fixture successor with 26 focused passes and four Linux GTK
journeys. Retained terminal summaries confirm those passes and clean analysis.
This documentation pass reruns no product checks. The real WingApp/router reaches
Local consent through keyboard controls at 390/1280 logical widths and 100/200% text.
Cancel and Back start no setup. Stop rejects late success/failure. Check again only
inspects. Continue alone returns to separate pairing controls. Disposing the route
then selecting a direct Agent contact requires no management credential or request.
Each journey records 12 inspections, six deliberate setup starts, four cancellations
and zero management attempts, Agent mutations or forbidden reads.
The source archive and manifest hashes match the receipt. Of 849 recorded inputs,
847 match this snapshot. Two later SSH key-selection inputs differ. This is frozen-
candidate qualification, not a passing whole-tree gate. CONNECTION-LOCAL-ENROLLMENT-NATIVE
is done for this bounded slice. Actual installation/adoption, live authentication,
OAuth, Android, assistive-technology output and protected-main delivery remain open.

The [Remote authentication explanation receipt](quality/remote-auth-explanation.md)
records 38 focused Flutter passes, clean analysis and four Linux GTK fixture journeys.
Retained terminal summaries confirm those results. This pass reruns no product tests.
Public welcome and Chat entry expose keyboard-reachable guidance for Remote HTTPS
and VPN at 390/1280 logical widths and 100/200% text. Local excludes that guidance.
Synthetic 403/401 denial retains endpoint, token and name drafts. Cancel saves
nothing; explicit retry succeeds. Idle performs no authentication replay.
Each journey records four connects, one save and 23 token reads, with zero
management, mutation or forbidden-read attempts. All 855 recorded source hashes
and the source archive and manifest digests match this inspected snapshot.
CONNECTION-REMOTE-AUTH-EXPLANATION is done for this bounded slice. Browser OAuth
implementation, live authentication, physical keychain, Android and protected-main
delivery remain unqualified. Reuse these public-control checks rather than queueing
another synthetic explanation journey.

The [production connection browser matrix](quality/connection-production-browser-matrix.md)
records 64 focused Flutter passes, clean analysis, a JavaScript build and 14
Chromium journeys through the real WingApp/router. Complete retained terminal
summaries confirm those results; this documentation pass reruns no product checks.
The frozen candidate combines optional legacy Local consent/Stop/inspection-only
retry, Remote denial/save recovery, saved editing and colliding saved-host identities.
Direct paths record zero management traffic and Agent mutations. The two-host
replacement uses a channel-event seam, not public selection during discovery.
A semantic wrapper exposes Remote authentication guidance as static text while
retaining selection and keyboard access. Of 693 manifest entries, 682 match this
inspected snapshot and 11 differ, including source, tests, localization and dependencies.
This qualifies the recorded candidate, not the current worktree. Legacy setup
fixtures do not qualify replacement Hermes-home discovery or same-phone setup.
CONNECTION-PRODUCTION-BROWSER-MATRIX is done for bounded browser composition.
Actual installation, live authentication, native SSH, Android and protected-main
integration remain separate gaps in the existing setup/authentication successor.

Inspect existing auth-recovery,
enrollment, router and saved-host tests before adding duplicate harnesses.

| Scenario | Observable expected outcome | Evidence needed |
| --- | --- | --- |
| Agent-only onboarding | With Wing Link absent, first-run Local and Remote reach direct Agent connection. No management install, pairing, credential or network request is required. SSH connects directly on supported native targets, or explains its unsupported status without requiring Wing Link. | Passing public-route widgets and compiled Chromium journeys are retained in [the first-run receipt](quality/direct-first-run.md). Dedicated widgets exercise 390/1280px at 1x/2x text; browser traces record zero management requests and mutations. [Native GTK fixture journeys](quality/direct-first-run-native.md) also pass at 390/1280px and 1x/2x text. Separate Android, live authentication and managed SSH evidence remains required. |
| Independent authority | A reachable Agent remains usable when optional Wing Link is unavailable or rejects authentication. Missing Agent APIs render unsupported actions without management setup prompts or invented support. | Production-path widget/channel tests with exact request counts and separate Agent/management credentials. |
| Primary entry | Local, SSH and Remote are keyboard reachable at wide/compact sizes. VPN remains reachable inside Remote. Unsupported native behavior has explicit copy. | Updated auth-recovery/router widgets and a freshly compiled fixture browser journey. |
| Local reuse/setup | Existing installation and setup-needed states remain distinct. Confirmation starts one operation. Cancel, failure and Retry remain owner-bound. Success enters direct Agent connection without requiring Wing Link or claiming inference readiness. | Existing local-setup/enrollment tests plus new Agent-only regression coverage. A named isolated Linux build/launch and setup target qualify actual host behavior separately. |
| Remote token connection | Explicit connection validates the endpoint, securely saves its credential and reports connection/readiness independently. Failed auth or persistence never claims success. | Production-path unit/widget regressions and compiled fixture journey. Approved isolated live Agent check for actual authentication/chat. |
| Remote OAuth | Exact supported auth discovery/sign-in works, or unsupported OAuth is explained without token copying or a fake login. Cancelled sign-in cannot activate another host. | Contract review first. Browser/native login against an approved isolated target only if supported. |
| SSH input and trust | Fixed forwarding accepts only bounded typed inputs. Unknown host requires explicit review. Changed keys fail closed. No remote command/configuration input is exposed. | Native contract/security review, deterministic rejection tests, then controlled native OpenSSH qualification. |
| SSH connection and cancellation | Authentication, port collision, timeout and child exit produce bounded errors. Repeated Connect cannot duplicate children. Cancel and late callbacks cannot retain or replace another owner's tunnel. | Fake-runner regression matrix plus native isolated SSH server/process receipts. Browser fixtures cannot qualify system SSH. |
| SSH disconnect/reconnect | Only the owned child is cleaned up. Reconnect preserves durable host/profile/session when a forwarding port changes. No implicit send, approval or Stop occurs. Remote service/run state remains authoritative. | Delayed-owner unit/widget tests and native tunnel interruption/recovery checks with exact mutation counts. |
| Saved connection switching | Name/edit/test/remove retain stable connection identity. Colliding profile/session IDs on two hosts remain isolated. Late old results cannot activate, fail or disconnect the replacement. | Existing Gateway/directory/channel regressions and compiled fixture two-host journey. |
| Sensitive data and platform limits | No key material, tokens, private endpoints or host paths enter logs/screenshots/ordinary preferences. Web does not invoke OpenSSH. Agent and Wing Link credentials are never interchangeable. | Scoped security/source checks and supported-platform tests. Native/live receipts remain separately attributed. |

Use deterministic synthetic hosts and fake subprocesses first. Native qualification
requires an isolated SSH server, owned preferences/known-host storage and explicit
credentials through an approved private mechanism. Do not read or alter personal
SSH keys, known_hosts, Agent profiles, services or desktop preferences. Missing
native tooling affects only dependent checks. Continue browser and shared tests.

For every path, report implemented, unsupported, failed and not-run behavior
separately. A successful tunnel or public health check is not authenticated chat.
No new native/live connection qualification is claimed by this documentation pass.

### Fresh full Dart verification after matrix preparation

`npm run test` completed with exit **0**, **3,501 passed and zero failed** in
this later shared-worktree run. The
[receipt](../.task-evidence/parity-flow-matrix/npm-test-result.json) and
[log](../.task-evidence/parity-flow-matrix/npm-test.log) bind that result to the
command. No product-code repair was made by this follow-up. This passing current
run does not rewrite older source-bound failures or qualify native Linux,
Android Maestro, live providers or complete Desktop parity.

### Follow-up full Dart suite result

The connection-documentation follow-up ran
`timeout --signal=TERM --kill-after=20s 1200s npm run test -- --reporter expanded`.
It completed with exit 1, 3,489 passed and six failed. All failures were in
`test/features/gateway/gateway_keyboard_client_test.dart`: success, failure and
unsupported health scenarios at both 390px and 1280px with 200% text. Four cases
could not find the expected semantic element. Two could not find the expected
basic-health fallback text. These observations do not establish the root cause.

The [parsed receipt](../.task-evidence/desktop-connection-docs/npm-test-result.json)
and [full log](../.task-evidence/desktop-connection-docs/npm-test.log) retain the
executed result. This run used the shared current worktree, not a pinned isolated
snapshot. It does not supersede native/live qualification or prove the whole
tree passed. The later [Gateway harness repair](quality/gateway-keyboard-bootstrap-repair.md)
closes FIX-GATEWAY-KEYBOARD-390 in [root TODO](../TODO.md#now--next): six focused
cases and 68 nearest checks pass after correcting the history envelope.
The full-suite failure remains historical evidence, not a current open repair.
No product or test repair was performed during that earlier documentation pass.

## Verification follow-up: session-picker harness

The requested `npm run test` follow-up completed with exit 1: 3,485 passed
and ten failed. All ten failures reproduced in
`test/features/hermes_chat/screens/hermes_chat_session_picker_test.dart`.
That harness still expected automatic catalog selection when session identity
was unknown. One explicit row tap also lacked a rebuild before confirmation.

Only the harness changed. It now selects a catalog row deliberately and waits
for its rebuild before confirming. Unknown, unconfirmed and mismatched identities
assert disabled confirmation and zero submissions before selection. The existing
owner-roundtrip and pending-success tests still exercise rejection after selection.
Production picker and channel code were not changed by this repair.

The focused command
`npm run test -- test/features/hermes_chat/screens/hermes_chat_session_picker_test.dart --reporter expanded`
passes all 14 cases. `dart format` reports zero changes and `flutter analyze`
reports no issues. The subsequent full `npm run test` exits 0 with 3,495 passes.
Its optional local log is `.task-evidence/repo-docs-picker-verification.log`.
These are Linux Flutter test results from the shared working tree, not native
relaunch, compiled browser, live inference or complete M1 acceptance.

## Native relaunch and canonical transcript recovery

The [native receipt](quality/native-relaunch-workflow.md) records two distinct
Linux GTK processes under Xvfb. Retained phase logs and counters confirm exact
remembered off-page session/history, two submissions, one approval, one Stop and
zero unexpected mutations. All 628 final native input hashes match this snapshot.
The 56-test focused receipt predates two later workspace-helper/test refinements;
it does not qualify those final refinements. Compatible development packages were
extracted into an owned prefix without system installation. That predecessor used separate model and lifecycle scenarios. The
[combined native receipt](quality/native-model-relaunch-workflow.md) now records
model rejection/acknowledgment, approval and Stop in one scenario across two GTK
processes. Both phase counters remain unchanged after restart. Its native and
focused manifests each match all 628 inspected inputs; retained logs show clean
analysis and 340 focused passes. These are inspected receipts, not new test runs.

VERIFY-NATIVE-MODEL-RELAUNCH is delivered with an explicit contract limit:
restored model text does not restore a confirmed provider/model pair. The picker
shows unknown identity, no preselection and disabled confirmation until deliberate
choice. Cancellation changes nothing. Exact-pair readback remains unsupported.
The later [resumed-send receipt](quality/native-resumed-send.md) completes
VERIFY-NATIVE-RESUMED-SEND for explicit reselection and one acknowledged synthetic
send to the restored exact session. Retained checkpoints show zero mutations on
restart, Cancel and route reopening. Both native phases exited 0 with distinct
GTK PIDs; focused checks record 340 passes. All 644 native and 644 focused input
hashes match the inspected snapshot. These are retained results, not tests rerun
by this documentation pass. PARITY-LIVE-WORKFLOW retains actual generation
qualification. Full-shell startup,
screen readers and other platforms remain unverified. M1 stays partial.

The [live-workflow preparation receipt](quality/live-desktop-daily-workflow.md)
records ten Python launcher regressions, 98 client tests and six mutation-budget
regressions passing on an attributed source snapshot. Retained terminal logs and
`build/live-workflow-evidence/checks.json` support those results; this documentation
pass does not rerun them. The retained manifest matches 551 of 588 current input
hashes and three of five overlay hashes. The Python helper and its test differ
from that manifest, although both match the latest branch. Do not extend these
historical checks to the whole current tree. Tests prove GET-only preflight,
zero startup/restoration writes, exact request/run guards and consumed slots after
ambiguous dispatch.
Direct native invocation must refuse before network access while the provider-call
ceiling is unqualified. The prepared Chat driver and native read-only readiness
target have analysis evidence, not actual-Agent/native journey execution. Remaining
live checks need a supported ceiling across retries, tool/approval continuations
and auxiliary work before either native phase can generate. The later
[provider-call boundary receipt](quality/live-provider-call-ceiling.md) records
31 Python passes and six unchanged Dart guard passes on its isolated branch.
Remaining submission declarations, exhausted declarations and fresh process/counter
resets all refuse before external operations. Retained receipts match all six
branch input hashes; shared helper/tests differ, so these passes do not qualify
the shared tree. The inspected Agent interfaces do not supply the required physical-
attempt ceiling. A submission counter is not an inference ceiling; deterministic
refusal is not M1 acceptance. The independent
[credential-free GTK shell smoke](quality/native-no-inference-smoke.md) now has a
branch execution receipt, not live generation. The current report supersedes that
receipt after review found incomplete analyzed-source retention and excluded
local tool-state capture. The corrected retained run captures every included input
before execution. An offline archive check matches all 1,065 inputs to the manifest
and executed hashes, with no excluded runtime names or linked members. Two GTK
phases record persisted synthetic owner/history restoration, keyboard loading
cancellation, failed-read retry and wrong-owner rejection. Both phases record zero
mutation/provider requests and confirmed teardown before state deletion. Retained
logs record 12 snapshot tests, 23 focused Flutter tests and four public refusal
tests passing, plus clean analysis. These are inspected results, not product tests
rerun by this documentation pass. Shared helper/tests differ from the reviewed
overlays. Do not reuse the superseded archive or qualify the current shared tree,
physical keyboard/IME, packaged execution or live generation from this receipt.
The later [native denied-read receipt](quality/native-no-inference-auth-recovery.md)
adds synthetic typed 401/403 at persisted exact-session restoration. Expected
outcomes: retain the saved owner without active history, expose recovery UI, and
restore canonical history only through explicit Tab/Space Retry after read authority
returns. Cancelled valid/foreign history and wrong-owner Retry must remain unapplied.
Retained logs record four passing GTK phases, 83 focused Flutter tests, 14 snapshot
regressions and four admission guards. Archive and executed hashes agree for all
1,067 inputs, including five reviewed overlays. All phase mutation, provider and
management counters are zero. These are inspected executor results, not product
tests rerun here. They qualify the frozen synthetic Linux candidate, not the
shared helper, physical input, packaged execution or live Agent authentication.
The [bootstrap-denied successor](quality/native-no-inference-bootstrap-recovery.md)
adds required-capabilities 401/403 before inventory/history becomes usable.
Expected outcomes: retain the persisted exact owner, show recovery without stale
transcript/composer, and issue only health/capabilities reads while denied.
Tab focus must not retry. Space explicitly retries once under continued denial,
then restores canonical history after synthetic authority returns. Cancelled
valid/foreign-owner results must remain unapplied. Retained logs record six passing
GTK phases, 88 focused Flutter tests, 15 snapshot regressions and four admission
guards. All 1,068 archived inputs match executed hashes; mutation/provider/management
counts remain zero. This pass inspects those results, not a new product run.
Live authentication, inference, physical input and packaged execution remain unqualified.

Actual-Agent execution, canonical readbacks and zero recovery mutations remain
unqualified and require separate QA authentication plus the missing budget contract.

The same receipt's [cleanup correction](quality/live-desktop-daily-workflow.md#round-1-cleanup-correction)
records 14 Python regressions after review reproduced a preparation-cancellation
leak. Synthetic source/SDK tools exercise source archive, SDK copy, repeated
signals, resistant descendants and spawn failure. Expected outcomes are fixed
`NATIVE_CANCELLED`, exit 2, reaped owned groups and removed temporary state.
Successful fake-tool preparation proves launcher control flow only. The Dart
inputs remain unchanged; Flutter/native checks were not rerun for this correction.
The original ten-test receipt does not cover the repaired cancellation paths.

The [two-process receipt](quality/live-two-process-orchestration.md) records
23 passing synthetic lifecycle regressions. Distinct driver/app groups share owned
state; resistant descendants are reaped before the successor or state deletion.
A regression requires refusal and retained state when teardown is unconfirmed.
The [display authentication receipt](quality/live-display-isolation.md) records
29 passing tests on its later isolated branch. Retained machine evidence matches
all six recorded branch input hashes, not the shared helper/test predecessor.
Real Xvfb/xdpyinfo checks admit correct authorization, deny empty/wrong credentials
and reject TCP access. Both synthetic phases use the same owned display/auth file;
success and cancellation tear down groups before deletion. These checks qualify
Linux X protocol admission and orchestration, not GTK, live Agent generation,
provider-call enforcement or hostile same-UID isolation. This documentation pass
inspects receipts and branch source only; it reruns no product tests.

The [transcript reconnect receipt](quality/chat-transcript-reconnect.md) records
391 focused passes in isolated and shared workspaces, clean analysis, a release
web build and two Chromium journeys. Ten available selected hashes match; the
removed web artifact cannot be rehashed. Canonical tool-result rows retain server
order, category-only activity and canonical IDs without raw content or preview.
Reconnect, page reload and route/viewport remount add zero mutations and retire
obsolete approval actions. Persisted completion does not prove tool success.
Unfinished invocations and transient reasoning recovery remain outside this slice.
VERIFY-CHAT-TRANSCRIPT-RECONNECT and VERIFY-CHAT-TRANSCRIPT-ACCESSIBILITY are done
for their bounded fixture slices. The [accessibility receipt](quality/chat-transcript-accessibility.md)
records two widget tests and two freshly compiled Chromium journeys at 200%
scaling/zoom. Keyboard access, visible focus, canonical ordering and zero recovery
mutations survive reconnect/remount and compact/wide return. All eight selected
receipt fingerprints match this snapshot. These are inspected receipts, not new
test runs. The later [native transcript receipt](quality/native-transcript-recovery.md)
records four Linux GTK cases at 390/1280px and 100/200% text through production
Chat/channel with deterministic HTTP/SSE. Expected outcomes: canonical IDs/order
survive reconnect, remount and compact/wide return; keyboard disclosure exposes
only redacted categories; retired approvals lose controls/focus. Explicit failure
retry answers only the same request. Delayed failure cannot settle a replacement.
Each case records five deliberate setup sends, five decision attempts, 23 reads,
zero creates/Stops and zero recovery mutations. Retained logs confirm four tooling
tests, 15 focused tests, clean analysis and one native test containing four cases.
All 783 archived execution inputs match their manifest and this inspected tree.
These are inspected executor results, not fresh product runs or independent approval.
M1-NATIVE-APPROVAL-RESTORATION is done for that bounded slice.
VERIFY-CHAT-TRANSCRIPT-NATIVE remains open for its separate acceptance; coordinate
with this evidence instead of repeating the four cases. Process restart, live
Agent behavior, physical input and screen readers remain unqualified.
CHAT-FIDELITY and the live M1 milestone remain partial.

The [native Stop receipt](quality/native-stop-recovery.md) adds four passing Linux
GTK cases at 390/1280 logical widths and 100/200% text with reduced motion.
Expected outcomes: keyboard Stop retains unresolved ownership through acknowledgment,
unknown status, wrong-run readback and failed status/history reads. Public directory
and Add Hermes recovery admit canonical history before a deliberate resumed send.
Failed Stop retains ownership. Delayed retired settlement cannot overwrite or
release the replacement run. Each case records 68 reads, four explicit submissions,
three deliberate Stop attempts, zero session creates and zero approval decisions.
Recovery causes no mutation or extra Stop. Retained logs confirm five tooling
tests, 335 focused Flutter passes, clean analysis and one native target containing
four complete cases. Archive and manifest digests match; all 788 executed input
hashes match this inspected tree. These are inspected executor results, not fresh
product runs or independent review approval. M1-NATIVE-STOP-RECOVERY is done for
this synthetic slice. Its standalone result does not qualify process restart.
The later integrated fixture below supplies bounded restart evidence; live
Agent/provider authentication, real tools/Stop and protected-main delivery remain open.

The [native status receipt](quality/native-status-accessibility.md) records four
Linux GTK fixture journeys at 390/1280 logical widths and 100/200% text.
Expected outcomes: Tab and Enter/Space expose complete labeled, redacted status;
compact More updates during owner replacement; recovering/failed states do not
show cached identity as current. Resize and route return preserve operability.
All seven mutation counters remain zero in every journey. Retained logs confirm
25 focused widget passes, clean analysis and one native target containing four
journeys. The source archive and manifest digests match; all 794 archived inputs
match their executed fingerprints and this inspected tree. These are inspected
executor results, not fresh product runs or independent approval.
M1-STATUS-ACCESSIBILITY is done for this bounded repair. Live Agent/provider,
physical input, screen-reader, other-platform and protected-main qualification
remain separate.

The [integrated restart receipt](quality/native-integrated-daily-restart.md) closes
M1-NATIVE-INTEGRATED-RESTART for a credential-free Linux GTK fixture sequence.
Expected outcomes: select the off-page session, answer its correlated approval
once, Stop its exact run, reject sends while canonical recovery is denied, and
retain canonical identity after a delayed Stop response. A second process restores
exact owner/history without mutations, requires explicit model reselection and
permits one deliberate resumed send. Compact/wide journeys use 200% text and
reduced motion. Route navigation uses the router, and scrolling uses test helpers;
this is not an entirely keyboard-only or physical-input qualification.
Retained logs confirm five tooling tests, 376 targeted Flutter passes, clean
analysis and four native invocations. All 1,296 archived input hashes match the
executed manifest. Before this maintenance pass, eight documentation inputs
already differed, so this receipt does not qualify the entire current tree.
This pass inspects executor evidence;
it reruns no product test and infers no independent approval. Remaining gaps are
live authentication/generation, enforceable provider-call admission, authoritative
model-pair readback, other platforms and protected-main delivery.

## Developer gate

From the repository root, use Flutter 3.44.2, Node.js 22 and Go 1.26 for Wing Link.
Resolve dependencies as described in [Contributing](../CONTRIBUTING.md).
Run focused tests while iterating, then checks proportional to the changed boundary.
The complete existing gate is owned by [Contributing](../CONTRIBUTING.md#required-checks).

For browser behavior, build the deterministic target before Playwright:

```bash
flutter build web --release -t lib/main_e2e.dart
npm run web:e2e
```

Do not run concurrent builds against the same output tree. Inspect fixture and
launcher arguments before a focused browser/native run. The
[native daily-use plan](plans/2026-10-03-desktop-daily-workflow.md#ordered-bounded-work)
requires fresh platform metadata and ownership checks before its launcher.

Documentation-only changes use `git diff --check` and affected local-link,
anchor, command and meaning checks. Do not launch a release, restart a service,
install packages or make destructive requests to validate documentation.

## Acceptance records and gaps

The [composer accessibility receipt](quality/chat-composer-accessibility.md)
records seven widget passes and one compiled Chromium journey. All eight scoped
fingerprints match this snapshot; retained final widget/build/browser logs confirm
those passes. Widgets exercise 200% text-only scaling; Chromium separately uses
native 200% whole-render zoom with reduced motion. Keyboard traversal, draft
retention, capture cancellation and one exact Send/Stop remain qualified only for
these deterministic cases. This documentation pass does not rerun product checks.
VERIFY-CHAT-COMPOSER-ACCESSIBILITY stays done. The later
[reasoning accessibility receipt](quality/reasoning-disclosure-accessibility.md)
records two focused widget passes, 98 nearest-test passes, clean analysis, a
JavaScript build and one compiled Chromium journey. All 215 retained input
fingerprints match this snapshot; the generated build has been removed, so its
recorded hash cannot be rechecked. Final logs confirm the reported passes.
Widgets separately exercise 200% text-only scaling; Chromium uses 200% whole-render
zoom. Reduced motion, keyboard disclosure, adaptive return, completion and reused-ID
owner replacement cause no incidental mutations. VERIFY-CHAT-DISCLOSURE-ACCESSIBILITY
is done for this bounded evidence, not independent approval or a new product run.
The [streamed-order receipt](quality/chat-transcript-order.md) records 129 focused
widget passes, clean analysis, a fresh JavaScript build and two Chromium journeys.
Eleven available input fingerprints match this snapshot. The exercised web output
was removed, so its recorded hash cannot be rechecked. Retained final logs confirm
the reported results; this pass does not rerun product checks or infer approval.
The journeys check canonical reasoning/commentary/tool/answer order, unique rows,
keyboard focus and compact/wide return. Completion sends exactly one approval
decision; session replacement sends none. Each journey submits one run and no Stop.
The repaired queue rejects explicit-profile mismatches at display and activation,
including reused session IDs. Widgets additionally cover profile/channel replacement
and late old-owner events. VERIFY-CHAT-TRANSCRIPT-ORDER is done for this bounded
evidence. History reconnect, whole-transcript enlarged-text access, screen-reader
and native/live qualification remain gaps; CHAT-FIDELITY stays partial.

The [compact Profiles mapping](quality/compact-desktop-outcome.md) records two
passing Linux-hosted widget navigation checks. Mobile bottom navigation opens
profile management directly instead of Desktop's switch-picker menu. All eight
retained source fingerprints match this snapshot. These checks use placeholder
routes and taps, not real mobile destination recovery, keyboard, Android or
native execution. They do not prove selected Agent profile or session persistence.
The [recents comparison](quality/grouped-recents-reference.md) defines source-only
loaded grouping. The later [delivery receipt](quality/grouped-recents-implementation.md)
records 72 shell widget passes and one freshly compiled Chromium journey.
It covers stable groups, exact Open/New, keyboard traversal and adaptive return
without incidental requests. This pass inspected receipts, not a new product run.
The [recovery receipt](quality/grouped-recents-recovery.md) closes the bounded
adversarial follow-up with eight new widgets, 71 focused passes and one compiled
Chromium journey. Keyboard hide/return and pending-owner rejection use existing
sidebar collapse/resize, not group disclosure. The later
[native receipt](quality/grouped-recents-native.md) records six phases in a Linux
GTK app under Xvfb, 18 viewport/focus assertions and ten exact-row selection
completions. Of 640 recorded inputs, 633 match this snapshot. Seven Chat/E2E and
localization files changed with the later Remote retry slice. The shell/channel
and native target inputs still match; the native receipt does not qualify the
full current dirty tree. Retained logs confirm
clean analysis, 71 focused passes and one native integration pass. Its 73 app
requests are GET; four obsolete Opens reject admission and each fresh Open succeeds.
This uses the production shell/channel with synthetic route content and injected
keys, not full feature screens, physical input, OS minimization or live Agent.
These are inspected receipts, not product checks rerun by this pass.
The earlier recovery journey recorded 33 browser app requests, all
GET; explicit connection/Open reads remain separate from zero incidental reads.
Retained final logs confirm analysis and a JavaScript build. Of 570 recorded
inputs, 568 still match; the two changed Chat connection files belong to the later
saved-host repair. These historical receipts do not qualify the full current tree.
Global modal adaptation is recorded below; native/live checks remain queued.
Group disclosure is not implemented.
Project grouping, native/live and screen-reader qualification remain unverified.
Both parent parity goals remain partial.

The [passive footer receipt](quality/profile-footer-implementation.md) records
63 shell widget passes, including nine footer regressions, and compiled Chromium
navigation with unchanged owner state and zero incidental domain requests.
Its three scoped source/test fingerprints match the inspected checkout. Cases
cover owner replacement, default/disconnected labels, redaction, pointer/Enter/Space
and reverse focus traversal. Widgets cover 48px targets and 2x text / 360px height;
browser short-height checks use normal text scale. These are retained executor
receipts, not new execution, screen-reader or native qualification.
The [composition brief](quality/profile-footer-composition.md) and
[next-port mapping](quality/desktop-next-port-slice.md) remain preparation evidence.
Global switching and Project-grouped recents remain separate work.
Loaded source grouping and the global owner-bound session modal are delivered.

The later [native panel receipt](quality/global-session-modal-native.md) records
one passing Linux GTK integration journey with twelve phases and 89 focused
widget passes. Injected keyboard traversal, 200% text, reduced motion and viewport
changes retain reachable controls. Delayed Open/New completions reject obsolete
owners; explicit history Retry performs one read without replay. Passive panel
work adds no requests. Retained metadata records 173 requests, including ten
explicit New POSTs, and zero runs or unexpected mutations. The three dedicated
inputs still match their recorded hashes. Of 644 copied inputs, 640 match; four
daily-workflow inputs changed with the later resumed-send slice. This historical
result does not qualify the entire current tree. Physical input, live profiles,
full feature screens and screen readers remain unverified. Footer qualification
and its feature-route recovery successor remain queued.

The [modal receipt](quality/global-session-modal.md) records 120 passing focused
widget tests and a compiled Chromium keyboard journey. All eight scoped source/test
fingerprints match this snapshot; the retained widget log confirms its final pass.
The browser receipt records named focus traversal, exact history requests and zero
captured errors. These are inspected executor receipts, not product checks rerun here.
Coverage includes one admitted panel, search focus, bidirectional containment,
Escape/Close focus return, explicit pagination retry and once-only acknowledged
activation. Owner/resource/route loss and change-away-and-back reject stale actions;
cancellation/reopening does not replay New, prompts or approvals.
The [New-recovery correction](quality/global-session-modal.md#independent-review-correction-new-recovery)
records 122 focused passes and two compiled Chromium journeys. All four rework
fingerprints match this snapshot; retained executor and review widget logs each
confirm 122 passes. Each retained New/Retry browser receipt shows one creation
and two history reads of the same acknowledged ID. Retry must never create another
session, and owner replacement must reject stale read/navigation intent.
Unacknowledged creation failure offers no generic replay. These are inspected
receipts, not new product runs or inferred review approval.
The [adaptive panel receipt](quality/global-session-modal-adaptive.md) records
103 focused widget passes, clean analysis, a fresh JavaScript build and four
Chromium journeys, including two rerun predecessor journeys. All 203 retained
input fingerprints match this snapshot. Widgets exercise 200% Flutter text;
Chromium separately uses 200% whole-render zoom. Keyboard traversal keeps search,
New and rows reachable through wide, compact and short-window resize. Escape/Close
returns surviving focus. Delayed owner/route replacement rejects obsolete results;
explicit current-owner activation and New retain exact history/create counts.
Retained final logs confirm these results; this pass does not rerun product checks
or infer independent approval. The later npm entry is a focused 103-test rerun,
not a full-suite pass. The separate full-suite log has no completion result; see
[verification scope](quality/global-session-modal-adaptive.md#follow-up-npm-verification-scope).
Standalone agent-branch compilation remains unchecked because predecessor shell,
localization and channel inputs were consumed from the shared tree. Native/live
and screen-reader qualification remain unverified. The parent composition goal stays partial.

The historical [composer comparison](quality/chat-fidelity-reference.md) defines
six direct-dictation oracles. The delivered
[wide draft action](quality/chat-direct-dictation.md) now implements that slice.
Its nine recorded artifact fingerprints match the inspected checkout. Retained
logs record 109 passing composer, lifecycle, controller and direct-action tests,
plus a JavaScript release build. Browser receipts at 1440px and 390px record
keyboard activation, unavailable-service recovery and zero mutation/audio/management
requests or page errors. These are inspected receipts, not tests rerun by this pass.

Controlled widget services cover recognition, cancellation, retry, exact-owner and
gate invalidation, append/caret/focus recovery and zero submissions. Browser capture
remains unavailable; the browser journey proves keyboard and text recovery only.
The card branch needs the approved explicit-model-selection predecessor for a
clean build. Standalone branch execution, physical audio, native/Linux runtime,
live Agent and full transcript/IME parity remain NOT_CHECKED. Independent final
approval is not inferred from executor evidence.

The historical [reasoning comparison](quality/chat-transcript-disclosure.md)
identified a fixed-summary deviation. The [implementation receipt](quality/reasoning-disclosure-implementation.md)
reports 91 passing transcript tests and one fresh compiled Chromium journey.
It covers Thinking…/Thought, Tab/Enter/Space, completion focus, collapsed fresh
owner content, redaction and static reduced-motion chrome. Five inspected branch
files match the current source/test/report snapshot. This pass does not rerun tests.

Retained `green.log` and `widgets.log` record intermediate semantics-handle
failures; `build.log` ends at a Wasm dry-run warning. They do not verify the
reported final passes. The retained browser receipt records named focus, exact
requests and no page errors, not native execution. The later
[recovery receipt](quality/reasoning-disclosure-recovery.md) has final logs for
100 passing widget tests, clean analysis, a completed JavaScript build and two
compiled Chromium journeys. Its eight source fingerprints match this snapshot.
These later checks qualify mounted updates, eviction/remount and owner replacement
without changing the historical failures. HTTP reconnect removes transient
reasoning rather than reconstructing it from text history. Both browser journeys
record one deliberate run submission and no incidental Agent mutations.
VERIFY-CHAT-DISCLOSURE-RECOVERY is done for this bounded evidence;
independent final approval and a new run by this documentation pass are not implied.
The [adaptive receipt](quality/reasoning-disclosure-adaptive.md) records 101 passing
widget tests and three compiled Chromium journeys, including both recovery controls.
All six receipt fingerprints match this snapshot; retained final logs confirm the
reported passes, clean analysis and completed JavaScript build. This pass inspected
those logs; it did not rerun product checks. Compact/wide return retains expansion
while releasing old actionable focus; Tab/Shift+Tab reaches the replacement summary.
Same-layout resize and completion retain focus. Reused-ID owner replacement resets
expansion without incidental mutations. VERIFY-CHAT-DISCLOSURE-ADAPTIVE is done
for this bounded evidence.

The [wide composer receipt](quality/chat-composer-order.md) records 59 focused
widget passes and one compiled Chromium journey. All 13 source fingerprints
match this snapshot; retained final logs confirm analysis, build and test passes.
Named Tab/Shift+Tab traversal and unavailable draft-capture recovery cause zero
mutations. Deliberate Send and Stop each cause one request. Widgets also cover
held model loading, repeat activation and Enter/Space Stop. The existing order
required no production change. Active-run Stop placement, follow-up queuing and
hands-free controls remain explicit Desktop deviations. The [adaptive recovery receipt](quality/chat-composer-order-recovery.md) adds seven
widgets, 68 focused passes and one compiled Chromium journey. All seven source
fingerprints match this snapshot; retained final logs confirm analysis, build and
test passes. Tab/Shift+Tab survives 1440 → 600 → 1440 return. Pending model reads
reject session/profile/channel replacement; capture rejects late text and focus.
Enter/Space cancel capture without Agent Stop, while run Stop targets only the
replacement channel. Browser readbacks record one exact-session Send and one Stop,
with zero incidental creates, model writes or approvals. Large-text access,
screen-reader, native/live and full transcript parity remain unverified. This pass
inspected receipts; it did not rerun product checks.

The [security boundary receipt](quality/security-current-boundary.md) records
named denial, containment, redaction, approval/replay and reconnect checks.
Its regression proves mismatched approval fields do not spend the exact request;
an intentional negative control fails before the unchanged control passes.
These source-bound checks do not qualify live authentication, native secure
storage, target TLS/pinning or all threats. SECURITY remains partial.
This documentation pass inspects receipts; it runs no product tests.


The [session rename journey receipt](quality/session-rename-journey.md) records
three production-screen/channel/client widget journeys, 136 mutation-owner passes
and three selected channel passes. Rename submits one explicitly scoped PATCH
and displays the server-confirmed title. Reconnect and reopen read the same
owner's title/history without another mutation. Cancel and same-ID profile
replacement submit nothing. The delivered receipt and new test match branch
commit `222be4ee`; retained logs confirm these results. This documentation pass
runs no product tests. Native/browser/live transport, full-router navigation
and complete session parity remain unverified.

The [session delete journey receipt](quality/session-delete-journey.md) records
three production-screen/channel/client widget journeys, 136 mutation-owner passes,
three selected ownership passes, five channel-delete passes and two client passes.
Confirmation submits one profile-scoped DELETE. Reconnect reads the fixture's
remaining rows and current history without another mutation. Cancel and same-ID
profile replacement submit nothing. The receipt matches branch commit `f84e8ebd`;
retained journey, ownership and channel-delete logs confirm the recorded passes.
This documentation pass runs no product tests. Live persistence, full-router,
browser/native interaction and complete session parity remain unverified.
Root TODO preserves the completed rename/delete/branch tasks and the delivered
search/resume qualification. It does not request duplicate execution of those slices.

The [branch journey receipt](quality/session-fork-journey.md) records three
production-screen/channel/client widget passes. Confirmation creates one child
with explicit profile and parent identity, then reads its history. Reconnect and
explicit reopen read updated fixture history with only GET requests. Cancel and
same-ID profile replacement submit nothing. The four scoped test/action/channel/
client hashes match this snapshot; the retained journey log reports three passes.
The receipt also records 136 mutation-owner, ten channel and one client passes.
These checks do not qualify automatic restoration, live persistence, native/browser
interaction or complete session parity.

The [search/resume receipt](quality/session-search-resume-journey.md) records four
production-screen/channel/client journeys and 111 nearest passes. All six scoped
source hashes match this snapshot; retained logs confirm those counts and clean
final analysis. Search filters loaded row metadata, not the server transcript corpus.
Explicit selection and reconnect/reopen read authoritative fixture history with
only GET requests. Late old-selection/profile results cannot replace the current owner.
SESSIONS is met for its recorded deterministic journeys, not complete Desktop
parity. Full-text search, automatic restoration, full-router, browser/native and
live qualification remain separate gaps. This pass inspects receipts and runs
no product tests.

The [bounded session-picker receipt](quality/session-model-pair-read.md) records
358 focused Flutter passes and a fresh JS-release build. Production-path widgets
at 390px and 1280px check unknown identity, deliberate selection, route return,
repeated Cancel, exact owner/history and zero mutations before selection.
When the Agent does not report the pair, Use for session must remain disabled
until an explicit choice. Known acknowledged identities must remain distinct
from catalog eligibility. These checks do not prove exact-pair restoration.
The unchanged integrated browser cases still fail at both widths on line 192's
exact-pair assertion. Later resumed-send and final mutation-count assertions are
NOT_CHECKED. M1 remains partial; native/live qualification is separate.


The [Chat new-session selector receipt](quality/chat-new-session-selector-repair.md)
records 28 passing cases across the smoke and speech browser suites.
The repaired selectors distinguish Chat's `New session` from the shell's
`New Session`. Speech checks cover 1280px and 390px, including the compact menu.
Both recorded test fingerprints match the inspected files. This is retained
compiled Chromium evidence, not a new run or physical speech qualification.
The earlier strict-selector failures do not describe these repaired callers.
Other browser suites, live Agent behavior and native relaunch remain unverified.
The passing harness slice does not close FIX-NPM-AUDIT or SECURITY.

The committed retirement removes the optional OmniRoute installer and its
embedded dependency closure. The [historical dependency review](quality/omniroute-install-review.md)
retains failed audit results for its original inputs. These failures do not prove
that the current root dependencies fail, and removal is not a passing audit.
The existing security successor must verify absent installer assets, CLI actions,
discovery and special profile setup, while preserving generic Agent inventory,
historical audit data and external installations. Run the root audit and the
focused retirement checks on the supported toolchain with exact source bindings.
The [backlog](../TODO.md#now--next) lists these checks; this pass runs none of them.

For each executed check, record the exact command, exit status, parsed result
counts where available, source identity, target and log/receipt references.
Separate passed, failed, not run and blocked checks. A receipt from a predecessor
snapshot does not prove a later dirty tree passes.

The Desktop-first daily workflow remains unaccepted where the
[parity ledger](product/hermes-desktop-parity.md) and
[restoration admission review](quality/2026-10-04-autogoal-restoration-admission-review.md)
withhold exact provider/model restoration or native/live admission. Focused Chat
repairs do not close those gates. The bounded global loaded-session slice is
independently approved; see its [runbook](runbooks/global-session-access.md).
Its retained shell fingerprint differs from the current sidebar. Historical
approval does not qualify the changed presentation. The later
[shell redesign receipt](runbooks/desktop-shell-reference-fidelity.md) records
57 focused widget passes and two compiled Chromium journeys, including global
Open/New. Its four final source fingerprints match the inspected snapshot, but
its manifest does not bind every global-session caller/test/browser input.
The receipt's later [P1 correction](runbooks/desktop-shell-reference-fidelity.md#independent-review-p1-correction)
fixes a focus outline hidden by an opaque Ink overlay. Style assertions alone
missed this defect; the augmented regression checks rendered edge pixels with
simultaneous hover and focus in both themes. Retained `focus-fix-tests.log` and
`focus-fix-browser-tests.log` record 57 widget passes and two Chromium passes.
These are executor checks, not independent finish approval or a full-suite pass.
The [fresh current-source receipt](quality/2026-10-06-global-sessions-current-check.md)
binds 521 copied inputs and a 195-file local dependency closure at review. Its command
receipt records 44 shell-widget passes, nine caller/lifetime passes, a fresh web
build and one deterministic Chromium Open/New pass, all exit 0. Fresh execution
replaces incomplete historical attribution; this documentation pass did not rerun
those checks. The [independent review receipt](../.task-evidence/t_d06ef06d/review-run/review-validation.json)
records approved bounded acceptance and independent repetition of the same checks.
All 31 executor and 27 review integrity entries remain intact. The documentation
recheck found fifteen changed inputs among the 521 recorded source fingerprints.
They include shared recovery code, channel tests and restoration/recreation tests.
The ledger preserves the completed task and bounded
review-snapshot acceptance; it does not qualify these later recovery/Stop edits.
DOC-M2-AMBIGUOUS-404 and DOC-M2-HISTORY-IDENTITY are done for their bounded repairs.
DOC-M2-HISTORY-ADMISSION is done for its bounded repair; the
[independent review verdict](../.task-evidence/t_4e4a4f7d/review-414.json) approves
that slice. DOC-M2-POST-REPAIR-CALLERS is done for bounded current-source
execution. The [post-repair receipt](quality/2026-10-06-m2-post-repair-callers.md)
records 85 focused passes, clean analysis/formatting, a fresh release build and
one compiled Chromium Open/New journey. The documentation recheck matches 518
of its 519 source inputs. `hermes_chat_death_completion_recovery_test.dart` has
changed since that receipt; the pass does not qualify this later test revision.
Independent final approval remains unverified. These deterministic checks do not
qualify M2. The delivered
[credential-denial oracle](quality/2026-10-06-m2-credential-denial-oracle.md)
records two app-level cases, 60 nearest passes and four selected channel passes.
All 428 recorded lib/test fingerprints match this snapshot. HTTP 401 denial and
public Retry retain the original lease and remembered owner. Later explicit
authority restoration admits canonical history before settlement, with zero
fixture recovery mutations. These are inspected receipts, not new test runs or
a final independent approval verdict. The later
[HTTP 403 oracle receipt](quality/2026-10-06-m2-forbidden-recovery-oracle.md)
records three app-level cases and 60 nearest passes. All 428 recorded lib/test
fingerprints match the inspected snapshot. Resource-read denial and public Retry
retain exact ownership; later explicit authority recovery admits canonical history
before settlement without fixture mutation replay. The ledger records this bounded
execution task done. The later [independent review execution receipt](../.task-evidence/t_b00feca2/review-440-tests.json)
records 63 passing cases and clean analysis. Its import-closure receipt matches
151 local dependencies and 443 analyzed files in this snapshot. This pass inspected
those receipts; it did not rerun product checks. Independent final approval remains
unverified. The delivered
[bootstrap HTTP 401 control](quality/2026-10-06-m2-bootstrap-denial-oracle.md)
records four app-level cases, 60 nearest passes and clean analysis. All 428
lib/test fingerprints, 151 local closure inputs and 443 analyzed files match
this snapshot. Required-capabilities denial and public Retry retain the exact
lease and remembered owner without mutation attempts. Explicit authority recovery
admits canonical history before settlement. This is inspected execution, not a
new product run or independent final approval. The delivered
[bootstrap HTTP 403 control](quality/2026-10-06-m2-bootstrap-forbidden-oracle.md)
records five app-level controls and 65 total passes with the nearest targets.
Its 151 local closure inputs and 443 analyzed files match the inspected snapshot.
Required-capabilities denial and public Retry retain byte-identical ownership and
remembered selection; original-authority recovery hydrates canonical history
before settlement without fixture mutation replay. This pass inspected receipts,
not a new product run or final independent approval. Synthetic denial does not
prove live expiry/revocation, Android process death or authoritative live counts.
Native desktop, live generation, full suites and full session-modal parity remain
unqualified.

The [keyboard follow-through](quality/flutter-keyboard-follow-through.md) records
an earlier failed full-suite run and later approved focused repair separately.
Passing focused checks do not establish a new full-suite result.
The later repository-root `npm run test` log records 3,386 passes and three
shell failures: two palette/selection assertions in
`test/shared/widgets/app_shell_reference_fidelity_test.dart` and a removed-brand
assertion in `test/shared/widgets/app_shell_test.dart`. See the
[retained log](../.task-evidence/repo-docs-npm-test.log). The subsequent
FINISH-DESKTOP-SHELL qualification is complete in [root TODO](../TODO.md#now--next).
DOC-GLOBAL-SESSIONS-CURRENT-CHECK remains done for its separately attributed receipt.
This is a separate historical failed run, not the isolated mirror's incomplete attempt.
It does not establish a session-authority defect. The subsequent commit `1afe1307`
has an [exact-tree delivery receipt](runbooks/desktop-shell-reference-fidelity.md#committed-tree-validation)
recording 3,469 passing Flutter tests, clean analysis/formatting, a release web build
and two Chromium shell journeys. This pass verified its tree and seven log hashes;
it did not rerun product checks. That committed-tree pass excludes today's untracked
inventory keyboard regression and concurrent changes. It does not qualify the
current dirty worktree, full web E2E suite, native runtime or live provider workflow.

The later [inventory keyboard qualification](quality/shell-inventory-keyboard-qualification.md)
records eight inventory widget passes at 390/1280px and 200% text, plus 73
focused shell passes. Clean analysis and two Chromium journeys followed a fresh
JS-release E2E build. Browser checks do not assert 200% text scaling. The
original harness passed unchanged; no production repair is claimed.
This documentation pass verifies retained log hashes and branch/harness identity,
not a new product run or independent final approval. PARITY-COMPOSITION remains
partial; native, live, screen-reader and complete-suite qualification remain separate.

The later [approval-settlement harness receipt](../.task-evidence/t_9cc17611/receipt.md)
records explicit session admission and a valid history envelope in the integrated
owner regression. The existing production responder fence is unchanged. Retained
logs record 12 owner tests and 405 neighboring tests passed, with clean analysis.
The current test blob matches the receipt. Earlier disposal checks timed out
before reaching settlement because the fixture had no admitted session; preserve
those failures as historical evidence, not a current production defect.
FIX-APPROVAL-SETTLEMENT-OWNER is done in the ledger. This documentation pass
inspects that receipt, not a new run, independent approval or complete M1 acceptance.

The [M2 continuity baseline](quality/2026-10-06-m2-continuity-baseline.md) records
passing deterministic channel/store checks, not Android OS-death acceptance.
The [app-level completion oracle](quality/2026-10-06-m2-death-completion-oracle.md)
now records a passing running → absent client → completed → recreated-client
check with exact owner/history restoration and zero replay. It uses deterministic
transport and mocked storage, not Android process death or a real keystore.
The existing `scripts/maestro/chat_process_recovery_qa.yaml` targets the production
package and checks active-run recovery, not completion while absent. Do not use
it as an isolated QA death-to-completion check. The
[Android preflight](quality/2026-10-06-m2-android-preflight.md) now maps package,
runner, storage and observer prerequisites for the remaining
[ANDROID-M2-DEATH-COMPLETE-01 scenario](quality/2026-10-06-m2-continuity-baseline.md#exactly-one-future-scenario-android-m2-death-complete-01).
Its offline integrity receipt matches 28 scoped source fingerprints; it is not
independent final approval or Android qualification.
The goal ledger marks [DOC-M2-ANDROID-PREFLIGHT](../TODO.md#now--next) done
for source-only preparation. Its retained receipt does not establish independent
final approval. The [counting-contract artifact](quality/2026-10-06-m2-counting-contract.md)
now traces the inspected metrics, run status, replay and authentication-audit reads.
None supplies complete accepted/rejected mutation counts, whole-attempt owner
coverage and closed observation intervals. Its disposition remains
`authoritative_counts_unavailable`. The offline integrity receipt binds 46 source
files and the document, not an installed runtime. The goal ledger now records
DOC-M2-COUNTING-CONTRACT done for that source-only slice. Its retained receipt
does not establish independent native review. The
[recovery-read admission task](../TODO.md#now--next) now has a
[source-bound characterization receipt](quality/2026-10-06-m2-recovery-read-admission.md).
Retained logs record 16 focused passes, one nearest recreation pass and clean
analysis in an isolated mirror. Green characterization assertions reproduced three
defects: ambiguous status 404 clears ownership, unrelated history is accepted under
the requested session, and an ungranted declared history scope does not prevent
reads. Required repair outcomes are retained unresolved ownership on ambiguous 404,
validated response/compaction lineage before publication or settlement, and refused
ungranted declared history reads without breaking legacy baseline compatibility.
The exact completed-status/history positive case is demonstrated, not unconditional
recovery admission. The [independent same-card review](../.task-evidence/t_3c5078de/review-validation.json)
approves the bounded characterization, not product recovery. It independently
repeats the 16 focused checks, one nearest check and clean analysis. The ledger
records that slice done. [Root TODO](../TODO.md#now--next) orders three bounded
repair oracles for ambiguous 404, history identity and declared history admission.
The later [ambiguous-404 repair receipt](quality/2026-10-06-m2-ambiguous-404.md)
records 18 focused, 78 nearest and 42 restoration passes, plus clean formatting
and analysis. Its three changed source/test hashes and retained command-log
hashes match the inspected snapshot. Both indistinguishable status errors now
retain the exact durable lease and duplicate-Send guard through Retry and channel
recreation. Later exact terminal status and canonical history settle without
replay. These are inspected executor receipts, not new runs by this documentation
pass. The [artifact-review receipt](../.task-evidence/t_3a5135a8/review-398-validation.json)
independently repeats baseline RED, 18 focused, 78 nearest and 42 restoration checks,
with clean format and analysis. The [scoped npm receipt](../.task-evidence/t_3a5135a8/review-398-npm-validation.json)
records 394 passes, not a full-suite run. All five authored fingerprints and eight
review log hashes match this snapshot. The goal ledger marks the 404 slice done
and subsequently marks history identity done. Do not duplicate completed work. These receipts
do not establish a final native approval verdict or M2 acceptance. The later
[history-identity implementation receipt](quality/2026-10-06-m2-history-identity.md)
records rejection before publication or lease settlement, with authorized
compaction-lineage positive controls. Retained logs record 48 focused, 432 nearest
and 63 caller/restoration passes, clean formatting and clean analysis. All 15
production/test/runbook fingerprints match this snapshot; the report itself has
changed since its recorded fingerprint. All 25 command-log hashes match.
The [independent review execution receipt](../.task-evidence/t_cd72a5d5/review-404-validation.json)
now binds all 16 selected source/document fingerprints, including the current report.
Its matching logs record 48 focused, 432 nearest and 63 caller passes, plus 543
scoped npm passes. The [independent review verdict](../.task-evidence/t_cd72a5d5/review-404.md)
approves the bounded implementation. DOC-M2-HISTORY-IDENTITY is done in the ledger;
this documentation pass reruns no product tests.
The later [history-admission implementation receipt](quality/2026-10-06-m2-history-admission.md)
records declared denial before history I/O, preserved legacy/granted controls and
retained ownership through recreation. All six selected source/document hashes
match; final retained logs record 64 focused, 432 nearest and 43 caller passes,
clean formatting and clean analysis. The superseded 63-test focused log is not
retained and is not acceptance evidence. The
[independent review verdict](../.task-evidence/t_4e4a4f7d/review-414.json) approves
the bounded repair. Its matching combined log records 539 focused, nearest and
caller passes; its receipt also records clean analysis and unchanged formatting.
The read-only integrity check verifies six selected source/document hashes,
441 mirror Dart files, manifests, commit contents and retained command logs.
DOC-M2-HISTORY-ADMISSION remains done in the ledger. Neither
historical characterization nor these bounded repairs qualifies Android or live recovery.
The later [post-repair caller receipt](quality/2026-10-06-m2-post-repair-callers.md)
records the separate deterministic caller/lifetime and compiled-browser pass.
HTTP 401 and HTTP 403 resource-read denial now have the bounded receipts above.
Required-capabilities HTTP 401 and HTTP 403 rejection now have completed
app-level controls. The delivered
[observer composition](quality/2026-10-06-m2-observer-composition.md) maps 185 local
source files and 775 dependency edges in its predecessor snapshot. Its retained
integrity receipt is not current-source, compiled or device evidence.
The [QA observer receipt](../.task-evidence/t_53f0d91e/report.md),
[delivery brief](quality/2026-10-06-m2-qa-delivery-admission.md),
[receipt-handoff proposal](quality/2026-10-06-m2-receipt-handoff-contract.md),
[admission trace](quality/2026-10-06-m2-coordinator-admission-trace.md),
[custody requirements](quality/2026-10-06-m2-custody-proof-review.md),
[isolated ordering oracle](quality/2026-10-06-m2-custody-ordering-oracle.md) and
[caller-closure report](quality/2026-10-06-m2-runtime-caller-closure.md)
are predecessor evidence. Their source bindings do not qualify the later privacy
migration or current runtime construction. Preserve their bounded historical results.

The delivered [default-refusal boundary](quality/2026-10-06-m2-default-refusal.md)
now executes REG-DEFAULT/INJECTION/API/POSITIVE. The actual QA main awaits the
input-free bootstrap and returns without Flutter binding, app launch or runtime I/O.
Runtime sink, journal, observer and authority injection APIs are absent.
Private fake diagnostics preserve validator, ordering, invalidation and error controls.
The retained [validation receipt](../.task-evidence/t_41606eec/validation.json)
records 44 tooling passes, clean analysis and unchanged formatting.
The [probe receipt](../.task-evidence/t_41606eec/probes.json) records 60 negative
external consumers, four positive metadata/bootstrap controls and three isolated
mutations that break their intended invariant. All 13 authored fingerprints match.
These are inspected executor receipts, not new product runs or independent approval.
The probes cover source-level refusal and library privacy, not installed plugin I/O.

QA-M2-DEFAULT-REFUSAL and DOC-M2-REFUSAL-CONTINUATION are done for their
bounded source-only slices. The [updated preflight](quality/2026-10-06-m2-refusal-continuation-preflight.md)
separates removed observation APIs from retained product storage/history seams.
DOC-M2-ISSUER-EVIDENCE-CONTRACT is done for its source-only
[admission dossier](quality/2026-10-06-m2-issuer-evidence-contract.md), not installed
admission. The dossier remains PROPOSED; all ten installed facts are UNAVAILABLE.
The delivered [package provenance brief](quality/2026-10-06-m2-package-provenance.md)
distinguishes configuration from measured package mode, compiled target and
complete delivered closure. Its retained checks are lexical source evidence,
not artifact measurement. F01/F02 remain UNAVAILABLE. The delivered
[manifest assessment contract](quality/2026-10-06-m2-manifest-assessment-contract.md)
remains PROPOSED. Its retained lexical and altered-document checks verify document
integrity, not an inspector, sandbox, XML parser, APK or Android runtime.
The future assessment must distinguish measured rejection from parser failure,
refuse changed inputs and tool closure, and discard results after isolation failure.
Even MANIFEST_FACTS_ONLY leaves the candidate NOT_ADMITTED. The delivered
[isolation preflight](quality/2026-10-06-m2-inspector-isolation-preflight.md)
records public metadata only. It does not demonstrate namespace permission,
resource enforcement, immutable-input seals or a complete pinned tool closure.
The delivered [synthetic isolation contract](quality/2026-10-06-m2-synthetic-isolation-contract.md)
defines expected refusals when exact limits or descendant cleanup cannot be
enforced. It is a PROPOSED source-only contract, not executed containment proof.
Exact cumulative CPU enforcement remains UNAVAILABLE; per-process limits, rate
controls and counter polling do not establish the aggregate ceiling.
The [delivered CPU feasibility assessment](quality/2026-10-06-m2-cpu-enforcement-feasibility.md)
finds no established exact-budget mechanism among the reviewed interfaces.
It records UNAVAILABLE / cpu_budget_unavailable and no mechanism execution.
The delivered [CPU-envelope assessment](quality/2026-10-06-m2-cpu-envelope-proof.md)
identifies `B_setup` as the first unestablished term. Its document-integrity checks
do not prove the inclusive CPU bound. DOC-M2-CPU-ENVELOPE-PROOF is done for
source-only delivery; M2 remains unverified. Inode-policy review remains separate. No APK, inspector or
synthetic control execution is admitted.
Wrong or absent evidence must remain NOT_ADMITTED.
Document review does not admit an installed issuer.
Runtime bootstrap
must remain `not_admitted` and `continuation_unavailable`, with `qualifies=false`.
No installed issuer, secure-storage protection/durability, cross-process custody,
packaging, private retrieval, Android process death or live target is qualified.
History admission and authoritative counting require separate evidence.
M2 remains unverified. Health totals, unchanged history and fixture counters cannot
establish zero live restoration mutations. Named-device, credential-denial and
denied-notification checks retain their separate qualification requirements.

The [M6 artifact inventory](quality/2026-10-06-m6-artifact-evidence.md) maps
receipt producers, exact verifier inputs and integrated recovery gaps. Its offline
checks are not candidate execution or installed-alpha acceptance. The delivered
[offline admission oracle](quality/2026-10-06-m6-candidate-admission.md) records
56 passing synthetic checks, including changed identity/bytes/certificate and
missing receipts. The goal ledger marks DOC-M6-CANDIDATE-ADMISSION done for that
bounded preparation; independent final approval is not established by this receipt.
The delivered [read-only comparator](runbooks/offline-release-candidate-comparison.md)
requires independent public expectations and compares the published index with
recomputed bindings. Its [source-bound receipt](../.task-evidence/t_bef84284/validation.json)
records `node --test test/tooling/compare_release_candidate_test.mjs test/tooling/release_evidence_test.mjs`: 120 passes, zero failures.
All four recorded production/test/runbook fingerprints match this snapshot.
This is retained synthetic evidence on Node v26.7.0, not a new test run or
Node 22 qualification. The goal ledger now records DOC-M6-OFFLINE-CHECKER done
for the bounded comparator slice; its retained receipt does not establish native
same-card approval. The [Node 22 proof task](../TODO.md#now--next) covers baseline
execution without treating another runtime version as a pass. Actual public candidate
comparison, signatures and installed-runtime qualification remain NOT_CHECKED.
A passing comparison does not prove install, upgrade,
rollback or applicable M1–M5 behavior on the same artifact. Those require separate
source-, artifact- and target-bound execution receipts.

The [discovery conformance receipt](quality/2026-10-06-wing-link-api-conformance.md)
now records executed offline checks for Wing Link GET `/meta` and GET `/healthz`.
All 20 recorded source fingerprints match this snapshot. The retained receipt
records passing YAML parsing, local-reference and JSON Schema checks, two scoped
Go commands, 62 recorder responses and nine rejected negative cases. The metadata
schema now requires the exact supported-generation array `[1, 2]`. Initialization
failure, negotiation precedence and dispatch boundaries are checked without sockets.
This is inspected execution evidence, not a new run by this documentation pass.
The goal ledger now records DOC-API-CONFORMANCE done for discovery only; the
receipt does not establish native same-card approval. The
[device-self conformance task](../TODO.md#now--next) covers one remaining family.
Full OpenAPI standards validation, other management families,
TLS/pinning, live transport and complete API conformance remain NOT_CHECKED.
The whole API-CONFORMANCE goal remains unverified despite this bounded pass.

Physical speech, platform screen-reader use, current-source process-death soak,
signed distribution and update/service rollback need their own matching evidence.
No new runtime check was executed by writing this test plan.
