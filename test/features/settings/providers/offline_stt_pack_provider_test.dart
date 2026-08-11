import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/features/settings/providers/offline_stt_pack_provider.dart';
import 'package:wing/features/voice/services/models/offline_voice_model_manifests.dart';
import 'package:wing/features/voice/services/models/voice_model_pack_installer.dart';
import 'package:wing/shared/voice/voice_capture_service.dart';

void main() {
  test('offline STT tier defaults to Base and persists selection', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      container.read(offlineSttModelTierProvider),
      OfflineSttModelTier.recommended,
    );

    await container
        .read(offlineSttModelTierProvider.notifier)
        .setTier(OfflineSttModelTier.quality);

    expect(
      container.read(offlineSttModelTierProvider),
      OfflineSttModelTier.quality,
    );
    expect(
      (await SharedPreferences.getInstance()).getString(
        'wing.voice.offline_stt_tier',
      ),
      'quality',
    );
  });

  test(
    'latest tier intent wins while persisted preference is loading',
    () async {
      SharedPreferences.setMockInitialValues({
        'wing.voice.offline_stt_tier': 'quality',
      });
      final preferences = await SharedPreferences.getInstance();
      final loader = Completer<SharedPreferences>();
      final container = ProviderContainer(
        overrides: [
          offlineSttPreferencesLoaderProvider.overrideWithValue(
            () => loader.future,
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(offlineSttModelTierProvider),
        OfflineSttModelTier.recommended,
      );
      final selection = container
          .read(offlineSttModelTierProvider.notifier)
          .setTier(OfflineSttModelTier.recommended);
      loader.complete(preferences);
      await selection;
      await Future<void>.delayed(Duration.zero);

      expect(
        container.read(offlineSttModelTierProvider),
        OfflineSttModelTier.recommended,
      );
      expect(
        preferences.getString('wing.voice.offline_stt_tier'),
        'recommended',
      );
    },
  );

  test('refresh exposes installed pack provenance', () async {
    final repository = _FakeOfflineSttPackRepository(installed: true);
    final container = ProviderContainer(
      overrides: [
        offlineSttPackRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    final controller = container.read(
      offlineSttPackControllerProvider.notifier,
    );

    await controller.refresh();

    expect(controller.state.status, OfflineSttPackStatus.installed);
    expect(controller.state.provenance, 'sherpa-onnx Whisper Base INT8');
  });

  test('install publishes busy state then installed state', () async {
    final repository = _FakeOfflineSttPackRepository(installed: false);
    final gate = Completer<void>();
    repository.installGate = gate;
    repository.progress = const VoiceModelPackProgress(
      receivedBytes: 5,
      totalBytes: 10,
      artifactName: 'encoder',
    );
    final container = ProviderContainer(
      overrides: [
        offlineSttPackRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    final controller = container.read(
      offlineSttPackControllerProvider.notifier,
    );
    await controller.refresh();

    final installation = controller.install();
    await Future<void>.delayed(Duration.zero);
    expect(controller.state.status, OfflineSttPackStatus.installing);
    expect(controller.state.receivedBytes, 5);
    expect(controller.state.totalBytes, 10);
    gate.complete();
    await installation;

    expect(controller.state.status, OfflineSttPackStatus.installed);
    expect(repository.installCalls, 1);
  });

  test('repository errors are sanitized before reaching UI state', () async {
    final repository = _FakeOfflineSttPackRepository(installed: false)
      ..installError = StateError('/secret/model/url?token=credential');
    final container = ProviderContainer(
      overrides: [
        offlineSttPackRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    final controller = container.read(
      offlineSttPackControllerProvider.notifier,
    );
    await controller.refresh();

    await controller.install();

    expect(controller.state.status, OfflineSttPackStatus.error);
    expect(
      controller.state.message,
      'The offline speech pack could not be installed.',
    );
    expect(controller.state.message, isNot(contains('/secret')));
    expect(controller.state.message, isNot(contains('credential')));
  });

  test('delete returns pack to absent state', () async {
    final repository = _FakeOfflineSttPackRepository(installed: true);
    final container = ProviderContainer(
      overrides: [
        offlineSttPackRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    final controller = container.read(
      offlineSttPackControllerProvider.notifier,
    );
    await controller.refresh();

    await controller.delete();

    expect(controller.state.status, OfflineSttPackStatus.absent);
    expect(repository.deleteCalls, 1);
  });

  test(
    'delete awaits active offline runtime disposal before file removal',
    () async {
      final repository = _FakeOfflineSttPackRepository(installed: true);
      final owner = OfflineVoiceRuntimeOwner();
      final runtime = _BlockingLifecycleService();
      unawaited(owner.adopt(runtime));
      final container = ProviderContainer(
        overrides: [
          offlineSttPackRepositoryProvider.overrideWithValue(repository),
          offlineVoiceRuntimeOwnerProvider.overrideWithValue(owner),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(
        offlineSttPackControllerProvider.notifier,
      );
      await controller.refresh();

      final deletion = controller.delete();
      await Future<void>.delayed(Duration.zero);

      expect(runtime.disposeCalls, 1);
      expect(repository.deleteCalls, 0);
      runtime.disposal.complete();
      await deletion;
      expect(repository.deleteCalls, 1);
    },
  );
}

class _BlockingLifecycleService implements VoiceCaptureLifecycleService {
  final disposal = Completer<void>();
  int disposeCalls = 0;

  @override
  Future<void> dispose() {
    disposeCalls += 1;
    return disposal.future;
  }
}

class _FakeOfflineSttPackRepository
    implements OfflineSttPackProgressRepository {
  _FakeOfflineSttPackRepository({required this.installed});

  bool installed;
  Completer<void>? installGate;
  Object? installError;
  VoiceModelPackProgress? progress;
  int installCalls = 0;
  int deleteCalls = 0;

  @override
  Future<OfflineSttPackInstallation?> installedPack() async => installed
      ? const OfflineSttPackInstallation(
          provenance: 'sherpa-onnx Whisper Base INT8',
        )
      : null;

  @override
  Future<OfflineSttPackInstallation> install() async {
    installCalls += 1;
    final gate = installGate;
    if (gate != null) await gate.future;
    final error = installError;
    if (error != null) throw error;
    installed = true;
    return const OfflineSttPackInstallation(
      provenance: 'sherpa-onnx Whisper Base INT8',
    );
  }

  @override
  Future<OfflineSttPackInstallation> installWithProgress(
    VoiceModelPackProgressCallback onProgress,
  ) async {
    final value = progress;
    if (value != null) onProgress(value);
    return install();
  }

  @override
  Future<void> delete() async {
    deleteCalls += 1;
    installed = false;
  }
}
