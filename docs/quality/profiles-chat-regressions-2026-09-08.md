# Profile setup and chat regressions — 2026-09-08

## Findings and fixes

1. **Delayed saved-host restoration stranded guided setup.** Profiles previously
   tried loading Wing Link inventory only on its first frame. The screen now
   observes changes to the selected host, its enrollment, and native profile
   capability availability. Setup opens once when the inventory is ready.
2. **Inventory errors had no visible recovery on disconnected screens.** Early
   returns bypassed the error banner. Errors now remain visible with Retry.
   Unrelated directory notifications do not retry failed requests automatically.
3. **Revoked or replaced enrollment could leave stale profile controls visible.**
   Inventory ownership includes the selected gateway, management origin, credential,
   pin, and native capability state. Changing that identity invalidates the list.
   This is ephemeral client read state, not a new profile/domain authority.
4. **Failed enrolled-profile connections still opened Chat.** Profiles now checks
   both connection success and the selected enrolled endpoint before navigation,
   retaining the profile screen and showing a bounded error on failure.
5. **Canonical history duplicated pre-tool assistant text and could overwrite
   commentary with the final answer.** Final text now reconciles with the final
   assistant segment of the current user turn. Equivalent local segments defer to
   canonical messages within that same turn; distinct commentary, activity, and
   repeated replies from earlier turns survive.

The delayed-setup, identical pre-tool answer, and failed-chat-opening regressions
were observed failing before their fixes. Separate coverage preserves earlier
identical replies and canonical commentary/final-message identities. The setup
retry test also verifies that revocation clears the visible inventory without
connecting chat or exposing raw errors.

The read-only Agent reference confirms that completion can carry an authoritative
per-turn transcript (`api_server_openai_routes.py`, `_turn_transcript_messages`)
and run completion is tested in `tests/gateway/test_api_server_runs.py`. No Agent
code, compatibility operation, protocol field, or permission was added.

## Validation

- Focused channel, Profiles, and profile-editor run: **341 tests passed**.
- `flutter test --concurrency=1`: **1,645 tests passed**.
- `dart format --output=none --set-exit-if-changed lib test integration_test`:
  no changes required.
- `flutter analyze`: no issues.
- `(cd wing_link && go test ./...)`: passed.
- `npm audit`: zero vulnerabilities.
- `git diff --check`: passed.
- `flutter build apk --release`: passed, universal APK, approximately 64.6 MB.
- `flutter build web --release -t lib/main_e2e.dart`: passed through the E2E runner.
- `npm run web:e2e`: **46 passed, one live-host test skipped**, Chromium.
- `npm run readme:assets`: regenerated against a separate local fixture using
  the same current web build.

Physical Android, live paired-host, microphone, and acoustic acceptance require
separate qualification. Deterministic tests and builds do not establish those
claims. Stable submission identity and the remaining voice UX inventory are
separate work.

The subsequent [profile and voice UI pass](profile-voice-ui-2026-09-08.md)
addresses active-profile labeling, clone form overflow, voice recovery, and
separate capture/playback controls with additional regression evidence.
