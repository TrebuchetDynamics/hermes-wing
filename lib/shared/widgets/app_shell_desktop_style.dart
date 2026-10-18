import 'package:flutter/material.dart';

import '../../theme/hermes_desktop_tokens.dart';

/// Shell roles share the official Desktop palette with compact feature routes.
class AppShellDesktopStyle {
  const AppShellDesktopStyle._({
    required this.rail,
    required this.workArea,
    required this.foreground,
    required this.secondary,
    required this.hover,
    required this.selection,
    required this.accent,
    required this.border,
  });

  factory AppShellDesktopStyle.forBrightness(Brightness brightness) {
    final colors = HermesDesktopTokens.colors(brightness);
    return AppShellDesktopStyle._(
      rail: colors.surfaceContainerLow,
      workArea: colors.surface,
      foreground: colors.onSurface,
      secondary: colors.onSurfaceVariant,
      hover: colors.primary.withValues(alpha: 0.06),
      selection: colors.primary.withValues(alpha: 0.08),
      accent: colors.primary,
      border: colors.outlineVariant,
    );
  }

  final Color rail;
  final Color workArea;
  final Color foreground;
  final Color secondary;
  final Color hover;
  final Color selection;
  final Color accent;
  final Color border;

  static const shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(10)),
  );

  ThemeData sidebarTheme(ThemeData theme) => theme.copyWith(
    colorScheme: theme.colorScheme.copyWith(
      surface: rail,
      primary: accent,
      onSurface: foreground,
      onSurfaceVariant: secondary,
      outlineVariant: border,
    ),
    textTheme: theme.textTheme.apply(
      bodyColor: foreground,
      displayColor: foreground,
    ),
    iconTheme: IconThemeData(color: secondary, size: 16),
    textButtonTheme: TextButtonThemeData(
      style: navigationStyle(selected: false),
    ),
  );

  // Opaque Ink overlays cover IconButton's Material border. Focus leaves the
  // shape visible, including when the pointer also hovers the focused control.
  ButtonStyle toggleStyle() => navigationStyle(selected: false).copyWith(
    overlayColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.focused)
          ? Colors.transparent
          : states.contains(WidgetState.hovered)
          ? hover
          : Colors.transparent,
    ),
    side: WidgetStateProperty.resolveWith(
      (states) => BorderSide(
        width: 2,
        color: states.contains(WidgetState.focused)
            ? secondary
            : Colors.transparent,
      ),
    ),
  );

  ButtonStyle navigationStyle({required bool selected}) => ButtonStyle(
    minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
    padding: const WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    ),
    shape: const WidgetStatePropertyAll(shape),
    textStyle: WidgetStatePropertyAll(
      TextStyle(
        fontSize: 13,
        height: 1.4,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
      ),
    ),
    foregroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return secondary.withValues(alpha: 0.55);
      }
      return selected ? accent : foreground;
    }),
    backgroundColor: WidgetStatePropertyAll(
      selected ? selection : Colors.transparent,
    ),
    overlayColor: WidgetStateProperty.resolveWith(
      (states) =>
          states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.focused)
          ? hover
          : Colors.transparent,
    ),
    side: WidgetStateProperty.resolveWith(
      (states) => BorderSide(
        color: states.contains(WidgetState.focused)
            ? secondary
            : Colors.transparent,
      ),
    ),
    animationDuration: const Duration(milliseconds: 150),
  );
}
