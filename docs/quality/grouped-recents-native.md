# Native grouped recents recovery

Card `t_3a6bafe4`, task `VERIFY-GROUPED-RECENTS-NATIVE`, goal
`PARITY-COMPOSITION`. Result: PASS for the bounded deterministic Linux journey.
Native same-card review is the final handoff; review approval is not claimed.

## Delivered scope

- [Dedicated native integration](../../integration_test/linux_grouped_recents_test.dart)
  mounts the production `AppShell`, `ShellSessionAccess` and HTTP channel in a
  small router with focusable synthetic route content. It does not mount the
  full feature screens. Its recording channel subclass delegates selection to
  production unchanged, records exact action/completion counts and awaits the
  obsolete operation's completion before asserting rejection.
- [Response gate](../../integration_test/support/grouped_recents_fixture.dart)
  forwards the existing deterministic fixture over loopback. It holds an actual
  received history response, never synthesizes a successful upstream response.
  Requests and response sizes are bounded. Fixture setup bypasses the recorded
  app plane and is listed separately.
- [Native runner](../../scripts/support/grouped_recents_native.py) uses the existing
  [workspace isolation helper](../../scripts/support/desktop_daily_workspace.py)
  and [Linux root validation](../../integration_test/support/linux_test_isolation.dart).
  It owns its SDK/source/build copies, HOME/XDG/preferences, fixture and Xvfb
  process groups. Native plugins and bundled Wing Link compilation remain enabled;
  no management service or live Agent is launched. Build parallelism is two.

No production defect was exposed by the passing journey. No predecessor shell,
channel, daily-workflow target, fixture, recovery test, localization, upstream or
excluded connection/Android/product file was changed by this card. Agent remains
session authority; Wing Link is not a data-plane proxy. The response gate is
qualification infrastructure only, not shipped client architecture.

## Executed acceptance evidence

Environment: native Flutter Linux GTK runner under task-owned Xvfb X11 with
software rendering, x86_64, Linux 7.0.0-31-generic, glibc 2.39. Flutter 3.44.2,
Dart 3.12.2. Final native app PID: `2114310`.

1. Native keyboard return: PASS. Two explicit Opens after collapse/expand and
   compact/wide return select `synthetic-native-recents` once each and navigate
   to `/hermes`. Both directions use injected Tab/Shift+Tab; Enter and Space
   activate controls. The hidden sidebar inventory and exact row are absent
   through 16 traversal steps in each direction. The test uses 2x text,
   1280x600 wide and 390x844 compact Flutter view sizes. Eighteen focus assertions
   require focused semantics and control rectangles wholly inside the viewport.
   No Flutter exception or overflow occurred in the passing run. These are native
   adaptive viewport changes, not OS window minimization or physical resize input.
2. Pending-owner settlement: PASS. Four held Opens cover collapse disposal,
   compact disposal, same-channel reconnect generation and identical-origin/
   loaded-ID replacement channel. The fixture's default unscoped contract has
   no selected profile ID; replacement preserves that identity rather than
   inventing profile multiplexing. After actual selection completion, old and
   current owners remain on `e2e-hermes-session`, with no admitted target history,
   stale error or navigation away from `/tools`. Each fresh Space Open admits the
   exact target once. Ten explicit exact-row selections complete: six accepted
   Opens and four obsolete Opens. Profile A-B-A remains predecessor widget
   coverage, not newly qualified native profile multiplexing.
3. Effects and cleanup: PASS. The app makes 73 requests, all GET. Seven deliberate
   fixture connections each issue the same nine bootstrap reads (including one
   initial-session history read). Ten remaining requests are exact target history
   reads with `limit=500`, `offset=0`, `order=latest`; no profile query is advertised
   by this fixture. Total history reads: 17. Presentation/traversal/return and late
   settlement add no requests. There are zero app mutations: no New, Send,
   approval or Stop effects. Separate test-client setup performs one reset POST,
   one seed POST and two run-count GETs; run count remains zero. Teardown records
   all owned leaders reaped, no surviving owned groups and the owned root removed.

## Exact checks

Final runner command, from the Wing root, exit 0:

```sh
TMPDIR=<home>/.hermes/profiles/wing/cache/scratch PKG_CONFIG_PATH="$PWD/build/t_3a6bafe4/prereqs/root/usr/lib/x86_64-linux-gnu/pkgconfig" LIBRARY_PATH="$PWD/build/t_3a6bafe4/prereqs/root/usr/lib/x86_64-linux-gnu" timeout --signal=TERM --kill-after=20s 1000s python3 scripts/support/grouped_recents_native.py
```

The runner executes these commands with its independent SDK in the copied app:

```sh
flutter analyze --no-pub
flutter test --no-pub --concurrency=1 test/shared/widgets/app_shell_grouped_recents_recovery_test.dart test/shared/widgets/app_shell_grouped_recents_test.dart test/shared/widgets/app_shell_global_session_access_test.dart test/shared/widgets/app_shell_focus_traversal_test.dart --reporter expanded
xvfb-run -a -s '-screen 0 1600x1200x24 -nolisten tcp' flutter test --verbose --no-pub -d linux integration_test/linux_grouped_recents_test.dart --reporter expanded
```

All exit 0: analyzer has no issues, 71 focused widget tests pass, and the native
integration test passes. `checks.json` records exact isolated SDK paths and exits.
The main checkout also executed, exit 0:

```sh
dart format --output=none --set-exit-if-changed integration_test/linux_grouped_recents_test.dart integration_test/support/grouped_recents_fixture.dart
git diff --check
```

Compatible libsecret/GStreamer/ORC development packages were downloaded with
`timeout 120s apt-get download` and extracted into the task-owned build prefix,
following the [retained recipe](native-relaunch-workflow.md#safe-user-space-prerequisites-and-reproduction).
Installed runtime versions were rechecked with `dpkg-query -W`; they match that
recipe. The prerequisite receipt retains all 13 package hashes. No sudo, system
installation, loader override, plugin stub or shared service change occurred.

Earlier attempts produced new harness diagnostics: analyzer brace requirements,
nonfocusable dummy route content, an incorrect assumed profile query, lifecycle
fixture seed rejection and semantics-handle cleanup ordering. The final target
uses focusable route content and the fixture's actual advertised contract, and
releases its semantics handle before native end-of-test verification. Earlier
logs and pre-final receipts are historical failures, not acceptance evidence.

## Source identity and retained evidence

Base HEAD: `1afe1307e37ee1ddfa1f7d67ad047509e99c8784`, plus preserved shared dirty
predecessor inputs. The copied manifest has SHA-256
`d523b9074baab4f141c77d77c1260b8b59e809f9e3d9a68cd3d7d66e4011a604`.
All 640 copied files still present in the checkout matched their tested hashes.
The manifest includes the fixture's local JS dependencies, package graph,
Linux hosts/plugins, and Wing Link sources; upstream clones are excluded.

Scoped hashes:

- App shell: `9c9d959aa3a8adeb560749c3a1b7a45d3ec5b3b2e5d9fb396fb0ec2bb002c832`
- Session access: `434821cf8674f50de1159f78eec5739d5d743ed70847423d07d93128edc97aa1`
- Native integration: `7447968ac1201b808cfc1a9b5aa3cc2a9aa8245395c05f05e70674679dbe53ee`
- Fixture gate: `efad78c159fdd48f6bbec4277bbe897d50080562c387098e0be2edaf7114ca1b`
- Native runner: `3bf8c03f9d3d91cc76c0f8416f1c89711e94130f1e60cf7b4cd5bbd59fb7d940`
- Native bundle executable: `2e60d9074bee04e3f3d3356438c70f37c0b93b816609bd5e18bc19297edba023`

Small evidence is retained in ignored `build/t_3a6bafe4/evidence/`: launcher,
analysis, focused and native logs; request/focus/action receipt; exact commands;
source manifest/verification; build fingerprint; prerequisite hashes and teardown.
The handoff also retains an evidence archive. Task-owned source/SDK/build copies
and extracted/downloaded prerequisites are removed; unrelated build output stays.

The card-only local agent branch depends on shared predecessor changes, including
session access, global scope and shell/channel projections. Standalone branch
qualification is NOT_CHECKED. Goal task/evidence/render changes remain narrow
shared-ledger updates; unrelated inherited ledger edits are not copied into the
card-only commit. No push, merge, release or deployment occurs.

Live Agent/provider, physical keyboard/IME, OS hide/minimize, screen reader,
contrast certification, native multi-source grouping, full feature-route screens,
Android/device, audio, signed distribution and full-suite qualification:
NOT_CHECKED. This receipt supersedes only the bounded native recents gap in the
[earlier recovery evidence](grouped-recents-recovery.md#gaps-and-defaults).

Questions: none. Defaults applied: existing source grouping and sidebar lifetime,
fixture-advertised profile contract, isolated development qualification only.
