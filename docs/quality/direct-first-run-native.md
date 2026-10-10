# Native direct first-run Agent entry

Card `t_95a5ae74`; goal task `M1-DIRECT-FIRST-RUN-NATIVE`.

## Implemented and qualified

This card adds a reproducible GTK qualification harness, not a production routing
or transport change. It qualifies the predecessor's public first-run entry through
the existing production router, enrollment chooser, Chat connection form,
`HermesApiChannel`, gateway directory and contact cache. An initially empty injected
endpoint store records saves without touching keychains or personal credentials.
Native SharedPreferences uses only the launcher-owned HOME/XDG directories.

Linux x86_64 GTK execution passes four journeys at logical widths 390/1280 and
1x/2x text. The integration binding maps those layouts into the real GTK view;
this is not an OS window-resize or OS text-setting qualification. Tab/Space find
and activate production controls with actual focus assertions. `ensureVisible`
assists scrolling and test input inserts the synthetic URL. Physical keyboard,
IME and screen-reader qualification remain **NOT_CHECKED**.

## Acceptance evidence

1. [The native target](../../integration_test/linux_direct_first_run_test.dart)
   starts at the production `/hermes` route with no endpoints or cached owner.
   Public Add Hermes reaches Local / SSH / Remote, then the VPN subchoice.
   Optional setup exposes both local setup and pairing; keyboard manual entry
   returns to the direct form. Public Back traverses the pairing chooser and
   connection stack without saving or performing any transport request.
   All four adaptive/text combinations execute this journey on GTK, not Chromium.
   SSH copy explicitly requires a tunnel established outside Wing. No tunnel or
   local installer is executed.
2. [The fixture](../../integration_test/support/direct_first_run_native_fixture.dart)
   accepts only bounded synthetic Agent GET routes at two `.invalid` origins.
   It has no socket implementation, provider access, bearer or provider fixture
   credentials. POST/PATCH/PUT/DELETE and both streaming methods fail and count
   attempts. Unexpected GETs also fail and count. Enrollment management callbacks
   fail and count attempts independently. All three attempt counters remain zero.
   A synthetic capabilities 401 renders sanitized recovery copy without the raw
   exception marker, saving, automatic retry or focus-triggered reads. Deliberate
   Space on Add Hermes retries, saves an Agent-only endpoint, and public contact
   activation reaches exact `synthetic-qa` / `synthetic-history` history.
   A held first-run bootstrap is superseded by another synthetic channel owner;
   completing the stale read cannot save or replace that newer owner. This
   controlled external-owner change is test injection, not another user journey.
   The store is a fake; secure credential persistence is not qualified here.
3. [The launcher](../../scripts/run_linux_direct_first_run.sh) freezes Wing-only
   inputs before any check, verifies its retained source archive, and hashes the
   executed sources afterward. It strips inherited HOME/XDG/display/DBus/proxy/
   authorization state, copies the SDK, rewrites local package roots, uses an
   authenticated owned Xvfb display and bounded process groups, and deletes the
   copied app/SDK/preferences only after teardown. [Five launcher regressions](../../test/tooling/direct_first_run_native_test.py)
   cover argument refusal, isolated environment, exception cleanup, snapshot
   exclusion/link rejection, attribution and receipt rejection. No live admission
   gate, personal runtime, shared gateway, upstream clone or system package was
   modified.

## Checks and source identity

Final [sanitized receipt](direct-first-run-native-receipt.json) records exact
commands, source/dependency fingerprints, measured durations, request traces and
all attempts. Final evidence directory: `build/t_95a5ae74/attempt-v11jt14t/`.
All final commands exited 0:

- `python3 -B -m unittest discover -s test/tooling -p direct_first_run_native_test.py`
  — five passed, 0.233s.
- `bash -n scripts/run_linux_direct_first_run.sh` — 0.022s.
- `dart format --output=none --set-exit-if-changed integration_test/linux_direct_first_run_test.dart integration_test/support/direct_first_run_native_fixture.dart`
  — unchanged, 0.133s.
- `flutter analyze --no-pub` — no issues, 16.339s.
- `flutter test --no-pub --concurrency=1 test/features/enrollment/hermes_direct_first_run_test.dart test/features/hermes_chat/screens/hermes_connection_primary_entry_test.dart test/features/hermes_chat/screens/hermes_chat_screen_auth_recovery_test.dart`
  — 17 passed, 27.125s.
- `flutter test --no-pub --concurrency=1 -d linux integration_test/linux_direct_first_run_test.dart`
  — four native journeys passed, 212.101s including native compilation. Flutter
  ignores `--concurrency` for integration tests; the launcher starts one driver
  and bounds build concurrency to two.
- Scoped `git diff --cached --check -- <seven owned files>` — passed using an
  isolated temporary index, including new untracked files; shared staging was
  untouched. Changed local documentation links resolve.

The final public launcher command (269.796s total) was:

```sh
PKG_CONFIG_PATH="$PWD/build/t_95a5ae74/deps/root/usr/lib/x86_64-linux-gnu/pkgconfig" LIBRARY_PATH="$PWD/build/t_95a5ae74/deps/root/usr/lib/x86_64-linux-gnu" timeout 20m bash scripts/run_linux_direct_first_run.sh
```

User-space prerequisites followed the [retained recipe](native-relaunch-workflow.md#safe-user-space-prerequisites-and-reproduction):
13 apt-downloaded packages were extracted only into this card's ignored build
prefix; pkg-config prefixes were rewritten there. Installed runtime compatibility
was checked before execution. Flutter 3.44.2 / Dart 3.12.2, GTK 3.24.41,
GStreamer 1.24.2 and libsecret 0.21.4 were actually exercised. The bundle compiles
Wing Link but launches no management service. No system install or sudo was used.
The owned prerequisite prefix and disposable probe are removed after qualification;
reproduction requires preparing a fresh compatible prefix, not those deleted files.

The final archive contains 754 attributed Wing inputs, captured before checks:
`executed-source.tar.gz` SHA-256
`759dfbd39e2e5e610a32067b8f616ed6c2e73f434521e07cc394a528d61e625d`.
`source.json` records every preexisting dirty source hash and owner; it also lives
inside that verified archive. `dependencies.json` hashes transitive local package
source. Base HEAD is `b9eb5b3d9f6f3a433dd36cb6271ad8ec769b2319`; predecessor
first-run implementation is `046267501ae884fde73e5a0ea1dae02353d5c8c8`, not assumed
merged. The qualified candidate includes attributed dirty predecessor overlays,
not simply either commit's clean tree. None of those bytes is this card's output.

The source-run Python launcher imports the inherited
`scripts/support/desktop_no_inference_smoke.py`, then loads the isolated runtime
helper from Git object `894439b76c889fed45f3c4d57b73086f1e18d479`. Both dependencies
are fingerprinted; `executed-runtime-helper.py` retains the exact loaded helper.
The own-files agent commit alone is not a standalone launcher checkout: the
integration owner must assemble those inherited inputs/Git object, or reproduce
from the retained candidate with the same repository object available. Existing
helpers are deliberately not included in this card's owned diff. No packaged
launcher/image/distribution qualification is implied.

## Render inspection and retries

Twelve final native X11 captures have distinct hashes. Final wide connection,
compact 200% denial/retry and compact connected-session captures were loaded and
inspected. Local/SSH/Remote and the nested VPN choice are visible in the wide
capture. The compact denial shows sanitized auth guidance, focused Add Hermes
retry and separate optional setup after harness scrolling. Exact profile/history
and correctly disabled unsupported chat controls appear after activation. Some
existing compact labels/helper text ellipsize; they are not repaired in this
qualification-only card. These are native GTK captures, not browser substitutes.

The eight retained launcher attempts are not hidden: an omitted provider import
failed analysis; an environment-prefix omission failed prerequisite discovery;
three GTK runs exposed incorrect harness assumptions about imperative route
information, pairing Back consumption and supported default profile context.
A local synthetic-channel probe isolated the latter. A passing run's captures
showed only the test-start frame because overriding physical view metrics was
invalid for the real GTK surface. The integration binding's logical surface sizing
fixed it. A further capture adjustment explicitly revealed the focused retry and
primary choices. The final candidate then passed all checks again. Only final
renders support the visual qualification; earlier captures do not.

## Delivery and remaining gaps

Implemented: owned isolated first-run harness and regression/evidence artifacts.
Qualified: bounded deterministic Linux GTK production-UI behavior at the frozen
source fingerprint. Native fixture evidence is **not live authentication**.
Delivered to protected main: **NOT_CHECKED**. Local agent commit and same-card
review handoff are not merge, release or approval evidence. Goal bookkeeping marks
only this task done, not M1 met. Existing production and harness inputs stay
predecessor-owned; this card adds no production seam or feature.

Remaining M1: actual generation, correlated approval/Stop/relaunch, live auth,
authoritative model-pair persistence, managed SSH, Android, combined broader gate
and protected-main delivery. Secure storage, physical input, real network/auth,
platform audio and screen readers were not tested. Next slice remains the existing
`PARITY-LIVE-WORKFLOW` when supported disposable QA prerequisites clear; otherwise
continue the remaining connection/auth matrix. No new task is spawned here.

Questions: none. Defaults applied: deterministic GET-only transport, optional
management, externally established SSH and preservation of all predecessor bytes.
