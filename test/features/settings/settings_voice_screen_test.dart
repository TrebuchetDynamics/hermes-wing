import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/features/settings/providers/voice_settings_provider.dart';
import 'package:wing/features/settings/screens/settings_screen.dart';
import 'package:wing/l10n/app_localizations.dart';

void main() {
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
    expect(tester.takeException(), isNull);

    final advanced = find.byKey(const ValueKey('voice-advanced-expansion'));
    await tester.scrollUntilVisible(advanced, 300);
    expect(tester.takeException(), isNull);
  });

  testWidgets('recognition language can select automatic or one locale', (
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
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('voice-advanced-expansion')),
      300,
    );
    final advanced = find.byKey(const ValueKey('voice-advanced-expansion'));
    await tester.ensureVisible(advanced);
    await tester.pumpAndSettle();
    await tester.tap(advanced);
    await tester.pumpAndSettle();

    final picker = find.byKey(const ValueKey('voice-language-mode'));
    expect(picker, findsOneWidget);
    await tester.ensureVisible(picker);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: picker,
        matching: find.byType(DropdownButton<VoiceLanguageMode>),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Automatic · device recognizer'), findsWidgets);
    await tester.tap(find.text('Español').last);
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(VoiceSettingsScreen)),
    );
    expect(
      container.read(wingVoiceSettingsProvider).languageMode,
      VoiceLanguageMode.spanish,
    );
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
    final advanced = find.byKey(const ValueKey('voice-advanced-expansion'));
    await tester.ensureVisible(advanced);
    await tester.pumpAndSettle();
    await tester.tap(advanced);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('settings-command-word')), findsOneWidget);
  });

  testWidgets('command word save requires nonblank bounded input', (
    tester,
  ) async {
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
    final advanced = find.byKey(const ValueKey('voice-advanced-expansion'));
    await tester.scrollUntilVisible(advanced, 300);
    await tester.tap(advanced);
    await tester.pumpAndSettle();
    final command = find.byKey(const ValueKey('settings-command-word'));
    await tester.scrollUntilVisible(command, 300);
    await tester.ensureVisible(command);
    await tester.pumpAndSettle();
    await tester.tap(command);
    await tester.pumpAndSettle();

    final field = find.byKey(const ValueKey('settings-command-word-field'));
    await tester.enterText(field, '   ');
    await tester.pump();
    final save = find.widgetWithText(FilledButton, 'Save');
    expect(tester.widget<FilledButton>(save).onPressed, isNull);

    await tester.enterText(field, 'wing');
    await tester.pump();
    expect(tester.widget<FilledButton>(save).onPressed, isNotNull);
    expect(tester.widget<TextField>(field).maxLength, 64);
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
