import 'package:betto_lang_detector/betto_lang_detector.dart';

/// Identifies the language of text before it is sent to a speech engine.
abstract interface class VoiceTextLanguageDetector {
  /// Returns an ISO 639-1 language code, or null when the text is too short
  /// or ambiguous to safely override the device's selected TTS language.
  String? detect(String text);
}

class DefaultVoiceTextLanguageDetector implements VoiceTextLanguageDetector {
  DefaultVoiceTextLanguageDetector({LanguageDetector? detector})
    : _detector = detector ?? LanguageDetector.pureDart(minConfidence: 0.75);

  final LanguageDetector _detector;

  @override
  String? detect(String text) {
    final trimmed = text.trim();
    final hint = _shortTextLanguageHint(trimmed);
    if (hint != null) return hint;
    if (trimmed.runes.where(_isLetter).length < 12) return null;
    return switch (_detector.detect(trimmed)) {
      Detected(:final best, :final ranked)
          when ranked.length == 1 ||
              best.confidence - ranked[1].confidence >= 0.1 =>
        best.code,
      _ => null,
    };
  }

  String? _shortTextLanguageHint(String text) {
    if (text.contains('¿') || text.contains('¡')) return 'es';
    if (RegExp(r'[\u3040-\u30ff]').hasMatch(text)) return 'ja';
    if (RegExp(r'[\uac00-\ud7af]').hasMatch(text)) return 'ko';

    final words = RegExp(
      r"[a-zÀ-ÿ']+",
      caseSensitive: false,
    ).allMatches(text.toLowerCase()).map((match) => match.group(0)!).toSet();
    for (final entry in _shortTextMarkers.entries) {
      if (words.intersection(entry.value).length >= 2) return entry.key;
    }
    return null;
  }

  static const _shortTextMarkers = <String, Set<String>>{
    'es': {
      'hola',
      'cómo',
      'estás',
      'puedo',
      'ayudarte',
      'gracias',
      'qué',
      'sí',
    },
    'fr': {'bonjour', 'merci', 'je', 'vous', 'peux', 'aider', 'comment', 'oui'},
    'de': {'hallo', 'danke', 'ich', 'kann', 'ihnen', 'helfen', 'nicht'},
    'pt': {'olá', 'você', 'posso', 'ajudar', 'obrigado', 'obrigada', 'não'},
    'it': {'ciao', 'grazie', 'posso', 'aiutarti', 'come', 'sono'},
  };

  bool _isLetter(int rune) =>
      (rune >= 0x41 && rune <= 0x5a) ||
      (rune >= 0x61 && rune <= 0x7a) ||
      rune > 0x7f;
}
