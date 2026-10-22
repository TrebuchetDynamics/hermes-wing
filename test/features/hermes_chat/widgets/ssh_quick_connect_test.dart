import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/ssh/secure_ssh_quick_connect_store.dart';
import 'package:wing/core/hermes/ssh/ssh_types.dart';
import 'package:wing/core/hermes/ssh/secure_managed_ssh_host_trust_store.dart';
import 'package:wing/features/hermes_chat/providers/managed_ssh_connection_controller.dart';
import 'package:wing/features/hermes_chat/widgets/managed_ssh_connection_panel.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../../../core/hermes/ssh/secure_ssh_quick_connect_store_test.dart'
    show entry;
import 'managed_ssh_connection_panel_test.dart' show FakeChannel, FakeForward;

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  for (final changedKey in [false, true]) {
    testWidgets(
      'cold open only connects on tap and verifies saved host: changed=$changedKey',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        final store = SecureSshQuickConnectStore();
        await store.save(entry(), isCurrent: () => true);
        await const SecureManagedSshHostTrustStore().verify(
          ManagedSshConfig(
            host: 'example.invalid',
            username: 'tester',
            agentPort: 8642,
            agentProfile: 'demo',
          ),
          entry().hostKey,
          review: () async => true,
          isCurrent: () => true,
        );
        final channel = FakeChannel();
        final forward = FakeForward();
        final controller = ManagedSshConnectionController(forward, channel);
        var successes = 0;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              managedSshConnectionControllerProvider.overrideWithValue(
                controller,
              ),
              sshQuickConnectStoreProvider.overrideWithValue(store),
            ],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: SingleChildScrollView(
                  child: ManagedSshConnectionPanel(
                    onCancel: () {},
                    onConnected: () => successes++,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(forward.config, isNull);
        expect(find.byType(TextFormField), findsNothing);
        expect(find.textContaining('synthetic-token'), findsNothing);
        await tester.tap(find.byKey(const ValueKey('ssh-quick-connect')));
        await tester.pump();
        final key = ManagedSshHostKey(
          'ssh-ed25519',
          List.filled(32, changedKey ? 4 : 3),
        );
        // Real adapter validates the reviewed key before it asks for SSH credentials.
        final accepted = await forward.verify!(forward.config!, key);
        if (changedKey) {
          expect(accepted, isFalse);
          forward.waiting.completeError(
            const ManagedSshException(ManagedSshFailure.hostKeyRejected),
          );
        } else {
          // Trust still requires the existing reviewed pin; a saved quick record is
          // not permission to accept a different host. The dialog is exercised below.
          expect(accepted, isTrue);
          forward.ready();
        }
        await tester.pumpAndSettle();
        expect(successes, changedKey ? 0 : 1);
        if (!changedKey) expect(channel.token, 'synthetic-token');
        if (changedKey) {
          expect(find.byKey(const ValueKey('ssh-quick-error')), findsOneWidget);
        }
        await tester.pumpWidget(const SizedBox());
        controller.dispose();
        debugDefaultTargetPlatformOverride = null;
      },
    );
  }

  for (final remember in [false, true]) {
    testWidgets(
      'first verified connection remembers only with explicit consent: $remember',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        final channel = FakeChannel();
        final forward = FakeForward();
        final controller = ManagedSshConnectionController(forward, channel);
        final store = SecureSshQuickConnectStore();
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
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              managedSshConnectionControllerProvider.overrideWithValue(
                controller,
              ),
              sshQuickConnectStoreProvider.overrideWithValue(store),
            ],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: SingleChildScrollView(
                  child: ManagedSshConnectionPanel(onCancel: () {}),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        if (remember) {
          await tester.tap(find.byKey(const ValueKey('ssh-quick-remember')));
          await tester.pumpAndSettle();
        }
        for (final field in {
          'host': 'example.invalid',
          'username': 'tester',
          'password': 'synthetic-password',
          'agent-profile': 'demo',
          'agent-token': 'synthetic-token',
        }.entries) {
          final finder = find.byKey(ValueKey('managed-ssh-${field.key}'));
          await tester.ensureVisible(finder);
          await tester.enterText(finder, field.value);
        }
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pump();
        expect(await forward.verify!(forward.config!, entry().hostKey), isTrue);
        forward.ready();
        await tester.pumpAndSettle();
        expect(channel.state.isConnected, isTrue);
        expect(
          (await store.load())?.request.agentProfile,
          remember ? 'demo' : null,
        );
        expect(find.textContaining('synthetic-token'), findsNothing);
        await tester.pumpWidget(const SizedBox());
        controller.dispose();
        debugDefaultTargetPlatformOverride = null;
      },
    );
  }

  testWidgets('forget exposes empty fields and deletes only quick slot', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final store = SecureSshQuickConnectStore();
    await store.save(entry(), isCurrent: () => true);
    final controller = ManagedSshConnectionController(
      FakeForward(),
      FakeChannel(),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          managedSshConnectionControllerProvider.overrideWithValue(controller),
          sshQuickConnectStoreProvider.overrideWithValue(store),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: ManagedSshConnectionPanel(onCancel: () {}),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('ssh-quick-forget')));
    await tester.pumpAndSettle();
    expect(await store.load(), isNull);
    expect(find.byKey(const ValueKey('ssh-quick-connect')), findsNothing);
    expect(
      tester
          .widget<TextFormField>(
            find.byKey(const ValueKey('managed-ssh-agent-token')),
          )
          .controller!
          .text,
      isEmpty,
    );
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
    debugDefaultTargetPlatformOverride = null;
  });
}
