# Chat profile picker

Chat's existing **Switch profile** header action now opens a searchable,
keyboard-operable picker over the current Agent channel's already-loaded profiles.
This is a local presentation slice, not a new profile API or backend.

## Interaction

- Search is case-insensitive and literal across display name, stable profile ID
  and model. It does not search descriptions, trim the query or interpret regex.
- The active profile appears first; remaining matches preserve inventory order.
  Hiding the active row does not change Chat ownership.
- Search receives focus on opening. Unmodified ArrowUp/ArrowDown move the
  highlighted result, clamped at either end; Enter chooses that exact result.
  With no matches, Enter does nothing. Escape dismisses from any picker control.
- Native Tab/Shift+Tab traverse search, the labeled **Clear profile search**
  action, result rows and **Manage profiles**. Native text-editing shortcuts,
  selection modifiers and composition remain outside result-key handling.
- Highlighted/focused rows scroll into view without animation. The active row
  has a radio indicator and selected semantics; keyboard highlighting has a
  chevron and semantic hint, not only a color change.
- Clear restores all loaded profiles. **No matching profiles** is different
  from **No profiles available** when inventory becomes empty while open.
  The existing header hides the trigger when initial inventory is empty.
- **Manage profiles** dismisses the picker and uses the existing `/profiles`
  route. It does not implicitly select a profile.

Opening, searching, clearing, dismissal and management navigation do not submit
profile/session/message/model/approval operations from this picker. The destination
Profiles screen retains its own existing loading behavior. Explicit result
activation alone enters the existing `_switchProfile` flow; its pending/error
behavior and gateway-contact synchronization remain authoritative. There is no
optimistic selected-profile update, automatic retry or mutation replay here.

## Ownership and lifetime

Query and highlighting are volatile and reset when reopened. Same-owner inventory
updates refresh matches without discarding the query. Admission requires the
rendered channel/endpoint/profile to remain connected and settled. The open
picker captures channel, endpoint, profile and gateway contact; synchronous
listeners latch ownership loss, including same-frame loss/restoration.

Cached rows cannot select a removed target, select into a replacement channel,
navigate after owner loss, or activate after dismissal/disposal. Selection is
rechecked after modal completion. Repeated cached activation cannot pop the
underlying Chat route. All modal inventory/listener state is released on exit.

No Agent domain state, credentials, global CLI profile activation, endpoint,
backend contract, shared fake or state-management contract was changed.

## Desktop fidelity and limits

The read-only reference is
[Desktop ProfileSwitcher](../../hermes-desktop/src/renderer/src/screens/Layout/ProfileSwitcher.tsx),
especially its name/ID/model search, active-first ordering, arrow/Enter/Escape
handling and management action. Wing keeps the existing adaptive bottom sheet
and explicit Agent selection flow rather than Desktop's optimistic global
activation. Query whitespace remains literal in Wing.

Running/stopped grouping is deliberately deferred: absent/default gateway
metadata is not evidence of runtime health. Global Ctrl/Command+P, footer
placement and shell redesign are outside this slice. See the
[client ADR](../adr/client.md) and [API/state ADR](../adr/api-and-state.md).

## Executed checks

Task `t_3ea005fc` exercised production `HermesChatScreen` in the Linux Flutter
widget runner at 390 and 1280 logical pixels, including 200% text scaling,
reduced motion, semantic selection, keyboard-only picker entry/navigation,
scroll-to-highlight, literal matching, no-match/empty handling, clear/reopen,
same-owner inventory updates, delayed/rejected selection and stale controls.
The `/profiles` navigation test uses GoRouter with a deterministic destination,
not the live Profiles backend.

Executed commands:

```sh
flutter gen-l10n
dart format lib/features/hermes_chat/screens/hermes_chat_screen.dart lib/features/hermes_chat/widgets/chat_profile_picker.dart test/features/hermes_chat/screens/hermes_chat_profile_picker_test.dart
flutter analyze
flutter test --no-pub --concurrency=1 test/features/hermes_chat/screens/hermes_chat_profile_picker_test.dart
flutter test --no-pub --concurrency=1 test/features/hermes_chat/screens/hermes_chat_gateway_switch_test.dart
```

The unchanged-picker RED failed only on the absent search control at both widths.
Final focused tests: 46 passed. Existing gateway-switch neighbors: 75 passed.
Final analyzer: no issues. Scoped whitespace and local-link checks are recorded
with the baseline-relative diff, final hashes, raw RED/GREEN logs and command
exits in the profile-local `autogoal/chat-profile-picker/` evidence directory.
Early expanded-test failures and the single analyzer style correction are retained
there; they are not passing evidence.

This does not qualify a physical screen reader, native desktop interaction,
compiled browser, Android, live Agent/provider generation or the full native/live
daily-workflow milestone. Existing native authentication, exact runtime pair,
passive-resume and browser-restoration qualification gates remain unchanged.
No build, service, installation, credential access or real generation was run.

### Submitted selection feedback ownership

Task `t_34071b35` reproduced obsolete failure SnackBars after a submitted public
picker selection: replacing the channel or losing/restoring its connection,
endpoint or unrelated profile before delayed rejection reported against the
mounted replacement owner. All four cases reproduced at 390 and 1280 pixels.

The switch now captures channel, endpoint and gateway contact, synchronously
latches unrelated ownership loss, and only reports failures to that operation's
current owner. The selected target profile/contact is an expected transition,
not unrelated ownership loss. A current-owner rejection remains actionable;
there is no optimistic state, automatic retry or replay.

Picker observers end when the closing route is removed rather than waiting for
selection settlement. Switch observers end on settlement or screen disposal;
pending-flag cleanup belongs to that operation. The closing-route admission latch
and existing rapid-entry behavior are retained.

The final public-pointer regression is unchanged between baseline RED (10 failed,
4 passed) and repaired GREEN (14 passed). It also checks unchanged replacement
state, fresh open/selection, successful target transition, current-owner errors,
operation listener release and explicit-selection-only mutation counts. Listener
assertions are baseline-relative: the existing screen channel observer was found
retained after disposal and is outside this repair. This is not a claim that all
Chat listeners are leak-free.

Commands ran in `.task-evidence/t_34071b35/project`, a complete isolated copy of
the Flutter source/test graph and manifests because canonical Flutter assets were
occupied. `flutter analyze` passed; the profile-picker, profile-picker-open-order,
gateway-switch, model-picker-open-order and model-authority targets passed together
(139 tests). Exact commands, source hashes, RED/GREEN logs and acceptance mapping
are in `.task-evidence/t_34071b35/receipt.md`.

Evidence is Linux Flutter widget-runner only. Native GTK, compiled browser, live
Agent/provider, Android, physical accessibility and packaging remain
**NOT_CHECKED**. No backend contract, shared fake, Agent reference or runtime was
changed, and existing authentication and daily-workflow qualification gates remain.

### Rapid public entry and dismissal

Task `t_6329b9bf` reproduced four stacked picker routes at both 390 and 1280
logical pixels by using Tab to reach the header, then Enter-down and three
key-repeat events before the next frame. Holding Enter through active-row
dismissal also reproduced a second route during the reverse animation. Pointer
hit testing did not reproduce stacking in the checked sequence.

Chat now admits one profile picker at a time, retaining the presentation latch
until the closing route is removed. Ignored activations are not queued. The
existing owner fences and explicit profile-switch flow remain unchanged.
The unchanged final regression passes with offstage-inclusive picker/search
counts, ordinary dismissal, fresh reopen, active/different profile selection,
management navigation and same-frame disconnect/restoration controls. The test
harness enables animation for these cases without changing existing defaults.

Evidence and exact RED/GREEN commands are in
`.task-evidence/t_6329b9bf/receipt.md`; tests use the production Chat screen with
deterministic channels and a fixture management destination. This is Linux widget
runner evidence only. Native desktop, browser, Android, live runtime, packaging
and physical keyboard/screen-reader behavior remain **NOT_CHECKED** by this task.
