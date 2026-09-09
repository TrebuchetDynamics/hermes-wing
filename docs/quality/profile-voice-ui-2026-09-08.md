# Profile setup and voice UI — 2026-09-08

## Reference study

Read-only Desktop sources: `src/renderer/src/screens/Agents/Agents.tsx`
separates profile creation, cloning, and chat actions;
`src/renderer/src/screens/Chat/ChatInput.tsx` explicitly labels recording and
stopping. Wing applies these interaction principles through its existing Flutter
channel and voice controller. Desktop's local IPC is not a remote API contract.
The reference's `lat` command is unavailable; live source and the code graph were
used instead.

## Reproduced and corrected

- A disconnected Wing Link inventory marked its first profile selected. **Active
  chat** now requires a connected Agent endpoint and the matching enrolled profile;
  managing a host does not select a chat profile. A regression also opens another
  enrolled endpoint on the same host, then disconnects without removing inventory.
- A long clone-source name overflowed the 320-pixel setup form by 842 pixels.
  The selector now stays within its available width and truncates long labels.
- Mute while idle changed controller state without notifying the UI. The output
  action now updates immediately while capture remains active.
- Foreground recovery retained a notice falsely describing the app as currently
  backgrounded. The notice now describes the past interruption and microphone-off
  state. Text-only backgrounding does not produce a voice warning.
- Generic voice failures now offer **Resume hands-free** and **Continue in text**.
  Resume uses the existing capture and speech teardown barriers and requires an
  explicit tap; foreground return does not reopen capture.
- Output, microphone, and whole-session actions are visible, labeled controls.
  **Stop reply** stops playback; **End hands-free listening** stops capture;
  **End voice session** stops both. The former microphone pause label overstated
  the controller's support for a resumable microphone substate.
- Simultaneous capture and playback display both **Listening for interruption**
  and **Playing assistant reply**. Only the status group is a voice live region;
  partial transcript updates remain readable without reannouncing the whole panel.

Setup displays naming requirements and explains inherited provider/model settings.
Chat labels its host, names the selected profile in the composer, and keeps the
composer available for drafting during standalone playback. **Dictate a draft**
is reachable in the composer menu as well as through microphone long press; both
paths leave the transcript unsent for review.

No upstream checkout, protocol, compatibility operation, credential handling,
Project authority, or capability gate changed. No workspace is inferred from a
profile's name or conversation prose.

## Qualification limits

These are deterministic Flutter and browser journeys. Physical Android, live
paired-host setup, microphone permissions, speech recognition, acoustic quality,
and screen-reader announcement timing still need target-device qualification.
Stable submission identity and authoritative Project context remain separate work.

## Validation

- `flutter gen-l10n`: regenerated localization successfully.
- `dart format --output=none --set-exit-if-changed lib test integration_test`:
  350 files, no changes required.
- `flutter analyze`: no issues.
- Focused `flutter test` over `test/features/profiles`, the voice lifecycle and
  gateway-switch screen tests, and `test/features/hermes_chat/voice`:
  **224 passed**.
- `flutter test --concurrency=1`: **1,651 passed**.
- `(cd wing_link && go test ./...)`: passed.
- `npm audit`: zero vulnerabilities.
- `flutter build apk --release`: passed; universal APK, 64,580,671 bytes.
  SHA-256: `caf7df408dc03e69bb4229d3c46011a7ae817068ff02c51a925c08cf931936c4`.
- `npm run web:e2e`: built `lib/main_e2e.dart` for release and passed the first
  three suites. The TTS suite passed 18 cases and exposed one outdated selector:
  the session-change notice is now an accessible group with recovery buttons,
  rather than a plain text node. The corrected test also asserts both buttons.
  Its targeted rerun passed, as did fresh-process runs of the remaining lifecycle,
  live-host, smoke, and screenshot specs against the same build. Aggregate:
  **46 passed, one live-host case skipped**, Linux Chromium.
- `README_ASSET_BASE_URL=http://127.0.0.1:8871/ npm run readme:assets`:
  regenerated screenshots against a separate deterministic fixture.
- `git diff --check`: passed. Upstream reference checkouts were not modified.

The browser reruns used `WING_APP_URL=http://127.0.0.1:8871/ npx playwright test
--config=playwright.config.mjs`, with the failed session-change case selected by
`--grep 'Agent speech stops when starting a new session'`, then each remaining
spec in a separate process. No application change was needed after the full
Flutter suite and APK build; the browser assertion was updated to the new
accessible structure.
