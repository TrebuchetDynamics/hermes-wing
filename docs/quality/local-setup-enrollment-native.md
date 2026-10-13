# Direct Local enrollment and saved-owner recovery on native Linux

Card: `t_69ceda90`; bounded current-source qualification within
`CONNECTION-SETUP-AUTH-MATRIX` / `CONNECTION-PATHS`. The parent matrix and
`CONNECTION-LINK-REMOVAL` / `CONNECTION-LINK-RETIREMENT` remain open.
The previous `t_4c7cb087` setup/adoption/pairing journey is historical and
withdrawn as current qualification. Its counters do not apply to this journey.
No official Desktop parity is established; see the
[reference correction](official-desktop-reference.md).

## Implemented behavior and scope

Extended the existing shared journey, focused widget regression and native
receipt validator. No production change, new dependency, replacement harness,
installer, lifecycle operation, shell bridge or upstream edit was needed.
The existing Linux driver and launcher remain the entry points.

The real `WingApp`, public router, enrollment, direct connection panel,
`HermesApiChannel`, gateway directory, `SecureHermesEndpointStore` and
`GatewayContactCache` execute. The secure-storage platform is an in-memory fake;
Agent HTTP uses the existing credential-free `example.invalid` read fixture;
speech is disabled. Unexpected real HTTP clients fail and are counted.

Production `LocalHermesHomeDiscovery` and `IoLocalHermesHomePlatform` inspect
actual temporary missing/default `.hermes`/selected directories. A counting
wrapper delegates metadata inspection, using `tester.runAsync` for filesystem
completion. Its user-home input is an owner-only test directory, never a personal
Hermes home. Directory selection is a provider override returning cancellation,
then that selected test directory: this is NOT an actual OS chooser qualification.

## Acceptance evidence

Each journey uses keyboard Tab/Space through public controls, beginning with an
already-saved synthetic Agent endpoint and remembered profile/session. The saved
endpoint has no Agent credential; historical management fields and a separate
inert token slot are seeded in fake secure storage. Non-secret raw legacy
metadata and the remembered selection use preferences (mock preferences in the
widget suite; isolated native preferences on GTK).

1. Public Connect another gateway → optional setup → Local opens production
   enrollment. The missing-home result has no path and no connected channel.
   Chooser cancellation performs no selected inspection, write or owner change.
   Keyboard AppBar Back restores welcome and preserves the raw bundle, raw
   metadata, saved endpoint identity and remembered profile/session.
2. Creating a test `.hermes` directory makes the next public entry report a found
   directory. Selecting the alternate test folder updates only the ephemeral
   displayed path. Both results remain disconnected; the production explanation
   explicitly separates discovery from installation, service, authentication and
   model readiness. Platform Back returns to welcome with ownership/raw records
   unchanged. The native screenshot shows that explanation.
3. Explicit direct Connect receives a new synthetic 401 bootstrap denial, shows
   a sanitized live-region error and never renders `private-response` text.
   Bundle/metadata/remembered owner remain unchanged. A two-second observation
   produces no additional Agent reads: no automatic retry or mutation replay.
4. A later explicit Connect succeeds against the read fixture. Public contact
   activation uses the original saved gateway ID, Agent profile and exact
   `synthetic-history` session. All historical fields and the inert slot survive
   the production store save. No management credential is adopted as an Agent
   credential. This is credential-free recovery/persistence coverage, NOT real
   bearer authentication or secure-keychain qualification.
5. Every native receipt asserts four metadata inspections (three default, one
   selected), two chooser-seam calls, zero retired-slot reads/deletes, zero Link
   network operations, zero Agent mutations and zero forbidden Agent reads.
   The Python validator rejects missing, changed or non-integer counters and
   false/missing preservation receipts. Screenshot admission requires the exact
   phase/width/scale filename set, not just an old image count.

The four GTK journeys exercise logical 390×1000 and 1280×1000 surfaces at
100% and 200% text. `/proc` observation binds all four receipts to executable
`wing`, native PID `2015713`, driver process group `2014883`, start ticks
`269622993`. The driver, app and private authenticated Xvfb groups are torn down.
Wrong/missing display authority is rejected, no TCP display listener is exposed,
and isolated HOME/XDG/state is removed after teardown.

Actual screenshots: 20 phase captures plus an inspected contact sheet in the
receipt directory below. The full-size compact 200% denial and wide 200% found-home
captures were also inspected. Copy wraps without a Flutter overflow exception;
field labels/helper text can ellipsize at compact 200%. The existing GTK backing
window is shorter than the logical test surface: root captures clip the lower
viewport and are not proof that all controls are simultaneously visible. Tab/Space
activation and scroll-to-control are exercised; OS window resizing and assistive
technology speech output are NOT_CHECKED. Do not present these captures as a
physical-window-size or full accessibility acceptance claim.

## Admission, source and environment

Initial pre-edit admission succeeded (exit 0, `worker_start_admitted`):

```text
python3 /home/xel/git/gormes/hermes-toolset/skills/autowork/scripts/pass_workspace.py --manifest /home/xel/.hermes/profiles/wing/autowork/pass-f0db315c9fedb49b-61ac9bf267934aaca31579023f10bf7a.json --manifest-sha256 cb18d83e9f8b2aee0d63c87f75b508ea6dc2b959bb2a4a29d3057db649cb0d25 --workspace /home/xel/.hermes/profiles/wing/cache/scratch/autowork-passes/f0db315c9fedb49b-61ac9bf267934aaca31579023f10bf7a
```

Clean admitted base: `31d1bc3c90ee42d72a569f85d2b1f7fc9aba254c`.
Final native evidence (ignored, local):
`.task-evidence/t_69ceda90/attempt-bv_58t8l/`.
It contains `verification.json`, `source.json`, `dependencies.json`, scoped logs,
four native receipts, screenshots and an immutable `executed-source.tar.gz`.
Archive SHA-256:
`99becae0895983706f522606f28ba7452fe2d4c7e0b7ba297f936563ba3ad682`.
Source-manifest SHA-256:
`66716fc7a3381d40973d8e3fbe8a28f80fc5aa582ded7ff805986f41477b4634`.
All executed input hashes were checked again after execution. This receipt is not
a build input. The exact implementation commit is supplied by the finish gate
and native review handoff, not guessed here before committing.

Flutter 3.44.2 (`c9a6c48423`), Dart 3.12.2, Linux 7.0.0-31-generic x86_64,
GTK 3.24.41, GStreamer 1.24.2 and libsecret 0.21.4 were observed.
`pubspec.lock` SHA-256:
`f089602c321af4a65d6f1dc70b6adef724079bedc8e4f1d0496f7b8e22641c89`.
`package-lock.json` SHA-256:
`f32c4b4d226bf6cef1a1f66733d4c2e065e0656d1223e89f17ceb68f42429b63`.
Frozen transitive package-source manifest SHA-256:
`6ae7789069c2750a1a892a1c82a234776e3cc0d48e5d2aecc3f9e2a7ca34e3ba`.
Package-config/plugin/development archive identities are in `verification.json`.

The first launcher attempt failed because this isolated checkout lacked the
existing user-space GStreamer/libsecret development prerequisite. Non-secret
cached development dependencies were copied read-only from canonical into the
isolated checkout; no host packages or services were installed/changed. Initial
copy dereferenced links and failed on dangling documentation/library links; the
copy was repaired preserving all 59 link texts, then all 860 regular files and
links were compared with the source. Matching-copy manifest SHA-256:
`9cb492c0a407e5ff2e2d4c6438238efaa699f0c6d7ae336be6c08c165df5402c`,
at `.task-evidence/t_69ceda90/development-dependencies.json`.
The final native pass follows that repair and the final fixture assertions.

The unchanged launcher uses the heavyweight `flutter-owner.lock`, bounded
180-second ownership wait and two build jobs. It copies SDK/packages and uses
the existing reviewed process/display helper from
`894439b76c889fed45f3c4d57b73086f1e18d479` (SHA-256
`295299f3d23505ff115ceb03fbfac3d552889c2c3dd3eb775c4de8108d39dec6`).
It is a source-run development harness requiring the existing ignored
`.task-evidence/t_636ced72/deps/` extraction, not a portable end-user artifact.
Transitive source is retained with the frozen candidate.

## Exact checks and iterations

Baseline, before edits: focused enrollment plus `test/features/local_setup`
passed 14 tests; Python harness passed two tests. New fixture iterations exposed
an incorrect assumed public entry control, then pending filesystem completion,
then the old widget inspection count. These were fixture corrections, not
production defects; every named assertion remains exercised.

Final frozen native launcher command:
`timeout 9m bash scripts/run_linux_local_setup_enrollment.sh`
→ exit 0, `NATIVE_LOCAL_ENROLLMENT_PASS`, 176.055 seconds.
Within that exact frozen run:

| Command (copied SDK paths abbreviated) | Result | Seconds |
| --- | --- | ---: |
| `python3 -B -m unittest discover -s test/tooling -p local_setup_enrollment_native_test.py` | 2 pass | 0.080 |
| `bash -n scripts/run_linux_local_setup_enrollment.sh` | pass | 0.020 |
| `dart format --output=none --set-exit-if-changed integration_test/linux_local_setup_enrollment_test.dart test/features/enrollment/hermes_local_setup_enrollment_test.dart integration_test/support/local_setup_enrollment_native_fixture.dart` | unchanged | 0.130 |
| `flutter analyze --no-pub` | no issues | 17.349 |
| `flutter test --no-pub --concurrency=1 test/features/enrollment/hermes_local_setup_enrollment_test.dart test/features/local_setup` | 14 pass | 36.039 |
| `flutter test --no-pub --concurrency=1 -d linux integration_test/linux_local_setup_enrollment_test.dart` | 4 GTK pass | 108.303 |

An earlier expanded focused union including
`test/core/hermes/setup/legacy_endpoint_preservation_test.dart` passed 20 tests;
that unchanged preservation suite also covers retained Agent credentials,
failed writes and changed-origin non-reuse. Final finish-gate checks rerun this
union against the owned candidate. Three launcher attempts are retained: one
prerequisite failure and two GTK passes, the latter superseding the first after
metadata/live-region assertion additions and dependency-copy verification.
Monetary cost and independent review duration are unknown.

## Qualification and delivery boundary

Implemented: current-source fixture/receipt expansion; no production fix.
Qualified: isolated Linux GTK logical-size/text-scale journey using production
metadata/store/domain paths over the declared external fakes.
Delivery: scoped local commit and one independent native review are separate from
canonical integration/publication. This worker does not merge, push or mark the
parent matrix complete. Native review must bind the finish receipt, full commit
and task ref to the original admission and the retained source manifest.

NOT_CHECKED: actual OS folder chooser, real Agent authentication/provider
inference, actual secure keychain, physical/native window sizing, screen-reader
speech, Android/Termux device onboarding, full-suite/browser/release/distribution
acceptance. No historical result is relabeled as current proof. Next remaining
slice is Android/Termux direct setup/migration and separately authorized real
onboarding, not another retirement deletion or replacement backend.
