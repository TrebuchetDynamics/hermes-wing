# Diagnostics read and redaction contract

Status: source-bound evidence for `DOC-DIAGNOSTICS-CONTRACT`, goal
`DIAGNOSTICS-RECOVERY`, native task `t_b11c4e9d`. Documentation only;
independent review and coordinator integration remain separate. The goal stays
partial. This receipt does not qualify remote logs, native clipboard, backup,
import, configuration repair or a live Agent.

## Evidence identity

- Admitted Wing source: `712bb78b2f8354681d94e8ad341ce542d0413764`, clean
  detached workspace before generation; no production/test changes.
- Initial `pass_workspace.py` guard returned `worker_start_admitted` before tests
  or edits, using manifest SHA-256
  `f4e4dafa9f36359a40280f44ecf8b8e272f6c3f32d32680d08be4330bf2edaf7`.
  Original command/workspace and finish commit/ref belong to the native card
  tool history and handoff; later reconstruction is not admission proof.
- Read-only official Agent/Desktop checkout:
  `158fd638da1629c8e62caf9ade1515d162def8ab`, clean at inspection. Its root,
  Desktop, renderer, gateway, TUI and web area instructions were consulted.
  The reference is absent from the isolated Wing workspace; inspection used the
  canonical read-only reference, not a copied or modified runtime.
- Execution host: Linux `7.0.0-31-generic`, x86_64; Flutter `3.44.2`, framework
  `c9a6c48423`, engine revision `77e2e94772`, Dart `3.12.2`, Python `3.12.14`.
  Node `v26.7.0` differs from the repository's Node 22 recommendation; no Node
  check/build was run and no toolchain was changed.
- Dependency SHA-256, unchanged before/after acceptance:
  `pubspec.lock` = `f089602c321af4a65d6f1dc70b6adef724079bedc8e4f1d0496f7b8e22641c89`;
  `package-lock.json` = `f32c4b4d226bf6cef1a1f66733d4c2e065e0656d1223e89f17ceb68f42429b63`;
  `pubspec.yaml` = `7986bd3eaa967657f453e08f0522a4254496393699dc9640a7aba7de4cf1a43a`;
  `package.json` = `c5acb3d1eae19f0f20c119745fd3ee5b0677457e01e9b14fcd3d8f1266b4e833`.
- Generated package configuration was initially absent. Offline locked resolution
  succeeded; its workspace-specific SHA-256 is
  `6382cec7c5d10172ea018d26fa9d05aa8a5c98067e9a91d077a93a8c13382c35`.
  This generated file is not an owned deliverable.
- Source/test closure fingerprint: `25154cf71591077d0150906de9ce02029cf86cb83d82e67660d0c62fd7c05a60`
  over 86 tracked paths. Recipe: `git ls-files` for `lib/core/hermes`,
  `lib/shared/security/wing_redaction.dart`, `lib/features/settings/screens`,
  `lib/features/hermes_chat/diagnostics`, `lib/features/hermes_chat/screens`,
  `lib/router`, and the four test targets below (diagnostics directory included);
  SHA-256 each file, then SHA-256 compact JSON of ordered `[path, digest]` pairs.
  Regeneration did not change tracked source/tests or dependency inputs.

## Public entry and shared consumers

[Settings overview](../../lib/features/settings/screens/settings_screen.dart)
(line 269) pushes `/settings/diagnostics`; the
[router](../../lib/router/providers/app_router.dart) (164–169) mounts
`DiagnosticsSettingsScreen`. The
[screen](../../lib/features/settings/screens/settings_diagnostics_screen.dart)
(7–18) watches `hermesChannelProvider` and rebuilds from `channel.state`.
Opening it does not connect, refresh, read files or call a diagnostic API.

Its Copy action (133–151) exports the current widget state through
[`hermesDiagnosticsExport`](../../lib/features/hermes_chat/diagnostics/hermes_diagnostics_export.dart),
then writes text through `Clipboard.setData`. It neither reads the clipboard nor
uploads/saves a file. A pending copy disables duplicate taps; success waits for
completion, failures produce generic localized guidance and permit explicit retry.

The same exporter is used by
[Chat's diagnostic dialog](../../lib/features/hermes_chat/screens/state/hermes_chat_connection.dart)
(509–610), reached by compact More or the wide Diagnostics button in
[`hermes_chat_screen.dart`](../../lib/features/hermes_chat/screens/hermes_chat_screen.dart)
(1729/1792). Chat freezes the export at dialog opening rather than subscribing to
subsequent state. Its second copy action exports only the static **Deferred** raw
log status/exclusions, not logs. Clipboard failure is inline live-region feedback;
mounted/current-route checks suppress completion feedback after dialog exit.
Chat does not have Settings' pending-copy duplicate guard.

Scope reach: these two callers, exporter, shared redactor, channel/client/model and
readiness policies, route/provider wiring, existing fake channel and four focused
test targets. Only this receipt changes; no exports, fixtures, configuration,
localization, dependencies or production callers need edits for documentation.

## Allowed projection and actual bounds

These are current selected fields, not approval to add arbitrary diagnostic data.

| Surface | Selected fields | Bounds and exclusions |
| --- | --- | --- |
| Settings connection | Localized connection enum; first loaded model, else capability model; transport policy label; detailed-health version and gateway state | Blank model and absent health have explicit fallbacks. Model/version/gateway strings are displayed directly, without export redaction or length caps. No base URL, key, raw error or session title is rendered here. |
| Settings inventory/session | Counts of models, skills, enabled toolsets, jobs and loaded sessions; active-session yes/none; localized names of failed optional resources | Failure **keys**, not error values; at most the five `HermesOptionalResource` enum members. Counts are loaded inventory, not all server resources. Zero alone does not distinguish unsupported from empty. |
| Shared export base | Connection enum, loaded-session count, active title (else ID, else none), active-message count | Free-text title/ID goes through redacted preview, default 120 Dart string code units plus possible ellipsis. Message bodies are not traversed/exported, but ordinary session-title content survives. |
| Export health | Status, platform, version/unknown, gateway state/unknown, active-agent count | Four strings use default 120 preview; parser bounds active agents to 0–1,000,000. No basic-health fallback, PID, exit reason, readiness details, platform map or raw response. |
| Export capabilities | Model; auth-required boolean; transport/Stop/approval/session-stream and feature-derived flags; static voice-path text; feature/endpoint names; endpoint method/path descriptions; surface-readiness rows | Names sorted; name/model lists take 12 entries, 80 code units each, then `+N more`. Routes take 12 sorted entries: name 48, method 12, path 96; readiness title 120/detail 240. Ellipsis may add one unit. Values, granted-scope lists and token are not serialized. |
| Export inventory/footer | Model list; skill/toolset/job counts; sorted optional-failure enum names; fixed exclusion statements | No skill bodies, job content, errors, tool arguments/results, transcripts, raw logs, credential storage or endpoint origin field. Footer assertions are intended exclusions, not a proof of arbitrary free-text safety. |

The exporter has field/list bounds, not a total byte-size guard. Redaction processes
an entire input string **before** shortening it; there is no upstream work-budget
bound here. It does not normalize embedded newlines. Settings' directly displayed
model/health strings do not inherit export bounds. The
[health parser](../../lib/core/hermes/models/hermes_health.dart) (30–43) parses the
four health strings without their own text caps. Do not advertise fully bounded,
content-free or private-origin-free display from these tests.

## Redaction boundary

The export's `_safeDiagnosticsText` delegates to
[`wingRedactedPreview`](../../lib/shared/security/wing_redaction.dart) (308–312),
which applies `wingRedactSensitiveText` before truncation. That shared path also
serves channel error/UI sanitization; the exporter excludes error values outright.
Rules cover MEDIA delivery tokens; legacy Wing handoff code fields; tool wrappers;
Authorization/Bearer/Basic, cookie/API-key/auth-token headers; URL userinfo;
file URIs, recognized POSIX-home/root paths, tilde/drive/UNC and quoted paths;
labelled secrets; recognized provider-token/JWT shapes and secret-labelled text.

This is pattern redaction, not semantic removal of all private content. Ordinary
URLs/origins, arbitrary unlabelled secrets and ordinary session-title text are not
universally removed. Endpoint paths describe routes rather than permitting host
file reads. The required fixtures demonstrate particular recognized cases, not
complete credential, private-endpoint or transcript-content noninterference.
Some header/JWT fixtures already contain placeholders and negative assertions
against absent markers; those cases are not strong coverage of the real shape.
Keep the [security decision](../adr/security-and-privacy.md) and
[threat model](../security/threat-model.md) as the acceptance bar, not the footer.

## Agent operation and grants, without invented authority

There is **no remote diagnostic/log read operation or grant for opening/copying
this local projection**. It consumes previously authorized state. No new
`logs:read` grant, shell bridge, config command or direct Agent-file access exists.

For one actual contributing read, trace detailed health:

1. [Connection bootstrap](../../lib/core/hermes/channel/api_channel/hermes_api_channel_connection.dart)
   (52–70) reads basic `/health` and capabilities, then conditionally calls
   `HermesApiClient.healthDetailed` (62–65 in the
   [client](../../lib/core/hermes/client/hermes_api_client.dart)) for
   **GET `/health/detailed`**, advertised name **`health_detailed`**.
2. Bootstrap `_capabilityEndpointAuthorized` (489–501) requires supported schema,
   exact method/path and every declared `required_scopes` allowed by auth. It does
   not check supported profile context. The URI is host-level: `healthDetailed`
   supplies no profile argument.
3. Explicit `loadDetailedHealth` uses
   [`state.canReadDetailedHealth`](../../lib/core/hermes/channel/hermes_channel_state.dart)
   (171–172, 244–255), additionally rejecting unsupported profile-scoped context.
   Denial throws before the read. Absent/denied optional bootstrap skips without
   inventing a resource failure; actual failure records a sanitized error, while
   these diagnostics display/export only the resource name.
4. The official Agent at the pinned reference advertises this exact endpoint in
   `gateway/platforms/api_server.py:78–102`, with no named `required_scopes`
   contract. `_handle_health_detailed:2456–2499` uses Bearer `_require_auth` and
   returns runtime health, not log text. Wing's unscoped-health connection test
   explicitly accepts that contract. Do not claim `gateway:read` is always required:
   it is enforced **if declared**, not fabricated when absent.
5. Export surface-readiness takes a different view:
   [`hermes_surface_readiness.dart`](../../lib/core/hermes/policy/hermes_surface_readiness.dart)
   (63–68) specifically requires advertised/granted `gateway:read`. Thus unscoped
   Agent health can load while the readiness row denies it. Bootstrap/state/
   readiness are not a single identical authorization predicate. Export config,
   memory and some voice flags are feature claims, not verified writable actions;
   the voice-path sentence is static, not current runtime qualification.

Other projected counts come from existing exact reads: models `/v1/models`, skills
`/v1/skills`, toolsets `/v1/toolsets`, jobs `/api/jobs` (`tasks:read` plus all
required scopes). The
[inventory loader](../../lib/core/hermes/channel/api_channel/hermes_api_channel_inventory.dart)
passes selected profile for these; copying performs none of them. The
[API/state ADR](../adr/api-and-state.md) still requires exact operations, all
required grants and current resource context; loaded metadata grants no writes.

Official Desktop is different: `apps/desktop/src/app/contrib/panes.tsx:39–43`
reads 300 agent-log lines every five seconds while its Logs pane is mounted.
`src/api/config.ts:94–128` routes `getLogs` through `profileScoped()` to
**GET `/api/logs`**, with file/lines/level/component/search query fields.
`hermes_cli/web_routers/status.py:819–859` resolves a `LOG_FILES` allowlisted file
in the selected profile, defaults to 100 lines, caps ordinary reads/output to 500,
and searches up to 2,000 candidate lines before trimming. That handler returns
lines without an additional response redaction pass. Server middleware owns auth;
this is not a Wing-advertised diagnostic grant or proof of a safe mobile export.
The nearest `tests/hermes_cli/test_web_logs_async.py` proves yielding during reads,
not redaction. Desktop also has a consented `diagnostics.share_nous` upload
(`src/store/send-diagnostics.ts:81–115`); no upload was invoked or adopted by Wing.
Upstream source/tests were inspected only, not executed or modified.

## Denial, ownership recovery and missing oracles

Connection bootstrap clears state at a new generation (connection source 32–44)
and rejects superseded client/generation completions before publishing (115–118).
Detailed-health refresh has connection and request-generation fences (206–237),
clears health on current failure and ignores old completions. This is shared
channel recovery, not a diagnostic-owned retry or durable log cache.

Settings follows changing channel state, but its clipboard completion checks only
`mounted`, not host/profile/generation or current route. Chat retains an opening
snapshot and guards feedback by route lifetime, not owner identity. Neither
consumer revokes an already-submitted clipboard write on owner change. The four
executed targets contain no host/profile roundtrip or revoked-authority diagnostic
copy oracle. Do not equate dialog-disposal tests with wrong-owner recovery.

Adjacent inspected, **NOT_EXECUTED** coverage:
`test/core/hermes/channel/hermes_api_channel_tests/connection_tests.dart:155–204`
checks denied `gateway:read` causes zero health calls; 384–427 checks unscoped
Bearer health. `lifecycle_race_tests.dart:240–297` checks newest overlapping health
read wins. `test/core/hermes/hermes_surface_readiness_authorization_test.dart`
contains cross-projection scope denial. These leads do not close the missing
clipboard ownership or live authorization scenarios.

## Executed acceptance

Commands ran in the original admitted isolated workspace; all exited 0:

```sh
flutter pub get --offline --enforce-lockfile
git diff --exit-code -- pubspec.lock package-lock.json
timeout 10m flutter analyze --no-pub
timeout 10m flutter test --no-pub --concurrency=1 test/features/settings/settings_diagnostics_screen_test.dart test/features/hermes_chat/diagnostics/hermes_diagnostics_export_test.dart test/features/hermes_chat/diagnostics/hermes_diagnostics_redaction_test.dart test/features/hermes_chat/screens/hermes_chat_diagnostics_clipboard_test.dart
git diff --check
```

- Analyze: no issues, reported 6.9 seconds on the initial run.
- Focused union: **65 tests passed**, runner elapsed about 10 seconds.
  [Settings tests](../../test/features/settings/settings_diagnostics_screen_test.dart)
  cover 390px light/dark, 100/200% text, reachability/inset, empty-model fallback,
  exclusion of raw error values, copy, duplicate guard and failure notice.
  [Export tests](../../test/features/hermes_chat/diagnostics/hermes_diagnostics_export_test.dart)
  and [redaction tests](../../test/features/hermes_chat/diagnostics/hermes_diagnostics_redaction_test.dart)
  cover deterministic failure-name order, recognized patterns, redaction before
  truncation, model/title/health paths and fixed exclusions.
  [Chat clipboard tests](../../test/features/hermes_chat/screens/hermes_chat_diagnostics_clipboard_test.dart)
  exercise 390/1280px, both actions, pending success/failure, explicit retry,
  exit-animation/dialog/UI disposal, generic accessible failure and no listed
  channel mutations. System clipboard is mocked.
- Local Markdown targets/anchors checked by a standard-library validator;
  `git diff --check` passed. Finish gate reruns required analysis/test/link/hash/
  whitespace checks and records their exact argv/results on the native card.
- No production change, new regression logic or additional dependency. Measured
  review duration, inference usage and cost are unknown, not estimated.

Ponytail full applied directly to this documentation-only change: reuse existing
screen/export/redactor/tests; omit a log reader, new grants/APIs, abstraction,
backup/import implementation and extra review lane. Checks above establish the
bounded fixture behavior only. No material code-method skill was needed.

## Remaining milestone and coordinator proposal

Smallest remaining implementation proposal (not executed here): unify the existing
Settings/Chat diagnostic field projection with the shared redacted preview, remove
unneeded free-form active title/ID from a privacy-safe export, and bind copy
intent/feedback to current owner. Add one focused adversarial fixture proving
private-origin/content exclusion and host/profile roundtrip invalidation; retain
clipboard failure recovery. Resolve health/readiness grant/context drift in its
shared policy with a scoped/unscoped denial regression, not a fabricated grant.
These are outside this evidence-only card; return for coordinator deduplication,
not an upstream patch or new task dispatched by this worker.

Smallest named-platform qualification scenario, **NOT_CHECKED**: after that
privacy/ownership slice, Linux native Wing with a disposable, unmodified Agent;
open Settings and Chat diagnostics on owner A, copy/read back only synthetic
metadata, exercise clipboard denial/explicit retry and A→B ownership change,
confirm no A identifiers/errors in B feedback/export and no log/config/mutation
requests. Verify denied detailed-health read makes zero calls and unscoped Bearer
health is reported consistently with its real capability document. Record exact
Wing/Agent revisions and platform clipboard evidence; no inference is necessary.
Android, macOS, Windows, browser E2E, screen readers and live credential/provider
qualification are also **NOT_CHECKED**.

`DOC-DIAGNOSTICS-BACKUP-CONTRACT` remains a separate next evidence slice only after
coordinator closure of this card. Atomic backup/import and repairs stay gated;
this receipt neither implements them nor closes `DIAGNOSTICS-RECOVERY`. Required
independent same-card review precedes ledger closure/integration. No canonical
ledger edits, push, PR, deployment, installs or live targets were performed.
