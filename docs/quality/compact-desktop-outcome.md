# Compact Profiles access against the Desktop outcome

> Reference correction: [official Desktop authority](official-desktop-reference.md). Prior Desktop source citations and parity conclusions in this document are withdrawn. Wing test results remain historical behavior evidence only.


Status: bounded source mapping and freshly executed Linux-hosted Flutter widget
navigation checks for `t_1f328b2e` / `DOC-PARITY-PLATFORM-DEVIATIONS`.
This receipt indexes exactly one adaptation: opening profile management from
mobile bottom navigation instead of Desktop's profile-switcher menu. It changes
no product behavior and does not qualify Android or full Desktop parity.
`PARITY` remains partial; same-card native review follows this receipt.

## Reference and source binding

Desktop HEAD inspected: `withdrawn reference revision`.
Its [AGENTS.md](official-desktop-reference.md#withdrawn-evidence) was read before source inspection.
`lat` is unavailable (`command -v lat` found no executable); no installation,
reference test execution or reference edits occurred. Five pre-existing `.claude`
deletions were observed and left untouched; the pin is not a remote-latest claim.

Wing base HEAD: `1afe1307e37ee1ddfa1f7d67ad047509e99c8784`, with shared dirty
changes. This mapping is bound to the inspected working files, not a claim that
the checked-out HEAD already includes the footer. The predecessor implementation
is commit `4164bd06f7ef4266a5239da7714730d8f45e388c` on
`agent/wing/t_82b3229c`. Board readback reports that card done with approval in
review run 785. A byte-hash comparison against that commit confirmed equality
for the current shell, footer test, focus-traversal test and footer receipt.

| Inspected source | SHA-256 |
| --- | --- |
| `lib/shared/widgets/app_shell.dart` | `1e64f3a12a824a3f2437a9651a874065c45f8187042a390f17e9a01f7678135a` |
| `test/shared/widgets/app_shell_test.dart` | `9e1529ac1402a8c70f0d1ad1d32a3d39919da50ce8fb63d24eec07f679e38b0c` |
| `test/shared/widgets/app_shell_desktop_parity_test.dart` | `995f11fabd7c25e3d73de663a4cca3c3deb128cb7eec4e29419076010e7e2d1c` |
| `withdrawn source citation` | `7f9d9196a913baa87e3599090ed0a7cf685b3df3c4f1ab86cc9df7cc723983b5` |
| `withdrawn source citation` | `3167398843c1afa556492a8786bcded9d82cffd7ba3e1c65a29b1f291a63056d` |

Additional Wing route/destination and predecessor fingerprints are retained in
`.task-evidence/t_1f328b2e/source-binding.json` (ignored, local evidence).

## One outcome, three presentations

Outcome: intentionally open the profile-management surface, without implicitly
choosing a profile. This is not the separate outcome of switching Chat ownership.

| Presentation | Current caller and destination | Explicit difference |
| --- | --- | --- |
| Desktop reference, expanded or collapsed sidebar | [ProfileSwitcher](official-desktop-reference.md#withdrawn-evidence):210–236 opens its switch picker via the separate expanded switch button or collapsed avatar. Its Manage Profiles button at 290–299 closes that picker and invokes `onManage`. [Layout](official-desktop-reference.md#withdrawn-evidence):844–849 supplies `goTo("agents")`; 945–956 renders `Agents` locally, or a Profiles `RemoteNotice` in remote mode. | Management is reached through the switch picker, not a mobile tab. Expanded profile-chip activation edits appearance instead; it is not the management action. |
| Wing desktop, expanded or collapsed | [AppShell](../../lib/shared/widgets/app_shell.dart):47–68 chooses desktop at widths >=600. The fixed footer is composed at 512–515; `_DesktopProfileFooter` at 641–704 uses `context.go(AppRoutes.profiles)` at 700. The utility Profiles destination is retained. | Passive current-profile context plus a direct Manage profiles action; no Desktop edit/switch picker. Collapsing the rail is still desktop, not mobile. |
| Wing mobile/compact viewport | [AppShell](../../lib/shared/widgets/app_shell.dart):47–53 selects `_MobileShell` below 600. At 110–165 its visible NavigationBar has Chat, Profiles, Connections and More. Selecting index 1 goes directly to `AppRoutes.profiles` at 136–142; 177–181 selects index 1 on the Profiles route. | Profiles is a first-class bottom destination, bypassing the Desktop picker and lacking the footer's current-profile context. More is not required for this outcome. The bar is absent when `appShellNavigationVisible` is false. |

Both Wing callers use the same `/profiles` constant in
[AppRoutes](../../lib/router/routes/app_routes.dart):7, and the production
[router](../../lib/router/providers/app_router.dart):72–79 builds the same
`ProfilesScreen`. Neither caller supplies a profile selection nor `setup=new`.
Width only changes presentation, never authority. This maps the narrow access
outcome; it does not assert identical Desktop lifecycle, appearance, switching,
remote restrictions or route-state retention.

The destination retains its own authority: [ProfilesScreen](../../lib/features/profiles/screens/profiles_screen.dart):266–313 distinguishes selected management
host/current Agent and supported Wing Link source, loading, disconnected/error
and unavailable states. Exact Agent profile-read checks remain at 1023–1045.
Its failed inventory Retry at 224–228 is an explicit destination action, not a
bottom-tab retry or queued mutation. Agent remains the profile authority; Wing
Link stays the reviewed management plane. No domain contract, credential,
shadow inventory or global profile-use behavior is introduced by this mapping.

## Executed evidence and inherited limits

Fresh command, run from the Wing root, exit 0, two tests passed:

```sh
flutter test --no-pub --concurrency=1 --reporter=expanded test/shared/widgets/app_shell_test.dart test/shared/widgets/app_shell_desktop_parity_test.dart --name 'bottom tabs navigate to Profiles and retain selection|compact resize retains mobile navigation and desktop choice'
```

Retained output: `.task-evidence/t_1f328b2e/navigation-tests.log`.
The first [existing test](../../test/shared/widgets/app_shell_test.dart):90–140
uses a disconnected fake channel at 390×844, taps Profiles and proves the
`/profiles` placeholder route and selected index 1; it then reaches Connections.
The second [existing test](../../test/shared/widgets/app_shell_desktop_parity_test.dart):175–204 starts on Profiles at 900×700, collapses desktop, resizes to
390×844 and proves selected index 1, four mobile destinations and no desktop
rail/toggle. It navigates to Chat, then restores 900×700 and confirms the
collapsed desktop choice, Chat selection and no layout exception.

These are discriminating widget navigation checks, not a production
`ProfilesScreen` mobile lifecycle test, Android Back execution, platform
integration or compiled-browser execution. No source or tests were edited.

Keyboard/focus and recovery evidence is deliberately separated:

- The unchanged [footer implementation receipt](profile-footer-implementation.md#acceptance-evidence)
  and [footer regression](../../test/shared/widgets/app_shell_profile_footer_test.dart):289–361
  attribute expanded/collapsed pointer, Enter and Space activation to the
  predecessor: one navigation to real `ProfilesScreen`, denied grants remain
  denied, no channel calls, reconnect does not replay navigation. Its focus test
  at 366–473 covers painted focus and reverse traversal at 2x text/360px height.
  These checks and the predecessor's compiled Chromium evidence were NOT rerun
  by this card. Source equality supports attribution, not fresh execution.
- Fresh mobile checks use taps and placeholder destinations. Keyboard activation,
  focus painting/escape, screen-reader behavior, real mobile destination
  failure/Retry, denied-grant handling and stale-owner transitions remain
  NOT_CHECKED by this card. A successful selected tab is not an active Agent
  profile, restored chat session or proof of management persistence.
- Desktop's nearest [ProfileSwitcher tests](official-desktop-reference.md#withdrawn-evidence):57–89 cover default display names,
  not this management journey; they were inspected, not executed.

## Receipt checks and coverage index

Executed checks (exit 0), retained under `.task-evidence/t_1f328b2e/`:

```sh
python .task-evidence/t_1f328b2e/check_receipt.py
git diff --check
python <home>/.hermes/shared-skills/repo-docs/scripts/goals.py validate <repo>
```

The link checker checks every new receipt's relative Markdown target and heading
anchor, and this new untracked file's trailing whitespace. Logs: `links.log`,
`diff-check.log`, `ledger-validate.log`. Goal updates use only the supported
`task ... DOC-PARITY-PLATFORM-DEVIATIONS done`, executed evidence and `render`
operations; shared `goals.json`/`TODO.md` stay outside the authored commit.

This is one indexed deviation for [HD-SHELL and HD-PROFILE](../product/hermes-desktop-feature-matrix.md#feature-groups),
not a matrix status upgrade. It follows the
[reference/evidence boundary](../product/hermes-desktop-parity.md#reference-and-evidence-boundary)
and the [current route inventory](../product/routes.md).
The bounded result is: source-mapped management access and PASS for deterministic
mobile selection/desktop-to-mobile adaptation, with distinct keyboard/recovery
coverage gaps. `DOC-PARITY-PLATFORM-DEVIATIONS` may close for this receipt;
`PARITY`, full footer parity and full platform qualification remain partial.

Native Linux/macOS/Windows, physical/emulated Android, live Agent/provider,
screen reader, packaging/install/update and real Desktop runtime: NOT_CHECKED.
No browser, analyzer, full suite, Go or audit checks ran for this documentation
slice. No large build output was created. Existing dirty implementation, receipts,
indexes, assets and localization were preserved; no upstream or system changes,
publication or unauthorized device/runtime action occurred.

Questions: none. Existing no-system-change, no-unauthorized-device-action and
no-publication defaults remain applied.
