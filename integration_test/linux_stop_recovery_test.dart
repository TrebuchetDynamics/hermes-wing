import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/features/hermes_chat/gateways/gateway_contact_cache.dart';
import 'package:wing/features/hermes_chat/gateways/hermes_gateway_directory.dart';
import 'package:wing/router/providers/app_router.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../test/features/hermes_chat/screens/hermes_chat_transcript_reconnect_test.dart'
    as reference;
import 'support/stop_recovery_native_fixture.dart';
import '../test/features/hermes_chat/support/fake_hermes_endpoint_store.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('GTK keyboard Stop retains uncertainty until canonical recovery', (
    tester,
  ) async {
    final root = Platform.environment['WING_STOP_ROOT'];
    if (root == null ||
        Platform.environment['HOME'] != '$root/home' ||
        Platform.environment['WING_LIVE_AUTH'] != null) {
      throw StateError('Use the owned Stop launcher');
    }
    SharedPreferences.setMockInitialValues({
      'wing.tips.dismissed.v1': ['moreDestinations', 'voice', 'approvals'],
    });
    addTearDown(() => binding.setSurfaceSize(null));
    final highlight = FocusManager.instance.highlightStrategy;
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(() => FocusManager.instance.highlightStrategy = highlight);
    for (final width in [390.0, 1280.0]) {
      for (final scale in [1.0, 2.0]) {
        final fixture = StopRecoveryNativeFixture();
        final channel = fixture.channel;
        final store = FakeHermesEndpointStore();
        final directory = HermesGatewayDirectory(
          store: store,
          cache: GatewayContactCache(),
          loader: HermesApiGatewaySummaryLoader(clientBuilder: fixture.client),
          activeChannel: channel,
        );
        final container = ProviderContainer(
          overrides: [
            hermesChannelProvider.overrideWithValue(channel),
            hermesEndpointStoreProvider.overrideWithValue(store),
            hermesGatewayDirectoryProvider.overrideWith((_) => directory),
            hermesVoiceCaptureServiceProvider.overrideWithValue(null),
            hermesTextToSpeechServiceProvider.overrideWithValue(null),
          ],
        );
        await channel.connect(baseUrl: 'http://127.0.0.1:8642');
        await binding.setSurfaceSize(Size(width, 1000));
        final router = container.read(routerProvider);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(
              routerConfig: router,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(scale),
                  disableAnimations: true,
                ),
                child: child!,
              ),
            ),
          ),
        );
        await reference.settle(tester);
        Future<void> reach(String label, {String? key}) async {
          await tester.runAsync(() => pumpEventQueue());
          await reference.settle(tester);
          if (find.text(label).evaluate().isEmpty &&
              find.text('Latest activity').evaluate().isNotEmpty) {
            await reference.reach(tester, 'Latest activity');
            await tester.sendKeyEvent(LogicalKeyboardKey.enter);
            await reference.settle(tester);
          }
          final target = key == null
              ? find.text(label)
              : find.byKey(ValueKey(key));
          await tester.ensureVisible(target);
          // ActionChip is used by production Stop; recognize its focus ancestor.
          for (var i = 0; i < 100; i++) {
            final context = FocusManager.instance.primaryFocus?.context;
            var keyedFocus =
                key != null && context?.widget.key == ValueKey(key);
            if (key != null) {
              context?.visitAncestorElements((element) {
                if (element.widget.key == ValueKey(key)) keyedFocus = true;
                return !keyedFocus;
              });
            }
            if (keyedFocus) return;
            final control =
                context?.findAncestorWidgetOfExactType<ListTile>() ??
                context?.findAncestorWidgetOfExactType<ActionChip>() ??
                context?.findAncestorWidgetOfExactType<FilledButton>() ??
                context?.findAncestorWidgetOfExactType<OutlinedButton>();
            if (control != null &&
                find
                    .descendant(
                      of: find.byWidget(control),
                      matching: target,
                      matchRoot: true,
                    )
                    .evaluate()
                    .isNotEmpty) {
              final rect = tester.getRect(target);
              expect(rect.left, greaterThanOrEqualTo(0));
              expect(rect.right, lessThanOrEqualTo(width));
              expect(rect.height, greaterThan(0));
              return;
            }
            await tester.sendKeyEvent(LogicalKeyboardKey.tab);
            await tester.pump();
          }
          fail('Keyboard could not reach $label');
        }

        Future<void> capture(String phase) async {
          await tester.runAsync(() async {
            await Future<void>.delayed(const Duration(milliseconds: 250));
            final result = await Process.run('/usr/bin/import', [
              '-window',
              'root',
              '$root/cache/stop-$width-$scale-$phase.png',
            ]);
            expect(result.exitCode, 0);
          });
        }

        Future<void> blocked() async {
          expect(channel.state.hasUnreconciledRun, isTrue);
          expect(
            find.byKey(const ValueKey('hermes-chat-error-retry')),
            findsNothing,
          );
          final before = fixture.mutations.length;
          await expectLater(
            channel.sendText('Synthetic forbidden duplicate'),
            throwsStateError,
          );
          expect(fixture.mutations.length, before);
          await reference.settle(tester);
        }

        Future<void> reconnect() async {
          await reach('Reconnect');
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await reference.settle(tester);
          await tester.runAsync(() => pumpEventQueue());
          await reference.settle(tester);
        }

        final phases = <String>[];
        // Acknowledgment alone, unknown status, wrong owner and failing reads
        // must all retain the exact run. Every recovery is a deliberate read.
        final first = channel.sendText('Synthetic Stop request');
        await tester.runAsync(fixture.prelude);
        await reference.settle(tester);
        await capture('unfocused');
        await reach('Stop');
        await capture('focus');
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await reference.settle(tester);
        await first;
        await blocked();
        phases.add('acknowledged-unresolved');
        fixture.outcome = 'unknown';
        await reconnect();
        await blocked();
        phases.add('unknown');
        fixture.wrongRun = true;
        await reconnect();
        await blocked();
        phases.add('wrong-run');
        fixture.wrongRun = false;
        fixture.failStatus = true;
        await reconnect();
        await blocked();
        phases.add('status-error');
        fixture.failStatus = false;
        fixture.terminal.add('run_1');
        fixture.failHistory = true;
        await reconnect();
        await blocked();
        phases.add('history-error');
        fixture.failHistory = false;
        // A failed history read during connect returns to the connection form;
        // its explicit Add Hermes action is the read-only recovery entry here.
        await reach('Add Hermes', key: 'gateway-contacts-add');
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await reference.settle(tester);
        await tester.enterText(
          find.byKey(const ValueKey('hermes-base-url-field')),
          'http://127.0.0.1:8642',
        );
        await reach('Add Hermes', key: 'hermes-connect-button');
        await capture('recovery');
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await reference.settle(tester);
        await tester.runAsync(() => pumpEventQueue());
        await reference.settle(tester);
        expect(channel.state.hasUnreconciledRun, isFalse);
        await tester.pageBack();
        await reference.settle(tester);
        await tester.runAsync(() => pumpEventQueue());
        await reference.settle(tester);
        final contact = directory.contacts.single;
        await reach(
          'Synthetic contact',
          key:
              'gateway-contact-${contact.id.gatewayId}-${contact.id.profileId}',
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await reference.settle(tester);
        await tester.runAsync(() => pumpEventQueue());
        await reference.settle(tester);
        expect(channel.state.activeMessages.single.id, 'canonical-stop');
        expect(fixture.mutations, ['/v1/runs', '/v1/runs/run_1/stop']);
        phases.add('canonical-recovered');
        await capture('recovered');
        // Only a fresh deliberate send is allowed after readback; Stop failure
        // does not authorize another send or automatic Stop retry.
        fixture.outcome = 'running';
        fixture.failStop = true;
        final second = channel.sendText('Synthetic deliberate resumed request');
        await tester.runAsync(fixture.prelude);
        await reference.settle(tester);
        await reach('Stop');
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await reference.settle(tester);
        await second;
        await blocked();
        phases.add('stop-error');
        await capture('failed');
        fixture.terminal.add('run_2');
        await reconnect();
        expect(channel.state.hasUnreconciledRun, isFalse);
        // Delayed old Stop success after canonical recovery and replacement
        // cannot settle or overwrite the replacement's streaming owner.
        fixture.failStop = false;
        final third = channel.sendText('Synthetic delayed Stop setup');
        await tester.runAsync(fixture.prelude);
        await reference.settle(tester);
        final retired = channel.activeTurnInterruptionTarget!;
        final gate = Completer<void>();
        fixture.stopGate = gate;
        await reach('Stop');
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await reference.settle(tester);
        await third;
        await blocked();
        fixture.terminal.add('run_3');
        await channel.connect(baseUrl: 'http://127.0.0.1:8642');
        final fourth = channel.sendText('Synthetic replacement setup');
        await tester.runAsync(fixture.prelude);
        await reference.settle(tester);
        final replacement = channel.activeTurnInterruptionTarget!;
        expect(replacement.runId, 'run_4');
        gate.complete();
        await reference.settle(tester);
        expect(
          channel.activeTurnInterruptionTarget?.matches(replacement),
          isTrue,
        );
        expect(await channel.stopTurn(retired), isFalse);
        expect(channel.state.activeMessages.last.text, 'Synthetic active work');
        phases.add('late-owner-fenced');
        expect(fixture.mutations, [
          '/v1/runs',
          '/v1/runs/run_1/stop',
          '/v1/runs',
          '/v1/runs/run_2/stop',
          '/v1/runs',
          '/v1/runs/run_3/stop',
          '/v1/runs',
        ]);
        expect(tester.takeException(), isNull);
        final receipt = File('$root/cache/stop-$width-$scale.pending');
        receipt.writeAsStringSync(
          jsonEncode({
            'native_pid': pid,
            'width': width,
            'text_scale': scale,
            'phases': phases,
            'mutations': fixture.mutations,
            'reads': fixture.reads,
            'canonical_ids': ['canonical-stop'],
            'recovery_mutations': 0,
            'creates': 0,
            'approvals': 0,
            'deliberate_resumed_sends': 1,
            'stops': 3,
            'late_owner_fenced': true,
          }),
        );
        receipt.renameSync('$root/cache/stop-$width-$scale.json');
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(seconds: 1)),
        );
        await tester.pumpWidget(const SizedBox.shrink());
        await channel.disconnect();
        await fourth;
        container.dispose();
        router.dispose();
        await fixture.dispose();
      }
    }
  });
}
