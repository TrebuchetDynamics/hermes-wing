/// A contiguous piece of text and the language an offline TTS engine should use.
final class TtsLanguageSegment {
  const TtsLanguageSegment({required this.languageHint, required this.text});

  final String languageHint;
  final String text;

  @override
  bool operator ==(Object other) =>
      other is TtsLanguageSegment &&
      other.languageHint == languageHint &&
      other.text == text;

  @override
  int get hashCode => Object.hash(languageHint, text);
}

abstract interface class TtsLanguageSegmenter {
  List<TtsLanguageSegment> segment(String text);
}

/// Conservative sentence/clause-level English/Spanish segmentation.
///
/// It changes languages only when a span contains clear lexical or orthographic
/// evidence. Ambiguous spans remain with the surrounding language.
final class ConservativeEnglishSpanishSegmenter
    implements TtsLanguageSegmenter {
  const ConservativeEnglishSpanishSegmenter();

  static final RegExp _boundary = RegExp(r'(?:(?<=[.!?;:])[\t ]+|\n+)');
  static final RegExp _word = RegExp(r"[A-Za-zÁÉÍÓÚÜÑáéíóúüñ']+");
  static final RegExp _spanishOrthography = RegExp(r'[¿¡ñáéíóúü]');
  static const Set<String> _spanishWords = {
    'ayuda',
    'ayudar',
    'ayudarte',
    'como',
    'cómo',
    'cuando',
    'donde',
    'el',
    'eres',
    'es',
    'esta',
    'este',
    'esto',
    'gracias',
    'hola',
    'hoy',
    'la',
    'las',
    'los',
    'para',
    'por',
    'puede',
    'puedes',
    'puedo',
    'que',
    'qué',
    'son',
    'soy',
    'una',
    'venir',
  };
  static const Set<String> _englishWords = {
    'a',
    'am',
    'an',
    'and',
    'are',
    'can',
    'continue',
    'could',
    'first',
    'hello',
    'help',
    'how',
    'is',
    'please',
    'second',
    'select',
    'test',
    'that',
    'the',
    'there',
    'this',
    'today',
    'we',
    'what',
    'when',
    'where',
    'would',
    'you',
  };

  @override
  List<TtsLanguageSegment> segment(String text) {
    if (text.isEmpty) return const [];
    final pieces = <String>[];
    var start = 0;
    for (final match in _boundary.allMatches(text)) {
      pieces.add(text.substring(start, match.end));
      start = match.end;
    }
    if (start < text.length) pieces.add(text.substring(start));

    final detected = [for (final piece in pieces) _detect(piece)];
    final segments = <TtsLanguageSegment>[];
    for (var index = 0; index < pieces.length; index += 1) {
      final language =
          detected[index] ?? _nearestLanguage(detected, index) ?? 'en';
      final piece = pieces[index];
      if (segments.isNotEmpty && segments.last.languageHint == language) {
        final previous = segments.removeLast();
        segments.add(
          TtsLanguageSegment(
            languageHint: language,
            text: previous.text + piece,
          ),
        );
      } else {
        segments.add(TtsLanguageSegment(languageHint: language, text: piece));
      }
    }
    return List.unmodifiable(segments);
  }

  String? _detect(String text) {
    var spanishScore = _spanishOrthography.hasMatch(text) ? 2 : 0;
    var englishScore = 0;
    for (final match in _word.allMatches(text)) {
      final token = match.group(0)!.toLowerCase();
      if (_spanishWords.contains(token)) spanishScore += 1;
      if (_englishWords.contains(token)) englishScore += 1;
    }
    if (spanishScore == englishScore) return null;
    return spanishScore > englishScore ? 'es' : 'en';
  }

  String? _nearestLanguage(List<String?> detected, int index) {
    for (var distance = 1; distance < detected.length; distance += 1) {
      final before = index - distance;
      if (before >= 0 && detected[before] != null) return detected[before];
      final after = index + distance;
      if (after < detected.length && detected[after] != null) {
        return detected[after];
      }
    }
    return null;
  }
}
