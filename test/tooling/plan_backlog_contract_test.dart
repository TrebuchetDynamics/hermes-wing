import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/plan_backlog_contract.dart';

void main() {
  group('native task records', () {
    late Directory root;
    late File record;
    setUp(() {
      root = Directory.systemTemp.createTempSync('wing-plan-records-');
      final items = Directory('${root.path}/tasks/items')
        ..createSync(recursive: true);
      record = File('${items.path}/DEV-001-c7.md');
    });
    tearDown(() => root.deleteSync(recursive: true));

    test('reads TOML headers and keeps this task body separate', () {
      record.writeAsStringSync(
        "+++\nid = 'DEV-001-c7'\nstatus = 'open'\n+++\n- Sources: [Plan](../../docs/plans/example.md)\n",
      );
      final tasks = readPlanTaskRecords(root);
      expect(tasks.keys, ['DEV-001-c7']);
      expect(tasks['DEV-001-c7']!['status'], 'open');
      expect(
        tasks['DEV-001-c7']!['body'],
        contains('[Plan](../../docs/plans/example.md)'),
      );
    });

    test('malformed records and filename identity mismatch fail closed', () {
      for (final text in [
        "+++\nid = 'OTHER'\nstatus = 'open'\n+++\n",
        "+++\nid = [\n+++\n",
        "+++\nid = 'DEV-001-c7'\nstatus = 'unknown'\n+++\n",
        "id = 'DEV-001-c7'\n",
      ]) {
        record.writeAsStringSync(text);
        expect(() => readPlanTaskRecords(root), throwsFormatException);
      }
    });
  });

  for (final id in ['TASK-ONE', 'DEV-001-c7']) {
    group(id, () {
      final open = '- [ ] **$id** — [Plan](docs/plans/example.md)\n';
      final done = '- [x] **$id** — [Plan](docs/plans/example.md)\n';

      for (final status in ['open', 'in_progress']) {
        test('$status requires an unchecked live body', () {
          expect(
            planTaskBody(id: id, status: status, todo: open, archive: ''),
            open,
          );
          for (final sources in [
            (todo: '', archive: open),
            (todo: '', archive: done),
            (todo: done, archive: ''),
          ]) {
            expect(
              () => planTaskBody(
                id: id,
                status: status,
                todo: sources.todo,
                archive: sources.archive,
              ),
              throwsFormatException,
            );
          }
        });
      }

      test('done accepts one checked live or archived body', () {
        for (final checked in [done, done.replaceFirst('[x]', '[X]')]) {
          for (final sources in [
            (todo: checked, archive: ''),
            (todo: '', archive: checked),
          ]) {
            expect(
              planTaskBody(
                id: id,
                status: 'done',
                todo: sources.todo,
                archive: sources.archive,
              ),
              checked,
            );
          }
        }
      });

      test('absent, duplicate and unchecked done bodies fail closed', () {
        for (final sources in [
          (todo: '', archive: ''),
          (todo: '- [x] **$id-OTHER** — Other task\n', archive: ''),
          (todo: done, archive: done),
          (todo: '$done$done', archive: ''),
          (todo: '', archive: '$done$done'),
          (todo: open, archive: ''),
          (todo: '', archive: open),
        ]) {
          expect(
            () => planTaskBody(
              id: id,
              status: 'done',
              todo: sources.todo,
              archive: sources.archive,
            ),
            throwsFormatException,
          );
        }
      });

      test('unsupported ledger states cannot authorize an archived body', () {
        expect(
          () =>
              planTaskBody(id: id, status: 'unknown', todo: '', archive: done),
          throwsFormatException,
        );
      });

      test('plan links cannot leak from adjacent task bodies', () {
        final withoutLink = '- [x] **$id** — No plan link\n';
        final neighborId = id == 'TASK-ONE' ? 'DEV-001-c7' : '$id-OTHER';
        final neighbor =
            '- [x] **$neighborId** — [Plan](docs/plans/example.md)\n';
        expect(
          planTaskBody(
            id: id,
            status: 'done',
            todo: '',
            archive: '$withoutLink$neighbor',
          ),
          withoutLink,
        );
      });
    });
  }
}
