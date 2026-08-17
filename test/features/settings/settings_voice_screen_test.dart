import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/features/settings/providers/offline_stt_pack_provider.dart';
import 'package:wing/features/settings/providers/voice_settings_provider.dart';
import 'package:wing/features/settings/screens/settings_screen.dart';
import 'package:wing/features/voice/services/models/offline_voice_model_manifests.dart';
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

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('voice-advanced-expansion')),
      300,
    );
    await tester.tap(find.byKey(const ValueKey('voice-advanced-expansion')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('recognition language can select bilingual auto or one locale', (
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
    expect(find.text('Auto · English + Español'), findsWidgets);
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

  testWidgets('offline STT pack can be downloaded from Voice settings', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final repository = _FakeOfflineSttRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          offlineSttPackRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: VoiceSettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final pack = find.byKey(const ValueKey('voice-offline-stt-pack'));
    await tester.scrollUntilVisible(pack, 300);
    expect(pack, findsOneWidget);
    expect(find.textContaining('Whisper Base'), findsWidgets);

    final tier = find.byKey(const ValueKey('voice-offline-stt-tier'));
    expect(tier, findsOneWidget);
    await tester.tap(tier);
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Whisper Small').last);
    await tester.pumpAndSettle();
    expect(
      ProviderScope.containerOf(
        tester.element(pack),
      ).read(offlineSttModelTierProvider),
      OfflineSttModelTier.quality,
    );

    final download = find.byKey(const ValueKey('voice-offline-stt-download'));
    await tester.tap(download);
    await tester.pumpAndSettle();

    expect(repository.installCalls, 1);
    expect(
      find.byKey(const ValueKey('voice-offline-stt-delete')),
      findsOneWidget,
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

class _FakeOfflineSttRepository implements OfflineSttPackRepository {
  bool installed = false;
  int installCalls = 0;

  @override
  Future<OfflineSttPackInstallation?> installedPack() async => installed
      ? const OfflineSttPackInstallation(provenance: 'verified test revision')
      : null;

  @override
  Future<OfflineSttPackInstallation> install() async {
    installCalls += 1;
    installed = true;
    return const OfflineSttPackInstallation(
      provenance: 'verified test revision',
    );
  }

  @override
  Future<void> delete() async {
    installed = false;
  }
}
