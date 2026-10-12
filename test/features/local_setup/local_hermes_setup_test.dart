import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/wing_link/local_wing_link_host.dart';
import 'package:wing/features/local_setup/providers/local_hermes_setup_provider.dart';

void main() {
  test('dispose cancels an active host setup operation', () async {
    final operation = _PendingSetupOperation();
    final host = LocalWingLinkHost(
      executablePath: '/opt/hermes-wing/wing',
      runner: (_, _) async => const LocalWingLinkProcessResult(
        exitCode: 0,
        stdout:
            '{"protocol_version":1,"platform":"linux","hermes_installed":true,"hermes_healthy":true,"hermes_version":"Hermes Agent v1.2.3","wing_link_version":"dev","setup_available":true}',
      ),
      setupStarter: (_, _) async => operation,
    );
    final controller = LocalHermesSetupController(host);
    await controller.inspect();

    final setup = controller.setup();
    await Future<void>.delayed(Duration.zero);
    controller.dispose();
    await Future<void>.delayed(Duration.zero);

    expect(operation.cancelled, isTrue);
    operation.completeCancelled();
    await setup;
  });

  test('classifies healthy existing Hermes as adoptable', () async {
    final controller = LocalHermesSetupController(
      LocalWingLinkHost(
        executablePath: '/opt/hermes-wing/wing',
        runner: (path, arguments) async => const LocalWingLinkProcessResult(
          exitCode: 0,
          stdout:
              '{"protocol_version":1,"platform":"linux","hermes_installed":true,"hermes_healthy":true,"hermes_version":"Hermes Agent v1.2.3","wing_link_version":"dev","setup_available":true}',
        ),
      ),
    );
    addTearDown(controller.dispose);

    await controller.inspect();

    expect(controller.status, LocalHermesSetupStatus.ready);
    expect(controller.inspection?.hermesVersion, 'Hermes Agent v1.2.3');
  });
}

class _PendingSetupOperation implements LocalWingLinkSetupOperation {
  final Completer<LocalWingLinkProcessResult> _result = Completer();
  bool cancelled = false;

  @override
  Future<LocalWingLinkProcessResult> get result => _result.future;

  @override
  Future<void> cancel() async {
    cancelled = true;
    completeCancelled();
  }

  void completeCancelled() {
    if (_result.isCompleted) return;
    _result.complete(const LocalWingLinkProcessResult(exitCode: 130));
  }
}
