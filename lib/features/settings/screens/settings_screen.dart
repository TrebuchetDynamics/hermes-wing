import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/hermes/channel/hermes_channel.dart';
import '../../../core/hermes/policy/hermes_transport_policy.dart';
import '../../../l10n/app_localizations.dart';
import '../../../router/app_routes.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../hermes_chat/diagnostics/hermes_diagnostics_export.dart';
import '../../hermes_chat/providers/hermes_channel_provider.dart';
import '../../../theme/wing_theme.dart';
import '../providers/chat_preferences_provider.dart';
import '../providers/theme_settings_provider.dart';
import '../providers/voice_settings_provider.dart';

part 'settings_diagnostics_screen.dart';
part 'settings_voice_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.settingsDestination),
        actions: const [AppShellMenuButton()],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 820;
          final horizontalPadding = wide ? 32.0 : 16.0;
          final hasSpellcheck = WidgetsBinding
              .instance
              .platformDispatcher
              .nativeSpellCheckServiceDefined;
          final appearance = const _AppearanceSettingsSection();
          final voice = const _VoiceSettingsSection();

          return ListView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              wide ? 28 : 8,
              horizontalPadding,
              32,
            ),
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.dns_outlined),
                  title: Text(strings.gatewayDestination),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go(AppRoutes.gateway),
                ),
              ),
              if (hasSpellcheck) const _ChatSettingsSection(),
              if (wide)
                _SettingsColumns(
                  key: const ValueKey('settings-two-column-layout'),
                  children: [
                    appearance,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [voice, const _DiagnosticsSettingsLink()],
                    ),
                  ],
                )
              else ...[
                appearance,
                voice,
                const _DiagnosticsSettingsLink(),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SettingsColumns extends StatelessWidget {
  const _SettingsColumns({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < children.length; index++) ...[
          if (index > 0) const SizedBox(width: 20),
          Expanded(child: children[index]),
        ],
      ],
    );
  }
}

class _AppearanceSettingsSection extends ConsumerWidget {
  const _AppearanceSettingsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final appearance = ref.watch(wingThemeSettingsProvider);
    final controller = ref.read(wingThemeSettingsProvider.notifier);
    return _SettingsSectionCard(
      title: strings.settingsAppearanceSection,
      icon: Icons.palette_outlined,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: SegmentedButton<ThemeMode>(
            key: const ValueKey('settings-theme-mode'),
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
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
            selected: {appearance.mode},
            onSelectionChanged: (selection) =>
                unawaited(controller.setMode(selection.single)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Semantics(
            container: true,
            identifier: 'settings-palette-picker',
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: strings.themePaletteLabel,
                filled: false,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<WingThemePalette>(
                  key: const ValueKey('settings-palette-picker'),
                  value: appearance.palette,
                  isExpanded: true,
                  isDense: true,
                  itemHeight: null,
                  items: [
                    for (final palette in WingThemePalette.values)
                      DropdownMenuItem(
                        value: palette,
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: palette.seed,
                              radius: 8,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(_paletteLabel(strings, palette)),
                            ),
                          ],
                        ),
                      ),
                  ],
                  onChanged: (palette) {
                    if (palette != null) {
                      unawaited(controller.setPalette(palette));
                    }
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChatSettingsSection extends ConsumerWidget {
  const _ChatSettingsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final preferences = ref.watch(wingChatPreferencesProvider);
    final controller = ref.read(wingChatPreferencesProvider.notifier);
    return _SettingsSectionCard(
      title: strings.settingsChatSection,
      icon: Icons.chat_bubble_outline,
      children: [
        SwitchListTile(
          key: const ValueKey('chat-spellcheck-enabled'),
          title: Text(strings.chatSpellcheckTitle),
          subtitle: Text(strings.chatSpellcheckSubtitle),
          value: preferences.spellcheckEnabled,
          onChanged: controller.setSpellcheckEnabled,
        ),
      ],
    );
  }
}

class _VoiceSettingsSection extends StatelessWidget {
  const _VoiceSettingsSection();

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        key: const ValueKey('settings-voice-link'),
        minTileHeight: 56,
        minVerticalPadding: 8,
        leading: const Icon(Icons.graphic_eq),
        title: Text(strings.voiceSettingsTitle),
        subtitle: Text(strings.settingsVoiceSummary),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(AppRoutes.settingsVoice),
      ),
    );
  }
}

class _DiagnosticsSettingsLink extends ConsumerWidget {
  const _DiagnosticsSettingsLink();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channel = ref.watch(hermesChannelProvider);
    return AnimatedBuilder(
      animation: channel,
      builder: (context, _) {
        final strings = AppLocalizations.of(context);
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            key: const ValueKey('settings-diagnostics-link'),
            minTileHeight: 56,
            minVerticalPadding: 8,
            leading: const Icon(Icons.monitor_heart_outlined),
            title: Text(strings.chatConnectionDiagnosticsTitle),
            subtitle: Text(
              _connectionStatusLabel(strings, channel.state.status),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.settingsDiagnostics),
          ),
        );
      },
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
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            container: true,
            headingLevel: 2,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
              child: Row(
                children: [
                  ExcludeSemantics(
                    child: Icon(icon, size: 16, color: colors.onSurfaceVariant),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(title, style: theme.textTheme.labelLarge),
                  ),
                ],
              ),
            ),
          ),
          Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
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
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 340 ||
            MediaQuery.textScalerOf(context).scale(14) > 18) {
          return ListTile(
            leading: Icon(icon, size: 18, color: iconColor),
            title: Text(title),
            subtitle: Text(value),
            dense: true,
          );
        }
        return MergeSemantics(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: iconColor ?? theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 92,
                  child: Text(
                    title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
              ],
            ),
          ),
        );
      },
    );
  }
}
