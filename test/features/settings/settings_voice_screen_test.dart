import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/features/settings/screens/settings_screen.dart';
import 'package:wing/l10n/app_localizations.dart';

void main() {
  testWidgets('Pocket Speech settings explain downloads and playback choices', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      'wing.voice.pocket_speech_model': 'kitten',
      'wing.voice.kokoro_model_path': '/models/kitten/model.onnx',
      'wing.voice.kokoro_voices_path': '/models/kitten/voices.json',
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: VoiceSettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final speed = find.byKey(const ValueKey('voice-pocket-speech-speed'));
    await tester.scrollUntilVisible(speed, 300);

    expect(find.byKey(const ValueKey('voice-pocket-speech-voice')), findsOne);
    final preview = find.byKey(const ValueKey('voice-pocket-speech-preview'));
    expect(preview, findsOne);
    expect(
      tester
          .widget<OutlinedButton>(
            find.descendant(of: preview, matching: find.byType(OutlinedButton)),
          )
          .onPressed,
      isNotNull,
    );
    expect(speed, findsOne);
    expect(find.text('About 26 MB · English · 8 voices'), findsOneWidget);
    expect(find.textContaining('stored on this device'), findsOneWidget);
  });

  testWidgets('large text stays usable on a narrow phone', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(320, 700),
              textScaler: TextScaler.linear(2),
            ),
            child: VoiceSettingsScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('advanced voice controls start collapsed and can be revealed', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: VoiceSettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('settings-command-word')), findsNothing);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('voice-advanced-expansion')),
      300,
    );
    expect(find.text('Advanced'), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('voice-advanced-expansion')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('settings-command-word')), findsOneWidget);
  });

  testWidgets('the Advanced heading renders once', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: VoiceSettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('voice-advanced-expansion')),
      300,
    );
    expect(find.text('Advanced'), findsOneWidget);
  });
}
