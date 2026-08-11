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
