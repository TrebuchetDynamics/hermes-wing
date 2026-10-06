# Offline Wing Link discovery contract conformance

Date: 2026-10-06. Native task: `t_f2b5c61e`. Backlog slice:
`DOC-API-CONFORMANCE`; goal `API-CONFORMANCE` remains **unverified**.
Implementation/test acceptance: passed. Independent native same-card review is
separate from this execution receipt; this document does not approve closure.

## Delivered change

The [code-first snapshot](../api/wing-link.openapi.yaml) now has executed,
source-bound conformance evidence for exactly **GET /meta** and **GET /healthz**.
No production handlers, upstream repositories, shared tests, project dependencies,
Agent state, live servers or personal runtime state were changed or accessed.

One demonstrated schema underconstraint was reconciled: metadata's
`supported_protocol_generations` previously accepted any integer array, including
`[99]`, while `CurrentMetadata` always returns `[1, 2]`. The schema now requires
that exact ordered array. The checker proves the original copied constraint
accepts `[99]` and the corrected constraint rejects it. This is a documentation
constraint fix, not a runtime protocol change. Discovery and shared protocol-header
descriptions now document initialization precedence, exact dispatch limits and
accepted integer spellings. Other operations and their schemas are unchanged.

## Reproduction and artifacts

From the repository root, using the already-installed Go 1.26.1, Python 3 with
`jsonschema`, and Ruby Psych 5.0.1:

```sh
python3 .task-evidence/t_f2b5c61e/check_discovery.py
```

Executed exit: **0**. No tooling was installed. `GOPROXY=off`, `GOSUMDB=off`, and
`GOTOOLCHAIN=local` disable Go network resolution and automatic toolchain download.

- [Checker](../../.task-evidence/t_f2b5c61e/check_discovery.py): complete YAML
  parsing, reference checks, schema checks, Go recorder execution and falsification.
- [Go probe](../../.task-evidence/t_f2b5c61e/discovery_probe_test.go): task-owned
  test file injected with Go `-overlay`; never copied into shared package source.
- [Actual recorder fixtures](../../.task-evidence/t_f2b5c61e/fixtures.json): 62
  responses plus rune-bound metadata; synthetic public fingerprint only.
- [Validation receipt](../../.task-evidence/t_f2b5c61e/validation.json): exact
  subprocess commands, exits/output, nine negative checks, and 20 SHA-256 source
  fingerprints. Local command paths are replaced by `<repo>`. Fixture contents
  contain no generated credentials, pairing proofs, private endpoints or paths.

The checker creates then removes an overlay map at the evidence directory. Its
second Go command is reproducible through that checker, not a command relying on
an abandoned machine-local overlay file:

```sh
GOPROXY=off GOSUMDB=off GOTOOLCHAIN=local go test ./internal/protocol ./internal/app -run 'TestMetadata|TestProtocolGenerationSupport|TestProtocolMetadataAndNMinusOneNegotiation|TestServerFailsClosedWhenAuditLogIsUnsafe' -count=1 -v
WING_DISCOVERY_FIXTURES=<repo>/.task-evidence/t_f2b5c61e/fixtures.json GOPROXY=off GOSUMDB=off GOTOOLCHAIN=local go test -overlay <repo>/.task-evidence/t_f2b5c61e/overlay.json ./internal/app -run '^TestOfflineDiscoveryConformanceProbe$' -count=1 -v
```

Both execute from `wing_link/`; both exited **0**. Existing tests cover metadata
serialization, current/previous generations, sorted allowlisted capabilities,
optional directory availability, negotiation and unsafe audit initialization.
The additional probe exercises the missing schema-to-response and boundary checks
without any `httptest.NewServer` or socket. `gofmt` was applied to the probe.
Shared Go test files are unchanged; this is a docs/task-owned-checker slice, so the
unrelated full Go suite (which includes network listeners) was not run.

## Acceptance evidence

1. **Full document and references:** Ruby Psych `safe_load` parsed the entire YAML
   document; AST traversal rejects duplicate mapping keys. All 496 local `$ref`
   occurrences (42 unique targets) resolved. Every `x-code-reference` path exists
   within the repository. Missing references and missing source paths fail;
   replacing Metadata with the existing but incorrect Status target also fails.
   Component schemas passed Draft 2020-12 metaschema checks. Discovery response
   instances and documented header values passed JSON Schema validation.

   **Coverage limit:** a full OpenAPI 3.1 standards validator is not installed.
   OpenAPI standards validation is **NOT_CHECKED**; YAML parsing, pointer resolution
   and JSON Schema validation are not a substitute. Reference existence for other
   families is structural coverage only, not behavior qualification.

2. **Discovery contract:** the recorder probe binds to unchanged
   `ServeHTTP` in [serve.go](../../wing_link/internal/app/serve.go) (430–485),
   negotiation parsing (765–772), constructor fallback (399–414), JSON encoding
   (1493–1497), and [CurrentMetadata](../../wing_link/internal/protocol/metadata.go)
   (24–62). The fixture outputs are validated against the referenced response
   schemas in the snapshot, not recreated expected JSON.

   - Initialized GET `/meta` bypasses negotiation even for `0`, `3`, `x`, `1.0`
     and integer overflow. Both discovery operations are unauthenticated.
   - GET `/healthz` selects previous generation 1 for missing, empty or
     whitespace-only headers; accepts explicit 1/2, whitespace-surrounded `2`,
     `+2`, and `02`; rejects unsupported/malformed/overflow values with 426.
   - JSON responses send `Content-Type: application/json`; all checked responses
     send `Cache-Control: no-store` and `Wing-Protocol: 2`, including 404/426/503.
   - Metadata fields, exact generation list, required fields and string bounds
     conform. Unicode inputs demonstrate truncation at 64 version runes and 96
     fingerprint runes. Unknown/duplicate optional capabilities are excluded and
     output remains sorted; existing nearest tests cover directory capabilities.
   - Health is exactly `status: ok`, `protocol_version: 2`, with no extra fields.
     This is process liveness, not Agent/provider readiness.
   - HEAD/POST/OPTIONS on the exact discovery paths, and GET with a trailing
     slash, produce empty 404 with supported protocol. Invalid protocol preempts
     non-GET dispatch with 426. That is not a GET `/meta` 426 response: the
     checker validates its shared negotiation body against UpgradeError while
     retaining the metadata operation's documented default-response headers.
   - Disposable unsafe audit, approval and local-proof fixtures each replace
     both routes with typed 503 `host_state_unavailable`, including malformed
     protocol and non-GET requests. Initialization failure precedes both
     metadata bypass and negotiation. No fixture secrets leave the disposable
     constructor state. Successful HTTP dispatch uses deterministic minimal
     in-process server state; constructor behavior is checked separately.

3. **Discrimination, provenance and handoff:** nine isolated negative copies
   reject missing/wrong references, missing code paths, wrong health generation,
   wrong response protocol header, oversized Unicode strings, unsupported metadata
   generation lists, and extra health fields. Authoritative source is never
   mutated for falsification. The corrected spec, checker, probe and cited owned
   source files are fingerprinted in `validation.json` (checkout base `4acdb4e1`,
   dirty-source fingerprints govern). A first checker run exposed a checker-only
   assumption that non-GET `/meta` 426 was a GET response; that was corrected to
   distinguish shared pre-dispatch errors before the final passing run. No product
   assertion was relaxed. Task-owned whitespace and local link/hash checks are
   recorded in `final-checks.json`.

## Reserved shared-ledger handoff

The current selection receipt reserves TODO/goals writes to the repo-docs lane.
The worker re-read `TODO.md` and `goals.json` for this slice and preserves that
reservation rather than interpreting an absent on-disk lock as permission.
Neither shared ledger is edited. Repo-docs should use its supported `goals.py`
helper to mark only `DOC-API-CONFORMANCE` done after accepting this source-bound
receipt. Record executed scoped evidence pointing to the checker command and this
report, but keep `API-CONFORMANCE` unverified: complete owned-API conformance is
not proved by a discovery-family pass. Do not promote global goal status from
these scoped passing fixtures. Native review remains the sole final approval.

## NOT_CHECKED

Other management families, full OpenAPI standards compliance, TLS/pinning/native
transport, live server behavior, Agent/provider readiness, Flutter/browser flows,
packaged runtime/dependency delivery, installation, builds, release, deployment,
and global API conformance. This source-run checker depends on existing Python
`jsonschema`, Ruby Psych and Go; it is not a shipped runtime component.

Questions: none. Defaults applied: offline discovery only, task-owned overlay
instead of shared test edits, reserved-ledger handoff, no live service or tooling
installation.
