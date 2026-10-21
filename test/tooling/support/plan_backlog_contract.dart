import 'dart:convert';
import 'dart:io';

Map<String, dynamic> readPlanTaskRecords(Directory root) {
  // Use Python's TOML parser rather than a partial second task-store parser.
  final result = Process.runSync('python3', [
    '-c',
    r'''
import json
from pathlib import Path
import tomllib

items = Path('tasks/items')
if not items.is_dir():
    raise ValueError('Missing canonical task store')
records = {}
for path in sorted(items.glob('*.md')):
    parts = path.read_text().split('+++', 2)
    if len(parts) != 3 or parts[0]:
        raise ValueError(f'{path}: missing TOML frontmatter')
    header = tomllib.loads(parts[1])
    if header['id'] != path.stem:
        raise ValueError(f'{path}: task identity mismatch')
    if header.get('status') not in ('open', 'done', 'superseded'):
        raise ValueError(f'{path}: unsupported task status')
    records[header['id']] = {**header, 'body': parts[2]}
print(json.dumps(records))
''',
  ], workingDirectory: root.path);
  if (result.exitCode != 0) {
    throw FormatException('Cannot read task records: ${result.stderr}');
  }
  return jsonDecode(result.stdout as String) as Map<String, dynamic>;
}

String planTaskBody({
  required String id,
  required String status,
  required String todo,
  required String archive,
}) {
  final bodies = <({bool archived, bool checked, String text})>[];
  final marker = RegExp(
    r'^- \[([ xX])\] \*\*([A-Za-z0-9][A-Za-z0-9_-]*)\*\*',
    multiLine: true,
  );
  for (final source in [
    (text: todo, archived: false),
    (text: archive, archived: true),
  ]) {
    final markers = marker.allMatches(source.text).toList();
    for (var i = 0; i < markers.length; i++) {
      if (markers[i].group(2) != id) continue;
      bodies.add((
        archived: source.archived,
        checked: markers[i].group(1) != ' ',
        text: source.text.substring(
          markers[i].start,
          i + 1 < markers.length ? markers[i + 1].start : source.text.length,
        ),
      ));
    }
  }
  if (bodies.length != 1) {
    throw FormatException(
      '$id needs exactly one task body; found ${bodies.length}',
    );
  }
  final body = bodies.single;
  if (!['open', 'in_progress', 'done'].contains(status) ||
      body.checked != (status == 'done') ||
      (body.archived && status != 'done')) {
    throw FormatException('$id body location/checkbox disagrees with $status');
  }
  return body.text;
}
