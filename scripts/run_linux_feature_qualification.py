#!/usr/bin/env python3
"""Fixed offline Linux fixture lanes. See docs/quality/linux-qualification-driver.md."""
import argparse
import json
import os
from pathlib import Path
import re
import shutil
import signal
import subprocess
import sys
import tempfile

sys.path.insert(0, str(Path(__file__).resolve().parent / 'support'))
import linux_qualification_support as qa
from desktop_live_workflow import Refusal, cancellation_scope, live_group, run_owned

SOURCE = Path(__file__).resolve().parents[1]
TARGETS = {
    'shared': ('test/tooling/linux_feature_adapter_inventory_test.dart',
               'integration_test/linux_feature_regression_test.dart'),
    'connections': ('integration_test/linux_connection_feature_qualification_test.dart',),
    'chat': ('integration_test/linux_chat_feature_qualification_test.dart',),
    'management': ('integration_test/linux_management_feature_qualification_test.dart',),
    'access': ('integration_test/linux_access_feature_qualification_test.dart',),
    'report': ('scripts/check_linux_feature_qualification.py',),
}
RUNNERS = {'chat': ('run_linux_local_serve_reads', 'run_linux_transcript_keyboard'),
           'access': ('run_linux_shell_compact_return',)}
# Live engine pumps wait wall-clock time. Keep all five six-minute cases in
# separate bounded batches, rather than excluding them or shortening their waits.
SHARED_TIMERS = (r'test/features/profiles/profile_editor_sheet_test\.dart '
                 r'(?:failed delete needs fresh typed confirmation:|'
                 r'create failure clears credential and never replays:)')
SHARED_NATIVE_BATCHES = {
    'core': r'^(?!test/features/hermes_chat/screens/)(?!' + SHARED_TIMERS + r')[\s\S]*$',
    'screens': r'^test/features/hermes_chat/screens/',
    'delete-timers': r'^test/features/profiles/profile_editor_sheet_test\.dart failed delete needs fresh typed confirmation:',
    'create-timers': r'^test/features/profiles/profile_editor_sheet_test\.dart create failure clears credential and never replays:',
}


def atomic_json(path, value):
    fd, name = tempfile.mkstemp(prefix=path.name + '-', suffix='.partial', dir=path.parent)
    temporary = Path(name)
    try:
        with os.fdopen(fd, 'w') as stream:
            json.dump(value, stream, indent=2, sort_keys=True)
            stream.write('\n')
        temporary.replace(path)
    finally:
        temporary.unlink(missing_ok=True)


def output_root(path, source, environ, *, inspect_contents=True):
    scratch, path = qa.plain_path(environ['TMPDIR']), qa.plain_path(path)
    forbidden = [source]
    if environ.get('WING_LINUX_DEPENDENCY_PREFIX'):
        forbidden.append(qa.plain_path(environ['WING_LINUX_DEPENDENCY_PREFIX']))
    if environ.get('PUB_CACHE'): forbidden.append(qa.plain_path(environ['PUB_CACHE']))
    flutter = shutil.which('flutter', path=environ.get('PATH', '/usr/bin:/bin'))
    if flutter: forbidden.append(Path(flutter).resolve().parents[1])
    if (path == scratch or not path.is_relative_to(scratch) or
            any(path.is_relative_to(root) or root.is_relative_to(path) for root in forbidden)):
        raise ValueError('Output must be a dedicated TMPDIR child outside source/SDK/dependencies')
    path.parent.mkdir(parents=True, exist_ok=True)
    path.mkdir(mode=0o700, exist_ok=True)
    if path.stat().st_uid != os.getuid() or path.stat().st_mode & 0o077:
        raise ValueError('Owned private output directory required')
    marker = path / '.wing-linux-qualification.json'
    expected = dict(schema=1, source=str(source), uid=os.getuid())
    if any(path.iterdir()):
        if qa.identity(qa.read_json(marker)) != qa.identity(expected): raise ValueError('Unowned output directory')
        if inspect_contents and any(p.is_symlink() for p in path.rglob('*')): raise ValueError('Linked output artifact')
    else:
        atomic_json(marker, expected)
    (path / 'logs').mkdir(exist_ok=True)
    return path


def validate_cases(value):
    if not isinstance(value, dict) or type(value.get('schema')) is not int or value['schema'] != 1:
        raise ValueError('Schema-1 case document required')
    cases = value.get('cases')
    if not isinstance(cases, list) or not cases: raise ValueError('Nonempty case inventory required')
    seen = set()
    for row in cases:
        if not isinstance(row, dict): raise ValueError('Invalid case')
        case_id = row.get('id')
        if not isinstance(case_id, str) or not case_id or case_id in seen: raise ValueError('Missing/duplicate case ID')
        seen.add(case_id)
        for name in ('feature_ids', 'route_ids'):
            ids = row.get(name)
            if not isinstance(ids, list) or not ids or any(not isinstance(v, str) or not v for v in ids) or len(set(ids)) != len(ids):
                raise ValueError('Exact feature/route identities required')
        for name in ('backend', 'input', 'storage'):
            if not isinstance(row.get(name), str) or not row[name]: raise ValueError('Case environment identity required')
        if row.get('status') not in ('pass', 'fail', 'not_run', 'unsupported', 'coverage_gap'): raise ValueError('Terminal status required')
        if row['status'] in ('not_run', 'unsupported', 'coverage_gap') and (
                not isinstance(row.get('skip_reason'), str) or not row['skip_reason']):
            raise ValueError('Non-pass reason required')
        if row['status'] == 'unsupported' and row.get('negative_assertion') is not True: raise ValueError('Passing negative assertion required')
        for name in ('native_pid', 'owner_count'):
            if type(row.get(name)) is not int or row[name] <= 0: raise ValueError('Native PID and exact owner count required')
        counts = row.get('operation_counts')
        if not isinstance(counts, dict) or not counts or any(not isinstance(k, str) or type(v) is not int or v < 0 for k, v in counts.items()):
            raise ValueError('Exact nonnegative operation counts required')
    return cases


def process_identity(pid, group):
    fields = Path('/proc', str(pid), 'stat').read_text().rsplit(')', 1)[1].split()
    if pid == group or int(fields[2]) != group or fields[0] == 'Z': raise ValueError('GTK PID is not driver-owned')
    return dict(native_pid=pid, start_ticks=fields[19])


def native_processes(group):
    result = []
    for process in Path('/proc').iterdir():
        try:
            if (process / 'exe').resolve().name == 'wing': result.append(process_identity(int(process.name), group))
        except (OSError, ValueError, IndexError):
            continue
    return result


def suite_result(log, *, require_success=True):
    starts, terminal, completed = {}, {}, False
    for line in log.read_text(errors='replace').splitlines():
        try: event = json.loads(line)
        except ValueError: continue  # Flutter/platform diagnostics share stdout.
        if not isinstance(event, dict): continue
        kind = event.get('type')
        if kind not in ('testStart', 'testDone', 'done'): continue
        if completed: raise ValueError('Duplicate or post-terminal suite record')
        if kind == 'testStart':
            number, name = event['test']['id'], event['test']['name']
            if type(number) is not int or number in starts or not isinstance(name, str) or not name:
                raise ValueError('Duplicate/invalid suite start identity')
            starts[number] = name
        elif kind == 'testDone':
            number = event['testID']
            if type(number) is not int or number in terminal or number not in starts:
                raise ValueError('Duplicate/unknown suite terminal identity')
            if (type(event.get('skipped')) is not bool or type(event.get('hidden', False)) is not bool or
                    event.get('result') not in ('success', 'failure', 'error') or
                    (require_success and (event['result'] != 'success' or event['skipped']))):
                raise ValueError('Skipped, failed or invalid suite result')
            terminal[number] = event
        else:
            if type(event.get('success')) is not bool or (require_success and event['success'] is not True):
                raise ValueError('Suite failed')
            completed = True
    if not completed or set(starts) != set(terminal): raise ValueError('Incomplete suite inventory')
    tests = [dict(id=number, name=starts[number], result=row['result'], skipped=row['skipped'])
             for number, row in sorted(terminal.items()) if not row.get('hidden', False)]
    if not tests: raise ValueError('Empty suite inventory')
    return tests


def commands(lane, sdk, tools, *, shared_batch=None):
    if lane == 'report': return [[sys.executable, '-B', TARGETS[lane][0], '--phase', 'fixture']]
    result = []
    for target in TARGETS[lane]:
        if lane == 'shared' and shared_batch not in (None, 'core') and target.startswith('test/'):
            continue
        command = [str(sdk / 'bin/flutter'), 'test', '--no-pub', '--concurrency=1']
        if lane == 'shared': command.append('--machine')
        if target.startswith('integration_test/'):
            command = [tools['xvfb-run']['path'], '-a', '-s', '-screen 0 1440x1000x24 -nolisten tcp',
                       tools['dbus-run-session']['path'], '--', *command, '-d', 'linux']
            if lane == 'shared': command.append('--no-dds')
        if lane == 'shared' and target.startswith('integration_test/'):
            batches = SHARED_NATIVE_BATCHES if shared_batch is None else {shared_batch: SHARED_NATIVE_BATCHES[shared_batch]}
            result.extend([*command, target, '--name', selection] for selection in batches.values())
        else:
            result.append([*command, target])
    result.extend([sys.executable, '-B', 'integration_test/' + name + '.py'] for name in RUNNERS.get(lane, ()))
    return result


def retain_artifacts(directory, output, lane, index):
    artifacts = {}
    if directory.is_dir():
        target = Path(tempfile.mkdtemp(prefix=f'{lane}-{index}-runner-', dir=output))
        for path in sorted(directory.iterdir()):
            if path.is_symlink(): raise ValueError('Linked runner artifact')
            if path.is_file():
                saved = target / path.name
                shutil.copyfile(path, saved)
                artifacts[path.name] = dict(path=str(saved.relative_to(output)), sha256=qa.digest(saved))
    return artifacts


def validate_runner(name, directory):
    value = qa.read_json(directory / 'verification.json')
    if (value.get('status') != 'PASS' or type(value.get('exit_code')) is not int or value['exit_code'] != 0 or
            value.get('isolated_state_removed') is not True or
            not any(value.get(k) is True for k in ('owned_group_gone', 'native_group_gone'))):
        raise ValueError('Runner terminal/cleanup evidence missing')
    import importlib
    sys.path.insert(0, str(SOURCE / 'integration_test'))
    importlib.import_module(name).validate(value['receipt'])
    return value


def execute(lane, source, output, state, receipt, prefix, sdk, node, environ):
    app = state / 'app'
    qa.snapshot(source, app, receipt['source']['inputs'])
    pub_cache = Path(environ['PUB_CACHE']).resolve() if environ.get('PUB_CACHE') else None
    if lane != 'report':
        if qa.identity(qa.sdk_inputs(sdk)) != receipt['toolchain']['sdk_sha256']:
            raise ValueError('SDK changed before capture')
        if qa.identity(qa.tree(prefix, links=True)) != receipt['toolchain']['dependencies_sha256']:
            raise ValueError('Native dependencies changed before capture')
        original_packages = qa.package_inputs(source, sdk, pub_cache)[2]
        if qa.identity(original_packages) != receipt['toolchain']['packages_sha256']:
            raise ValueError('Package input changed before capture')
        deps = qa.stage_dependencies(prefix, state / 'deps')
        copied_sdk = state / 'flutter'
        env = qa.isolated_environment(state, prefix=deps, sdk=sdk, node=node)
        qa.prepare(source, app, sdk, copied_sdk, env, pub_cache)
        captured = qa.package_inputs(app, copied_sdk, state / 'packages')[2]
        if {k: v for k, v in captured.items() if k != 'metadata'} != {k: v for k, v in original_packages.items() if k != 'metadata'}:
            raise ValueError('Package source changed during capture')
        if qa.identity(qa.sdk_inputs(copied_sdk)) != receipt['toolchain']['sdk_sha256']:
            raise ValueError('SDK changed during capture')
    else:
        deps = copied_sdk = None
    def executed_inputs():
        result = {'source': qa.source_inputs(app)}
        if copied_sdk:
            result.update(dependencies=qa.tree(deps, links=True),
                          packages=qa.package_inputs(app, copied_sdk, state / 'packages')[2],
                          sdk=qa.sdk_inputs(copied_sdk))
        return result
    before = executed_inputs()
    receipt['executed_inputs_sha256'] = qa.identity(before)
    seen = set()
    for index, command in enumerate(commands(lane, copied_sdk, receipt['toolchain'], shared_batch=receipt.get('batch'))):
        case_root = Path(tempfile.mkdtemp(prefix='wing-linux-qualification-', dir=state / 'cache'))
        env = qa.isolated_environment(case_root, prefix=deps, sdk=copied_sdk, node=node)
        env.update(TMPDIR=str(case_root.parent), WING_LINUX_RUNNER_OUTPUT=str(case_root / 'runner'),
                   PUB_CACHE=str(state / 'packages'))
        if deps: env['WING_LINUX_DEPENDENCY_PREFIX'] = str(deps)
        if lane in ('chat', 'shared'): env['AUTOWORK_PORT_BASE'] = str(int(environ['AUTOWORK_PORT_BASE']))
        (case_root / '.wing-linux-test-owner').write_text(qa.identity(receipt['source']))
        cases_file, observed = case_root / 'feature-cases.json', {}
        def observe(group):
            if lane == 'shared': observed['native'] = observed.get('native') or native_processes(group)
            elif cases_file.exists() and not observed:
                cases = validate_cases(qa.read_json(cases_file))
                observed.update(sha256=qa.digest(cases_file), processes=[process_identity(c['native_pid'], group) for c in cases])
        if lane == 'report': command.extend(['--input', str(output)])
        target = next((target for target in TARGETS[lane] if target in command), None)
        runner = Path(command[-1]).stem if command[-1].endswith('.py') and lane != 'report' else None
        command = ['/bin/bash', '-c', 'exec "$@" 2>&1', 'qualification', *command]
        log = output / 'logs' / f'{lane}-{index}.log'
        row = dict(command=command, exit_code=None, status='not_run', log=str(log.relative_to(output)))
        receipt['commands'].append(row)
        atomic_json(output / (lane + '.json'), receipt)
        receipt['cleanup']['groups_gone'] = False
        try:
            with log.open('wb') as stream:
                limit = 1500 if receipt.get('batch') == 'delete-timers' else 900
                code, group = run_owned(command, app, env, timeout=limit, stdout=stream, observe=observe)
            row.update(exit_code=code, driver_pid=group, status='pass' if code == 0 else 'fail',
                       owned_group_gone=not live_group(group))
            receipt['cleanup']['groups_gone'] = row['owned_group_gone'] and runner is None
        except Refusal as error:
            row['owned_group_gone'] = str(error) != 'OWNED_TEARDOWN_INCOMPLETE'
            receipt['cleanup']['groups_gone'] = row['owned_group_gone'] and runner is None
            raise
        except BaseException:
            row['owned_group_gone'] = True  # run_owned tears down before propagating.
            receipt['cleanup']['groups_gone'] = runner is None
            raise
        finally:
            row['log_sha256'] = qa.digest(log)
            if runner and row.get('owned_group_gone') is True:
                row['artifacts'] = retain_artifacts(case_root / 'runner', output, lane, index)
        if row.get('owned_group_gone') is not True: raise Refusal('OWNED_TEARDOWN_INCOMPLETE')
        if executed_inputs() != before: raise ValueError('Executed source/tool/dependency drift')
        if runner:
            directory = case_root / 'runner'
            # Native runners own a second process session. The outer group's
            # disappearance is not proof that the native group/state is gone.
            receipt['cleanup']['groups_gone'] = False
            nested = qa.read_json(directory / 'verification.json')
            native = nested.get('exit_code')
            if type(native) is int and -64 <= native <= 255 and native != 0:
                row['native_exit_code'] = native
            cleanup = nested.get('cleanup', {})
            clean = (isinstance(cleanup, dict) and cleanup.get('groups_gone') is True and
                     cleanup.get('state_removed') is True and nested.get('isolated_state_removed') is True and
                     nested.get('cleanup_error') is None and not any(p.is_dir() for p in directory.iterdir()))
            if not clean: raise Refusal('NESTED_TEARDOWN_INCOMPLETE')
            receipt['cleanup']['groups_gone'] = True
            if code: return row.get('native_exit_code', code)
            receipt['runner_receipts'].append(dict(runner=runner, receipt=validate_runner(runner, directory)))
        elif lane == 'shared':
            tests = suite_result(log, require_success=code == 0)
            if target.startswith('integration_test/') and not observed.get('native'):
                raise ValueError('Shared GTK process not observed')
            receipt['suite_runs'].append(dict(target=target, target_sha256=receipt['source']['inputs'][target],
                command_index=index, status='pass' if code == 0 else 'fail', tests=tests,
                native_processes=observed.get('native', []), log_sha256=row['log_sha256'],
                backend='deterministic-mocks', input='framework', storage='mock'))
            if code: return code
        elif code:
            return code
        elif lane != 'report':
            cases = validate_cases(qa.read_json(cases_file))
            if not observed or observed['sha256'] != qa.digest(cases_file): raise ValueError('Missing/changed native observation')
            saved = output / f'{lane}-{index}-feature-cases.json'
            shutil.copyfile(cases_file, saved)
            for case in cases:
                if case['id'] in seen: raise ValueError('Duplicate lane case ID')
                seen.add(case['id'])
                receipt['cases'].append(case | dict(command_index=index, artifact_sha256=qa.digest(saved), log_sha256=row['log_sha256']))
            row['processes'] = observed['processes']
    if lane not in ('shared', 'report') and (not receipt['cases'] or any(c['status'] not in ('pass', 'unsupported') for c in receipt['cases'])):
        raise ValueError('Incomplete/failed feature case inventory')
    return 0


def shared_batches(args, source, output, receipt, environ):
    """Join only source/tool-bound terminal batches; keep failures and exact IDs."""
    first_failure = 0
    receipt['batches'] = []
    native_names = set()
    for batch in SHARED_NATIVE_BATCHES:
        directory = output / ('shared-' + batch)
        saved = directory / 'shared.json'
        if not saved.exists():
            child = argparse.Namespace(**(vars(args) | {'shared_batch': batch}))
            campaign(child, source, environ)
        value = qa.read_json(saved)
        if (type(value.get('schema')) is not int or value['schema'] != 1 or
                value.get('lane') != 'shared' or value.get('batch') != batch or
                value.get('source') != receipt['source'] or value.get('toolchain') != receipt['toolchain']):
            raise ValueError('Stale or mismatched shared batch: ' + batch)
        if (value.get('ready') is not True or value.get('status') not in ('pass', 'fail') or
                value.get('cleanup', {}).get('groups_gone') is not True or
                value['cleanup'].get('state_removed') is not True):
            raise ValueError('Incomplete shared batch/cleanup: ' + batch)
        rows, suites = value['commands'], value['suite_runs']
        expected = 2 if batch == 'core' else 1
        if len(rows) != expected or len(suites) != expected:
            raise ValueError('Incomplete shared batch inventory: ' + batch)
        captured_state = Path(value['cleanup']['state'])
        if captured_state.is_absolute() or len(captured_state.parts) != 1 or not captured_state.name.startswith('state-'):
            raise ValueError('Invalid shared batch state identity')
        expected_commands = commands('shared', directory / captured_state / 'flutter', receipt['toolchain'], shared_batch=batch)
        offset = len(receipt['commands'])
        for index, (row, suite) in enumerate(zip(rows, suites)):
            expected_command = ['/bin/bash', '-c', 'exec "$@" 2>&1', 'qualification', *expected_commands[index]]
            if row.get('command') != expected_command:
                raise ValueError('Shared batch fixed command changed')
            code = row.get('exit_code')
            if (type(code) is not int or row.get('owned_group_gone') is not True or
                    type(row.get('driver_pid')) is not int or row['driver_pid'] <= 0 or
                    row.get('status') != ('pass' if code == 0 else 'fail')):
                raise ValueError('Nonterminal shared command: ' + batch)
            relative = Path(row['log'])
            if relative.is_absolute() or '..' in relative.parts:
                raise ValueError('Escaping batch log')
            log = qa.plain_path(directory / relative)
            if qa.digest(log) != row['log_sha256']:
                raise ValueError('Shared batch log changed')
            target = TARGETS['shared'][0 if batch == 'core' and index == 0 else 1]
            if (target not in row['command'] or suite['target'] != target or
                    suite['target_sha256'] != receipt['source']['inputs'][target] or
                    suite['command_index'] != index or
                    suite['tests'] != suite_result(log, require_success=code == 0) or
                    suite['log_sha256'] != row['log_sha256'] or
                    suite['status'] != ('pass' if code == 0 else 'fail') or
                    any(suite.get(k) != v for k, v in {'backend': 'deterministic-mocks', 'input': 'framework', 'storage': 'mock'}.items())):
                raise ValueError('Shared batch command/result mismatch')
            if target.startswith('integration_test/'):
                command = row['command']
                if (command.count('--name') != 1 or command[command.index('--name') + 1] != SHARED_NATIVE_BATCHES[batch] or
                        not suite.get('native_processes')):
                    raise ValueError('Shared native selection/observation mismatch')
                for process in suite['native_processes']:
                    if (type(process.get('native_pid')) is not int or process['native_pid'] <= 0 or
                            not isinstance(process.get('start_ticks'), str) or not process['start_ticks'].isdigit()):
                        raise ValueError('Invalid shared native process identity')
                names = [test['name'] for test in suite['tests'] if test['name'].startswith('test/')]
                if not names or any(not re.search(SHARED_NATIVE_BATCHES[batch], name) or name in native_names for name in names):
                    raise ValueError('Empty, overlapping or misselected native cases')
                if batch in ('delete-timers', 'create-timers') and len(names) != (3 if batch == 'delete-timers' else 2):
                    raise ValueError('Incomplete six-minute observation inventory')
                native_names.update(names)
            elif '--name' in row['command']:
                raise ValueError('Filtered host inventory')
            receipt['commands'].append(row | {'batch': batch, 'log': str(log.relative_to(output))})
            receipt['suite_runs'].append(suite | {'batch': batch, 'command_index': offset + index})
            if code and not first_failure: first_failure = code
        if (value['status'] == 'pass') != all(row['exit_code'] == 0 for row in rows):
            raise ValueError('Shared batch status mismatch')
        receipt['batches'].append(dict(batch=batch, receipt=str(saved.relative_to(output)), sha256=qa.digest(saved)))
    return first_failure


def campaign(args, source, environ):
    receipt = dict(schema=1, lane=args.lane, status='not_run', commands=[], cases=[], suite_runs=[], runner_receipts=[],
                   cleanup=dict(groups_gone=True, state_removed=False))
    output = state = None
    code = 2
    try:
        directory = args.output_dir
        if args.shared_batch is not None:
            if args.lane != 'shared': raise ValueError('Batch selection is only valid for shared')
            # Other fixed batches may still own copied SDK/dependency links.
            # Validate the parent's root/marker here, then fully inspect this child.
            parent = output_root(directory, source, environ, inspect_contents=False)
            directory = parent / ('shared-' + args.shared_batch)
            receipt['batch'] = args.shared_batch
        output = output_root(directory, source, environ)
        state = Path(tempfile.mkdtemp(prefix='state-', dir=output))
        receipt['cleanup']['state'] = str(state.relative_to(output))
        env = qa.isolated_environment(state)
        inputs = qa.source_inputs(source)
        revision = subprocess.run(['/usr/bin/git', 'rev-parse', 'HEAD'], cwd=source, env=env,
                                  capture_output=True, text=True, timeout=30, check=True).stdout.strip()
        receipt['source'] = dict(revision=revision, inputs=inputs, tree_sha256=qa.identity(inputs))
        inspection, prefix, sdk, node = qa.inspect(source, environ, state)
        receipt.update(inspection)
        binding = dict(schema=1, source=receipt['source'], toolchain=receipt['toolchain'])
        path = output / 'campaign.json'
        if path.exists() and qa.identity(qa.read_json(path)) != qa.identity(binding):
            raise ValueError('Stale campaign; use a fresh output directory')
        if not path.exists(): atomic_json(path, binding)
        atomic_json(output / (args.lane + '.json'), receipt)
        if args.lane == 'preflight':
            receipt['status'], code = 'pass', 0  # Inspection, not runtime qualification.
        elif args.lane != 'report' and not receipt['ready']:
            receipt['status'] = 'not_run'
        else:
            required = [*TARGETS[args.lane], *('integration_test/' + r + '.py' for r in RUNNERS.get(args.lane, ()))]
            missing = [name for name in required if name not in inputs]
            if missing: raise ValueError('Missing selected lane inputs: ' + ', '.join(missing))
            if args.lane in ('chat', 'shared') and not 1024 <= int(environ['AUTOWORK_PORT_BASE']) <= 65435:
                raise ValueError('Owned AUTOWORK_PORT_BASE required')
            if args.lane == 'shared' and args.shared_batch is None:
                code = shared_batches(args, source, output, receipt, environ)
            else:
                code = execute(args.lane, source, output, state, receipt, prefix, sdk, node, environ)
            if qa.source_inputs(source) != inputs: raise ValueError('Original source drift')
            if args.lane != 'report':
                cache = Path(environ['PUB_CACHE']).resolve() if environ.get('PUB_CACHE') else None
                if (qa.identity(qa.tree(prefix, links=True)) != receipt['toolchain']['dependencies_sha256'] or
                        qa.identity(qa.package_inputs(source, sdk, cache)[2]) != receipt['toolchain']['packages_sha256'] or
                        qa.identity(qa.sdk_inputs(sdk)) != receipt['toolchain']['sdk_sha256']):
                    raise ValueError('Original dependency drift')
            receipt['status'] = 'pass' if code == 0 else 'fail'
    except (OSError, ValueError, KeyError, TypeError, AssertionError, subprocess.SubprocessError, Refusal) as error:
        receipt['status'] = 'fail'
        receipt['error'] = str(error) if isinstance(error, (ValueError, Refusal)) else type(error).__name__
        exits = [r.get('native_exit_code', r['exit_code']) for r in receipt['commands'] if type(r['exit_code']) is int and r['exit_code'] != 0]
        code = exits[0] if exits else 2
        if output is None:
            print(json.dumps(dict(schema=1, lane=args.lane, status='not_run', error=receipt['error'])), file=sys.stderr)
    finally:
        if state and receipt['cleanup']['groups_gone']:
            shutil.rmtree(state)
            receipt['cleanup']['state_removed'] = True
        if output:
            atomic_json(output / (args.lane + '.json'), receipt)
            for path in (output / 'campaign.json', output / (args.lane + '.json')):
                if path.exists(): print(json.dumps(dict(path=str(path), sha256=qa.digest(path))))
    return code


def main(argv=None, *, source=SOURCE, environ=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--lane', required=True, choices=['preflight', *TARGETS])
    parser.add_argument('--output-dir', type=Path, required=True)
    parser.add_argument('--dependency-prefix', type=Path, help='Reviewed disposable usr prefix')
    parser.add_argument('--shared-batch', choices=tuple(SHARED_NATIVE_BATCHES),
                        help='Prepare one fixed shared batch; the ordinary shared lane validates and joins all batches')
    args = parser.parse_args(argv)
    environ = dict(os.environ if environ is None else environ)
    if args.dependency_prefix: environ['WING_LINUX_DEPENDENCY_PREFIX'] = str(args.dependency_prefix)
    with cancellation_scope():
        return campaign(args, Path(source).resolve(), environ)


if __name__ == '__main__':
    result = main()
    if result < 0:
        signal.signal(-result, signal.SIG_DFL)
        os.kill(os.getpid(), -result)
    sys.exit(result)
