# M2 production-preserving QA observer composition

## Disposition and evidence ceiling

DOC-M2-OBSERVER-COMPOSITION / t_bd91fa65 is a source-only composition slice.
M2 remains **unverified**; `authoritative_counts_unavailable` remains mandatory.
No observer, entrypoint, product feature, build, device action or counting source
was implemented or activated. Complete static local closure is not compiled
closure, packaged execution, Android death durability or server mutation evidence.

The next bounded slice can implement a conservative QA store/state observer through
existing injection seams. It cannot currently qualify the whole Android scenario:
there is no admitted authoritative counting source, no existing private M2 sink,
and no public canonical-history-admitted callback before detached lease removal.
The last gap is observation, not evidence of a recovery bug: source ordering shows
an internal canonical fetch before removal, but public state is published later.
Do not alter owners/lifecycle to manufacture an observation in this slice.

Authority: [client transport qualification](../adr/client.md#transport-qualification)
and [API/state decision](../adr/api-and-state.md#decision). Counting authority for
this investigation is the [counting disposition](2026-10-06-m2-counting-contract.md#practical-next-step-disposition),
not new upstream research. The [three-file preflight](2026-10-06-m2-android-preflight.md#bounded-write-and-delivery-contract)
and [single accepted scenario](2026-10-06-m2-continuity-baseline.md#exactly-one-future-scenario-android-m2-death-complete-01)
are retained unchanged. Read-only Agent/Desktop reference locations are established
in AGENTS.md; no deep reference inspection or execution was needed here.

## Current startup and persistence composition

Source-line ranges below are checked against current dirty-source hashes, not
assumed to describe HEAD. The exact SHA-256/line records are in
[source-snapshot.json](../../.task-evidence/t_bd91fa65/source-snapshot.json);
all transitively reached Dart source hashes are in
[production-closure.json](../../.task-evidence/t_bd91fa65/production-closure.json).

| Edge / exact symbol | Current source and interpretation |
| --- | --- |
| `main` → `WingApp` | `lib/main.dart:1-5` calls `runApp(const WingApp())`; `lib/app.dart:1` exports `app/wing_app.dart`. |
| `WingApp.build` → scope/shell/router | `lib/app/wing_app.dart:14-22` creates its own default `ProviderScope` around `DesktopHostCommandListener` / private `_WingMaterialApp`. Lines 35-44 subscribe to production connect intents. `lib/router/providers/app_router.dart:41-63` initially opens `/hermes` and `HermesChatScreen`. Do not copy a fake feature shell. |
| Endpoint provider → real persistence | `lib/features/hermes_chat/providers/hermes_channel_provider.dart:17-19` creates `SecureHermesEndpointStore`. Its constructor uses real `FlutterSecureStorage`, not a mock. `lib/core/hermes/setup/secure_hermes_endpoint_store.dart:28-54` loads selected endpoint metadata with legacy/fallback behavior; 108-143 awaits the authoritative secure bundle write separately from non-secret preference projections. Never export endpoint configuration or credential bytes. |
| Channel provider → real transport / detached slot | `hermes_channel_provider.dart:23-28` creates `HermesApiChannel(detachedRunStore: SecureHermesDetachedRunStore())` and registers disposal. `lib/core/hermes/channel/hermes_api_channel.dart:43-64` is the public detached-store injection seam; the default clientBuilder stays `HermesApiClient`. No independent detached-store Riverpod provider exists. |
| Store contract / serialization | `lib/core/hermes/channel/hermes_detached_run_store.dart:74-84` exposes `coordinationKey`, `load`, `save`. `lib/core/hermes/setup/secure_hermes_detached_run_store.dart:10-25,46-54` uses one stable secure key, a maximum of 16 leases and an awaited secure write. A wrapper MUST preserve the delegated coordinationKey; a random observer key would split process-local operation serialization. |
| Real directory / cache / loader | `hermes_channel_provider.dart:40-69` supplies `HermesApiGatewaySummaryLoader`, `GatewayContactCache`, the secure endpoint provider and the same active channel; lifetime attach/detach is retained; directory startup is eager via `unawaited(directory.start())`. No fake directory/cache/endpoint substitution is acceptable. |
| Remembered selection → exact restore | `lib/features/hermes_chat/gateways/hermes_gateway_directory.dart:334-367` loads cache selection, cached contacts, refreshes real endpoints and activates the remembered contact with preferred session. `activate:1031-1114` uses current-generation checks, explicit profile selection, deferred session selection and `restoreSession(...canAccept: isCurrent)`. |
| Selection persistence | `lib/features/hermes_chat/gateways/gateway_contact_cache.dart:52-101` validates selection shape and checks `canWrite` after asynchronous preference acquisition. Directory `_rememberActiveSelection:1182-1212` serializes writes and fences owner/session/generations. This is a separate preference path, not detached-lease acknowledgement; swallowed preference failures are not proof of successful remembered-selection persistence. |
| Recovery vs explicit new session | Directory `activate:1117-1158` may create a session when no preferred session exists or for Telegram. A QA attempt MUST require the original explicit remembered session, not treat fallback endpoint/profile or session creation as recovery. Keep this production behavior unchanged and reject missing owner metadata. |
| State projection | `hermes_channel_provider.dart:32-37` listens to the channel and invalidates its immutable state projection. A QA listener can observe real state without replacing it. `HermesApiChannel._setState:143-176` publishes and notifies; private generation/history fields are not an observer API. |
| Direct Agent network | `lib/core/hermes/client/hermes_api_client.dart:22-46` selects platform transport defaults; IO `_request:86-106` opens the requested URI through `HttpClient`, disables redirects and uses supplied headers. Preserve clientBuilder/default transport; do not intercept bodies/headers, use native dashboard clients, or proxy through Wing Link. |

The default directory can also perform pending Wing Link credential acknowledgement
on refresh. That is management traffic, not Agent chat proxying. The later disposable
attempt must be enrolled and acknowledged before observation, and fail if management
setup intervenes; this card does not disable or override that production behavior.

### Delegated acknowledgement versus witnessed hydration

`_runDetachedStoreOperation` / `_persistDetachedMutation` in
`lib/core/hermes/channel/api_channel/hermes_api_channel_messaging.dart:1468-1514`
serialize on the delegated key, load/merge existing leases, await `save`, then replace
the in-process lease map. Successful return from the underlying secure write proves
only that delegated platform call completed. It does not witness Android keystore
protection, fsync, death survival, backup isolation or OS locking behavior.

`_recoverDetachedRun:2092-2175` binds origin/profile/session/run and connection /
profile/caller fences; exact terminal status must be followed by `_fetchTurns` before
removal. Authentication failure, foreign status, ambiguous 404 or history failure
retains conservative ownership. `_fetchTurns` in
`lib/core/hermes/channel/api_channel/hermes_api_channel_connection.dart:334-398`
checks read authorization and generations, accepts latest-page ordering, updates
private history/pagination caches, and returns turns WITHOUT publishing channel state.
`_selectSession` in `api_channel/hermes_api_channel_sessions.dart:57-131` subsequently
fetches/publishes canonical messages and Send-guard state. Therefore a store-wrapper
removal event can precede the listener's visible canonical-history event. Comparing
the later UI IDs cannot retroactively prove earlier public hydration admission.

A store wrapper may compare before/after lease tuples ephemerally to classify an
observed load/save/removal, but cannot read private history snapshots or internal
connection generations. Use a QA process-generation alias plus its own observation
fence, invalidate on owner transitions, and never label it the channel's private
generation. Separate store-write success, canonical identity/order match, public
settlement observation and qualification. Preserve unresolved evidence as unknown.

## Complete current local dependency closure

Root: current `lib/main.dart`. Recursive literal import/export/part traversal follows
`package:wing/` to `lib/`, relative paths, URI `part of` reverse edges, and EVERY
conditional alternative without selecting a runtime platform. The artifact enumerates
185 local files, 775 directed edges: 532 local, 160 external-package, 83 Dart SDK.
It records 710 imports, 25 exports, 20 parts and 20 reverse part-of edges, with file
hashes, directive source lines and conditional syntax. There are no unresolved local
literal targets in this snapshot. This is the complete current static local closure
under those rules, not a claim to resolve external package/plugin implementation.

Seven conditional directives and all alternatives are included:

| Source | Default / alternatives (all local) |
| --- | --- |
| `lib/core/hermes/client/hermes_api_client.dart:22-25` | transport stub; `dart.library.io` → IO; `dart.library.html` → web |
| `lib/core/wing_link/local_wing_link_host.dart:4-6` | local host stub; IO host |
| `lib/core/wing_link/wing_link_transport.dart:1-2` | transport stub; IO transport (conditional export) |
| `lib/core/wing_link/wing_link_transport_stub.dart:1-3` | Agent transport stub; HTML web transport |
| `lib/features/enrollment/providers/hermes_enrollment_provider.dart:16-17` | transport-failure stub; IO failure |
| `lib/features/hermes_chat/export/hermes_transcript_export.dart:6-9` | unsupported; IO; JS-interop web export |
| `lib/features/voice/services/platform/voice_capture_platform.dart:3-5` | voice stub; IO voice platform |

The app/router imports all feature routes, so the closure intentionally includes
voice, enrollment, export and host-management code even though the future scenario
will not exercise those routes. Channel library parts and screen/widget parts are
not omitted just because they share a library or are not separate runtime widgets.
The source graph is an all-alternatives superset, not Android compiler tree shaking.

### Explicit external, dynamic and native boundaries

The 17 external package roots are: `flutter`, `flutter_localizations`,
`flutter_riverpod`, `go_router`, `uuid`, `shared_preferences`,
`flutter_secure_storage`, `web`, `speech_to_text`, `audioplayers`, `flutter_tts`,
`flutter_markdown_plus`, `url_launcher`, `markdown`, `file_selector`, `crypto`, `intl`.
`intl` is referenced by generated localization code and represented in pubspec.lock;
it is not an additional proposed dependency. SDK boundaries are `dart:async`,
`collection`, `convert`, `developer`, `io`, `js_interop`, `math`, `typed_data`, `ui`.
No SDK/package implementation was traversed or executed. Pubspec/lock hashes bind
manifest observations only; generated plugin registration, dependency resolution,
Flutter/Riverpod nested-scope behavior and engine delivery remain NOT_CHECKED.

Native/plugin crossings include secure storage (endpoint and lease protection plus
proposed private sink), shared preferences (contact/selection/theme/pins), speech,
TTS, audio, file selection and URL launch. The graph gives their exact importing
files/lines rather than claiming plugin installation. Custom channel boundaries:
`lib/app/desktop_host_command_listener.dart:21-38`,
`lib/features/enrollment/services/hermes_connect_intent_source.dart:36-64`, and
`lib/features/voice/services/platform/device_speech_recognition_availability.dart:55-67`.
Android `MainActivity.kt:40-79` configures connect-intent, speech and durable-key
channels; none is an M2 metadata-export channel. Runtime method/event handlers,
OS services, dynamic URI destinations and injected callbacks are not Dart import
edges and have not been qualified. No literal dynamic import, FFI DynamicLibrary
or spawned-isolate delivery was found by the bounded source-marker scan; absence
of those markers is not a proof of all external runtime behavior.

`android/app/build.gradle.kts:80-100` supplies the debug `.qa` suffix only with
`WING_ISOLATED_DEVICE_TEST=1`; manifest `:14-24` names MainActivity. These sources
are packaging leads, not an APK/merged manifest/entrypoint proof. Do not build the
existing feature target: `integration_test/support/maestro/feature_channel.dart:11`
imports `test/.../fake_hermes_channel.dart`, and the existing Android feature runner
builds/installs that fixture. Its inclusion of a real app shell cannot establish
production persistence. No existing runner or manifest is changed or authorized here.

## Proposed added edges and private sink feasibility

These three files are absent; there is no compiled proposed closure to measure.
[contract.json](../../.task-evidence/t_bd91fa65/contract.json) binds the proposed
allowlist and refusal rules. A new entrypoint would add these explicit edges:

| Proposed file | Planned imports / boundary |
| --- | --- |
| `integration_test/hermes_m2_observer_main.dart` | `package:wing/app.dart`; channel provider and `HermesApiChannel`; support `m2_observer.dart`; Flutter widgets and Riverpod. Call production `WingApp`, not the feature fixture. |
| `integration_test/support/m2_observer.dart` | Existing `HermesDetachedRunStore`/lease and channel state contracts; `SecureHermesDetachedRunStore`; existing `flutter_secure_storage`; bounded `dart:async`/`convert` metadata serialization. Use existing `uuid` for aliases and `crypto` only for synthetic-result digest. No new dependency. |
| `test/tooling/m2_observer_test.dart` | Support module; `flutter_test`; existing contracts. Local typed fake delegates/count-source/sink belong ONLY to this new test file, never the entrypoint's closure. No feature fake imports. |

The exact proposed URI edges and existing-target envelope are enumerated in
[proposed-edges.json](../../.task-evidence/t_bd91fa65/proposed-edges.json). They are
design declarations, never parsed imports from absent files. The test's added
production-app/provider imports permit a nested-scope identity regression; its
`flutter_test` package is a separate test boundary, not a QA-app dependency.
The entrypoint's proposed local envelope is the current app closure plus the new
entrypoint/support module and their recursively resolved production imports. Its
exact directives, any selected package imports and every future transitive edge
must be recomputed after implementation, not copied from this snapshot as a pass.
The test closure intentionally permits isolated observer fakes; the production/QA
entrypoint closure MUST reject them. No integration-test framework dependency is
needed merely to compose a dedicated `main`; if one is later selected, enumerate
that dev-plugin delivery boundary rather than assuming the feature runner fits.

Use one outer QA `ProviderScope` channel-factory override, or an equivalent inherited
container, around unmodified `WingApp`. The override constructs real
`HermesApiChannel(detachedRunStore: observer(real SecureHermesDetachedRunStore))`,
attaches the observer listener before directory startup and retains `ref.onDispose`.
Leave endpoint, cache, directory, summary-loader, router, intents and transport
providers at production defaults. WingApp's inner ProviderScope has no overrides:
future deterministic composition tests must prove the actual screen/directory and
listener resolve the SAME overridden channel across the nested scope, without a
second eagerly read directory. This is a proposed Riverpod composition, not an
executed inheritance guarantee. Do not expose private `_WingMaterialApp` by editing
production shell or duplicate its implementation.

There is no existing private M2 sink seam. The proposed support module can own a
new typed sink interface and a dedicated QA-only `FlutterSecureStorage` metadata
slot, entirely within the three-file allowlist. Use a fixed M2 namespace plus a
validated random attempt alias, never a caller-supplied path/key or product endpoint /
lease key. Retain only bounded metadata, serialize asynchronous sink commits, cap
both queued and persisted events/UTF-8 bytes, refuse truncation/overflow, and require
readback/flush before exporting any qualification receipt. The existing secure
plugin is an available source-level primitive, NOT an implemented sink or a private
Android durability guarantee. Do not use ordinary prefs, logcat, analytics, clipboard,
public files, developer logs or a network listener as an easier export path.

Observer sink errors must invalidate QA evidence without turning a successful
product store save into a failed save or swallowing a delegated store failure.
Emit a success observation only after delegate returns, record typed failure without
raw exception text, and rethrow the SAME delegated failure to the channel. Loss of
sink records, pending flush or process death before sink acknowledgement means
missing evidence, never a reconstructed success. A local observer read method is
not an external extraction/coordination protocol; safe receipt transfer and installed
identity admission are precise future gaps. No new native method/plugin/export or
runner is authorized to bridge them here.

## Exactly one next implementation brief

Name: **QA-M2-STORE-STATE-OBSERVER** (NOT_IMPLEMENTED; no new card created).
Implement only the three proposed paths above plus that future task's evidence.
Deliver a delegating store observer, typed bounded metadata validator/private sink,
and production-preserving QA composition with deterministic tests. Do not implement
an Android coordinator, counting endpoint, transport proxy, production instrumentation
or owner/lifecycle repair. If the three-file envelope cannot compose safely, record
that precise dependency gap and leave qualification unavailable.

Required observable oracles for the future adapter (not executed by this card):

1. Delayed save: delegate's completer remains pending; no `store_write_ack` or
   lease-removal success appears before completion. Coordination key and lease
   objects are passed through without altered ownership/serialization.
2. Failed write: same delegated error is rethrown, typed failure is recorded, no
   success follows. Load/save/removal sink failures refuse QA evidence without
   changing product persistence semantics. Acknowledgement is delegated-call-only;
   no test labels it Android death durability.
3. Wrong owner/stale generation: missing origin/profile/session/run, foreign tuple,
   switched channel owner, stale process alias or stale observation fence cannot
   satisfy admission. Mixed attempts/generations and sequence duplicates/regression
   fail. Raw tuple mappings stay ephemeral; alias strings are random, max 64 chars.
4. Canonical identity/order before settlement: require witnessed canonical user /
   assistant aliases, no missing/duplicate/reordered IDs and locally matched synthetic
   result before a settlement claim. Tool-context messages are not substituted for
   visible transcript. A later UI match cannot backdate an event. If the current
   public seams cannot witness the internal admission before removal, emit typed
   unavailable evidence and REFUSE this oracle; do not infer it from store success
   or add a private owner callback outside scope. Isolated synthetic event fixtures
   must reject early settlement and prove correct validator ordering only.
5. Strict schema: reject extra fields and arbitrary strings/errors; maximum **128
   events** and **64 KiB** of UTF-8 encoded attempt envelope (including wrappers),
   not per event. Bound queued output, aliases, integers and nested counter keys.
   Reject malformed, out-of-order, duplicated, dropped or overflowed records; do
   not silently sample. Sink readback/flush must be complete and generation-bound.
6. Authoritative counts: until a separately admitted existing unmodified-Agent source
   provides whole-attempt/credential accepted AND rejected counts for all owners /
   transports, continuous epoch, closed intervals and complete mutation coverage,
   emit `authoritative_counts_unavailable` and REFUSE qualification. Unknown/lost /
   reset/denied counts are not zero. Client attempts remain diagnostic only. Fixture
   counters are visibly `fixture`, never authoritative live accepted/rejected totals.
   Count deliberate submissions, run starts, session creation, chat/completions,
   Stop, approval responses and unknown mutations separately; second submission or
   any recovery mutation fails. Do not invent route, grant, server ledger or source.

The strict metadata field proposal is in contract.json. It preserves preflight's
allowlist: schema/version; attempt/target/process and origin/profile/session/run /
message aliases; sequence/monotonic elapsed time; application ID/API/ABI and reviewed
source/APK digests; enumerated phase/status/error; acknowledgement and owner/history /
order/result/notification/PID-generation matched booleans; separated bounded client /
authoritative accepted/rejected/phase-delta counters, epoch alias and coverage boolean;
synthetic-only expected digest. No raw PID/serial, alias mapping, origins, labels,
IDs, paths, body, prompt/output, provider value, credential/auth/cookie/key, storage
blob, speech or arbitrary error may enter output. Never hash sensitive data as a
redaction substitute. Exact enum vocabulary/type constraints belong in the future
validator; the offline contract checker is not that runtime validator.

The single [accepted scenario](2026-10-06-m2-continuity-baseline.md#exactly-one-future-scenario-android-m2-death-complete-01)
still requires one authorized synthetic turn, running plus lease acknowledgement,
confirmed QA PID absence while Agent completes, same-storage new-generation relaunch,
exact canonical recovery then settlement, total submission one and recovery mutation
delta zero. No automatic extra generation/retry or replacement session is permitted.
No user red-line action is requested or performed here.

## Acceptance evidence and exact offline checks

Task-local evidence is sanitized source/schema/command metadata only. No product or
upstream code is imported/executed by these checks; Python loads only task-owned
scanner/checker modules. Proposed entrypoint files must remain absent.

Executed from the repository root (exact exits/results in validation.json):

```text
python .task-evidence/t_bd91fa65/closure.py snapshot
python .task-evidence/t_bd91fa65/closure.py verify
python .task-evidence/t_bd91fa65/snapshot.py
python .task-evidence/t_bd91fa65/check.py
```

The initial scanner attempt exited 1 because it treated later ordinary Dart words
as directives. Restricting directives to the pre-declaration header fixed that
ordinary checker defect; snapshot/verify then exited 0. The acceptance checker also
cross-checks every header directive with an independent anchored-source scan, verifies
exact source lines/symbols/hashes, local links/anchors and receipt schemas, and runs
isolated negative controls for deleted local closure edges, missing target files,
inserted fake dependencies, forbidden metadata fields and weakened counting rules.
These controls are source/contract copies in memory, NOT production mutations.

Scoped whitespace commands executed by the checker:

```text
git diff --check -- docs/quality/2026-10-06-m2-observer-composition.md .task-evidence/t_bd91fa65
git diff --no-index --check /dev/null docs/quality/2026-10-06-m2-observer-composition.md
```

No-index exit 1 with no diagnostics denotes added-file difference; diagnostics fail
acceptance. Scoped tracked check must exit 0. No broad suite was run.

| Acceptance criterion | Delivered mapping / ceiling |
| --- | --- |
| 1. Exact production seams, closure, conditional/part and delivery boundaries | Startup/persistence table, all-alternatives production-closure.json with 185 hashes/775 edges, 34 selected snapshot sources and checked source-line symbols; missing public admission/sink/transfer seams explicitly recorded. Proposed edges separate; no compiled proposed closure. |
| 2. One bounded future brief, strict limits/refusal, honest platform claims | QA-M2-STORE-STATE-OBSERVER only; contract.json plus six oracles and private sink proposal; unavailable authority and pre-settlement observation refuse qualification. Three-file allowlist unchanged. |
| 3. Passing offline checks, discriminating negatives, task-only commit and bookkeeping | Task-local check.py / validation.json; commit-receipt.json records helper commit and exact branch/blob readback; completion-receipt.json reserves shared ledger handoff for existing repo-docs owner. Only this report is committed. Native same-card review is the final card step, not independent approval. |

Original pre-inspection fingerprints match the seven previously present sources in
observer-composition-source.json. Predecessor review451 test/analyzer receipt bytes
are hash-bound and retained without replay; only the overlapping oracle source was
compared, not its whole old compiled closure. They remain deterministic predecessor
evidence, not current runtime qualification.

Repo-docs ownership was refreshed by re-reading the selection receipt and current
M2 ledger state; no release of cron ba15b4ed8db6's shared TODO/goals ownership was
observed. Per the card's concurrency exception, completion-receipt.json records the
local documentation completion and exact checks for its next pass. Do not race
`goals.py task/evidence/render` here. The receipt requests closing only this slice,
preserving M2 unverified and authoritative_counts_unavailable; document-integrity
checks are never M2 platform acceptance. The helper's all-done promotion rule means
repo-docs must retain remaining qualification coverage rather than silently promote
M2. Shared ledgers and profile-local journals were not rewritten by this scoped card.

Separately **NOT_CHECKED**: APK/entrypoint packaging; OS death; keystore/permissions;
live credential/inference/counting; native interaction. Also NOT_CHECKED: plugin
registration, QA storage isolation on a device, sink retrieval and canonical-admission
runtime timing. Retained tester and original scheduled dismissal resources were not
touched. No tests/analyzer/build/browser/device/adb/network/install/storage probing.

Questions: none. Source-only/default fail-closed direction applied; native review
approval and later execution admission remain separate from this delivered report.
