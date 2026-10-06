# Android M2 death-to-completion isolation and observer preflight

Date identifier: 2026-10-06. Card: `t_f5728f44`.
Goal task: `DOC-M2-ANDROID-PREFLIGHT`. M2 remains **unverified**.

## Result and evidence ceiling

Delivered a source-backed prerequisite map for **ANDROID-M2-DEATH-COMPLETE-01**,
not a device qualification or an executable runner. No runtime capability is
activated. Static package isolation exists conditionally; the feature fixture
replaces the recovery stack, and the existing recovery flow targets production
storage and asserts active/Reconnect rather than absent-client completion.
Exactly one future slice is specified below: a QA-only metadata observation adapter.

The [baseline scenario](2026-10-06-m2-continuity-baseline.md#exactly-one-future-scenario-android-m2-death-complete-01)
and [deterministic oracle receipt](2026-10-06-m2-death-completion-oracle.md)
remain the acceptance references. The latter records one passing Linux widget
oracle, not OS process death. Its historical counters are `runStarts=1`,
`sessionCreates=0`, `otherMutations=0`, recovery mutation delta zero. These are
fixture results, not observations made by this card against Android or Agent.

No build, Flutter/analyzer/test, Maestro (including syntax check), adb, discovery,
install, socket, live request, credential acquisition, provider inference or
process action ran. Retained flutter_tester PID 96817 and shared build/fixture/
display resources were not touched. Connection/lifecycle owner sources,
Disconnect and approval-dismissal tests/runbooks and their evidence trees are
excluded. Reference clones were not needed or inspected deeply and are unchanged.
No production code, existing test, runner, manifest, runbook or shared ledger was
edited. Source-only findings are gaps, not permission to repair other slices.

## Named-target admission record — not allocated

| Field | Current value / required future evidence |
| --- | --- |
| Disposable target name | NOT_ALLOCATED. Future receipt must name one newly owned disposable emulator; no historical AVD or personal application may be reused by default. |
| Unique serial | NOT_CHECKED / unset. Mandatory explicit serial; never auto-select the first attached device or allow an empty serial. Keep actual local serial in private qualification metadata; publish a stable target alias and equality result. |
| Android release/API/ABI | Proposed default Android 14 / API 34 / x86_64, pending real target readback. These are requested values, not discovered hardware. |
| QA package / storage owner | Required `com.trebuchetdynamics.hermes.wing.qa`; conditional debug suffix is source-backed, installation and storage separation NOT_CHECKED. Never use production `com.trebuchetdynamics.hermes.wing`. |
| Source/APK/entrypoint | Source fingerprints captured here; APK digest, packaged entrypoint, merged package ID and build/install identity NOT_CHECKED. Existing feature entrypoint is not the required recovery entrypoint. |
| Agent / profile / session / run | NOT_ADMITTED. Require a separately qualified unmodified Agent/M1 run-mode receipt and exact non-default owner tuple before one deliberate turn. No guessed endpoint or replacement session. |
| Authentication / cost | NOT_ADMITTED. Separate private disposable auth, authorized network/provider/model and one bounded-turn cost ceiling are required. No credential values or cost consent are inferred from source or fixtures. |
| Process / generation | NOT_CHECKED. Future PID disappearance plus a fresh process-generation alias must be witnessed independently; ProviderContainer recreation is not that observation. |

The static identity chain is
`scripts/run_android_maestro_features.sh:7–15` (required target and isolated
Maestro cache) → `scripts/run_android_maestro_features.sh:42–46` (debug fixture
build/install/explicit runner target) → `android/app/build.gradle.kts:37–45`
(base application ID) and `android/app/build.gradle.kts:80–94` (debug-only `.qa`
when `WING_ISOLATED_DEVICE_TEST=1`). The fixed APK path is shared build output,
not a task-owned artifact or an isolation lock. `WING_QA_OUTPUT_DIR` is optional;
cache isolation does not isolate the Flutter build directory, Gradle resources,
device ownership, fixture or display. There is no cleanup trap or installed-package
readback in the 46-line wrapper. A nonempty serial is not proof of disposable ownership.

## Scenario prerequisite and oracle map

INSPECTED means exact source evidence, not execution. INHERITED means the scoped
historical deterministic receipt is retained with its limits. GAP means absent
from the inspected paths, not a repository-wide nonexistence claim. All Android,
live Agent and provider assertions below are NOT_CHECKED.

| Requirement | Exact existing source / receipt | What remains missing |
| --- | --- | --- |
| Explicit disposable serial/API/ABI and exclusive target ownership | Baseline lines 159–164; runner required `WING_QA_DEVICE` at 7–8 and `-s` / `--device` at 44–45 | No named-target identity readback, ownership lease, API/ABI assertion or exclusive-device cleanup contract in this wrapper. Admission record above is intentionally empty. |
| QA package, storage and build identity | Gradle `defaultConfig` and conditional debug suffix above; feature wrapper 42–46 | Verify actual merged package and APK digest/entrypoint before install. Recovery YAML names production package at line 6; never run it unchanged. `.qa` static intent alone does not prove Keystore/shared-preference isolation or installed binary identity. |
| Recovery dependency delivery | `integration_test/hermes_features_maestro_main.dart:80–99`, `integration_test/hermes_features_maestro_main.dart:104–108`, `integration_test/hermes_features_maestro_main.dart:154–180`: provider overrides, `MaestroFeatureChannel`, fake endpoint store and fake summary loader; `integration_test/support/maestro/feature_channel.dart:101–109` documents fake service | The packaged feature fixture does not exercise real detached persistence, direct Agent transport or production remembered-startup recovery. Requires a distinct QA entrypoint that does not replace those seams; no packaging/build success inferred from imports. |
| Admitted unmodified Agent/run contract | `docs/runbooks/hermes-agent-release-compatibility.md:3–20`, `docs/runbooks/hermes-agent-release-compatibility.md:59–61`; `docs/adr/client.md:61–81`; `lib/core/hermes/client/hermes_api_client.dart:355–424` (`startRun`, `getRunStatus`, `runEvents`); oracle fixture capabilities at test lines 97–145 | Source-derived capabilities/client methods are not an M1 live receipt. Verify advertised exact methods/routes/grants/profile binding and canonical history on the disposable runtime. No native-web substitution or upstream patch. |
| Private auth and bounded cost consent | Baseline 165–175; `docs/security/threat-model.md:29–41`, `docs/adr/api-and-state.md:13–36` | No target-scoped private auth or turn/cost admission collected here. Keep Agent and Wing Link secrets separate; no argv, URLs, clipboard, fixture, logs or personal credential reuse. Existing runbook command examples are not secret-safe execution authorization. |
| Metadata-only durable lease-write acknowledgement | `lib/core/hermes/channel/api_channel/hermes_api_channel_messaging.dart:222–269` awaits `store.save`; `lib/core/hermes/setup/secure_hermes_detached_run_store.dart:45–54` awaits platform secure write; `lib/core/hermes/channel/hermes_detached_run_store.dart:74–84` is the load/save seam | Awaited write is a source seam, not externally witnessed Android durability. No QA metadata acknowledgement is exposed in these inspected paths. Real storage write/read survival/lock behavior must be observed without dumping secure values. |
| Process generation and running-before-death | Oracle test 333–363 asserts running/lease, removes tree/container, then marks client absent; recovery YAML 30–34 asserts Stop and immediately stops/launches | No PID/generation witness or authoritative running read immediately before confirmed death. Stop button visibility is not server state. Completion before death makes the attempt non-discriminating and invalid; no automatic second turn. |
| Completed while client absent | Test `_Backend.completeWhileAbsent` at 83–88 and oracle 353–363; `_recoverDetachedRun` source below | Current YAML never waits while absent or reads completed canonical history. Require independent authenticated direct Agent status/history reads during absence, bounded at 120 seconds; terminal failed/cancelled/404 is not completed acceptance. |
| Exact restored origin/profile/session/run | `lib/features/hermes_chat/gateways/hermes_gateway_directory.dart:1031–1115` (`activate` preferred session returns before new-session branch); `lib/core/hermes/channel/api_channel/hermes_api_channel_sessions.dart:15–54` (`_restoreSession`); oracle 388–390 and 431–433 | Named-device stored owner and generation readback absent. Labels, latest inventory, default bootstrap reads and Reconnect cannot establish exact ownership. Newer unrelated inventory session in fixture discriminates substitution only deterministically. |
| Canonical IDs/order/result and guard release after hydration | `lib/core/hermes/channel/api_channel/hermes_api_channel_messaging.dart:2092–2182` (`_recoverDetachedRun`) matches tuple/status, fetches turns, then removes/persists lease; `lib/core/hermes/client/hermes_api_client.dart:220–244` (`sessionMessagesPage`); oracle 369–446 parks history, checks exact IDs/authors/order/text/status, single visible entries and lease release | No Android canonical-read/UI correspondence or synthetic result digest observer. Must compare canonical server messages to recovered channel/UI using aliases and in-memory synthetic-result comparison; lease acknowledgement of removal comes only after successful history. Transient/mismatched status keeps uncertainty. 404 is registry-absence policy, not completion. |
| Exactly one deliberate submission, zero recovery creates/sends/Stop/approvals | Test `_Backend.mutations` at 66–81 and transport interception 214–259; final `recoveryReads`/counter checks at 434–446 | The fixture counts every non-GET attempt and rejects unknown transport. Android feature controls only show in-memory `submittedTurns`/selected fake mutation arrays, not an authoritative ledger surviving death. Need server-side counts plus client attempt counts; never conclude zero from missing UI/logs. |
| Notifications denied, foreground status/history usable | `ROADMAP.md:156–171`; `docs/product/notification-contract-proposal.md:3–19`; `android/app/src/main/AndroidManifest.xml:1–13` has no notification permission declaration | No notification-denial/readback oracle in recovery YAML. Read/search of Android source found no `POST_NOTIFICATIONS` seam; packaged manifest and OS permission state still NOT_CHECKED. Absence of push implementation is not proof of tested permission denial. No push enrollment/tap/delivery enters this slice. |
| Expiry/revocation and wrong-owner ceilings | Baseline 204–217; `_recoverDetachedRun` tuple checks at 2108–2132 and failure branch 2159–2171; directory authentication restoration failure 1069–1079 | Widget oracle is not real expiry/revocation. QA fixture's `trustClient` 244–275 and controls 450–455 simulate Wing Link failures, not expiry/revocation of the Agent credential. Require separately authorized controls on the same completed disposable run, counters across controls, no foreign hydration, replacement session, send or approval; missing expiry or revocation stays NOT_CHECKED individually. |

### Current observer search boundary

`integration_test/hermes_features_maestro_main.dart:357–378` shows display-only
fixture counters (`Submitted turns`, approval decisions, model/persona writes,
microphone permission), not durable/server metadata. `MaestroFeatureChannel.sendText`
at `integration_test/support/maestro/feature_channel.dart:327–359` increments an
in-memory counter and emits a fake approval; it cannot keep an independent Agent
run alive after process death. A focused `search_files` search for
`lease|detached|runStarts|otherMutations|secure|recovery` in
`integration_test/support/maestro` returned zero matches. This establishes only
that bounded directory search; no repository-wide absence claim is made.

The original recovery flow is independently insufficient:
`scripts/maestro/chat_process_recovery_qa.yaml:6–10` addresses production;
`scripts/maestro/chat_process_recovery_qa.yaml:22–34` creates a session, requests a
2,000-word story and immediately stops/relaunches;
`scripts/maestro/chat_process_recovery_qa.yaml:41–46` checks still-active/Reconnect
and absent Retry/Stop. It supplies none of the absent-client terminal-history,
exact tuple, durable-ack or authoritative-count oracles. Do not adapt the broad
regression wrapper by running it; its unrelated mutation coverage is not admission.

## Exactly one next slice — QA metadata observation adapter

Proposed, NOT_IMPLEMENTED and NOT_AUTHORIZED to run by this card. This is the
smallest observation prerequisite, not a full Android runner, another task,
production instrumentation or an Agent-side modification.

### Bounded write and delivery contract

A future scoped implementation may add only a new QA observation support module,
one new dedicated integration QA entrypoint composing production startup/channel/
endpoint/secure-store seams, and its nearest new deterministic adapter tests.
Proposed resources: `integration_test/support/m2_observer.dart`,
`integration_test/hermes_m2_observer_main.dart`,
`test/tooling/m2_observer_test.dart`, plus that future card's evidence directory.
These paths are a proposed write allowlist, not claims that files exist today.
Do not change feature fixtures, existing scripts/manifests, shared shell, connection/
lifecycle owners, upstream code, Wing Link data-plane routing or personal storage.
If composition requires any such change, report a dependency gap rather than widen
this slice. Runtime/device execution is separate future admission.

Wrap `HermesDetachedRunStore` at the existing injectable channel seam, delegating
to `SecureHermesDetachedRunStore`; report write acknowledgement only after delegated
save returns successfully, with sequence and process-generation binding. Failure
emits a typed failure, never success. Use channel state only to witness hydrated
canonical IDs/order and unresolved ownership; do not inject synthetic recovered
state. The widget oracle's fixture slot is not the real store for this adapter.

The observer must NOT proxy Agent traffic, intercept credentials into logs, create
shadow run state or edit Agent. It consumes a separately admitted read-only,
metadata-only authoritative counting source from the unmodified Agent deployment.
No supported counting endpoint/operation was qualified here. If the deployment
cannot provide one without an Agent modification, the adapter must emit
`authoritative_counts_unavailable` and refuse qualification. Client request
interception is a diagnostic supplement, never the authoritative server ledger.
This unknown source is an admission gap, not permission to invent a route or use
Wing Link as a proxy. A QA-only in-process fake may test observer validation but
must be visibly typed `fixture`, not a live evidence substitute.

Delivery checks for that future slice must resolve the new entrypoint's complete
local import closure, prove no fake channel/directory/endpoint or mocked secure
storage override is included, and inspect the packaged APK/merged application ID
and entrypoint identity. Existing Gradle support is a lead, not packaged execution
proof. With scripts/manifests excluded, missing dedicated runner/install verification
remains a separate recorded gap, not an edit authorization. No such build ran here.

### Allowlisted output and fail-closed rules

Emit one bounded schema-versioned metadata stream to a private QA observer sink,
maximum 128 events and 64 KiB per attempt, no global logcat dump or analytics.
Retain sanitized receipts in the future card's evidence directory. Allow only:

- attempt/target/process-generation and origin/profile/session/run/message aliases
  (random per-attempt aliases, max 64 characters); sequence and monotonic elapsed
  milliseconds; application ID, API/ABI and reviewed source/APK digests;
- enumerated phase/status/error, store write/load/removal acknowledgement booleans,
  exact-owner/history/order/synthetic-result-match booleans, notification denial
  readback, old-PID-absent/new-generation booleans;
- total and phase-delta integer counters for deliberate submission, run starts,
  session creates, chat/completions sends, Stop, approval responses and unknown
  mutations, including rejected attempts; ledger epoch/complete-coverage boolean;
- synthetic-only expected-result digest computed locally and discarded raw output,
  never a digest of a credential, private origin, personal transcript or host path.

Raw PID/serial and alias mappings remain ephemeral private coordinator metadata;
public receipts contain aliases and matched booleans. No raw origin, IDs, profile
labels, paths, request body, prompt/output, auth header, key, cookie, storage blob,
recognized speech, provider value or arbitrary error string may be emitted.
Reject extra fields, malformed/out-of-order/duplicate events, mixed attempt or
process generations, overflow, missing owner dimensions, foreign tuple, missing
acknowledgement, dropped records or ledger reset. Do not trust self-reported
client counts as complete server coverage. Counts must cover the whole disposable
credential/attempt, not merely filter the expected run: replacement sessions,
wrong-profile sends and alternate transports must remain detectable.

Keep client mutation-attempt counts and authoritative accepted/rejected operation
counts separate. Require a continuous authoritative epoch across death/relaunch,
closed observation intervals, and a complete mutation classification; unknown
non-read operations fail acceptance. A network failure, auth denial or source
restart must not collapse unknown into zero. Read operations must preserve exact
owner binding; missing required grants prevent admission, not cause fallback.

### Discriminating checks and cleanup boundary

Future adapter tests must prove: delayed/failed storage writes cannot acknowledge;
wrong/stale owner or generation cannot satisfy history; missing/duplicated/order-
changed message IDs fail; a second submission or any session-create/send/Stop/
approval/unknown mutation increments a counter and fails zero-delta; ledger loss,
reset or unavailable authority refuses qualification; forbidden fields fail
schema validation. Fixture tests prove these observer rules only.

A later authorized coordinator must perform the baseline's single attempt:
notification denial readback → explicit owner and one accepted submission →
authoritative running plus durable acknowledgement → background and running
readback → confirmed QA PID absence → exact completed status/canonical history
while absent → same-storage relaunch with fresh generation → exact canonical UI
and guard removal only after hydration → authoritative total one and recovery
mutation delta zero. Bound the absent wait to 120 seconds; completion before death,
timeout, failed/cancelled/404, missing evidence or identity drift fails the attempt.
Never auto-retry generation or create another session. The same completed run may
support separately admitted expiry/revocation/wrong-owner controls, not extra turns.

The coordinator must own a disposable serial, QA package, task-specific build/output
and observer resources before any action; do not borrow shared build/fixture/display
resources. Preserve app data across the death interval and recheck installed identity
before launch/stop. After collection, revoke only the separately admitted disposable
credential through its supported authorized contract, delete ephemeral observer
mappings and clean up only owned QA/emulator resources. No production package,
shared AVD, private auth file, Agent profile/domain data or other card/process may
be cleared. Cleanup failures are reported separately, never hidden by a passing UI.
No install, permission mutation, revocation, death or cleanup action is authorized
here. Keystore durability/lock, OS death, real denial/expiry/revocation, inference,
live M1, packaged runtime and push all remain NOT_CHECKED.

## Offline checks, source binding and acceptance

Bounded source evidence is in this card's local uncommitted
`.task-evidence/t_f5728f44/` directory:
`source-snapshot.json`, `ownership.json`, `acceptance.json`, `validation.json`
and `check_preflight.py`. Fingerprints bind 28 explicitly selected files at HEAD
`4acdb4e1f51262ccfdca5174776eed1e3ef65188`; dirty-file SHA-256, not HEAD alone,
is the authority. Eight overlapping predecessor files matched the oracle's
`source-hashes.json`, including the oracle, messaging/session restoration, client,
directory and detached-store seams. This is scoped freshness only, not revalidation
of the predecessor's 200-file closure, excluded connection/lifecycle sources or
historical analyzer/full-suite results. The predecessor `oracle-verified.json`
exit 0 and four-line log were read, not replayed.

Executed from the repository root:

```text
python3 /home/xel/.hermes/shared-skills/repo-docs/scripts/goals.py next /home/xel/git/gormes/hermes-wing --json
python3 .task-evidence/t_f5728f44/check_preflight.py snapshot
python3 .task-evidence/t_f5728f44/check_preflight.py ownership
python3 .task-evidence/t_f5728f44/check_preflight.py verify
```

The read-only helper returned this task first, `in_progress`, M2 `unverified`;
snapshot/ownership exited 0. `verify` parses task receipt JSON, verifies local
links and source-line ranges, compares bounded source hashes and unchanged shared
ledger bytes, and executes these scoped checks:

```text
git diff --no-index --check /dev/null docs/quality/2026-10-06-m2-android-preflight.md
git diff --check -- docs/quality/2026-10-06-m2-android-preflight.md .task-evidence/t_f5728f44
```

The first complete `verify` exited 0: two local links (including the scenario
anchor), 29 source-line ranges and three receipt JSON files passed; all 28 source
fingerprints and both shared ledger files were unchanged. The no-index check
exited 1 with empty stdout/stderr (added-file difference, no whitespace
diagnostics); scoped tracked diff check exited 0. Final document SHA-256 and
repeated final integrity readback are in `validation.json` and native review
metadata. These checks prove document integrity, not platform/runtime support.

Acceptance mapping:

1. Complete prerequisite-to-source/gap map: named-target admission table and
   scenario matrix, exact cited symbols/line ranges, bounded SHA-256 snapshot
   and scoped predecessor equality. No fabricated target, counters or live output.
2. One smallest future observer slice: bounded new-file allowlist, typed redaction,
   real-store acknowledgement, authoritative counting admission, fail-closed tuple/
   generation/ledger rules, discriminating checks and separate runner/delivery/
   cleanup gates. No implementation activated and no second task created.
3. Offline receipt parsing, local links, line ranges and scoped whitespace/freshness
   checks: `check_preflight.py verify` and `validation.json`; native same-card
   review is the sole independent final acceptance lane. Review entry is requested
   after those checks; an entry refusal is preserved verbatim without replaying
   tests, replacing this card or claiming approval.

Fresh ownership readback confirmed this running Wing card and no other running
Wing card. The selection receipt reserves shared TODO/goals editing for delegated
repo-docs job `ba15b4ed8db6`; no release of that reservation was observed. Therefore
no `task done`, `evidence` mutation or `render` ran against the shared ledger.
A profile-local journal/completion receipt carries this documentation handoff to
repo-docs. Do not feed document-integrity passes into M2 acceptance: `goals.py`
evidence can auto-promote an unverified goal when all its tasks are done. Keep
Android qualification represented as unverified; only the authorized native
review lane may approve this card. No owner questions are needed for this slice.
Default applied: source-only preparation and proposed API 34 x86_64 target class,
not allocation, implementation or live qualification.
