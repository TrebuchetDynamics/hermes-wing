"""Bounded GTK saved connection repair; disposable loopback, never live admission."""

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


CARD = 't_f18c95fe'
OWNED = (
    'integration_test/linux_saved_endpoint_edit_test.dart',
    'integration_test/support/saved_endpoint_edit_native_fixture.dart',
    'scripts/run_linux_saved_endpoint_edit.sh',
    'scripts/support/saved_endpoint_edit_native.py',
    'test/tooling/saved_endpoint_edit_native_test.py',
)
PREREQUISITE = '589e0a703ef6bcfc2ac85398c59fc533ecb44b9b'


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
    expected = [{'method': 'GET', 'path': '/v1/capabilities', 'query': {}, 'status': n}
                for n in (403, 200, 500)]
    if (type(value['native_pid']) is not int or value['native_pid'] <= 0 or
            value['width'] not in (390.0, 1280.0) or value['text_scale'] not in (1.0, 2.0) or
            any(value[k] is not True for k in ('public_entry', 'keyboard_retry',
                'cancel_no_mutation', 'pending_cancel_fenced', 'exact_id_peer_preserved',
                'reopened_key_blank', 'owner_unchanged')) or
            value['physical_keychain'] != 'NOT_CHECKED' or
            any(type(value[k]) is not int or value[k] != n for k, n in {
                'connect_delta': 0, 'disconnect_delta': 0, 'mutation_attempts': 0,
                'active_read_delta': 0, 'save_commits': 1}.items()) or
            value['requests'] != expected):
        raise ValueError('Invalid saved-edit result')
    return value


def freeze(source, app, snapshot):
    identity = snapshot.freeze(source, app)
    for name, row in identity['inputs'].items():
        row['owner'] = CARD if name in OWNED else 'preexisting-worktree'
    identity['editor_prerequisite_revision'] = PREREQUISITE
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
            env['WING_SAVED_EDIT_ROOT'] = str(root)
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
                'pkg_config_versions': subprocess.check_output(['pkg-config', '--modversion', 'gtk+-3.0', 'gstreamer-1.0',
                    'gstreamer-app-1.0', 'gstreamer-audio-1.0', 'libsecret-1'], env=env, timeout=30).decode(),
                'isolated_home_xdg': True, 'inherited_dbus': False, 'bounded_build_parallelism': 2,
                'prerequisite_archives': {p.name: snapshot.digest(p) for p in sorted((evidence_root.parent / 'deps/downloads').glob('*.deb'))},
            }
            commands = [
                ['python3', '-B', '-m', 'unittest', 'discover', '-s', 'test/tooling', '-p', 'saved_endpoint_edit_native_test.py'],
                ['bash', '-n', OWNED[2]],
                [str(sdk / 'bin/dart'), 'format', '--output=none', '--set-exit-if-changed', *OWNED[:2]],
                [str(sdk / 'bin/flutter'), 'analyze', '--no-pub'],
                [str(sdk / 'bin/flutter'), 'test', '--no-pub', '--concurrency=1',
                 'test/features/hermes_chat/screens/hermes_chat_saved_endpoint_edit_test.dart',
                 'test/core/hermes/setup/saved_endpoint_edit_store_test.dart',
                 'test/features/hermes_chat/screens/hermes_chat_saved_connection_workflows_test.dart',
                 'test/features/hermes_chat/screens/hermes_chat_remote_connection_retry_test.dart'],
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
                        for path in sorted((root / 'cache').glob('saved-edit-*.json')):
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
                    expected = {f'saved-edit-{w}-{s}.json' for w in (390.0, 1280.0) for s in (1.0, 2.0)}
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
            retry_helpers().verify_go_dependencies(root, evidence, snapshot)
            result['status'] = 'NATIVE_SAVED_ENDPOINT_EDIT_PASS'
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
