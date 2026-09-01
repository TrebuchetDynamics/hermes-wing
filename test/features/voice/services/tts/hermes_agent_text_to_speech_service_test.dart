import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/voice/services/tts/hermes_agent_text_to_speech_service.dart';

void main() {
  test('sends reply text to Hermes Agent and plays returned audio', () async {
    final players = _FakePlayerFactory();
    final spoken = <String>[];
    final service = HermesAgentTextToSpeechService((text) async {
      spoken.add(text);
      return Uint8List.fromList([1, 2, 3]);
    }, playerFactory: players.create);
    addTearDown(() async {
      await service.dispose();
      await players.close();
    });

    final speaking = service.speak(' hello ');
    await Future<void>.delayed(Duration.zero);
    expect(spoken, ['hello']);
    expect(players.latest.audio, [1, 2, 3]);
    players.latest.complete();
    await speaking;
  });

  test('a replacement utterance completes the interrupted caller', () async {
    final players = _FakePlayerFactory();
    final service = HermesAgentTextToSpeechService(
      (_) async => Uint8List.fromList([1]),
      playerFactory: players.create,
    );
    addTearDown(() async {
      await service.dispose();
      await players.close();
    });

    final first = service.speak('first');
    await Future<void>.delayed(Duration.zero);
    final second = service.speak('second');
    await first.timeout(const Duration(seconds: 1));
    players.latest.complete();
    await second;
  });

  test(
    'a delayed predecessor completion cannot finish its replacement',
    () async {
      final players = _FakePlayerFactory();
      final service = HermesAgentTextToSpeechService(
        (_) async => Uint8List.fromList([1]),
        playerFactory: players.create,
      );
      addTearDown(() async {
        await service.dispose();
        await players.close();
      });

      final first = service.speak('first');
      await Future<void>.delayed(Duration.zero);
      final second = service.speak('second');
      await first.timeout(const Duration(seconds: 1));
      await Future<void>.delayed(Duration.zero);
      var secondCompleted = false;
      unawaited(second.then((_) => secondCompleted = true));

      players.players[0].complete();
      await Future<void>.delayed(Duration.zero);
      expect(secondCompleted, isFalse);

      players.players[1].complete();
      await second;
    },
  );

  test('an asynchronous playback error fails the active utterance', () async {
    final players = _FakePlayerFactory();
    final service = HermesAgentTextToSpeechService(
      (_) async => Uint8List.fromList([1]),
      playerFactory: players.create,
    );
    addTearDown(() async {
      await service.dispose();
      await players.close();
    });

    final speaking = service.speak('reply');
    await Future<void>.delayed(Duration.zero);
    players.latest.fail(StateError('playback failed'));

    await expectLater(speaking, throwsStateError);
  });
}

final class _FakePlayerFactory {
  final players = <_FakePlayer>[];

  _FakePlayer create() {
    final player = _FakePlayer();
    players.add(player);
    return player;
  }

  _FakePlayer get latest => players.last;

  Future<void> close() async {
    for (final player in players) {
      await player.close();
    }
  }
}

final class _FakePlayer implements HermesSpeechAudioPlayer {
  final _completions = StreamController<void>.broadcast();
  List<int>? audio;

  @override
  Stream<void> get onComplete => _completions.stream;

  @override
  Future<void> play(Uint8List audio) async => this.audio = audio;

  void complete() => _completions.add(null);

  void fail(Object error) => _completions.addError(error);

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}

  Future<void> close() => _completions.close();
}
