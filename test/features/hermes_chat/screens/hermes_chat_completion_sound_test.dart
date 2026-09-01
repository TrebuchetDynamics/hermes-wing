import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/l10n/app_localizations.dart';

import '../support/fake_hermes_channel.dart';

void main() {
  testWidgets('opted-in completion sound plays only after a reply finishes', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'wing.voice.completion_sound_enabled': true,
    });
    final soundCalls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'SystemSound.play') soundCalls.add(call);
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );
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

    channel.beginStreamingTurn('Notify me when this finishes.');
    await tester.pump();
    channel.appendStreamingTurnText('Still working.');
    await tester.pump();
    expect(soundCalls, isEmpty);

    channel.completeStreamingTurn(text: 'Finished.');
    await tester.pumpAndSettle();

    expect(soundCalls, hasLength(1));
    expect(soundCalls.single.arguments, 'SystemSoundType.alert');
  });
}
