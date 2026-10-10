"""Disposable full-app SSH fixture/preparation. Native execution is opt-in.

No user SSH configuration, keys, Agent runtime, or Wing Link listener is used.
The document picker is deliberately substituted; it remains NOT_CHECKED.
"""
import argparse
import asyncio
import base64
import collections
import hashlib
import hmac
import json
import logging
import os
import pathlib
import secrets
import shutil
import signal
import subprocess
import sys
import time


def mapping(lane, mode):
    if lane == 'linux' and mode is None:
        return '127.0.0.1'
    if lane == 'android' and mode == 'adb-reverse':
        return '127.0.0.1'
    raise ValueError('Android requires explicit owned adb-reverse mapping')


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def inputs(source):
    names = ('lib', 'assets', 'test', 'integration_test', 'linux', 'android',
             'wing_link', 'third_party', 'vendor', 'scripts/support',
             'pubspec.yaml', 'pubspec.lock', 'analysis_options.yaml', 'l10n.yaml')
    result = {}
    excluded = {'build', '.gradle', '.dart_tool', 'ephemeral', '__pycache__',
                'node_modules', '.git', 'local.properties', 'key.properties'}
    for name in names:
        entry = source / name
        candidates = sorted(entry.rglob('*')) if entry.is_dir() else [entry]
        for path in candidates:
            relative = path.relative_to(source)
            if any(part in excluded for part in relative.parts):
                continue
            if path.is_symlink():
                raise ValueError('Source symlinks require explicit review')
            if path.is_file():
                result[str(relative)] = sha(path)
    return result


def freeze(source, destination):
    source, destination = source.resolve(), destination.resolve()
    if destination.exists() or destination.is_relative_to(source):
        raise ValueError('Fresh external snapshot required')
    before = inputs(source)
    destination.mkdir(parents=True, mode=0o700)
    for name in before:
        target = destination / name
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source / name, target)
    if inputs(source) != before or inputs(destination) != before:
        raise RuntimeError('Source changed during freeze; retry after integration')
    return {'scope': 'copied source inputs only; SDK/packages/runtime assets excluded',
            'inputs': before}


def verify_product(app, manifest):
    for name, expected in manifest['inputs'].items():
        if name.startswith(('lib/', 'integration_test/')) and sha(app / name) != expected:
            raise RuntimeError('Frozen product/test source changed during native build')


class Agent:
    def __init__(self, token):
        self.token = token
        self.requests = collections.Counter()
        self.mutations = self.forbidden = self.denials = 0

    def summary(self):
        return {'requests': dict(sorted(self.requests.items())),
                'mutation_attempts': self.mutations,
                'forbidden_reads': self.forbidden, 'auth_denials': self.denials}

    def respond(self, method, target, headers, body):
        from urllib.parse import urlsplit, parse_qs
        uri = urlsplit(target)
        path = uri.path
        if not hmac.compare_digest(headers.get('authorization', ''), 'Bearer ' + self.token):
            self.denials += 1
            return 401, {'error': 'Unauthorized'}
        if method != 'GET':
            self.mutations += 1
            return 405, {'error': 'Read only'}
        profile = parse_qs(uri.query).get('profile', [''])[0]
        allowed = {'/health', '/v1/capabilities', '/api/profiles'}
        scoped = {'/api/sessions', '/api/sessions/qa-history',
                  '/api/sessions/qa-history/messages', '/api/model/options'}
        if path not in allowed and not (path in scoped and profile in {'default', 'qa-key'}):
            self.forbidden += 1
            return 404, {'error': 'Unavailable'}
        if sum(self.requests.values()) >= 256:
            raise RuntimeError('Bounded fixture request budget exhausted')
        self.requests[f'GET {path}'] += 1
        if path == '/health':
            return 200, {'status': 'ok'}
        if path == '/v1/capabilities':
            endpoints = {'profiles': '/api/profiles', 'sessions': '/api/sessions',
                         'session': '/api/sessions/{session_id}',
                         'session_messages': '/api/sessions/{session_id}/messages',
                         'model_options': '/api/model/options'}
            return 200, {'schema_version': 1,
                'profile_context': {'type': 'query', 'name': 'profile',
                    'required': True, 'default_profile_id': 'default'},
                'auth': {'type': 'bearer', 'required': True,
                    'granted_scopes': ['profiles:read', 'sessions:read', 'models:read']},
                'features': {'model_options': True},
                'endpoints': {key: {'method': 'GET', 'path': value,
                    'profile_scoped': key != 'profiles',
                    'required_scopes': ['profiles:read' if key == 'profiles' else
                        'models:read' if key == 'model_options' else 'sessions:read']}
                    for key, value in endpoints.items()}}
        if path == '/api/profiles':
            return 200, {'data': [{'id': 'qa-key', 'name': 'Key QA'}]}
        row = {'id': 'qa-history', 'title': 'Key QA history', 'source': 'api_server',
               'profile_id': profile, 'message_count': 1,
               'runtime': {'provider': 'synthetic', 'model': 'synthetic/model'}}
        if path == '/api/sessions':
            return 200, {'data': [row], 'has_more': False}
        if path == '/api/sessions/qa-history':
            return 200, {'object': 'hermes.session', 'session': row}
        if path.endswith('/messages'):
            return 200, {'object': 'list', 'session_id': 'qa-history', 'data': [
                {'id': 'qa-message', 'session_id': 'qa-history', 'role': 'assistant',
                 'content': 'Disposable SSH key history'}]}
        return 200, {'provider': 'synthetic', 'model': 'synthetic/model', 'providers': [
            {'slug': 'synthetic', 'label': 'Synthetic', 'authenticated': True,
             'models': ['synthetic/model']}]}


class Fixture:
    async def __aenter__(self):
        import asyncssh
        self.agent = Agent(secrets.token_urlsafe(32))
        self.connections = set()
        self.ssh_auths = self.ssh_denials = self.forwards = self.forbidden_ssh = 0
        self.hold = False
        self.release = asyncio.Event()
        host_key = asyncssh.generate_private_key('ssh-ed25519')
        self.client_key = asyncssh.generate_private_key('ssh-ed25519')
        wrong = asyncssh.generate_private_key('ssh-ed25519')
        self.http = await asyncio.start_server(self.serve_agent, '127.0.0.1', 0, limit=8192)
        self.agent_port = self.http.sockets[0].getsockname()[1]
        self.control = await asyncio.start_server(self.serve_control, '127.0.0.1', 0, limit=8192)
        owner = self

        class Server(asyncssh.SSHServer):
            def connection_made(self, conn):
                self.conn = conn
                owner.connections.add(conn)

            def connection_lost(self, exc):
                owner.connections.discard(self.conn)

            def begin_auth(self, username):
                return True

            def public_key_auth_supported(self):
                return True

            def validate_public_key(self, username, key):
                accepted = username == 'wing-test' and key == owner.client_key.convert_to_public()
                if not accepted:
                    owner.ssh_denials += 1
                return accepted

            def auth_completed(self):
                owner.ssh_auths += 1

            def connection_requested(self, host, port, orig_host, orig_port):
                if host == '127.0.0.1' and port == owner.agent_port:
                    owner.forwards += 1
                    return True
                owner.forbidden_ssh += 1
                return False

            def session_requested(self):
                owner.forbidden_ssh += 1
                return False

            def server_requested(self, host, port):
                owner.forbidden_ssh += 1
                return False

        try:
            self.ssh = await asyncssh.create_server(Server, '127.0.0.1', 0,
                server_host_keys=[host_key], config=None, encoding=None,
                password_auth=False, kbdint_auth=False, allow_scp=False,
                sftp_factory=None, agent_forwarding=False, x11_forwarding=False,
                allow_pty=False, login_timeout=10)
        except BaseException:
            await self.__aexit__(None, None, None)
            raise
        self.runtime = {'host': '127.0.0.1', 'ssh_port': self.ssh.get_port(),
            'agent_port': self.agent_port, 'control_port': self.control.sockets[0].getsockname()[1],
            'username': 'wing-test', 'agent_token': self.agent.token,
            'fingerprint': host_key.get_fingerprint('sha256'),
            'valid_key': self.client_key.export_private_key().decode(),
            'wrong_key': wrong.export_private_key().decode(), 'invalid_key': 'not a private key',
            'picker': 'BOUNDED_DOCUMENT_SUBSTITUTE', 'native_picker': 'NOT_CHECKED'}
        return self

    def summary(self):
        return dict(self.agent.summary(), ssh_auths=self.ssh_auths,
            ssh_denials=self.ssh_denials, forwards=self.forwards,
            forbidden_ssh=self.forbidden_ssh, live_ssh=len(self.connections))

    async def read_request(self, reader):
        raw = await asyncio.wait_for(reader.readuntil(b'\r\n\r\n'), 5)
        lines = raw.decode('ascii').split('\r\n')
        method, target, _ = lines[0].split(' ')
        headers = {line.split(': ', 1)[0].lower(): line.split(': ', 1)[1]
                   for line in lines[1:] if ': ' in line}
        # Reject all body-bearing requests, never consume/log secret or mutation bodies.
        return method, target, headers

    async def reply(self, writer, status, value):
        body = json.dumps(value).encode()
        writer.write(f'HTTP/1.1 {status} Fixture\r\nContent-Type: application/json\r\nCache-Control: no-store\r\nConnection: close\r\nContent-Length: {len(body)}\r\n\r\n'.encode() + body)
        await writer.drain()

    async def serve_agent(self, reader, writer):
        try:
            method, target, headers = await self.read_request(reader)
            if target.split('?')[0] == '/v1/capabilities' and self.hold:
                await asyncio.wait_for(self.release.wait(), 20)
            status, body = self.agent.respond(method, target, headers, '')
            await self.reply(writer, status, body)
        except (ConnectionError, asyncio.TimeoutError, asyncio.IncompleteReadError):
            # A deliberately cancelled bootstrap closes its client socket.
            return
        except ValueError:
            self.agent.forbidden += 1
        finally:
            writer.close()
            await writer.wait_closed()

    async def serve_control(self, reader, writer):
        try:
            method, target, _ = await self.read_request(reader)
            if method == 'GET' and target == '/stats':
                value = self.summary()
            elif method == 'POST' and target == '/hold':
                self.hold = True
                self.release.clear()
                value = {'held': True}
            elif method == 'POST' and target == '/release':
                self.hold = False
                self.release.set()
                value = {'released': True}
            else:
                await self.reply(writer, 404, {'error': 'Unavailable'})
                return
            await self.reply(writer, 200, value)
        finally:
            writer.close()
            await writer.wait_closed()

    async def __aexit__(self, *args):
        self.release.set()
        for name in ('ssh', 'http', 'control'):
            server = getattr(self, name, None)
            if server:
                server.close()
                await server.wait_closed()
        connections = tuple(self.connections)
        for conn in connections:
            conn.close()
        await asyncio.gather(*(c.wait_closed() for c in connections), return_exceptions=True)
        if getattr(self, 'runtime', None) is not None:
            self.runtime.clear()
        self.runtime = None
        self.client_key = None
        self.agent.token = ''



async def probe_fixture():
    """Fixture protocol/cleanup proof, explicitly not Wing/native evidence."""
    import asyncssh
    async with Fixture() as fixture:
        runtime = fixture.runtime
        assert runtime is not None
        expected = runtime['fingerprint']
        class PinnedClient(asyncssh.SSHClient):
            def validate_host_public_key(self, host, addr, port, key):
                return hmac.compare_digest(key.get_fingerprint('sha256'), expected)
        common = dict(host='127.0.0.1', port=runtime['ssh_port'], username='wing-test',
                      known_hosts=(), client_factory=PinnedClient, agent_path=None, config=None)
        async with asyncssh.connect(**common, client_keys=[fixture.client_key]) as conn:
            reader, writer = await conn.open_connection('127.0.0.1', runtime['agent_port'])
            request = 'GET /api/sessions/qa-history/messages?profile=qa-key HTTP/1.1\r\nHost: fixture\r\nAuthorization: Bearer ' + runtime['agent_token'] + '\r\n\r\n'
            writer.write(request.encode())
            await writer.drain()
            response = await asyncio.wait_for(reader.read(), 5)
            assert b'Disposable SSH key history' in response
            writer.close()
            await writer.wait_closed()
            try:
                await conn.open_connection('localhost', runtime['agent_port'])
            except asyncssh.ChannelOpenError:
                pass
            else:
                raise AssertionError('Unowned forward accepted')
            try:
                await conn.run('fixture-denied', check=True)
            except asyncssh.ChannelOpenError:
                pass
            else:
                raise AssertionError('Shell accepted')
        try:
            async with asyncssh.connect(**common,
                    client_keys=[asyncssh.generate_private_key('ssh-ed25519')]):
                raise AssertionError('Wrong key accepted')
        except asyncssh.PermissionDenied:
            pass
        expected = 'SHA256:deliberately-mismatched-fixture-host'
        try:
            async with asyncssh.connect(**common, client_keys=[fixture.client_key]):
                raise AssertionError('Changed host key accepted')
        except asyncssh.HostKeyNotVerifiable:
            pass
        ports = [runtime['ssh_port'], runtime['agent_port'], runtime['control_port']]
        assert fixture.agent.requests['GET /api/sessions/qa-history/messages'] == 1
    for port in ports:
        try:
            _, writer = await asyncio.wait_for(asyncio.open_connection('127.0.0.1', port), 1)
        except OSError:
            continue
        writer.close()
        await writer.wait_closed()
        raise AssertionError('Owned fixture listener survived')
    return {'fixture_only': True, 'pinned_key_forward': True, 'wrong_key_denied': True,
            'changed_host_key_denied': True, 'unowned_forward_denied': True,
            'shell_denied': True, 'closed': True, 'native_workflow': 'NOT_CHECKED'}


def native_command(flutter, lane, device):
    if lane == 'android' and not device:
        raise ValueError('Explicit disposable Android serial required')
    command = [flutter, 'test', '--no-pub', '-d',
               'linux' if lane == 'linux' else device,
               'integration_test/managed_ssh_key_native_test.dart',
               '--dart-define=WING_SSH_KEY_ISOLATED=true', '--reporter', 'expanded']
    if lane == 'linux':
        command = ['xvfb-run', '-a', '-s',
                   '-screen 0 1280x1100x24 -nolisten tcp'] + command
    elif lane != 'android':
        raise ValueError('Native lanes only')
    return command


def validate_result(value, lane):
    expected = {'platform', 'workflow', 'native_picker', 'physical_secure_storage',
                'encrypted_key', 'model', 'wing_link', 'cycles', 'counters'}
    if set(value) != expected or value['platform'] != lane or value['workflow'] != 'PASS':
        raise ValueError('Native result schema failed')
    for field in ('native_picker', 'physical_secure_storage', 'encrypted_key'):
        if value[field] != 'NOT_CHECKED':
            raise ValueError('Substituted seams cannot qualify native behavior')
    if value['model'] != 'READ_ONLY_INVENTORY' or value['wing_link'] != 'NO_LISTENER':
        raise ValueError('Unexpected authority claim')
    counts = value['counters']
    if set(counts) != {'requests', 'mutation_attempts', 'forbidden_reads', 'forbidden_ssh',
                       'auth_denials', 'ssh_auths', 'ssh_denials', 'forwards', 'live_ssh'}:
        raise ValueError('Unexpected counter schema')
    for name, count in counts.items():
        if name != 'requests' and (type(count) is not int or not 0 <= count <= 256):
            raise ValueError('Counter bounds failed')
    if any(counts[k] for k in ('mutation_attempts', 'forbidden_reads', 'forbidden_ssh', 'auth_denials')):
        raise ValueError('Forbidden native request observed')
    allowed = {'GET ' + path for path in ('/health', '/v1/capabilities', '/api/profiles',
               '/api/sessions', '/api/sessions/qa-history',
               '/api/sessions/qa-history/messages', '/api/model/options')}
    def check_reads(reads):
        if not isinstance(reads, dict) or not set(reads) <= allowed:
            raise ValueError('Unexpected read path')
        if any(type(v) is not int or not 0 <= v <= 256 for v in reads.values()):
            raise ValueError('Read bounds failed')
    check_reads(counts['requests'])
    if not isinstance(value['cycles'], list) or len(value['cycles']) != 2:
        raise ValueError('Two native journeys required')
    for cycle in value['cycles']:
        if set(cycle) != {'request_delta'}:
            raise ValueError('Unexpected cycle schema')
        check_reads(cycle['request_delta'])
        required = {'GET ' + path for path in ('/health', '/v1/capabilities',
            '/api/profiles', '/api/sessions', '/api/model/options',
            '/api/sessions/qa-history/messages')}
        if any(cycle['request_delta'].get(path, 0) < 1 for path in required):
            raise ValueError('Native journey did not exercise required Agent reads')
    if counts['live_ssh'] != 0 or counts['ssh_auths'] < 3 or counts['ssh_denials'] < 1:
        raise ValueError('SSH authentication, mismatch or teardown evidence missing')
    if value['cycles'][0] != value['cycles'][1]:
        raise ValueError('Explicit reconnect read counts differ')
    return value


def live_group(pgid):
    for path in pathlib.Path('/proc').iterdir():
        if not path.name.isdigit():
            continue
        try:
            fields = (path / 'stat').read_text().rsplit(')', 1)[1].split()
            if fields[0] != 'Z' and int(fields[2]) == pgid:
                return True
        except (FileNotFoundError, ProcessLookupError):
            continue
    return False


async def stop_group(child):
    for sig, deadline in ((signal.SIGTERM, 5), (signal.SIGKILL, 3)):
        try:
            os.killpg(child.pid, sig)
        except ProcessLookupError:
            break
        end = time.monotonic() + deadline
        while live_group(child.pid) and time.monotonic() < end:
            await asyncio.sleep(0.05)
        if not live_group(child.pid):
            break
    await asyncio.wait_for(child.wait(), 3)
    if live_group(child.pid):
        raise RuntimeError('Owned process group survives; retain scratch')


async def command(argv, cwd=None, env=None, timeout=600):
    child = await asyncio.create_subprocess_exec(*argv, cwd=cwd, env=env,
        stdout=asyncio.subprocess.DEVNULL, stderr=asyncio.subprocess.DEVNULL,
        start_new_session=True)
    try:
        code = await asyncio.wait_for(child.wait(), timeout)
        if code:
            raise RuntimeError('Owned preparation command failed; output suppressed')
    finally:
        await stop_group(child)


async def run(args):
    import tempfile
    repo = pathlib.Path(__file__).resolve().parents[2]
    base = pathlib.Path(os.environ['TMPDIR']).resolve()
    tag = 'r' + secrets.token_hex(6)
    root = pathlib.Path(tempfile.mkdtemp(prefix='wing-ssh-key-', dir=base))
    marker = root / '.owned-ssh-key-qa'
    marker.touch()
    logs = repo / '.task-evidence/parallel-key-native' / (args.lane + '-' + tag)
    logs.mkdir(parents=True, mode=0o700)
    result = {'platform': args.lane, 'native_workflow': 'NOT_CHECKED',
              'native_picker': 'NOT_CHECKED'}
    mapped = []
    app_id = 'com.trebuchetdynamics.hermes.wing.qa.sshkey.' + tag
    env = dict(os.environ)
    child = None
    cleaned = False
    try:
        manifest = freeze(repo, root / 'app')
        app = root / 'app'
        form = (app / 'lib/features/hermes_chat/widgets/managed_ssh_connection_form.dart').read_text()
        if any(key not in form for key in ('managed-ssh-auth-private-key', 'managed-ssh-select-key')):
            raise RuntimeError('Private-key producer has not integrated; native execution refused')
        (logs / 'source-inputs.json').write_text(json.dumps(manifest, indent=2))
        flutter_binary = shutil.which('flutter')
        if not flutter_binary:
            raise RuntimeError('Flutter prerequisite unavailable')
        flutter_source = pathlib.Path(flutter_binary).resolve()
        sdk = flutter_source.parents[1]
        await command(['cp', '-a', '--reflink=auto', str(sdk), str(root / 'flutter')])
        flutter = str(root / 'flutter/bin/flutter')
        for name in ('home', 'config', 'cache', 'data', 'runtime'):
            (root / name).mkdir(mode=0o700)
        env.update(HOME=str(root / 'home'), XDG_CONFIG_HOME=str(root / 'config'),
            XDG_CACHE_HOME=str(root / 'cache'), XDG_DATA_HOME=str(root / 'data'),
            XDG_RUNTIME_DIR=str(root / 'runtime'), PUB_CACHE=os.environ.get('PUB_CACHE',
            str(pathlib.Path.home() / '.pub-cache')), WING_ISOLATED_DEVICE_TEST='1',
            GDK_BACKEND='x11', LIBGL_ALWAYS_SOFTWARE='1', CMAKE_BUILD_PARALLEL_LEVEL='2')
        for name in ('DBUS_SESSION_BUS_ADDRESS', 'SSH_AUTH_SOCK', 'DISPLAY',
                     'WAYLAND_DISPLAY', 'SESSION_MANAGER'):
            env.pop(name, None)
        # Application identity overlays affect ONLY the frozen snapshot.
        overlays = {}
        if args.lane == 'linux':
            path = app / 'linux/CMakeLists.txt'
            original = path.read_text()
            edited = original.replace('set(APPLICATION_ID "com.trebuchetdynamics.hermes.wing")',
                                      'set(APPLICATION_ID "' + app_id + '")')
        else:
            path = app / 'android/app/build.gradle.kts'
            original = path.read_text()
            edited = original.replace('applicationIdSuffix = ".qa"',
                                      'applicationIdSuffix = ".qa.sshkey.' + tag + '"')
            sdk_dir = os.environ.get('ANDROID_HOME') or os.environ.get('ANDROID_SDK_ROOT')
            if not sdk_dir:
                raise RuntimeError('Explicit Android SDK location required')
            (app / 'android/local.properties').write_text('sdk.dir=' + sdk_dir + '\nflutter.sdk=' + str(root / 'flutter') + '\n')
        if original == edited:
            raise RuntimeError('Application identity overlay unavailable')
        path.write_text(edited)
        overlays[str(path.relative_to(app))] = sha(path)
        async with Fixture() as fixture:
            runtime = fixture.runtime
            assert runtime is not None
            runtime['host'] = mapping(args.lane, args.mapping)
            runtime_path = app / 'integration_test/managed_ssh_key_native_runtime.json'
            runtime_path.write_text(json.dumps(runtime))
            runtime_path.chmod(0o600)
            pubspec = app / 'pubspec.yaml'
            text = pubspec.read_text()
            anchor = '  assets:\n'
            if text.count(anchor) != 1:
                raise RuntimeError('Runtime asset injection requires existing assets list')
            pubspec.write_text(text.replace(anchor,
                anchor + '    - integration_test/managed_ssh_key_native_runtime.json\n'))
            overlays['pubspec.yaml'] = sha(pubspec)
            (logs / 'snapshot-overlays.json').write_text(json.dumps({
                'scope': 'non-secret build overlays; generated runtime asset excluded',
                'inputs': overlays, 'runtime_asset': 'GENERATED_SECRET_DELETED_AT_TEARDOWN'}))
            if args.lane == 'android':
                state = subprocess.check_output(['adb', '-s', args.device, 'get-state'], text=True).strip()
                if state != 'device':
                    raise RuntimeError('Disposable Android target unavailable')
                for port in (runtime['ssh_port'], runtime['control_port']):
                    await command(['adb', '-s', args.device, 'reverse', '--no-rebind',
                                   f'tcp:{port}', f'tcp:{port}'], timeout=10)
                    mapped.append(port)
                    listing = await asyncio.to_thread(subprocess.check_output,
                        ['adb', '-s', args.device, 'reverse', '--list'], text=True)
                    if not any(line.split()[-2:] == [f'tcp:{port}', f'tcp:{port}']
                               for line in listing.splitlines()):
                        raise RuntimeError('Owned Android reverse mapping readback failed')
            await command([flutter, 'pub', 'get', '--offline'], cwd=app, env=env, timeout=120)
            verify_product(app, manifest)
            argv = native_command(flutter, args.lane, args.device)
            child = await asyncio.create_subprocess_exec(*argv, cwd=app, env=env,
                stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.STDOUT,
                start_new_session=True, limit=65536)
            async def collect():
                receipt = None
                assert child.stdout is not None
                async for line in child.stdout:
                    # Do not retain raw Flutter logs: test failures can contain secrets.
                    marker_text = b'WING_SSH_KEY_RESULT '
                    if marker_text in line:
                        payload = line.split(marker_text, 1)[1].strip()
                        if len(payload) > 16384 or receipt is not None:
                            raise RuntimeError('Native receipt bounds failed')
                        receipt = validate_result(json.loads(payload), args.lane)
                code = await child.wait()
                if code or receipt is None:
                    raise RuntimeError('Native test failed or receipt missing; raw output suppressed')
                return receipt
            receipt = await asyncio.wait_for(collect(), 600)
            await stop_group(child)
            verify_product(app, manifest)
            effective = {name: sha(app / name) for name in manifest['inputs']}
            (logs / 'effective-inputs.json').write_text(json.dumps({
                'scope': manifest['scope'], 'inputs': effective}, indent=2))
            artifacts = {str(path.relative_to(app)): sha(path)
                for path in (app / 'build').rglob('*')
                if path.is_file() and (path.name == 'wing' or path.suffix == '.apk')}
            (logs / 'artifact-sha256.json').write_text(json.dumps(artifacts, indent=2))
            result = {'platform': args.lane, 'native_workflow': 'PASS',
                      'native_picker': 'NOT_CHECKED', 'result': receipt, 'native_exit': 0}
    finally:
        # Repeated signals cannot interrupt cleanup or delete state with survivors.
        loop = asyncio.get_running_loop()
        for sig in (signal.SIGTERM, signal.SIGINT):
            loop.remove_signal_handler(sig)
            signal.signal(sig, signal.SIG_IGN)
        if child is not None:
            await stop_group(child)
        for port in mapped:
            await command(['adb', '-s', args.device, 'reverse', '--remove', f'tcp:{port}'], timeout=10)
            listing = await asyncio.to_thread(subprocess.check_output,
                ['adb', '-s', args.device, 'reverse', '--list'], text=True)
            if any(line.split()[-2:] == [f'tcp:{port}', f'tcp:{port}']
                   for line in listing.splitlines()):
                raise RuntimeError('Owned Android mapping survived teardown')
        if args.lane == 'android' and child is not None:
            installed = await asyncio.to_thread(subprocess.check_output,
                ['adb', '-s', args.device, 'shell', 'pm', 'list', 'packages', app_id], text=True)
            for package in (app_id, app_id + '.test'):
                if 'package:' + package in installed.splitlines():
                    await command(['adb', '-s', args.device, 'uninstall', package], timeout=20)
            remaining = await asyncio.to_thread(subprocess.check_output,
                ['adb', '-s', args.device, 'shell', 'pm', 'list', 'packages', app_id], text=True)
            if any('package:' + package in remaining.splitlines()
                   for package in (app_id, app_id + '.test')):
                raise RuntimeError('Owned Android QA installation survived teardown')
        if marker.is_file() and root.parent == base:
            shutil.rmtree(root)
            cleaned = True
        result['isolated_state_removed'] = cleaned
        (logs / 'receipt.json').write_text(json.dumps(result, indent=2))
    print(json.dumps({'platform': args.lane, 'native_workflow': result['native_workflow'],
                      'native_picker': 'NOT_CHECKED', 'isolated_state_removed': cleaned}))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--lane', choices=('linux', 'android'), required=True)
    parser.add_argument('--mapping', choices=('adb-reverse',))
    parser.add_argument('--device')
    parser.add_argument('--run', action='store_true', help='Build/run only after producer integration')
    args = parser.parse_args()
    mapping(args.lane, args.mapping)
    argv = native_command('flutter', args.lane, args.device)
    if not args.run:
        print(json.dumps({'platform': args.lane, 'native_workflow': 'NOT_CHECKED',
            'native_picker': 'NOT_CHECKED', 'host_mapping': args.mapping or 'owned-linux-loopback',
            'command': argv, 'requires': ['integrated private-key form', 'asyncssh Python environment',
                'frozen source snapshot', 'generated disposable document asset'],
            'storage': 'ISOLATED_TEST_SEAMS_NOT_PHYSICAL_QUALIFICATION'}))
        return 0
    os.umask(0o077)
    logging.disable(logging.CRITICAL)
    async def supervised():
        task = asyncio.create_task(run(args))
        loop = asyncio.get_running_loop()
        for sig in (signal.SIGTERM, signal.SIGINT):
            loop.add_signal_handler(sig, task.cancel)
        await task
    asyncio.run(supervised())
    return 0


if __name__ == '__main__':
    try:
        sys.exit(main())
    except (Exception, asyncio.CancelledError) as exc:
        # Exception text might contain a synthetic key; never echo it.
        print('MANAGED_SSH_KEY_QA_BLOCKED ' + type(exc).__name__, file=sys.stderr)
        sys.exit(1)
