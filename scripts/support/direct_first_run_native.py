"""Isolated credential-free GTK first-run qualification; no live admission."""
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

CARD = 't_95a5ae74'
OWNED = (
    'integration_test/linux_direct_first_run_test.dart',
    'integration_test/support/direct_first_run_native_fixture.dart',
    'scripts/run_linux_direct_first_run.sh',
    'scripts/support/direct_first_run_native.py',
    'test/tooling/direct_first_run_native_test.py',
)
ROUTES = {'/health', '/v1/capabilities', '/api/profiles', '/api/sessions',
          '/api/sessions/synthetic-history', '/api/sessions/synthetic-history/messages'}


def helpers():
    path = pathlib.Path(__file__).with_name('desktop_no_inference_smoke.py')
    spec = importlib.util.spec_from_file_location('first_run_snapshot_helpers', path)
    if spec is None or spec.loader is None:
        raise ValueError('Snapshot helper unavailable')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def freeze(source, app):
    helper = helpers()
    helper.CARD = CARD
    helper.OWNED = ()
    helper.OVERLAYS = ()
    helper.ROOTS = ('lib', 'test', 'integration_test', 'assets', 'linux',
                    'wing_link', 'scripts', 'playwright/support')
    identity = helper.freeze(source, app)
    for name, row in identity['inputs'].items():
        row['owner'] = CARD if name in OWNED else 'preexisting-worktree'
    identity['reference_dependency'] = '046267501ae884fde73e5a0ea1dae02353d5c8c8'
    return identity


def isolated_environment(root):
    # Never inherit credentials, DISPLAY, HOME, DBus, proxy settings or Agent state.
    env = {k: os.environ[k] for k in ('PATH', 'LANG', 'PKG_CONFIG_PATH',
           'CMAKE_PREFIX_PATH', 'LIBRARY_PATH', 'CPATH') if k in os.environ}
    for name in ('home', 'config', 'data', 'cache', 'runtime'):
        (root / name).mkdir(mode=0o700)
    env.update(HOME=str(root / 'home'), XDG_CONFIG_HOME=str(root / 'config'),
               XDG_DATA_HOME=str(root / 'data'), XDG_CACHE_HOME=str(root / 'cache'),
               XDG_RUNTIME_DIR=str(root / 'runtime'), TMPDIR=str(root / 'cache'),
               WING_DIRECT_ROOT=str(root), GDK_BACKEND='x11',
               LIBGL_ALWAYS_SOFTWARE='1', CMAKE_BUILD_PARALLEL_LEVEL='2',
               PUB_CACHE=os.environ.get('PUB_CACHE', str(pathlib.Path.home() / '.pub-cache')),
               GOMODCACHE=subprocess.check_output(['go', 'env', 'GOMODCACHE'], timeout=30).decode().strip(),
               GOMAXPROCS='2', GOFLAGS='-p=2', GOPROXY='off', GOSUMDB='off',
               GOTOOLCHAIN='local', GOCACHE=str(root / 'cache/go-build'))
    return env


def read_receipt(path):
    if path.is_symlink() or path.stat().st_size > 32768:
        raise ValueError('Invalid native receipt file')
    value = json.loads(path.read_text())
    booleans = ('public_entry', 'optional_pairing_reachable', 'back_no_save',
                'pending_owner_fenced', 'denial_sanitized', 'explicit_keyboard_retry', 'agent_only_save')
    if (type(value['native_pid']) is not int or value['native_pid'] <= 0 or
            value['width'] not in (390.0, 1280.0) or value['text_scale'] not in (1.0, 2.0) or
            not all(value[k] is True for k in booleans) or
            value['keyboard_modes'] != ['local', 'ssh', 'remote', 'vpn'] or
            value['profile'] != 'synthetic-qa' or value['session'] != 'synthetic-history' or
            any(type(value[k]) is not int or value[k] != 0 for k in ('management_attempts', 'mutation_attempts', 'forbidden_read_attempts')) or
            not value['requests'] or any(r['method'] != 'GET' or r['path'] not in ROUTES or
                                       set(r) != {'method', 'path', 'query'} or
                                       not set(r['query']) <= {'profile', 'limit', 'offset', 'order'}
                                       for r in value['requests']) or
            value['denied_reads'] != [{'status': 401, 'path': '/v1/capabilities', 'profile': None}]):
        raise ValueError('Invalid direct first-run result')
    return value


def run(source):
    source = pathlib.Path(source).resolve()
    evidence_root = source / 'build' / CARD
    evidence_root.mkdir(parents=True, exist_ok=True)
    evidence = pathlib.Path(tempfile.mkdtemp(prefix='attempt-', dir=evidence_root))
    helper = helpers()
    live, helper_hash = helper.predecessor(source)
    result = {'status': 'FAIL', 'checks': [], 'live_authentication': 'NOT_CHECKED',
              'predecessor_runtime_helper_sha256': helper_hash}
    started = time.monotonic()
    try:
        with live.owned_workspace(evidence) as root:
            app, sdk = root / 'app', root / 'flutter'
            identity = freeze(source, app)
            (evidence / 'source.json').write_text(json.dumps(identity, indent=2))
            result['source_archive'] = helper.retain_candidate(app, evidence, identity)
            executable = shutil.which('flutter')
            if executable is None:
                raise ValueError('Flutter unavailable')
            live.prepare_packages(source, app, pathlib.Path(executable).resolve().parent.parent, sdk)
            env = isolated_environment(root)
            # Hash local transitive package source, not only the package configuration.
            dependencies = {}
            for package in json.loads((app / '.dart_tool/package_config.json').read_text())['packages']:
                from urllib.parse import urlsplit, unquote
                directory = pathlib.Path(unquote(urlsplit(package['rootUri']).path))
                if directory == app:
                    continue
                dependencies[package['name']] = {
                    str(p.relative_to(directory)): helper.digest(p)
                    for p in sorted(directory.rglob('*'))
                    if p.is_file() and not p.is_symlink() and p.suffix in
                    ('.dart', '.h', '.c', '.cc', '.cpp', '.cmake', '.yaml')
                }
            (evidence / 'dependencies.json').write_text(json.dumps(dependencies, indent=2))
            result['environment'] = {
                'uname': list(os.uname()),
                'sdk': subprocess.check_output([str(sdk / 'bin/flutter'), '--version'], env=env, timeout=30).decode(),
                'dependency_manifest_sha256': helper.digest(evidence / 'dependencies.json'),
                'package_config_sha256': helper.digest(app / '.dart_tool/package_config.json'),
                'plugins_sha256': helper.digest(app / '.flutter-plugins-dependencies'),
                'prerequisite_archives': {p.name: helper.digest(p) for p in sorted((evidence_root / 'deps/downloads').glob('*.deb'))},
                'pkg_config_versions': subprocess.check_output(['pkg-config', '--modversion', 'gtk+-3.0', 'gstreamer-1.0',
                    'gstreamer-app-1.0', 'gstreamer-audio-1.0', 'libsecret-1'], env=env, timeout=30).decode(),
                'isolated_home_xdg': True, 'inherited_dbus': False,
                'bounded_build_parallelism': 2,
            }
            commands = [
                ['python3', '-B', '-m', 'unittest', 'discover', '-s', 'test/tooling', '-p', 'direct_first_run_native_test.py'],
                ['bash', '-n', 'scripts/run_linux_direct_first_run.sh'],
                [str(sdk / 'bin/dart'), 'format', '--output=none', '--set-exit-if-changed', *OWNED[:2]],
                [str(sdk / 'bin/flutter'), 'analyze', '--no-pub'],
                [str(sdk / 'bin/flutter'), 'test', '--no-pub', '--concurrency=1',
                 'test/features/enrollment/hermes_direct_first_run_test.dart',
                 'test/features/hermes_chat/screens/hermes_connection_primary_entry_test.dart',
                 'test/features/hermes_chat/screens/hermes_chat_screen_auth_recovery_test.dart'],
            ]
            def check(command, index, observe=None, timeout=300):
                tick = time.monotonic()
                with (evidence / f'check-{index}.log').open('wb') as log:
                    code, driver = live.run_owned(['bash', '-c', 'exec "$@" 2>&1', 'direct', *command], app, env,
                                                 timeout=timeout, stdout=log, observe=observe)
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
                    def on_native(driver):
                        for path in sorted((root / 'cache').glob('direct-*.json')):
                            value = read_receipt(path)
                            checksum = helper.digest(path)
                            if path.name in observed:
                                if observed[path.name]['sha256'] != checksum:
                                    raise ValueError('Native receipt changed')
                                continue
                            fields = pathlib.Path('/proc', str(value['native_pid']), 'stat').read_text().rsplit(')', 1)[1].split()
                            if int(fields[2]) != driver or fields[0] == 'Z' or driver == value['native_pid']:
                                raise ValueError('Native GTK process not driver-owned')
                            observed[path.name] = {'sha256': checksum, 'driver_pid': driver,
                                'start_ticks': fields[19], 'executable': pathlib.Path('/proc', str(value['native_pid']), 'exe').resolve().name}
                    command = [str(sdk / 'bin/flutter'), 'test', '--no-pub', '--concurrency=1', '-d', 'linux', OWNED[0]]
                    check(command, 'native', observe=on_native, timeout=600)
                    expected = {f'direct-{width}-{scale}.json' for width in (390.0, 1280.0) for scale in (1.0, 2.0)}
                    if set(observed) != expected or not live.live_group(display_pid):
                        raise ValueError('Incomplete GTK coverage or missing display')
                    result['journeys'] = []
                    for name in sorted(expected):
                        path = root / 'cache' / name
                        result['journeys'].append(read_receipt(path) | observed[name])
                        shutil.copyfile(path, evidence / name)
                    for path in (root / 'cache').glob('*.png'):
                        shutil.copyfile(path, evidence / path.name)
                    renders = {p.name: helper.digest(p) for p in evidence.glob('*.png')}
                    if len(renders) != 12 or len(set(renders.values())) < 3:
                        raise ValueError('Missing or unchanged native renders')
                    result['renders'] = renders
                    raise Finished()
                try:
                    live.run_owned(['/usr/bin/Xvfb', '-displayfd', '1', '-screen', '0', '1440x1000x24', '-nolisten', 'tcp', '-auth', str(authority)],
                                   app, env, timeout=700, stdout=output, observe=on_display)
                except Finished:
                    result['display']['owned_group_gone'] = True
                else:
                    raise ValueError('Display exited before native qualification')
            hashes = {name: helper.digest(app / name) for name in helper.candidate_hashes(identity)}
            if hashes != helper.candidate_hashes(identity):
                raise ValueError('Executed source changed')
            result['executed_input_hashes'] = hashes
            result['status'] = 'NATIVE_DIRECT_FIRST_RUN_PASS'
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
