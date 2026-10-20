# Canonical Bot Chat on the native channel

Task `ANDROID-CANONICAL-BOT-CHAT`, restored from `87938f2f` onto `4cf4a5dd`.
Offline implementation only; Android/live acceptance is pending.

Start with the [fixed native requests](../../lib/core/hermes/client/hermes_web_bot_chat.dart),
[owner-fenced adoption](../../lib/core/hermes/channel/api_channel/hermes_api_channel_bot_chat.dart)
and [focused regressions](../../test/features/hermes_chat/bots/).

## User outcome and bounds

Chat's compact More actions menu and wide header expose **Bot Chat** for the
selected connection/profile. Choose the profile with the existing switcher.
Ordinary session access remains separate. There is no new Office surface, bot
catalog, messaging bridge or canonical-ID registry.

A separate ticket-authenticated native reader stages the target without clearing
the current conversation. `session.list` carries the captured profile, exact
`Bot Chat` title and `include_hidden: true`. Only one matching registry row can
win; its `resolved_id` is the current compression tip. Each opening re-resolves:
recency and ordinary side threads never identify the Bot Chat. An empty result
contradicting already loaded canonical metadata fails closed, as do lookup errors.

Confirmed absence permits another lookup before native `session.create` with
`title`, `hidden`, `follow_profile_config` and a per-gesture idempotency key.
`session.title` must materialize the row with `pending: false`. Only exact title
conflict code 4022 permits another lookup to adopt the winner. Unknown writes,
timeouts and unsupported methods never retry mutations or submit an intro prompt.
A failed open may leave an Agent-committed row; Wing does not delete/retitle it or
claim that persistence rolled back. The next explicit retry consults the registry.

Title persistence is not proof of hiding: Agent's pending-hide step is separate
and best-effort. Profile-stamped native REST detail reads verify exact registry
ID/title/profile and persisted hidden flags for both root and tip. Only these
allowlisted facts are used; raw detail/config/prompt payloads are never projected,
logged or persisted. Failed hidden readback is not fabricated local success.

Target history and supported, settled replay must finish before foreground
adoption. Positive history evidence cannot be satisfied by an empty transcript.
Connection/profile/session generations, continuous source invalidation, and the
UI's owner/draft epochs prevent late results from retargeting newer work. A source
turn starting and completing cannot revive an old open. Invalid candidates are
disconnected immediately. Staging never answers a live server request: even an
error reply could globally withdraw the active source's approval. Such a request
closes only the candidate without replying; nonempty replay requests also reject
staging. The synchronous owner handoff enables request handling only after the
candidate is accepted. Repeated concurrent opens share one owner-scoped flight;
Agent title arbitration handles competing clients.

Adoption reuses the existing secure exact-session recovery path, not a canonical
identity pin. Send stays disabled until recovery persistence settles. A persistence
failure keeps loaded history visible but requires explicit reconciliation before
Send; raw storage causes are not displayed. Reader-owned pagination/loading flags
are retired with the old reader, so an interrupted ordinary page cannot strand
future pagination. Baseline history-export ownership is invalidated by reader,
selection-generation and qualification changes; export gates were not widened.

Verified hidden metadata supplies the active heading but is excluded from ordinary
recents/pickers. The existing owner-scoped composer store retains ordinary drafts.
Background refresh can update only the same active canonical tip, never create or
navigate. There is no new polling/roster navigation hook; a changed tip requires
an explicit open.

## Source and qualification boundary

Read-only official Agent/Desktop pin:
[`158fd638da1629c8e62caf9ade1515d162def8ab`](https://github.com/NousResearch/hermes-agent/tree/158fd638da1629c8e62caf9ade1515d162def8ab).
Upstream source/tests were inspected, not modified or executed.

- Desktop `apps/desktop/src/AGENTS.md` Bot Mode and
  `src/plugins/hermes-bots/canonical-chat.ts`: owner/title identity, hidden lookup,
  lineage, absence, conflict adoption and background refresh. Wing omits the
  inference-based compatibility fallback.
- `tui_gateway/contracts/sessions.py:120–155,220–245,306–334`,
  `contracts/base.py:13–16`: actual native fields and unknown-key rejection.
- `tui_gateway/methods_session.py:526–550,1202–1234` and
  `hermes_state_titles.py:124–159`: window-free registry, genuine compression tip,
  persistence and transactional title arbitration.
- `tui_gateway/session_workdir.py:410–459` and
  `hermes_cli/web_routers/sessions.py:524–545`: separate pending-hide handling
  and the authoritative profile-stamped detail readback.
- Nearest source oracles include Desktop
  `bot-row-opens-canonical-chat.test.ts`, Agent
  `tests/tui_gateway/test_profiles_list_canonical_session.py`, and generic REST
  title-conflict tests in `tests/gateway/test_session_api.py:730–773`.

Gateway REST is **not** this native contract and remains explicitly unavailable
for canonical opening. Its filtered/windowed listing and generic create do not
establish these guarantees. The native ticket authenticates a full session
identity, not `/v1` operation scopes. Existing native origin, authentication and
platform guards remain; only the traced fixed operations are used.

A running, approval-waiting, submitting, stopping or unreconciled source cannot
be replaced. Unsettled/running targets and unsupported replay cannot be adopted.
These are explicit capability gaps, not positive Bot acceptance. The predecessor's
[native tab exclusion](chat-session-workspace.md#interaction-and-deliberate-desktop-differences)
remains. This does not qualify simultaneous profile sockets, background-profile
streams, native multi-tab run switching, process death, services or notifications.

## Checks and pending live work

This retry restores the approved implementation rather than reimplementing it.
The integration regression was reproduced: the native transport source guard
rejected the new private `hermes_web_bot_chat.dart` part. Its exact path is now
included beside the existing internal parts; no wider product imports are allowed.
The original guard then passed. Current baseline keyboard-only browser focus
handling was preserved when resolving the restoration conflict.

Fresh results: all 16 focused Bot tests and four native read/transport-guard tests
passed. The serialized 94-test native/read/recovery/workspace/touch/export/picker
batch passed 85 cases; nine fixture-bind failures on occupied assigned ports each
passed an isolated rerun within the assigned range. Earlier overlapping fixture
runs are not qualification evidence. Analyzer, localization regeneration and
changed-file formatting passed. Independent read-only review found no
critical/important findings. The task report records exact commands and reruns.

The deterministic web target was rebuilt and all four Chromium workspace journeys
passed at 390/1280px without test retries: REST Bot capability gaps preserve drafts,
ordinary switching and Stop still work, and lost-tab recovery preserves the
sibling session-owned run. The build retains dependency WASM and font warnings;
this is not WASM qualification. Linux-hosted wire fixtures use the Android
forwarded-serve entry; Android-target widget variants exercise compact controls,
capability gaps, draft cancellation and an actual channel history/draft roundtrip.
These are not Android runtime qualification.

```sh
flutter test --no-pub test/features/hermes_chat/bots
flutter analyze
flutter build web --release -t lib/main_e2e.dart
```

Isolated Android `.qa` device/emulator journeys, actual managed SSH, live
unmodified Agent authentication/creation/concurrency, native accessibility/IME
and process-death qualification remain pending. Canonical history inherits the native
lifecycle's 500-message projection and 1 MiB frame bounds; larger forever-chats
remain unqualified and oversized responses fail closed. No Android target was attached;
no live provider/inference permission was used. Revisit this receipt when native
contracts, readback, adoption/replay, recovery or the tab exclusion changes.
