# Android APK size audit — 2026-09-05

## Scope and measurements

Inspected the Flutter client, Android build, release workflow, and local APK ZIP
contents. Upstream reference clones are outside this audit. No application code,
dependencies, or release configuration were changed. The checkout already had
uncommitted work; these are local measurements, not release qualification.

Sizes below use decimal MB (1,000,000 bytes), measuring APK files rather than
installed application storage or Play Store download sizes.

| Artifact | Bytes | MB |
| --- | ---: | ---: |
| Existing debug APK | 173,561,047 | 173.56 |
| Existing universal release APK, September 2 | 63,694,927 | 63.69 |
| Fresh armeabi-v7a release APK | 20,673,153 | 20.67 |
| Fresh arm64-v8a release APK | 22,752,541 | 22.75 |
| Fresh x86_64 release APK | 24,209,673 | 24.21 |
| ARM64 target, size-analysis build without separate symbols | 22,975,649 | 22.98 |
| ARM64 target with separate debug symbols | 21,599,393 | 21.60 |

The universal baseline predates the current checkout, so the approximately 64%
smaller ARM64 artifact is not a controlled same-source before/after comparison.
However, the baseline ZIP directly establishes the cause: native libraries occupy
62,021,660 bytes across three architectures, or 97.4% of that APK. Bundled Flutter
assets occupy just 132,134 compressed bytes.

The fresh ARM64 APK contains 11,579,920 bytes of `libflutter.so`, 9,438,096 bytes
of compiled Dart in `libapp.so`, and 131,704 bytes in two other native libraries.

With `--target-platform android-arm64 --split-debug-info`, `libapp.so` falls to
8,061,840 bytes: 1,376,256 bytes less (14.6%). This non-split build also includes
195,764 bytes of small JNI/datastore libraries for other ABIs, so its total APK
delta is not a pure symbols-only comparison. The 4,534,920-byte symbols file is
outside the APK. A matching non-split ARM64 size-analysis build without symbol
separation is 22,975,649 bytes, confirming a total reduction of 1,376,256 bytes
(6.0%). The measured artifact is preserved locally at
`build/apk-size-audit/app-arm64-v8a-stripped-release.apk`; symbols are in
`build/apk-size-audit-symbols/app.android-arm64.symbols`.

The size-analysis JSON is preserved at
`build/apk-size-audit/apk-code-size-analysis.json`. Its accounted, decompressed
Dart AOT sizes are not incremental APK savings:

| Package | Accounted bytes |
| --- | ---: |
| Flutter | 3,553,503 |
| Wing | 1,424,543 |
| Flutter localizations | 270,387 |
| markdown | 118,864 |
| Riverpod | 104,803 |
| flutter_markdown_plus | 47,438 |

Wing's largest attributed files are `hermes_chat_screen.dart` (351,927 bytes) and
`hermes_api_channel.dart` (154,019 bytes), both live core functionality. Size alone
does not make them removal candidates. Replacing Markdown rendering targets only
about 0.17 MB of accounted AOT code before replacement cost, so it ranks well below
packaging changes. Framework localization is a smaller possible investigation,
but removing delegates requires preserving localized framework strings, semantics,
and supported locale behavior; no such change was tested.

## Prioritized reductions

1. **Publish per-architecture APKs for direct installation.** Measured with
   `flutter build apk --release --split-per-abi`. The outputs are under
   `build/app/outputs/flutter-apk/`, named `app-<abi>-release.apk`. A user installs
   the one matching their device. These are standalone APKs, distinct from a
   multi-file Play Store split installation. Keep a universal fallback if needed.
2. **Separate Dart debug symbols.** Measure `--split-debug-info` independently
   of architecture splitting, retaining symbols for each exact build and ABI so
   crash traces can be symbolized. Do not package symbols inside the APK.
   This audit measured the command below successfully; combine ABI splitting
   and symbol separation in a subsequent controlled release-build comparison.

   ```bash
   flutter build apk --release --target-platform android-arm64 \
     --split-debug-info=build/apk-size-audit-symbols
   ```
3. **Use the existing AAB for Play distribution.** Play can deliver device-specific
   packages; the AAB upload's file size is not the user's download size. No Play
   download or installation size was measured here.
4. **Track artifact size per ABI in CI.** Compare identical build modes, targets,
   and symbol settings. Set budgets from measured release artifacts. Prioritize
   package-level AOT analysis before replacing libraries or removing features.

The release workflow currently builds a universal APK and publishes it as
`hermes-wing-android.apk`. Adding ABI artifacts must update the exact inventories
in `scripts/release_evidence.mjs` and `scripts/verify_release_artifacts.sh`, checksum
and signature verification, workflow uploads, and their contract tests together.
The current smoke uses an x86_64 emulator: simply replacing its APK with an ARM64
APK will break installation. Preserve exact-artifact checks and qualify each
claimed architecture. Retain build symbols as private build artifacts.

## Unused code and dependencies

The existing MCP graph's Dart orphan queries returned insufficient results, so
the scan used live import/export/part directives, including conditional imports,
followed by reference checks. Of 176 Dart files, 171 are reachable from
`lib/main.dart` through those directives. This measures file reachability, not
whether every member of every file is used.

The five outside that closure are:

- `lib/main_e2e.dart`: intentional separate E2E entrypoint.
- `lib/core/hermes/hermes_api.dart`: export facade used by tests.
- `lib/core/protocol/wing_voice_run.dart` and
  `lib/core/protocol/voice/wing_voice_run.dart`: export facades used through tests.
- `lib/core/protocol/voice/wing_voice_status.dart`: unused one-line export facade;
  the model imports/exports `contracts/wing_voice_status.dart` directly. Removing
  the facade would provide no meaningful APK reduction; it was retained.

All declared production dependencies have live imports. The Android scanner
dependencies serve separate live methods in `MainActivity.kt`: `scanQrCode`
and `decodeQrImage`. No runtime class/enum/mixin/typedef with only its declaration
occurrence was found by the secondary token-reference scan. This is a bounded
scan, not proof that every declaration is necessary. No code was deleted.

Flutter 3.44.2's installed Gradle plugin already enables release minification and
resource shrinking; fresh R8 usage/resource reports were produced. The build
also shrank Material Icons from 1,645,184 to 22,432 bytes (98.6%). Adding redundant
shrink flags or removing README images will not address the main APK cost. The
only declared application asset is `assets/config/termux_bootstrap.json`.

## Validation and limits

- `flutter build apk --release --split-per-abi`: passed on isolated retry.
  The first attempt failed because the generated registrant included the
  dev-only integration-test plugin. No source workaround was applied.
- `flutter analyze`: failed with two existing style infos in the already-dirty
  `profiles_screen.dart:263` and `profiles_screen_test.dart:171`; no unused-code
  diagnostic was reported.
- Combining `--analyze-size` and `--split-debug-info` was rejected by Flutter;
  use separate builds for those measurements.
- `flutter build apk --release --target-platform android-arm64
  --split-debug-info=build/apk-size-audit-symbols`: passed.
- `flutter build apk --release --target-platform android-arm64 --analyze-size`:
  passed; generated the package-level report.
- `git diff --check` and audit Markdown whitespace/local-link checks: passed.
- Build warnings include secure-storage compile SDK 37 versus app SDK 36,
  Kotlin migration notices, and a missing Cupertino font-family reference.
  These are not established APK-size causes.
- Android compilation ran on Linux with Flutter 3.44.2 / Dart 3.12.2. No device
  install, physical behavior, signing qualification, store delivery, or other
  platform runtime was exercised. Local builds are not distribution approval.

References: [Flutter app-size guidance](https://docs.flutter.dev/perf/app-size)
and [Android release guidance](https://docs.flutter.dev/deployment/android).
