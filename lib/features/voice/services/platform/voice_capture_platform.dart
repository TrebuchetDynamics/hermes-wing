import 'package:flutter/foundation.dart';

import 'src/voice_capture_platform_stub.dart'
    if (dart.library.io) 'src/voice_capture_platform_io.dart'
    as platform;

class VoiceCapturePlatform {
  const VoiceCapturePlatform({
    required this.isAndroid,
    this.isIOS = false,
    this.isMacOS = false,
    this.isWindows = false,
    this.isWeb = false,
  });

  final bool isAndroid;
  final bool isIOS;
  final bool isMacOS;
  final bool isWindows;
  final bool isWeb;
}

VoiceCapturePlatform currentVoiceCapturePlatform() {
  return VoiceCapturePlatform(
    isAndroid: platform.isAndroid,
    isIOS: platform.isIOS,
    isMacOS: platform.isMacOS,
    isWindows: platform.isWindows,
    isWeb: kIsWeb,
  );
}
