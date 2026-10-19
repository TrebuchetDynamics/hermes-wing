import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';
import 'package:wing/shared/widgets/app_shell.dart';

import '../support/fake_hermes_channel.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final width in [390.0, 480.0, 599.0]) {
    testWidgets('phone chat keeps a quiet header and composer at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final channel = FakeHermesChannel();
      addTearDown(channel.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [hermesChannelProvider.overrideWithValue(channel)],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: AppShellSessionNavigation(child: HermesChatScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('hermes-more-actions-button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('hermes-disconnect-button')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('hermes-diagnostics-button')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('hermes-mic-button')), findsNothing);
      expect(
        find.byKey(const ValueKey('hermes-draft-mic-button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('hermes-live-voice-start')),
        findsOneWidget,
      );
      final surface = find.byKey(const ValueKey('hermes-composer-surface'));
      expect(tester.getSize(surface).height, lessThan(180));
      final field = find.byKey(const ValueKey('hermes-composer-field'));
      await tester.enterText(field, 'Keep my draft');
      channel.beginStreamingTurn('Synthetic question');
      await tester.pump();
      expect(
        find.byKey(const ValueKey('hermes-composer-stop-chip')),
        findsOneWidget,
      );
      expect(tester.widget<TextField>(field).controller!.text, 'Keep my draft');
      channel.completeStreamingTurn(text: 'Synthetic response.');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
