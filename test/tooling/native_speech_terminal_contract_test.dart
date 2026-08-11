import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'native stop and cancel acknowledge without fabricating terminal status',
    () {
      final source = File(
        'third_party/speech_to_text/android/src/main/kotlin/'
        'com/csdcorp/speech_to_text/SpeechToTextPlugin.kt',
      ).readAsStringSync();
      final stop = _between(
        source,
        'private fun stopListening',
        'private fun cancelListening',
      );
      final cancel = _between(
        source,
        'private fun cancelListening',
        'private fun locales',
      );

      expect(stop, contains('if (!recognizerStops'));
      expect(stop, contains('destroyRecognizer()'));
      expect(cancel, contains('if (!recognizerStops'));
      expect(cancel, contains('destroyRecognizer()'));
      expect(
        RegExp(r'notifyListening\(isRecording = false\)').allMatches(stop),
        hasLength(1),
      );
      expect(
        RegExp(r'notifyListening\(isRecording = false\)').allMatches(cancel),
        hasLength(1),
      );
    },
  );

  test('only native result or error callbacks publish terminal status', () {
    final source = File(
      'third_party/speech_to_text/android/src/main/kotlin/'
      'com/csdcorp/speech_to_text/SpeechToTextPlugin.kt',
    ).readAsStringSync();
    final results = _between(
      source,
      'private fun updateResults',
      'private fun isDuplicateFinal',
    );
    final end = _between(
      source,
      'override fun onEndOfSpeech',
      'override fun onError',
    );

    expect(results, contains('if (isFinal && isListening())'));
    expect(results, contains('notifyListening(isRecording = false)'));
    expect(end, isNot(contains('notifyListening')));
  });
}

String _between(String source, String start, String end) {
  final startIndex = source.indexOf(start);
  final endIndex = source.indexOf(end, startIndex + start.length);
  expect(startIndex, isNonNegative, reason: 'missing $start');
  expect(endIndex, greaterThan(startIndex), reason: 'missing $end');
  return source.substring(startIndex, endIndex);
}
