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
