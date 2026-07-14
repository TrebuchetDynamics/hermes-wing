import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateProvider;
import 'package:path_provider/path_provider.dart';

import '../../../router/providers/app_router.dart';
import '../../hermes_chat/providers/hermes_channel_provider.dart';
import '../../settings/providers/voice_settings_provider.dart';
import '../../voice/services/tts/text_to_speech_service.dart';
import '../core/needle_engine.dart';
import '../core/needle_model_install_service.dart';
import '../services/voice_command_dispatcher.dart';
import '../services/voice_command_router.dart';
import '../services/voice_command_validator.dart';

/// Root-scoped: the loaded model stays resident for the whole app session,
/// and [NeedleEngine.unload] runs only at ProviderContainer teardown — never
/// when a screen that reads the router is popped.
final voiceCommandEngineProvider = Provider<NeedleEngineApi>((ref) {
  final engine = NeedleEngine();
  ref.onDispose(engine.unload);
  return engine;
});

/// FutureProvider because resolving the app-support directory is async.
final voiceCommandInstallServiceProvider =
    FutureProvider<NeedleModelInstallService>((ref) async {
      final support = await getApplicationSupportDirectory();
      return NeedleModelInstallService(supportDirectory: support);
    });

/// The installed TTS voice names, queried once via `getVoices` and cached by
/// ordinary FutureProvider semantics — the list doesn't change while the app
/// is running. A query failure (unsupported platform, cold-starting engine)
/// degrades to an empty list rather than surfacing an error the router has
/// no way to act on.
final ttsVoiceNamesProvider = FutureProvider<List<String>>((ref) async {
  try {
    return await PluginFlutterTtsEngine().voiceNames();
  } catch (_) {
    return const [];
  }
});

/// Null when the feature toggle is off — the seam stays cold and today's
/// behavior is untouched (augment-only guarantee).
final voiceCommandRouterProvider = Provider<VoiceCommandRouter?>((ref) {
  final enabled = ref.watch(
    navivoxVoiceSettingsProvider.select((s) => s.voiceCommandsEnabled),
  );
  if (!enabled) return null;
  final engine = ref.watch(voiceCommandEngineProvider);
  return VoiceCommandRouter(
    engine: engine,
    modelDirProvider: () async {
      final install = await ref.read(voiceCommandInstallServiceProvider.future);
      return install.installedModelDir();
    },
    contextProvider: () => VoiceCommandContext(
      sessionTitles: [
        for (final session in ref.read(hermesChannelProvider).state.sessions)
          if (session.title != null) session.title!,
      ],
      voiceNames: ref.read(ttsVoiceNamesProvider).value ?? const [],
    ),
  );
});

/// Adapts the real settings controller to the dispatcher's minimal sink
/// interface so the dispatcher never needs a live Riverpod `Notifier`.
class _NavivoxVoiceSettingsSink implements VoiceCommandSettingsSink {
  _NavivoxVoiceSettingsSink(this._controller);

  final NavivoxVoiceSettingsController _controller;

  @override
  void setContinuousVoiceEnabled(bool enabled) =>
      _controller.setContinuousVoiceEnabled(enabled);

  @override
  void setSpeechRate(double rate) => _controller.setSpeechRate(rate);

  @override
  void setTtsVoiceName(String? name) => _controller.setTtsVoiceName(name);
}

/// Last dispatched command's user-facing message. The chat screen (chip/
/// snackbar wiring) listens and clears it after showing a SnackBar.
final voiceCommandNoticeProvider = StateProvider<String?>((ref) => null);

/// Late-bound hooks into whichever screen currently owns the microphone.
/// `stop_voice_run`/`start_voice_run` need to reach into that screen's own
/// voice-capture controller, which this provider has no direct handle on.
/// Defaults are no-ops so the dispatcher is always safe to construct, even
/// before any screen has bound real callbacks.
class VoiceCaptureHooks {
  void Function() onStop = () {};
  void Function() onStart = () {};
}

final voiceCaptureHooksProvider = Provider<VoiceCaptureHooks>(
  (ref) => VoiceCaptureHooks(),
);

final voiceCommandDispatcherProvider = Provider<VoiceCommandDispatcher>((ref) {
  final hooks = ref.watch(voiceCaptureHooksProvider);
  return VoiceCommandDispatcher(
    channel: () => ref.read(hermesChannelProvider),
    // push (not go): a routed navigation should stack over whatever screen
    // triggered it — go() would replace the whole match stack and strand
    // the operator with no way back (same lesson as the Needle-spike debug
    // entry point in the settings screen).
    navigate: (path) => ref.read(routerProvider).push(path),
    settings: () => _NavivoxVoiceSettingsSink(
      ref.read(navivoxVoiceSettingsProvider.notifier),
    ),
    showNotice: (message) =>
        ref.read(voiceCommandNoticeProvider.notifier).state = message,
    stopVoiceCapture: () => hooks.onStop(),
    startVoiceCapture: () => hooks.onStart(),
  );
});
