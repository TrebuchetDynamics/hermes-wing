"""Deterministic boundary checks, not evidence of live Agent/provider execution."""
import contextlib

import importlib.util
import io
import json
import os

import pathlib
import shutil
import signal
import subprocess
import sys
import tempfile
import threading
import time
import unittest
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from unittest import mock
from typing import Any

ROOT = pathlib.Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('live_workflow', ROOT / 'scripts/support/desktop_live_workflow.py')
assert spec is not None and spec.loader is not None
live = importlib.util.module_from_spec(spec)
spec.loader.exec_module(live)


def authorization(port=9):
    return dict(schema=1, mode='read-only', approved_disposable=True,
                approved_reads=True, expires_at=time.time() + 180,
                origin=f'http://127.0.0.1:{port}/p/qa', profile='qa', session='qa-session',
                provider='openai-codex', model='gpt-6.1-sol',
                api_key='test-owned-not-a-credential', generation_limit=3, generations_used=0)


def capabilities() -> dict[str, Any]:
    return dict(object='hermes.api_server.capabilities', platform='hermes-agent',
                auth=dict(type='bearer', required=True),
                features={name: True for name in live.FEATURES},
                endpoints={name: dict(method=method, path=path)
                           for name, (method, path) in live.OPERATIONS.items()})


def synthetic_workflow(source, marker, scenario='success'):
    """Real orchestration, synthetic display/driver/app; no Agent connection."""
    app_code = '''
import json,os,pathlib,signal,subprocess,sys,time
root=pathlib.Path(os.environ['WING_LIVE_ROOT'])
phase=os.environ['WING_LIVE_PHASE']
marker=pathlib.Path(sys.argv[1]); scenario=sys.argv[2]
def event(**extra):
 with marker.open('a') as out:
  out.write(json.dumps(dict(phase=phase, app=os.getpid(), driver=os.getppid(), root=str(root),
                          display=os.environ['DISPLAY'], home=os.environ['HOME'], **extra))+'\\n')
state=root/'config/selection'
if phase=='write': state.write_text('test-owned-session')
else:
 assert state.read_text()=='test-owned-session'
 records=[json.loads(s) for s in marker.read_text().splitlines()]
 first=next(r for r in records if r.get('phase')=='write' and 'app' in r)
 for p in pathlib.Path('/proc').iterdir():
  try: fields=(p/'stat').read_text().rsplit(')',1)[1].split()
  except (OSError,IndexError): continue
  assert not (int(fields[2])==first['driver'] and fields[0]!='Z')
if scenario in ('cancel-write','cancel-verify','resistant'):
 ready=root/'cache'/('ready-'+phase)
 child=subprocess.Popen([sys.executable,'-c','import pathlib,signal,sys,time; signal.signal(signal.SIGTERM,signal.SIG_IGN); pathlib.Path(sys.argv[1]).touch(); time.sleep(60)',str(ready)])
 deadline=time.monotonic()+5
 while not ready.exists() and time.monotonic()<deadline: time.sleep(.01)
 assert ready.exists()
 event(descendant=child.pid)
else: event()
if scenario=='fail-write' and phase=='write': raise SystemExit(7)
if scenario=='missing-write' and phase=='write': raise SystemExit(0)
if scenario=='cancel-'+phase:
 signal.signal(signal.SIGTERM,signal.SIG_IGN)
 time.sleep(60)
receipt=dict(phase=phase,native_pid=os.getpid(),run_id='qa-'+phase,
 message_count=1 if phase=='write' else 2,history_identity='a'*64,owner_identity='0'*64,
 counts=dict(submits=1,approvals=int(phase=='write'),stops=int(phase=='write'),model_locks=1),
 canonical_status='cancelled' if phase=='write' else 'completed',provider_calls=None)
if scenario=='bad-write' and phase=='write': receipt['owner_identity']='b'*64
if scenario=='driver-pid' and phase=='write': receipt['native_pid']=os.getppid()
if scenario=='tamper' and phase=='verify':
 p=root/'cache/live-write.json'; p.write_text(p.read_text()+' ')
path=root/'cache'/('live-'+phase+'.json')
temporary=path.with_suffix('.tmp'); temporary.write_text(json.dumps(receipt)); temporary.rename(path)
time.sleep(.2)
'''
    def prepare(source, app, root):
        target = root / 'flutter/bin/flutter'
        target.parent.mkdir(parents=True)
        driver = ('import subprocess,sys\n'
                  f'child=subprocess.Popen([sys.executable,"-c",{app_code!r},{str(marker)!r},{scenario!r}])\n'
                  'raise SystemExit(child.wait())\n')
        target.write_text('#!' + sys.executable + '\n' + driver)
        target.chmod(0o700)
    def display(fd):
        return [sys.executable, '-c',
                'import json,os,pathlib,time\n'
                f'with pathlib.Path({str(marker)!r}).open("a") as out: out.write(json.dumps(dict(display_pid=os.getpid()))+"\\n")\n'
                'print("87",flush=True); time.sleep(60)']
    original_rmtree = shutil.rmtree
    def checked_delete(path, *args, **kwargs):
        if marker.exists():
            records = [json.loads(s) for s in marker.read_text().splitlines()]
            for record in records:
                if record.get('root') == str(path):
                    assert not live.live_group(record['driver'])
                if 'display_pid' in record:
                    assert not live.live_group(record['display_pid'])
            with marker.open('a') as out:
                out.write(json.dumps(dict(deletion_checked=True)) + '\n')
        return original_rmtree(path, *args, **kwargs)
    with mock.patch.object(shutil, 'rmtree', side_effect=checked_delete):
        return live.prepared_two_process(source, _prepare=prepare, _display=display)


class BoundaryTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        (ROOT / 'build').mkdir(exist_ok=True)
    def call(self, payload, args=None):
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            code = live.main(args or [], io.StringIO(payload))
        return code, json.loads(output.getvalue())

    def test_no_auth_no_network_or_workspace(self):
        with mock.patch.object(live, 'read_capabilities') as network, mock.patch.object(live, 'native_readiness') as native:
            code, receipt = self.call('', ['--native-read-only'])
            self.assertEqual(code, 2)
            self.assertEqual(receipt['status'], 'AUTHORIZATION_REQUIRED_NO_NETWORK')
            self.assertEqual(receipt['read_requests_attempted'], 0)
            network.assert_not_called()
            native.assert_not_called()

    def test_invalid_authority_fails_before_network(self):
        changes = [dict(approved_disposable=False), dict(approved_reads=False),
                   dict(expires_at=0), dict(expires_at=time.time() + 301),
                   dict(schema=True), dict(profile='../personal'), dict(session=''),
                   dict(provider='substitution'), dict(model='other-model'),
                   dict(api_key=''), dict(api_key='bad\ncredential-value'),
                   dict(generation_limit=4), dict(generation_limit=True),
                   dict(generations_used=3), dict(generations_used=-1),
                   dict(generations_used=True), dict(mode='live')]
        for change in changes:
            with self.subTest(change=list(change)):
                payload = authorization() | change
                with mock.patch.object(live, 'read_capabilities') as network:
                    code, receipt = self.call(json.dumps(payload))
                    self.assertEqual(code, 2)
                    self.assertEqual(receipt['read_requests_attempted'], 0)
                    self.assertEqual(receipt['inference_count'], 0)
                    network.assert_not_called()

    def test_invalid_origin_never_contacts_target(self):
        targets = ['http://localhost:9/p/qa', 'http://192.0.2.1:9/p/qa',
                   'https://127.0.0.1:9/p/qa', 'http://127.0.0.1/p/qa',
                   'http://user:secret@127.0.0.1:9/p/qa',
                   'http://127.0.0.1:9/p/personal', 'http://127.0.0.1:9/p/qa?key=private',
                   'http://127.0.0.1:9/p/qa#private', 'http://127.0.0.1:bad/p/qa',
                   'http://127.0.0.1:9/p/qa\n']
        for target in targets:
            with self.subTest(target=target), mock.patch.object(live, 'read_capabilities') as network:
                code, receipt = self.call(json.dumps(authorization() | dict(origin=target)))
                self.assertEqual(code, 2)
                self.assertNotIn(target, json.dumps(receipt))
                network.assert_not_called()

    def test_unsupported_exact_operations_and_grants(self):
        live.require_operations(capabilities())
        changes = [dict(schema_version=2), dict(auth=dict(type='bearer', required=False)),
                   dict(features={}), dict(endpoints={})]
        for change in changes:
            with self.subTest(change=list(change)), self.assertRaises(live.Refusal):
                live.require_operations(capabilities() | change)
        for name in live.OPERATIONS:
            for change in (dict(method='DELETE'), dict(path='/invented'),
                           dict(required_scopes=['runs:write']), dict(profile_scoped=True)):
                with self.subTest(operation=name, change=change):
                    doc = capabilities()
                    doc['endpoints'][name].update(change)
                    with self.assertRaises(live.Refusal):
                        live.require_operations(doc)
        doc = capabilities()
        doc['endpoints']['runs']['required_scopes'] = ['runs:write']
        doc['auth']['granted_scopes'] = ['runs:write']
        live.require_operations(doc)

    def test_malformed_input_and_exception_redaction(self):
        for raw in ('{', 'null', '[]', 'x' * 16385):
            code, receipt = self.call(raw)
            self.assertEqual(code, 2)
            self.assertEqual(receipt['mutations'], 0)
        with mock.patch.object(live, 'read_capabilities', side_effect=OSError('private endpoint and credential')):
            code, receipt = self.call(json.dumps(authorization()))
            self.assertEqual(code, 2)
            self.assertNotIn('private', json.dumps(receipt))

    def test_real_launcher_no_inputs(self):
        result = subprocess.run(['bash', str(ROOT / 'scripts/run_linux_desktop_live_workflow.sh')],
                                input='', text=True, capture_output=True, timeout=10)
        self.assertEqual(result.returncode, 2)
        receipt = json.loads(result.stdout)
        self.assertEqual(receipt['status'], 'AUTHORIZATION_REQUIRED_NO_NETWORK')
        self.assertEqual(receipt['mutations'], 0)
        self.assertEqual(result.stderr, '')

    def test_real_launcher_read_only_http_contract(self):
        requests = []
        doc = capabilities()
        status = [200]
        class Handler(BaseHTTPRequestHandler):
            def do_GET(self):
                requests.append((self.command, self.path))
                self.send_response(status[0])
                self.end_headers()
                self.wfile.write(json.dumps(doc).encode())
            def do_POST(self):
                requests.append((self.command, self.path))
                self.send_response(500)
                self.end_headers()
            def log_message(self, format, *args):
                return
        server = ThreadingHTTPServer(('127.0.0.1', 0), Handler)
        thread = threading.Thread(target=server.serve_forever)
        thread.start()
        try:
            payload = authorization(server.server_port)
            def launch():
                return subprocess.run(['bash', str(ROOT / 'scripts/run_linux_desktop_live_workflow.sh')],
                                      input=json.dumps(payload), text=True, capture_output=True, timeout=10)
            result = launch()
            self.assertEqual(result.returncode, 0)
            self.assertEqual(json.loads(result.stdout)['status'], 'READ_ONLY_PREFLIGHT_PASS')
            del doc['endpoints']['run_stop']
            result = launch()
            self.assertEqual(result.returncode, 2)
            self.assertEqual(json.loads(result.stdout)['status'], 'REQUIRED_OPERATION_UNAVAILABLE')
            status[0] = 302  # Must not follow redirects or forward credentials.
            result = launch()
            self.assertEqual(result.returncode, 2)
            self.assertEqual(json.loads(result.stdout)['status'], 'AUTHORITY_READ_REJECTED')
            self.assertEqual(requests, [('GET', '/p/qa/v1/capabilities')] * 3)
            for change in (dict(generations_used=3), dict(approved_disposable=False), dict(api_key='')):
                payload.update(change)
                before = len(requests)
                self.assertEqual(launch().returncode, 2)
                self.assertEqual(len(requests), before)
        finally:
            server.shutdown()
            thread.join(timeout=5)
            server.server_close()
        self.assertFalse(thread.is_alive())

    def test_owned_timeout_reaps_process_group(self):
        with tempfile.TemporaryDirectory(dir=ROOT / 'build') as temp:
            with self.assertRaises(subprocess.TimeoutExpired):
                live.run_owned([sys.executable, '-c', 'import time; time.sleep(60)'], temp, {}, timeout=0.1)
        code, child_pid = live.run_owned([sys.executable, '-c', 'pass'], ROOT, {})
        self.assertEqual(code, 0)
        self.assertFalse(live.live_group(child_pid))

    def test_spawn_failure_is_not_suppressed_and_handlers_restore(self):
        previous = {s: signal.getsignal(s) for s in (signal.SIGINT, signal.SIGTERM)}
        with self.assertRaises(FileNotFoundError):
            live.run_owned(['/nonexistent-test-owned-executable'], ROOT, {})
        self.assertEqual(previous, {s: signal.getsignal(s) for s in previous})

    def test_owned_descendant_is_reaped_after_leader_exit(self):
        command = [sys.executable, '-c',
                   'import subprocess,sys; subprocess.Popen([sys.executable,"-c","import time; time.sleep(60)"])']
        code, child_pid = live.run_owned(command, ROOT, {})
        self.assertEqual(code, 0)
        self.assertFalse(live.live_group(child_pid))

    def test_snapshot_excludes_unrelated_dirty_and_upstreams(self):
        with tempfile.TemporaryDirectory(dir=ROOT / 'build') as temp:
            source, app = pathlib.Path(temp) / 'source', pathlib.Path(temp) / 'app'
            source.mkdir()
            for name in live.INPUT_ROOTS:
                (source / name).mkdir()
                (source / name / 'committed.txt').write_text('committed')
            for name in live.INPUT_FILES:
                (source / name).write_text('committed')
            subprocess.run(['git', 'init', '-q', str(source)], check=True)
            subprocess.run(['git', 'add', '.'], cwd=source, check=True)
            subprocess.run(['git', '-c', 'user.name=QA', '-c', 'user.email=qa@example.invalid',
                            'commit', '-qm', 'test-owned source'], cwd=source, check=True)
            (source / 'lib/committed.txt').write_text('unrelated dirty bytes')
            (source / 'lib/untracked.txt').write_text('unrelated owner')
            (source / 'hermes-agent').mkdir()
            for name in live.OWNED:
                p = source / name
                p.parent.mkdir(parents=True, exist_ok=True)
                p.write_text('attributed')
            identity = live.snapshot(source, app, revision='HEAD')
            self.assertEqual((app / 'lib/committed.txt').read_text(), 'committed')
            self.assertFalse((app / 'lib/untracked.txt').exists())
            self.assertFalse((app / 'hermes-agent').exists())
            self.assertEqual(set(identity['overlays']), set(live.OWNED))
            for name, checksum in identity['inputs'].items():
                self.assertEqual(live.digest(app / name), checksum)
            with self.assertRaises(FileExistsError):
                live.snapshot(source, app, revision='HEAD')


    def native_probe(self, interrupt, archive=False):
        """Real entry/preparation; fake SDK/tools, never an actual native/Agent run."""
        requests = []
        class Handler(BaseHTTPRequestHandler):
            def do_GET(self):
                requests.append((self.command, self.path))
                self.send_response(200)
                self.end_headers()
                self.wfile.write(json.dumps(capabilities()).encode())
            def log_message(self, format, *args):
                return
        server = ThreadingHTTPServer(('127.0.0.1', 0), Handler)
        thread = threading.Thread(target=server.serve_forever)
        thread.start()
        try:
            with tempfile.TemporaryDirectory(dir=ROOT / 'build') as temp:
                root = pathlib.Path(temp)
                source, sdk, tools = root / 'source', root / 'sdk', root / 'tools'
                source.mkdir()
                tools.mkdir()
                (sdk / 'bin').mkdir(parents=True)
                def executable(path, code):
                    path.write_text('#!' + sys.executable + '\n' + code)
                    path.chmod(0o700)
                executable(sdk / 'bin/flutter', 'raise SystemExit(0)\n')
                for repo in (source, sdk):
                    subprocess.run(['git', 'init', '-q', str(repo)], check=True)
                subprocess.run(['git', 'fetch', '-q', str(ROOT), live.PREDECESSOR],
                               cwd=source, check=True)
                for name in live.INPUT_ROOTS:
                    (source / name).mkdir()
                    (source / name / 'input.txt').write_text('test-owned')
                for name in live.INPUT_FILES:
                    (source / name).write_text('test-owned')
                for name in live.OWNED:
                    target = source / name
                    target.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(ROOT / name, target)
                for repo in (source, sdk):
                    subprocess.run(['git', 'add', '.'], cwd=repo, check=True)
                    subprocess.run(['git', '-c', 'user.name=QA', '-c', 'user.email=qa@example.invalid',
                                    'commit', '-qm', 'test-owned inputs'], cwd=repo, check=True)
                (source / '.dart_tool').mkdir()
                (source / '.dart_tool/package_config.json').write_text(json.dumps(dict(packages=[
                    dict(name='wing', rootUri=source.as_uri()),
                    dict(name='flutter', rootUri=sdk.as_uri())])))
                (source / '.dart_tool/package_graph.json').write_text('{}')
                (source / '.flutter-plugins-dependencies').write_text('{"plugins":{}}')
                marker, launched = root / 'copy.json', root / 'launched'
                if archive:
                    real_git = shutil.which('git')
                    executable(tools / 'git',
                               'import json,os,pathlib,subprocess,sys,time\n'
                               'if sys.argv[1] == "archive":\n'
                               ' child=subprocess.Popen([sys.executable,"-c","import time; time.sleep(60)"])\n'
                               f' pathlib.Path({str(marker)!r}).write_text(json.dumps(dict(pid=os.getpid(),'
                               f'child=child.pid,destination={str(source / "build")!r})))\n'
                               ' time.sleep(60)\n'
                               f'os.execv({real_git!r},[{real_git!r},*sys.argv[1:]])\n')
                executable(tools / 'cp',
                           'import json,os,pathlib,shutil,signal,subprocess,sys,time\n'
                           'destination=pathlib.Path(sys.argv[-1])\n'
                           + ('destination.mkdir()\n'
                              'signal.signal(signal.SIGTERM,signal.SIG_IGN)\n'
                              'child=subprocess.Popen([sys.executable,"-c",'
                              '"import signal,time; signal.signal(signal.SIGTERM,signal.SIG_IGN); time.sleep(60)"])\n'
                              if interrupt else
                              'shutil.copytree(sys.argv[-2],destination)\nchild=None\n')
                           + f'pathlib.Path({str(marker)!r}).write_text(json.dumps(dict(pid=os.getpid(),'
                           'child=child.pid if child else None,destination=str(destination))))\n'
                           + ('time.sleep(60)\n' if interrupt else ''))
                executable(tools / 'timeout', f'import pathlib\npathlib.Path({str(launched)!r}).touch()\n')
                env = os.environ.copy()
                env['PATH'] = str(tools) + ':' + str(sdk / 'bin') + ':' + env['PATH']
                process = subprocess.Popen(['bash', str(source / live.OWNED[0]), '--native-read-only'],
                                           stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                                           stderr=subprocess.PIPE, text=True, env=env)
                assert process.stdin is not None
                process.stdin.write(json.dumps(authorization(server.server_port)))
                process.stdin.close()
                process.stdin = None
                try:
                    deadline = time.monotonic() + 15
                    while not marker.exists() and time.monotonic() < deadline and process.poll() is None:
                        time.sleep(0.02)
                    self.assertTrue(marker.exists(), 'Preparation child was not reached')
                    copy = json.loads(marker.read_text())
                    if interrupt:
                        process.send_signal(signal.SIGTERM)  # Parent only, not group.
                        if not archive:
                            time.sleep(0.05)
                            process.send_signal(signal.SIGTERM)  # Do not interrupt teardown.
                    stdout, stderr = process.communicate(timeout=20)
                    receipt = json.loads(stdout)
                    self.assertEqual(process.returncode, 2 if interrupt else 0)
                    self.assertEqual(receipt['status'], 'NATIVE_CANCELLED' if interrupt else 'NATIVE_READINESS_PASS')
                    self.assertEqual(stderr, '')
                    self.assertEqual(receipt['mutations'], 0)
                    self.assertEqual(receipt['inference_count'], 0)
                    self.assertNotIn(authorization()['api_key'], stdout)
                    self.assertNotIn(str(root), stdout)
                    self.assertFalse(live.live_group(copy['pid']))
                    if copy['child']:
                        stat = pathlib.Path(f'/proc/{copy["child"]}/stat')
                        self.assertTrue(not stat.exists() or stat.read_text().rsplit(')', 1)[1].split()[0] == 'Z')
                    if not archive:
                        self.assertFalse(pathlib.Path(copy['destination']).exists())
                    self.assertEqual(list((source / 'build').iterdir()), [])
                    self.assertEqual(launched.exists(), not interrupt)
                    self.assertEqual(requests, [('GET', '/p/qa/v1/capabilities')])
                finally:
                    if process.poll() is None:
                        process.kill()
                        process.wait(timeout=5)
                    if marker.exists():
                        copy = json.loads(marker.read_text())
                        if live.live_group(copy['pid']):
                            os.killpg(copy['pid'], signal.SIGKILL)
        finally:
            server.shutdown()
            thread.join(timeout=5)
            server.server_close()

    def test_real_native_launcher_cancel_during_sdk_copy(self):
        self.native_probe(interrupt=True)

    def test_real_native_launcher_successful_preparation_cleanup(self):
        self.native_probe(interrupt=False)

    def test_real_native_launcher_cancel_during_source_archive(self):
        self.native_probe(interrupt=True, archive=True)

    def orchestration_probe(self, scenario):
        with tempfile.TemporaryDirectory(dir=ROOT / 'build') as temp:
            marker = pathlib.Path(temp) / 'events.jsonl'
            code = ('import importlib.util,json,pathlib,sys\n'
                    f'spec=importlib.util.spec_from_file_location("probe",{__file__!r})\n'
                    'module=importlib.util.module_from_spec(spec); spec.loader.exec_module(module)\n'
                    'try:\n'
                    f' receipt=module.synthetic_workflow(module.ROOT,pathlib.Path({str(marker)!r}),{scenario!r})\n'
                    ' receipt.pop("source"); print(json.dumps(receipt))\n'
                    'except module.live.Refusal as error:\n'
                    ' print(json.dumps(dict(status=str(error)))); sys.exit(2)\n')
            process = subprocess.Popen([sys.executable, '-B', '-c', code],
                                       stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
            records = []
            try:
                if scenario.startswith('cancel-'):
                    phase = scenario.removeprefix('cancel-')
                    deadline = time.monotonic() + 20
                    while time.monotonic() < deadline and process.poll() is None:
                        if marker.exists():
                            records = [json.loads(s) for s in marker.read_text().splitlines()]
                            if any(r.get('phase') == phase for r in records):
                                break
                        time.sleep(.02)
                    self.assertTrue(any(r.get('phase') == phase for r in records))
                    process.send_signal(signal.SIGTERM)
                    time.sleep(.05)
                    process.send_signal(signal.SIGINT)
                stdout, stderr = process.communicate(timeout=30)
                self.assertEqual(stderr, '')
                self.assertNotIn(str(ROOT), stdout)
                records = [json.loads(s) for s in marker.read_text().splitlines()]
                self.assertTrue(any(r.get('deletion_checked') for r in records))
                for record in records:
                    if 'driver' in record:
                        self.assertFalse(live.live_group(record['driver']))
                        self.assertFalse(pathlib.Path(record['root']).exists())
                        self.assertEqual(record['home'], record['root'] + '/home')
                    if 'display_pid' in record:
                        self.assertFalse(live.live_group(record['display_pid']))
                return process.returncode, json.loads(stdout), records
            finally:
                if process.poll() is None:
                    process.kill()
                    process.wait(timeout=5)
                if marker.exists():
                    for line in marker.read_text().splitlines():
                        record = json.loads(line)
                        for key in ('driver', 'display_pid'):
                            if key in record and live.live_group(record[key]):
                                os.killpg(record[key], signal.SIGKILL)

    def test_two_process_sequence_distinct_app_and_driver_shared_state_display(self):
        code, receipt, records = self.orchestration_probe('success')
        self.assertEqual(code, 0)
        self.assertEqual(receipt['status'], 'TWO_PHASE_CONTROL_FLOW_PASS')
        self.assertEqual(receipt['live_workflow'], 'NOT_CHECKED')
        apps = [r for r in records if 'app' in r]
        self.assertEqual([r['phase'] for r in apps], ['write', 'verify'])
        self.assertEqual(len({r['root'] for r in apps}), 1)
        self.assertEqual(len({r['display'] for r in apps}), 1)
        self.assertEqual(len({r['app'] for r in apps} | {r['driver'] for r in apps}), 4)
        self.assertEqual(len([r for r in records if 'display_pid' in r]), 1)

    def test_phase_failure_invalid_handoff_and_driver_identity_prevent_successor(self):
        for scenario, expected in [('fail-write', 'NATIVE_PHASE_FAILED'),
                                   ('missing-write', 'INVALID_PHASE_RECEIPT'),
                                   ('bad-write', 'INVALID_PHASE_IDENTITY'),
                                   ('driver-pid', 'DRIVER_IS_NOT_APP')]:
            with self.subTest(scenario=scenario):
                code, receipt, records = self.orchestration_probe(scenario)
                self.assertEqual(code, 2)
                self.assertEqual(receipt['status'], expected)
                self.assertFalse(any(r.get('phase') == 'verify' for r in records))

    def test_two_phase_cancellation_reaps_term_resistant_descendants_before_deletion(self):
        for phase in ('write', 'verify'):
            with self.subTest(phase=phase):
                code, receipt, records = self.orchestration_probe('cancel-' + phase)
                self.assertEqual(code, 2)
                self.assertEqual(receipt['status'], 'NATIVE_CANCELLED')
                if phase == 'write':
                    self.assertFalse(any(r.get('phase') == 'verify' for r in records))

    def test_successful_leader_exit_reaps_resistant_phase_descendants(self):
        code, receipt, records = self.orchestration_probe('resistant')
        self.assertEqual(code, 0)
        self.assertEqual(receipt['status'], 'TWO_PHASE_CONTROL_FLOW_PASS')
        self.assertEqual(len([r for r in records if 'descendant' in r]), 2)

    def test_changed_handoff_cannot_report_success(self):
        code, receipt, _ = self.orchestration_probe('tamper')
        self.assertEqual(code, 2)
        self.assertEqual(receipt['status'], 'PHASE_HANDOFF_CHANGED')

    def test_bounded_phase_admission_rejects_noncanonical_identity_and_files(self):
        with tempfile.TemporaryDirectory(dir=ROOT / 'build') as temp:
            path = pathlib.Path(temp) / 'phase.json'
            good = dict(phase='write', native_pid=123, run_id='qa-write', message_count=1,
                        history_identity='a' * 64, owner_identity='0' * 64,
                        counts=dict(submits=1, approvals=1, stops=1, model_locks=1),
                        canonical_status='cancelled', provider_calls=None)
            changes = [dict(extra='private'), dict(phase='verify'), dict(native_pid=True),
                       dict(run_id='../escape'), dict(owner_identity='b' * 64),
                       dict(history_identity='private'), dict(message_count=-1),
                       dict(counts=dict(submits=True, approvals=1, stops=1, model_locks=1)),
                       dict(canonical_status='completed'), dict(provider_calls=True)]
            for change in changes:
                path.write_text(json.dumps(good | change))
                with self.assertRaises(live.Refusal):
                    live.read_phase(path, 'write', '0' * 64)
            for raw in ('x' * 4097, '{"phase":"write","phase":"verify"}', 'null'):
                path.write_text(raw)
                with self.assertRaises(live.Refusal):
                    live.read_phase(path, 'write', '0' * 64)
            path.unlink()
            path.symlink_to(pathlib.Path(temp) / 'outside')
            with self.assertRaises(live.Refusal):
                live.read_phase(path, 'write', '0' * 64)
            path.unlink()
            os.mkfifo(path)
            with self.assertRaises(live.Refusal):
                live.read_phase(path, 'write', '0' * 64)

    def test_stale_phase_artifact_prevents_any_launch(self):
        with tempfile.TemporaryDirectory(dir=ROOT / 'build') as temp:
            root = pathlib.Path(temp)
            (root / 'cache').mkdir()
            (root / 'cache/live-write.json').write_text('{}')
            with mock.patch.object(live, 'run_owned') as launch:
                with self.assertRaisesRegex(live.Refusal, 'STALE_PHASE_RECEIPT'):
                    live.two_phase_runner(root, root, {}, '0' * 64)
                launch.assert_not_called()

    def test_unconfirmed_teardown_preserves_state_instead_of_deleting_under_child(self):
        with tempfile.TemporaryDirectory(dir=ROOT / 'build') as temp:
            root = None
            with self.assertRaisesRegex(live.Refusal, 'OWNED_TEARDOWN_INCOMPLETE'):
                with live.owned_workspace(temp) as root:
                    (root / 'state').write_text('test-owned')
                    raise live.Refusal('OWNED_TEARDOWN_INCOMPLETE')
            assert root is not None
            self.assertTrue((root / 'state').exists())
            # No process was launched by this injected refusal; test cleanup is safe.
            shutil.rmtree(root)

    def test_successful_internal_phase_receipt_cannot_enable_public_live_gate(self):
        code, _, _ = self.orchestration_probe('success')
        self.assertEqual(code, 0)
        with mock.patch.object(live, 'read_capabilities') as network, \
                mock.patch.object(live, 'prepared_two_process') as runner:
            for args in ([], ['--native-read-only'], ['--live'], ['--synthetic']):
                code, receipt = self.call(json.dumps(authorization() | dict(mode='live')), args)
                self.assertEqual(code, 2)
                self.assertEqual(receipt['read_requests_attempted'], 0)
            network.assert_not_called()
            runner.assert_not_called()
        dart = (ROOT / 'integration_test/linux_desktop_live_workflow_test.dart').read_text()
        journey = dart[dart.index('void _journeyMain()'):]
        self.assertLess(journey.index('requireQualifiedLiveBudget();'), journey.index('WING_LIVE_AUTH'))
        self.assertIn("throw UnsupportedError('LIVE_INFERENCE_BOUND_NOT_QUALIFIED')", dart)


if __name__ == '__main__':
    (ROOT / 'build').mkdir(exist_ok=True)
    unittest.main()
