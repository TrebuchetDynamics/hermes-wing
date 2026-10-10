"""Read-only first slice of live qualification. Never bootstraps or mutates Agent."""
import contextlib
import hashlib
import http.client
import json
import os
import pathlib
import re
import shutil
import signal
import stat
import subprocess
import sys
import tarfile
import tempfile
import time
import urllib.parse
from typing import IO

OWNED = ('scripts/run_linux_desktop_live_workflow.sh',
         'scripts/support/desktop_live_workflow.py',
         'test/tooling/desktop_live_workflow_test.py',
         'test/tooling/desktop_live_workflow_budget_test.dart',
         'integration_test/linux_desktop_live_workflow_test.dart')
INPUT_ROOTS = ('lib', 'test', 'integration_test', 'assets', 'linux', 'wing_link')
INPUT_FILES = ('pubspec.yaml', 'pubspec.lock', 'analysis_options.yaml', 'l10n.yaml')
PREDECESSOR = '8bdae36cd40bccbf5b7fd6056d395606f01f58db'
OPERATIONS = {
    'sessions': ('GET', '/api/sessions'),
    'session': ('GET', '/api/sessions/{session_id}'),
    'session_messages': ('GET', '/api/sessions/{session_id}/messages'),
    'model_options': ('GET', '/api/model/options'),
    'session_model_lock': ('POST', '/api/sessions/{session_id}/model'),
    'runs': ('POST', '/v1/runs'),
    'run_events': ('GET', '/v1/runs/{run_id}/events'),
    'run_status': ('GET', '/v1/runs/{run_id}'),
    'run_approval': ('POST', '/v1/runs/{run_id}/approval'),
    'run_stop': ('POST', '/v1/runs/{run_id}/stop'),
}
FEATURES = ('run_submission', 'run_events_sse', 'run_status', 'run_stop',
            'run_approval_response', 'approval_events', 'session_model_lock',
            'model_options', 'session_resources')


class Refusal(Exception):
    """Only fixed codes, never caller data or exception strings, reach output."""


def authorize(payload, now=None):
    expected = {'schema', 'mode', 'approved_disposable', 'approved_reads',
                'expires_at', 'origin', 'profile', 'session', 'provider', 'model',
                'api_key', 'generation_limit', 'generations_used'}
    if not isinstance(payload, dict) or set(payload) != expected:
        raise Refusal('INVALID_AUTHORIZATION')
    if type(payload['schema']) is not int or payload['schema'] != 1 or payload['mode'] not in ('read-only', 'live'):
        raise Refusal('INVALID_AUTHORIZATION')
    if payload['approved_disposable'] is not True or payload['approved_reads'] is not True:
        raise Refusal('TARGET_NOT_APPROVED')
    now = time.time() if now is None else now
    expiry = payload['expires_at']
    if type(expiry) not in (int, float) or not now < expiry <= now + 300:
        raise Refusal('AUTHORIZATION_EXPIRED')
    for name in ('profile', 'session'):
        value = payload[name]
        if not isinstance(value, str) or not re.fullmatch(r'[A-Za-z0-9_-]{1,128}', value):
            raise Refusal('INVALID_IDENTITY')
    if (payload['provider'], payload['model']) != ('openai-codex', 'gpt-6.1-sol'):
        raise Refusal('EXACT_MODEL_REQUIRED')
    key = payload['api_key']
    if not isinstance(key, str) or not re.fullmatch(r'[!-~]{16,4096}', key):
        raise Refusal('INVALID_AUTHENTICATION')
    origin = payload['origin']
    if not isinstance(origin, str) or len(origin) > 512:
        raise Refusal('INVALID_TARGET')
    try:
        uri = urllib.parse.urlsplit(origin)
        port = uri.port
    except ValueError:
        raise Refusal('INVALID_TARGET') from None
    if (uri.scheme != 'http' or uri.hostname != '127.0.0.1' or not port or
            uri.username is not None or uri.password is not None or uri.query or
            uri.fragment or uri.path != '/p/' + payload['profile'] or
            uri.netloc != f'127.0.0.1:{port}' or
            origin != f'http://127.0.0.1:{port}/p/{payload["profile"]}'):
        raise Refusal('INVALID_TARGET')
    if (type(payload['generation_limit']) is not int or
            payload['generation_limit'] != 3 or
            type(payload['generations_used']) is not int or
            not 0 <= payload['generations_used'] < 3):
        raise Refusal('USAGE_EXHAUSTED_OR_INVALID')
    # No supported per-provider-call ceiling has been qualified. Three sends do
    # not bound tool continuations; do not turn an owner declaration into billing.
    if payload['mode'] == 'live':
        raise Refusal('LIVE_INFERENCE_BOUND_NOT_QUALIFIED')
    return payload


def require_operations(document):
    if not isinstance(document, dict) or document.get('object') != 'hermes.api_server.capabilities':
        raise Refusal('INVALID_CAPABILITIES')
    schema = document.get('schema_version', 1)
    if document.get('platform') != 'hermes-agent' or type(schema) is not int or schema != 1:
        raise Refusal('UNSUPPORTED_SCHEMA')
    auth = document.get('auth', {})
    if not isinstance(auth, dict) or auth.get('type') != 'bearer' or auth.get('required') is not True:
        raise Refusal('AUTHENTICATED_TARGET_REQUIRED')
    features = document.get('features', {})
    endpoints = document.get('endpoints', {})
    if not isinstance(features, dict) or not isinstance(endpoints, dict):
        raise Refusal('INVALID_CAPABILITIES')
    if any(features.get(name) is not True for name in FEATURES):
        raise Refusal('REQUIRED_OPERATION_UNAVAILABLE')
    grants = auth.get('granted_scopes', [])
    if not isinstance(grants, list) or any(not isinstance(g, str) for g in grants):
        raise Refusal('INVALID_CAPABILITIES')
    for name, (method, path) in OPERATIONS.items():
        endpoint = endpoints.get(name)
        if not isinstance(endpoint, dict) or (endpoint.get('method'), endpoint.get('path')) != (method, path):
            raise Refusal('REQUIRED_OPERATION_UNAVAILABLE')
        scopes = endpoint.get('required_scopes', [])
        if not isinstance(scopes, list) or any(not isinstance(s, str) for s in scopes):
            raise Refusal('INVALID_CAPABILITIES')
        if '*' not in grants and any(scope not in grants for scope in scopes):
            raise Refusal('REQUIRED_GRANT_UNAVAILABLE')
        if endpoint.get('profile_scoped'):
            context = document.get('profile_context', {})
            if context != {'type': 'query', 'name': 'profile', 'required': True,
                           'default_profile_id': 'default'}:
                raise Refusal('PROFILE_CONTEXT_UNAVAILABLE')


def read_capabilities(authorization):
    uri = urllib.parse.urlsplit(authorization['origin'])
    connection = http.client.HTTPConnection('127.0.0.1', uri.port, timeout=5)
    try:
        connection.request('GET', uri.path + '/v1/capabilities', headers={
            'Authorization': 'Bearer ' + authorization['api_key'], 'Accept': 'application/json'})
        response = connection.getresponse()
        if response.status != 200:
            raise Refusal('AUTHORITY_READ_REJECTED')
        raw = response.read(65537)
        if len(raw) > 65536:
            raise Refusal('CAPABILITIES_TOO_LARGE')
        document = json.loads(raw)
        require_operations(document)
        return {'status': 'READ_ONLY_PREFLIGHT_PASS', 'read_requests': 1,
                'mutations': 0, 'inference_count': 0, 'live_workflow': 'NOT_CHECKED'}
    finally:
        connection.close()


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


_cancellation_depth = 0


@contextlib.contextmanager
def cancellation_scope():
    """Keep repeated cancellation from interrupting process/state teardown."""
    global _cancellation_depth
    if _cancellation_depth:
        yield
        return
    def interrupted(signum, frame):
        for sig in (signal.SIGINT, signal.SIGTERM):
            signal.signal(sig, signal.SIG_IGN)
        raise Refusal('NATIVE_CANCELLED')
    previous = {s: signal.signal(s, interrupted) for s in (signal.SIGINT, signal.SIGTERM)}
    _cancellation_depth += 1
    try:
        yield
    finally:
        _cancellation_depth -= 1
        for sig, handler in previous.items():
            signal.signal(sig, handler)


def git_output(command, cwd):
    with tempfile.TemporaryFile() as output:
        code, _ = run_owned(['git', *command], cwd, os.environ.copy(),
                            timeout=30, stdout=output)
        if code:
            raise Refusal('SNAPSHOT_FAILED')
        output.seek(0)
        return output.read().decode().strip()


@contextlib.contextmanager
def owned_workspace(scratch):
    """Never delete state underneath a group whose teardown could not finish."""
    root = pathlib.Path(tempfile.mkdtemp(prefix='wing-linux-live.', dir=scratch))
    preserve = False
    try:
        yield root
    except Refusal as error:
        preserve = str(error) == 'OWNED_TEARDOWN_INCOMPLETE'
        raise
    finally:
        if not preserve:
            shutil.rmtree(root)


@cancellation_scope()
def snapshot(source, destination, revision=PREDECESSOR):
    """Freeze committed production inputs + only this card's attributed overlays."""
    source, destination = pathlib.Path(source).resolve(), pathlib.Path(destination)
    destination.mkdir()  # Fail rather than reuse somebody else's build/state.
    revision = git_output(['rev-parse', revision], source)
    with tempfile.TemporaryFile() as archive:
        code, _ = run_owned(['git', 'archive', revision, *INPUT_ROOTS, *INPUT_FILES],
                            source, os.environ.copy(), timeout=60, stdout=archive)
        if code:
            raise Refusal('SNAPSHOT_FAILED')
        archive.seek(0)
        with tarfile.open(fileobj=archive, mode='r|') as bundle:
            bundle.extractall(destination, filter='data')
    overlays = {}
    for name in OWNED:
        path = source / name
        before = digest(path)
        target = destination / name
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(path, target)
        if digest(path) != before or digest(target) != before:
            raise Refusal('SOURCE_CHANGED_DURING_SNAPSHOT')
        overlays[name] = before
    dirty = git_output(['diff', '--name-only', revision, '--',
                        *INPUT_ROOTS, *INPUT_FILES], source).splitlines()
    dirty += git_output(['ls-files', '--others', '--exclude-standard', '--',
                         *INPUT_ROOTS, *INPUT_FILES], source).splitlines()
    excluded_dirty = {name: digest(source / name) for name in dirty
                      if name not in OWNED and (source / name).is_file()}
    manifest = {str(p.relative_to(destination)): digest(p)
                for p in sorted(destination.rglob('*')) if p.is_file()}
    identity = {'base_revision': revision, 'overlay_owner': 't_2e1f363d',
                'predecessor': PREDECESSOR,
                'overlays': overlays, 'inputs': manifest, 'excluded_dirty_hashes': excluded_dirty,
                'excluded': ['all other dirty files', 'upstream clones', 'vendor', 'runtime state']}
    return identity


def prepare_packages(source, app, sdk, copied_sdk):
    code, _ = run_owned(['cp', '-a', '--reflink=auto', str(sdk), str(copied_sdk)],
                        source, os.environ.copy(), timeout=120)
    if code:
        raise Refusal('SDK_COPY_FAILED')
    config_path = pathlib.Path(source) / '.dart_tool/package_config.json'
    config = json.loads(config_path.read_text())
    for package in config['packages']:
        parsed = urllib.parse.urlsplit(package['rootUri'])
        if parsed.scheme not in ('', 'file'):
            raise Refusal('NONLOCAL_PACKAGE_ROOT')
        root = pathlib.Path(urllib.parse.unquote(parsed.path))
        root = (root if root.is_absolute() else config_path.parent / root).resolve()
        if root == pathlib.Path(source).resolve():
            root = pathlib.Path(app).resolve()
        elif root.is_relative_to(sdk):
            root = copied_sdk / root.relative_to(sdk)
        elif root.is_relative_to(pathlib.Path(source).resolve()):
            raise Refusal('UNATTRIBUTED_LOCAL_DEPENDENCY')
        package['rootUri'] = root.as_uri()
    (app / '.dart_tool').mkdir()
    (app / '.dart_tool/package_config.json').write_text(json.dumps(config) + '\n')
    shutil.copy2(pathlib.Path(source) / '.dart_tool/package_graph.json', app / '.dart_tool/package_graph.json')
    plugins_path = pathlib.Path(source) / '.flutter-plugins-dependencies'
    plugins = json.loads(plugins_path.read_text())
    for rows in plugins['plugins'].values():
        for row in rows:
            path = pathlib.Path(row['path']).resolve()
            if path.is_relative_to(sdk):
                row['path'] = str(copied_sdk / path.relative_to(sdk)) + '/'
    (app / '.flutter-plugins-dependencies').write_text(json.dumps(plugins) + '\n')


@cancellation_scope()
def native_readiness(source, authorization):
    """No inference. Owned SDK, display and preferences; child output discarded."""
    scratch = pathlib.Path(source) / 'build'
    scratch.mkdir(exist_ok=True)
    with owned_workspace(scratch) as root:
        app, sdk = root / 'app', root / 'flutter'
        identity = snapshot(source, app)
        flutter = shutil.which('flutter')
        if flutter is None:
            raise Refusal('FLUTTER_UNAVAILABLE')
        installed_sdk = pathlib.Path(flutter).resolve().parent.parent
        prepare_packages(source, app, installed_sdk, sdk)
        # Build preparation can consume most of the approval window. Revalidate
        # before launching the child, not just when stdin was first accepted.
        authorize(authorization)
        env = {key: os.environ[key] for key in ('PATH', 'LANG', 'PKG_CONFIG_PATH',
               'CMAKE_PREFIX_PATH', 'LIBRARY_PATH', 'CPATH') if key in os.environ}
        for name in ('home', 'config', 'data', 'cache', 'runtime'):
            (root / name).mkdir(mode=0o700)
        env.update(HOME=str(root / 'home'), XDG_CONFIG_HOME=str(root / 'config'),
                   XDG_DATA_HOME=str(root / 'data'), XDG_CACHE_HOME=str(root / 'cache'),
                   XDG_RUNTIME_DIR=str(root / 'runtime'), GDK_BACKEND='x11',
                   LIBGL_ALWAYS_SOFTWARE='1', CMAKE_BUILD_PARALLEL_LEVEL='2',
                   TMPDIR=str(root / 'cache'), GOCACHE=str(root / 'cache/go-build'),
                   GOMAXPROCS='2', GOFLAGS='-p=2', GOPROXY='off', GOSUMDB='off', GOTOOLCHAIN='local',
                   GOMODCACHE=os.environ.get('GOMODCACHE', str(pathlib.Path.home() / 'go/pkg/mod')),
                   PUB_CACHE=os.environ.get('PUB_CACHE', str(pathlib.Path.home() / '.pub-cache')),
                   WING_LIVE_AUTH=json.dumps(authorization), WING_LIVE_ROOT=str(root))
        command = ['timeout', '--signal=TERM', '--kill-after=10s', '300s', 'xvfb-run',
                   '-a', '-s', '-screen 0 1440x1000x24 -nolisten tcp', str(sdk / 'bin/flutter'),
                   'test', '--no-pub', '--concurrency=1', '-d', 'linux',
                   'integration_test/linux_desktop_live_workflow_test.dart']
        started = time.monotonic()
        code, child_pid = run_owned(command, app, env)
        return {'status': 'NATIVE_READINESS_PASS' if code == 0 else 'NATIVE_READINESS_FAIL',
                'exit': code, 'process_pid': child_pid, 'owned_group_gone': True,
                'duration_seconds': round(time.monotonic() - started, 3),
                'source': identity,
                'sdk_revision': git_output(['rev-parse', 'HEAD'], sdk),
                'package_config_sha256': digest(app / '.dart_tool/package_config.json'),
                'plugins_sha256': digest(app / '.flutter-plugins-dependencies'),
                'mutations': 0, 'inference_count': 0,
                'live_workflow': 'NOT_CHECKED'}


def read_phase(path, phase, owner):
    """Admit only the prepared Dart driver's bounded, content-free contract."""
    def unique(pairs):
        result = {}
        for key, value in pairs:
            if key in result:
                raise Refusal('INVALID_PHASE_RECEIPT')
            result[key] = value
        return result
    try:
        fd = os.open(path, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK)
        with os.fdopen(fd, 'rb') as stream:
            info = os.fstat(stream.fileno())
            if not stat.S_ISREG(info.st_mode) or info.st_size > 4096:
                raise Refusal('INVALID_PHASE_RECEIPT')
            raw = stream.read(4097)
        value = json.loads(raw, object_pairs_hook=unique)
        fields = {'phase', 'native_pid', 'run_id', 'message_count', 'history_identity',
                  'owner_identity', 'counts', 'canonical_status', 'provider_calls'}
        if not isinstance(value, dict) or set(value) != fields or len(raw) > 4096:
            raise Refusal('INVALID_PHASE_RECEIPT')
        if (value['phase'] != phase or value['owner_identity'] != owner or
                not isinstance(value['history_identity'], str) or
                not re.fullmatch('[0-9a-f]{64}', value['history_identity']) or
                not isinstance(value['run_id'], str) or
                not re.fullmatch('[A-Za-z0-9_-]{1,128}', value['run_id'])):
            raise Refusal('INVALID_PHASE_IDENTITY')
        for key, lower, upper in (('native_pid', 1, 2 ** 31 - 1),
                                  ('message_count', 0, 1000000)):
            if type(value[key]) is not int or not lower <= value[key] <= upper:
                raise Refusal('INVALID_PHASE_RECEIPT')
        calls = value['provider_calls']
        if calls is not None and (type(calls) is not int or not 0 <= calls <= 1000000):
            raise Refusal('INVALID_PHASE_RECEIPT')
        counts = {'submits': 1, 'approvals': int(phase == 'write'),
                  'stops': int(phase == 'write'), 'model_locks': 1}
        if (value['counts'] != counts or
                any(type(n) is not int for n in value['counts'].values()) or
                value['canonical_status'] != ('cancelled' if phase == 'write' else 'completed')):
            raise Refusal('INVALID_PHASE_RESULT')
        return value, hashlib.sha256(raw).hexdigest()
    except (OSError, ValueError, TypeError):
        raise Refusal('INVALID_PHASE_RECEIPT') from None


@cancellation_scope()
def two_phase_runner(app, root, env, owner, *, _command=None, _display_pid=None):
    """Internal orchestration seam; no public argument selects an executable.

    The fixed production driver still refuses before network. A synthetic command
    is injected only by Python tests; success here never qualifies inference.
    Caller owns preparation/display and keeps them alive through both phases.
    """
    receipts, drivers = [], []
    paths = [root / 'cache' / f'live-{phase}.json' for phase in ('write', 'verify')]
    if any(p.exists() or p.is_symlink() for p in paths):
        raise Refusal('STALE_PHASE_RECEIPT')
    for phase, path in zip(('write', 'verify'), paths):
        if _display_pid is not None and not live_group(_display_pid):
            raise Refusal('OWNED_DISPLAY_FAILED')
        if receipts and read_phase(paths[0], 'write', owner)[1] != receipts[0][1]:
            raise Refusal('PHASE_HANDOFF_CHANGED')
        observed = {}
        def observe(driver_pid):
            if not path.exists() and not path.is_symlink():
                return
            value, checksum = read_phase(path, phase, owner)
            native = value['native_pid']
            if native == driver_pid:
                raise Refusal('DRIVER_IS_NOT_APP')
            if observed and observed != {'pid': native, 'sha256': checksum}:
                raise Refusal('PHASE_RECEIPT_CHANGED')
            if not observed:
                try:
                    fields = pathlib.Path(f'/proc/{native}/stat').read_text().rsplit(')', 1)[1].split()
                    if int(fields[2]) != driver_pid or fields[0] == 'Z':
                        raise Refusal('APP_IDENTITY_NOT_OWNED')
                except (OSError, ValueError, IndexError):
                    raise Refusal('APP_IDENTITY_NOT_OWNED') from None
                observed.update(pid=native, sha256=checksum)
        command = (_command(phase) if _command else
                   [str(root / 'flutter/bin/flutter'), 'test', '--no-pub',
                    '--concurrency=1', '-d', 'linux',
                    'integration_test/linux_desktop_live_workflow_test.dart'])
        code, driver = run_owned(command, app, env | {'WING_LIVE_PHASE': phase},
                                 timeout=300, observe=observe)
        if code:
            raise Refusal('NATIVE_PHASE_FAILED')
        value, checksum = read_phase(path, phase, owner)
        if not observed or observed['sha256'] != checksum:
            raise Refusal('APP_IDENTITY_NOT_OBSERVED')
        if receipts:
            previous, previous_checksum = read_phase(paths[0], 'write', owner)
            if previous_checksum != receipts[0][1]:
                raise Refusal('PHASE_HANDOFF_CHANGED')
            if (value['native_pid'] == previous['native_pid'] or driver in drivers or
                    value['run_id'] == previous['run_id'] or
                    value['message_count'] < previous['message_count']):
                raise Refusal('INVALID_RELAUNCH_IDENTITY')
        receipts.append((value, checksum))
        drivers.append(driver)
    return {'status': 'TWO_PHASE_CONTROL_FLOW_PASS', 'live_workflow': 'NOT_CHECKED',
            'phases': [{'phase': value['phase'], 'driver_pid': driver,
                        'app_pid': value['native_pid'], 'receipt_sha256': checksum,
                        'owned_group_gone': True}
                       for (value, checksum), driver in zip(receipts, drivers)]}


@cancellation_scope()
def prepared_two_process(source, *, _prepare=None, _display=None, _command=None,
                         _owner=None):
    """Prepare exactly one workspace/state/display for the internal phase runner.

    Not wired to public live authorization. Without test injection, the prepared
    Dart driver fails closed. No authentication is discovered or inferred.
    """
    scratch = pathlib.Path(source) / 'build'
    scratch.mkdir(exist_ok=True)
    with owned_workspace(scratch) as root:
        app, sdk = root / 'app', root / 'flutter'
        identity = snapshot(source, app)
        flutter = shutil.which('flutter')
        if flutter is None and _prepare is None:
            raise Refusal('FLUTTER_UNAVAILABLE')
        if _prepare:
            _prepare(source, app, root)
        else:
            assert flutter is not None
            prepare_packages(source, app, pathlib.Path(flutter).resolve().parent.parent, sdk)
        env = {k: os.environ[k] for k in ('PATH', 'LANG') if k in os.environ}
        for name in ('home', 'config', 'data', 'cache', 'runtime'):
            (root / name).mkdir(mode=0o700)
        env.update(HOME=str(root / 'home'), XDG_CONFIG_HOME=str(root / 'config'),
                   XDG_DATA_HOME=str(root / 'data'), XDG_CACHE_HOME=str(root / 'cache'),
                   XDG_RUNTIME_DIR=str(root / 'runtime'), TMPDIR=str(root / 'cache'),
                   WING_LIVE_ROOT=str(root), GDK_BACKEND='x11',
                   LIBGL_ALWAYS_SOFTWARE='1', CMAKE_BUILD_PARALLEL_LEVEL='2',
                   GOMAXPROCS='2', GOFLAGS='-p=2', GOPROXY='off', GOSUMDB='off',
                   GOTOOLCHAIN='local', GOCACHE=str(root / 'cache/go-build'))
        # Xvfb selects a free display and reports it on an owned pipe, not a
        # caller-chosen shared display. Keep its process group through both phases.
        with tempfile.TemporaryFile(dir=root / 'cache') as display_file:
            display_command = (_display(display_file.fileno()) if _display else
                               ['Xvfb', '-displayfd', '1', '-screen', '0',
                                '1440x1000x24', '-nolisten', 'tcp'])
            display_deadline = time.monotonic() + 10
            def phases(display_pid):
                display_file.seek(0)
                number = display_file.read(17)
                if not re.fullmatch(rb'[0-9]{1,5}\n', number):
                    if time.monotonic() >= display_deadline:
                        raise Refusal('OWNED_DISPLAY_FAILED')
                    return
                env['DISPLAY'] = ':' + number.decode().strip()
                result = two_phase_runner(app, root, env, _owner or '0' * 64,
                                          _command=_command, _display_pid=display_pid)
                if not live_group(display_pid):
                    raise Refusal('OWNED_DISPLAY_FAILED')
                result['source'] = identity
                # Terminate the display only after the phase runner has fully
                # torn down both groups. Raising unwinds through run_owned cleanup.
                raise _PhasesFinished(result)
            try:
                run_owned(display_command, app, env, timeout=620,
                          stdout=display_file, observe=phases)
            except _PhasesFinished as finished:
                return finished.receipt
            raise Refusal('OWNED_DISPLAY_FAILED')


class _PhasesFinished(Exception):
    def __init__(self, receipt):
        self.receipt = receipt


def live_group(pgid):
    for process in pathlib.Path('/proc').iterdir():
        try:
            fields = (process / 'stat').read_text().rsplit(')', 1)[1].split()
            if int(fields[2]) == pgid and fields[0] != 'Z':
                return True
        except (OSError, ValueError, IndexError):
            continue  # Process can disappear while enumerating /proc.
    return False


@cancellation_scope()
def run_owned(command, cwd, env, timeout=320, stdout: int | IO = subprocess.DEVNULL,
              observe=None):
    # Defer cancellation while acquiring the child identity, without passing
    # a blocked signal mask to the executable or its descendants.
    signals = (signal.SIGINT, signal.SIGTERM)
    cancelled = False
    def spawning_interrupted(signum, frame):
        nonlocal cancelled
        cancelled = True
        for sig in signals:
            signal.signal(sig, signal.SIG_IGN)
    handlers = {s: signal.signal(s, spawning_interrupted) for s in signals}
    child = None
    try:
        child = subprocess.Popen(command, cwd=cwd, env=env, stdout=stdout,
                                 stderr=subprocess.DEVNULL, start_new_session=True,
                                 restore_signals=True)
        if cancelled:
            raise Refusal('NATIVE_CANCELLED')
        for sig, handler in handlers.items():
            signal.signal(sig, handler)
        if cancelled:
            raise Refusal('NATIVE_CANCELLED')
        if observe is None:
            return child.wait(timeout=timeout), child.pid
        deadline = time.monotonic() + timeout
        while child.poll() is None:
            observe(child.pid)
            if time.monotonic() >= deadline:
                raise subprocess.TimeoutExpired(command, timeout)
            time.sleep(0.02)
        observe(child.pid)
        return child.returncode, child.pid
    finally:
        # Teardown finishes before the temporary SDK/preferences are removed.
        previous = {s: signal.signal(s, signal.SIG_IGN) for s in signals}
        try:
            if child is not None:
                for sig in (signal.SIGTERM, signal.SIGKILL):
                    try:
                        os.killpg(child.pid, sig)
                    except ProcessLookupError:
                        break
                    except OSError:
                        raise Refusal('OWNED_TEARDOWN_INCOMPLETE') from None
                    deadline = time.monotonic() + 3
                    while live_group(child.pid) and time.monotonic() < deadline:
                        time.sleep(0.02)
                    if not live_group(child.pid):
                        break
                try:
                    child.wait(timeout=3)
                except subprocess.TimeoutExpired:
                    raise Refusal('OWNED_TEARDOWN_INCOMPLETE') from None
                if live_group(child.pid):
                    raise Refusal('OWNED_TEARDOWN_INCOMPLETE')
            elif cancelled:
                raise Refusal('NATIVE_CANCELLED')
        finally:
            for s, handler in (previous if child is not None else handlers).items():
                signal.signal(s, handler)


def main(argv=None, stdin=None):
    argv = sys.argv[1:] if argv is None else argv
    started = time.monotonic()
    reads = 0
    receipt: dict[str, object]
    try:
        if argv not in ([], ['--native-read-only']):
            raise Refusal('INVALID_ARGUMENTS_USE_STDIN')
        stream = sys.stdin if stdin is None else stdin
        if stream.isatty():
            raise Refusal('AUTHORIZATION_REQUIRED_NO_NETWORK')
        raw = stream.read(16385)
        if not raw:
            raise Refusal('AUTHORIZATION_REQUIRED_NO_NETWORK')
        if len(raw) > 16384:
            raise Refusal('AUTHORIZATION_TOO_LARGE')
        authorization = authorize(json.loads(raw))
        reads = 1
        receipt = read_capabilities(authorization)
        if argv:
            receipt = native_readiness(pathlib.Path(__file__).resolve().parents[2], authorization)
        code = receipt.get('exit', 0)
    except Refusal as error:
        receipt = {'status': str(error)}
        code = 2
    except (OSError, ValueError, TypeError, subprocess.SubprocessError,
            http.client.HTTPException, tarfile.TarError):
        receipt = {'status': 'READINESS_FAILED_REDACTED'}
        code = 2
    receipt.update(read_requests_attempted=reads, mutations=0, inference_count=0,
                   live_workflow='NOT_CHECKED', duration_seconds=round(time.monotonic() - started, 3))
    print(json.dumps(receipt, sort_keys=True))
    return code


if __name__ == '__main__':
    sys.exit(main())
