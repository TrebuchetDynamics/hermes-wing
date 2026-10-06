import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/hermes/channel/hermes_channel.dart';
import '../../../l10n/app_localizations.dart';
import '../../../router/app_routes.dart';
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
    void finishEditor() {
      // Shell pages remain mounted during their exit transition. A late save
      // must not replace a destination the user has already chosen.
      if (ModalRoute.of(context)?.isCurrent ?? false) {
        context.go(AppRoutes.profiles);
      }
    }

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
                title: strings.soulConnectionRequiredTitle,
                body: strings.soulConnectionRequiredBody,
                actionLabel: strings.soulOpenChatAction,
                onAction: () => context.go(AppRoutes.hermes),
              )
            : profile == null
            ? WingEmptyState(
                icon: Icons.person_search_outlined,
                title: strings.soulProfileRequiredTitle,
                body: strings.soulProfileRequiredBody,
                actionLabel: strings.soulOpenProfilesAction,
                onAction: () => context.go(AppRoutes.profiles),
              )
            : !state.canEditProfileSoul
            ? WingEmptyState(
                icon: Icons.lock_outline,
                title: strings.soulUnavailableTitle,
                body: strings.soulUnavailableBody,
              )
            : ProfileEditorSheet(
                key: ValueKey('soul-editor-${profile.id}'),
                channel: channel,
                profiles: state.profiles,
                profile: profile,
                canEditSoul: true,
                soulOnly: true,
                onCancel: finishEditor,
                onSaved: finishEditor,
              ),
      ),
    );
  }
}
