import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('native PCM read failure emits its owned error before release', () {
    final source = File(
      'android/app/src/main/kotlin/com/trebuchetdynamics/hermes/wing/voice/'
      'WingVoiceEnginePlugin.kt',
    ).readAsStringSync();
    final readLoop = _between(
      source,
      'private fun readLoop',
      'private fun postError',
    );
    final terminal = _between(
      source,
      'private fun postError',
      'private fun owns(',
    );

    expect(readLoop, contains('postErrorAndRelease(generation, record'));
    expect(terminal, contains('if (owns(generation, record))'));
    expect(terminal, contains('eventSink?.error'));
    expect(terminal, contains('invalidateAndRelease(generation, record)'));
    expect(
      terminal.indexOf('eventSink?.error'),
      lessThan(terminal.indexOf('invalidateAndRelease(generation, record)')),
    );
  });

  test('playback stop waits for queued writes before releasing ownership', () {
    final source = File(
      'android/app/src/main/kotlin/com/trebuchetdynamics/hermes/wing/voice/'
      'WingVoiceEnginePlugin.kt',
    ).readAsStringSync();
    final stop = _between(
      source,
      'private fun stopPlayback',
      'private fun readLoop',
    );
    final scheduledRelease = _between(
      source,
      'private fun schedulePlaybackRelease',
      'private fun stopActivePlayback',
    );

    expect(stop, contains('schedulePlaybackRelease(generation, null)'));
    expect(scheduledRelease, contains('invalidatePlayback'));
    expect(scheduledRelease, contains('playbackExecutor.execute'));
    expect(scheduledRelease, contains('releasePlayback(track)'));
    expect(
      scheduledRelease.indexOf('playbackExecutor.execute'),
      lessThan(scheduledRelease.indexOf('releasePlayback(track)')),
    );
  });
}

String _between(String source, String start, String end) {
  final startIndex = source.indexOf(start);
  final endIndex = source.indexOf(end, startIndex + start.length);
  expect(startIndex, isNonNegative, reason: 'missing $start');
  expect(endIndex, greaterThan(startIndex), reason: 'missing $end');
  return source.substring(startIndex, endIndex);
}
