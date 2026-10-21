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

enum _SettingsCategory { appearance, chat, voice, connections }

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    this.initialCategory,
    this.onCategoryChanged,
    super.key,
  });

  final String? initialCategory;
  final ValueChanged<String>? onCategoryChanged;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  _SettingsCategory _category = _SettingsCategory.appearance;

  _SettingsCategory _resolveCategory(String? name) =>
      _SettingsCategory.values
          .where(
            (category) =>
                category.name ==
                switch (name) {
                  'config:appearance' => 'appearance',
                  'config:chat' => 'chat',
                  'config:voice' => 'voice',
                  'gateway' => 'connections',
                  _ => name,
                },
          )
          .firstOrNull ??
      _SettingsCategory.appearance;

  void _selectCategory(_SettingsCategory category) {
    setState(() => _category = category);
    widget.onCategoryChanged?.call(switch (category) {
      _SettingsCategory.appearance => 'config:appearance',
      _SettingsCategory.chat => 'config:chat',
      _SettingsCategory.voice => 'config:voice',
      _SettingsCategory.connections => 'gateway',
    });
  }

  @override
  void initState() {
    super.initState();
    _category = _resolveCategory(widget.initialCategory);
  }

  @override
  void didUpdateWidget(covariant SettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialCategory != widget.initialCategory) {
      _category = _resolveCategory(widget.initialCategory);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final labels = {
      _SettingsCategory.appearance: strings.settingsAppearanceSection,
      _SettingsCategory.chat: strings.settingsChatSection,
      _SettingsCategory.voice: strings.settingsVoiceSection,
      _SettingsCategory.connections: strings.gatewayDestination,
    };
    const icons = {
      _SettingsCategory.appearance: Icons.palette_outlined,
      _SettingsCategory.chat: Icons.chat_bubble_outline,
      _SettingsCategory.voice: Icons.mic_none_outlined,
      _SettingsCategory.connections: Icons.dns_outlined,
    };
    final hasSpellcheck = WidgetsBinding
        .instance
        .platformDispatcher
        .nativeSpellCheckServiceDefined;
    final categories = [
      for (final category in _SettingsCategory.values)
        if (category != _SettingsCategory.chat || hasSpellcheck) category,
    ];
    final selectedCategory = categories.contains(_category)
        ? _category
        : _SettingsCategory.appearance;
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
                key: ValueKey('settings-content-${selectedCategory.name}'),
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
                        title: wide ? labels[selectedCategory]! : null,
                        children: switch (selectedCategory) {
                          _SettingsCategory.appearance => [
                            const _AppearanceSettingsSection(),
                          ],
                          _SettingsCategory.chat => [
                            if (hasSpellcheck) const _ChatSettingsSection(),
                          ],
                          _SettingsCategory.voice => [
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
                    key: ValueKey((
                      'settings-category-selection',
                      selectedCategory,
                    )),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: DropdownButtonFormField<_SettingsCategory>(
                      key: const ValueKey('settings-category-picker'),
                      initialValue: selectedCategory,
                      isExpanded: true,
                      itemHeight: null,
                      decoration: InputDecoration(
                        labelText: strings.settingsDestination,
                      ),
                      items: [
                        for (final category in categories)
                          DropdownMenuItem(
                            value: category,
                            child: Text(labels[category]!),
                          ),
                      ],
                      onChanged: (category) {
                        if (category != null) {
                          _selectCategory(category);
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
                          for (final category in categories)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: ListTile(
                                key: ValueKey(
                                  'settings-category-${category.name}',
                                ),
                                selected: selectedCategory == category,
                                selectedTileColor: Theme.of(
                                  context,
                                ).colorScheme.secondaryContainer,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                leading: Icon(icons[category], size: 20),
                                title: Text(labels[category]!),
                                onTap: () => _selectCategory(category),
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
        const _ChatTextScaleSetting(),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            strings.themePaletteLabel,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final largeText = MediaQuery.textScalerOf(context).scale(14) > 20;
            final columns = largeText || constraints.maxWidth < 440
                ? 1
                : constraints.maxWidth < 720
                ? 2
                : 3;
            final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
            return Wrap(
              key: const ValueKey('settings-theme-gallery'),
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final palette in WingThemePalette.values)
                  SizedBox(
                    width: width,
                    child: _ThemePreviewChoice(
                      palette: palette,
                      label: _paletteLabel(strings, palette),
                      selected: appearance.palette == palette,
                      onSelected: () =>
                          unawaited(controller.setPalette(palette)),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ChatTextScaleSetting extends ConsumerWidget {
  const _ChatTextScaleSetting();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final scale = ref.watch(wingChatPreferencesProvider).transcriptTextScale;
    final percent = (scale * 100).round();
    // Pinch zoom can retain intermediate values; displaying Settings must not
    // silently round or overwrite that saved presentation preference.
    final percentages = {90, 100, 110, 125, 150, 175, percent}.toList()..sort();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            strings.chatTextScaleTitle,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 4),
          Text(
            strings.chatTextScaleDescription,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final value in percentages)
                ChoiceChip(
                  key: ValueKey('settings-chat-text-scale-$value'),
                  label: Text('$value%'),
                  selected: value == percent,
                  onSelected: (_) => ref
                      .read(wingChatPreferencesProvider.notifier)
                      .setTranscriptTextScale(value / 100),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ThemePreviewChoice extends StatelessWidget {
  const _ThemePreviewChoice({
    required this.palette,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final WingThemePalette palette;
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = wingThemeFor(palette, theme.brightness).colorScheme;
    final border = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.outlineVariant;
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: border, width: selected ? 2 : 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('settings-theme-${palette.name}'),
          onTap: onSelected,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ExcludeSemantics(
                  child: Container(
                    height: 88,
                    decoration: BoxDecoration(
                      color: preview.surface,
                      border: Border.all(color: preview.outlineVariant),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Row(
                      children: [
                        Container(
                          width: 30,
                          color: preview.surfaceContainerLow,
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  height: 5,
                                  width: 52,
                                  color: preview.onSurface,
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  height: 4,
                                  width: 76,
                                  color: preview.onSurfaceVariant,
                                ),
                                const Spacer(),
                                Align(
                                  alignment: AlignmentDirectional.centerEnd,
                                  child: Container(
                                    height: 16,
                                    width: 42,
                                    decoration: BoxDecoration(
                                      color: preview.primary,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(label, style: theme.textTheme.labelLarge),
                    ),
                    const SizedBox(width: 8),
                    if (selected)
                      Icon(
                        Icons.check,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
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
