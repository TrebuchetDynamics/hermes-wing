"""Remote explanation launcher boundaries; never GTK or personal state."""
import importlib.util
import json
import os
import pathlib
import tempfile
import unittest
from unittest import mock

ROOT = pathlib.Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('auth_native', ROOT / 'scripts/support/remote_auth_explanation_native.py')
assert spec is not None and spec.loader is not None
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class RemoteAuthNativeTests(unittest.TestCase):
    def test_arguments_refused_before_preparation(self):
        with mock.patch.object(module, 'run') as run:
            self.assertEqual(module.main(['--credential']), 2)
            run.assert_not_called()

    def test_environment_discards_shared_state(self):
        first, snapshot = module.helpers()
        self.assertEqual(snapshot.CARD, module.CARD)
        self.assertEqual(snapshot.OVERLAYS, ())
        with tempfile.TemporaryDirectory() as tmp:
            with mock.patch.dict(os.environ, {'DISPLAY': ':shared', 'HOME': '/private',
                'DBUS_SESSION_BUS_ADDRESS': 'private', 'WING_LIVE_AUTH': 'forbidden',
                'HTTPS_PROXY': 'private'}, clear=True), mock.patch.object(first.subprocess, 'check_output', return_value=b'/packages\n'):
                env = first.isolated_environment(pathlib.Path(tmp))
            for key in ('DISPLAY', 'DBUS_SESSION_BUS_ADDRESS', 'WING_LIVE_AUTH', 'HTTPS_PROXY'):
                self.assertNotIn(key, env)
            self.assertEqual(env['HOME'], tmp + '/home')
            self.assertEqual(env['CMAKE_BUILD_PARALLEL_LEVEL'], '2')

    def test_receipt_requires_both_denials_explicit_controls_and_zero_mutations(self):
        value = dict(native_pid=1, width=390.0, text_scale=2.0, connects=4, saves=1,
            token_reads=12, management_attempts=0, mutation_attempts=0, forbidden_read_attempts=0,
            physical_keychain='NOT_CHECKED',
            requests=[{'method': 'GET', 'path': '/health', 'query': {}}],
            denied_reads=[{'status': status, 'path': '/v1/capabilities', 'profile': None}
                for status in (403, 401)])
        for key in ('public_entry', 'denial_sanitized', 'keyboard_explanation',
                    'explicit_retry_cancel', 'form_draft_retained'):
            value[key] = True
        with tempfile.TemporaryDirectory() as tmp:
            path = pathlib.Path(tmp) / 'receipt.json'
            path.write_text(json.dumps(value))
            self.assertEqual(module.read_receipt(path), value)
            for key, changed in [('mutation_attempts', 1), ('management_attempts', 1),
                ('denied_reads', []), ('keyboard_explanation', False), ('token_reads', 0),
                ('saves', 2), ('physical_keychain', 'PASS'),
                ('requests', [{'method': 'GET', 'path': '/oauth', 'query': {}}])]:
                path.write_text(json.dumps(value | {key: changed}))
                with self.assertRaises(ValueError):
                    module.read_receipt(path)
            path.unlink()
            path.symlink_to('missing')
            with self.assertRaises(ValueError):
                module.read_receipt(path)


if __name__ == '__main__':
    unittest.main()
