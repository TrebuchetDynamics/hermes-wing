# Chat Continuity Implementation Plan

> **For agentic workers:** Use executing-plans task-by-task. Checkboxes track future implementation. No commits, external writes, or delegation are authorized by this plan.

**Goal:** Preserve the user’s exact composer and transcript context across delayed callbacks, session changes, authoritative refreshes, and foreground recovery.

**Architecture:** Reuse the existing `_ComposerDraftKey` resource identity and add small feature-local policies for draft generations and viewport ownership. Keep draft content process-local in the first release. Restore only after authoritative session history lands, and never let restoration override explicit navigation.

**Tech Stack:** Flutter 3.44.2, Dart, Riverpod, `HermesChannelState`, `ScrollController`, flutter_test. No new dependency.

## Global Constraints

- Keys always include gateway, profile, and session identity.
- Agent history remains authoritative; local state is presentation state, not a second transcript.
- Do not persist prompt text, attachment bytes, attachment contents, recognized speech, or content hashes.
- The first viewport marker is process-local and contains only resource identity, authoritative turn/source identity when available, and edge offset. IDs remain private metadata.
- Explicit session selection, deep-link intent, or future notification target wins over automatic restoration.
- Missing/deleted anchors fall back to latest activity without throwing.
- Do not stage or commit unless the human explicitly asks.

---

### Task 1: Fence attachment-picker completions by composer identity

Status: partially executed; the receipt at the end supersedes this baseline. See the
[program evidence and dependencies](2026-09-04-conduit-adaptation-roadmap.md).
Current `_sendComposerText` clears before dispatch; generation-safe clearing is
a preservation contract for the proposed store, not proof of a delayed-success
bug in today's flow. Late picker/normalization ownership is an observed gap.

**Files:**
- Modify: `lib/features/hermes_chat/composer/hermes_chat_message_flow.dart`
- Test: `test/features/hermes_chat/screens/hermes_chat_voice_lifecycle_test.dart`

**Interfaces:**
- Consumes: existing `_ComposerDraftKey? _composerDraftKey(HermesChannelState state)`.
- Produces: late picker and file-read results commit only when the original key remains active.

- [ ] **Step 1: Write the failing session-switch test**

Add a test whose picker returns through a `Completer<XFile?>`. Tap the paperclip in session A, switch to session B, complete the picker with a valid small text file, and assert that neither session B nor the visible composer receives the attachment.

- [ ] **Step 2: Add gateway/profile variants**

Use the existing gateway/profile switching harnesses to prove A → B and A → B → A. Returning to the same string identity is not enough: capture a monotonically increasing picker operation generation as well as `_ComposerDraftKey`.

- [ ] **Step 3: Implement the minimal gate**

At picker start capture:

`final targetKey = _composerDraftKey(ref.read(hermesChannelProvider).state);`

Increment `_attachmentPickGeneration`, capture it locally, and before every state commit require:

`mounted && generation == _attachmentPickGeneration && _composerDraftKey(ref.read(hermesChannelProvider).state) == targetKey`.

Increment the generation on connection, gateway, profile, or session changes, explicit attachment removal/replacement, and disposal. Capture it before the first await, including pasted-image normalization. Pass the same owner token through `_stageComposerImage`; revalidate after picker, length, byte-read, and normalization awaits, and before errors or busy-state cleanup. Cancellation clears only its matching generation. Owner replacement releases obsolete busy state so old work cannot block the new composer. Reject a null composer key rather than allowing null to match null.

- [ ] **Step 4: Verify**

Run:

`flutter test test/features/hermes_chat/screens/hermes_chat_voice_lifecycle_test.dart --plain-name 'late attachment picker result stays with its original composer identity'`

Expected: PASS, one picker call, no staged attachment in the replacement context.

- [ ] **Step 5: Review checkpoint**

Confirm no filename, bytes, path, or picker exception was logged or persisted.

### Task 2: Give text and attachments one generation-owned draft bucket

**Files:**
- Create: `lib/features/hermes_chat/composer/hermes_composer_draft_store.dart`
- Modify: `lib/features/hermes_chat/screens/hermes_chat_screen.dart`
- Modify: `lib/features/hermes_chat/composer/hermes_chat_message_flow.dart`
- Modify: `lib/features/hermes_chat/screens/state/hermes_chat_lifecycle.dart`
- Test: `test/features/hermes_chat/composer/hermes_composer_draft_store_test.dart`
- Test: `test/features/hermes_chat/screens/hermes_chat_gateway_switch_test.dart`
- Test: `test/features/hermes_chat/screens/hermes_chat_voice_lifecycle_test.dart`

**Interfaces:**
- Produces:

`HermesComposerDraftKey(gatewayId, profileId, sessionId)`

`HermesComposerDraft(text, attachment, generation)`

`HermesComposerSubmission(key, text, attachment, generation)`

`HermesComposerDraftStore.update(key, text:, attachment:)`

`HermesComposerDraftStore.captureForSubmission(key)`

`HermesComposerDraftStore.clearIfGeneration(key, generation)`

Migration is excluded from the first store interface. Task 3 adds it only if a real provisional-session product flow exists.

- [ ] **Step 1: Unit-test generation-safe clearing**

Prove: capture generation 1, edit to generation 2 while send 1 is pending, then `clearIfGeneration(key, 1)` returns false and preserves generation 2 text plus attachment.

- [ ] **Step 2: Unit-test bounds and eviction**

Keep the current maximums: 64 entries and 65,536 grapheme clusters per draft (`_maxComposerDraftCharacters`), not 64 KiB. Preserve existing per-attachment validation and use a proposed 16 MiB aggregate retained-attachment budget, counting normalized bytes or UTF-8 text bytes. The visible attachment uses its existing bound separately. Evict inactive attachments first and expose eviction when revisiting that draft; never silently drop the active attachment or captured submission. Keep retry payloads bounded. Nothing is written to disk.

- [ ] **Step 3: Replace parallel screen fields**

Replace `LinkedHashMap<_ComposerDraftKey, String> _composerDrafts` plus global `_stagedAttachment` ownership with the store. The visible controllers remain Flutter presentation adapters; the store becomes the single owner of draft text, attachment, and generation.

- [ ] **Step 4: Capture before send and make eager clearing generation-safe**

`HermesChannel.sendText` currently completes at stream termination, so leaving submitted text in the editor until success would be misleading. Capture `HermesComposerSubmission`, transition that exact generation to an empty post-submit generation immediately, and remember both generation numbers.

- [ ] **Step 5: Restore only when the empty generation is still current**

On an immediate/terminal send failure, restore the submitted text and attachment only if the draft is still the empty post-submit generation. If the user typed or staged anything newer, preserve it and retain the captured payload only in the bounded retry affordance. Never overwrite the newer draft.

Apply the same ownership checks to steering and queued follow-up failure callbacks. Failure restoration is presentation only; reconnect must never automatically replay the captured submission.

- [ ] **Step 6: Verify**

Run the store unit test plus `hermes_chat_gateway_switch_test.dart`, `hermes_chat_voice_lifecycle_test.dart`, and attachment cases in `hermes_chat_rich_transcript_test.dart`.

### Task 3: Gate provisional-session migration on a real product flow

**Files:**
- Inspect: `lib/features/hermes_chat/session/hermes_chat_session_actions.dart`
- Inspect: `lib/core/hermes/channel/hermes_channel.dart`
- Modify only if applicable: `lib/features/hermes_chat/composer/hermes_composer_draft_store.dart`
- Test only if applicable: `test/features/hermes_chat/composer/hermes_composer_draft_store_test.dart`

**Interfaces:**
- Consumes: the Task 2 store; add generation-checked `migrate(from, to)` only after applicability is proven.
- Produces: no product code unless Wing actually allows composing before an Agent session ID exists.

- [ ] **Step 1: Prove applicability**

Trace create-session and first-send behavior. If the composer is disabled until `activeSessionId` exists, record “not applicable” in this plan’s implementation receipt and stop this task.

- [ ] **Step 2: If applicable, define the provisional key**

Use an in-memory random operation ID scoped to gateway/profile. Never derive it from prompt text or persist it.

- [ ] **Step 3: Test atomic migration**

When Agent creation returns session S, move the entire draft only if the provisional generation still matches. If S already has a newer draft, preserve S and leave the provisional draft recoverable.

- [ ] **Step 4: Verify**

Run the store unit tests and the exact create-session widget test. No invented Agent parameter or local session record is allowed.

### Task 3A: Add a presentation-only fallback for missing or duplicate turn IDs

**Files:**
- Create: `lib/features/hermes_chat/presentation/hermes_turn_presentation_identity.dart`
- Modify: `lib/features/hermes_chat/controllers/hermes_channel_observation.dart`
- Modify: `lib/features/hermes_chat/presentation/hermes_chat_timeline.dart`
- Test: `test/features/hermes_chat/presentation/hermes_turn_presentation_identity_test.dart`
- Test: `test/features/hermes_chat/controllers/hermes_channel_observation_test.dart`

**Interfaces:**
- Produces `HermesTurnPresentationIdentity.resolve(turns, index)`.
- Returns authoritative `turn.id` only when nonblank and unique in the scoped session; otherwise returns a presentation key derived from session, author, created-at value, kind, and same-signature occurrence ordinal. It never mutates `HermesChatTurn.id`.

- [ ] **Step 1: Write missing/duplicate-ID tests**

Parse several Agent history messages with blank IDs and duplicate nonblank IDs. Assert widget keys, completion observation, and viewport anchors remain distinct and deterministic across an identical authoritative refresh.

- [ ] **Step 2: Keep the fallback non-authoritative**

Use the resolver only for Flutter keys, completion-edge observation, and viewport anchors. API requests, run ownership, approvals, and transcript models continue using Agent identity only.

Fallback keys are valid only within the unchanged presentation snapshot. They
must not prove identity across canonical replacement or pagination, nor trigger
completion notifications for an ambiguous old/new row. Restore across snapshots
only with authoritative identity; otherwise invalidate the marker and use the
safe latest-activity fallback. An alias map cannot manufacture missing evidence.

- [ ] **Step 3: Test pagination effects**

Prepending older history must not change fallback identity for existing rows. If timestamp/author/kind plus occurrence cannot guarantee this, keep an in-memory alias map scoped to connection/profile/session generation; do not use message content or persist it.

- [ ] **Step 4: Verify**

Run presentation-identity, channel-observation, pagination, and rich-transcript tests.

### Task 4: Model viewport ownership explicitly

**Files:**
- Create: `lib/features/hermes_chat/presentation/hermes_transcript_viewport.dart`
- Modify: `lib/features/hermes_chat/presentation/hermes_chat_timeline.dart`
- Modify: `lib/features/hermes_chat/screens/hermes_chat_screen.dart`
- Modify: `lib/features/hermes_chat/screens/state/hermes_chat_layout.dart`
- Test: `test/features/hermes_chat/presentation/hermes_transcript_viewport_test.dart`
- Test: `test/features/hermes_chat/screens/hermes_chat_rich_transcript_test.dart`

**Interfaces:**
- Produces `enum HermesViewportMode { followingLatest, browsing, restoring, explicitTarget }`.
- Produces `HermesViewportAnchor(gatewayId, profileId, sessionId, turnId, sourceMessageId, edgeOffset)`; optional source identity is used only if Agent data supplies it. No text or content hash.
- Produces `HermesTranscriptViewportController.userScrolled(...)`, `capture(...)`, `beginAuthoritativeRefresh(...)`, `restore(...)`, and `followLatest()`.

- [ ] **Step 1: Unit-test transitions**

Prove that user scroll away from the tail enters `browsing`; new deltas do not move the viewport; returning near the tail enters `followingLatest`; explicit navigation suppresses restoration.

- [ ] **Step 2: Give transcript rows stable keys**

Key each rendered turn by authoritative session and turn ID. Capture the topmost visible turn plus its local edge offset before lifecycle refresh.

- [ ] **Step 3: Restore after authoritative history**

After refreshed history commits, restore by turn ID within the captured resource. If IDs changed, use authoritative source-message identity only when available and unambiguous. Never infer identity from text, timestamps, or ordinal position. Without a reliable anchor, follow latest in the same selected session. If the session vanished, expose safe session selection rather than automatically choosing another conversation. Bound restoration to two layout attempts and one authoritative refresh; never fetch unbounded history to hunt for a marker.

- [ ] **Step 4: Preserve user ownership during layout changes**

Keyboard, text scale, window resize, Markdown expansion, and image decode may auto-scroll only in `followingLatest`. Reduced motion uses an immediate jump.

Pending post-frame callbacks capture viewport generation and owner; user scroll
or explicit navigation invalidates them immediately. Respect the reverse-list
orientation. Retain at most 64 process-local markers, evict inactive markers,
and delete markers on gateway removal or confirmed session deletion. A “Latest
activity” action explicitly returns to `followingLatest`; “Continue where I left
off” restores only a valid marker.

- [ ] **Step 5: Add widget regressions**

Cover canonical turn replacement, missing anchors, session deletion, profile switch, new deltas while browsing, 200% text scale, and explicit session selection during resume.

- [ ] **Step 6: Verify**

Run the viewport unit test, rich transcript suite, gateway/session suite, and lifecycle suite.

### Task 5: Orchestrate foreground restoration after canonical refresh

**Files:**
- Modify: `lib/features/hermes_chat/screens/state/hermes_chat_lifecycle.dart`
- Modify: `lib/features/hermes_chat/controllers/hermes_channel_observation.dart`
- Modify: `lib/features/hermes_chat/gateways/gateway_contact_cache.dart`
- Test: `test/features/hermes_chat/screens/hermes_chat_voice_lifecycle_test.dart`
- Test: `test/features/hermes_chat/screens/hermes_chat_gateway_switch_test.dart`

**Interfaces:**
- Consumes: `HermesTranscriptViewportController` from Task 4.
- Produces: ordered resume phases: transport health decision → intended session resolve → authoritative session/message refresh → viewport restore. If the channel lacks an explicit refresh seam, add `Future<void> reconcileActiveSession()` to `HermesChannel` and implement it with the already-advertised direct Agent session/history reads.

- [ ] **Step 1: Write ordering tests with deferred futures**

Assert restoration does not run before session messages refresh, and a user-selected replacement session cancels the old restoration generation.

- [ ] **Step 2: Add restoration generation and intent priority**

Capture gateway/profile/session plus an incrementing lifecycle generation. Priority order is: explicit target, current user selection, valid prior anchor, latest activity.

- [ ] **Step 3: Keep active streams attached**

Do not reconnect or replace a healthy attached stream merely to restore presentation. Existing detached-run recovery remains authoritative.

- [ ] **Step 4: Verify**

Run lifecycle, gateway switch, auth recovery, and rich transcript tests.

### Task 6: Decide whether any continuity state may become durable

**Files:**
- Modify if approved: `docs/adr/security-and-privacy.md`
- Modify if approved: `docs/security/threat-model.md`
- Modify if approved: `docs/product/prd.md`

**Interfaces:**
- Produces: a human-reviewed retention decision, not code.

- [ ] **Step 1: Document the candidate data**

Separate draft content, attachment metadata, resource IDs, and viewport anchors. State retention, deletion, backup, lock-screen, export, and compromise behavior for each.

- [ ] **Step 2: Default deny**

Until approved, keep drafts and viewport markers process-local. Ordinary preferences must never hold prompt text or attachment information.

This leaves process-death continuity unimplemented. Foreground continuity with a
surviving process must not be described as durable recovery.

- [ ] **Step 3: If approved, write a separate storage plan**

Require platform secure storage or an encrypted bounded store, explicit user controls, migration tests, and deletion on gateway removal. Do not add storage inside this plan.

## Validation receipt

Run the named focused suites, format only changed Dart files, and run
`flutter analyze`. After integration run the complete gate in `CONTRIBUTING.md`,
including the deterministic web build before Playwright. Record commands,
results, source identity, and targets in the program receipt. Tests and runtime
behavior were not exercised by writing this plan.

## Execution receipt (2026-09-04)

Source: `5cd4400e582590e6d1d6337a2bbfc32291b36f0e` plus dirty worktree;
Linux-hosted Flutter unit/widget tests, not physical-device qualification.

| Task | Status and evidence |
| --- | --- |
| 1 | Implemented picker, file read, normalization, cancellation, error and busy-state generation guards. The deferred A → B → A session-picker regression failed before the change and passes afterward; the newer picker remains operable. Gateway/profile matrix remains to expand. |
| 2 | Implemented 64-entry/65,536-grapheme text+attachment store, 16 MiB inactive attachment budget, visible eviction, atomic eager capture, and generation-checked exception restoration. Six store tests pass. Core `sendText` can complete normally on terminal failure: a typed outcome is still needed before whole-task completion; do not infer failure ownership from latest text or row position. |
| 3 | Not applicable: picker/send require connected active session identity. No provisional session model or migration method added. |
| 3A | Implemented unique Agent IDs and snapshot-local object/occurrence fallback keys. Ambiguous IDs are excluded from completion edges and cross-refresh anchors. No content hash, timestamp inference, or invented canonical ID. |
| 4 | Implemented bounded semantic markers and follow/browse/restore ownership, reverse-list offsets, reduced-motion jumps, explicit Latest activity, stale callback invalidation, session deletion/gateway removal cleanup. Visible-anchor restore and stale-user-intent tests pass. Missing/unmounted anchors fall back to latest; no source-message mapping exists. Expanded 200% text/layout/deletion matrix remains. |
| 5 | Wired canonical `reconcileActiveSession` before restore; core skips healthy live streams. Owner changes invalidate pending work. Full deferred foreground/reconnect/navigation matrix remains before task closure. |
| 6 | Proposal delivered in [continuity retention](../../product/continuity-retention-proposal.md). Default deny remains; no ADR approval or disk persistence. Process-death continuity is not implemented. |

Validation: store suite 6 passed; combined lifecycle, gateway-switch,
channel-observation and session-source suites 91 passed; viewport/rich-transcript
suites 72 passed. The separate `voice controls separate output mute from
microphone pause` widget regression passed. Integrated checks are recorded in the
[program receipt](2026-09-04-conduit-adaptation-roadmap.md#execution-receipt-2026-09-04).
Unchecked steps remain open where the full specified matrix has not been earned.

Final integration caught and fixed two additional edges: semantic restoration
explicitly requests a frame when canonical refresh leaves widgets unchanged;
Latest activity appears only while browsing/restoring and never overlays content.
The approval-tip test now scrolls its off-screen dismiss action into view.
The combined tips/auth-recovery/viewport/rich-transcript suite passes 88 tests;
the missing-anchor regression first failed, then passed after the frame fix.
