import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/wing_link/termux_wing_link_launcher.dart';

void main() {
  test('reads Termux package and permission readiness independently', () async {
    final launcher = TermuxWingLinkLauncher(
      invoke: (method, arguments) async {
        expect(method, 'availability');
        expect(arguments, isNull);
        return {
          'termux_installed': true,
          'run_command_permission_granted': false,
        };
      },
    );

    final availability = await launcher.availability();

    expect(availability.termuxInstalled, isTrue);
    expect(availability.runCommandPermissionGranted, isFalse);
    expect(availability.ready, isFalse);
  });

  test('dispatches only typed Wing Link operations', () async {
    final calls = <Object?>[];
    final launcher = TermuxWingLinkLauncher(
      invoke: (method, arguments) async {
        calls.add(method);
        calls.add(arguments);
        return {'dispatched': true};
      },
    );

    await launcher.dispatch(TermuxWingLinkOperation.setup);

    expect(calls, [
      'dispatch',
      {'operation': 'setup'},
    ]);
  });

  test('fails closed on malformed native responses', () async {
    final launcher = TermuxWingLinkLauncher(
      invoke: (method, arguments) async => {'dispatched': false},
    );

    await expectLater(
      launcher.dispatch(TermuxWingLinkOperation.start),
      throwsA(isA<TermuxWingLinkException>()),
    );
  });
}
