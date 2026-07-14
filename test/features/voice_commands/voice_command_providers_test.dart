import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:navivox/features/settings/providers/voice_settings_provider.dart';
import 'package:navivox/features/voice_commands/core/needle_model_install_service.dart';
import 'package:navivox/features/voice_commands/providers/voice_command_providers.dart';
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
    container.read(navivoxVoiceSettingsProvider.notifier);
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
    // reading the router: `NavivoxVoiceSettings` starts at its (router-off)
    // default and only flips once shared_preferences resolves.
    container.read(navivoxVoiceSettingsProvider.notifier);
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
}

List<int> _zipWith(Map<String, String> files) {
  final archive = Archive();
  files.forEach((path, content) {
    archive.addFile(ArchiveFile(path, content.length, content.codeUnits));
  });
  return ZipEncoder().encode(archive);
}
