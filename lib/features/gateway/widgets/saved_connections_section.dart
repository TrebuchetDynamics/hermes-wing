import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/hermes/setup/hermes_endpoint_store.dart';
import '../../../features/hermes_chat/gateways/gateway_contact.dart';
import '../../../features/hermes_chat/gateways/hermes_gateway_directory.dart';
import '../../../l10n/app_localizations.dart';
import '../../../router/app_routes.dart';

class SavedConnectionsSection extends StatelessWidget {
  const SavedConnectionsSection({super.key, required this.directory});

  final HermesGatewayDirectory directory;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final groups = directory.hosts;
    return Card(
      child: Column(
        children: [
          if (groups.isEmpty)
            ListTile(title: Text(strings.settingsNoSavedGateways))
          else
            for (final group in groups)
              _GatewaySettingsTile(group: group, directory: directory),
          ListTile(
            key: const ValueKey('settings-connect-another-gateway'),
            minTileHeight: 56,
            minVerticalPadding: 8,
            leading: const Icon(Icons.add_link),
            title: Text(strings.settingsConnectAnotherGateway),
            subtitle: Text(strings.settingsScanPairingQr),
            onTap: () => context.push(AppRoutes.enroll),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              strings.settingsCredentialsNote,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GatewaySettingsTile extends StatelessWidget {
  const _GatewaySettingsTile({required this.group, required this.directory});

  final GatewayHostOverview group;
  final HermesGatewayDirectory directory;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final profileCount = group.profileCount > 1
        ? ' · ${strings.officeAgentCount(group.profileCount)}'
        : '';
    final primary = directory.gateways.firstWhere(
      (gateway) => gateway.id == group.id,
    );
    return ListTile(
      key: ValueKey('connection-host-${group.id}'),
      selected: group.containsGateway(directory.managementGatewayId),
      onTap: () => directory.selectManagementGateway(group.id),
      minTileHeight: 56,
      minVerticalPadding: 8,
      leading: Icon(
        group.availability == GatewayAvailability.online
            ? Icons.cloud_done_outlined
            : Icons.cloud_off_outlined,
      ),
      title: Text(group.label),
      subtitle: Text(
        '${group.baseUrl}$profileCount · ${group.availability.name}',
      ),
      trailing: PopupMenuButton<String>(
        key: ValueKey('settings-gateway-menu-${group.id}'),
        tooltip: strings.settingsGatewayActionsTooltip(group.label),
        onSelected: (action) async {
          if (action == 'agents') {
            await _runGatewayAction(context, () async {
              final activeGatewayId = directory.activeContactId?.gatewayId;
              final gatewayId = group.containsGateway(activeGatewayId)
                  ? activeGatewayId!
                  : group.id;
              directory.selectManagementGateway(gatewayId);
              if (context.mounted) context.go(AppRoutes.profiles);
            }, strings.settingsConnectGatewayError);
          } else if (action == 'rename') {
            await _renameGateway(context, directory, primary);
          } else if (action == 'connection') {
            await _updateGatewayConnection(context, directory, primary);
          } else if (action == 'reconnect') {
            await _runGatewayAction(context, () async {
              for (final gatewayId in group.gatewayIds) {
                await directory.reconnectGateway(gatewayId);
              }
            }, strings.settingsReconnectGatewayError);
          } else if (action == 'remove') {
            await _removeGatewayGroup(context, directory, group);
          }
        },
        itemBuilder: (_) => [
          PopupMenuItem(
            value: 'agents',
            child: Text(strings.settingsManageAgentsAction),
          ),
          if (!group.managedByWingLink)
            PopupMenuItem(
              value: 'rename',
              child: Text(strings.settingsRenameAction),
            ),
          if (!group.managedByWingLink)
            PopupMenuItem(
              value: 'connection',
              child: Text(strings.settingsUpdateConnectionAction),
            ),
          PopupMenuItem(
            value: 'reconnect',
            child: Text(strings.settingsReconnectAction),
          ),
          PopupMenuItem(
            value: 'remove',
            child: Text(strings.voiceRemoveAction),
          ),
        ],
      ),
    );
  }
}

Future<void> _renameGateway(
  BuildContext context,
  HermesGatewayDirectory directory,
  GatewayOverview gateway,
) async {
  final strings = AppLocalizations.of(context);
  var draftLabel = gateway.label;
  final label = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(strings.settingsRenameGatewayTitle),
      content: TextFormField(
        key: const ValueKey('settings-gateway-rename-field'),
        initialValue: gateway.label,
        autofocus: true,
        decoration: InputDecoration(
          labelText: strings.settingsGatewayNameLabel,
        ),
        onChanged: (value) => draftLabel = value,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(strings.cancelAction),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, draftLabel),
          child: Text(strings.saveAction),
        ),
      ],
    ),
  );
  if (label == null || !context.mounted) return;
  await _runGatewayAction(
    context,
    () => directory.renameGateway(gateway.id, label),
    strings.settingsRenameGatewayError,
  );
}

Future<void> _updateGatewayConnection(
  BuildContext context,
  HermesGatewayDirectory directory,
  GatewayOverview gateway,
) async {
  final result = await showDialog<_GatewayConnectionUpdate>(
    context: context,
    builder: (dialogContext) => _GatewayConnectionDialog(
      initialBaseUrl: gateway.baseUrl,
      active: directory.activeContactId?.gatewayId == gateway.id,
    ),
  );
  if (result == null || !context.mounted) return;
  await _runGatewayAction(
    context,
    () => directory.updateGatewayConnection(
      gateway.id,
      baseUrl: result.baseUrl,
      apiKey: result.apiKey,
      clearApiKey: result.clearApiKey,
    ),
    AppLocalizations.of(context).settingsUpdateConnectionError,
  );
}

typedef _GatewayConnectionUpdate = ({
  String baseUrl,
  String? apiKey,
  bool clearApiKey,
});

class _GatewayConnectionDialog extends StatefulWidget {
  const _GatewayConnectionDialog({
    required this.initialBaseUrl,
    required this.active,
  });

  final String initialBaseUrl;
  final bool active;

  @override
  State<_GatewayConnectionDialog> createState() =>
      _GatewayConnectionDialogState();
}

class _GatewayConnectionDialogState extends State<_GatewayConnectionDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _baseUrlController;
  final _apiKeyController = TextEditingController();
  var _clearApiKey = false;

  @override
  void initState() {
    super.initState();
    _baseUrlController = TextEditingController(text: widget.initialBaseUrl);
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(strings.settingsUpdateConnectionTitle),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                key: const ValueKey('settings-gateway-base-url-field'),
                controller: _baseUrlController,
                keyboardType: TextInputType.url,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  labelText: strings.settingsGatewayUrlLabel,
                  helperText: strings.settingsGatewayUrlHelper,
                ),
                validator: (value) => _gatewayBaseUrlError(strings, value),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const ValueKey('settings-gateway-api-key-field'),
                controller: _apiKeyController,
                obscureText: true,
                autocorrect: false,
                enableSuggestions: false,
                enabled: !_clearApiKey,
                decoration: InputDecoration(
                  labelText: strings.settingsNewTokenLabel,
                  helperText: strings.settingsNewTokenHelper,
                  helperMaxLines: 2,
                ),
              ),
              CheckboxListTile(
                key: const ValueKey('settings-gateway-clear-api-key'),
                contentPadding: EdgeInsets.zero,
                value: _clearApiKey,
                title: Text(strings.settingsClearTokenTitle),
                subtitle: Text(strings.settingsClearTokenSubtitle),
                onChanged: (value) => setState(() {
                  _clearApiKey = value ?? false;
                  if (_clearApiKey) _apiKeyController.clear();
                }),
              ),
              if (widget.active)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(strings.settingsActiveGatewayNote),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(strings.cancelAction),
        ),
        FilledButton(
          key: const ValueKey('settings-gateway-connection-save'),
          onPressed: widget.active ? null : _submit,
          child: Text(strings.settingsSaveAndReconnect),
        ),
      ],
    );
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    final token = _apiKeyController.text.trim();
    Navigator.pop(context, (
      baseUrl: _baseUrlController.text,
      apiKey: token.isEmpty ? null : token,
      clearApiKey: _clearApiKey,
    ));
  }
}

String? _gatewayBaseUrlError(AppLocalizations strings, String? value) {
  final origin = hermesPublicEndpointBaseUrl(value ?? '');
  final uri = Uri.tryParse(origin);
  if (uri == null ||
      !uri.hasScheme ||
      uri.host.isEmpty ||
      (uri.scheme != 'http' && uri.scheme != 'https')) {
    return strings.settingsGatewayOriginError;
  }
  return null;
}

Future<void> _removeGatewayGroup(
  BuildContext context,
  HermesGatewayDirectory directory,
  GatewayHostOverview group,
) async {
  final strings = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      key: const ValueKey('settings-gateway-remove-dialog'),
      title: Text(strings.settingsRemoveGatewayTitle),
      content: Text(strings.settingsRemoveGatewayBody(group.label)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(strings.cancelAction),
        ),
        FilledButton(
          key: const ValueKey('settings-gateway-remove-confirm'),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(strings.voiceRemoveAction),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  await _runGatewayAction(context, () async {
    for (final gatewayId in group.gatewayIds) {
      await directory.removeGateway(gatewayId);
    }
  }, strings.settingsRemoveGatewayError);
}

Future<void> _runGatewayAction(
  BuildContext context,
  Future<void> Function() action,
  String errorMessage,
) async {
  try {
    await action();
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(errorMessage)));
  }
}
