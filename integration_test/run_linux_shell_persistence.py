"""Two real GTK processes, isolated preferences, no Agent or personal storage."""

import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import time

SOURCE = Path(__file__).resolve().parents[1]
CARD = 't_c5aaada0'


def module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    assert spec is not None and spec.loader is not None
    result = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result


def validate(receipt, phase):
    assert phase in ('collapse', 'restore') and receipt['phase'] == phase
    assert type(receipt['native_pid']) is int and receipt['native_pid'] > 0
    assert receipt['initial_width'] == (250 if phase == 'collapse' else 64)
    assert receipt['restored_width'] == 64
    assert receipt['keyboard_collapse'] is (phase == 'collapse')
    assert receipt['persisted_expanded'] is False
    assert receipt['unavailable_storage_usable'] is True
    assert all(type(receipt[k]) is int and receipt[k] == 0
               for k in ('reads', 'sends', 'mutations'))


def preferences(root, digest):
    files = list((root / 'data').rglob('shared_preferences.json'))
    assert len(files) == 1 and not files[0].is_symlink()
    value = json.loads(files[0].read_text())
    assert value.get('flutter.wing.shell.sidebar_expanded') is False
    return {'file': str(files[0].relative_to(root)), 'sha256': digest(files[0])}


def run():
    live = module('shell_process_helpers', SOURCE / 'scripts/support/desktop_live_workflow.py')
    freeze = module('shell_snapshot_helpers', SOURCE / 'scripts/support/desktop_no_inference_smoke.py')
    local = module('shell_isolation_helpers', SOURCE / 'scripts/support/local_setup_enrollment_native.py')
    evidence = SOURCE / '.task-evidence' / CARD
    evidence.mkdir(parents=True, exist_ok=True)
    attempt = Path(tempfile.mkdtemp(prefix='native-', dir=evidence))
    result = {'status': 'FAIL', 'phases': [], 'live_agent': 'NOT_CHECKED',
              'os_keyring': 'NOT_CHECKED', 'android': 'NOT_CHECKED'}
    started = time.monotonic()
    try:
        with live.owned_workspace(attempt) as root:
            app, sdk = root / 'app', root / 'flutter'
            freeze.CARD, freeze.OWNED, freeze.OVERLAYS = CARD, (), ()
            freeze.ROOTS = ('lib', 'test', 'integration_test', 'assets', 'linux', 'scripts', 'playwright/support')
            identity = freeze.freeze(SOURCE, app)
            (attempt / 'source.json').write_text(json.dumps(identity, indent=2))
            result['source_manifest_sha256'] = freeze.digest(attempt / 'source.json')
            result['source_archive'] = freeze.retain_candidate(app, attempt, identity)
            executable = shutil.which('flutter')
            assert executable is not None
            live.prepare_packages(SOURCE, app, Path(executable).resolve().parents[1], sdk)
            local.freeze_packages(app, root, sdk)
            env = local.isolated_environment(root)
            # Reuse cached user-space build prerequisites; never install packages.
            deps_source = Path('/home/xel/git/gormes/hermes-wing/.task-evidence/t_636ced72/deps/root')
            deps = root / 'deps'
            shutil.copytree(deps_source, deps, symlinks=True)
            for pc in deps.rglob('*.pc'):
                pc.write_text(pc.read_text().replace(str(deps_source), str(deps)))
            env.update(PKG_CONFIG_PATH=str(deps / 'usr/lib/x86_64-linux-gnu/pkgconfig'),
                       CMAKE_PREFIX_PATH=str(deps / 'usr'), LIBRARY_PATH=str(deps / 'usr/lib/x86_64-linux-gnu'),
                       LD_LIBRARY_PATH=str(deps / 'usr/lib/x86_64-linux-gnu'), CPATH=str(deps / 'usr/include'))
            dependencies = {str(p.relative_to(root)): freeze.digest(p)
                            for base in (root / 'packages', deps)
                            for p in sorted(base.rglob('*')) if p.is_file() and not p.is_symlink()}
            (attempt / 'dependencies.json').write_text(json.dumps(dependencies, indent=2))
            result['environment'] = {
                'uname': list(os.uname()),
                'sdk': subprocess.check_output([str(sdk / 'bin/flutter'), '--version'], env=env, timeout=30).decode(),
                'engine_sha256': freeze.digest(sdk / 'bin/cache/engine.stamp'),
                'lockfile_sha256': freeze.digest(app / 'pubspec.lock'),
                'dependency_manifest_sha256': freeze.digest(attempt / 'dependencies.json'),
                'isolated_home_xdg': True, 'inherited_dbus': False,
                'pkg_config_versions': subprocess.check_output(['pkg-config', '--modversion', 'gtk+-3.0',
                    'gstreamer-1.0', 'gstreamer-app-1.0', 'gstreamer-audio-1.0', 'libsecret-1'], env=env, timeout=30).decode(),
            }
            assert not list((root / 'data').rglob('shared_preferences.json'))
            for phase in ('collapse', 'restore'):
                path = root / 'cache' / f'shell-{phase}.json'
                observed = {}

                def observe(driver):
                    if not path.exists() or observed:
                        return
                    assert not path.is_symlink() and path.stat().st_size < 32768
                    receipt = json.loads(path.read_text())
                    validate(receipt, phase)
                    fields = Path('/proc', str(receipt['native_pid']), 'stat').read_text().rsplit(')', 1)[1].split()
                    assert int(fields[2]) == driver and fields[0] != 'Z'
                    assert receipt['native_pid'] != driver
                    observed.update(native_pid=receipt['native_pid'], start_ticks=fields[19],
                                    receipt_sha256=freeze.digest(path))

                command = ['xvfb-run', '-a', '-s', '-screen 0 1440x1000x24 -nolisten tcp',
                           str(sdk / 'bin/flutter'), 'test', '--no-pub', '--concurrency=1', '-d', 'linux',
                           'integration_test/linux_shell_persistence_test.dart']
                with (attempt / f'{phase}.log').open('wb') as log:
                    code, driver = live.run_owned(['bash', '-c', 'exec "$@" 2>&1', 'shell', *command],
                        app, env | {'WING_SHELL_PHASE': phase}, timeout=600, stdout=log, observe=observe)
                row = {'phase': phase, 'command': command, 'exit_code': code, 'driver_pid': driver}
                result['phases'].append(row)
                assert code == 0, f'Native {phase} failed; inspect {attempt}/{phase}.log'
                receipt = json.loads(path.read_text())
                validate(receipt, phase)
                assert observed and observed['receipt_sha256'] == freeze.digest(path)
                assert not live.live_group(driver), 'Previous process group survived'
                row.update(receipt=receipt, process=observed, owned_group_gone=True,
                           preferences=preferences(root, freeze.digest))
                shutil.copyfile(path, attempt / f'{phase}-receipt.json')
            first, second = result['phases']
            assert first['process']['native_pid'] != second['process']['native_pid']
            assert first['preferences'] == second['preferences'], 'Restore rewrote saved choice'
            assert all(freeze.digest(app / p) == row['sha256'] for p, row in identity['inputs'].items())
            assert all(freeze.digest(root / p) == expected for p, expected in dependencies.items())
            result['status'] = 'PASS'
        result['isolated_state_removed'] = True
    finally:
        result['duration_seconds'] = round(time.monotonic() - started, 3)
        (attempt / 'verification.json').write_text(json.dumps(result, indent=2))
        print(json.dumps({'evidence': str(attempt), **result}))


def self_check():
    for phase in ('collapse', 'restore'):
        receipt = dict(phase=phase, native_pid=1, initial_width=250 if phase == 'collapse' else 64,
                       restored_width=64, keyboard_collapse=phase == 'collapse', persisted_expanded=False,
                       unavailable_storage_usable=True, reads=0, sends=0, mutations=0)
        validate(receipt, phase)
        for key, value in [('phase', 'other'), ('native_pid', True), ('initial_width', 0),
                           ('restored_width', 250), ('keyboard_collapse', phase != 'collapse'),
                           ('persisted_expanded', True), ('unavailable_storage_usable', False),
                           ('reads', 1), ('sends', 1), ('mutations', 1), ('reads', False)]:
            try:
                validate(receipt | {key: value}, phase)
            except AssertionError:
                continue
            raise AssertionError(f'Invalid {key} accepted')
    print('shell-persistence runner self-check passed')


if __name__ == '__main__':
    if sys.argv[1:] == ['--self-check']:
        self_check()
    else:
        assert not sys.argv[1:], 'Runner accepts no credentials or target arguments'
        run()
