"""Task-owned GTK fixture runner. No Agent, personal state or host installation."""

import importlib.util
import json
import os

from pathlib import Path
import shutil
import sys
import time

SOURCE = Path(__file__).resolve().parents[1]


def module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    assert spec is not None and spec.loader is not None
    result = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result


def validate(receipt):
    assert all(type(receipt[key]) is int and receipt[key] == expected
               for key, expected in dict(requests=6, mutations=0, credential_saves=0).items())
    assert all(receipt[k] is True for k in ('denied', 'unsupported', 'cancelled', 'explicit_retry'))
    assert receipt['profile'] == 'default' and receipt['session'] == 'default-session'
    assert type(receipt['native_pid']) is int and receipt['native_pid'] > 0


def run():
    qa = module('serve_qualification_inputs', SOURCE / 'scripts/support/linux_qualification_support.py')
    qa.reject_live(os.environ)
    prefix = qa.dependency_prefix(os.environ)
    live = module('serve_live_helpers', SOURCE / 'scripts/support/desktop_live_workflow.py')
    freeze = module('serve_snapshot_helpers', SOURCE / 'scripts/support/desktop_no_inference_smoke.py')
    attempt = qa.runner_output(os.environ, 'serve-reads-')
    result = {'live_agent_authentication': 'NOT_CHECKED', 'real_secret_acquisition': 'NOT_CHECKED', 'android': 'NOT_CHECKED'}
    start = time.monotonic()
    with qa.record_attempt(attempt, result), live.owned_workspace(attempt) as root:
        app, sdk = root / 'app', root / 'flutter'
        inputs = qa.source_inputs(SOURCE)
        qa.snapshot(SOURCE, app, inputs)
        identity = {'inputs': {name: {'sha256': checksum} for name, checksum in inputs.items()}}
        (attempt / 'source.json').write_text(json.dumps(identity, indent=2))
        executable = shutil.which('flutter')
        assert executable is not None
        sdk_source = Path(executable).resolve().parents[1]
        deps = qa.stage_dependencies(prefix, root / 'deps')
        env = qa.isolated_environment(root, prefix=deps, sdk=sdk, node=shutil.which('node'))
        env['WING_LOCAL_ROOT'] = str(root)
        pub_cache = Path(os.environ['PUB_CACHE']).resolve() if os.environ.get('PUB_CACHE') else None
        qa.prepare(SOURCE, app, sdk_source, sdk, env, pub_cache)
        command = ['xvfb-run', '-a', '-s', '-screen 0 1440x1000x24 -nolisten tcp',
                   str(sdk / 'bin/flutter'), 'test', '--no-pub', '--concurrency=1', '-d', 'linux',
                   'integration_test/linux_local_serve_reads_test.dart']
        with (attempt / 'native.log').open('wb') as log:
            code, driver = live.run_owned(['bash', '-c', 'exec "$@" 2>&1', 'serve', *command],
                                          app, env, timeout=600, stdout=log,
                                          observe=lambda driver: result.update(driver_pid=driver))
        result.update(command=command, exit_code=code, driver_pid=driver, source_manifest_sha256=freeze.digest(attempt / 'source.json'))
        if code:
            raise RuntimeError(f'Native journey failed; inspect {attempt}/native.log')
        receipt = json.loads((root / 'cache/serve-read-receipt.json').read_text())
        validate(receipt)
        assert all(freeze.digest(app / p) == row['sha256'] for p, row in identity['inputs'].items()), 'Executed source changed'
        assert not live.live_group(driver), 'Owned process group survived'
        result.update(receipt=receipt, status='PASS', owned_group_gone=True,
                      duration_seconds=round(time.monotonic() - start, 3))
    print(json.dumps(result))


if __name__ == '__main__':
    if sys.argv[1:] == ['--self-check']:
        receipt = dict(requests=6, mutations=0, credential_saves=0, denied=True, unsupported=True,
                       cancelled=True, explicit_retry=True, profile='default', session='default-session', native_pid=1)
        validate(receipt)
        for key, value in [('requests', 7), ('requests', 6.0), ('mutations', 1),
                           ('mutations', False), ('credential_saves', 1),
                           ('credential_saves', False), ('denied', False)]:
            try:
                validate(receipt | {key: value})
            except AssertionError:
                continue
            raise AssertionError('Invalid receipt accepted')
        print('serve-read runner self-check passed')
    else:
        assert not sys.argv[1:], 'Runner accepts no credentials or target arguments'
        run()
