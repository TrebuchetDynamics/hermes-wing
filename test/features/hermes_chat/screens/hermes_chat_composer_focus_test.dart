import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/models/hermes_session.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../support/fake_hermes_channel.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('desktop composer takes focus on initial chat entry', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [hermesChannelProvider.overrideWithValue(channel)],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HermesChatScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final composer = tester.widget<TextField>(
      find.byKey(const ValueKey('hermes-composer-field')),
    );
    expect(composer.focusNode!.hasFocus, isTrue);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('desktop composer regains focus when its reply finishes', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);
    channel.beginStreamingTurn('Finish this response.');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [hermesChannelProvider.overrideWithValue(channel)],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HermesChatScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));

    final composer = tester.widget<TextField>(
      find.byKey(const ValueKey('hermes-composer-field')),
    );
    composer.focusNode!.unfocus();
    await tester.pump();
    expect(composer.focusNode!.hasFocus, isFalse);

    channel.completeStreamingTurn(text: 'Finished.');
    await tester.pumpAndSettle();

    expect(composer.focusNode!.hasFocus, isTrue);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('background completion does not steal desktop composer focus', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final channel = FakeHermesChannel(
      sessions: const [
        HermesSession(id: 'session-1', source: 'fake'),
        HermesSession(id: 'session-2', source: 'fake'),
      ],
      activeSessionId: 'session-2',
    );
    addTearDown(channel.dispose);
    channel.beginStreamingTurn('Background response.');
    await channel.selectSession('session-1');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [hermesChannelProvider.overrideWithValue(channel)],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HermesChatScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));

    final composer = tester.widget<TextField>(
      find.byKey(const ValueKey('hermes-composer-field')),
    );
    composer.focusNode!.unfocus();
    await tester.pump();
    channel.completeStreamingTurn(
      text: 'Background finished.',
      sessionId: 'session-2',
    );
    await tester.pumpAndSettle();

    expect(composer.focusNode!.hasFocus, isFalse);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('completion does not open the mobile composer keyboard', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);
    channel.beginStreamingTurn('Finish without opening the keyboard.');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [hermesChannelProvider.overrideWithValue(channel)],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HermesChatScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));

    final composer = tester.widget<TextField>(
      find.byKey(const ValueKey('hermes-composer-field')),
    );
    channel.completeStreamingTurn(text: 'Finished.');
    await tester.pumpAndSettle();

    expect(composer.focusNode!.hasFocus, isFalse);
    debugDefaultTargetPlatformOverride = null;
  });
}
