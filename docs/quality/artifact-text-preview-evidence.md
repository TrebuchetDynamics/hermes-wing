# Plain-text artifact inert-preview evidence

Status: source-only receipt for `DOC-ARTIFACT-INERT-PREVIEW-EVIDENCE`, goal
**ARTIFACTS**. Start with the verdict, then the oracle table. This extends the
[retrieval contract](artifact-retrieval-contract.md#nearest-tests-and-inert-preview-oracle)
for **one upstream-permitted type: `text/plain`**. “Permitted” means membership in
Agent's transport MIME allowlist, not permission for Wing to retrieve or preview.
No content request, artifact receipt acquisition or preview activation occurred.

## Verdict and inspected identities

**There is no allowed Wing retrieval/preview contract for this type in the
inspected sources.** Agent advertises `artifact_download`, GET
`/v1/artifacts/download/{artifact_id}`, for browser control, but Wing has no caller
and the contract lacks session/run ownership and a Wing-supported explicit profile
declaration. Text bytes are not validated as UTF-8 or screened for active syntax.
Keep retrieval/preview/save unavailable; do not manufacture an endpoint, scope,
renderer, folder permission or direct-file fallback to close this gap.

Read-only checkout pins, obtained with `git rev-parse HEAD`:

| Checkout | Revision | Meaning |
| --- | --- | --- |
| Wing task baseline | `6f6b0af331ac314f9f08db5142b3a04b7607f546` | Clean assigned `autowork/DOC-ARTIFACT-INERT-PREVIEW-EVIDENCE` worktree before documentation edits. |
| Hermes Agent | `158fd638da1629c8e62caf9ade1515d162def8ab` | Clean canonical read-only reference; not present inside this isolated worktree. |
| Official Desktop | `158fd638da1629c8e62caf9ade1515d162def8ab` | `hermes-agent/apps/desktop/` in the same repository, not independent runtime evidence. |

The local `goals.json` task tracker marks `DOC-ARTIFACT-CONTRACT` done and this
slice open; dependency receipt `c7df5bb5` and tracker closure `1294caad` are baseline
ancestors. The native execution slot binds this task, branch and baseline to
attempt 1. No continuation ledger was found in this isolated checkout; no external
tracker/lease history is attested and no other worker claim was adopted or released.
The prior task's [sanitized worker report](#sanitized-receipt-inspection) was
inspected, not reinterpreted as runtime qualification.

Authority: [API/state](../adr/api-and-state.md),
[security/privacy](../adr/security-and-privacy.md),
[immutable Agent](../adr/runtime-and-delivery.md#hard-boundary-never-modify-hermes-agent),
[threat model](../security/threat-model.md), and the
[accepted port plan](../../ROADMAP.md#flutter-port-execution-roadmap).
The [parity status table](../product/hermes-desktop-parity.md#statuses) is a gap
index; its historical directory/management wording grants no artifact authority.
Folder grants are **directory-only**: no file listing, read, preview, save or launch.

## One-type authoritative trace

All upstream line ranges refer to the pinned source, inspected without executing
handlers, store methods or tests:

- **Advertisement and authentication:** [API][api]:2536–2575 advertises the
  browser-control download, MIME list, maximum bytes and TTL even when disabled.
  API:2858–2877 gates enabled state, configured key, Bearer authentication and
  per-action/principal rate budget. API:2742–2770 derives principal from profile
  and expected key and classifies actual peer transport family; 2779–2839 resolves
  per-profile stores. Neither the endpoint row nor a `text/plain` label supplies
  session/run ownership or a Wing-supported query-profile declaration. See the
  [full authentication/profile trace](artifact-retrieval-contract.md#exact-authoritative-trace).
- **MIME is metadata:** [store][store]:24–30 includes `text/plain`.
  Store:159–198 checks byte count and normalized MIME before storing; 287–295
  strips MIME parameters, trims/lowercases and bounds a display-only filename.
  It does not decode text or reject HTML, Markdown, links, embedded-resource syntax,
  control characters in content or binary bytes labeled `text/plain`. Do not infer
  UTF-8 from a charset parameter that normalization discards. Default upload cap is
  10 MiB, not a preview/parse-work budget.
- **Integrity and one-shot delivery:** store:204–227 reads the whole file, verifies
  its recorded SHA-256, drops the index entry and best-effort unlinks it. There is
  no independent pre-read size bound or content safety pass. API:2923–2950 returns
  raw bytes with stored MIME, hash/ID headers and attachment disposition. A correct
  hash proves consistency, not safe rendering or trusted authorship. Consumption
  precedes delivery; cancellation/disconnect cannot promise non-consumption,
  rollback, durable delivery or safe retry of this GET.

## Inert-preview and denial/cancel oracle map

“Required” below is a future admission oracle, **not implemented Wing behavior or
an invented callable protocol**. The current outcome is no artifact operation.
No synthetic payload was sent or rendered in this task.

| Case for `text/plain` | Source/test evidence inspected | Oracle and remaining gap |
| --- | --- | --- |
| Valid MIME/hash but hostile HTML, Markdown links, resource references or code | Store:159–227 has no text parser. [Agent tests][agent-tests]:429–464 roundtrip ordinary text and assert hash/one-shot consumption. | Required: bounded validated text remains literal, noninteractive content or is rejected before presentation; zero scripts, link activation, subresource/network requests, host reads, app launches or implicit saves. Transport roundtrip is **not** this oracle. |
| Declared type versus bytes, invalid encoding, oversized content or parse work | Store:159–170 only checks length/MIME; [Agent tests][agent-tests]:86–95 checks configured size/MIME rejection. API:2879–2921 checks upload body, not preview. | Required: a verified bounded byte/decoding/work policy before publishing any preview; unsupported/malformed/oversize input publishes no content. No text-decoding, binary-mislabeling or hostile-text preview test exists in this inspected seam. Do not borrow the local export's UTF-8 encoder as a retrieved-byte decoder. |
| HTML/SVG declared as such | [Agent tests][agent-tests]:468–494 expects 415 for `text/html`, and 400 for missing filename. Store allowlist excludes `text/html` and `image/svg+xml`. | Existing transport rejection does not inspect identical syntax labeled `text/plain`, and is not a client renderer test. Do not MIME-sniff or promote plain text into active HTML/SVG/Markdown. |
| Wrong authority, invalid/expired/consumed ID or tampered bytes | Store tests [86–192][agent-tests] cover scope/principal/family, ID shape, TTL and checksum; HTTP tests [501–554][agent-tests] cover foreign scope, unknown ID and upload rate budget. | API:2923–2950 maps disabled/unknown/read/checksum to 404, expiry to 410 and invalid ID/scope to 400; prelude supplies 403/401/429. Required client denial publishes no artifact content or false saved state, no path fallback or automatic retry. Generic 404 is not proof of deletion; tamper failure does not consume the entry. Full production middleware and Wing authority denial are not established by the directly mounted test app. |
| Cancel before action; close or owner change while awaiting result | No Wing artifact request/preview action exists. Agent's load consumes before response. | Required: no request before explicit, eligible intent; cancellation/owner loss prevents later content publication or implicit save/launch. After request admission, outcome may be unknown, not “cancelled on Agent.” Closing a pane is not rollback and reconnect must not replay the one-shot request. No retrieved-artifact cancellation test is present. |
| Local text export cancellation or owner loss | [Linux saver](../../lib/features/hermes_chat/export/hermes_transcript_export_io.dart):12–42 and [tests](../../test/features/hermes_chat/export/hermes_transcript_export_linux_test.dart):65–101 reject stale intent before picker, null selection and changed owner after the wait, preserving an existing file. [Chat tests](../../test/features/hermes_chat/screens/hermes_chat_transcript_export_test.dart):309–357, 518–530 cover cancel/dispose/failure/oversize and Escape. | Useful **adjacent** no-write/no-false-success oracles only. Picker is mocked in the Linux test despite its test title; it is not a native-dialog run or Agent cancellation. No guarantee can recall an already-started write/download. |

### Official Desktop reference, not transport substitution

[Desktop registry][registry]:274–357 stores supplied content by session/slug with
versions and opens a rail preview on user action, not through browser-control hex
IDs. [Preview][preview]:17 maps `code` downloads to `text/plain`; 200–202 offers
code only in source mode, and 260–265 passes it to `SourceView`. This is a product
reference for source presentation, not a `text/plain` Agent retrieval contract.
Its [nearest test][preview-tests]:58–64 asserts absence of the Rendered button for
ordinary code, not hostile-text/network/launch rejection. Preview tests:113–128
assert a missing registry record offers Close and invokes `onClose`; this is not
cancellation of a download. HTML's `allow-scripts` iframe and sanitized SVG paths
(preview:74–104; tests:33–56) do not prove inert plain-text rendering and must not
be used to promote text into an active preview.

### Wing media/export callers, not a preview implementation

- [Timeline](../../lib/features/hermes_chat/presentation/hermes_chat_timeline.dart):684–810
  uses rich transcript text, attachment labels and undelivered-host-reference
  notices, not an artifact GET. [Rich text](../../lib/features/hermes_chat/presentation/hermes_rich_text.dart):154–160,
  282–347 has explicit link-launch callbacks and bounded data-image handling.
  Remote/file images defer to labels. This Markdown path is **not** a literal,
  noninteractive artifact-text oracle and must not be treated as one.
- [Local export model](../../lib/features/hermes_chat/export/hermes_transcript_export.dart):11–45
  encodes already-loaded transcript snapshots as immutable UTF-8, generic `.txt`
  or `.md` names, capped at 4 MiB without truncation. [Model tests](../../test/features/hermes_chat/export/hermes_transcript_export_test.dart):8–50
  preserve script-looking source bytes/Unicode and reject oversized output; they
  never execute or preview those bytes. [Chat caller](../../lib/features/hermes_chat/screens/hermes_chat_screen.dart):1323–1470
  snapshots only on explicit action and fences channel/origin/profile/session/
  generation, including post-wait feedback. [Browser saver](../../lib/features/hermes_chat/export/hermes_transcript_export_web.dart):14–39
  starts a local Blob download, not a fetch or persistence acknowledgment.
- Read-only search of `lib/core/hermes/` and `lib/features/hermes_chat/` found no
  `artifact_download`, `artifact_transport` or `/v1/artifacts/` caller. Reusing
  local export or inline media cannot supply missing retrieval authority.

## Sanitized receipt inspection

The retained `DOC-ARTIFACT-CONTRACT` attempt-1 worker `report.json` records commit
`c7df5bb59ee7256f8fd934e8d283311ac44a6106`, documentation/link/range checks and
independent review `d1b52b61-c0b5-45cf-9c73-ef14cfd0944c`. Its pending-live item
explicitly leaves retrieval/preview/save unqualified. Only those bounded metadata
were used; no artifact ID, payload, host path, endpoint or credential is reproduced.
Its report is evidence of the prior documentation checks, **not** an Agent artifact
receipt. No sanitized runtime text-artifact preview receipt was available in this
slice. The [existing export runbook](../runbooks/chat-transcript-export.md#exact-owner-failure-feedback-repair-t_aaa10f17)
reports synthetic save/owner checks separately; those results were not rerun or
upgraded to retrieved-artifact evidence here.

## Validation and follow-through

Checklist for this documentation slice:

- Source identity/cleanliness, dependency and caller inspection; no content access.
- Verify changed Markdown targets, anchors and cited line ranges locally against
  pinned source objects; no HTTP link probes or artifact calls.
- Independent fresh-context contract/security review and `git diff --check`.
- One scoped local documentation commit; coordinator integration remains separate.

Final commands/results belong to the worker report. Tests above were **inspected,
not executed**; no test was added for documentation. Only Linux source inspection
was exercised. No application, browser, native/device or live Agent preview/save
safety is qualified; ARTIFACTS remains open. A future implementation first needs
an eligible unmodified Agent contract, then focused hostile-text/denial/cancel
regressions and separately authorized named-platform/live and persistence evidence.
Revisit on handler/store/auth/capability changes, a Wing artifact caller, Desktop
preview changes or changes to adjacent media/export ownership policies.

[api]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/gateway/platforms/api_server.py
[store]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/gateway/browser_control_artifacts.py
[agent-tests]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/gateway/test_browser_control_artifacts.py
[registry]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/store/artifacts.ts
[preview]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/app/chat/right-rail/preview-artifact.tsx
[preview-tests]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/app/chat/right-rail/preview-artifact.test.tsx
