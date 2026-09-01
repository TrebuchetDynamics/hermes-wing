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

  test('completion sound defaults off and persists opt-in', () async {
    SharedPreferences.setMockInitialValues({});
    final firstContainer = ProviderContainer();
    final controller = firstContainer.read(wingVoiceSettingsProvider.notifier);
    await pumpEventQueue();

    expect(
      firstContainer.read(wingVoiceSettingsProvider).completionSoundEnabled,
      isFalse,
    );
    controller.setCompletionSoundEnabled(true);
    await pumpEventQueue();
    firstContainer.dispose();

    final secondContainer = ProviderContainer();
    addTearDown(secondContainer.dispose);
    secondContainer.read(wingVoiceSettingsProvider.notifier);
    await pumpEventQueue();
    expect(
      secondContainer.read(wingVoiceSettingsProvider).completionSoundEnabled,
      isTrue,
    );
  });

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

  test('disposing during preference work does not raise', () async {
    SharedPreferences.setMockInitialValues({});
    final loadingContainer = ProviderContainer();
    loadingContainer.read(wingVoiceSettingsProvider.notifier);
    loadingContainer.dispose();

    final savingContainer = ProviderContainer();
    final controller = savingContainer.read(wingVoiceSettingsProvider.notifier);
    await pumpEventQueue();
    controller.setSpeakRepliesEnabled(true);
    savingContainer.dispose();

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

    controller.setSpeakRepliesEnabled(true);
    await pumpEventQueue();
  });

  test('voice language mode defaults to bilingual auto and persists', () async {
    SharedPreferences.setMockInitialValues({});
    final firstContainer = ProviderContainer();
    final controller = firstContainer.read(wingVoiceSettingsProvider.notifier);
    await pumpEventQueue();

    expect(
      firstContainer.read(wingVoiceSettingsProvider).languageMode,
      VoiceLanguageMode.autoEnglishSpanish,
    );
    controller.setLanguageMode(VoiceLanguageMode.spanish);
    await pumpEventQueue();
    firstContainer.dispose();

    final secondContainer = ProviderContainer();
    addTearDown(secondContainer.dispose);
    secondContainer.read(wingVoiceSettingsProvider.notifier);
    await pumpEventQueue();

    expect(
      secondContainer.read(wingVoiceSettingsProvider).languageMode,
      VoiceLanguageMode.spanish,
    );
  });
}
