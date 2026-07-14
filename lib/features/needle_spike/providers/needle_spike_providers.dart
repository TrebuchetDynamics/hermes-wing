import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/voice/voice_capture_service.dart';
import '../../voice/services/platform/default_voice_capture_service.dart';
import '../../voice_commands/providers/voice_command_providers.dart';
import '../services/needle_spike_service.dart';

/// Aliased onto the shared `voice_commands` providers so the app has ONE
/// Needle engine instance and ONE install-service instance app-wide,
/// whether reached through the real feature or this eval screen.
final needleEngineProvider = voiceCommandEngineProvider;
final needleInstallServiceProvider = voiceCommandInstallServiceProvider;

final needleSpikeServiceProvider = Provider<NeedleSpikeService>((ref) {
  return NeedleSpikeService(engine: ref.watch(needleEngineProvider));
});

final needleVoiceCaptureFactoryProvider =
    Provider<VoiceCaptureService? Function()>((ref) {
      return createDefaultVoiceCaptureService;
    });
