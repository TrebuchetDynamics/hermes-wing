import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/hermes/channel/hermes_channel.dart';
import '../../../core/hermes/models/hermes_capabilities.dart';
import '../../../l10n/app_localizations.dart';
import '../../hermes_chat/providers/hermes_channel_provider.dart';
import '../providers/profile_selection_provider.dart';
import '../widgets/profile_editor_sheet.dart';

class AgentsScreen extends ConsumerStatefulWidget {
  const AgentsScreen({super.key});

  @override
  ConsumerState<AgentsScreen> createState() => _AgentsScreenState();
}

class _AgentsScreenState extends ConsumerState<AgentsScreen> {
  String? _actionError;
  String? _switchingProfileId;

  @override
  Widget build(BuildContext context) {
    final channel = ref.watch(hermesChannelProvider);
    final strings = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(strings.agentsTitle)),
      body: AnimatedBuilder(
        animation: channel,
        builder: (context, _) => _buildBody(context, channel, strings),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    HermesChannel channel,
    AppLocalizations strings,
  ) {
    final state = channel.state;
    final capabilities = state.capabilities;

    if (state.status == HermesConnectionStatus.connecting) {
      return Center(
        child: Semantics(
          label: strings.agentsLoading,
          child: const CircularProgressIndicator(),
        ),
      );
    }
    if (state.status == HermesConnectionStatus.error) {
      return _AgentsMessage(
        icon: Icons.cloud_off_outlined,
        title: strings.agentsConnectionError,
        body: state.errorMessage ?? strings.profileOperationFailed,
      );
    }
    if (!_canReadProfiles(capabilities)) {
      return _AgentsMessage(
        icon: Icons.lock_outline,
        title: strings.agentsUnavailableTitle,
        body: strings.agentsUnavailableBody,
      );
    }

    final profiles = state.profiles;
    // Seed the default profile for display when nothing is selected yet, so
    // the UI has profile context on mount. This is a pure derivation and never
    // triggers an active-profile network call.
    final selectedId = effectiveSelectedProfileId(state);
    final canCreate = _canUseEndpoint(
      capabilities,
      scope: 'profiles:write',
      name: 'profile_create',
      method: 'POST',
      path: '/api/profiles',
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        _AgentsHeader(
          title: strings.agentsTitle,
          subtitle: strings.agentsSubtitle,
          readOnly: !capabilities!.auth.allows('profiles:write'),
          readOnlyLabel: strings.readOnlyAccess,
          action: canCreate
              ? FilledButton.icon(
                  onPressed: () =>
                      _openEditor(channel: channel, profiles: profiles),
                  icon: const Icon(Icons.add),
                  label: Text(strings.newAgent),
                )
              : null,
        ),
        if (_actionError != null) ...[
          const SizedBox(height: 16),
          MaterialBanner(
            content: Text(_actionError!),
            actions: [
              TextButton(
                onPressed: () => setState(() => _actionError = null),
                child: Text(strings.doneAction),
              ),
            ],
          ),
        ],
        const SizedBox(height: 20),
        if (profiles.isEmpty)
          _AgentsMessage(
            icon: Icons.support_agent_outlined,
            title: strings.agentsEmptyTitle,
            body: strings.agentsEmptyBody,
          )
        else
          for (var index = 0; index < profiles.length; index++) ...[
            if (index > 0) const SizedBox(height: 12),
            _AgentCard(
              profile: profiles[index],
              selected: profiles[index].id == selectedId,
              canEdit: _canUseEndpoint(
                capabilities,
                scope: 'profiles:write',
                name: 'profile_update',
                method: 'PATCH',
                path: '/api/profiles/{profile_id}',
              ),
              canDelete:
                  profiles[index].id != 'default' &&
                  _canUseEndpoint(
                    capabilities,
                    scope: 'profiles:write',
                    name: 'profile_delete',
                    method: 'DELETE',
                    path: '/api/profiles/{profile_id}',
                  ),
              strings: strings,
              switching: _switchingProfileId == profiles[index].id,
              onChat: _switchingProfileId == null
                  ? () => _selectProfile(channel, profiles[index].id)
                  : null,
              onEdit: () => _openEditor(
                channel: channel,
                profiles: profiles,
                profile: profiles[index],
                canEditSoul:
                    _canUseEndpoint(
                      capabilities,
                      scope: 'profiles:read',
                      name: 'profile_soul',
                      method: 'GET',
                      path: '/api/profiles/{profile_id}/soul',
                    ) &&
                    _canUseEndpoint(
                      capabilities,
                      scope: 'profiles:write',
                      name: 'profile_soul_update',
                      method: 'PUT',
                      path: '/api/profiles/{profile_id}/soul',
                    ),
                canDelete:
                    profiles[index].id != 'default' &&
                    _canUseEndpoint(
                      capabilities,
                      scope: 'profiles:write',
                      name: 'profile_delete',
                      method: 'DELETE',
                      path: '/api/profiles/{profile_id}',
                    ),
              ),
              onDelete: () => _openEditor(
                channel: channel,
                profiles: profiles,
                profile: profiles[index],
                canDelete: true,
              ),
            ),
          ],
      ],
    );
  }

  Future<void> _openEditor({
    required HermesChannel channel,
    required List<HermesProfile> profiles,
    HermesProfile? profile,
    bool canEditSoul = false,
    bool canDelete = false,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => ProfileEditorSheet(
        channel: channel,
        profiles: profiles,
        profile: profile,
        canEditSoul: canEditSoul,
        canDelete: canDelete,
      ),
    );
  }

  Future<void> _selectProfile(HermesChannel channel, String profileId) async {
    if (_switchingProfileId != null) return;
    setState(() {
      _switchingProfileId = profileId;
      _actionError = null;
    });
    try {
      await channel.selectProfile(profileId);
    } catch (_) {
      if (mounted) {
        setState(() {
          _actionError = AppLocalizations.of(context).profileOperationFailed;
        });
      }
    } finally {
      if (mounted && _switchingProfileId == profileId) {
        setState(() => _switchingProfileId = null);
      }
    }
  }
}

bool _canReadProfiles(HermesCapabilityDocument? capabilities) =>
    _canUseEndpoint(
      capabilities,
      scope: 'profiles:read',
      name: 'profiles',
      method: 'GET',
      path: '/api/profiles',
    );

bool _canUseEndpoint(
  HermesCapabilityDocument? capabilities, {
  required String scope,
  required String name,
  required String method,
  required String path,
}) =>
    capabilities != null &&
    capabilities.supportsSchema &&
    capabilities.auth.allows(scope) &&
    capabilities.advertisesEndpoint(name, method, path);

class _AgentsHeader extends StatelessWidget {
  const _AgentsHeader({
    required this.title,
    required this.subtitle,
    required this.readOnly,
    required this.readOnlyLabel,
    this.action,
  });

  final String title;
  final String subtitle;
  final bool readOnly;
  final String readOnlyLabel;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.spaceBetween,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text(subtitle, style: theme.textTheme.bodyLarge),
              if (readOnly) ...[
                const SizedBox(height: 10),
                Chip(
                  avatar: const Icon(Icons.visibility_outlined, size: 18),
                  label: Text(readOnlyLabel),
                ),
              ],
            ],
          ),
        ),
        ?action,
      ],
    );
  }
}

class _AgentCard extends StatelessWidget {
  const _AgentCard({
    required this.profile,
    required this.selected,
    required this.canEdit,
    required this.canDelete,
    required this.strings,
    required this.switching,
    required this.onChat,
    required this.onEdit,
    required this.onDelete,
  });

  final HermesProfile profile;
  final bool selected;
  final bool canEdit;
  final bool canDelete;
  final AppLocalizations strings;
  final bool switching;
  final VoidCallback? onChat;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = profile.displayName.isEmpty
        ? profile.id
        : profile.displayName;
    final semanticsLabel = [
      displayName,
      strings.agentStableId(profile.id),
      if (selected) strings.selectedAgent,
      if (profile.id == 'default') strings.defaultAgent,
    ].join(', ');

    return Semantics(
      container: true,
      selected: selected,
      label: semanticsLabel,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    child: Text(
                      displayName.characters.first.toUpperCase(),
                      semanticsLabel: '',
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(displayName, style: theme.textTheme.titleMedium),
                        const SizedBox(height: 3),
                        Text(
                          strings.agentStableId(profile.id),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (selected)
                    Chip(
                      avatar: const Icon(Icons.check_circle_outline, size: 18),
                      label: Text(strings.selectedAgent),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (profile.id == 'default')
                    Chip(label: Text(strings.defaultAgent)),
                  Chip(
                    avatar: const Icon(Icons.psychology_outlined, size: 18),
                    label: Text(
                      profile.model.isEmpty
                          ? strings.agentNoModel
                          : profile.model,
                    ),
                  ),
                  Chip(
                    avatar: const Icon(Icons.extension_outlined, size: 18),
                    label: Text(strings.agentSkillsCount(profile.skillsCount)),
                  ),
                  Chip(
                    avatar: Icon(
                      profile.gatewayRunning
                          ? Icons.check_circle_outline
                          : Icons.pause_circle_outline,
                      size: 18,
                    ),
                    label: Text(
                      profile.gatewayRunning
                          ? strings.agentGatewayRunning
                          : strings.agentGatewayOff,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: onChat,
                    icon: switching
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.chat_bubble_outline),
                    label: Text(
                      switching
                          ? strings.switchingAgent
                          : strings.chatWithAgent,
                    ),
                  ),
                  if (canEdit)
                    OutlinedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined),
                      label: Text(strings.editAgent),
                    ),
                  if (canDelete)
                    TextButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline),
                      label: Text(strings.deleteAgent),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgentsMessage extends StatelessWidget {
  const _AgentsMessage({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 44),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                body,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
