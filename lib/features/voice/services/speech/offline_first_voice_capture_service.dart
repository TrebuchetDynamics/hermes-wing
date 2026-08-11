import 'dart:async';

import '../../../../shared/voice/voice_capture_service.dart';

typedef OfflineVoiceCaptureLoader = Future<VoiceCaptureService?> Function();

final class OfflineFirstVoiceCaptureCancelled implements Exception {
  const OfflineFirstVoiceCaptureCancelled();

  @override
  String toString() => 'OfflineFirstVoiceCaptureCancelled';
}

/// Selects an installed app-owned recognizer before capture starts and retains
/// the platform recognizer as a compatibility fallback.
///
/// It never restarts the microphone with the fallback after a local decoding
/// failure; doing so would silently record a second utterance. Instead, the
/// failed local backend is disabled for the next turn.
final class OfflineFirstVoiceCaptureService
    implements
        VoiceCaptureService,
        VoiceCaptureProgressService,
        VoiceCaptureProvenanceService,
        VoiceCaptureLifecycleService {
  OfflineFirstVoiceCaptureService({
    required OfflineVoiceCaptureLoader loadOffline,
    required VoiceCaptureService fallback,
  }) : this._(loadOffline, fallback);

  OfflineFirstVoiceCaptureService._(this._loadOffline, this._fallback);

  final OfflineVoiceCaptureLoader _loadOffline;
  final VoiceCaptureService _fallback;
  final _partials = StreamController<String>.broadcast(sync: true);
  Future<VoiceCaptureService?>? _offlineFuture;
  VoiceCaptureService? _loadedOffline;
  VoiceCaptureService? _activeDelegate;
  StreamSubscription<String>? _partialSubscription;
  int _generation = 0;
  int? _activeGeneration;
  bool _disposed = false;

  @override
  Stream<String> get partialTranscripts => _partials.stream;

  @override
  VoiceEngineProvenance get provenance {
    final service = _loadedOffline ?? _fallback;
    if (service is VoiceCaptureProvenanceService) {
      return (service as VoiceCaptureProvenanceService).provenance;
    }
    return const VoiceEngineProvenance(
      engine: 'Platform speech recognition',
      adapter: 'Wing voice capture',
      model: null,
      offlineRequested: true,
      appOwnedModel: false,
    );
  }

  Future<VoiceCaptureService?> _offline() {
    return _offlineFuture ??= Future<VoiceCaptureService?>.sync(_loadOffline)
        .then((service) async {
          if (_disposed) {
            if (service != null) await _disposeService(service);
            return null;
          }
          _loadedOffline = service;
          return service;
        })
        .catchError((Object _) => null);
  }

  @override
  Future<VoiceCapture> capture({required Duration timeout}) async {
    if (_disposed) throw StateError('Voice capture is disposed.');
    if (_activeGeneration != null) {
      throw StateError('Voice capture is already active.');
    }
    final generation = ++_generation;
    _activeGeneration = generation;

    final offline = await _offline();
    if (_activeGeneration != generation) {
      throw const OfflineFirstVoiceCaptureCancelled();
    }
    final delegate = offline ?? _fallback;
    _activeDelegate = delegate;
    if (delegate is VoiceCaptureProgressService) {
      final progress = delegate as VoiceCaptureProgressService;
      _partialSubscription = progress.partialTranscripts.listen((partial) {
        if (_activeGeneration == generation) _partials.add(partial);
      });
    }

    try {
      return await delegate.capture(timeout: timeout);
    } catch (_) {
      if (identical(delegate, offline)) {
        _loadedOffline = null;
        _offlineFuture = Future<VoiceCaptureService?>.value(null);
      }
      rethrow;
    } finally {
      if (_activeGeneration == generation) _activeGeneration = null;
      if (identical(_activeDelegate, delegate)) _activeDelegate = null;
      final subscription = _partialSubscription;
      _partialSubscription = null;
      await subscription?.cancel();
    }
  }

  @override
  Future<void> cancel() {
    _generation += 1;
    _activeGeneration = null;
    final delegate = _activeDelegate;
    _activeDelegate = null;
    final subscription = _partialSubscription;
    _partialSubscription = null;
    return Future.wait<void>([
      Future<void>.sync(() => delegate?.cancel() ?? Future<void>.value()),
      Future<void>.sync(() => subscription?.cancel() ?? Future<void>.value()),
    ]).then<void>((_) {});
  }

  Future<void> _disposeService(VoiceCaptureService service) {
    if (service is! VoiceCaptureLifecycleService) return Future<void>.value();
    return Future<void>.sync(
      () => (service as VoiceCaptureLifecycleService).dispose(),
    );
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    final loading = _offlineFuture;
    final loaded = _loadedOffline;
    _loadedOffline = null;
    try {
      await Future.wait<void>([
        Future<void>.sync(cancel),
        if (loaded != null) _disposeService(loaded),
        if (loading != null)
          loading.then<void>((service) async {
            if (service != null && !identical(service, loaded)) {
              await _disposeService(service);
            }
          }),
        _disposeService(_fallback),
      ]);
    } finally {
      await _partials.close();
    }
  }
}
