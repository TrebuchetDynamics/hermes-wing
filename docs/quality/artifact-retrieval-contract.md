# Bounded artifact retrieval contract

Status: source evidence for `DOC-ARTIFACT-CONTRACT`, goal **ARTIFACTS**.
Documentation only; no operation enabled or invoked. Start with the verdict below,
then the authoritative trace. This receipt does not close ARTIFACTS or qualify
native, browser, device, live Agent, download persistence or hostile-content safety.

## Verdict and evidence identity

One exact candidate exists: **`artifact_download`, GET
`/v1/artifacts/download/{artifact_id}`**, owned by Agent's browser-control transport.
It is **not** a general session artifact/file retrieval API. Wing has no caller for
it. It consumes a one-shot artifact even though the HTTP verb is GET. Keep this
operation unavailable in Wing: the inspected contract lacks session/run ownership,
a Wing-supported explicit profile declaration and an inert preview contract.
Do not describe the operation as absent upstream, or inline media/local transcript
export as its implementation.

Inspected read-only references, each pinned with `git rev-parse HEAD`:

| Reference | Revision | Inspection boundary |
| --- | --- | --- |
| Wing task baseline | `c95540b92b93bdd0ffa3a1204cf6d03be3703155` | Clean `autowork/DOC-ARTIFACT-CONTRACT` worktree before this receipt; source/tests unchanged. |
| Hermes Agent | `158fd638da1629c8e62caf9ade1515d162def8ab` | Canonical read-only `hermes-agent/` reference, clean at inspection; absent from this isolated worktree. |
| Official Desktop (`hermes-agent/apps/desktop/`) | `158fd638da1629c8e62caf9ade1515d162def8ab` | Same repository/revision, not a second independent backend or runtime result. |

The coordinator assigned this one task/worktree. The current TODO index names this
slice and its dependent inert-preview evidence slice; the continuation ledger has
no `DOC-ARTIFACT-CONTRACT` claim. No other lease was adopted/released, and no tracker
completion is asserted. The only new deliverable is this page under `docs/quality/`.

Authority: [API/state](../adr/api-and-state.md),
[security/privacy](../adr/security-and-privacy.md),
[immutable runtime](../adr/runtime-and-delivery.md#hard-boundary-never-modify-hermes-agent)
and [threat model](../security/threat-model.md). The
[parity row](../product/hermes-desktop-parity.md#statuses) is a gap index, not API
or directory authority. Historical management-plane wording there does not override
these living decisions.

## Exact authoritative trace

Line ranges below refer to the pinned Agent source, not an installed/live server.

1. **Advertisement and registration.** [api_server.py][api]:78–102 declares the
   endpoint; 1756–1760 registers it; 2535–2580 returns it in `/v1/capabilities`.
   `features.browser_extension_control` also reports `enabled`, protocol version,
   artifact capabilities, download method/path, `max_bytes`, TTL and MIME list.
   The route is advertised even while disabled. Endpoint rows contain method/path,
   not `required_scopes`, `profile_scoped`, or a session ownership model. Neither
   a broad feature claim nor route presence admits an action.
2. **Profile and authentication.** [api_server.py][api]:1562–1612 resolves the
   expected Bearer key from the selected profile (named profiles fail closed on a
   missing usable scoped key) and compares it in constant time. The `/p/<profile>/`
   middleware at 1674–1743 rejects unserved prefixes and binds profile context.
   Artifact prelude 2858–2877 additionally requires a configured adapter API key,
   validates Bearer auth, derives the principal and applies the rate limiter.
   No `artifacts:read` or directory grant is declared/checked here; do not invent one
   or infer anonymous access from an absent grant list.
3. **Identity.** [api_server.py][api]:2742–2770 checks the live browser-control flag,
   derives principal from profile plus expected key, and classifies the actual peer
   as `local-api` or `remote-api`. Per-profile store resolution is at 2779–2839.
   [browser_control_artifacts.py][store]:89–105 hashes **principal + transport
   family**, deliberately excluding session ID and capabilities. Profile separation
   comes from the selected store and principal, not from session authorization.
   The ID is server-minted 32-character lowercase hex, never a filename or host path
   (159–198, 274–284). Key rotation changes the derived principal. This is not a
   device-specific, run-specific, or profile-incarnation receipt.
4. **Download.** [api_server.py][api]:2923–2950 first denies disabled control (404),
   then authenticates/rate-limits and calls `ArtifactStore.load` off the event loop.
   Success returns raw bytes, stored Content-Type, `X-Artifact-Sha256`,
   `X-Artifact-Id`, and attachment Content-Disposition. Store load at
   [browser_control_artifacts.py][store]:204–227 validates ID, scope and TTL, reads
   the file, verifies SHA-256, drops its in-memory index entry under lock and then
   best-effort unlinks it. A second successful load is impossible for that entry.
   Consumption precedes response delivery: timeout/disconnect is **unknown delivery**,
   not permission to retry, reconnect-fetch or claim a saved artifact.
5. **Denials/lifetime.** Unknown/consumed is 404, expired is 410, invalid ID or scope
   mismatch is 400, missing configured key is 403, bad Bearer is 401 and exhausted
   rate budget is 429. The handler maps checksum/read errors to 404; status alone
   cannot prove deletion. Default TTL is 300 seconds; the index is memory-only,
   and a fresh store sweeps prior-process orphans (store:114–150, 245–272).
   No durable retry receipt, Range/resume or delivery acknowledgment is provided by
   this handler. Default budget is 30 requests/60 seconds **per action + principal**,
   not a global byte/storage quota (api:2841–2845, 2873; store:298–322).

### MIME, size and content: supported versus unavailable

| Boundary | Source-supported guarantee | Not established / admission consequence |
| --- | --- | --- |
| Upload provenance (inspected only to explain download bounds) | API 2879–2921 rejects empty bodies, asks for at most cap+1 bytes, rejects oversize, then calls store. Store 159–198 limits accepted bytes to default **10 MiB**, records size/hash and writes temp + rename. | No upload/request implementation belongs to this task. No total store quota, decompression budget or guaranteed complete streaming-body receipt follows from these checks. |
| MIME | Store 24–30 allows `application/json`, `application/pdf`, `image/gif`, `image/jpeg`, `image/png`, `image/webp`, `text/plain`. Actual normalization at 287–290 strips parameters, trims and lowercases before membership. | Contrary to its allowlist comment, parameterized variants are not rejected solely for parameters. No byte-signature, UTF-8, JSON/PDF structure, image dimensions/frame or executable-content validation occurs in this store. MIME is metadata, not a safe-rendering verdict. |
| Download bounds/integrity | Successful load must match the recorded SHA-256 of an accepted upload; receipt includes size, MIME, hash, creation/expiry, `one_shot` and optional relative download path (store:66–86). | Load uses whole-file `read_bytes()` before hash comparison, with no independent pre-read cap. Thus accepted upload size is not a download work-budget guarantee under on-disk alteration. SHA proves byte consistency, not trusted authorship, secret-free content or harmlessness. No malware/redaction pass or inert preview is supplied. |
| Filename/path | Store 292–295 replaces slash/backslash, removes characters below U+0020 and caps display filename to 160 Python characters; filename is not used for storage paths. | Do not treat the display name or Content-Disposition as a client destination, safe extension, opaque resource identity or permission to launch an app. |
| Authorization/context | Feature enablement, configured key, expected-profile Bearer, principal/family and opaque ID checks apply. | No exact session/run relation, current Wing owner fence, separately revocable artifact grant or advertised Wing query-profile contract. A folder chooser/grant, profile listing, transcript link or `MEDIA:` token supplies none of these. |

## Official Desktop is a different artifact surface

The official renderer's [registry][desktop-registry]:270–357 registers supplied
content under `(session, slug)` with versions, opens a referenced preview only on
user action and does not use the browser-control hex IDs for that flow.
[preview-artifact.tsx][desktop-preview]:17–104 handles code/HTML/SVG; HTML uses
`srcDoc` in a sandbox with **`allow-scripts`**, SVG uses DOMPurify, and the explicit
Open-in-browser helper writes HTML through a Desktop bridge. Its
[nearest tests][desktop-tests]:33–64 check the scripts-only sandbox attribute,
SVG script removal and source-only code mode. They do **not** establish inert HTML
or no-network rendering. This source slice is product reference evidence, not
permission to port active HTML, Electron filesystem access or the bridge to Wing.

## Wing caller closure and current media/export boundary

No `artifact_download`, `artifact_transport`, browser-control artifact method or
`/v1/artifacts/` caller exists in inspected `lib/core/hermes/` or
`lib/features/hermes_chat/`. The generic
[capability decoder](../../lib/core/hermes/models/hermes_capabilities.dart):15–82
can retain arbitrary endpoint metadata; that is not an artifact action gate.
[Profile context decoding](../../lib/core/hermes/models/hermes_capabilities.dart):85–127
supports declared required query `profile`, not an inferred `/p/` adaptation. Do
not graft an artifact operation onto the existing generic client or directory seam.

Current adjacent outcomes, not a retrieved-artifact implementation:

- [Timeline](../../lib/features/hermes_chat/presentation/hermes_chat_timeline.dart):684–810
  renders supported text/attachment labels and an undelivered notice for recognized
  host-file/audio/`MEDIA:` references, not a host-file download control.
- [Rich text](../../lib/features/hermes_chat/presentation/hermes_rich_text.dart):282–347
  accepts inline **data:** PNG/JPEG/GIF/WebP only: URI text at most 7 MiB code units,
  decoded bytes nonempty and at most 5 MiB, matching format metadata; remote/file
  image URIs fall back to a text label. The
  [metadata policy](../../lib/features/hermes_chat/presentation/inline_transcript_image_safety.dart):3–38
  bounds each dimension to 8192, pixels to 16 Mi, frames to 60, animation pixels to
  64 Mi, aggregate render budget to 32 Mi pixels per `HermesRichText` build and decode
  dimensions to 2048. This is not an entire-session aggregate or a complete codec
  safety proof. It is a different, already-loaded media path, with no artifact GET.
- [Export model](../../lib/features/hermes_chat/export/hermes_transcript_export.dart):11–45
  creates local UTF-8 `.txt`/`.md` snapshots with generic filenames, a 4 MiB byte cap
  and no truncation. [Chat caller](../../lib/features/hermes_chat/screens/hermes_chat_screen.dart):1323–1470
  snapshots loaded turns on explicit action, pre-bounds serialization work and
  checks channel/origin/profile/session/generation ownership. The
  [browser saver](../../lib/features/hermes_chat/export/hermes_transcript_export_web.dart):14–39
  creates a local Blob download request; the
  [Linux saver](../../lib/features/hermes_chat/export/hermes_transcript_export_io.dart):8–44
  rechecks ownership after the picker, before writing. Neither fetches an Agent
  artifact. A started write/download cannot be recalled; browser request success
  is not persistence proof. See the [existing export runbook](../runbooks/chat-transcript-export.md).

## Nearest tests and inert-preview oracle

**Inspected, not executed**; no tests were added for documentation:

- [Agent artifact tests][agent-tests]:86–192 cover size/MIME rejection, roundtrip,
  SHA tamper rejection, principal/family scope, traversal IDs and expiry;
  429–554 cover authenticated HTTP one-shot download, upload rejection, foreign
  scope/unknown IDs and rate limiting. 556–654 cover advertisement, intentional
  HTTP-without-session → session-bearing broker composition and distinct profile
  stores. Their small `_app` directly mounts handlers: these are not full production
  multiplex-middleware, download revoked-key or Wing ownership tests.
- [Async store test][async-tests]:18–40 checks single-flight off-loop construction,
  not a content bound or delivery guarantee.
- [Wing transcript cases](../../test/features/hermes_chat/screens/hermes_chat_rich_transcript_test.dart):674–791,
  2893–3061 cover recognized undelivered host references, bounded inline images,
  MIME mismatch, pixel/frame rejection, alt semantics and remote image deferral.
  [Metadata tests](../../test/features/hermes_chat/presentation/inline_transcript_image_safety_test.dart):8–122
  inspect supported format/dimension/frame bounds.
  [Export tests](../../test/features/hermes_chat/export/hermes_transcript_export_test.dart):9–64
  cover preserved inert source bytes, Unicode and byte-limit rejection, not Agent retrieval.

**Absent operation/oracle:** there is no Wing retrieved-artifact preview to qualify.
A later candidate must first establish exact advertised operation, supported
explicit profile/session/run identity and current authentication/authorization,
then bind result admission to the initiating Wing owner and bounded verified bytes.
For an inert preview oracle, hostile markup/links/embedded resources must remain
literal noninteractive content or be rejected before rendering, with zero scripts,
subresource/network requests, host reads, external-app launches and implicit saves;
rejected/oversize/stale-owner results must publish no content. These are admission
requirements, **not implemented checks or a new protocol**. The separate dependent
[plain-text evidence slice](artifact-text-preview-evidence.md) maps `text/plain`
hostile-content and denial/cancel oracles under
`DOC-ARTIFACT-INERT-PREVIEW-EVIDENCE`; it does not enable retrieval or qualify a
renderer. This retrieval receipt did not execute that dependent task.

Folder grants are **directory-only** under the [API/state decision](../adr/api-and-state.md):
opaque child-folder lookup is not file enumeration and never implies artifact
lookup, read, preview, save or launch authority. No arbitrary path, shell, direct
Agent-file access, new compatibility service or upstream patch may fill this gap.

## Validation and follow-through

Offline scope: source inspection on Linux only; no Flutter/Agent/Desktop tests,
application build, server activation, credentials, inference or live operations.
Independent fresh-context contract/security review (run
`d1b52b61-c0b5-45cf-9c73-ef14cfd0944c`) found no critical, important or minor
findings and judged the bounded documentation ready for integration, not runtime
qualification. It did not attest lease history or contact external GitHub URLs.
Pin and clean-reference checks, changed Markdown target/range verification and
`git diff --check` are the remaining closeout gates. Their final commands/results
belong to the worker report; source inspection must not be promoted to native/live
qualification.

Revisit when the pinned Agent handler/store/capability/profile/auth contracts,
official preview outcome, Wing media policy or artifact caller changes. Any later
retrieval/preview/save implementation requires its own focused regression and
named-platform/live qualification with an unmodified Agent and separate consent.
Coordinator integration and ARTIFACTS acceptance remain separate from this local
contract commit.

[api]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/gateway/platforms/api_server.py
[store]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/gateway/browser_control_artifacts.py
[agent-tests]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/gateway/test_browser_control_artifacts.py
[async-tests]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/gateway/test_api_server_artifact_store_async.py
[desktop-registry]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/store/artifacts.ts
[desktop-preview]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/app/chat/right-rail/preview-artifact.tsx
[desktop-tests]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/app/chat/right-rail/preview-artifact.test.tsx
