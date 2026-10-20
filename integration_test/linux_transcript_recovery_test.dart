import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/models/hermes_chat_turn.dart';
import 'package:wing/features/hermes_chat/gateways/gateway_contact.dart';
import 'package:wing/features/hermes_chat/gateways/gateway_contact_cache.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../test/features/hermes_chat/screens/hermes_chat_transcript_reconnect_test.dart'
    as reference;
import 'support/transcript_recovery_native_fixture.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  unawaited(
    binding.allTestsPassed.future.then((passed) async {
      final root = Platform.environment['WING_TRANSCRIPT_ROOT'];
      final phase = Platform.environment['WING_TRANSCRIPT_PHASE'];
      if (root != null && {'write', 'verify'}.contains(phase)) {
        final terminal = File('$root/cache/transcript-$phase-terminal.pending');
        terminal.writeAsStringSync(
          jsonEncode({
            'phase': phase,
            'native_pid': pid,
            'passed': passed,
            'tests': binding.results.length,
          }),
        );
        terminal.renameSync('$root/cache/transcript-$phase-terminal.json');
        await Future<void>.delayed(const Duration(seconds: 1));
        exit(passed ? 0 : 1);
      }
    }),
  );
  testWidgets('GTK two-process canonical history and retired approval recovery', (
    tester,
  ) async {
    final root = Platform.environment['WING_TRANSCRIPT_ROOT'];
    final phase = Platform.environment['WING_TRANSCRIPT_PHASE'];
    if (root == null ||
        !{'write', 'verify'}.contains(phase) ||
        Platform.environment['HOME'] != '$root/home' ||
        Platform.environment['DBUS_SESSION_BUS_ADDRESS'] != null ||
        Platform.environment['WING_LIVE_AUTH'] != null) {
      throw StateError('Use the owned transcript restart launcher');
    }
    // Real Linux preferences survive process exit; no mock initialization.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('wing.tips.dismissed.v1', [
      'moreDestinations',
      'voice',
      'approvals',
    ]);
    final cache = GatewayContactCache();
    const owner = GatewayContactId(
      gatewayId: 'synthetic-transcript',
      profileId: 'default',
    );
    final remembered = await cache.loadSelection();
    expect(remembered?.sessionId, phase == 'write' ? null : reference.session);
    if (phase == 'verify') expect(remembered?.contactId, owner);
    addTearDown(() => binding.setSurfaceSize(null));
    final highlight = FocusManager.instance.highlightStrategy;
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(() => FocusManager.instance.highlightStrategy = highlight);

    for (final width in [390.0, 1280.0]) {
      for (final scale in [1.0, 2.0]) {
        debugPrint('TRANSCRIPT_PHASE $phase width=$width scale=$scale');
        final prefix = '$root/cache/transcript-$width-$scale';
        final fixture = TranscriptRecoveryNativeFixture(
          leaseFile: File('$prefix-leases.json'),
        );
        if (phase == 'write') fixture.canonical = false;
        final channel = fixture.channel;
        final container = ProviderContainer(
          overrides: [
            hermesChannelProvider.overrideWithValue(channel),
            hermesVoiceCaptureServiceProvider.overrideWithValue(null),
            hermesTextToSpeechServiceProvider.overrideWithValue(null),
          ],
        );
        await channel.connect(baseUrl: 'http://127.0.0.1:8642');
        expect(channel.state.activeSessionId, reference.session);
        expect(channel.state.selectedProfileId ?? 'default', owner.profileId);
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

        Future<void> reach(Finder target) async {
          expect(target, findsOneWidget);
          await tester.ensureVisible(target);
          for (var i = 0; i < 100; i++) {
            final context = FocusManager.instance.primaryFocus?.context;
            final control =
                context?.findAncestorWidgetOfExactType<ListTile>() ??
                context?.findAncestorWidgetOfExactType<TextButton>() ??
                context?.findAncestorWidgetOfExactType<FilledButton>() ??
                context?.findAncestorWidgetOfExactType<OutlinedButton>();
            if (control != null &&
                find
                    .descendant(of: find.byWidget(control), matching: target)
                    .evaluate()
                    .isNotEmpty) {
              final rect = tester.getRect(target);
              expect(rect.left, greaterThanOrEqualTo(0));
              expect(
                rect.right,
                lessThanOrEqualTo(
                  MediaQuery.sizeOf(tester.element(target)).width,
                ),
              );
              return;
            }
            await tester.sendKeyEvent(LogicalKeyboardKey.tab);
            await tester.pump();
          }
          fail('Keyboard cannot reach $target');
        }

        Future<void> expand(String id) async {
          if (find
                  .byKey(ValueKey('hermes-tool-activity-$id'))
                  .evaluate()
                  .isEmpty &&
              find.text('Latest activity').evaluate().isNotEmpty) {
            await reach(find.text('Latest activity'));
            await tester.sendKeyEvent(LogicalKeyboardKey.enter);
            await reference.settle(tester);
          }
          final title = find.descendant(
            of: find.byKey(ValueKey('hermes-tool-activity-$id')),
            matching: find.text('Hermes host activity · 2 steps'),
          );
          if (title.evaluate().isEmpty) {
            // Like ensureVisible, prepare the reversed lazy viewport before
            // exercising actual Tab/Enter on the disclosure (no pointer taps).
            final scrollable = find.descendant(
              of: find.byKey(const ValueKey('hermes-transcript')),
              matching: find.byType(Scrollable),
            );
            tester.state<ScrollableState>(scrollable).position.jumpTo(0);
            await reference.settle(tester);
          }
          await reach(title);
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await reference.settle(tester);
        }

        await mount(width);
        if (phase == 'write') {
          // One deliberate setup mutation per viewport; it is never replayed.
          unawaited(channel.sendText('Synthetic pending restart request'));
          await tester.runAsync(() async {
            await pumpEventQueue();
            fixture.canonical = true;
            await channel.connect(baseUrl: 'http://127.0.0.1:8642');
            await pumpEventQueue();
          });
        } else {
          expect(fixture.mutations, isEmpty);
          expect(channel.state.hasUnreconciledRun, true);
        }
        await tester.runAsync(
          () => fixture.activeTools(approval: phase == 'write'),
        );
        await reference.settle(tester);
        expect(channel.state.activeMessages.take(5).map((t) => t.id), [
          'canonical-user',
          'canonical-commentary',
          'canonical-read',
          'canonical-web',
          'canonical-answer',
        ]);
        final tools = channel.state.activeMessages
            .where((t) => t.kind == HermesTurnKind.toolCall)
            .toList();
        expect(tools.map((t) => (t.toolCall!.name, t.toolCall!.status)), [
          ('read_file', 'completed'),
          ('web_search', 'completed'),
          ('terminal', 'failed'),
          ('browser', 'running'),
        ]);
        if (phase == 'write') {
          await reach(find.text('Approve once'));
          await cache.saveSelection(
            const GatewayContactSelection(
              contactId: owner,
              sessionId: reference.session,
            ),
          );
        } else {
          for (final label in ['Approve once', 'Deny', 'Review']) {
            expect(find.text(label), findsNothing);
          }
          // Canonical history order survives route remount and compact/wide return.
          await tester.pumpWidget(const SizedBox.shrink());
          await mount(width == 390 ? 1280 : 390);
          await mount(width);
          await expand('canonical-read');
          expect(
            tester.getTopLeft(find.text('File activity')).dy,
            lessThan(tester.getTopLeft(find.text('Web activity')).dy),
          );
          await expand('tool-run_1:error-terminal');
          expect(
            tester.getTopLeft(find.text('Code activity')).dy,
            lessThan(tester.getTopLeft(find.text('Browser activity')).dy),
          );
          expect(find.text('Host action needs attention'), findsWidgets);
          expect(find.text('Working on Hermes host'), findsOneWidget);
          expect(find.text(reference.hidden), findsNothing);
          // Expired observation is not a successful terminal run; retain its lease.
          await tester.runAsync(fixture.streams.last.close);
          final expiryDeadline = DateTime.now().add(
            const Duration(seconds: 40),
          );
          while (channel.state.activeMessages.last.status !=
                  HermesTurnStatus.failed &&
              DateTime.now().isBefore(expiryDeadline)) {
            await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 200)),
            );
            await tester.pump();
          }
          await reference.settle(tester);
          expect(channel.state.errorMessage, contains('timed out'));
          expect(
            channel.state.activeMessages.last.status,
            HermesTurnStatus.failed,
          );
          expect(channel.state.activeMessages.last.toolCall, isNull);
          expect(channel.state.hasUnreconciledRun, true);
          expect(
            channel.state.activeMessages
                .where((t) => t.toolCall?.name == 'browser')
                .single
                .toolCall!
                .status,
            'running',
          );
          expect(fixture.mutations, isEmpty);
        }
        expect(fixture.decisions, isEmpty);
        expect(fixture.mutations, phase == 'write' ? ['/v1/runs'] : <String>[]);
        expect(tester.takeException(), isNull);
        final selected = await cache.loadSelection();
        final snapshot = {
          'phase': phase,
          'native_pid': pid,
          'width': width,
          'text_scale': scale,
          'owner': {
            'gateway': selected!.contactId.gatewayId,
            'profile':
                channel.state.selectedProfileId ?? selected.contactId.profileId,
            'session': channel.state.activeSessionId,
            'origin': Uri.parse(channel.state.connectedBaseUrl!).origin,
          },
          'canonical_ids': channel.state.activeMessages
              .take(5)
              .map((t) => t.id)
              .toList(),
          'tools': tools
              .map(
                (t) => {'name': t.toolCall!.name, 'status': t.toolCall!.status},
              )
              .toList(),
          'approval_visible': find.text('Approve once').evaluate().isNotEmpty,
          'unresolved': channel.state.hasUnreconciledRun,
          'last_status': channel.state.activeMessages.last.status.name,
        };
        await tester.pumpWidget(const SizedBox.shrink());
        container.dispose();
        await fixture.dispose();
        expect(fixture.decisions, isEmpty);
        expect(fixture.mutations, phase == 'write' ? ['/v1/runs'] : <String>[]);
        final leases =
            jsonDecode(File('$prefix-leases.json').readAsStringSync()) as List;
        expect(leases, hasLength(1));
        final receipt = File('$prefix-$phase.pending');
        receipt.writeAsStringSync(
          jsonEncode({
            ...snapshot,
            'lease': leases.single,
            'requests': fixture.requests,
            'mutations': fixture.mutations,
            'decisions': fixture.decisions,
          }),
        );
        receipt.renameSync('$prefix-$phase.json');
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(seconds: 1)),
        );
      }
    }
  });
}
