"""Two owned GTK processes over deterministic transport; no live admission."""

import datetime
import hashlib
import importlib.util
import json
import os
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile
import time


TARGET = 'integration_test/linux_transcript_recovery_test.dart'
OWNER = {'gateway': 'synthetic-transcript', 'profile': 'default',
         'session': 'synthetic-reconnect', 'origin': 'http://127.0.0.1:8642'}
CANONICAL = ['canonical-user', 'canonical-commentary', 'canonical-read', 'canonical-web', 'canonical-answer']
TOOLS = [{'name': name, 'status': status} for name, status in (
    ('read_file', 'completed'), ('web_search', 'completed'),
    ('terminal', 'failed'), ('browser', 'running'))]


def helper(name):
    spec = importlib.util.spec_from_file_location(name, pathlib.Path(__file__).with_name(name + '.py'))
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def read_receipt(path):
    if path.is_symlink() or path.stat().st_size > 32768:
        raise ValueError('Invalid receipt file')
    v = json.loads(path.read_text())
    phase = v['phase']
    if (phase not in ('write', 'verify') or type(v['native_pid']) is not int or v['native_pid'] <= 0 or
        v['width'] not in (390.0, 1280.0) or v['text_scale'] not in (1.0, 2.0) or
        v['owner'] != OWNER or v['canonical_ids'] != CANONICAL or v['tools'] != TOOLS or
        v['mutations'] != (['/v1/runs'] if phase == 'write' else []) or v['decisions'] != [] or
        v['approval_visible'] is not (phase == 'write') or
        v['unresolved'] is not True or
        v['last_status'] != ('streaming' if phase == 'write' else 'failed')):
        raise ValueError('Invalid transcript restart result')
    lease = v['lease']
    if (set(lease) != {'run_id', 'session_id', 'base_url', 'created_at'} or
        lease['run_id'] != 'run_1' or lease['session_id'] != OWNER['session'] or
        lease['base_url'] != OWNER['origin']):
        raise ValueError('Wrong durable run owner')
    datetime.datetime.fromisoformat(lease['created_at'])
    queries = {'/health': {}, '/v1/capabilities': {},
               '/api/sessions': {'limit': '50', 'offset': '0'},
               '/api/sessions/synthetic-reconnect/messages': {'limit': '500', 'offset': '0', 'order': 'latest'},
               '/v1/runs/run_1': {}, '/v1/runs/run_1/events': {}, '/v1/runs': {}}
    routes = set(queries) - {'/v1/runs', '/v1/runs/run_1/events'}
    posts = []
    for request in v['requests']:
        method, path, query = request['method'], request['path'], request['query']
        if (request['origin'] != OWNER['origin'] or query != queries.get(path) or
            set(request) != {'method', 'origin', 'path', 'query'} | ({'body'} if method == 'POST' else set()) or
            not (method == 'GET' and path in routes or
                 method == 'SSE' and path == '/v1/runs/run_1/events' or
                 phase == 'write' and method == 'POST' and path == '/v1/runs')):
            raise ValueError('Unexpected request or wrong owner')
        if method == 'POST':
            posts.append(request)
    if [r['path'] for r in posts] != v['mutations'] or (posts and posts[0]['body'] != {
        'session_id': OWNER['session'], 'input': 'Synthetic pending restart request',
        'message': 'Synthetic pending restart request'}):
        raise ValueError('Replay or wrong submission owner')
    reads = {r['path'] for r in v['requests'] if r['method'] == 'GET'}
    if ('/api/sessions/synthetic-reconnect/messages' not in reads or
        not any(r['method'] == 'SSE' for r in v['requests']) or
        phase == 'verify' and '/v1/runs/run_1' not in reads):
        raise ValueError('Missing canonical history or active owner recovery')
    return v


def validate_pair(first, second):
    if (first['phase'] != 'write' or second['phase'] != 'verify' or
        first['native_pid'] == second['native_pid'] or
        any(first[k] != second[k] for k in ('owner', 'canonical_ids', 'tools', 'width', 'text_scale', 'lease'))):
        raise ValueError('Not a distinct exact-owner restart')


def source_hashes(source):
    names = subprocess.check_output(['git', 'ls-files', '-z', '--cached', '--others', '--exclude-standard', '--', 'lib', 'test', 'integration_test',
        'linux', 'assets', 'scripts', 'pubspec.yaml', 'pubspec.lock', 'analysis_options.yaml', 'l10n.yaml'], cwd=source).decode().split('\0')
    return {name: digest(source / name) for name in names if name and (source / name).is_file()}


def bundle_hashes(bundle):
    return {str(path.relative_to(bundle)): digest(path)
            for path in sorted(bundle.rglob('*')) if path.is_file()}


def run(source):
    source = pathlib.Path(source).resolve()
    first = helper('direct_first_run_native')
    # Reuse the existing authenticated-display/process supervisor, not historical
    # Wing product sources or its retired source archive.
    supervisor = helper('desktop_no_inference_smoke')
    live, supervisor_hash = supervisor.predecessor(source)
    # All state and retained diagnostics live in task scratch, never a shared HOME.
    evidence = pathlib.Path(tempfile.mkdtemp(prefix='transcript-restart-', dir=os.environ['TMPDIR']))
    print('Evidence: ' + str(evidence), flush=True)
    result = {'status': 'FAIL', 'checks': [], 'live_agent': 'NOT_CHECKED', 'journeys': [],
              'supervisor_revision': supervisor.PREDECESSOR, 'supervisor_sha256': supervisor_hash}
    started = time.monotonic()
    try:
        inputs = source_hashes(source)
        (evidence / 'source.json').write_text(json.dumps({'base_revision': subprocess.check_output(
            ['git', 'rev-parse', 'HEAD'], cwd=source).decode().strip(), 'inputs': inputs}, indent=2))
        with live.owned_workspace(evidence) as root:
            env = first.isolated_environment(root)
            env.pop('WING_DIRECT_ROOT')
            env['WING_TRANSCRIPT_ROOT'] = str(root)
            vm_port = int(os.environ['AUTOWORK_PORT_BASE']) + 1
            env.update(FLUTTER_ENGINE_SWITCHES='1',
                       FLUTTER_ENGINE_SWITCH_1=f'vm-service-port={vm_port}')
            result['owned_vm_service_port'] = vm_port
            sdk = pathlib.Path(shutil.which('flutter')).resolve().parent.parent
            env['PATH'] = str(sdk / 'bin') + ':' + env['PATH']
            # Optional developer-provisioned sysroot, never installed by the launcher.
            cache = os.environ.get('AUTOWORK_CACHE')
            if cache:
                sysroot = pathlib.Path(cache) / 'linux-dev-noble-20261007/root/usr'
                if sysroot.is_dir():
                    env['PKG_CONFIG_PATH'] = str(sysroot / 'lib/x86_64-linux-gnu/pkgconfig')
                    env['LIBRARY_PATH'] = str(sysroot / 'lib/x86_64-linux-gnu')
            result['environment'] = {'uname': list(os.uname()),
                'sdk': subprocess.check_output([str(sdk / 'bin/flutter'), '--version'], timeout=30).decode(),
                'sdk_tools': {name: digest(sdk / name) for name in ('bin/cache/flutter_tools.snapshot', 'bin/cache/dart-sdk/bin/dart')},
                'dependency_inputs': {name: digest(source / name) for name in (
                    '.dart_tool/package_config.json', '.dart_tool/package_graph.json', '.flutter-plugins-dependencies')},
                'isolated_home_xdg': True, 'inherited_dbus': False}
            build_command = [str(sdk / 'bin/flutter'), 'build', 'linux', '--debug', '--no-pub',
                '-t', TARGET, '--dart-define=INTEGRATION_TEST_SHOULD_REPORT_RESULTS_TO_NATIVE=false']
            with (evidence / 'build.log').open('wb') as log:
                code, builder = live.run_owned(['bash', '-c', 'exec "$@" 2>&1', 'build', *build_command],
                    source, env, timeout=600, stdout=log)
            result['checks'].append({'command': build_command, 'exit': code,
                'builder_pid': builder, 'owned_group_gone': True})
            if code:
                raise ValueError('Native build failed; inspect build.log')
            bundle = source / 'build/linux/x64/debug/bundle'
            built_inputs = bundle_hashes(bundle)
            authority = root / 'cache/display-authority'
            live.display_authority(authority)
            env['XAUTHORITY'] = str(authority)
            deadline = time.monotonic() + 10
            class Finished(Exception):
                pass
            with tempfile.TemporaryFile(dir=root / 'cache') as output:
                def on_display(display_pid):
                    output.seek(0)
                    number = output.read(17)
                    if not re.fullmatch(rb'[0-9]{1,5}\n', number):
                        if time.monotonic() > deadline:
                            raise ValueError('Display startup failed')
                        return
                    env['DISPLAY'] = ':' + number.decode().strip()
                    live.admit_display(root, env)
                    result['display'] = {'pid': display_pid, 'authenticated': True,
                                         'wrong_missing_authority_rejected': True}
                    binaries = []
                    for phase in ('write', 'verify'):
                        env['WING_TRANSCRIPT_PHASE'] = phase
                        observed = {}
                        paths = [root / 'cache' / f'transcript-{w}-{s}-{phase}.json'
                                 for w in (390.0, 1280.0) for s in (1.0, 2.0)]
                        if any(p.exists() for p in paths):
                            raise ValueError('Stale phase receipt')
                        def on_native(driver):
                            for path in paths:
                                if not path.exists():
                                    continue
                                value = read_receipt(path)
                                checksum = digest(path)
                                if path.name in observed:
                                    if observed[path.name]['sha256'] != checksum:
                                        raise ValueError('Native receipt changed')
                                    continue
                                fields = pathlib.Path('/proc', str(value['native_pid']), 'stat').read_text().rsplit(')', 1)[1].split()
                                exe = pathlib.Path('/proc', str(value['native_pid']), 'exe').resolve()
                                binary = source / 'build/linux/x64/debug/bundle/wing'
                                if (int(fields[2]) != driver or fields[0] == 'Z' or driver != value['native_pid'] or
                                    exe != binary or digest(exe) != digest(binary)):
                                    raise ValueError('GTK process not driver-owned matching build')
                                observed[path.name] = {'sha256': checksum, 'driver_pid': driver,
                                    'start_ticks': fields[19], 'binary_sha256': digest(exe)}
                                shutil.copyfile(path, evidence / path.name)
                        # Launch the SAME built Dart payload twice. Recompiling a
                        # flutter-test bootstrap per phase changes its kernel.
                        command = [str(bundle / 'wing')]
                        tick = time.monotonic()
                        with (evidence / f'{phase}.log').open('wb') as log:
                            code, driver = live.run_owned(['bash', '-c', 'exec "$@" 2>&1', 'transcript', *command],
                                source, env, timeout=600, stdout=log, observe=on_native)
                        result['checks'].append({'command': command, 'phase': phase, 'exit': code,
                            'driver_pid': driver, 'owned_group_gone': True, 'duration_seconds': round(time.monotonic() - tick, 3)})
                        if code or len(observed) != 4 or not live.live_group(display_pid):
                            raise ValueError('Incomplete native phase; inspect log')
                        ports = re.findall(r'Dart VM service is listening on http://127\.0\.0\.1:([0-9]+)/',
                                           (evidence / f'{phase}.log').read_text())
                        if ports != [str(vm_port)]:
                            raise ValueError('VM service left the task-owned port range')
                        terminal_path = root / 'cache' / f'transcript-{phase}-terminal.json'
                        terminal = json.loads(terminal_path.read_text())
                        if terminal != {'phase': phase, 'native_pid': driver, 'passed': True, 'tests': 1}:
                            raise ValueError('Missing native terminal test receipt')
                        shutil.copyfile(terminal_path, evidence / terminal_path.name)
                        rows = [read_receipt(path) | observed[path.name] for path in paths]
                        if len({r['native_pid'] for r in rows}) != 1:
                            raise ValueError('Unexpected phase process replacement')
                        if phase == 'verify':
                            for before, after in zip(result['journeys'], rows):
                                validate_pair(before, after)
                            if driver == result['checks'][-2]['driver_pid']:
                                raise ValueError('Driver was not restarted')
                        result['journeys'].extend(rows)
                        binary_inputs = bundle_hashes(bundle)
                        if (binary_inputs != built_inputs or
                            'data/flutter_assets/kernel_blob.bin' not in binary_inputs or 'wing' not in binary_inputs):
                            raise ValueError('Incomplete debug application bundle')
                        (evidence / f'{phase}-bundle.json').write_text(json.dumps(binary_inputs, indent=2))
                        binaries.append(binary_inputs)
                        if source_hashes(source) != inputs:
                            raise ValueError('Executed source drift')
                    if binaries[0] != binaries[1]:
                        raise ValueError('Restart build drift')
                    result['native_binary_sha256'] = binaries[0]['wing']
                    result['native_bundle_manifest_sha256'] = digest(evidence / 'write-bundle.json')
                    result['native_bundle_files'] = len(binaries[0])
                    raise Finished()
                try:
                    live.run_owned(['/usr/bin/Xvfb', '-displayfd', '1', '-screen', '0', '1440x1000x24',
                        '-nolisten', 'tcp', '-auth', str(authority)], source, env, timeout=1250, stdout=output, observe=on_display)
                except Finished:
                    result['display']['owned_group_gone'] = True
                else:
                    raise ValueError('Display exited before qualification')
            result['status'] = 'NATIVE_TRANSCRIPT_RESTART_PASS'
        result['isolated_state_deleted_after_teardown'] = True
    except Exception as error:
        result['failure'] = str(error)
        raise
    finally:
        result['duration_seconds'] = round(time.monotonic() - started, 3)
        (evidence / 'verification.json').write_text(json.dumps(result, indent=2))
    return result


def main(argv=None):
    argv = sys.argv[1:] if argv is None else argv
    if argv:
        print(json.dumps({'status': 'NO_ARGUMENTS_OR_CREDENTIALS_ACCEPTED'}))
        return 2
    result = run(pathlib.Path(__file__).resolve().parents[2])
    print(json.dumps({k: result[k] for k in ('status', 'duration_seconds', 'isolated_state_deleted_after_teardown')}))
    return 0


if __name__ == '__main__':
    sys.exit(main())
