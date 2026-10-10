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


CARD = 't_912b8858'
OWNED = (
    'integration_test/linux_transcript_recovery_test.dart',
    'integration_test/support/transcript_recovery_native_fixture.dart',
    'scripts/run_linux_transcript_recovery.sh',
    'scripts/support/transcript_recovery_native.py',
    'test/tooling/transcript_recovery_native_test.py',
)
BASELINE = 'build/t_263cb8bd/evidence/attempt-vqmcptlp/executed-source.tar.gz'
BASELINE_HASH = '2cc3740bcd2924e9c907bacc60ed7faac9835f292a95759c9a33163c26aaa72b'


def helpers():
    path = pathlib.Path(__file__).with_name('direct_first_run_native.py')
    spec = importlib.util.spec_from_file_location('transcript_first', path)
    first = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(first)
    snapshot = first.helpers()
    return first, snapshot


def read_receipt(path):
    if path.is_symlink() or path.stat().st_size > 32768:
        raise ValueError('Invalid receipt file')
    v = json.loads(path.read_text())
    expected_decisions = [
        {'path': f'/v1/runs/run_{n}/approval', 'request_id': f'request_{n}', 'choice': 'once'}
        for n in (2, 3, 3, 4, 5)]
    if (type(v['native_pid']) is not int or v['native_pid'] <= 0 or
        v['width'] not in (390.0, 1280.0) or v['text_scale'] not in (1.0, 2.0) or
        v['decisions'] != expected_decisions or
        any(type(v[k]) is not int or v[k] != 0 for k in ('recovery_mutations', 'creates', 'stops')) or
        any(v[k] is not True for k in ('retired_rejected', 'late_failure_fenced', 'explicit_retry_only')) or
        v['canonical_ids'] != ['canonical-user', 'canonical-commentary', 'canonical-read', 'canonical-web', 'canonical-answer'] or
        v['mutations'].count('/v1/runs') != 5 or len(v['mutations']) != 10 or
        [p for p in v['mutations'] if p != '/v1/runs'] != [d['path'] for d in expected_decisions] or
        not v['reads'] or any(p not in {'/health', '/v1/capabilities', '/api/sessions',
            '/api/sessions/synthetic-reconnect/messages', '/v1/runs/run_1',
            '/v1/runs/run_2', '/v1/runs/run_3', '/v1/runs/run_5'} for p in v['reads'])):
        raise ValueError('Invalid transcript recovery result')
    return v


def freeze(source, app, snapshot):
    import tarfile
    import hashlib
    archive = source / BASELINE
    if snapshot.digest(archive) != BASELINE_HASH:
        raise ValueError('Attributed predecessor archive changed')
    app.mkdir()
    with tarfile.open(archive) as bundle:
        identity = json.load(bundle.extractfile('source.json'))
        hashes = snapshot.candidate_hashes(identity)
        members = bundle.getmembers()
        if {m.name for m in members} != set(hashes) | {'source.json'}:
            raise ValueError('Unexpected baseline archive inputs')
        for member in members:
            name = member.name
            if not member.isfile() or pathlib.PurePosixPath(name).is_absolute() or '..' in pathlib.PurePosixPath(name).parts:
                raise ValueError('Unsafe archive member')
            if name == 'source.json':
                continue
            raw = bundle.extractfile(member).read()
            if hashlib.sha256(raw).hexdigest() != hashes[name]:
                raise ValueError('Baseline input mismatch')
            target = app / name
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(raw)
            target.chmod(member.mode)
    identity['attributed_prerequisite'] = {'card': 't_263cb8bd',
        'commit': '9f84b77197a83f4fc08a61ee3251c5456f380533', 'archive_sha256': BASELINE_HASH}
    for name in OWNED:
        path = source / name
        if path.is_symlink() or not path.is_file() or name in hashes:
            raise ValueError('Owned additive source required')
        target = app / name
        target.parent.mkdir(parents=True, exist_ok=True)
        raw = path.read_bytes()
        target.write_bytes(raw)
        identity['inputs'][name] = {'sha256': hashlib.sha256(raw).hexdigest(), 'owner': CARD, 'dirty': True}
    # Launcher imports are validated against the exact reviewed snapshot, not
    # a generic shared dirty overlay. No production sources are copied from it.
    for name in ('direct_first_run_native.py', 'desktop_no_inference_smoke.py', 'remote_connection_retry_native.py'):
        key = 'scripts/support/' + name
        if snapshot.digest(source / key) != hashes[key]:
            raise ValueError('Read-only helper prerequisite drift')
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
            env['WING_TRANSCRIPT_ROOT'] = str(root)
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
                'sysroot_hashes': {str(p.relative_to(sysroot)): snapshot.digest(p)
                    for p in sorted(sysroot.rglob('*')) if p.is_file() and not p.is_symlink()},
                'tools': {name: snapshot.digest(pathlib.Path('/usr/bin') / name)
                    for name in ('Xvfb', 'import', 'pkg-config')},
            }
            commands = [
                ['python3', '-B', '-m', 'unittest', 'discover', '-s', 'test/tooling', '-p', 'transcript_recovery_native_test.py'],
                ['bash', '-n', OWNED[2]],
                [str(sdk / 'bin/dart'), 'format', '--output=none', '--set-exit-if-changed', *OWNED[:2]],
                [str(sdk / 'bin/flutter'), 'analyze', '--no-pub'],
                [str(sdk / 'bin/flutter'), 'test', '--no-pub', '--concurrency=1',
                 'test/features/hermes_chat/screens/hermes_chat_transcript_reconnect_test.dart',
                 'test/features/hermes_chat/screens/hermes_chat_transcript_accessibility_test.dart',
                 'test/core/hermes/channel/hermes_approval_settlement_owner_test.dart'],
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
                        for path in sorted((root / 'cache').glob('transcript-*.json')):
                            if not path.is_symlink() and path.stat().st_size <= 32768:
                                shutil.copyfile(path, evidence / path.name)
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
                    expected = {f'transcript-{w}-{s}.json' for w in (390.0, 1280.0) for s in (1.0, 2.0)}
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
                    if len(renders) != 20 or len(set(renders.values())) < 3:
                        raise ValueError('Missing or unchanged renders')
                    for w in (390.0, 1280.0):
                        for s in (1.0, 2.0):
                            prefix = f'transcript-{w}-{s}-'
                            if (renders[prefix + 'focus.png'] == renders[prefix + 'unfocused.png'] or
                                renders[prefix + 'approval.png'] == renders[prefix + 'approval-unfocused.png']):
                                raise ValueError('No rendered keyboard focus change')
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
            result['native_binary_sha256'] = snapshot.digest(app / 'build/linux/x64/debug/bundle/wing')
            result['linked_libraries'] = subprocess.check_output(['ldd', str(app / 'build/linux/x64/debug/bundle/wing')], env=env, timeout=30).decode()
            if any(snapshot.digest(sysroot / name) != value for name, value in result['environment']['sysroot_hashes'].items()):
                raise ValueError('Prerequisite source drift')
            result['status'] = 'NATIVE_TRANSCRIPT_RECOVERY_PASS'
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
