import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/features/settings/providers/offline_stt_pack_provider.dart';
import 'package:wing/features/settings/providers/voice_settings_provider.dart';
import 'package:wing/features/settings/screens/settings_screen.dart';
import 'package:wing/features/voice/services/models/offline_voice_model_manifests.dart';
import 'package:wing/features/voice/services/tts/pocket_speech_asset_download_service.dart';
import 'package:wing/l10n/app_localizations.dart';
import 'package:wing/shared/voice/text_to_speech_service.dart';

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

    expect(
      find.text('Choose a compact English pack or the larger English pack'),
      findsOneWidget,
    );

    final speed = find.byKey(const ValueKey('voice-pocket-speech-speed'));
    await tester.scrollUntilVisible(speed, 300);

    final voicePicker = find.byKey(const ValueKey('voice-pocket-speech-voice'));
    expect(voicePicker, findsOne);
    await tester.ensureVisible(voicePicker);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: voicePicker,
        matching: find.byType(DropdownButton<String?>),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Jasper'), findsOneWidget);
    expect(find.text('Bella'), findsNothing);
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
    expect(find.text('About 26 MB · English · 1 voice'), findsOneWidget);
    expect(find.textContaining('stored on this device'), findsOneWidget);
  });

  testWidgets('Pocket Speech deletion awaits active runtime disposal', (
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
    final downloader = _FakeAssetDownloadService();
    debugPocketSpeechAssetDownloadService = downloader;
    addTearDown(() => debugPocketSpeechAssetDownloadService = null);
    final owner = OfflineTtsRuntimeOwner();
    final runtime = _BlockingDisposeTtsService();
    await owner.adopt(runtime, ownsOfflineModels: true);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [offlineTtsRuntimeOwnerProvider.overrideWithValue(owner)],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: VoiceSettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final remove = find.byKey(
      const ValueKey('voice-pocket-speech-remove-kitten'),
    );
    final removeButton = tester.widget<IconButton>(remove);
    expect(removeButton.onPressed, isNotNull);
    removeButton.onPressed!();
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Remove'));
    await tester.pump();

    expect(runtime.disposeStarted, isTrue);
    expect(downloader.deleteCalls, 0);

    runtime.disposeGate.complete();
    await tester.pumpAndSettle();
    expect(downloader.deleteCalls, 1);
  });

  testWidgets(
    'model picker shows download size and language coverage before selection',
    (tester) async {
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
        find.byKey(const ValueKey('voice-pocket-speech-model')),
        300,
      );
      final modelDropdown = find.descendant(
        of: find.byKey(const ValueKey('voice-pocket-speech-model')),
        matching: find.byType(DropdownButton<PocketSpeechModel>),
      );
      await tester.ensureVisible(modelDropdown);
      await tester.pumpAndSettle();
      await tester.tap(modelDropdown);
      await tester.pumpAndSettle();

      expect(
        find.text('Kitten · About 26 MB · English · 1 voice'),
        findsOneWidget,
      );
      expect(
        find.text('Kokoro · About 331 MB · English + Spanish · 2 voices'),
        findsOneWidget,
      );
    },
  );

  testWidgets('selecting a model restores its verified installed pack', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'wing.voice.pocket_speech_model': 'kokoro',
    });
    debugPocketSpeechAssetDownloadService = _FakeAssetDownloadService();
    addTearDown(() => debugPocketSpeechAssetDownloadService = null);

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
      find.byKey(const ValueKey('voice-pocket-speech-model')),
      300,
    );
    final modelDropdown = find.descendant(
      of: find.byKey(const ValueKey('voice-pocket-speech-model')),
      matching: find.byType(DropdownButton<PocketSpeechModel>),
    );
    await tester.ensureVisible(modelDropdown);
    await tester.pumpAndSettle();
    await tester.tap(modelDropdown);
    await tester.pumpAndSettle();
    await tester.tap(
      find.text('Kitten · About 26 MB · English · 1 voice').last,
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('stored on this device'), findsOneWidget);
  });

  testWidgets('missing Kokoro voice data is reported, not shown as empty', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'wing.voice.pocket_speech_model': 'kokoro',
      'wing.voice.kokoro_model_path': '/missing/model.onnx',
      'wing.voice.kokoro_voices_path': '/missing/voices.json',
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
    await tester.pump();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(VoiceSettingsScreen)),
    );
    for (var attempt = 0; attempt < 10; attempt++) {
      final settings = container.read(wingVoiceSettingsProvider);
      final voices = container.read(pocketSpeechVoiceNamesProvider);
      if (settings.pocketSpeechModel == PocketSpeechModel.kokoro &&
          voices.hasError) {
        break;
      }
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
    }

    expect(
      container.read(wingVoiceSettingsProvider).pocketSpeechModel,
      PocketSpeechModel.kokoro,
    );
    expect(container.read(pocketSpeechVoiceNamesProvider).hasError, isTrue);
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
    await tester.tap(find.byKey(const ValueKey('voice-advanced-expansion')));
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

  testWidgets('leaving voice settings stops an in-flight preview', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'wing.voice.pocket_speech_model': 'kitten',
      'wing.voice.kokoro_model_path': '/models/kitten/model.onnx',
      'wing.voice.kokoro_voices_path': '/models/kitten/voices.json',
    });
    final fake = _FakePreviewTtsService();
    debugPocketSpeechPreviewServiceFactory = (_) => fake;
    addTearDown(() => debugPocketSpeechPreviewServiceFactory = null);

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
    await tester.scrollUntilVisible(find.text('Preview'), 300);
    await tester.ensureVisible(find.text('Preview'));
    await tester.pump();
    await tester.tap(find.text('Preview'));
    await tester.pump();

    await tester.pumpWidget(const SizedBox());
    await tester.pump();

    expect(fake.disposed, isTrue);
  });

  testWidgets('a running offline preview exposes a stop control that ends it', (
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
    final fake = _FakePreviewTtsService();
    debugPocketSpeechPreviewServiceFactory = (_) => fake;
    addTearDown(() => debugPocketSpeechPreviewServiceFactory = null);

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

    await tester.scrollUntilVisible(find.text('Preview'), 300);
    await tester.ensureVisible(find.text('Preview'));
    await tester.pump();
    await tester.tap(find.text('Preview'));
    await tester.pump();

    final stop = find.byKey(const ValueKey('voice-preview-stop'));
    expect(stop, findsOneWidget);

    await tester.tap(stop);
    await tester.pumpAndSettle();

    expect(fake.stopped, isTrue);
    expect(find.text('Preview'), findsOneWidget);
    expect(stop, findsNothing);
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

class _FakeAssetDownloadService implements PocketSpeechAssetDownloadService {
  int deleteCalls = 0;

  @override
  bool isConfigured(PocketSpeechModel model) => true;

  @override
  Future<PocketSpeechVoicePack?> installedPack(PocketSpeechModel model) async =>
      model == PocketSpeechModel.kitten
      ? const PocketSpeechVoicePack(
          model: PocketSpeechModel.kitten,
          modelPath: '/models/kitten/model.onnx',
          voicesPath: '/models/kitten/voices.json',
        )
      : null;

  @override
  Future<PocketSpeechVoicePack> download(
    PocketSpeechModel model, {
    PocketSpeechDownloadProgressCallback? onProgress,
  }) => throw UnimplementedError();

  @override
  Future<void> delete(PocketSpeechModel model) async {
    deleteCalls += 1;
  }
}

class _BlockingDisposeTtsService implements TextToSpeechService {
  final disposeGate = Completer<void>();
  bool disposeStarted = false;

  @override
  Future<void> speak(String text) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {
    disposeStarted = true;
    await disposeGate.future;
  }
}

class _FakePreviewTtsService implements TextToSpeechService {
  final _speaking = Completer<void>();
  bool stopped = false;
  bool disposed = false;

  @override
  Future<void> speak(String text) => _speaking.future;

  @override
  Future<void> stop() async {
    stopped = true;
    if (!_speaking.isCompleted) _speaking.complete();
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    if (!_speaking.isCompleted) _speaking.complete();
  }
}
