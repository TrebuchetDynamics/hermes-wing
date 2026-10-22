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
          (todo: '- Sources: [Plan](docs/plans/example.md)\n', archive: ''),
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

  test(
    'native closures require a done record body without checkbox conflicts',
    () {
      for (final id in ['TASK-ONE', 'DEV-001-c7']) {
        const body = '- Sources: [Plan](docs/plans/example.md)\n';
        final checkbox = '- [x] **$id** — Archived task\n';
        final neighbor = '- [x] **$id-OTHER** — Neighbor task\n';
        for (final closure in ['manual', 'coordinator_verified']) {
          expect(
            planTaskBody(
              id: id,
              status: 'done',
              todo: body,
              archive: neighbor,
              closure: closure,
            ),
            body,
          );
          for (final invalid in [
            (status: 'open', todo: body, archive: ''),
            (status: 'unknown', todo: body, archive: ''),
            (status: 'done', todo: '  \n', archive: ''),
            (status: 'done', todo: body, archive: checkbox),
            (status: 'done', todo: checkbox, archive: ''),
            (status: 'done', todo: '$checkbox$checkbox', archive: ''),
          ]) {
            expect(
              () => planTaskBody(
                id: id,
                status: invalid.status,
                todo: invalid.todo,
                archive: invalid.archive,
                closure: closure,
              ),
              throwsFormatException,
            );
          }
        }
      }
    },
  );

  test(
    'unsupported closure provenance cannot use record or archive bodies',
    () {
      for (final closure in ['', 'verified', 'coordinator_verified_extra']) {
        for (final archive in ['', '- [x] **TASK-ONE** — Archived task\n']) {
          expect(
            () => planTaskBody(
              id: 'TASK-ONE',
              status: 'done',
              todo: '- Sources: [Plan](docs/plans/example.md)\n',
              archive: archive,
              closure: closure,
            ),
            throwsFormatException,
          );
        }
      }
    },
  );

  test('primary plan backlinks must be direct and in the selected body', () {
    const path = 'docs/plans/example.md';
    for (final closure in ['manual', 'coordinator_verified']) {
      for (final body in ['- Sources: Other plan\n', '[Plan]($path#section)']) {
        final selected = planTaskBody(
          id: 'DEV-001-c7',
          status: 'done',
          todo: body,
          archive: '- [x] **DEV-001-c7-OTHER** — [Plan]($path)\n',
          closure: closure,
        );
        expect(
          () => requirePrimaryPlanBacklink(selected, path),
          throwsFormatException,
        );
      }
    }
    for (final body in ['[Plan]($path)', '[Plan](../../$path)']) {
      expect(() => requirePrimaryPlanBacklink(body, path), returnsNormally);
    }
  });
}
