# Linux accessibility, lifecycle and voice boundaries

## Scope and verdict

The [access target](../../integration_test/linux_access_feature_qualification_test.dart)
and [fixture](../../integration_test/support/linux_access_feature_fixture.dart)
implement the offline access slice of the
[Linux campaign](../plans/2026-10-21-linux-feature-qualification.md).
They exercise current Wing controls, not a new Agent API or product feature.
Hermes Agent remains authoritative; synthetic channels never contact an Agent,
provider, personal service or credential store.

**Overall Linux qualification remains PARTIAL.** Framework semantics, geometry,
keyboard events and lifecycle injection are not screen-reader, physical input,
Wayland/IME, microphone or acoustic qualification. Synthetic capture cancellation
is not a positive audio result. No application installation/update/removal or
release publication is performed.

## Case inventory

All cases run in the Linux Flutter engine on an owned Xvfb X11 display. Preferences
are mocked except where separately identified. Agent state is volatile and
synthetic. Native PID, exact owner and operation counts accompany each row.

| Case ID | Executed seam and failure oracle |
| --- | --- |
| `access-footer` | Reuses the existing profile-footer journey: Tab/Shift+Tab, Enter/Space, painted focus, 100/200% text, expanded/collapsed/compact-return, obsolete owner notifications, Profiles route return and zero incidental reads/mutations. Four synthetic channel owners; mocked preferences. |
| `access-status` | Reuses status presentation/inspection at 390/1280px and 200% text; current full model semantics and geometry, recovery/failure/replacement without stale model labels or mutations. Four resource owners across two fixtures. This is framework semantics, not a screen reader. |
| `access-keyboard` | Light/dark, 1280→390→1280px, 200% text and reduced motion: editor plus six named composer actions remain hit-testable, within the viewport and keyboard reachable. Enter opens the real model picker; Escape restores its original launcher focus. Retained same-owner draft, no sends/model writes. The focused model action also survives normal channel/profile replacement without traversal repair; an obsolete owner notification cannot change the replacement draft or steal its subsequently acquired editor focus. Four owners across both themes. Checks alpha-composited editor foreground against its opaque painted composer container at ≥4.5:1, not whole-screen contrast certification. |
| `access-voice-unavailable` | Linux default capture is absent; explicit Live voice entry offers Continue in text. Draft stays editable; zero capture/playback/sends. |
| `access-voice-denied` | Deferred synthetic draft capture reports permission denial through the public service seam; safe inline failure, retained text and no automatic retry/send. This does not exercise an OS permission dialog. |
| `access-voice-cancel` | Explicit draft-dictation cancel rejects a late recognized result, retaining the existing draft without re-arm/send. |
| `access-voice-background` | Active Live voice receives framework inactive/resumed events. Cancellation and late-result rejection prevent automatic resume/re-arm/send; this is not OS minimization. |
| `access-voice-owner` | Replacement channel/profile ends an active Live loop. The text editor returns, is keyboard reachable and retains its replacement draft/focus through an obsolete recognition completion. Both channels' sends and writes are checked. Live voice replaces the editor, so this does not assert automatic focus transfer from the removed Live surface. |
| `access-voice-dispose` | Unmount an active Live loop, then complete obsolete capture. No sends, playback, re-arm or framework exception. No claim that a disposed route's volatile draft is persisted. |
| `access-voice-playback` | One deliberate synthetic text send starts deferred speech. Explicit Stop precedes late playback completion; the new draft remains editable, without capture, automatic send or stale playback revival. |
| `access-host-command` | Production bounded Settings listener handles a framework platform message and Ctrl+, without constructing an Agent channel. Not a click on the OS menu. |
| `access-export` | Public transcript actions copy to the real owned GTK clipboard, cancel the real GTK Save File chooser, then explicitly confirm a save and compare exact UTF-8 bytes. Only chooser keys are OS-injected through X11; action taps are framework events. No older-history read or send. |

The editor's semantics check verifies its text-field role and current value;
non-editor actions require a nonempty semantics label/tooltip. Owner replacement
focus preservation is tested on the stable model action, not on the old editor:
`_syncComposerDraft` deliberately retires its platform input client to prevent
queued IME events from editing a different owner's draft. This safety boundary is
unchanged. Resizing uses
`setSurfaceSize` plus the test view, not a physical window resize. Reduced-motion
coverage checks the requested media setting and absence of composer scale
transitions, not all application animation. Receipt evidence contains only
synthetic UI observations; private output roots are never committed.

## Invocation and receipts

Use Flutter 3.44.2 / bundled Dart 3.12.2, Node 22, checkout-local offline package
metadata, explicit `PUB_CACHE` and the reviewed disposable native prefix described
in the [driver guide](linux-qualification-driver.md). The host must also provide
`/usr/share/mime/mime.cache` from `shared-mime-info`; missing metadata fails the
fixture rather than enabling inherited data roots. This is not a hermetic
cross-distribution qualification. Use a **fresh** private output directory under
`TMPDIR`:

```sh
python3 scripts/run_linux_feature_qualification.py --lane access \
  --output-dir "$TMPDIR/linux-qualification"
```

The fixed driver owns Xvfb, D-Bus, HOME/XDG, source/dependency fingerprints, command
exits/log digests, process-group observation and final cleanup. It registers this
target followed by the existing compact-return persistence runner; this lane does
not modify its registration. The target validates its launcher-owned root,
HOME/XDG identity and marker before running. Python temporary suffix underscores
are accepted by the shared root validator; parent, canonical path and marker
checks are unchanged.

Only after **all 12** cases finish does the target atomically rename
`feature-cases.pending` to `feature-cases.json` directly under
`WING_LINUX_TEST_ROOT`. Rows use the driver's schema-1 fields, not a parallel
receipt schema. The GTK process stays alive briefly for driver observation.
Missing or failed cases cannot produce a complete receipt. The driver adds
source/command/log bindings; a standalone target receipt is not a passing
campaign receipt.

### Local evidence and limitations

The **registered access lane passed** with Flutter 3.44.2 / Dart 3.12.2,
Node 22 and the validated cached native prefix (GTK 3.24.41, GStreamer 1.24.2,
libsecret 0.21.4). Its two fixed commands exited 0: all **12 native feature cases**
and the **compact-return persistence journey**. The private schema-1 campaign,
source/tool bindings, log/case digests and observed GTK process identities remain
with the worker report. Both command groups exited and owned state was removed.
This is current-source offline fixture evidence, not aggregate Linux acceptance.

The feature target uses owned Xvfb/X11, D-Bus and HOME/XDG. The export case seeds
only the stock system `shared-mime-info` cache into its owned XDG data directory
and records the copied bytes' SHA-256. It does not inherit host data search roots,
copy user MIME settings, mock the chooser or change GTK/package/SDK sources.
Export teardown clears its clipboard and deletes its owned directory; widget
teardown unmounts the tree and restores view, focus-highlight and hit-test settings.
The driver removes the MIME metadata with the rest of its owned state. The separate compact-
return runner uses another owned Xvfb/HOME/XDG with **real Linux preferences** and
no inherited D-Bus. It verified keyboard collapse, 1280→390→1280px framework
reflow, retained editor/draft/provider scope, unchanged saved collapsed intent
and zero Agent reads/sends/mutations. Its preferences JSON was read back before
cleanup. This does not establish cold-relaunch, keyring or physical-window input.

The retained earlier candidate had corrected a stale 250px expanded-sidebar
oracle; current `AppShell` and its existing layout/persistence widget checks
specify **237px expanded / 64px collapsed**. This retry preserves that narrowly
scoped fixture/receipt-validator correction, with no product layout or persistence
change.

This retry reproduced the later integration failure: eleven cases passed, then
GTK aborted on its first Save File chooser and neither export nor teardown
completed. The compact-return command was not dispatched in those failed runs.
A private native trace identified `ensure_surface_for_gicon`: GTK could not decode
its own fallback PNG because the isolated `XDG_DATA_DIRS` had no MIME database.
A bounded GdkPixbuf probe failed with empty owned data and decoded the same stock
resource after seeding only the public MIME cache. The fixture now prepares that
metadata before opening the real chooser; all cancellation, explicit consent,
exact UTF-8 readback and cleanup assertions remain. The complete registered lane
then passed on fresh output. Failed attempts remain private evidence, not passing
receipts.

The current shared validator accepts stock native-only plugins and the SDK's
versionless `sky_engine`; offline package preparation required no package, SDK,
lockfile or generated-import-URI rewrite. No shared driver registration or
validation change was made by this lane. Driver unit tests and runner self-checks
remain harness checks, distinct from the executed native persistence journey.

Before adopting the earlier access candidate, all three named managed-SSH modules
ran **together** against the current verified `MAIN-REPAIR-003` deterministic
storage/owned-port fixtures: **44/44 passed**. No fixed-port remapping, listener
shutdown, product authentication/recovery change or flaky classification was used.
The older held candidates' standalone or isolated results are not current passes.

Artifact tooling (`install_linux.sh`, `run_linux_release_build.sh`,
`verify_release_artifacts.sh`) was inspected and syntax-checked only. Installer
staging/activation, signature/digest verification, retained keyring, upgrade,
removal and rollback are **not runtime-qualified** by inspection or syntax.

## Retained qualification owners

- `PARITY-NATIVE-LINUX-LIVE`: actual Agent/SSH/OAuth, physical microphone/audio,
  acoustic playback/interruption, screen reader, Wayland and actual IME.
- `VERIFY-SHELL-NATIVE-INPUT`: physical keyboard/window and OS menu activation.
  Mock preference journeys do not prove persisted intent or real native input.
- `VERIFY-DESKTOP-NATIVE-DELIVERY`: exact-artifact install/upgrade, retained
  keyring, client-only removal and authorized failure/rollback on a disposable
  target.
- `PARITYGAP-002-76-LIVE`: full GTK export qualification including overwrite,
  owner-change and live-history acceptance is not waived by this bounded case.

The final evidence join must consume the source-bound registered lane receipts,
not substitute older standalone results. Normal coordinator merged-tree review
and integration remain separate from this worker's checks. Existing live-task
acceptance and the pinned feature matrix remain unchanged.
