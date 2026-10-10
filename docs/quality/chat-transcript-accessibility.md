# Enlarged-text transcript and exact-owner recovery

Task: `VERIFY-CHAT-TRANSCRIPT-ACCESSIBILITY`; card: `t_42880105`; goal:
`CHAT-FIDELITY` (still partial beyond this slice).

## Delivered change

Single and grouped tool-summary titles now wrap instead of forcing one ellipsized
line. The discriminating grouped-title test failed with `maxLines == 1` before
the repair; the final two widget tests cover both title paths. No transport,
approval authority, durable disclosure state, localization or backend contract
was changed. Existing authoritative history replaces ephemeral reasoning and
pending approvals; absent reasoning is not invented during recovery.

The shared timeline builds on the independently approved adaptive reasoning
source from `agent/wing/t_e3589e12` at
`089e25dfa3ebc2c75a71866636d7f79d6a7407c6`. Compared with that source, this card owns
only the two title-wrapping hunks. The local branch retains that approved shared
file content; it does not claim the earlier reasoning changes as new work.
Other dirty files were neither edited nor committed by this card. Qualification
uses the integrated Wing checkout snapshot, not a clean standalone HEAD or a
full-suite/merge-train certification.

## Acceptance evidence

1. At widget `TextScaler.linear(2)`, actual Tab/Enter/Space operate reasoning,
   grouped tools and current Approve once/Deny/Review controls at 390 and 1280
   logical pixels. The canonical user/commentary/tool-group/answer rows retain
   order and viewport bounds after reconnect, screen remount and compact/wide
   return. Single-tool and grouped-tool titles allow wrapping. Final result:
   two tests passed, no Flutter exceptions.
2. Fresh compiled Chromium uses actual browser 200% whole-render zoom, verified
   by DPR 2 and CSS widths 390/1280 (viewport widths 780/2560). Both reconnect
   and reload journeys exercise streamed reasoning/tool disclosures, pending
   controls, authoritative canonical replacement, route remount and layout
   return using keys. Pixel comparisons establish visible focus on the recovered
   tool disclosure and current approval, with keyboard escape/inverse return.
   Semantic overlays and renderer pixels are both checked; zero page/overflow
   errors were observed. Final result: two journeys passed, retries disabled.
3. Owner replacement removes the old approval controls and old focus. Each
   browser journey's receipt has exactly one setup prompt and no decisions or
   Stops throughout recovery/remount. Deliberate current-owner setup then adds
   exactly one prompt and one `POST /v1/runs/run_2/approval` with choice `once`.
   Final per-journey totals: two prompts, one approval, zero Stops, zero creates;
   recovery mutation delta zero. Widget receipts independently match these
   mutation paths and canonical IDs.

Canonical synthetic resource identities:
`synthetic-accessibility`, `canonical-user`, `canonical-commentary`,
`canonical-read`, `canonical-web`, `canonical-answer`, `run_1`, `run_2`.
No live provider, private transcript or real host execution is involved.

## Executed checks

Flutter commands ran in `.dart_tool/transcript-accessibility/wing`, a Wing-only
copy with lib/test/integration_test/web/assets, manifests and analyzer/localization
configuration. Upstream/vendor reference repositories are excluded. Final lib
source byte-comparison against the shared checkout showed no drift.

- `timeout 5m flutter test --concurrency=1 --reporter expanded test/features/hermes_chat/screens/hermes_chat_transcript_accessibility_test.dart` — PASS, 2 tests.
- `timeout 5m flutter analyze` — PASS, no issues.
- `timeout 10m flutter build web --release --no-wasm-dry-run -t lib/main_e2e.dart` — PASS, fresh `build/web`. Existing CupertinoIcons font warning remains; no Cupertino icon support claim is made. JS build only, not Wasm qualification.
- From the shared checkout: `WING_APP_URL=http://127.0.0.1:8977/ CHROME_EXECUTABLE=/usr/bin/chromium NODE_OPTIONS=--max-old-space-size=2048 timeout 8m npx playwright test --config=playwright/transcript_accessibility.config.mjs --workers=1` — PASS, 2 journeys.
- `dart format --output=none --set-exit-if-changed lib/features/hermes_chat/presentation/hermes_chat_timeline.dart test/features/hermes_chat/screens/hermes_chat_transcript_accessibility_test.dart` — PASS.
- `git diff --check -- lib/features/hermes_chat/presentation/hermes_chat_timeline.dart test/features/hermes_chat/screens/hermes_chat_transcript_accessibility_test.dart playwright/tests/regression/chat-transcript-accessibility.spec.mjs playwright/support/hermes_transcript_accessibility_fixture.mjs playwright/support/hermes_transcript_accessibility_server.mjs playwright/transcript_accessibility.config.mjs` — PASS.

Diagnostics were corrected in the dedicated harness: forward traversal avoids
wrapping backward through the entire shell; the composer locator is exact;
resize waits for the new renderer bounds before reacquiring focus; Chromium
zoom screenshot clips are scaled from CSS to pre-zoom viewport coordinates.
The shared keyboard helper and existing reconnect fixtures/reports are unchanged.
A test-only mistaken scroll-coordinate adjustment was reverted after confirming
that the production transcript uses `reverse: true`. The initial build was
interrupted in the prior run; final compilation above completed successfully.
A port collision and an expired bounded fixture server were resolved using
available isolated ports and restarting only this card's server.

Compact observed receipts, check logs and rendered focus crops remain under
`.dart_tool/transcript-accessibility/`; large isolated build/copy outputs are
removed at handoff. The durable source-bound summary is
[the receipt](chat-transcript-accessibility-receipt.json).

## Reproduction

Populate `.dart_tool/transcript-accessibility/wing` from the current integrated
Wing sources listed above (not upstream clones), then run `flutter pub get`, the
widget/analyzer commands and fresh web build inside that directory. Start the
dedicated composition from the repository root:

```sh
PORT=8977 HERMES_E2E_PORT=8978 NODE_OPTIONS=--max-old-space-size=2048 \
  timeout 10m node playwright/support/hermes_transcript_accessibility_server.mjs
```

Check the listener returns HTTP 200, then execute the Chromium command above
from another terminal. Choose a different free port pair if these are occupied;
never terminate someone else's listener. The dedicated config retains fixture
receipts under its ignored observations directory and does not run other suites.

## Evidence boundary

Tested: Linux-hosted Flutter widget runner and headless system Chromium running
the freshly built deterministic Flutter web entrypoint. Shared checkout baseline:
`1afe1307e37ee1ddfa1f7d67ad047509e99c8784`, plus preserved integrated changes
fingerprinted in the receipt. No new API/events, credentials or shadow state.

NOT_CHECKED: native desktop interaction, live Agent/provider execution, physical
screen readers, mobile/Android, Wasm, packaged/signed delivery and full suite or
merge-train compatibility. Recovery history in this fixture intentionally lacks
reasoning; the test verifies its removal, not persisted reasoning restoration.
No broader CHAT-FIDELITY completion or new platform support is asserted.

Questions: none; existing architectural defaults applied.
