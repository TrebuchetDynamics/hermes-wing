import 'package:flutter_test/flutter_test.dart';

import 'support/plan_backlog_contract.dart';

void main() {
  const open = '- [ ] **TASK-ONE** — [Plan](docs/plans/example.md)\n';
  const done = '- [x] **TASK-ONE** — [Plan](docs/plans/example.md)\n';

  for (final status in ['open', 'in_progress']) {
    test('$status requires an unchecked live body', () {
      expect(
        planTaskBody(id: 'TASK-ONE', status: status, todo: open, archive: ''),
        open,
      );
      for (final sources in [
        (todo: '', archive: open),
        (todo: '', archive: done),
        (todo: done, archive: ''),
      ]) {
        expect(
          () => planTaskBody(
            id: 'TASK-ONE',
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
            id: 'TASK-ONE',
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
      (todo: '- [x] **TASK-ONE-OTHER** — Other task\n', archive: ''),
      (todo: done, archive: done),
      (todo: '$done$done', archive: ''),
      (todo: '', archive: '$done$done'),
      (todo: open, archive: ''),
      (todo: '', archive: open),
    ]) {
      expect(
        () => planTaskBody(
          id: 'TASK-ONE',
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
      () => planTaskBody(
        id: 'TASK-ONE',
        status: 'unknown',
        todo: '',
        archive: done,
      ),
      throwsFormatException,
    );
  });

  test('plan links cannot leak from adjacent task bodies', () {
    const withoutLink = '- [x] **TASK-ONE** — No plan link\n';
    const neighbor = '- [x] **TASK-TWO** — [Plan](docs/plans/example.md)\n';
    expect(
      planTaskBody(
        id: 'TASK-ONE',
        status: 'done',
        todo: '',
        archive: '$withoutLink$neighbor',
      ),
      withoutLink,
    );
  });
}
