# Voice capture and profile rename regressions

The capture regression reproduces `notListening` arriving before the final
transcript. Wing now waits for `done` and accepts completed recognition when the
engine reports it stopped. Silence produces the existing no-transcript outcome.
The suite retains adversarial duplicate-terminal and stale-result cases.

A successful Wing Link rename now reconciles the returned profile identity with
the independently enrolled Agent route on the same reviewed host. Credentials,
Wing Link identity, and TLS pin are preserved. Chat reconnects when reachable;
if Hermes stopped its gateway, the confirmed new identity remains visible with
offline health. Old session previews are discarded. Agent API edits also refresh
the Chat directory after closing the editor.

Validation on Linux:

```bash
flutter test test/features/voice/services/speech test/features/hermes_chat/voice test/features/hermes_chat/gateways/hermes_gateway_directory_test.dart test/features/profiles/profiles_screen_test.dart test/features/providers
flutter analyze
dart format --output=none --set-exit-if-changed lib/features/voice/services/speech/speech_to_text_voice_capture_service.dart lib/features/hermes_chat/gateways/hermes_gateway_directory.dart lib/features/profiles/screens/profiles_screen.dart test/features/voice/services/speech/speech_to_text_voice_capture_service_test.dart test/features/hermes_chat/gateways/hermes_gateway_directory_test.dart test/features/profiles/profiles_screen_test.dart
git diff --check
```

Results: 271 tests passed; analysis found no issues; formatting and whitespace
checks passed. The initial normal-recognition regression failed before the fix.
A widget regression exercises Wing Link rename through the editor and checks the
new Chat route and active selection. Directory tests cover both reachable and
stopped gateways after rename. Provider capability and ownership tests pass.

Limits: these are deterministic regression tests, not physical microphone or
live provider qualification. This change has not been installed on the phone.
It does not restart a host gateway or infer mappings for profiles renamed before
this fix, or renamed outside Wing. Existing-profile provider edits still require
the advertised Agent APIs; Wing Link compatibility does not enable them.
