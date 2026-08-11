import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const scriptPath = 'scripts/check_evidence_matrix.dart';

  Future<ProcessResult> runChecker([List<String> arguments = const []]) {
    expect(File(scriptPath).existsSync(), isTrue, reason: 'checker is missing');
    final flutterRoot = Platform.environment['FLUTTER_ROOT'];
    final dart = flutterRoot == null ? 'dart' : '$flutterRoot/bin/dart';
    return Process.run(dart, ['run', scriptPath, ...arguments]);
  }

  test('repository evidence matrix is complete and current', () async {
    final result = await runChecker();

    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(result.stdout, contains('evidence_matrix=PASS'));
  });

  test('checker rejects a stale qualified receipt', () async {
    final temp = await Directory.systemTemp.createTemp('wing-evidence-stale-');
    addTearDown(() => temp.delete(recursive: true));
    final matrix = File('${temp.path}/matrix.md');
    await matrix.writeAsString('''
# Evidence matrix

| ID | Capability | Classification | Source identity | Artifact or receipt identity | Platform | Evidence date UTC | Limitations |
| --- | --- | --- | --- | --- | --- | --- | --- |
| chat | Chat | qualified | abc123 | receipt-1 | Android | 2026-01-01 | One device only |
''');

    final result = await runChecker([
      '--matrix',
      matrix.path,
      '--now',
      '2026-08-09T00:00:00Z',
      '--max-age-days',
      '90',
    ]);

    expect(result.exitCode, isNot(0));
    expect('${result.stdout}${result.stderr}', contains('stale receipt'));
    expect('${result.stdout}${result.stderr}', contains('chat'));
  });

  test(
    'checker permits explicitly unverified evidence without a receipt',
    () async {
      final temp = await Directory.systemTemp.createTemp('wing-evidence-open-');
      addTearDown(() => temp.delete(recursive: true));
      final matrix = File('${temp.path}/matrix.md');
      await matrix.writeAsString('''
# Evidence matrix

| ID | Capability | Classification | Source identity | Artifact or receipt identity | Platform | Evidence date UTC | Limitations |
| --- | --- | --- | --- | --- | --- | --- | --- |
| acoustic | Acoustic AEC | unverified | worktree | none | physical Android | 2026-08-09 | No physical acoustic receipt |
''');

      final result = await runChecker([
        '--matrix',
        matrix.path,
        '--now',
        '2026-08-09T00:00:00Z',
        '--max-age-days',
        '90',
      ]);

      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    },
  );
}
