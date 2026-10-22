import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:wing/core/hermes/ssh/secure_ssh_quick_connect_store.dart';
import 'package:wing/core/hermes/ssh/secure_managed_ssh_host_trust_store.dart';
import 'package:wing/core/hermes/ssh/ssh_types.dart';
import 'package:wing/features/hermes_chat/providers/managed_ssh_connection_controller.dart';
import 'package:wing/features/hermes_chat/widgets/managed_ssh_connection_panel.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../test/core/hermes/ssh/secure_ssh_quick_connect_store_test.dart'
    show entry;
import '../test/features/hermes_chat/widgets/managed_ssh_connection_panel_test.dart'
    show FakeChannel, FakeForward;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Android encrypted remembered access reconnects with one tap', (
    tester,
  ) async {
    if (!Platform.isAndroid ||
        !const bool.fromEnvironment('WING_ANDROID_QUICK_CONNECT_QA')) {
      throw StateError('Use the isolated Android quick-connect QA target');
    }
    // Disposable .qa app only. Real Android secure storage; no live credentials.
    final store = SecureSshQuickConnectStore();
    await store.forget();
    await store.save(entry(), isCurrent: () => true);
    await const SecureManagedSshHostTrustStore().verify(
      ManagedSshConfig(
        host: 'example.invalid',
        username: 'tester',
        agentPort: 8642,
      ),
      entry().hostKey,
      review: () async => true,
      isCurrent: () => true,
    );
    final restoredStore = SecureSshQuickConnectStore();
    final loaded = await restoredStore.load();
    expect(loaded!.request.agentProfile, 'demo');
    for (final scale in [1.0, 2.0]) {
      await binding.setSurfaceSize(const Size(390, 1000));
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      final channel = FakeChannel();
      final forward = FakeForward();
      final controller = ManagedSshConnectionController(forward, channel);
      var connected = false;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            managedSshConnectionControllerProvider.overrideWithValue(
              controller,
            ),
            sshQuickConnectStoreProvider.overrideWithValue(restoredStore),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SingleChildScrollView(
                child: ManagedSshConnectionPanel(
                  onCancel: () {},
                  onConnected: () => connected = true,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(forward.config, isNull);
      final connect = find.byKey(const ValueKey('ssh-quick-connect'));
      expect(connect, findsOneWidget);
      await tester.ensureVisible(connect);
      await tester.tap(connect);
      await tester.pump();
      expect(await forward.verify!(forward.config!, entry().hostKey), isTrue);
      forward.ready();
      await tester.pumpAndSettle();
      expect(connected, isTrue);
      expect(channel.token, 'synthetic-token');
      expect(find.byType(TextFormField), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      await tester.pumpAndSettle();
    }
    await restoredStore.forget();
    expect(await SecureSshQuickConnectStore().load(), isNull);
    tester.platformDispatcher.clearTextScaleFactorTestValue();
    await binding.setSurfaceSize(null);
    binding.reportData = {
      'quick_connect':
          'real Android secure store, 390px, 100/200% text; deterministic SSH/channel; no live host authentication',
    };
  });
}
