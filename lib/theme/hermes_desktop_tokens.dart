import 'package:flutter/material.dart';

/// Nous seeds and applied CSS mixes from official Desktop ccc695635094.
/// One palette for compact and wide clients; no native glass dependency.
abstract final class HermesDesktopTokens {
  static const primary = Color(0xff0053fd);
  static const darkPrimary = Color(0xff4a84fe);

  static ColorScheme colors(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final foreground = dark ? const Color(0xffe6edf3) : const Color(0xff1f2328);
    final chrome = Color.lerp(
      dark ? const Color(0xff0d0d0e) : const Color(0xfff3f3f3),
      dark ? const Color(0xff0d1117) : Colors.white,
      dark ? 0.74 : 0.92,
    )!;
    final editor = Color.lerp(
      dark ? const Color(0xff161618) : const Color(0xfffcfcfc),
      dark ? const Color(0xff010409) : const Color(0xfff6f8fa),
      dark ? 0.38 : 0.22,
    )!;
    final accent = dark ? darkPrimary : primary;
    return ColorScheme.fromSeed(
      seedColor: accent,
      brightness: brightness,
    ).copyWith(
      primary: accent,
      onPrimary: dark ? const Color(0xff161616) : Colors.white,
      primaryContainer: dark
          ? const Color(0xff1d2e4f)
          : const Color(0xffdeeaff),
      onPrimaryContainer: foreground,
      secondary: accent,
      onSecondary: dark ? const Color(0xff161616) : Colors.white,
      surface: chrome,
      onSurface: foreground.withValues(alpha: 0.94),
      onSurfaceVariant: foreground.withValues(alpha: 0.74),
      surfaceContainerLowest: editor,
      surfaceContainerLow: dark
          ? const Color(0xff010409)
          : const Color(0xfff6f8fa),
      surfaceContainer: editor,
      surfaceContainerHigh: dark
          ? const Color(0xff161b22)
          : const Color(0xfff6f8fa),
      surfaceContainerHighest: dark
          ? const Color(0xff1a1e24)
          : const Color(0xfff6f6f6),
      outline: dark ? const Color(0xff7d8590) : const Color(0xff656d76),
      outlineVariant: dark ? const Color(0xff30363d) : const Color(0xffd0d7de),
      error: dark ? const Color(0xfff85149) : const Color(0xffcf222e),
      onError: dark ? const Color(0xff161616) : Colors.white,
    );
  }
}
