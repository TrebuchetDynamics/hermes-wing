import 'package:flutter_test/flutter_test.dart';
import 'package:wing/shared/voice/voice_text_language_detector.dart';

void main() {
  final detector = DefaultVoiceTextLanguageDetector();

  test('identifies common incoming reply languages', () {
    expect(
      detector.detect(
        'Hello. I can help you with your question and explain the answer clearly.',
      ),
      'en',
    );
    expect(detector.detect('Hola, ¿cómo puedo ayudarte hoy?'), 'es');
    expect(detector.detect('Bonjour, comment puis-je vous aider ?'), 'fr');
    expect(detector.detect('こんにちは、お手伝いできますか？'), 'ja');
  });

  test('keeps the device TTS language for ambiguous short text', () {
    expect(detector.detect('2'), isNull);
    expect(detector.detect('ok'), isNull);
    expect(detector.detect('Hello, how can I help you today?'), isNull);
  });
}
