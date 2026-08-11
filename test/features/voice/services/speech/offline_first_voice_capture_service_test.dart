import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/voice/services/speech/offline_first_voice_capture_service.dart';
import 'package:wing/shared/voice/voice_capture_service.dart';

void main() {
  test(
    'uses platform fallback when verified offline pack is unavailable',
    () async {
      final fallback = _FakeCaptureService('platform result');
      final service = OfflineFirstVoiceCaptureService(
        loadOffline: () async => null,
        fallback: fallback,
      );

      final result = await service.capture(timeout: const Duration(seconds: 1));

      expect(result.transcript, 'platform result');
      expect(fallback.captureCalls, 1);
    },
  );

  test('uses installed offline service without touching fallback', () async {
    final local = _FakeCaptureService('offline result');
    final fallback = _FakeCaptureService('platform result');
    final service = OfflineFirstVoiceCaptureService(
      loadOffline: () async => local,
      fallback: fallback,
    );

    final result = await service.capture(timeout: const Duration(seconds: 1));

    expect(result.transcript, 'offline result');
    expect(local.captureCalls, 1);
    expect(fallback.captureCalls, 0);
  });

  test(
    'cancel during model load invalidates before fallback can start',
    () async {
      final loader = Completer<VoiceCaptureService?>();
      final fallback = _FakeCaptureService('must not start');
      final service = OfflineFirstVoiceCaptureService(
        loadOffline: () => loader.future,
        fallback: fallback,
      );

      final capture = service.capture(timeout: const Duration(seconds: 1));
      final cancellation = service.cancel();
      loader.complete(null);

      await expectLater(
        capture,
        throwsA(isA<OfflineFirstVoiceCaptureCancelled>()),
      );
      await cancellation;
      expect(fallback.captureCalls, 0);
    },
  );

  test(
    'dispose during model load releases resolved local and fallback',
    () async {
      final loader = Completer<VoiceCaptureService?>();
      final local = _FakeCaptureService('local');
      final fallback = _FakeCaptureService('fallback');
      final service = OfflineFirstVoiceCaptureService(
        loadOffline: () => loader.future,
        fallback: fallback,
      );

      final capture = service.capture(timeout: const Duration(seconds: 1));
      final captureExpectation = expectLater(
        capture,
        throwsA(isA<OfflineFirstVoiceCaptureCancelled>()),
      );
      final disposal = service.dispose();
      loader.complete(local);

      await disposal;
      await captureExpectation;
      expect(local.disposeCalls, 1);
      expect(fallback.disposeCalls, 1);
      await expectLater(
        service.capture(timeout: const Duration(seconds: 1)),
        throwsStateError,
      );
    },
  );
}

class _FakeCaptureService
    implements VoiceCaptureService, VoiceCaptureLifecycleService {
  _FakeCaptureService(this.transcript);

  final String transcript;
  int captureCalls = 0;
  int cancelCalls = 0;
  int disposeCalls = 0;

  @override
  Future<VoiceCapture> capture({required Duration timeout}) async {
    captureCalls += 1;
    return VoiceCapture(
      audio: Uint8List(0),
      transcript: transcript,
      duration: Duration.zero,
      confidence: 1,
    );
  }

  @override
  Future<void> cancel() async {
    cancelCalls += 1;
  }

  @override
  Future<void> dispose() async {
    disposeCalls += 1;
  }
}
