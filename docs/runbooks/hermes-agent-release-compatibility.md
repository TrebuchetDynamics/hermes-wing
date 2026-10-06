# Audit a Hermes Agent release

Use this checklist for every Hermes Agent release Wing intends to qualify. The
Agent version and commit identify the evidence; they never enable a Wing
feature. Wing still requires a supported capability schema plus each exact
advertised method, path, profile context, and scope.

## 1. Pin the candidate

- Record `hermes --version`, the release tag, and the full upstream commit.
- Use a clean, disposable Hermes profile with synthetic sessions and no private
  endpoint URLs, credentials, transcripts, paths, or generated agent state.
- Record the Wing source revision and target platforms.
- Diff the Agent release against the last qualified release across
  `/health`, `/v1/capabilities`, sessions, runs/events, approvals, stop,
  profiles, providers/models, skills/toolsets, jobs, and detailed health.

Classify every delta as **required fix**, **adoption candidate**, or **no Wing
change**. Never infer compatibility from an unchanged release number or route
handler alone.

## 2. Capture the capability fixture

Start the candidate API server on loopback. Keep the bearer value only in an
environment variable and disable shell tracing:

```bash
set +x
export HERMES_API_KEY='<temporary scoped test credential>'
export HERMES_BASE_URL='http://127.0.0.1:8642'
release='vX.Y.Z-release-id'
mkdir -p "test/fixtures/hermes_agent/$release"
curl --fail --silent --show-error \
  -H "Authorization: Bearer $HERMES_API_KEY" \
  "$HERMES_BASE_URL/v1/capabilities" \
  | python3 -m json.tool \
  > "test/fixtures/hermes_agent/$release/capabilities.json"
```

Review the JSON before adding it. It may contain only bounded capability
metadata. Remove hostnames, URLs, tokens, paths, profile labels, and other
operator data if a future schema adds them. Do not alter methods, paths, scopes,
feature values, profile context, or schema version.

Add `metadata.json` beside it with:

```json
{
  "agent_version": "X.Y.Z",
  "agent_release": "release-id",
  "upstream_commit": "full commit",
  "fixture_kind": "live-capture",
  "source": "GET /v1/capabilities",
  "sanitization": [],
  "contains_secrets": false
}
```

The checked-in v0.20.0 fixture is source-derived because no isolated live server
was used for the baseline. A new release is not qualified until its fixture is
a reviewed live capture.

## 3. Run the contract and live probes

The released-fixture test discovers every directory under
`test/fixtures/hermes_agent/`. After adding the fixture, run:

```bash
flutter test test/core/hermes/hermes_api_test.dart \
  --plain-name "released Hermes Agent capability fixtures remain compatible"
```

The fixture-discovery check validates provenance, secret hygiene, a supported
schema, the exact sessions route, and at least one usable chat transport. The
surrounding `hermes_api_test.dart` contract suite separately verifies additive
unknown fields, unsupported schemas, exact methods and paths, profile query
context, declared scopes, and optional-surface degradation. Both checks must
pass; do not describe the positive release fixture
as evidence for a contract shape it does not contain.

Against the disposable live server, verify `/health`, `/v1/capabilities`, and
`/api/sessions` first. Then run the existing browser/live smoke only when its
scoped test credential and provider are explicitly available:

```bash
npm run hermes:live-smoke
flutter build web --release -t lib/main_e2e.dart
npm run web:e2e
```

Do not read Agent files, databases, active-profile state, or CLI output as a
fallback contract.

## 4. Record the result

### Disposable Linux/web qualification in progress

Task `t_38174cb7` has authorization for disposable actual Agent and Wing Link
targets and scoped test mutations. The owner's current model selection is
`gpt-6.1-sol` / `openai-codex`, superseding the earlier local-model choice.
Local inference and its owned management targets were stopped after their
in-flight tests finished. The isolated installed-Agent target is configured for
the chosen model/provider, but native `auth status openai-codex` reports logged
out with no stored Codex credentials. Provision OAuth through supported private
authentication before rerunning generation; never copy auth stores, extract
serving credentials, weaken authentication or purchase API credit. Preserve separate direct
Agent and Wing Link connections and use the supported native gateway launcher,
not the Desktop JSON-RPC `serve` interface, for the existing product channel.

The installed Agent's advertised `GET /v1/skills` returned HTTP 500 in the isolated
target: its API caller passes `include_editorial=True`, while `_find_all_skills`
does not accept that argument. Wing retains an unavailable inventory instead of
inventing an empty successful result. An unmodified official `v2026.9.7` release
was installed separately as a bounded alternate; its same authenticated skills
and toolset reads returned HTTP 200. This is target-specific evidence, not a
version-based feature gate or permission to patch Agent.

Earlier local-model attempts are retained as failures, not qualification:
the 4B model exceeded fixed live-test deadlines and the 0.6B model generated
incorrect exact-request responses. No local-model fallback is authorized now.
The custom local endpoint and measured local-context override were cleared on
the disposable installed-Agent target using supported CLI configuration.
No generated replies qualify live tool approvals or physical voice. Full
results, source/artifact hashes and independent same-card tester/reviewer
acceptance remain required.

The release receipt or issue must include:

- Agent version/tag/commit and Wing revision;
- fixture path and sanitization review;
- required fixes, adoption candidates, and no-change surfaces;
- exact commands and outcomes;
- platforms exercised;
- missing credentials/hardware and unverified surfaces;
- confirmation that no secrets, transcripts, private URLs, or local paths were
  retained.

A failed required bootstrap or chat contract blocks qualification. Failure of
an optional advertised surface blocks only that surface when Wing degrades
safely and the failure is recorded.

## Internal native-web read qualification (not a production connection)

`lib/core/hermes/client/hermes_web_read_client.dart` is a separate, internal
Dart VM loopback qualification transport for the native `hermes serve` web API.
It is not exported by the product API, enrolled, registered with channel selection,
or reachable from UI routing. `productAuthorization` always returns the typed
`unsupportedAuthorization` outcome, even after successful reads. Existing gateway
channel semantics and Wing Link are unchanged. Do not use dashboard authority as
a substitute for advertised operation grants or paired-device revocation.

The implemented reads are explicit-profile REST sessions/history and ticket-only
WebSocket `gateway.ready`, `gateway.ping`, and `session.list` qualification.
RPC list IDs are connection evidence, not another authoritative inventory cache;
the inspected RPC summaries do not return profile identity. REST validates returned
profile/session, numeric message IDs, Unix-second timestamps, and pagination without
sorting server display order. DTOs drop host-path/domain extras. Errors contain only
typed outcomes and optional numeric RPC codes, never raw upstream text.

Limits: 1 MiB per HTTP body and WebSocket message before JSON decoding, eight pending
HTTP requests and eight pending RPC requests, bounded page counts and deadlines,
no redirects/proxies or WebSocket compression, and generation invalidation on replacement or
disconnect. Dart's built-in WebSocket assembles messages before the application
size check; this is not a pre-allocation memory bound against hostile remote peers.
Remote transport/credential acquisition and production activation remain unqualified.

Repeat from the repository root, with the pre-provisioned Flutter 3.44.2 / Dart 3.12.2
toolchain and already resolved locked dependencies (no dependency update):

```bash
env PATH="/opt/data/toolchains/flutter-sdk/bin:$PATH" \
  PUB_CACHE=/opt/data/toolchains/pub-cache TMPDIR=/opt/data/cache/scratch \
  CI=true FLUTTER_SUPPRESS_ANALYTICS=true \
  flutter test --no-pub test/core/hermes/client/hermes_web_read_test.dart \
    test/core/hermes/client/hermes_web_read_adversarial_test.dart
/opt/hermes/.venv/bin/python scripts/qualify_hermes_web_reads.py
```

The non-interactive Python harness constructs fresh scratch HOME/HERMES_HOME and a
minimal environment, starts only its owned unmodified `serve --isolated` child,
generates owned basic auth, and imports one synthetic ended session via the native
API. It passes its ephemeral credential to the actual Dart implementation over
stdin, not argv, URLs, logs or persisted configuration. Cookie extraction is owned
test setup only, never a production credential flow. The harness requires the exact
named Dart assertions, writes a sanitized scratch receipt, checks real ticket
single-use/expiry and access expiry, removes owned auth state, terminates only its
child, and checks listener closure plus the observed gateway PID's start identity.
Recheck `hermes gateway status` before/after; continuity is not a production health
test. If the gateway PID changes, update qualification only after inspecting its
identity; never kill or restart production to make this test pass.

Evidence covers Linux Dart VM loopback only, not Android, browsers, remote TLS/SPKI,
two-profile positive isolation, replay/recovery, send/chat, approvals, tools, admin,
or provider operations. No production enrollment, secure-store migration, backend
selector or read-ready channel is authorized by this test. Same-card tester then
reviewer acceptance is required; executor/live fixture evidence is not final approval.

## Internal native-web lifecycle slice (in progress, not product support)

The explicit `connectLifecycleForQualification()` opt-in reuses the internal
read transport's ticket dial, generation checks and bounded fixed RPC seam.
`HermesWebLifecycle` projects session-scoped events onto existing Wing
`HermesChatTurn`/`HermesToolCall` models; it is not a second session store or a
registered product `HermesChannel`. Product routing, enrollment, gateway transport
and Wing Link remain unchanged. Successful create/resume/history never changes
`productAuthorization` from `unsupportedAuthorization`.

Implemented internal operations are clean `session.create`, explicit durable-ID
`session.resume` with `lazy:true`, canonical `session.history`, `prompt.submit`
acceptance distinct from event completion, exact `session.interrupt`, correlated
`approval.respond` with `all:false` and only `once`/`deny`, and bounded
`session.events.since`. Runtime and stored IDs remain separate. Installed Agent
approvals are server requests (`method: approval`), not legacy approval events;
the adapter advertises `client.capabilities {server_requests:true}`, retains only
correlation IDs and requires `resolved:1`. Other interactive methods receive a
fixed unsupported response, never a synthetic affirmative answer.

Recovery always resumes the durable session and reads canonical history. Replay
validates epoch, sequence, truncation and bounded open requests; history is never
duplicated by appending old deltas. Unknown submissions are not automatically
resent or manufactured as completed. Uncertainty remains explicit and prevents
another submission; there is no production retry UI. Agentless watch recovery of
an already-running turn is conservative: canonical state remains visible, but
this slice does not claim full detached-run or resumed-live-stream continuity.

Reproducible checks with the toolchain actually present in the Oct 1 container
(Flutter 3.47.5 / Dart 3.13.4, not the repository's 3.44.2 qualification target):

```bash
/opt/flutter/bin/flutter test --no-pub \
  test/core/hermes/client/hermes_web_lifecycle_test.dart \
  test/core/hermes/client/hermes_web_read_test.dart \
  test/core/hermes/client/hermes_web_read_adversarial_test.dart
/opt/hermes/.venv/bin/python scripts/qualify_hermes_web_lifecycle.py
```

The lifecycle harness uses generated gated basic-provider auth, literal loopback,
fresh tickets, an empty durable session imported through the supported API, and
clean create drafts. There are no provider credentials, inference submissions,
seeded answers, raw database writes or Agent modifications. Its receipt contains
fixed assertions, source/artifact digests, typed error codes, owned cleanup and
observed gateway start-identity continuity. Generated authentication is passed to
Dart on ephemeral stdin; it is not enrollment or user sign-in evidence.

Native qualification is currently BLOCKED, not passed: installed v0.21.5 /
749220ef accepted clean create, draft/durable resume and canonical empty history,
but both exact interrupt probes returned RPC 5032. The installed interrupt handler
waits for agent initialization even for an idle session; no provider setup or
inference permission was inferred to bypass that boundary. The harness continues
other authorized probes, records interrupt assertions as false and exits nonzero.
Do not substitute deterministic cancellation tests for this unmet native gate.
No production activation, real generated turns, live approvals, Android/browser,
remote TLS, background behavior or independent acceptance is claimed.
