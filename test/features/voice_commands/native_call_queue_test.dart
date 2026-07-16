import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/voice_commands/core/needle_engine.dart';

void main() {
  group('NativeCallQueue', () {
    test(
      'ops run strictly in submission order even when the first is slow',
      () async {
        final queue = NativeCallQueue();
        final log = <String>[];

        final first = queue.run(() async {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          log.add('first');
          return 1;
        });
        final second = queue.run(() async {
          log.add('second');
          return 2;
        });

        expect(await first, 1);
        expect(await second, 2);
        expect(log, ['first', 'second']);
      },
    );

    test('a queued op error does not break the chain', () async {
      final queue = NativeCallQueue();

      final failing = queue.run<void>(() async {
        throw StateError('boom');
      });
      await expectLater(failing, throwsStateError);

      final result = await queue.run(() async => 'still alive');
      expect(result, 'still alive');
    });
  });

  group('NeedleEngine op serialization', () {
    test('load spawns its isolate with sendable captures only', () async {
      final engine = NeedleEngine();
      Object? failure;
      try {
        await engine.load('/nonexistent/model/dir');
      } catch (e) {
        failure = e;
      }
      expect(failure, isNotNull);
      // On host the native lib is absent, so a correctly-structured spawn
      // fails INSIDE the worker isolate with a library-load error. The bug
      // this guards against fails BEFORE spawn with an isolate-message
      // "unsendable" ArgumentError.
      expect('$failure', isNot(contains('unsendable')));
    });

    test('complete after unload rejects asynchronously with '
        'NeedleEngineException', () async {
      final engine = NeedleEngine();
      await engine.unload();

      final future = engine.complete(
        messagesJson: '[]',
        toolsJson: '[]',
        optionsJson: '{}',
      );

      await expectLater(future, throwsA(isA<NeedleEngineException>()));
    });
  });
}
