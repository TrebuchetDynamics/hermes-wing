import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Installation-local appearance only. No Agent profile is assigned or changed.
final wingAvatarVariationProvider = NotifierProvider<WingAvatarVariation, int>(
  WingAvatarVariation.new,
);

class WingAvatarVariation extends Notifier<int> {
  static const preferenceKey = 'wing.appearance.avatar_variation.v1';
  int _generation = 0;

  @override
  int build() {
    _load();
    return 0;
  }

  Future<void> _load() async {
    final generation = _generation;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!ref.mounted || generation != _generation) return;
      state = (prefs.getInt(preferenceKey) ?? 0).clamp(0, 11);
    } catch (_) {
      // The deterministic default remains available without storage.
    }
  }

  Future<bool> select(int variation) async {
    if (variation < 0 || variation > 11) return false;
    _generation++;
    state = variation;
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setInt(preferenceKey, variation);
    } catch (_) {
      return false;
    }
  }
}

/// Stable across Dart VM/web. Length-framed JSON preserves exact identity parts.
List<int> wingAvatarRecipe(List<String> identity, int variation) => sha256
    .convert(utf8.encode(jsonEncode(['wing-avatar-v1', identity, variation])))
    .bytes;

/// Decorative artwork; callers retain the actual profile name and semantics.
class WingAvatar extends ConsumerWidget {
  const WingAvatar({
    required this.identity,
    this.size = 36,
    this.variation,
    super.key,
  });

  final List<String> identity;
  final double size;
  final int? variation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = variation ?? ref.watch(wingAvatarVariationProvider) ?? 0;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: WingAvatarPainter(wingAvatarRecipe(identity, selected)),
        ),
      ),
    );
  }
}

/// A small winged creature, assembled from a versioned deterministic recipe.
class WingAvatarPainter extends CustomPainter {
  const WingAvatarPainter(this.recipe);
  final List<int> recipe;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    final hue = recipe[0] * 360 / 256;
    final background = HSLColor.fromAHSL(1, hue, .55, .9).toColor();
    final body = HSLColor.fromAHSL(1, hue, .48, .38).toColor();
    final ink = Paint()..color = const Color(0xff17212b);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, 100, 100),
        const Radius.circular(30),
      ),
      Paint()..color = background,
    );
    final wings = Paint()
      ..color = HSLColor.fromAHSL(1, (hue + 35) % 360, .5, .65).toColor();
    canvas.drawOval(const Rect.fromLTWH(8, 37, 32, 38), wings);
    canvas.drawOval(const Rect.fromLTWH(60, 37, 32, 38), wings);
    final top = 21.0 + recipe[1] % 8;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(25, top, 75, 82),
        Radius.circular(18.0 + recipe[2] % 9),
      ),
      Paint()..color = body,
    );
    final eyes = Paint()..color = Colors.white;
    final eyeY = 44.0 + recipe[3] % 6;
    canvas.drawCircle(Offset(40, eyeY), 7, eyes);
    canvas.drawCircle(Offset(60, eyeY), 7, eyes);
    final look = (recipe[4] % 5 - 2).toDouble();
    canvas.drawCircle(Offset(40 + look, eyeY), 3, ink);
    canvas.drawCircle(Offset(60 + look, eyeY), 3, ink);
    ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(const Rect.fromLTWH(43, 58, 14, 10), 0, 3.14, false, ink);
    final crest = Path()
      ..moveTo(43, top + 2)
      ..lineTo(50, top - 10)
      ..lineTo(57, top + 2)
      ..close();
    canvas.drawPath(crest, wings);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant WingAvatarPainter oldDelegate) =>
      oldDelegate.recipe.toString() != recipe.toString();
}
