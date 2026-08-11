import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/voice/services/tts/language_segmenter.dart';

void main() {
  const segmenter = ConservativeEnglishSpanishSegmenter();

  test(
    'segments clear English and Spanish sentences without changing text',
    () {
      const text = 'Hello, how are you? Hola, ¿cómo estás hoy?';

      final segments = segmenter.segment(text);

      expect(segments, const [
        TtsLanguageSegment(languageHint: 'en', text: 'Hello, how are you? '),
        TtsLanguageSegment(languageHint: 'es', text: 'Hola, ¿cómo estás hoy?'),
      ]);
      expect(segments.map((segment) => segment.text).join(), text);
    },
  );

  test('does not switch for very short ambiguous spans', () {
    const text = 'Please continue. No. Select OK.';

    final segments = segmenter.segment(text);

    expect(segments, const [
      TtsLanguageSegment(languageHint: 'en', text: text),
    ]);
  });

  test('keeps a short ambiguous span in its Spanish context', () {
    const text = 'Hola, ¿cómo estás? OK. Gracias por venir.';

    expect(segmenter.segment(text), const [
      TtsLanguageSegment(languageHint: 'es', text: text),
    ]);
  });

  test('segments clear language changes at clause boundaries', () {
    const text = 'Please continue; gracias por venir.';

    expect(segmenter.segment(text), const [
      TtsLanguageSegment(languageHint: 'en', text: 'Please continue; '),
      TtsLanguageSegment(languageHint: 'es', text: 'gracias por venir.'),
    ]);
  });

  test('recognizes common unaccented Spanish without overfitting accents', () {
    const text = 'This is a test. Esta es una prueba.';

    expect(segmenter.segment(text), const [
      TtsLanguageSegment(languageHint: 'en', text: 'This is a test. '),
      TtsLanguageSegment(languageHint: 'es', text: 'Esta es una prueba.'),
    ]);
  });
}
