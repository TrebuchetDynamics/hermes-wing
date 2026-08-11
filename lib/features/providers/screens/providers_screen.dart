import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/hermes/channel/hermes_channel.dart';
import '../../../core/hermes/hermes_domain_authority.dart';
import '../../../core/hermes/models/hermes_runtime_model.dart';
import '../../../core/wing_link/wing_link_client.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/wing_empty_state.dart';
import '../../../shared/widgets/wing_gateway_picker.dart';
import '../../../shared/widgets/wing_skeleton.dart';
import '../../agents/providers/profile_selection_provider.dart';
import '../../hermes_chat/gateways/hermes_gateway_directory.dart';
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
typedef ProvidersWingLinkClientBuilder =
    WingLinkClient Function({required Uri origin, required String token});

final providersWingLinkClientBuilderProvider =
    Provider<ProvidersWingLinkClientBuilder>(
      (ref) =>
          ({required origin, required token}) =>
              WingLinkClient(origin: origin, token: token),
    );

class ProvidersScreen extends ConsumerStatefulWidget {
  const ProvidersScreen({super.key});

  @override
  ConsumerState<ProvidersScreen> createState() => _ProvidersScreenState();
}

class _ProvidersScreenState extends ConsumerState<ProvidersScreen> {
  String? _loadedContextKey;
  String? _switchingGatewayId;
  String? _actionError;
  int _loadGeneration = 0;
  bool _loading = false;
  bool _loadFailed = false;
  WingLinkClient? _wingLinkClient;
  List<WingLinkProvider>? _wingLinkProviders;
  String _wingLinkProfileId = 'default';

  @override
  Widget build(BuildContext context) {
    final channel = ref.watch(hermesChannelProvider);
    final directory = ref.watch(hermesGatewayDirectoryProvider);
    final strings = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.providersTitle),
        actions: const [AppShellMenuButton()],
      ),
      body: SafeArea(
        top: false,
        child: AnimatedBuilder(
          animation: Listenable.merge([channel, directory]),
          builder: (context, _) {
            _maybeReload(channel, directory);
            return Column(
              children: [
                if (directory.gateways.isNotEmpty)
                  WingGatewayPicker(
                    fieldKey: const ValueKey('providers-gateway-picker'),
                    directory: directory,
                    helpText: strings.providersGatewayHelp,
                    enabled: _switchingGatewayId == null,
                    onSelected: (id) =>
                        unawaited(_selectGateway(directory, id, strings)),
                  ),
                if (_actionError != null)
                  MaterialBanner(
                    content: Text(_actionError!),
                    actions: [
                      TextButton(
                        onPressed: () => setState(() => _actionError = null),
                        child: Text(strings.doneAction),
                      ),
                    ],
                  ),
                Expanded(child: _buildBody(context, channel, strings)),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Loads providers + models on mount and whenever the selected profile
  /// changes. Fire-and-forget: the channel drives state, and per-surface read
  /// gates keep unauthorized calls from being issued.
  void _maybeReload(HermesChannel channel, HermesGatewayDirectory directory) {
    final state = channel.state;
    if (state.status != HermesConnectionStatus.connected) return;
    final gatewayId = directory.activeContactId?.gatewayId;
    final profileId = effectiveSelectedProfileId(state);
    final contextKey =
        '${gatewayId ?? state.connectedBaseUrl ?? 'legacy'}::${profileId ?? 'default'}';
    if (contextKey == _loadedContextKey) return;
    _loadedContextKey = contextKey;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_reload(channel, directory, profileId, contextKey));
    });
  }

  Future<void> _reload(
    HermesChannel channel,
    HermesGatewayDirectory directory,
    String? profileId,
    String contextKey,
  ) async {
    final generation = ++_loadGeneration;
    final gatewayId = directory.activeContactId?.gatewayId;
    final config = gatewayId == null
        ? null
        : directory.configForGateway(gatewayId);
    final origin = Uri.tryParse(config?.wingLinkOrigin?.trim() ?? '');
    final token = config?.wingLinkToken?.trim() ?? '';
    final wingLinkProfileId = profileId ?? 'default';
    final wingLinkClient =
        wingLinkDomainFallbacksEnabled &&
            !channel.state.canReadProviders &&
            origin != null &&
            origin.host.isNotEmpty &&
            token.isNotEmpty
        ? ref.read(providersWingLinkClientBuilderProvider)(
            origin: origin,
            token: token,
          )
        : null;
    setState(() {
      _loading = true;
      _loadFailed = false;
      _wingLinkClient = wingLinkClient;
      _wingLinkProfileId = wingLinkProfileId;
      _wingLinkProviders = wingLinkClient == null ? const [] : null;
    });
    try {
      final wingLinkProviders = wingLinkClient == null
          ? const <WingLinkProvider>[]
          : await wingLinkClient.listProviders(profile: wingLinkProfileId);
      await Future.wait([
        if (channel.state.canReadProviders) channel.loadProviders(),
        if (channel.state.canReadModels) channel.loadModels(),
      ]);
      if (mounted &&
          generation == _loadGeneration &&
          _loadedContextKey == contextKey) {
        setState(() => _wingLinkProviders = wingLinkProviders);
      }
    } catch (_) {
      if (mounted &&
          generation == _loadGeneration &&
          effectiveSelectedProfileId(channel.state) == profileId &&
          _loadedContextKey == contextKey) {
        setState(() => _loadFailed = true);
      }
    } finally {
      if (mounted && generation == _loadGeneration) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _selectGateway(
    HermesGatewayDirectory directory,
    String gatewayId,
    AppLocalizations strings,
  ) async {
    setState(() {
      _switchingGatewayId = gatewayId;
      _actionError = null;
    });
    try {
      await directory.activateGateway(gatewayId);
    } catch (_) {
      if (mounted) setState(() => _actionError = strings.gatewayConnectFailed);
    } finally {
      if (mounted) setState(() => _switchingGatewayId = null);
    }
  }

  Widget _buildBody(
    BuildContext context,
    HermesChannel channel,
    AppLocalizations strings,
  ) {
    final state = channel.state;

    if (state.status == HermesConnectionStatus.connecting ||
        (_loading &&
            state.providers.isEmpty &&
            (_wingLinkProviders?.isEmpty ?? true))) {
      return WingSkeletonList(semanticLabel: strings.providersLoading);
    }
    if (state.status == HermesConnectionStatus.error) {
      return WingEmptyState(
        icon: Icons.cloud_off_outlined,
        title: strings.providersConnectionError,
        body: state.errorMessage ?? strings.providerOperationFailed,
      );
    }
    if (state.status != HermesConnectionStatus.connected) {
      return WingEmptyState(
        icon: Icons.hub_outlined,
        title: strings.gatewaySelectPromptTitle,
        body: strings.providersConnectionRequiredBody,
      );
    }
    if (!state.canReadProviders && _wingLinkClient == null) {
      if (!state.canReadRuntimeModels) {
        return WingEmptyState(
          icon: Icons.lock_outline,
          title: strings.providersUnavailableTitle,
          body: strings.providersUnavailableBody,
        );
      }
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          _ProvidersHeader(
            subtitle: strings.providersSubtitle,
            readOnly: true,
            readOnlyLabel: strings.readOnlyAccess,
          ),
          const SizedBox(height: 20),
          WingEmptyState(
            icon: Icons.lock_outline,
            title: strings.providersUnavailableTitle,
            body: strings.providersUnavailableBody,
          ),
          const SizedBox(height: 20),
          _ModelSection(strings: strings, state: state, onChoose: () {}),
        ],
      );
    }
    if (_loadFailed) {
      return WingEmptyState(
        icon: Icons.sync_problem_outlined,
        title: strings.providersConnectionError,
        body: strings.providerOperationFailed,
        actionLabel: strings.retryAction,
        onAction: _loading
            ? null
            : () => unawaited(
                _reload(
                  channel,
                  ref.read(hermesGatewayDirectoryProvider),
                  effectiveSelectedProfileId(state),
                  _loadedContextKey ?? 'retry',
                ),
              ),
      );
    }

    final providers = [
      ...state.providers.where((provider) => provider.configured),
      ...state.providers.where((provider) => !provider.configured),
    ];
    final wingLinkProviders = _wingLinkProviders ?? const <WingLinkProvider>[];
    final canWriteProviders = state.canWriteProviders;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        _ProvidersHeader(
          subtitle: strings.providersSubtitle,
          readOnly: !canWriteProviders && _wingLinkClient == null,
          readOnlyLabel: strings.readOnlyAccess,
          action: _wingLinkClient == null
              ? null
              : FilledButton.tonalIcon(
                  onPressed: () => _openCustomProviderEditor(),
                  icon: const Icon(Icons.add),
                  label: Text(strings.createAction),
                ),
        ),
        const SizedBox(height: 20),
        if (providers.isEmpty && wingLinkProviders.isEmpty)
          WingEmptyState(
            icon: Icons.key_off_outlined,
            title: strings.providersEmptyTitle,
            body: strings.providersEmptyBody,
          )
        else ...[
          for (var index = 0; index < providers.length; index++) ...[
            if (index == 0 ||
                providers[index - 1].configured !=
                    providers[index].configured) ...[
              if (index > 0) const SizedBox(height: 24),
              Text(
                providers[index].configured
                    ? strings.providersConfiguredSection
                    : strings.providersAvailableSection,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 10),
            ] else
              const SizedBox(height: 12),
            _ProviderCard(
              provider: providers[index],
              strings: strings,
              canManage: canWriteProviders,
              onManage: () => _openCredentialSheet(channel, providers[index]),
            ),
          ],
          for (final provider in wingLinkProviders) ...[
            if (providers.isNotEmpty || provider != wingLinkProviders.first)
              const SizedBox(height: 12),
            _WingLinkProviderCard(
              provider: provider,
              strings: strings,
              onEdit: () => _openCustomProviderEditor(provider),
            ),
          ],
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

  Future<void> _openCustomProviderEditor([WingLinkProvider? provider]) async {
    final strings = AppLocalizations.of(context);
    final client = _wingLinkClient;
    final profileId = _wingLinkProfileId;
    if (client == null) return;
    var id = provider?.id ?? '';
    var baseUrl = provider?.baseUrl ?? '';
    var model = provider?.model ?? '';
    final formKey = GlobalKey<FormState>();
    final action = await showDialog<_CustomProviderDraft>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.providersTitle),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  key: const ValueKey('wing-link-provider-id'),
                  initialValue: id,
                  enabled: provider == null,
                  onChanged: (value) => id = value,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: strings.modelProviderLabel,
                    helperText: strings.profileStableNameHint,
                  ),
                  validator: (value) => _validProviderId(value)
                      ? null
                      : strings.profileStableNameHint,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey('wing-link-provider-endpoint'),
                  initialValue: baseUrl,
                  onChanged: (value) => baseUrl = value,
                  autocorrect: false,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                    labelText: strings.enrollEndpointLabel,
                  ),
                  validator: (value) => _validProviderBaseUrl(value)
                      ? null
                      : strings.settingsGatewayOriginError,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey('wing-link-provider-model'),
                  initialValue: model,
                  onChanged: (value) => model = value,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: strings.modelNameLabel,
                  ),
                  validator: (value) => (value?.trim().isEmpty ?? true)
                      ? strings.providerOperationFailed
                      : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          if (provider != null)
            TextButton(
              key: const ValueKey('wing-link-provider-delete'),
              onPressed: () => Navigator.pop(
                dialogContext,
                _CustomProviderDraft(
                  id: provider.id,
                  baseUrl: provider.baseUrl,
                  model: provider.model,
                  delete: true,
                ),
              ),
              child: Text(strings.voiceRemoveAction),
            ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(strings.cancelAction),
          ),
          FilledButton(
            key: const ValueKey('wing-link-provider-save'),
            onPressed: () {
              if (formKey.currentState?.validate() != true) return;
              Navigator.pop(
                dialogContext,
                _CustomProviderDraft(
                  id: id.trim(),
                  baseUrl: baseUrl.trim(),
                  model: model.trim(),
                ),
              );
            },
            child: Text(
              provider == null ? strings.createAction : strings.saveAction,
            ),
          ),
        ],
      ),
    );
    if (action == null || !mounted) return;
    if (action.delete) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(strings.deleteAgentTitle(action.id)),
          content: Text(strings.chatSessionActionDeleteBody(action.id)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(strings.cancelAction),
            ),
            FilledButton(
              key: const ValueKey('wing-link-provider-delete-confirm'),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(strings.voiceRemoveAction),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    if (!identical(client, _wingLinkClient) ||
        profileId != _wingLinkProfileId) {
      return;
    }
    try {
      WingLinkProvider? changed;
      if (action.delete) {
        await client.deleteProvider(
          profile: profileId,
          id: action.id,
          revision: provider!.revision,
        );
      } else if (provider == null) {
        changed = await client.createProvider(
          profile: profileId,
          id: action.id,
          baseUrl: action.baseUrl,
          model: action.model,
        );
      } else {
        changed = await client.updateProvider(
          profile: profileId,
          id: provider.id,
          baseUrl: action.baseUrl,
          model: action.model,
          revision: provider.revision,
        );
      }
      if (mounted &&
          identical(client, _wingLinkClient) &&
          profileId == _wingLinkProfileId) {
        final providers = [
          for (final item in _wingLinkProviders ?? const <WingLinkProvider>[])
            if (item.id != action.id) item,
          ?changed,
        ]..sort((a, b) => a.id.compareTo(b.id));
        setState(() {
          _wingLinkProviders = providers;
          _actionError = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _actionError = strings.providerOperationFailed);
      }
    }
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
    required this.subtitle,
    required this.readOnly,
    required this.readOnlyLabel,
    this.action,
  });

  final String subtitle;
  final bool readOnly;
  final String readOnlyLabel;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitle, style: theme.textTheme.bodyLarge),
          if (readOnly) ...[
            const SizedBox(height: 10),
            Chip(
              avatar: const Icon(Icons.visibility_outlined, size: 18),
              label: Text(readOnlyLabel),
            ),
          ],
          if (action != null) ...[const SizedBox(height: 12), action!],
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

class _WingLinkProviderCard extends StatelessWidget {
  const _WingLinkProviderCard({
    required this.provider,
    required this.strings,
    required this.onEdit,
  });

  final WingLinkProvider provider;
  final AppLocalizations strings;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(provider.id, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(provider.baseUrl),
          const SizedBox(height: 4),
          Text('${strings.modelNameLabel}: ${provider.model}'),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: ValueKey('wing-link-provider-edit-${provider.id}'),
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
            label: Text(strings.editAgent),
          ),
        ],
      ),
    ),
  );
}

class _CustomProviderDraft {
  const _CustomProviderDraft({
    required this.id,
    required this.baseUrl,
    required this.model,
    this.delete = false,
  });

  final String id;
  final String baseUrl;
  final String model;
  final bool delete;
}

bool _validProviderId(String? value) =>
    RegExp(r'^[a-z0-9][a-z0-9_-]{0,63}$').hasMatch(value?.trim() ?? '');

bool _validProviderBaseUrl(String? value) {
  final uri = Uri.tryParse(value?.trim() ?? '');
  return uri != null &&
      (uri.scheme == 'http' || uri.scheme == 'https') &&
      uri.host.isNotEmpty &&
      uri.userInfo.isEmpty &&
      !uri.hasQuery &&
      !uri.hasFragment;
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
        if (!state.canReadModels && state.canReadRuntimeModels)
          _RuntimeModelsCard(
            strings: strings,
            models: state.models,
            details: state.runtimeModels,
          )
        else if (!state.canReadModels)
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
                          auxiliaryTaskLabel(strings, aux.task),
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

class _RuntimeModelsCard extends StatelessWidget {
  const _RuntimeModelsCard({
    required this.strings,
    required this.models,
    required this.details,
  });

  final AppLocalizations strings;
  final List<String> models;
  final List<HermesRuntimeModel> details;

  @override
  Widget build(BuildContext context) {
    final sortedModels =
        models
            .map(_boundedRuntimeModelLabel)
            .where((model) => model.isNotEmpty)
            .toSet()
            .toList(growable: false)
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.runtimeModelsTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(strings.runtimeModelsBody),
            const SizedBox(height: 12),
            if (details.isNotEmpty)
              for (var index = 0; index < details.length; index++) ...[
                if (index > 0) const Divider(),
                _RuntimeModelTile(model: details[index], strings: strings),
              ]
            else if (sortedModels.isEmpty)
              Text(strings.runtimeModelsEmptyBody)
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final model in sortedModels) Chip(label: Text(model)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _RuntimeModelTile extends StatelessWidget {
  const _RuntimeModelTile({required this.model, required this.strings});

  final HermesRuntimeModel model;
  final AppLocalizations strings;

  @override
  Widget build(BuildContext context) {
    final id = _boundedRuntimeModelLabel(model.id);
    final root = _boundedRuntimeModelLabel(model.root);
    final parent = _boundedRuntimeModelLabel(model.parent);
    final isAlias = model.isRouteAlias;
    return ListTile(
      key: ValueKey('runtime-model-$id'),
      contentPadding: EdgeInsets.zero,
      leading: Icon(isAlias ? Icons.alt_route : Icons.memory_outlined),
      title: Text(id),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isAlias
                ? strings.runtimeModelRouteAlias
                : strings.runtimeModelPrimary,
          ),
          if (isAlias && root.isNotEmpty)
            Text(strings.runtimeModelRoutesTo(root)),
          if (isAlias && parent.isNotEmpty)
            Text(strings.runtimeModelParent(parent)),
        ],
      ),
    );
  }
}

String _boundedRuntimeModelLabel(String value) {
  final normalized = value
      .replaceAll(RegExp(r'[\u0000-\u001f\u007f]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  const maximumLength = 120;
  if (normalized.length <= maximumLength) return normalized;
  return '${normalized.substring(0, maximumLength - 1)}…';
}
