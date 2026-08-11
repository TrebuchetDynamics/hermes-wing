import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/voice/services/tts/incremental_tts_coordinator.dart';
import 'package:wing/features/voice/services/tts/incremental_tts_engine.dart';
import 'package:wing/shared/voice/text_to_speech_service.dart';

void main() {
  test('streams language-segmented PCM chunks to playback in order', () async {
    final engine = _FakeIncrementalTtsEngine();
    final playback = _FakePcmPlayback();
    final coordinator = IncrementalTtsCoordinator(
      engine: engine,
      playback: playback,
      fallback: FakeTextToSpeechService(),
    );

    await coordinator.speak('Hello, how are you? Hola, ¿cómo estás hoy?');

    expect(
      engine.requests.map((request) => (request.languageHint, request.text)),
      [('en', 'Hello, how are you? '), ('es', 'Hola, ¿cómo estás hoy?')],
    );
    expect(playback.bytes, [1, 2]);
    expect(engine.requests.map((request) => request.generation).toSet(), {1});
  });

  test('stop invalidates generation before cancellation finishes', () async {
    final engine = _ControlledIncrementalTtsEngine();
    final playback = _FakePcmPlayback();
    final coordinator = IncrementalTtsCoordinator(
      engine: engine,
      playback: playback,
      fallback: FakeTextToSpeechService(),
    );
    final speaking = coordinator.speak('Hello there.');
    await _flushEvents();
    final generation = engine.requests.single.generation;

    final stopping = coordinator.stop();
    engine.emit(generation, 7);
    await _flushEvents();

    expect(playback.bytes, isEmpty);
    engine.finishSecondStop();
    await stopping;
    await speaking;
  });

  test('active synthesis errors fail over with the original text', () async {
    final fallback = FakeTextToSpeechService();
    final coordinator = IncrementalTtsCoordinator(
      engine: _FailingIncrementalTtsEngine(),
      playback: _FakePcmPlayback(),
      fallback: fallback,
    );

    await coordinator.speak('Hello. Hola, ¿cómo estás?');

    expect(fallback.spoken, ['Hello. Hola, ¿cómo estás?']);
  });

  test('stale chunks and errors cannot affect a successor', () async {
    final engine = _MultiControlledIncrementalTtsEngine();
    final playback = _FakePcmPlayback();
    final fallback = FakeTextToSpeechService();
    final coordinator = IncrementalTtsCoordinator(
      engine: engine,
      playback: playback,
      fallback: fallback,
    );
    final first = coordinator.speak('Hello first.');
    await _flushEvents();
    final firstGeneration = engine.requests.single.generation;

    final second = coordinator.speak('Hello second.');
    await _flushEvents();
    final secondGeneration = engine.requests.last.generation;
    engine.emit(secondGeneration, firstGeneration, 8);
    engine.fail(firstGeneration);
    await engine.complete(firstGeneration);
    engine.emit(secondGeneration, secondGeneration, 9);
    await engine.complete(secondGeneration);

    await second;
    await first;
    expect(playback.bytes, [9]);
    expect(fallback.spoken, isEmpty);
  });

  test('playback errors do not invoke synthesis fallback', () async {
    final fallback = FakeTextToSpeechService();
    final coordinator = IncrementalTtsCoordinator(
      engine: _FakeIncrementalTtsEngine(),
      playback: _FailingPcmPlayback(),
      fallback: fallback,
    );

    await expectLater(coordinator.speak('Hello.'), throwsStateError);

    expect(fallback.spoken, isEmpty);
  });
}

Future<void> _flushEvents() => Future<void>.delayed(Duration.zero);

final class _MultiControlledIncrementalTtsEngine
    implements IncrementalTtsEngine {
  final List<TtsSynthesisRequest> requests = [];
  final Map<int, StreamController<PcmAudioChunk>> _controllers = {};

  @override
  Stream<PcmAudioChunk> synthesize(TtsSynthesisRequest request) {
    requests.add(request);
    return (_controllers[request.generation] =
            StreamController<PcmAudioChunk>())
        .stream;
  }

  void emit(int requestGeneration, int chunkGeneration, int byte) {
    _controllers[requestGeneration]!.add(
      PcmAudioChunk(
        generation: chunkGeneration,
        bytes: Uint8List.fromList([byte]),
      ),
    );
  }

  void fail(int generation) {
    _controllers[generation]!.addError(StateError('stale failure'));
  }

  Future<void> complete(int generation) => _controllers[generation]!.close();

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {
    await Future.wait(
      _controllers.values.map((controller) => controller.close()),
    );
  }
}

final class _FailingIncrementalTtsEngine implements IncrementalTtsEngine {
  @override
  Stream<PcmAudioChunk> synthesize(TtsSynthesisRequest request) =>
      Stream<PcmAudioChunk>.error(StateError('synthesis failed'));

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}

final class _ControlledIncrementalTtsEngine implements IncrementalTtsEngine {
  final List<TtsSynthesisRequest> requests = [];
  final _controller = StreamController<PcmAudioChunk>();
  final _secondStop = Completer<void>();
  int _stopCalls = 0;

  @override
  Stream<PcmAudioChunk> synthesize(TtsSynthesisRequest request) {
    requests.add(request);
    return _controller.stream;
  }

  void emit(int generation, int byte) {
    _controller.add(
      PcmAudioChunk(generation: generation, bytes: Uint8List.fromList([byte])),
    );
  }

  void finishSecondStop() => _secondStop.complete();

  @override
  Future<void> stop() {
    _stopCalls += 1;
    return _stopCalls == 2 ? _secondStop.future : Future<void>.value();
  }

  @override
  Future<void> dispose() async {
    await _controller.close();
  }
}

final class _FakeIncrementalTtsEngine implements IncrementalTtsEngine {
  final List<TtsSynthesisRequest> requests = [];

  @override
  Stream<PcmAudioChunk> synthesize(TtsSynthesisRequest request) {
    requests.add(request);
    return Stream.value(
      PcmAudioChunk(
        generation: request.generation,
        bytes: Uint8List.fromList([requests.length]),
      ),
    );
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}

final class _FailingPcmPlayback implements IncrementalPcmPlayback {
  @override
  Future<void> write(PcmAudioChunk chunk) =>
      Future<void>.error(StateError('playback failed'));

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}

final class _FakePcmPlayback implements IncrementalPcmPlayback {
  final List<int> bytes = [];

  @override
  Future<void> write(PcmAudioChunk chunk) async {
    bytes.addAll(chunk.bytes);
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}
