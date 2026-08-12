import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/hermes_chat/widgets/hermes_profile_identity.dart';

void main() {
  test('profile color is stable and distinguishes known profile ids', () {
    final first = hermesProfileColor('sidon');
    expect(hermesProfileColor('sidon'), first);
    expect(hermesProfileColor('mineru'), isNot(first));
    expect(hermesProfileColor('default'), isNot(first));
  });

  test('valid advertised hex color overrides the stable palette', () {
    expect(
      hermesProfileColor('sidon', advertisedColor: '#7C3AED'),
      const Color(0xFF7C3AED),
    );
    expect(
      hermesProfileColor('sidon', advertisedColor: 'not-a-color'),
      hermesProfileColor('sidon'),
    );
  });

  test('advertised alpha is normalized to an opaque identity color', () {
    expect(
      hermesProfileColor('sidon', advertisedColor: '#007C3AED'),
      const Color(0xFF7C3AED),
    );
  });

  test('profile foreground remains legible against its identity color', () {
    final backgrounds = <Color>[
      for (final id in ['sidon', 'mineru', 'default', 'coding-agent'])
        hermesProfileColor(id),
      const Color(0xFF777777),
      const Color(0xFFEEEEEE),
      const Color(0xFF101010),
    ];
    for (final background in backgrounds) {
      final foreground = hermesProfileForeground(background);
      expect(foreground, anyOf(Colors.white, Colors.black));
      expect(_contrastRatio(background, foreground), greaterThanOrEqualTo(4.5));
    }
  });
}

double _contrastRatio(Color first, Color second) {
  final lighter = first.computeLuminance() > second.computeLuminance()
      ? first
      : second;
  final darker = identical(lighter, first) ? second : first;
  return (lighter.computeLuminance() + 0.05) /
      (darker.computeLuminance() + 0.05);
}
