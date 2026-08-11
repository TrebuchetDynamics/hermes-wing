import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/wing_link/local_wing_link_host.dart';
import 'package:wing/features/local_setup/providers/local_hermes_setup_provider.dart';
import 'package:wing/features/local_setup/screens/local_hermes_setup_screen.dart';
import 'package:wing/l10n/app_localizations.dart';

void main() {
  testWidgets('installs missing Hermes only after explicit consent', (
    tester,
  ) async {
    final responses = <LocalWingLinkProcessResult>[
      const LocalWingLinkProcessResult(
        exitCode: 0,
        stdout:
            '{"protocol_version":1,"platform":"linux","hermes_installed":false,"hermes_healthy":false,"wing_link_version":"dev","setup_available":true}',
      ),
      const LocalWingLinkProcessResult(
        exitCode: 0,
        stdout:
            '{"protocol_version":1,"result":{"hermes_installed":true,"hermes_adopted":false,"hermes_version":"Hermes Agent v1.2.3","gateway_started":true}}',
      ),
      const LocalWingLinkProcessResult(
        exitCode: 0,
        stdout:
            '{"protocol_version":1,"platform":"linux","hermes_installed":true,"hermes_healthy":true,"hermes_version":"Hermes Agent v1.2.3","wing_link_version":"dev","setup_available":true}',
      ),
    ];
    final calls = <List<String>>[];
    final host = LocalWingLinkHost(
      executablePath: '/opt/hermes-wing/wing',
      runner: (path, arguments) async {
        calls.add(arguments);
        return responses.removeAt(0);
      },
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [localWingLinkHostProvider.overrideWithValue(host)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const LocalHermesSetupScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hermes Agent is not installed'), findsOneWidget);
    expect(calls, [
      ['inspect', '--json'],
    ]);

    await tester.tap(find.byKey(const ValueKey('local-hermes-setup-action')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('local-hermes-setup-consent')),
      findsOneWidget,
    );
    expect(calls.length, 1);

    await tester.tap(find.byKey(const ValueKey('local-hermes-setup-confirm')));
    await tester.pumpAndSettle();

    expect(find.text('Hermes gateway is ready'), findsOneWidget);
    expect(calls, [
      ['inspect', '--json'],
      ['setup', '--json'],
      ['inspect', '--json'],
    ]);
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
