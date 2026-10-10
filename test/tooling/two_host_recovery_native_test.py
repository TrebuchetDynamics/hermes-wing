"""Two-host receipts fail closed; no GTK, secrets or shared preferences."""
import importlib.util
import hashlib
import io
import json
import pathlib
import socket
import tarfile
import tempfile
import unittest
from unittest import mock

ROOT = pathlib.Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('two_host_native', ROOT / 'scripts/support/two_host_recovery_native.py')
assert spec is not None and spec.loader is not None
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


def valid():
    requests = [
        {'owner': owner, 'method': 'GET', 'path': path,
         'query': {'profile': 'synthetic-qa'} if path.startswith('/api/sessions') else {}}
        for owner in ('A', 'B') for path in ('/health', '/api/sessions/synthetic-history/messages')]
    return dict(native_pid=1, width=390.0, text_scale=2.0, profile='synthetic-qa',
        session='synthetic-history', physical_keychain='NOT_CHECKED',
        public_saved_selection=True, keyboard_retry=True, same_id_return_fenced=True,
        idle_no_reconnect=True, saved_connected_distinct=True,
        late_cases=[dict(reject=reject, cancelled=True, replacement_preserved=True) for reject in (False, True)],
        requests=requests + [requests[2]], retry_requests=requests[2:] + [requests[2]], retry_connects=1,
        management_attempts=0, mutation_attempts=0, forbidden_read_attempts=0)


class TwoHostRecoveryTests(unittest.TestCase):
    def test_port_probe_accepts_closed_server_but_rejects_live_listener(self):
        with socket.socket() as server:
            server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            server.bind(('127.0.0.1', 0))
            port = server.getsockname()[1]
            server.listen()
            with self.assertRaises(OSError):
                module.verify_ports_released([port])
            with socket.create_connection(('127.0.0.1', port)) as client:
                accepted, _ = server.accept()
                accepted.close()
                self.assertEqual(client.recv(1), b'')
        module.verify_ports_released([port])

    def test_entry_archive_wins_and_later_foreign_code_is_not_admitted(self):
        _, snapshot = module.helpers()
        with tempfile.TemporaryDirectory() as tmp:
            root = pathlib.Path(tmp)
            source = root / 'source'
            source.mkdir()
            baseline = root / 'frozen-entry'
            web = root / 'frozen-web-inputs'
            def archive(folder, files):
                folder.mkdir()
                rows = {}
                with tarfile.open(folder / 'executed-source.tar.gz', 'w:gz') as bundle:
                    for name, value in files.items():
                        raw = value.encode()
                        member = tarfile.TarInfo(name)
                        member.size = len(raw)
                        member.mode = 0o600
                        bundle.addfile(member, io.BytesIO(raw))
                        rows[name] = dict(sha256=hashlib.sha256(raw).hexdigest(), dirty=True)
                (folder / 'source.json').write_text(json.dumps(dict(inputs=rows)))
            old = "return lowerCaseError.contains('socketexception') ||"
            archive(baseline, {module.PRODUCTION: old, 'lib/entry.dart': 'entry'})
            archive(web, {'lib/entry.dart': 'foreign overwrite',
                          'lib/foreign.dart': 'outside scope', 'web/index.html': 'web'})
            target = source / module.OWNED[0]
            target.parent.mkdir(parents=True)
            target.write_text('owned overlay')
            app = root / 'app'
            actual = module.freeze(source, app, snapshot, baseline)
            self.assertEqual((app / 'lib/entry.dart').read_text(), 'entry')
            self.assertFalse((app / 'lib/foreign.dart').exists())
            self.assertEqual((app / 'web/index.html').read_text(), 'web')
            self.assertEqual((app / module.OWNED[0]).read_text(), 'owned overlay')
            self.assertIn('hermes api network connection failed', (app / module.PRODUCTION).read_text())
            self.assertEqual(len(actual['inherited_archives']), 2)

    def test_arguments_rejected_before_run(self):
        with mock.patch.object(module, 'run') as run:
            self.assertEqual(module.main(['--credential']), 2)
            run.assert_not_called()

    def test_freeze_attributes_only_owned_files_without_overlays(self):
        _, snapshot = module.helpers()
        self.assertEqual(snapshot.OVERLAYS, ())
        self.assertNotIn('hermes-agent', snapshot.ROOTS)
        self.assertNotIn('hermes-desktop', snapshot.ROOTS)
        identity = {'inputs': {module.OWNED[0]: {'dirty': True}, 'lib/a.dart': {'dirty': True}}}
        with mock.patch.object(snapshot, 'freeze', return_value=identity):
            actual = module.freeze(ROOT, ROOT / 'unused', snapshot)
        self.assertEqual(actual['inputs'][module.OWNED[0]]['owner'], module.CARD)
        self.assertEqual(actual['inputs']['lib/a.dart']['owner'], 'preexisting-worktree')

    def test_receipt_rejects_missing_owner_recovery_and_mutations(self):
        value = valid()
        with tempfile.TemporaryDirectory() as tmp:
            path = pathlib.Path(tmp) / 'receipt.json'
            path.write_text(json.dumps(value))
            self.assertEqual(module.read_receipt(path), value)
            for key, change in [('late_cases', []), ('keyboard_retry', False),
                    ('same_id_return_fenced', False), ('mutation_attempts', 1),
                    ('management_attempts', 1), ('physical_keychain', 'PASS'),
                    ('retry_requests', value['requests'][:2]),
                    ('requests', [dict(owner='B', method='POST', path='/api/sessions', query={})])]:
                path.write_text(json.dumps(value | {key: change}))
                with self.assertRaises(ValueError):
                    module.read_receipt(path)
            path.unlink()
            path.symlink_to('missing')
            with self.assertRaises(ValueError):
                module.read_receipt(path)


if __name__ == '__main__':
    unittest.main()
