import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/voice/services/speech/speech_to_text_voice_capture_service.dart';

void main() {
  test('speech diagnostics do not log recognized words', () async {
    final logs = <String>[];
    final service = SpeechToTextVoiceCaptureService(
      engine: _FakeSpeechToTextEngine('my private transcript'),
      diagnosticLog: logs.add,
    );

    final capture = await service.capture(timeout: const Duration(seconds: 5));

    expect(capture.transcript, 'my private transcript');
    expect(logs.join('\n'), isNot(contains('my private transcript')));
    expect(logs.join('\n'), contains('result wordsLength=21'));
  });
}

class _FakeSpeechToTextEngine implements SpeechToTextEngine {
  _FakeSpeechToTextEngine(this.words);

  final String words;

  @override
  Future<bool?> hasPermission() async => true;

  @override
  Future<bool> initialize({
    required void Function(Object error) onError,
    required void Function(String status) onStatus,
  }) async {
    onStatus('listening');
    return true;
  }

  @override
  Future<SpeechToTextLocale?> systemLocale() async => null;

  @override
  Future<void> listen({
    required void Function(SpeechToTextSnapshot result) onResult,
    required Duration listenFor,
    required Duration pauseFor,
    required String? localeId,
  }) async {
    onResult(
      SpeechToTextSnapshot(words: words, confidence: 0.9, finalResult: true),
    );
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> cancel() async {}
}
