import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
import '../../../shared/voice/text_to_speech_service.dart';
import '../../../shared/voice/voice_capture_service.dart';
import '../../chat/voice/controllers/transcript_voice_capture_flow.dart';
import '../../voice/services/platform/default_voice_capture_service.dart';
import '../controllers/hermes_continuous_voice_reply_policy.dart';
import '../controllers/hermes_voice_run_controller.dart';
import '../diagnostics/hermes_diagnostics_export.dart';
import '../providers/hermes_channel_provider.dart';

/// Voice-capture/TTS services for the Hermes chat screen.
final hermesVoiceCaptureServiceProvider = Provider<VoiceCaptureService?>(
  (_) => createDefaultVoiceCaptureService(),
);

final hermesTextToSpeechServiceProvider = Provider<TextToSpeechService?>(
  (_) => null,
);

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

class _HermesChatScreenState extends ConsumerState<HermesChatScreen> {
  final _baseUrlController = TextEditingController(
    text: 'http://127.0.0.1:8642',
  );
  final _apiKeyController = TextEditingController();
  final _profileLabelController = TextEditingController();
  final _composerController = TextEditingController();
  final HermesVoiceRunController _voiceRunController =
      HermesVoiceRunController();

  HermesChannel? _subscribed;
  StreamSubscription<NavivoxApprovalRequest>? _approvalSubscription;
  bool _continuousVoiceEnabled = false;
  bool _capturing = false;
  String? _voiceError;
  String? _queuedFollowUpError;
  final Queue<_QueuedFollowUp> _queuedFollowUps = Queue<_QueuedFollowUp>();
  final Queue<NavivoxApprovalRequest> _pendingApprovals = Queue();
  String? _answeringApprovalId;
  String? _approvalSessionId;
  String? _lastSpokenTurnId;
  bool _hadActiveTurn = false;
  int _connectAttemptId = 0;
  late Future<List<HermesEndpointConfig>> _endpointProfilesFuture;

  @override
  void initState() {
    super.initState();
    _endpointProfilesFuture = _loadEndpointProfiles();
  }

  @override
  void dispose() {
    _subscribed?.removeListener(_onChannelChanged);
    _approvalSubscription?.cancel();
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    _profileLabelController.dispose();
    _composerController.dispose();
    super.dispose();
  }

  Future<List<HermesEndpointConfig>> _loadEndpointProfiles() =>
      ref.read(hermesEndpointStoreProvider).loadProfiles();

  void _refreshEndpointProfiles() {
    if (!mounted) return;
    setState(() {
      _endpointProfilesFuture = _loadEndpointProfiles();
    });
  }

  void _onChannelChanged() {
    final channel = _subscribed;
    if (channel != null) {
      final turnActive = _isTurnActive(channel.state);
      if (channel.state.isConnected) {
        final activeSessionId = channel.state.activeSessionId;
        if (_approvalSessionId != null &&
            _approvalSessionId != activeSessionId) {
          _pendingApprovals.clear();
          _answeringApprovalId = null;
        }
        _approvalSessionId = activeSessionId;
        _dropQueuedFollowUpsForMissingSessions(channel.state);
        if (_hadActiveTurn && !turnActive) {
          _pendingApprovals.clear();
          _answeringApprovalId = null;
        }
        _hadActiveTurn = turnActive;
        _sendQueuedFollowUpIfIdle(channel);
      } else {
        _queuedFollowUps.clear();
        _queuedFollowUpError = null;
        _pendingApprovals.clear();
        _answeringApprovalId = null;
        _approvalSessionId = null;
        _hadActiveTurn = false;
        _continuousVoiceEnabled = false;
        _voiceError = null;
        _stopSpeaking();
      }
    }
    if (mounted) setState(() {});
  }

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
      _hadActiveTurn = false;
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

  Widget _buildConnectForm(
    BuildContext context,
    HermesChannel channel,
    HermesChannelState state,
  ) {
    final connecting = state.status == HermesConnectionStatus.connecting;
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Connect to Hermes Agent',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                FutureBuilder<List<HermesEndpointConfig>>(
                  future: _endpointProfilesFuture,
                  builder: (context, snapshot) => _EndpointProfileChips(
                    profiles: snapshot.data ?? const [],
                    connecting: connecting,
                    onSelect: _selectEndpointProfile,
                    onRename: (profile) =>
                        unawaited(_renameEndpointProfile(context, profile)),
                    onDelete: (profile) =>
                        unawaited(_deleteEndpointProfile(profile)),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ActionChip(
                      key: const ValueKey('hermes-preset-local'),
                      label: const Text('Local Hermes'),
                      onPressed: connecting
                          ? null
                          : () => _applyEndpointPreset('http://127.0.0.1:8642'),
                    ),
                    ActionChip(
                      key: const ValueKey('hermes-preset-android'),
                      label: const Text('Android emulator'),
                      onPressed: connecting
                          ? null
                          : () => _applyEndpointPreset('http://10.0.2.2:8642'),
                    ),
                    ActionChip(
                      key: const ValueKey('hermes-preset-remote'),
                      label: const Text('Remote/LAN'),
                      onPressed: connecting
                          ? null
                          : () => _applyEndpointPreset(''),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  key: const ValueKey('hermes-base-url-field'),
                  controller: _baseUrlController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Hermes API base URL',
                    helperText: _hermesBaseUrlHint,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  key: const ValueKey('hermes-api-key-field'),
                  controller: _apiKeyController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'API key (optional)',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  key: const ValueKey('hermes-profile-label-field'),
                  controller: _profileLabelController,
                  decoration: const InputDecoration(
                    labelText: 'Profile label (optional)',
                    helperText: 'Saved locally; leave blank to use the URL.',
                  ),
                ),
                const SizedBox(height: 16),
                if (state.status == HermesConnectionStatus.error &&
                    state.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _HermesConnectError(error: state.errorMessage!),
                  ),
                ElevatedButton(
                  key: const ValueKey('hermes-connect-button'),
                  onPressed: connecting
                      ? null
                      : () => unawaited(_connect(channel)),
                  child: connecting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Connect'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChat(
    BuildContext context,
    HermesChannel channel,
    HermesChannelState state,
  ) {
    final pendingApproval = _pendingApprovals.isEmpty
        ? null
        : _pendingApprovals.first;
    final pendingApprovalCount = _pendingApprovals.length;
    final hasActiveSession = state.activeSessionId != null;
    final canSendTurns = _canSendTurns(state);
    final canRespondToApprovals = _canRespondToApprovals(state);
    final isTurnActive = _isTurnActive(state);
    return Column(
      children: [
        if (pendingApproval != null)
          _ApprovalBanner(
            request: pendingApproval,
            pendingCount: pendingApprovalCount,
            responding: pendingApproval.id.trim() == _answeringApprovalId,
            canRespond: canRespondToApprovals,
            onDecide: (decision) =>
                unawaited(_resolveApproval(channel, decision)),
            onDismissMalformed: _dismissCurrentApproval,
          ),
        if (state.capabilities != null)
          _HermesCapabilityStrip(
            capabilities: state.capabilities!,
            detailedHealth: state.detailedHealth,
            models: state.models,
            skills: state.skills,
            enabledToolsets: state.enabledToolsets,
            jobs: state.jobs,
          ),
        if (hasActiveSession && !canSendTurns)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Card(
              key: ValueKey('hermes-chat-transport-unavailable'),
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Hermes did not advertise a supported chat transport for this endpoint.',
                ),
              ),
            ),
          ),
        Expanded(
          child: state.activeSessionId == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _canCreateSession(state)
                          ? 'No Hermes sessions. Create a new session to start chatting.'
                          : 'No Hermes sessions are available, and this endpoint did not advertise session creation.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.builder(
                  key: const ValueKey('hermes-transcript'),
                  padding: const EdgeInsets.all(12),
                  itemCount: state.activeMessages.length,
                  itemBuilder: (context, index) =>
                      _TurnBubble(turn: state.activeMessages[index]),
                ),
        ),
        if (state.errorMessage != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: _HermesChatError(
              error: state.errorMessage!,
              onRetry:
                  !canSendTurns ||
                      isTurnActive ||
                      _retryableFailedUserText(state) == null
                  ? null
                  : () => _retryLastFailedTurn(channel),
              onReconnect: () =>
                  unawaited(_confirmDisconnect(context, channel)),
            ),
          ),
        if (_voiceError != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              _voiceError!,
              key: const ValueKey('hermes-voice-error'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        if (_queuedFollowUps.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: MaterialBanner(
              key: const ValueKey('hermes-queued-follow-up'),
              content: Text(_queuedFollowUpSummary(state)),
              actions: [
                if (_canOpenQueuedFollowUpSession(state))
                  TextButton(
                    key: const ValueKey('hermes-queued-follow-up-open-session'),
                    onPressed: () =>
                        unawaited(_openQueuedFollowUpSession(context, channel)),
                    child: const Text('Open session'),
                  ),
                TextButton.icon(
                  key: const ValueKey('hermes-queued-follow-up-copy'),
                  onPressed: () {
                    unawaited(
                      Clipboard.setData(
                        ClipboardData(
                          text: _queuedFollowUpDetailsSummary(state),
                        ),
                      ),
                    );
                    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Copied redacted Hermes queued follow-ups.',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_outlined),
                  label: const Text('Copy'),
                ),
                TextButton(
                  key: const ValueKey('hermes-queued-follow-up-send-now'),
                  onPressed: _canSendQueuedFollowUp(state)
                      ? () => _sendQueuedFollowUpIfIdle(channel)
                      : null,
                  child: const Text('Send now'),
                ),
                TextButton(
                  key: const ValueKey('hermes-queued-follow-up-cancel'),
                  onPressed: () =>
                      unawaited(_confirmClearQueuedFollowUps(context)),
                  child: const Text('Cancel all'),
                ),
              ],
            ),
          ),
        if (_queuedFollowUpError != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              _queuedFollowUpError!,
              key: const ValueKey('hermes-queued-follow-up-error'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Semantics(
                  label: 'Continuous voice — device STT to Hermes text',
                  child: Switch(
                    key: const ValueKey('hermes-continuous-voice-switch'),
                    value: _continuousVoiceEnabled,
                    onChanged: canSendTurns
                        ? (value) {
                            setState(() => _continuousVoiceEnabled = value);
                            if (value) {
                              unawaited(_captureOnce(channel));
                            } else {
                              _stopSpeaking();
                            }
                          }
                        : null,
                  ),
                ),
                Expanded(
                  child: TextField(
                    key: const ValueKey('hermes-composer-field'),
                    controller: _composerController,
                    enabled: canSendTurns,
                    decoration: InputDecoration(
                      hintText: canSendTurns
                          ? 'Message Hermes…'
                          : 'Chat transport unavailable',
                    ),
                    onSubmitted: (_) => _sendComposerText(channel),
                  ),
                ),
                if (isTurnActive)
                  IconButton(
                    key: const ValueKey('hermes-stop-button'),
                    tooltip: 'Stop',
                    icon: const Icon(Icons.stop_circle_outlined),
                    onPressed: () => _stopActiveTurn(channel),
                  ),
                if (state.capabilities != null) ...[
                  IconButton(
                    key: const ValueKey('hermes-attachments-button'),
                    tooltip: 'Attachments/media status',
                    icon: const Icon(Icons.attach_file_outlined),
                    onPressed: () =>
                        _showAttachmentsDeferred(context, state.capabilities!),
                  ),
                  IconButton(
                    key: const ValueKey('hermes-files-context-button'),
                    tooltip: 'Files/context folders status',
                    icon: const Icon(Icons.folder_open_outlined),
                    onPressed: () =>
                        _showFilesContextDeferred(context, state.capabilities!),
                  ),
                ],
                IconButton(
                  key: const ValueKey('hermes-mic-button'),
                  tooltip: 'Speak — device STT to Hermes text',
                  icon: _capturing
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.mic_none_outlined),
                  onPressed: _capturing || !canSendTurns
                      ? null
                      : () => unawaited(_captureOnce(channel)),
                ),
                IconButton(
                  key: const ValueKey('hermes-send-button'),
                  tooltip: 'Send',
                  icon: const Icon(Icons.send_outlined),
                  onPressed: canSendTurns
                      ? () => _sendComposerText(channel)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _stopActiveTurn(HermesChannel channel) {
    channel.stopActiveTurn();
    setState(() => _continuousVoiceEnabled = false);
    _stopSpeaking();
  }

  void _showAttachmentsDeferred(
    BuildContext context,
    HermesCapabilityDocument capabilities,
  ) {
    final advertised =
        capabilities.supportsFeature('attachments_api') ||
        capabilities.supportsFeature('multimodal_chat');
    final detail = advertised
        ? 'Hermes advertises attachments or multimodal chat, but Navivox has not wired mobile-safe upload controls yet.'
        : 'Hermes did not advertise a mobile-safe attachments API. Navivox keeps this chat text-only plus device STT transcripts.';
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hermes attachments/media',
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(detail, key: const ValueKey('hermes-attachments-detail')),
              const SizedBox(height: 8),
              const Text(
                'No files, photos, transcripts, or local paths are uploaded from this control.',
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  key: const ValueKey('hermes-attachments-close'),
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilesContextDeferred(
    BuildContext context,
    HermesCapabilityDocument capabilities,
  ) {
    final advertised =
        capabilities.supportsFeature('files_api') ||
        capabilities.supportsFeature('context_folders_api') ||
        capabilities.supportsFeature('workspace_files');
    final detail = advertised
        ? 'Hermes advertises file or context-folder capabilities, but Navivox has not wired mobile-safe file/context controls yet.'
        : 'Hermes did not advertise a mobile-safe files/context folders API. Navivox keeps workspace paths hidden.';
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hermes files/context folders',
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  detail,
                  key: const ValueKey('hermes-files-context-detail'),
                ),
                const SizedBox(height: 8),
                const Text(
                  'No local file paths, folder names, transcripts, or workspace contents are uploaded from this control.',
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    key: const ValueKey('hermes-files-context-close'),
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _resolveApproval(
    HermesChannel channel,
    HermesApprovalDecision decision,
  ) async {
    if (_pendingApprovals.isEmpty || _answeringApprovalId != null) return;
    final request = _pendingApprovals.first;
    final approvalId = request.id.trim();
    if (approvalId.isEmpty) return;
    final approvalSessionId = _approvalSessionId;
    setState(() => _answeringApprovalId = approvalId);
    try {
      await channel.respondToApproval(
        approvalId: approvalId,
        decision: decision,
      );
      if (!mounted) return;
      setState(() {
        final stillSameSession = _approvalSessionId == approvalSessionId;
        if (stillSameSession &&
            _pendingApprovals.isNotEmpty &&
            _approvalRequestKey(_pendingApprovals.first) ==
                _approvalRequestKey(request)) {
          _pendingApprovals.removeFirst();
        }
        if (_answeringApprovalId == approvalId) {
          _answeringApprovalId = null;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (_answeringApprovalId == approvalId) {
          _answeringApprovalId = null;
        }
      });
    }
  }

  void _dismissCurrentApproval() {
    if (_pendingApprovals.isEmpty) return;
    setState(() {
      _pendingApprovals.removeFirst();
      _answeringApprovalId = null;
    });
  }

  void _selectEndpointProfile(HermesEndpointConfig profile) {
    _baseUrlController.text = profile.baseUrl;
    _apiKeyController.text = profile.apiKey ?? '';
    _profileLabelController.text = profile.label ?? '';
  }

  void _applyEndpointPreset(String baseUrl) {
    _baseUrlController.text = baseUrl;
    _apiKeyController.clear();
    _profileLabelController.clear();
  }

  Future<void> _renameEndpointProfile(
    BuildContext context,
    HermesEndpointConfig profile,
  ) async {
    final id = profile.id;
    if (id == null || id.trim().isEmpty) return;
    var draftLabel = _safeHermesRenameDefault(profile.label ?? '');
    final nextLabel = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const ValueKey('hermes-endpoint-profile-rename-dialog'),
        title: const Text('Rename Hermes profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profile for ${_safeHermesUiPreview(profile.baseUrl, maxLength: 120)}. '
              'Stored API keys remain in secure storage.',
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const ValueKey('hermes-endpoint-profile-rename-field'),
              initialValue: draftLabel,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Profile label',
                helperText: 'Leave blank to show the endpoint URL.',
              ),
              onChanged: (value) => draftLabel = value,
              onFieldSubmitted: (value) =>
                  Navigator.of(dialogContext).pop(value.trim()),
            ),
          ],
        ),
        actions: [
          TextButton(
            key: const ValueKey('hermes-endpoint-profile-rename-cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('hermes-endpoint-profile-rename-save'),
            onPressed: () => Navigator.of(dialogContext).pop(draftLabel.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (nextLabel == null) return;
    final label = nextLabel.trim();
    if (label == (profile.label ?? '').trim()) return;
    try {
      await ref
          .read(hermesEndpointStoreProvider)
          .save(
            baseUrl: profile.baseUrl,
            apiKey: profile.apiKey,
            label: label.isEmpty ? null : label,
            profileId: id,
          );
      _refreshEndpointProfiles();
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not rename Hermes profile: ${_safeHermesUiError(error)}',
          ),
        ),
      );
    }
  }

  Future<void> _deleteEndpointProfile(HermesEndpointConfig profile) async {
    final id = profile.id;
    if (id == null || id.trim().isEmpty) return;
    await ref.read(hermesEndpointStoreProvider).deleteProfile(id);
    if (_baseUrlController.text.trim() == profile.baseUrl) {
      _baseUrlController.clear();
      _apiKeyController.clear();
      _profileLabelController.clear();
    }
    _refreshEndpointProfiles();
  }

  Future<void> _connect(HermesChannel channel) async {
    final attemptId = ++_connectAttemptId;
    final baseUrl = hermesPublicEndpointBaseUrl(_baseUrlController.text);
    final apiKey = _apiKeyController.text.trim();
    final profileLabel = _safeHermesUiText(_profileLabelController.text).trim();
    await channel.connect(
      baseUrl: baseUrl,
      apiKey: apiKey.isEmpty ? null : apiKey,
    );
    if (attemptId != _connectAttemptId ||
        hermesPublicEndpointBaseUrl(_baseUrlController.text) != baseUrl ||
        _apiKeyController.text.trim() != apiKey ||
        _safeHermesUiText(_profileLabelController.text).trim() !=
            profileLabel ||
        channel.state.status != HermesConnectionStatus.connected) {
      return;
    }
    await ref
        .read(hermesEndpointStoreProvider)
        .save(
          baseUrl: baseUrl,
          apiKey: apiKey.isEmpty ? null : apiKey,
          label: profileLabel.isEmpty ? null : profileLabel,
        );
    _refreshEndpointProfiles();
  }

  Future<void> _confirmDisconnect(
    BuildContext context,
    HermesChannel channel,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const ValueKey('hermes-disconnect-confirm-dialog'),
        title: const Text('Disconnect from Hermes?'),
        content: Text(
          'Disconnect from ${_safeHermesUiPreview(_baseUrlController.text, maxLength: 120)} '
          'and remove this saved endpoint/API key from this device. Other saved '
          'Hermes profiles remain available.',
        ),
        actions: [
          TextButton(
            key: const ValueKey('hermes-disconnect-cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('hermes-disconnect-confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _disconnect(channel);
  }

  Future<void> _disconnect(HermesChannel channel) async {
    await channel.disconnect();
    await ref.read(hermesEndpointStoreProvider).clear();
    _refreshEndpointProfiles();
  }

  void _showDiagnosticsDialog(BuildContext context, HermesChannelState state) {
    final diagnostics = hermesDiagnosticsExport(state);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hermes diagnostics'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(
              diagnostics,
              key: const ValueKey('hermes-diagnostics-text'),
            ),
          ),
        ),
        actions: [
          TextButton(
            key: const ValueKey('hermes-diagnostics-copy'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: diagnostics));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Hermes diagnostics copied')),
              );
            },
            child: const Text('Copy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSessionsPanel(BuildContext context, HermesChannel channel) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => _HermesSessionsPanel(
        state: channel.state,
        canCreate: _canCreateSession(channel.state),
        onCreate: () {
          Navigator.of(sheetContext).pop();
          unawaited(_createSession(context, channel));
        },
        onSelect: (session) {
          Navigator.of(sheetContext).pop();
          unawaited(_selectSession(context, channel, session));
        },
        onRename: (session) {
          Navigator.of(sheetContext).pop();
          unawaited(_renameSession(context, channel, session));
        },
        onFork: (session) {
          Navigator.of(sheetContext).pop();
          unawaited(_forkSession(context, channel, session));
        },
        onDelete: (session) {
          Navigator.of(sheetContext).pop();
          unawaited(_deleteSession(context, channel, session));
        },
      ),
    );
  }

  Future<void> _createSession(
    BuildContext context,
    HermesChannel channel,
  ) async {
    try {
      await channel.createSession();
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not create session: ${_safeHermesUiError(error)}',
          ),
        ),
      );
    }
  }

  Future<void> _selectSession(
    BuildContext context,
    HermesChannel channel,
    HermesSession session,
  ) async {
    try {
      await channel.selectSession(session.id);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open session: ${_safeHermesUiError(error)}'),
        ),
      );
    }
  }

  Future<void> _renameSession(
    BuildContext context,
    HermesChannel channel,
    HermesSession session,
  ) async {
    final currentTitle = session.title ?? '';
    var draftTitle = _safeHermesRenameDefault(currentTitle);
    final nextTitle = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename session'),
        content: TextFormField(
          key: const ValueKey('hermes-session-title-field'),
          initialValue: draftTitle,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Session title'),
          onChanged: (value) => draftTitle = value,
          onFieldSubmitted: (value) => Navigator.of(context).pop(value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('hermes-session-title-save'),
            onPressed: () => Navigator.of(context).pop(draftTitle.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    final title = nextTitle?.trim();
    if (title == null || title.isEmpty || title == currentTitle) return;
    try {
      await channel.renameSession(sessionId: session.id, title: title);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not rename session: ${_safeHermesUiError(error)}',
          ),
        ),
      );
    }
  }

  Future<void> _forkSession(
    BuildContext context,
    HermesChannel channel,
    HermesSession session,
  ) async {
    try {
      await channel.forkSession(session.id);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not fork session: ${_safeHermesUiError(error)}'),
        ),
      );
    }
  }

  Future<void> _deleteSession(
    BuildContext context,
    HermesChannel channel,
    HermesSession session,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete session?'),
        content: Text(
          'Delete "${_safeHermesUiPreview(session.title ?? session.id, maxLength: 96)}" from Hermes?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('hermes-session-delete-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await channel.deleteSession(session.id);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not delete session: ${_safeHermesUiError(error)}',
          ),
        ),
      );
    }
  }

  void _enqueueApprovalRequest(NavivoxApprovalRequest request) {
    final requestKey = _approvalRequestKey(request);
    final duplicate = _pendingApprovals.any(
      (pending) => _approvalRequestKey(pending) == requestKey,
    );
    if (duplicate || _answeringApprovalId == request.id.trim()) return;
    _approvalSessionId = _subscribed?.state.activeSessionId;
    _pendingApprovals.addLast(request);
  }

  String _approvalRequestKey(NavivoxApprovalRequest request) {
    final id = request.id.trim();
    if (id.isNotEmpty) return 'id:$id';
    final toolCallId = request.toolCallId.trim();
    if (toolCallId.isNotEmpty) {
      return 'tool:$toolCallId';
    }
    return 'prompt:${request.prompt}';
  }

  void _sendComposerText(HermesChannel channel) {
    final text = _composerController.text.trim();
    if (text.isEmpty) return;
    if (_isTurnActive(channel.state)) {
      if (_queuedFollowUps.length >= _maxQueuedFollowUps) {
        setState(() {
          _queuedFollowUpError =
              'Queued follow-ups are full ($_maxQueuedFollowUps). Wait for Hermes to finish before adding more.';
        });
        return;
      }
      _composerController.clear();
      setState(() {
        _queuedFollowUpError = null;
        _queuedFollowUps.addLast(
          _QueuedFollowUp(text, channel.state.activeSessionId),
        );
      });
      return;
    }
    _composerController.clear();
    if (_queuedFollowUpError != null) {
      setState(() => _queuedFollowUpError = null);
    }
    _sendText(channel, text);
  }

  bool _isTurnActive(HermesChannelState state) =>
      state.activeMessages.isNotEmpty &&
      state.activeMessages.last.status == HermesTurnStatus.streaming;

  bool _canSendTurns(HermesChannelState state) {
    if (state.activeSessionId == null) return false;
    final capabilities = state.capabilities;
    if (capabilities == null) return true;
    return HermesTransportPolicy(capabilities).supportsAnyChatTransport;
  }

  bool _canRespondToApprovals(HermesChannelState state) {
    final capabilities = state.capabilities;
    if (capabilities == null) return true;
    return HermesTransportPolicy(capabilities).supportsRunApprovalResponse;
  }

  bool _canCreateSession(HermesChannelState state) =>
      state.capabilities?.advertisesEndpoint(
        'session_create',
        'POST',
        '/api/sessions',
      ) ??
      false;

  void _sendQueuedFollowUpIfIdle(HermesChannel channel) {
    if (!_canSendQueuedFollowUp(channel.state)) return;
    final queued = _queuedFollowUps.removeFirst();
    _queuedFollowUpError = null;
    _sendText(
      channel,
      queued.text,
      requeueOnFailure: true,
      requeueSessionId: queued.sessionId,
    );
  }

  void _dropQueuedFollowUpsForMissingSessions(HermesChannelState state) {
    final sessionIds = state.sessions.map((session) => session.id).toSet();
    _queuedFollowUps.removeWhere(
      (queued) =>
          queued.sessionId != null && !sessionIds.contains(queued.sessionId),
    );
  }

  bool _canSendQueuedFollowUp(HermesChannelState state) {
    if (_queuedFollowUps.isEmpty ||
        _isTurnActive(state) ||
        !_canSendTurns(state)) {
      return false;
    }
    return _queuedFollowUps.first.sessionId == state.activeSessionId;
  }

  bool _canOpenQueuedFollowUpSession(HermesChannelState state) {
    if (_queuedFollowUps.isEmpty) return false;
    final sessionId = _queuedFollowUps.first.sessionId;
    if (sessionId == null || sessionId == state.activeSessionId) return false;
    return state.sessions.any((session) => session.id == sessionId);
  }

  Future<void> _openQueuedFollowUpSession(
    BuildContext context,
    HermesChannel channel,
  ) async {
    if (!_canOpenQueuedFollowUpSession(channel.state)) return;
    final sessionId = _queuedFollowUps.first.sessionId;
    if (sessionId == null) return;
    try {
      await channel.selectSession(sessionId);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not open queued follow-up session: ${_safeHermesUiError(error)}',
          ),
        ),
      );
    }
  }

  void _retryLastFailedTurn(HermesChannel channel) {
    if (!_canSendTurns(channel.state)) return;
    final text = _retryableFailedUserText(channel.state);
    if (text == null) return;
    _sendText(channel, text);
  }

  void _sendText(
    HermesChannel channel,
    String text, {
    bool requeueOnFailure = false,
    String? requeueSessionId,
  }) {
    final sessionId = requeueSessionId ?? channel.state.activeSessionId;
    unawaited(
      channel.sendText(text).catchError((Object error) {
        if (!mounted || !requeueOnFailure || !channel.state.isConnected) return;
        setState(() {
          _queuedFollowUpError =
              'Could not send queued follow-up: ${_safeHermesUiError(error)}';
          if (_queuedFollowUps.length < _maxQueuedFollowUps) {
            _queuedFollowUps.addFirst(_QueuedFollowUp(text, sessionId));
          }
        });
      }),
    );
  }

  String? _retryableFailedUserText(HermesChannelState state) {
    final turns = state.activeMessages;
    for (var index = turns.length - 1; index > 0; index--) {
      final turn = turns[index];
      if (turn.author != HermesTurnAuthor.assistant ||
          turn.status != HermesTurnStatus.failed) {
        continue;
      }
      for (var userIndex = index - 1; userIndex >= 0; userIndex--) {
        final userTurn = turns[userIndex];
        if (userTurn.author == HermesTurnAuthor.user &&
            userTurn.text.trim().isNotEmpty) {
          return userTurn.text.trim();
        }
      }
    }
    return null;
  }

  String _queuedFollowUpSummary(HermesChannelState state) {
    final count = _queuedFollowUps.length;
    final label = count == 1 ? 'follow-up' : 'follow-ups';
    final preview = _queuedFollowUps
        .take(2)
        .map((queued) => _queuedFollowUpPreview(queued.text))
        .join(' • ');
    final remaining = count - 2;
    final suffix = remaining > 0 ? ' • +$remaining more' : '';
    final waiting = !_canSendTurns(state)
        ? ' Waiting for a supported Hermes chat transport.'
        : _queuedFollowUps.first.sessionId != state.activeSessionId
        ? ' Waiting for the original session.'
        : '';
    return 'Queued $count $label after current reply: $preview$suffix$waiting';
  }

  String _queuedFollowUpPreview(String text) =>
      _safeHermesUiPreview(text, maxLength: 48);

  String _queuedFollowUpDetailsSummary(HermesChannelState state) {
    final buffer = StringBuffer()
      ..writeln('Hermes queued follow-ups')
      ..writeln('Queued: ${_queuedFollowUps.length}')
      ..writeln(
        'Active session: ${_safeHermesUiPreview(state.activeSessionId ?? 'none', maxLength: 80)}',
      )
      ..writeln(
        'Next session: ${_safeHermesUiPreview(_queuedFollowUps.first.sessionId ?? 'none', maxLength: 80)}',
      )
      ..writeln('Can send now: ${_canSendQueuedFollowUp(state)}');
    var index = 1;
    for (final queued in _queuedFollowUps.take(_maxQueuedFollowUps)) {
      buffer.writeln(
        '$index. ${_safeHermesUiPreview(queued.text, maxLength: 160)}',
      );
      index += 1;
    }
    buffer.write('Secrets: redacted');
    return buffer.toString();
  }

  Future<void> _confirmClearQueuedFollowUps(BuildContext context) async {
    if (_queuedFollowUps.isEmpty) return;
    final count = _queuedFollowUps.length;
    final label = count == 1 ? 'follow-up' : 'follow-ups';
    final preview = _queuedFollowUps
        .take(3)
        .map((queued) => _safeHermesUiPreview(queued.text, maxLength: 80))
        .join('\n');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const ValueKey('hermes-queued-follow-up-clear-dialog'),
        title: Text('Cancel $count queued $label?'),
        content: Text(
          '$preview${count > 3 ? '\n+${count - 3} more' : ''}\n\n'
          'Queued text is redacted and bounded in this confirmation.',
        ),
        actions: [
          TextButton(
            key: const ValueKey('hermes-queued-follow-up-clear-keep'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep'),
          ),
          FilledButton(
            key: const ValueKey('hermes-queued-follow-up-clear-confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Cancel all'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _queuedFollowUps.clear();
      _queuedFollowUpError = null;
    });
  }

  Future<void> _captureOnce(HermesChannel channel) async {
    if (_capturing) return;
    final service =
        widget.voiceCaptureServiceOverride ??
        ref.read(hermesVoiceCaptureServiceProvider);
    final captureSessionId = channel.state.activeSessionId;
    setState(() {
      _capturing = true;
      _voiceError = null;
    });
    final outcome = await const TranscriptVoiceCaptureFlow().capture(
      service: service,
      timeout: const Duration(seconds: 12),
    );
    if (!mounted) return;
    setState(() => _capturing = false);
    if (!channel.state.isConnected ||
        channel.state.activeSessionId != captureSessionId) {
      _setVoiceFailure(
        'Voice capture was discarded because the Hermes session changed.',
      );
      return;
    }

    switch (outcome.status) {
      case TranscriptVoiceCaptureStatus.unavailable:
        _setVoiceFailure('Voice input is not available here.');
        return;
      case TranscriptVoiceCaptureStatus.failed:
        _setVoiceFailure(outcome.errorMessage ?? 'Voice capture failed.');
        return;
      case TranscriptVoiceCaptureStatus.captured:
        final result = _voiceRunController.captureSucceeded(
          channel,
          outcome.capture!,
          handleLocalCommand: (_) => false,
        );
        final voiceRunId = result.scheduleAutoSendFor;
        if (voiceRunId != null) {
          final sent = _voiceRunController.autoSendIfPending(
            channel,
            voiceRunId,
          );
          final run = channel.state.voiceRuns[voiceRunId];
          if (sent.submitted && run?.status == NavivoxVoiceRunStatus.failed) {
            _setVoiceFailure(run?.reason ?? 'Voice turn could not be sent.');
          }
        }
    }
  }

  void _setVoiceFailure(String message) {
    final safeMessage = _safeHermesUiPreview(message, maxLength: 160);
    setState(() {
      if (_continuousVoiceEnabled) {
        _continuousVoiceEnabled = false;
        _voiceError = '$safeMessage Continuous voice paused.';
      } else {
        _voiceError = safeMessage;
      }
    });
  }

  void _stopSpeaking() {
    final tts =
        widget.textToSpeechServiceOverride ??
        ref.read(hermesTextToSpeechServiceProvider);
    if (tts == null) return;
    unawaited(tts.stop().catchError((_) {}));
  }

  void _maybeContinueVoiceLoop(HermesChannel channel) {
    if (!_continuousVoiceEnabled || _capturing) return;
    final reply = hermesContinuousVoiceReplyToSpeak(
      turns: channel.state.activeMessages,
      enabled: true,
      lastSpokenTurnId: _lastSpokenTurnId,
    );
    if (reply == null) return;
    _lastSpokenTurnId = reply.id;
    final tts =
        widget.textToSpeechServiceOverride ??
        ref.read(hermesTextToSpeechServiceProvider);
    if (tts == null) {
      setState(() {
        _continuousVoiceEnabled = false;
        _voiceError =
            'Text-to-speech is not available here. Continuous voice paused.';
      });
      return;
    }
    unawaited(
      tts
          .speak(reply.text)
          .then((_) {
            if (!mounted || !_continuousVoiceEnabled) return;
            if (!channel.state.isConnected ||
                channel.state.activeSessionId != reply.sessionId) {
              setState(() {
                _continuousVoiceEnabled = false;
                _voiceError =
                    'Hermes session changed before voice could re-arm. Continuous voice paused.';
              });
              return;
            }
            unawaited(_captureOnce(channel));
          })
          .catchError((Object error) {
            if (!mounted) return;
            setState(() {
              _continuousVoiceEnabled = false;
              _voiceError =
                  'Could not speak Hermes reply. Continuous voice paused.';
            });
          }),
    );
  }
}

class _QueuedFollowUp {
  const _QueuedFollowUp(this.text, this.sessionId);

  final String text;
  final String? sessionId;
}

class _HermesChatError extends StatelessWidget {
  const _HermesChatError({required this.error, this.onRetry, this.onReconnect});

  final String error;
  final VoidCallback? onRetry;
  final VoidCallback? onReconnect;

  @override
  Widget build(BuildContext context) {
    final lower = error.toLowerCase();
    final authRejected = _isHermesAuthError(lower);
    final approvalResponseFailed = lower.contains('could not answer approval');
    final malformedApprovalRequest = lower.contains(
      'approval request was missing an approval id',
    );
    final unsupportedChatTransport = lower.contains(
      'did not advertise a supported chat transport',
    );
    final streamOrNetworkFailure =
        _isHermesNetworkError(lower) || lower.contains('stream');
    final runCancelled = lower.contains('hermes run was cancelled');
    final runFailed = lower.contains('hermes run failed');
    final (title, recovery) = authRejected
        ? (
            'Hermes API rejected the saved API key.',
            'Reconnect with a fresh Hermes API key, then retry this message.',
          )
        : approvalResponseFailed
        ? (
            'Hermes could not record the approval decision.',
            'Review the request, check that the run is still active, then try the decision again.',
          )
        : malformedApprovalRequest
        ? (
            'Hermes sent an incomplete approval request.',
            'Retry when Hermes can provide an approval id for this run.',
          )
        : unsupportedChatTransport
        ? (
            'Hermes endpoint does not support chat turns.',
            'Connect to a Hermes API server that advertises session chat streaming or run events.',
          )
        : runCancelled
        ? ('Hermes run was cancelled.', 'Start a new turn when you are ready.')
        : runFailed
        ? (
            'Hermes run failed.',
            'Check Hermes, then retry this message when the run is recoverable.',
          )
        : streamOrNetworkFailure
        ? (
            'Hermes stream dropped.',
            'Check the endpoint/network and send again when Hermes is reachable.',
          )
        : ('Hermes could not finish the turn.', 'Retry when Hermes is ready.');
    return Card(
      key: const ValueKey('hermes-chat-error'),
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title),
            const SizedBox(height: 4),
            Text(recovery),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  TextButton.icon(
                    key: const ValueKey('hermes-chat-error-details'),
                    onPressed: () => _showHermesErrorDetailsSheet(
                      context,
                      title: title,
                      recovery: recovery,
                      error: error,
                    ),
                    icon: const Icon(Icons.article_outlined),
                    label: const Text('Details'),
                  ),
                  if ((authRejected || streamOrNetworkFailure) &&
                      onReconnect != null)
                    OutlinedButton.icon(
                      key: const ValueKey('hermes-chat-error-reconnect'),
                      onPressed: onReconnect,
                      icon: const Icon(Icons.key_outlined),
                      label: const Text('Reconnect'),
                    ),
                  if (onRetry != null)
                    FilledButton.icon(
                      key: const ValueKey('hermes-chat-error-retry'),
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry last message'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showHermesErrorDetailsSheet(
  BuildContext context, {
  required String title,
  required String recovery,
  required String error,
}) {
  final safeError = _safeHermesUiPreview(
    _safeHermesUiText(error),
    maxLength: 1200,
  );
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          key: const ValueKey('hermes-error-details-sheet'),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: Theme.of(sheetContext).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(recovery),
              const SizedBox(height: 12),
              const Text('Redacted error details'),
              const SizedBox(height: 4),
              SelectableText(
                safeError,
                key: const ValueKey('hermes-error-details-text'),
              ),
              const SizedBox(height: 8),
              const Text(
                'Secrets, bearer tokens, API keys, cookies, and copied endpoint credentials are redacted before display.',
                key: ValueKey('hermes-error-details-redaction-note'),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      key: const ValueKey('hermes-error-details-copy'),
                      onPressed: () {
                        unawaited(
                          Clipboard.setData(ClipboardData(text: safeError)),
                        );
                        ScaffoldMessenger.maybeOf(sheetContext)?.showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Copied redacted Hermes error details.',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_outlined),
                      label: const Text('Copy redacted details'),
                    ),
                    TextButton(
                      key: const ValueKey('hermes-error-details-close'),
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

String _safeHermesUiText(String text) {
  var safe = text;
  safe = safe.replaceAllMapped(
    RegExp(
      r'(Authorization\s*[:=]\s*(?:Bearer|Basic)\s+)[^\s,;]+',
      caseSensitive: false,
    ),
    (match) => '${match[1]}[redacted]',
  );
  safe = safe.replaceAllMapped(
    RegExp(r'Bearer\s+[^\s,;]+', caseSensitive: false),
    (_) => 'Bearer [redacted]',
  );
  safe = safe.replaceAllMapped(
    RegExp(r'Basic\s+[^\s,;]+', caseSensitive: false),
    (_) => 'Basic [redacted]',
  );
  safe = safe.replaceAllMapped(
    RegExp(
      r'((?:Cookie|Set-Cookie|X-API-Key|X-Auth-Token)\s*[:=]\s*)[^\n\r,;]+',
      caseSensitive: false,
    ),
    (match) => '${match[1]}[redacted]',
  );
  safe = safe.replaceAllMapped(
    RegExp(r'([a-z][a-z0-9+.-]*://)([^/\s@]+@)', caseSensitive: false),
    (match) => '${match[1]}[redacted]@',
  );
  safe = safe.replaceAll(
    RegExp(r'\b[A-Z]:\\[^\s,;]+', caseSensitive: false),
    '[redacted-path]',
  );
  safe = safe.replaceAll(RegExp(r'\\\\[^\s,;]+'), '[redacted-path]');
  safe = safe.replaceAll(
    RegExp(r'/(?:home|Users|var|private|mnt|Volumes)/[^\s,;]+'),
    '[redacted-path]',
  );
  safe = safe.replaceAllMapped(
    RegExp(
      r'(api[-_ ]?key|token|secret|password|passwd|pwd|credential|credentials|auth)(\s*(?:=|:)\s*)[^\s,;]+',
      caseSensitive: false,
    ),
    (match) => '${match[1]}${match[2]}[redacted]',
  );
  safe = safe
      .replaceAll(
        RegExp(r'sk-[a-z0-9_-]{12,}', caseSensitive: false),
        'sk-[redacted]',
      )
      .replaceAll(
        RegExp(r'gh[pousr]_[a-z0-9_]{20,}', caseSensitive: false),
        'ghp_[redacted]',
      )
      .replaceAll(
        RegExp(r'xox[abprs]-[a-z0-9-]{20,}', caseSensitive: false),
        'xox-[redacted]',
      )
      .replaceAll(
        RegExp(
          r'eyJ[a-z0-9_-]{8,}\.[a-z0-9_-]{8,}\.[a-z0-9_-]{8,}',
          caseSensitive: false,
        ),
        '[redacted-jwt]',
      );
  return safe.replaceAll(
    RegExp(r'secret[-_a-z0-9.]*', caseSensitive: false),
    '[redacted]',
  );
}

String _safeHermesUiPreview(String text, {int maxLength = 80}) {
  final safe = _safeHermesUiText(text);
  if (safe.length <= maxLength) return safe;
  return '${safe.substring(0, maxLength).trimRight()}…';
}

class _EndpointProfileChips extends StatelessWidget {
  const _EndpointProfileChips({
    required this.profiles,
    required this.connecting,
    required this.onSelect,
    required this.onRename,
    required this.onDelete,
  });

  final List<HermesEndpointConfig> profiles;
  final bool connecting;
  final ValueChanged<HermesEndpointConfig> onSelect;
  final ValueChanged<HermesEndpointConfig> onRename;
  final ValueChanged<HermesEndpointConfig> onDelete;

  @override
  Widget build(BuildContext context) {
    if (profiles.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Saved Hermes profiles',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final profile in profiles)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InputChip(
                    key: ValueKey(
                      'hermes-endpoint-profile-${profile.id ?? profile.baseUrl}',
                    ),
                    label: Text(
                      _safeHermesUiPreview(profile.displayLabel, maxLength: 48),
                    ),
                    onPressed: connecting ? null : () => onSelect(profile),
                    onDeleted: connecting || profile.id == null
                        ? null
                        : () => unawaited(
                            _confirmDeleteProfile(context, profile),
                          ),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    tooltip: _safeHermesUiPreview(
                      profile.baseUrl,
                      maxLength: 96,
                    ),
                  ),
                  IconButton(
                    key: ValueKey(
                      'hermes-endpoint-profile-rename-${profile.id ?? profile.baseUrl}',
                    ),
                    tooltip: 'Rename Hermes profile',
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    onPressed: connecting || profile.id == null
                        ? null
                        : () => onRename(profile),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _confirmDeleteProfile(
    BuildContext context,
    HermesEndpointConfig profile,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const ValueKey('hermes-endpoint-profile-delete-dialog'),
        title: const Text('Remove saved Hermes profile?'),
        content: Text(
          'Remove ${_safeHermesUiPreview(profile.displayLabel, maxLength: 96)} '
          '(${_safeHermesUiPreview(profile.baseUrl, maxLength: 120)}) from this device. '
          'Any stored API key for this profile is removed from secure storage.',
        ),
        actions: [
          TextButton(
            key: const ValueKey('hermes-endpoint-profile-delete-cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('hermes-endpoint-profile-delete-confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) onDelete(profile);
  }
}

String _safeHermesRenameDefault(String text) {
  final safe = _safeHermesUiText(text);
  if (safe != text || safe.length > 96) return '';
  return safe;
}

String _safeHermesSessionSearchText(String text) {
  final safe = _safeHermesUiText(text);
  if (safe == text) return safe;
  return safe.replaceAll('[redacted]', '').trim();
}

String _safeHermesUiError(Object error) =>
    _safeHermesUiPreview(error.toString(), maxLength: 160);

bool _isHermesAuthError(String lowerCaseError) {
  return lowerCaseError.contains('401') ||
      lowerCaseError.contains('403') ||
      lowerCaseError.contains('419') ||
      lowerCaseError.contains('unauthorized') ||
      lowerCaseError.contains('forbidden') ||
      lowerCaseError.contains('expired') ||
      lowerCaseError.contains('invalid api key') ||
      lowerCaseError.contains('invalid token');
}

bool _isHermesNetworkError(String lowerCaseError) {
  return lowerCaseError.contains('socketexception') ||
      lowerCaseError.contains('clientexception') ||
      lowerCaseError.contains('handshakeexception') ||
      lowerCaseError.contains('connection refused') ||
      lowerCaseError.contains('connection reset') ||
      lowerCaseError.contains('connection aborted') ||
      lowerCaseError.contains('connection closed') ||
      lowerCaseError.contains('software caused connection abort') ||
      lowerCaseError.contains('econnrefused') ||
      lowerCaseError.contains('econnreset') ||
      lowerCaseError.contains('broken pipe') ||
      lowerCaseError.contains('failed host lookup') ||
      lowerCaseError.contains('host lookup failed') ||
      lowerCaseError.contains('temporary failure in name resolution') ||
      lowerCaseError.contains('name or service not known') ||
      lowerCaseError.contains('no route to host') ||
      lowerCaseError.contains('network is unreachable') ||
      lowerCaseError.contains('network unreachable') ||
      lowerCaseError.contains('timed out') ||
      lowerCaseError.contains('timeout');
}

class _HermesConnectError extends StatelessWidget {
  const _HermesConnectError({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    final lower = error.toLowerCase();
    final (title, recovery) = _isHermesAuthError(lower)
        ? (
            'Hermes API rejected the API key.',
            'Check the endpoint API key in Hermes and try again.',
          )
        : _isHermesNetworkError(lower)
        ? (
            'Hermes endpoint is unreachable.',
            'Check the base URL, network, VPN, and that Hermes API server is running.',
          )
        : ('Could not connect to Hermes.', 'Check the endpoint and try again.');
    return Column(
      key: const ValueKey('hermes-connect-error'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
        const SizedBox(height: 4),
        Text(recovery),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            key: const ValueKey('hermes-connect-error-details'),
            onPressed: () => _showHermesErrorDetailsSheet(
              context,
              title: title,
              recovery: recovery,
              error: error,
            ),
            icon: const Icon(Icons.article_outlined),
            label: const Text('Details'),
          ),
        ),
      ],
    );
  }
}

class _HermesSessionsPanel extends StatefulWidget {
  const _HermesSessionsPanel({
    required this.state,
    required this.canCreate,
    required this.onCreate,
    required this.onSelect,
    required this.onRename,
    required this.onFork,
    required this.onDelete,
  });

  final HermesChannelState state;
  final bool canCreate;
  final VoidCallback onCreate;
  final ValueChanged<HermesSession> onSelect;
  final ValueChanged<HermesSession> onRename;
  final ValueChanged<HermesSession> onFork;
  final ValueChanged<HermesSession> onDelete;

  @override
  State<_HermesSessionsPanel> createState() => _HermesSessionsPanelState();
}

class _HermesSessionsPanelState extends State<_HermesSessionsPanel> {
  final _searchController = TextEditingController();
  var _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _canRename =>
      widget.state.capabilities?.advertisesEndpoint(
        'session_update',
        'PATCH',
        '/api/sessions/{session_id}',
      ) ??
      false;

  bool get _canDelete =>
      widget.state.capabilities?.advertisesEndpoint(
        'session_delete',
        'DELETE',
        '/api/sessions/{session_id}',
      ) ??
      false;

  bool get _canFork =>
      widget.state.capabilities?.advertisesEndpoint(
        'session_fork',
        'POST',
        '/api/sessions/{session_id}/fork',
      ) ??
      false;

  @override
  Widget build(BuildContext context) {
    final allSessions = widget.state.sessions;
    final query = _query.trim().toLowerCase();
    final sessions = query.isEmpty
        ? allSessions
        : allSessions
              .where(
                (session) => _sessionMatchesQuery(
                  session,
                  query,
                  widget.state.activeSessionId,
                ),
              )
              .toList(growable: false);
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.8,
        child: Column(
          children: [
            ListTile(
              title: Text(
                'Hermes sessions',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              trailing: widget.canCreate
                  ? FilledButton.icon(
                      key: const ValueKey('hermes-sessions-new'),
                      onPressed: widget.onCreate,
                      icon: const Icon(Icons.add_comment_outlined),
                      label: const Text('New'),
                    )
                  : null,
            ),
            if (allSessions.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  key: const ValueKey('hermes-session-search-field'),
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search sessions',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            key: const ValueKey('hermes-session-search-clear'),
                            tooltip: 'Clear search',
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          ),
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _sessionCountSummary(
                      visibleCount: sessions.length,
                      totalCount: allSessions.length,
                      query: _query,
                    ),
                    key: const ValueKey('hermes-session-count-summary'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            ],
            if (allSessions.isEmpty)
              const Expanded(
                child: Center(child: Text('No Hermes sessions yet.')),
              )
            else if (sessions.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    'No Hermes sessions match “${_safeHermesUiPreview(_query.trim(), maxLength: 64)}”.',
                  ),
                ),
              )
            else
              Expanded(
                child: ListView(
                  key: const ValueKey('hermes-sessions-list'),
                  children: [
                    for (final group in _sessionGroups(
                      sessions,
                      widget.state.activeSessionId,
                    )) ...[
                      Padding(
                        key: ValueKey('hermes-session-group-${group.key}'),
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Text(
                          group.label,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                      for (final session in group.sessions)
                        _HermesSessionTile(
                          session: session,
                          active: session.id == widget.state.activeSessionId,
                          canRename: _canRename,
                          canFork: _canFork,
                          canDelete: _canDelete,
                          onSelect: widget.onSelect,
                          onRename: widget.onRename,
                          onFork: widget.onFork,
                          onDelete: widget.onDelete,
                        ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String _sessionCountSummary({
  required int visibleCount,
  required int totalCount,
  required String query,
}) {
  final totalLabel = totalCount == 1 ? 'session' : 'sessions';
  if (query.trim().isEmpty) return '$totalCount $totalLabel';
  return 'Showing $visibleCount of $totalCount $totalLabel';
}

bool _sessionMatchesQuery(
  HermesSession session,
  String query,
  String? activeSessionId,
) {
  final groupTokens = session.id == activeSessionId
      ? const ['active', 'active session']
      : session.parentSessionId != null
      ? const ['forked', 'forked session', 'forked sessions']
      : const ['other', 'other session', 'other sessions'];
  return [
    session.title,
    session.id,
    session.preview,
    session.parentSessionId,
    session.lastActive,
    ...groupTokens,
  ].whereType<String>().any(
    (value) =>
        _safeHermesSessionSearchText(value).toLowerCase().contains(query),
  );
}

List<_HermesSessionGroup> _sessionGroups(
  List<HermesSession> sessions,
  String? activeSessionId,
) {
  final active = <HermesSession>[];
  final forked = <HermesSession>[];
  final other = <HermesSession>[];
  for (final session in sessions) {
    if (session.id == activeSessionId) {
      active.add(session);
    } else if (session.parentSessionId != null) {
      forked.add(session);
    } else {
      other.add(session);
    }
  }
  return [
    if (active.isNotEmpty)
      _HermesSessionGroup('active', 'Active session', active),
    if (forked.isNotEmpty)
      _HermesSessionGroup('forked', 'Forked sessions', _recentFirst(forked)),
    if (other.isNotEmpty)
      _HermesSessionGroup('other', 'Other sessions', _recentFirst(other)),
  ];
}

List<HermesSession> _recentFirst(List<HermesSession> sessions) {
  final sorted = List<HermesSession>.of(sessions);
  sorted.sort((a, b) {
    final recency = _sessionTimestamp(b).compareTo(_sessionTimestamp(a));
    if (recency != 0) return recency;
    return (a.title ?? a.id).compareTo(b.title ?? b.id);
  });
  return sorted;
}

int _sessionTimestamp(HermesSession session) {
  final parsed = DateTime.tryParse(session.lastActive ?? '');
  return parsed?.millisecondsSinceEpoch ?? 0;
}

class _HermesSessionGroup {
  const _HermesSessionGroup(this.key, this.label, this.sessions);

  final String key;
  final String label;
  final List<HermesSession> sessions;
}

class _HermesSessionTile extends StatelessWidget {
  const _HermesSessionTile({
    required this.session,
    required this.active,
    required this.canRename,
    required this.canFork,
    required this.canDelete,
    required this.onSelect,
    required this.onRename,
    required this.onFork,
    required this.onDelete,
  });

  final HermesSession session;
  final bool active;
  final bool canRename;
  final bool canFork;
  final bool canDelete;
  final ValueChanged<HermesSession> onSelect;
  final ValueChanged<HermesSession> onRename;
  final ValueChanged<HermesSession> onFork;
  final ValueChanged<HermesSession> onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: ValueKey('hermes-session-row-${session.id}'),
      selected: active,
      leading: active
          ? const Icon(Icons.check_circle_outline)
          : const Icon(Icons.chat_bubble_outline),
      title: Text(
        _safeHermesUiPreview(session.title ?? session.id, maxLength: 96),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        [
          '${session.messageCount} messages',
          if (session.parentSessionId != null)
            'Forked from ${_safeHermesUiPreview(session.parentSessionId!, maxLength: 80)}',
          if (session.lastActive != null)
            'Last active ${_safeHermesUiPreview(session.lastActive!, maxLength: 80)}',
          if (session.preview != null)
            _safeHermesUiPreview(session.preview!, maxLength: 160),
        ].join(' • '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () => onSelect(session),
      trailing: PopupMenuButton<String>(
        key: ValueKey('hermes-session-menu-${session.id}'),
        tooltip: 'Session actions',
        onSelected: (value) {
          switch (value) {
            case 'copy':
              unawaited(
                Clipboard.setData(
                  ClipboardData(text: _sessionDetailsSummary(session, active)),
                ),
              );
              ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                const SnackBar(
                  content: Text('Copied redacted Hermes session details.'),
                ),
              );
            case 'rename':
              onRename(session);
            case 'fork':
              onFork(session);
            case 'delete':
              onDelete(session);
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'copy', child: Text('Copy details')),
          if (canRename)
            const PopupMenuItem(value: 'rename', child: Text('Rename')),
          if (canFork) const PopupMenuItem(value: 'fork', child: Text('Fork')),
          if (canDelete)
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
        ],
      ),
    );
  }

  String _sessionDetailsSummary(HermesSession session, bool active) {
    final buffer = StringBuffer()
      ..writeln('Hermes session')
      ..writeln(
        'Title: ${_safeHermesUiPreview(session.title ?? session.id, maxLength: 96)}',
      )
      ..writeln('ID: ${_safeHermesUiPreview(session.id, maxLength: 120)}')
      ..writeln('Active: $active')
      ..writeln('Messages: ${session.messageCount}');
    if (session.parentSessionId != null) {
      buffer.writeln(
        'Forked from: ${_safeHermesUiPreview(session.parentSessionId!, maxLength: 120)}',
      );
    }
    if (session.lastActive != null) {
      buffer.writeln(
        'Last active: ${_safeHermesUiPreview(session.lastActive!, maxLength: 120)}',
      );
    }
    if (session.preview != null) {
      buffer.write(
        'Preview: ${_safeHermesUiPreview(session.preview!, maxLength: 240)}',
      );
    }
    return buffer.toString().trimRight();
  }
}

class _HermesCapabilityStrip extends StatelessWidget {
  const _HermesCapabilityStrip({
    required this.capabilities,
    this.detailedHealth,
    this.models = const [],
    this.skills = const [],
    this.enabledToolsets = const [],
    this.jobs = const [],
  });

  final HermesCapabilityDocument capabilities;
  final HermesHealthStatus? detailedHealth;
  final List<String> models;
  final List<String> skills;
  final List<String> enabledToolsets;
  final List<HermesJob> jobs;

  void _showList(BuildContext context, String title, List<String> items) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final item in items)
                ListTile(
                  title: Text(
                    _safeHermesUiPreview(item, maxLength: 96),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showJobs(BuildContext context) {
    final jobsAdminAdvertised =
        capabilities.supportsFeature('jobs_admin') &&
        capabilities.advertisesEndpoint('jobs', 'GET', '/api/jobs');
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hermes jobs'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  jobsAdminAdvertised
                      ? 'Read-only inventory. Hermes advertises jobs admin, but Navivox has not enabled mobile create/edit/delete scheduling.'
                      : 'Read-only inventory. Mobile create/edit/delete scheduling is not available.',
                  key: const ValueKey('hermes-jobs-read-only-note'),
                ),
              ),
              for (final job in jobs)
                ListTile(
                  title: Text(
                    _safeHermesUiPreview(job.displayName, maxLength: 96),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(_jobSummary(job)),
                  trailing: IconButton(
                    key: ValueKey('hermes-job-copy-${job.id}'),
                    tooltip: 'Copy job details',
                    icon: const Icon(Icons.copy_outlined),
                    onPressed: () {
                      unawaited(
                        Clipboard.setData(
                          ClipboardData(text: _jobDetailsSummary(job)),
                        ),
                      );
                      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                        const SnackBar(
                          content: Text('Copied redacted Hermes job details.'),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _jobSummary(HermesJob job) {
    final parts = <String>[
      job.enabled ? 'Enabled' : 'Disabled',
      if (job.state?.trim().isNotEmpty ?? false)
        'State: ${_safeHermesUiPreview(job.state!, maxLength: 48)}',
      if (job.scheduleDisplay?.trim().isNotEmpty ?? false)
        'Schedule: ${_safeHermesUiPreview(job.scheduleDisplay!, maxLength: 80)}',
      if (job.nextRunAt?.trim().isNotEmpty ?? false)
        'Next: ${_safeHermesUiPreview(job.nextRunAt!, maxLength: 48)}',
      if (job.lastRunAt?.trim().isNotEmpty ?? false)
        'Last: ${_safeHermesUiPreview(job.lastRunAt!, maxLength: 48)}',
      if (job.lastError?.trim().isNotEmpty ?? false)
        'Last error: ${_safeHermesUiPreview(job.lastError!, maxLength: 96)}',
    ];
    return parts.join(' • ');
  }

  String _jobDetailsSummary(HermesJob job) {
    final buffer = StringBuffer()
      ..writeln('Hermes job')
      ..writeln(
        'Name: ${_safeHermesUiPreview(job.displayName, maxLength: 120)}',
      )
      ..writeln('ID: ${_safeHermesUiPreview(job.id, maxLength: 120)}')
      ..writeln('Enabled: ${job.enabled}');
    if (job.state?.trim().isNotEmpty ?? false) {
      buffer.writeln(
        'State: ${_safeHermesUiPreview(job.state!, maxLength: 80)}',
      );
    }
    if (job.scheduleDisplay?.trim().isNotEmpty ?? false) {
      buffer.writeln(
        'Schedule: ${_safeHermesUiPreview(job.scheduleDisplay!, maxLength: 120)}',
      );
    }
    if (job.nextRunAt?.trim().isNotEmpty ?? false) {
      buffer.writeln(
        'Next: ${_safeHermesUiPreview(job.nextRunAt!, maxLength: 80)}',
      );
    }
    if (job.lastRunAt?.trim().isNotEmpty ?? false) {
      buffer.writeln(
        'Last: ${_safeHermesUiPreview(job.lastRunAt!, maxLength: 80)}',
      );
    }
    if (job.lastError?.trim().isNotEmpty ?? false) {
      buffer.write(
        'Last error: ${_safeHermesUiPreview(job.lastError!, maxLength: 240)}',
      );
    }
    return buffer.toString().trimRight();
  }

  void _showSurfaceReadiness(BuildContext context) {
    final items = hermesSurfaceReadiness(capabilities);
    final summary = _surfaceReadinessSummary(items);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hermes surface readiness'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  'No mobile config, memory, schedule, gateway, or persona mutation controls are enabled.',
                  key: ValueKey('hermes-admin-surfaces-note'),
                ),
              ),
              for (final item in items)
                ListTile(
                  title: Text(item.title),
                  subtitle: Text(item.detail),
                  trailing: Text(item.status.label),
                ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            key: const ValueKey('hermes-surfaces-copy'),
            onPressed: () {
              unawaited(Clipboard.setData(ClipboardData(text: summary)));
              ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                const SnackBar(
                  content: Text('Copied Hermes surface readiness summary.'),
                ),
              );
            },
            icon: const Icon(Icons.copy_outlined),
            label: const Text('Copy summary'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _surfaceReadinessSummary(List<HermesSurfaceReadiness> items) {
    final buffer = StringBuffer('Hermes surface readiness');
    for (final item in items) {
      buffer.writeln();
      buffer.write(
        '- ${_safeHermesUiPreview(item.title, maxLength: 80)}: ${item.status.label} — ${_safeHermesUiPreview(item.detail, maxLength: 240)}',
      );
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final policy = HermesTransportPolicy(capabilities);
    final surfaceItems = hermesSurfaceReadiness(capabilities);
    final deferredCount = surfaceItems
        .where((item) => item.status == HermesSurfaceStatus.deferred)
        .length;
    final blockedCount = surfaceItems
        .where((item) => item.status == HermesSurfaceStatus.blocked)
        .length;
    final chips = <Widget>[
      if (policy.supportsRunsTransport)
        const Chip(label: Text('Runs SSE enabled')),
      if (!policy.supportsRunsTransport && policy.supportsSessionChatStream)
        const Chip(label: Text('Session chat streaming enabled')),
      if (policy.supportsRealtimeVoice || policy.supportsAudioApi)
        const Chip(
          label: Text(
            'Server audio advertised; Navivox uses device STT -> Hermes text',
          ),
        )
      else
        const Chip(label: Text('Voice: device STT -> Hermes text')),
      if (detailedHealth?.version case final version?)
        Chip(
          label: Text(
            'Version: ${_safeHermesUiPreview(version, maxLength: 48)}',
          ),
        ),
      if (detailedHealth?.gatewayState case final gatewayState?)
        Chip(
          label: Text(
            'Gateway: ${_safeHermesUiPreview(gatewayState, maxLength: 48)}',
          ),
        ),
      if (detailedHealth != null)
        Chip(label: Text('Active agents: ${detailedHealth!.activeAgents}')),
      if (models.isNotEmpty)
        ActionChip(
          key: const ValueKey('hermes-models-chip'),
          label: Text(
            'Models: ${models.take(2).map((model) => _safeHermesUiPreview(model, maxLength: 48)).join(', ')}',
          ),
          onPressed: () => _showList(context, 'Hermes models', models),
        ),
      if (skills.isNotEmpty)
        ActionChip(
          key: const ValueKey('hermes-skills-chip'),
          label: Text('Skills: ${skills.length}'),
          onPressed: () => _showList(context, 'Hermes skills', skills),
        ),
      if (enabledToolsets.isNotEmpty)
        ActionChip(
          key: const ValueKey('hermes-toolsets-chip'),
          label: Text('Toolsets enabled: ${enabledToolsets.length}'),
          onPressed: () =>
              _showList(context, 'Hermes toolsets', enabledToolsets),
        ),
      if (jobs.isNotEmpty)
        ActionChip(
          key: const ValueKey('hermes-jobs-chip'),
          label: Text('Jobs: ${jobs.length}'),
          onPressed: () => _showJobs(context),
        ),
      ActionChip(
        key: const ValueKey('hermes-surfaces-chip'),
        label: Text('Surfaces: $deferredCount deferred, $blockedCount blocked'),
        onPressed: () => _showSurfaceReadiness(context),
      ),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Card(
        key: const ValueKey('hermes-capability-strip'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Hermes Agent ${_safeHermesUiPreview(capabilities.model, maxLength: 96)}',
              ),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: chips),
            ],
          ),
        ),
      ),
    );
  }
}

class _ApprovalBanner extends StatelessWidget {
  const _ApprovalBanner({
    required this.request,
    required this.pendingCount,
    required this.responding,
    required this.canRespond,
    required this.onDecide,
    required this.onDismissMalformed,
  });

  final NavivoxApprovalRequest request;
  final int pendingCount;
  final bool responding;
  final bool canRespond;
  final ValueChanged<HermesApprovalDecision> onDecide;
  final VoidCallback onDismissMalformed;

  @override
  Widget build(BuildContext context) {
    final risk = request.risk;
    final hasApprovalId = request.id.trim().isNotEmpty;
    final canAnswer = canRespond && hasApprovalId;
    return Material(
      key: const ValueKey('hermes-approval-banner'),
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (pendingCount > 1)
              Text(
                '$pendingCount pending approvals',
                key: const ValueKey('hermes-approval-pending-count'),
              ),
            Text(_safeHermesUiPreview(request.prompt, maxLength: 240)),
            if (risk != null)
              Text('Risk: ${_safeHermesUiPreview(risk, maxLength: 120)}'),
            if (!canRespond) ...[
              const SizedBox(height: 8),
              const Text(
                'Hermes did not advertise approval responses for this run.',
                key: ValueKey('hermes-approval-response-unavailable'),
              ),
            ] else if (!hasApprovalId) ...[
              const SizedBox(height: 8),
              const Text(
                'Hermes sent this approval without an approval id, so it cannot be answered.',
                key: ValueKey('hermes-approval-id-missing'),
              ),
            ],
            if (responding) ...[
              const SizedBox(height: 8),
              const LinearProgressIndicator(
                key: ValueKey('hermes-approval-responding'),
              ),
              const SizedBox(height: 4),
              const Text('Answering Hermes approval…'),
            ],
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  key: const ValueKey('hermes-approval-review'),
                  onPressed: responding
                      ? null
                      : () => _showApprovalSheet(context),
                  icon: const Icon(Icons.security_outlined),
                  label: const Text('Review'),
                ),
                if (!hasApprovalId)
                  TextButton(
                    key: const ValueKey('hermes-approval-dismiss-malformed'),
                    onPressed: responding ? null : onDismissMalformed,
                    child: const Text('Dismiss'),
                  ),
                TextButton(
                  key: const ValueKey('hermes-approval-deny'),
                  onPressed: responding || !canAnswer
                      ? null
                      : () => onDecide(HermesApprovalDecision.deny),
                  child: const Text('Deny'),
                ),
                OutlinedButton(
                  key: const ValueKey('hermes-approval-session'),
                  onPressed: responding || !canAnswer
                      ? null
                      : () => unawaited(_confirmSessionAllow(context)),
                  child: const Text('Allow for session'),
                ),
                OutlinedButton(
                  key: const ValueKey('hermes-approval-always'),
                  onPressed: responding || !canAnswer
                      ? null
                      : () => unawaited(_confirmAlwaysAllow(context)),
                  child: const Text('Always allow'),
                ),
                FilledButton(
                  key: const ValueKey('hermes-approval-once'),
                  onPressed: responding || !canAnswer
                      ? null
                      : () => onDecide(HermesApprovalDecision.once),
                  child: const Text('Approve once'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmSessionAllow(
    BuildContext context, {
    bool closeSheetOnConfirm = false,
  }) async {
    final risk = request.risk;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const ValueKey('hermes-approval-session-confirm-dialog'),
        title: const Text('Allow this for the session?'),
        content: Text(
          '${_safeHermesUiPreview(request.prompt, maxLength: 240)}'
          '${risk == null ? '' : '\nRisk: ${_safeHermesUiPreview(risk, maxLength: 160)}'}\n\n'
          'This may approve matching requests for the current Hermes session.',
        ),
        actions: [
          TextButton(
            key: const ValueKey('hermes-approval-session-cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('hermes-approval-session-confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Allow for session'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (closeSheetOnConfirm && context.mounted) {
      Navigator.of(context).pop();
    }
    onDecide(HermesApprovalDecision.session);
  }

  Future<void> _confirmAlwaysAllow(
    BuildContext context, {
    bool closeSheetOnConfirm = false,
  }) async {
    final risk = request.risk;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const ValueKey('hermes-approval-always-confirm-dialog'),
        title: const Text('Always allow this Hermes approval?'),
        content: Text(
          '${_safeHermesUiPreview(request.prompt, maxLength: 240)}'
          '${risk == null ? '' : '\nRisk: ${_safeHermesUiPreview(risk, maxLength: 160)}'}\n\n'
          'This may approve matching future requests without asking again.',
        ),
        actions: [
          TextButton(
            key: const ValueKey('hermes-approval-always-cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('hermes-approval-always-confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Always allow'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (closeSheetOnConfirm && context.mounted) {
      Navigator.of(context).pop();
    }
    onDecide(HermesApprovalDecision.always);
  }

  void _showApprovalSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        final risk = request.risk;
        final hasApprovalId = request.id.trim().isNotEmpty;
        final canAnswer = canRespond && hasApprovalId;
        final safePrompt = _safeHermesUiText(request.prompt);
        final promptTruncated = safePrompt.length > 600;
        final safeRisk = risk == null ? null : _safeHermesUiText(risk);
        final riskTruncated = (safeRisk?.length ?? 0) > 240;
        final safeToolCallId = _safeHermesUiText(request.toolCallId);
        final approvalSummary = _approvalReviewSummary(
          safePrompt: safePrompt,
          safeRisk: safeRisk,
          safeToolCallId: safeToolCallId,
          hasApprovalId: hasApprovalId,
        );
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              key: const ValueKey('hermes-approval-sheet-scroll'),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Review Hermes approval',
                    style: Theme.of(sheetContext).textTheme.titleLarge,
                  ),
                  if (pendingCount > 1) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Reviewing 1 of $pendingCount pending approvals',
                      key: const ValueKey(
                        'hermes-approval-sheet-pending-count',
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  SelectableText(
                    _safeHermesUiPreview(safePrompt, maxLength: 600),
                    key: const ValueKey('hermes-approval-sheet-prompt'),
                  ),
                  if (promptTruncated)
                    const Text(
                      'Prompt preview truncated for mobile review.',
                      key: ValueKey('hermes-approval-sheet-prompt-truncated'),
                    ),
                  if (safeRisk != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Risk: ${_safeHermesUiPreview(safeRisk, maxLength: 240)}',
                      key: const ValueKey('hermes-approval-sheet-risk'),
                    ),
                    if (riskTruncated)
                      const Text(
                        'Risk preview truncated for mobile review.',
                        key: ValueKey('hermes-approval-sheet-risk-truncated'),
                      ),
                  ],
                  if (request.toolCallId.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Tool call: ${_safeHermesUiPreview(safeToolCallId, maxLength: 160)}',
                    ),
                  ],
                  if (!canRespond) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Decision buttons are disabled because Hermes did not advertise /v1/runs/{run_id}/approval.',
                    ),
                  ] else if (!hasApprovalId) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Decision buttons are disabled because Hermes did not include an approval id.',
                    ),
                  ],
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        key: const ValueKey('hermes-approval-sheet-copy'),
                        onPressed: () {
                          unawaited(
                            Clipboard.setData(
                              ClipboardData(text: approvalSummary),
                            ),
                          );
                          ScaffoldMessenger.maybeOf(sheetContext)?.showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Copied redacted Hermes approval details.',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy_outlined),
                        label: const Text('Copy details'),
                      ),
                      TextButton(
                        key: const ValueKey('hermes-approval-sheet-close'),
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        child: const Text('Close'),
                      ),
                      if (!hasApprovalId)
                        TextButton(
                          key: const ValueKey(
                            'hermes-approval-sheet-dismiss-malformed',
                          ),
                          onPressed: () {
                            Navigator.of(sheetContext).pop();
                            onDismissMalformed();
                          },
                          child: const Text('Dismiss'),
                        ),
                      TextButton(
                        key: const ValueKey('hermes-approval-sheet-deny'),
                        onPressed: canAnswer
                            ? () {
                                Navigator.of(sheetContext).pop();
                                onDecide(HermesApprovalDecision.deny);
                              }
                            : null,
                        child: const Text('Deny'),
                      ),
                      OutlinedButton(
                        key: const ValueKey('hermes-approval-sheet-session'),
                        onPressed: canAnswer
                            ? () => unawaited(
                                _confirmSessionAllow(
                                  sheetContext,
                                  closeSheetOnConfirm: true,
                                ),
                              )
                            : null,
                        child: const Text('Allow for session'),
                      ),
                      OutlinedButton(
                        key: const ValueKey('hermes-approval-sheet-always'),
                        onPressed: canAnswer
                            ? () => unawaited(
                                _confirmAlwaysAllow(
                                  sheetContext,
                                  closeSheetOnConfirm: true,
                                ),
                              )
                            : null,
                        child: const Text('Always allow'),
                      ),
                      FilledButton(
                        key: const ValueKey('hermes-approval-sheet-once'),
                        onPressed: canAnswer
                            ? () {
                                Navigator.of(sheetContext).pop();
                                onDecide(HermesApprovalDecision.once);
                              }
                            : null,
                        child: const Text('Approve once'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _approvalReviewSummary({
    required String safePrompt,
    required String? safeRisk,
    required String safeToolCallId,
    required bool hasApprovalId,
  }) {
    final buffer = StringBuffer()
      ..writeln('Hermes approval review')
      ..writeln('Prompt: ${_safeHermesUiPreview(safePrompt, maxLength: 600)}');
    if (safeRisk != null) {
      buffer.writeln('Risk: ${_safeHermesUiPreview(safeRisk, maxLength: 240)}');
    }
    if (safeToolCallId.trim().isNotEmpty) {
      buffer.writeln(
        'Tool call: ${_safeHermesUiPreview(safeToolCallId, maxLength: 160)}',
      );
    }
    buffer
      ..writeln('Approval id present: $hasApprovalId')
      ..write('Pending approvals: $pendingCount');
    return buffer.toString();
  }
}

class _ToolCallCard extends StatelessWidget {
  const _ToolCallCard({required this.turnId, required this.toolCall});

  final String turnId;
  final HermesToolCall toolCall;

  @override
  Widget build(BuildContext context) {
    final icon = switch (toolCall.status) {
      'completed' => Icons.check_circle_outline,
      'failed' => Icons.error_outline,
      _ => Icons.hourglass_top_outlined,
    };
    final detail = toolCall.result ?? toolCall.preview;
    return Card(
      key: ValueKey('hermes-tool-turn-$turnId'),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        dense: true,
        leading: Icon(icon),
        title: Text(
          _safeHermesUiPreview(toolCall.name, maxLength: 80),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: detail != null
            ? Text(
                _safeHermesUiPreview(detail, maxLength: 160),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              )
            : null,
      ),
    );
  }
}

class _TurnBubble extends StatelessWidget {
  const _TurnBubble({required this.turn});

  final HermesChatTurn turn;

  @override
  Widget build(BuildContext context) {
    final toolCall = turn.toolCall;
    if (turn.kind == HermesTurnKind.toolCall && toolCall != null) {
      return _ToolCallCard(turnId: turn.id, toolCall: toolCall);
    }
    final isUser = turn.author == HermesTurnAuthor.user;
    final streaming = turn.status == HermesTurnStatus.streaming;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        key: ValueKey('hermes-turn-${turn.id}'),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: const BoxConstraints(maxWidth: 480),
        decoration: BoxDecoration(
          color: isUser
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: Text(turn.text)),
            if (streaming) ...[
              const SizedBox(width: 8),
              const SizedBox(
                height: 12,
                width: 12,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
