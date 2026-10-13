# Android connection editor ordering

Task: `t_68ab585f` / CONNECTION-PATHS / CONNECTION-OFFICIAL-DESKTOP-PORT.
Base: `9d8b3cad3c8d1eb28966e1b50cee28a033808b1e`.
Status: offline implementation; independent same-card review pending. Parent
milestones remain open. No canonical integration or publication by this worker.

## Admission and scope

Before the first test or production edit, the original guard passed with outcome
`worker_start_admitted`:

```sh
python3 /home/xel/git/gormes/hermes-toolset/skills/autowork/scripts/pass_workspace.py --manifest /home/xel/.hermes/profiles/wing/autowork/pass-d2460795b8c6b201-d436a5c46b0e4c619337264ab523c312.json --manifest-sha256 c2adc1f078446a24a3ea2deb054b41da0bac8951fc8d0b5c80efec26f7db2b31 --workspace /home/xel/.hermes/cache/scratch/autowork-passes/d2460795b8c6b201-d436a5c46b0e4c619337264ab523c312
```

Decision: reuse the current mode enum, selection controller, chip keys and
`enrollInstallOnPhoneAction` localized label. Only native Android presentation
changes; Linux/web retain Local, SSH, Remote. No new copy, dependencies,
transport, runtime, storage, credentials or installer behavior.

The traced production path is `HermesAddScreen` → `HermesChatScreen`
(`initiallyEditingConnection`, `initialConnectionMode`) → shared
[`_buildConnectForm`](../../lib/features/hermes_chat/screens/state/hermes_chat_layout.dart).
Its chips call the existing `_selectConnectionMode`; Remote retains VPN selection.
Local selection and `connectLocal` retain the fixed phone endpoint
`http://127.0.0.1:8642`. SSH continues to use `ManagedSshConnectionPanel`, not CLI
or Link. The changed presentation is shared with existing connection editing.

## Acceptance evidence

The [production regression](../../test/features/hermes_chat/screens/hermes_connection_primary_entry_test.dart)
uses the real Add screen/router and API channel with deterministic requests.
Eight cases cover Linux and Android platform overrides, widths 390/1280 and text
scales 1/2. It checks:

- exact chip order and labels, including `Use this phone (Termux)` on Android;
- keyboard selection of SSH, Remote HTTPS, VPN and Local, including retained VPN;
- Android manual guide/explicit existing-Agent skip and fixed loopback display;
- unchanged Linux home discovery and deliberately editable advanced endpoint;
- cancellation restores the exact connected channel state, origin/profile/session
  and canonical history, with no additional requests or saved-store writes/clear.

RED: before production edits, the primary-entry target returned exit 1: all four
Linux cases passed, all four Android cases failed on Local-first order.
The first attempt could not run `--no-pub` because the fresh workspace had no
package configuration. `timeout 5m flutter pub get` resolved the existing locked
dependencies without tracked manifest/lock changes. After the presentation fix,
a test initially expected the endpoint before the guide's explicit skip; this
was corrected to exercise that production action. GREEN: eight cases passed.

Required verification (Linux host, Flutter 3.44.2 / Dart 3.12.2):

```sh
dart format --output=none --set-exit-if-changed lib/features/hermes_chat/screens/state/hermes_chat_layout.dart test/features/hermes_chat/screens/hermes_connection_primary_entry_test.dart
timeout 5m flutter analyze --no-pub
timeout 5m flutter test --no-pub --concurrency=1 test/features/hermes_chat/screens/hermes_connection_primary_entry_test.dart test/features/hermes_chat/screens/hermes_chat_screen_android_endpoint_test.dart test/features/enrollment test/features/hermes_chat/screens/hermes_ssh_no_cli_test.dart test/features/hermes_chat/widgets/platform_local_connection_panel_test.dart
git diff --check
```

Analysis passed with no issues (6.9s); the required suite passed 41 tests (45s).
The finish gate reruns these checks on the final owned candidate and binds its
local `agent/wing/t_68ab585f` commit in the native review handoff. Changed local
Markdown links are checked for target-file existence. No ARB changes or
localization generation were needed. Review must use that exact finish commit,
not the dirty workspace union or a new admission manifest.

## Limits and next slice

Implemented: Android editor distinction matching welcome, with deterministic
production-control evidence. Qualified: only Linux-hosted Flutter widgets with
platform overrides, not a native Android application or live Agent.
Delivered: local task-ref commit only; integration/publication remain the
coordinator's review-gated responsibility.

NOT_CHECKED: physical Android, native Linux app, compiled web, live SSH host trust,
remote TLS/authentication, Termux installation/readiness and saved SSH relaunch.
Transport/security code is unchanged, not newly qualified by this presentation
regression. No Agent or Desktop reference was modified or used to make parity
claims. Remaining milestone gaps are native/live connection qualification and
separate retained consumer/packaging retirement; neither is implemented here.
