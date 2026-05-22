import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/channel/navivox_channel.dart';
import '../../../core/channel/navivox_channel_provider.dart';
import '../../../core/protocol/navivox_event.dart';
import '../../../core/protocol/navivox_voice_run.dart';
import '../../../router/app_routes.dart';
import '../../settings/providers/voice_settings_provider.dart';
import '../../voice/services/text_to_speech_service.dart';
import '../../voice/services/voice_capture_service.dart';
import '../widgets/approval_banner.dart';
import '../widgets/transcript_surface.dart';

/// Voice-capture service used by the chat input bar. Override in tests with
/// [FakeVoiceCaptureService]; production wiring slots in
/// [RecordVoiceCaptureService] once the real mic + STT plugins land.
final chatVoiceCaptureServiceProvider = Provider<VoiceCaptureService?>(
  (_) => null,
);

final chatTextToSpeechServiceProvider = Provider<TextToSpeechService?>(
  (_) => null,
);

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

class _ChatScreenState extends ConsumerState<ChatScreen> {
  NavivoxChannel? _subscribed;
  String? _pendingVoiceRunId;
  Timer? _pendingVoiceTimer;
  Timer? _commandModeTimer;
  bool _commandMode = false;
  bool _routeProfileSynced = false;
  String? _lastRouteProfileKey;
  String? _voiceNotice;

  void _onChannelChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
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
    final server = state.activeServer;
    final activeProfile = state.activeProfileContact;
    final voiceService =
        widget.voiceCaptureServiceOverride ??
        ref.watch(chatVoiceCaptureServiceProvider);
    final textToSpeechService = ref.watch(chatTextToSpeechServiceProvider);
    final voiceSettings = ref.watch(navivoxVoiceSettingsProvider);
    final voiceDisabledReason = _voiceDisabledReason(
      voiceService: voiceService,
      activeProfile: activeProfile,
      settings: voiceSettings,
    );
    final voiceRecoveryAction = _voiceRecoveryAction(
      activeProfile,
      voiceDisabledReason,
    );
    final activeVoiceRun = state.activeVoiceRun;
    final pendingVoiceRun =
        activeVoiceRun?.status == NavivoxVoiceRunStatus.pendingSend
        ? activeVoiceRun
        : null;
    final adapterMessages = [
      ...state.messagesList,
      if (pendingVoiceRun != null)
        NavivoxChatMessage(
          id: 'pending-${pendingVoiceRun.id}',
          author: NavivoxMessageAuthor.user,
          kind: NavivoxMessageKind.voice,
          createdAt: pendingVoiceRun.createdAt,
          voice: NavivoxVoiceMessage(
            voiceRunId: pendingVoiceRun.id,
            duration: pendingVoiceRun.duration ?? Duration.zero,
            transcript: pendingVoiceRun.transcript ?? '',
            confidence: pendingVoiceRun.confidence ?? 1,
            status: pendingVoiceRun.status,
          ),
        ),
    ];
    final selectedAgent = state.selectedAgentId == null
        ? null
        : state.agents
              .where((agent) => agent.id == state.selectedAgentId)
              .firstOrNull;

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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(activeProfile?.displayName ?? server?.name ?? 'Chats'),
            if (activeProfile != null)
              Text(
                '${activeProfile.serverLabel} • ${_profileHealthLabel(activeProfile.health)}',
                style: Theme.of(context).textTheme.labelMedium,
              )
            else if (server != null)
              Text(
                server.status,
                style: Theme.of(context).textTheme.labelMedium,
              ),
          ],
        ),
        actions: [
          IconButton(
            key: const ValueKey('chat-context-action'),
            tooltip: 'Chat info',
            onPressed: () => _showChatInfo(
              context,
              profile: activeProfile,
              server: server,
              agent: selectedAgent,
            ),
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: Column(
        children: [
          ApprovalBanner(channel: channel),
          _VoiceModeBanner(
            commandMode: _commandMode,
            commandWord: voiceSettings.commandWord,
            disabledReason: voiceDisabledReason,
            notice: _voiceNotice,
            pending: pendingVoiceRun != null,
            pendingTranscript: pendingVoiceRun?.transcript,
            profileName: activeProfile?.displayName,
            recoveryAction: voiceRecoveryAction,
            ready:
                voiceService != null &&
                activeProfile != null &&
                voiceDisabledReason == null,
            canTrustServer:
                activeProfile != null &&
                voiceService != null &&
                !_voiceSettings(ref).isTrusted(activeProfile.serverId),
            onTrustServer: activeProfile == null
                ? null
                : () => ref
                      .read(navivoxVoiceSettingsProvider.notifier)
                      .setServerTrusted(activeProfile.serverId, true),
            onCancelPending: _cancelPendingVoice,
          ),
          Expanded(
            child: TranscriptSurface(
              messages: adapterMessages,
              onSend: (text) => _handleTextSubmit(channel, text),
              voiceCaptureService: voiceDisabledReason == null
                  ? voiceService
                  : null,
              voiceUnavailableReason: voiceDisabledReason,
              textToSpeechService: textToSpeechService,
              assistantTypingLabel:
                  activeProfile?.activeTurnState == 'streaming'
                  ? '${activeProfile!.displayName} is typing…'
                  : null,
              onCancelActiveTurn: activeProfile?.activeTurnState == 'streaming'
                  ? () => channel.cancelActiveTurn()
                  : null,
              onVoice: (capture) => _handleVoiceCapture(channel, capture),
              onVoiceCaptureStarted: () {
                _pendingVoiceRunId = channel.startVoiceRun();
              },
              onVoiceCaptureFailed: (error) {
                final id = _pendingVoiceRunId;
                if (id != null) {
                  channel.failVoiceRun(
                    id,
                    reason: _voiceCaptureFailureReason(error),
                  );
                }
                _pendingVoiceRunId = null;
              },
              forwardTargets: state.profileContacts
                  .where((contact) => contact.key != activeProfile?.key)
                  .toList(growable: false),
              onForward: (message, target) =>
                  _handleForward(channel, message: message, target: target),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showChatInfo(
    BuildContext context, {
    required NavivoxProfileContact? profile,
    required NavivoxServer? server,
    required NavivoxAgent? agent,
  }) {
    final theme = Theme.of(context);
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: ListView(
            shrinkWrap: true,
            children: [
              Text('Chat info', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              if (profile != null) ...[
                _ChatInfoRow(
                  icon: Icons.person,
                  label: 'Profile',
                  value: profile.displayName,
                ),
                _ChatInfoRow(
                  icon: Icons.badge_outlined,
                  label: 'Profile ID',
                  value: profile.profileId,
                ),
                _ChatInfoRow(
                  icon: Icons.dns,
                  label: 'Server',
                  value: profile.serverLabel,
                ),
                if (profile.serverId.trim() != profile.serverLabel.trim())
                  _ChatInfoRow(
                    icon: Icons.tag,
                    label: 'Server ID',
                    value: profile.serverId,
                  ),
                _ChatInfoRow(
                  icon: Icons.circle,
                  label: 'Status',
                  value: _profileHealthLabel(profile.health),
                ),
              ] else if (server != null) ...[
                _ChatInfoRow(
                  icon: Icons.dns,
                  label: 'Server',
                  value: server.name,
                ),
                _ChatInfoRow(
                  icon: Icons.circle,
                  label: 'Status',
                  value: server.status,
                ),
              ] else
                const _ChatInfoRow(
                  icon: Icons.chat_bubble_outline,
                  label: 'Profile',
                  value: 'Select a chat',
                ),
              if (agent != null)
                _ChatInfoRow(
                  icon: Icons.smart_toy,
                  label: 'Agent',
                  value: agent.name,
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _profileHealthLabel(NavivoxProfileHealth health) {
    return switch (health) {
      NavivoxProfileHealth.online => 'online',
      NavivoxProfileHealth.offline => 'offline',
      NavivoxProfileHealth.needsAuth => 'auth required',
      NavivoxProfileHealth.warning => 'warning',
    };
  }

  String _voiceCaptureFailureReason(Object error) {
    if (error is VoiceCaptureTimeout) return 'Voice capture timed out.';
    return 'Voice capture failed.';
  }

  NavivoxVoiceSettings _voiceSettings(WidgetRef ref) {
    return ref.read(navivoxVoiceSettingsProvider);
  }

  String? _voiceDisabledReason({
    required VoiceCaptureService? voiceService,
    required NavivoxProfileContact? activeProfile,
    required NavivoxVoiceSettings settings,
  }) {
    if (voiceService == null) return 'device STT unavailable';
    if (!settings.continuousVoiceEnabled) return 'disabled in Settings';
    if (activeProfile == null) return 'select a profile';
    if (!settings.isTrusted(activeProfile.serverId)) {
      return 'trust ${activeProfile.serverLabel}';
    }
    if (activeProfile.health != NavivoxProfileHealth.online) {
      return _profileHealthLabel(activeProfile.health);
    }
    final profileVoiceReason = activeProfile.voiceCapability.disabledReason
        .trim();
    if (profileVoiceReason.isNotEmpty) return profileVoiceReason;
    if (activeProfile.voiceCapability.deviceStt.trim().toLowerCase() ==
            'unavailable' &&
        activeProfile.voiceCapability.recoveryAction.trim().isNotEmpty) {
      return 'device STT unavailable';
    }
    if (!activeProfile.micAvailable) return 'mic unavailable';
    return null;
  }

  String? _voiceRecoveryAction(
    NavivoxProfileContact? activeProfile,
    String? voiceDisabledReason,
  ) {
    if (voiceDisabledReason == null) return null;
    final recoveryAction = activeProfile?.voiceCapability.recoveryAction.trim();
    if (recoveryAction != null && recoveryAction.isNotEmpty) {
      final disabledReason = activeProfile!.voiceCapability.disabledReason
          .trim();
      if (disabledReason.isNotEmpty && voiceDisabledReason == disabledReason) {
        return recoveryAction;
      }
      if (voiceDisabledReason == 'device STT unavailable' &&
          activeProfile.voiceCapability.deviceStt.trim().toLowerCase() ==
              'unavailable') {
        return recoveryAction;
      }
    }
    if (voiceDisabledReason == 'device STT unavailable') {
      return 'Install or enable device speech recognition, then reopen Navivox.';
    }
    return null;
  }

  void _handleTextSubmit(NavivoxChannel channel, String text) {
    if (_handleLocalCommand(channel, text, fromVoice: false)) return;
    channel.sendText(text);
  }

  void _handleForward(
    NavivoxChannel channel, {
    required NavivoxChatMessage message,
    required NavivoxProfileContact target,
  }) {
    final text = _forwardText(message);
    if (text.isEmpty) return;
    channel.selectProfileContact(
      serverId: target.serverId,
      profileId: target.profileId,
    );
    GoRouter.maybeOf(context)?.go(
      '/chats/${Uri.encodeComponent(target.serverId)}/'
      '${Uri.encodeComponent(target.profileId)}',
    );
    channel.sendText(text);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Forwarded to ${target.displayName}')),
    );
  }

  String _forwardText(NavivoxChatMessage message) {
    return switch (message.kind) {
      NavivoxMessageKind.text => message.text ?? '',
      NavivoxMessageKind.voice => message.voice?.transcript ?? '',
      NavivoxMessageKind.toolCall => [
        message.toolCall?.name,
        message.toolCall?.status,
        message.toolCall?.summary,
      ].whereType<String>().where((part) => part.isNotEmpty).join('\n'),
      NavivoxMessageKind.safetyWarning ||
      NavivoxMessageKind.approvalRequest => [
        message.safetyNotice?.message,
        message.safetyNotice?.risk,
      ].whereType<String>().where((part) => part.isNotEmpty).join('\n'),
    };
  }

  void _handleVoiceCapture(NavivoxChannel channel, VoiceCapture capture) {
    if (_handleLocalCommand(channel, capture.transcript, fromVoice: true)) {
      final id = _pendingVoiceRunId;
      if (id != null) {
        channel.cancelVoiceRun(id, reason: 'local voice command');
        _pendingVoiceRunId = null;
      }
      return;
    }
    _pendingVoiceTimer?.cancel();
    final voiceRunId = _pendingVoiceRunId ?? channel.startVoiceRun();
    _pendingVoiceRunId = voiceRunId;
    channel.stageVoiceRunTranscript(
      voiceRunId: voiceRunId,
      transcript: capture.transcript,
      duration: capture.duration,
      confidence: capture.confidence,
    );
    setState(() {
      _voiceNotice = 'Sending...';
    });
    _pendingVoiceTimer = Timer(widget.voiceAutoSendGrace, () {
      if (!mounted || _pendingVoiceRunId != voiceRunId) return;
      final run = channel.state.voiceRuns[voiceRunId];
      if (run?.status != NavivoxVoiceRunStatus.pendingSend) return;
      setState(() {
        _pendingVoiceRunId = null;
        _voiceNotice = null;
      });
      channel.submitVoiceRun(voiceRunId);
    });
  }

  void _cancelPendingVoice() {
    _pendingVoiceTimer?.cancel();
    final channel = _subscribed;
    final voiceRunId = _pendingVoiceRunId ?? channel?.state.activeVoiceRun?.id;
    if (channel != null && voiceRunId != null) {
      channel.cancelVoiceRun(voiceRunId);
    }
    setState(() {
      _pendingVoiceRunId = null;
      _voiceNotice = 'Voice turn cancelled before server commit.';
    });
  }

  bool _handleLocalCommand(
    NavivoxChannel channel,
    String raw, {
    required bool fromVoice,
  }) {
    final body = _commandBody(raw, fromVoice: fromVoice);
    if (body == null) return false;
    if (body.isEmpty) {
      _enterCommandMode();
      return true;
    }
    _exitCommandMode(clearNotice: false);
    return _runCommandBody(channel, body);
  }

  String? _commandBody(String raw, {required bool fromVoice}) {
    final text = raw.trim();
    if (text.isEmpty) return null;
    final commandWord = _voiceSettings(ref).commandWord.toLowerCase();
    final lower = text.toLowerCase();
    if (_commandMode &&
        fromVoice &&
        !_startsWithCommandWord(lower, commandWord)) {
      return text;
    }
    if (!_startsWithCommandWord(lower, commandWord)) return null;
    return text.length == commandWord.length
        ? ''
        : text.substring(commandWord.length).trim();
  }

  bool _startsWithCommandWord(String lower, String commandWord) {
    if (lower == commandWord) return true;
    return lower.startsWith('$commandWord ');
  }

  void _enterCommandMode() {
    _commandModeTimer?.cancel();
    setState(() {
      _commandMode = true;
      _voiceNotice = 'Command mode';
    });
    _commandModeTimer = Timer(widget.voiceCommandTimeout, () {
      if (!mounted) return;
      setState(() {
        _commandMode = false;
        _voiceNotice = 'Command mode timed out.';
      });
    });
  }

  void _exitCommandMode({required bool clearNotice}) {
    _commandModeTimer?.cancel();
    if (!_commandMode && !clearNotice) return;
    setState(() {
      _commandMode = false;
      if (clearNotice) _voiceNotice = null;
    });
  }

  bool _runCommandBody(NavivoxChannel channel, String body) {
    final normalized = _normalizeCommand(body);
    switch (normalized) {
      case 'cancel':
        if (channel.state.activeVoiceRun?.status ==
            NavivoxVoiceRunStatus.pendingSend) {
          _cancelPendingVoice();
        } else {
          channel.cancelActiveTurn();
          _showCommandMessage(
            'Cancel requested. Started side effects may still exist.',
          );
        }
        return true;
      case 'stop':
        channel.stopActiveTurn();
        _showCommandMessage(
          'Stop requested. Started side effects may still exist.',
        );
        return true;
      case 'settings':
        context.go(AppRoutes.settings);
        return true;
      case 'help':
        _showCommandMessage(
          'Voice commands: navi <profile>, cancel, stop, settings, help.',
        );
        return true;
    }
    return _switchProfileFromCommand(channel, body, normalized);
  }

  bool _switchProfileFromCommand(
    NavivoxChannel channel,
    String rawBody,
    String normalized,
  ) {
    final settings = _voiceSettings(ref);
    if (!settings.profileSwitchingEnabled) {
      _showCommandMessage('Voice profile switching is disabled.');
      return true;
    }
    final matches = channel.state.profileContacts
        .where((contact) => _contactCommandNames(contact).contains(normalized))
        .toList(growable: false);
    if (matches.length == 1) {
      final contact = matches.single;
      channel.selectProfileContact(
        serverId: contact.serverId,
        profileId: contact.profileId,
      );
      GoRouter.maybeOf(context)?.go(
        '/chats/${Uri.encodeComponent(contact.serverId)}/'
        '${Uri.encodeComponent(contact.profileId)}',
      );
      _showCommandMessage('Switched to ${contact.displayName}.');
      return true;
    }
    if (matches.length > 1) {
      _showCommandMessage('Choose one profile named ${rawBody.trim()}.');
      return true;
    }
    _showCommandMessage('Voice command not recognized: ${rawBody.trim()}.');
    return true;
  }

  Set<String> _contactCommandNames(NavivoxProfileContact contact) {
    return {
      _normalizeCommand(contact.profileId),
      _normalizeCommand(contact.displayName),
    };
  }

  String _normalizeCommand(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  void _showCommandMessage(String message) {
    setState(() => _voiceNotice = message);
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

class _VoiceModeBanner extends StatelessWidget {
  const _VoiceModeBanner({
    required this.commandMode,
    required this.commandWord,
    required this.disabledReason,
    required this.notice,
    required this.pending,
    required this.pendingTranscript,
    required this.profileName,
    required this.recoveryAction,
    required this.ready,
    required this.canTrustServer,
    required this.onTrustServer,
    required this.onCancelPending,
  });

  final bool commandMode;
  final String commandWord;
  final String? disabledReason;
  final String? notice;
  final bool pending;
  final String? pendingTranscript;
  final String? profileName;
  final String? recoveryAction;
  final bool ready;
  final bool canTrustServer;
  final VoidCallback? onTrustServer;
  final VoidCallback onCancelPending;

  @override
  Widget build(BuildContext context) {
    final text = pending
        ? 'Sending...'
        : commandMode
        ? 'Command mode'
        : disabledReason != null
        ? 'Continuous voice unavailable: $disabledReason'
        : ready
        ? 'Continuous voice ready'
        : notice;
    if (text == null) return const SizedBox.shrink();
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: InkWell(
        key: const ValueKey('continuous-voice-banner'),
        onTap: () => _showVoiceControls(context),
        child: Semantics(
          button: true,
          enabled: true,
          hint: 'Open continuous voice controls',
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(
                  disabledReason == null ? Icons.keyboard_voice : Icons.mic_off,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(text)),
                const Icon(Icons.tune, size: 18),
                if (pending)
                  TextButton(
                    onPressed: onCancelPending,
                    child: const Text('Cancel'),
                  ),
                if (!pending && canTrustServer)
                  TextButton(
                    onPressed: onTrustServer,
                    child: const Text('Trust server'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showVoiceControls(BuildContext context) {
    final status = pending
        ? 'Pending voice turn'
        : disabledReason != null
        ? 'Continuous voice unavailable'
        : ready
        ? 'Ready for ${profileName ?? 'chat'}'
        : 'Voice standby';
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Text(
              'Continuous voice',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: Icon(
                disabledReason == null ? Icons.keyboard_voice : Icons.mic_off,
              ),
              title: Text(status),
              subtitle: Text(
                pendingTranscript?.isNotEmpty == true
                    ? pendingTranscript!
                    : disabledReason ??
                          'Tap the mic to speak. Say “$commandWord” for command mode.',
              ),
            ),
            if (pending)
              ListTile(
                leading: const Icon(Icons.cancel_outlined),
                title: const Text('Cancel pending voice'),
                onTap: () {
                  Navigator.of(context).pop();
                  onCancelPending();
                },
              ),
            if (disabledReason != null && recoveryAction != null)
              ListTile(
                leading: const Icon(Icons.tips_and_updates_outlined),
                title: const Text('Recovery action'),
                subtitle: Text(recoveryAction!),
              ),
            if (disabledReason != null)
              ListTile(
                leading: const Icon(Icons.settings_voice_outlined),
                title: const Text('Open voice settings'),
                subtitle: const Text(
                  'Review continuous voice and trust settings',
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  GoRouter.maybeOf(context)?.go(AppRoutes.settings);
                },
              ),
            ListTile(
              leading: const Icon(Icons.short_text),
              title: const Text('Command word'),
              subtitle: Text(commandWord),
            ),
            ListTile(
              leading: const Icon(Icons.record_voice_over),
              title: const Text('How it works'),
              subtitle: Text(
                disabledReason == null
                    ? 'Tap once to capture a turn. Use command mode for local actions like switching profiles, stop, cancel, help, or settings.'
                    : 'Reason: $disabledReason. Continuous voice stays off until resolved.',
              ),
            ),
            if (!pending && canTrustServer)
              ListTile(
                leading: const Icon(Icons.verified_user_outlined),
                title: const Text('Trust server'),
                onTap: () {
                  Navigator.of(context).pop();
                  onTrustServer?.call();
                },
              ),
          ],
        ),
      ),
    );
  }
}
