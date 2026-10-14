"""Task-owned GTK fixture runner. No Agent, personal state or host installation."""

import importlib.util
import json

from pathlib import Path
import shutil
import sys
import tempfile
import time

SOURCE = Path(__file__).resolve().parents[1]


def module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    assert spec is not None and spec.loader is not None
    result = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result


def validate(receipt):
    assert receipt['requests'] == 15 and receipt['mutations'] == 4
    assert (receipt['sends'], receipt['answers'], receipt['stops']) == (2, 1, 1)
    assert (receipt['rpc_requests'], receipt['tickets'], receipt['stale_answers']) == (20, 4, 0)
    assert all(receipt[k] is True for k in ('chat_auth_denied', 'chat_unsupported', 'idle_withdrawal',
                                         'authoritative_stop', 'uncertain_recovery_without_replay'))
    assert receipt['credential_saves'] == 0
    assert all(receipt[k] is True for k in ('denied', 'unsupported', 'cancelled', 'explicit_retry'))
    assert receipt['profile'] == 'default' and receipt['session'] == 'default-session'
    assert type(receipt['native_pid']) is int and receipt['native_pid'] > 0


def run():
    live = module('serve_live_helpers', SOURCE / 'scripts/support/desktop_live_workflow.py')
    freeze = module('serve_snapshot_helpers', SOURCE / 'scripts/support/desktop_no_inference_smoke.py')
    local = module('serve_isolation_helpers', SOURCE / 'scripts/support/local_setup_enrollment_native.py')
    evidence = SOURCE / '.task-evidence/t_45cc9352'
    evidence.mkdir(parents=True, exist_ok=True)
    attempt = Path(tempfile.mkdtemp(prefix='native-', dir=evidence))
    result = {'live_agent_authentication': 'NOT_CHECKED', 'real_secret_acquisition': 'NOT_CHECKED', 'android': 'NOT_CHECKED'}
    start = time.monotonic()
    with live.owned_workspace(attempt) as root:
        app, sdk = root / 'app', root / 'flutter'
        freeze.CARD = 't_45cc9352'
        freeze.OWNED = ()
        freeze.OVERLAYS = ()
        freeze.ROOTS = ('lib', 'test', 'integration_test', 'assets', 'linux', 'scripts', 'playwright/support')
        identity = freeze.freeze(SOURCE, app)
        (attempt / 'source.json').write_text(json.dumps(identity, indent=2))
        executable = shutil.which('flutter')
        assert executable is not None
        sdk_source = Path(executable).resolve().parents[1]
        live.prepare_packages(SOURCE, app, sdk_source, sdk)
        local.freeze_packages(app, root, sdk)
        env = local.isolated_environment(root)
        # Reuse extracted development dependencies; never install system packages.
        deps_source = Path('/home/xel/git/gormes/hermes-wing/.task-evidence/t_636ced72/deps/root')
        deps = root / 'deps'
        shutil.copytree(deps_source, deps, symlinks=True)
        for pc in deps.rglob('*.pc'):
            pc.write_text(pc.read_text().replace(str(deps_source), str(deps)))
        env.update(PKG_CONFIG_PATH=str(deps / 'usr/lib/x86_64-linux-gnu/pkgconfig'),
                   CMAKE_PREFIX_PATH=str(deps / 'usr'), LIBRARY_PATH=str(deps / 'usr/lib/x86_64-linux-gnu'),
                   LD_LIBRARY_PATH=str(deps / 'usr/lib/x86_64-linux-gnu'), CPATH=str(deps / 'usr/include'))
        command = ['xvfb-run', '-a', '-s', '-screen 0 1440x1000x24 -nolisten tcp',
                   str(sdk / 'bin/flutter'), 'test', '--no-pub', '--concurrency=1', '-d', 'linux',
                   'integration_test/linux_local_serve_chat_test.dart']
        with (attempt / 'native.log').open('wb') as log:
            code, driver = live.run_owned(command, app, env, timeout=600, stdout=log)
        result.update(command=command, exit_code=code, driver_pid=driver, source_manifest_sha256=freeze.digest(attempt / 'source.json'))
        if code:
            (attempt / 'verification.json').write_text(json.dumps(result, indent=2))
            raise RuntimeError(f'Native journey failed; inspect {attempt}/native.log')
        receipt = json.loads((root / 'cache/serve-chat-receipt.json').read_text())
        validate(receipt)
        assert all(freeze.digest(app / p) == row['sha256'] for p, row in identity['inputs'].items()), 'Executed source changed'
        result.update(receipt=receipt, status='PASS', duration_seconds=round(time.monotonic() - start, 3))
    result['isolated_state_removed'] = True
    (attempt / 'verification.json').write_text(json.dumps(result, indent=2))
    print(json.dumps(result))


if __name__ == '__main__':
    if sys.argv[1:] == ['--self-check']:
        receipt = dict(requests=15, mutations=4, sends=2, answers=1, stops=1, rpc_requests=20, tickets=4, stale_answers=0,
                       chat_auth_denied=True, chat_unsupported=True, idle_withdrawal=True, authoritative_stop=True,
                       uncertain_recovery_without_replay=True, credential_saves=0, denied=True, unsupported=True,
                       cancelled=True, explicit_retry=True, profile='default', session='default-session', native_pid=1)
        validate(receipt)
        for key, value in [('requests', 16), ('mutations', 5), ('credential_saves', 1), ('denied', False),
                           ('sends', 3), ('answers', 2), ('stale_answers', 1), ('authoritative_stop', False)]:
            try:
                validate(receipt | {key: value})
            except AssertionError:
                continue
            raise AssertionError('Invalid receipt accepted')
        print('serve-chat runner self-check passed')
    else:
        assert not sys.argv[1:], 'Runner accepts no credentials or target arguments'
        run()
