import 'package:flutter/material.dart';

const _profilePalette = <Color>[
  Color(0xFF7C3AED),
  Color(0xFF2563EB),
  Color(0xFF0891B2),
  Color(0xFF059669),
  Color(0xFFD97706),
  Color(0xFFDC2626),
  Color(0xFFDB2777),
  Color(0xFF4F46E5),
];

/// Returns a stable identity color for a Hermes profile.
///
/// An Agent-advertised `#RRGGBB` or `#AARRGGBB` value takes precedence. When
/// absent, the stable wire profile id selects a color without local state.
Color hermesProfileColor(String profileId, {String? advertisedColor}) {
  final advertised = _parseHexColor(advertisedColor);
  if (advertised != null) return advertised;
  var hash = 0x811C9DC5;
  for (final unit in profileId.trim().toLowerCase().codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return _profilePalette[hash % _profilePalette.length];
}

Color hermesProfileForeground(Color background) {
  final luminance = background.computeLuminance();
  final whiteContrast = 1.05 / (luminance + 0.05);
  final blackContrast = (luminance + 0.05) / 0.05;
  return whiteContrast >= blackContrast ? Colors.white : Colors.black;
}

Color? _parseHexColor(String? value) {
  final normalized = value?.trim().replaceFirst('#', '') ?? '';
  if (!RegExp(r'^(?:[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$').hasMatch(normalized)) {
    return null;
  }
  final parsed = int.parse(normalized, radix: 16);
  return Color(0xFF000000 | (parsed & 0x00FFFFFF));
}
