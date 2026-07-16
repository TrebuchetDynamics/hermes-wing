import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/needle_spike/data/needle_test_transcripts.dart';
import 'package:wing/features/needle_spike/services/needle_tool_catalog.dart';

void main() {
  test('catalog defines 10 uniquely named function tools', () {
    expect(NeedleToolCatalog.tools, hasLength(10));
    expect(NeedleToolCatalog.toolNames, hasLength(10));
    for (final tool in NeedleToolCatalog.tools) {
      expect(tool['type'], 'function');
      final function = tool['function'] as Map<String, dynamic>;
      expect(function['name'], isNotEmpty);
      expect(function['description'], isNotEmpty);
      final parameters = function['parameters'] as Map<String, dynamic>;
      expect(parameters['type'], 'object');
      expect(parameters, contains('properties'));
    }
  });

  test('toolsJson round-trips as JSON', () {
    final decoded = jsonDecode(NeedleToolCatalog.toolsJson) as List<dynamic>;
    expect(decoded, hasLength(10));
  });

  test('every canned transcript targets a catalog tool, two per tool', () {
    expect(needleTestTranscripts, hasLength(20));
    final counts = <String, int>{};
    for (final t in needleTestTranscripts) {
      expect(NeedleToolCatalog.toolNames, contains(t.expectedTool));
      counts[t.expectedTool] = (counts[t.expectedTool] ?? 0) + 1;
    }
    expect(counts.values.every((c) => c == 2), isTrue);
  });
}
