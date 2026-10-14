"""Real isolated GTK adaptive-return fixture; not an OS-window resize test."""

import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import time

from run_linux_shell_persistence import module, preferences

SOURCE = Path(__file__).resolve().parents[1]
CARD = 't_0246c28c'


def validate(receipt):
    expected = dict(phase='compact-return', initial_width=250.0, restored_width=64.0,
                    compact_width=390, returned_width=1280, keyboard_collapse=True,
                    persisted_expanded=False, compact_sidebar_absent=True,
                    draft_state_retained=True, draft_text_retained=True,
                    provider_scope_retained=True, preference_unchanged=True,
                    resize_seam='IntegrationTestWidgetsFlutterBinding.setSurfaceSize',
                    reads=0, sends=0, mutations=0)
    for key, value in expected.items():
        assert type(receipt[key]) is type(value) and receipt[key] == value, key
    assert type(receipt['native_pid']) is int and receipt['native_pid'] > 0


def run():
    live = module('compact_process_helpers', SOURCE / 'scripts/support/desktop_live_workflow.py')
    freeze = module('compact_snapshot_helpers', SOURCE / 'scripts/support/desktop_no_inference_smoke.py')
    local = module('compact_isolation_helpers', SOURCE / 'scripts/support/local_setup_enrollment_native.py')
    evidence = SOURCE / '.task-evidence' / CARD
    evidence.mkdir(parents=True, exist_ok=True)
    attempt = Path(tempfile.mkdtemp(prefix='native-', dir=evidence))
    result = dict(status='FAIL', live_agent='NOT_CHECKED', os_keyring='NOT_CHECKED',
                  android='NOT_CHECKED', physical_os_resize='NOT_CHECKED', physical_keyboard='NOT_CHECKED')
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
            result['environment'] = dict(
                uname=list(os.uname()),
                sdk=subprocess.check_output([str(sdk / 'bin/flutter'), '--version'], env=env, timeout=30).decode(),
                engine_sha256=freeze.digest(sdk / 'bin/cache/engine.stamp'),
                lockfile_sha256=freeze.digest(app / 'pubspec.lock'),
                dependency_manifest_sha256=freeze.digest(attempt / 'dependencies.json'),
                isolated_home_xdg=True, inherited_dbus=False,
                pkg_config_versions=subprocess.check_output(['pkg-config', '--modversion', 'gtk+-3.0',
                    'gstreamer-1.0', 'gstreamer-app-1.0', 'gstreamer-audio-1.0', 'libsecret-1'], env=env, timeout=30).decode())
            assert not list((root / 'data').rglob('shared_preferences.json'))
            path = root / 'cache/shell-compact-return.json'
            observed = {}

            def observe(driver):
                if not path.exists() or observed:
                    return
                assert not path.is_symlink() and path.stat().st_size < 32768
                receipt = json.loads(path.read_text())
                validate(receipt)
                fields = Path('/proc', str(receipt['native_pid']), 'stat').read_text().rsplit(')', 1)[1].split()
                assert int(fields[2]) == driver and fields[0] != 'Z'
                assert receipt['native_pid'] != driver
                observed.update(native_pid=receipt['native_pid'], start_ticks=fields[19],
                                receipt_sha256=freeze.digest(path))

            command = ['xvfb-run', '-a', '-s', '-screen 0 1440x1000x24 -nolisten tcp',
                       str(sdk / 'bin/flutter'), 'test', '--no-pub', '--concurrency=1', '-d', 'linux',
                       'integration_test/linux_shell_compact_return_test.dart']
            with (attempt / 'native.log').open('wb') as log:
                code, driver = live.run_owned(['bash', '-c', 'exec "$@" 2>&1', 'shell', *command],
                    app, env, timeout=600, stdout=log, observe=observe)
            result.update(command=command, exit_code=code, driver_pid=driver)
            assert code == 0, f'Native compact return failed; inspect {attempt}/native.log'
            receipt = json.loads(path.read_text())
            validate(receipt)
            assert observed and observed['receipt_sha256'] == freeze.digest(path)
            assert not live.live_group(driver), 'Owned process group survived'
            result.update(receipt=receipt, process=observed, owned_group_gone=True,
                          preferences=preferences(root, freeze.digest))
            shutil.copyfile(path, attempt / 'compact-return-receipt.json')
            assert all(freeze.digest(app / p) == row['sha256'] for p, row in identity['inputs'].items())
            assert all(freeze.digest(root / p) == expected for p, expected in dependencies.items())
            result['status'] = 'PASS'
        result['isolated_state_removed'] = True
    finally:
        result['duration_seconds'] = round(time.monotonic() - started, 3)
        (attempt / 'verification.json').write_text(json.dumps(result, indent=2))
        print(json.dumps({'evidence': str(attempt), **result}))


def self_check():
    receipt = dict(phase='compact-return', native_pid=1, initial_width=250.0, restored_width=64.0,
                   compact_width=390, returned_width=1280, keyboard_collapse=True,
                   persisted_expanded=False, compact_sidebar_absent=True, draft_state_retained=True,
                   draft_text_retained=True, provider_scope_retained=True, preference_unchanged=True,
                   resize_seam='IntegrationTestWidgetsFlutterBinding.setSurfaceSize', reads=0, sends=0, mutations=0)
    validate(receipt)
    invalid = [{}]
    for key, value in receipt.items():
        missing = receipt.copy()
        del missing[key]
        invalid.append(missing)
        wrong = not value if type(value) is bool else value + 1 if type(value) in (int, float) else 'other'
        if key == 'native_pid':
            wrong = 0
        invalid.extend([receipt | {key: wrong}, receipt | {key: None}])
        if type(value) is int:
            invalid.append(receipt | {key: True})
    for value in invalid:
        try:
            validate(value)
        except (AssertionError, KeyError):
            continue
        raise AssertionError('Malformed or missing proof accepted')
    print('shell-compact-return runner self-check passed')


if __name__ == '__main__':
    if sys.argv[1:] == ['--self-check']:
        self_check()
    else:
        assert not sys.argv[1:], 'Runner accepts no credentials or target arguments'
        run()
