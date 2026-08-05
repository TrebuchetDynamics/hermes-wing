import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Future<ProcessResult> _runWing(
  List<String> arguments, {
  Map<String, String> environment = const {},
}) => Process.run(
  './wing-cli',
  arguments,
  environment: {
    ...Platform.environment,
    'WING_HERMES_TOKEN': 'test-token',
    ...environment,
  },
);

void _expectCleanFailure(ProcessResult result, String message) {
  expect(result.exitCode, isNonZero);
  expect(result.stderr, contains(message));
  expect(result.stderr, isNot(contains('Traceback')));
  expect(result.stdout, isNot(contains('test-token')));
}

void main() {
  test('wing-cli rejects malformed origins without a traceback', () async {
    for (final origin in [
      'http://127.0.0.1:not-a-port',
      'http://[invalid',
      'http://127.0.0.1:0',
    ]) {
      for (final command in ['qr', 'link']) {
        _expectCleanFailure(
          await _runWing(
            [command, '--origin', origin],
            environment: {'WING_CLI_BROKER_HOST': '127.0.0.1'},
          ),
          '--origin must be an http(s) origin without credentials, path, query, or fragment',
        );
      }
    }
  });

  test('wing-cli rejects invalid broker setup without a traceback', () async {
    for (final environment in [
      {'WING_CLI_BROKER_HOST': 'bad host'},
      {'WING_CLI_BROKER_HOST': '127.0.0.1', 'WING_CLI_BROKER_TIMEOUT': 'bad'},
    ]) {
      _expectCleanFailure(
        await _runWing(
          ['qr'],
          environment: {
            'WING_HERMES_URL': 'http://127.0.0.1:8642',
            ...environment,
          },
        ),
        environment.containsKey('WING_CLI_BROKER_HOST') &&
                environment['WING_CLI_BROKER_HOST'] == 'bad host'
            ? 'WING_CLI_BROKER_HOST could not be bound'
            : 'WING_CLI_BROKER_TIMEOUT must be an integer number of seconds',
      );
    }
  });

  test(
    'wing-cli does not forward credentials through enrollment redirects',
    () async {
      var receivedAuthorization = false;
      final target = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(target.close);
      target.listen((request) async {
        receivedAuthorization = request.headers.value('authorization') != null;
        request.response.statusCode = HttpStatus.internalServerError;
        await request.response.close();
      });
      final origin = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(origin.close);
      origin.listen((request) async {
        request.response
          ..statusCode = HttpStatus.found
          ..headers.set(
            'location',
            'http://127.0.0.1:${target.port}/redirected',
          );
        await request.response.close();
      });

      _expectCleanFailure(
        await _runWing(['link', '--origin', 'http://127.0.0.1:${origin.port}']),
        'Hermes enrollment failed (302).',
      );
      expect(receivedAuthorization, isFalse);
    },
  );

  test(
    'wing-cli rejects unsafe enrollment responses without a traceback',
    () async {
      for (final response in [
        (
          status: HttpStatus.internalServerError,
          body: 'Bearer test-token',
          message: 'Hermes enrollment failed (500).',
        ),
        (
          status: HttpStatus.ok,
          body: 'not-json',
          message: 'Hermes enrollment response was not valid JSON',
        ),
        (
          status: HttpStatus.ok,
          body: '[]',
          message: 'Hermes enrollment response was not an object',
        ),
        (
          status: HttpStatus.ok,
          body: '{"pairing_uri":"http://[invalid"}',
          message:
              'Hermes enrollment response did not include a valid pairing URI',
        ),
      ]) {
        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        addTearDown(server.close);
        server.listen((request) async {
          request.response
            ..statusCode = response.status
            ..write(response.body);
          await request.response.close();
        });
        _expectCleanFailure(
          await _runWing([
            'link',
            '--origin',
            'http://127.0.0.1:${server.port}',
          ]),
          response.message,
        );
      }
    },
  );
}
