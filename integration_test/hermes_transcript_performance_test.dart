import 'dart:convert';
import 'dart:io';
import 'dart:ui' show FrameTiming;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:wing/features/hermes_chat/presentation/hermes_rich_text.dart';
import 'package:wing/l10n/app_localizations.dart';

// Native-only benchmark: RSS belongs to this process, never browser estimates.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const selectedCase = String.fromEnvironment('TRANSCRIPT_CASE');
  const selectedBytes = int.fromEnvironment('TRANSCRIPT_BYTES');
  final receipts = <Map<String, Object?>>[];
  for (final bytes in [100000, 1000000]) {
    if (selectedBytes != 0 && selectedBytes != bytes) continue;
    for (final kind in ['paragraphs', 'code', 'line', 'table', 'unclosed']) {
      if (selectedCase.isNotEmpty && selectedCase != kind) continue;
      testWidgets(
        '$kind $bytes bytes native transcript benchmark',
        (tester) async {
          final data = _syntheticTranscript(kind, bytes);
          expect(utf8.encode(data).length, bytes);
          final durations = <int>[];
          final frameBuild = <int>[];
          final frameRaster = <int>[];
          final memory = <int>[];
          final frames = <FrameTiming>[];
          void collect(List<FrameTiming> values) => frames.addAll(values);
          binding.addTimingsCallback(collect);
          addTearDown(() => binding.removeTimingsCallback(collect));
          final scroll = ScrollController();
          addTearDown(scroll.dispose);
          final live = ValueNotifier(data);
          addTearDown(live.dispose);
          Widget app() => MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SingleChildScrollView(
                controller: scroll,
                child: ValueListenableBuilder<String>(
                  valueListenable: live,
                  builder: (_, text, _) => HermesRichText(text),
                ),
              ),
            ),
          );
          for (var repetition = 0; repetition < 12; repetition++) {
            final elapsed = Stopwatch()..start();
            await tester.pumpWidget(app());
            await tester.pumpAndSettle();
            elapsed.stop();
            if (repetition >= 2) durations.add(elapsed.elapsedMicroseconds);
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pumpAndSettle();
            if (repetition >= 2) memory.add(ProcessInfo.currentRss);
          }
          await tester.pumpWidget(app());
          await tester.pumpAndSettle();
          final updateDurations = <int>[];
          // 20 Hz target; measured work may exceed that cadence on slow cases.
          for (var update = 0; update < 20; update++) {
            final elapsed = Stopwatch()..start();
            live.value = '${live.value}${'x' * 1024}';
            if (scroll.hasClients) {
              scroll.jumpTo(
                update.isEven ? scroll.position.maxScrollExtent : 0,
              );
            }
            await tester.pump(const Duration(milliseconds: 50));
            elapsed.stop();
            updateDurations.add(elapsed.elapsedMicroseconds);
          }
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
          for (final frame in frames) {
            frameBuild.add(frame.buildDuration.inMicroseconds);
            frameRaster.add(frame.rasterDuration.inMicroseconds);
          }
          final receipt = <String, Object?>{
            'case': kind,
            'bytes': bytes,
            'mode': kReleaseMode
                ? 'release'
                : kProfileMode
                ? 'profile'
                : 'debug-not-qualification',
            'platform': Platform.operatingSystem,
            'source': const String.fromEnvironment(
              'BENCHMARK_SOURCE',
              defaultValue: 'unrecorded',
            ),
            'warmups': 2,
            'repetitions': durations.length,
            'mount_us': durations,
            'mount_p50_us': _percentile(durations, .50),
            'mount_p95_us': _percentile(durations, .95),
            'frame_count': frames.length,
            'frame_build_p95_us': _percentile(frameBuild, .95),
            'frame_raster_p95_us': _percentile(frameRaster, .95),
            'stream_update_including_50ms_pump_us': updateDurations,
            'closed_rss_bytes': memory,
            'max_rss_bytes': ProcessInfo.maxRss,
          };
          receipts.add(receipt);
          binding.reportData = {'transcript_performance': receipts};
          debugPrint('TRANSCRIPT_PERFORMANCE ${jsonEncode(receipt)}');
        },
        timeout: const Timeout(Duration(minutes: 10)),
      );
    }
  }
}

int? _percentile(List<int> values, double fraction) {
  if (values.isEmpty) return null;
  final sorted = [...values]..sort();
  return sorted[((sorted.length - 1) * fraction).ceil()];
}

String _syntheticTranscript(String kind, int bytes) {
  final unit = switch (kind) {
    'paragraphs' =>
      'Synthetic bounded benchmark paragraph with **emphasis**.\n\n',
    'code' => '```text\nsynthetic code sample\n```\n\n',
    'line' => 'x',
    'table' =>
      '| A | B | C | D | E | F | G | H |\n|---|---|---|---|---|---|---|---|\n| 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |\n\n',
    'unclosed' => 'unclosed **emphasis and [link plus code `\n',
    _ => throw ArgumentError.value(kind),
  };
  final prefix = kind == 'unclosed' ? '```text\n' : '';
  return '$prefix${unit * ((bytes ~/ unit.length) + 1)}'.substring(0, bytes);
}
