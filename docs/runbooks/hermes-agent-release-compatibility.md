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
