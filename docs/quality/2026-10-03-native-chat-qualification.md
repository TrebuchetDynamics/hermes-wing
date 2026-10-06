# Native Chat and exact-session qualification preflight

## Outcome

**HOLD — no native integration or live Agent qualification was run by this worker.**
The existing deterministic Linux targets are identifiable, but concurrent Flutter
build/test processes and missing native development metadata prevent a safe new
launch in this shared checkout. No source, harness, dependency, Agent runtime,
credential store, service, or acceptance card was changed. This report is the
worker's only repository write.

Observed on **2026-10-03 at 18:49:59 UTC−06:00**, checkout
`ca149a82189c8c9e5abd98b376bfeae1e43f6f3f` plus the existing dirty worktree.
The HEAD alone does not identify the changing uncommitted source. Other workers
own browser builds and the Flutter suite; these findings do not accept their runs.

## Current behavior and evidence boundaries

- Production [channel wiring](../../lib/features/hermes_chat/providers/hermes_channel_provider.dart)
  constructs `HermesApiChannel` with secure detached-run storage. Agent data-plane
  credentials are separate from Wing Link management credentials. Internal
  native-web qualification clients are not the enabled production transport.
- [Exact restoration](../runbooks/chat-session-restoration.md) restores the saved
  gateway/profile/session tuple, not inventory page one's default. The live
  [directory](../../lib/features/hermes_chat/gateways/hermes_gateway_directory.dart)
  defers selection while connecting/selecting the intended profile, then requests
  that exact session. Pending/failure retains ownership; explicit choice transfers
  it. Directory/Remove/disposal and newer selections invalidate older activation.
- [Channel restoration](../../lib/core/hermes/channel/api_channel/hermes_api_channel_sessions.dart)
  checks the exact advertised metadata/history GET operations, grants and profile
  context. Known inventory rows skip metadata; off-page rows require it. Selection
  reuses canonical-history/detached-run recovery and fences late results by client,
  connection, profile, selection and activation. It does not create a replacement
  session or replay a prompt.
- [Preference persistence](../../lib/features/hermes_chat/gateways/gateway_contact_cache.dart)
  checks validity after asynchronous preferences acquisition. Directory writes and
  clears are serialized. This is source inspection, not native-plugin execution.
- The [production Chat runbook](../runbooks/chat-production-journey.md) defines a
  compiled-browser production-channel journey for correlated approval/denial,
  Stop acknowledgment versus terminal status, transport loss, canonical recovery
  and a subsequent prompt without replay. Synthetic replies are not generation.
- The restoration runbook names real-channel/client directory tests, adversarial
  operation/grant/metadata cases, preference write races, stale-draft ownership,
  accessible recovery and compiled-browser page-two reload receipts. The
  [independent focused report](2026-10-03-session-restoration-study-verification.md)
  records an earlier 116-test restoration/switch run and three channel regressions;
  those are attributed evidence, not commands executed by this worker.

No existing `integration_test/linux*` target inspected implements the full
remembered off-page gateway/profile/session relaunch journey. The persistence
launcher proves groups and local settings across two processes, **not** that
restoration journey. Native minimize/restore preserves a standalone `TextField`
draft, **not** an Agent-owned conversation or a running Chat turn.

## Observed prerequisites

Read-only discovery used tool lookup, package metadata, native-library resolution,
package-root existence and process classification. Environment probes returned
presence booleans only; no live manifest or credential contents were opened.

| Check | Observed result | Consequence |
| --- | --- | --- |
| Display environment | `DISPLAY` and `WAYLAND_DISPLAY` configured | Do not drive the personal desktop; use an owned Xvfb display. |
| Installed tools | Flutter, Dart, Node, Xvfb/xvfb-run, Fluxbox, xprop, pkg-config, CMake, Ninja and clang++ found | No installation attempted. |
| X11 helper libraries | `libX11.so.6` and `libXtst.so.6` resolved | Helper uses ctypes/XTest; absent `xdotool` is not a blocker. |
| SDK cache identity | Flutter 3.44.2 / Dart 3.12.2 | Read cached version metadata; did not invoke a version/update command. |
| Package-root health | All 143 package roots in existing package config exist | No `pub get`, dependency repair or cache migration performed. |
| Native pkg-config | `gtk+-3.0` available; `libsecret-1`, `gstreamer-1.0`, `gstreamer-app-1.0`, `gstreamer-audio-1.0` missing | Existing aggregate Linux launcher would exit 2 at its development-package preflight. Runtime `.so` availability does not satisfy build metadata. |
| Concurrency | At least one Flutter build and one Flutter test process active | Existing launchers share Flutter SDK/build outputs; no independent build-output path or lock in these scripts. Do not launch another Flutter command concurrently. |
| Live inputs | `WING_LIVE_PROFILE_MANIFEST`, `WING_LIVE_LINK_MANIFEST`, `WING_LIVE_LINK_BINARY`, `WING_LINK_STATE` unset | No launchable approved isolated target/auth was supplied to this worker. Not proof that no isolated service exists elsewhere. |

The [roadmap](../../ROADMAP.md) says the isolated target lacks Codex credentials
and needs private supported OAuth provisioning; the selected actual-inference
provider/model is `openai-codex` / `gpt-6.1-sol`, not a replacement local model.
This is a documented blocker, not a fresh authentication probe. This worker did
not scan runtime homes, search for secret files, contact services, import personal
OAuth state, or start/configure an Agent.

## Existing deterministic commands to run after blockers clear

Run from the repository root, with the configured scratch `TMPDIR`, installed
approved tools and exclusive Flutter/build ownership. Recheck package metadata and
process activity immediately before execution. These are **not-run commands**, not
passing receipts. Explicit X11 selection prevents inheriting the personal Wayland
session for native keyboard/clipboard operations.

```sh
# Real native sockets + production HermesApiChannel + Chat UI,
# against its own ephemeral deterministic Node fixture; no real provider.
env -u WAYLAND_DISPLAY GDK_BACKEND=x11 xvfb-run -a \
  flutter test --no-pub -d linux integration_test/linux_http_e2e_test.dart \
  --reporter expanded

# Real preferences plugin, isolated HOME/XDG roots, write then verify processes.
env -u WAYLAND_DISPLAY GDK_BACKEND=x11 \
  bash scripts/run_linux_persistence_e2e.sh

# Owned Xvfb/Fluxbox, isolated HOME/XDG, synthetic picker/save fixtures only.
# Runs both native-input and transcript-export targets sequentially.
env -u WAYLAND_DISPLAY GDK_BACKEND=x11 \
  bash scripts/run_linux_native_input_e2e.sh
```

The [HTTP target](../../integration_test/linux_http_e2e_test.dart) reserves two
loopback ports, waits for both child-server bind announcements before reset,
uses mocked preferences and `EmptyHermesEndpointStore`, and tears down its server.
At 420/1440 widths it covers create/send/approve/deny, usable post-denial prompt,
Stop/new explicit prompt, and CRUD/reconnect without replay. It is narrower than
the production-browser multi-stage journey and the exact remembered-session matrix.

The [persistence launcher](../../scripts/run_linux_persistence_e2e.sh) owns a
marked scratch root, isolates HOME/config/data/cache and removes only that root.
Its two phases assert retained group/theme/voice-setting preferences and zero
submitted turns. The [native-input launcher](../../scripts/run_linux_native_input_e2e.sh)
uses the same ownership pattern plus a private Xvfb window manager. Its helper
refuses an unmarked or out-of-root target. Tests cover GTK keyboard, Unicode IME
commit/cancel, minimize/resume draft, and native transcript save/cancel byte
readback at 390/1280 with a fake channel. Neither launcher loads Agent auth.

The broad `bash scripts/run_linux_e2e.sh` is **not** the preferred scoped launch:
it also runs fixture/transport/maestro/large-reader targets and may use the existing
personal `DISPLAY` for some targets. Do not invoke
`scripts/run_linux_release_build.sh` to bypass this gate: its fallback deletes
`build/linux` and prepares dependencies, outside this worker's authorized scope.

Exact restoration's six-file Flutter matrix and compiled-browser commands remain
in its runbook. They belong to the coordinated suite/browser workers; running
widget tests with no `-d linux` is not native GTK qualification. A future full
native remembered-session receipt must actually restore the tuple across native
relaunch, demonstrate canonical identity and zero restoration mutations, and name
its endpoint/auth/secure-storage and process-lifecycle boundaries.

## Live qualification prerequisites and consent

The existing `bash scripts/run_linux_live_e2e.sh` requires the four private live
inputs above, owner-only manifest files and disposable Agent/Link state. It runs
real-profile provider generation plus management pairing/approval/revocation
journeys. It is **not a read-only preflight** and is not authorized here.
`scripts/run_linux_live_features_e2e.sh` avoids provider inference but still needs
real manifests and isolated management state and performs an approved directory
grant; it is not a credential-free deterministic alternative.

Before any live run, the owner must supply/confirm:

1. An unmodified supported disposable Agent target, selected advertised production
   API operations and explicit profile/session/run identities. No runtime patch,
   CLI data-plane bridge, personal-state access or shadow state.
2. Supported private OAuth/auth acquisition for the owner-selected provider/model,
   without reading/copying personal credentials. Credentials remain private
   runtime inputs, never argv, URLs, card metadata, report output or diagnostics.
3. Authorized harmless prompt/tool, allowed network destinations, billing ceiling,
   duration and cleanup policy. Generation and session/management mutations need
   their own consent; merely finding an endpoint is insufficient.
4. Exclusive build/test ownership, satisfied native development prerequisites,
   owned display/preferences, and sanitized command/result plus canonical
   run/history receipts. Stop acknowledgment must not be recorded as cancellation.
5. A separately named Android device/emulator and OS/API for process death/relaunch,
   secure storage, IME and accessibility. Linux/Xvfb and compact Chromium do not
   qualify Android, physical speech/acoustics, or detached-run durability.

## Checks executed by this worker

All observations are from this checkout during this preflight; syntax checks do
not compile Flutter, execute UI behavior or prove authentication.

```sh
bash -n scripts/run_linux_e2e.sh scripts/run_linux_persistence_e2e.sh scripts/run_linux_native_input_e2e.sh scripts/run_linux_live_e2e.sh scripts/run_linux_live_features_e2e.sh
python3 -c 'import ast,pathlib; ast.parse(pathlib.Path("scripts/linux_native_input.py").read_text()); print("Launcher shell syntax and native input Python AST: PASS")'
git rev-parse HEAD
```

These commands exited **0**. SDK cache, pkg-config/tool/package-root and process
checks produced the prerequisite results above. The documentation check
`git diff --no-index --check /dev/null docs/quality/2026-10-03-native-chat-qualification.md`
returned **1 with no whitespace diagnostics** (normal no-index new-file difference);
a local-link existence probe exited **0** with **11 links, zero missing targets**.
No build, analyzer, Flutter test, native UI, live inference, browser or Android
result is claimed by this worker. Required behavioral checks remain **HOLD**.

## Acceptance/card status

No authoritative task-board/card read or transition was available in this
worker's task. The production runbook and roadmap M1/action sections still say
`t_19a425b2` awaits same-card tester/reviewer acceptance, while the roadmap's
Now paragraph says its deterministic slice passed independent review. That is a
**documentation inconsistency**, not evidence for either current card status.
`t_f098a32e` is documented as triage/lifecycle blocked; this report does not verify
or close that board gate. Parent/owner must read the exact cards and their
source-bound tester/reviewer receipts before asserting acceptance. No milestone,
full-suite, live Agent or platform acceptance is advanced here.
