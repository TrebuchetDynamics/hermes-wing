import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/wing_link/local_wing_link_host.dart';
import 'package:wing/features/local_setup/providers/local_hermes_setup_provider.dart';
import 'package:wing/features/local_setup/screens/local_hermes_setup_screen.dart';
import 'package:wing/l10n/app_localizations.dart';

void main() {
  testWidgets('port conflict offers specific recovery without raw host details', (
    tester,
  ) async {
    var setups = 0;
    final host = LocalWingLinkHost(
      executablePath: '/opt/hermes-wing/wing',
      runner: (_, args) async {
        if (args.first == 'setup') {
          setups++;
          return const LocalWingLinkProcessResult(
            exitCode: 1,
            stdout:
                '{"protocol_version":2,"error":{"code":"gateway_port_in_use","message":"private host detail"}}',
          );
        }
        return const LocalWingLinkProcessResult(
          exitCode: 0,
          stdout:
              '{"protocol_version":2,"platform":"linux","hermes_installed":true,"hermes_healthy":true,"hermes_version":"Hermes Agent v1.2.3","setup_available":true}',
        );
      },
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [localWingLinkHostProvider.overrideWithValue(host)],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: LocalHermesSetupScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('local-hermes-setup-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('local-hermes-setup-confirm')));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('local Hermes API port is already in use'),
      findsOneWidget,
    );
    expect(find.textContaining('private host detail'), findsNothing);
    expect(find.text('Connection options'), findsOneWidget);
    await tester.tap(find.text('Check again'));
    await tester.pumpAndSettle();
    expect(setups, 1);
  });

  testWidgets(
    'setup shows its current stage and can be stopped without retrying',
    (tester) async {
      final operation = _PendingSetupOperation();
      var setupCalls = 0;
      final host = LocalWingLinkHost(
        executablePath: '/opt/hermes-wing/wing',
        runner: (_, _) async => const LocalWingLinkProcessResult(
          exitCode: 0,
          stdout:
              '{"protocol_version":2,"platform":"linux","hermes_installed":true,"hermes_healthy":true,"hermes_version":"Hermes Agent v1.2.3","setup_available":true}',
        ),
        setupStarter: (_, progress) async {
          setupCalls++;
          progress(
            const LocalWingLinkProgress(
              phase: 'gateway',
              message: 'private process output',
              percent: 96,
            ),
          );
          return operation;
        },
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [localWingLinkHostProvider.overrideWithValue(host)],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: LocalHermesSetupScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('local-hermes-setup-action')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('local-hermes-setup-confirm')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Starting the Hermes gateway'), findsOneWidget);
      expect(find.textContaining('private process output'), findsNothing);
      expect(find.text('96%'), findsOneWidget);
      await tester.tap(find.text('Stop setup'));
      await tester.pumpAndSettle();
      expect(operation.cancelled, isTrue);
      expect(find.text('Setup stopped'), findsOneWidget);
      expect(setupCalls, 1);
      await tester.tap(find.text('Check again'));
      await tester.pumpAndSettle();
      expect(find.text('Hermes Agent is ready'), findsOneWidget);
      expect(setupCalls, 1);
    },
  );

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

    expect(find.text('Set up Hermes on this Linux computer'), findsOneWidget);
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

  testWidgets('inspection failure is announced and retry recovers', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var calls = 0;
    final host = LocalWingLinkHost(
      executablePath: '/opt/hermes-wing/wing',
      runner: (_, _) async {
        calls++;
        if (calls == 1) {
          throw StateError('private host path and process detail');
        }
        return const LocalWingLinkProcessResult(
          exitCode: 0,
          stdout:
              '{"protocol_version":1,"platform":"linux","hermes_installed":true,"hermes_healthy":true,"hermes_version":"Hermes Agent v1.2.3","wing_link_version":"dev","setup_available":true}',
        );
      },
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [localWingLinkHostProvider.overrideWithValue(host)],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: LocalHermesSetupScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final failure = find.byKey(const ValueKey('local-hermes-setup-failure'));
    expect(failure, findsOneWidget);
    expect(tester.getSemantics(failure).flagsCollection.isLiveRegion, isTrue);
    expect(find.text('Setup needs attention'), findsOneWidget);
    expect(find.textContaining('private host path'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('local-hermes-setup-retry')));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text('Hermes Agent is ready'), findsOneWidget);
    semantics.dispose();
  });

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
