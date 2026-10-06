import 'package:flutter/material.dart';

/// Shell-only roles from Desktop main.css at 2ed89070; never a route theme.
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

  factory AppShellDesktopStyle.forBrightness(Brightness brightness) =>
      brightness == Brightness.dark
      ? const AppShellDesktopStyle._(
          rail: Color(0xff171717),
          workArea: Color(0xff212121),
          foreground: Color(0xffececec),
          secondary: Color(0xffb4b4b4),
          hover: Color(0xff2f2f2f),
          selection: Color(0x26003f7a),
          // Desktop's #006acd falls below 4.5:1 on its dark rail.
          accent: Color(0xff579fff),
          border: Color(0x0fffffff),
        )
      : const AppShellDesktopStyle._(
          rail: Color(0xfff8f8f8),
          workArea: Colors.white,
          foreground: Color(0xff111111),
          secondary: Color(0xff555555),
          hover: Color(0xfff0f0f0),
          selection: Color(0x14003f7a),
          accent: Color(0xff003f7a),
          border: Color(0xffe5e5e5),
        );

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
