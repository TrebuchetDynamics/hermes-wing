# Native Remote authentication and uncertain-save retry

> Reference correction: [official Desktop authority](official-desktop-reference.md). Prior Desktop source citations and parity conclusions in this document are withdrawn. Wing test results remain historical behavior evidence only.


Card `t_2d93a7e9`; task `M1-NATIVE-CONNECTION-SAVE-RETRY`; milestone M1 remains partial.

## Implemented

This card adds a Linux GTK qualification harness, not a production behavior change.
The [native target](../../integration_test/linux_remote_connection_retry_test.dart)
uses production routing, the public first-run Add Hermes/Remote form,
`HermesApiChannel`, connection directory and real native SharedPreferences.
The [fixture](../../integration_test/support/remote_connection_retry_native_fixture.dart)
reuses the reviewed GET-only authority and injects faults at the existing endpoint-store
seam. Its in-memory persistence is NOT physical keychain qualification.
No production seam, Agent runtime, Wing Link service, upstream reference or other
profile was changed. Reference locations were confirmed as `hermes-agent/` and
`withdrawn source citation`; no deep upstream study or modification was needed.

## Acceptance evidence

1. All four GTK journeys start with empty endpoints at the production `/hermes`
   route. Tab/Space reaches Add Hermes, Remote, fields and explicit retry. A
   synthetic capabilities 401 renders generic authentication guidance, not the raw
   exception marker. It makes one connect and zero saves; idle time and focus do
   not retry. The deliberate retry connects to the exact synthetic
   `default` / `synthetic-history` owner. Production supports the advertised
   query-profile context with `default_profile_id=default`, not arbitrary defaults.
   The fixture distinguishes those session rows from the later directory owner.
   Public contact activation subsequently selects `synthetic-qa` /
   `synthetic-history`; equal session labels do not substitute for profile identity.
2. That successful connection encounters an injected save rejection. Connected
   host/profile/session and editable URL/name draft remain unchanged; the generic
   uncertainty notice does not claim persistence success or expose storage details.
   Idle does not retry or disconnect. Explicit Add Hermes admits exactly one
   connect/save, followed by the existing directory transition. Four additional
   delayed-save cases per layout cover success/error crossed with public form
   edits or a controlled channel-owner replacement. Pending Add Hermes is disabled.
   Late settlement cannot change the draft/owner, close the form, refresh the
   directory, emit replacement failure feedback or disconnect it. Each case admits
   exactly one save attempt. The replacement connect/profile/session is test
   injection, not a second public user journey. Across each journey: six save
   attempts, three fake commits; zero forbidden Agent reads, Agent mutations or
   enrollment management attempts. Send/session creation/approval/Stop and streams
   all fail and count at the fixture boundary. No Wing Link credential or network
   transport is provided; management callbacks count and reject any attempt.
3. The [launcher](../../scripts/run_linux_remote_connection_retry.sh) freezes and
   archives the Wing Linux qualification input closure before checks. It reuses
   reviewed snapshot/environment/process/display helpers rather than shipping new
   native integration. It copies the SDK and all external Dart package source into
   independent owned locations, rewrites plugin roots, records dependency hashes,
   authenticates its owned Xvfb display and rejects missing/wrong Xauthority.
   The adapter also copies the declared Wing Link Go module sources and their
   cached graph/download metadata into an owned `GOMODCACHE`. It archives every
   copied file, records module versions/checksums and the Go compiler version,
   resolves dependencies offline, and builds with `-mod=readonly`. Shared Go build
   cache, module source and downloads are not used by the native build. Source
   hashes are checked immediately after dependency preparation; Go dependency
   hashes are checked again after GTK execution. Go cache lock files are excluded
   as coordination state, not source. Graph metadata may include older versions;
   these are hashed and retained, not silently attributed as selected modules.
   Bounded process groups and isolated HOME/XDG/cache/state are removed after
   execution. Source hashes are checked after execution. The retained package
   archive was independently verified against all 17239 manifest files.
   Six Python regressions cover argument refusal, environment isolation, ownership
   attribution, rejected mutation/management/missing-recovery receipts, Go archive
   integrity/shared-cache isolation/read-only-directory teardown, and rejected
   missing or out-of-cache Go dependencies. No prerequisite helper or production
   CMake was changed.

## Checks

Final evidence: `build/t_2d93a7e9/attempt-k98schlk/` and the
[sanitized receipt](remote-connection-retry-native-receipt.json).
The receipt uses `flutter`/`dart` aliases for the isolated executable paths;
`verification.json` retains the actual argv, durations and exit codes.

- `python3 -B -m unittest discover -s test/tooling -p remote_connection_retry_native_test.py` — exit 0, six tests, 0.133s.
- `bash -n scripts/run_linux_remote_connection_retry.sh` — exit 0, 0.022s.
- `dart format --output=none --set-exit-if-changed integration_test/linux_remote_connection_retry_test.dart integration_test/support/remote_connection_retry_native_fixture.dart` — exit 0, 0.133s.
- `flutter analyze --no-pub` — exit 0, 15.747s.
- `flutter test --no-pub --concurrency=1 test/features/hermes_chat/screens/hermes_chat_remote_connection_retry_test.dart test/features/enrollment/hermes_direct_first_run_test.dart test/features/hermes_chat/screens/hermes_chat_screen_auth_recovery_test.dart` — exit 0, 28.179s.
- `flutter test --no-pub --concurrency=1 -d linux integration_test/linux_remote_connection_retry_test.dart` — exit 0, 378.363s.

Focused Dart suites: 33 tests passed. Native target: four tests passed, including
16 delayed-settlement cases. Final launcher duration: 460.506s.
The public command was:

```sh
PKG_CONFIG_PATH="$PWD/build/t_2d93a7e9/deps/root/usr/lib/x86_64-linux-gnu/pkgconfig" LIBRARY_PATH="$PWD/build/t_2d93a7e9/deps/root/usr/lib/x86_64-linux-gnu" timeout 12m bash scripts/run_linux_remote_connection_retry.sh
```

Flutter ignores integration-test `--concurrency`; the launcher runs one driver
and sets build parallelism to two. Flutter 3.44.2 / Dart 3.12.2, GTK 3.24.41,
GStreamer 1.24.2, libsecret 0.21.4 and Go 1.26.1 were exercised on Linux x86_64.
Missing development prerequisites were apt-downloaded and extracted into this
card's user-space prefix using the [existing recipe](native-relaunch-workflow.md#safe-user-space-prerequisites-and-reproduction).
No sudo or system install was used. The prefix is disposable; prepare a fresh
compatible prefix to reproduce. Package filenames and hashes are in the receipt.

## Attribution and source-run boundary

Frozen base: `b9eb5b3d9f6f3a433dd36cb6271ad8ec769b2319`.
`source.json` identifies each input and owner, including
115 inherited dirty inputs. These are not this card's changes.
The verified source archive contains 759 inputs;
SHA-256 `642d00fae39e286d34ff71e34f79e2ea4a53bb420006bbd702ac85892fbb2d7e`.
Package archive SHA-256 `ea4844adb658d1d8b08e4b70b3ced9d29f7e1fbe7777155efc82da53d8aa0345`.
Go module archive SHA-256 `a8806569d276e48b5ee36e044cb777ea24a1fb40bc40116c1f997ea5d2a20821`.
All 677 archived Go files and 17239 Dart package files were independently checked
against their manifests. The four selected Go modules are qrterminal v3.2.1,
x/sys v0.35.0, qr v0.2.0 and x/term v0.13.0; exact module identities/checksums
and `go version go1.26.1 linux/amd64` are recorded in the receipt.
The immutable source/package/Go archives, manifests, check logs, receipts and PNGs are
retained; copied SDK/app/build/state/display/prefix are removed.

The read-only prerequisite launcher and Dart authority match reviewed first-run
commit `45a80e42ad2724ed7bcede7e8dea4b26d4990a0c` byte-for-byte. They are not owned
outputs. The source-run Python closure includes inherited
`direct_first_run_native.py`, `desktop_no_inference_smoke.py`, and the loaded Git
runtime helper from `894439b76c889fed45f3c4d57b73086f1e18d479`.
`executed-runtime-helper.py` retains the exact loaded bytes. The owned-files agent
commit alone is not a standalone launcher checkout: integration must assemble
those attributed prerequisites/Git object or reproduce from the retained candidate.
Packaged launcher/image/distribution execution is NOT_CHECKED. The bundle compiles
Wing Link, but no service is launched and no management authority is added.

## Render inspection and retry history

Twelve actual native X11 renders were retained. Final wide uncertain-save,
compact 200% uncertain-save, auth rejection and connected-session captures were
loaded and inspected. Recovery feedback wraps readably; Add Hermes remains visible
and operable after assisted scrolling. Compact title and unsupported composer
labels ellipsize; this card does not claim those unrelated visual gaps are repaired.
The connected render identifies `synthetic-qa` and synthetic session history.

Logical 390/1280 widths and 1x/2x text were injected through the integration
binding into a real GTK surface. Tab/Space are logical events; `ensureVisible`
assists scrolling, and `enterText` inserts synthetic URL/name text. Physical
keyboard/IME, OS window resizing/text settings and screen-reader qualification
remain NOT_CHECKED. GTK execution is not Chromium or Android evidence.

All attempts are recorded, not hidden. Missing provider import failed analysis;
using the empty-only Add control after saving failed GTK; waiting for a pending
spinner with `pumpAndSettle` caused a foreground tool timeout. Its leftover owned
workspace was removed after confirming no owned process remained. An initial
four-layout pass was superseded to add exact connection-owner assertions.
A non-default query-context fixture was correctly rejected; a later flow-control
lint failed analysis. The final corrected candidate reran every scoped check and
passed. No product defect was demonstrated or production repair made.

The first review requested complete Go dependency attribution because Linux CMake
also compiles Wing Link. During correction, one preparation failed on missing
disposable development prerequisites and exposed copied Go directories retaining
read-only permissions; its abandoned owned workspace was removed after checking
no process referenced it. A later run passed all scoped checks and all four GTK
journeys but correctly failed the final source-integrity check: `go mod download
all` adds test-only dependency sums to `go.sum`. An isolated probe reproduced that
change. The adapter now freezes declared build modules without `all`, preserves
the source lockfiles, and checks source integrity before expensive checks too.

## Delivery and remaining gaps

Implemented: owned native recovery harness, launcher/regressions and evidence.
Qualified: deterministic Linux GTK auth/save recovery at this frozen input closure.
Delivered to protected main: NOT_CHECKED. Local agent commit and same-card native
review handoff are not merge, release or M1 completion. Goal bookkeeping closes
only this named task. Shared dirty goal-ledger changes remain separately owned.

Remaining M1: actual Agent authentication/generation/approval/Stop/relaunch,
physical keychain persistence, automatic model-pair readback, managed SSH and
protected-main delivery. Android, live TLS/network/credentials, full repository
gate, audio and packaged distribution are NOT_CHECKED. Next slice remains the
accepted native connection matrix or live prerequisites when genuinely available;
this card enqueues no new task. Measured check durations are in the receipt;
usage/cost and review duration are unknown.

Questions: none. Defaults applied: GET-only fixture, no inference or personal
credential discovery, existing contracts and preserved inherited ownership.
