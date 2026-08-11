import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/settings/providers/voice_settings_provider.dart';
import 'package:wing/shared/voice/text_to_speech_service.dart';

void main() {
  test('offline TTS runtime owner awaits exact service disposal', () async {
    final owner = OfflineTtsRuntimeOwner();
    final service = _BlockingTtsService();
    await owner.adopt(service);

    var released = false;
    final release = owner.releaseAll().then((_) => released = true);
    await Future<void>.delayed(Duration.zero);

    expect(service.disposeCalls, 1);
    expect(released, isFalse);

    service.disposal.complete();
    await release;
    expect(released, isTrue);
  });
}

final class _BlockingTtsService implements TextToSpeechService {
  final disposal = Completer<void>();
  int disposeCalls = 0;

  @override
  Future<void> dispose() {
    disposeCalls += 1;
    return disposal.future;
  }

  @override
  Future<void> speak(String text) async {}

  @override
  Future<void> stop() async {}
}
