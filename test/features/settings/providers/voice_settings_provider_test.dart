import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wing/features/settings/providers/voice_settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'an immediate voice preference change wins over async preference load',
    () async {
      SharedPreferences.setMockInitialValues({
        'wing.voice.continuous_enabled': true,
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(wingVoiceSettingsProvider.notifier);
      controller.setContinuousVoiceEnabled(false);
      await pumpEventQueue();

      expect(
        container.read(wingVoiceSettingsProvider).continuousVoiceEnabled,
        isFalse,
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('wing.voice.continuous_enabled'), isFalse);
    },
  );

  test('command phrases are normalized and persisted', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(wingVoiceSettingsProvider.notifier);
    await pumpEventQueue();

    controller.setCommandWord(' Hey   Navi ');
    await pumpEventQueue();

    expect(container.read(wingVoiceSettingsProvider).commandWord, 'hey navi');
    expect(
      (await SharedPreferences.getInstance()).getString(
        'wing.voice.command_word',
      ),
      'hey navi',
    );
  });

  test(
    'stored Pocket Speech enablement fails closed without its pack',
    () async {
      SharedPreferences.setMockInitialValues({
        'wing.voice.kokoro_tts_enabled': true,
        'wing.voice.pocket_speech_model': 'kokoro',
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(wingVoiceSettingsProvider.notifier);
      await pumpEventQueue();

      final settings = container.read(wingVoiceSettingsProvider);
      expect(settings.pocketSpeechVoicePackReady, isFalse);
      expect(settings.pocketSpeechTtsEnabled, isFalse);
    },
  );

  test('disposing during preference work does not raise', () async {
    SharedPreferences.setMockInitialValues({});
    final loadingContainer = ProviderContainer();
    loadingContainer.read(wingVoiceSettingsProvider.notifier);
    loadingContainer.dispose();

    final savingContainer = ProviderContainer();
    final controller = savingContainer.read(wingVoiceSettingsProvider.notifier);
    await pumpEventQueue();
    controller.setSpeechRate(1.5);
    savingContainer.dispose();

    await pumpEventQueue();
  });

  test('removing a pack targets its model after selection changes', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(wingVoiceSettingsProvider.notifier);
    await pumpEventQueue();

    controller.setPocketSpeechVoicePack(
      const PocketSpeechVoicePack(
        model: PocketSpeechModel.kokoro,
        modelPath: '/models/kokoro/model.onnx',
        voicesPath: '/models/kokoro/voices.json',
      ),
    );
    controller.setPocketSpeechVoicePack(
      const PocketSpeechVoicePack(
        model: PocketSpeechModel.kitten,
        modelPath: '/models/kitten/model.onnx',
        voicesPath: '/models/kitten/voices.json',
      ),
    );
    controller.clearPocketSpeechVoicePack(PocketSpeechModel.kokoro);

    controller.setPocketSpeechModel(PocketSpeechModel.kokoro);
    expect(
      container.read(wingVoiceSettingsProvider).pocketSpeechVoicePack,
      isNull,
    );
    controller.setPocketSpeechModel(PocketSpeechModel.kitten);
    expect(
      container
          .read(wingVoiceSettingsProvider)
          .pocketSpeechVoicePack
          ?.modelPath,
      '/models/kitten/model.onnx',
    );
    await pumpEventQueue();
  });

  test('voice preference write failures are contained', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.resetStatic();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/shared_preferences'),
          (call) async {
            if (call.method == 'getAll') return <String, Object>{};
            throw PlatformException(code: 'write_failed');
          },
        );
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(wingVoiceSettingsProvider.notifier);
    await pumpEventQueue();

    controller.setSpeechRate(1.5);
    await pumpEventQueue();
  });

  test('switching models remembers a downloaded pack after restart', () async {
    SharedPreferences.setMockInitialValues({});
    final firstContainer = ProviderContainer();
    final controller = firstContainer.read(wingVoiceSettingsProvider.notifier);
    await pumpEventQueue();

    controller.setPocketSpeechVoicePack(
      const PocketSpeechVoicePack(
        model: PocketSpeechModel.kokoro,
        modelPath: '/models/kokoro/model.onnx',
        voicesPath: '/models/kokoro/voices.json',
      ),
    );
    controller.setPocketSpeechTtsEnabled(true);
    controller.setTtsVoiceName('ef_dora');
    controller.setPocketSpeechModel(PocketSpeechModel.kitten);
    await pumpEventQueue();
    firstContainer.dispose();

    final secondContainer = ProviderContainer();
    addTearDown(secondContainer.dispose);
    final restoredController = secondContainer.read(
      wingVoiceSettingsProvider.notifier,
    );
    await pumpEventQueue();
    restoredController.setPocketSpeechModel(PocketSpeechModel.kokoro);
    await pumpEventQueue();

    final settings = secondContainer.read(wingVoiceSettingsProvider);
    expect(settings.pocketSpeechModel, PocketSpeechModel.kokoro);
    expect(
      settings.pocketSpeechVoicePack?.modelPath,
      '/models/kokoro/model.onnx',
    );
    expect(settings.pocketSpeechTtsEnabled, isFalse);
    expect(settings.ttsVoiceName, isNull);
  });
}
