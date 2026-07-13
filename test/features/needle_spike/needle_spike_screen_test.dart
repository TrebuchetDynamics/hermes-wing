import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/needle_spike/providers/needle_spike_providers.dart';
import 'package:navivox/features/needle_spike/screens/needle_spike_screen.dart';
import 'package:navivox/features/needle_spike/services/needle_engine.dart';
import 'package:navivox/features/needle_spike/services/needle_model_install_service.dart';

class _FakeEngine implements NeedleEngineApi {
  bool loaded = false;

  @override
  bool get isLoaded => loaded;

  @override
  Future<void> load(String modelDir) async {
    loaded = true;
  }

  @override
  Future<String> complete({
    required String messagesJson,
    required String toolsJson,
    required String optionsJson,
  }) async {
    return '{"success": true, "response": "", "function_calls": '
        '[{"name": "show_status", "arguments": {}}], "total_time_ms": 42.0}';
  }

  @override
  Future<void> unload() async {}
}

/// Lays down a pre-installed fake model and pumps the screen to ready state.
///
/// Directory.systemTemp.createTemp and the screen's own initState model
/// check both use dart:io's real (isolate-backed) async file APIs, which
/// never resolve inside a bare testWidgets pump cycle — they need the real
/// event loop that tester.runAsync provides, plus a short real-time delay
/// so the pending isolate response is delivered before the next pump().
Future<void> _pumpReadyScreen(WidgetTester tester) async {
  final tempDir = await tester.runAsync(
    () => Directory.systemTemp.createTemp('needle_screen'),
  );
  addTearDown(() => tempDir!.delete(recursive: true));
  final install = NeedleModelInstallService(supportDirectory: tempDir!);
  final modelDir = Directory('${tempDir.path}/needle_spike/model')
    ..createSync(recursive: true);
  File('${modelDir.path}/config.json').writeAsStringSync('{}');
  File(
    '${tempDir.path}/needle_spike/.installed',
  ).writeAsStringSync(modelDir.path);

  await tester.runAsync(() async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          needleEngineProvider.overrideWithValue(_FakeEngine()),
          needleInstallServiceProvider.overrideWith((ref) async => install),
          needleVoiceCaptureFactoryProvider.overrideWithValue(() => null),
        ],
        child: const MaterialApp(home: NeedleSpikeScreen()),
      ),
    );
    // Yield to the real event loop long enough for the pending real IO
    // (installedModelDir's File.exists/readAsString) to be delivered.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await tester.pump();
  });
  await tester.pumpAndSettle();
}

/// The result card and scorecard render below the 20-chip bank, which
/// pushes them out of the default test viewport. ListView only mounts
/// visible slivers, so scroll before locating them.
Future<void> _scrollToBottom(WidgetTester tester) async {
  await tester.drag(find.byType(ListView), const Offset(0, -2000));
  await tester.pumpAndSettle();
}

Future<void> _scrollToTop(WidgetTester tester) async {
  await tester.drag(find.byType(ListView), const Offset(0, 2000));
  await tester.pumpAndSettle();
}

Future<void> _runTranscript(WidgetTester tester, String transcript) async {
  await tester.enterText(
    find.byKey(const Key('needle-transcript-field')),
    transcript,
  );
  await tester.tap(find.byKey(const Key('needle-run-button')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'typed transcript produces a parsed tool call and scorecard tick',
    (tester) async {
      await _pumpReadyScreen(tester);
      await _runTranscript(tester, 'is the agent connected');
      await _scrollToBottom(tester);

      expect(find.textContaining('show_status'), findsOneWidget);
      expect(find.textContaining('wall'), findsOneWidget);

      await tester.tap(find.byKey(const Key('needle-verdict-correct')));
      await tester.pump();
      expect(find.textContaining('correct 1'), findsOneWidget);
    },
  );

  testWidgets('verdict buttons only score a real, unscored, current result', (
    tester,
  ) async {
    await _pumpReadyScreen(tester);
    await _scrollToBottom(tester);

    // Before any run there is no result: the verdict buttons are disabled,
    // so tapping one must not record anything.
    await tester.tap(
      find.byKey(const Key('needle-verdict-correct')),
      warnIfMissed: false,
    );
    await tester.pump();
    expect(find.textContaining('total 0'), findsOneWidget);

    // Produce a result.
    await _scrollToTop(tester);
    await _runTranscript(tester, 'is the agent connected');
    await _scrollToBottom(tester);

    // First tap scores the result; a second tap must not double-count.
    await tester.tap(find.byKey(const Key('needle-verdict-correct')));
    await tester.pump();
    expect(find.textContaining('correct 1'), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('needle-verdict-correct')),
      warnIfMissed: false,
    );
    await tester.pump();
    expect(find.textContaining('correct 1'), findsOneWidget);
    expect(find.textContaining('correct 2'), findsNothing);
  });
}
