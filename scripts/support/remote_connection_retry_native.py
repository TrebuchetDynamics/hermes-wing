"""Bounded GTK Remote recovery; synthetic authority, never live admission."""
import hashlib
import importlib.util
import json
import os
import pathlib
import re
import shutil
import subprocess
import sys
import tarfile
import tempfile
import time
from urllib.parse import unquote, urlsplit

CARD = 't_2d93a7e9'
OWNED = (
    'integration_test/linux_remote_connection_retry_test.dart',
    'integration_test/support/remote_connection_retry_native_fixture.dart',
    'scripts/run_linux_remote_connection_retry.sh',
    'scripts/support/remote_connection_retry_native.py',
    'test/tooling/remote_connection_retry_native_test.py',
)
PREREQUISITE = '45a80e42ad2724ed7bcede7e8dea4b26d4990a0c'


def helpers():
    # Read-only launcher prerequisites. The loaded Git helper is retained below.
    path = pathlib.Path(__file__).with_name('direct_first_run_native.py')
    spec = importlib.util.spec_from_file_location('retry_first_run', path)
    if spec is None or spec.loader is None:
        raise ValueError('First-run helper unavailable')
    first = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(first)
    snapshot = first.helpers()
    snapshot.CARD = CARD
    snapshot.OWNED = ()
    snapshot.OVERLAYS = ()
    snapshot.ROOTS = ('lib', 'test', 'integration_test', 'assets', 'linux',
                      'wing_link', 'scripts', 'playwright/support')
    return first, snapshot


def read_receipt(path):
    if path.is_symlink() or path.stat().st_size > 32768:
        raise ValueError('Invalid receipt file')
    value = json.loads(path.read_text())
    cases = [{'reject': reject, 'replacement': replacement, 'fenced': True}
             for reject in (False, True) for replacement in (False, True)]
    if (type(value['native_pid']) is not int or value['native_pid'] <= 0 or
            value['width'] not in (390.0, 1280.0) or value['text_scale'] not in (1.0, 2.0) or
            any(value[k] is not True for k in ('public_entry', 'denial_sanitized',
                'explicit_keyboard_retry', 'connected_draft_retained')) or
            value['profile'] != 'synthetic-qa' or value['session'] != 'synthetic-history' or
            value['auth_profile'] != 'default' or value['auth_session'] != 'synthetic-history' or
            value['physical_keychain'] != 'NOT_CHECKED' or value['late_cases'] != cases or
            any(type(value[k]) is not int or value[k] != n for k, n in {
                'auth_connects': 1, 'auth_saves': 0, 'retry_connects': 1, 'retry_saves': 1,
                'save_attempts': 6, 'save_commits': 3, 'management_attempts': 0,
                'mutation_attempts': 0, 'forbidden_read_attempts': 0}.items()) or
            not value['requests'] or any(set(r) != {'method', 'path', 'query'} or
                r['method'] != 'GET' or r['path'] not in {
                    '/health', '/v1/capabilities', '/api/profiles', '/api/sessions',
                    '/api/sessions/synthetic-history', '/api/sessions/synthetic-history/messages'} or
                not set(r['query']) <= {'profile', 'limit', 'offset', 'order'}
                for r in value['requests']) or
            value['denied_reads'] != [{'status': 401, 'path': '/v1/capabilities', 'profile': None}]):
        raise ValueError('Invalid Remote recovery result')
    return value


def freeze(source, app, snapshot):
    identity = snapshot.freeze(source, app)
    for name, row in identity['inputs'].items():
        row['owner'] = CARD if name in OWNED else 'preexisting-worktree'
    identity['launcher_prerequisite_revision'] = PREREQUISITE
    return identity


def dependencies(app, sdk, evidence, snapshot):
    """Copy external package closure; checks never use mutable shared packages."""
    config_path = app / '.dart_tool/package_config.json'
    config = json.loads(config_path.read_text())
    package_root = sdk.parent / 'packages'
    package_root.mkdir()
    manifest = {}
    relocation = {}
    archive = evidence / 'executed-packages.tar.gz'
    with tarfile.open(archive, 'x:gz') as bundle:
        for row in config['packages']:
            source = pathlib.Path(unquote(urlsplit(row['rootUri']).path)).resolve()
            if source == app:
                continue
            if source.is_relative_to(sdk):
                target = source
            else:
                target = package_root / row['name']
                shutil.copytree(source, target, symlinks=False)
                relocation[str(source)] = str(target)
                row['rootUri'] = target.as_uri()
            hashes = {}
            for path in sorted(target.rglob('*')):
                if path.is_file() and not path.is_symlink():
                    relative = str(path.relative_to(target))
                    hashes[relative] = snapshot.digest(path)
                    bundle.add(path, arcname=row['name'] + '/' + relative, recursive=False)
            manifest[row['name']] = hashes
    archive.chmod(0o400)
    config_path.write_text(json.dumps(config))
    plugin_path = app / '.flutter-plugins-dependencies'
    plugins = json.loads(plugin_path.read_text())
    for rows in plugins['plugins'].values():
        for row in rows:
            old = str(pathlib.Path(row['path']).resolve())
            if old in relocation:
                row['path'] = relocation[old] + '/'
    plugin_path.write_text(json.dumps(plugins))
    (evidence / 'dependencies.json').write_text(json.dumps(manifest, indent=2))
    return {'archive_sha256': snapshot.digest(archive),
            'manifest_sha256': snapshot.digest(evidence / 'dependencies.json'),
            'package_config_sha256': snapshot.digest(config_path),
            'plugins_sha256': snapshot.digest(plugin_path)}


def go_dependencies(app, root, evidence, env, snapshot):
    """Freeze the bundle's module closure before any native build uses it."""
    shared = pathlib.Path(env['GOMODCACHE']).resolve()
    owned = root / 'go-modules'
    owned.mkdir()
    raw = subprocess.check_output(['go', 'mod', 'download', '-json'],
                                  cwd=app / 'wing_link', env=env, timeout=60).decode()
    decoder = json.JSONDecoder()
    rows = []
    while raw.strip():
        row, end = decoder.raw_decode(raw.lstrip())
        raw = raw.lstrip()[end:]
        if 'Error' in row or not row.get('Dir'):
            raise ValueError('Go dependency unavailable offline')
        rows.append(row)
    for row in rows:
        directory = pathlib.Path(row['Dir']).resolve()
        metadata = pathlib.Path(row['GoMod']).resolve().parent
        if not directory.is_relative_to(shared) or not metadata.is_relative_to(shared):
            raise ValueError('Go dependency outside shared module cache')
        shutil.copytree(directory, owned / directory.relative_to(shared), symlinks=False)
        # Go's shared cache has read-only directories; owned copies must teardown.
        for path in [owned / directory.relative_to(shared),
                     *(owned / directory.relative_to(shared)).rglob('*')]:
            if path.is_dir():
                path.chmod(0o700)
        target = owned / metadata.relative_to(shared)
        if not target.exists():
            # Retain graph metadata too: older .mod files can be needed by MVS.
            shutil.copytree(metadata, target, symlinks=False,
                            ignore=shutil.ignore_patterns('*.lock', '*.tmp'))
    env['GOMODCACHE'] = str(owned)
    env['GOFLAGS'] = '-p=2 -mod=readonly'
    manifest = {str(p.relative_to(owned)): snapshot.digest(p)
                for p in sorted(owned.rglob('*')) if p.is_file()}
    archive = evidence / 'executed-go-modules.tar.gz'
    with tarfile.open(archive, 'x:gz') as bundle:
        for name in manifest:
            bundle.add(owned / name, arcname=name, recursive=False)
    archive.chmod(0o400)
    manifest_path = evidence / 'go-dependencies.json'
    manifest_path.write_text(json.dumps(manifest, indent=2))
    # This must resolve exclusively from the copied cache, with networking off.
    subprocess.check_output(['go', 'list', '-deps', '.'], cwd=app / 'wing_link',
                            env=env, timeout=60)
    return {'modules': [{k: row[k] for k in ('Path', 'Version', 'Sum', 'GoModSum')}
                        for row in rows],
            'files': len(manifest), 'archive_sha256': snapshot.digest(archive),
            'manifest_sha256': snapshot.digest(manifest_path),
            'toolchain': subprocess.check_output(['go', 'version'], env=env, timeout=30).decode().strip(),
            'isolated_module_cache': True, 'offline_readonly_build': True}


def verify_go_dependencies(root, evidence, snapshot):
    manifest = json.loads((evidence / 'go-dependencies.json').read_text())
    actual = {str(p.relative_to(root / 'go-modules')): snapshot.digest(p)
              for p in sorted((root / 'go-modules').rglob('*'))
              if p.is_file() and not p.name.endswith('.lock')}
    if actual != manifest:
        raise ValueError('Executed Go dependencies changed')


def run(source):
    source = pathlib.Path(source).resolve()
    first, snapshot = helpers()
    live, helper_hash = snapshot.predecessor(source)
    evidence_root = source / 'build' / CARD
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
            result['source_archive'] = snapshot.retain_candidate(app, evidence, identity)
            executable = shutil.which('flutter')
            if executable is None:
                raise ValueError('Flutter unavailable')
            live.prepare_packages(source, app, pathlib.Path(executable).resolve().parent.parent, sdk)
            result['dependencies'] = dependencies(app, sdk, evidence, snapshot)
            env = first.isolated_environment(root)
            env.pop('WING_DIRECT_ROOT')
            env['WING_RETRY_ROOT'] = str(root)
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
                ['python3', '-B', '-m', 'unittest', 'discover', '-s', 'test/tooling', '-p', 'remote_connection_retry_native_test.py'],
                ['bash', '-n', OWNED[2]],
                [str(sdk / 'bin/dart'), 'format', '--output=none', '--set-exit-if-changed', *OWNED[:2]],
                [str(sdk / 'bin/flutter'), 'analyze', '--no-pub'],
                [str(sdk / 'bin/flutter'), 'test', '--no-pub', '--concurrency=1',
                 'test/features/hermes_chat/screens/hermes_chat_remote_connection_retry_test.dart',
                 'test/features/enrollment/hermes_direct_first_run_test.dart',
                 'test/features/hermes_chat/screens/hermes_chat_screen_auth_recovery_test.dart'],
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
                        for path in sorted((root / 'cache').glob('retry-*.json')):
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
                    expected = {f'retry-{w}-{s}.json' for w in (390.0, 1280.0) for s in (1.0, 2.0)}
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
            result['status'] = 'NATIVE_REMOTE_CONNECTION_RETRY_PASS'
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
