import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:wing/shared/async/fire_and_forget.dart';

void main() {
  // Captured eagerly: a lazily-initialized top-level would resolve to the
  // mock that setUp installs, not the real default sink.
  final defaultReporter = reportFireAndForgetFailure;
  late List<({String operation, Object error})> reported;

  setUp(() {
    reported = [];
    reportFireAndForgetFailure = (operation, error) =>
        reported.add((operation: operation, error: error));
  });

  tearDown(() => reportFireAndForgetFailure = defaultReporter);

  test('a rejected operation is reported, not raised', () async {
    fireAndForget(
      Future<void>.error(StateError('recognizer unavailable')),
      'voice capture cancel',
    );
    await Future<void>.delayed(Duration.zero);

    expect(reported.single.operation, 'voice capture cancel');
    expect(reported.single.error, isStateError);
  });

  test('a successful operation reports nothing', () async {
    fireAndForget(Future<void>.value(), 'teardown');
    await Future<void>.delayed(Duration.zero);

    expect(reported, isEmpty);
  });

  test('a null operation is a no-op so service?.cancel() reads naturally', () {
    fireAndForget(null, 'absent service');

    expect(reported, isEmpty);
  });

  test('the operation is started, not merely wrapped', () async {
    var started = false;
    fireAndForget(Future<void>(() async => started = true), 'work');
    await Future<void>.delayed(Duration.zero);

    expect(started, isTrue);
  });

  test(
    'a later rejection is still reported after the caller moved on',
    () async {
      final completer = Completer<void>();
      fireAndForget(completer.future, 'slow teardown');
      await Future<void>.delayed(Duration.zero);
      expect(reported, isEmpty);

      completer.completeError(StateError('too late'));
      await Future<void>.delayed(Duration.zero);

      expect(reported.single.operation, 'slow teardown');
    },
  );

  test('one failure does not suppress the next', () async {
    fireAndForget(Future<void>.error(StateError('first')), 'a');
    fireAndForget(Future<void>.error(StateError('second')), 'b');
    await Future<void>.delayed(Duration.zero);

    expect(reported.map((r) => r.operation), ['a', 'b']);
  });

  test('the default reporter never rethrows', () async {
    reportFireAndForgetFailure = defaultReporter;

    fireAndForget(Future<void>.error(StateError('boom')), 'default sink');
    await Future<void>.delayed(Duration.zero);
  });
}
