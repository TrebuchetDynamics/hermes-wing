import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/hermes/channel/hermes_channel.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/wing_empty_state.dart';
import '../../hermes_chat/providers/hermes_channel_provider.dart';
import '../../profiles/widgets/profile_editor_sheet.dart';

/// Standalone profile persona editor backed by Hermes Agent's SOUL contract.
///
/// This route deliberately reuses [ProfileEditorSheet]'s revision-aware editor
/// rather than keeping a second persona controller or local copy of SOUL data.
class SoulScreen extends ConsumerWidget {
  const SoulScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channel = ref.watch(hermesChannelProvider);
    return AnimatedBuilder(
      animation: channel,
      builder: (context, _) =>
          _SoulScaffold(channel: channel, state: channel.state),
    );
  }
}

class _SoulScaffold extends StatelessWidget {
  const _SoulScaffold({required this.channel, required this.state});

  final HermesChannel channel;
  final HermesChannelState state;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final profile = state.selectedProfile;
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.personaLabel),
        actions: const [AppShellMenuButton()],
      ),
      body: SafeArea(
        top: false,
        child: !state.isConnected
            ? WingEmptyState(
                icon: Icons.cloud_off_outlined,
                title: strings.agentsUnavailableTitle,
                body: strings.agentsEmptyBody,
              )
            : profile == null
            ? WingEmptyState(
                icon: Icons.person_search_outlined,
                title: strings.agentsEmptyTitle,
                body: strings.agentsEmptyBody,
              )
            : !_supportsPersona(state)
            ? WingEmptyState(
                icon: Icons.lock_outline,
                title: strings.agentsUnavailableTitle,
                body: strings.agentsUnavailableBody,
              )
            : ProfileEditorSheet(
                key: ValueKey('soul-editor-${profile.id}'),
                channel: channel,
                profiles: state.profiles,
                profile: profile,
                canEditSoul: true,
                soulOnly: true,
              ),
      ),
    );
  }
}

bool _supportsPersona(HermesChannelState state) {
  final capabilities = state.capabilities;
  if (capabilities == null || !capabilities.supportsSchema) return false;
  final profile = state.selectedProfile;
  if (profile == null) return false;
  final profileContext =
      profile.id == 'default' ||
      capabilities.profileContext.isSupportedQueryContext;
  if (!profileContext ||
      !capabilities.auth.allows('profiles:read') ||
      !capabilities.auth.allows('profiles:write')) {
    return false;
  }
  bool supports(String name, String method, String path, String scope) {
    final endpoint = capabilities.endpoints[name];
    return endpoint != null &&
        endpoint.requiredScopes.every(capabilities.auth.allows) &&
        capabilities.advertisesScopedEndpoint(name, method, path, scope) &&
        capabilities.auth.allows(scope);
  }

  return supports(
        'profile_soul',
        'GET',
        '/api/profiles/{name}/soul',
        'profiles:read',
      ) &&
      supports(
        'profile_soul_update',
        'PUT',
        '/api/profiles/{name}/soul',
        'profiles:write',
      );
}
