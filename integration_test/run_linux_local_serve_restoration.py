"""Isolated two-process GTK restoration; synthetic backend/storage, no live Agent."""
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import time
import urllib.request

from run_linux_local_serve_chat import module

SOURCE = Path(__file__).resolve().parents[1]


def validate(first, second):
    assert (first['sends'], first['answers'], first['stops']) == (1, 1, 1)
    assert (second['sends'], second['answers'], second['stops']) == (2, 1, 1)
    assert (first['tickets'], first['rpc_requests'], len(first['resumes'])) == (1, 9, 1)
    assert (second['tickets'], second['rpc_requests'], len(second['resumes'])) == (3, 21, 3)
    assert first['native_pid'] > 0 and second['native_pid'] > 0 and first['native_pid'] != second['native_pid']
    assert second['denied_read_recovered'] is True
    for receipt in (first, second):
        assert (receipt['profile'], receipt['stored'], receipt['runtime'], receipt['uncertain']) == ('demo', 'demo-session', 'runtime-demo-session', True)
        assert all(r == {'profile': 'demo', 'session_id': 'demo-session', 'lazy': True} for r in receipt['resumes'])


def run():
    live = module('restoration_live_helpers', SOURCE / 'scripts/support/desktop_live_workflow.py')
    freeze = module('restoration_snapshot_helpers', SOURCE / 'scripts/support/desktop_no_inference_smoke.py')
    local = module('restoration_isolation_helpers', SOURCE / 'scripts/support/local_setup_enrollment_native.py')
    evidence = SOURCE / '.task-evidence/t_d9e374e1'
    evidence.mkdir(parents=True, exist_ok=True)
    attempt = Path(tempfile.mkdtemp(prefix='native-', dir=evidence))
    start = time.monotonic()
    result = dict(live_agent='NOT_CHECKED', os_keyring='NOT_CHECKED', android='NOT_CHECKED')
    with live.owned_workspace(attempt) as root:
        app, sdk = root / 'app', root / 'flutter'
        freeze.CARD, freeze.OWNED, freeze.OVERLAYS = 't_d9e374e1', (), ()
        freeze.ROOTS = ('lib', 'test', 'integration_test', 'assets', 'linux', 'scripts', 'playwright/support')
        identity = freeze.freeze(SOURCE, app)
        (attempt / 'source.json').write_text(json.dumps(identity, indent=2))
        executable = shutil.which('flutter')
        assert executable
        sdk_source = Path(executable).resolve().parents[1]
        live.prepare_packages(SOURCE, app, sdk_source, sdk)
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
        receipts, commands = [], []
        with (attempt / 'fixture.log').open('wb') as fixture_log:
            backend = subprocess.Popen([str(sdk / 'bin/dart'), 'integration_test/support/local_serve_restoration_server.dart'],
                                       cwd=app, env=env, stdout=fixture_log, stderr=subprocess.STDOUT)
            try:
                ready = root / 'cache/serve-restoration-ready.json'
                deadline = time.monotonic() + 30
                while not ready.exists() and time.monotonic() < deadline:
                    assert backend.poll() is None, 'Fixture exited before readiness'
                    time.sleep(.05)
                assert ready.exists(), 'Fixture readiness timed out'
                origin = json.loads(ready.read_text())['origin']
                for phase in ('first', 'second'):
                    if phase == 'second':
                        request = urllib.request.Request(origin + '/fixture/deny', headers={'Authorization': 'Bearer synthetic-serve-owner'})
                        with urllib.request.urlopen(request, timeout=5) as response:
                            assert response.status == 200
                    command = ['xvfb-run', '-a', '-s', '-screen 0 1440x1000x24 -nolisten tcp', str(sdk / 'bin/flutter'),
                               'test', '--no-pub', '--concurrency=1', '-d', 'linux', '--dart-define=SERVE_RESTORATION_PHASE=' + phase,
                               'integration_test/linux_local_serve_restoration_test.dart']
                    commands.append(command)
                    with (attempt / (phase + '.log')).open('wb') as log:
                        code, driver = live.run_owned(command, app, env, timeout=600, stdout=log)
                    assert code == 0, f'{phase} failed; inspect {attempt}/{phase}.log'
                    receipt = json.loads((root / ('cache/serve-restoration-' + phase + '.json')).read_text())
                    receipts.append(receipt)
                validate(*receipts)
                assert all(freeze.digest(app / p) == row['sha256'] for p, row in identity['inputs'].items()), 'Executed source changed'
                result.update(status='PASS', receipts=receipts, commands=commands, source_manifest_sha256=freeze.digest(attempt / 'source.json'))
            finally:
                backend.terminate()
                try:
                    backend.wait(timeout=10)
                except subprocess.TimeoutExpired:
                    backend.kill()
                    backend.wait(timeout=10)
    result.update(isolated_state_removed=True, duration_seconds=round(time.monotonic() - start, 3))
    (attempt / 'verification.json').write_text(json.dumps(result, indent=2))
    print(json.dumps(result))


if __name__ == '__main__':
    assert not sys.argv[1:], 'Runner accepts no credentials or target arguments'
    run()
