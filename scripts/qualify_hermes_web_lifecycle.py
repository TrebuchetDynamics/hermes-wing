"""Owned, unmodified native Agent + actual Dart internal lifecycle; no inference.
Run: /opt/hermes/.venv/bin/python scripts/qualify_hermes_web_lifecycle.py
Requires installed Hermes and existing resolved Wing dependencies. Credentials,
login cookie and native state are generated privately and deleted, never logged.
"""
import hashlib
import http.cookiejar
import json
import os
from pathlib import Path
import secrets
import shutil
import socket
import subprocess
import tempfile
import time
import urllib.error
import urllib.request

REPO = Path(__file__).resolve().parent.parent
HERMES = '/opt/hermes/bin/hermes'
DART = '/opt/flutter/bin/dart'


def gateway_identity():
    path = Path('/proc/233/stat')
    return path.read_text().rsplit(')', 1)[1].split()[19] if path.exists() else None


def main():
    scratch = Path(os.environ['TMPDIR'])
    root = Path(tempfile.mkdtemp(prefix='wing-native-lifecycle-', dir=scratch))
    root.chmod(0o700)
    home = root / 'owned-home'
    home.mkdir(mode=0o700)
    before = gateway_identity()
    receipt = {'internal_only': True, 'production_activation': False,
               'inference_exercised': False, 'live_prompt_approval_events': False,
               'platform': 'Linux Dart VM literal loopback',
               'gateway_pid': 233, 'gateway_start_before': before,
               'native_identity': subprocess.check_output([HERMES, '--version'], text=True).splitlines()[0],
               'dart_identity': subprocess.check_output([DART, '--version'], text=True).strip(),
               'source_sha256': {}, 'artifact_sha256': {}}
    source_paths = ['tui_gateway/methods_session.py', 'tui_gateway/methods_prompt.py',
                    'tui_gateway/server.py', 'tui_gateway/event_replay.py',
                    'tui_gateway/server_requests.py', 'hermes_cli/web_server_chat.py',
                    'hermes_cli/dashboard_auth/routes.py']
    for path in source_paths:
        receipt['source_sha256'][path] = hashlib.sha256((Path('/opt/hermes') / path).read_bytes()).hexdigest()
    for path in ['scripts/qualify_hermes_web_lifecycle.py', 'scripts/qualify_hermes_web_lifecycle.dart',
                 'lib/core/hermes/client/hermes_web_read_client.dart',
                 'lib/core/hermes/client/hermes_web_read_rpc.dart',
                 'lib/core/hermes/client/hermes_web_lifecycle.dart']:
        receipt['artifact_sha256'][path] = hashlib.sha256((REPO / path).read_bytes()).hexdigest()
    env = {'PATH': '/opt/hermes/bin:/usr/local/bin:/usr/bin:/bin', 'HOME': str(home),
           'HERMES_HOME': str(home / '.hermes'), 'TMPDIR': str(root), 'LANG': 'C.UTF-8',
           'PYTHONDONTWRITEBYTECODE': '1',
           'HERMES_DASHBOARD_PUBLIC_URL': 'http://wing-qualification.example.test',
           'HERMES_DASHBOARD_BASIC_AUTH_USERNAME': 'qualification',
           'HERMES_DASHBOARD_BASIC_AUTH_PASSWORD': secrets.token_urlsafe(32),
           'HERMES_DASHBOARD_BASIC_AUTH_SECRET': secrets.token_urlsafe(48),
           'HERMES_DASHBOARD_BASIC_AUTH_TTL_SECONDS': '300'}
    # No inherited provider keys, auth/config, MCP, plugins or crash markers.
    # Clean create prewarms an agent; without a configured provider its build
    # fails before inference. Watch resume is lazy:true to avoid auto-continuation.
    jar = http.cookiejar.CookieJar()
    plain = urllib.request.build_opener(urllib.request.ProxyHandler({}))
    login = urllib.request.build_opener(urllib.request.ProxyHandler({}), urllib.request.HTTPCookieProcessor(jar))
    with socket.socket() as sock:
        sock.bind(('127.0.0.1', 0))
        port = sock.getsockname()[1]
    origin = f'http://127.0.0.1:{port}'
    process = None

    def request(path, body=None, headers=None, client=None):
        req = urllib.request.Request(origin + path,
            data=json.dumps(body).encode() if body is not None else None,
            headers={'Content-Type': 'application/json', **(headers or {})})
        with (client or plain).open(req, timeout=10) as response:
            raw = response.read(1048577)
            assert len(raw) <= 1048576 and response.status == 200
            return json.loads(raw)

    try:
        process = subprocess.Popen([HERMES, 'serve', '--isolated', '--host', '127.0.0.1', '--port', str(port)],
            cwd=root, env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        deadline = time.monotonic() + 60
        while time.monotonic() < deadline:
            if process.poll() is not None:
                raise RuntimeError('owned server exited')
            try:
                status = request('/api/status')
                break
            except (urllib.error.URLError, TimeoutError):
                time.sleep(0.25)
        else:
            raise RuntimeError('owned startup timeout')
        assert status['auth_required'] is True
        result = request('/auth/password-login', {'provider': 'basic', 'username': 'qualification',
            'password': env['HERMES_DASHBOARD_BASIC_AUTH_PASSWORD']}, client=login)
        assert result.get('ok') is True
        credential = next(cookie.value for cookie in jar if cookie.name.endswith('hermes_session_at'))
        assert isinstance(credential, str) and credential
        jar.clear()
        now = time.time()
        # Durable EMPTY session via supported import. No seeded answer or generated
        # content, and no raw DB writes. Separately test a clean create draft.
        imported = request('/api/sessions/import', {'profile': 'default', 'sessions': [{
            'id': 'wing-lifecycle-empty-durable', 'source': 'cli',
            'title': 'Empty qualification fixture', 'started_at': now, 'ended_at': now,
            'end_reason': 'complete', 'messages': []}]}, {'Authorization': 'Bearer ' + credential})
        assert imported.get('imported') == 1
        command = [DART, f'--packages={REPO}/.dart_tool/package_config.json',
                   str(REPO / 'scripts/qualify_hermes_web_lifecycle.dart')]
        dart = subprocess.run(command, cwd=REPO, input=json.dumps({'origin': origin, 'credential': credential}),
            text=True, capture_output=True, timeout=90,
            env={'PATH': '/opt/flutter/bin:/usr/bin:/bin', 'HOME': str(home), 'TMPDIR': str(root),
                 'LANG': 'C.UTF-8', 'CI': 'true', 'FLUTTER_SUPPRESS_ANALYTICS': 'true'})
        parsed = json.loads(dart.stdout)
        # Only allow fixed labels/booleans and typed errors into the receipt.
        allowed = {'native_clean_create_distinct_runtime_stored_ids', 'native_exact_idle_interrupt',
            'native_fresh_ticket_reconnect_live_draft_resume_history',
            'native_durable_agentless_resume_canonical_empty_history', 'native_durable_exact_idle_interrupt',
            'native_durable_reconnect_and_authorization_stays_unsupported',
            'native_missing_profile_create_4064', 'native_missing_profile_resume_4064',
            'native_anonymous_lifecycle_ticket_rejected', 'native_wrong_lifecycle_ticket_rejected'}
        receipt['dart'] = {'command': command, 'exit_code': dart.returncode,
            'assertions': {key: value is True for key, value in parsed.get('assertions', {}).items() if key in allowed}}
        receipt['dart']['blockers'] = {key: value for key, value in parsed.get('blockers', {}).items()
            if key in {'native_exact_idle_interrupt', 'native_durable_exact_idle_interrupt'}
            and (value is None or isinstance(value, int))}
        if parsed.get('failure') in {'malformed', 'oversized', 'identity', 'authentication', 'notFound',
                                     'redirect', 'network', 'timeout', 'disconnected', 'stale', 'rpc', 'busy', 'qualification'}:
            receipt['dart']['failure'] = parsed['failure']
            receipt['dart']['rpc_code'] = parsed.get('rpc_code')
        assert dart.returncode == 0 and set(receipt['dart']['assertions']) == allowed
        assert all(receipt['dart']['assertions'].values())
        receipt['passed'] = True
    except Exception as error:
        receipt['passed'] = False
        receipt['failure_type'] = type(error).__name__
    finally:
        if process is not None:
            if process.poll() is None:
                process.terminate()
                try:
                    process.wait(timeout=20)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait(timeout=5)
            receipt['owned_process_exit_code'] = process.returncode
        try:
            with socket.create_connection(('127.0.0.1', port), timeout=1):
                receipt['owned_listener_closed'] = False
        except OSError:
            receipt['owned_listener_closed'] = True
        jar.clear()
        env.clear()
        shutil.rmtree(home)
        receipt['owned_home_removed'] = not home.exists()
        receipt['gateway_start_after'] = gateway_identity()
        receipt['gateway_start_unchanged'] = before is not None and before == receipt['gateway_start_after']
        receipt['passed'] = bool(receipt.get('passed') and receipt['owned_listener_closed'] and
                                 receipt['owned_home_removed'] and receipt['gateway_start_unchanged'])
        (root / 'receipt.json').write_text(json.dumps(receipt, indent=2) + '\n')
        print(json.dumps({'receipt': str(root / 'receipt.json'), 'passed': receipt['passed']}))
    return 0 if receipt['passed'] else 1


if __name__ == '__main__':
    raise SystemExit(main())
