# Bounded Linux paged session JSON export

Task: `PARITYGAP-002-76`. Offline implementation, not GTK/live qualification or
closure of the `HD-EXPORT` runtime cells.

## Source and scope

The [resolved source contract](unowned-desktop-outcomes-contract.md#hd-export)
traces official Desktop's `apps/desktop/src/api/sessions.ts` collector and
`apps/desktop/src/lib/session-export.ts` wrapper, and Agent's
`hermes_cli/web_routers/sessions.py` messages handler. Read-only source inspection
also traced `hermes_state_messages.py`: authenticated ancestor rows keep their
physical session identity, the envelope names the resolved continuation tip,
and physical IDs are not necessarily display-order monotonic. This is a projected
history export, not an Agent database backup. The task's detailed accepted slice
is its [accepted paged-session JSON scope](../plans/2026-10-03-desktop-port-goal.md#paged-session-json-export).
That plan records intent; the implementation and executed checks below, not the
plan's presence, establish the bounded offline outcome.

On Linux, Chat's existing transcript menu offers **Export paged history as JSON**
only for the fixed authenticated local-serve reader with a settled, idle owner.
Gateway HTTP, browser JSON and other native platforms remain unavailable. The
existing loaded text/Markdown copy/save actions still redact their original
snapshot and fetch no history.

## Boundaries

- Capture the reader/connection generation/origin, profile and selection
  generations, stored session ID/title, and local run generation once. A profile
  or session roundtrip does not revive an attempt. Cancellation does not disconnect
  the shared reader or chat lifecycle. Explicit retry creates a new attempt at zero.
- Require private, **unredacted** export consent before fetching. Fetch fixed GET
  pages with explicit profile, `limit=500`, `order=oldest`, offsets and
  `include_compacted=true`. Validate envelope/profile, stable resolved tip and exact
  integer pagination on every page. Short/empty pages terminate; an exact multiple
  requires the terminal empty page. Duplicate physical IDs fail, not deduplicate.
- Keep raw projected structured, hidden, ancestor, compacted and tool records as
  inert JSON. Ordinary display-history identity checks are unchanged. No attachment
  URL fetching, HTML interpretation, clipboard fallback, Agent files, backup/import,
  canonical `session.export`, native ticket acquisition or host save operation.
- Preserve the existing 1 MiB response cap. Collection has a 60-second total deadline
  and a 4 MiB final UTF-8 cap **including the wrapper and title**. Any read/auth,
  redirect, network, pagination, limit, cancellation or owner failure discards the
  attempt with no prepared output or partial save action. No spooling or truncation.
- Emit `exported_at`, captured requested `session_id`, `title`, `session:null`,
  `message_count` and raw `messages`. No client-added private origin, credential,
  destination or `complete=true`. Save immutable, ephemeral owner-bound bytes as
  `hermes-session.json` with `application/json`, only after a separate explicit Save.
- Recheck ownership before the chooser, after it, after local replacement consent
  and immediately before write. Because the reviewed Linux chooser does not promise
  overwrite confirmation, every selected destination requires **Save and allow
  replacement** consent, even if it appears new: another process may create a file
  before writing. No existence-check race can imply consent. Paths stay local.
  Saved, download-requested, unsupported, cancelled and failed outcomes differ.
  Cancelling cannot roll back an OS write that already started.

This is **paged history, not a frozen snapshot**. Stable tip and duplicate checks
cannot detect every external edit/deletion or offset omission; same-length edits
can evade them. There is no atomic completeness claim or cross-page revision.
The authenticated server owns ancestor/lineage projection: the response does not
provide a separate lineage manifest for the client to prove each ancestor.

## Offline verification

Focused regressions exercise real bounded HTTP requests for 0/499/500/501/1000
synthetic rows, terminal paging, raw Unicode/ancestor/structured/tool content,
identity/pagination/duplicate/auth/redirect/network/response/final-limit rejection,
explicit retry, cancellation/disconnect, and late owner rejection. Additional
collector coverage checks the deadline and multibyte wrapper overhead. Channel
coverage checks session/profile roundtrips and run start/end. Linux saver tests use
a mocked chooser but real temporary destination files for exact bytes, extensions,
MIME, consent, concurrent destination creation, stale owners and error outcomes.
Widget coverage checks consent, progress/cancel, separate Save, late callbacks,
terminal feedback and zero partial saves; retained loaded-export cases compare
existing copy bytes and assert zero history backfill.

`flutter gen-l10n`, changed-Dart formatting, `flutter analyze --no-pub` and the
task's combined client/channel/export/transcript widget test command passed
(804 tests). The fresh deterministic JS-release E2E web build passed with retained
third-party Wasm/font warnings. The two loaded-export Chromium cases (390/1280px)
failed their exact-byte expectation at `transcript-export.spec.mjs:61`; each also
failed alone and both failed identically on baseline
`83fcbc032a7c871c17258d8b46a58a18bd4fea04`. These are recorded as unrelated
baseline failures, not browser passes. The retained widget regressions verify
loaded save/copy byte equality and zero history backfill.

Final command details are recorded in the task execution report. The full offline
suite is the coordinator's integrated-tree gate, not a worker claim. Browser
compilation or fixture checks do not qualify native JSON saving.

## Pending qualification

On a named isolated Linux GTK target, exercise paged JSON preparation, real chooser
save/overwrite refusal and consent, cancel during read/picker, owner switch and
exact destination-byte readback. Separately verify actual unmodified Agent
projection, including lineage and compacted rows. Other platforms, live credentials,
canonical export/private tickets, backup/import and full Desktop parity remain
separate outcomes. No physical device, GTK UI or live Agent was exercised here.
