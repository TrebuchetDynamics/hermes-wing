import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/wing_link/local_wing_link_host.dart';
import 'package:wing/features/local_setup/providers/local_hermes_setup_provider.dart';

const inspection = LocalWingLinkProcessResult(
  exitCode: 0,
  stdout:
      '{"protocol_version":2,"platform":"linux","hermes_installed":true,"hermes_healthy":true,"setup_available":true}',
);

void main() {
  for (final success in [true, false]) {
    test(
      'Stop fences delayed ${success ? 'success' : 'failure'} until explicit inspect',
      () async {
        var reads = 0;
        var setups = 0;
        final operation = PendingOperation();
        final controller = LocalHermesSetupController(
          LocalWingLinkHost(
            executablePath: '/synthetic/wing',
            runner: (_, _) async {
              reads++;
              return inspection;
            },
            setupStarter: (_, _) async {
              setups++;
              return operation;
            },
          ),
        );
        await controller.inspect();
        final setup = controller.setup();
        await Future<void>.delayed(Duration.zero);
        final cancel = controller.cancel();
        expect(controller.status, LocalHermesSetupStatus.cancelling);
        operation.resultCompleter.complete(
          LocalWingLinkProcessResult(
            exitCode: success ? 0 : 1,
            stdout: success
                ? '{"protocol_version":2,"result":{"hermes_installed":true,"hermes_adopted":true,"gateway_started":true}}'
                : 'synthetic private output',
          ),
        );
        await Future.wait([setup, cancel]);
        expect(controller.status, LocalHermesSetupStatus.cancelled);
        expect(reads, 1);
        expect(setups, 1);
        await controller.setup();
        expect(setups, 1);
        await controller.inspect();
        expect(reads, 2);
        expect(controller.status, LocalHermesSetupStatus.ready);
        controller.dispose();
      },
    );
  }

  test(
    'dispose contains cancellation errors and ignores late failure',
    () async {
      final operation = PendingOperation();
      final controller = LocalHermesSetupController(
        LocalWingLinkHost(
          executablePath: '/synthetic/wing',
          runner: (_, _) async => inspection,
          setupStarter: (_, _) async => operation,
        ),
      );
      await controller.inspect();
      final setup = controller.setup();
      await Future<void>.delayed(Duration.zero);
      controller.dispose();
      operation.resultCompleter.completeError(StateError('synthetic failure'));
      await setup;
      await Future<void>.delayed(Duration.zero);
      expect(controller.status, LocalHermesSetupStatus.installing);
    },
  );

  test('disposed controller cannot initiate inspection or setup', () async {
    final calls = <List<String>>[];
    final controller = LocalHermesSetupController(
      LocalWingLinkHost(
        executablePath: '/synthetic/wing',
        runner: (_, args) async {
          calls.add(args);
          return inspection;
        },
      ),
    );
    await controller.inspect();
    controller.dispose();
    await controller.inspect();
    await controller.setup();
    expect(calls, [
      ['inspect', '--json'],
    ]);
  });
}

class PendingOperation implements LocalWingLinkSetupOperation {
  final resultCompleter = Completer<LocalWingLinkProcessResult>();
  @override
  Future<LocalWingLinkProcessResult> get result => resultCompleter.future;
  @override
  Future<void> cancel() async {}
}
