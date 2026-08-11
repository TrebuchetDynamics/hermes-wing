import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/wing_link/local_wing_link_host.dart';

void main() {
  test('inspects through only the Wing Link binary beside Wing', () async {
    final calls = <Object?>[];
    final host = LocalWingLinkHost(
      executablePath: '/opt/hermes-wing/wing',
      runner: (path, arguments) async {
        calls.add(path);
        calls.add(arguments);
        return const LocalWingLinkProcessResult(
          exitCode: 0,
          stdout:
              '{"protocol_version":1,"platform":"linux","hermes_installed":true,"hermes_healthy":true,"hermes_version":"Hermes Agent v1.2.3","wing_link_version":"0.1.0","setup_available":true}',
        );
      },
    );

    final inspection = await host.inspect();

    expect(calls, [
      '/opt/hermes-wing/wing-link',
      ['inspect', '--json'],
    ]);
    expect(inspection.hermesInstalled, isTrue);
    expect(inspection.hermesHealthy, isTrue);
    expect(inspection.hermesVersion, 'Hermes Agent v1.2.3');
    expect(inspection.setupAvailable, isTrue);
  });

  test('runs bounded setup and parses install versus adoption', () async {
    final host = LocalWingLinkHost(
      executablePath: '/opt/hermes-wing/wing',
      runner: (path, arguments) async {
        expect(path, '/opt/hermes-wing/wing-link');
        expect(arguments, ['setup', '--json']);
        return const LocalWingLinkProcessResult(
          exitCode: 0,
          stdout:
              '{"protocol_version":1,"result":{"hermes_installed":true,"hermes_adopted":false,"hermes_version":"Hermes Agent v1.2.3","gateway_started":true}}',
        );
      },
    );

    final result = await host.setup();

    expect(result.hermesInstalled, isTrue);
    expect(result.hermesAdopted, isFalse);
    expect(result.gatewayStarted, isTrue);
  });

  test('rejects a concurrent setup before a starter returns', () async {
    final started = Completer<LocalWingLinkSetupOperation>();
    final host = LocalWingLinkHost(
      executablePath: '/opt/hermes-wing/wing',
      setupStarter: (_, _) => started.future,
    );

    final first = host.setup();
    await expectLater(
      host.setup(),
      throwsA(
        isA<LocalWingLinkException>().having(
          (error) => error.code,
          'code',
          'setup_in_progress',
        ),
      ),
    );
    started.complete(
      _FakeSetupOperation(
        const LocalWingLinkProcessResult(
          exitCode: 0,
          stdout:
              '{"protocol_version":1,"result":{"hermes_installed":true,"hermes_adopted":true,"hermes_version":"Hermes Agent v1.2.3","gateway_started":true}}',
        ),
      ),
    );
    await first;
  });

  test('fails closed when bundled Wing Link exits unsuccessfully', () async {
    final host = LocalWingLinkHost(
      executablePath: '/opt/hermes-wing/wing',
      runner: (path, arguments) async => const LocalWingLinkProcessResult(
        exitCode: 1,
        stderr: 'private diagnostic that must not surface',
      ),
    );

    await expectLater(host.inspect(), throwsA(isA<LocalWingLinkException>()));
  });
}

class _FakeSetupOperation implements LocalWingLinkSetupOperation {
  _FakeSetupOperation(LocalWingLinkProcessResult result)
    : _result = Future.value(result);

  final Future<LocalWingLinkProcessResult> _result;

  @override
  Future<LocalWingLinkProcessResult> get result => _result;

  @override
  Future<void> cancel() async {}
}
