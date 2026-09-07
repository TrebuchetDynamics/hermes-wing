# Linux minimalist UI review — 5 September 2026

This pass reviewed the 83 native Linux captures from the preceding real Agent,
Wing Link, and OmniRoute tour. The direction is a compact, legible workspace:
neutral surfaces, clear action names, fewer passive badges, and visible recovery.

## Findings and changes

| Screenshot finding | Change | Preserved behavior |
| --- | --- | --- |
| The primary destination says “Hermes”, which does not explain its purpose to new users. | Label it “Chat” and use a conversation icon. | Existing route, adaptive navigation and keyboard behavior. |
| The conversation title competes with a blue pill, “Active”, idle “Ready”, and a generic model badge. | Use a plain title and quiet metadata. Show run/reconciliation/connection status when relevant; omit only the generic fallback model in the header. | Known session model, session switching, message count and semantic active-session label. |
| The composer repeats idle readiness and voice status inside a heavy rounded panel. | Remove redundant idle labels; use a lighter desktop surface, 12 px desktop corners and 16 px mobile corners. | Model picker, hands-free switch, microphone, attachments, Send, Stop, Retry and connection warnings. |
| Unavailable and empty screens center a small message in a large blank viewport. | Place a compact, left-aligned explanation near the top, with a neutral icon and bounded readable text. | Scrolling, large text, live-region announcements and filled recovery actions. |

The shared worktree already contained inventory, profile and Settings refinements.
They were preserved; their appearance in the comparison is not authorship evidence
for this pass. Changes here remain within presentation and localization. No Agent
or Wing Link authority, credential handling, or capability contract was changed.

## Visual evidence

- [Before and after](../../test-results/linux-minimal-review-2026-09-05/before-after.html)
- [Current gallery](../../test-results/linux-minimal-review-2026-09-05/index.html)
- [Original screenshots ZIP](../../test-results/linux-minimal-review-2026-09-05/linux-ui-review.zip)

Screenshots are ignored local artifacts. Live values, generated session identities,
and scroll positions may vary between runs.

## Validation

- `flutter gen-l10n`: passed; generated localization output includes the Chat label.
- `dart format` on the six changed Dart files: no further changes.
- `flutter analyze`: no issues.
- `flutter test --concurrency=1 test/shared/widgets test/features/hermes_chat/screens test/features/profiles test/features/providers test/features/tools test/features/soul test/features/schedules test/features/gateway test/features/settings test/theme test/router`: **505 passed**.
- The new composer test checks that the model action remains present, idle badges
  disappear, and Stop remains hit-testable during a run. Existing suites cover
  focus, keyboard shortcuts, voice controls, large text and recovery actions.
- An initial broad run failed seven recovery-action tests after changing the
  shared button type. Restoring `FilledButton` preserved existing integrations;
  the complete 505-test rerun above passed without weakening assertions.
- `npm run readme:assets`: passed, including the release build of
  `lib/main_e2e.dart`; README and landing PNGs regenerated. The build emitted the
  existing Cupertino font-family warning, but completed successfully. These
  browser captures use deterministic fixtures, separate from the real Linux tour.
- `bash scripts/run_linux_live_visual.sh`: **passed in 3m01s**, wrapper exit 0,
  using real Hermes Agent, Wing Link and OmniRoute. Captured **81 states across
  14 routes**, including real provider reply, profile create/rename/delete,
  catalog autocomplete, theme and voice preferences, setup tutorial and reconnect.
  There are two fewer captures than before because Settings no longer requires
  separate bottom-scroll views in either theme.
- Gallery verification: all 81 PNGs passed integrity checks and decoded in
  Chromium; all 81 before/after pairs exist; tutorial filtering finds five states.
  Contact sheets of every state and full-size Chat, Schedules, profile creation,
  and README mobile renders were inspected.
- `git diff --check`: passed.

After the tour, Wing Link reported only the isolated default profile. Both owned
services were stopped and private runtime state and credentials were removed.

## Delivery verification

The UI commit was exported from the Git index and tested independently of the
remaining shared-worktree edits. Analysis and changed-file formatting passed.
The same UI command exercised 498 tests: 496 passed, and two old route-driver
assertions failed. Including the existing Office shell assertion and removing
ambiguous Settings scroll lookups made both affected route tests pass on rerun.
The additional concurrent inventory/Settings tests remain outside this commit;
the earlier 505-test and native screenshots receipts describe the shared worktree.

## Remaining findings

The earlier screenshot review found a stale session-rail message count beside a
populated conversation. Resolving that requires tracing Agent reconciliation; this
pass does not substitute a cosmetic count. The earlier full native feature suite
also reported a profile-catalog Retry failure that passed in the widget runner.
This UI pass does not establish that native-only issue as fixed.

Visual inspection of the new native light renders confirms that the chat title
and composer no longer compete with idle badges. Schedules now places its
capability explanation below the host selector rather than midway down the page.

Native Linux under Xvfb is the exercised rendering target. Physical audio, speech,
OS file pickers, host installation and unavailable administrative writes are not
qualified by these screenshots.
