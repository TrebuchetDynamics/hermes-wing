import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/channel/hermes_detached_run_store.dart';
import 'package:wing/core/hermes/setup/secure_hermes_detached_run_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('malformed detached-run payload fails closed', () async {
    FlutterSecureStorage.setMockInitialValues({
      'wing.hermes.detached_runs.v1': '{not-json',
    });

    await expectLater(
      SecureHermesDetachedRunStore().load(),
      throwsFormatException,
    );
  });

  test('one malformed detached lease fails the entire recovery load', () async {
    FlutterSecureStorage.setMockInitialValues({
      'wing.hermes.detached_runs.v1':
          '[{"run_id":"run_1","session_id":"sess_1",'
          '"base_url":"http://127.0.0.1:8642",'
          '"created_at":"2026-08-11T00:00:00Z"},'
          '{"run_id":""}]',
    });

    await expectLater(
      SecureHermesDetachedRunStore().load(),
      throwsFormatException,
    );
  });

  test('malformed trailing lease beyond storage bound fails load', () async {
    final rows = List.generate(
      16,
      (index) => {
        'run_id': 'run_$index',
        'session_id': 'sess_1',
        'base_url': 'http://127.0.0.1:8642',
        'created_at': '2026-08-11T00:00:00Z',
      },
    )..add({'run_id': ''});
    FlutterSecureStorage.setMockInitialValues({
      'wing.hermes.detached_runs.v1': jsonEncode(rows),
    });

    await expectLater(
      SecureHermesDetachedRunStore().load(),
      throwsFormatException,
    );
  });

  test('oversized valid persisted ownership fails closed', () async {
    final rows = List.generate(
      17,
      (index) => {
        'run_id': 'run_$index',
        'session_id': 'sess_$index',
        'base_url': 'http://127.0.0.1:8642',
        'created_at': '2026-08-11T00:00:00Z',
      },
    );
    FlutterSecureStorage.setMockInitialValues({
      'wing.hermes.detached_runs.v1': jsonEncode(rows),
    });

    await expectLater(
      SecureHermesDetachedRunStore().load(),
      throwsFormatException,
    );
  });

  test(
    'secure store rejects ownership overflow instead of truncating',
    () async {
      final leases = List.generate(
        17,
        (index) => HermesDetachedRunLease(
          runId: 'run_$index',
          sessionId: 'sess_$index',
          baseUrl: 'http://127.0.0.1:8642',
          profileId: null,
          createdAt: DateTime.utc(2026, 8, 11),
        ),
      );

      await expectLater(
        SecureHermesDetachedRunStore().save(leases),
        throwsStateError,
      );
      expect(await SecureHermesDetachedRunStore().load(), isEmpty);
    },
  );

  test(
    'malformed profile id never becomes default-profile ownership',
    () async {
      for (final malformed in <Object?>['', '   ', 7, false, <String>[]]) {
        FlutterSecureStorage.setMockInitialValues({
          'wing.hermes.detached_runs.v1': jsonEncode([
            {
              'run_id': 'run_1',
              'session_id': 'sess_1',
              'base_url': 'http://127.0.0.1:8642',
              'profile_id': malformed,
              'created_at': '2026-08-11T00:00:00Z',
            },
          ]),
        });

        await expectLater(
          SecureHermesDetachedRunStore().load(),
          throwsFormatException,
          reason: 'profile_id=$malformed must fail closed',
        );
      }
    },
  );
}
