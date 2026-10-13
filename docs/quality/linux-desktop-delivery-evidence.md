# Linux installed-client delivery evidence

Card: `t_ff18519b`. Backlog: `DOC-DESKTOP-DELIVERY-EVIDENCE`.
Goal: `DESKTOP-DELIVERY` (partial; unchanged).

## Result and source identity

This is an offline source-bound inventory, not an installed Linux qualification.
The admitted Wing source is `d3360c7fd46e59be133c88e763ecf4aab9dbaa75`, tree
`bb28b33cdb48e85780d281532bc72cbe2ab4e470`. All source ranges below refer to that
commit, not a remote release or the current upstream branch. The original clean
isolated workspace passed `pass_workspace.py` before design, tests or edits;
manifest `pass-abd5be188eba9c2e-a73d6f54e9224bb7bc84a8d0de95d75e.json` SHA-256:
`b4b492cf4c8a3148c01772bdb14bfd4d2929b508304adfc9812f9b31c3b9c63c`.
The frozen finish commit and `agent/wing/t_ff18519b` ref are recorded by the native
handoff; a document cannot embed its own final commit hash without changing it.
Independent review must verify original admission history and that exact ref.

Only this receipt changes. Scripts, callers, CMake, fixtures, tests, workflow,
lockfiles and canonical ledgers remain unchanged. Compilation, source tests and
synthetic receipts do not establish installed-client activation, health or rollback.
The [delivery ADR](../adr/runtime-and-delivery.md#agent-only-delivery) requires
named-target evidence. `DOC-DESKTOP-UNINSTALL-EVIDENCE` remains a separate slice.

## Installed path and release path

| Boundary | Inspected producer / consumer | Evidence ceiling and missing proof |
| --- | --- | --- |
| Public source install/update | [installer](../../scripts/install_linux.sh):43–53 runs `flutter pub get`, then [build helper](../../scripts/run_linux_release_build.sh); requires executable `build/linux/x64/release/bundle/wing` | Running the same installer replaces an existing bundle. It does not consume the CI archive, checksum sidecar or release manifest; it emits no source/artifact/target-bound installation receipt. This invocation did not run it. |
| Build dependency closure | Build helper:9–14 uses installed libsecret and GStreamer pkg-config inputs; otherwise :17–102 downloads/extracts Debian development/runtime packages into a local prefix and wraps paired clang executables | Local apt package versions, system libraries and compiler inputs are not recorded by a delivery receipt. Rootless dependency setup is a build technique, not target-library availability or installed health proof. |
| Complete client bundle | [Linux CMake](../../linux/CMakeLists.txt):7–17, 75–86, 89–139 installs `wing`, Flutter/AOT libraries, native/plugin libraries and data/assets; binary RPATH is `$ORIGIN/lib`, plugins use `$ORIGIN` | Copying only `wing` is not the delivered client. Source relocatability assertions do not prove actual runtime resolution on a named installation target. |
| Activation | Installer:55–80 copies the whole bundle into sibling staging, renames an existing installation to backup, then renames staging into place | Install-directory symlinks are rejected. Only a failed final rename attempts restoration of backup; no installed-byte comparison, health gate or successful restoration receipt exists in this path. |
| Launcher and recovery boundary | Installer:79–91 deletes backup **before** writing/chmodding the `hermes-wing` shell launcher; launcher executes the installed `wing` with forwarded arguments | A launcher-write/chmod failure or subsequent unhealthy client occurs after backup deletion. The EXIT trap only removes staging before activation, not a general recovery transaction. The rename-failure branch is not post-activation rollback. No retained verified predecessor or health-triggered rollback is demonstrated. |
| Menu/client entry | [GTK runner](../../linux/runner/my_application.cc):71–130, 174–203 creates Settings/About/Window/View menus, registers plugins and shows the window on first Flutter frame; [listener](../../lib/app/desktop_host_command_listener.dart):49–58 routes `openSettings` to existing Settings | This is the in-window application menu, not an OS launcher installer. The installer creates no `.desktop` entry. Process survival alone does not observe first frame, operable menus, Settings routing, keyring access or retained endpoint/profile/session identities. Menu source and [listener tests](../../test/app/desktop_host_command_listener_test.dart) were inspected, not natively exercised. |
| CI archive and manifest | [release-alpha workflow](../../.github/workflows/release-alpha.yml):153–192 builds a Linux x64 archive plus sidecar and invokes [release evidence](../../scripts/release_evidence.mjs):53–99, 188–230 to emit `linux-release-evidence.json` | Manifest binds revision, dirty flag, version/build, tag, repository, CI run/attempt, lockfile digests, artifact size/digest and observed Node/Flutter versions. Linux signing identity is null. This is not an installed generation or a named desktop target identity. |
| Pre-publication host gate | [verifier](../../scripts/verify_release_artifacts.sh):40–121 checks exact inventory, manifests and checksums; :168–234 inspects bounded safe archives and launches extracted `bundle/wing` under Xvfb for five seconds, checks PID, then kills it | No installer/launcher is invoked and no previous generation is used. `linux_bundle_launch` is archive-process smoke, not installed activation, first-frame health, retained-state update or rollback. The script executes candidates and was not run here. |
| Receipt aggregation/publication | Verifier:251–288 produces `release-verification-receipt.json`; evidence:124–186 binds that host receipt and the separate Android smoke receipt; workflow:223–262, 322–421 gates, aggregates and publishes | `release-qualification-index.json` binds bytes/identity but has no Linux installed-target activation/health/rollback phase consumer. Publication and CI success are not that missing scenario. No workflow was dispatched or remote artifact inspected. |

The verifier's initial allowlist is exactly three evidence JSON files, Android
APK/AAB with individual sidecars, and Linux/web archives with individual sidecars
(verifier:40–52). A previous host receipt or smoke file is not an initial verifier
input. Its bounds, signature checks and archive containment must not be relaxed.

## Identity and dependency inputs

The proposed qualification subject is an installed **Linux x64 Flutter client**,
not an Agent service. No target was selected or exercised; OS/distribution,
desktop session/display, runtime-library versions, installed bundle and launcher
identities, predecessor identity and observation timestamps are NOT_CHECKED.
No candidate tag, artifact digest or installed generation is available here.
Scoped probes found no `dist/linux-release-evidence.json`,
`dist/release-verification-receipt.json` or `dist/release-qualification-index.json`
in this isolated checkout. This is not a claim that artifacts exist nowhere.

Offline check tools: Flutter 3.44.2 (framework `c9a6c48423`), Dart 3.12.2,
Node v26.7.0, Python 3.12.14. Repository/CI baseline is Flutter 3.44.2 and Node 22;
Node 22 qualification is **absent** from this run. Synthetic test manifests that
say `v22.0.0` do not change the actual executing Node version. Offline enforced
lockfile resolution succeeded; both tracked lockfiles remained unchanged:

| Input | SHA-256 |
| --- | --- |
| `pubspec.lock` | `f089602c321af4a65d6f1dc70b6adef724079bedc8e4f1d0496f7b8e22641c89` |
| `package-lock.json` | `f32c4b4d226bf6cef1a1f66733d4c2e065e0656d1223e89f17ceb68f42429b63` |

CI Linux build inputs additionally include clang, CMake, Ninja, pkg-config, GTK,
libsecret and GStreamer development packages; its verifier installs runtime
libraries and Xvfb. The manifest records Node/Flutter and the two lockfiles, not
those native package versions or an installed desktop environment. No native
build, system dependency installation or npm dependency installation ran here.

## Historical and official reference limits

The [alpha runbook](../runbooks/release-alpha.md):35–40 distinguishes archive
checksums from canonical signed APT/RPM distribution and matching-device support.
The [older M6 inventory](2026-10-06-m6-artifact-evidence.md) and
[Linux service observations](linux-service-receipts.md) describe a retired
Wing Link lifecycle chain, not current installed-client receipts. The referenced
`record_linux_service_qualification.mjs` is absent from this admitted source;
its service phases must not be reused as client support or restored here.

Read-only official Agent/Desktop reference: commit
`158fd638da1629c8e62caf9ade1515d162def8ab`. Root and Desktop `AGENTS.md` instructions
were inspected before comparison. Official
`apps/desktop/electron-builder.config.cjs`:279–286 targets AppImage; Wing's path
above is a source-built Flutter bundle and shell launcher. Official source shows
a different packaging contract, not execution evidence for Wing or permission
to port Electron internals, bundle/modify Agent or add host lifecycle authority.
No upstream tests, builds or mutations ran.

## Executed offline checks

All commands ran in the original isolated workspace at the admitted source plus
this receipt only; required checks are replayed by `finish_task.py` before commit.
No failure/recovery retries were needed for the initial check batch.

- `timeout 120s flutter pub get --offline --enforce-lockfile` — PASS.
- `git diff --exit-code -- pubspec.lock package-lock.json` — PASS, unchanged locks.
- `timeout 180s flutter test --no-pub test/tooling/package_scripts_contract_test.dart --name '^Linux'` — PASS, three source-contract assertions: pre-build launcher symlink guard, paired compiler executables and plugin RPATH.
- `timeout 180s flutter test --no-pub test/tooling/release_workflow_contract_test.dart --name '^(release publication|release workflow actions|alpha artifacts|alpha release publishes|exact artifacts|alpha tag|existing release)'` — PASS, eight source-contract tests. The verifier-executing negative test and Node-wrapper test were deliberately excluded; no shell verifier was executed.
- `timeout 180s flutter test --no-pub test/app/desktop_host_command_listener_test.dart --plain-name 'desktop hosts retain canonical Hermes Wing identity and menu wiring'` — PASS, one host-source wiring test; no widget or native menu interaction ran.
- `timeout 120s node --test test/tooling/release_evidence_test.mjs test/tooling/compare_release_candidate_test.mjs test/tooling/record_release_qualification_test.mjs test/tooling/ci_gate_test.mjs` — PASS, 109 tests, initial Node-reported duration 3754.79863 ms. Fixtures exercise digest/identity/schema/receipt rejection and offline comparison, including Linux artifact mutation; Android recorder tests inject inspection, not ADB/device execution.
- `bash -n scripts/install_linux.sh scripts/run_linux_release_build.sh scripts/verify_release_artifacts.sh` — PASS, syntax only.
- Local Python standard-library Markdown target/heading-anchor validator for this receipt — PASS, 13 local links; exact executable code is retained in the native check receipt and replayed at finish.
- `git diff --check` — PASS, replayed at finish; the local validator additionally checks this new untracked receipt for trailing whitespace before commit.

These qualify only offline source-contract and synthetic evidence handling on
this Linux-hosted toolchain. Full Flutter analysis/suite, browser/native UI,
installed update/recovery, real release verification, signing and distribution
are NOT_CHECKED. Total elapsed/review time and cost were not measured; review is
pending independently, not a passed check.

## Smallest successor proposal

Return to coordinator `wing`, without creating or dispatching another card:
qualify one installed-client update failure **after bundle rename but before
launcher/health acceptance**, with a distinct verified predecessor. First address
backup deletion preceding launcher/health acceptance in the existing installer,
with the smallest isolated filesystem regression; then, under separate explicit
target/candidate execution authority, bind candidate and predecessor source/tag,
manifest/archive digests, complete installed bundle/launcher identity and named
Linux OS/architecture/display/runtime inputs to observed activation, first-frame
and operable Settings health, failure, restored predecessor bytes and restored
health. Preserve saved Agent credential and exact endpoint/profile/session
identities; publish only redacted/allowlisted observations, never secrets, private
paths or transcripts. Do not invent a health API, updater, service or signing
claim to fill the gap. This proposal is not authorization for execution.

DESKTOP-DELIVERY stays partial; uninstall retention/removal evidence and signed
distribution remain separate. No completed retirement work is reopened.
Ponytail full: one receipt reuses existing producers/tests; no abstraction,
dependency, updater, guard task, extra reviewer, ledger edit or live action.
