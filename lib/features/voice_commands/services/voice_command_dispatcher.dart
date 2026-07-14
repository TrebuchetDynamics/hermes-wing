import '../../../core/hermes/channel/hermes_channel.dart';
import '../../../router/app_routes.dart';
import '../models/voice_command.dart';

/// The three settings mutations a routed voice command may trigger. Kept as
/// a minimal interface (rather than depending on
/// `NavivoxVoiceSettingsController` directly) so the dispatcher never needs a
/// live Riverpod `Notifier` — a test double just implements these three
/// methods, and production code adapts the real controller to this shape.
abstract interface class VoiceCommandSettingsSink {
  void setContinuousVoiceEnabled(bool enabled);
  void setSpeechRate(double rate);
  void setTtsVoiceName(String? name);
}

/// Binds a validated [VoiceRouteResult] to the app services it augments.
/// Never rethrows: any failure below becomes a `showNotice` call so a bad
/// local-command execution can never surface as a crash or block the
/// (always-available) Hermes path. Notices never carry transcript content.
class VoiceCommandDispatcher {
  VoiceCommandDispatcher({
    required HermesChannel Function() channel,
    required void Function(String path) navigate,
    required VoiceCommandSettingsSink Function() settings,
    required void Function(String message) showNotice,
    required void Function() stopVoiceCapture,
    required void Function() startVoiceCapture,
    // Private fields behind public named parameters; an initializing formal
    // would force the parameters to be named `_channel` etc.
  }) : _channel = channel, // ignore: prefer_initializing_formals
       // ignore: prefer_initializing_formals
       _navigate = navigate,
       // ignore: prefer_initializing_formals
       _settings = settings,
       // ignore: prefer_initializing_formals
       _showNotice = showNotice,
       // ignore: prefer_initializing_formals
       _stopVoiceCapture = stopVoiceCapture,
       // ignore: prefer_initializing_formals
       _startVoiceCapture = startVoiceCapture;

  final HermesChannel Function() _channel;
  final void Function(String path) _navigate;
  final VoiceCommandSettingsSink Function() _settings;
  final void Function(String message) _showNotice;
  final void Function() _stopVoiceCapture;
  final void Function() _startVoiceCapture;

  Future<void> dispatch(VoiceRouteResult result) async {
    try {
      switch (result.command) {
        case VoiceCommandId.navigateToScreen:
          _navigate(
            result.args['screen'] == 'settings'
                ? AppRoutes.settings
                : AppRoutes.hermes,
          );
        case VoiceCommandId.showStatus:
          _showNotice(_connectionLine(_channel().state));
        case VoiceCommandId.stopVoiceRun:
          _stopVoiceCapture();
        case VoiceCommandId.startVoiceRun:
          _startVoiceCapture();
        case VoiceCommandId.toggleContinuousMode:
          final enabled = result.args['enabled'] as bool;
          _settings().setContinuousVoiceEnabled(enabled);
          _showNotice(
            enabled
                ? 'Continuous voice turned on.'
                : 'Continuous voice turned off.',
          );
        case VoiceCommandId.newSession:
          await _channel().createSession();
          _showNotice('Started a new session.');
        case VoiceCommandId.switchSession:
          await _switchSession(result);
        case VoiceCommandId.setTtsVoice:
          final voice = result.args['voice'] as String;
          _settings().setTtsVoiceName(voice);
          _showNotice('Voice set to "$voice".');
        case VoiceCommandId.setSpeechRate:
          final rate = result.args['rate'] as double;
          _settings().setSpeechRate(rate);
          _showNotice('Speech rate set to $rate.');
      }
    } catch (e) {
      _showNotice('Command failed: ${e.runtimeType}');
    }
  }

  Future<void> _switchSession(VoiceRouteResult result) async {
    final target = _normalizeTitle(result.args['session_name']);
    for (final session in _channel().state.sessions) {
      if (_normalizeTitle(session.title) == target) {
        await _channel().selectSession(session.id);
        return;
      }
    }
    _showNotice('Session no longer exists.');
  }

  static String _normalizeTitle(Object? value) =>
      '$value'.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  String _connectionLine(HermesChannelState state) {
    final connected = state.isConnected ? 'Connected' : 'Disconnected';
    final model = _modelName(state);
    return model == null ? connected : '$connected ($model)';
  }

  String? _modelName(HermesChannelState state) {
    final sessionModel = state.activeSession?.model?.trim();
    if (sessionModel != null && sessionModel.isNotEmpty) return sessionModel;
    if (state.models.isNotEmpty) return state.models.first;
    final capabilityModel = state.capabilities?.model.trim();
    if (capabilityModel != null && capabilityModel.isNotEmpty) {
      return capabilityModel;
    }
    return null;
  }
}
