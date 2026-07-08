import 'package:flutter/services.dart';

import '../../../../core/protocol/voice_unavailable_reason.dart';
import 'voice_capture_platform.dart';

class DeviceSpeechRecognitionDiagnostics {
  const DeviceSpeechRecognitionDiagnostics({
    required this.recognitionServiceCount,
    this.microphonePermissionGranted,
    this.recognitionServices = const <String>[],
  });

  final int recognitionServiceCount;
  final bool? microphonePermissionGranted;
  final List<String> recognitionServices;

  bool get hasRecognitionService => recognitionServiceCount > 0;
}

class VoiceCaptureReadiness {
  const VoiceCaptureReadiness._({
    required this.available,
    required this.unavailableReason,
    this.diagnostics,
  });

  const VoiceCaptureReadiness.available({
    DeviceSpeechRecognitionDiagnostics? diagnostics,
  }) : this._(
         available: true,
         unavailableReason: null,
         diagnostics: diagnostics,
       );

  const VoiceCaptureReadiness.unavailable(
    String reason, {
    DeviceSpeechRecognitionDiagnostics? diagnostics,
  }) : this._(
         available: false,
         unavailableReason: reason,
         diagnostics: diagnostics,
       );

  final bool available;
  final String? unavailableReason;
  final DeviceSpeechRecognitionDiagnostics? diagnostics;
}

abstract interface class DeviceSpeechRecognitionDiagnosticsProbe {
  Future<DeviceSpeechRecognitionDiagnostics> read();
}

class MethodChannelDeviceSpeechRecognitionDiagnosticsProbe
    implements DeviceSpeechRecognitionDiagnosticsProbe {
  const MethodChannelDeviceSpeechRecognitionDiagnosticsProbe({
    MethodChannel channel = _defaultChannel,
  }) : this._(channel);

  const MethodChannelDeviceSpeechRecognitionDiagnosticsProbe._(this._channel);

  static const _defaultChannel = MethodChannel(
    'com.trebuchetdynamics.navivox/device_speech',
  );

  final MethodChannel _channel;

  @override
  Future<DeviceSpeechRecognitionDiagnostics> read() async {
    final raw = await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'diagnostics',
    );
    final map = raw ?? const <dynamic, dynamic>{};
    return DeviceSpeechRecognitionDiagnostics(
      recognitionServiceCount: _intValue(map['recognitionServiceCount']),
      microphonePermissionGranted: map['microphonePermissionGranted'] as bool?,
      recognitionServices: _stringList(map['recognitionServices']),
    );
  }
}

Future<VoiceCaptureReadiness> checkDefaultVoiceCaptureReadiness({
  VoiceCapturePlatform? platform,
  DeviceSpeechRecognitionDiagnosticsProbe? diagnosticsProbe,
}) async {
  final effectivePlatform = platform ?? currentVoiceCapturePlatform();
  if (!effectivePlatform.isAndroid) {
    final supported =
        effectivePlatform.isIOS ||
        effectivePlatform.isMacOS ||
        effectivePlatform.isWindows ||
        effectivePlatform.isWeb;
    return supported
        ? const VoiceCaptureReadiness.available()
        : const VoiceCaptureReadiness.unavailable(deviceSttUnavailableReason);
  }

  try {
    final diagnostics =
        await (diagnosticsProbe ??
                const MethodChannelDeviceSpeechRecognitionDiagnosticsProbe())
            .read();
    if (!diagnostics.hasRecognitionService) {
      return VoiceCaptureReadiness.unavailable(
        deviceSttUnavailableReason,
        diagnostics: diagnostics,
      );
    }
    return VoiceCaptureReadiness.available(diagnostics: diagnostics);
  } catch (_) {
    return const VoiceCaptureReadiness.unavailable(deviceSttUnavailableReason);
  }
}

int _intValue(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return 0;
}

List<String> _stringList(Object? value) {
  if (value is Iterable) {
    return value.whereType<String>().toList(growable: false);
  }
  return const <String>[];
}
