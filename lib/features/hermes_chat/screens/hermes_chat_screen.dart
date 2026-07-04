import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/hermes/channel/hermes_channel.dart';
import '../../../core/hermes/models/hermes_capabilities.dart';
import '../../../core/hermes/models/hermes_chat_turn.dart';
import '../../../core/hermes/models/hermes_health.dart';
import '../../../core/hermes/models/hermes_session.dart';
import '../../../core/hermes/policy/hermes_surface_readiness.dart';
import '../../../core/hermes/policy/hermes_transport_policy.dart';
import '../../../shared/voice/text_to_speech_service.dart';
import '../../../shared/voice/voice_capture_service.dart';
import '../../chat/voice/controllers/transcript_voice_capture_flow.dart';
import '../../voice/services/platform/default_voice_capture_service.dart';
import '../controllers/hermes_continuous_voice_reply_policy.dart';
import '../controllers/hermes_voice_run_controller.dart';
import '../diagnostics/hermes_diagnostics_export.dart';
import '../providers/hermes_channel_provider.dart';

/// Voice-capture/TTS services for the Hermes chat screen, separate from the
/// Gormes `chat` feature's providers of the same shape.
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

/// Native Hermes Agent chat/session screen: manual connect, session list,
/// streamed transcript, text composer, and continuous voice. See
/// docs/adr/0007-native-hermes-channel-not-navivox-channel-adapter.md — this
/// does not reuse or relabel the Gormes-era chat screen.
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
  final _composerController = TextEditingController();
  final HermesVoiceRunController _voiceRunController =
      HermesVoiceRunController();

  HermesChannel? _subscribed;
  StreamSubscription<NavivoxApprovalRequest>? _approvalSubscription;
  bool _continuousVoiceEnabled = false;
  bool _capturing = false;
  String? _voiceError;
  String? _lastSpokenTurnId;
  NavivoxApprovalRequest? _pendingApproval;

  @override
  void dispose() {
    _subscribed?.removeListener(_onChannelChanged);
    _approvalSubscription?.cancel();
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    _composerController.dispose();
    super.dispose();
  }

  void _onChannelChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final channel = ref.watch(hermesChannelProvider);
    if (!identical(_subscribed, channel)) {
      _subscribed?.removeListener(_onChannelChanged);
      channel.addListener(_onChannelChanged);
      _subscribed = channel;
      unawaited(_approvalSubscription?.cancel());
      _approvalSubscription = channel.approvalRequests.listen((request) {
        if (mounted) setState(() => _pendingApproval = request);
      });
    }
    final state = channel.state;
    final activeSession = state.activeSession;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _maybeContinueVoiceLoop(channel);
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(activeSession?.title ?? 'Hermes'),
        actions: [
          if (state.isConnected) ...[
            IconButton(
              key: const ValueKey('hermes-sessions-button'),
              tooltip: 'Sessions',
              icon: const Icon(Icons.view_list_outlined),
              onPressed: () => _showSessionsPanel(context, channel),
            ),
            IconButton(
              key: const ValueKey('hermes-new-session'),
              tooltip: 'New session',
              icon: const Icon(Icons.add_comment_outlined),
              onPressed: () => unawaited(channel.createSession()),
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
              onPressed: () => unawaited(_disconnect(channel)),
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
    return Center(
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
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    key: const ValueKey('hermes-preset-local'),
                    label: const Text('Local Hermes'),
                    onPressed: connecting
                        ? null
                        : () =>
                              _baseUrlController.text = 'http://127.0.0.1:8642',
                  ),
                  ActionChip(
                    key: const ValueKey('hermes-preset-android'),
                    label: const Text('Android emulator'),
                    onPressed: connecting
                        ? null
                        : () =>
                              _baseUrlController.text = 'http://10.0.2.2:8642',
                  ),
                  ActionChip(
                    key: const ValueKey('hermes-preset-remote'),
                    label: const Text('Remote/LAN'),
                    onPressed: connecting
                        ? null
                        : () => _baseUrlController.clear(),
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
              const SizedBox(height: 16),
              if (state.status == HermesConnectionStatus.error &&
                  state.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    state.errorMessage!,
                    key: const ValueKey('hermes-connect-error'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
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
    );
  }

  Widget _buildChat(
    BuildContext context,
    HermesChannel channel,
    HermesChannelState state,
  ) {
    final pendingApproval = _pendingApproval;
    final hasActiveSession = state.activeSessionId != null;
    final isTurnActive =
        state.activeMessages.isNotEmpty &&
        state.activeMessages.last.status == HermesTurnStatus.streaming;
    return Column(
      children: [
        if (pendingApproval != null)
          _ApprovalBanner(
            request: pendingApproval,
            onDecide: (decision) => _resolveApproval(channel, decision),
          ),
        if (state.capabilities != null)
          _HermesCapabilityStrip(
            capabilities: state.capabilities!,
            detailedHealth: state.detailedHealth,
            models: state.models,
            skills: state.skills,
            enabledToolsets: state.enabledToolsets,
            jobs: state.jobs.map((job) => job.displayName).toList(),
          ),
        Expanded(
          child: state.activeSessionId == null
              ? const Center(
                  child: Text(
                    'No Hermes sessions. Create a new session to start chatting.',
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
        if (_voiceError != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              _voiceError!,
              key: const ValueKey('hermes-voice-error'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Switch(
                  key: const ValueKey('hermes-continuous-voice-switch'),
                  value: _continuousVoiceEnabled,
                  onChanged: (value) {
                    setState(() => _continuousVoiceEnabled = value);
                    if (value) unawaited(_captureOnce(channel));
                  },
                ),
                Expanded(
                  child: TextField(
                    key: const ValueKey('hermes-composer-field'),
                    controller: _composerController,
                    enabled: hasActiveSession,
                    decoration: const InputDecoration(
                      hintText: 'Message Hermes…',
                    ),
                    onSubmitted: (_) => _sendComposerText(channel),
                  ),
                ),
                if (isTurnActive)
                  IconButton(
                    key: const ValueKey('hermes-stop-button'),
                    tooltip: 'Stop',
                    icon: const Icon(Icons.stop_circle_outlined),
                    onPressed: () => channel.stopActiveTurn(),
                  ),
                IconButton(
                  key: const ValueKey('hermes-mic-button'),
                  tooltip: 'Speak',
                  icon: _capturing
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.mic_none_outlined),
                  onPressed: _capturing || !hasActiveSession
                      ? null
                      : () => unawaited(_captureOnce(channel)),
                ),
                IconButton(
                  key: const ValueKey('hermes-send-button'),
                  tooltip: 'Send',
                  icon: const Icon(Icons.send_outlined),
                  onPressed: hasActiveSession
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

  void _resolveApproval(
    HermesChannel channel,
    HermesApprovalDecision decision,
  ) {
    final request = _pendingApproval;
    if (request == null) return;
    channel.respondToApproval(approvalId: request.id, decision: decision);
    setState(() => _pendingApproval = null);
  }

  Future<void> _connect(HermesChannel channel) async {
    final baseUrl = _baseUrlController.text.trim();
    final apiKey = _apiKeyController.text.trim();
    await channel.connect(
      baseUrl: baseUrl,
      apiKey: apiKey.isEmpty ? null : apiKey,
    );
    if (channel.state.status != HermesConnectionStatus.connected) return;
    await ref
        .read(hermesEndpointStoreProvider)
        .save(baseUrl: baseUrl, apiKey: apiKey.isEmpty ? null : apiKey);
  }

  Future<void> _disconnect(HermesChannel channel) async {
    await channel.disconnect();
    await ref.read(hermesEndpointStoreProvider).clear();
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
      builder: (sheetContext) => _HermesSessionsPanel(
        state: channel.state,
        onCreate: () {
          Navigator.of(sheetContext).pop();
          unawaited(channel.createSession());
        },
        onSelect: (session) {
          Navigator.of(sheetContext).pop();
          unawaited(channel.selectSession(session.id));
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

  Future<void> _renameSession(
    BuildContext context,
    HermesChannel channel,
    HermesSession session,
  ) async {
    var draftTitle = session.title ?? '';
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
    if (title == null || title.isEmpty || title == session.title) return;
    try {
      await channel.renameSession(sessionId: session.id, title: title);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not rename session: $error')),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not fork session: $error')));
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
        content: Text('Delete "${session.title ?? session.id}" from Hermes?'),
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
        SnackBar(content: Text('Could not delete session: $error')),
      );
    }
  }

  void _sendComposerText(HermesChannel channel) {
    final text = _composerController.text.trim();
    if (text.isEmpty) return;
    _composerController.clear();
    unawaited(channel.sendText(text));
  }

  Future<void> _captureOnce(HermesChannel channel) async {
    if (_capturing) return;
    final service =
        widget.voiceCaptureServiceOverride ??
        ref.read(hermesVoiceCaptureServiceProvider);
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

    switch (outcome.status) {
      case TranscriptVoiceCaptureStatus.unavailable:
        setState(() => _voiceError = 'Voice input is not available here.');
        return;
      case TranscriptVoiceCaptureStatus.failed:
        setState(() => _voiceError = outcome.errorMessage);
        return;
      case TranscriptVoiceCaptureStatus.captured:
        final result = _voiceRunController.captureSucceeded(
          channel,
          outcome.capture!,
          handleLocalCommand: (_) => false,
        );
        final voiceRunId = result.scheduleAutoSendFor;
        if (voiceRunId != null) {
          _voiceRunController.autoSendIfPending(channel, voiceRunId);
        }
    }
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
    final speakFuture = tts?.speak(reply.text) ?? Future<void>.value();
    unawaited(
      speakFuture.whenComplete(() {
        if (mounted && _continuousVoiceEnabled) {
          unawaited(_captureOnce(channel));
        }
      }),
    );
  }
}

class _HermesSessionsPanel extends StatefulWidget {
  const _HermesSessionsPanel({
    required this.state,
    required this.onCreate,
    required this.onSelect,
    required this.onRename,
    required this.onFork,
    required this.onDelete,
  });

  final HermesChannelState state;
  final VoidCallback onCreate;
  final ValueChanged<HermesSession> onSelect;
  final ValueChanged<HermesSession> onRename;
  final ValueChanged<HermesSession> onFork;
  final ValueChanged<HermesSession> onDelete;

  @override
  State<_HermesSessionsPanel> createState() => _HermesSessionsPanelState();
}

class _HermesSessionsPanelState extends State<_HermesSessionsPanel> {
  var _query = '';

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
                (session) => [session.title, session.id, session.preview]
                    .whereType<String>()
                    .any((value) => value.toLowerCase().contains(query)),
              )
              .toList(growable: false);
    return SafeArea(
      child: SizedBox(
        height: 420,
        child: Column(
          children: [
            ListTile(
              title: Text(
                'Hermes sessions',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              trailing: FilledButton.icon(
                key: const ValueKey('hermes-sessions-new'),
                onPressed: widget.onCreate,
                icon: const Icon(Icons.add_comment_outlined),
                label: const Text('New'),
              ),
            ),
            if (allSessions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  key: const ValueKey('hermes-session-search-field'),
                  decoration: const InputDecoration(
                    labelText: 'Search sessions',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
              ),
            if (allSessions.isEmpty)
              const Expanded(
                child: Center(child: Text('No Hermes sessions yet.')),
              )
            else if (sessions.isEmpty)
              Expanded(
                child: Center(
                  child: Text('No Hermes sessions match “${_query.trim()}”.'),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  key: const ValueKey('hermes-sessions-list'),
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    final session = sessions[index];
                    final active = session.id == widget.state.activeSessionId;
                    return ListTile(
                      key: ValueKey('hermes-session-row-${session.id}'),
                      selected: active,
                      leading: active
                          ? const Icon(Icons.check_circle_outline)
                          : const Icon(Icons.chat_bubble_outline),
                      title: Text(
                        session.title ?? session.id,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        [
                          '${session.messageCount} messages',
                          if (session.preview != null) session.preview!,
                        ].join(' • '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => widget.onSelect(session),
                      trailing: PopupMenuButton<String>(
                        key: ValueKey('hermes-session-menu-${session.id}'),
                        tooltip: 'Session actions',
                        onSelected: (value) {
                          switch (value) {
                            case 'rename':
                              widget.onRename(session);
                            case 'fork':
                              widget.onFork(session);
                            case 'delete':
                              widget.onDelete(session);
                          }
                        },
                        itemBuilder: (context) => [
                          if (_canRename)
                            const PopupMenuItem(
                              value: 'rename',
                              child: Text('Rename'),
                            ),
                          if (_canFork)
                            const PopupMenuItem(
                              value: 'fork',
                              child: Text('Fork'),
                            ),
                          if (_canDelete)
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
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
  final List<String> jobs;

  void _showList(BuildContext context, String title, List<String> items) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [for (final item in items) ListTile(title: Text(item))],
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

  void _showSurfaceReadiness(BuildContext context) {
    final items = hermesSurfaceReadiness(capabilities);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hermes surface readiness'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
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
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
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
        const Chip(label: Text('Runs/tool progress enabled')),
      if (!policy.supportsRunsTransport && policy.supportsSessionChatStream)
        const Chip(label: Text('Session chat streaming enabled')),
      if (policy.supportsRealtimeVoice)
        const Chip(label: Text('Server voice advertised; using device STT'))
      else
        const Chip(label: Text('Voice uses device speech-to-text')),
      if (detailedHealth?.version case final version?)
        Chip(label: Text('Version: $version')),
      if (detailedHealth?.gatewayState case final gatewayState?)
        Chip(label: Text('Gateway: $gatewayState')),
      if (detailedHealth != null)
        Chip(label: Text('Active agents: ${detailedHealth!.activeAgents}')),
      if (models.isNotEmpty)
        ActionChip(
          key: const ValueKey('hermes-models-chip'),
          label: Text('Models: ${models.take(2).join(', ')}'),
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
          onPressed: () => _showList(context, 'Hermes jobs', jobs),
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
              Text('Hermes Agent ${capabilities.model}'),
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
  const _ApprovalBanner({required this.request, required this.onDecide});

  final NavivoxApprovalRequest request;
  final ValueChanged<HermesApprovalDecision> onDecide;

  @override
  Widget build(BuildContext context) {
    final risk = request.risk;
    return Material(
      key: const ValueKey('hermes-approval-banner'),
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(request.prompt),
            if (risk != null) Text('Risk: $risk'),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              children: [
                TextButton(
                  key: const ValueKey('hermes-approval-deny'),
                  onPressed: () => onDecide(HermesApprovalDecision.deny),
                  child: const Text('Deny'),
                ),
                OutlinedButton(
                  key: const ValueKey('hermes-approval-session'),
                  onPressed: () => onDecide(HermesApprovalDecision.session),
                  child: const Text('Allow for session'),
                ),
                OutlinedButton(
                  key: const ValueKey('hermes-approval-always'),
                  onPressed: () => onDecide(HermesApprovalDecision.always),
                  child: const Text('Always allow'),
                ),
                FilledButton(
                  key: const ValueKey('hermes-approval-once'),
                  onPressed: () => onDecide(HermesApprovalDecision.once),
                  child: const Text('Approve once'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
        title: Text(toolCall.name),
        subtitle: detail != null ? Text(detail) : null,
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
