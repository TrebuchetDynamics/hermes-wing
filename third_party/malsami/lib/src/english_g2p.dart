// This file is deprecated. Use en_g2p.dart instead.
// Keeping this file for backward compatibility.

import 'constants.dart';
import 'lexicon.dart';
import 'token.dart';
import 'utils.dart';

/// Regular expression for tokenizing text
final RegExp _tokenRegex = RegExp(r'[^\s]+|\s+');

/// Regular expression for link format
final RegExp _linkRegex = RegExp(r'\[([^\]]+)\]\(([^\)]*)\)');

/// English G2P (Grapheme-to-Phoneme) engine
///
/// This is the Dart implementation of the Python G2P class
///
@Deprecated('This class is deprecated. Use EnglishG2P from en_g2p.dart instead.')
class EnglishG2P {
  /// Whether to use British English pronunciation
  final bool british;

  /// Lexicon for dictionary lookups
  late Lexicon lexicon;

  /// Unknown token representation
  final String unk;

  /// Whether the lexicon has been initialized
  bool _initialized = false;

  /// Constructor
  EnglishG2P({
    this.british = false,
    this.unk = '❓',
  }) {
    lexicon = Lexicon(british);
  }

  /// Initialize the G2P engine
  Future<void> initialize() async {
    if (!_initialized) {
      await lexicon.initialize();
      _initialized = true;
    }
  }

  /// Preprocess text before tokenization
  String preprocess(String text) {
    // Handle markdown links
    text = text.replaceAllMapped(_linkRegex, (match) {
      final String linkText = match.group(1)!;
      final String linkUrl = match.group(2)!;

      // Check if the URL contains phonetic transcription
      if (linkUrl.startsWith('/') && linkUrl.endsWith('/') && linkUrl.length > 2) {
        // Extract the phonetic transcription
        final String phonemes = linkUrl.substring(1, linkUrl.length - 1);

        // Return the link text with the phonetic transcription as a special marker
        return '$linkText⟨$phonemes⟩';
      }

      return linkText;
    });

    return text;
  }

  /// Tokenize text into MTokens
  List<MToken> tokenize(String text) {
    final List<MToken> tokens = [];

    // Simple tokenization by splitting on whitespace
    final Iterable<RegExpMatch> matches = _tokenRegex.allMatches(text);

    for (final match in matches) {
      final String matchText = match.group(0)!;

      if (matchText.trim().isEmpty) {
        // This is whitespace
        if (tokens.isNotEmpty) {
          final MToken lastToken = tokens.last;
          tokens[tokens.length - 1] = lastToken.copyWith(
            whitespace: lastToken.whitespace + matchText,
          );
        }
      } else {
        // This is a token
        final String whitespace = matchText.endsWith(' ') ? ' ' : '';
        final String tokenText = matchText.trim();

        // Determine if this token should have a space before it
        final bool prespace = tokens.isNotEmpty &&
            tokens.last.whitespace.isNotEmpty;

        // Simple tag assignment (in a real implementation, this would use POS tagging)
        String tag = 'NN';
        if (punctTags.contains(tokenText)) {
          tag = tokenText;
        } else if (tokenText.toLowerCase() == 'the') {
          tag = 'DT';
        } else if (tokenText.toLowerCase() == 'a' || tokenText.toLowerCase() == 'an') {
          tag = 'DT';
        } else if (tokenText.toLowerCase() == 'is' || tokenText.toLowerCase() == 'are') {
          tag = 'VBZ';
        } else if (tokenText.toLowerCase() == 'to') {
          tag = 'TO';
        } else if (tokenText.toLowerCase() == 'for') {
          tag = 'IN';
        }

        tokens.add(MToken(
          text: tokenText,
          tag: tag,
          whitespace: whitespace,
          underscore: Underscore(
            prespace: prespace,
          ),
        ));
      }
    }

    return tokens;
  }

  /// Process tokens to determine their phonetic representation
  Future<List<MToken>> processTokens(List<MToken> tokens) async {
    if (!_initialized) {
      await initialize();
    }

    final List<MToken> processedTokens = [];

    for (int i = 0; i < tokens.length; i++) {
      final MToken token = tokens[i];

      // Determine context for this token
      final bool? futureVowel = (i < tokens.length - 1) ?
          _startsWithVowelSound(tokens[i + 1].text) : null;

      final bool futureTo = (i < tokens.length - 1) &&
          tokens[i + 1].text.toLowerCase() == 'to';

      final TokenContext ctx = TokenContext(
        futureVowel: futureVowel,
        futureTo: futureTo,
      );

      // Look up the token in the lexicon
      final (String? phonemes, int? rating) = lexicon.lookup(
        token.text,
        token.tag,
        token.underscore?.stress,
        ctx
      );

      // Create a processed token with phonemes
      processedTokens.add(token.copyWith(
        phonemes: phonemes,
        underscore: token.underscore != null ? token.underscore!.copyWith(
          rating: rating,
        ) : Underscore(rating: rating),
      ));
    }

    return processedTokens;
  }

  /// Determine if a word starts with a vowel sound
  bool? _startsWithVowelSound(String word) {
    if (word.isEmpty) return null;

    // Common words that don't follow the usual pattern
    final Map<String, bool> exceptions = {
      'one': false,
      'once': false,
      'user': true,
      'unicorn': true,
      'unique': true,
      'university': true,
      'union': true,
      'unit': true,
      'united': true,
      'universe': true,
      'universal': true,
      'uranium': true,
      'uranus': true,
      'urban': true,
      'urge': true,
      'urgent': true,
      'urine': true,
      'url': true,
      'urn': true,
      'usage': true,
      'use': true,
      'useful': true,
      'useless': true,
      'usual': true,
      'usually': true,
      'utility': true,
      'utopia': true,
      'utopian': true,
    };

    final String lowerWord = word.toLowerCase();

    if (exceptions.containsKey(lowerWord)) {
      return exceptions[lowerWord];
    }

    // Check first letter
    final String firstChar = lowerWord[0];

    // Vowels generally start with vowel sounds
    if ('aeiou'.contains(firstChar)) {
      // 'u' can be tricky - if followed by certain consonants, it might not be a vowel sound
      if (firstChar == 'u' && lowerWord.length > 1) {
        final String secondChar = lowerWord[1];
        if ('sn'.contains(secondChar)) {
          return false;
        }
      }
      return true;
    }

    // 'h' followed by vowel might be silent in some words
    if (firstChar == 'h' && lowerWord.length > 1 && 'our'.contains(lowerWord[1])) {
      // Words like 'hour', 'honor'
      if (lowerWord.startsWith('hon') || lowerWord.startsWith('hour')) {
        return true;
      }
    }

    return false;
  }

  /// Merge adjacent tokens when appropriate
  List<MToken> mergeTokens(List<MToken> tokens) {
    if (tokens.isEmpty) return tokens;

    final List<MToken> mergedTokens = [];
    List<MToken> currentGroup = [];

    for (int i = 0; i < tokens.length; i++) {
      final MToken token = tokens[i];

      if (currentGroup.isEmpty) {
        currentGroup.add(token);
      } else {
        // Determine if this token should be merged with the current group
        final bool shouldMerge = _shouldMergeTokens(currentGroup.last, token);

        if (shouldMerge) {
          currentGroup.add(token);
        } else {
          if (currentGroup.length > 1) {
            mergedTokens.add(_mergeTokenGroup(currentGroup));
          } else {
            mergedTokens.add(currentGroup.first);
          }
          currentGroup = [token];
        }
      }
    }

    // Handle the last group
    if (currentGroup.isNotEmpty) {
      if (currentGroup.length > 1) {
        mergedTokens.add(_mergeTokenGroup(currentGroup));
      } else {
        mergedTokens.add(currentGroup.first);
      }
    }

    return mergedTokens;
  }

  /// Determine if two tokens should be merged
  bool _shouldMergeTokens(MToken token1, MToken token2) {
    // Merge tokens that form contractions
    if (token2.text == "'" || token2.text == "'s" || token2.text == "'t" ||
        token2.text == "'ll" || token2.text == "'ve" || token2.text == "'re" ||
        token2.text == "'d") {
      return true;
    }

    // Merge hyphenated words
    if (token1.text.endsWith('-') || token2.text.startsWith('-')) {
      return true;
    }

    // Merge tokens that form a compound number
    if ((token1.text.isNumeric() && token2.text.isNumeric()) ||
        (token1.text.isNumeric() && token2.text == '.') ||
        (token1.text == '.' && token2.text.isNumeric()) ||
        (token1.text.isNumeric() && token2.text == ',') ||
        (token1.text == ',' && token2.text.isNumeric())) {
      return true;
    }

    return false;
  }

  /// Merge a group of tokens into a single token
  MToken _mergeTokenGroup(List<MToken> group) {
    // Combine all tokens into a single token
    final String combinedText = group.map((t) => t.text).join('');
    final String combinedPhonemes = group.map((t) => t.phonemes ?? '').join('');
    return MToken(
      text: combinedText,
      tag: group.first.tag,
      whitespace: group.last.whitespace,
      phonemes: combinedPhonemes
    );
  }

  // Flag to track if the engine has been initialized
  // This is already declared as a field above

  // The initialize method is already declared above

  /// Convert text to phonetic representation
  Future<(String, List<MToken>)> convert(String text, {bool preprocess = true}) async {
    if (!_initialized) {
      await initialize();
    }

    // Since this is a deprecated class, we'll just return a placeholder
    // The actual implementation is in en_g2p.dart
    return Future.value(('', <MToken>[]));
  }
}

/// Extension to check if a string is numeric
extension NumericString on String {
  bool isNumeric() {
    if (isEmpty) return false;
    return RegExp(r'^[0-9]+$').hasMatch(this);
  }
}
