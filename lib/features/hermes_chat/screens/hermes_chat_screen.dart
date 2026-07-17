import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/hermes/channel/hermes_channel.dart';
import '../../../core/hermes/models/hermes_capabilities.dart';
import '../../../core/hermes/models/hermes_chat_turn.dart';
import '../../../core/hermes/models/hermes_health.dart';
import '../../../core/hermes/models/hermes_job.dart';
import '../../../core/hermes/models/hermes_session.dart';
import '../../../core/hermes/policy/hermes_surface_readiness.dart';
import '../../../core/hermes/policy/hermes_endpoint_security.dart';
import '../../../core/hermes/policy/hermes_transport_policy.dart';
import '../../../core/hermes/setup/hermes_endpoint_store.dart';
import '../../../l10n/app_localizations.dart';
import '../../../router/routes/app_routes.dart';
import '../../agents/providers/profile_selection_provider.dart';
import '../../../shared/voice/voice_capture_service.dart';
import '../../settings/providers/voice_settings_provider.dart';
import '../../voice/services/platform/default_voice_capture_service.dart';
import '../../voice/services/tts/text_to_speech_service.dart';
import '../../voice_commands/models/voice_command.dart';
import '../../voice_commands/providers/voice_command_providers.dart';
import '../../voice_commands/widgets/voice_command_chip.dart';
import '../controllers/hermes_voice_input_controller.dart';
import '../diagnostics/hermes_diagnostics_export.dart';
import '../providers/hermes_channel_provider.dart';
import '../widgets/hermes_rich_text.dart';

part 'widgets/hermes_chat_error.dart';
part 'widgets/hermes_chat_sessions.dart';
part 'widgets/hermes_chat_status.dart';
part 'widgets/hermes_chat_timeline.dart';
part 'state/hermes_chat_lifecycle.dart';
part 'state/hermes_chat_layout.dart';
part 'state/hermes_chat_connection.dart';
part 'state/hermes_chat_session_actions.dart';
part 'state/hermes_chat_message_flow.dart';
part 'state/hermes_chat_voice_commands.dart';

/// Voice-capture/TTS services for the Hermes chat screen.
final hermesVoiceCaptureServiceProvider = Provider<VoiceCaptureService?>(
  (_) => createDefaultVoiceCaptureService(),
);

final hermesTextToSpeechServiceProvider = Provider<TextToSpeechService?>((ref) {
  final settings = ref.watch(wingVoiceSettingsProvider);
  final service =
      settings.pocketSpeechTtsEnabled && settings.pocketSpeechVoicePackReady
      ? createPocketSpeechTextToSpeechService(
          enabled: true,
          voicePack: settings.pocketSpeechVoicePack!,
          settings: () => ref.read(wingVoiceSettingsProvider),
        )
      : createDefaultTextToSpeechService(
          settings: () => ref.read(wingVoiceSettingsProvider),
        );
  if (service != null) {
    ref.onDispose(() => unawaited(service.dispose()));
  }
  return service;
});

const _hermesBaseUrlHint =
    'Local desktop/Linux/Windows/iOS simulator: http://127.0.0.1:8642\n'
    'Android emulator: http://10.0.2.2:8642\n'
    'Physical device: LAN/VPN/Tailscale URL';
const _maxQueuedFollowUps = 5;
const _configuredHermesBaseUrl = String.fromEnvironment('WING_HERMES_BASE_URL');

bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;
String get _defaultHermesBaseUrl => _configuredHermesBaseUrl;

bool _isValidHermesBaseUrl(String value) {
  final uri = Uri.tryParse(value.trim());
  return uri != null &&
      (uri.scheme == 'http' || uri.scheme == 'https') &&
      uri.host.isNotEmpty;
}

/// Native Hermes Agent chat/session screen: manual connect, session list,
/// streamed transcript, text composer, and continuous voice. See
/// docs/adr/0007-native-hermes-channel-not-wing-channel-adapter.md.
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
  final _baseUrlController = TextEditingController(text: _defaultHermesBaseUrl);
  final _apiKeyController = TextEditingController();
  final _profileLabelController = TextEditingController();
  final _composerController = TextEditingController();
  final _transcriptScrollController = ScrollController();
  late final HermesVoiceInputController _voiceInputController;

  HermesChannel? _subscribed;
  late final ProviderSubscription<HermesChannel> _channelProviderSubscription;
  StreamSubscription<HermesApprovalRequest>? _approvalSubscription;
  String? _queuedFollowUpError;
  final Queue<_QueuedFollowUp> _queuedFollowUps = Queue<_QueuedFollowUp>();
  final Queue<HermesApprovalRequest> _pendingApprovals = Queue();
  String? _answeringApprovalId;
  String? _approvalSessionId;
  int _connectAttemptId = 0;
  bool _reconnectingOnResume = false;
  bool _obscureApiKey = true;
  late Future<List<HermesEndpointConfig>> _endpointProfilesFuture;

  // Voice-command routing (see docs/superpowers/plans/2026-07-13-needle-router.md
  // Task 10): at most one confirm-tier chip is shown at a time, and the
  // suspension hint fires once per screen lifetime.
  VoiceRouteResult? _pendingVoiceCommand;
  bool _pendingVoiceCommandAutoSend = false;
  bool _suspensionNoticeShown = false;
  late final VoiceCaptureHooks _voiceCaptureHooks;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _baseUrlController.addListener(_onConnectionFormChanged);
    _composerController.addListener(_onComposerChanged);
    _voiceInputController = HermesVoiceInputController(
      channel: () => ref.read(hermesChannelProvider),
      captureService: () =>
          widget.voiceCaptureServiceOverride ??
          ref.read(hermesVoiceCaptureServiceProvider),
      textToSpeechService: () =>
          widget.textToSpeechServiceOverride ??
          ref.read(hermesTextToSpeechServiceProvider),
      settings: () => ref.read(wingVoiceSettingsProvider),
      onDraft: _appendVoiceDraft,
      routeTranscript: _routeTranscript,
      onRoutedCommand: _onRoutedCommand,
    )..addListener(_onVoiceInputChanged);
    _voiceCaptureHooks = ref.read(voiceCaptureHooksProvider);
    _voiceCaptureHooks.onStop = () =>
        _voiceInputController.pause('Stopped by voice command.');
    _voiceCaptureHooks.onStart = () =>
        unawaited(_voiceInputController.enableContinuous());
    _channelProviderSubscription = ref.listenManual<HermesChannel>(
      hermesChannelProvider,
      (_, channel) => _subscribeToChannel(channel),
      fireImmediately: true,
    );
    _endpointProfilesFuture = _loadEndpointProfiles();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Unbind the voice-capture hooks so a stop/start command dispatched
    // after this screen is gone cannot reach a disposed controller.
    _voiceCaptureHooks.onStop = () {};
    _voiceCaptureHooks.onStart = () {};
    _channelProviderSubscription.close();
    _voiceInputController.removeListener(_onVoiceInputChanged);
    _voiceInputController.dispose();
    _subscribed?.removeListener(_onChannelChanged);
    _approvalSubscription?.cancel();
    _baseUrlController.removeListener(_onConnectionFormChanged);
    _composerController.removeListener(_onComposerChanged);
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    _profileLabelController.dispose();
    _composerController.dispose();
    _transcriptScrollController.dispose();
    super.dispose();
  }

  void _onConnectionFormChanged() {
    if (mounted) setState(() {});
  }

  void _onComposerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_reconnectAfterResumeIfRecoverable());
    } else {
      _voiceInputController.pause(
        'Continuous voice paused while Hermes Wing is not in the foreground.',
      );
    }
  }

  void _onVoiceInputChanged() {
    if (mounted) setState(() {});
  }

  void _appendVoiceDraft(String transcript) {
    final existing = _composerController.text.trimRight();
    final draft = existing.isEmpty ? transcript : '$existing $transcript';
    _composerController.value = TextEditingValue(
      text: draft,
      selection: TextSelection.collapsed(offset: draft.length),
    );
  }

  void _setState(VoidCallback fn) => setState(fn);

  /// Compact Chat-header control (near the session controls) that shows the
  /// client-selected agent and opens the switcher. The label seeds the default
  /// agent when nothing is selected yet, purely for display.
  Widget _buildProfileSwitcher(
    BuildContext context,
    HermesChannel channel,
    HermesChannelState state,
  ) {
    final strings = AppLocalizations.of(context);
    final selectedId = effectiveSelectedProfileId(state);
    HermesProfile? selected;
    for (final profile in state.profiles) {
      if (profile.id == selectedId) {
        selected = profile;
        break;
      }
    }
    final label = selected == null || selected.displayName.isEmpty
        ? (selectedId ?? strings.switchAgent)
        : selected.displayName;
    return TextButton.icon(
      key: const ValueKey('hermes-profile-switcher'),
      onPressed: () => _showProfileSwitcher(context, channel, state),
      icon: const Icon(Icons.support_agent_outlined),
      label: Text(
        _safeHermesUiPreview(label, maxLength: 24),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Future<void> _showProfileSwitcher(
    BuildContext context,
    HermesChannel channel,
    HermesChannelState state,
  ) async {
    final strings = AppLocalizations.of(context);
    final selectedId = effectiveSelectedProfileId(state);
    final chosen = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Semantics(
                header: true,
                child: Text(
                  strings.switchAgentTitle,
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
              ),
            ),
            for (final profile in state.profiles)
              ListTile(
                leading: Icon(
                  profile.id == selectedId
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                ),
                title: Text(
                  _safeHermesUiPreview(
                    profile.displayName.isEmpty
                        ? profile.id
                        : profile.displayName,
                    maxLength: 64,
                  ),
                ),
                subtitle: Text(strings.agentStableId(profile.id)),
                selected: profile.id == selectedId,
                onTap: () => Navigator.of(sheetContext).pop(profile.id),
              ),
          ],
        ),
      ),
    );
    if (chosen == null || !context.mounted) return;
    await _switchProfile(context, channel, chosen);
  }

  Future<void> _switchProfile(
    BuildContext context,
    HermesChannel channel,
    String profileId,
  ) async {
    if (profileId == effectiveSelectedProfileId(channel.state)) return;
    // Switching agents changes the client-local profile context. Clear state
    // that belonged to the prior profile before the refresh lands: stale
    // pending approvals, an answering-approval marker, any pending voice
    // command, and continuous voice capture. The transcript itself is replaced
    // by the profile-scoped session refresh inside selectProfile, so nothing
    // from the prior profile is retained here.
    _voiceInputController.pause(
      'Continuous voice paused while switching agents.',
    );
    setState(() {
      _pendingApprovals.clear();
      _answeringApprovalId = null;
      _pendingVoiceCommand = null;
      _pendingVoiceCommandAutoSend = false;
    });
    try {
      await channel.selectProfile(profileId);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(
              context,
            ).switchAgentFailed(_safeHermesUiError(error)),
          ),
        ),
      );
    }
  }

  void _subscribeToChannel(HermesChannel channel) {
    if (identical(_subscribed, channel)) return;
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
    _onChannelChanged();
  }

  @override
  Widget build(BuildContext context) {
    final channel = ref.watch(hermesChannelProvider);
    final state = channel.state;
    final activeSession = state.activeSession;
    final compactAppBar = MediaQuery.sizeOf(context).width < 480;

    ref.listen<String?>(voiceCommandNoticeProvider, (_, notice) {
      if (notice == null) return;
      ScaffoldMessenger.maybeOf(
        context,
      )?.showSnackBar(SnackBar(content: Text(notice)));
      ref.read(voiceCommandNoticeProvider.notifier).state = null;
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _safeHermesUiPreview(activeSession?.title ?? 'Hermes', maxLength: 96),
        ),
        actions: [
          if (state.isConnected) ...[
            if (state.profiles.isNotEmpty)
              _buildProfileSwitcher(context, channel, state),
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
            if (compactAppBar)
              PopupMenuButton<String>(
                key: const ValueKey('hermes-more-actions-button'),
                tooltip: 'More actions',
                onSelected: (action) {
                  if (action == 'diagnostics') {
                    _showDiagnosticsDialog(context, state);
                  } else {
                    unawaited(_confirmDisconnect(context, channel));
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'diagnostics',
                    child: ListTile(
                      leading: Icon(Icons.info_outline),
                      title: Text('Diagnostics'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'disconnect',
                    child: ListTile(
                      leading: Icon(Icons.logout_outlined),
                      title: Text('Disconnect'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              )
            else ...[
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
                onPressed: () =>
                    unawaited(_confirmDisconnect(context, channel)),
              ),
            ],
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
