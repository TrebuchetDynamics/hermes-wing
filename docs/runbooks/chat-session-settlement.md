# Chat session create/open settlement ownership

Chat's public **New Session** and session-row **Open** actions retain their
original channel, connected origin, selected profile and active contact for
caller-side settlement. Channel/provider/contact loss, disconnect, or pending
profile selection invalidates that lifetime synchronously and permanently.
Returning to the original owner before the next frame does not revive it.

An obsolete rejection cannot show a SnackBar in replacement Chat. An obsolete
create completion cannot refresh the replacement contact. An obsolete open
completion cannot focus the replacement composer. Open retains its lifetime
observer through the scheduled desktop focus callback and rechecks both owner
and intended active session inside that callback. Observers are removed on
settlement and Chat disposal, even when the channel future is still pending.
These are operation-added listeners, not a repair of unrelated screen listeners.

The active session is deliberately not part of the owner snapshot: create clears
its previous selection and selects the created session, while open selects its
intended row. These legitimate transitions, current-owner errors, and a fresh
explicit retry still work. Existing restoration admission and
[rename/branch/delete confirmations](chat-session-mutation-intent.md) are unchanged.
No backend mutation, selection-generation, cancellation, replay, capability or
model-authority contract changes are introduced.

## Production contract characterization

`HermesApiChannel.createSession` delegates to the sessions extension. Its create
request catch rethrows even after the profile request guard becomes obsolete
(`lib/core/hermes/channel/api_channel/hermes_api_channel_sessions.dart`, create
catch). Thus a stale create rejection can reach Chat's caller; the old mounted-only
catch was insufficient. The success path can also resolve normally after its
response-owner guard refuses a state update, which previously refreshed whichever
contact was current.

The normal production Open history catch already suppresses obsolete errors via
`canAcceptHistory()`. The test's production-style Open mode preserves that
suppression; defensive rejecting-channel cases characterize the shared caller,
not an alleged backend exploit or a requested backend change. A detached old
channel can also legitimately resolve with its selected target while the provider
now presents another channel. Checking only the old channel's active session was
not sufficient to focus current Chat.

## Executed verification

Task `t_cd455c23` used the deterministic Flutter widget runner on Linux with
Flutter 3.44.2 / Dart 3.12.2. Complete source-identical `lib`, `test`,
`integration_test`, assets, tools and Flutter manifests were copied to
`.task-evidence/t_cd455c23/project` to keep read-only reference checkouts out of
analysis. No new runtime module, dependency or packaging manifest was added;
production changes remain imported parts of `HermesChatScreen`.

Commands from that isolated project:

```sh
flutter test test/features/hermes_chat/screens/hermes_chat_session_settlement_owner_test.dart
flutter test test/features/hermes_chat/screens/hermes_chat_session_mutation_owner_test.dart test/features/hermes_chat/screens/hermes_chat_gateway_switch_test.dart test/features/hermes_chat/screens/hermes_chat_session_restoration_test.dart test/features/hermes_chat/screens/hermes_chat_profile_switch_owner_test.dart test/features/hermes_chat/screens/hermes_chat_session_picker_test.dart
flutter analyze
```

Results: 102 settlement-owner cases passed; 249 named neighboring cases passed;
analyzer found no issues. Changed-file `dart format --output=none
--set-exit-if-changed` and `git diff --check` also passed. The final identical
oracle was replayed against captured pre-repair production bytes: exit 1, with
stale SnackBars, unrelated contact refresh and replacement focus failures, plus
missing operation-lifetime observer failures. That replay had no Flutter debug
invariant errors; the production-style obsolete Open suppression controls passed.
Initial harness iterations exposed the need to reset the test platform override
before Flutter's invariant check and to supply an authoritative active replacement
session before asserting draft preservation (a null selection has no stored draft).
These corrections were task-local and did not weaken the final oracle.

Tests use public compact-sheet (390px) and wide-rail (1280px) actions, delayed
channel futures, provider replacement, profile/origin/contact loss and same-frame
loss/return, disconnect/reconnect, and Chat unmount. They assert replacement
state/transcript/draft/focus preservation, no incidental sends or mutations,
current-owner actionable errors and explicit fresh retries, intended selection
success, and operation-listener cleanup relative to the mounted baseline.
Directory/contact and provider-return fakes retain the existing transport response
generation fence; that fence is not supplied by the caller repair. A separate
post-settlement/pre-frame test uses an already successful Open to isolate the
queued focus callback's own ABA fence.

Source fingerprints, baseline-relative patch, command logs and graph equality
receipt are in `.task-evidence/t_cd455c23/`. Unrelated dirty-worktree and predecessor
content are preserved. The local task-branch snapshot includes pre-existing dirty
content in edited files; only the baseline-relative patch is attributed to this task.

NOT_CHECKED: native desktop interaction/build/package, compiled browser, live
Agent/provider, Android/device, physical accessibility/screen reader, full
canonical suite, full daily-workflow/parity, deployment and release acceptance.
No upstream edits, live credentials or requests, push, merge or deployment occurred.
Independent same-card review run 236 approved this bounded repair at local branch
`agent/wing/t_cd455c23`, commit `4cf3ea299e214f852d9472bf6c96b0e1fe155e55`.
The reviewer independently passed all six named suites (351 tests), analysis,
changed-file formatting, whitespace and six local links, and verified source and
commit fingerprints. Receipt: `.task-evidence/t_cd455c23/independent-review.md`.
That approval does not qualify the NOT_CHECKED targets above.

Authority: [client ownership](../adr/client.md#transport-qualification) and
[API and state](../adr/api-and-state.md).
