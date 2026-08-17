# malsami (Wing fork)

This directory is a **vendored fork** of the Dart G2P package
[`malsami`](https://github.com/yansigit/malsami), pinned through
`dependency_overrides:` in the Wing app's `pubspec.yaml`
(`malsami: path: third_party/malsami`). The upstream README is copied verbatim
below; the fork-specific information lives in this section.

## Fork summary

- **Upstream repository:** <https://github.com/yansigit/malsami> (published on
  pub.dev as `malsami`).
- **Pinned upstream baseline:** version **0.0.3** (the pub.dev release).
  Evidence: `third_party/malsami/pubspec.yaml` declares `version: 0.0.3`, and
  the app's `pubspec.lock` records `malsami` as `dependency: "direct
  overridden"`, `source: path`, `version: "0.0.3"`. No upstream commit SHA is
  recorded in-tree; to pin to a commit, diff the vendored copy against the
  upstream repository's history.
- **What it provides:** `EnglishG2P`, a grapheme-to-phoneme engine for
  American and British English backed by bundled lexicon assets, intended as the
  text-to-speech frontend (a Dart port of the Python Malsami G2P engine used by
  Kokoro models).
- **Who consumes it:** nothing in `lib/` imports `package:malsami`, and no
  package in the resolved dependency graph currently depends on it (verified by
  scanning the `sherpa_onnx` package and every pub-cache pubspec). The
  `dependency_overrides` entry is therefore a dormant pin: if any direct or
  transitive use of `malsami` is introduced (the sherpa_onnx / TTS
  text-frontend ecosystem is the historical consumer), the vendored copy below
  is used instead of the pub.dev release.

## Verified patch inventory

Patches below were verified by diffing `third_party/malsami` against the pub.dev
`malsami-0.0.3` release.

| File | Patch | Why |
| --- | --- | --- |
| `lib/src/lexicon.dart` | Dictionary asset paths changed from root-relative `assets/us_gold.json` etc. to Flutter package-relative `packages/malsami/assets/...`. | Flutter namespaces dependency assets under `packages/<package>/`; the upstream 0.0.3 paths only load when an application happens to duplicate the dictionaries in its own asset bundle, so the G2P engine would fail to initialize as a dependency. |
| `lib/src/english_g2p.dart`, `lib/src/utils.dart` | Formatting / trailing-whitespace normalization only; no functional change. | `dart format` hygiene. |
| `assets/vi_teencode.json`, `assets/vi_symbols.json`, `assets/vi_acronyms.json`, `assets/ja_words.txt` | Extra asset files carried from the upstream repository but not shipped in pub.dev 0.0.3 and not referenced by this copy's `pubspec.yaml` assets list. | No Vietnamese/Japanese support is wired up; these files are inert. |

## Why the patch is not upstreamed

Whether the asset-path fix has been merged upstream has not been verified.
Check the upstream repository (`yansigit/malsami`) for a post-0.0.3 release or
pull request that fixes `lib/src/lexicon.dart` before assuming the fork can be
dropped; the diff against pub.dev 0.0.3 above is the ground truth to re-check.

## Upgrade path

- **Rebase:** replace `third_party/malsami` with a fresh checkout of the pinned
  upstream tag/commit, re-apply the `lib/src/lexicon.dart` asset-path patch,
  run `dart format`, and re-diff against pub.dev 0.0.3. Then run
  `flutter pub get` and the voice tests.
- **Drop the fork when:** upstream releases a version that loads the lexicon
  dictionaries correctly as a dependency (making the asset-path patch
  unnecessary), or Wing stops resolving `malsami` altogether — then delete the
  `dependency_overrides` entry and this directory together.

---

# Upstream README

> Copied verbatim from the pinned baseline (malsami 0.0.3 on pub.dev); only
> trailing whitespace was normalized.

A Dart implementation of a Grapheme-to-Phoneme (G2P) engine for Flutter. This package converts text into phonetic representations that can be used for text-to-speech synthesis.

This library is highly inspired by the Misaki G2P engine.

Currently, only English is supported.

## Features

- Convert English text to phonetic representation
- Support for both American and British English pronunciation
- Handle special cases, contractions, and homographs
- Process text with markdown-style phonetic annotations
- Lightweight and easy to integrate with Flutter applications

## Getting Started

Add the package to your `pubspec.yaml` file:

```yaml
dependencies:
  malsami: ^0.0.3
```

Import the package in your Dart code:

```dart
import 'package:malsami/malsami.dart';
```

## Usage

### Basic Usage

```dart
// Create an instance of the English G2P engine
final g2p = EnglishG2P();

// Initialize the engine (loads dictionaries)
await g2p.initialize();

// Convert text to phonetic representation
final (phonemes, tokens) = await g2p.convert('Hello world!');

print(phonemes); // Outputs the phonetic representation
```

### Using British English

```dart
// Create an instance with British English pronunciation
final g2p = EnglishG2P(british: true);

// Initialize and use as above
await g2p.initialize();
final (phonemes, _) = await g2p.convert('Hello world!');
```

### Using Phonetic Annotations

You can include specific pronunciations for words using markdown-style links:

```dart
// The text in the URL part will be used as the phonetic representation
final (phonemes, _) = await g2p.convert('[Kokoro](/kˈOkəɹO/) models');

// Outputs: kˈOkəɹO mˈɑdᵊlz
```

## Example App

Check out the example app in the `/example` folder for a complete Flutter application demonstrating how to use the Malsami Dart library.

## Phoneme Set

Malsami Dart uses a set of phonemes based on the International Phonetic Alphabet (IPA) with some modifications for optimal text-to-speech synthesis. For a complete list of phonemes, see the documentation in the source code.

## Limitations

- Currently only supports English
- Requires dictionary files to be included as assets
- No neural network fallback for out-of-vocabulary words yet

## Credits

This is a Dart port of the original Python-based Malsami G2P engine, which was designed for Kokoro models.
