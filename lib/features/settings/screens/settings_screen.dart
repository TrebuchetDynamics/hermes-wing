import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pocket_speech/pocket_speech.dart';

import '../../../core/hermes/channel/hermes_channel.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/hermes/policy/hermes_transport_policy.dart';
import '../../../core/hermes/setup/hermes_endpoint_store.dart';
import '../../../router/app_routes.dart';
import '../../hermes_chat/diagnostics/hermes_diagnostics_export.dart';
import '../../hermes_chat/gateways/gateway_contact.dart';
import '../../hermes_chat/gateways/hermes_gateway_directory.dart';
import '../../hermes_chat/providers/hermes_channel_provider.dart';
import '../../../theme/wing_theme.dart';
import '../../voice/services/tts/text_to_speech_service.dart';
import '../providers/theme_settings_provider.dart';
import '../providers/voice_settings_provider.dart';

part 'settings_diagnostics_screen.dart';
part 'settings_voice_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(wingVoiceSettingsProvider);
    final controller = ref.read(wingVoiceSettingsProvider.notifier);
    final channel = ref.watch(hermesChannelProvider);
    final gatewayDirectory = ref.watch(hermesGatewayDirectoryProvider);

    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.settingsDestination)),
      body: AnimatedBuilder(
        animation: channel,
        builder: (context, _) {
          final state = channel.state;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SettingsSectionCard(
                title: strings.settingsGatewaysSection,
                icon: Icons.cable_outlined,
                children: [
                  if (gatewayDirectory.gateways.isEmpty)
                    _StatusTile(
                      icon: Icons.link_off,
                      title: strings.settingsGatewaysSection,
                      value: strings.settingsNoSavedGateways,
                    )
                  else
                    for (final gateway in gatewayDirectory.gateways)
                      _GatewaySettingsTile(
                        gateway: gateway,
                        directory: gatewayDirectory,
                      ),
                  ListTile(
                    key: const ValueKey('settings-connect-another-gateway'),
                    leading: const Icon(Icons.add_link),
                    title: Text(strings.settingsConnectAnotherGateway),
                    subtitle: Text(strings.settingsScanPairingQr),
                    onTap: () => context.push(AppRoutes.enroll),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Text(strings.settingsCredentialsNote),
                  ),
                ],
              ),
              _SettingsSectionCard(
                title: strings.settingsAppearanceSection,
                icon: Icons.palette_outlined,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: SegmentedButton<ThemeMode>(
                      key: const ValueKey('settings-theme-mode'),
                      segments: [
                        ButtonSegment(
                          value: ThemeMode.system,
                          label: Text(strings.themeModeSystem),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          label: Text(strings.themeModeLight),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          label: Text(strings.themeModeDark),
                        ),
                      ],
                      selected: {ref.watch(wingThemeSettingsProvider).mode},
                      onSelectionChanged: (selection) => unawaited(
                        ref
                            .read(wingThemeSettingsProvider.notifier)
                            .setMode(selection.single),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (final palette in WingThemePalette.values)
                          ChoiceChip(
                            key: ValueKey('settings-palette-${palette.name}'),
                            avatar: CircleAvatar(
                              backgroundColor: palette.seed,
                              radius: 8,
                            ),
                            label: Text(_paletteLabel(strings, palette)),
                            selected:
                                ref.watch(wingThemeSettingsProvider).palette ==
                                palette,
                            onSelected: (_) => unawaited(
                              ref
                                  .read(wingThemeSettingsProvider.notifier)
                                  .setPalette(palette),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              _SettingsSectionCard(
                title: strings.settingsVoiceSection,
                icon: Icons.keyboard_voice_outlined,
                children: [
                  SwitchListTile(
                    key: const ValueKey('voice-continuous-enabled'),
                    title: Text(strings.voiceContinuousTitle),
                    subtitle: Text(strings.voiceContinuousSubtitle),
                    value: settings.continuousVoiceEnabled,
                    onChanged: controller.setContinuousVoiceEnabled,
                  ),
                  SwitchListTile(
                    key: const ValueKey('voice-speak-replies-enabled'),
                    title: Text(strings.voiceSpeakRepliesTitle),
                    subtitle: Text(strings.voiceSpeakRepliesSubtitle),
                    value: settings.speakRepliesEnabled,
                    onChanged: controller.setSpeakRepliesEnabled,
                  ),
                  ListTile(
                    key: const ValueKey('settings-voice-link'),
                    leading: const Icon(Icons.graphic_eq),
                    title: Text(strings.voiceSettingsTitle),
                    subtitle: Text(
                      strings.settingsVoiceLinkSummary(
                        settings.pocketSpeechModel.label,
                        settings.pocketSpeechVoicePackReady
                            ? strings.settingsVoiceInstalled
                            : strings.settingsVoiceNotInstalled,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(AppRoutes.settingsVoice),
                  ),
                ],
              ),
              _SettingsSectionCard(
                title: strings.diagnosticsTitle,
                icon: Icons.monitor_heart_outlined,
                children: [
                  ListTile(
                    key: const ValueKey('settings-diagnostics-link'),
                    leading: const Icon(Icons.monitor_heart_outlined),
                    title: Text(strings.diagnosticsTitle),
                    subtitle: Text(
                      _connectionStatusLabel(strings, state.status),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(AppRoutes.settingsDiagnostics),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

String _paletteLabel(AppLocalizations strings, WingThemePalette palette) =>
    switch (palette) {
      WingThemePalette.wing => strings.themePaletteWing,
      WingThemePalette.indigo => strings.themePaletteIndigo,
      WingThemePalette.forest => strings.themePaletteForest,
      WingThemePalette.amber => strings.themePaletteAmber,
      WingThemePalette.mulberry => strings.themePaletteMulberry,
    };

class _GatewaySettingsTile extends StatelessWidget {
  const _GatewaySettingsTile({required this.gateway, required this.directory});

  final GatewayOverview gateway;
  final HermesGatewayDirectory directory;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return ListTile(
      leading: Icon(
        gateway.availability == GatewayAvailability.online
            ? Icons.cloud_done_outlined
            : Icons.cloud_off_outlined,
      ),
      title: Text(gateway.label),
      subtitle: Text('${gateway.baseUrl} · ${gateway.availability.name}'),
      trailing: PopupMenuButton<String>(
        key: ValueKey('settings-gateway-menu-${gateway.id}'),
        tooltip: strings.settingsGatewayActionsTooltip(gateway.label),
        onSelected: (action) async {
          if (action == 'agents') {
            await _runGatewayAction(context, () async {
              await directory.activateGateway(gateway.id);
              if (context.mounted) context.go(AppRoutes.agents);
            }, strings.settingsConnectGatewayError);
          } else if (action == 'rename') {
            await _renameGateway(context, directory, gateway);
          } else if (action == 'connection') {
            await _updateGatewayConnection(context, directory, gateway);
          } else if (action == 'reconnect') {
            await _runGatewayAction(
              context,
              () => directory.reconnectGateway(gateway.id),
              strings.settingsReconnectGatewayError,
            );
          } else if (action == 'remove') {
            await _removeGateway(context, directory, gateway);
          }
        },
        itemBuilder: (_) => [
          PopupMenuItem(
            value: 'agents',
            child: Text(strings.settingsManageAgentsAction),
          ),
          PopupMenuItem(
            value: 'rename',
            child: Text(strings.settingsRenameAction),
          ),
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

Future<void> _removeGateway(
  BuildContext context,
  HermesGatewayDirectory directory,
  GatewayOverview gateway,
) async {
  final strings = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      key: const ValueKey('settings-gateway-remove-dialog'),
      title: Text(strings.settingsRemoveGatewayTitle),
      content: Text(strings.settingsRemoveGatewayBody(gateway.label)),
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
  await _runGatewayAction(
    context,
    () => directory.removeGateway(gateway.id),
    strings.settingsRemoveGatewayError,
  );
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

class _SettingsSectionCard extends StatelessWidget {
  const _SettingsSectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            leading: Icon(icon),
            title: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(value),
      dense: true,
    );
  }
}
