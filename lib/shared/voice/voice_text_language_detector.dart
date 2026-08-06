import 'package:betto_lang_detector/betto_lang_detector.dart';
import 'package:unorm_dart/unorm_dart.dart' as unorm;

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
    final trimmed = unorm
        .nfc(text)
        .replaceAll(_fencedCode, ' ')
        .replaceAll(_indentedCode, ' ')
        .replaceAll(_inlineCode, ' ')
        .replaceAll(_email, ' ')
        .replaceAll(_url, ' ')
        .replaceAll(_absolutePath, ' ')
        .trim();
    final unquoted = trimmed.replaceAll(_blockquote, ' ').trim();
    final totalLetterCount = trimmed.runes.where(_isLetter).length;
    final unquotedLetterCount = unquoted.runes.where(_isLetter).length;
    final textToDetect =
        unquotedLetterCount >= 12 && unquotedLetterCount * 2 >= totalLetterCount
        ? unquoted
        : trimmed;
    final letterCount = textToDetect.runes.where(_isLetter).length;
    final scriptLanguage = _dominantScriptLanguage(textToDetect, letterCount);
    if (scriptLanguage != null) return scriptLanguage;
    final hint = _shortTextLanguageHint(textToDetect);
    if (hint != null) return hint;
    if (letterCount < 12) return null;
    return switch (_detector.detect(
      _withoutMinorityEastAsianText(textToDetect),
    )) {
      Detected(:final best, :final ranked)
          when ranked.length == 1 ||
              best.confidence - ranked[1].confidence >= 0.1 =>
        best.code,
      _ => null,
    };
  }

  String? _shortTextLanguageHint(String text) {
    if (text.contains('¿') || text.contains('¡')) return 'es';
    final words = RegExp(
      r"[\p{L}\p{M}]+(?:'[\p{L}\p{M}]+)?",
      caseSensitive: false,
      unicode: true,
    ).allMatches(text.toLowerCase()).map((match) => match.group(0)!).toSet();
    if (words.intersection(_englishForeignWordFraming).isNotEmpty &&
        (words.contains('and') ||
            words.contains('english') ||
            words.contains('means'))) {
      return 'en';
    }
    for (final entry in _shortTextMarkers.entries) {
      final matches = words.intersection(entry.value).length;
      if (matches >= 2 &&
          (words.length <= 6 || matches * 5 >= words.length * 2)) {
        return entry.key;
      }
    }
    return null;
  }

  String? _dominantScriptLanguage(String text, int letterCount) {
    if (letterCount == 0) return null;
    for (final script in _distinctLanguageScripts.entries) {
      final scriptLetters = script.value
          .allMatches(text)
          .where((match) => _letter.hasMatch(match.group(0)!))
          .length;
      if (scriptLetters * 2 >= letterCount) return script.key;
    }
    final kana = _kana.allMatches(text).length;
    final hangul = _hangul.allMatches(text).length;
    final han = _han.allMatches(text).length;
    if ((kana + hangul + han) * 2 < letterCount) return null;
    if (kana > 0) return 'ja';
    if (hangul > 0) return 'ko';
    return han > 0 ? 'zh' : null;
  }

  String _withoutMinorityEastAsianText(String text) => text.replaceAll(
    RegExp(r'[\u3040-\u30ff\u3400-\u9fff\uac00-\ud7af]'),
    ' ',
  );

  static const _englishForeignWordFraming = {
    'use',
    'say',
    'compare',
    'explain',
    'word',
    'words',
    'translate',
  };

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
      'explicar',
      'respuesta',
      'claramente',
    },
    'fr': {
      'bonjour',
      'merci',
      'je',
      'vous',
      'peux',
      'aider',
      'comment',
      'oui',
      'expliquer',
      'réponse',
      'clairement',
    },
    'de': {'hallo', 'danke', 'ich', 'kann', 'ihnen', 'helfen', 'nicht'},
    'pt': {'olá', 'você', 'posso', 'ajudar', 'obrigado', 'obrigada', 'não'},
    'it': {
      'ciao',
      'grazie',
      'posso',
      'aiutarti',
      'come',
      'sono',
      'spiegare',
      'risposta',
      'chiaramente',
    },
    'ar': {'مرحبا', 'كيف', 'يمكنني', 'مساعدتك', 'اليوم'},
    'ru': {'привет', 'чем', 'помочь', 'сегодня'},
    'hi': {'नमस्ते', 'मैं', 'आपकी', 'कैसे', 'मदद', 'सकता'},
    'nl': {
      'hallo',
      'ik',
      'vandaag',
      'helpen',
      'vraag',
      'antwoord',
      'uitleggen',
    },
    'az': {
      'salam',
      'bu',
      'gün',
      'sualınıza',
      'cavab',
      'verməyə',
      'cavabı',
      'aydın',
      'izah',
      'etməyə',
      'kömək',
      'bilərəm',
    },
    'tr': {
      'merhaba',
      'bugün',
      'sorunuz',
      'konusunda',
      'size',
      'yardımcı',
      'olabilirim',
    },
    'da': {'hej', 'hjælpe', 'dig', 'dit', 'spørgsmål', 'tydeligt'},
    'no': {'hei', 'hjelpe', 'deg', 'spørsmålet', 'tydelig'},
    'kk': {
      'сәлем',
      'бүгін',
      'сұрағыңызға',
      'жауап',
      'беруге',
      'және',
      'жауабын',
      'анық',
      'түсіндіруге',
      'көмектесе',
      'аламын',
    },
    'mn': {
      'сайн',
      'байна',
      'өнөөдөр',
      'таны',
      'асуултад',
      'хариулж',
      'хариултыг',
      'тодорхой',
      'тайлбарлахад',
      'тусалж',
      'чадна',
    },
    'uk': {
      'привіт',
      'можу',
      'допомогти',
      'вам',
      'запитанням',
      'пояснити',
      'відповідь',
    },
    'fa': {'می', 'توانم', 'امروز', 'پاسخ', 'سؤال', 'شما', 'کمک', 'کنم'},
    'ur': {'میں', 'آج', 'آپ', 'سوال', 'جواب', 'دینے', 'مدد', 'سکتا', 'ہوں'},
    'ne': {
      'नमस्कार',
      'आज',
      'तपाईंको',
      'प्रश्नको',
      'उत्तर',
      'दिन',
      'स्पष्ट',
      'रूपमा',
      'व्याख्या',
      'मद्दत',
      'गर्न',
      'सक्छु',
    },
    'mr': {
      'नमस्कार',
      'मी',
      'तुमच्या',
      'प्रश्नाचे',
      'उत्तर',
      'देण्यास',
      'मदत',
      'करू',
      'शकतो',
    },
    'cs': {'mohu', 'pomoci', 'odpovědět', 'otázku', 'vše', 'vysvětlit'},
    'sk': {
      'deň',
      'môžem',
      'pomôcť',
      'odpovedať',
      'otázku',
      'všetko',
      'vysvetliť',
    },
    'sl': {
      'pozdravljeni',
      'danes',
      'vam',
      'lahko',
      'pomagam',
      'odgovoriti',
      'vprašanje',
      'jasno',
      'razložiti',
      'odgovor',
    },
    'bg': {
      'здравейте',
      'днес',
      'мога',
      'ви',
      'помогна',
      'отговорите',
      'въпроса',
      'обясня',
      'отговора',
      'ясно',
    },
    'sr': {
      'здраво',
      'данас',
      'могу',
      'вам',
      'помогнем',
      'одговорите',
      'питање',
      'јасно',
      'објасним',
      'одговор',
    },
    'ms': {'helo', 'boleh', 'soalan', 'menerangkan', 'jawapannya'},
    'id': {
      'halo',
      'saya',
      'dapat',
      'membantu',
      'menjawab',
      'pertanyaan',
      'anda',
      'menjelaskan',
      'jawabannya',
      'hari',
      'ini',
    },
    'sq': {
      'përshëndetje',
      'sot',
      'mund',
      'ndihmoj',
      'përgjigjeni',
      'pyetjes',
      'shpjegoj',
      'qartë',
      'përgjigjen',
    },
    'is': {
      'halló',
      'ég',
      'get',
      'hjálpað',
      'þér',
      'svara',
      'spurningunni',
      'útskýra',
      'svarið',
      'skýrt',
      'dag',
    },
    'gl': {
      'ola',
      'hoxe',
      'podo',
      'axudarche',
      'responder',
      'pregunta',
      'explicar',
      'claramente',
      'resposta',
    },
    'ro': {
      'bună',
      'ziua',
      'vă',
      'pot',
      'ajuta',
      'să',
      'răspundeți',
      'întrebare',
      'explic',
      'răspunsul',
      'clar',
    },
  };

  static final _fencedCode = RegExp(r'(`{3,}|~{3,}).*?\1', dotAll: true);
  static final _indentedCode = RegExp(r'^(?: {4}|\t).+$', multiLine: true);
  static final _inlineCode = RegExp(r'(`+).*?\1');
  static final _blockquote = RegExp(r'^ {0,3}>.*$', multiLine: true);
  static final _email = RegExp(
    r'[\p{L}\p{M}\p{N}_.+-]+@(?:[\p{L}\p{M}\p{N}-]+\.)+[\p{L}\p{M}]{2,}',
    caseSensitive: false,
    unicode: true,
  );
  static final _url = RegExp(
    r'(?:[a-z][a-z0-9+.-]*://|www\.)\S+|(?:[\p{L}\p{N}-]+\.)+[\p{L}]{2,}(?::\d{1,5})?(?:[/?#]\S*)?',
    caseSensitive: false,
    unicode: true,
  );
  static final _absolutePath = RegExp(
    r'(?<![\p{L}\p{N}])(?:[a-z]:[\\/]|/|\\\\)\S+',
    caseSensitive: false,
    multiLine: true,
    unicode: true,
  );
  static final _letter = RegExp(r'^\p{L}$', unicode: true);
  static final _distinctLanguageScripts = <String, RegExp>{
    'ta': RegExp(r'[\u0b80-\u0bff]'),
    'te': RegExp(r'[\u0c00-\u0c7f]'),
    'kn': RegExp(r'[\u0c80-\u0cff]'),
    'ml': RegExp(r'[\u0d00-\u0d7f]'),
    'si': RegExp(r'[\u0d80-\u0dff]'),
    'lo': RegExp(r'[\u0e80-\u0eff]'),
    'my': RegExp(r'[\u1000-\u109f]'),
    'ka': RegExp(r'[\u10a0-\u10ff]'),
    'km': RegExp(r'[\u1780-\u17ff]'),
  };
  static final _kana = RegExp(r'[\u3040-\u30ff]');
  static final _han = RegExp(r'[\u3400-\u9fff]');
  static final _hangul = RegExp(r'[\uac00-\ud7af]');

  bool _isLetter(int rune) => _letter.hasMatch(String.fromCharCode(rune));
}
