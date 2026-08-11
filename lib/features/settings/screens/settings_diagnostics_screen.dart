part of 'settings_screen.dart';

class DiagnosticsSettingsScreen extends ConsumerWidget {
  const DiagnosticsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channel = ref.watch(hermesChannelProvider);
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.diagnosticsTitle),
        actions: const [AppShellMenuButton()],
      ),
      body: AnimatedBuilder(
        animation: channel,
        builder: (context, _) {
          final state = channel.state;
          final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
          return ListView(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
            children: [
              _SettingsSectionCard(
                title: strings.diagnosticsConnectionSection,
                icon: Icons.cable_outlined,
                children: [
                  _StatusTile(
                    icon: Icons.circle,
                    iconColor: switch (state.status) {
                      HermesConnectionStatus.connected => Colors.green,
                      HermesConnectionStatus.connecting => Colors.amber,
                      HermesConnectionStatus.error => Theme.of(
                        context,
                      ).colorScheme.error,
                      HermesConnectionStatus.disconnected => Theme.of(
                        context,
                      ).colorScheme.outline,
                    },
                    title: strings.diagnosticsStatusLabel,
                    value: _connectionStatusLabel(strings, state.status),
                  ),
                  _StatusTile(
                    icon: Icons.memory_outlined,
                    title: strings.diagnosticsModelLabel,
                    value: state.models.isEmpty
                        ? state.capabilities?.model ??
                              strings.diagnosticsModelNotReported
                        : state.models.first,
                  ),
                  _StatusTile(
                    icon: Icons.account_tree_outlined,
                    title: strings.diagnosticsRunTransportLabel,
                    value: _runTransportLabel(strings, state),
                  ),
                  _StatusTile(
                    icon: Icons.info_outline,
                    title: strings.diagnosticsVersionHealthLabel,
                    value: _healthLabel(strings, state),
                  ),
                ],
              ),
              _SettingsSectionCard(
                title: strings.diagnosticsInventorySection,
                icon: Icons.checklist_outlined,
                children: [
                  _StatusTile(
                    icon: Icons.inventory_2_outlined,
                    title: strings.diagnosticsResourcesLabel,
                    value: strings.diagnosticsResourcesSummary(
                      state.models.length,
                      state.skills.length,
                      state.enabledToolsets.length,
                      state.jobs.length,
                    ),
                  ),
                  if (state.optionalResourceErrors.isNotEmpty)
                    _StatusTile(
                      icon: Icons.warning_amber_outlined,
                      title: strings.diagnosticsInventoryWarningsLabel,
                      value: _optionalResourceWarningLabel(
                        strings,
                        state.optionalResourceErrors.keys,
                      ),
                    ),
                ],
              ),
              _SettingsSectionCard(
                title: strings.diagnosticsSessionsSection,
                icon: Icons.chat_outlined,
                children: [
                  _StatusTile(
                    icon: Icons.chat_outlined,
                    title: strings.diagnosticsSessionsSection,
                    value: strings.diagnosticsSessionsSummary(
                      state.sessions.length,
                      state.activeSessionId == null
                          ? strings.diagnosticsActiveNone
                          : strings.diagnosticsActiveYes,
                    ),
                  ),
                ],
              ),
              _SettingsSectionCard(
                title: strings.diagnosticsExportSection,
                icon: Icons.copy_outlined,
                children: [
                  ListTile(
                    key: const ValueKey('settings-copy-diagnostics'),
                    leading: const Icon(Icons.copy_outlined),
                    title: Text(strings.diagnosticsCopyTitle),
                    subtitle: Text(strings.diagnosticsCopySubtitle),
                    onTap: () async {
                      await Clipboard.setData(
                        ClipboardData(text: hermesDiagnosticsExport(state)),
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(strings.diagnosticsCopiedNotice),
                        ),
                      );
                    },
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

String _connectionStatusLabel(
  AppLocalizations strings,
  HermesConnectionStatus status,
) => switch (status) {
  HermesConnectionStatus.disconnected => strings.diagnosticsStatusDisconnected,
  HermesConnectionStatus.connecting => strings.diagnosticsStatusConnecting,
  HermesConnectionStatus.connected => strings.diagnosticsStatusConnected,
  HermesConnectionStatus.error => strings.diagnosticsStatusError,
};

String _runTransportLabel(AppLocalizations strings, HermesChannelState state) {
  final capabilities = state.capabilities;
  if (capabilities == null) return strings.diagnosticsTransportNotConnected;
  final policy = HermesTransportPolicy(capabilities);
  if (policy.supportsRunsTransport) return strings.diagnosticsTransportRunsSse;
  if (policy.supportsSessionChatStream) {
    return strings.diagnosticsTransportSessionStream;
  }
  return strings.diagnosticsTransportUnavailable;
}

String _healthLabel(AppLocalizations strings, HermesChannelState state) {
  final health = state.detailedHealth;
  if (health == null) {
    return state.errorMessage ?? strings.diagnosticsNoHealthDetails;
  }
  final version = health.version ?? strings.diagnosticsUnknownVersion;
  final gateway = health.gatewayState ?? strings.diagnosticsUnknownGateway;
  return strings.diagnosticsHealthSummary(version, gateway);
}

String _optionalResourceWarningLabel(
  AppLocalizations strings,
  Iterable<HermesOptionalResource> resources,
) {
  final labels =
      resources
          .map(
            (resource) => switch (resource) {
              HermesOptionalResource.detailedHealth =>
                strings.diagnosticsResourceHealth,
              HermesOptionalResource.models =>
                strings.diagnosticsResourceModels,
              HermesOptionalResource.skills =>
                strings.diagnosticsResourceSkills,
              HermesOptionalResource.toolsets =>
                strings.diagnosticsResourceToolsets,
              HermesOptionalResource.jobs => strings.diagnosticsResourceJobs,
            },
          )
          .toList()
        ..sort();
  final summary = labels.join(', ');
  return strings.diagnosticsUnavailableSummary(
    '${summary[0].toUpperCase()}${summary.substring(1)}',
  );
}
