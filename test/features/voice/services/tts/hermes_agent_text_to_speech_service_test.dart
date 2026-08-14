import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/voice/services/tts/hermes_agent_text_to_speech_service.dart';

void main() {
  test('sends reply text to Hermes Agent and plays returned audio', () async {
    final player = _FakePlayer();
    final spoken = <String>[];
    final service = HermesAgentTextToSpeechService((text) async {
      spoken.add(text);
      return Uint8List.fromList([1, 2, 3]);
    }, player: player);
    addTearDown(service.dispose);

    final speaking = service.speak(' hello ');
    await Future<void>.delayed(Duration.zero);
    expect(spoken, ['hello']);
    expect(player.audio, [1, 2, 3]);
    player.complete();
    await speaking;
  });

  test('a replacement utterance completes the interrupted caller', () async {
    final player = _FakePlayer();
    final service = HermesAgentTextToSpeechService(
      (_) async => Uint8List.fromList([1]),
      player: player,
    );
    addTearDown(service.dispose);

    final first = service.speak('first');
    await Future<void>.delayed(Duration.zero);
    final second = service.speak('second');
    await first.timeout(const Duration(seconds: 1));
    player.complete();
    await second;
  });
}

final class _FakePlayer implements HermesSpeechAudioPlayer {
  final _completions = StreamController<void>.broadcast();
  List<int>? audio;

  @override
  Stream<void> get onComplete => _completions.stream;

  @override
  Future<void> play(Uint8List audio) async => this.audio = audio;

  void complete() => _completions.add(null);

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() => _completions.close();
}
