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
import 'package:wing/l10n/app_localizations.dart';

import '../test/features/hermes_chat/support/fake_hermes_endpoint_store.dart';

import '../test/features/hermes_chat/screens/hermes_chat_transcript_reconnect_test.dart'
    as reference;
import 'support/transcript_recovery_native_fixture.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'GTK retired Review closes; Space disclosure and current Deny return',
    (tester) async {
      final root = Platform.environment['WING_TRANSCRIPT_ROOT'];
      if (!Platform.isLinux ||
          root == null ||
          Platform.environment['HOME'] != '$root/home' ||
          Platform.environment['XDG_DATA_HOME'] != '$root/data' ||
          Platform.environment.containsKey('DBUS_SESSION_BUS_ADDRESS') ||
          Platform.environment.containsKey('WING_LIVE_AUTH')) {
        throw StateError(
          'Use integration_test/run_linux_transcript_keyboard.py',
        );
      }
      SharedPreferences.setMockInitialValues({
        'wing.tips.dismissed.v1': ['moreDestinations', 'voice', 'approvals'],
      });
      addTearDown(() => binding.setSurfaceSize(null));
      final highlight = FocusManager.instance.highlightStrategy;
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(() => FocusManager.instance.highlightStrategy = highlight);
      final fixture = TranscriptRecoveryNativeFixture();
      addTearDown(fixture.dispose);
      final container = ProviderContainer(
        overrides: [
          hermesChannelProvider.overrideWithValue(fixture.channel),
          hermesEndpointStoreProvider.overrideWithValue(
            FakeHermesEndpointStore(),
          ),
          hermesVoiceCaptureServiceProvider.overrideWithValue(null),
          hermesTextToSpeechServiceProvider.overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);
      final observations = <Map<String, Object?>>[];
      final captures = <String>[];
      Future<void> resize(double width) async {
        await binding.setSurfaceSize(Size(width, 720));
        await reference.settle(tester);
        observations.add({
          'width': MediaQuery.sizeOf(
            tester.element(find.byType(HermesChatScreen)),
          ).width,
          'mutations': fixture.mutations.length,
          'decisions': fixture.decisions.length,
        });
      }

      Future<void> mount(double width) async {
        await binding.setSurfaceSize(Size(width, 720));
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => LayoutBuilder(
                builder: (context, constraints) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    size: constraints.biggest,
                    textScaler: TextScaler.linear(2),
                    disableAnimations: true,
                  ),
                  child: child!,
                ),
              ),
              home: const HermesChatScreen(),
            ),
          ),
        );
        await reference.settle(tester);
      }

      Future<void> focusKey(String key) async {
        final target = find.byKey(ValueKey(key));
        if (target.evaluate().isEmpty &&
            find.text('Latest activity').evaluate().isNotEmpty) {
          await reference.reach(tester, 'Latest activity');
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await reference.settle(tester);
        }
        expect(target, findsOneWidget);
        await tester.ensureVisible(target);
        final element = target.evaluate().single;
        for (var i = 0; i < 100; i++) {
          var focused = false;
          FocusManager.instance.primaryFocus?.context?.visitAncestorElements((
            e,
          ) {
            if (e == element) focused = true;
            return !focused;
          });
          if (focused) {
            await reference.settle(tester);
            final rect = tester.getRect(target);
            final size = tester.getSize(find.byType(MaterialApp));
            expect(rect.left, greaterThanOrEqualTo(0));
            expect(rect.right, lessThanOrEqualTo(size.width));
            expect(rect.top, greaterThanOrEqualTo(0));
            expect(rect.bottom, lessThanOrEqualTo(size.height));
            return;
          }
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump();
        }
        fail('Keyboard could not reach $key');
      }

      Future<void> capture(String phase) async {
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 250));
          final result = await Process.run('/usr/bin/import', [
            '-window',
            'root',
            '$root/cache/$phase.png',
          ]);
          expect(result.exitCode, 0);
        });
        captures.add(phase);
      }

      await fixture.channel.connect(baseUrl: 'http://127.0.0.1:8642');
      await mount(390);
      final first = fixture.channel.sendText(reference.prompt);
      await tester.runAsync(fixture.prelude);
      await reference.settle(tester);
      await focusKey('hermes-approval-review');
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await reference.settle(tester);
      expect(find.text('Review Hermes approval'), findsOneWidget);
      await focusKey('hermes-approval-sheet-once');
      final retiredFocus = FocusManager.instance.primaryFocus;
      final recoveryStart = fixture.mutations.length;
      fixture.canonical = true;
      await fixture.channel.connect(baseUrl: 'http://127.0.0.1:8642');
      await first;
      await reference.settle(tester);
      expect(find.text('Review Hermes approval'), findsNothing);
      for (final key in [
        'hermes-approval-banner',
        'hermes-approval-sheet-once',
        'hermes-approval-sheet-deny',
      ]) {
        expect(find.byKey(ValueKey(key)), findsNothing);
      }
      expect(FocusManager.instance.primaryFocus, isNot(same(retiredFocus)));
      expect(fixture.channel.state.activeMessages.map((t) => t.id), [
        'canonical-user',
        'canonical-commentary',
        'canonical-read',
        'canonical-web',
        'canonical-answer',
      ]);
      await tester.pumpWidget(const SizedBox.shrink());
      await mount(1280);
      await resize(390);
      await resize(1280);
      FocusManager.instance.primaryFocus?.unfocus();
      await reference.settle(tester);
      await capture('tool-unfocused');
      await reference.reach(tester, 'Hermes host activity · 2 steps');
      await reference.settle(tester);
      await capture('tool-focused');
      final disclosureFocus = FocusManager.instance.primaryFocus;
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      expect(FocusManager.instance.primaryFocus, isNot(same(disclosureFocus)));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      expect(FocusManager.instance.primaryFocus, same(disclosureFocus));
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await reference.settle(tester);
      expect(find.text('File activity'), findsOneWidget);
      expect(find.text('Web activity'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('File activity')).dy,
        lessThan(tester.getTopLeft(find.text('Web activity')).dy),
      );
      expect(find.text(reference.hidden), findsNothing);
      await capture('tool-expanded');
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await reference.settle(tester);
      expect(find.text('File activity'), findsNothing);
      await fixture.channel.reconcileActiveSession();
      final recoveryMutations = fixture.mutations.length - recoveryStart;
      expect(recoveryMutations, 0);

      fixture.canonical = false;
      await fixture.channel.connect(baseUrl: 'http://127.0.0.1:8642');
      final current = fixture.channel.sendText(
        'Synthetic current keyboard request',
      );
      await tester.runAsync(fixture.prelude);
      await reference.settle(tester);
      await resize(390);
      await resize(1280);
      await capture('review-unfocused');
      await focusKey('hermes-approval-review');
      await capture('review-focused');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await reference.settle(tester);
      expect(find.text('Review Hermes approval'), findsOneWidget);
      await focusKey('hermes-approval-sheet-close');
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await reference.settle(tester);
      expect(find.text('Review Hermes approval'), findsNothing);
      expect(fixture.decisions, isEmpty);
      await resize(390);
      await focusKey('hermes-approval-review');
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await reference.settle(tester);
      await focusKey('hermes-approval-sheet-deny');
      await capture('deny-focused');
      expect(find.text(reference.hidden), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await reference.settle(tester);
      expect(fixture.decisions, [
        {
          'path': '/v1/runs/run_2/approval',
          'request_id': 'request_2',
          'choice': 'deny',
        },
      ]);
      expect(
        find.byKey(const ValueKey('hermes-approval-banner')),
        findsNothing,
      );
      await tester.runAsync(fixture.complete);
      await current;
      await reference.settle(tester);
      expect(fixture.mutations, [
        '/v1/runs',
        '/v1/runs',
        '/v1/runs/run_2/approval',
      ]);
      expect(tester.takeException(), isNull);
      final receipt = File('$root/cache/keyboard.pending');
      receipt.writeAsStringSync(
        jsonEncode({
          'native_pid': pid,
          'text_scale': 2.0,
          'retired_review_removed': true,
          'inverse_disclosure_traversal': true,
          'recovery_mutations': recoveryMutations,
          'observations': observations,
          'requests': fixture.requests,
          'mutations': fixture.mutations,
          'decisions': fixture.decisions,
          'captures': captures,
        }),
      );
      receipt.renameSync('$root/cache/keyboard.json');
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 2)),
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
