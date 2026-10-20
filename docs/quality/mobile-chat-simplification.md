# Compact Chat usability

## Scope

Preserve official Desktop's Chat-home hierarchy and one action/state owner
(`hermes-agent/apps/desktop/DESIGN.md`, Information architecture), adapting
presentation for touch rather than adding product capabilities.

- Below 600 logical pixels, keep secondary header actions in the existing named
  overflow menu, matching the compact shell breakpoint (previously 480).
- Compact composers retain attachment, draft dictation, secondary voice settings,
  Live voice and Send, without a second hands-free microphone or separate Live
  voice row. Draft dictation still requires explicit Send; Live voice retains its
  consent and interruption lifecycle. Stop remains pinned outside scrolling model
  metadata. Wide presentation is unchanged.
- Suppress the introductory voice-tip banner on phones. Voice actions remain
  discoverable by named controls and the existing secondary menu.
- No transport, authentication, capability, session ownership or mutation replay
  behavior changes.

## Verification

Flutter 3.44.9 / Dart 3.12.2 was selected explicitly; the documentation pin is
3.44.2, not available in the observed local SDK inventory. Offline enforced-lockfile
resolution passed with no dependency changes. Node 22.23.3 was used for Chromium.

- New compact-header/composer regressions failed on the original implementation at
  390/480/599 widths, then passed after the changes.
- `flutter analyze --no-pub`: passed.
- Changed-file `dart format --output=none --set-exit-if-changed`: passed.
- Focused `flutter test --no-pub --concurrency=1` union: 140 passed, covering compact
  geometry, 200% text, keyboard traversal, draft retention, session model selection,
  workspace close ownership, disconnect, draft dictation and Live voice lifecycle.
- Broader feature sweep initially reported 1,952 passes and five failures; all
  five affected cases were repaired and passed in the final focused union. A
  subsequent full feature attempt ended during Flutter listener cleanup with a
  missing temporary directory after 464 passes; its zero process exit does not
  establish full-suite completion. No full-suite pass is claimed.
- `flutter build web --release --no-pub -t lib/main_e2e.dart`: passed; existing TTS
  Wasm dry-run warnings remain, not Wasm qualification.
- Compiled Chromium `hermes-smoke.spec.mjs`: 8 passed using system Chromium.
- `flutter build apk --debug --no-pub --target-platform android-arm64 -t lib/main.dart`
  with `WING_ISOLATED_DEVICE_TEST=1`: passed. Existing secure-storage compile-SDK
  warning remains (plugin requests 37; build uses 36).
- Debug QA update installation was observed in Android package metadata. Captures
  did not establish loaded updated Chat: launch capture showed splash and later
  captures encountered other user applications. Device rendering, keyboard-open
  posture and physical voice remain unqualified. No private screenshots ship.

This receipt does not claim full Desktop parity, physical voice qualification,
60-fps performance or signed-distribution readiness.
