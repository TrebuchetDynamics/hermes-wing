import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/settings/providers/voice_settings_provider.dart';
import 'package:wing/features/voice_commands/core/needle_model_install_service.dart';
import 'package:wing/features/voice_commands/providers/voice_command_providers.dart';
import 'package:pocket_speech/pocket_speech.dart' show KittenCatalog;
import 'package:shared_preferences/shared_preferences.dart';

import '../hermes_chat/support/fake_hermes_channel.dart';

/// Isolates each container from the real filesystem/app-support directory:
/// the router provider must never touch real IO just to be read.
ProviderContainer _buildContainer(Directory tempDir) {
  return ProviderContainer(
    overrides: [
      voiceCommandInstallServiceProvider.overrideWith(
        (ref) async => NeedleModelInstallService(supportDirectory: tempDir),
      ),
      hermesChannelProvider.overrideWithValue(FakeHermesChannel()),
    ],
  );
}

void main() {
  test('router is null when the settings toggle is off', () async {
    SharedPreferences.setMockInitialValues({'voice_commands_enabled': false});
    final tempDir = await Directory.systemTemp.createTemp(
      'voice_command_providers_test',
    );
    addTearDown(() => tempDir.delete(recursive: true));
    final container = _buildContainer(tempDir);
    addTearDown(container.dispose);

    // Let the settings controller's async prefs load resolve (see
    // test/features/settings/voice_command_settings_test.dart for the same
    // synchronization pattern).
    container.read(wingVoiceSettingsProvider.notifier);
    await pumpEventQueue();

    expect(container.read(voiceCommandRouterProvider), isNull);
  });

  test('router is non-null when the settings toggle is on', () async {
    SharedPreferences.setMockInitialValues({'voice_commands_enabled': true});
    final tempDir = await Directory.systemTemp.createTemp(
      'voice_command_providers_test',
    );
    addTearDown(() => tempDir.delete(recursive: true));
    final container = _buildContainer(tempDir);
    addTearDown(container.dispose);

    // Prime and wait for the settings controller's async prefs load before
    // reading the router: `WingVoiceSettings` starts at its (router-off)
    // default and only flips once shared_preferences resolves.
    container.read(wingVoiceSettingsProvider.notifier);
    await pumpEventQueue();

    expect(container.read(voiceCommandRouterProvider), isNotNull);
  });

  group('NeedleModelInstallService.deleteModel', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp(
        'needle_delete_service_test',
      );
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('removes the installed marker', () async {
      final service = NeedleModelInstallService(supportDirectory: tempDir);
      final zip = _zipWith({'config.json': '{}'});
      await service.installFromZipBytes(zip);
      expect(await service.installedModelDir(), isNotNull);

      await service.deleteModel();

      expect(await service.installedModelDir(), isNull);
    });

    test('tolerates a missing install directory', () async {
      final service = NeedleModelInstallService(supportDirectory: tempDir);
      await expectLater(service.deleteModel(), completes);
      expect(await service.installedModelDir(), isNull);
    });
  });

  group('ttsVoiceNamesProvider backend awareness', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp(
        'tts_voice_names_provider_test',
      );
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('pocket speech + kitten returns the Kitten catalog names', () async {
      SharedPreferences.setMockInitialValues({});
      final container = _buildContainer(tempDir);
      addTearDown(container.dispose);

      final notifier = container.read(wingVoiceSettingsProvider.notifier);
      await pumpEventQueue();
      notifier.setPocketSpeechVoicePack(
        const PocketSpeechVoicePack(
          model: PocketSpeechModel.kitten,
          modelPath: 'kitten-model.bin',
          voicesPath: 'kitten-voices.bin',
        ),
      );
      notifier.setPocketSpeechTtsEnabled(true);
      await pumpEventQueue();

      final names = await container.read(ttsVoiceNamesProvider.future);
      expect(names, contains('Bella'));
      expect(names, equals(KittenCatalog.voices));
    });

    test(
      'pocket speech + kokoro reads the voice pack voices.json keys',
      () async {
        SharedPreferences.setMockInitialValues({});
        final voicesFile = File('${tempDir.path}/voices.json');
        await voicesFile.writeAsString(
          jsonEncode({'af_heart': {}, 'af_bella': {}}),
        );
        final container = _buildContainer(tempDir);
        addTearDown(container.dispose);

        final notifier = container.read(wingVoiceSettingsProvider.notifier);
        await pumpEventQueue();
        notifier.setPocketSpeechVoicePack(
          PocketSpeechVoicePack(
            model: PocketSpeechModel.kokoro,
            modelPath: '${tempDir.path}/model.bin',
            voicesPath: voicesFile.path,
          ),
        );
        notifier.setPocketSpeechTtsEnabled(true);
        await pumpEventQueue();

        final names = await container.read(ttsVoiceNamesProvider.future);
        expect(names, unorderedEquals(['af_heart', 'af_bella']));
      },
    );

    test(
      'pocket speech + kokoro resolves keys from a multi-megabyte voices.json',
      () async {
        SharedPreferences.setMockInitialValues({});
        final voicesFile = File('${tempDir.path}/voices.json');
        // Realistic shape: Kokoro packs embed float32 style vectors, so the
        // production file is tens of MB. ~2 MB here keeps the suite fast
        // while still proving large payloads resolve their keys.
        final vector = List<double>.filled(2048, 0.125);
        await voicesFile.writeAsString(
          jsonEncode({
            for (var i = 0; i < 100; i++) 'voice_$i': {'style': vector},
          }),
        );
        final container = _buildContainer(tempDir);
        addTearDown(container.dispose);

        final notifier = container.read(wingVoiceSettingsProvider.notifier);
        await pumpEventQueue();
        notifier.setPocketSpeechVoicePack(
          PocketSpeechVoicePack(
            model: PocketSpeechModel.kokoro,
            modelPath: '${tempDir.path}/model.bin',
            voicesPath: voicesFile.path,
          ),
        );
        notifier.setPocketSpeechTtsEnabled(true);
        await pumpEventQueue();

        final names = await container.read(ttsVoiceNamesProvider.future);
        expect(names, hasLength(100));
        expect(names, contains('voice_0'));
        expect(names, contains('voice_99'));
      },
    );

    test(
      'pocket speech + kokoro with a missing voices.json returns an empty list',
      () async {
        SharedPreferences.setMockInitialValues({});
        final container = _buildContainer(tempDir);
        addTearDown(container.dispose);

        final notifier = container.read(wingVoiceSettingsProvider.notifier);
        await pumpEventQueue();
        notifier.setPocketSpeechVoicePack(
          PocketSpeechVoicePack(
            model: PocketSpeechModel.kokoro,
            modelPath: '${tempDir.path}/model.bin',
            voicesPath: '${tempDir.path}/missing-voices.json',
          ),
        );
        notifier.setPocketSpeechTtsEnabled(true);
        await pumpEventQueue();

        final names = await container.read(ttsVoiceNamesProvider.future);
        expect(names, isEmpty);
      },
    );

    test(
      'pocket speech disabled falls back to the flutter_tts source',
      () async {
        SharedPreferences.setMockInitialValues({});
        final container = _buildContainer(tempDir);
        addTearDown(container.dispose);

        container.read(wingVoiceSettingsProvider.notifier);
        await pumpEventQueue();

        // No platform flutter_tts plugin is registered in this unit-test
        // environment, so the existing (unchanged) fallback degrades to an
        // empty list rather than throwing — this locks that the pocket
        // speech branches are not entered when the toggle is off.
        final names = await container.read(ttsVoiceNamesProvider.future);
        expect(names, isEmpty);
      },
    );
  });
}

List<int> _zipWith(Map<String, String> files) {
  final archive = Archive();
  files.forEach((path, content) {
    archive.addFile(ArchiveFile(path, content.length, content.codeUnits));
  });
  return ZipEncoder().encode(archive);
}
