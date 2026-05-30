import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../router/navigation_intent.dart';

import '../../../core/channel/navivox_channel.dart';
import '../../../core/channel/navivox_channel_provider.dart';
import '../../../core/protocol/navivox_event.dart';
import '../../../router/app_routes.dart';
import '../../profile_contacts/profile_contact_avatar.dart';
import '../../settings/providers/voice_settings_provider.dart';
import '../../voice/services/platform/default_voice_capture_service.dart';
import '../../voice/services/tts/text_to_speech_service.dart';
import '../../voice/services/capture/voice_capture_service.dart';
import '../presentation/chat_screen_presentation.dart';
import '../forwarding/forward_message_intent.dart';
import '../commands/local_command_dispatcher.dart';
import '../commands/local_command_intent.dart';
import '../transcript/presentation/transcript_message_action_presentation.dart';
import '../voice/controllers/voice_run_controller.dart';
import '../approval/approval_banner.dart';
import '../transcript/widgets/transcript_run_record_sheet.dart';
import '../transcript/widgets/transcript_surface.dart';

/// Voice-capture service used by the chat input bar. Override in tests with
/// [FakeVoiceCaptureService]; Android production uses platform speech-to-text.
final chatVoiceCaptureServiceProvider = Provider<VoiceCaptureService?>(
  (_) => createDefaultVoiceCaptureService(),
);

final chatVoiceCaptureReadinessProvider = FutureProvider<VoiceCaptureReadiness>(
  (_) => checkDefaultVoiceCaptureReadiness(),
);

final chatTextToSpeechServiceProvider = Provider<TextToSpeechService?>(
  (_) => null,
);

String? _readinessUnavailableReason(
  AsyncValue<VoiceCaptureReadiness>? readiness,
) {
  if (readiness == null) return null;
  return readiness.when(
    data: (value) => value.available
        ? null
        : value.unavailableReason ?? 'device STT unavailable',
    error: (_, _) => 'device STT unavailable',
    loading: () => null,
  );
}

bool? _readinessMicrophonePermissionGranted(
  AsyncValue<VoiceCaptureReadiness>? readiness,
) {
  if (readiness == null) return null;
  return readiness.when(
    data: (value) => value.diagnostics?.microphonePermissionGranted,
    error: (_, _) => null,
    loading: () => null,
  );
}

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    this.serverId,
    this.profileId,
    this.voiceCaptureServiceOverride,
    this.voiceAutoSendGrace = const Duration(milliseconds: 800),
    this.voiceCommandTimeout = const Duration(seconds: 5),
    super.key,
  });

  final String? serverId;
  final String? profileId;
  final VoiceCaptureService? voiceCaptureServiceOverride;
  final Duration voiceAutoSendGrace;
  final Duration voiceCommandTimeout;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with WidgetsBindingObserver {
  NavivoxChannel? _subscribed;
  final ForwardMessageIntent _forwardMessageIntent =
      const ForwardMessageIntent();
  final LocalCommandResolver _localCommandResolver =
      const LocalCommandResolver();
  final LocalCommandDispatcher _localCommandDispatcher =
      const LocalCommandDispatcher();
  final VoiceRunController _voiceRunController = VoiceRunController();
  Timer? _pendingVoiceTimer;
  Timer? _commandModeTimer;
  bool _commandMode = false;
  bool _routeProfileSynced = false;
  String? _lastRouteProfileKey;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  void _onChannelChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    _voiceRunController.clearRuntimeVoiceDisabledReason();
    ref.invalidate(chatVoiceCaptureReadinessProvider);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscribed?.removeListener(_onChannelChanged);
    _pendingVoiceTimer?.cancel();
    _commandModeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final channel = ref.watch(navivoxChannelProvider);
    if (!identical(_subscribed, channel)) {
      _subscribed?.removeListener(_onChannelChanged);
      channel.addListener(_onChannelChanged);
      _subscribed = channel;
    }
    _syncRouteProfile(channel);

    final state = channel.state;
    final voiceServiceOverride = widget.voiceCaptureServiceOverride;
    final voiceService =
        voiceServiceOverride ?? ref.watch(chatVoiceCaptureServiceProvider);
    final readiness = voiceServiceOverride == null && voiceService != null
        ? ref.watch(chatVoiceCaptureReadinessProvider)
        : null;
    final readinessUnavailableReason = _readinessUnavailableReason(readiness);
    final localMicrophonePermissionGranted =
        _readinessMicrophonePermissionGranted(readiness);
    final localVoiceCaptureChecking = readiness?.isLoading == true;
    final localVoiceCaptureAvailable =
        voiceService != null &&
        !localVoiceCaptureChecking &&
        readinessUnavailableReason == null;
    final textToSpeechService = ref.watch(chatTextToSpeechServiceProvider);
    final voiceSettings = ref.watch(navivoxVoiceSettingsProvider);
    final presentation = ChatScreenPresentation.fromState(
      state: state,
      voiceSettings: voiceSettings,
      localVoiceCaptureAvailable: localVoiceCaptureAvailable,
      localVoiceCaptureChecking: localVoiceCaptureChecking,
      localVoiceCaptureUnavailableReason: readinessUnavailableReason,
      localMicrophonePermissionGranted: localMicrophonePermissionGranted,
      runtimeVoiceDisabledReason:
          _voiceRunController.runtimeVoiceDisabledReason,
      notice: _voiceRunController.notice,
      commandMode: _commandMode,
    );
    final activeProfile = presentation.activeProfile;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            final router = GoRouter.maybeOf(context);
            if (router != null) {
              router.go(AppRoutes.chats);
              return;
            }
            Navigator.of(context).maybePop();
          },
        ),
        title: Row(
          children: [
            if (activeProfile != null) ...[
              ProfileContactAvatar(
                key: const ValueKey('chat-active-profile-avatar'),
                contact: activeProfile,
                radius: 18,
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    presentation.appBarTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (presentation.appBarSubtitle != null)
                    Text(
                      presentation.appBarSubtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            key: const ValueKey('chat-context-action'),
            tooltip: presentation.chatInfoTooltip,
            onPressed: () => _showChatInfo(context, presentation),
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: Column(
        children: [
          ApprovalBanner(channel: channel),
          _VoiceModeBanner(
            presentation: presentation.voiceMode,
            onTrustServer: activeProfile == null
                ? null
                : () => ref
                      .read(navivoxVoiceSettingsProvider.notifier)
                      .setServerTrusted(activeProfile.serverId, true),
            onCancelPending: _cancelPendingVoice,
          ),
          Expanded(
            child: TranscriptSurface(
              messages: presentation.transcriptMessages,
              onSend: (text) => _handleTextSubmit(channel, text),
              voiceCaptureService: presentation.voiceMode.ready
                  ? voiceService
                  : null,
              voiceUnavailableReason:
                  presentation.voiceMode.voiceCaptureUnavailableReason,
              voiceRecoveryAction: presentation.voiceMode.recoveryAction,
              onOpenVoiceSettings: () =>
                  NavigationIntent.go(context, const OpenSettings()),
              onUploadFile: () => _showAttachmentUnavailable(
                context,
                title: 'File upload unavailable',
                message:
                    'Gormes has not advertised a Navivox upload endpoint yet. Use text or workspace references for now.',
              ),
              onPickPhotoOrVideo: () => _showAttachmentUnavailable(
                context,
                title: 'Photo upload unavailable',
                message:
                    'Photo and video picking is ready to plug into the upload endpoint once Gormes enables uploads.',
              ),
              onOpenWorkspace: () =>
                  NavigationIntent.go(context, const OpenWorkspace()),
              textToSpeechService: textToSpeechService,
              assistantTypingLabel: presentation.assistantTypingLabel,
              onCancelActiveTurn: presentation.assistantTypingLabel != null
                  ? () => channel.cancelActiveTurn()
                  : null,
              onVoice: (capture) => _handleVoiceCapture(channel, capture),
              onVoiceCaptureStarted: () {
                _voiceRunController.startCapture(channel);
              },
              onVoiceCaptureFailed: (error) {
                _voiceRunController.captureFailed(channel, error);
                setState(() {});
              },
              forwardTargets: presentation.forwardTargets,
              onForward: (message, target) =>
                  _handleForward(channel, message: message, target: target),
              onInspectRunRecord: state.runRecordInspectionAvailable
                  ? (message) => _inspectRunRecord(channel, message)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAttachmentUnavailable(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.info_outline),
                title: Text(title),
                subtitle: Text(message),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showChatInfo(
    BuildContext context,
    ChatScreenPresentation presentation,
  ) {
    final theme = Theme.of(context);
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.64,
          minChildSize: 0.24,
          maxChildSize: 0.90,
          builder: (context, scrollController) => ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              Text(
                presentation.chatInfoTitle,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              for (final row in presentation.infoRows)
                _ChatInfoRow(
                  icon: _chatInfoIcon(row.kind),
                  label: row.label,
                  value: row.value,
                ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),
              for (final action in presentation.infoActions)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(_chatInfoActionIcon(action.kind)),
                  title: Text(action.title),
                  subtitle: Text(action.subtitle),
                  onTap: () => _handleChatInfoAction(context, action.kind),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleChatInfoAction(BuildContext context, ChatInfoActionKind kind) {
    Navigator.of(context).pop();
    NavigationIntent.go(context, switch (kind) {
      ChatInfoActionKind.openAgents => const OpenAgents(),
      ChatInfoActionKind.openWorkspace => const OpenWorkspace(),
      ChatInfoActionKind.openConfig => const OpenConfig(),
      ChatInfoActionKind.openSettings => const OpenSettings(),
      ChatInfoActionKind.manageGateways => const OpenGateways(),
    });
  }

  IconData _chatInfoActionIcon(ChatInfoActionKind kind) {
    return switch (kind) {
      ChatInfoActionKind.openAgents => Icons.people_alt_outlined,
      ChatInfoActionKind.openWorkspace => Icons.folder_open,
      ChatInfoActionKind.openConfig => Icons.settings_applications_outlined,
      ChatInfoActionKind.openSettings => Icons.settings_outlined,
      ChatInfoActionKind.manageGateways => Icons.dns_outlined,
    };
  }

  IconData _chatInfoIcon(ChatInfoRowKind kind) {
    return switch (kind) {
      ChatInfoRowKind.profile => Icons.person,
      ChatInfoRowKind.profileId => Icons.badge_outlined,
      ChatInfoRowKind.server => Icons.dns,
      ChatInfoRowKind.serverId => Icons.tag,
      ChatInfoRowKind.status => Icons.circle,
      ChatInfoRowKind.projects => Icons.folder_open,
      ChatInfoRowKind.agent => Icons.smart_toy,
      ChatInfoRowKind.selectProfile => Icons.chat_bubble_outline,
    };
  }

  NavivoxVoiceSettings _voiceSettings(WidgetRef ref) {
    return ref.read(navivoxVoiceSettingsProvider);
  }

  void _handleTextSubmit(NavivoxChannel channel, String text) {
    if (_handleLocalCommand(channel, text, fromVoice: false)) return;
    channel.sendText(text);
  }

  Future<void> _inspectRunRecord(
    NavivoxChannel channel,
    NavivoxChatMessage message,
  ) async {
    final runRecordId =
        TranscriptMessageActionPresentation.runRecordIdForMessage(message);
    if (runRecordId == null) return;
    try {
      final record = await channel.runRecord(runRecordId);
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.78,
          minChildSize: 0.32,
          maxChildSize: 0.94,
          builder: (context, scrollController) => TranscriptRunRecordSheet(
            record: record,
            scrollController: scrollController,
            key: const ValueKey('transcript-run-record-sheet'),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Run record unavailable.')));
    }
  }

  void _handleForward(
    NavivoxChannel channel, {
    required NavivoxChatMessage message,
    required NavivoxProfileContact target,
  }) {
    final result = _forwardMessageIntent.forward(
      channel,
      message: message,
      target: target,
    );
    if (!result.forwarded) return;
    final routeLocation = result.routeLocation;
    if (routeLocation != null) {
      GoRouter.maybeOf(context)?.go(routeLocation);
    }
    final snackbarMessage = result.snackbarMessage;
    if (snackbarMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(snackbarMessage)));
    }
  }

  void _handleVoiceCapture(NavivoxChannel channel, VoiceCapture capture) {
    _pendingVoiceTimer?.cancel();
    final result = _voiceRunController.captureSucceeded(
      channel,
      capture,
      handleLocalCommand: (transcript) =>
          _handleLocalCommand(channel, transcript, fromVoice: true),
    );
    final voiceRunId = result.scheduleAutoSendFor;
    if (voiceRunId == null) {
      if (result.handledLocalCommand) setState(() {});
      return;
    }

    setState(() {});
    _pendingVoiceTimer = Timer(widget.voiceAutoSendGrace, () {
      if (!mounted) return;
      final result = _voiceRunController.autoSendIfPending(channel, voiceRunId);
      if (result.submitted) setState(() {});
    });
  }

  void _cancelPendingVoice() {
    _pendingVoiceTimer?.cancel();
    _voiceRunController.cancelPending(_subscribed);
    setState(() {});
  }

  bool _handleLocalCommand(
    NavivoxChannel channel,
    String raw, {
    required bool fromVoice,
  }) {
    final settings = _voiceSettings(ref);
    final intent = _localCommandResolver.resolve(
      raw: raw,
      commandWord: settings.commandWord,
      commandMode: _commandMode,
      fromVoice: fromVoice,
      profileSwitchingEnabled: settings.profileSwitchingEnabled,
      contacts: channel.state.profileContacts,
    );
    if (!intent.consumesInput) return false;
    final result = _localCommandDispatcher.dispatch(channel, intent);
    return _applyLocalCommandDispatchResult(result);
  }

  void _enterCommandMode() {
    _commandModeTimer?.cancel();
    setState(() {
      _commandMode = true;
      _voiceRunController.notice = 'Command mode';
    });
    _commandModeTimer = Timer(widget.voiceCommandTimeout, () {
      if (!mounted) return;
      setState(() {
        _commandMode = false;
        _voiceRunController.notice = 'Command mode timed out.';
      });
    });
  }

  void _exitCommandMode({required bool clearNotice}) {
    _commandModeTimer?.cancel();
    if (!_commandMode && !clearNotice) return;
    setState(() {
      _commandMode = false;
      if (clearNotice) _voiceRunController.notice = null;
    });
  }

  bool _applyLocalCommandDispatchResult(LocalCommandDispatchResult result) {
    if (!result.consumed) return false;
    if (result.enterCommandMode) {
      _enterCommandMode();
      return true;
    }
    _exitCommandMode(clearNotice: false);
    if (result.cancelPendingVoice) {
      _cancelPendingVoice();
    }
    final routeLocation = result.routeLocation;
    if (routeLocation != null) {
      GoRouter.maybeOf(context)?.go(routeLocation);
    }
    final message = result.message;
    if (message != null) {
      _showCommandMessage(message);
    }
    return true;
  }

  void _showCommandMessage(String message) {
    setState(() => _voiceRunController.notice = message);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _syncRouteProfile(NavivoxChannel channel) {
    final serverId = widget.serverId;
    final profileId = widget.profileId;
    if (serverId == null || profileId == null) return;

    final key = '$serverId::$profileId';
    if (_lastRouteProfileKey != key) {
      _lastRouteProfileKey = key;
      _voiceRunController.clearRuntimeVoiceDisabledReason();
      _routeProfileSynced = false;
    }
    if (_routeProfileSynced) return;
    if (channel.state.selectedProfileContactKey == key &&
        channel.state.activeServerId == serverId) {
      _routeProfileSynced = true;
      return;
    }
    final exists = channel.state.profileContacts.any(
      (contact) =>
          contact.serverId == serverId && contact.profileId == profileId,
    );
    if (!exists) {
      _routeProfileSynced = true;
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (channel.state.selectedProfileContactKey == key &&
          channel.state.activeServerId == serverId) {
        _routeProfileSynced = true;
        return;
      }
      channel.selectProfileContact(serverId: serverId, profileId: profileId);
      _routeProfileSynced = true;
    });
  }
}

class _ChatInfoRow extends StatelessWidget {
  const _ChatInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label, style: theme.textTheme.labelLarge),
      subtitle: Text(value),
    );
  }
}

class _ContinuousVoiceLiveIndicator extends StatelessWidget {
  const _ContinuousVoiceLiveIndicator({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = active ? scheme.error : scheme.primary;
    return Row(
      key: const ValueKey('continuous-voice-live-indicator'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          key: const ValueKey('continuous-voice-live-dot'),
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        for (final height
            in active ? const [9.0, 14.0, 11.0] : const [7.0, 10.0, 8.0]) ...[
          Container(
            width: 3,
            height: height,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: active ? 0.9 : 0.55),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 2),
        ],
      ],
    );
  }
}

class _VoiceModeBanner extends StatelessWidget {
  const _VoiceModeBanner({
    required this.presentation,
    required this.onTrustServer,
    required this.onCancelPending,
  });

  final VoiceModePresentation presentation;
  final VoidCallback? onTrustServer;
  final VoidCallback onCancelPending;

  @override
  Widget build(BuildContext context) {
    final text = presentation.bannerText;
    if (text == null) return const SizedBox.shrink();
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: InkWell(
        key: const ValueKey('continuous-voice-banner'),
        onTap: () => _showVoiceControls(context),
        child: Semantics(
          button: true,
          enabled: true,
          hint: presentation.controlsSemanticsHint,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(
                  presentation.disabledReason == null
                      ? Icons.keyboard_voice
                      : Icons.mic_off,
                  size: 18,
                ),
                const SizedBox(width: 8),
                if (presentation.disabledReason == null) ...[
                  _ContinuousVoiceLiveIndicator(active: presentation.pending),
                  const SizedBox(width: 8),
                ],
                Expanded(child: Text(text)),
                const Icon(Icons.tune, size: 18),
                if (presentation.pending)
                  TextButton(
                    onPressed: onCancelPending,
                    child: Text(presentation.cancelPendingButtonLabel),
                  ),
                if (!presentation.pending && presentation.canTrustServer)
                  TextButton(
                    onPressed: onTrustServer,
                    child: Text(presentation.trustServerButtonLabel),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showVoiceControls(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: DraggableScrollableSheet(
          key: const ValueKey('continuous-voice-control-sheet'),
          expand: false,
          initialChildSize: 0.86,
          minChildSize: 0.32,
          maxChildSize: 0.86,
          builder: (context, scrollController) => ListView(
            controller: scrollController,
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              Text(
                presentation.sheetTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              for (final row in presentation.sheetRows)
                ListTile(
                  leading: Icon(_voiceControlRowIcon(row.kind)),
                  title: Text(row.title),
                  subtitle: row.subtitle == null ? null : Text(row.subtitle!),
                  onTap: _voiceControlRowTap(context, row.action),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _voiceControlRowIcon(VoiceControlRowKind kind) {
    return switch (kind) {
      VoiceControlRowKind.status =>
        presentation.disabledReason == null
            ? Icons.keyboard_voice
            : Icons.mic_off,
      VoiceControlRowKind.cancelPending => Icons.cancel_outlined,
      VoiceControlRowKind.recoveryAction => Icons.tips_and_updates_outlined,
      VoiceControlRowKind.openVoiceSettings => Icons.settings_voice_outlined,
      VoiceControlRowKind.diagnostics => Icons.fact_check_outlined,
      VoiceControlRowKind.androidRecognizer => Icons.android,
      VoiceControlRowKind.microphonePermission =>
        Icons.mic_external_on_outlined,
      VoiceControlRowKind.gatewayProfileStt => Icons.cloud_outlined,
      VoiceControlRowKind.commandWord => Icons.short_text,
      VoiceControlRowKind.howItWorks => Icons.record_voice_over,
      VoiceControlRowKind.trustServer => Icons.verified_user_outlined,
    };
  }

  VoidCallback? _voiceControlRowTap(
    BuildContext context,
    VoiceControlActionKind action,
  ) {
    return switch (action) {
      VoiceControlActionKind.none => null,
      VoiceControlActionKind.cancelPending => () {
        Navigator.of(context).pop();
        onCancelPending();
      },
      VoiceControlActionKind.openVoiceSettings => () {
        Navigator.of(context).pop();
        NavigationIntent.maybeGo(context, const OpenSettings());
      },
      VoiceControlActionKind.trustServer => () {
        Navigator.of(context).pop();
        onTrustServer?.call();
      },
    };
  }
}
