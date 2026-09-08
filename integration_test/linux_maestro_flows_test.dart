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
      'Maestro pairing invalid expired used and recovery width=$width',
      (tester) async {
        await launch(tester, width);
        await control(tester, 'Invalid pairing input');
        await control(tester, 'Prepare fixture paste');
        await tester.scrollUntilVisible(
          find.text('Pairing fixture'),
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await tapText(tester, 'Pairing fixture');
        await tapText(tester, 'I have a QR code or pairing link');
        await tapText(tester, 'Paste pairing link');
        expect(find.text('Pairing link couldn’t be opened'), findsOneWidget);
        await control(tester, 'Expired pairing input');
        await control(tester, 'Prepare fixture paste');
        await tapText(tester, 'Paste pairing link');
        expect(find.text('This pairing link expired'), findsOneWidget);
        await tapText(tester, 'Fixture controls');
        expect(find.text('Enrollment exchanges: 0'), findsOneWidget);
        await tapText(tester, 'Close controls');
        await control(tester, 'Used pairing input');
        await control(tester, 'Prepare fixture paste');
        await tapText(tester, 'Paste another link');
        await tapText(tester, 'Connect 1 profile');
        expect(find.text('Pairing couldn’t be completed'), findsOneWidget);
        await control(tester, 'Valid pairing input');
        await control(tester, 'Prepare fixture paste');
        await tapText(tester, 'Paste another link');
        await tapText(tester, 'Connect 1 profile');
        expect(find.text('1 profile paired'), findsOneWidget);
        await tapText(tester, 'Fixture controls');
        expect(find.text('Enrollment exchanges: 2'), findsOneWidget);
        await tapText(tester, 'Close controls');
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );

    testWidgets('Maestro trust errors fail closed width=$width', (
      tester,
    ) async {
      await launch(tester, width);
      for (final entry in {
        'Changed host identity': 'The host fingerprint changed.',
        'Expired device credential':
            'This device credential is expired or revoked.',
        'Unsupported protocol': 'outside the supported compatibility window.',
      }.entries) {
        await control(tester, entry.key);
        await tapText(tester, 'Gateway fixture');
        final error = find.textContaining(entry.value);
        await tester.scrollUntilVisible(
          error,
          250,
          scrollable: find.byType(Scrollable).first,
        );
        expect(error.hitTestable(), findsOneWidget);
        expect(find.text('Revoke this device'), findsNothing);
        await tapText(tester, 'Fixture home');
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('Maestro device revocation cancel and confirm width=$width', (
      tester,
    ) async {
      await launch(tester, width);
      await tapText(tester, 'Gateway fixture');
      final revoke = find.text('Revoke this device');
      await tester.scrollUntilVisible(
        revoke,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tapText(tester, 'Revoke this device');
      await tapText(tester, 'Cancel');
      await tapText(tester, 'Fixture controls');
      expect(find.text('Management revoked: false'), findsOneWidget);
      await tapText(tester, 'Close controls');
      await tapText(tester, 'Revoke this device');
      await tapText(tester, 'Revoke this device');
      expect(find.textContaining('This device was revoked.'), findsOneWidget);
      await tapText(tester, 'Fixture controls');
      expect(find.text('Management revoked: true'), findsOneWidget);
      await tapText(tester, 'Close controls');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('Maestro provider mutations and revoked grants width=$width', (
      tester,
    ) async {
      await launch(tester, width);
      await tapText(tester, 'Providers fixture');
      Future<void> receipt(String text) async {
        await tapText(tester, 'Fixture controls');
        expect(find.text(text), findsOneWidget);
        await tapText(tester, 'Close controls');
      }

      await tapText(tester, 'Manage credential');
      final secret = find.byWidgetPredicate(
        (widget) => widget is TextField && widget.obscureText,
      );
      expect(secret, findsOneWidget);
      expect(tester.widget<TextField>(secret).controller!.text, isEmpty);
      await tapText(tester, 'Set');
      expect(find.text('Enter a value to set.'), findsOneWidget);
      await tester.enterText(secret, 'fixture-only-input');
      await tapText(tester, 'Set');
      await receipt('Credential writes: 1');
      await tapText(tester, 'Manage credential');
      expect(tester.widget<TextField>(secret).controller!.text, isEmpty);
      await tapText(tester, 'Validate');
      expect(find.text('Credential accepted.'), findsOneWidget);
      expect(find.text('2 models available'), findsOneWidget);
      await tapText(tester, 'Remove');
      await receipt('Credential removals: 1');

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

      await tapText(tester, 'Manage credential');
      await tester.enterText(secret, 'fixture-only-input');
      await control(tester, 'Revoke write grants');
      await tapText(tester, 'Set');
      expect(
        find.text('The credential operation could not be completed.'),
        findsOneWidget,
      );
      await tapText(tester, 'Cancel');
      await receipt('Credential writes: 1');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });

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

    testWidgets('Maestro screen tour on Linux at width $width', (tester) async {
      await launch(tester, width);
      await tester.tap(find.text('Start visual review'));
      await tester.pumpAndSettle();

      const titles = [
        'Profiles',
        'Tools',
        'Office',
        'Providers',
        'Persona',
        'Gateway',
        'Settings',
        'Voice & speech',
        'Diagnostics',
        'Schedules',
        'What are we working on?',
        'Connect to Hermes',
        'Set up Hermes on this phone',
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
