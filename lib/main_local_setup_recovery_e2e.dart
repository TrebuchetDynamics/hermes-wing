// Isolated qualification harness: production setup UI, synthetic host only.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/wing_link/local_wing_link_host.dart';
import 'features/local_setup/providers/local_hermes_setup_provider.dart';
import 'features/local_setup/screens/local_hermes_setup_screen.dart';
import 'l10n/app_localizations.dart';

void main() {
  final fixture = SetupRecoveryFixture();
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Direct Agent entry remains independent'),
                FilledButton(
                  onPressed: () => context.push('/local'),
                  child: const Text('Optional Local setup'),
                ),
              ],
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/local',
        builder: (_, _) => const LocalHermesSetupScreen(),
      ),
      GoRoute(
        path: '/enroll',
        builder: (_, _) => const Scaffold(
          body: Center(child: Text('Pairing requires separate authentication')),
        ),
      ),
    ],
  );
  runApp(
    ProviderScope(
      overrides: [localWingLinkHostProvider.overrideWithValue(fixture.host)],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(2),
            disableAnimations: true,
          ),
          child: Column(
            children: [
              Expanded(child: child!),
              Material(
                child: SizedBox(
                  height: 230,
                  child: SingleChildScrollView(
                    child: ListenableBuilder(
                      listenable: fixture,
                      builder: (_, _) => Column(
                        children: [
                          Text(
                            'Fixture calls: inspect=${fixture.inspects} setup=${fixture.setups} cancel=${fixture.cancels}',
                          ),
                          Wrap(
                            spacing: 8,
                            children: [
                              TextButton(
                                onPressed: () {
                                  fixture.installed = false;
                                },
                                child: const Text('Fixture missing'),
                              ),
                              TextButton(
                                onPressed: () {
                                  fixture.installed = true;
                                },
                                child: const Text('Fixture ready'),
                              ),
                              TextButton(
                                onPressed: () => fixture.finish(true),
                                child: const Text('Fixture success'),
                              ),
                              TextButton(
                                onPressed: () => fixture.finish(false),
                                child: const Text('Fixture failure'),
                              ),
                              TextButton(
                                onPressed: () => router.go('/'),
                                child: const Text('Leave setup'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class SetupRecoveryFixture extends ChangeNotifier {
  bool installed = false;
  int inspects = 0;
  int setups = 0;
  int cancels = 0;
  RecoveryOperation? operation;
  late final host = LocalWingLinkHost(
    executablePath: '/synthetic/wing',
    runner: (_, args) async {
      if (args.join(' ') != 'inspect --json') {
        throw StateError('Unexpected operation');
      }
      inspects++;
      notifyListeners();
      return LocalWingLinkProcessResult(
        exitCode: 0,
        stdout: jsonEncode({
          'protocol_version': 2,
          'platform': 'linux',
          'hermes_installed': installed,
          'hermes_healthy': installed,
          'hermes_version': 'Synthetic Agent',
          'setup_available': true,
        }),
      );
    },
    setupStarter: (_, progress) async {
      setups++;
      operation = RecoveryOperation(() {
        cancels++;
        notifyListeners();
      });
      progress(
        const LocalWingLinkProgress(
          phase: 'gateway',
          message: 'synthetic private output',
          percent: 96,
        ),
      );
      notifyListeners();
      return operation!;
    },
  );
  void finish(bool success) {
    final current = operation;
    if (current == null || current.completer.isCompleted) return;
    if (success) installed = true;
    current.completer.complete(
      LocalWingLinkProcessResult(
        exitCode: success ? 0 : 1,
        stdout: success
            ? jsonEncode({
                'protocol_version': 2,
                'result': {
                  'hermes_installed': true,
                  'hermes_adopted': true,
                  'gateway_started': true,
                },
              })
            : 'synthetic private output',
      ),
    );
  }
}

class RecoveryOperation implements LocalWingLinkSetupOperation {
  RecoveryOperation(this.onCancel);
  final VoidCallback onCancel;
  final completer = Completer<LocalWingLinkProcessResult>();
  @override
  Future<LocalWingLinkProcessResult> get result => completer.future;
  @override
  Future<void> cancel() async => onCancel();
}
