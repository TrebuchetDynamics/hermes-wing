import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;

import 'constants.dart';
import 'utils.dart';

/// Lexicon class for English G2P
///
/// This is the Dart implementation of the Python Lexicon class
class Lexicon {
  /// Whether to use British English pronunciation
  final bool british;

  /// Stress values for capitalized words
  final List<double> capStresses = [0.5, 2];

  /// Gold-standard dictionary (high quality)
  Map<String, dynamic> golds = {};

  /// Silver-standard dictionary (medium quality)
  Map<String, dynamic> silvers = {};

  /// Constructor
  Lexicon(this.british);

  /// Initialize the lexicon by loading dictionaries
  Future<void> initialize() async {
    // Load the appropriate dictionaries based on language variant
    // Flutter namespaces dependency assets under packages/<package>/.
    // Loading the root-level assets/... path only works when an application
    // happens to duplicate these dictionaries in its own asset bundle.
    final String goldPath = british
        ? 'packages/malsami/assets/gb_gold.json'
        : 'packages/malsami/assets/us_gold.json';
    final String silverPath = british
        ? 'packages/malsami/assets/gb_silver.json'
        : 'packages/malsami/assets/us_silver.json';

    // Load gold dictionary
    final String goldJson = await rootBundle.loadString(goldPath);
    golds = growDictionary(json.decode(goldJson) as Map<String, dynamic>);

    // Load silver dictionary
    final String silverJson = await rootBundle.loadString(silverPath);
    silvers = growDictionary(json.decode(silverJson) as Map<String, dynamic>);

    // Validate dictionaries
    _validateDictionaries();
  }

  /// Grow the dictionary by adding capitalized versions of lowercase words
  Map<String, dynamic> growDictionary(Map<String, dynamic> dict) {
    final Map<String, dynamic> expanded = {};

    for (final entry in dict.entries) {
      final String key = entry.key;
      final dynamic value = entry.value;

      if (key.length < 2) continue;

      if (key == key.toLowerCase()) {
        if (key != key.capitalize()) {
          expanded[key.capitalize()] = value;
        }
      } else if (key == key.toLowerCase().capitalize()) {
        expanded[key.toLowerCase()] = value;
      }
    }

    // Merge the expanded entries with the original dictionary
    return {...expanded, ...dict};
  }

  /// Validate that all phonemes in the dictionaries are in the appropriate vocabulary
  void _validateDictionaries() {
    final vocab = british ? gbVocab : usVocab;

    for (final value in golds.values) {
      if (value is String) {
        assert(
          value.split('').every((c) => vocab.contains(c)),
          'Invalid phoneme in gold dictionary: $value',
        );
      } else if (value is Map) {
        assert(
          value.containsKey('DEFAULT'),
          'Missing DEFAULT key in gold dictionary map',
        );
        for (final v in value.values) {
          if (v != null) {
            assert(
              v.split('').every((c) => vocab.contains(c)),
              'Invalid phoneme in gold dictionary: $v',
            );
          }
        }
      }
    }
  }

  /// Get pronunciation for a proper noun (NNP)
  (String?, int?) getNNP(String word) {
    final List<String?> ps = [];

    for (int i = 0; i < word.length; i++) {
      if (isAlphaChar(word[i])) {
        ps.add(golds[word[i].toUpperCase()] as String?);
      }
    }

    if (ps.contains(null)) {
      return (null, null);
    }

    String phonemes = applyStress(ps.join(), 0);
    final parts = phonemes.split(secondaryStress);

    if (parts.length > 1) {
      phonemes = parts.join(primaryStress);
    }

    return (phonemes, 3);
  }

  /// Handle special cases for certain words based on context
  (String?, int?) getSpecialCase(
    String word,
    String tag,
    double? stress,
    TokenContext ctx, {
    int depth = 0,
  }) {
    // Handle additional symbols
    if (tag == 'ADD' && addSymbols.containsKey(word)) {
      return lookup(addSymbols[word]!, null, -0.5, ctx, depth: depth + 1);
    }

    // Handle common symbols
    if (symbols.containsKey(word)) {
      return lookup(symbols[word]!, null, null, ctx, depth: depth + 1);
    }

    // Handle abbreviations with periods
    if (word.contains('.') &&
        word.replaceAll('.', '').isAlphaString() &&
        word.split('.').map((p) => p.length).reduce(max) < 3) {
      return getNNP(word);
    }

    // Handle 'a' and 'A'
    if (word == 'a' || word == 'A') {
      return (tag == 'DT' ? 'ɐ' : 'ˈA', 4);
    }

    // Handle 'am', 'Am', 'AM'
    if (word == 'am' || word == 'Am' || word == 'AM') {
      if (tag.startsWith('NN')) {
        return getNNP(word);
      } else if (ctx.futureVowel == null ||
          word != 'am' ||
          (stress != null && stress > 0)) {
        return (golds['am'] as String, 4);
      }
      return ('ɐm', 4);
    }

    // Handle 'an', 'An', 'AN'
    if (word == 'an' || word == 'An' || word == 'AN') {
      if (word == 'AN' && tag.startsWith('NN')) {
        return getNNP(word);
      }
      return ('ɐn', 4);
    }

    // Handle 'I' as pronoun
    if (word == 'I' && tag == 'PRP') {
      return ('${secondaryStress}I', 4);
    }

    // Handle 'by', 'By', 'BY' as adverb
    if ((word == 'by' || word == 'By' || word == 'BY') &&
        getParentTag(tag) == 'ADV') {
      return ('bˈI', 4);
    }

    // Handle 'to', 'To', 'TO'
    if (word == 'to' ||
        word == 'To' ||
        (word == 'TO' && tag == 'TO' || tag == 'IN')) {
      if (ctx.futureVowel == null) {
        return (golds['to'] as String, 4);
      } else if (ctx.futureVowel == false) {
        return ('tə', 4);
      } else {
        return ('tʊ', 4);
      }
    }

    // Handle 'in', 'In', 'IN'
    if (word == 'in' || word == 'In' || (word == 'IN' && tag != 'NNP')) {
      final stress =
          (ctx.futureVowel == null || tag != 'IN') ? primaryStress : '';
      return ('$stressɪn', 4);
    }

    // Handle 'the', 'The', 'THE'
    if (word == 'the' || word == 'The' || (word == 'THE' && tag == 'DT')) {
      return (ctx.futureVowel == true ? 'ði' : 'ðə', 4);
    }

    // Handle 'vs' and 'vs.'
    if (tag == 'IN' && RegExp(r'vs\.?$', caseSensitive: false).hasMatch(word)) {
      return lookup('versus', null, null, ctx, depth: depth + 1);
    }

    // Handle 'used', 'Used', 'USED'
    if (word == 'used' || word == 'Used' || word == 'USED') {
      if ((tag == 'VBD' || tag == 'JJ') && ctx.futureTo) {
        return (golds['used']['VBD'] as String, 4);
      }
      return (golds['used']['DEFAULT'] as String, 4);
    }

    return (null, null);
  }

  /// Get the parent tag for a POS tag
  static String getParentTag(String tag) {
    if (tag.startsWith('NN')) return 'NN';
    if (tag.startsWith('VB')) return 'VB';
    if (tag.startsWith('JJ')) return 'JJ';
    if (tag.startsWith('RB')) return 'RB';
    if (tag.startsWith('PRP')) return 'PRP';
    if (tag.startsWith('WP')) return 'WP';
    if (tag.startsWith('WRB')) return 'WRB';
    if (tag.startsWith('WDT')) return 'WDT';
    return tag;
  }

  /// Look up a word in the lexicon
  (String?, int?) lookup(
    String word,
    String? tag,
    double? stress,
    TokenContext ctx, {
    int depth = 0,
  }) {
    // Prevent infinite recursion
    if (depth > 5) {
      return (null, null);
    }
    // Handle special cases first
    if (tag != null) {
      final (specialPs, specialRating) = getSpecialCase(
        word,
        tag,
        stress,
        ctx,
        depth: depth,
      );
      if (specialPs != null) {
        return (specialPs, specialRating);
      }
    }

    // Try gold dictionary first
    String? ps;
    if (golds.containsKey(word)) {
      final entry = golds[word];
      if (entry is String) {
        ps = entry;
      } else if (entry is Map && tag != null) {
        // Try tag-specific pronunciation
        if (entry.containsKey(tag)) {
          ps = entry[tag] as String?;
        }

        // Try parent tag
        if (ps == null && entry.containsKey(getParentTag(tag))) {
          ps = entry[getParentTag(tag)] as String?;
        }

        // Fall back to default
        if (ps == null && entry.containsKey('DEFAULT')) {
          ps = entry['DEFAULT'] as String?;
        }
      }

      if (ps != null) {
        return (applyStress(ps, stress), 4);
      }
    }

    // Try silver dictionary next
    if (silvers.containsKey(word)) {
      ps = silvers[word] as String?;
      if (ps != null) {
        return (applyStress(ps, stress), 2);
      }
    }

    // Handle capitalized words
    if (word.length > 1 &&
        word[0] == word[0].toUpperCase() &&
        word != word.toUpperCase()) {
      // Try lowercase version
      final (lowerPs, lowerRating) = lookup(
        word.toLowerCase(),
        tag,
        null,
        ctx,
        depth: depth + 1,
      );
      if (lowerPs != null) {
        return (applyStress(lowerPs, capStresses[0]), lowerRating);
      }
    }

    // Handle all-caps words
    if (word == word.toUpperCase() && word.length > 1) {
      // Try lowercase version
      final (lowerPs, lowerRating) = lookup(
        word.toLowerCase(),
        tag,
        null,
        ctx,
        depth: depth + 1,
      );
      if (lowerPs != null) {
        return (applyStress(lowerPs, capStresses[1]), lowerRating);
      }

      // Try as acronym
      if (word.isAlphaString()) {
        final (nnpPs, nnpRating) = getNNP(word);
        if (nnpPs != null) {
          return (nnpPs, nnpRating);
        }
      }
    }

    // Not found
    return (null, null);
  }

  /// Check if a character is an alphabetic character
  bool isAlphaChar(String char) {
    if (char.length != 1) return false;
    return RegExp(r'[a-zA-Z]').hasMatch(char);
  }
}

/// Extension to add capitalize method to String
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }

  bool isAlphaString() {
    if (isEmpty) return false;
    for (int i = 0; i < length; i++) {
      if (!isAlphaChar(this[i])) {
        return false;
      }
    }
    return true;
  }

  bool isAlphaChar(String char) {
    if (char.length != 1) return false;
    return RegExp(r'[a-zA-Z]').hasMatch(char);
  }
}
