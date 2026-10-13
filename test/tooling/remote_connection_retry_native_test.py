"""Remote launcher boundary tests, no GTK or personal state."""
import importlib.util
import json
import os
import pathlib
import tarfile
import tempfile
import unittest
from unittest import mock

ROOT = pathlib.Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('retry_native', ROOT / 'scripts/support/remote_connection_retry_native.py')
assert spec is not None and spec.loader is not None
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class RemoteRetryNativeTests(unittest.TestCase):
    def test_arguments_refuse_before_preparation(self):
        with mock.patch.object(module, 'run') as run:
            self.assertEqual(module.main(['--credential']), 2)
            run.assert_not_called()

    def test_environment_discards_shared_state(self):
        first, _ = module.helpers()
        with tempfile.TemporaryDirectory() as tmp:
            with mock.patch.dict(os.environ, {'DISPLAY': ':shared', 'HOME': '/private',
                 'DBUS_SESSION_BUS_ADDRESS': 'private', 'WING_LIVE_AUTH': 'forbidden',
                 'HTTPS_PROXY': 'private'}, clear=True), mock.patch.object(first.subprocess, 'check_output', return_value=b'/packages\n'):
                env = first.isolated_environment(pathlib.Path(tmp))
            for key in ('DISPLAY', 'DBUS_SESSION_BUS_ADDRESS', 'WING_LIVE_AUTH', 'HTTPS_PROXY'):
                self.assertNotIn(key, env)
            self.assertEqual(env['HOME'], tmp + '/home')
            self.assertEqual(env['CMAKE_BUILD_PARALLEL_LEVEL'], '2')

    def test_freeze_attributes_owned_and_inherited_without_overlay(self):
        _, snapshot = module.helpers()
        self.assertEqual(snapshot.OVERLAYS, ())
        identity = {'inputs': {module.OWNED[0]: {'dirty': True}, 'lib/a.dart': {'dirty': True}}}
        with mock.patch.object(snapshot, 'freeze', return_value=identity):
            value = module.freeze(ROOT, ROOT / 'unused', snapshot)
        self.assertEqual(value['inputs'][module.OWNED[0]]['owner'], module.CARD)
        self.assertEqual(value['inputs']['lib/a.dart']['owner'], 'preexisting-worktree')

    def test_receipt_requires_every_recovery_and_zero_forbidden_operations(self):
        value = dict(native_pid=1, width=390.0, text_scale=2.0, profile='synthetic-qa',
            session='synthetic-history', mutation_attempts=0, forbidden_read_attempts=0,
            auth_connects=1, auth_saves=0, retry_connects=1, retry_saves=1, save_attempts=6, save_commits=3,
            auth_profile='default', auth_session='synthetic-history',
            physical_keychain='NOT_CHECKED',
            late_cases=[{'reject': reject, 'replacement': replacement, 'fenced': True}
                for reject in (False, True) for replacement in (False, True)],
            requests=[{'method': 'GET', 'path': '/health', 'query': {}}],
            denied_reads=[{'status': 401, 'path': '/v1/capabilities', 'profile': None}])
        for key in ('public_entry', 'denial_sanitized', 'explicit_keyboard_retry', 'connected_draft_retained'):
            value[key] = True
        with tempfile.TemporaryDirectory() as tmp:
            path = pathlib.Path(tmp) / 'receipt.json'
            path.write_text(json.dumps(value))
            self.assertEqual(module.read_receipt(path), value)
            for key, changed in [('mutation_attempts', 1), ('forbidden_read_attempts', 1),
                                 ('late_cases', []), ('width', 800), ('retry_saves', 2),
                                 ('physical_keychain', 'PASS'),
                                 ('requests', [{'method': 'POST', 'path': '/health', 'query': {}}])]:
                path.write_text(json.dumps(value | {key: changed}))
                with self.assertRaises(ValueError):
                    module.read_receipt(path)
            path.unlink()
            path.symlink_to('missing')
            with self.assertRaises(ValueError):
                module.read_receipt(path)


if __name__ == '__main__':
    unittest.main()
