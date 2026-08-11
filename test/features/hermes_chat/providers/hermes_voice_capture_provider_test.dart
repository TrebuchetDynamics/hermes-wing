import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/features/settings/providers/offline_stt_pack_provider.dart';
import 'package:wing/features/voice/services/models/offline_voice_model_manifests.dart';
import 'package:wing/features/voice/services/platform/voice_capture_platform.dart';

void main() {
  test(
    'offline pack state change rebuilds the production capture selector',
    () async {
      SharedPreferences.setMockInitialValues({});
      final repository = _PackRepository();
      final container = ProviderContainer(
        overrides: [
          offlineSttPackRepositoryProvider.overrideWithValue(repository),
          hermesVoiceCapturePlatformProvider.overrideWithValue(
            const VoiceCapturePlatform(isAndroid: true),
          ),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        hermesVoiceCaptureServiceProvider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);
      final packController = container.read(
        offlineSttPackControllerProvider.notifier,
      );
      await packController.refresh();
      final before = container.read(hermesVoiceCaptureServiceProvider);

      await packController.install();
      await Future<void>.delayed(Duration.zero);
      final after = container.read(hermesVoiceCaptureServiceProvider);

      expect(before, isNotNull);
      expect(after, isNotNull);
      expect(identical(before, after), isFalse);
    },
  );

  test('offline STT tier change rebuilds the production selector', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = _PackRepository()..installed = true;
    final container = ProviderContainer(
      overrides: [
        offlineSttPackRepositoryProvider.overrideWithValue(repository),
        hermesVoiceCapturePlatformProvider.overrideWithValue(
          const VoiceCapturePlatform(isAndroid: true),
        ),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      hermesVoiceCaptureServiceProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);
    await container.read(offlineSttPackControllerProvider.notifier).refresh();
    final before = container.read(hermesVoiceCaptureServiceProvider);

    await container
        .read(offlineSttModelTierProvider.notifier)
        .setTier(OfflineSttModelTier.quality);
    await Future<void>.delayed(Duration.zero);
    final after = container.read(hermesVoiceCaptureServiceProvider);

    expect(before, isNotNull);
    expect(after, isNotNull);
    expect(identical(before, after), isFalse);
  });
}

class _PackRepository implements OfflineSttPackRepository {
  bool installed = false;

  @override
  Future<OfflineSttPackInstallation?> installedPack() async => installed
      ? const OfflineSttPackInstallation(provenance: 'test pack')
      : null;

  @override
  Future<OfflineSttPackInstallation> install() async {
    installed = true;
    return const OfflineSttPackInstallation(provenance: 'test pack');
  }

  @override
  Future<void> delete() async {
    installed = false;
  }
}
