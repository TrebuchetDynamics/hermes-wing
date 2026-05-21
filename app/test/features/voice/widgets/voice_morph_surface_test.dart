import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/voice/widgets/voice_morph_surface.dart';

void main() {
  testWidgets('exposes live semantics for each voice state', (tester) async {
    final semantics = tester.ensureSemantics();

    for (final state in VoiceMorphState.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: VoiceMorphSurface(state: state, intensity: 0.4)),
        ),
      );

      expect(
        find.bySemanticsLabel(VoiceMorphStyle.forState(state).label),
        findsOneWidget,
      );
    }
    semantics.dispose();
  });

  testWidgets('maps states to distinct visual styles', (tester) async {
    expect(
      VoiceMorphStyle.forState(VoiceMorphState.listening).primary,
      isNot(VoiceMorphStyle.forState(VoiceMorphState.speaking).primary),
    );
    expect(
      VoiceMorphStyle.forState(VoiceMorphState.thinking).cycleDuration,
      isNot(VoiceMorphStyle.forState(VoiceMorphState.listening).cycleDuration),
    );
  });

  testWidgets('clamps intensity before painting', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: VoiceMorphSurface(
            state: VoiceMorphState.speaking,
            intensity: 2.3,
          ),
        ),
      ),
    );

    final painter = tester.widget<CustomPaint>(_voiceCustomPaint()).painter;

    expect(painter, isA<VoiceMorphPainter>());
    expect((painter! as VoiceMorphPainter).intensity, 1);
  });

  testWidgets('reduced motion freezes animation phase but keeps state style', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: VoiceMorphSurface(
            state: VoiceMorphState.listening,
            intensity: 0.8,
            reducedMotion: true,
          ),
        ),
      ),
    );
    final first =
        tester.widget<CustomPaint>(_voiceCustomPaint()).painter!
            as VoiceMorphPainter;

    await tester.pump(const Duration(seconds: 2));
    final second =
        tester.widget<CustomPaint>(_voiceCustomPaint()).painter!
            as VoiceMorphPainter;

    expect(first.phase, 0);
    expect(second.phase, 0);
    expect(
      second.style.label,
      VoiceMorphStyle.forState(VoiceMorphState.listening).label,
    );
  });
}

Finder _voiceCustomPaint() {
  return find.descendant(
    of: find.byType(VoiceMorphSurface),
    matching: find.byType(CustomPaint),
  );
}
