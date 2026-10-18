# Chat Desktop composition

## Scope and reference

Reference: official Hermes Agent Desktop checkout `d923a5eb487a17c0a68801bba9ef0f56c81040a8`, read-only.

- `apps/desktop/src/app/chat/index.tsx`, `ChatHeader`: one session title and optional profile identity.
- `apps/desktop/src/app/chat/composer/controls.tsx`, `ComposerControls`: editor-first composition, model controls and secondary voice disclosure, explicit primary action.
- `apps/desktop/DESIGN.md`: conversation and composer remain primary; one action has one home.

Wing now gives the selected session one heading with its profile/host owner below it. The standalone open-session switcher appears only when there are multiple switchable conversations; the shell-owned session navigation suppresses it. The composer shares an editor-first structure across widths, with model/Stop metadata above the action row, 48-pixel action targets and secondary voice options behind a disclosure. Its bounded scroll viewport keeps expanded options reachable at large text sizes.

This is a composition slice, not a claim of complete Desktop feature or pixel parity. Agent capabilities, request ownership, session restoration, approval authorization and voice lifecycle remain authoritative. Dictation observes the voice master setting even while the secondary options are closed. Text remains available without speech.

## Local validation

Executed with Flutter **3.47.5 / Dart 3.13.4**, as explicitly requested for this delivery, rather than the older 3.44.2 documentation pin. `flutter pub get --offline --enforce-lockfile` succeeded; `pubspec.lock` is unchanged.

- Formatting of the changed Dart files: passed.
- Focused composition, composer accessibility/order/recovery, direct dictation, gateway switching, slash commands and voice lifecycle: **193 tests passed**. The final voice run includes an additional reactive master-setting assertion with the disclosure closed.
- Approval review recovery: passed after revealing the real transcript scroll target and asserting it is hit-testable; no approval decision or ownership assertion was removed.
- `flutter analyze`: one existing warning in `lib/core/hermes/local_discovery/local_hermes_home_discovery.dart:21` (`unawaited_return_in_try_block`). The same warning reproduces on pristine `fc54c07a` with the same SDK and lockfile.
- Broader comparison of `hermes_chat_queued_dialog_intent_test.dart`, `hermes_chat_session_mutation_owner_test.dart` and `hermes_chat_window_test.dart`: candidate **167 passed / 45 failed**, pristine `fc54c07a` **167 passed / 45 failed**, with the same failing test identities. Forty-four failures concern listener-count expectations; the remaining failure concerns dynamic reading-position restoration. These are not waived or weakened by this slice.
- An initial screens-directory run exceeded the tool wait window and ended during shutdown; it is incomplete, not a passing suite receipt. The focused and baseline-comparison runs above completed with observed exit codes.

Widget geometry and semantics were exercised at widths 390, 768 and 1440 with text scales 100% and 200%, including keyboard Stop and retained draft/owner identity. These are Linux Flutter test-renderer checks, not browser visual acceptance, real microphone/acoustic qualification or live Agent generation. Browser review belongs to the integration coordinator; no shared gateway was started.
