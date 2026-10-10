"""Frozen GTK public Remote auth copy/recovery. No live host or inference."""
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

CARD = 't_62edb5a9'
OWNED = (
    'integration_test/linux_remote_auth_explanation_test.dart',
    'integration_test/support/remote_auth_explanation_native_fixture.dart',
    'scripts/run_linux_remote_auth_explanation.sh',
    'scripts/support/remote_auth_explanation_native.py',
    'test/tooling/remote_auth_explanation_native_test.py',
    'test/features/hermes_chat/screens/hermes_remote_auth_explanation_test.dart',
    'lib/features/hermes_chat/screens/state/hermes_chat_layout.dart',
    'lib/l10n/app_en.arb', 'lib/l10n/app_localizations.dart',
    'lib/l10n/app_localizations_en.dart',
)
spec = importlib.util.spec_from_file_location('auth_retry_helpers',
    pathlib.Path(__file__).with_name('remote_connection_retry_native.py'))
if spec is None or spec.loader is None:
    raise ValueError('Remote retry helpers unavailable')
retry = importlib.util.module_from_spec(spec)
spec.loader.exec_module(retry)
dependencies = retry.dependencies
go_dependencies = retry.go_dependencies
verify_go_dependencies = retry.verify_go_dependencies


def helpers():
    first, snapshot = retry.helpers()
    snapshot.CARD = CARD
    return first, snapshot


def freeze(source, app, snapshot):
    identity = snapshot.freeze(source, app)
    for name, row in identity['inputs'].items():
        row['owner'] = CARD if name in OWNED else 'preexisting-worktree'
    return identity


def read_receipt(path):
    if path.is_symlink() or path.stat().st_size > 32768:
        raise ValueError('Invalid receipt file')
    value = json.loads(path.read_text())
    if (type(value['native_pid']) is not int or value['native_pid'] <= 0 or
        value['width'] not in (390.0, 1280.0) or value['text_scale'] not in (1.0, 2.0) or
        any(value[k] is not True for k in ('public_entry', 'denial_sanitized',
            'keyboard_explanation', 'explicit_retry_cancel', 'form_draft_retained')) or
        any(type(value[k]) is not int or value[k] != n for k, n in {
            'connects': 4, 'saves': 1, 'management_attempts': 0,
            'mutation_attempts': 0, 'forbidden_read_attempts': 0}.items()) or
        type(value['token_reads']) is not int or value['token_reads'] <= 0 or
        value['physical_keychain'] != 'NOT_CHECKED' or
        not value['requests'] or any(set(r) != {'method', 'path', 'query'} or
            r['method'] != 'GET' or r['path'] not in {
                '/health', '/v1/capabilities', '/api/profiles', '/api/sessions',
                '/api/sessions/synthetic-history', '/api/sessions/synthetic-history/messages'} or
            not set(r['query']) <= {'profile', 'limit', 'offset', 'order'}
            for r in value['requests']) or
        value['denied_reads'] != [{'status': status, 'path': '/v1/capabilities', 'profile': None}
            for status in (403, 401)]):
        raise ValueError('Invalid Remote auth explanation result')
    return value


def run(source):
    source = pathlib.Path(source).resolve()
    first, snapshot = helpers()
    live, helper_hash = snapshot.predecessor(source)
    evidence_root = source / '.task-evidence' / CARD / 'native'
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
            # Reuse user-space enrollment headers in a disposable dependency closure.
            borrowed = source / '.task-evidence/t_636ced72/deps/root'
            sysroot = root / 'native-sysroot'
            shutil.copytree(borrowed, sysroot, symlinks=False,
                ignore=lambda directory, names: [name for name in names if name == 'doc' or
                    (pathlib.Path(directory, name).is_symlink() and
                     not pathlib.Path(directory, name).exists())])
            for path in sysroot.rglob('*.pc'):
                path.write_text(path.read_text().replace(str(borrowed), str(sysroot)))
            native_hashes = {str(p.relative_to(sysroot)): snapshot.digest(p)
                for p in sorted(sysroot.rglob('*')) if p.is_file()}
            (evidence / 'native-dependencies.json').write_text(json.dumps(native_hashes, indent=2))
            for name in ('PKG_CONFIG_PATH', 'LIBRARY_PATH', 'CPATH', 'CMAKE_PREFIX_PATH'):
                env.pop(name, None)
            env['PKG_CONFIG_PATH'] = str(sysroot / 'usr/lib/x86_64-linux-gnu/pkgconfig')
            env['LIBRARY_PATH'] = str(sysroot / 'usr/lib/x86_64-linux-gnu')
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
                ['python3', '-B', '-m', 'unittest', 'discover', '-s', 'test/tooling', '-p', 'remote_auth_explanation_native_test.py'],
                ['bash', '-n', OWNED[2]],
                [str(sdk / 'bin/dart'), 'format', '--output=none', '--set-exit-if-changed', *OWNED[:2], OWNED[5], OWNED[6]],
                [str(sdk / 'bin/flutter'), 'analyze', '--no-pub'],
                [str(sdk / 'bin/flutter'), 'test', '--no-pub', '--concurrency=1',
                 'test/features/hermes_chat/screens/hermes_remote_auth_explanation_test.dart',
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
                    check([str(sdk / 'bin/flutter'), 'test', '--no-pub', '--concurrency=1', '-d', 'linux', '-v', OWNED[0]],
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
                    if len(renders) != 16 or len(set(renders.values())) < 3:
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
            if native_hashes != {str(p.relative_to(sysroot)): snapshot.digest(p)
                    for p in sorted(sysroot.rglob('*')) if p.is_file()}:
                raise ValueError('Executed native dependencies changed')
            result['status'] = 'NATIVE_REMOTE_AUTH_EXPLANATION_PASS'
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
