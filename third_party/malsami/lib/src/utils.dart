import 'constants.dart';
import 'token.dart';

/// Calculate the stress weight of a phoneme sequence
int stressWeight(String ps) {
  if (ps.isEmpty) return 0;

  int weight = 0;
  for (int i = 0; i < ps.length; i++) {
    String c = ps[i];
    if (diphthongs.contains(c)) {
      weight += 2;
    } else if (c != primaryStress && c != secondaryStress) {
      weight += 1;
    }
  }
  return weight;
}

/// Apply stress to a phoneme sequence
String applyStress(String ps, double? stress) {
  if (ps.isEmpty) return ps;
  if (stress == null) return ps;

  // Remove all stresses
  if (stress < -1) {
    return ps.replaceAll(primaryStress, '').replaceAll(secondaryStress, '');
  }

  // Convert primary stress to secondary
  if (stress == -1 || ((stress == 0 || stress == -0.5) && ps.contains(primaryStress))) {
    return ps.replaceAll(secondaryStress, '').replaceAll(primaryStress, secondaryStress);
  }

  // Add secondary stress if no stress marks present
  if ((stress == 0 || stress == 0.5 || stress == 1) &&
      !ps.contains(primaryStress) && !ps.contains(secondaryStress)) {
    if (!containsAnyVowel(ps)) return ps;
    return restress(secondaryStress + ps);
  }

  // Convert secondary stress to primary
  if (stress >= 1 && !ps.contains(primaryStress) && ps.contains(secondaryStress)) {
    return ps.replaceAll(secondaryStress, primaryStress);
  }

  // Add primary stress if no stress marks present
  if (stress > 1 && !ps.contains(primaryStress) && !ps.contains(secondaryStress)) {
    if (!containsAnyVowel(ps)) return ps;
    return restress(primaryStress + ps);
  }

  return ps;
}

/// Check if a string contains any vowel
bool containsAnyVowel(String text) {
  for (int i = 0; i < text.length; i++) {
    if (vowels.contains(text[i])) {
      return true;
    }
  }
  return false;
}

/// Reposition stress marks to be before vowels
String restress(String ps) {
  List<MapEntry<double, String>> ips = [];

  // Create indexed list of characters
  for (int i = 0; i < ps.length; i++) {
    ips.add(MapEntry(i.toDouble(), ps[i]));
  }

  // Find stress marks and their target vowels
  Map<int, int> stresses = {};
  for (int i = 0; i < ips.length; i++) {
    // Check if this character is a stress mark
    if (stresses.containsKey(i)) {
      // Find the next vowel
      for (int j = i; j < ips.length; j++) {
        if (vowels.contains(ips[j].value)) {
          stresses[i] = j;
          break;
        }
      }
    }
  }

  // Reposition stress marks
  for (var entry in stresses.entries) {
    int i = entry.key;
    int j = entry.value;
    String s = ips[i].value;
    ips[i] = MapEntry(j - 0.5, s);
  }

  // Sort and reconstruct the string
  ips.sort((a, b) => a.key.compareTo(b.key));
  return ips.map((e) => e.value).join();
}

/// Check if a string consists only of digits
bool isDigit(String text) {
  return digitRegex.hasMatch(text);
}

/// Merge a list of tokens into a single token
MToken mergeTokens(List<MToken> tokens, [String? unk]) {
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
  if (unk != null) {
    phonemes = '';
    for (var tk in tokens) {
      if (tk.underscore?.prespace == true && phonemes!.isNotEmpty &&
          !phonemes.endsWith(' ') && tk.phonemes != null) {
        phonemes = '$phonemes ';
      }
      phonemes = '$phonemes${(tk.phonemes == null) ? unk : tk.phonemes!}';
    }
  }

  // Combine text
  String text = '';
  for (int i = 0; i < tokens.length - 1; i++) {
    text += tokens[i].text + tokens[i].whitespace;
  }
  text += tokens.last.text;

  // Find the tag with the most uppercase letters (as a proxy for importance)
  String tag = tokens.reduce((curr, next) {
    int currWeight = curr.text.split('').where((c) => c == c.toUpperCase()).length;
    int nextWeight = next.text.split('').where((c) => c == c.toUpperCase()).length;
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
      currency: currencyValues.isNotEmpty ? currencyValues.reduce((a, b) => a ?? b) : null,
      numFlags: sortedNumFlags.join(),
      prespace: tokens.first.underscore?.prespace,
      rating: ratingValues.contains(null) ? null : ratingValues.whereType<int>().reduce((a, b) => a < b ? a : b),
    ),
  );
}

/// Token context class for tracking contextual information during processing
class TokenContext {
  final bool? futureVowel;
  final bool futureTo;

  const TokenContext({
    this.futureVowel,
    this.futureTo = false,
  });
}
