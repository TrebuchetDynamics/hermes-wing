"""Verify and publish native evidence without promoting partial runs to a pass."""
import ast
import datetime
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess

ROOT = Path(os.environ['TMPDIR']) / 'parity-native'


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def cases(invocation):
    return [c['name'] for c in invocation['cases']
            if not c['hidden'] and not c['skipped'] and c['result'] == 'success']


def mapping(name):
    for fragment, topics, scope in [
        ('pagination', ['HD-SEARCH'], 'loaded metadata/session management'),
        ('clipboard exports', ['HD-EXPORT'], 'loaded text/Markdown clipboard'),
        ('legacy pairing', ['HD-ENTRY'], 'retired-input rejection only'),
        ('gateway is read-only', ['HD-GATEWAY'], 'read-only; positive administration remains unsupported'),
        ('provider mutations', ['HD-PROVIDER', 'HD-MODEL'], 'synthetic operation/grant/revision UI only'),
        ('draft ownership', ['HD-DRAFT', 'HD-ATTACH'], 'volatile session/profile draft and picker ownership'),
        ('approval Stop', ['HD-APPROVAL', 'HD-STOP'], 'UI approval/Stop and fixture status recovery; not transport reconnect'),
        ('screen tour', ['HD-SHELL'], 'smoke only; cannot close feature rows'),
        ('attachments and schedule', ['HD-ATTACH', 'HD-SCHEDULE'], 'synthetic attachment send and schedule read recovery; no schedule mutation'),
    ]:
        if fragment in name:
            return topics, scope
    raise AssertionError(name)


def main():
    source = json.loads((ROOT / 'native-source.json').read_text())
    assert source['sha256'] == hashlib.sha256(json.dumps(source['files'], sort_keys=True).encode()).hexdigest()
    assert all(Path(p).is_file() and sha(Path(p)) == want for p, want in source['files'].items())
    assert all(sha(ROOT / p) == want for p, want in source['scratch_tools'].items())
    assert subprocess.check_output(['node', '--version'], text=True).strip() == source['runtime']['node_version']
    assert sha(Path(shutil.which('node'))) == source['runtime']['node_sha256']
    tool_dir = Path('docs/quality/native-linux-parity-tools')
    executed_tools, published_hashes = {}, {}
    for name in ('run_native.py', 'env.sh', 'bounded_bind.c', 'validate_native_harness.py',
                 'bin/flutter', 'bin/owned-dbus-daemon'):
        executed_tools[name] = {'sha256': sha(ROOT / name), 'utf8': (ROOT / name).read_text()}
        published_hashes[name] = sha(tool_dir / name)
    changed_tools = [name for name in published_hashes
                     if published_hashes[name] != source['scratch_tools'][name]]
    assert set(changed_tools) <= {'run_native.py', 'validate_native_harness.py'}
    if changed_tools:
        # Reuse GUI receipts only for this independently tested termination wait fix.
        old = ast.parse(executed_tools['run_native.py']['utf8'])
        new = ast.parse((tool_dir / 'run_native.py').read_text())
        def functions(tree):
            return {n.name: ast.dump(n, include_attributes=False) for n in tree.body
                    if isinstance(n, ast.FunctionDef)}
        a, b = functions(old), functions(new)
        assert set(b) - set(a) == {'wait_all'} and not set(a) - set(b)
        assert all(a[name] == b[name] for name in a if name != 'terminate_owned')
        for tree in (old, new):
            tree.body = [n for n in tree.body if not isinstance(n, ast.FunctionDef)]
        assert ast.dump(old, include_attributes=False) == ast.dump(new, include_attributes=False)
        candidate = Path(os.environ['TMPDIR']) / 'harness-candidate/parity-native'
        assert all(sha(candidate / name) == published_hashes[name] for name in changed_tools)
        assert (ROOT / 'wait-green.exit').read_text().strip() == '0'
    spec = importlib.util.spec_from_file_location('current_native_policy', tool_dir / 'run_native.py')
    policy = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(policy)
    journal = ROOT / 'native-runs.jsonl'
    rows = [json.loads(line) for line in journal.read_text().splitlines()] if journal.exists() else []
    terminal = ROOT / 'native-execution.exit'
    exit_code = int(terminal.read_text().strip()) if terminal.exists() else None
    expected = ['broad'] + [f'scenario-{i:02}' for i in range(1, 21)]
    assert [r['label'] for r in rows] == expected[:len(rows)]
    complete = (exit_code == 0 and len(rows) == len(expected)
                and all(r['exit'] == 0 and r['intended_cases_passed'] for r in rows))
    events = {sha(p): p.name for p in ROOT.glob('*.events.jsonl')}
    bundles, runs = {}, []
    native_pids = []
    for row in rows:
        assert row['source_sha256'] == source['sha256']
        assert policy.validate(row['invocations'], row['label'], row['command']) == row['intended_cases_passed']
        assert row['source_unchanged'] and row['scratch_tools_unchanged']
        assert sha(ROOT / (row['label'] + '.log')) == row['log_sha256']
        invocations = []
        for inv in row['invocations']:
            assert inv['bundle_sha256'] == hashlib.sha256(json.dumps(inv['bundle_files'], sort_keys=True).encode()).hexdigest()
            if inv['events_sha256'] is not None:
                assert inv['events_sha256'] in events
            bundles[inv['bundle_sha256']] = inv['bundle_files']
            invocations.append({'command': inv['args'], 'launcher_exit': inv['exit'],
                                'persistence_phase': inv['persistence_phase'], 'cases': cases(inv),
                                'terminal_success': inv['terminal_success'],
                                'events_sha256': inv['events_sha256'],
                                'events_file': events.get(inv['events_sha256']),
                                'bundle_sha256': inv['bundle_sha256'], 'seconds': inv['seconds']})
        result = {'label': row['label'], 'command': row['command'], 'launcher_exit': row['exit'],
                  'seconds': row['seconds'], 'accepted': row['intended_cases_passed'],
                  'native_pids': row['native_pids'], 'log_file': row['label'] + '.log',
                  'log_sha256': row['log_sha256'], 'source_sha256': row['source_sha256'],
                  'remaining_marked_processes': len(row['owned_processes_remaining']),
                  'remaining_owned_display_directories': row['owned_display_state_remaining'],
                  'terminated_marked_children_after_exit': len(row['owned_processes_terminated_after_command']),
                  'invocations': invocations}
        if row['label'] != 'broad':
            requested = row['command'][row['command'].index('--plain-name') + 1]
            result['name'] = requested
            result['hd_topics'], result['bounded_scope'] = mapping(requested)
            if row['intended_cases_passed']:
                assert len(invocations) == 1 and invocations[0]['cases'] == [requested]
                assert len(row['native_pids']) == 1
                native_pids.extend(row['native_pids'])
        result['owned_state_removed'] = row['owned_state_removed']
        if complete:
            assert row['owned_state_removed']
            assert not row['owned_processes_remaining'] and row['owned_display_state_remaining'] == 0
        runs.append(result)
    if complete:
        assert len(set(native_pids)) == len(native_pids) == 20
        assert not list((ROOT / 'owned-state').iterdir())
    result = {'task': 'PARITY-NATIVE-LINUX',
              'baseline': subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip(),
              'recovered_native_delta_from': '20552926d826d8578f85abc4221560c3f4707b14',
              'recorded_utc': datetime.datetime.now(datetime.timezone.utc).isoformat(),
              'scope': 'GTK debug source-runs with deterministic services; no full official row, live/provider/device/release acceptance',
              'run_status': 'passed' if complete else 'incomplete_or_failed', 'launcher_exit': exit_code,
              'expected_driver_commands': len(expected), 'completed_driver_commands': len(rows),
              'not_completed_labels': expected[len(rows):],
              'source': source, 'receipt_builder_sha256': sha(Path(__file__)),
              'executed_tool_sources': executed_tools, 'published_tool_hashes': published_hashes,
              'harness_followup': {'changed_candidates': changed_tools,
                                  'reason': 'shared-deadline pidfd draining; no native/source/build/acceptance change' if changed_tools else None,
                                  'current_controls_passed': True if changed_tools else None,
                                  'controls_log_sha256': sha(ROOT / 'wait-green.log') if changed_tools else None},
              'environment': {'flutter': '3.44.2', 'dart': '3.12.2',
                              'node': source['runtime']['node_version'],
                              'node_sha256': source['runtime']['node_sha256'],
                              'framework_revision': 'c9a6c48423', 'engine_revision': '77e2e94772',
                              'platform': 'Linux amd64 GTK/X11 under owned Xvfb',
                              'rendering': 'LIBGL_ALWAYS_SOFTWARE=1, LP_NUM_THREADS=2',
                              'compiler_parallelism': 2, 'port_base': int(os.environ['AUTOWORK_PORT_BASE']),
                              'port_end': int(os.environ['AUTOWORK_PORT_BASE']) + 99,
                              'temporary_tcp_allocator': True, 'system_package_changes': False,
                              'personal_runtime_changes': False, 'upstream_changes': False},
              'runs': runs, 'bundle_manifests': bundles, 'matrix_rows_closed': [],
              'abort_cleanup': json.loads((ROOT / 'native-abort.json').read_text())['cleanup']
                              if (ROOT / 'native-abort.json').exists() else None,
              'limits': ['Unavailable-state assertions never qualify positive operations.',
                         'Fixture status recovery is not transport reconnect; HTTP reconnect is separate.',
                         'Widths are Flutter view overrides in actual GTK processes, not Android or physical display receipts.',
                         'IME covers production Chat GTK Unicode preedit through X11 only.',
                         'No browser, live Agent/provider/SSH/OAuth, OS keyring, audio hardware, screen reader or signed-release qualification.']}
    Path('docs/quality/native-linux-parity-receipts.json').write_text(json.dumps(result, indent=2) + '\n')
    print('Native receipt:', result['run_status'], len(runs), 'completed driver commands; no matrix rows closed')


if __name__ == '__main__':
    main()
