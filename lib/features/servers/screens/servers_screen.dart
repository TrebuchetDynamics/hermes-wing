import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/channel/navivox_channel.dart';
import '../../../core/channel/navivox_channel_provider.dart';
import '../../../router/app_routes.dart';
import '../../../shared/widgets/profile_contact_avatar.dart';
import '../actions/gateway_management_action_coordinator.dart';
import '../overview/servers_screen_presentation.dart';
import '../registration/presentation/register_gateway_presentation.dart';

const _gatewayManagementActions = GatewayManagementActionCoordinator();

Future<void> _showAdaptiveSheet({
  required BuildContext context,
  required WidgetBuilder child,
  bool isScrollControlled = false,
}) {
  if (MediaQuery.sizeOf(context).width >= 720) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640, maxHeight: 720),
          child: child(dialogContext),
        ),
      ),
    );
  }
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: isScrollControlled,
    builder: child,
  );
}

class ServersScreen extends ConsumerWidget {
  const ServersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(navivoxChannelProvider).state;
    final presentation = ServersScreenPresentation.fromState(state);

    return Scaffold(
      appBar: AppBar(title: const Text('Gateways')),
      body: !presentation.hasGateways
          ? const Center(child: Text('No gateways registered'))
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: presentation.gateways.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final gateway = presentation.gateways[index];
                return _ServerCard(
                  gateway: gateway,
                  onManage: () => _showManageGateway(
                    context,
                    ref.read(navivoxChannelProvider),
                    gateway,
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        tooltip: 'Register gateway',
        onPressed: () =>
            _showRegisterGateway(context, ref.read(navivoxChannelProvider)),
        icon: const Icon(Icons.add_link),
        label: const Text('Register'),
      ),
    );
  }

  void _showManageGateway(
    BuildContext context,
    NavivoxChannel channel,
    ServerGatewayPresentation gateway,
  ) {
    final server = gateway.server;
    final gatewayStatus = gateway.gatewayStatus;
    final parentContext = context;
    _showAdaptiveSheet(
      context: context,
      child: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          children: [
            Text(
              gateway.manageTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.dns),
              title: Text(server.name),
              subtitle: Text(gateway.statusSubtitle),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.health_and_safety_outlined),
              title: Text(gatewayStatus.title),
              subtitle: Text(
                '${gatewayStatus.headline}\n'
                '${gatewayStatus.summaryLine}\n'
                '${gatewayStatus.profileContactsLine}',
              ),
              isThreeLine: true,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.info_outline),
              title: Text(gatewayStatus.deferredMetadataTitle),
              subtitle: Text(gatewayStatus.deferredMetadataMessage),
            ),
            if (gateway.showReconnectStatus)
              ListTile(
                key: const ValueKey('server-reconnect-readiness'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.sync_outlined),
                title: Text(gateway.reconnectStatusTitle),
                subtitle: Text(
                  gateway.reconnectRecoveryMessage == null
                      ? gateway.reconnectStatusMessage
                      : '${gateway.reconnectStatusMessage}\n${gateway.reconnectRecoveryMessage}',
                ),
                isThreeLine: gateway.reconnectRecoveryMessage != null,
              ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.tag),
              title: Text(gateway.serverIdTitle),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 56, bottom: 12),
              child: SelectableText(server.id),
            ),
            if (gateway.activeProfileLabel != null) ...[
              const Divider(),
              ListTile(
                key: ValueKey('server-active-profile-${server.id}'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.badge_outlined),
                title: Text(gateway.activeProfileTitle),
                subtitle: Text(gateway.activeProfileLabel!),
              ),
            ],
            if (gateway.showDisconnectAction) ...[
              const Divider(),
              ListTile(
                key: const ValueKey('server-disconnect-current'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.link_off),
                title: Text(gateway.disconnectActionTitle),
                subtitle: Text(gateway.disconnectActionSubtitle),
                onTap: () => _confirmDisconnect(context, channel, gateway),
              ),
            ],
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.people_alt_outlined),
              title: Text(gateway.profilesSectionTitle),
            ),
            if (gateway.profileContacts.isEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 56),
                child: Text(gateway.emptyProfilesLabel),
              )
            else
              for (final profile in gateway.profileContacts)
                ListTile(
                  key: ValueKey(
                    'server-profile-${profile.contact.serverId}-${profile.contact.profileId}',
                  ),
                  contentPadding: EdgeInsets.zero,
                  leading: ProfileContactAvatar(contact: profile.contact),
                  title: Text(profile.contact.displayName),
                  subtitle: Text(profile.contact.profileId),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _HealthPill(label: profile.compactHealthLabel),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () => _applyGatewayManagementEffect(
                    parentContext,
                    channel,
                    _gatewayManagementActions.selectProfile(profile),
                    sheetContext: context,
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDisconnect(
    BuildContext context,
    NavivoxChannel channel,
    ServerGatewayPresentation gateway,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(gateway.disconnectDialogTitle),
        content: Text(gateway.disconnectDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(gateway.disconnectCancelLabel),
          ),
          FilledButton(
            key: const ValueKey('server-disconnect-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(gateway.disconnectConfirmLabel),
          ),
        ],
      ),
    );
    switch (_gatewayManagementActions.afterDisconnectConfirmation(confirmed)) {
      case NoopGatewayDisconnectPlan():
        return;
      case DisconnectGatewayPlan():
        break;
    }

    try {
      await channel.disconnect();
      if (!context.mounted) return;
      _applyGatewayManagementEffect(
        context,
        channel,
        _gatewayManagementActions.disconnectSucceeded(gateway),
      );
    } catch (error) {
      if (!context.mounted) return;
      _applyGatewayManagementEffect(
        context,
        channel,
        _gatewayManagementActions.disconnectFailed(gateway, error),
      );
    }
  }

  void _applyGatewayManagementEffect(
    BuildContext context,
    NavivoxChannel channel,
    GatewayManagementEffect effect, {
    BuildContext? sheetContext,
  }) {
    switch (effect) {
      case SelectGatewayProfileAndOpenChatEffect(
        :final serverId,
        :final profileId,
      ):
        if (sheetContext != null) Navigator.of(sheetContext).pop();
        channel.selectProfileContact(serverId: serverId, profileId: profileId);
        GoRouter.maybeOf(
          context,
        )?.go(AppRoutes.chatLocation(serverId: serverId, profileId: profileId));
      case CloseGatewaySheetAndShowSnackbarEffect(:final message):
        Navigator.of(context).maybePop();
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(message)));
      case ShowGatewaySnackbarEffect(:final message):
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _showRegisterGateway(BuildContext context, NavivoxChannel channel) {
    _showAdaptiveSheet(
      context: context,
      isScrollControlled: true,
      child: (context) => _RegisterGatewaySheet(channel: channel),
    );
  }
}

class _RegisterGatewaySheet extends StatefulWidget {
  const _RegisterGatewaySheet({required this.channel});

  final NavivoxChannel channel;

  @override
  State<_RegisterGatewaySheet> createState() => _RegisterGatewaySheetState();
}

class _RegisterGatewaySheetState extends State<_RegisterGatewaySheet> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  final _baseUrlController = TextEditingController();
  final _tokenController = TextEditingController();
  bool _testing = false;

  @override
  void dispose() {
    _labelController.dispose();
    _baseUrlController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final presentation = RegisterGatewayPresentation(testing: _testing);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Form(
          key: _formKey,
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.add_link),
                title: Text(presentation.title),
                subtitle: Text(presentation.instructions),
              ),
              TextFormField(
                key: const ValueKey('register-gateway-label'),
                controller: _labelController,
                decoration: InputDecoration(
                  labelText: presentation.gatewayLabelFieldLabel,
                  helperText: presentation.gatewayLabelHelperText,
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const ValueKey('register-gateway-base-url'),
                controller: _baseUrlController,
                decoration: InputDecoration(
                  labelText: presentation.baseUrlFieldLabel,
                  hintText: presentation.baseUrlHintText,
                ),
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.next,
                validator: presentation.validateBaseUrl,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const ValueKey('register-gateway-token'),
                controller: _tokenController,
                decoration: InputDecoration(
                  labelText: presentation.tokenFieldLabel,
                  helperText: presentation.tokenHelperText,
                ),
                obscureText: true,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  key: const ValueKey('register-gateway-test'),
                  onPressed: _testing ? null : _testConnection,
                  icon: _testing
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.network_check),
                  label: Text(presentation.testButtonLabel),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.info_outline),
                title: Text(presentation.boundaryTitle),
                subtitle: Text(presentation.boundarySubtitle),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _testConnection() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    const presentation = RegisterGatewayPresentation();
    final request = presentation.connectRequest(
      baseUrl: _baseUrlController.text,
      token: _tokenController.text,
    );
    setState(() => _testing = true);
    try {
      await widget.channel.connect(
        baseUrl: request.baseUrl,
        token: request.token,
      );
      if (!mounted) return;
      _applyRegisterGatewayEffect(
        _gatewayManagementActions.registerConnectionPassed(
          presentation.connectionPassedMessage,
          request,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _applyRegisterGatewayEffect(
        _gatewayManagementActions.registerConnectionFailed(
          presentation.connectionFailedMessage,
          error,
        ),
      );
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  void _applyRegisterGatewayEffect(GatewayManagementEffect effect) {
    switch (effect) {
      case ShowGatewaySnackbarEffect(:final message):
      case CloseGatewaySheetAndShowSnackbarEffect(:final message):
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              duration: const Duration(seconds: 8),
              content: Text(message),
            ),
          );
      case SelectGatewayProfileAndOpenChatEffect():
        break;
    }
  }
}

class _ServerCard extends StatelessWidget {
  const _ServerCard({required this.gateway, required this.onManage});

  final ServerGatewayPresentation gateway;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final server = gateway.server;
    final gatewayStatus = gateway.gatewayStatus;
    return Card(
      key: ValueKey('server-card-${server.id}'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  gateway.active ? Icons.hub : Icons.dns,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        server.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        gateway.statusSubtitle,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Tooltip(
                  message: 'Details for ${server.name}',
                  child: OutlinedButton.icon(
                    key: ValueKey('server-manage-${server.id}'),
                    onPressed: onManage,
                    icon: const Icon(Icons.tune, size: 18),
                    label: const Text('Details'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DecoratedBox(
              key: ValueKey('server-status-${server.id}'),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: theme.brightness == Brightness.dark ? 0.44 : 0.52,
                ),
                border: Border.all(color: theme.colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _StatusPill(
                      icon: Icons.monitor_heart_outlined,
                      label: gatewayStatus.title,
                    ),
                    _StatusPill(
                      icon: gateway.active
                          ? Icons.check_circle_outline
                          : Icons.radio_button_checked,
                      label: gatewayStatus.headline,
                    ),
                    Text(
                      gatewayStatus.summaryLine,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final label in gateway.countLabels)
                  _CountChip(label: label),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.44),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(visualDensity: VisualDensity.compact, label: Text(label));
  }
}

class _HealthPill extends StatelessWidget {
  const _HealthPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label, style: Theme.of(context).textTheme.labelSmall);
  }
}
