# Desktop shell reference fidelity — redesign slice

> Reference correction: [official Desktop authority](../quality/official-desktop-reference.md). Prior Desktop source citations and parity conclusions in this document are withdrawn. Wing test results remain historical behavior evidence only.


Status: independent fix-list review resolved the P1 toggle-outline defect and
corrected the typography description. `DESIGN.md` and `.impeccable/design.json`
record the delivered slice. This bounded disposition is not whole-surface,
whole-app or platform acceptance.
The owner confirmed PRODUCT.md and pinned Hermes Desktop for a faithful Flutter redesign, desktop shell/sidebar first, then Chat.
This receipt supersedes the earlier refinement framing, not its preserved evidence.

## Reference and direction

Read-only Desktop pin: `withdrawn reference revision`.

- Layout (local-only reference: `withdrawn source citation`),
  lines 686–850: clean collapse header, pinned navigation, flexible session region,
  utility/profile footer; missing domain functionality must not be imitated.
- CSS (local-only reference: `withdrawn source citation`), lines 9–75:
  light/dark rail, work-area, foreground, hover and selection roles.
- CSS lines 507–518: 10px medium corners and Cairo/Manrope/system font stack.
- CSS lines 2175–2189, 2237–2268, 2406–2453: 26px status bar, 250/64px sidebar,
  top-right toggle, 13px navigation, subtle accent selection.

The code-led Operate direction contract is in
`.impeccable/surfaces/lib-shared-widgets-app-shell-dart.md` (seed `b59dfc09`, assigned
candidate 5 explicitly overridden by the user-pinned reference). Parent owns
PRODUCT.md, the fresh independent finish review, fleet detector and documenter.
The fix worker reloaded the existing context; no new seed or second detector ran.

## Delivered shell replacement

[Shell](../../lib/shared/widgets/app_shell.dart) and
[scoped roles](../../lib/shared/widgets/app_shell_desktop_style.dart):

- 250/64 logical-pixel sidebar; removed redundant brand block; top-right expanded
  toggle and centered collapsed toggle in a fixed 64px header.
- Flat reference light `#f8f8f8` / dark `#171717` sidebar and status strip.
- White / `#212121` workspace backing, scoped through scaffold background only;
  no global theme change or feature/control theme replacement.
- 13px navigation labels, 16px icons, 10px label gap and 10px corners; normal
  inactive text, semibold selection, exact reference light accent `#003f7a` and
  8%/15% subtle blue selection surfaces.
- Explicit reference-style hover/focus surface, shaped keyboard focus border and
  150ms button response; no circular default focus halo or ornamental motion.
- Workflow above the existing **Loaded sessions** region, utilities anchored
  below. Group headings are no longer painted but named group semantics remain.
- Full-width 26px-minimum status strip, 11px text, scalable at enlarged text.
- Removed Wing's 1180px work-area cap and sidebar divider; nested navigator
  semantics and route-local traversal policy remain intact.

The nine available routes and their current ordering remain functional. Session
controls still perform exact acknowledged operations through the existing owner;
no new session/profile state, reads, fake recents or profile footer was introduced.
The redesign itself did not alter Chat. Delivery also carries the minimal
predecessor presentation, shell localization and guarded session/directory
contracts needed by this shell on a standalone checkout.
Compact/mobile styling and behavior are unchanged, with byte-identical light and
dark compact captures. Existing dark/light choices determine the reference shell
scheme; route/control themes retain the user's existing app palette.

### Explicit fidelity/accessibility differences

- All controls retain at least 48×48 targets, rather than Desktop's 30px toggle,
  smaller expanded rows and 40px collapsed controls. Header is consequently 64px.
- System/native font fallback remains instead of bundling Desktop's Manrope Latin
  face and Cairo Arabic subset. Desktop's Cairo `@font-face` has an Arabic Unicode
  range, so English resolves to Manrope, not Cairo. Size, weight and density are
  matched; exact bundled typography remains a gap. No font installation is needed
  for this focus-only correction.
- Flutter Material icon family and always-visible named toggle are retained,
  not Desktop's Lucide pictograms/circular-mark hover swap.
- Labeled utilities are preserved, not converted into Desktop's icon-only footer
  strip. Existing Profiles/Persona routes remain explicit until the real
  profile-footer workflow is qualified. Discover, Kanban and Memory are not added.
- Desktop's dark `#006acd` selected text is lifted to `#579fff` for readable
  contrast. Text contrast tests cover selected/hover and primary/secondary text
  in both shell schemes at 4.5:1 or better. The toggle outline is separately
  pixel-verified at 7.02:1 light and 8.65:1 dark.

## Evidence and exact checks

Evidence directory:
`.task-evidence/desktop-shell-fidelity/`.

Baseline `app_shell.before.dart` is the original dirty source, SHA-256
`15fe0f6771b95cc5190615fe95bb3b9419a537cd8af32708132ff2dba1173faf`.
`redesign-task-only.diff` attributes this task against that baseline, not Git HEAD.
`redesign-manifest.json` records final source/reference/screenshot hashes, isolated
source equality, unchanged mobile/state prefix except the style import, and
byte-identical compact light/dark captures. Older `manifest.json`, `task-only.diff`
and `after-*` images belong to the superseded refinement pass.

Required final browser images (all opened and checked):

- `redesign-final-light-desktop.png`, `redesign-final-dark-desktop.png`: 1280×900.
- `redesign-final-light-collapsed.png`, `redesign-final-dark-collapsed.png`.
- `redesign-final-light-keyboard-focus.png`, `redesign-final-dark-keyboard-focus.png`.
- `redesign-final-light-compact.png`, `redesign-final-dark-compact.png`: 390×844.

Original light baseline: `before-desktop.png`, `before-compact.png`. Dark baseline:
`redesign-before-dark-desktop.png`, `redesign-before-dark-compact.png` (earlier
refinement state before redesign, explicitly not the untouched original dark state).
The redesign used one batched inspection and one correction/confirmation round.
The correction made the reference work-area backing visible behind opaque route
Scaffolds; no further UI polishing round was performed.

`reference-css-light.png` / `reference-css-dark.png` are **source-derived CSS
specimens**, not a running Desktop product or approved generated comp. The local
HTML loads the read-only checkout's actual stylesheet/fonts; it explicitly labels
omitted runtime state. They qualify palette/type/control CSS only, not reference
navigation behavior or full profile/session composition. No image generation or
shipping raster asset was introduced.

Flutter 3.44.2 / Dart 3.12.2, Linux. Tests/builds ran in an isolated source copy at
`the isolated source mirror` to avoid
another worker's build outputs. The manifest confirms task source bytes match.

| Command | Result | Evidence log |
| --- | --- | --- |
| `flutter test --no-pub --concurrency=1 test/shared/widgets/app_shell_reference_fidelity_test.dart --plain-name 'redesigned shell uses Desktop palette and navigation type scale'` | expected exit 1: reference rail vs incumbent palette | `redesign-red.log` |
| Focused work-area assertion before implementation | expected exit 1: white vs incumbent scaffold backing | `work-area-red.log` |
| `npm run test -- test/shared/widgets/app_shell_reference_fidelity_test.dart test/shared/widgets/app_shell_desktop_parity_test.dart test/shared/widgets/app_shell_navigation_groups_test.dart test/shared/widgets/app_shell_focus_traversal_test.dart test/shared/widgets/app_shell_global_session_access_test.dart` | exit 0, **57 passed** | `redesign-final-tests.log` |
| `flutter analyze` | exit 0, no issues | `redesign-final-analyze.log` |
| `flutter build web --release --no-pub --no-wasm-dry-run -t lib/main_e2e.dart` | exit 0 | `redesign-final-build.log` |
| `CHROME_EXECUTABLE=/usr/bin/chromium WING_APP_URL=http://127.0.0.1:19767/ npx playwright test --config=playwright.config.mjs playwright/tests/regression/desktop-navigation-groups.spec.mjs playwright/tests/regression/global-session-access.spec.mjs --output=.task-evidence/desktop-shell-fidelity/redesign-playwright-output` | exit 0, **2 passed** | `redesign-browser-tests.log` |
| `node .task-evidence/desktop-shell-fidelity/capture.mjs redesign-final-light light` and corresponding `redesign-final-dark dark` | exit 0, keyboard collapse/navigation, valid captures, no page errors | final browser JSON/images |
| `dart format --output=none --set-exit-if-changed lib/shared/widgets/app_shell.dart lib/shared/widgets/app_shell_desktop_style.dart test/shared/widgets/app_shell_reference_fidelity_test.dart` | exit 0, unchanged | terminal receipt |
| Scoped `git diff --check` and runbook local links | exit 0; no broken links | terminal receipt |

The [new regression](../../test/shared/widgets/app_shell_reference_fidelity_test.dart)
pins frame roles, typography, dimensions, shape, target sizes, draft/focus retention,
contrast and hover/focus treatment. Unmodified nearest suites cover all nine routes,
short windows, 200% text, nested semantics, bidirectional focus, compact recovery
and exact loaded-session acknowledgement/owner invalidation. Browser receipts verify
all-route keyboard operation and only the intended exact session reads/create.

### Verification limitations and recovered issues

Unscoped `npm run test` was also attempted when explicitly requested. It did
**not pass**: the isolated mirror omitted native-host/docs source-contract inputs
(e.g. `macos/Runner/AppDelegate.swift`, `android/`, `.github/`, `wing_link/`), and the
tool terminated after 420 seconds. Last progress was +1397/-54 including teardown;
these are incomplete progress counts, not a final test total or full-suite verdict.
`npm-test.log` preserves failures. No unrelated production/test repairs were made
and a full-suite pass is not claimed. The explicitly scoped npm command above
subsequently passed on the final code.

A separate repository-root `npm run test` completed with 3,386 passes and three
shell assertion failures. The test plan (local-only reference: `../test-plan.md#acceptance-records-and-gaps`)
records that historical log separately from the completed FINISH-DESKTOP-SHELL qualification.
Do not combine its completed
result with the isolated mirror's incomplete counts, or infer a full-suite pass
from the focused redesign checks. This documentation pass did not rerun tests.

An initial analyzer mirror omitted integration_test; adding it resolved import
errors. A redesign style lint required braces and is fixed in the final clean
analyzer run. Port 8877 was occupied, so the owned server used 19767/19768 without
terminating another owner. `lat` was unavailable; source inspection was read-only.
Read-only ownership checks found no running wing task before edits. No shared
ledgers, worker-owned code, upstream repository, cards, credentials, commits or
pushes were changed. The old refinement detector result is historical and does
not certify the redesigned sources; parent owns the fleet detector.

## Independent review P1 correction

Only the collapse/expand IconButton changed. Flutter resolves `ButtonStyle.side`
into the actual Material shape, but an opaque focused Ink overlay painted over
that border; style-property assertions passed while rendered edge pixels failed.
The toggle now uses its own style: transparent focused overlay (also when hovered)
and a continuous 2px secondary-color outline. Unfocused mouse hover retains the
reference fill; navigation-row styles are unchanged. The 48×48 target, 10px
corners, 250/64 rail widths, keyboard focus retention and reduced-motion behavior
remain unchanged.

- `focus-fix-red.log`: expected failure, **0** opaque outline pixels against the
  required 24; the actual Material shape/property assertion had passed.
- `focus-fix-tests.log`: same scoped npm test command above, **57 passed**. The
  augmented existing regression checks rendered shell pixels and both themes /
  collapse-expand icons with simultaneous hover and focus, all four straight edges,
  target geometry, actual Material shape and outline contrast ≥3:1.
- `focus-fix-analyze.log`: analyzer exit 0, no issues. An initial test-only braces
  lint was corrected; `focus-fix-format.log` records formatter exit 0, unchanged.
- `focus-fix-build.log`: deterministic web release build exit 0. Existing
  Cupertino font warning remains, not a build failure or native qualification.
- `focus-fix-browser-tests.log`: same two browser journeys above, **2 passed**.
- Same eight required `redesign-final-*` views were recaptured in one batch; the
  focus images use `recapture-focus.mjs`, pointer at (1100,850), 350ms settled
  delay and retained keyboard focus. All eight were opened and checked for capture
  validity. `focus-fix-pixel-checks.json` records exact image edge samples and
  contrast; it is execution evidence, not visual finish approval.

The prior work-area correction receipt remains historical. This batch addresses
only the independent review P1; no new polish hunt or detector was performed.
Native, screen-reader, live-provider and the original dirty-source full-suite
state remain unqualified by that visual-review batch.

## Standalone checkout dependency boundary

Delivery uses the predecessor grouped navigation, collapse/focus/semantics,
loaded-session access, passive directory lifetime and caller-admitted select/create
operations with their regression tests. An original standalone candidate extracted
only directory activity reporting and retained earlier activation outcomes. Its
queued/reentrant notification regressions and full suite passed in an isolated
snapshot, but the shared branch subsequently advanced with separately committed
predecessor work. That candidate's green receipt is not reused for the new base.

The final shell change retains the newly committed contracts and runs fresh gates
on its exact staged tree. It does not reverse existing restoration/retry UI,
deferred selection, persistence fences, approval/Stop or native-web work, and does
not claim those independent features were implemented or runtime-qualified by this
redesign. Historical receipts above describe their own source state. Exact-tree
gates, source hashes and the concurrent-base observation remain local-only delivery
evidence under `.task-evidence/shell-delivery/`; they are not product files.

## Committed-tree validation

Commit `1afe1307e37ee1ddfa1f7d67ad047509e99c8784` delivers this slice on tree
`5681b2c9ffc0c7221a1e5a497665a2d35393256b`. The local-only
`.task-evidence/shell-delivery/delivery-receipt.json` binds the integrated snapshot
and seven hashed logs. This documentation pass matched the commit tree and log
hashes. It inspected execution evidence; it did not rerun product checks.

The receipt records passing formatting, `flutter analyze`,
`flutter test --concurrency=1` (3,469 passes), the 57-test focused shell command,
a release `lib/main_e2e.dart` web build and two Chromium shell journeys.
Root `npm audit` passed with unchanged root dependency blobs. That result does
not cover later changes to Wing Link's embedded OmniRoute dependencies.

These checks supersede the earlier shell assertion failures only for the committed
snapshot. The untracked inventory keyboard harness and subsequent dirty-worktree
changes were not in that tree. The later inventory qualification below closes
that bounded check; the restyle itself is delivered. Go, complete web E2E, native runtime, live Agent
and device qualification were not run in this receipt. Node 26.7.0 execution does
not qualify the documented Node.js 22 baseline.

## Inventory keyboard qualification

The later [qualification receipt](../quality/shell-inventory-keyboard-qualification.md)
on `t_65ce1e31` records eight inventory and 73 focused shell widget passes,
clean analysis and two Chromium journeys after a fresh JS-release build.
The original inventory harness passed unchanged. Browser checks cover navigation
and exact Open/New at 390/1280px, not 200% browser text scaling.

FINISH-DESKTOP-SHELL is done for this bounded delivery in goals.json. Retained
log hashes and the harness match the inspected receipt and branch.
This pass does not rerun tests or establish independent final approval.
Full composition parity and native/live/screen-reader qualification remain incomplete.

## Remaining gates and parity gaps

- **Bounded finish gate:** independent `focus-fix-verdict.md` resolved the two
  requested corrections; `DESIGN.md` and `.impeccable/design.json` now record the
  slice. The verdict and raw captures remain local-only evidence under
  `.task-evidence/desktop-shell-fidelity/`, not clean-checkout artifacts.
  Executor receipts do not self-certify whole-surface visual acceptance.
- **Native/live:** NOT_CHECKED — native desktop, Android/iOS devices, screen
  reader, live Agent/provider, release and window-chrome integration.
- **Remaining shell:** real profile footer, grouped recents, full sessions modal,
  multi-conversation tabs, missing destination coverage, exact bundled font,
  icon-only footer density and collapse relaunch persistence.
- **Next slice:** Chat matching; no composer/transcript/lifecycle code was edited.

See [navigation](desktop-navigation-groups.md),
[session access](global-session-access.md) and the
[historical UI gap ledger](../product/hermes-desktop-ui-gap.md) (not evidence of this delivered redesign). Shared ledgers were deliberately
left untouched; this is a partial shell redesign, not whole-app parity acceptance.
