// No math or foundation imports needed

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
  EnglishG2P({this.british = false, this.unk = '❓'}) {
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
      if (linkUrl.startsWith('/') &&
          linkUrl.endsWith('/') &&
          linkUrl.length > 2) {
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
        final bool prespace =
            tokens.isNotEmpty && tokens.last.whitespace.isNotEmpty;

        // Simple tag assignment (in a real implementation, this would use POS tagging)
        String tag = 'NN';
        if (punctTags.contains(tokenText)) {
          tag = tokenText;
        } else if (tokenText.toLowerCase() == 'the') {
          tag = 'DT';
        } else if (tokenText.toLowerCase() == 'a' ||
            tokenText.toLowerCase() == 'an') {
          tag = 'DT';
        } else if (tokenText.toLowerCase() == 'is' ||
            tokenText.toLowerCase() == 'are') {
          tag = 'VBZ';
        } else if (tokenText.toLowerCase() == 'to') {
          tag = 'TO';
        } else if (tokenText.toLowerCase() == 'for') {
          tag = 'IN';
        } else if (tokenText.toLowerCase() == 'by') {
          tag = 'ADV';
        } else if (tokenText.toLowerCase() == 'am') {
          tag = 'VB';
        }

        tokens.add(
          MToken(
            text: tokenText,
            tag: tag,
            whitespace: whitespace,
            underscore: Underscore(prespace: prespace),
          ),
        );
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

      // Check for custom phoneme in ⟨...⟩
      final match = RegExp(r'^(.*)⟨(.+)⟩').firstMatch(token.text);
      if (match != null) {
        final word = match.group(1)!;
        final phoneme = match.group(2)!;
        processedTokens.add(
          token.copyWith(
            text: word,
            phonemes: phoneme,
            underscore:
                token.underscore != null
                    ? token.underscore!.copyWith(rating: 4)
                    : Underscore(rating: 4),
          ),
        );
        continue;
      }

      // Determine context for this token
      final bool? futureVowel =
          (i < tokens.length - 1)
              ? _startsWithVowelSound(tokens[i + 1].text)
              : null;

      final bool futureTo =
          (i < tokens.length - 1) && tokens[i + 1].text.toLowerCase() == 'to';

      final TokenContext ctx = TokenContext(
        futureVowel: futureVowel,
        futureTo: futureTo,
      );

      // Handle numeric tokens by converting to words and looking up each word
      String? phonemes;
      int? rating;

      // Check if token is numeric (possibly with trailing punctuation)
      String cleanedText = token.text;
      String trailingPunctuation = '';

      // Extract trailing punctuation
      while (cleanedText.isNotEmpty &&
          !RegExp(
            r'[0-9a-zA-Z]',
          ).hasMatch(cleanedText[cleanedText.length - 1])) {
        trailingPunctuation =
            cleanedText[cleanedText.length - 1] + trailingPunctuation;
        cleanedText = cleanedText.substring(0, cleanedText.length - 1);
      }

      if (isNumeric(cleanedText)) {
        final String? words = numberToWords(cleanedText);
        if (words != null) {
          // Split the words and look up each one
          final List<String> wordList = words.split(' ');
          final List<String> wordPhonemes = [];
          bool allWordsFound = true;

          for (final word in wordList) {
            try {
              final (String? wordPs, int? wordRating) = lexicon.lookup(
                word,
                'NN', // Treat number words as nouns
                null, // Don't pass stress to avoid complications
                TokenContext(
                  futureVowel: null,
                  futureTo: false,
                ), // Simple context
              );
              if (wordPs != null) {
                wordPhonemes.add(wordPs);
                rating ??= wordRating;
              } else {
                // If any word is not found, mark as not found
                allWordsFound = false;
                break;
              }
            } catch (e) {
              // If lookup fails, mark as not found
              allWordsFound = false;
              break;
            }
          }

          if (allWordsFound && wordPhonemes.isNotEmpty) {
            phonemes = wordPhonemes.join(' ');
            // Add back any trailing punctuation as unknown tokens
            if (trailingPunctuation.isNotEmpty) {
              phonemes = '$phonemes $unk';
            }
          } else {
            // If conversion failed, fall back to unknown token
            phonemes = null;
            rating = null;
          }
        }
      } else {
        // Look up the token normally in the lexicon
        final (String? ps, int? rt) = lexicon.lookup(
          token.text,
          token.tag,
          token.underscore?.stress,
          ctx,
        );
        phonemes = ps;
        rating = rt;
      }

      // Create a processed token with phonemes
      processedTokens.add(
        token.copyWith(
          phonemes: phonemes,
          underscore:
              token.underscore != null
                  ? token.underscore!.copyWith(rating: rating)
                  : Underscore(rating: rating),
        ),
      );
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
    if (firstChar == 'h' &&
        lowerWord.length > 1 &&
        'our'.contains(lowerWord[1])) {
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
          // Merge the current group and start a new one
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
    // Don't merge if there's whitespace between tokens
    if (token1.whitespace.isNotEmpty) return false;

    // Merge tokens that form contractions
    if (token2.text == "'" ||
        token2.text == "'s" ||
        token2.text == "'t" ||
        token2.text == "'ll" ||
        token2.text == "'ve" ||
        token2.text == "'re" ||
        token2.text == "'d") {
      return true;
    }

    // Merge hyphenated words
    if (token1.text.endsWith('-') || token2.text.startsWith('-')) {
      return true;
    }

    // Don't merge numbers with punctuation to handle them separately
    // Only merge consecutive numbers for compound numbers like "123"
    if (isNumeric(token1.text) && isNumeric(token2.text)) {
      return true;
    }

    return false;
  }

  /// Check if a string consists only of digits
  bool isNumeric(String text) {
    if (text.isEmpty) return false;
    return RegExp(r'^[0-9]+$').hasMatch(text);
  }

  /// Convert a numeric string to its English word equivalent
  String? numberToWords(String numStr) {
    if (!isNumeric(numStr)) return null;

    final int? num = int.tryParse(numStr);
    if (num == null) return null;

    return _convertNumberToWords(num);
  }

  /// Convert an integer to its English word equivalent
  String _convertNumberToWords(int num) {
    if (num == 0) return 'zero';

    // Handle negative numbers
    if (num < 0) return 'negative ${_convertNumberToWords(-num)}';

    // Basic numbers 0-19
    final List<String> ones = [
      '',
      'one',
      'two',
      'three',
      'four',
      'five',
      'six',
      'seven',
      'eight',
      'nine',
      'ten',
      'eleven',
      'twelve',
      'thirteen',
      'fourteen',
      'fifteen',
      'sixteen',
      'seventeen',
      'eighteen',
      'nineteen',
    ];

    // Tens
    final List<String> tens = [
      '',
      '',
      'twenty',
      'thirty',
      'forty',
      'fifty',
      'sixty',
      'seventy',
      'eighty',
      'ninety',
    ];

    if (num < 20) return ones[num];

    if (num < 100) {
      final int tensDigit = num ~/ 10;
      final int onesDigit = num % 10;
      if (onesDigit == 0) {
        return tens[tensDigit];
      } else {
        return '${tens[tensDigit]} ${ones[onesDigit]}';
      }
    }

    if (num < 1000) {
      final int hundreds = num ~/ 100;
      final int remainder = num % 100;
      String result = '${ones[hundreds]} hundred';
      if (remainder > 0) {
        result += ' ${_convertNumberToWords(remainder)}';
      }
      return result;
    }

    if (num < 1000000) {
      final int thousands = num ~/ 1000;
      final int remainder = num % 1000;
      String result = '${_convertNumberToWords(thousands)} thousand';
      if (remainder > 0) {
        result += ' ${_convertNumberToWords(remainder)}';
      }
      return result;
    }

    if (num < 1000000000) {
      final int millions = num ~/ 1000000;
      final int remainder = num % 1000000;
      String result = '${_convertNumberToWords(millions)} million';
      if (remainder > 0) {
        result += ' ${_convertNumberToWords(remainder)}';
      }
      return result;
    }

    // For numbers beyond billions, just return the original number as a fallback
    return num.toString();
  }

  /// Merge a group of tokens into a single token
  MToken _mergeTokenGroup(List<MToken> tokens) {
    // Extract stress values from tokens
    Set<double?> stressValues = {};
    for (var tk in tokens) {
      if (tk.underscore?.stress != null) {
        stressValues.add(tk.underscore!.stress);
      }
    }

    // Extract currency values from tokens
    Set<String?> currencyValues = {};
    for (var tk in tokens) {
      if (tk.underscore?.currency != null) {
        currencyValues.add(tk.underscore!.currency);
      }
    }

    // Extract rating values from tokens
    Set<int?> ratingValues = {};
    for (var tk in tokens) {
      ratingValues.add(tk.underscore?.rating);
    }

    // Combine phonemes
    String? phonemes;
    phonemes = '';
    for (var tk in tokens) {
      if (tk.underscore?.prespace == true && phonemes!.isNotEmpty) {
        phonemes = '$phonemes ';
      }
      phonemes = '$phonemes${(tk.phonemes == null) ? unk : tk.phonemes!}';
    }

    // Combine text
    String text = '';
    for (int i = 0; i < tokens.length - 1; i++) {
      text += tokens[i].text + tokens[i].whitespace;
    }
    text += tokens.last.text;

    // Find the tag with the most uppercase letters (as a proxy for importance)
    String tag =
        tokens.reduce((curr, next) {
          int currWeight =
              curr.text.split('').where((c) => c == c.toUpperCase()).length;
          int nextWeight =
              next.text.split('').where((c) => c == c.toUpperCase()).length;
          return currWeight >= nextWeight ? curr : next;
        }).tag;

    // Combine num_flags
    Set<String> numFlags = {};
    for (var tk in tokens) {
      if (tk.underscore?.numFlags != null) {
        for (int i = 0; i < tk.underscore!.numFlags!.length; i++) {
          numFlags.add(tk.underscore!.numFlags![i]);
        }
      }
    }
    List<String> sortedNumFlags = numFlags.toList()..sort();

    return MToken(
      text: text,
      tag: tag,
      whitespace: tokens.last.whitespace,
      phonemes: phonemes,
      startTs: tokens.first.startTs,
      endTs: tokens.last.endTs,
      underscore: Underscore(
        isHead: tokens.first.underscore?.isHead,
        alias: null,
        stress: stressValues.length == 1 ? stressValues.first : null,
        currency:
            currencyValues.isNotEmpty
                ? currencyValues.reduce((a, b) => a ?? b)
                : null,
        numFlags: sortedNumFlags.join(),
        prespace: tokens.first.underscore?.prespace,
        rating:
            ratingValues.contains(null)
                ? null
                : ratingValues.whereType<int>().reduce((a, b) => a < b ? a : b),
      ),
    );
  }

  /// Convert text to phonetic representation
  Future<(String, List<MToken>)> convert(
    String text, {
    bool preprocess = true,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    // Preprocess the text if needed
    final String processedText = preprocess ? this.preprocess(text) : text;

    // Tokenize the text
    final List<MToken> tokens = tokenize(processedText);

    // Process tokens to determine phonetic representation
    final List<MToken> processedTokens = await processTokens(tokens);

    // Merge tokens when appropriate
    final List<MToken> mergedTokens = mergeTokens(processedTokens);

    // Combine phonemes into a single string
    final StringBuffer phonemes = StringBuffer();
    for (int i = 0; i < mergedTokens.length; i++) {
      final MToken token = mergedTokens[i];

      if (i > 0 && token.underscore?.prespace == true) {
        phonemes.write(' ');
      }

      phonemes.write(token.phonemes ?? unk);
    }

    return (phonemes.toString(), mergedTokens);
  }
}
