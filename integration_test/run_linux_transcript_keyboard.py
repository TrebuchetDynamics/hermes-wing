"""Current-source GTK transcript keys; isolated Xvfb, not physical input proof."""
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys

SOURCE = Path(__file__).resolve().parents[1]
TARGET = 'integration_test/linux_transcript_keyboard_test.dart'
DRIVER = 'integration_test/support/transcript_keyboard_driver.dart'


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    assert spec is not None and spec.loader is not None
    result = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result


def validate(value):
    assert type(value['native_pid']) is int and value['native_pid'] > 0
    assert type(value['text_scale']) is float and value['text_scale'] == 2.0
    assert value['retired_review_removed'] is True
    assert value['inverse_disclosure_traversal'] is True
    assert type(value['recovery_mutations']) is int and value['recovery_mutations'] == 0
    assert value['mutations'] == ['/v1/runs', '/v1/runs', '/v1/runs/run_2/approval']
    assert value['decisions'] == [dict(path='/v1/runs/run_2/approval', request_id='request_2', choice='deny')]
    assert value['observations'] == [dict(width=w, mutations=m, decisions=0)
                                    for w, m in ((390.0, 1), (1280.0, 1), (390.0, 2), (1280.0, 2), (390.0, 2))]
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
    qa = module('transcript_qualification_inputs', SOURCE / 'scripts/support/linux_qualification_support.py')
    qa.reject_live(os.environ)
    prefix = qa.dependency_prefix(os.environ)
    port = int(os.environ['AUTOWORK_PORT_BASE'])
    assert 1024 <= port <= 65435, 'Owned port range required'
    executable = shutil.which('flutter')
    assert executable is not None, 'Flutter required'
    sdk_source = Path(executable).resolve().parents[1]
    evidence = qa.runner_output(os.environ, 'transcript-keyboard-')
    live = module('transcript_process_helpers', SOURCE / 'scripts/support/desktop_live_workflow.py')
    inputs = qa.source_inputs(SOURCE)
    (evidence / 'source.json').write_text(json.dumps(inputs, indent=2))
    result = dict(status='FAIL', source_manifest_sha256=digest(evidence / 'source.json'),
                  live_agent='NOT_CHECKED', physical_keyboard='NOT_CHECKED', screen_reader='NOT_CHECKED')
    with qa.record_attempt(evidence, result):
        with live.owned_workspace(evidence) as root:
            app, sdk = root / 'app', root / 'flutter'
            qa.snapshot(SOURCE, app, inputs)
            deps = qa.stage_dependencies(prefix, root / 'deps')
            env = qa.isolated_environment(root, prefix=deps, sdk=sdk, node=shutil.which('node'))
            env['WING_TRANSCRIPT_ROOT'] = str(root)
            pub_cache = Path(os.environ['PUB_CACHE']).resolve() if os.environ.get('PUB_CACHE') else None
            qa.prepare(SOURCE, app, sdk_source, sdk, env, pub_cache)
            result['environment'] = dict(uname=list(os.uname()),
                sdk=subprocess.check_output([str(sdk / 'bin/flutter'), '--version'], env=env, timeout=30).decode(),
                engine_stamp_sha256=digest(sdk / 'bin/cache/engine.stamp'),
                pkg_config_versions=subprocess.check_output(['pkg-config', '--modversion', 'gtk+-3.0',
                    'gstreamer-1.0', 'libsecret-1'], env=env, timeout=30).decode(), isolated_home_xdg=True,
                inherited_display_dbus=False, port_base=port)
            path, observed = root / 'cache/keyboard.json', {}
            result['process'] = observed

            def on_native(driver):
                result['driver_pid'] = driver
                if not path.exists() or observed:
                    return
                assert not path.is_symlink() and path.stat().st_size <= 32768
                value = json.loads(path.read_text())
                validate(value)
                fields = Path('/proc', str(value['native_pid']), 'stat').read_text().rsplit(')', 1)[1].split()
                assert fields[0] != 'Z' and int(fields[2]) == driver and driver != value['native_pid']
                observed.update(native_pid=value['native_pid'], driver_pid=driver,
                                start_ticks=fields[19], receipt_sha256=digest(path))

            command = ['xvfb-run', '-a', '-s', '-screen 0 1440x1000x24 -nolisten tcp',
                       str(sdk / 'bin/flutter'), 'drive', '--no-pub', '-d', 'linux', '--no-dds',
                       f'--host-vmservice-port={port}', f'--device-vmservice-port={port}',
                       '--driver=' + DRIVER, '--target=' + TARGET]
            result['command'] = command
            with (evidence / 'native.log').open('wb') as log:
                code, driver = live.run_owned(['bash', '-c', 'exec "$@" 2>&1', 'transcript', *command],
                    app, env, timeout=600, stdout=log, observe=on_native)
            result['exit_code'] = code
            assert code == 0, f'Native journey failed; inspect {evidence}/native.log'
            assert observed and not live.live_group(driver)
            assert digest(path) == observed['receipt_sha256']
            value = json.loads(path.read_text())
            validate(value)
            shutil.copyfile(path, evidence / 'keyboard.json')
            for name in value['captures']:
                shutil.copyfile(root / 'cache' / (name + '.png'), evidence / (name + '.png'))
            renders = {p.name: digest(p) for p in evidence.glob('*.png')}
            assert renders['tool-unfocused.png'] != renders['tool-focused.png']
            assert renders['review-unfocused.png'] != renders['review-focused.png']
            assert qa.source_inputs(app) == inputs and qa.source_inputs(SOURCE) == inputs, 'Executed source drift'
            result.update(status='PASS', receipt=value, process=observed, renders=renders,
                          native_group_gone=True, display={'launcher': 'xvfb-run', 'owned_group_gone': True},
                          native_binary_sha256=digest(app / 'build/linux/x64/debug/bundle/wing'))
        result['isolated_state_removed'] = True
    print(json.dumps(dict(evidence=str(evidence), status=result['status'])))


if __name__ == '__main__':
    run()
