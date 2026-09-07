# Native Linux live-service visual review — 2026-09-05

This review runs the production Flutter route tree in the native Linux GTK
application under Xvfb. It uses real Hermes Agent, an acknowledged real Wing Link
pairing, GNOME secure storage, and the serving OmniRoute instance. Agent state,
profiles, and synthetic chat sessions are isolated from the user's normal Agent
home. No service fixture or canned model response is installed.

The screenshot gallery is local and intentionally excluded from Git:
`test-results/linux-live-visual-2026-09-05/index.html`. The same directory contains
original PNG files, `manifest.json`, and `linux-ui-review.zip`. Open the HTML file
and filter by route, theme, or feature. Each thumbnail links to original pixels.
The manifest is the precise capture inventory; a screenshot records a visible
state, not proof that every operation on that screen passed.

## Coverage

All 14 registered production routes are captured in light and dark themes:
chat, Profiles, Providers, Tools, Schedules, Office, Persona, Gateway, Settings,
Voice & speech, Diagnostics, enrollment, manual connection, and local setup.
Long content also has lower-page captures. Feature captures include real catalog
suggestions and OmniRoute discovery, directory browsing, theme choices, voice
configuration, pairing entry/paste, gateway actions and cancelled removal,
synthetic chat draft/send/reply, session actions, search, disconnect/reconnect,
and skill/toolset search recovery. The profile lifecycle also captures native UI
creation, real Wing Link rename, and locally approved deletion followed by a
production-list capture; renaming/deletion in this sequence use the real API.
The immediate post-deletion screenshot still shows the removed row: it is
evidence of stale UI, not proof that the list reconciled. Newly cloned profiles
show Not enrolled / Gateway off and disabled Chat; chat was exercised on the
already enrolled isolated profile, not on the new clone. The manifest records exactly which optional
controls were reachable on this runtime.

Providers administration and scheduled jobs are unavailable on this Agent's
advertised API. Persona asks for an authoritative selected profile; its editor
is not qualified here. OmniRoute is discovered as serving and requiring
authentication; fresh OmniRoute credential provisioning remains unsupported.
These are visible product limitations, not successful mutation tests.

Local setup detects the installed Agent; installation/adoption was not executed
against the user's installation. Pairing screens contain no live codes. The paste capture shows the real
empty-clipboard validation state, not a successful pairing exchange. Manual
connection credentials are cleared in the unsaved form before capture. Only
synthetic QA chat appears in screenshots. Public QA host fingerprints and opaque
device identifiers are not bearer credentials.

This does not qualify physical display/input, microphone, speech recognition,
audio playback, camera/QR scanning, OS file chooser interaction, remote TLS/VPN,
provider secret provisioning, gateway update/rollback, or unsupported Agent
administration. The earlier [live E2E report](linux-live-e2e-2026-09-05.md) records
separate live session/profile lifecycle and native regression evidence.

## UI improvements supported by the screenshots

1. **Make profile and model identity consistent.** Profiles shows `default` and
   the configured model, while the persistent status bar says `Profile Not loaded`
   and `Model hermes-agent`. Office calls the same connection `Endpoint contact`.
   Explain endpoint-only identity and runtime aliases, and surface authoritative
   profile/model details wherever they are actually available.
2. **Give unavailable screens a useful next action.** Providers and Schedules
   devote most of the window to a lock and capability explanation. Provider setup
   is available elsewhere through reviewed Wing Link operations. Link to that
   supported setup path and distinguish runtime catalog access from administration.
3. **Fit the profile editor to desktop.** The tall bottom sheet hides its Create
   action below the initial viewport. Provider suggestions cover the remaining
   fields and partially clip the last visible option. Use a bounded scrolling form
   with a persistent action area and predictable autocomplete height.
4. **Improve inventory navigation.** Fifty-three skills precede toolsets in one
   long column. Give the two inventories visible section navigation and preserve
   search context. Long metadata rows need stronger name/description hierarchy.
5. **Reduce duplicated headings and empty space.** Profiles repeats its heading;
   Office presents a tiny endpoint card in an otherwise empty desktop page.
   Use the space for actionable current context without inventing Agent state.
6. **Clarify setup and desktop language.** Manual connection includes technical
   transport compatibility wording; local setup has no obvious return action in
   its captured header. Voice guidance uses touch-oriented wording on Linux.
   Lead with the user's next step and show technical details on demand.
7. **Reconcile session metadata after replies.** The transcript shows two
   messages and run token usage, but the session rail and details sheet still
   report zero messages/tokens. Distinguish delayed metadata from actual zero
   values and reconcile authoritative session summaries after completion.
8. **Complete the new-profile journey.** The clone appears with disabled Chat,
   Not enrolled, and Gateway off, without an obvious next action. After an external
   approved deletion, the immediate profile view still retains its card. Make
   enrollment/readiness actionable and review profile-inventory invalidation.
9. **Keep diagnostics and trust actions discoverable.** Diagnostics export and
   lower Wing Link trust controls require scrolling at the default window size.
   Preserve a visible route to these actions and avoid identity-heavy strings
   dominating the normal health overview.

## Bugs found during the real tour

- Leaving chat notified the shell's `ValueNotifier` during route disposal,
  producing `setState() or markNeedsBuild() called when widget tree was locked`.
  Restoration now occurs after the frame. A regression retains the shell listener
  while unmounting chat and verifies navigation is restored without an exception.
- Clearing inventory searches produced `RenderBox was not laid out` in Flutter's
  selection delegate. Two variable-height inventory sections were children of a
  lazy `ListView`; they now share an eagerly laid-out scroll column. Text selection
  remains enabled. Tests cover long inventory filtering, 200% text scale, and the
  existing inventory operations under the production selection wrapper.

## Reproduction

Supply protected manifests from an isolated Agent and acknowledged Wing Link
pairing. Never commit manifests or embed their contents in shell commands.

```bash
# Set WING_LIVE_PROFILE_MANIFEST, WING_LIVE_LINK_MANIFEST,
# WING_LIVE_LINK_BINARY and the isolated Wing Link service environment.
WING_VISUAL_OUTPUT="$PWD/test-results/linux-live-visual" \
  bash scripts/run_linux_live_visual.sh
python3 scripts/build_linux_visual_gallery.py test-results/linux-live-visual
```

The runner creates a separate D-Bus session, Xvfb display, and ephemeral native
keyring. The harness drives actual Flutter controls and captures the rendered
application boundary. `WING_VISUAL_APPEND=1` adds feature captures to an existing
manifest without repeating the light/dark route tour. Capture artifacts remain
local and ignored. The profile cleanup approval applies only to the profile
created by this test on its isolated Wing Link instance.

## Validation receipts

- **98 original screenshots**, 14 unique production routes, light and dark
  coverage, plus repeated feature evidence from the final profile lifecycle run.
- `flutter test -d linux integration_test/linux_live_visual_test.dart --reporter expanded`:
  full route/feature tour passed (2m34s); the extended profile/feature run passed
  (1m29s). The initial two attempts failed on the UI exceptions described above.
- `flutter test test/features/tools/tools_screen_test.dart test/features/hermes_chat/screens/hermes_chat_disposal_test.dart test/router/app_router_transitions_test.dart`:
  **27 passed**. An intermediate 200% text-scale test used a stale `ListView`
  finder; it now targets the actual scrollable and passes.
- `flutter analyze`: **no issues found**.
- Changed Dart files: `dart format --output=none --set-exit-if-changed`: passed.
- `bash -n scripts/run_linux_live_visual.sh` and `git diff --check`: passed.
- Gallery opened in Chromium: 98 cards, filtering to dark showed 19 captures.
  Gallery/ZIP builder verifies that each referenced original image exists.
- The final native test succeeded, but its shell wrapper returned nonzero when
  D-Bus removed a portal mount between checking and unmounting it. Cleanup now
  tolerates that race only when the mount is actually gone. The corrected cleanup
  was run successfully against the leftover owned keyring directory; the entire
  native tour was not repeated after this shell-only correction.

The isolated Agent/Wing Link processes were stopped. Their runtime state,
credentials, pairing state, and temporary keyring were removed. The user's
OmniRoute service remains active. Existing unrelated worktree edits were retained.
This scoped visual review did not repeat the entire repository complete gate;
Go/browser product code was not changed in this slice.
