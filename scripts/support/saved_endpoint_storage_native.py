"""Real plugin persistence under a private bus, keyring, state and GTK display."""
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

CARD = 't_d83a3347'
OWNED = (
    'integration_test/linux_saved_endpoint_storage_test.dart',
    'integration_test/support/saved_endpoint_storage_native_fixture.dart',
    'scripts/run_linux_saved_endpoint_storage.sh',
    'scripts/support/saved_endpoint_storage_native.py',
    'test/tooling/saved_endpoint_storage_native_test.py',
)


def helpers():
    path = pathlib.Path(__file__).with_name('saved_endpoint_edit_native.py')
    spec = importlib.util.spec_from_file_location('storage_prerequisite', path)
    if spec is None or spec.loader is None:
        raise ValueError('Storage prerequisite unavailable')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    first, snapshot = module.helpers()
    snapshot.CARD = CARD
    return module, first, snapshot


def bus_config(root, deny=False):
    # No system service directories or activation, no owner's session connection.
    denied = '<deny send_destination="org.freedesktop.secrets" send_interface="org.freedesktop.Secret.Collection" send_member="CreateItem"/>' if deny else ''
    return f'''<!DOCTYPE busconfig PUBLIC "-//freedesktop//DTD D-Bus Bus Configuration 1.0//EN" "http://www.freedesktop.org/standards/dbus/1.0/busconfig.dtd">
<busconfig><type>session</type><listen>unix:path={root}/runtime/bus</listen>
<auth>EXTERNAL</auth><policy context="default"><allow own="*"/>
<allow send_destination="*"/><allow receive_sender="*"/>{denied}</policy></busconfig>'''


def probe(env, method, *args):
    return subprocess.run(['/usr/bin/gdbus', 'call', '--session',
        '--dest', 'org.freedesktop.DBus', '--object-path', '/org/freedesktop/DBus',
        '--method', 'org.freedesktop.DBus.' + method, *args],
        env=env, capture_output=True, timeout=3)


def read_receipt(path, phase):
    if path.is_symlink() or path.stat().st_size > 4096:
        raise ValueError('Invalid storage receipt')
    value = json.loads(path.read_text())
    expected = {'phase', 'native_pid', 'cases', 'real_plugins',
                'canonical_peer_preserved', 'preferences_secret_free',
                'reopened_key_blank', 'cancel_no_mutation', 'denied_save_retry',
                'connect_delta', 'mutation_attempts', 'active_read_delta'}
    if (set(value) != expected or value['phase'] != phase or
            type(value['native_pid']) is not int or value['native_pid'] <= 0 or
            type(value['cases']) is not int or value['cases'] != 4 or
            any(value[k] is not True for k in ('real_plugins',
                'canonical_peer_preserved', 'preferences_secret_free',
                'reopened_key_blank', 'cancel_no_mutation')) or
            value['denied_save_retry'] is not (phase == 'write') or
            any(type(value[k]) is not int or value[k] != 0 for k in
                ('connect_delta', 'mutation_attempts', 'active_read_delta'))):
        raise ValueError('Storage journey failed')
    return value


def service_phases(live, root, app, sdk, env, evidence, result, check):
    snapshot = helpers()[2]
    config = root / 'runtime/bus.conf'
    config.write_text(bus_config(root))
    bus_env = env | {'DBUS_SESSION_BUS_ADDRESS': f'unix:path={root}/runtime/bus'}
    deadline = time.monotonic() + 10
    class Finished(Exception):
        pass
    def on_bus(bus_pid):
        response = probe(bus_env, 'GetId')
        if response.returncode:
            if time.monotonic() >= deadline:
                raise ValueError('Private bus startup failed')
            return
        # The random unlock password is stdin-only; wrapper/daemon stay in the
        # run_owned process group. No values, hashes, keyring bytes or output saved.
        wrapper = ('import subprocess,secrets; '
                   'raise SystemExit(subprocess.run(["/usr/bin/gnome-keyring-daemon",'
                   '"--foreground","--unlock","--components=secrets",'
                   '"--control-directory",' + repr(str(root / 'runtime/keyring')) + '],'
                   'input=secrets.token_hex(32).encode(),stdout=subprocess.DEVNULL,'
                   'stderr=subprocess.DEVNULL).returncode)')
        service_deadline = time.monotonic() + 10
        def on_keyring(service_driver):
            response = probe(bus_env, 'GetConnectionUnixProcessID', 'org.freedesktop.secrets')
            if response.returncode:
                if time.monotonic() >= service_deadline:
                    raise ValueError('Private Secret Service startup failed')
                return
            match = re.fullmatch(rb'\(uint32 ([0-9]+),\)\n', response.stdout)
            if not match:
                raise ValueError('Invalid service identity')
            service_pid = int(match[1])
            if os.getpgid(service_pid) != service_driver:
                raise ValueError('Secret Service is not owned')
            result['storage_service'] = {'bus_pid': bus_pid, 'service_pid': service_pid,
                'service_driver': service_driver, 'private_address': True,
                'no_activation_directories': True, 'stdin_only_unlock': True}
            journeys = []
            for phase in ('write', 'verify'):
                receipt = root / 'cache' / f'storage-{phase}.json'
                observed = {}
                control_events = []
                def observe(driver):
                    request = root / 'cache/control-request'
                    if request.exists():
                        mode = request.read_text()
                        if mode not in ('deny', 'allow'):
                            raise ValueError('Unknown service control')
                        config.write_text(bus_config(root, mode == 'deny'))
                        # Synchronous reload acknowledgement precedes UI save.
                        if probe(bus_env, 'ReloadConfig').returncode:
                            raise ValueError('Private bus policy reload failed')
                        request.unlink()
                        (root / 'cache/control-ready').write_text(mode)
                        control_events.append(mode)
                    if not receipt.exists():
                        return
                    value = read_receipt(receipt, phase)
                    checksum = snapshot.digest(receipt)
                    if observed:
                        if observed['sha256'] != checksum:
                            raise ValueError('Receipt changed')
                        return
                    fields = pathlib.Path('/proc', str(value['native_pid']), 'stat').read_text().rsplit(')', 1)[1].split()
                    if int(fields[2]) != driver or fields[0] == 'Z' or driver == value['native_pid']:
                        raise ValueError('Native app not driver-owned')
                    observed.update(sha256=checksum, start_ticks=fields[19], driver_pid=driver)
                check([str(sdk / 'bin/flutter'), 'test', '--no-pub', '--concurrency=1',
                       '-d', 'linux', OWNED[0]], phase, bus_env | {'WING_STORAGE_PHASE': phase}, observe, 600)
                value = read_receipt(receipt, phase)
                if not observed or control_events != (['deny', 'allow'] * 4 if phase == 'write' else []):
                    raise ValueError('Missing native/service-control observation')
                if journeys and value['native_pid'] == journeys[0]['native_pid']:
                    raise ValueError('Restart did not change native process')
                journeys.append(value | observed | {'control_events': control_events})
                shutil.copyfile(receipt, evidence / receipt.name)
                for image in (root / 'cache').glob('storage-*.png'):
                    shutil.copyfile(image, evidence / image.name)
            result['journeys'] = journeys
            if not live.live_group(bus_pid) or not live.live_group(service_driver):
                raise ValueError('Service did not survive restart')
            raise Finished()
        try:
            live.run_owned([sys.executable, '-B', '-c', wrapper], app, bus_env,
                           timeout=1250, observe=on_keyring)
        except Finished:
            result['storage_service']['keyring_owned_group_gone'] = True
            raise Finished()
        raise ValueError('Secret Service exited')
    try:
        with (evidence / 'bus.log').open('wb') as log:
            live.run_owned(['bash', '-c', 'exec "$@" 2>&1', 'bus', '/usr/bin/dbus-daemon', '--nofork', '--config-file=' + str(config)],
                           app, env, timeout=1280, observe=on_bus, stdout=log)
    except Finished:
        result['storage_service']['bus_owned_group_gone'] = True
        return
    raise ValueError('Private bus exited')


def run(source):
    source = pathlib.Path(source).resolve()
    prerequisite, first, snapshot = helpers()
    live, helper_hash = snapshot.predecessor(source)
    evidence_root = source / 'build' / CARD / 'evidence'
    evidence_root.mkdir(parents=True, exist_ok=True)
    evidence = pathlib.Path(tempfile.mkdtemp(prefix='attempt-', dir=evidence_root))
    result = {'status': 'FAIL', 'checks': [], 'runtime_helper_sha256': helper_hash,
              'inference': 'NOT_CHECKED', 'evidence': str(evidence)}
    started = time.monotonic()
    try:
        raw = subprocess.check_output(['git', 'show', snapshot.PREDECESSOR + ':scripts/support/desktop_live_workflow.py'], cwd=source, timeout=30)
        (evidence / 'executed-runtime-helper.py').write_bytes(raw)
        # Linux Unix-domain socket paths are bounded to 108 bytes. Keep state
        # beside evidence rather than nested beneath attempt-specific directories.
        with live.owned_workspace(evidence_root.parent) as root:
            app, sdk = root / 'app', root / 'flutter'
            identity = snapshot.freeze(source, app)
            for name, row in identity['inputs'].items():
                row['owner'] = CARD if name in OWNED else 'preexisting-worktree'
            (evidence / 'source.json').write_text(json.dumps(identity, indent=2))
            result['source_archive'] = snapshot.retain_candidate(app, evidence, identity)
            executable = shutil.which('flutter')
            if executable is None:
                raise ValueError('Flutter unavailable')
            live.prepare_packages(source, app, pathlib.Path(executable).resolve().parent.parent, sdk)
            result['dependencies'] = prerequisite.retry_helpers().dependencies(app, sdk, evidence, snapshot)
            env = first.isolated_environment(root)
            env.pop('WING_DIRECT_ROOT')
            env['WING_STORAGE_ROOT'] = str(root)
            env['WING_STORAGE_RUNTIME_HELPER'] = str(evidence / 'executed-runtime-helper.py')
            result['go_dependencies'] = prerequisite.retry_helpers().go_dependencies(app, root, evidence, env, snapshot)
            result['environment'] = {'uname': list(os.uname()),
                'sdk': subprocess.check_output([str(sdk / 'bin/flutter'), '--version'], env=env, timeout=30).decode(),
                'tools': {name: snapshot.digest(pathlib.Path('/usr/bin') / name)
                          for name in ('dbus-daemon', 'gnome-keyring-daemon', 'Xvfb')},
                'isolated_home_xdg': True, 'inherited_dbus': False, 'build_parallelism': 2}
            result['native_prerequisites'] = {
                'package_versions': subprocess.check_output(['pkg-config', '--modversion',
                    'gtk+-3.0', 'gstreamer-1.0', 'gstreamer-app-1.0', 'gstreamer-audio-1.0', 'libsecret-1'], env=env, timeout=30).decode(),
                'owned_archive_hashes': {p.name: snapshot.digest(p) for p in sorted(
                    (evidence_root.parent / 'deps/downloads').glob('*.deb'))},
                'owned_sysroot_hashes': {str(p.relative_to(evidence_root.parent / 'deps/sysroot')): snapshot.digest(p)
                    for p in sorted((evidence_root.parent / 'deps/sysroot').rglob('*'))
                    if p.is_file() and not p.is_symlink()},
            }
            def check(command, label, check_env=None, observe=None, timeout=300):
                tick = time.monotonic()
                with (evidence / f'{label}.log').open('wb') as log:
                    code, driver = live.run_owned(['bash', '-c', 'exec "$@" 2>&1', 'storage', *command],
                        app, check_env or env, timeout=timeout, stdout=log, observe=observe)
                result['checks'].append({'command': command, 'exit': code,
                    'duration_seconds': round(time.monotonic() - tick, 3), 'owned_group_gone': True})
                if code:
                    raise ValueError('Scoped check failed; inspect retained log')
                return driver
            commands = [
                ['python3', '-B', '-m', 'unittest', 'discover', '-s', 'test/tooling', '-p', 'saved_endpoint_storage_native_test.py'],
                ['bash', '-n', OWNED[2]],
                [str(sdk / 'bin/dart'), 'format', '--output=none', '--set-exit-if-changed', *OWNED[:2]],
                [str(sdk / 'bin/flutter'), 'analyze', '--no-pub'],
                [str(sdk / 'bin/flutter'), 'test', '--no-pub', '--concurrency=1',
                 'test/core/hermes/setup/saved_endpoint_edit_store_test.dart',
                 'test/features/hermes_chat/screens/hermes_chat_saved_endpoint_edit_test.dart'],
            ]
            for index, command in enumerate(commands):
                check(command, f'check-{index}')
            authority = root / 'cache/display-authority'
            live.display_authority(authority)
            env['XAUTHORITY'] = str(authority)
            deadline = time.monotonic() + 10
            class Finished(Exception):
                pass
            with tempfile.TemporaryFile(dir=root / 'cache') as display:
                def on_display(display_pid):
                    display.seek(0)
                    number = display.read(17)
                    if not re.fullmatch(rb'[0-9]{1,5}\n', number):
                        if time.monotonic() >= deadline:
                            raise ValueError('Display startup failed')
                        return
                    env['DISPLAY'] = ':' + number.decode().strip()
                    live.admit_display(root, env)
                    result['display'] = {'authenticated': True, 'wrong_missing_authority_rejected': True}
                    service_phases(live, root, app, sdk, env, evidence, result, check)
                    raise Finished()
                try:
                    live.run_owned(['/usr/bin/Xvfb', '-displayfd', '1', '-screen', '0', '1440x1000x24',
                                    '-nolisten', 'tcp', '-auth', str(authority)],
                                   app, env, timeout=1350, stdout=display, observe=on_display)
                except Finished:
                    result['display']['owned_group_gone'] = True
                else:
                    raise ValueError('Display exited before qualification')
            actual = {n: snapshot.digest(app / n) for n in snapshot.candidate_hashes(identity)}
            if actual != snapshot.candidate_hashes(identity):
                raise ValueError('Executed source changed')
            result['executed_input_hashes'] = actual
            prerequisite.retry_helpers().verify_go_dependencies(root, evidence, snapshot)
            if len(list(evidence.glob('storage-*.png'))) != 12:
                raise ValueError('Incomplete blank-field captures')
            executable = app / 'build/linux/x64/debug/bundle/wing'
            result['native_binary_sha256'] = snapshot.digest(executable)
            result['linked_libraries'] = subprocess.check_output(['ldd', str(executable)], env=env, timeout=30).decode()
            result['renders'] = {p.name: snapshot.digest(p) for p in sorted(evidence.glob('storage-*.png'))}
            result['status'] = 'LINUX_REAL_STORAGE_RESTART_PASS'
        result['isolated_state_deleted_after_teardown'] = True
    finally:
        result['duration_seconds'] = round(time.monotonic() - started, 3)
        owned_root = locals().get('root')
        result['owned_workspace_absent'] = owned_root is None or not owned_root.exists()
        # run_owned's finally verifies whole-group death even on failed attempts.
        for label in ('storage_service', 'display'):
            record = result.get(label, {})
            result[label + '_recorded_processes_gone'] = all(
                not pathlib.Path('/proc', str(value)).exists()
                for key, value in record.items() if key.endswith('pid') or key == 'service_driver')
        (evidence / 'verification.json').write_text(json.dumps(result, indent=2))
    return result


def main(argv=None):
    if (sys.argv[1:] if argv is None else argv):
        print('NO_ARGUMENTS_OR_CREDENTIALS_ACCEPTED')
        return 2
    result = run(pathlib.Path(__file__).resolve().parents[2])
    print(json.dumps({k: result[k] for k in ('status', 'evidence', 'duration_seconds')}))
    return 0


if __name__ == '__main__':
    sys.exit(main())
