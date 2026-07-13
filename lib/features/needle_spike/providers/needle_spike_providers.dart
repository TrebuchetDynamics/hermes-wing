import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../shared/voice/voice_capture_service.dart';
import '../../voice/services/platform/default_voice_capture_service.dart';
import '../services/needle_engine.dart';
import '../services/needle_model_install_service.dart';
import '../services/needle_spike_service.dart';

/// Deliberately root-scoped: the loaded model stays resident for the whole
/// app session, and [NeedleEngine.unload] runs only at ProviderContainer
/// teardown — not when the spike screen is popped.
final needleEngineProvider = Provider<NeedleEngineApi>((ref) {
  final engine = NeedleEngine();
  ref.onDispose(engine.unload);
  return engine;
});

/// FutureProvider because resolving the app-support directory is async.
/// The screen consumes it via `ref.read(needleInstallServiceProvider.future)`.
final needleInstallServiceProvider = FutureProvider<NeedleModelInstallService>((
  ref,
) async {
  final support = await getApplicationSupportDirectory();
  return NeedleModelInstallService(supportDirectory: support);
});

final needleSpikeServiceProvider = Provider<NeedleSpikeService>((ref) {
  return NeedleSpikeService(engine: ref.watch(needleEngineProvider));
});

final needleVoiceCaptureFactoryProvider =
    Provider<VoiceCaptureService? Function()>((ref) {
      return createDefaultVoiceCaptureService;
    });
