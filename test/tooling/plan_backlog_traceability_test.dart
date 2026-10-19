import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/plan_backlog_contract.dart';

void main() {
  test('every retained plan has an explicit canonical backlog disposition', () {
    final plans = [Directory('docs/plans'), Directory('docs/superpowers/plans')]
        .expand((directory) => directory.listSync())
        .whereType<File>()
        .where((file) => file.path.endsWith('.md'))
        .map((file) => file.path)
        .toSet();
    final index = File('docs/plans/README.md').readAsStringSync();
    final map = RegExp(
      r'<!-- plan-task-map:start -->([\s\S]*?)<!-- plan-task-map:end -->',
    ).firstMatch(index);
    expect(map, isNotNull, reason: 'Plans need one explicit backlog mapping.');
    if (map == null) return;
    final ledger =
        jsonDecode(File('goals.json').readAsStringSync())
            as Map<String, dynamic>;
    final tasks = {
      for (final task in ledger['tasks'] as List)
        (task as Map<String, dynamic>)['id'] as String: task,
    };
    final todo = File('TODO.md').readAsStringSync();
    final archive = File('todo.archive.md').readAsStringSync();
    final entries = <String>{};
    for (final line in map.group(1)!.split('\n')) {
      if (!line.startsWith('| `docs/')) continue;
      final fields = line.split('|').map((field) => field.trim()).toList();
      expect(fields.length, 6, reason: 'Mapping columns must be explicit.');
      final path = fields[1].replaceAll('`', '');
      final disposition = fields[2];
      expect(entries.add(path), isTrue, reason: 'Duplicate plan: $path');
      expect(plans.contains(path), isTrue, reason: 'Unknown plan: $path');
      expect([
        'Current',
        'Historical',
        'Superseded',
        'Proposal',
        'Deferred',
        'Policy',
      ], contains(disposition));
      final ids = RegExp(
        r'`([A-Za-z0-9][A-Za-z0-9_-]*)`',
      ).allMatches(fields[3]).map((match) => match.group(1)!).toList();
      if (disposition == 'Current') {
        expect(ids, isNotEmpty, reason: 'Current plan has no tasks: $path');
      }
      final bodies = <String, String>{};
      for (final id in ids) {
        expect(
          tasks.containsKey(id),
          isTrue,
          reason: '$path names unknown $id',
        );
        bodies[id] = planTaskBody(
          id: id,
          status: tasks[id]!['status'] as String,
          todo: todo,
          archive: archive,
        );
      }
      if (ids.isNotEmpty && disposition != 'Policy') {
        expect(
          bodies[ids.first],
          contains(']($path)'),
          reason: '$path needs a direct link from its primary task body.',
        );
      }
      if (disposition == 'Deferred') {
        expect(ids, isEmpty, reason: 'Deferred work is not executable: $path');
      }
      expect(fields[4], isNotEmpty, reason: 'State needs a reason: $path');
      if (path != 'docs/plans/README.md') {
        final content = File(path).readAsStringSync();
        expect(content, contains('## Backlog connection'), reason: path);
        expect(content, contains('TODO.md'), reason: path);
        expect(content, contains('#plan-to-task-coverage'), reason: path);
      }
    }
    expect(entries, unorderedEquals(plans));
  });
}
