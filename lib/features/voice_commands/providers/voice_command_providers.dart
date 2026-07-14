import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateProvider;
import 'package:path_provider/path_provider.dart';
import 'package:pocket_speech/pocket_speech.dart' show KittenCatalog;

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

/// The candidate TTS voice names, sourced from whichever backend is
/// currently active and cached by ordinary FutureProvider semantics. The
/// list normally doesn't change while the app is running, but it CAN come
/// back empty (flutter_tts cold start on some Android OEM engines; a Kokoro
/// voice pack that hasn't finished installing) — callers that observe an
/// empty list should invalidate this provider so the next read retries
/// instead of being stuck with the empty cache for the whole session. A
/// query failure (unsupported platform, cold-starting engine, unreadable
/// voices.json) degrades to an empty list rather than surfacing an error
/// the router has no way to act on.
///
/// Priority, watching the settings selects that must invalidate this
/// provider when they change:
/// 1. Pocket Speech enabled + Kitten model ⇒ the static Kitten catalog
///    names (proper-cased, matching what `KittenCatalog.supportsVoice`
///    expects — the validator hands back original-cased candidates).
/// 2. Pocket Speech enabled + Kokoro model ⇒ the top-level keys of the
///    active voice pack's `voices.json`.
/// 3. Pocket Speech disabled ⇒ the flutter_tts device voice list (today's
///    behavior, unchanged).
final ttsVoiceNamesProvider = FutureProvider<List<String>>((ref) async {
  final pocketEnabled = ref.watch(
    navivoxVoiceSettingsProvider.select((s) => s.pocketSpeechTtsEnabled),
  );
  final pocketModel = ref.watch(
    navivoxVoiceSettingsProvider.select((s) => s.pocketSpeechModel),
  );
  final kokoroVoicesPath = ref.watch(
    navivoxVoiceSettingsProvider.select(
      (s) => s.pocketSpeechVoicePack?.voicesPath,
    ),
  );

  if (pocketEnabled) {
    switch (pocketModel) {
      case PocketSpeechModel.kitten:
        return KittenCatalog.voices;
      case PocketSpeechModel.kokoro:
        return _kokoroVoiceNames(kokoroVoicesPath);
    }
  }

  try {
    return await PluginFlutterTtsEngine().voiceNames();
  } catch (_) {
    return const [];
  }
});

/// Reads the Kokoro voice pack's `voices.json` and returns its top-level
/// keys as voice names. Missing/unreadable/malformed content degrades to an
/// empty list — same non-caching-a-failure contract as the flutter_tts path
/// above (an empty [FutureProvider] result is not an error, so the existing
/// empty-retry rule in `voiceCommandRouterProvider` still applies).
///
/// The read + decode + key extraction runs in [Isolate.run]: Kokoro's
/// voices.json embeds full float32 style vectors and can be tens of MB, so
/// decoding it on the main isolate would visibly jank the UI on every
/// backend switch. The closure captures only the path string (isolate
/// entrypoints must not capture unsendable state like `ref` or plugin
/// handles), and only the small key list crosses back.
Future<List<String>> _kokoroVoiceNames(String? voicesPath) async {
  if (voicesPath == null) return const [];
  try {
    return await Isolate.run(() => _readVoiceNamesSync(voicesPath));
  } catch (_) {
    return const [];
  }
}

/// Isolate entrypoint for [_kokoroVoiceNames]; must stay top-level (or
/// static) so it can't accidentally close over unsendable state.
List<String> _readVoiceNamesSync(String voicesPath) {
  final decoded = jsonDecode(File(voicesPath).readAsStringSync());
  if (decoded is! Map) return const [];
  return decoded.keys.map((key) => key.toString()).toList();
}

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
    contextProvider: () {
      final voiceNames = ref.read(ttsVoiceNamesProvider).value ?? const [];
      if (voiceNames.isEmpty) {
        // Cold-start guard: some Android OEM TTS engines report no voices
        // until they finish initializing. Don't let an empty first result
        // stick around for the whole session — invalidate now so the NEXT
        // route re-queries the plugin instead of reusing the empty cache.
        ref.invalidate(ttsVoiceNamesProvider);
      }
      return VoiceCommandContext(
        sessionTitles: [
          for (final session in ref.read(hermesChannelProvider).state.sessions)
            if (session.title != null) session.title!,
        ],
        voiceNames: voiceNames,
      );
    },
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
