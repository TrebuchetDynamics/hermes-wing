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

enum _SettingsCategory { appearance, chat, connections }

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  _SettingsCategory _category = _SettingsCategory.appearance;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final labels = {
      _SettingsCategory.appearance: strings.settingsAppearanceSection,
      _SettingsCategory.chat: strings.settingsChatSection,
      _SettingsCategory.connections: strings.gatewayDestination,
    };
    const icons = {
      _SettingsCategory.appearance: Icons.palette_outlined,
      _SettingsCategory.chat: Icons.chat_bubble_outline,
      _SettingsCategory.connections: Icons.dns_outlined,
    };
    final hasSpellcheck = WidgetsBinding
        .instance
        .platformDispatcher
        .nativeSpellCheckServiceDefined;
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.settingsDestination),
        actions: const [AppShellMenuButton()],
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
            final wide = constraints.maxWidth >= 820 * textScale.clamp(1, 1.5);
            final content = FocusTraversalGroup(
              child: ListView(
                key: ValueKey('settings-content-${_category.name}'),
                padding: EdgeInsets.fromLTRB(
                  wide ? 32 : 16,
                  24,
                  wide ? 32 : 16,
                  32,
                ),
                children: [
                  Align(
                    alignment: AlignmentDirectional.topStart,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 840),
                      child: _SettingsCategoryContent(
                        title: wide ? labels[_category]! : null,
                        children: switch (_category) {
                          _SettingsCategory.appearance => [
                            const _AppearanceSettingsSection(),
                          ],
                          _SettingsCategory.chat => [
                            if (hasSpellcheck) const _ChatSettingsSection(),
                            const _VoiceSettingsSection(),
                          ],
                          _SettingsCategory.connections => [
                            ListTile(
                              key: const ValueKey('settings-connections-link'),
                              contentPadding: EdgeInsets.zero,
                              minTileHeight: 56,
                              title: Text(strings.gatewayDestination),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => context.go(AppRoutes.gateway),
                            ),
                            const _DiagnosticsSettingsLink(),
                          ],
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
            if (!wide) {
              return Column(
                key: const ValueKey('settings-compact-layout'),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: DropdownButtonFormField<_SettingsCategory>(
                      key: const ValueKey('settings-category-picker'),
                      initialValue: _category,
                      isExpanded: true,
                      itemHeight: null,
                      decoration: InputDecoration(
                        labelText: strings.settingsDestination,
                      ),
                      items: [
                        for (final category in _SettingsCategory.values)
                          DropdownMenuItem(
                            value: category,
                            child: Text(labels[category]!),
                          ),
                      ],
                      onChanged: (category) {
                        if (category != null) {
                          setState(() => _category = category);
                        }
                      },
                    ),
                  ),
                  Expanded(child: content),
                ],
              );
            }
            return Row(
              key: const ValueKey('settings-category-layout'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 208,
                  child: Material(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    child: FocusTraversalGroup(
                      child: ListView(
                        padding: const EdgeInsets.all(12),
                        children: [
                          for (final category in _SettingsCategory.values)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: ListTile(
                                key: ValueKey(
                                  'settings-category-${category.name}',
                                ),
                                selected: _category == category,
                                selectedTileColor: Theme.of(
                                  context,
                                ).colorScheme.secondaryContainer,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                leading: Icon(icons[category], size: 20),
                                title: Text(labels[category]!),
                                onTap: () =>
                                    setState(() => _category = category),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: content),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SettingsCategoryContent extends StatelessWidget {
  const _SettingsCategoryContent({required this.title, required this.children});

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (title != null) ...[
        Semantics(
          headingLevel: 2,
          child: Text(title!, style: Theme.of(context).textTheme.titleLarge),
        ),
        const SizedBox(height: 16),
      ],
      for (var index = 0; index < children.length; index++) ...[
        if (index > 0) const Divider(height: 1),
        children[index],
      ],
    ],
  );
}

// As in Desktop ListRow, the pane's width (not the window) owns control layout.
class _SettingsControlRow extends StatelessWidget {
  const _SettingsControlRow({required this.label, required this.control});

  final String label;
  final Widget control;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final title = Text(label, style: Theme.of(context).textTheme.bodyLarge);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child:
            constraints.maxWidth >= 640 &&
                MediaQuery.textScalerOf(context).scale(14) <= 18
            ? Row(
                children: [
                  Expanded(child: title),
                  const SizedBox(width: 24),
                  SizedBox(width: 300, child: control),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [title, const SizedBox(height: 12), control],
              ),
      );
    },
  );
}

class _AppearanceSettingsSection extends ConsumerWidget {
  const _AppearanceSettingsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final appearance = ref.watch(wingThemeSettingsProvider);
    final controller = ref.read(wingThemeSettingsProvider.notifier);
    final modes = [
      ButtonSegment(
        value: ThemeMode.system,
        label: Text(strings.themeModeSystem),
      ),
      ButtonSegment(
        value: ThemeMode.light,
        label: Text(strings.themeModeLight),
      ),
      ButtonSegment(value: ThemeMode.dark, label: Text(strings.themeModeDark)),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Vertical native segments preserve full labels at 200% text.
              final stacked =
                  constraints.maxWidth < 360 ||
                  MediaQuery.textScalerOf(context).scale(14) > 18;
              return SegmentedButton<ThemeMode>(
                key: const ValueKey('settings-theme-mode'),
                direction: stacked ? Axis.vertical : Axis.horizontal,
                showSelectedIcon: false,
                segments: modes,
                selected: {appearance.mode},
                onSelectionChanged: (selection) =>
                    unawaited(controller.setMode(selection.single)),
              );
            },
          ),
        ),
        const Divider(height: 1),
        _SettingsControlRow(
          label: strings.themePaletteLabel,
          control: Semantics(
            identifier: 'settings-palette-picker',
            label: strings.themePaletteLabel,
            child: DropdownButtonFormField<WingThemePalette>(
              key: const ValueKey('settings-palette-picker'),
              initialValue: appearance.palette,
              isExpanded: true,
              itemHeight: null,
              decoration: const InputDecoration(isDense: false),
              items: [
                for (final palette in WingThemePalette.values)
                  DropdownMenuItem(
                    value: palette,
                    child: Row(
                      children: [
                        ExcludeSemantics(
                          child: CircleAvatar(
                            backgroundColor: palette.seed,
                            radius: 8,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(_paletteLabel(strings, palette))),
                      ],
                    ),
                  ),
              ],
              onChanged: (palette) {
                if (palette != null) unawaited(controller.setPalette(palette));
              },
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
    return SwitchListTile(
      key: const ValueKey('chat-spellcheck-enabled'),
      contentPadding: EdgeInsets.zero,
      title: Text(strings.chatSpellcheckTitle),
      subtitle: Text(strings.chatSpellcheckSubtitle),
      value: preferences.spellcheckEnabled,
      onChanged: controller.setSpellcheckEnabled,
    );
  }
}

class _VoiceSettingsSection extends StatelessWidget {
  const _VoiceSettingsSection();

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      key: const ValueKey('settings-voice-link'),
      minTileHeight: 56,
      minVerticalPadding: 8,
      leading: const Icon(Icons.graphic_eq),
      title: Text(strings.voiceSettingsTitle),
      subtitle: Text(strings.settingsVoiceSummary),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push(AppRoutes.settingsVoice),
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
        return ListTile(
          contentPadding: EdgeInsets.zero,
          key: const ValueKey('settings-diagnostics-link'),
          minTileHeight: 56,
          minVerticalPadding: 8,
          leading: const Icon(Icons.monitor_heart_outlined),
          title: Text(strings.chatConnectionDiagnosticsTitle),
          subtitle: Text(_connectionStatusLabel(strings, channel.state.status)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push(AppRoutes.settingsDiagnostics),
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
