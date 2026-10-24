import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Static, metadata-free BotFace fallback from official Desktop 14e1e43a2376:
/// plugins/hermes-bots/avatar.tsx and lib/profile-color.ts. This does not assign
/// an Agent avatar or consume the retired Wing creature-family preference.
class HermesProfileAvatar extends StatelessWidget {
  const HermesProfileAvatar({
    required this.profileId,
    this.size = 36,
    super.key,
  });

  final String profileId;
  final double size;

  static int _hash(Iterable<int> units) {
    var hash = 0;
    for (final unit in units) {
      hash = (hash * 31 + unit) & 0xffffffff;
    }
    return hash;
  }

  static String shapeFor(String name) {
    if (name.trim().toLowerCase() == 'default') return 'squircle';
    const shapes = [
      'circle',
      'squircle',
      'pill',
      'triangle',
      'hexagon',
      'cloud',
      'drop',
    ];
    // JS for-of visits codepoints, while charCodeAt(0) uses the first UTF-16 unit.
    final units = name.runes.map(
      (rune) => rune > 0xffff ? 0xd800 + ((rune - 0x10000) >> 10) : rune,
    );
    return shapes[_hash(units) % shapes.length];
  }

  static Color colorFor(String name) {
    final key = name.trim();
    if (key.isEmpty || key.toLowerCase() == 'default') {
      return const Color(0xff8b5cf6);
    }
    return HSLColor.fromAHSL(
      1,
      (_hash(key.codeUnits) % 360).toDouble(),
      .68,
      .58,
    ).toColor();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _ProfileFacePainter(shapeFor(profileId), colorFor(profileId)),
      ),
    ),
  );
}

class _ProfileFacePainter extends CustomPainter {
  const _ProfileFacePainter(this.shape, this.color);
  final String shape;
  final Color color;

  Path _outline() {
    if (shape == 'cloud') {
      return Path()
        ..moveTo(11, 32)
        ..arcToPoint(const Offset(10, 17.1), radius: const Radius.circular(7.5))
        ..arcToPoint(const Offset(29, 12.5), radius: const Radius.circular(9.5))
        ..arcToPoint(const Offset(30, 32), radius: const Radius.circular(7))
        ..close();
    }
    if (shape == 'drop') {
      return Path()
        ..moveTo(20, 3)
        ..cubicTo(20, 3, 6, 20, 6, 27)
        ..arcToPoint(
          const Offset(34, 27),
          radius: const Radius.elliptical(14, 13.5),
          clockwise: false,
        )
        ..cubicTo(34, 20, 20, 3, 20, 3)
        ..close();
    }
    final path = Path();
    for (var i = 0; i < 52; i++) {
      final angle = i / 52 * math.pi * 2 - math.pi / 2;
      final c = math.cos(angle);
      final s = math.sin(angle);
      var radius = 16.2;
      if (shape == 'squircle') {
        radius =
            16.2 / math.pow(math.pow(c.abs(), 5) + math.pow(s.abs(), 5), 1 / 5);
      } else if (shape == 'pill') {
        radius =
            16 /
            math.pow(
              math.pow(c.abs(), 8) + math.pow((s / .72).abs(), 8),
              1 / 8,
            );
      } else if (shape == 'triangle') {
        final sector =
            ((angle + math.pi / 2 + math.pi * 2) %
                (math.pi * 2) /
                (math.pi * 2 / 3)) %
            1;
        radius = 13.5 / math.max(.42, math.cos((sector - .5) * 1.9));
      } else if (shape == 'hexagon') {
        const segment = math.pi / 3;
        radius =
            16.2 *
            math.cos(segment / 2) /
            math.cos(angle - segment * (angle / segment).round());
      }
      final point = Offset(20 + radius * c, 20 + radius * s);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    // SVG's default xMidYMid meet preserves its 40x44 viewBox in a square.
    final scale = math.min(size.width / 40, size.height / 44);
    canvas.translate(
      (size.width - 40 * scale) / 2,
      (size.height - 44 * scale) / 2,
    );
    canvas.scale(scale);
    canvas.drawPath(_outline(), Paint()..color = color);
    final dark =
        color.r * 255 * .2126 + color.g * 255 * .7152 + color.b * 255 * .0722 <
        110;
    final eyes = Paint()
      ..color = dark ? const Color(0xf2e8dcc3) : const Color(0xd9000000);
    final highlight = Paint()
      ..color = dark ? const Color(0x99000000) : const Color(0xd9ffffff);
    final eyeY = shape == 'cloud' ? 22.0 : 17.2;
    for (final x in [15.4, 24.6]) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, eyeY), width: 4.4, height: 4.6),
        eyes,
      );
      canvas.drawCircle(Offset(x - .6, eyeY - .7), .65, highlight);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ProfileFacePainter oldDelegate) =>
      shape != oldDelegate.shape || color != oldDelegate.color;
}
