"""Two-host GTK qualification; reuses the isolated predecessor launcher closure."""
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

CARD = 't_e40e9669'
OWNED = (
    'integration_test/linux_two_host_recovery_test.dart',
    'integration_test/support/two_host_recovery_native_fixture.dart',
    'scripts/run_linux_two_host_recovery.sh',
    'scripts/support/two_host_recovery_native.py',
    'test/tooling/two_host_recovery_native_test.py',
    'test/features/hermes_chat/screens/hermes_chat_two_host_recovery_test.dart',
    'docs/quality/two-host-recovery-native.md',
)
DART_FILES = (OWNED[0], OWNED[1], OWNED[5])
PRODUCTION = 'lib/features/hermes_chat/screens/widgets/hermes_chat_error.dart'


def prerequisites():
    path = pathlib.Path(__file__).with_name('remote_connection_retry_native.py')
    spec = importlib.util.spec_from_file_location('two_host_prerequisites', path)
    if spec is None or spec.loader is None:
        raise ValueError('Remote retry prerequisites unavailable')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


shared = prerequisites()
dependencies = shared.dependencies
go_dependencies = shared.go_dependencies
verify_go_dependencies = shared.verify_go_dependencies


def helpers():
    first, snapshot = shared.helpers()
    snapshot.CARD = CARD
    snapshot.ROOTS = (*snapshot.ROOTS[:-1], 'playwright', 'web')
    snapshot.FILES = (*snapshot.FILES, 'package.json', 'package-lock.json', 'playwright.config.mjs')
    snapshot.EXCLUDED_NAMES |= {'results.json', 'test-results', 'playwright-report'}
    return first, snapshot


def freeze(source, app, snapshot, baseline=None):
    if baseline is None:
        identity = snapshot.freeze(source, app)
    else:
        import hashlib
        import tarfile
        app.mkdir()
        identity = None
        inherited = {}
        archives = []
        for folder in (baseline, baseline.with_name('frozen-web-inputs')):
            manifest = json.loads((folder / 'source.json').read_text())
            if identity is None:
                identity = manifest
            archive = folder / 'executed-source.tar.gz'
            archives.append({'sha256': snapshot.digest(archive), 'name': folder.name})
            with tarfile.open(archive) as bundle:
                for name, row in manifest['inputs'].items():
                    if name in inherited:
                        continue
                    if folder != baseline and not (
                            name.startswith(('web/', 'playwright/')) or
                            name in ('package.json', 'package-lock.json', 'playwright.config.mjs')):
                        continue
                    relative = pathlib.PurePosixPath(name)
                    if relative.is_absolute() or '..' in relative.parts or str(relative) != name:
                        raise ValueError('Invalid frozen input path')
                    member = bundle.getmember(name)
                    if not member.isfile():
                        raise ValueError('Non-file frozen input')
                    stream = bundle.extractfile(member)
                    if stream is None:
                        raise ValueError('Missing frozen input')
                    with stream:
                        raw = stream.read()
                    if hashlib.sha256(raw).hexdigest() != row['sha256']:
                        raise ValueError('Frozen input checksum changed')
                    target = app / name
                    target.parent.mkdir(parents=True, exist_ok=True)
                    target.write_bytes(raw)
                    target.chmod(member.mode)
                    inherited[name] = dict(row)
        assert identity is not None
        identity['inputs'] = inherited
        identity['reviewed_overlays'] = {}
        identity['inherited_archives'] = archives
        for name in OWNED:
            original = source / name
            if not original.is_file():
                continue
            target = app / name
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(original.read_bytes())
            target.chmod(original.stat().st_mode & 0o777)
            identity['inputs'][name] = {'sha256': snapshot.digest(target), 'dirty': True}
        target = app / PRODUCTION
        original = target.read_text()
        old = "return lowerCaseError.contains('socketexception') ||"
        if original.count(old) != 1:
            raise ValueError('Network predicate baseline changed')
        target.write_text(original.replace(old,
            "return lowerCaseError.contains('hermes api network connection failed') ||\n"
            "      lowerCaseError.contains('socketexception') ||"))
        identity['inputs'][PRODUCTION]['sha256'] = snapshot.digest(target)
    for name, row in identity['inputs'].items():
        row['owner'] = CARD if name in OWNED else 'preexisting-worktree'
    identity['owned_hunks'] = {
        PRODUCTION: 'Recognize canonical HermesApiTransportException network text; other bytes inherited.'}
    return identity


def read_receipt(path):
    if path.is_symlink() or path.stat().st_size > 65536:
        raise ValueError('Invalid receipt file')
    value = json.loads(path.read_text())
    cases = [{'reject': reject, 'cancelled': True, 'replacement_preserved': True}
             for reject in (False, True)]
    routes = {'/health', '/v1/capabilities', '/api/profiles', '/api/sessions',
              '/api/sessions/synthetic-history/messages'}
    if (type(value['native_pid']) is not int or value['native_pid'] <= 0 or
            value['width'] not in (390.0, 1280.0) or value['text_scale'] not in (1.0, 2.0) or
            any(value[k] is not True for k in ('public_saved_selection', 'keyboard_retry',
                'same_id_return_fenced', 'idle_no_reconnect', 'saved_connected_distinct')) or
            value['profile'] != 'synthetic-qa' or value['session'] != 'synthetic-history' or
            value['physical_keychain'] != 'NOT_CHECKED' or value['late_cases'] != cases or
            any(type(value[k]) is not int or value[k] != 0 for k in
                ('management_attempts', 'mutation_attempts', 'forbidden_read_attempts')) or
            not value['requests'] or any(set(r) != {'owner', 'method', 'path', 'query'} or
                r['owner'] not in ('A', 'B') or r['method'] != 'GET' or r['path'] not in routes or
                not set(r['query']) <= {'profile', 'limit', 'offset', 'order'} or
                (r['path'].startswith('/api/sessions') and r['query'].get('profile') not in ('default', 'synthetic-qa'))
                for r in value['requests']) or
            {r['owner'] for r in value['requests']} != {'A', 'B'} or
            not value['retry_requests'] or
            any(r['owner'] != 'B' or r not in value['requests'] for r in value['retry_requests']) or
            value['retry_connects'] != 1 or
            sum(r['path'] == '/health' for r in value['retry_requests']) != 2 or
            sum(r['path'].endswith('/messages') for r in value['retry_requests']) != 1):
        raise ValueError('Invalid two-host recovery result')
    return value


def native_dependencies(root, evidence, env, snapshot):
    """Use the existing release launcher's rootless Debian dependency strategy."""
    names = ('libsecret-1-dev', 'libgcrypt20-dev', 'libgpg-error-dev',
             'libgstreamer1.0-dev', 'libgstreamer1.0-0',
             'libgstreamer-plugins-base1.0-dev', 'libgstreamer-plugins-base1.0-0',
             'liborc-0.4-dev', 'liborc-0.4-0t64', 'libunwind-dev', 'libdw-dev', 'libelf-dev')
    downloads = evidence / 'deps/downloads'
    downloads.mkdir(parents=True)
    tick = time.monotonic()
    with (evidence / 'native-dependencies.log').open('wb') as log:
        subprocess.run(['apt-get', 'download', *names], cwd=downloads,
                       stdout=log, stderr=subprocess.STDOUT, check=True, timeout=120)
    prefix, pcdir, compiler = root / 'native', root / 'pkgconfig', root / 'compiler'
    prefix.mkdir()
    pcdir.mkdir()
    compiler.mkdir()
    for archive in sorted(downloads.glob('*.deb')):
        subprocess.run(['dpkg', '-x', str(archive), str(prefix)], check=True, timeout=30)
    for directory in (prefix / 'usr/lib/x86_64-linux-gnu/pkgconfig', prefix / 'usr/share/pkgconfig'):
        if directory.exists():
            for path in directory.glob('*.pc'):
                (pcdir / path.name).write_text(path.read_text().replace('prefix=/usr', f'prefix={prefix}/usr'))
    system_secret = pathlib.Path('/usr/lib/x86_64-linux-gnu/libsecret-1.so.0')
    if system_secret.exists():
        link = prefix / 'usr/lib/x86_64-linux-gnu/libsecret-1.so'
        link.unlink(missing_ok=True)
        link.symlink_to(system_secret)
    cc, cxx = shutil.which('clang'), shutil.which('clang++')
    if not cc or not cxx:
        raise ValueError('Clang unavailable')
    (compiler / 'clang').symlink_to(cc)
    import shlex
    wrapper = compiler / 'clang++'
    wrapper.write_text('#!/usr/bin/env bash\n'
        'for argument in "$@"; do\n'
        f'  [ "$argument" = -c ] && exec {shlex.quote(cxx)} "$@"\n'
        'done\n'
        f'exec {shlex.quote(cxx)} -L{shlex.quote(str(prefix / "usr/lib/x86_64-linux-gnu"))} "$@"\n')
    wrapper.chmod(0o700)
    env['PATH'] = str(compiler) + ':' + env['PATH']
    env['PKG_CONFIG_PATH'] = str(pcdir)
    env['CPATH'] = str(prefix / 'usr/include')
    env['LD_LIBRARY_PATH'] = str(prefix / 'usr/lib/x86_64-linux-gnu')
    return {'duration_seconds': round(time.monotonic() - tick, 3),
            'archives': {p.name: snapshot.digest(p) for p in downloads.glob('*.deb')}}


def verify_ports_released(ports):
    import socket
    for port in ports:
        with socket.socket() as handle:
            # A closed server may leave accepted sockets in TIME_WAIT.
            handle.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            handle.bind(('127.0.0.1', port))


def browser_checks(app, root, sdk, evidence, env, live, snapshot, check):
    """Fresh compiled web owner regressions; never reuse a mutable build."""
    import socket
    import urllib.error
    import urllib.request
    check(['npm', 'ci', '--ignore-scripts', '--no-audit', '--no-fund'], 'npm')
    packages = {str(p.relative_to(app / 'node_modules')): snapshot.digest(p)
                for p in sorted((app / 'node_modules').rglob('*'))
                if p.is_file() and not p.is_symlink()}
    (evidence / 'node-dependencies.json').write_text(json.dumps(packages, indent=2))
    check([str(sdk / 'bin/flutter'), 'build', 'web', '--release', '--no-pub', '--no-wasm-dry-run',
           '-t', 'lib/main_e2e.dart'], 'web-build', timeout=600)
    ports = []
    with socket.socket() as first, socket.socket() as second:
        for handle in (first, second):
            handle.bind(('127.0.0.1', 0))
            ports.append(handle.getsockname()[1])
    env.update(PORT=str(ports[0]), HERMES_E2E_PORT=str(ports[1]),
               WING_APP_URL=f'http://127.0.0.1:{ports[0]}/',
               CHROME_EXECUTABLE='/usr/bin/chromium', NODE_OPTIONS='--max-old-space-size=2048')
    tick = time.monotonic()
    class Finished(Exception):
        pass
    ready = False
    def observe(server):
        nonlocal ready
        if ready:
            return
        try:
            with urllib.request.urlopen(env['WING_APP_URL'], timeout=1) as response:
                ready = response.status == 200
        except (OSError, urllib.error.URLError):
            if time.monotonic() - tick > 10:
                raise ValueError('Fixture did not start')
            return
        if not ready:
            return
        check(['node', 'node_modules/@playwright/test/cli.js', 'test',
               '--config=playwright.config.mjs',
               'playwright/tests/regression/remote-connection-retry.spec.mjs',
               'playwright/tests/regression/saved-connection-workflows.spec.mjs',
               '--workers=1', '--retries=0', '--output=' + str(evidence / 'browser')],
              'browser', timeout=300)
        shutil.copyfile(app / 'playwright/results.json', evidence / 'browser-results.json')
        raise Finished()
    try:
        with (evidence / 'browser-server.log').open('wb') as log:
            live.run_owned(['node', 'serve_web.mjs'], app, env, timeout=400,
                           stdout=log, observe=observe)
    except Finished:
        pass
    else:
        raise ValueError('Fixture ended without browser checks')
    verify_ports_released(ports)
    return {'main_dart_js_sha256': snapshot.digest(app / 'build/web/main.dart.js'),
            'node': subprocess.check_output(['node', '--version'], env=env).decode().strip(),
            'chromium': subprocess.check_output(['/usr/bin/chromium', '--version'], env=env).decode().strip(),
            'isolated_ports_released': True, 'server_owned_group_gone': True}


def run(source):
    source = pathlib.Path(source).resolve()
    first, snapshot = helpers()
    live, helper_hash = snapshot.predecessor(source)
    evidence_root = source / '.task-evidence' / CARD
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
            baseline = evidence_root / 'frozen-entry'
            identity = freeze(source, app, snapshot, baseline if baseline.exists() else None)
            (evidence / 'source.json').write_text(json.dumps(identity, indent=2))
            result['source_archive'] = snapshot.retain_candidate(app, evidence, identity)
            executable = shutil.which('flutter')
            if executable is None:
                raise ValueError('Flutter unavailable')
            live.prepare_packages(source, app, pathlib.Path(executable).resolve().parent.parent, sdk)
            result['dependencies'] = dependencies(app, sdk, evidence, snapshot)
            env = first.isolated_environment(root)
            env.pop('WING_DIRECT_ROOT')
            env['WING_TWO_HOST_ROOT'] = str(root)
            result['native_dependencies'] = native_dependencies(root, evidence, env, snapshot)
            result['go_dependencies'] = go_dependencies(app, root, evidence, env, snapshot)
            prepared_hashes = {name: snapshot.digest(app / name)
                               for name in snapshot.candidate_hashes(identity)}
            if prepared_hashes != snapshot.candidate_hashes(identity):
                result['changed_prepared_inputs'] = [name for name, checksum in prepared_hashes.items()
                    if checksum != snapshot.candidate_hashes(identity)[name]]
                raise ValueError('Dependency preparation changed source')
            result['environment'] = {
                'uname': list(os.uname()),
                'sdk': subprocess.check_output([str(sdk / 'bin/flutter'), '--version'], env=env, timeout=30).decode(),
                'pkg_config_versions': subprocess.check_output(['pkg-config', '--modversion', 'gtk+-3.0', 'gstreamer-1.0',
                    'gstreamer-app-1.0', 'gstreamer-audio-1.0', 'libsecret-1'], env=env, timeout=30).decode(),
                'isolated_home_xdg': True, 'inherited_dbus': False, 'bounded_build_parallelism': 2,
                'prerequisite_archives': {p.name: snapshot.digest(p) for p in sorted((evidence_root / 'deps/downloads').glob('*.deb'))},
            }
            commands = [
                ['python3', '-B', '-m', 'unittest', 'discover', '-s', 'test/tooling', '-p', 'two_host_recovery_native_test.py'],
                ['bash', '-n', OWNED[2]],
                [str(sdk / 'bin/dart'), 'format', '--output=none', '--set-exit-if-changed', *DART_FILES, PRODUCTION],
                [str(sdk / 'bin/flutter'), 'test', '--no-pub', '--concurrency=1',
                 'test/features/hermes_chat/screens/hermes_chat_two_host_recovery_test.dart'],
                [str(sdk / 'bin/flutter'), 'analyze', '--no-pub'],
                [str(sdk / 'bin/flutter'), 'test', '--no-pub', '--concurrency=1',
                 'test/features/hermes_chat/screens/hermes_chat_two_host_recovery_test.dart',
                 'test/features/hermes_chat/screens/hermes_chat_saved_connection_workflows_test.dart',
                 'test/features/hermes_chat/screens/hermes_chat_gateway_switch_test.dart'],
            ]
            def check(command, index, observe=None, timeout=300):
                tick = time.monotonic()
                with (evidence / f'check-{index}.log').open('wb') as log:
                    code, driver = live.run_owned(['bash', '-c', 'exec "$@" 2>&1', 'retry', *command],
                        app, env, timeout=timeout, stdout=log, observe=observe)
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
                        for path in sorted((root / 'cache').glob('two-host-*.json')):
                            value = read_receipt(path)
                            checksum = snapshot.digest(path)
                            if path.name in observed:
                                if observed[path.name]['sha256'] != checksum:
                                    raise ValueError('Native receipt changed')
                                continue
                            fields = pathlib.Path('/proc', str(value['native_pid']), 'stat').read_text().rsplit(')', 1)[1].split()
                            if int(fields[2]) != driver or fields[0] == 'Z' or driver == value['native_pid']:
                                raise ValueError('GTK process not driver-owned')
                            observed[path.name] = {'sha256': checksum, 'driver_pid': driver,
                                'start_ticks': fields[19], 'executable': pathlib.Path('/proc', str(value['native_pid']), 'exe').resolve().name}
                    check([str(sdk / 'bin/flutter'), 'test', '--no-pub', '--concurrency=1', '-d', 'linux', OWNED[0]],
                          'native', observe=on_native, timeout=600)
                    expected = {f'two-host-{w}-{s}.json' for w in (390.0, 1280.0) for s in (1.0, 2.0)}
                    if set(observed) != expected or not live.live_group(display_pid):
                        raise ValueError('Incomplete GTK coverage')
                    result['journeys'] = []
                    for name in sorted(expected):
                        path = root / 'cache' / name
                        result['journeys'].append(read_receipt(path) | observed[name])
                        shutil.copyfile(path, evidence / name)
                    for path in (root / 'cache').glob('*.png'):
                        shutil.copyfile(path, evidence / path.name)
                    renders = {p.name: snapshot.digest(p) for p in evidence.glob('*.png')}
                    if len(renders) != 12 or len(set(renders.values())) < 3:
                        raise ValueError('Missing or unchanged renders')
                    result['renders'] = renders
                    raise Finished()
                try:
                    live.run_owned(['/usr/bin/Xvfb', '-displayfd', '1', '-screen', '0', '1440x1000x24', '-nolisten', 'tcp', '-auth', str(authority)],
                                   app, env, timeout=700, stdout=output, observe=on_display)
                except Finished:
                    result['display']['owned_group_gone'] = True
                else:
                    raise ValueError('Display exited before qualification')
            hashes = {name: snapshot.digest(app / name) for name in snapshot.candidate_hashes(identity)}
            result['executed_input_hashes'] = hashes
            if hashes != snapshot.candidate_hashes(identity):
                raise ValueError('Executed source changed')
            verify_go_dependencies(root, evidence, snapshot)
            # Chromium's singleton socket cannot use the deeply nested evidence path.
            browser_scratch = pathlib.Path.home() / '.hermes/cache/scratch' / CARD
            browser_scratch.mkdir(parents=True, exist_ok=True)
            with tempfile.TemporaryDirectory(prefix='b-', dir=browser_scratch) as short_tmp:
                env['TMPDIR'] = short_tmp
                result['browser'] = browser_checks(app, root, sdk, evidence, env, live, snapshot, check)
            if {name: snapshot.digest(app / name) for name in hashes} != hashes:
                raise ValueError('Browser checks changed source')
            result['status'] = 'NATIVE_TWO_HOST_RECOVERY_PASS'
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
