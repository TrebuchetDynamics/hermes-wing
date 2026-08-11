import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../voice/services/models/default_voice_model_pack_installer.dart';
import '../../voice/services/models/offline_voice_model_manifests.dart';
import '../../voice/services/models/voice_model_pack.dart';
import '../../voice/services/models/voice_model_pack_installer.dart';
import '../../../shared/voice/voice_capture_service.dart';

/// Serializes ownership of capture services that may hold mapped model files.
final class OfflineVoiceRuntimeOwner {
  VoiceCaptureLifecycleService? _current;
  Future<void> _releaseBarrier = Future<void>.value();

  Future<void> adopt(VoiceCaptureLifecycleService service) {
    if (identical(_current, service)) return _releaseBarrier;
    final previous = _current;
    _current = service;
    if (previous != null) _queueRelease(previous);
    return _releaseBarrier;
  }

  Future<void> release(VoiceCaptureLifecycleService service) {
    if (!identical(_current, service)) return _releaseBarrier;
    _current = null;
    _queueRelease(service);
    return _releaseBarrier;
  }

  Future<void> releaseAll() {
    final current = _current;
    _current = null;
    if (current != null) _queueRelease(current);
    return _releaseBarrier;
  }

  void _queueRelease(VoiceCaptureLifecycleService service) {
    _releaseBarrier = _releaseBarrier.then(
      (_) => Future<void>.sync(service.dispose),
    );
  }
}

final offlineVoiceRuntimeOwnerProvider = Provider<OfflineVoiceRuntimeOwner>(
  (_) => OfflineVoiceRuntimeOwner(),
);

final offlineSttModelTierProvider =
    NotifierProvider<OfflineSttModelTierController, OfflineSttModelTier>(
      OfflineSttModelTierController.new,
    );

final offlineSttPreferencesLoaderProvider =
    Provider<Future<SharedPreferences> Function()>(
      (_) => SharedPreferences.getInstance,
    );

final class OfflineSttModelTierController
    extends Notifier<OfflineSttModelTier> {
  static const _preferenceKey = 'wing.voice.offline_stt_tier';
  int _generation = 0;
  bool _loaded = false;

  @override
  OfflineSttModelTier build() {
    unawaited(_load());
    return OfflineSttModelTier.recommended;
  }

  Future<void> _load() async {
    final generation = _generation;
    final prefs = await ref.read(offlineSttPreferencesLoaderProvider)();
    if (!ref.mounted || generation != _generation) return;
    final saved = prefs.getString(_preferenceKey);
    state = OfflineSttModelTier.values.firstWhere(
      (tier) => tier.name == saved,
      orElse: () => OfflineSttModelTier.recommended,
    );
    _loaded = true;
  }

  Future<void> setTier(OfflineSttModelTier tier) async {
    if (_loaded && tier == state) return;
    _generation += 1;
    final generation = _generation;
    state = tier;
    final prefs = await ref.read(offlineSttPreferencesLoaderProvider)();
    await prefs.setString(_preferenceKey, tier.name);
    if (ref.mounted && generation == _generation) _loaded = true;
  }
}

enum OfflineSttPackStatus {
  checking,
  absent,
  installing,
  installed,
  deleting,
  error,
}

final class OfflineSttPackInstallation {
  const OfflineSttPackInstallation({required this.provenance});

  final String provenance;
}

final class OfflineSttPackState {
  const OfflineSttPackState({
    required this.status,
    this.provenance,
    this.message,
    this.receivedBytes,
    this.totalBytes,
  });

  const OfflineSttPackState.checking()
    : this(status: OfflineSttPackStatus.checking);

  final OfflineSttPackStatus status;
  final String? provenance;
  final String? message;
  final int? receivedBytes;
  final int? totalBytes;

  double? get progress => switch ((receivedBytes, totalBytes)) {
    (final received?, final total?) when total > 0 => received / total,
    _ => null,
  };

  bool get isBusy =>
      status == OfflineSttPackStatus.checking ||
      status == OfflineSttPackStatus.installing ||
      status == OfflineSttPackStatus.deleting;
}

abstract interface class OfflineSttPackRepository {
  Future<OfflineSttPackInstallation?> installedPack();

  Future<OfflineSttPackInstallation> install();

  Future<void> delete();
}

abstract interface class OfflineSttPackProgressRepository
    implements OfflineSttPackRepository {
  Future<OfflineSttPackInstallation> installWithProgress(
    VoiceModelPackProgressCallback onProgress,
  );
}

final class DefaultOfflineSttPackRepository
    implements OfflineSttPackProgressRepository {
  DefaultOfflineSttPackRepository({
    this.tier = OfflineSttModelTier.recommended,
  });

  final OfflineSttModelTier tier;
  Future<VoiceModelPackInstaller>? _installer;

  VoiceModelPackManifest get _manifest => offlineSttManifestForTier(tier);

  Future<VoiceModelPackInstaller> get _resolvedInstaller =>
      _installer ??= createDefaultVoiceModelPackInstaller();

  @override
  Future<OfflineSttPackInstallation?> installedPack() async {
    final installer = await _resolvedInstaller;
    final installed = await installer.installedPack(_manifest);
    if (installed == null) return null;
    return OfflineSttPackInstallation(provenance: installed.provenance);
  }

  @override
  Future<OfflineSttPackInstallation> install() => installWithProgress((_) {});

  @override
  Future<OfflineSttPackInstallation> installWithProgress(
    VoiceModelPackProgressCallback onProgress,
  ) async {
    final installer = await _resolvedInstaller;
    final installed = await installer.install(
      _manifest,
      onProgress: onProgress,
    );
    return OfflineSttPackInstallation(provenance: installed.provenance);
  }

  @override
  Future<void> delete() async {
    final installer = await _resolvedInstaller;
    await installer.delete(_manifest.packId, _manifest.version);
  }
}

final offlineSttPackRepositoryProvider = Provider<OfflineSttPackRepository>(
  (ref) => DefaultOfflineSttPackRepository(
    tier: ref.watch(offlineSttModelTierProvider),
  ),
);

final offlineSttPackControllerProvider =
    NotifierProvider<OfflineSttPackController, OfflineSttPackState>(
      OfflineSttPackController.new,
    );

final class OfflineSttPackController extends Notifier<OfflineSttPackState> {
  late OfflineSttPackRepository _repository;
  int _generation = 0;

  @override
  OfflineSttPackState build() {
    _repository = ref.watch(offlineSttPackRepositoryProvider);
    unawaited(refresh());
    return const OfflineSttPackState.checking();
  }

  Future<void> refresh() async {
    final generation = ++_generation;
    state = const OfflineSttPackState.checking();
    try {
      final installed = await _repository.installedPack();
      if (generation != _generation) return;
      state = installed == null
          ? const OfflineSttPackState(status: OfflineSttPackStatus.absent)
          : OfflineSttPackState(
              status: OfflineSttPackStatus.installed,
              provenance: installed.provenance,
            );
    } catch (_) {
      if (generation == _generation) {
        state = const OfflineSttPackState(
          status: OfflineSttPackStatus.error,
          message: 'The offline speech pack could not be checked.',
        );
      }
    }
  }

  Future<void> install() async {
    final generation = ++_generation;
    state = const OfflineSttPackState(status: OfflineSttPackStatus.installing);
    try {
      final repository = _repository;
      final installed = repository is OfflineSttPackProgressRepository
          ? await repository.installWithProgress((progress) {
              if (generation != _generation) return;
              state = OfflineSttPackState(
                status: OfflineSttPackStatus.installing,
                receivedBytes: progress.receivedBytes,
                totalBytes: progress.totalBytes,
              );
            })
          : await repository.install();
      if (generation != _generation) return;
      state = OfflineSttPackState(
        status: OfflineSttPackStatus.installed,
        provenance: installed.provenance,
      );
    } catch (_) {
      if (generation == _generation) {
        state = const OfflineSttPackState(
          status: OfflineSttPackStatus.error,
          message: 'The offline speech pack could not be installed.',
        );
      }
    }
  }

  Future<void> delete() async {
    final generation = ++_generation;
    state = const OfflineSttPackState(status: OfflineSttPackStatus.deleting);
    try {
      await ref.read(offlineVoiceRuntimeOwnerProvider).releaseAll();
      await _repository.delete();
      if (generation == _generation) {
        state = const OfflineSttPackState(status: OfflineSttPackStatus.absent);
      }
    } catch (_) {
      if (generation == _generation) {
        state = const OfflineSttPackState(
          status: OfflineSttPackStatus.error,
          message: 'The offline speech pack could not be removed.',
        );
      }
    }
  }
}
