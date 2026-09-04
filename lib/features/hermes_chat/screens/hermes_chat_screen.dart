import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
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
import '../../../shared/security/wing_redaction.dart';
import '../../../l10n/app_localizations_en.dart';
import '../../../router/routes/app_routes.dart';
import '../../profiles/providers/profile_selection_provider.dart';
import '../../providers/widgets/model_picker_sheet.dart';
import '../widgets/session_model_picker_sheet.dart';
import '../../../shared/async/fire_and_forget.dart';
import '../../../shared/tips/wing_tip_card.dart';
import '../../../shared/tips/wing_tips.dart';
import '../../../shared/voice/text_to_speech_service.dart';
import '../../../shared/voice/voice_capture_service.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/wing_empty_state.dart';
import '../../settings/providers/chat_preferences_provider.dart';
import '../../settings/providers/voice_settings_provider.dart';
import '../../voice/services/platform/default_voice_capture_service.dart';
import '../../voice/services/platform/voice_capture_platform.dart';
import '../../voice/services/tts/hermes_agent_text_to_speech_service.dart';
import '../../voice/services/tts/platform_text_to_speech_service.dart';
import '../composer/attachments/hermes_attachment_content.dart';
import '../composer/attachments/hermes_image_attachment_normalizer.dart';
import '../composer/attachments/staged_attachment.dart';
import '../composer/hermes_composer_draft_store.dart';
import '../messaging/approvals/hermes_approval_queue.dart';
import '../controllers/hermes_channel_observation.dart';
import '../controllers/hermes_connection_form.dart';
import '../controllers/hermes_follow_up_queue.dart';
import '../voice/hermes_voice_failure.dart';
import '../voice/hermes_voice_input_controller.dart';
import '../gateways/gateway_contact.dart';
import '../gateways/gateway_contacts_view.dart';
import '../groups/chat_group_controller.dart';
import '../gateways/hermes_gateway_directory.dart';
import '../diagnostics/hermes_diagnostics_export.dart';
import '../providers/hermes_channel_provider.dart';
import '../session/hermes_session_pin_store.dart';
import '../widgets/hermes_profile_identity.dart';
import '../presentation/hermes_rich_text.dart';
import '../presentation/hermes_turn_presentation_identity.dart';
import '../presentation/hermes_transcript_viewport.dart';

part 'widgets/hermes_chat_error.dart';
part 'widgets/hermes_chat_sessions.dart';
part 'widgets/hermes_chat_status.dart';
part '../presentation/hermes_chat_timeline.dart';
part 'state/hermes_chat_lifecycle.dart';
part 'state/hermes_chat_layout.dart';
part 'state/hermes_chat_connection.dart';
part '../session/hermes_chat_session_actions.dart';
part '../composer/hermes_chat_message_flow.dart';

/// Voice-capture/TTS services for the Hermes chat screen.
final hermesVoiceCapturePlatformProvider = Provider<VoiceCapturePlatform>(
  (_) => currentVoiceCapturePlatform(),
);

final hermesVoiceCaptureServiceProvider = Provider<VoiceCaptureService?>((ref) {
  final platform = ref.watch(hermesVoiceCapturePlatformProvider);
  final languageMode = ref.watch(
    wingVoiceSettingsProvider.select((settings) => settings.languageMode),
  );
  final service = createDefaultVoiceCaptureService(
    platform: platform,
    localeId: languageMode.localeId,
  );
  ref.onDispose(() {
    if (service is VoiceCaptureLifecycleService) {
      fireAndForget(
        (service as VoiceCaptureLifecycleService).dispose(),
        'voice capture disposal',
      );
    } else if (service != null) {
      fireAndForget(service.cancel(), 'voice capture cancellation');
    }
  });
  return service;
});

final hermesAttachmentPickerProvider = Provider<Future<XFile?> Function()>(
  (_) => openFile,
);

typedef HermesAgentTtsFactory =
    TextToSpeechService Function(HermesSpeechSynthesizer synthesize);

final hermesAgentTtsFactoryProvider = Provider<HermesAgentTtsFactory>(
  (_) =>
      (synthesize) => HermesAgentTextToSpeechService(synthesize),
);

final hermesTextToSpeechServiceProvider = Provider<TextToSpeechService?>((ref) {
  final channel = ref.watch(hermesChannelProvider);
  final capabilities = ref.watch(
    hermesChannelStateProvider.select((state) => state.capabilities),
  );
  final TextToSpeechService service;
  if (channel is HermesAudioChannel &&
      capabilities != null &&
      HermesTransportPolicy(capabilities).supportsSpeechSynthesis) {
    service = ref.watch(hermesAgentTtsFactoryProvider)(
      (channel as HermesAudioChannel).synthesizeSpeech,
    );
  } else if (kIsWeb || defaultTargetPlatform != TargetPlatform.linux) {
    // Agent synthesis is authoritative when advertised. Device speech keeps
    // replies usable with older Agents that do not expose audio_api.
    service = PlatformTextToSpeechService();
  } else {
    return null;
  }
  ref.onDispose(
    () => fireAndForget(service.dispose(), 'Hermes Agent TTS disposal'),
  );
  return service;
});

const _hermesBaseUrlHint =
    'Local desktop/Linux/Windows/iOS simulator: http://127.0.0.1:8642\n'
    'Android emulator: http://10.0.2.2:8642\n'
    'Physical device: LAN/VPN/Tailscale URL';
const _maxQueuedFollowUps = 5;
const _maxComposerHistoryEntries = 50;
const _maxUnreadCompletedSessions = 64;
const _composerImageInsertionMimeTypes = <String>[
  'image/png',
  'image/jpeg',
  'image/gif',
  'image/webp',
];
const _configuredHermesBaseUrl = String.fromEnvironment('WING_HERMES_BASE_URL');
const _hermesLocalBaseUrl = 'http://127.0.0.1:8642';
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

enum _HermesConnectionMode { local, remote, vpn, ssh }

enum _TranscriptCopyFormat { text, markdown }

typedef _ComposerDraftKey = HermesComposerDraftKey;

const _maxComposerDraftEntries = 64;

final class _FailedDirectTurnPayload {
  const _FailedDirectTurnPayload({
    required this.sessionId,
    required this.text,
    this.imageDataUrl,
    this.textAttachment,
    this.attachmentName,
  });

  final String sessionId;
  final String text;
  final String? imageDataUrl;
  final String? textAttachment;
  final String? attachmentName;

  bool get hasAttachment => imageDataUrl != null || textAttachment != null;
}

class _OpenSessionsIntent extends Intent {
  const _OpenSessionsIntent();
}

class _CreateSessionIntent extends Intent {
  const _CreateSessionIntent();
}

class _CycleActiveSessionIntent extends Intent {
  const _CycleActiveSessionIntent(this.delta);

  final int delta;
}

class _SelectActiveSessionOrdinalIntent extends Intent {
  const _SelectActiveSessionOrdinalIntent(this.ordinal);

  final int ordinal;
}

const _activeSessionOrdinalKeys = <(LogicalKeyboardKey, int)>[
  (LogicalKeyboardKey.digit1, 1),
  (LogicalKeyboardKey.digit2, 2),
  (LogicalKeyboardKey.digit3, 3),
  (LogicalKeyboardKey.digit4, 4),
  (LogicalKeyboardKey.digit5, 5),
  (LogicalKeyboardKey.digit6, 6),
  (LogicalKeyboardKey.digit7, 7),
  (LogicalKeyboardKey.digit8, 8),
  (LogicalKeyboardKey.digit9, 9),
  (LogicalKeyboardKey.numpad1, 1),
  (LogicalKeyboardKey.numpad2, 2),
  (LogicalKeyboardKey.numpad3, 3),
  (LogicalKeyboardKey.numpad4, 4),
  (LogicalKeyboardKey.numpad5, 5),
  (LogicalKeyboardKey.numpad6, 6),
  (LogicalKeyboardKey.numpad7, 7),
  (LogicalKeyboardKey.numpad8, 8),
  (LogicalKeyboardKey.numpad9, 9),
];

List<HermesSession> _switchableHermesSessions(
  HermesChannelState state, {
  Set<String> retainedSessionIds = const {},
}) => [
  for (final session in state.sessions)
    if (session.id == state.activeSessionId ||
        state.isSessionStreaming(session.id) ||
        retainedSessionIds.contains(session.id))
      session,
];

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
/// docs/adr/client.md.
class HermesChatScreen extends ConsumerStatefulWidget {
  const HermesChatScreen({
    this.voiceCaptureServiceOverride,
    this.textToSpeechServiceOverride,
    this.initiallyEditingConnection = false,
    super.key,
  });

  final VoiceCaptureService? voiceCaptureServiceOverride;
  final TextToSpeechService? textToSpeechServiceOverride;
  final bool initiallyEditingConnection;

  @override
  ConsumerState<HermesChatScreen> createState() => _HermesChatScreenState();
}

class _HermesChatScreenState extends ConsumerState<HermesChatScreen>
    with WidgetsBindingObserver {
  late final HermesConnectionForm _connectionForm;
  final _composerController = TextEditingController();
  late final FocusNode _composerFocusNode;
  final _transcriptScrollController = ScrollController();
  late final _transcriptViewport = HermesTranscriptViewportController(
    _transcriptScrollController,
  );
  late final HermesVoiceInputController _voiceInputController;
  StagedAttachment? get _stagedAttachment => _activeComposerDraftKey == null
      ? null
      : _composerDrafts.read(_activeComposerDraftKey!).attachment;
  set _stagedAttachment(StagedAttachment? value) {
    _invalidateAttachmentPick();
    final key = _activeComposerDraftKey;
    if (key != null) {
      _composerDrafts.update(
        key,
        text: _composerController.text,
        attachment: value,
      );
    }
  }

  int _attachmentPickGeneration = 0;
  int _composerOwnerGeneration = 0;
  Object? _attachmentOwner;

  void _invalidateAttachmentPick() {
    _attachmentPickGeneration++;
    _pickingAttachment = false;
  }

  void _syncAttachmentOwner(HermesChannel channel) {
    final state = channel.state;
    final owner = (
      channel,
      state.isConnected,
      state.connectedBaseUrl,
      _gatewayDirectory.activeContactId,
      state.selectedProfileId,
      state.activeSessionId,
    );
    if (_attachmentOwner == owner) return;
    _attachmentOwner = owner;
    _composerOwnerGeneration++;
    _invalidateAttachmentPick();
  }

  _FailedDirectTurnPayload? _failedDirectTurn;
  String? _attachmentError;
  bool _pickingAttachment = false;
  int _selectedLocalSlashCommandIndex = 0;
  final Map<String, GlobalKey> _localSlashCommandKeys = {};
  final _localSlashSuggestionsKey = GlobalKey();
  String? _dismissedLocalSlashCommandDraft;
  final LinkedHashMap<_ComposerDraftKey, List<String>> _composerHistories =
      LinkedHashMap();
  final _composerDrafts = HermesComposerDraftStore();
  _ComposerDraftKey? _activeComposerDraftKey;
  _ComposerDraftKey? _activeComposerHistoryKey;
  int? _composerHistoryIndex;
  String _composerHistoryDraft = '';
  bool _applyingComposerHistory = false;
  bool _composerCompositionActive = false;
  int _composerCompositionRevision = 0;
  bool _initialComposerFocusScheduled = false;
  double? _transcriptPinchStartScale;
  bool _profileSwitchPending = false;

  HermesChannel? _subscribed;
  late final ProviderSubscription<HermesChannel> _channelProviderSubscription;
  late final ProviderSubscription<bool> _completionSoundSubscription;
  bool _completionSoundEnabled = false;
  late final HermesGatewayDirectory _gatewayDirectory;
  Set<String> _knownGatewayIds = {};
  late final ChatGroupController _chatGroupController;
  late final HermesSessionPinStore _sessionPins;
  late final HermesApprovalQueue _approvals;
  final HermesFollowUpQueue _followUps = HermesFollowUpQueue(
    capacity: _maxQueuedFollowUps,
  );
  final HermesChannelObservation _observation = HermesChannelObservation();
  final LinkedHashSet<String> _unreadCompletedSessionIds = LinkedHashSet();
  bool _reconnectingOnResume = false;
  bool _reconnectInFlight = false;
  _HermesConnectionMode _connectionMode = _HermesConnectionMode.remote;
  late bool _editingConnection;
  bool? _requestedShellNavigationVisible;
  late Future<List<HermesEndpointConfig>> _endpointProfilesFuture;

  void _startTranscriptPinch(ScaleStartDetails details) {
    if (details.pointerCount < 2) return;
    _transcriptPinchStartScale = ref
        .read(wingChatPreferencesProvider)
        .transcriptTextScale;
  }

  void _updateTranscriptPinch(ScaleUpdateDetails details) {
    final startScale = _transcriptPinchStartScale;
    if (startScale == null || details.pointerCount < 2) return;
    ref
        .read(wingChatPreferencesProvider.notifier)
        .setTranscriptTextScale(startScale * details.scale);
  }

  void _endTranscriptPinch(ScaleEndDetails details) {
    _transcriptPinchStartScale = null;
  }

  String _localizedVoiceFailureMessage(
    HermesVoiceFailure failure,
    String? detail,
  ) {
    final strings = AppLocalizations.of(context);
    return switch (failure) {
      HermesVoiceFailure.timedOut => strings.chatVoiceCaptureTimedOut,
      HermesVoiceFailure.microphonePermissionDenied =>
        strings.chatVoiceMicrophonePermissionDenied,
      HermesVoiceFailure.deviceLanguageUnavailable =>
        strings.chatVoiceDeviceLanguageUnavailable,
      HermesVoiceFailure.deviceSpeechUnavailable =>
        strings.chatVoiceDeviceSpeechUnavailable,
      HermesVoiceFailure.noSpeech => strings.chatVoiceNoSpeechDetected,
      HermesVoiceFailure.generic =>
        detail == null || detail.isEmpty
            ? strings.chatVoiceCaptureFailedFallback
            : strings.chatVoiceCaptureFailed(detail),
      HermesVoiceFailure.captureSessionChanged =>
        strings.chatVoiceCaptureSessionChanged,
      HermesVoiceFailure.inputUnavailable => strings.chatVoiceInputUnavailable,
      HermesVoiceFailure.turnSendFailed =>
        detail == null || detail.isEmpty
            ? strings.chatVoiceTurnSendFailedFallback
            : strings.chatVoiceTurnSendFailed(detail),
      HermesVoiceFailure.shutdownTimedOut => strings.chatVoiceShutdownTimedOut,
      HermesVoiceFailure.shutdownFailed => strings.chatVoiceShutdownFailed,
      HermesVoiceFailure.playbackUnavailable =>
        strings.chatVoicePlaybackUnavailable,
      HermesVoiceFailure.playbackUnavailableContinuous =>
        strings.chatVoicePlaybackUnavailableContinuous,
      HermesVoiceFailure.playbackFailed => strings.chatVoicePlaybackFailed,
      HermesVoiceFailure.playbackFailedContinuous =>
        strings.chatVoicePlaybackFailedContinuous,
      HermesVoiceFailure.playbackSessionChanged =>
        strings.chatVoicePlaybackSessionChanged,
      HermesVoiceFailure.playbackSessionChangedContinuous =>
        strings.chatVoicePlaybackSessionChangedContinuous,
      HermesVoiceFailure.pausedByLocalCommand =>
        strings.chatVoicePausedByLocalCommand,
    };
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _editingConnection = widget.initiallyEditingConnection;
    _connectionForm = HermesConnectionForm(
      normalizeBaseUrl: hermesPublicEndpointBaseUrl,
      sanitizeLabel: _safeHermesUiText,
      initialBaseUrl: _defaultHermesBaseUrl,
    )..addListener(_onConnectionFormChanged);
    _connectionForm.baseUrl.addListener(_onConnectionFormChanged);
    _composerFocusNode = FocusNode(
      debugLabel: 'Hermes composer',
      onKeyEvent: (_, event) => _handleLocalSlashCommandKeyEvent(
        event,
        ref.read(hermesChannelProvider),
      ),
    );
    HardwareKeyboard.instance.addHandler(_handleGlobalSlashCommandKeyEvent);
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
      failureMessage: _localizedVoiceFailureMessage,
      continuousPausedMessage: (message) =>
          AppLocalizations.of(context).chatVoiceContinuousPaused(message),
    )..addListener(_onVoiceInputChanged);
    _approvals = HermesApprovalQueue(
      channel: () => ref.read(hermesChannelProvider),
      onResolveError: _showApprovalError,
    )..addListener(_onApprovalsChanged);
    _gatewayDirectory = ref.read(hermesGatewayDirectoryProvider);
    _knownGatewayIds = _gatewayDirectory.gateways
        .map((gateway) => gateway.id)
        .toSet();
    _gatewayDirectory.addListener(_onGatewayDirectoryChanged);
    _chatGroupController = ChatGroupController();
    unawaited(_chatGroupController.load());
    _sessionPins = HermesSessionPinStore()..addListener(_onSessionPinsChanged);
    unawaited(_sessionPins.load());
    _completionSoundSubscription = ref.listenManual<bool>(
      wingVoiceSettingsProvider.select(
        (settings) => settings.completionSoundEnabled,
      ),
      (_, enabled) => _completionSoundEnabled = enabled,
      fireImmediately: true,
    );
    _channelProviderSubscription = ref.listenManual<HermesChannel>(
      hermesChannelProvider,
      (_, channel) => _subscribeToChannel(channel),
      fireImmediately: true,
    );
    _endpointProfilesFuture = _loadEndpointProfiles();
  }

  @override
  void didUpdateWidget(covariant HermesChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initiallyEditingConnection &&
        !oldWidget.initiallyEditingConnection) {
      _editingConnection = true;
    }
  }

  @override
  void dispose() {
    _gatewayDirectory.removeListener(_onGatewayDirectoryChanged);
    _composerDrafts.clear();
    _transcriptViewport.dispose();
    _invalidateAttachmentPick();
    final subscribed = _subscribed;
    _subscribed = null;
    subscribed?.removeListener(_onChannelChanged);
    appShellNavigationVisible.value = true;
    WidgetsBinding.instance.removeObserver(this);
    _channelProviderSubscription.close();
    _completionSoundSubscription.close();
    _voiceInputController.removeListener(_onVoiceInputChanged);
    _voiceInputController.dispose();
    _approvals.removeListener(_onApprovalsChanged);
    _approvals.dispose();
    _chatGroupController.dispose();
    _sessionPins.removeListener(_onSessionPinsChanged);
    _sessionPins.dispose();
    _connectionForm.baseUrl.removeListener(_onConnectionFormChanged);
    _connectionForm.removeListener(_onConnectionFormChanged);
    _connectionForm.dispose();
    _composerController.removeListener(_onComposerChanged);
    HardwareKeyboard.instance.removeHandler(_handleGlobalSlashCommandKeyEvent);
    _composerController.dispose();
    _composerFocusNode.dispose();
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

  void _selectConnectionMode(_HermesConnectionMode mode) {
    if (_connectionMode == mode) return;
    if ((mode == _HermesConnectionMode.local ||
            mode == _HermesConnectionMode.ssh) &&
        _connectionForm.baseUrl.text.trim().isEmpty) {
      _connectionForm.baseUrl.text = _hermesLocalBaseUrl;
    }
    setState(() => _connectionMode = mode);
  }

  void _onSessionPinsChanged() {
    if (mounted) setState(() {});
  }

  void _onGatewayDirectoryChanged() {
    final current = _gatewayDirectory.gateways
        .map((gateway) => gateway.id)
        .toSet();
    final removed = _knownGatewayIds.difference(current);
    _knownGatewayIds = current;
    if (removed.isEmpty) return;
    _composerDrafts.forgetWhere((key) => removed.contains(key.gatewayId));
    _transcriptViewport.forgetWhere(
      (owner) =>
          owner is HermesComposerDraftKey && removed.contains(owner.gatewayId),
    );
  }

  void _forgetComposerSession(HermesComposerDraftKey? owner, String sessionId) {
    if (owner == null) return;
    final key = (
      gatewayId: owner.gatewayId,
      profileId: owner.profileId,
      sessionId: sessionId,
    );
    _composerDrafts.forgetWhere((candidate) => candidate == key);
    _transcriptViewport.forgetWhere((candidate) => candidate == key);
  }

  void _cycleActiveSession(
    BuildContext context,
    HermesChannel channel,
    HermesChannelState state,
    int delta,
  ) {
    final sessions = _switchableHermesSessions(
      state,
      retainedSessionIds: _unreadCompletedSessionIds,
    );
    if (sessions.length < 2) return;
    final current = sessions.indexWhere(
      (session) => session.id == state.activeSessionId,
    );
    if (current < 0) return;
    final next = (current + delta) % sessions.length;
    unawaited(_selectSession(context, channel, sessions[next]));
  }

  void _selectActiveSessionOrdinal(
    BuildContext context,
    HermesChannel channel,
    HermesChannelState state,
    int ordinal,
  ) {
    final sessions = _switchableHermesSessions(
      state,
      retainedSessionIds: _unreadCompletedSessionIds,
    );
    if (sessions.length < 2) return;
    final index = ordinal == 9 ? sessions.length - 1 : ordinal - 1;
    if (index < 0 || index >= sessions.length) return;
    final session = sessions[index];
    if (session.id == state.activeSessionId) return;
    unawaited(_selectSession(context, channel, session));
  }

  GatewayContactId _sessionPinContact(HermesChannelState state) {
    return _gatewayDirectory.activeContactId ??
        GatewayContactId(
          gatewayId: 'direct',
          profileId: state.selectedProfileId ?? 'default',
        );
  }

  void _onComposerChanged() {
    final key = _activeComposerDraftKey;
    if (key != null) {
      _composerDrafts.update(
        key,
        text: _composerController.text,
        attachment: _stagedAttachment,
      );
    }
    final composing = _composerController.value.composing;
    final isComposing = composing.isValid && !composing.isCollapsed;
    final revision = ++_composerCompositionRevision;
    if (isComposing) {
      _composerCompositionActive = true;
    } else if (_composerCompositionActive) {
      scheduleMicrotask(() {
        if (_composerCompositionRevision == revision) {
          _composerCompositionActive = false;
        }
      });
    }
    _selectedLocalSlashCommandIndex = 0;
    if (_dismissedLocalSlashCommandDraft != _composerController.text) {
      _dismissedLocalSlashCommandDraft = null;
    }
    if (!_applyingComposerHistory) {
      _composerHistoryIndex = null;
      _composerHistoryDraft = '';
    }
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      fireAndForget(
        _reconnectAfterResumeIfRecoverable(),
        'Hermes reconnect after resume',
      );
    } else {
      _transcriptViewport.capture();
      _voiceInputController.pause(
        _hermesStrings(context).chatShellVoicePausedBackgroundBody,
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
    if (_usesDesktopKeyboardShortcuts) _composerFocusNode.requestFocus();
  }

  _ComposerDraftKey? _composerDraftKey(HermesChannelState state) {
    final sessionId = state.activeSessionId;
    final contact = _gatewayDirectory.activeContactId;
    final profileId = state.selectedProfileId ?? contact?.profileId;
    if (sessionId == null || !state.isConnected) {
      return null;
    }
    return (
      gatewayId: contact?.gatewayId ?? state.connectedBaseUrl ?? 'direct',
      profileId: profileId,
      sessionId: sessionId,
    );
  }

  _ComposerDraftKey? _composerHistoryKey(HermesChannelState state) {
    final sessionId = state.activeSessionId;
    if (sessionId == null) return null;
    final contact = _gatewayDirectory.activeContactId;
    return (
      gatewayId: contact?.gatewayId ?? 'direct',
      profileId: state.selectedProfileId ?? contact?.profileId ?? 'default',
      sessionId: sessionId,
    );
  }

  void _syncComposerDraft(HermesChannelState state) {
    final nextKey = _composerDraftKey(state);
    final nextHistoryKey = _composerHistoryKey(state);
    if (nextHistoryKey != _activeComposerHistoryKey) {
      _activeComposerHistoryKey = nextHistoryKey;
      _composerHistoryIndex = null;
      _composerHistoryDraft = '';
    }
    if (nextKey == _activeComposerDraftKey) return;
    _activeComposerDraftKey = nextKey;
    _transcriptViewport.setOwner(nextKey);
    _composerDrafts.activate(nextKey);
    _composerHistoryIndex = null;
    _composerHistoryDraft = '';
    final saved = nextKey == null
        ? const HermesComposerDraft()
        : _composerDrafts.read(nextKey);
    final draft = saved.text;
    _attachmentError = saved.attachmentEvicted
        ? AppLocalizations.of(context).chatAttachmentDraftEvicted
        : null;
    _composerController.value = TextEditingValue(
      text: draft,
      selection: TextSelection.collapsed(offset: draft.length),
    );
  }

  void _rememberComposerText(String text) {
    final prompt = text.trim();
    final key = _activeComposerHistoryKey;
    if (prompt.isEmpty || key == null) return;
    final history = _composerHistories.remove(key) ?? <String>[];
    history.add(prompt);
    if (history.length > _maxComposerHistoryEntries) history.removeAt(0);
    _composerHistories[key] = history;
    while (_composerHistories.length > _maxComposerDraftEntries) {
      _composerHistories.remove(_composerHistories.keys.first);
    }
    _composerHistoryIndex = null;
    _composerHistoryDraft = '';
  }

  String? _recallPreviousComposerText() {
    final key = _activeComposerHistoryKey;
    final history = key == null ? null : _composerHistories[key];
    if (history == null || history.isEmpty) return null;
    final currentIndex = _composerHistoryIndex;
    if (currentIndex == null) {
      _composerHistoryDraft = _composerController.text;
      _composerHistoryIndex = history.length - 1;
    } else if (currentIndex > 0) {
      _composerHistoryIndex = currentIndex - 1;
    }
    return history[_composerHistoryIndex!];
  }

  String? _recallNextComposerText() {
    final key = _activeComposerHistoryKey;
    final history = key == null ? null : _composerHistories[key];
    final currentIndex = _composerHistoryIndex;
    if (history == null || currentIndex == null) return null;
    if (currentIndex < history.length - 1) {
      _composerHistoryIndex = currentIndex + 1;
      return history[_composerHistoryIndex!];
    }
    _composerHistoryIndex = null;
    return _composerHistoryDraft;
  }

  void _applyComposerHistoryText(String text) {
    _applyingComposerHistory = true;
    try {
      _composerController.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    } finally {
      _applyingComposerHistory = false;
    }
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
      onPressed: _profileSwitchPending
          ? null
          : () => _showProfileSwitcher(context, channel, state),
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
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
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
      _hermesStrings(context).chatShellVoicePausedSwitchingAgentsBody,
    );
    setState(() {
      _profileSwitchPending = true;
      _approvals.reset();
    });
    try {
      final activeContact = _gatewayDirectory.activeContactId;
      if (activeContact == null) {
        await channel.selectProfile(profileId);
      } else {
        await _gatewayDirectory.selectProfileOnActiveGateway(
          profileId,
          discoveredProfile: channel.state.profiles
              .where((profile) => profile.id == profileId)
              .firstOrNull,
        );
      }
      if (!mounted) return;
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
    } finally {
      if (mounted) setState(() => _profileSwitchPending = false);
    }
  }

  void _subscribeToChannel(HermesChannel channel) {
    if (identical(_subscribed, channel)) return;
    _subscribed?.removeListener(_onChannelChanged);
    channel.addListener(_onChannelChanged);
    _subscribed = channel;
    _observation.adopt(channel.state);
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
          _hermesStrings(
            context,
          ).chatShellApprovalAnswerFailedBody(_safeHermesUiError(error)),
        ),
      ),
    );
  }

  bool _hasActiveGatewayWork(HermesChannel channel) =>
      channel.state.hasStreamingSessions ||
      _approvals.hasPendingWork ||
      _followUps.isNotEmpty;

  Future<bool> _confirmLeaveActiveContact(HermesChannel channel) async {
    if (!_hasActiveGatewayWork(channel)) return true;
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            final strings = AppLocalizations.of(dialogContext);
            return AlertDialog(
              key: const ValueKey('hermes-gateway-switch-confirm-dialog'),
              title: Text(strings.chatShellSwitchChatsTitle),
              content: Text(strings.chatShellSwitchChatsBody),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text(strings.chatShellStayAction),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: Text(strings.chatShellSwitchAction),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  void _refreshActiveGatewayContact() {
    final gatewayId = _gatewayDirectory.activeContactId?.gatewayId;
    if (gatewayId == null) return;
    // This runs automatically after every completed turn and session action,
    // so a gateway that stopped being saved must not raise here.
    fireAndForget(
      _gatewayDirectory.reconnectGateway(gatewayId),
      'active gateway contact refresh',
    );
  }

  Future<void> _showGatewayContacts() async {
    final channel = ref.read(hermesChannelProvider);
    if (!await _confirmLeaveActiveContact(channel) || !mounted) return;
    _voiceInputController.pause(
      _hermesStrings(context).chatShellContactClosedBody,
    );
    _followUps.clear();
    _approvals.clearPending();
    await ref.read(hermesGatewayDirectoryProvider).showDirectory();
  }

  Future<void> _openGatewayContact(GatewayContactId id) async {
    final strings = _hermesStrings(context);
    final channel = ref.read(hermesChannelProvider);
    final directory = ref.read(hermesGatewayDirectoryProvider);
    if (directory.activeContactId != null &&
        directory.activeContactId != id &&
        !await _confirmLeaveActiveContact(channel)) {
      return;
    }
    _voiceInputController.pause(strings.chatShellContactSwitchedBody);
    _followUps.clear();
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
    final unsupportedCapabilitySchema =
        state.capabilities?.supportsSchema == false;
    final canUseConnectedAgent =
        state.isConnected && !unsupportedCapabilitySchema;
    final activeSession = state.activeSession;
    final compactAppBar = MediaQuery.sizeOf(context).width < 480;
    final hasGateways =
        directory.contacts.isNotEmpty || directory.hasSavedGateways;
    final legacyConnected = state.isConnected && !hasGateways;
    final showingDirectory =
        !_editingConnection &&
        directory.activeContactId == null &&
        (hasGateways || !state.isConnected) &&
        !legacyConnected;
    final activeContact = directory.activeContact;
    if (state.isConnected) {
      _activeComposerDraftKey ??= _composerDraftKey(state);
      _activeComposerHistoryKey ??= _composerHistoryKey(state);
    }
    final selectedProfile = state.profiles
        .where((profile) => profile.id == state.selectedProfileId)
        .firstOrNull;
    final identityColor = hermesProfileColor(
      activeContact?.id.profileId ?? state.selectedProfileId ?? 'default',
      advertisedColor: selectedProfile?.color,
    );
    _requestShellNavigation(activeContact == null);
    final switchableSessions = _switchableHermesSessions(
      state,
      retainedSessionIds: _unreadCompletedSessionIds,
    );
    final desktopShortcuts = <ShortcutActivator, Intent>{
      if (_usesDesktopKeyboardShortcuts && canUseConnectedAgent) ...{
        const SingleActivator(LogicalKeyboardKey.keyK, control: true):
            const _OpenSessionsIntent(),
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true):
            const _OpenSessionsIntent(),
        if (switchableSessions.length > 1) ...{
          const SingleActivator(LogicalKeyboardKey.tab, control: true):
              const _CycleActiveSessionIntent(1),
          const SingleActivator(
            LogicalKeyboardKey.tab,
            control: true,
            shift: true,
          ): const _CycleActiveSessionIntent(
            -1,
          ),
          for (final entry in _activeSessionOrdinalKeys) ...{
            SingleActivator(entry.$1, control: true):
                _SelectActiveSessionOrdinalIntent(entry.$2),
            SingleActivator(entry.$1, meta: true):
                _SelectActiveSessionOrdinalIntent(entry.$2),
          },
        },
      },
      if (_usesDesktopKeyboardShortcuts &&
          canUseConnectedAgent &&
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
                tooltip: strings.chatShellAllChatsTooltip,
                onPressed: () => unawaited(_showGatewayContacts()),
                icon: const Icon(Icons.arrow_back),
              ),
        title: activeContact == null
            ? Text(
                _editingConnection
                    ? strings.chatLayoutConnectTitle
                    : showingDirectory
                    ? strings.agentsTitle
                    : _safeHermesUiPreview(
                        activeSession?.title ?? strings.chatShellHermesTitle,
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
                      key: const ValueKey('hermes-contact-avatar'),
                      radius: 17,
                      backgroundColor: identityColor,
                      foregroundColor: hermesProfileForeground(identityColor),
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
                            _contactProfileTitle(activeContact),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.circle,
                                size: 8,
                                color:
                                    activeContact.availability ==
                                        GatewayAvailability.online
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  activeContact.gatewayLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                            ],
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
              tooltip: strings.chatShellConnectAnotherGatewayTooltip,
              onPressed: () => context.push(AppRoutes.enroll),
              icon: const Icon(Icons.person_add_alt_1_outlined),
            ),
          if (!showingDirectory && canUseConnectedAgent) ...[
            if (state.profiles.isNotEmpty)
              _buildProfileSwitcher(context, channel, state),
            if (!compactAppBar) ...[
              IconButton(
                key: const ValueKey('hermes-sessions-button'),
                tooltip: _usesDesktopKeyboardShortcuts
                    ? strings.desktopSessionsShortcutTooltip(
                        _desktopShortcutModifier,
                      )
                    : strings.chatShellSessionsLabel,
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
                      : strings.chatShellNewSessionLabel,
                  icon: const Icon(Icons.add_comment_outlined),
                  onPressed: () => unawaited(_createSession(context, channel)),
                ),
            ],
            if (compactAppBar)
              PopupMenuButton<String>(
                key: const ValueKey('hermes-more-actions-button'),
                tooltip: strings.chatShellMoreActionsTooltip,
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
                  PopupMenuItem(
                    value: 'sessions',
                    child: ListTile(
                      leading: const Icon(Icons.view_list_outlined),
                      title: Text(strings.chatShellSessionsLabel),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  if (_canCreateSession(state))
                    PopupMenuItem(
                      value: 'new-session',
                      child: ListTile(
                        leading: const Icon(Icons.add_comment_outlined),
                        title: Text(strings.chatShellNewSessionLabel),
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
                  PopupMenuItem(
                    value: 'diagnostics',
                    child: ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: Text(strings.chatShellDiagnosticsLabel),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'disconnect',
                    child: ListTile(
                      leading: const Icon(Icons.logout_outlined),
                      title: Text(strings.chatShellDisconnectLabel),
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
                tooltip: strings.chatShellDiagnosticsLabel,
                icon: const Icon(Icons.info_outline),
                onPressed: () => _showDiagnosticsDialog(context, state),
              ),
              IconButton(
                key: const ValueKey('hermes-disconnect-button'),
                tooltip: strings.chatShellDisconnectLabel,
                icon: const Icon(Icons.logout_outlined),
                onPressed: () =>
                    unawaited(_confirmDisconnect(context, channel)),
              ),
            ],
          ],
          const AppShellMenuButton(),
        ],
      ),
      body: _editingConnection
          ? _buildConnectForm(context, channel, state)
          : showingDirectory
          ? GatewayContactsView(
              contacts: directory.contacts,
              refreshing: directory.refreshing,
              onRefresh: directory.refresh,
              onOpen: (id) => unawaited(_openGatewayContact(id)),
              onConnect: () => context.push(AppRoutes.enroll),
              groupController: _chatGroupController,
            )
          : unsupportedCapabilitySchema
          ? WingEmptyState(
              key: const ValueKey('hermes-unsupported-capability-schema'),
              icon: Icons.system_update_alt,
              title: strings.chatUnsupportedAgentTitle,
              body: strings.chatUnsupportedAgentBody,
              actionLabel: strings.chatShellDiagnosticsLabel,
              onAction: () => context.push(AppRoutes.settingsDiagnostics),
              liveRegion: true,
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
            _CycleActiveSessionIntent:
                CallbackAction<_CycleActiveSessionIntent>(
                  onInvoke: (intent) {
                    _cycleActiveSession(
                      context,
                      channel,
                      channel.state,
                      intent.delta,
                    );
                    return null;
                  },
                ),
            _SelectActiveSessionOrdinalIntent:
                CallbackAction<_SelectActiveSessionOrdinalIntent>(
                  onInvoke: (intent) {
                    _selectActiveSessionOrdinal(
                      context,
                      channel,
                      channel.state,
                      intent.ordinal,
                    );
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

String _contactProfileTitle(GatewayContact contact) {
  final value = contact.profileName.trim();
  if (value.isEmpty) return '?';
  final first = value.characters.first;
  return '${first.toUpperCase()}${value.substring(first.length)}';
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
      strings.chatShellTranscriptSessionLabel(
        _safeHermesUiPreview(session.title ?? session.id, maxLength: 96),
      ),
      strings.chatShellTranscriptSessionIdLabel(
        _safeHermesUiPreview(session.id, maxLength: 120),
      ),
      if (session.model?.trim().isNotEmpty ?? false)
        strings.sessionModelLabel(
          _safeHermesUiPreview(session.model!.trim(), maxLength: 120),
        ),
      strings.chatShellTranscriptMessageCountLabel(session.messageCount),
      ..._hermesExtendedSessionMetadataLines(strings, session),
    ];
    sections.add(
      markdown
          ? [
              '## ${strings.chatShellTranscriptSessionMetadataTitle}',
              metadata.join('\n'),
            ].join('\n\n')
          : [
              strings.chatShellTranscriptSessionMetadataTitle,
              ...metadata,
            ].join('\n'),
    );
  }
  for (final turn in turns) {
    final toolCall = turn.toolCall;
    if (turn.kind == HermesTurnKind.toolCall && toolCall != null) {
      final status = switch (toolCall.status) {
        'failed' => strings.chatTranscriptToolStatusNeedsAttentionLabel,
        'running' => strings.chatTranscriptToolStatusRunningLabel,
        _ => strings.chatTranscriptToolStatusCompletedLabel,
      };
      final heading = strings.chatTranscriptHostActivityTitle;
      sections.add(
        [
          markdown ? '## $heading' : heading,
          status,
        ].join(markdown ? '\n\n' : '\n'),
      );
      continue;
    }

    final text = _safeHermesUiText(turn.text.trim());
    final attachment = turn.attachment;
    final attachmentText = attachment == null
        ? null
        : attachment.kind == HermesAttachmentKind.image
        ? strings.chatImageAttachmentLabel(attachment.name)
        : strings.chatFileAttachmentLabel(attachment.name);
    if (text.isEmpty && attachmentText == null) continue;
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
              if (text.isNotEmpty) text,
              ?attachmentText,
              if (usageText != null) '_${usageText}_',
            ].join('\n\n')
          : [
              '$author:',
              if (text.isNotEmpty) text,
              ?attachmentText,
              ?usageText,
            ].join('\n'),
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
