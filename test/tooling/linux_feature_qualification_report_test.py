"""Receipt checker public seams; synthetic evidence is never product qualification."""
import contextlib
import copy
import io
import importlib.util
import json
import os
import re
from pathlib import Path
import sys
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO / 'scripts'))
sys.path.insert(0, str(REPO / 'scripts/support'))


class ReportTest(unittest.TestCase):
    def setUp(self):
        path = REPO / 'scripts/check_linux_feature_qualification.py'
        self.assertTrue(path.is_file(), 'The receipt checker is missing')
        spec = importlib.util.spec_from_file_location('linux_report', path)
        self.qa = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(self.qa)
        tmp = tempfile.TemporaryDirectory(dir=os.environ['TMPDIR'])
        self.addCleanup(tmp.cleanup)
        self.root = Path(tmp.name)
        self.target = 'integration_test/linux_management_feature_qualification_test.dart'
        self.source = {'revision': 'a' * 40, 'inputs': {self.target: 'b' * 64}}
        self.source['tree_sha256'] = self.qa.qa.identity(self.source['inputs'])
        self.case = dict(id='management.example', feature_ids=['HD-PROFILE'], route_ids=['/profiles'],
                         status='pass', backend='synthetic', input='framework', storage='mock',
                         native_pid=124, owner_count=1, operation_counts={'writes': 0})
        self.expected = {'management.example': (['HD-PROFILE'], ['/profiles'])}
        self.write('management-0-feature-cases.json', {'schema': 1, 'cases': [self.case]})
        self.write('logs/management-0.log', 'synthetic native log', raw=True)
        self.receipt = dict(schema=1, lane='management', status='pass', ready=True, errors=[],
                            source=self.source, toolchain={}, executed_inputs_sha256='c' * 64,
                            cleanup=dict(groups_gone=True, state_removed=True, state='state-test'),
                            cases=[self.case | dict(command_index=0,
                                artifact_sha256=self.qa.qa.digest(self.root / 'management-0-feature-cases.json'),
                                log_sha256=self.qa.qa.digest(self.root / 'logs/management-0.log'))],
                            commands=[dict(command=['/bin/bash', '-c', 'exec "$@" 2>&1', 'qualification',
                                '/tools/xvfb-run', '-a', '-s', '-screen 0 1440x1000x24 -nolisten tcp',
                                '/tools/dbus-run-session', '--', str(self.root / 'state-test/flutter/bin/flutter'),
                                'test', '--no-pub', '--concurrency=1', '-d', 'linux', self.target],
                                exit_code=0, status='pass', owned_group_gone=True, driver_pid=123,
                                processes=[dict(native_pid=124, start_ticks='456')],
                                log='logs/management-0.log',
                                log_sha256=self.qa.qa.digest(self.root / 'logs/management-0.log'))],
                            suite_runs=[], runner_receipts=[])
        self.receipt['toolchain'] = {name: {'path': '/tools/' + name} for name in ('xvfb-run', 'dbus-run-session')}
        self.write('campaign.json', dict(schema=1, source=self.source, toolchain=self.receipt['toolchain']))

    def write(self, name, value, raw=False):
        path = self.root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(value if raw else json.dumps(value))

    def check(self, value=None):
        self.write('management.json', self.receipt if value is None else value)
        return self.qa.check_lane('management', self.root, self.source['inputs'], self.expected)

    def test_terminal_cases_bind_exact_inventory_artifacts_and_dispatch(self):
        rows, proof = self.check()
        self.assertEqual([r['id'] for r in rows], ['management.example'])
        self.assertEqual(proof['status'], 'pass')
        mutations = {
            'missing': lambda d: d['cases'].clear(),
            'duplicate': lambda d: d['cases'].append(d['cases'][0]),
            'empty': lambda d: d.update(cases=[]),
            'stale-source': lambda d: d['source']['inputs'].update({self.target: 'd' * 64}),
            'interrupted': lambda d: d['commands'][0].update(exit_code=None),
            'boolean-count': lambda d: d['cases'][0].update(owner_count=True),
            'boolean-operation': lambda d: d['cases'][0].update(operation_counts={'writes': False}),
            'boolean-exit': lambda d: d['commands'][0].update(exit_code=False),
            'skip': lambda d: d['cases'][0].update(status='not_run'),
            'feature': lambda d: d['cases'][0].update(feature_ids=['HD-PROVIDER']),
            'route': lambda d: d['cases'][0].update(route_ids=['/providers']),
            'unknown': lambda d: d['cases'][0].update(id='management.unregistered'),
            'artifact': lambda d: d['cases'][0].update(artifact_sha256='0' * 64),
            'wrapper': lambda d: d['commands'][0].update(command=['/bin/true', self.target]),
            'filtered': lambda d: d['commands'][0]['command'].extend(['--name', 'one']),
            'cleanup': lambda d: d['cleanup'].update(state_removed=False),
            'boolean-schema': lambda d: d.update(schema=True),
            'missing-native': lambda d: d['commands'][0].update(processes=[]),
            'escaping-log': lambda d: d['commands'][0].update(log='../other.log'),
        }
        for label, mutate in mutations.items():
            changed = copy.deepcopy(self.receipt)
            mutate(changed)
            with self.subTest(label=label), self.assertRaises(ValueError):
                self.check(changed)
        (self.root / 'logs/management-0.log').write_text('altered')
        with self.assertRaises(ValueError):
            self.check()

    def test_explained_nonpasses_remain_nonpasses_and_exact_failure_survives(self):
        for status in ('fail', 'not_run', 'unsupported', 'coverage_gap'):
            with self.subTest(status=status):
                value = copy.deepcopy(self.receipt)
                case = value['cases'][0]
                case.update(status=status, skip_reason='Explicit fixture boundary', negative_assertion=True)
                self.write('management-0-feature-cases.json', {'schema': 1, 'cases': [
                    {k: v for k, v in case.items() if k not in ('command_index', 'artifact_sha256', 'log_sha256')}]})
                case['artifact_sha256'] = self.qa.qa.digest(self.root / 'management-0-feature-cases.json')
                value.update(status='fail')
                value['commands'][0].update(status='fail', exit_code=37)
                rows, proof = self.check(value)
                self.assertEqual(rows[0]['status'], status)
                self.assertEqual(proof['commands'][0]['exit_code'], 37)
        value['cases'][0].update(status='unsupported', negative_assertion=False)
        with self.assertRaises(ValueError):
            self.check(value)

    def test_machine_suite_rejects_hidden_skips_and_interruption(self):
        events = [dict(type='testStart', test=dict(id=1, name='test/example_test.dart case')),
                  dict(type='testDone', testID=1, result='success', skipped=False),
                  dict(type='done', success=True)]
        path = self.root / 'suite.log'
        for change in ('none', 'interrupted', 'duplicate', 'skip', 'empty', 'false-terminal'):
            altered = copy.deepcopy(events)
            if change == 'interrupted': altered.pop()
            if change == 'duplicate': altered.insert(1, altered[0])
            if change == 'skip': altered[1]['skipped'] = True
            if change == 'empty': altered[1]['hidden'] = True
            if change == 'false-terminal': altered[2]['success'] = False
            path.write_text('\n'.join(json.dumps(e) for e in altered))
            if change == 'none':
                self.assertEqual(len(self.qa.read_suite(path)), 1)
            else:
                with self.subTest(change=change), self.assertRaises(ValueError):
                    self.qa.read_suite(path)

        hidden = [events[0], events[1], dict(type='testStart', test=dict(id=2, name='framework teardown')),
                  dict(type='testDone', testID=2, result='failure', skipped=False, hidden=True),
                  dict(type='done', success=False)]
        path.write_text('\n'.join(json.dumps(e) for e in hidden))
        self.assertEqual([r['result'] for r in self.qa.read_suite(path)], ['success', 'failure'])

    def test_shared_join_binds_the_exact_batch_and_validates_native_identity(self):
        adapter = REPO / 'integration_test/linux_feature_regression_test.dart'
        selected = re.findall(r"import\s+'\.\./(test/[^']+_test\.dart)'\s+as", adapter.read_text())
        current = {path: 'b' * 64 for path in selected}
        current['integration_test/linux_feature_regression_test.dart'] = self.qa.qa.digest(adapter)
        value = dict(source=self.source, toolchain=self.receipt['toolchain'], commands=[], suite_runs=[], batches=[])
        logs = []
        for batch in ('core', 'screens', 'delete-timers', 'create-timers'):
            directory = 'shared-' + batch
            target = 'integration_test/linux_feature_regression_test.dart'
            names = [p + ' synthetic case' for p in selected]
            # Different reporter IDs can legitimately share an exception's title.
            names += ['test/features/profiles/profile_editor_sheet_test.dart failed delete needs fresh typed confirmation: ' + str(n // 2) for n in range(3)]
            names += ['test/features/profiles/profile_editor_sheet_test.dart create failure clears credential and never replays: ' + str(n) for n in range(2)]
            selection = self.qa.driver.SHARED_NATIVE_BATCHES[batch]
            native = [n for n in names if re.search(selection, n)]
            groups = [('test/tooling/linux_feature_adapter_inventory_test.dart', ['inventory']), (target, native)] if batch == 'core' else [(target, native)]
            child = dict(schema=1, source=value['source'], toolchain=value['toolchain'], lane='shared', batch=batch,
                         cleanup=dict(groups_gone=True, state_removed=True, state='state-test'), commands=[], suite_runs=[])
            vectors = self.qa.driver.commands('shared', self.root / directory / 'state-test/flutter', value['toolchain'], shared_batch=batch)
            for index, (target, group) in enumerate(groups):
                current[target] = current.get(target, 'b' * 64)
                tests = [dict(id=i, name=name, result='success', skipped=False) for i, name in enumerate(group)]
                events = []
                if target.startswith('test/'):
                    events.append(dict(type='print', message=json.dumps(dict(kind='linux-adapter-inventory', selected_suites=selected, unselected_suites=[]))))
                for row in tests:
                    events.extend([dict(type='testStart', test=dict(id=row['id'], name=row['name'])),
                                   dict(type='testDone', testID=row['id'], result='success', skipped=False)])
                events.append(dict(type='done', success=True))
                log = 'logs/' + str(index) + '.log'
                self.write(directory + '/' + log, '\n'.join(json.dumps(e) for e in events), raw=True)
                checksum = self.qa.qa.digest(self.root / directory / log)
                command = dict(command=['/bin/bash', '-c', 'exec "$@" 2>&1', 'qualification', *vectors[index]], exit_code=0, log=log, log_sha256=checksum, status='pass')
                suite = dict(target=target, tests=tests, command_index=index, target_sha256=current[target], log_sha256=checksum, status='pass', native_processes=[dict(native_pid=124, start_ticks='456')])
                child['commands'].append(command)
                child['suite_runs'].append(suite)
                value['commands'].append(command | dict(batch=batch, log=directory + '/' + log))
                value['suite_runs'].append(suite | dict(batch=batch, command_index=len(value['suite_runs'])))
                logs.append(self.root / directory / log)
            self.write(directory + '/shared.json', child)
            value['batches'].append(dict(batch=batch, receipt=directory + '/shared.json', sha256=self.qa.qa.digest(self.root / directory / 'shared.json')))
        cases = self.qa.check_shared(self.root, value, current, logs)
        self.assertTrue(any(c['name'].startswith('test/features/hermes_chat/bots/') for c in cases))
        bad = copy.deepcopy(value)
        self.write('unrelated.json', {})
        bad['batches'][0].update(receipt='unrelated.json', sha256=self.qa.qa.digest(self.root / 'unrelated.json'))
        with self.assertRaisesRegex(ValueError, 'binding'):
            self.qa.check_shared(self.root, bad, current, logs)
        bad = copy.deepcopy(value)
        path = self.root / 'shared-core/shared.json'
        child = json.loads(path.read_text())
        for processes in ([dict(native_pid=True, start_ticks='456')], [dict(native_pid=124, start_ticks='not-ticks')]):
            child['suite_runs'][1]['native_processes'] = processes
            bad['suite_runs'][1]['native_processes'] = processes
            path.write_text(json.dumps(child))
            bad['batches'][0]['sha256'] = self.qa.qa.digest(path)
            with self.assertRaisesRegex(ValueError, 'GTK observation'):
                self.qa.check_shared(self.root, bad, current, logs)

    def test_failed_nested_runner_preserves_native_exit_without_success_receipt(self):
        target = 'integration_test/linux_access_feature_qualification_test.dart'
        self.source['inputs'] = {target: 'b' * 64}
        self.source['tree_sha256'] = self.qa.qa.identity(self.source['inputs'])
        value = copy.deepcopy(self.receipt)
        value.update(lane='access', source=self.source, status='fail', runner_receipts=[])
        value['commands'][0]['command'][-1] = target
        self.write('access-0-feature-cases.json', {'schema': 1, 'cases': [self.case]})
        value['cases'][0]['artifact_sha256'] = self.qa.qa.digest(self.root / 'access-0-feature-cases.json')
        proof = dict(status='FAIL', exit_code=37, isolated_state_removed=True,
                     cleanup=dict(groups_gone=True, state_removed=True))
        self.write('nested/verification.json', proof)
        self.write('logs/access-1.log', 'native failure', raw=True)
        value['commands'].append(dict(command=['/bin/bash', '-c', 'exec "$@" 2>&1', 'qualification',
            sys.executable, '-B', 'integration_test/run_linux_shell_compact_return.py'],
            exit_code=1, native_exit_code=37, status='fail', driver_pid=125, owned_group_gone=True,
            log='logs/access-1.log', log_sha256=self.qa.qa.digest(self.root / 'logs/access-1.log'),
            artifacts={'verification.json': dict(path='nested/verification.json',
                sha256=self.qa.qa.digest(self.root / 'nested/verification.json'))}))
        self.write('campaign.json', dict(schema=1, source=self.source, toolchain=value['toolchain']))
        self.write('access.json', value)
        _, result = self.qa.check_lane('access', self.root, self.source['inputs'], self.expected)
        self.assertEqual(result['commands'][1]['native_exit_code'], 37)
        self.assertEqual(result['status'], 'fail')

    def test_composition_verifies_original_locations_and_complete_input_equivalence(self):
        self.check()
        changed = self.source['inputs'] | {'scripts/check_linux_feature_qualification.py': 'f' * 64}
        rows, proof = self.qa.check_lane('management', self.root, changed, self.expected)
        self.assertEqual(rows[0]['id'], 'management.example')
        self.assertEqual(proof['source_equivalence']['changed_nonexecuted_inputs'], ['scripts/check_linux_feature_qualification.py'])
        with self.assertRaises(ValueError):
            self.qa.check_lane('management', self.root, changed | {self.target: 'e' * 64}, self.expected)
        lanes = {}
        for lane in ('shared', 'connections', 'chat', 'management', 'access'):
            self.write(lane + '.json', self.receipt)
            lanes[lane] = dict(directory=str(self.root), receipt_sha256=self.qa.qa.digest(self.root / (lane + '.json')),
                               campaign_sha256=self.qa.qa.digest(self.root / 'campaign.json'))
        self.write('composition.json', dict(schema=1, lanes=lanes))
        selected = self.qa.evidence_roots(self.root)
        self.assertEqual(set(selected), {'shared', 'connections', 'chat', 'management', 'access'})
        failed = copy.deepcopy(self.receipt)
        failed.update(lane='chat', status='fail', cases=[])
        failed['commands'][0].update(exit_code=37, status='fail')
        self.write('chat.json', failed)
        selected['chat'] = self.root / 'new-chat'
        history = self.qa.retained_failures(self.root, selected)
        self.assertEqual(history[0]['commands'][0]['exit_code'], 37)
        self.assertEqual(history[0]['qualification'], 'historical-failure-not-current-coverage')
        lanes['chat']['receipt_sha256'] = '0' * 64
        self.write('composition.json', dict(schema=1, lanes=lanes))
        with self.assertRaises(ValueError):
            self.qa.evidence_roots(self.root)

    def test_public_action_inventory_rejects_omissions_and_source_drift(self):
        source = self.root / 'source'
        source.mkdir()
        menu = source / 'lib/features/chat/menu.dart'
        menu.parent.mkdir(parents=True)
        menu.write_text("""Widget menu() => PopupMenuButton<String>(
  onSelected: dispatch,
  itemBuilder: (_) => [
    PopupMenuItem(value: 'copy-id', child: Text('Copy ID')),
    PopupMenuItem(value: 'details', child: Text('Details')),
    CheckedPopupMenuItem(value: Action.handsFree, onTap: toggle),
  ],
);
// onPressed: notAnAction
final text = 'onTap: notAnAction';
enum Filter { all, enabled, disabled }
const auxiliary = ['vision', 'web_extract'];
final slots = [const _SlotOption(label: 'main', scope: 'main'),
  for (final task in auxiliary) _SlotOption(label: task, scope: 'auxiliary')];
final commands = [for (final alias in ['timestamps', 'ts'])
  _LocalSlashCommand(id: alias)];
final filters = [for (final option in Filter.values)
  ChoiceChip(label: Text(switch (option) {
    Filter.all => 'All', Filter.enabled => 'Enabled', Filter.disabled => 'Disabled',
  }), onSelected: (_) => select(option))];
""")
        shell = source / 'lib/shared/shell.dart'
        shell.parent.mkdir(parents=True)
        shell.write_text('final key = SingleActivator(LogicalKeyboardKey.escape);\n'
                         'final button = TextButton(onPressed: cancel);\n')
        report = self.qa.public_action_ledger(source)
        self.qa.validate_public_actions(report, source)
        entries = report['actions']
        copy_id = next(k for k, v in entries.items() if v['source']['selector'] == "'copy-id'")
        self.assertEqual(entries[copy_id]['statuses'], ['coverage_gap'])
        self.assertEqual(entries[copy_id]['cases'], [])
        self.assertEqual(sum(v['source']['kind'] == 'callback' for v in entries.values()), 4)
        self.assertIn('Action.handsFree', [v['source']['selector'] for v in entries.values()])
        self.assertIn("'main'", [v['source']['selector'] for v in entries.values() if v['source']['kind'] == 'descriptor'])
        self.assertEqual([v['source']['selector'] for v in entries.values() if v['source']['kind'] == 'collection-choice'][:2],
                         ["'vision'", "'web_extract'"])
        self.assertEqual([v['source']['selector'] for v in entries.values() if v['source']['kind'] == 'enum-choice'],
                         ['Filter.all', 'Filter.enabled', 'Filter.disabled'])
        self.assertEqual([v['source']['selector'] for v in entries.values() if v['source']['kind'] == 'literal-choice'],
                         ["'timestamps'", "'ts'"])
        for label in ('missing-menu', 'missing-choice', 'missing-file', 'unknown', 'unearned-pass'):
            changed = copy.deepcopy(report)
            if label == 'missing-menu': del changed['actions'][copy_id]
            if label == 'missing-choice':
                choice = next(k for k, v in entries.items() if v['source']['selector'] == 'Filter.disabled')
                del changed['actions'][choice]
            if label == 'missing-file':
                changed['actions'] = {k: v for k, v in entries.items() if v['source']['file'] != 'lib/shared/shell.dart'}
                del changed['action_sources']['lib/shared/shell.dart']
            if label == 'unknown': changed['actions']['unknown'] = entries[copy_id]
            if label == 'unearned-pass': changed['actions'][copy_id].update(statuses=['pass'])
            with self.subTest(label=label), self.assertRaises(ValueError):
                self.qa.validate_public_actions(changed, source)
        original = menu.read_text()
        for text in (original.replace("'copy-id'", "'copy-all'"),
                     original + "\nfinal extra = PopupMenuItem(value: 'delete');\n",
                     original + '\nfinal button = TextButton(onPressed: send);\n'):
            menu.write_text(text)
            with self.assertRaises(ValueError):
                self.qa.validate_public_actions(report, source)
        menu.write_text(original)
        shell.unlink()
        with self.assertRaises(ValueError):
            self.qa.validate_public_actions(report, source)

    def test_invalid_cli_replaces_previous_verdict_instead_of_leaving_green(self):
        self.root.chmod(0o700)
        self.write('qualification.json', {'fixture_verdict': 'COMPLETE'})
        with contextlib.redirect_stdout(io.StringIO()):
            code = self.qa.main(['--phase', 'fixture', '--input', str(self.root)])
        self.assertEqual(code, 2)
        result = json.loads((self.root / 'qualification.json').read_text())
        self.assertEqual(result['fixture_verdict'], 'INVALID')
        self.assertEqual(result['overall_linux_verdict'], 'PARTIAL')

    def test_ledger_never_promotes_absence_or_unsupported_to_pass(self):
        rows = [self.case | {'status': 'unsupported', 'skip_reason': 'No contract'}]
        report = self.qa.make_ledger(rows, ['HD-PROFILE', 'HD-UPDATE'], ['/profiles', '/enroll'],
                                     {'save': ['management.example'], 'install': []})
        self.assertEqual(report['fixture_verdict'], 'PARTIAL')
        self.assertEqual(report['overall_linux_verdict'], 'PARTIAL')
        self.assertEqual(report['features']['HD-PROFILE']['statuses'], ['unsupported'])
        self.assertEqual(report['features']['HD-UPDATE']['statuses'], ['coverage_gap'])
        self.assertEqual(report['routes']['/enroll']['cases'], [])
        self.assertEqual(report['actions']['install']['statuses'], ['coverage_gap'])
        self.assertFalse(report['parity_met'])
        with self.assertRaises(ValueError):
            self.qa.make_ledger(rows, ['HD-PROVIDER'], ['/profiles'], {'save': ['missing']})


if __name__ == '__main__':
    unittest.main()
