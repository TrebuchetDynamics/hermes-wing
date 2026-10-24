import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'hermes_features_maestro_main.dart' as fixture;

// Native counterparts of the UI flows under scripts/maestro/fixture/.
// Production screens, deterministic services; no live account or provider.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.shouldPropagateDevicePointerEvents = true;
  WidgetController.hitTestWarningShouldBeFatal = true;

  setUpAll(() => debugPrint('NATIVE_PARITY_PID=$pid'));

  Future<void> launch(WidgetTester tester, double width) async {
    SharedPreferences.setMockInitialValues({});
    binding.testTextInput.register();
    addTearDown(binding.testTextInput.unregister);
    tester.view.physicalSize = Size(width, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final previousErrorHandler = FlutterError.onError;
    addTearDown(() => FlutterError.onError = previousErrorHandler);
    await fixture.main();
    await tester.pumpAndSettle();
  }

  Future<void> tapText(
    WidgetTester tester,
    String text, {
    bool waitForIdle = true,
  }) async {
    debugPrint('Linux UI action: $text');
    final target = find.text(text).last;
    await tester.ensureVisible(target);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(target);
    if (!waitForIdle) {
      // Deferred picker progress intentionally animates until explicitly resolved.
      await tester.pump(const Duration(milliseconds: 350));
      return;
    }
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 5),
    );
  }

  Future<void> control(
    WidgetTester tester,
    String action, {
    bool waitForIdle = true,
  }) async {
    await tapText(tester, 'Fixture controls', waitForIdle: waitForIdle);
    await tapText(tester, action, waitForIdle: waitForIdle);
  }

  for (final width in [420.0, 1440.0]) {
    testWidgets(
      'Maestro session pagination search pin and delete width=$width',
      (tester) async {
        await launch(tester, width);
        await tester.scrollUntilVisible(
          find.text('Chat fixture'),
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await tapText(tester, 'Chat fixture');
        await control(tester, 'Enable session pagination');
        Future<void> openSessions() async {
          if (width < 800) {
            await tester.tap(find.byTooltip('More actions'));
            await tester.pumpAndSettle();
            await tapText(tester, 'Sessions');
          } else {
            await tester.tap(
              find.byKey(const ValueKey('hermes-sessions-button')),
            );
            await tester.pumpAndSettle();
          }
        }

        await openSessions();
        await tapText(tester, 'Load more sessions');
        expect(find.text('Load more sessions'), findsNothing);
        expect(find.text('Fixture third'), findsWidgets);
        final search = find.byKey(
          const ValueKey('hermes-session-search-field'),
        );
        await tester.enterText(search, 'Fixture second');
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('hermes-session-row-sess_1')).hitTestable(),
          findsNothing,
        );
        await tester.tap(
          find.byKey(const ValueKey('hermes-session-menu-sess_2')).last,
        );
        await tester.pumpAndSettle();
        await tapText(tester, 'Pin');
        expect(find.text('Pinned'), findsWidgets);
        await tester.tap(
          find.byKey(const ValueKey('hermes-session-menu-sess_2')).last,
        );
        await tester.pumpAndSettle();
        await tapText(tester, 'Unpin');
        await tester.enterText(search, '');
        await tester.pumpAndSettle();
        await tapText(tester, 'Select');
        await tapText(tester, 'Select all');
        await tapText(tester, 'Delete 3');
        await tapText(tester, 'Cancel');
        await tapText(tester, 'Fixture controls');
        expect(find.text('Deleted sessions: 0'), findsOneWidget);
        await tapText(tester, 'Close controls');
        await openSessions();
        expect(find.text('Fixture first'), findsWidgets);
        await tapText(tester, 'Select');
        await tapText(tester, 'Select all');
        await tapText(tester, 'Delete 3');
        await tapText(tester, 'Delete');
        await tapText(tester, 'Fixture controls');
        expect(find.text('Deleted sessions: 3'), findsOneWidget);
        await tapText(tester, 'Close controls');
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );

    testWidgets(
      'Maestro exact text and Markdown clipboard exports width=$width',
      (tester) async {
        await launch(tester, width);
        await tester.scrollUntilVisible(
          find.text('Chat fixture'),
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await tapText(tester, 'Chat fixture');
        await tester.enterText(
          find.byKey(const ValueKey('hermes-composer-field')),
          'Fixture export',
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('hermes-send-button')));
        for (var tick = 0; tick < 100; tick++) {
          await tester.pump(const Duration(milliseconds: 50));
          if (find.text('Approve once').hitTestable().evaluate().isNotEmpty) {
            break;
          }
        }
        await tapText(tester, 'Approve once');
        for (final format in {'text': 'Text', 'Markdown': 'Markdown'}.entries) {
          if (width < 800) {
            await tester.tap(find.byTooltip('More actions'));
            await tester.pumpAndSettle();
            await tapText(tester, 'Copy transcript');
          } else {
            await tester.tap(
              find.byKey(const ValueKey('hermes-copy-transcript-button')),
            );
            await tester.pumpAndSettle();
          }
          await tapText(tester, 'Copy as ${format.key}');
          await control(tester, 'Check transcript clipboard');
          await tapText(tester, 'Fixture controls');
          expect(
            find.text('${format.value} export matches: true'),
            findsOneWidget,
          );
          await tapText(tester, 'Close controls');
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );

    testWidgets(
      'Maestro legacy pairing rejection and direct recovery width=$width',
      (tester) async {
        await launch(tester, width);

        await tester.scrollUntilVisible(
          find.text('Legacy input rejection fixture'),
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await tapText(tester, 'Legacy input rejection fixture');
        expect(
          find.text('Pairing links are no longer supported'),
          findsOneWidget,
        );
        expect(find.text('Paste pairing link'), findsNothing);
        await tester.tap(
          find.byKey(const ValueKey('hermes-enrollment-manual-connect')),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('hermes-welcome')), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );

    testWidgets('Maestro gateway is read-only without management width=$width', (
      tester,
    ) async {
      await launch(tester, width);
      await tapText(tester, 'Gateway fixture');
      final note = find.text(
        'Read-only gateway status. Manage services, logs, and messaging platforms on the host.',
      );
      await tester.scrollUntilVisible(
        note,
        250,
        scrollable: find.descendant(
          of: find.byKey(const ValueKey('gateway-body-list')),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.ensureVisible(note);
      await tester.pumpAndSettle();
      expect(note.hitTestable(), findsOneWidget);
      expect(find.text('Host fingerprint'), findsNothing);
      expect(find.text('Revoke this device'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets(
      'Maestro credential contract denial and independent models width=$width',
      (tester) async {
        await launch(tester, width);
        await tapText(tester, 'Providers fixture');
        Future<void> receipt(String text) async {
          await tapText(tester, 'Fixture controls');
          expect(find.text(text), findsOneWidget);
          await tapText(tester, 'Close controls');
        }

        expect(find.text('Manage credential'), findsNothing);
        expect(
          find.byWidgetPredicate(
            (widget) => widget is TextField && widget.obscureText,
          ),
          findsNothing,
        );
        await receipt('Credential writes: 0');
        await receipt('Credential removals: 0');

        await tapText(tester, 'Choose model');
        await tapText(tester, 'fixture-small');
        await tapText(tester, 'fixture-large');
        await tapText(tester, 'Assign');
        await receipt('Model writes: 1');
        await tapText(tester, 'Choose model');
        await control(tester, 'Inject revision conflict');
        await tapText(tester, 'Assign');
        expect(
          find.text(
            'The model selection changed elsewhere. Reopen the picker to try again.',
          ),
          findsOneWidget,
        );
        await receipt('Model writes: 1');
        await tapText(tester, 'Cancel');
        await tapText(tester, 'Choose model');
        await tapText(tester, 'Assign');
        await receipt('Model writes: 2');
        await receipt('Model attempts: 3');

        await control(tester, 'Revoke write grants');
        expect(find.text('Manage credential'), findsNothing);
        await receipt('Credential writes: 0');
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
    );

    for (final delayedPicker in [false, true]) {
      testWidgets(
        'Maestro draft ownership width=$width delayedPicker=$delayedPicker',
        (tester) async {
          await launch(tester, width);
          await tester.scrollUntilVisible(
            find.text('Chat fixture'),
            250,
            scrollable: find.byType(Scrollable).first,
          );
          await tapText(tester, 'Chat fixture');
          final composer = find.byKey(const ValueKey('hermes-composer-field'));
          final attach = find.byTooltip('Attach image or text file');
          String draft() => tester.widget<TextField>(composer).controller!.text;
          await tester.enterText(composer, 'Fixture first draft');
          await tester.pump();
          if (delayedPicker) await control(tester, 'Pick deferred fixture');
          await tester.tap(attach);
          await tester.pump(const Duration(milliseconds: 100));
          await control(
            tester,
            'Select second session',
            waitForIdle: !delayedPicker,
          );
          expect(draft(), isEmpty);
          expect(find.byTooltip('Remove attachment'), findsNothing);
          await tester.enterText(composer, 'Fixture second draft');
          await tester.pump();
          if (delayedPicker) {
            await control(
              tester,
              'Complete fixture picker',
              waitForIdle: false,
            );
            await tester.pumpAndSettle();
          }
          expect(draft(), 'Fixture second draft');
          expect(find.byTooltip('Remove attachment'), findsNothing);
          await control(tester, 'Select first session');
          expect(draft(), 'Fixture first draft');
          expect(
            find.byTooltip('Remove attachment'),
            delayedPicker ? findsNothing : findsOneWidget,
          );
          await control(tester, 'Select draft profile');
          expect(draft(), isEmpty);
          expect(find.byTooltip('Remove attachment'), findsNothing);
          await tester.enterText(composer, 'Fixture other profile');
          await tester.pump();
          await control(tester, 'Select default profile');
          expect(draft(), 'Fixture first draft');
          expect(
            find.byTooltip('Remove attachment'),
            delayedPicker ? findsNothing : findsOneWidget,
          );
          if (delayedPicker) {
            await control(tester, 'Pick text fixture');
            await tester.tap(attach);
            await tester.pumpAndSettle();
            expect(find.byTooltip('Remove attachment'), findsOneWidget);
            expect(find.textContaining('fixture-note.txt'), findsWidgets);
          }
          await tapText(tester, 'Fixture controls');
          expect(find.text('Submitted turns: 0'), findsOneWidget);
          expect(
            find.text('Picker calls: ${delayedPicker ? 2 : 1}'),
            findsOneWidget,
          );
          await tapText(tester, 'Close controls');
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
        },
      );
    }

    testWidgets(
      'Maestro approval Stop and offline status recovery width=$width',
      (tester) async {
        await launch(tester, width);
        await tester.scrollUntilVisible(
          find.text('Chat fixture'),
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await tapText(tester, 'Chat fixture');
        Future<void> send(String text) async {
          await tester.enterText(
            find.byKey(const ValueKey('hermes-composer-field')),
            text,
          );
          await tester.pump();
          await tester.tap(find.byKey(const ValueKey('hermes-send-button')));
          for (var tick = 0; tick < 100; tick++) {
            await tester.pump(const Duration(milliseconds: 50));
            if (find.text('Approve once').hitTestable().evaluate().isNotEmpty) {
              return;
            }
          }
          fail('Approval did not become actionable after deliberate Send.');
        }

        await send('Fixture deny turn');
        // Reviewing leaves the pending run animated behind the modal.
        await tapText(tester, 'Review', waitForIdle: false);
        expect(find.text('Review Hermes approval'), findsOneWidget);
        await tapText(tester, 'Deny');
        expect(find.textContaining('Fixture decision deny'), findsWidgets);
        await send('Fixture stopped turn');
        await tapText(tester, 'Stop');
        expect(find.textContaining('Fixture approval 2'), findsNothing);
        await send('Fixture next turn');
        await tapText(tester, 'Approve once');
        expect(find.textContaining('Fixture decision once'), findsWidgets);
        // Offline recovery also animates until the explicit reconnect.
        await control(tester, 'Disconnect fixture', waitForIdle: false);
        final composer = find.byKey(const ValueKey('hermes-composer-field'));
        expect(composer, findsNothing);
        expect(find.byType(CircularProgressIndicator), findsWidgets);
        await control(tester, 'Reconnect fixture', waitForIdle: false);
        await tester.pumpAndSettle();
        expect(composer, findsOneWidget);
        expect(tester.widget<TextField>(composer).enabled, isTrue);
        await tester.enterText(composer, 'Fixture unsent recovery draft');
        await tester.pump();
        expect(
          tester
              .widget<IconButton>(
                find.byKey(const ValueKey('hermes-send-button')),
              )
              .onPressed,
          isNotNull,
        );
        expect(find.textContaining('Fixture decision once'), findsWidgets);
        expect(find.text('Approve once'), findsNothing);
        await tapText(tester, 'Fixture controls');
        for (final receipt in [
          'Submitted turns: 3',
          'Approval decisions: 2',
          'Stop calls: 1',
          'Active session: sess_1',
        ]) {
          expect(find.text(receipt), findsOneWidget);
        }
        await tapText(tester, 'Close controls');
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
    );

    testWidgets('Maestro screen tour on Linux at width $width', (tester) async {
      await launch(tester, width);
      await tester.tap(find.text('Start visual review'));
      await tester.pumpAndSettle();

      const titles = [
        'Profiles',
        'Tools',

        'Providers',
        'Persona',
        'Connections',
        'Settings',
        'Voice & speech',
        'Diagnostics',
        'Schedules',
        'What are we working on?',
        'Connect to Hermes',
        // Linux Local uses direct connection, not the retired phone setup page.
        'Add Hermes',
      ];
      for (var step = 0; step < titles.length * 2; step++) {
        expect(find.text('${step + 1} / 26'), findsOneWidget);
        final destination = find
            .text(titles[step % titles.length])
            .hitTestable();
        expect(
          destination,
          findsWidgets,
          reason: 'Visible destination at step ${step + 1}, width $width',
        );
        if (step % titles.length == titles.length - 1) {
          expect(
            tester
                .widget<ChoiceChip>(
                  find.byKey(const ValueKey('hermes-connection-mode-local')),
                )
                .selected,
            isTrue,
          );
        }
        expect(
          Theme.of(tester.element(destination.first)).brightness,
          step < titles.length ? Brightness.light : Brightness.dark,
        );
        expect(tester.takeException(), isNull);
        if (step < titles.length * 2 - 1) {
          await tester.tap(find.text('Next screen'));
          await tester.pumpAndSettle();
        }
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });

    testWidgets('Maestro attachments and schedule recovery at width $width', (
      tester,
    ) async {
      await launch(tester, width);
      await tester.scrollUntilVisible(
        find.text('Chat fixture'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tapText(tester, 'Chat fixture');
      final attach = find.byTooltip('Attach image or text file');
      await tester.tap(attach);
      await tester.pumpAndSettle();
      expect(find.textContaining('fixture-note.txt'), findsWidgets);
      await tester.tap(find.byTooltip('Remove attachment'));
      await tester.pumpAndSettle();
      expect(find.textContaining('fixture-note.txt'), findsNothing);

      for (final scenario in {
        'Pick cancel fixture': null,
        'Pick binary fixture': 'Hermes accepts PNG',
        'Pick oversize fixture': 'Text files must be 256 KB or smaller.',
        'Pick invalid fixture': 'Text attachments must contain valid UTF-8.',
      }.entries) {
        await control(tester, scenario.key);
        await tester.tap(attach);
        await tester.pumpAndSettle();
        expect(find.byTooltip('Remove attachment'), findsNothing);
        if (scenario.value != null) {
          expect(find.textContaining(scenario.value!), findsWidgets);
        }
      }
      await control(tester, 'Pick text fixture');
      await tester.tap(attach);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('hermes-composer-field')),
        'Fixture file send',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('hermes-send-button')));
      // A pending approval can keep the streaming indicator animated.
      for (var tick = 0; tick < 100; tick++) {
        await tester.pump(const Duration(milliseconds: 50));
        if (find.text('Approve once').hitTestable().evaluate().isNotEmpty) {
          break;
        }
      }
      expect(find.text('Approve once').hitTestable(), findsOneWidget);
      await tapText(tester, 'Approve once');
      await tapText(tester, 'Fixture controls');
      expect(find.text('Text attachment sent: true'), findsOneWidget);
      expect(find.text('Submitted turns: 1'), findsOneWidget);
      await tapText(tester, 'Close controls');
      await tapText(tester, 'Fixture home');
      await tester.scrollUntilVisible(
        find.text('Schedules fixture'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tapText(tester, 'Schedules fixture');
      expect(find.textContaining('Fixture daily check'), findsWidgets);
      await control(tester, 'Fail schedule refresh');
      await tester.tap(find.byTooltip('Refresh schedules'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Schedules could not be loaded from Hermes.'),
        findsWidgets,
      );
      await control(tester, 'Restore schedule refresh');
      await tester.tap(find.byTooltip('Refresh schedules'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Fixture daily check'), findsWidgets);
      expect(
        find.textContaining('Schedules could not be loaded from Hermes.'),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  }
}
