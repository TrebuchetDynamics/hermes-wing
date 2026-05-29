import 'src/voice_capture_platform_stub.dart'
    if (dart.library.io) 'src/voice_capture_platform_io.dart'
    as platform;

class VoiceCapturePlatform {
  const VoiceCapturePlatform({required this.isAndroid});

  final bool isAndroid;
}

VoiceCapturePlatform currentVoiceCapturePlatform() {
  return VoiceCapturePlatform(isAndroid: platform.isAndroid);
}
