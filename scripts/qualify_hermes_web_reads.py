"""Owned isolated Hermes setup only; all read qualification runs actual Dart.

Run: /opt/hermes/.venv/bin/python scripts/qualify_hermes_web_reads.py
Never inherits provider environment, reads production sessions or modifies Agent.
"""
import http.cookiejar
import json

from pathlib import Path
import secrets
import socket
import subprocess
import tempfile
import time
import urllib.error
import urllib.request

REPO = Path(__file__).resolve().parents[1]
SCRATCH = Path('/opt/data/cache/scratch')
DART = '/opt/data/toolchains/flutter-sdk/bin/dart'
HERMES = '/opt/hermes/bin/hermes'


def process_identity():
    # Read only the observed gateway PID's immutable start identity; no argv/env.
    stat = Path('/proc/233/stat')
    return stat.read_text().rsplit(')', 1)[1].split()[19] if stat.exists() else None


def main():
    receipt = {'assertions': {}, 'production_activation': False}
    before = process_identity()
    receipt['gateway_observed_pid'] = 233
    receipt['gateway_start_identity_before'] = before
    root = Path(tempfile.mkdtemp(prefix='wing-dart-web-', dir=SCRATCH))
    root.chmod(0o700)
    process = None
    port = None
    try:
        home = root / 'owned-home'
        home.mkdir(mode=0o700)
        env = {'PATH': '/opt/hermes/bin:/usr/local/bin:/usr/bin:/bin',
               'HOME': str(home), 'HERMES_HOME': str(home / '.hermes'),
               'TMPDIR': str(root), 'LANG': 'C.UTF-8', 'PYTHONDONTWRITEBYTECODE': '1',
               'HERMES_DASHBOARD_PUBLIC_URL': 'http://wing-qualification.example.test',
               'HERMES_DASHBOARD_BASIC_AUTH_USERNAME': 'qualification',
               'HERMES_DASHBOARD_BASIC_AUTH_PASSWORD': secrets.token_urlsafe(32),
               'HERMES_DASHBOARD_BASIC_AUTH_SECRET': secrets.token_urlsafe(48),
               'HERMES_DASHBOARD_BASIC_AUTH_TTL_SECONDS': '60'}
        with socket.socket() as sock:
            sock.bind(('127.0.0.1', 0))
            port = sock.getsockname()[1]
        origin = f'http://127.0.0.1:{port}'
        jar = http.cookiejar.CookieJar()
        opener = urllib.request.build_opener(urllib.request.ProxyHandler({}), urllib.request.HTTPCookieProcessor(jar))

        def request(path, body=None, headers=None):
            req = urllib.request.Request(origin + path,
                data=json.dumps(body).encode() if body is not None else None,
                headers={'Content-Type': 'application/json', **(headers or {})})
            with opener.open(req, timeout=10) as response:
                if response.status != 200:
                    raise RuntimeError('owned setup HTTP failure')
                return json.loads(response.read(1048576))

        process = subprocess.Popen([HERMES, 'serve', '--isolated', '--host', '127.0.0.1', '--port', str(port)],
            env=env, cwd=root, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        deadline = time.monotonic() + 60
        while time.monotonic() < deadline:
            if process.poll() is not None:
                raise RuntimeError('owned serve startup failed')
            try:
                status = request('/api/status')
                break
            except (urllib.error.URLError, TimeoutError):
                time.sleep(0.5)
        else:
            raise RuntimeError('owned serve startup timeout')
        assert status.get('auth_required') is True
        receipt['assertions']['native_auth_gate_enabled'] = True
        receipt['native_version'] = status.get('version')
        assert request('/auth/password-login', {'provider': 'basic', 'username': 'qualification',
                       'password': env['HERMES_DASHBOARD_BASIC_AUTH_PASSWORD']}).get('ok') is True
        credential = next(cookie.value for cookie in jar if cookie.name.endswith('hermes_session_at'))
        assert isinstance(credential, str) and credential
        now = time.time()
        body = {'profile': 'default', 'sessions': [{'id': 'wing-qualification-session', 'source': 'cli',
            'title': 'Synthetic qualification', 'started_at': now, 'ended_at': now, 'end_reason': 'complete',
            'messages': [{'role': 'user', 'content': 'Synthetic read-only fixture', 'timestamp': now},
                         {'role': 'assistant', 'content': 'Synthetic fixture reply, not generation', 'timestamp': now}]}]}
        imported = request('/api/sessions/import', body, {'Authorization': 'Bearer ' + credential})
        assert imported.get('imported') == 1 and imported.get('skipped') == 0
        receipt['assertions']['native_synthetic_ended_import'] = True
        bearer = {'Authorization': 'Bearer ' + credential}
        # Safe synthetic wire fields for receipt/fixture provenance only. The
        # acceptance reads themselves execute Dart below, not this setup helper.
        inventory = request('/api/sessions?profile=default&limit=10&offset=0', headers=bearer)
        history = request('/api/sessions/wing-qualification-session/messages?profile=default&limit=10&offset=0&order=oldest', headers=bearer)
        receipt['rest_list_envelope'] = {key: inventory[key] for key in ('total', 'limit', 'offset', 'storage')}
        session_fields = ('id', 'profile', 'source', 'model', 'started_at', 'ended_at', 'message_count', 'title', 'preview', 'is_active')
        receipt['rest_list_envelope']['sessions'] = [{key: row.get(key) for key in session_fields} for row in inventory['sessions']]
        receipt['rest_history_envelope'] = {key: history[key] for key in ('session_id', 'profile', 'pagination')}
        message_fields = ('id', 'session_id', 'role', 'content', 'timestamp', 'tool_name', 'tool_call_id', 'reasoning', 'display_kind')
        receipt['rest_history_envelope']['messages'] = [{key: row.get(key) for key in message_fields} for row in history['messages']]
        dart_env = {'PATH': '/opt/data/toolchains/flutter-sdk/bin:/usr/bin:/bin',
            'HOME': str(home), 'TMPDIR': str(root), 'LANG': 'C.UTF-8',
            'PUB_CACHE': '/opt/data/toolchains/pub-cache', 'CI': 'true', 'FLUTTER_SUPPRESS_ANALYTICS': 'true'}
        result = subprocess.run([DART, 'run', 'scripts/qualify_hermes_web_reads.dart'], cwd=REPO,
            env=dart_env, input=json.dumps({'origin': origin, 'credential': credential}),
            text=True, capture_output=True, timeout=180)
        # Never print raw stderr or failed stdout. Only the allowlisted receipt.
        parsed = json.loads(result.stdout)
        assertions = parsed.get('assertions', {})
        assert isinstance(assertions, dict) and all(isinstance(k, str) and v is True for k, v in assertions.items())
        required = {
            'dart_rest_explicit_default_list', 'dart_rest_identity_numeric_ids_unix_time_nullable_history',
            'dart_anonymous_rest_rejected', 'dart_anonymous_history_rejected', 'dart_anonymous_ticket_rejected',
            'dart_wrong_rest_rejected', 'dart_wrong_history_rejected', 'dart_wrong_ticket_rejected',
            'dart_missing_profile_list', 'dart_missing_profile_history', 'dart_missing_profile_rpc_4064',
            'dart_ticket_subprotocol_gateway_ready_ping_list', 'production_authorization_unsupported_despite_positive_reads',
            'dart_anonymous_upgrade_rejected', 'dart_wrong_upgrade_ticket_rejected', 'dart_ticket_single_use_rejected',
            'dart_real_duration_ticket_expiry_rejected', 'dart_real_duration_access_expiry_rejected',
        }
        assert set(assertions) == required
        receipt['assertions'].update(assertions)
        receipt['assertion_count'] = len(receipt['assertions'])
        receipt['ticket_ttl_seconds'] = parsed['ticket_ttl_seconds']
        receipt['dart_exit_code'] = result.returncode
        if result.returncode != 0 or 'failure' in parsed:
            raise RuntimeError('Dart probe failed')
        receipt['platform'] = 'Linux Dart VM loopback only'
        receipt['isolation'] = 'fresh HOME/HERMES_HOME; constructed env; generated owned auth on stdin; no provider credentials/inference/production API calls'
        jar.clear()
        env.clear()
    except Exception as exc:
        receipt['failure_type'] = type(exc).__name__
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
        if port is not None:
            try:
                with socket.create_connection(('127.0.0.1', port), timeout=1):
                    receipt['owned_listener_closed'] = False
            except OSError:
                receipt['owned_listener_closed'] = True
        after = process_identity()
        receipt['gateway_start_identity_after'] = after
        receipt['gateway_identity_unchanged'] = before is not None and before == after
        # Scratch may contain native generated auth. Keep only the sanitized
        # receipt, never log/copy this owned state into the repository.
        import shutil
        shutil.rmtree(root / 'owned-home', ignore_errors=True)
        path = root / 'receipt.json'
        path.write_text(json.dumps(receipt, indent=2) + '\n')
        print(json.dumps(receipt, indent=2))
        print('Receipt:', path)
    return 1 if 'failure_type' in receipt or not receipt.get('owned_listener_closed') or not receipt.get('gateway_identity_unchanged') else 0


if __name__ == '__main__':
    raise SystemExit(main())
