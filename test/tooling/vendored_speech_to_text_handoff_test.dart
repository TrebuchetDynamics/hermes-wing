import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text_platform_interface/speech_to_text_platform_interface.dart';

void main() {
  late SpeechToTextPlatform originalPlatform;
  late _DelayedSpeechPlatform platform;
  late SpeechToText speech;

  setUp(() {
    originalPlatform = SpeechToTextPlatform.instance;
    platform = _DelayedSpeechPlatform();
    SpeechToTextPlatform.instance = platform;
    speech = SpeechToText.withMethodChannel();
  });

  tearDown(() {
    SpeechToTextPlatform.instance = originalPlatform;
  });

  test('rejects overlapping listen while native handoff is pending', () async {
    expect(await speech.initialize(), isTrue);
    final first = speech.listen();

    await expectLater(speech.listen(), throwsA(isA<ListenFailedException>()));

    platform.completeListen(0, true);
    await first;
  });

  test('stale listen completion cannot clear successor handoff', () async {
    final statuses = <String>[];
    final errors = <String>[];
    final levels = <double>[];
    await speech.initialize(
      onStatus: statuses.add,
      onError: (error) => errors.add(error.errorMsg),
    );

    final predecessor = speech.listen(onSoundLevelChange: levels.add);
    await speech.cancel();
    final successor = speech.listen(onSoundLevelChange: levels.add);

    platform.completeListen(0, true);
    await predecessor;
    platform.onStatus?.call('done');
    platform.onError?.call('{"errorMsg":"stale predecessor","permanent":true}');
    platform.onSoundLevel?.call(99);

    expect(statuses, isEmpty);
    expect(errors, isEmpty);
    expect(levels, isEmpty);

    platform.completeListen(1, true);
    await successor;
    expect(statuses, [SpeechToText.listeningStatus]);
  });
}

class _DelayedSpeechPlatform extends SpeechToTextPlatform {
  final _listenCompletions = <Completer<bool>>[];

  @override
  Future<bool> initialize({
    debugLogging = false,
    List<SpeechConfigOption>? options,
  }) async => true;

  @override
  Future<bool> hasPermission() async => true;

  @override
  Future<bool> listen({
    String? localeId,
    SpeechListenOptions? options,
    partialResults = true,
    onDevice = false,
    int listenMode = 0,
    sampleRate = 0,
  }) {
    final completion = Completer<bool>();
    _listenCompletions.add(completion);
    return completion.future;
  }

  void completeListen(int index, bool started) {
    _listenCompletions[index].complete(started);
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> cancel() async {}
}
