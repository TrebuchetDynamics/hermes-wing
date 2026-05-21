import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

enum VoiceMorphState { idle, listening, thinking, speaking, disabled }

@immutable
class VoiceMorphStyle {
  const VoiceMorphStyle({
    required this.label,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.cycleDuration,
    required this.breath,
    required this.rotation,
  });

  final String label;
  final Color primary;
  final Color secondary;
  final Color accent;
  final Duration cycleDuration;
  final double breath;
  final double rotation;

  static VoiceMorphStyle forState(VoiceMorphState state) {
    return switch (state) {
      VoiceMorphState.idle => const VoiceMorphStyle(
        label: 'Voice mode idle',
        primary: Color(0xff6da6ff),
        secondary: Color(0xff80e7cf),
        accent: Color(0xffffc978),
        cycleDuration: Duration(milliseconds: 4600),
        breath: 0.20,
        rotation: 0.35,
      ),
      VoiceMorphState.listening => const VoiceMorphStyle(
        label: 'Listening',
        primary: Color(0xff55d6be),
        secondary: Color(0xff73a7ff),
        accent: Color(0xffffde77),
        cycleDuration: Duration(milliseconds: 2600),
        breath: 0.34,
        rotation: 0.55,
      ),
      VoiceMorphState.thinking => const VoiceMorphStyle(
        label: 'Thinking',
        primary: Color(0xff8894ff),
        secondary: Color(0xff63d7e6),
        accent: Color(0xffff8fa3),
        cycleDuration: Duration(milliseconds: 5400),
        breath: 0.18,
        rotation: -0.32,
      ),
      VoiceMorphState.speaking => const VoiceMorphStyle(
        label: 'Speaking',
        primary: Color(0xffff9770),
        secondary: Color(0xffffd166),
        accent: Color(0xff65d6c3),
        cycleDuration: Duration(milliseconds: 1800),
        breath: 0.42,
        rotation: 0.82,
      ),
      VoiceMorphState.disabled => const VoiceMorphStyle(
        label: 'Voice mode unavailable',
        primary: Color(0xff87909a),
        secondary: Color(0xffb4bbc2),
        accent: Color(0xffd2d6da),
        cycleDuration: Duration(milliseconds: 6000),
        breath: 0.04,
        rotation: 0,
      ),
    };
  }
}

class VoiceMorphSurface extends StatefulWidget {
  const VoiceMorphSurface({
    required this.state,
    this.intensity = 0,
    this.reducedMotion = false,
    this.size = 224,
    super.key,
  });

  final VoiceMorphState state;
  final double intensity;
  final bool reducedMotion;
  final double size;

  @override
  State<VoiceMorphSurface> createState() => _VoiceMorphSurfaceState();
}

class _VoiceMorphSurfaceState extends State<VoiceMorphSurface>
    with SingleTickerProviderStateMixin {
  late final AnimationController _phaseController;

  @override
  void initState() {
    super.initState();
    _phaseController = AnimationController(vsync: this);
    _configureController();
  }

  @override
  void didUpdateWidget(VoiceMorphSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state ||
        oldWidget.reducedMotion != widget.reducedMotion) {
      _configureController();
    }
  }

  @override
  void dispose() {
    _phaseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = VoiceMorphStyle.forState(widget.state);
    final intensity = widget.intensity.clamp(0.0, 1.0);
    final mediaReducedMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final freezePhase =
        widget.reducedMotion ||
        mediaReducedMotion ||
        widget.state == VoiceMorphState.disabled;

    return Semantics(
      container: true,
      label: style.label,
      liveRegion: true,
      child: RepaintBoundary(
        child: SizedBox.square(
          dimension: widget.size,
          child: AnimatedBuilder(
            animation: _phaseController,
            builder: (context, _) {
              return CustomPaint(
                painter: VoiceMorphPainter(
                  style: style,
                  intensity: intensity,
                  phase: freezePhase ? 0 : _phaseController.value,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _configureController() {
    final style = VoiceMorphStyle.forState(widget.state);
    _phaseController.duration = style.cycleDuration;
    if (widget.reducedMotion || widget.state == VoiceMorphState.disabled) {
      _phaseController
        ..stop()
        ..value = 0;
      return;
    }
    if (!_phaseController.isAnimating) {
      _phaseController.repeat();
    }
  }
}

@visibleForTesting
class VoiceMorphPainter extends CustomPainter {
  const VoiceMorphPainter({
    required this.style,
    required this.intensity,
    required this.phase,
  });

  final VoiceMorphStyle style;
  final double intensity;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final shortest = math.min(size.width, size.height);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = shortest / 2;
    final wave = math.sin(phase * math.pi * 2);
    final breath = 1 + (style.breath * (0.45 + intensity) * wave * 0.10);

    _drawRadialGlow(
      canvas,
      center,
      radius * 0.88 * breath,
      style.secondary.withValues(alpha: 0.22),
    );
    _drawBlobs(canvas, center, radius, breath);
    _drawSoftRing(canvas, center, radius);
    _drawCore(canvas, center, radius, breath);
  }

  void _drawBlobs(Canvas canvas, Offset center, double radius, double breath) {
    const count = 5;
    for (var i = 0; i < count; i++) {
      final turn = phase * math.pi * 2 * style.rotation;
      final angle = turn + (i * math.pi * 2 / count);
      final localWave = math.sin(turn + i * 1.37);
      final distance = radius * (0.12 + style.breath * 0.10 + intensity * 0.08);
      final offset = center.translate(
        math.cos(angle) * distance * (1 + localWave * 0.10),
        math.sin(angle) * distance * (1 - localWave * 0.08),
      );
      final blobRadius =
          radius * (0.34 + intensity * 0.10 + localWave.abs() * 0.035) * breath;
      final color = switch (i % 3) {
        0 => style.primary,
        1 => style.secondary,
        _ => style.accent,
      };
      _drawRadialGlow(
        canvas,
        offset,
        blobRadius,
        color.withValues(alpha: 0.42),
      );
    }
  }

  void _drawSoftRing(Canvas canvas, Offset center, double radius) {
    final ringPaint = Paint()
      ..color = style.primary.withValues(alpha: 0.25 + intensity * 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * (0.035 + intensity * 0.020)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawCircle(center, radius * (0.62 + style.breath * 0.10), ringPaint);
  }

  void _drawCore(Canvas canvas, Offset center, double radius, double breath) {
    final coreRadius = radius * (0.32 + intensity * 0.08) * breath;
    final paint = Paint()
      ..shader = ui.Gradient.radial(
        center,
        coreRadius,
        [
          style.accent.withValues(alpha: 0.70),
          style.primary.withValues(alpha: 0.36),
          style.secondary.withValues(alpha: 0.04),
        ],
        const [0, 0.58, 1],
      )
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
    canvas.drawCircle(center, coreRadius, paint);
  }

  void _drawRadialGlow(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
  ) {
    final paint = Paint()
      ..shader = ui.Gradient.radial(center, radius, [
        color,
        color.withValues(alpha: 0),
      ])
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant VoiceMorphPainter oldDelegate) {
    return oldDelegate.style != style ||
        oldDelegate.intensity != intensity ||
        oldDelegate.phase != phase;
  }
}
