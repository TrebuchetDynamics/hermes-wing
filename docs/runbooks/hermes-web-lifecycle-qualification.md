# Internal native-web lifecycle qualification — partial, blocked

Card: `t_43937159`. Executor implementation evidence only; no independent
acceptance, production activation or sign-in qualification. The required native
interrupt gate is unmet. This is not a diagnostic-only completion or a supported
product migration.

## Implemented artifact

- Explicit internal `connectLifecycleForQualification()` opt-in on the existing
  loopback ticket transport, with fixed lifecycle RPCs and shared Wing turn/tool
  models. No product backend/channel registration, enrollment route, Wing Link
  changes, gateway changes, generic RPC API or second session store.
- Explicit profile on session operations, separate runtime and durable IDs,
  canonical history, acceptance separate from completion, bounded session events,
  exact interruption, correlated approval responses (`once`/`deny`, `all:false`,
  authoritative `resolved:1`), and source-supported server-request approvals.
- Fresh ticket per dial; recovery binds origin/profile/runtime/epoch/cursor,
  re-reads canonical history and validates bounded replay/open requests. Unknown
  submissions are never automatically replayed or manufactured as completed.
  Uncertainty remains visible and submission-disabled. Running watch recovery is
  conservative; full resumed live streaming is not qualified.
- `productAuthorization` remains `unsupportedAuthorization`, including after
  successful native lifecycle reads. Structural import/export regression guards
  preserve the absence of product routing.

Changed artifacts:

- `lib/core/hermes/client/hermes_web_read_client.dart` (existing accepted internal artifact)
- `lib/core/hermes/client/hermes_web_read_rpc.dart` (existing accepted internal artifact)
- `lib/core/hermes/client/hermes_web_lifecycle.dart` (new)
- `test/core/hermes/client/hermes_web_read_test.dart` (internal-file allowlist only)
- `test/core/hermes/client/hermes_web_lifecycle_test.dart` (new)
- `scripts/qualify_hermes_web_lifecycle.dart` and `.py` (new)
- `docs/runbooks/hermes-agent-release-compatibility.md` (append-only new section)
- this report

## Exact source trace

Installed, unmodified native identity: Hermes Agent v0.21.5 (2026.9.24),
CLI-reported upstream `749220ef`. This is not attributed to the reference clone's
revision or the researcher-fetched source pin. Installed sources are read-only.

- `tui_gateway/methods_session.py:334–428`: clean create returns runtime and stored
  IDs, does not persist an empty draft, schedules agent construction.
- `methods_session.py:629–652,767–809,915–946`: live draft and `lazy:true` durable
  watch resume; lazy branch avoids generic crash auto-continuation.
- `methods_session.py:1813–1827`: canonical runtime history projection, numeric
  `row_id` when persisted. Count is not assumed equal to projected row count.
- `methods_session.py:2124–2152`: exact interrupt resolves nowait, then calls
  `_sess` in its inline path, waiting for an agent even for an idle session.
- `server.py:885–889,1169–1171`: waiting/build failure is numeric RPC `5032`.
- `methods_prompt.py:564–700,1209–1253`: submit acceptance statuses and exact queue
  request correlation, authoritative approval resolution count.
- `server.py:765–798`, `server_requests.py:9–28`: installed approvals are
  server-to-client requests with `srq-*` IDs plus queue request IDs; advertised
  server-request support and `request.cancel` withdrawal.
- `event_replay.py:21–121`, `methods_session.py:2324–2338`: process epoch,
  per-runtime sequence, finite replay ring, truncation and open requests.
- `contracts/events.py:107–205,258–291`: message/reasoning/tool event payloads.
  The inspected installed tool lifecycle emits `tool.start`/`tool.complete`, not
  an invented generic `tool.progress` operation.

Nearest read-only reference tests: `tests/tui_gateway/test_protocol.py:601–684,
725–776,971–1024`, `tests/test_tui_gateway_event_replay.py:31–110,138–154`, and
`tests/test_tui_gateway_server.py:95–138`. Their approval contracts predate the
installed server-request shape, and their create agent construction is mocked.
These upstream tests were inspected, not executed or modified.

## Verification actually executed

Target: Linux Dart VM literal loopback. Flutter widget test runner is used only
for deterministic transport/model regressions, not UI/platform qualification.
Actual tools: `/opt/flutter`, Flutter 3.47.5 / Dart 3.13.4 linux_x64. No claim of
qualification with repository-target Flutter 3.44.2.

1. Initial `flutter test --no-pub` failed to compile because the existing package
   map pointed at absent `/opt/data/toolchains` roots. `flutter pub get --offline`
   failed because packages were absent from cache. `/opt/flutter/bin/flutter pub
   get` then succeeded using ordinary package download, resolving seven SDK-pinned
   dependency differences. Its automatic tracked changes to `pubspec.lock` and
   `analysis_options.yaml` were precisely reversed; `git diff` confirms neither
   remains changed. Ignored package metadata now references the actual SDK/cache.
   No global tool replacement or runtime provider configuration was performed.
2. Format changed Dart files with `/opt/flutter/bin/dart format` — passed.
3. `/opt/flutter/bin/flutter test --no-pub --concurrency=1
   test/core/hermes/client/hermes_web_lifecycle_test.dart
   test/core/hermes/client/hermes_web_read_test.dart
   test/core/hermes/client/hermes_web_read_adversarial_test.dart` — exit 0,
   49 tests passed, including 12 new lifecycle tests. These cover accepted →
   streamed → canonical replacement, wrong profile/session, duplicate frames,
   correlated least-privilege approvals, cancellation/completion races, delayed
   acceptance, unknown-submission no-replay, fresh-ticket reconnect, epoch and
   truncation fallback, pending selection invalidation, gaps, cross-origin/profile
   checkpoint rejection and correlated replayed open requests.
4. `/opt/flutter/bin/flutter analyze --no-pub
   lib/core/hermes/client/hermes_web_read_client.dart
   lib/core/hermes/client/hermes_web_read_rpc.dart
   lib/core/hermes/client/hermes_web_lifecycle.dart
   test/core/hermes/client/hermes_web_lifecycle_test.dart
   scripts/qualify_hermes_web_lifecycle.dart` — exit 0, no issues.
5. `/opt/hermes/.venv/bin/python scripts/qualify_hermes_web_lifecycle.py` — exit 1,
   intentionally FAILED native acceptance, not a passing qualification. It executes
   the actual Dart adapter, not Python RPC substitutes. Final receipt:
   `/opt/data/profiles/executor/cache/scratch/wing-native-lifecycle-z45brb5j/receipt.json`.
6. `git diff --check` — exit 0. No staging, commits, push, product activation,
   production restart, Agent edits or unrelated tracked changes.

## Native boundary and blocker

Passed native assertions: clean create with distinct runtime/stored IDs and empty
history; fresh-ticket reconnect and live draft resume; durable agentless resume
and canonical empty history; durable reconnect with unsupported product authority;
missing-profile create/resume rejection `4064`; anonymous and wrong-auth lifecycle
ticket rejection. The durable fixture was EMPTY and imported through the supported
native API. It was not a seeded answer or generation evidence.

Both clean-draft and durable idle `session.interrupt` returned RPC `5032`.
The initial 10-second attempt timed out; the 30-second attempt returned the typed
initialization failure, reproduced in subsequent owned runs. The final harness
continues other authorized probes, records both interrupt assertions false and
exits nonzero. Raw server error text is neither propagated nor retained; `5032`
can mean initialization pending or failed, so no narrower raw-error diagnosis is
claimed. No configured provider, personal credentials, prompt/inference call,
synthetic Agent replacement or authorization broadening was added to force a pass.

The implementation cannot proceed to required same-card tester/reviewer acceptance
while this native gate remains unmet. The smallest unblock is a supported
unmodified no-provider interrupt path, or a narrowly specified and explicitly
approved provider-initialization-only qualification target with its network policy.
Inference, billing and production authority remain separately unapproved; no
upstream-edit exception or credential request is implied.

## Sanitization, isolation and cleanup

The harness constructs fresh owner-only HOME/HERMES_HOME and minimal environment,
uses generated native gated basic-provider login, and sends ephemeral auth only on
Dart stdin. No reusable credentials enter URLs, argv, receipts or ordinary logs.
No inherited auth/config/MCP or crash-marker state is read. Child cwd is an empty
owned scratch directory; stdout/stderr are discarded. Empty durable fixture import
is through an Agent API, not a raw store write. No Agent code is modified.

Final owned native process exited `-15`; its listener was verified closed and its
owned home removed. Gateway PID 233 start identity was `161424466` both before and
after. This proves observed process continuity, not production health.

Final artifact SHA-256 values:

- lifecycle adapter: `f40ab9494c64d42eb6e97406c3572c70e5cee00d3f6f9ce4ffd3ffb29f3958f2`
- Dart harness: `06ccc37f7a0b417b43968e0cf6454c5a808db3c3dafd9f6f8d54965290c2e539`
- Python harness: `ed26e1bdd662e3c38d88118c538b90ce9f14346088afb660f31f76150d713225`
- final receipt: `2a9a50a5c9f214957206c3b5537f526067bf9dd9707608a11ad977d6eaed69a2`

Installed source SHA-256 values from the final receipt:

- `methods_session.py`: `6510098165745c41f92a53cbe35ec7bbf8cbbf6623ffc535f46e960b5a320623`
- `methods_prompt.py`: `c3b31b794542410fa39fd27b0433b5d9b7e1ca04a6c33fc2781378f87213b507`
- `server.py`: `a5cd171679d2361f895a290e3c938d8adf764b652a2b8196831f206bb382a145`
- `event_replay.py`: `79462cc7d5a80e2f2e516327d2637d4c8c836542f9fe86e03fec8d3308e63ec7`
- `server_requests.py`: `a3a58ed22cba8b9228d2b35eabb46e6bdc90b09630277ccc102cad9ad4c464fa`

CLI attachment was attempted on this own card with the documented command and
refused by the runtime: `delegate_task child contexts cannot mutate Kanban tasks
via the CLI`. No attachment success is claimed. Report/harness files remain in the
repository; the exact receipt path and checksum are supplied for inspection.

## Acceptance comparison

1. Internal bounded opt-in implementation and structural product exclusion have
   focused passing evidence. Shared Wing turn models are reused; production
   `HermesChannel` composition is deliberately untouched.
2. Submit/event/tool/completion/history/approval/interrupt behavior has deterministic
   passing coverage. Native interruption success is NOT proven. Unknown interactive
   methods are explicitly unsupported, not simulated.
3. Recovery/no-replay regressions pass. Canonical recovery is conservative; running
   watch-stream continuation and positive two-profile native isolation are not
   qualified. Missing-profile rejection is demonstrated, not upgraded to those claims.
4. Required native no-inference interruption gate FAILS `5032`; native clean create,
   resume/history/reconnect/auth/profile negatives succeed. No live generation,
   tool or approval claim.
5. Reproducible checked-in harness, sanitized receipt/report, actual identities,
   scoped analysis/tests/format and cleanup evidence produced. Artifact attachment
   capability was refused. Required same-card independent review has NOT started
   because native acceptance remains unmet.
