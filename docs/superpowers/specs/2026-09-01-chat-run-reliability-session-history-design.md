# Chat Run Reliability and Session History Design

## Status

Approved design for a reliability-first roadmap covering Hermes Wing chat runs, session history, and the session-scoped model picker.

## Purpose

Hermes Wing must prove that Agent-owned runs remain isolated and recoverable across concurrent profile activity, session or profile switches, application suspension, transport loss, and reconnection. After that reliability foundation is established, Wing can improve session discovery and model selection without inventing capabilities or state outside Hermes Agent contracts.

The work is ordered as follows:

1. Chat and run reliability tests.
2. Small channel fixes exposed by those tests.
3. Deterministic browser reliability coverage.
4. Paginated session history and loaded-page search/filter/grouping.
5. A searchable, provider-grouped session model picker.

Memory, Discover, Kanban controls, provider CRUD, gateway administration, and other surfaces remain deferred until Hermes Agent advertises exact suitable operations.

## Product and authority boundaries

Hermes Agent remains authoritative for profiles, sessions, runs, approvals, messages, and model inventory. Agent data-plane traffic continues directly between Wing and Hermes Agent; Wing Link is not involved.

Wing keeps one active-profile channel in the current UI. This design does not introduce multiple live profile tabs or a second domain store. A run is owned by the complete tuple:

- canonical Agent origin;
- profile ID;
- session ID; and
- run ID.

Every event, approval, stop request, durable lease, status response, and transcript reconciliation must remain bound to that tuple. A partial identity is insufficient when concurrent runs can exist.

Wing may retain provisional streamed presentation state and durable recovery leases. It must not treat either as authoritative session history, silently replay messages or controls, or create a shadow copy of Agent-owned domain state.

## Current evidence and constraints

The existing channel already has substantial deterministic coverage for same-profile concurrent session runs, targeted stop, approval routing, detached leases, stale connection generations, stream loss, and transcript reconciliation. The principal reliability gaps are cross-profile detach/switch/reattach behavior and browser-level lifecycle proof.

Hermes Agent currently advertises session listing and session message endpoints. Its session list supports bounded pagination and source filtering. It does not advertise a dedicated full-text session-search endpoint. Wing therefore must not promise exhaustive transcript or server-wide search.

Hermes Agent also advertises model-option inventory and a session-scoped model-lock operation. The model-picker work must use these contracts and must not mutate profile-wide model assignment.

## Run lifecycle architecture

### Active streaming

When Wing submits a run, it records the exact ownership tuple before consuming run events. Optimistic user and assistant turns are presentation state for the owning session only.

An incoming event may mutate state only when its supplied identifiers are compatible with the expected run and session. An explicit mismatched run ID or session ID is ignored. Profile and Agent origin remain fixed by the scoped client and durable lease that opened the stream.

Approvals are registered against their originating run. A later session or profile selection cannot redirect the response. Stop similarly resolves the active run for the currently selected session and profile and must not affect another run.

### Profile switching

Switching from profile A to profile B while A owns a run does not implicitly stop the Agent-owned run. Wing:

1. finishes local observation for A without sending a stop request;
2. retains A's durable run lease;
3. discards stale callbacks through connection, profile-selection, and stream-generation checks;
4. loads B's authoritative session inventory and active transcript; and
5. permits a B run when B has no unresolved run for that session.

Profile A and B may therefore have overlapping Agent-owned runs even though Wing presents one active profile at a time.

### Reattachment and terminal recovery

When Wing returns to a profile with a durable lease, it first asks Hermes Agent for run status when the exact status operation is advertised.

- Queued or running: retain the lease, reattach to the exact run event stream, and block duplicate submission for that session.
- Completed, failed, or cancelled: validate the returned run and session IDs, release the matching lease, and fetch canonical session messages.
- Not found after an Agent restart: treat the process-local run as absent, release the matching lease, and fetch canonical session messages.
- Transient or malformed status response: fail closed, retain the lease, and keep duplicate submission blocked.

Lease removal must be compare-and-remove safe so a delayed status or stop completion cannot clear a newer lease with the same broader resource identity.

### Server-authoritative transcript reconciliation

Streamed output is provisional. Wing fetches Agent session messages after:

- a successful terminal run event;
- terminal status discovered by polling or reattachment;
- a stream that closes or fails before a terminal event; and
- reconnect recovery when the run is no longer active.

Canonical Agent history wins when available. Wing may preserve local structured run details that the message endpoint does not expose, but it must not replace newer canonical text with stale streamed text.

If canonical history cannot be fetched, Wing preserves the visible provisional transcript and marks reconciliation as unresolved. The user receives an explicit refresh path. Wing does not replay the original message automatically.

## Reliability test design

### Channel contract matrix

Add focused deterministic tests for these invariants:

1. A profile A run survives a switch to profile B without receiving an implicit stop.
2. Profile B can start its own run while A remains detached.
3. Interleaved A and B events update only their owning transcripts.
4. An event with a mismatched run or session ID is ignored.
5. A's approval remains bound to A after B becomes active.
6. Stopping B does not stop or locally fail A.
7. Returning to A reattaches only to A's exact durable lease.
8. A terminal A status reconciles A's transcript from Agent history without changing B.
9. Delayed status, approval, stop, session-history, and profile-selection responses cannot mutate a newer connection or selection generation.
10. Stream loss retains ownership and blocks duplicate submission until Agent status or history resolves it.
11. Canonical history replaces optimistic or partial streamed text after terminal recovery.
12. Failed history refresh preserves provisional output and an explicit unreconciled state.
13. Durable lease operations remain serialized without losing concurrent profile runs.

Tests should assert relationships and ownership invariants rather than freeze incidental event counts or model catalogs.

### Deterministic browser fixture

Extend the existing deterministic Hermes fixture rather than introduce another backend. It must model:

- two explicit profiles;
- independent session lists and message histories;
- independently controlled run status and SSE streams;
- approval gates and stop requests per run;
- canonical terminal transcripts; and
- durable status across browser reload.

The targeted Playwright flow is:

1. Start a run in profile A.
2. Switch to profile B and start a second run.
3. Emit events and approvals in an interleaved order.
4. Verify transcripts, status indicators, and controls do not cross profiles.
5. Pause/resume the Flutter lifecycle and drop the active transport.
6. Reload the browser page to reconstruct the channel and durable lease store.
7. Reconnect and verify Agent-canonical transcripts.
8. Stop one run and confirm the other remains active or reconciles independently.

These tests establish deterministic web behavior only. They do not qualify physical Android or desktop suspend behavior.

## Session inventory design

### Pagination state

The channel exposes authoritative pagination state alongside the loaded sessions:

- loaded session rows;
- active query identity, including profile and source filter;
- next offset;
- whether the Agent reports another page;
- initial-load and next-page loading state; and
- bounded page-load error state.

Initial connection and profile selection load the first bounded page. A user-triggered "Load more" fetches the next page. Responses are accepted only when the connection generation, profile ID, and query identity still match.

Appending a page deduplicates by session ID. The newest returned server row replaces an older loaded row. Changing profile or server-backed source filter resets pagination; pages from different queries are never mixed.

A next-page failure preserves every previously loaded row and offers retry for that page. It does not clear the active transcript or session selection.

### Search semantics

Search is local and covers loaded metadata only:

- title;
- preview;
- session ID;
- parent session ID;
- source; and
- localized presentation grouping terms.

When more server pages exist, the interface explicitly says that search covers loaded sessions and keeps "Load more" available. Wing does not fetch every page automatically and does not claim transcript-content search.

### Filtering and grouping

Source filtering should use the existing Agent `source` list query where supported by the current session-list contract. Changing the source starts a new authoritative page sequence.

Date grouping remains presentation-only:

1. Pinned
2. Today
3. Yesterday
4. This week
5. Earlier

Within a group, sessions sort by server-reported activity time with a stable title-or-ID tie break. Grouping never changes Agent state.

Hermes Agent session metadata is authoritative when it returns a durable pinned flag. Wing must prefer that field over divergent presentation state and should not expand Wing-local session pinning. Migration or removal of the existing local pin store must avoid losing user reachability and should occur only after the current Agent response contract is verified in Wing's supported fixture.

### Shared presentation logic

The desktop session rail and compact session panel currently duplicate filtering and grouping behavior. Extract only the pure shared query, sorting, grouping, count-summary, and pagination presentation logic needed by both surfaces. Keep adaptive widget composition separate.

## Session model-picker design

Replace the two nested dropdowns with one searchable, keyboard-accessible sheet backed by `HermesModelOptions.selectableProviders`.

The sheet:

- shows the current confirmed provider/model first with a clear Current marker;
- groups models beneath Agent-provided provider labels;
- searches provider label, provider slug, and model ID;
- excludes unconfigured, unauthenticated providers through the existing selectable-provider policy;
- distinguishes loading, empty inventory, refresh failure, no search matches, and lock failure;
- keeps the sheet open and the previous confirmed selection unchanged on lock failure;
- disables duplicate submission while the lock request is active; and
- calls only the advertised session-scoped model-lock operation.

The sheet must preserve keyboard traversal, visible focus, semantic labels, screen-reader status for errors, and usable large-text wrapping.

No favorites, recent-model persistence, Wing-owned catalog, profile-wide assignment, or provider credential mutation is included.

## Failure behavior

- Profile switch during a run: detach locally, retain the lease, and never stop implicitly.
- Status unavailable: retain ownership and block duplicate submission.
- Ownership mismatch: ignore the response and retain conservative recovery state.
- Terminal status: release only the exact matching lease, then refresh history.
- History refresh failure: preserve the visible transcript and expose explicit refresh.
- Stale page response: discard it without altering the current query.
- Page-load failure: preserve loaded pages and expose retry.
- Approval or stop failure: attach the error to the originating session; do not surface it as another profile's chat error.
- Model-lock failure: keep the picker open and preserve the previous confirmed selection.

## Implementation slices

1. Add the missing cross-profile and lifecycle channel contract tests.
2. Apply the smallest shared-channel fixes exposed by those tests.
3. Extend the deterministic fixture and targeted Playwright reliability flow.
4. Add bounded session-list pagination to the API client and channel state.
5. Update desktop and compact session history using shared pure presentation logic.
6. Replace the model dropdowns with the searchable grouped picker.
7. Update localization and product documentation for changed support wording.

Each slice remains independently reviewable and validated. Reliability work is completed before session or model-picker UX changes.

## Validation

During implementation, run the nearest focused checks for each slice. Final validation for the complete roadmap includes:

- focused Hermes API channel tests;
- session rail/panel and model-picker widget tests;
- `dart format --output=none --set-exit-if-changed` for changed Dart paths;
- `flutter analyze`;
- `flutter build web --release -t lib/main_e2e.dart`;
- targeted Playwright reliability specifications;
- the full Playwright suite when shared fixture behavior changes; and
- `git diff --check`.

Physical Android and desktop lifecycle behavior remains unverified unless separately exercised on those targets.

## Out of scope

This design excludes:

- Memory;
- Discover;
- Kanban controls;
- provider CRUD or credential mutation;
- gateway administration;
- exhaustive or transcript-content session search;
- multiple simultaneously visible profile channels;
- Wing-owned model catalogs or model assignments;
- offline mutation queues or automatic message replay; and
- changes to Hermes Agent or Hermes Desktop reference checkouts.

## Completion criteria

The roadmap is complete when deterministic channel and browser tests prove cross-profile run isolation, suspend/reconnect recovery, approval and stop ownership, event cross-talk rejection, and server-authoritative transcript reconciliation; session history paginates and searches only loaded authoritative rows with honest scope wording; and the session model picker provides searchable Agent-backed selection without widening domain authority.
