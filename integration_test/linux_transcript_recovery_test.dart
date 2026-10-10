import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../test/features/hermes_chat/screens/hermes_chat_transcript_reconnect_test.dart'
    as reference;
import 'support/transcript_recovery_native_fixture.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('GTK keyboard canonical recovery and exact approval owner', (
    tester,
  ) async {
    final root = Platform.environment['WING_TRANSCRIPT_ROOT'];
    if (root == null ||
        Platform.environment['HOME'] != '$root/home' ||
        Platform.environment['WING_LIVE_AUTH'] != null) {
      throw StateError('Use the owned transcript launcher');
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
        final fixture = TranscriptRecoveryNativeFixture();
        final approvals = <HermesApprovalRequest>[];
        final subscription = fixture.channel.approvalRequests.listen(
          approvals.add,
        );
        final container = ProviderContainer(
          overrides: [
            hermesChannelProvider.overrideWithValue(fixture.channel),
            hermesVoiceCaptureServiceProvider.overrideWithValue(null),
            hermesTextToSpeechServiceProvider.overrideWithValue(null),
          ],
        );
        await fixture.channel.connect(baseUrl: 'http://127.0.0.1:8642');
        Future<void> mount(double size) async {
          await binding.setSurfaceSize(Size(size, 1000));
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(scale),
                    disableAnimations: true,
                  ),
                  child: child!,
                ),
                home: const HermesChatScreen(),
              ),
            ),
          );
          await reference.settle(tester);
        }

        Future<void> reach(String label) async {
          if (find.text(label).evaluate().isEmpty &&
              find.text('Latest activity').evaluate().isNotEmpty) {
            await reference.reach(tester, 'Latest activity');
            await tester.sendKeyEvent(LogicalKeyboardKey.enter);
            await reference.settle(tester);
          }
          await tester.ensureVisible(find.text(label));
          await reference.reach(tester, label);
          await reference.settle(tester);
          final rect = tester.getRect(find.text(label));
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(
            rect.right,
            lessThanOrEqualTo(
              MediaQuery.sizeOf(tester.element(find.text(label))).width,
            ),
          );
          expect(rect.height, greaterThan(0));
        }

        Future<void> capture(String phase) async {
          await tester.runAsync(() async {
            await Future<void>.delayed(const Duration(milliseconds: 250));
            final result = await Process.run('/usr/bin/import', [
              '-window',
              'root',
              '$root/cache/transcript-$width-$scale-$phase.png',
            ]);
            expect(result.exitCode, 0);
          });
        }

        await mount(width);
        final first = fixture.channel.sendText(reference.prompt);
        await tester.runAsync(fixture.prelude);
        await reference.settle(tester);
        await reach('Approve once');
        final retired = approvals.last;
        final oldFocus = FocusManager.instance.primaryFocus;
        fixture.canonical = true;
        await fixture.channel.connect(baseUrl: 'http://127.0.0.1:8642');
        await first;
        await reference.settle(tester);
        expect(find.text('Approve once'), findsNothing);
        expect(FocusManager.instance.primaryFocus, isNot(same(oldFocus)));
        expect(
          fixture.channel.state.activeMessages.map((t) => t.id),
          fixture.history.history.map((r) => r['id']),
        );
        await expectLater(
          fixture.channel.respondToApproval(
            approvalId: retired.id,
            runId: retired.runId,
            origin: retired,
            decision: HermesApprovalDecision.once,
          ),
          throwsStateError,
        );
        await tester.pumpWidget(const SizedBox.shrink());
        await mount(width == 390 ? 1280 : 390);
        await mount(width);
        FocusManager.instance.primaryFocus?.unfocus();
        await reference.settle(tester);
        await capture('unfocused');
        await reach('Hermes host activity · 2 steps');
        await capture('focus');
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await reference.settle(tester);
        expect(find.text('File activity'), findsOneWidget);
        expect(find.text('Web activity'), findsOneWidget);
        expect(find.text('Completed on Hermes host'), findsNWidgets(3));
        expect(find.text(reference.hidden), findsNothing);
        await capture('recovered');
        await fixture.channel.reconcileActiveSession();
        expect(fixture.mutations, ['/v1/runs']);
        fixture.canonical = false;
        await fixture.channel.connect(baseUrl: 'http://127.0.0.1:8642');
        final second = fixture.channel.sendText('Synthetic current request');
        await tester.runAsync(fixture.prelude);
        await reference.settle(tester);
        await capture('approval-unfocused');
        await reach('Approve once');
        await capture('approval');
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await reference.settle(tester);
        expect(fixture.decisions, [
          {
            'path': '/v1/runs/run_2/approval',
            'request_id': 'request_2',
            'choice': 'once',
          },
        ]);
        await tester.runAsync(fixture.complete);
        await second;
        await reference.settle(tester);
        // Explicit failing decision retains exact owner; there is no auto retry.
        final third = fixture.channel.sendText('Synthetic retry request');
        await tester.runAsync(fixture.prelude);
        await reference.settle(tester);
        fixture.failNext = true;
        await reach('Approve once');
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await reference.settle(tester);
        expect(fixture.decisions.length, 2);
        expect(find.text('Approve once'), findsOneWidget);
        await mount(width == 390 ? 1280 : 390);
        await mount(width);
        expect(fixture.decisions.length, 2);
        await reach('Approve once');
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await reference.settle(tester);
        expect(fixture.decisions.length, 3);
        expect(
          fixture.decisions.skip(1),
          everyElement({
            'path': '/v1/runs/run_3/approval',
            'request_id': 'request_3',
            'choice': 'once',
          }),
        );
        await tester.runAsync(fixture.complete);
        await third;
        await reference.settle(tester);
        // An in-flight response's late failure cannot settle the replacement.
        final fourth = fixture.channel.sendText('Synthetic delayed request');
        await tester.runAsync(fixture.prelude);
        await reference.settle(tester);
        final delayedOwner = approvals.last;
        final gate = Completer<void>();
        fixture.gate = gate;
        fixture.failNext = true;
        await reach('Approve once');
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await reference.settle(tester);
        expect(fixture.decisions.length, 4);
        await fixture.channel.disconnect();
        await fixture.channel.connect(baseUrl: 'http://127.0.0.1:8642');
        await fourth;
        final fifth = fixture.channel.sendText('Synthetic replacement request');
        await tester.runAsync(fixture.prelude);
        await reference.settle(tester);
        expect(
          approvals.last.connectionGeneration,
          isNot(delayedOwner.connectionGeneration),
        );
        gate.complete();
        await reference.settle(tester);
        expect(fixture.decisions.length, 4);
        await expectLater(
          fixture.channel.respondToApproval(
            approvalId: delayedOwner.id,
            runId: delayedOwner.runId,
            origin: delayedOwner,
            decision: HermesApprovalDecision.once,
          ),
          throwsStateError,
        );
        await reach('Approve once');
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await reference.settle(tester);
        expect(fixture.decisions.last, {
          'path': '/v1/runs/run_5/approval',
          'request_id': 'request_5',
          'choice': 'once',
        });
        await tester.runAsync(fixture.complete);
        await fifth;
        expect(fixture.mutations.where((p) => p == '/v1/runs').length, 5);
        expect(fixture.mutations.where((p) => p.endsWith('/stop')), isEmpty);
        expect(fixture.mutations.length, 10);
        expect(tester.takeException(), isNull);
        final receipt = File('$root/cache/transcript-$width-$scale.pending');
        receipt.writeAsStringSync(
          jsonEncode({
            'native_pid': pid,
            'width': width,
            'text_scale': scale,
            'canonical_ids': fixture.history.history
                .map((r) => r['id'])
                .toList(),
            'reads': fixture.reads,
            'mutations': fixture.mutations,
            'decisions': fixture.decisions,
            'recovery_mutations': 0,
            'creates': 0,
            'stops': 0,
            'retired_rejected': true,
            'late_failure_fenced': true,
            'explicit_retry_only': true,
          }),
        );
        receipt.renameSync('$root/cache/transcript-$width-$scale.json');
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(seconds: 1)),
        );
        await tester.pumpWidget(const SizedBox.shrink());
        container.dispose();
        await subscription.cancel();
        await fixture.dispose();
      }
    }
  });
}
