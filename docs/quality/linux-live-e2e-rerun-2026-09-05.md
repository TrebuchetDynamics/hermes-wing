# Native Linux E2E and screenshot rerun — 5 September 2026

This fresh run uses the native GTK Flutter application, the production route tree,
a real isolated Hermes Agent, real Wing Link pairing and credentials, the serving
OmniRoute instance, and an ephemeral GNOME keyring. It is driven with Flutter's
native integration-test runner under Xvfb. No canned model response or fake
service is installed in the visual tour.

Open `test-results/linux-live-visual-2026-09-05-rerun/index.html` for the latest
filterable screenshot gallery. The same directory contains original PNGs,
`manifest.json`, and `linux-ui-review.zip`. Previous evidence is preserved in
`test-results/linux-live-visual-2026-09-05/`.

## What this rerun adds

- Fresh light/dark captures of all 14 production routes, including current
  Settings, Diagnostics, and Gateway worktree changes.
- Profile rename through the actual UI, with a real Wing Link inventory assertion.
- Existing-profile editor and rename draft captures.
- Typed profile-deletion confirmation, both empty/disabled and matching/enabled;
  cancelled before the subsequent approved backend cleanup operation.
- Voice preferences toggled and asserted, then restored before chat. This proves
  preference controls, not microphone, speech, or speaker operation.
- Recognition-language menu and lower gateway trust controls.
- Full rerun of chat send/reply, session dialogs, search, connection recovery,
  catalog autocomplete, profile create/cleanup, and tools filtering.

## Coverage and limits

The Agent advertises 28 operations: chat/responses, models/model options,
sessions and their lifecycle, runs/events/status/steer/stop/approval,
artifact upload/download, browser-control registration/connection, health,
skills, and toolsets. An advertised operation is not automatically a tested
feature; screenshots and test receipts below are the evidence boundary.

Providers administration and Schedules remain unavailable on this runtime.
Persona requires an authoritative selected profile. The profile catalog and
OmniRoute discovery work through reviewed Wing Link setup operations; fresh
OmniRoute credential provisioning remains unsupported. New cloned profiles are
not automatically enrolled for chat in this run. The real provider reply comes
from the already enrolled isolated profile.

The gallery records visible unsupported and unavailable states. It does not
claim successful schedule/provider/persona mutations, OS file selection, artifact
transfer, browser control, local installation/adoption, service update/rollback,
physical display/input, camera scanning, microphone recognition, or audio output.
No real pairing codes, provider secrets, or private chat history are captured.
Manual-connection credential fields are cleared before taking screenshots.

The broad native regression inventory now includes all 88 current test files
under `test/app`, `test/features`, `test/router`, and `test/shared`. Three omitted
files were added: native handoff subscriptions, enrollment recovery, and profile
catalogs. It uses deterministic service/storage seams.
It is additional UI and behavior evidence, not a substitute for the live tour.

## UI review

The [previous screenshot review](linux-live-visual-review-2026-09-05.md) lists the
main improvements: consistent profile/model identity, useful next actions on
unavailable screens, desktop profile-editor sizing, inventory navigation, session
metadata reconciliation, and clear enrollment/readiness after creating a profile.
The new captures make the profile edit/delete and voice/trust interactions
reviewable as well. Inspect the latest originals before implementing visual fixes;
other worktree changes may already address an earlier screenshot.

## Verification notes

The first expanded run exposed a test-driver race after successful profile
rename: the next action ran before the prior sheet finished closing. The driver
now waits for completion and taps only hit-testable controls. The failed attempt
is retained in the local logs; its mislabeled confirmation capture is replaced
by the final rerun. No production assertions or capability gates were weakened.

## Screenshot results

The final live tour passed in 2m55s and its wrapper exited successfully. It
produced **80 distinct screenshot states across all 14 routes**, including
19 light and 19 dark route/scroll views. All 80 PNGs decoded successfully in
Chromium, and the gallery filter returned the expected dark captures.

The post-deletion screenshot in this rerun shows only the default profile: the
previously observed stale card did not recur after waiting for UI completion.
Treat that earlier observation as timing-sensitive, not a confirmed permanent
profile-cache defect. The new typed deletion screenshots show the disabled and
enabled destructive action correctly. The revocation dialog is captured and
cancelled; the paired device remains available for the rest of the live checks.

## Broad native regression results

`xvfb-run -a flutter test -d linux integration_test/linux_feature_regression_test.dart --reporter expanded`
exercised **1,016 cases in 7 minutes: 1,014 passed and 2 failed**.

1. **Intermittent transcript following:** `streaming preserves manual history
   position until the user sends` observed a 5-pixel offset instead of the expected
   bottom position (within 1 pixel). The focused widget test passed, and two
   isolated native reruns passed unchanged. This is not evidence of a fixed root
   cause or a completely green full run.
2. **Unresolved native catalog Retry:** `profile setup retries catalog, offers
   unconfigured provider and clears stale model` consistently fails in the native
   runner. Instrumentation showed the Retry tap did not invoke the second loader
   call (`attempts=1`); the field had focus but correctly had zero options. The
   same six catalog tests pass in the widget runner. Waiting for settling, making
   the control visible, and matching the Linux viewport did not resolve it.
   Experimental changes and instrumentation were removed; the original assertions
   remain, and the test is retained in the expanded native inventory. The live
   tour's successful catalog/autocomplete path does not qualify this retry path.

The full native suite is therefore **not green**. Neither failure is hidden by a
skip, a relaxed assertion, or a capability change. No production fix is claimed
for these two findings.

## Additional live-service and static checks

`bash scripts/run_linux_live_e2e.sh` exited successfully with all four native
live-service flows passing:

- Actual provider reply through the UI.
- Session create/update/delete, fork, inventories, and reconciliation.
- Steer and stop an accepted run without replay.
- Real Wing Link catalog (55 provider entries), serving OmniRoute discovery,
  autocomplete selection, profile creation/rename, and approved deletion.

`flutter analyze` reports no issues. `go test ./...` passes for Wing Link.
The focused chat-disposal tests pass (2 cases), the focused scrolling widget test
passes, and all 6 catalog widget tests pass. Formatting, shell syntax, gallery
image/filter validation, and `git diff --check` pass.

Only test coverage and the visual harness were expanded during this rerun; no
production change is claimed for the two native regression findings. Existing
unrelated worktree changes were retained. The isolated services and credentials
were cleaned up after verification; the user's OmniRoute service remains running.
