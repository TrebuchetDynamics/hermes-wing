import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:file_selector/file_selector.dart';
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
import '../../../l10n/app_localizations_en.dart';
import '../../../router/routes/app_routes.dart';
import '../../agents/providers/profile_selection_provider.dart';
import '../../../shared/async/fire_and_forget.dart';
import '../../../shared/voice/voice_capture_service.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../settings/providers/voice_settings_provider.dart';
import '../../voice/services/platform/default_voice_capture_service.dart';
import '../../voice/services/tts/text_to_speech_service.dart';
import '../attachments/hermes_attachment_content.dart';
import '../attachments/staged_attachment.dart';
import '../controllers/hermes_approval_queue.dart';
import '../controllers/hermes_connection_form.dart';
import '../controllers/hermes_voice_input_controller.dart';
import '../gateways/gateway_contact.dart';
import '../gateways/gateway_contacts_view.dart';
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

/// Voice-capture/TTS services for the Hermes chat screen.
final hermesVoiceCaptureServiceProvider = Provider<VoiceCaptureService?>(
  (_) => createDefaultVoiceCaptureService(),
);

final hermesAttachmentPickerProvider = Provider<Future<XFile?> Function()>(
  (_) => openFile,
);

final hermesTextToSpeechServiceProvider = Provider<TextToSpeechService?>((ref) {
  final settings = ref.watch(wingVoiceSettingsProvider);
  final platformService = createDefaultTextToSpeechService(
    settings: () => ref.read(wingVoiceSettingsProvider),
  );
  final service =
      settings.pocketSpeechTtsEnabled && settings.pocketSpeechVoicePackReady
      ? createPocketSpeechTextToSpeechService(
          enabled: true,
          voicePack: settings.pocketSpeechVoicePack!,
          settings: () => ref.read(wingVoiceSettingsProvider),
          fallback: platformService,
        )
      : platformService;
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
const _composerEmojis = [
  '😀',
  '😂',
  '🥰',
  '😍',
  '😊',
  '😉',
  '😎',
  '🤔',
  '👍',
  '👏',
  '🙏',
  '💪',
  '🎉',
  '🔥',
  '❤️',
  '✨',
  '✅',
  '👀',
  '💡',
  '🚀',
  '🤝',
  '💯',
  '🙌',
  '🫡',
];

enum _ComposerMenuAction { sessions, handsFree }

enum _TranscriptCopyFormat { text, markdown }

class _OpenSessionsIntent extends Intent {
  const _OpenSessionsIntent();
}

class _CreateSessionIntent extends Intent {
  const _CreateSessionIntent();
}

bool get _usesDesktopKeyboardShortcuts =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS);
String get _desktopShortcutModifier =>
    defaultTargetPlatform == TargetPlatform.macOS ? '⌘' : 'Ctrl';

bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;
String get _defaultHermesBaseUrl => _configuredHermesBaseUrl;
AppLocalizations _hermesStrings(BuildContext context) =>
    Localizations.of<AppLocalizations>(context, AppLocalizations) ??
    AppLocalizationsEn();

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
  late final HermesConnectionForm _connectionForm;
  final _composerController = TextEditingController();
  final _transcriptScrollController = ScrollController();
  late final HermesVoiceInputController _voiceInputController;
  StagedAttachment? _stagedAttachment;

  HermesChannel? _subscribed;
  late final ProviderSubscription<HermesChannel> _channelProviderSubscription;
  late final HermesApprovalQueue _approvals;
  String? _queuedFollowUpError;
  final Queue<_QueuedFollowUp> _queuedFollowUps = Queue<_QueuedFollowUp>();
  String? _observedSessionId;
  String? _completedAssistantSignature;
  bool _reconnectingOnResume = false;
  bool? _requestedShellNavigationVisible;
  late Future<List<HermesEndpointConfig>> _endpointProfilesFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _connectionForm = HermesConnectionForm(
      normalizeBaseUrl: hermesPublicEndpointBaseUrl,
      sanitizeLabel: _safeHermesUiText,
      initialBaseUrl: _defaultHermesBaseUrl,
    )..addListener(_onConnectionFormChanged);
    _connectionForm.baseUrl.addListener(_onConnectionFormChanged);
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
    )..addListener(_onVoiceInputChanged);
    _approvals = HermesApprovalQueue(
      channel: () => ref.read(hermesChannelProvider),
      onResolveError: _showApprovalError,
    )..addListener(_onApprovalsChanged);
    _channelProviderSubscription = ref.listenManual<HermesChannel>(
      hermesChannelProvider,
      (_, channel) => _subscribeToChannel(channel),
      fireImmediately: true,
    );
    _endpointProfilesFuture = _loadEndpointProfiles();
  }

  @override
  void dispose() {
    appShellNavigationVisible.value = true;
    WidgetsBinding.instance.removeObserver(this);
    _channelProviderSubscription.close();
    _voiceInputController.removeListener(_onVoiceInputChanged);
    _voiceInputController.dispose();
    _subscribed?.removeListener(_onChannelChanged);
    _approvals.removeListener(_onApprovalsChanged);
    _approvals.dispose();
    _connectionForm.baseUrl.removeListener(_onConnectionFormChanged);
    _connectionForm.removeListener(_onConnectionFormChanged);
    _connectionForm.dispose();
    _composerController.removeListener(_onComposerChanged);
    _composerController.dispose();
    _transcriptScrollController.dispose();
    super.dispose();
  }

  void _requestShellNavigation(bool visible) {
    if (_requestedShellNavigationVisible == visible) return;
    _requestedShellNavigationVisible = visible;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) appShellNavigationVisible.value = visible;
    });
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
    // pending approvals, an answering-approval marker, and continuous voice
    // capture. The transcript itself is replaced by the profile-scoped session
    // refresh inside selectProfile, so nothing from the prior profile is
    // retained here.
    _voiceInputController.pause(
      'Continuous voice paused while switching agents.',
    );
    setState(_approvals.reset);
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
    _observedSessionId = channel.state.activeSessionId;
    _completedAssistantSignature = _completedAssistantTurnSignature(
      channel.state,
    );
    _approvals.watch(channel);
    _onChannelChanged();
  }

  void _onApprovalsChanged() {
    if (mounted) setState(() {});
  }

  void _showApprovalError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Could not answer Hermes approval: ${_safeHermesUiError(error)}',
        ),
      ),
    );
  }

  bool _hasActiveGatewayWork(HermesChannel channel) =>
      channel.state.hasStreamingSessions ||
      _approvals.hasPendingWork ||
      _queuedFollowUps.isNotEmpty;

  Future<bool> _confirmLeaveActiveContact(HermesChannel channel) async {
    if (!_hasActiveGatewayWork(channel)) return true;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            key: const ValueKey('hermes-gateway-switch-confirm-dialog'),
            title: const Text('Switch chats?'),
            content: const Text(
              'This gateway has active work or an approval. Switching closes its live streams; Hermes remains authoritative and will reconcile them when reopened.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Stay'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Switch'),
              ),
            ],
          ),
        ) ??
        false;
  }

  String? _completedAssistantTurnSignature(HermesChannelState state) {
    final ids = <String>[
      for (final turns in state.messages.values)
        for (final turn in turns)
          if (turn.author == HermesTurnAuthor.assistant &&
              turn.status == HermesTurnStatus.completed)
            '${turn.sessionId}:${turn.id}',
    ]..sort();
    return ids.isEmpty ? null : ids.join('\u001f');
  }

  void _refreshActiveGatewayContact() {
    final directory = ref.read(hermesGatewayDirectoryProvider);
    final gatewayId = directory.activeContactId?.gatewayId;
    if (gatewayId == null) return;
    // This runs automatically after every completed turn and session action,
    // so a gateway that stopped being saved must not raise here.
    fireAndForget(
      directory.reconnectGateway(gatewayId),
      'active gateway contact refresh',
    );
  }

  Future<void> _showGatewayContacts() async {
    final channel = ref.read(hermesChannelProvider);
    if (!await _confirmLeaveActiveContact(channel) || !mounted) return;
    _voiceInputController.pause('Closed Hermes contact.');
    _queuedFollowUps.clear();
    _approvals.clearPending();
    await ref.read(hermesGatewayDirectoryProvider).showDirectory();
  }

  Future<void> _openGatewayContact(GatewayContactId id) async {
    final channel = ref.read(hermesChannelProvider);
    final directory = ref.read(hermesGatewayDirectoryProvider);
    if (directory.activeContactId != null &&
        directory.activeContactId != id &&
        !await _confirmLeaveActiveContact(channel)) {
      return;
    }
    _voiceInputController.pause('Switched Hermes contact.');
    _queuedFollowUps.clear();
    _approvals.clearPending();
    await directory.activate(id);
  }

  Future<void> _showTranscriptCopyOptions(
    BuildContext context,
    HermesChannelState state,
  ) async {
    final strings = _hermesStrings(context);
    final format = await showModalBottomSheet<_TranscriptCopyFormat>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              title: Text(strings.copyTranscriptAction),
              subtitle: Text(strings.copyTranscriptDescription),
            ),
            ListTile(
              key: const ValueKey('hermes-copy-transcript-text'),
              leading: const Icon(Icons.text_snippet_outlined),
              title: Text(strings.copyAsTextAction),
              onTap: () => Navigator.pop(context, _TranscriptCopyFormat.text),
            ),
            ListTile(
              key: const ValueKey('hermes-copy-transcript-markdown'),
              leading: const Icon(Icons.code_outlined),
              title: Text(strings.copyAsMarkdownAction),
              onTap: () =>
                  Navigator.pop(context, _TranscriptCopyFormat.markdown),
            ),
          ],
        ),
      ),
    );
    if (format == null || !context.mounted) return;
    await _copyTranscript(context, state, format);
  }

  Future<void> _copyTranscript(
    BuildContext context,
    HermesChannelState state,
    _TranscriptCopyFormat format,
  ) async {
    final strings = _hermesStrings(context);
    final transcript = switch (format) {
      _TranscriptCopyFormat.text => _hermesTranscriptText(
        state.activeMessages,
        strings,
        session: state.activeSession,
      ),
      _TranscriptCopyFormat.markdown => _hermesTranscriptMarkdown(
        state.activeMessages,
        strings,
        session: state.activeSession,
      ),
    };
    if (transcript.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: transcript));
    if (!context.mounted) return;
    final label = format == _TranscriptCopyFormat.markdown
        ? strings.transcriptFormatMarkdown
        : strings.transcriptFormatText;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(strings.transcriptCopiedMessage(label))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final directory = ref.watch(hermesGatewayDirectoryProvider);
    final channel = ref.watch(hermesChannelProvider);
    final strings = _hermesStrings(context);
    final state = channel.state;
    final activeSession = state.activeSession;
    final compactAppBar = MediaQuery.sizeOf(context).width < 480;
    final hasGateways =
        directory.contacts.isNotEmpty || directory.hasSavedGateways;
    final legacyConnected = state.isConnected && !hasGateways;
    final showingDirectory =
        hasGateways && directory.activeContactId == null && !legacyConnected;
    final activeContact = directory.activeContact;
    _requestShellNavigation(activeContact == null);
    final desktopShortcuts = <ShortcutActivator, Intent>{
      if (_usesDesktopKeyboardShortcuts && state.isConnected) ...{
        const SingleActivator(LogicalKeyboardKey.keyK, control: true):
            const _OpenSessionsIntent(),
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true):
            const _OpenSessionsIntent(),
      },
      if (_usesDesktopKeyboardShortcuts &&
          state.isConnected &&
          _canCreateSession(state)) ...{
        const SingleActivator(LogicalKeyboardKey.keyN, control: true):
            const _CreateSessionIntent(),
        const SingleActivator(LogicalKeyboardKey.keyN, meta: true):
            const _CreateSessionIntent(),
      },
    };

    final scaffold = Scaffold(
      appBar: AppBar(
        leading: activeContact == null
            ? null
            : IconButton(
                key: const ValueKey('hermes-back-to-contacts'),
                tooltip: 'All chats',
                onPressed: () => unawaited(_showGatewayContacts()),
                icon: const Icon(Icons.arrow_back),
              ),
        title: activeContact == null
            ? Text(
                showingDirectory
                    ? 'Hermes'
                    : _safeHermesUiPreview(
                        activeSession?.title ?? 'Hermes',
                        maxLength: 96,
                      ),
              )
            : TextButton(
                key: const ValueKey('hermes-contact-header'),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => _showSessionsPanel(context, channel),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 17,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      child: Text(
                        activeContact.profileName.trim().isEmpty
                            ? '?'
                            : activeContact.profileName
                                  .trim()
                                  .characters
                                  .first
                                  .toUpperCase(),
                      ),
                    ),
                    const SizedBox(width: 9),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: compactAppBar ? 140 : 240,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activeContact.profileName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '${activeContact.gatewayLabel} · ${activeContact.availability.name}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color:
                                      activeContact.availability ==
                                          GatewayAvailability.online
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
        actions: [
          if (showingDirectory)
            IconButton(
              key: const ValueKey('hermes-connect-another-gateway'),
              tooltip: 'Connect another gateway',
              onPressed: () => context.push(AppRoutes.enroll),
              icon: const Icon(Icons.add_link),
            ),
          if (!showingDirectory && state.isConnected) ...[
            if (activeContact == null && state.profiles.isNotEmpty)
              _buildProfileSwitcher(context, channel, state),
            if (!compactAppBar) ...[
              IconButton(
                key: const ValueKey('hermes-sessions-button'),
                tooltip: _usesDesktopKeyboardShortcuts
                    ? strings.desktopSessionsShortcutTooltip(
                        _desktopShortcutModifier,
                      )
                    : 'Sessions',
                icon: const Icon(Icons.view_list_outlined),
                onPressed: () => _showSessionsPanel(context, channel),
              ),
              if (_canCreateSession(state))
                IconButton(
                  key: const ValueKey('hermes-new-session'),
                  tooltip: _usesDesktopKeyboardShortcuts
                      ? strings.desktopNewSessionShortcutTooltip(
                          _desktopShortcutModifier,
                        )
                      : 'New session',
                  icon: const Icon(Icons.add_comment_outlined),
                  onPressed: () => unawaited(_createSession(context, channel)),
                ),
            ],
            if (compactAppBar)
              PopupMenuButton<String>(
                key: const ValueKey('hermes-more-actions-button'),
                tooltip: 'More actions',
                onSelected: (action) {
                  switch (action) {
                    case 'sessions':
                      _showSessionsPanel(context, channel);
                    case 'new-session':
                      unawaited(_createSession(context, channel));
                    case 'copy-transcript':
                      unawaited(_showTranscriptCopyOptions(context, state));
                    case 'diagnostics':
                      _showDiagnosticsDialog(context, state);
                    case 'disconnect':
                      unawaited(_confirmDisconnect(context, channel));
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'sessions',
                    child: ListTile(
                      leading: Icon(Icons.view_list_outlined),
                      title: Text('Sessions'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  if (_canCreateSession(state))
                    const PopupMenuItem(
                      value: 'new-session',
                      child: ListTile(
                        leading: Icon(Icons.add_comment_outlined),
                        title: Text('New session'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  if (state.activeMessages.isNotEmpty)
                    PopupMenuItem(
                      value: 'copy-transcript',
                      child: ListTile(
                        leading: const Icon(Icons.copy_all_outlined),
                        title: Text(strings.copyTranscriptAction),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'diagnostics',
                    child: ListTile(
                      leading: Icon(Icons.info_outline),
                      title: Text('Diagnostics'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
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
              if (state.activeMessages.isNotEmpty)
                IconButton(
                  key: const ValueKey('hermes-copy-transcript-button'),
                  tooltip: strings.copyTranscriptAction,
                  icon: const Icon(Icons.copy_all_outlined),
                  onPressed: () =>
                      unawaited(_showTranscriptCopyOptions(context, state)),
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
                onPressed: () =>
                    unawaited(_confirmDisconnect(context, channel)),
              ),
            ],
          ],
        ],
      ),
      body: !hasGateways
          ? state.isConnected
                ? _buildChat(context, channel, state)
                : _buildConnectForm(context, channel, state)
          : showingDirectory
          ? GatewayContactsView(
              contacts: directory.contacts,
              refreshing: directory.refreshing,
              onRefresh: directory.refresh,
              onOpen: (id) => unawaited(_openGatewayContact(id)),
              onConnect: () => context.push(AppRoutes.enroll),
            )
          : state.isConnected
          ? _buildChat(context, channel, state)
          : const Center(child: CircularProgressIndicator()),
    );
    Widget content = scaffold;
    if (desktopShortcuts.isNotEmpty) {
      content = Shortcuts(
        shortcuts: desktopShortcuts,
        child: Actions(
          actions: <Type, Action<Intent>>{
            _OpenSessionsIntent: CallbackAction<_OpenSessionsIntent>(
              onInvoke: (_) {
                _showSessionsPanel(context, channel);
                return null;
              },
            ),
            _CreateSessionIntent: CallbackAction<_CreateSessionIntent>(
              onInvoke: (_) {
                unawaited(_createSession(context, channel));
                return null;
              },
            ),
          },
          child: Focus(autofocus: true, child: content),
        ),
      );
    }
    if (activeContact == null) return content;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_showGatewayContacts());
      },
      child: content,
    );
  }
}

String _hermesTranscriptText(
  List<HermesChatTurn> turns,
  AppLocalizations strings, {
  HermesSession? session,
}) => _hermesTranscriptSections(
  turns,
  strings: strings,
  markdown: false,
  session: session,
).join('\n\n');

String _hermesTranscriptMarkdown(
  List<HermesChatTurn> turns,
  AppLocalizations strings, {
  HermesSession? session,
}) => _hermesTranscriptSections(
  turns,
  strings: strings,
  markdown: true,
  session: session,
).join('\n\n');

List<String> _hermesTranscriptSections(
  List<HermesChatTurn> turns, {
  required AppLocalizations strings,
  required bool markdown,
  HermesSession? session,
}) {
  final sections = <String>[];
  if (session != null && _hasHermesExtendedSessionMetadata(session)) {
    final metadata = [
      'Session: ${_safeHermesUiPreview(session.title ?? session.id, maxLength: 96)}',
      'Session ID: ${_safeHermesUiPreview(session.id, maxLength: 120)}',
      if (session.model?.trim().isNotEmpty ?? false)
        'Model: ${_safeHermesUiPreview(session.model!.trim(), maxLength: 120)}',
      'Messages: ${session.messageCount}',
      ..._hermesExtendedSessionMetadataLines(session),
    ];
    sections.add(
      markdown
          ? ['## Session metadata', metadata.join('\n')].join('\n\n')
          : ['Session metadata', ...metadata].join('\n'),
    );
  }
  for (final turn in turns) {
    final toolCall = turn.toolCall;
    if (turn.kind == HermesTurnKind.toolCall && toolCall != null) {
      final detail = (toolCall.result ?? toolCall.preview)?.trim();
      final heading = strings.transcriptToolHeading(toolCall.name);
      sections.add(
        [
          markdown ? '## $heading' : heading,
          strings.transcriptToolStatus(toolCall.status),
          if (detail?.isNotEmpty ?? false) detail!,
        ].join(markdown ? '\n\n' : '\n'),
      );
      continue;
    }

    final text = turn.text.trim();
    if (text.isEmpty) continue;
    final author = turn.kind == HermesTurnKind.reasoning
        ? strings.reasoningTitle
        : switch (turn.author) {
            HermesTurnAuthor.user => strings.transcriptAuthorYou,
            HermesTurnAuthor.assistant => strings.transcriptAuthorHermes,
            HermesTurnAuthor.system => strings.transcriptAuthorSystem,
          };
    final usage = turn.usage;
    final usageText = usage == null
        ? null
        : strings.transcriptRunTokenUsage(
            usage.inputTokens,
            usage.outputTokens,
            usage.totalTokens,
          );
    sections.add(
      markdown
          ? [
              '## $author',
              text,
              if (usageText != null) '_${usageText}_',
            ].join('\n\n')
          : ['$author:', text, ?usageText].join('\n'),
    );
  }
  return sections;
}

class _LocalSlashCommand {
  const _LocalSlashCommand({
    required this.id,
    required this.command,
    required this.description,
    required this.icon,
  });

  final String id;
  final String command;
  final String description;
  final IconData icon;
}

class _QueuedFollowUp {
  const _QueuedFollowUp(this.text, this.sessionId);

  final String text;
  final String? sessionId;
}
