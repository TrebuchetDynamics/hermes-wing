import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/models/hermes_runtime_model.dart';
import 'package:wing/core/hermes/models/hermes_skill.dart';
import 'package:wing/core/hermes/models/hermes_toolset.dart';

void main() {
  final readName = <String, String Function(String)>{
    'runtime model': (value) => HermesRuntimeModel.fromJson({'id': value}).id,
    'skill': (value) => HermesSkill.fromJson({'name': value}).name,
    'toolset': (value) => HermesToolset.fromJson({'name': value}).name,
  };
  for (final entry in readName.entries) {
    test('${entry.key} normalizes and bounds display metadata', () {
      expect(entry.value('  First\n\tSecond\u0000  '), 'First Second');
      expect(entry.value('x' * 120), 'x' * 120);
      expect(entry.value('x' * 121), '${'x' * 119}…');
    });
  }

  test('each metadata field retains its own length limit', () {
    final text = 'x' * 1001;
    final model = HermesRuntimeModel.fromJson({'root': text, 'parent': text});
    final skill = HermesSkill.fromJson({'description': text, 'category': text});
    final toolset = HermesToolset.fromJson({
      'label': text,
      'description': text,
      'tools': [text],
    });
    expect(model.root, '${'x' * 119}…');
    expect(model.parent, '${'x' * 119}…');
    expect(skill.description, '${'x' * 999}…');
    expect(skill.category, '${'x' * 79}…');
    expect(toolset.label, '${'x' * 159}…');
    expect(toolset.description, '${'x' * 999}…');
    expect(toolset.tools.single, '${'x' * 119}…');
  });
}
