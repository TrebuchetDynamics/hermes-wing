import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kokorodart/kokorodart.dart';

import '../../../core/hermes/channel/hermes_channel.dart';
import '../../../core/hermes/models/hermes_capabilities.dart';
import '../../../core/hermes/models/hermes_chat_turn.dart';
import '../../../core/hermes/models/hermes_health.dart';
import '../../../core/hermes/models/hermes_job.dart';
import '../../../core/hermes/models/hermes_session.dart';
import '../../../core/hermes/policy/hermes_surface_readiness.dart';
import '../../../core/hermes/policy/hermes_transport_policy.dart';
import '../../../core/hermes/setup/hermes_endpoint_store.dart';
import '../../../core/protocol/voice/models/navivox_voice_run.dart';
import '../../../shared/voice/voice_capture_service.dart';
import '../controllers/hermes_voice_capture_flow.dart';
import '../../settings/providers/voice_settings_provider.dart';
import '../../voice/services/platform/default_voice_capture_service.dart';
import '../../voice/services/tts/text_to_speech_service.dart';
import '../controllers/hermes_continuous_voice_reply_policy.dart';
import '../controllers/hermes_voice_run_controller.dart';
import '../diagnostics/hermes_diagnostics_export.dart';
import '../providers/hermes_channel_provider.dart';

part 'widgets/hermes_chat_error.dart';
part 'widgets/hermes_chat_sessions.dart';
part 'widgets/hermes_chat_status.dart';
part 'widgets/hermes_chat_timeline.dart';
part 'state/hermes_chat_lifecycle.dart';
part 'state/hermes_chat_layout.dart';
part 'state/hermes_chat_connection.dart';
part 'state/hermes_chat_session_actions.dart';
part 'state/hermes_chat_message_flow.dart';

/// Voice-capture/TTS services for the Hermes chat screen.
final hermesVoiceCaptureServiceProvider = Provider<VoiceCaptureService?>(
  (_) => createDefaultVoiceCaptureService(),
);

final hermesTextToSpeechServiceProvider = Provider<TextToSpeechService?>((ref) {
  final settings = ref.watch(navivoxVoiceSettingsProvider);
  if (settings.kokoroTtsEnabled && settings.kokoroAssetsReady) {
    return createKokoroTextToSpeechService(
      enabled: true,
      config: KokoroDartConfig(
        modelAsset: settings.kokoroModelPath!,
        voicesAsset: settings.kokoroVoicesPath!,
      ),
    );
  }
  return createDefaultTextToSpeechService();
});

const _hermesBaseUrlHint =
    'Local desktop/Linux/Windows/iOS simulator: http://127.0.0.1:8642\n'
    'Android emulator: http://10.0.2.2:8642\n'
    'Physical device: LAN/VPN/Tailscale URL';
const _maxQueuedFollowUps = 5;

/// Native Hermes Agent chat/session screen: manual connect, session list,
/// streamed transcript, text composer, and continuous voice. See
/// docs/adr/0007-native-hermes-channel-not-navivox-channel-adapter.md.
class HermesChatScreen extends ConsumerStatefulWidget {
  const HermesChatScreen({
    this.voiceCaptureServiceOverride,
    this.textToSpeechServiceOverride,
    super.key,
  });

  final VoiceCaptureService? voiceCaptureServiceOverride;
  final TextToSpeechService? textToSpeechServiceOverride;

  @override
  ConsumerState<HermesChatScreen> createState() => _HermesChatScreenState();
}

class _HermesChatScreenState extends ConsumerState<HermesChatScreen>
    with WidgetsBindingObserver {
  final _baseUrlController = TextEditingController(
    text: 'http://127.0.0.1:8642',
  );
  final _apiKeyController = TextEditingController();
  final _composerController = TextEditingController();
  final _transcriptScrollController = ScrollController();
  final HermesVoiceRunController _voiceRunController =
      HermesVoiceRunController();

  HermesChannel? _subscribed;
  StreamSubscription<HermesApprovalRequest>? _approvalSubscription;
  bool _continuousVoiceEnabled = false;
  bool _capturing = false;
  String? _voiceError;
  String? _queuedFollowUpError;
  final Queue<_QueuedFollowUp> _queuedFollowUps = Queue<_QueuedFollowUp>();
  final Queue<HermesApprovalRequest> _pendingApprovals = Queue();
  String? _answeringApprovalId;
  String? _approvalSessionId;
  String? _lastSpokenTurnId;
  int _connectAttemptId = 0;
  bool _reconnectingOnResume = false;
  late Future<List<HermesEndpointConfig>> _endpointProfilesFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _endpointProfilesFuture = _loadEndpointProfiles();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscribed?.removeListener(_onChannelChanged);
    _approvalSubscription?.cancel();
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    _composerController.dispose();
    _transcriptScrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_reconnectAfterResumeIfRecoverable());
    }
  }

  void _setState(VoidCallback fn) => setState(fn);

  @override
  Widget build(BuildContext context) {
    final channel = ref.watch(hermesChannelProvider);
    if (!identical(_subscribed, channel)) {
      _subscribed?.removeListener(_onChannelChanged);
      channel.addListener(_onChannelChanged);
      _subscribed = channel;
      _pendingApprovals.clear();
      _answeringApprovalId = null;
      _approvalSessionId = channel.state.activeSessionId;
      unawaited(_approvalSubscription?.cancel());
      _approvalSubscription = channel.approvalRequests.listen((request) {
        if (mounted) setState(() => _enqueueApprovalRequest(request));
      });
    }
    final state = channel.state;
    final activeSession = state.activeSession;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _maybeContinueVoiceLoop(channel);
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _safeHermesUiPreview(activeSession?.title ?? 'Hermes', maxLength: 96),
        ),
        actions: [
          if (state.isConnected) ...[
            IconButton(
              key: const ValueKey('hermes-sessions-button'),
              tooltip: 'Sessions',
              icon: const Icon(Icons.view_list_outlined),
              onPressed: () => _showSessionsPanel(context, channel),
            ),
            if (_canCreateSession(state))
              IconButton(
                key: const ValueKey('hermes-new-session'),
                tooltip: 'New session',
                icon: const Icon(Icons.add_comment_outlined),
                onPressed: () => unawaited(_createSession(context, channel)),
              ),
            IconButton(
              key: const ValueKey('hermes-diagnostics-button'),
              tooltip: 'Diagnostics',
              icon: const Icon(Icons.info_outline),
              onPressed: () => _showDiagnosticsDialog(context, state),
            ),
            IconButton(
              key: const ValueKey('hermes-disconnect-button'),
              tooltip: 'Disconnect',
              icon: const Icon(Icons.logout_outlined),
              onPressed: () => unawaited(_confirmDisconnect(context, channel)),
            ),
          ],
        ],
      ),
      body: state.isConnected
          ? _buildChat(context, channel, state)
          : _buildConnectForm(context, channel, state),
    );
  }
}

class _QueuedFollowUp {
  const _QueuedFollowUp(this.text, this.sessionId);

  final String text;
  final String? sessionId;
}
