"""Remaining transcript GTK keys, reusing the authenticated owned-process harness.

Runs this worktree, not the historical archive's four already-qualified cases.
All ephemeral state/evidence stays under TMPDIR; prerequisites are cache-only.
"""

import hashlib
import importlib.util
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import time

SOURCE = Path(__file__).resolve().parents[1]
TARGET = 'integration_test/linux_transcript_keyboard_test.dart'
DRIVER = 'integration_test/support/transcript_keyboard_driver.dart'
PREDECESSOR = '894439b76c889fed45f3c4d57b73086f1e18d479'


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    result = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result


def inputs():
    roots = ('lib', 'test', 'integration_test', 'linux', 'assets', 'scripts',
             'pubspec.yaml', 'pubspec.lock', 'analysis_options.yaml', 'l10n.yaml')
    names = subprocess.check_output(
        ['git', 'ls-files', '-z', '--cached', '--others', '--exclude-standard', '--', *roots],
        cwd=SOURCE).decode().split('\0')
    return {name: digest(SOURCE / name) for name in sorted(set(names) - {''})
            if (SOURCE / name).is_file() and not (SOURCE / name).is_symlink()}


def validate(value):
    assert type(value['native_pid']) is int and value['native_pid'] > 0
    assert type(value['text_scale']) is float and value['text_scale'] == 2.0
    assert value['retired_review_removed'] is True
    assert value['inverse_disclosure_traversal'] is True
    assert type(value['recovery_mutations']) is int and value['recovery_mutations'] == 0
    assert value['mutations'] == ['/v1/runs', '/v1/runs', '/v1/runs/run_2/approval']
    assert value['decisions'] == [dict(path='/v1/runs/run_2/approval', request_id='request_2', choice='deny')]
    assert value['observations'] == [dict(width=w, mutations=m, decisions=0)
                                    for w, m in ((390.0, 1), (1280.0, 1),
                                                 (390.0, 2), (1280.0, 2), (390.0, 2))]
    assert value['captures'] == ['tool-unfocused', 'tool-focused', 'tool-expanded',
                                 'review-unfocused', 'review-focused', 'deny-focused']
    assert [r['path'] for r in value['requests'] if r['method'] == 'POST'] == value['mutations']
    assert [r['path'] for r in value['requests'] if r['method'] == 'SSE'] == [
        '/v1/runs/run_1/events', '/v1/runs/run_2/events']
    allowed = {'/health', '/v1/capabilities', '/api/sessions',
               '/api/sessions/synthetic-reconnect/messages', '/v1/runs/run_1', '/v1/runs/run_2'}
    assert all(r['path'] in allowed for r in value['requests'] if r['method'] == 'GET')
    assert all(r['method'] in ('GET', 'POST', 'SSE') for r in value['requests'])


def run():
    assert not sys.argv[1:], 'No credentials or target arguments accepted'
    scratch = Path(os.environ['TMPDIR']).resolve()
    cache = Path(os.environ['AUTOWORK_CACHE']).resolve()
    port = int(os.environ['AUTOWORK_PORT_BASE'])
    sdk = cache / 'flutter-3.44.2'
    deps = cache / 'linux-dev-noble-20261007/root/usr'
    assert (sdk / 'bin/flutter').is_file() and (deps / 'lib/x86_64-linux-gnu/pkgconfig/libsecret-1.pc').is_file()
    evidence = Path(tempfile.mkdtemp(prefix='transcript-keyboard-', dir=scratch))
    helpers = module('transcript_snapshot', SOURCE / 'scripts/support/desktop_no_inference_smoke.py')
    isolation = module('transcript_isolation', SOURCE / 'scripts/support/local_setup_enrollment_native.py')
    live, helper_hash = helpers.predecessor(SOURCE)
    raw = subprocess.check_output(['git', 'show', PREDECESSOR + ':scripts/support/desktop_live_workflow.py'], cwd=SOURCE)
    (evidence / 'runtime-helper.py').write_bytes(raw)
    source = inputs()
    (evidence / 'source.json').write_text(json.dumps(source, indent=2))
    result = dict(status='FAIL', baseline=subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=SOURCE).decode().strip(),
                  source_manifest_sha256=digest(evidence / 'source.json'),
                  runtime_helper_revision=PREDECESSOR, runtime_helper_sha256=helper_hash,
                  live_agent='NOT_CHECKED', physical_keyboard='NOT_CHECKED', screen_reader='NOT_CHECKED')
    started = time.monotonic()
    try:
        with live.owned_workspace(evidence) as root:
            env = isolation.isolated_environment(root)
            env.update(PATH=str(sdk / 'bin') + ':' + os.environ['PATH'],
                       PUB_CACHE=str(cache / 'dart-pub-3.12.2'),
                       PKG_CONFIG_PATH=str(deps / 'lib/x86_64-linux-gnu/pkgconfig'),
                       LIBRARY_PATH=str(deps / 'lib/x86_64-linux-gnu'),
                       LD_LIBRARY_PATH=str(deps / 'lib/x86_64-linux-gnu'),
                       CMAKE_PREFIX_PATH=str(deps), CPATH=str(deps / 'include'),
                       WING_TRANSCRIPT_ROOT=str(root))
            env.pop('WING_LOCAL_ROOT')
            result['environment'] = dict(uname=list(os.uname()),
                sdk=subprocess.check_output([str(sdk / 'bin/flutter'), '--version'], env=env).decode(),
                engine_stamp_sha256=digest(sdk / 'bin/cache/engine.stamp'),
                pkg_config_versions=subprocess.check_output(['pkg-config', '--modversion', 'gtk+-3.0',
                    'gstreamer-1.0', 'libsecret-1'], env=env).decode(), isolated_home_xdg=True,
                inherited_display_dbus=False, port_base=port)
            authority = root / 'cache/authority'
            live.display_authority(authority)
            env['XAUTHORITY'] = str(authority)
            deadline = time.monotonic() + 10
            observed = {}

            class Finished(Exception):
                pass

            with tempfile.TemporaryFile(dir=root / 'cache') as display_output:
                def on_display(display_pid):
                    display_output.seek(0)
                    number = display_output.read(17)
                    if not re.fullmatch(rb'[0-9]{1,5}\n', number):
                        assert time.monotonic() < deadline, 'Display startup deadline'
                        return
                    env['DISPLAY'] = ':' + number.decode().strip()
                    live.admit_display(root, env)
                    result['display'] = dict(pid=display_pid, authenticated=True,
                                             wrong_missing_authority_rejected=True)
                    path = root / 'cache/keyboard.json'

                    def on_native(driver):
                        if not path.exists() or observed:
                            return
                        assert not path.is_symlink() and path.stat().st_size <= 32768
                        value = json.loads(path.read_text())
                        validate(value)
                        fields = Path('/proc', str(value['native_pid']), 'stat').read_text().rsplit(')', 1)[1].split()
                        assert fields[0] != 'Z' and int(fields[2]) == driver and driver != value['native_pid']
                        observed.update(native_pid=value['native_pid'], driver_pid=driver,
                            start_ticks=fields[19], executable=Path('/proc', str(value['native_pid']), 'exe').resolve().name,
                            receipt_sha256=digest(path))

                    command = [str(sdk / 'bin/flutter'), 'drive', '--no-pub', '-d', 'linux',
                               '--no-dds', f'--host-vmservice-port={port}', f'--device-vmservice-port={port}',
                               '--driver=' + DRIVER, '--target=' + TARGET]
                    result['command'] = command
                    with (evidence / 'native.log').open('wb') as log:
                        code, driver = live.run_owned(['bash', '-c', 'exec "$@" 2>&1', 'transcript', *command],
                            SOURCE, env, timeout=600, stdout=log, observe=on_native)
                    result['exit_code'] = code
                    assert code == 0, f'Native journey failed; inspect {evidence}/native.log'
                    assert observed and not live.live_group(driver) and live.live_group(display_pid)
                    assert digest(path) == observed['receipt_sha256']
                    value = json.loads(path.read_text())
                    validate(value)
                    shutil.copyfile(path, evidence / 'keyboard.json')
                    for name in value['captures']:
                        shutil.copyfile(root / 'cache' / (name + '.png'), evidence / (name + '.png'))
                    renders = {p.name: digest(p) for p in evidence.glob('*.png')}
                    assert renders['tool-unfocused.png'] != renders['tool-focused.png']
                    assert renders['review-unfocused.png'] != renders['review-focused.png']
                    result.update(receipt=value, process=observed, renders=renders,
                                  native_group_gone=True,
                                  native_binary_sha256=digest(SOURCE / 'build/linux/x64/debug/bundle/wing'))
                    raise Finished()

                try:
                    live.run_owned(['/usr/bin/Xvfb', '-displayfd', '1', '-screen', '0', '1440x1000x24',
                                    '-nolisten', 'tcp', '-auth', str(authority)], SOURCE, env,
                                   timeout=650, stdout=display_output, observe=on_display)
                except Finished:
                    result['display']['owned_group_gone'] = True
                else:
                    raise AssertionError('Display exited before GTK result')
            assert inputs() == source, 'Executed source drift'
            result['status'] = 'PASS'
        result['isolated_state_removed'] = True
    finally:
        result['duration_seconds'] = round(time.monotonic() - started, 3)
        (evidence / 'verification.json').write_text(json.dumps(result, indent=2))
        print(json.dumps(dict(evidence=str(evidence), status=result['status'])))


if __name__ == '__main__':
    run()
