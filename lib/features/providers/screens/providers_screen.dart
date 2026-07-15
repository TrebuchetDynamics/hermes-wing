import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/hermes/channel/hermes_channel.dart';
import '../../../l10n/app_localizations.dart';
import '../../agents/providers/profile_selection_provider.dart';
import '../../hermes_chat/providers/hermes_channel_provider.dart';
import '../widgets/model_picker_sheet.dart';
import '../widgets/provider_credential_sheet.dart';

/// Provider-credential and model-selection surface for the selected profile.
///
/// Mirrors the milestone-1 `/agents` screen: capability-gated mutation
/// visibility, loading/error/empty states, 200%-scale friendly. It reloads the
/// provider list and model inventory on mount and whenever the client-selected
/// profile changes (the deferred profile-switch reload), always write-only —
/// no raw key ever enters this tree.
class ProvidersScreen extends ConsumerStatefulWidget {
  const ProvidersScreen({super.key});

  @override
  ConsumerState<ProvidersScreen> createState() => _ProvidersScreenState();
}

class _ProvidersScreenState extends ConsumerState<ProvidersScreen> {
  String? _loadedProfileId;

  @override
  Widget build(BuildContext context) {
    final channel = ref.watch(hermesChannelProvider);
    final strings = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(strings.providersTitle)),
      body: AnimatedBuilder(
        animation: channel,
        builder: (context, _) {
          _maybeReload(channel);
          return _buildBody(context, channel, strings);
        },
      ),
    );
  }

  /// Loads providers + models on mount and whenever the selected profile
  /// changes. Fire-and-forget: the channel drives state, and per-surface read
  /// gates keep unauthorized calls from being issued.
  void _maybeReload(HermesChannel channel) {
    final state = channel.state;
    if (state.status != HermesConnectionStatus.connected) return;
    final profileId = effectiveSelectedProfileId(state);
    if (profileId == _loadedProfileId) return;
    _loadedProfileId = profileId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (state.canReadProviders) channel.loadProviders();
      if (state.canReadModels) channel.loadModels();
    });
  }

  Widget _buildBody(
    BuildContext context,
    HermesChannel channel,
    AppLocalizations strings,
  ) {
    final state = channel.state;

    if (state.status == HermesConnectionStatus.connecting) {
      return Center(
        child: Semantics(
          label: strings.providersLoading,
          child: const CircularProgressIndicator(),
        ),
      );
    }
    if (state.status == HermesConnectionStatus.error) {
      return _ProvidersMessage(
        icon: Icons.cloud_off_outlined,
        title: strings.providersConnectionError,
        body: state.errorMessage ?? strings.providerOperationFailed,
      );
    }
    if (!state.canReadProviders) {
      return _ProvidersMessage(
        icon: Icons.lock_outline,
        title: strings.providersUnavailableTitle,
        body: strings.providersUnavailableBody,
      );
    }

    final providers = state.providers;
    final canWriteProviders = state.canWriteProviders;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        _ProvidersHeader(
          title: strings.providersTitle,
          subtitle: strings.providersSubtitle,
          readOnly: !canWriteProviders,
          readOnlyLabel: strings.readOnlyAccess,
        ),
        const SizedBox(height: 20),
        if (providers.isEmpty)
          _ProvidersMessage(
            icon: Icons.key_off_outlined,
            title: strings.providersEmptyTitle,
            body: strings.providersEmptyBody,
          )
        else
          for (var index = 0; index < providers.length; index++) ...[
            if (index > 0) const SizedBox(height: 12),
            _ProviderCard(
              provider: providers[index],
              strings: strings,
              canManage: canWriteProviders,
              onManage: () => _openCredentialSheet(channel, providers[index]),
            ),
          ],
        const SizedBox(height: 28),
        _ModelSection(
          strings: strings,
          state: state,
          onChoose: () => _openModelPicker(channel, state),
        ),
      ],
    );
  }

  Future<void> _openCredentialSheet(
    HermesChannel channel,
    HermesProvider provider,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) =>
          ProviderCredentialSheet(channel: channel, provider: provider),
    );
  }

  Future<void> _openModelPicker(
    HermesChannel channel,
    HermesChannelState state,
  ) async {
    final inventory = state.modelInventory ?? const HermesModelInventory();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) =>
          ModelPickerSheet(channel: channel, inventory: inventory),
    );
  }
}

class _ProvidersHeader extends StatelessWidget {
  const _ProvidersHeader({
    required this.title,
    required this.subtitle,
    required this.readOnly,
    required this.readOnlyLabel,
  });

  final String title;
  final String subtitle;
  final bool readOnly;
  final String readOnlyLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedBox(
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
    );
  }
}

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({
    required this.provider,
    required this.strings,
    required this.canManage,
    required this.onManage,
  });

  final HermesProvider provider;
  final AppLocalizations strings;
  final bool canManage;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = provider.label.isEmpty ? provider.slug : provider.label;
    final semanticsLabel = [
      label,
      provider.configured
          ? strings.providerConfiguredBadge
          : strings.providerNotConfiguredBadge,
    ].join(', ');

    return Semantics(
      container: true,
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: theme.textTheme.titleMedium),
                        const SizedBox(height: 3),
                        Text(
                          provider.authType,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Chip(
                    avatar: Icon(
                      provider.configured
                          ? Icons.check_circle_outline
                          : Icons.remove_circle_outline,
                      size: 18,
                    ),
                    label: Text(
                      provider.configured
                          ? strings.providerConfiguredBadge
                          : strings.providerNotConfiguredBadge,
                    ),
                  ),
                ],
              ),
              if (provider.keyHint != null) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Chip(
                    avatar: const Icon(Icons.password_outlined, size: 18),
                    label: Text(
                      strings.providerKeyHintLabel(provider.keyHint!),
                    ),
                  ),
                ),
              ],
              if (canManage) ...[
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: onManage,
                    icon: const Icon(Icons.key_outlined),
                    label: Text(strings.manageCredentialAction),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ModelSection extends StatelessWidget {
  const _ModelSection({
    required this.strings,
    required this.state,
    required this.onChoose,
  });

  final AppLocalizations strings;
  final HermesChannelState state;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final assignment =
        state.modelInventory?.assignment ?? const HermesModelAssignment();
    final activeSummary = assignment.activeModel.isEmpty
        ? strings.noModelAssigned
        : (assignment.activeProvider.isEmpty
              ? assignment.activeModel
              : '${assignment.activeProvider} / ${assignment.activeModel}');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(strings.modelSelectionTitle, style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        if (!state.canReadModels)
          Text(strings.modelSelectionUnavailableBody)
        else ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.activeModelLabel,
                    style: theme.textTheme.labelLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(activeSummary, style: theme.textTheme.bodyLarge),
                  if (assignment.auxiliary.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      strings.auxiliaryModelsLabel,
                      style: theme.textTheme.labelLarge,
                    ),
                    const SizedBox(height: 4),
                    for (final aux in assignment.auxiliary)
                      Text(
                        strings.auxiliaryModelSummary(
                          aux.task,
                          aux.provider,
                          aux.model,
                        ),
                        style: theme.textTheme.bodyMedium,
                      ),
                  ],
                  if (state.canWriteModels) ...[
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.tonalIcon(
                        onPressed: onChoose,
                        icon: const Icon(Icons.tune),
                        label: Text(strings.chooseModelAction),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ProvidersMessage extends StatelessWidget {
  const _ProvidersMessage({
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
