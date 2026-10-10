"""Launcher boundary regressions without GTK, sockets or personal state."""
import importlib.util
import json
import os
import pathlib
import tempfile
import unittest
from unittest import mock

ROOT = pathlib.Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('direct_native', ROOT / 'scripts/support/direct_first_run_native.py')
assert spec is not None and spec.loader is not None
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class DirectNativeTests(unittest.TestCase):
    def test_arguments_refuse_before_preparation(self):
        with mock.patch.object(module, 'run') as run:
            self.assertEqual(module.main(['--credential']), 2)
            run.assert_not_called()

    def test_isolated_environment_drops_private_inputs(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = pathlib.Path(tmp)
            with mock.patch.dict(os.environ, {'DISPLAY': ':shared', 'HOME': '/personal',
                 'DBUS_SESSION_BUS_ADDRESS': 'private', 'WING_LIVE_AUTH': 'forbidden',
                 'HTTPS_PROXY': 'private'}, clear=True), mock.patch.object(module.subprocess, 'check_output', return_value=b'/packages\n'):
                env = module.isolated_environment(root)
            for key in ('DISPLAY', 'DBUS_SESSION_BUS_ADDRESS', 'WING_LIVE_AUTH', 'HTTPS_PROXY'):
                self.assertNotIn(key, env)
            self.assertEqual(env['HOME'], str(root / 'home'))
            self.assertEqual(env['XDG_CONFIG_HOME'], str(root / 'config'))
            self.assertEqual(env['CMAKE_BUILD_PARALLEL_LEVEL'], '2')
            self.assertEqual((root / 'home').stat().st_mode & 0o777, 0o700)

    def test_workspace_and_process_cleanup_on_exception(self):
        helper = module.helpers()
        live, _ = helper.predecessor(ROOT)
        with tempfile.TemporaryDirectory() as tmp:
            with self.assertRaisesRegex(ValueError, 'owned test failure'):
                with live.owned_workspace(pathlib.Path(tmp)) as root:
                    child_root = root
                    def fail(pgid):
                        self.assertTrue(live.live_group(pgid))
                        raise ValueError('owned test failure')
                    with self.assertRaisesRegex(ValueError, 'owned test failure'):
                        live.run_owned(['python3', '-c', 'import time; time.sleep(30)'], root,
                                       {'PATH': os.environ['PATH']}, timeout=2, observe=fail)
                    raise ValueError('owned test failure')
            self.assertFalse(child_root.exists())

    def test_snapshot_attribution_and_exclusions(self):
        helper = module.helpers()
        with tempfile.TemporaryDirectory() as tmp:
            source = pathlib.Path(tmp) / 'source'
            source.mkdir()
            (source / 'lib').mkdir()
            (source / 'lib/a.dart').write_text('preexisting')
            (source / 'lib/.hermes').mkdir()
            (source / 'lib/.hermes/private').write_text('excluded')
            (source / 'lib/.env').write_text('excluded')
            app = pathlib.Path(tmp) / 'app'
            helper.ROOTS = ('lib',)
            helper.FILES = ()
            helper.OVERLAYS = ()
            helper.OWNED = ()
            with mock.patch.object(helper.subprocess, 'check_output', side_effect=[b'lib/a.dart\n', b'lib/a.dart\n', b'revision\n']):
                identity = helper.freeze(source, app)
            self.assertEqual(set(identity['inputs']), {'lib/a.dart'})
            self.assertTrue(identity['inputs']['lib/a.dart']['dirty'])
            self.assertFalse((app / 'lib/.hermes').exists())
            (source / 'lib/linked').symlink_to(source / 'lib/a.dart')
            with mock.patch.object(helper.subprocess, 'check_output', return_value=b''), self.assertRaisesRegex(ValueError, 'Linked source'):
                helper.freeze(source, pathlib.Path(tmp) / 'rejected')

    def test_receipt_rejects_mutation_management_missing_coverage(self):
        value = dict(native_pid=1, width=390.0, text_scale=2.0,
            keyboard_modes=['local', 'ssh', 'remote', 'vpn'], profile='synthetic-qa',
            session='synthetic-history', management_attempts=0, mutation_attempts=0, forbidden_read_attempts=0,
            requests=[{'method': 'GET', 'path': '/health', 'query': {}}],
            denied_reads=[{'status': 401, 'path': '/v1/capabilities', 'profile': None}])
        for key in ('public_entry', 'optional_pairing_reachable', 'back_no_save', 'pending_owner_fenced',
                    'denial_sanitized', 'explicit_keyboard_retry', 'agent_only_save'):
            value[key] = True
        with tempfile.TemporaryDirectory() as tmp:
            path = pathlib.Path(tmp) / 'receipt.json'
            path.write_text(json.dumps(value))
            self.assertEqual(module.read_receipt(path), value)
            for key, changed in [('mutation_attempts', 1), ('management_attempts', 1),
                                 ('pending_owner_fenced', False), ('width', 800), ('requests', [{'method': 'POST', 'path': '/health', 'query': {}}])]:
                path.write_text(json.dumps(value | {key: changed}))
                with self.assertRaises(ValueError):
                    module.read_receipt(path)


if __name__ == '__main__':
    unittest.main()
