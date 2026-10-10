"""Source-bound synthetic GTK integrated restart; never admits live credentials."""

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


CARD = 't_e168b601'
OWNED = (
    'integration_test/linux_integrated_daily_restart_test.dart',
    'integration_test/support/integrated_daily_restart_fixture.dart',
    'scripts/run_linux_integrated_daily_restart.sh',
    'scripts/support/integrated_daily_restart_native.py',
    'test/tooling/integrated_daily_restart_native_test.py',
)
def helpers():
    path = pathlib.Path(__file__).with_name('direct_first_run_native.py')
    spec = importlib.util.spec_from_file_location('transcript_first', path)
    if spec is None or spec.loader is None:
        raise ValueError('Snapshot helper unavailable')
    first = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(first)
    snapshot = first.helpers()
    return first, snapshot


def read_receipt(path):
    if path.is_symlink() or path.stat().st_size > 32768:
        raise ValueError('Invalid receipt file')
    v = json.loads(path.read_text())
    phase = v['phase']
    session = 'synthetic-off-page'
    expected = ([f'/api/sessions/{session}/model', '/v1/runs',
                 '/v1/runs/run_1/approval', '/v1/runs', '/v1/runs/run_2/stop']
                if phase == 'write' else [f'/api/sessions/{session}/model', '/v1/runs'])
    trace = v['mutations']
    phases = (['explicit-off-page-selection', 'correlated-approval',
               'uncertain-stop-blocks-send', 'terminal-canonical-recovered']
              if phase == 'write' else ['exact-restored-no-replay', 'explicit-reselection-resumed-send'])
    if (phase not in ('write', 'verify') or type(v['native_pid']) is not int or v['native_pid'] <= 0 or
        v['width'] not in (390.0, 1280.0) or v['text_scale'] != 2.0 or
        v['profile'] != 'synthetic-qa' or v['session'] != session or v['phases'] != phases or
        any(type(v[k]) is not int or v[k] != 0 for k in ('restore_mutations', 'leave_mutations')) or
        v['late_owner_fenced'] is not (phase == 'write') or not v['focus'] or
        [r['path'] for r in trace] != expected or
        any(r['method'] != 'POST' or r['profile'] != 'synthetic-qa' for r in trace) or
        trace[0]['body'] != {'provider': 'synthetic', 'model': 'synthetic/model'} or
        v['canonical_ids'] != ['canonical_run_1', 'canonical_run_2'] + (['canonical_run_3'] if phase == 'verify' else [])):
        raise ValueError('Invalid integrated restart result')
    sends = [r['body'] for r in trace if r['path'] == '/v1/runs']
    messages = (['Synthetic deliberate approval prompt', 'Synthetic deliberate Stop prompt']
                if phase == 'write' else ['Synthetic deliberate resumed prompt'])
    if ([r.get('message') for r in sends] != messages or
        any(r.get('session_id') != session for r in sends) or
        (phase == 'write' and trace[2]['body'] != {'request_id': 'approval_run_1', 'choice': 'once'})):
        raise ValueError('Wrong mutation owner or replay')
    requests = v['requests']
    routes = {'/health', '/v1/capabilities', '/api/profiles', '/api/sessions', '/api/model/options',
              f'/api/sessions/{session}', f'/api/sessions/{session}/messages',
              '/api/sessions/synthetic-first/messages'} | set(expected)
    routes |= {f'/v1/runs/run_{n}' + suffix for n in range(1, 4) for suffix in ('', '/events')}
    if (not requests or any(r['method'] not in ('GET', 'POST') or r['path'] not in routes for r in requests) or
        not any(r['path'] == '/api/sessions' and r.get('returned_ids') == ['synthetic-first'] for r in requests) or
        not any(r['path'] == f'/api/sessions/{session}/messages' and r['profile'] == 'synthetic-qa' for r in requests) or
        (phase == 'verify' and not any(r['path'] == f'/api/sessions/{session}' and r['profile'] == 'synthetic-qa' for r in requests)) or
        (phase == 'write' and not any(r['path'] == '/v1/runs/run_2' for r in requests))):
        raise ValueError('Missing exact canonical/off-page recovery reads')
    return v


def freeze(source, app, snapshot):
    snapshot.CARD = CARD
    snapshot.OWNED = ()
    snapshot.OVERLAYS = ()
    snapshot.ROOTS = ('lib', 'test', 'integration_test', 'assets', 'linux',
                      'wing_link', 'scripts', 'playwright/support', 'docs', 'android', 'ios', 'macos', 'windows', 'web')
    snapshot.FILES += ('package.json', 'package-lock.json')
    identity = snapshot.freeze(source, app)
    for name, row in identity['inputs'].items():
        row['owner'] = CARD if name in OWNED else 'preexisting-worktree'
    identity['reference_dependency'] = 'current dirty Wing worktree, not main delivery'
    identity['predecessor_commits'] = ['b832870d6205acede576c1427424fff3abc26be0', snapshot.PREDECESSOR]
    identity['excluded'].append('personal credentials and provider generation')
    return identity


def retry_helpers():
    path = pathlib.Path(__file__).with_name('remote_connection_retry_native.py')
    spec = importlib.util.spec_from_file_location('saved_edit_retry_helpers', path)
    if spec is None or spec.loader is None:
        raise ValueError('Read-only retry helper unavailable')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def run(source):
    source = pathlib.Path(source).resolve()
    first, snapshot = helpers()
    snapshot.CARD = CARD
    live, helper_hash = snapshot.predecessor(source)
    evidence_root = source / 'build' / CARD / 'evidence'
    evidence_root.mkdir(parents=True, exist_ok=True)
    evidence = pathlib.Path(tempfile.mkdtemp(prefix='attempt-', dir=evidence_root))
    result = {'status': 'FAIL', 'checks': [], 'live_authentication': 'NOT_CHECKED',
              'physical_keychain': 'NOT_CHECKED', 'runtime_helper_sha256': helper_hash}
    started = time.monotonic()
    try:
        raw = subprocess.check_output(['git', 'show', snapshot.PREDECESSOR + ':scripts/support/desktop_live_workflow.py'], cwd=source, timeout=30)
        (evidence / 'executed-runtime-helper.py').write_bytes(raw)
        with live.owned_workspace(evidence) as root:
            app, sdk = root / 'app', root / 'flutter'
            identity = freeze(source, app, snapshot)
            (evidence / 'source.json').write_text(json.dumps(identity, indent=2))
            # These owned paths are new. Keep their additive delta separate from
            # inherited editor/launcher inputs, even when the worktree is dirty.
            patch = b''
            for name in OWNED:
                delta = subprocess.run(['git', 'diff', '--no-index', '--', '/dev/null', name],
                                       cwd=source, capture_output=True, timeout=30)
                if delta.returncode != 1:
                    raise ValueError('Task delta capture failed')
                patch += delta.stdout
            (evidence / 'baseline-to-task.patch').write_bytes(patch)
            result['source_archive'] = snapshot.retain_candidate(app, evidence, identity)
            executable = shutil.which('flutter')
            if executable is None:
                raise ValueError('Flutter unavailable')
            live.prepare_packages(source, app, pathlib.Path(executable).resolve().parent.parent, sdk)
            result['dependencies'] = retry_helpers().dependencies(app, sdk, evidence, snapshot)
            env = first.isolated_environment(root)
            env.pop('WING_DIRECT_ROOT')
            for name in ('PKG_CONFIG_PATH', 'LIBRARY_PATH', 'CPATH', 'CMAKE_PREFIX_PATH'):
                env.pop(name, None)
            sysroot = evidence_root.parent / 'deps/sysroot'
            env['PKG_CONFIG_PATH'] = str(sysroot / 'usr/lib/x86_64-linux-gnu/pkgconfig')
            env['LIBRARY_PATH'] = str(sysroot / 'usr/lib/x86_64-linux-gnu')
            env['WING_INTEGRATED_ROOT'] = str(root)
            result['go_dependencies'] = retry_helpers().go_dependencies(app, root, evidence, env, snapshot)
            prepared_hashes = {name: snapshot.digest(app / name)
                               for name in snapshot.candidate_hashes(identity)}
            if prepared_hashes != snapshot.candidate_hashes(identity):
                result['changed_prepared_inputs'] = [name for name, checksum in prepared_hashes.items()
                    if checksum != snapshot.candidate_hashes(identity)[name]]
                raise ValueError('Dependency preparation changed source')
            result['environment'] = {
                'uname': list(os.uname()),
                'sdk': subprocess.check_output([str(sdk / 'bin/flutter'), '--version'], env=env, timeout=30).decode(),
                'sdk_binary_hashes': {name: snapshot.digest(sdk / name) for name in (
                    'bin/cache/dart-sdk/bin/dart', 'bin/cache/flutter_tools.snapshot',
                    'bin/cache/artifacts/engine/linux-x64/flutter_tester',
                    'bin/cache/artifacts/engine/linux-x64/libflutter_linux_gtk.so')},
                'pkg_config_versions': subprocess.check_output(['pkg-config', '--modversion', 'gtk+-3.0', 'gstreamer-1.0',
                    'gstreamer-app-1.0', 'gstreamer-audio-1.0', 'libsecret-1'], env=env, timeout=30).decode(),
                'isolated_home_xdg': True, 'inherited_dbus': False, 'bounded_build_parallelism': 2,
                'prerequisite_archives': {p.name: snapshot.digest(p) for p in sorted((evidence_root.parent / 'deps/downloads').glob('*.deb'))},
                'sysroot_hashes': {str(p.relative_to(sysroot)): snapshot.digest(p)
                    for p in sorted(sysroot.rglob('*')) if p.is_file() and not p.is_symlink()},
                'tools': {name: snapshot.digest(pathlib.Path('/usr/bin') / name)
                    for name in ('Xvfb', 'import', 'pkg-config')},
            }
            commands = [
                ['python3', '-B', '-m', 'unittest', 'discover', '-s', 'test/tooling', '-p', 'integrated_daily_restart_native_test.py'],
                ['bash', '-n', OWNED[2]],
                [str(sdk / 'bin/dart'), 'format', '--output=none', '--set-exit-if-changed', *OWNED[:2]],
                [str(sdk / 'bin/flutter'), 'analyze', '--no-pub'],
                ['npm', 'run', 'test', '--', '--no-pub', '--concurrency=1',
                 'test/core/hermes/channel/hermes_api_channel_test.dart',
                 'test/features/hermes_chat/gateways/hermes_gateway_session_restoration_test.dart',
                 'test/features/hermes_chat/gateways/hermes_gateway_restoration_adversarial_test.dart',
                 'test/features/hermes_chat/messaging/approvals/hermes_approval_profile_owner_test.dart'],
            ]
            def check(command, index, observe=None, timeout=300):
                tick = time.monotonic()
                command_env = env | {'PATH': str(sdk / 'bin') + ':' + env['PATH']}
                with (evidence / f'check-{index}.log').open('wb') as log:
                    code, driver = live.run_owned(['bash', '-c', 'exec "$@" 2>&1', 'retry', *command],
                        app, command_env, timeout=timeout, stdout=log, observe=observe)
                result['checks'].append({'command': command, 'exit': code,
                    'duration_seconds': round(time.monotonic() - tick, 3), 'owned_group_gone': True})
                if code:
                    raise ValueError('Scoped check failed; inspect check log')
                return driver
            for index, command in enumerate(commands):
                check(command, index)
            authority = root / 'cache/display-authority'
            live.display_authority(authority)
            env['XAUTHORITY'] = str(authority)
            deadline = time.monotonic() + 10
            observed = {}
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
                    result['display'] = {'authenticated': True, 'wrong_missing_authority_rejected': True}
                    result['journeys'] = []
                    for width in (390.0, 1280.0):
                        journey = root / f'journey-{width}'
                        journey.mkdir()
                        for name in ('home', 'config', 'data', 'cache', 'runtime'):
                            (journey / name).mkdir(mode=0o700)
                        env.update(HOME=str(journey / 'home'), XDG_CONFIG_HOME=str(journey / 'config'),
                                   XDG_DATA_HOME=str(journey / 'data'), XDG_CACHE_HOME=str(journey / 'cache'),
                                   XDG_RUNTIME_DIR=str(journey / 'runtime'), TMPDIR=str(journey / 'cache'),
                                   WING_INTEGRATED_ROOT=str(journey), WING_INTEGRATED_WIDTH=str(width))
                        for phase in ('write', 'verify'):
                            env['WING_INTEGRATED_PHASE'] = phase
                            path = journey / 'cache' / f'integrated-{width}-{phase}.json'
                            def on_native(driver):
                                for image in (journey / 'cache').glob('*.png'):
                                    shutil.copyfile(image, evidence / image.name)
                                if not path.exists():
                                    return
                                shutil.copyfile(path, evidence / path.name)
                                value = read_receipt(path)
                                checksum = snapshot.digest(path)
                                if path.name in observed:
                                    if observed[path.name]['sha256'] != checksum:
                                        raise ValueError('Native receipt changed')
                                    return
                                fields = pathlib.Path('/proc', str(value['native_pid']), 'stat').read_text().rsplit(')', 1)[1].split()
                                if int(fields[2]) != driver or fields[0] == 'Z' or driver == value['native_pid']:
                                    raise ValueError('GTK process not driver-owned')
                                observed[path.name] = {'sha256': checksum, 'driver_pid': driver,
                                    'start_ticks': fields[19], 'executable': pathlib.Path('/proc', str(value['native_pid']), 'exe').resolve().name}
                            check([str(sdk / 'bin/flutter'), 'test', '--no-pub', '--concurrency=1', '-d', 'linux', OWNED[0]],
                                  f'native-{width}-{phase}', observe=on_native, timeout=480)
                            result['journeys'].append(read_receipt(path) | observed[path.name])
                        if result['journeys'][-1]['native_pid'] == result['journeys'][-2]['native_pid']:
                            raise ValueError('Process restart not observed')
                        if not live.live_group(display_pid):
                            raise ValueError('Display exited between processes')
                    renders = {p.name: snapshot.digest(p) for p in evidence.glob('*.png')}
                    if len(renders) != 14 or len(set(renders.values())) < 3:
                        raise ValueError('Missing or unchanged renders')
                    for width in (390.0, 1280.0):
                        if renders[f'integrated-{width}-write-focus.png'] == renders[f'integrated-{width}-write-unfocused.png']:
                            raise ValueError('Rendered keyboard focus unchanged')
                    result['renders'] = renders
                    raise Finished()
                try:
                    live.run_owned(['/usr/bin/Xvfb', '-displayfd', '1', '-screen', '0', '1440x1000x24', '-nolisten', 'tcp', '-auth', str(authority)],
                                   app, env, timeout=1600, stdout=output, observe=on_display)
                except Finished:
                    result['display']['owned_group_gone'] = True
                else:
                    raise ValueError('Display exited before qualification')
            hashes = {name: snapshot.digest(app / name) for name in snapshot.candidate_hashes(identity)}
            result['executed_input_hashes'] = hashes
            if hashes != snapshot.candidate_hashes(identity):
                raise ValueError('Executed source changed')
            retry_helpers().verify_go_dependencies(root, evidence, snapshot)
            result['native_binary_sha256'] = snapshot.digest(app / 'build/linux/x64/debug/bundle/wing')
            result['linked_libraries'] = subprocess.check_output(['ldd', str(app / 'build/linux/x64/debug/bundle/wing')], env=env, timeout=30).decode()
            if any(snapshot.digest(sysroot / name) != value for name, value in result['environment']['sysroot_hashes'].items()):
                raise ValueError('Prerequisite source drift')
            result['status'] = 'NATIVE_INTEGRATED_RESTART_PASS'
        result['isolated_state_deleted_after_teardown'] = True
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
    print(json.dumps({k: result[k] for k in ('status', 'duration_seconds', 'live_authentication', 'isolated_state_deleted_after_teardown')}))
    return 0


if __name__ == '__main__':
    sys.exit(main())
