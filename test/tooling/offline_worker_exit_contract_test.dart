import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Whisper disposal awaits worker exit after forced termination', () {
    final source = File(
      'lib/features/voice/services/speech/sherpa_whisper_runtime.dart',
    ).readAsStringSync();
    final isolatedClass = source.indexOf(
      'final class IsolatedSherpaWhisperRuntime',
    );
    final disposeStart = source.indexOf(
      '  Future<void> dispose() async {',
      isolatedClass,
    );
    final dispose = source.substring(
      disposeStart,
      source.indexOf('\n  }\n}', disposeStart),
    );

    expect(source, contains('final Future<void> _workerExited;'));
    expect(dispose, contains('await _workerExited;'));
    expect(dispose, isNot(contains('_workerExited.timeout(')));
    expect(
      dispose.indexOf('_isolate.kill(priority: Isolate.immediate);'),
      lessThan(dispose.indexOf('await _workerExited;')),
    );
    expect(
      dispose.indexOf('await _workerExited;'),
      lessThan(dispose.indexOf('await _exitSubscription.cancel();')),
    );
  });

  test(
    'Whisper startup failure awaits worker exit before closing ownership',
    () {
      final source = File(
        'lib/features/voice/services/speech/sherpa_whisper_runtime.dart',
      ).readAsStringSync();
      final startupStart = source.indexOf(
        '  static Future<IsolatedSherpaWhisperRuntime> start(',
      );
      final startup = source.substring(
        startupStart,
        source.indexOf(
          '  @override\n  Future<OfflineWhisperResult> transcribe(',
          startupStart,
        ),
      );

      expect(startup, contains('} catch (error, stackTrace) {'));
      expect(startup, contains('isolate.kill(priority: Isolate.immediate);'));
      expect(startup, contains('await workerExited.future;'));
      expect(
        startup.indexOf('isolate.kill(priority: Isolate.immediate);'),
        lessThan(startup.indexOf('await workerExited.future;')),
      );
    },
  );
}
