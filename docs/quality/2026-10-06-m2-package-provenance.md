# M2 isolated QA package provenance verification brief

Card: `t_7e4e424a`. Task: `DOC-M2-PACKAGE-PROVENANCE`. Goal: M2.
Status: source-bound verification method only; candidate NOT_ADMITTED.
F01/F02 artifact evidence is UNAVAILABLE. Android/full M2 remain unverified.

## Scope and authority

This brief refines [F01/F02 in the issuer dossier](2026-10-06-m2-issuer-evidence-contract.md#bounded-candidate-admission-dossier),
not the runtime. The [runtime ADR](../adr/runtime-and-delivery.md#decision),
[security ADR](../adr/security-and-privacy.md#decision) and
[threat model](../security/threat-model.md#trust-boundaries) remain binding.
Agent is authoritative; Wing Link supplies neither shadow domain state nor counts.
Source discovery excludes Agent/Desktop/Conduit. No upstream changes are made.
No production code, tests, manifests, builds, signing, artifact extraction,
installation, device access, private storage, credentials, authority issuance,
runner activation or live requests are authorized or performed on this card.
Existing locks and predecessor receipts remain untouched.

## Exact source versus delivered artifact

[source-snapshot.json](../../.task-evidence/t_7e4e424a/source-snapshot.json)
binds current worktree bytes, SHA-256, line counts and checkout HEAD, not a release.
The selection snapshot is compared separately; drift is reported, not inherited.
The task-local checker follows literal Dart import/export/part directives only.
Its source closure is not compiler attribution or external/native resolution.

| Inspected source | Configuration or lexical finding | Artifact evidence still needed |
| --- | --- | --- |
| [Gradle](../../android/app/build.gradle.kts), lines 37–45, 80–94 | Base ID is `com.trebuchetdynamics.hermes.wing`; only debug with `WING_ISOLATED_DEVICE_TEST=1` adds `.qa`. Release may use debug signing. | Same APK's merged ID must be `com.trebuchetdynamics.hermes.wing.qa`; explicit debuggable state and independently attributable Flutter debug build mode. Neither filename, flag, signature nor debuggable alone proves Flutter mode. |
| [QA main](../../integration_test/hermes_m2_observer_main.dart), lines 1–8; [observer](../../integration_test/support/m2_observer.dart), lines 1–33 | Main only awaits no-input `m2Bootstrap`; runtime always refuses before binding/providers/stores/channels/runApp. | Compiled target attribution to these exact bytes, not a command string or source URI found inside arbitrary binary bytes. |
| [Metadata](../../integration_test/support/m2_metadata.dart), lines 1–6; [pubspec](../../pubspec.yaml), lines 9–34; [lock](../../pubspec.lock), lines 1020–1027 | Local closure is main → observer → metadata; external directives are `dart:convert` and `package:uuid/uuid.dart`; UUID is locked to 4.6.0. | Compiler dependency report and verified external package/SDK inputs, emitted Dart payload and same-APK binding. Lock data does not measure fetched or compiled package bytes. |
| [Main manifest](../../android/app/src/main/AndroidManifest.xml), lines 14–56; [debug overlay](../../android/app/src/debug/AndroidManifest.xml); [profile overlay](../../android/app/src/profile/AndroidManifest.xml) | Shared MainActivity, launcher, VIEW/SEND pairing intents, Flutter embedding and barcode metadata. Overlays only declare INTERNET. | Merged manifest/components/permissions/resources measured from the exact APK; source manifests alone omit dependency contributions. |
| [MainActivity](../../android/app/src/main/kotlin/com/trebuchetdynamics/hermes/wing/MainActivity.kt), lines 18–26, 35–83 | FlutterActivity calls superclass engine setup and installs pairing, speech and durable-key channels. Dart's early refusal does not prove absent native registration or absent native side effects. | Delivered DEX/native libraries and lifecycle/plugin registration closure, including transitive local Kotlin helpers, Flutter embedding and Maven dependencies. No native safety/absence claim is made. |
| [Generated registrant](../../android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java), lines 14–68; Gradle lines 102–140; [settings](../../android/settings.gradle.kts), lines 20–26 | Current generated source registers audio, file selector, secure storage, TTS, integration_test, JNI, preferences, speech and URL launcher. Release-only stripping is not debug isolation. Gradle adds Google scanner dependencies; settings includes headless_voice_fixture. | Exact build's regenerated registrant, resolved native/plugin graph and APK contents. Module inclusion is not proof of packaging; this generated checkout file is not measured APK contents. |

No current source configuration defines a dedicated minimal M2 Android component
or plugin allowlist. A three-file Dart closure cannot be promoted into a claim
that the APK excludes all product-capable native code. A future reviewed closure
policy must distinguish present-but-uninvoked components from prohibited contents;
unknown or unreviewed closure refuses. This brief neither selects that policy nor
changes packaging to satisfy it.

## Existing methods and their limits

These are inspected methods, NOT executed artifact checks on this card.

| Existing method | Required inputs and existing refusal | F01/F02 limit |
| --- | --- | --- |
| [Release digester/verifier](../../scripts/release_evidence.mjs), lines 25–38, 55–103 | Public bounded regular nonsymlink files, explicit identity, fixed release inventory and lock inputs. Refuses size/type/digest/identity/inventory mismatch. | Measures file identity/consistency, not merged package/debug mode, Dart target or complete dependency closure. Its `target=android` is platform, not Flutter entrypoint. |
| [Offline comparator](../../scripts/compare_release_candidate.mjs), lines 17–57; [runbook](../runbooks/offline-release-candidate-comparison.md#what-the-result-means) | Complete public release bundle and independently supplied identity/certificate. Refuses missing/changed index, malformed or mismatched records. | Fixed release schema is not an isolated QA F01/F02 assay; record consistency is not compiled provenance. Do not run or adapt it as an M2 admission oracle. |
| [Release artifact gate](../../scripts/verify_release_artifacts.sh), lines 107–179 | Checksums, APK/AAB and release inputs/tools; checks ZIP integrity and unique matching bootstrap assets. | Broader signing/execution gate is outside scope. Asset equality does not identify M2 target or full closure. Never invoke the whole gate to obtain one package fact. |
| [Installed qualification recorder](../../scripts/record_release_qualification.mjs), lines 28–60 | Explicit device; reads product package, pulls single base APK and compares digest/version/build with release record; refuses split/mismatch. | Product package is hardcoded, not `.qa`; device/storage operations are excluded. F03 method cannot supply F01/F02 or authorize M2. |
| [Profiles runner](../../scripts/run_android_maestro_profiles.sh), lines 7–35; [features runner](../../scripts/run_android_maestro_features.sh), lines 7–46 | Explicit disposable target; isolated debug build with explicit non-M2 target, followed immediately by install/test. | No measured QA manifest/mode/compiled-target admission before installation. Wrong target for M2. Neither runner may be invoked here. |

Bounded searches of Wing scripts found no existing `apkanalyzer`, `aapt`,
`debuggable` or compiled-target inspector. APK manifest/mode measurement method:
UNAVAILABLE in inspected tooling. Complete compiled Dart/native/plugin closure
assessor: UNAVAILABLE. No SDK tool availability or version was probed; proposed
SDK commands below are a future method, not claimed installed tooling. No artifact
was located, opened, hashed or silently borrowed from prior builds.

## Required public inputs and refusal controls

A future F01/F02 assessor needs independently reviewed, non-secret inputs:

- One explicitly supplied immutable public QA APK; independently expected digest
  and size; build record linking exactly that APK to stable source fingerprints.
- Recorded cwd, exact build argv, effective isolation flag, explicit debug mode,
  exact M2 target, Flutter/Dart/Gradle/AGP/JDK/Android SDK versions and ABIs.
  Sanitization must exclude signing environment, credentials and private paths.
- Exact source inputs, package lock plus verified resolved package bytes, SDK
  identity, compiler dependency/output records, regenerated plugin registrant,
  resolved Maven/native dependency graph and merged manifest/resource records.
- A reviewed inspector/version and separately approved closure policy, with
  measured outputs bound to the same APK digest and independent build provenance.
  Caller-supplied labels/digests alone are not independently established custody.

| Control | Required refusal; no rights released |
| --- | --- |
| Wrong package | Product ID, other suffix, missing/ambiguous package identity: NOT_ADMITTED. Never install to learn the identity. |
| Wrong mode | Release/profile, missing debug attribution, debuggable false/unknown, only debug signature/filename/environment assertion: NOT_ADMITTED. Debuggable true is necessary but insufficient for Flutter debug mode. |
| Wrong target | Feature/profile/product/fake target; absent or conflicting compiled attribution; stale build record: NOT_ADMITTED, even with correct `.qa` ID. |
| Incomplete Dart closure | Missing resolved UUID/SDK/compiler inputs, unknown conditional/generated dependency, source closure offered as binary proof: NOT_ADMITTED. |
| Incomplete native/plugin closure | Missing merged components/DEX/native/registrant/dependency graph, unreviewed extra capabilities or policy, inventory without attribution: NOT_ADMITTED. |
| Cross-artifact or unstable inputs | Records for different APK digest, changed bytes, symlink/duplicate/oversized/ambiguous inputs, unauthenticated provenance: NOT_ADMITTED. Never fill gaps by inference. |

These refusals are proposed assessment requirements, not implemented APK/runtime
validation. Current runtime remains `not_admitted`, `continuation_unavailable`,
`qualifies=false`, `authoritative_counts_unavailable`. Even complete F01/F02
would not supply F03–F10, history admission, authoritative counts or launch/read/
write rights. All remain UNAVAILABLE/NOT_CHECKED; Android/full M2 stay unverified.

## Exactly one smallest separately scoped executable proof slice

Proposed next slice: offline merged-manifest measurement of one explicitly
supplied public isolated QA APK, a partial F01 check only. It is NOT authorized
or executed here and does not require a build, install or running application.

Separate authorization must name the immutable public APK and expected digest,
a reviewed local SDK `apkanalyzer` version/executable, bounded output/time/input
limits and a fresh task-owned output location. Missing input/tool authorization
means UNAVAILABLE, not a request to search devices, caches or private storage.
With that authorization, validate immutable regular nonsymlink input/size/digest,
then run fixed read-only SDK operations `apkanalyzer manifest application-id`,
`apkanalyzer manifest debuggable` and `apkanalyzer manifest print` on that same APK.
Record exact argv/tool identity/exits and sanitized package, debug flag and
component inventory; rehash to detect change. Require exact `.qa` ID and true
debuggable; malformed, ambiguous, missing, changed or mismatched output refuses.
Keep parser errors distinct from measured rejection, and retain no arbitrary
binary strings or paths in public output. Inspector isolation and hard bounds
must be reviewed before parsing untrusted APK input.

This slice establishes only measured manifest facts. Flutter debug attribution,
compiled target and complete closure stay UNAVAILABLE until independently
reviewed methods and build records exist. Signing is NOT_CHECKED. No build,
download, signer, install, launch, device/private storage, credentials, authority
issuance, runner or live request is permitted. It creates no accepting runtime,
protocol fields or new backlog card; it is the single executable proof proposal.

## Executed source-only checks and acceptance mapping

From repository root:

    python3 .task-evidence/t_7e4e424a/check_provenance.py snapshot
    python3 .task-evidence/t_7e4e424a/check_provenance.py verify

The checker records exact cwd/argv/exits in task-local command receipts. Snapshot
binds explicitly allowlisted source fingerprints and selection drift. Verify
checks unchanged bytes, literal local Dart closure/external directives, local
links/anchors, required refusal/status markers and whitespace on all authored
files, including new files. These are lexical checks, not Dart tests, compiler,
APK measurement, SDK availability, native security or runtime qualification.

Acceptance 1 maps to source/artifact distinctions, inspected methods and six
refusal controls. Acceptance 2 maps to explicit UNAVAILABLE methods/evidence,
one partial-F01 offline proposal and preserved F03–F10/history/counts/M2 ceiling.
Acceptance 3 maps to source-snapshot and command receipts, helper-managed scoped
ledger readback and authored-only local branch/SHA in the native review handoff.
Shared goals/TODO deltas are retained separately, not committed as wholly owned
files. Helpers may auto-promote M2 on document passes; public helper load/dump
preserves unverified before render. Ledger-model diagnostics are retained, never
converted to platform acceptance. Native same-card review is the final worker
step; review approval is not claimed.

Questions: none. Defaults: source-only, refusal-only; no new artifact/runtime
rights or packaging changes. No platform was exercised.

Executed outcomes: snapshot and verify exited 0; 31 source fingerprints and all
six selection comparisons matched. Local-link/anchor and authored-file whitespace
checks passed; exact details are in
[validation.json](../../.task-evidence/t_7e4e424a/validation.json).
Task/evidence/render succeeded and unrelated ledger objects were preserved.
The helper's validate command exited 1 with `M2: unverified goal has no open task`;
this known helper-model diagnostic is retained in
[ledger.json](../../.task-evidence/t_7e4e424a/ledger.json), not treated as platform
acceptance or repaired with invented follow-up work. M2 remains unverified.
