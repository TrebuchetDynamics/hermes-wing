# Malsami

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
