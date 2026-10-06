# M6 exact-artifact receipt inventory and recovery gaps

Card: `t_8daadbc0`. Backlog: `DOC-M6-ARTIFACT-EVIDENCE`. Date: 2026-10-06.

## Result and evidence ceiling

Delivered a source-bound inventory of the existing alpha receipt chain, not an
artifact qualification. M6 remains **unverified / not release-ready**. The
[roadmap outcome](../../ROADMAP.md#m6--deliver-an-integrated-qualified-alpha)
is an installed integrated workflow with safe upgrade and recovery, not archives
or green source CI. No architecture or release requirement changes here.

The checkout is dirty. Its base commit is
`4acdb4e1f51262ccfdca5174776eed1e3ef65188`; this is context, not candidate identity.
The [source inventory](../../.task-evidence/t_8daadbc0/source-inventory.json)
binds the inspected files by SHA-256 and byte length and captures the original
M6/TODO source sections. It is explicitly an offline-source-inventory receipt,
not a `release-qualification-index.json`.

No build, dependency installation, candidate extraction/execution, verifier run,
Flutter suite, browser, device discovery, OS installation, live Agent/inference,
service action, signing-secret lookup, network request or publication ran.
Retained flutter_tester PID 96817 and shared Flutter/build/fixture/display resources
were untouched. Existing production code, workflows, scripts, tests, runbooks,
architecture and upstream clones remain read-only. No runtime dependency is added.

## Candidate receipt admission and scoped absence

The offline check probed only the fixed release receipt names in root `dist/`
(the workflow/runbook candidate directory) and `docs/quality/` (public evidence
location). None was present at those exact paths: candidate qualification is
**NOT_CHECKED**, not a failed verifier or a claim that no candidate exists anywhere.
The 18 exact probes and results are in the source inventory. No home, secret,
shared build, arbitrary artifact directory or unrelated task-evidence sweep ran.
CI downloads, remote releases and manual `build/receipts` outputs were not checked.

The existing [public Android regression JSON](android-physical-regression-2026-09-04.json)
was parsed offline, not replayed. It names Samsung SM-S928B, Android API 36, arm64,
a debug `.qa` package and deterministic Agent fixture; its source base is
`32c98a42d3526e2e95f8882e6eb7c1ba7c2e9582`. Its recorded APK hashes distinguish
feature-test and `lib/main.dart` artifacts. This is historical fixture/device
reporting, not this dirty source, release signing, live provider, upgrade or M6
qualification. Microphone capture and audible playback are explicitly false.
The [older evidence matrix](evidence-matrix.md) similarly retains historical
source/target ceilings. No historical receipt is imported into the release index.
The [M2 preflight](2026-10-06-m2-android-preflight.md#result-and-evidence-ceiling)
is source prerequisite evidence, not Android process death or an M6 receipt.

## Receipt producer and consumer matrix

All rows below are INSPECTED contracts. Their runtime result here is NOT_CHECKED.
Line ranges refer to fingerprinted working-tree files, not remote-latest source.

| Producer / exact output | Consumer and binding | Scope and limit |
| --- | --- | --- |
| `android` workflow, lines 120–211: `android-release-evidence.json`, `android-termux-bootstrap.json`, signed APK/AAB and separate sidecars | `release_evidence.mjs emit android .` records APK/AAB size/digest and generated input digest. Host verifier calls `verify android` before archive work. | Bootstrap metadata binds tag, installer commit/digest, Android Wing Link asset digest/size; APK and AAB must carry identical metadata. Build/signature evidence is not installation or AAB/store delivery. |
| `linux`, lines 214–249: `linux-release-evidence.json`, Linux x64 archive/sidecar | `emit linux`; host `verify linux`, checksum/safe extraction/launch | Requires regular `bundle/wing` and `bundle/wing-link` members. Host smoke launches Wing for five seconds; it is not integrated Chat or service lifecycle. The host version checks execute standalone Wing Link files, not the bundled helper. |
| `web`, lines 251–278: `web-release-evidence.json`, static web archive/sidecar | `emit web`; host `verify web`, checksum/extraction, loopback packaged Playwright smoke | Production `flutter build web --release`, not the deterministic `main_e2e` build. Requires regular index/main JS/bootstrap files. Browser initialization/title/error checks are not actual backend workflow. |
| `wing-link`, lines 280–323: `wing-link-release-evidence.json`, six binaries, `wing-link-checksums.sha256` | `emit wing-link`; host `verify wing-link` and format/version checks; separate native jobs below | Cross-compilation and foreign format inspection do not qualify a host service. Android arm64 receives no matching-device version execution in this workflow. |
| `verify-artifacts`, lines 325–364: `release-verification-receipt.json` in `hermes-wing-verified-release` | Verifier checks exact pre-receipt input inventory; aggregate binds receipt bytes/cert/tag/revision/checks and every input file digest | Host receipt combines native Linux, QEMU arm64 and packaged browser launch. It does not supply the separate platform smoke files or an integrated install/upgrade/recovery receipt. |
| `android-artifact-smoke`, lines 366–422: `android-artifact-smoke.txt` / `android-artifact-smoke-receipt` | Aggregate checks exact APK/manifest hashes and tag/revision/run/attempt/build; `emulator`, `apk-install-launch`, `verified-installed-launched` | API 34 Google APIs x86_64 pixel_6 emulator. Verify one APK signer, install, pull single `base.apk` back and compare digest, launch/PID check, uninstall. This clean smoke is not upgrade, rollback, retained-state recovery, physical device or AAB delivery. |
| `wing-link-macos-smoke`, lines 424–458: `wing-link-macos-smoke.txt` / `wing-link-macos-smoke-receipt` | Aggregate accepts selected Darwin artifact digest and manifest hash; `native`, `binary-version`, `verified-ran-version` | Runner `uname -m` chooses only one of arm64/amd64. Other architecture is checksummed/formatted, not executed. This is Wing Link `version`, not Flutter macOS or launchd qualification. |
| `wing-link-windows-smoke`, lines 460–497: `wing-link-windows-smoke.txt` / `wing-link-windows-smoke-receipt` | Aggregate accepts Windows amd64 artifact/manifest hashes with the same native version contract | PowerShell checksum inventory/hash check then `version`. Not Flutter Windows, installation, Windows service or recovery. |
| `release-readiness`, lines 499–513 | `ci_gate.mjs release` requires exact job inventory and every required result `success` | CI statuses are an admission gate, not a new behavioral receipt. |
| `publish`, lines 515–601: `release-qualification-index.json` | Downloads verified bundle and separate smoke receipts, runs `aggregate dist` before `gh release create` | Final index binds manifests, payloads, auxiliary files and host/platform receipts. New prerelease/tag operations are outside this card. It does not import manual lifecycle/voice evidence or prove applicable M1–M5 integration. |

Sources: [workflow](../../.github/workflows/release-alpha.yml),
[verifier](../../scripts/verify_release_artifacts.sh),
[evidence implementation](../../scripts/release_evidence.mjs),
[CI gate](../../scripts/ci_gate.mjs),
[packaged browser smoke](../../playwright/tests/regression/release-artifact.spec.mjs).

## Exact verifier input allowlist

These are the 20 nonempty regular top-level files required before the host
receipt exists (`verify_release_artifacts.sh:40–80`). Extra files, non-file
entries, missing/empty entries fail admission. Do not place the platform smoke
receipts or a prior host receipt into this initial directory. Successful host
verification adds its receipt; publication later adds separate smoke files and
then the aggregate index. A verifier rerun needs a fresh initial candidate set.

| Group | Exact names |
| --- | --- |
| Evidence and generated metadata | `android-release-evidence.json`, `android-termux-bootstrap.json`, `linux-release-evidence.json`, `web-release-evidence.json`, `wing-link-release-evidence.json` |
| Android payloads and sidecars | `hermes-wing-android.aab`, `hermes-wing-android.aab.sha256`, `hermes-wing-android.apk`, `hermes-wing-android.apk.sha256` |
| Client archives and sidecars | `hermes-wing-linux-x64.tar.gz`, `hermes-wing-linux-x64.tar.gz.sha256`, `hermes-wing-web.tar.gz`, `hermes-wing-web.tar.gz.sha256` |
| Host payloads and checksum manifest | `wing-link-android-arm64`, `wing-link-checksums.sha256`, `wing-link-darwin-amd64`, `wing-link-darwin-arm64`, `wing-link-linux-amd64`, `wing-link-linux-arm64`, `wing-link-windows-amd64.exe` |

Checksum manifests must cover exactly the named payloads once, with bounded
basename-only names; one sidecar per client payload and six entries in the Wing
Link checksum manifest (`verifier:82–121`).

## Revision, signing and host admission

- Use the candidate's actual source checkout, not today's HEAD. `GITHUB_SHA`
  must be 40 lowercase hex characters; tag is `vVERSION-alpha.N`. Workflow tag
  validation binds app version and refuses an existing release or a tag at a
  different revision. This slice did not check tag existence or remote state.
- Evidence identity contains `source_revision`, `source_dirty`, `version`,
  `build_number`, `run_id`, `run_attempt`, `repository`, `tag`. Verification
  compares all except `source_dirty` against `currentIdentity`: local defaults
  run/attempt `0`, repository `local/hermes-wing` will not match a hosted CI
  manifest. Preserve the candidate's recorded public identity when later
  invoking verification; the runbook example alone does not set these fields.
  Dirty status is recorded, not a clean-tree guarantee. The script does not
  prove `GITHUB_SHA` equals the checkout; candidate source admission is still
  required by the runbook.
- Input digests are `pubspec.lock`, `package-lock.json`, `wing_link/go.mod`,
  `wing_link/go.sum`; Android adds `assets/config/termux_bootstrap.json`, verified
  against traveling `android-termux-bootstrap.json`. Payloads are bounded regular
  non-symlink files, including parent paths; up to 2 GiB each, inputs up to 16 MiB,
  JSON up to 128 KiB, smoke text up to 8 KiB. Recorded toolchains are Node plus
  Flutter (client) or Go (Wing Link), read from installed tools at emission.
  These input hashes do not replace a full source revision or runtime qualification.
- `WING_RELEASE_CERT_SHA256` is the public expected Android signing fingerprint.
  APK and AAB must each have one matching normalized certificate. `apksigner`
  verifies APK; `keytool` inspects AAB certificate and `jarsigner` requires a
  verified JAR without unsigned payload entries. Android manifest signing identity
  must also match. Keystore/password/alias custody is external: no secrets are
  needed or collected for this inventory. Debug-signing fallback in the
  [Android handoff](../runbooks/android/release-handoff.md#release-signing-setup)
  is explicitly not distributable release evidence.
- Explicit host commands: `curl`, `file`, `jarsigner`, `keytool`, `python3`,
  `qemu-aarch64-static`, `sha256sum`, `tar`, `timeout`, `unzip`, `xvfb-run`.
  Executable `APKSIGNER` or discovery under `ANDROID_HOME/build-tools` is required.
  Bash/Node and GNU-style `realpath`, `find`, sorting/checksum/text utilities are
  implicit script prerequisites. Packaged browser launch also requires the
  installed npm/Playwright closure and Chromium; native launch requires GTK,
  GStreamer, libsecret and display/Xvfb support. CI installs those prerequisites
  and Java 17/Android SDK. Tool availability here is NOT_CHECKED; no install ran.

See [local verifier admission](../runbooks/release-alpha.md#local-artifact-verification).

## Archive and executable boundary

Manifest verification precedes archive extraction or candidate execution.
ZIP integrity and unique APK/AAB bootstrap bytes are checked first; metadata has
exact keys, available=true, current candidate tag/installer revision, valid digests,
Wing Link asset size 1–50 MiB and installer source size 1 byte–1 MiB.

Tar inspection limits members to 50,000 and expanded bytes to 4 GiB; rejects
absolute/traversing/duplicate paths, hard links, special entries and escaping
symlink targets. Required entrypoints must be regular non-symlink files. It then
extracts both archives. `chmod` changes candidate Linux binary permissions;
`timeout` executes standalone Linux amd64 and QEMU arm64 `version`; Xvfb launches
extracted Wing; a loopback HTTP server serves extracted web files to Playwright.
These side effects make the verifier unsuitable for this offline card.
The host receipt's ten named checks are consumed by `qualificationIndex`, not
proof of any scenario beyond these inspected launches/signatures/integrity checks.

## Manual evidence chains, separate from publication

The [Android manual recorder](../../scripts/record_release_qualification.mjs),
lines 52–85,
binds installed single-base APK size/digest/version/build and manifest identity
for `physical-voice` or `server-audio`. Operator observations remain assertions;
physical voice rejects emulator and absent microphone permission. Output defaults
to `build/receipts/<kind>-release-qualification.json`, which was not inspected.
No physical/acoustic or server-audio receipt is claimed here.

The [Linux lifecycle receipt contract](linux-service-receipts.md) and
[recorder source](../../scripts/record_linux_service_qualification.mjs), lines
8–95, cover Linux amd64 `install`, `start`, `restart`, `health`,
`failed-activation-rollback`, `uninstall`, then a sequence index. Candidate and
distinct previously verified release sets are required. The recorder reads only
`bundle/wing` through bounded `tar -xOf`, hashes active files and records manual
phase/health observations; it does not perform lifecycle operations. Rollback
must match predecessor bytes and restored health, uninstall absent files/service.
The default `build/receipts/linux-service` directory was not swept. This manual
chain is not auto-published, not a successful-upgrade or signed-distribution proof.

Nearest tests were read, not run: [evidence tests](../../test/tooling/release_evidence_test.mjs)
exercise synthetic changed bytes/identity/inventory/symlinks/missing and altered
smoke receipts; [workflow tests](../../test/tooling/release_workflow_contract_test.dart)
trace ordering, unsafe archives, tag recovery and platform jobs, but also invoke
the forbidden shell verifier in a negative case. They are not safe to run as a
whole under this card. [Android recorder tests](../../test/tooling/record_release_qualification_test.mjs)
and [Linux recorder tests](../../test/tooling/linux_service_qualification_test.mjs)
use synthetic artifacts/observations, not live qualification.

## Integrated M1–M5 and recovery gaps

Every qualification result in this table is NOT_CHECKED for an exact M6 candidate.
Existing fixture, debug-device, source or executor receipts retain their original
limits and do not advance the named installed alpha.

| Applicable outcome | Missing exact-candidate proof |
| --- | --- |
| M1 actual work | Installed client + admitted unmodified Agent/profile/model/session; real provider output, harmless tool/correlated approval, authoritative stop, reconnect and canonical history with no replay. APK PID and web initialization cannot establish this. |
| M2 Android continuity | Named OS/API/ABI/package/artifact and process-generation evidence; running→completed while client absent, exact-owner canonical hydration and zero duplicate creates/sends, credential expiry/revocation/wrong-owner cases. Notifications denied remains separate from unsupported push. Source preflight is not OS death. |
| M3 trusted setup | Separate Agent/Wing Link credentials, reviewed native pin, secure enrollment, supported new-profile setup and explicit Chat; individual Project/existing-provider contracts qualified or precisely deferred, never simulated. |
| M4 supported work | Per-operation/grant/resource inventory/admin outcomes on the installed candidate, including unsupported/error states and authoritative readback for each admitted mutation. Missing discovery/MCP/memory/Kanban operations need explicit alpha deferrals. |
| M5 native output/accessibility | Installed Android copy/save/share and denial/cancel, IME/focus, large text/reduced motion/TalkBack; separate browser/native desktop target attribution. Physical voice/acoustic and Agent artifacts only if individually admitted/claimed. |
| Install and integrated acceptance | Exact signed APK identity after install and supported workflow on that same generation; applicable accepted M1–M5 and complete repository gate bound to candidate source. Historical dirty-tree checks and synthetic contracts cannot substitute. |
| Safe upgrade | Distinct verified predecessor/candidate, same admitted signing lineage and named channel/target, preserved expected state/owner isolation, activation and actual post-upgrade health/workflow. No upgrade scenario is emitted by the CI APK smoke. |
| Rollback/recovery | Deliberate bounded failure, trusted predecessor restoration, application/service health and authoritative session recovery without resend. The Linux manual contract prepares evidence capture but no live sequence was collected. Android rollback is not covered by Linux version execution. |
| Uninstall | Exact-target application and applicable service/files cleanup with retained/deleted state disposition observed. CI APK uninstall covers smoke cleanup only, not integrated alpha data/service cleanup. |
| Distribution and other targets | Signing custody/channel/publication permission, AAB store/split delivery, signed APT/RPM authority, native nonselected macOS/Android Wing Link devices, Windows/macOS Flutter clients and real services each need separate evidence. No general packaged-support claim. |

## One bounded next step

Prepare one offline candidate-admission comparison once an owner supplies a public
candidate index/manifests and exact candidate revision/tag: compare identity,
artifact/receipt/input digests, certificate identity, selected architecture and
scenario limits against this inventory. Report mismatches/missing receipts without
extracting or executing any candidate, and retain NOT_CHECKED for OS/live recovery.
This is a recommendation, not a new card, authorization or repeated broad audit.
Actual signed install/upgrade/recovery follows separately authorized target,
resource, signing and applicable M1–M5 admission; no release dispatch is proposed.

## Acceptance evidence

| Criterion | Delivered artifact / inspected contracts / executed check |
| --- | --- |
| 1: exact producer/consumer assets, admission and platform distinction | Matrix/allowlist/admission above; fingerprinted workflow, verifier and evidence source; source-inventory candidate probes, historical JSON parsing. No candidate present at exact probed paths; NOT_CHECKED elsewhere. |
| 2: applicable integrated/recovery gaps and bounded next step | M1–M5/recovery table and candidate-admission comparison above; roadmap M6 and runbook source sections. All runtime/platform/signing-custody/publication claims remain NOT_CHECKED. |
| 3: offline checks and source binding | Task-owned checker and command/exit receipt below validate inventory JSON, historical JSON, local links/anchors, allowlist/order, scoped source fingerprints and whitespace. Local agent branch commit is recorded in the native review handoff, not a source/release qualification. |

Exact offline commands and exits are saved in
[commands receipt](../../.task-evidence/t_8daadbc0/commands.json). The executable
[offline checker](../../.task-evidence/t_8daadbc0/check_inventory.py) uses Python
stdlib, Git read-only discovery and task-owned output only. Commands are:

- `python .task-evidence/t_8daadbc0/check_inventory.py capture`
- `python .task-evidence/t_8daadbc0/check_inventory.py check`
- `git diff --check -- docs/quality/2026-10-06-m6-artifact-evidence.md .task-evidence/t_8daadbc0`
- `git diff --no-index --check /dev/null <each task-authored document/check/JSON file>`

The explicit no-index checks cover new untracked files that ordinary `git diff`
omits. Git no-index exits 1 for a differing new file even with clean whitespace;
the runner accepts that only with empty stdout/stderr. The first attempt stopped
on that exit convention; its exact output is retained, then the corrected runner
completed the offline checks. This is documentation/check implementation acceptance; native same-card
review owns final approval. Offline executed passes stay in task receipts; only
inspection evidence belongs on M6, which must not be promoted by these checks.
Questions: none. No user choice, new requirement or privileged default is applied.

## Shared ledger handoff

Repo-docs job `ba15b4ed8db6` completed its 00:31:58 local report before this
bookkeeping pass. Supported `goals.py task ... done`, `evidence ... --kind
inspection`, and `render` each exited 0; exact commands/readback are in
[bookkeeping receipt](../../.task-evidence/t_8daadbc0/bookkeeping.json).
All other goal/task objects were preserved. M6 remains unverified; no executed
M6 evidence entry was added. The narrowly attributed TODO entry marks this
inventory delivered with native review pending, not the M6 outcome complete.

`goals.py validate .` then exited 1: `M6: unverified goal has no open task`.
This closes the sole inventory task, not the qualification gap. Repo-docs owns
adding the next bounded M6 backlog entry and rerendering/validating the shared
ledger; this card's explicit scope forbids selecting or enqueuing another task.
Its handoff is the candidate-admission comparison above, with all runtime gates
retained. This known bookkeeping gap is not a failed offline inventory check and
must not be cured by falsely marking M6 met.
