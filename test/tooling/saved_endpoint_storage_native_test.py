import importlib.util
import json
import os
import pathlib
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location('storage_native', ROOT / 'scripts/support/saved_endpoint_storage_native.py')
assert SPEC is not None and SPEC.loader is not None
M = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(M)


class NativeStorageContractTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        (ROOT / 'build').mkdir(exist_ok=True)

    def test_private_bus_has_no_activation_or_external_listener(self):
        text = M.bus_config(pathlib.Path('/owned'))
        self.assertIn('unix:path=/owned/runtime/bus', text)
        for forbidden in ('servicedir', 'standard_session_servicedirs', 'tcp:', 'include', 'session.conf'):
            self.assertNotIn(forbidden, text)
        self.assertNotIn('<deny', text)
        denied = M.bus_config(pathlib.Path('/owned'), True)
        self.assertIn('send_member="CreateItem"', denied)
        self.assertNotIn('send_member="GetSecret"', denied)

    def test_receipt_rejects_false_secret_safety_and_extra_content(self):
        with tempfile.TemporaryDirectory(dir=ROOT / 'build') as directory:
            path = pathlib.Path(directory) / 'receipt'
            value = dict(phase='write', native_pid=123, cases=4,
                         real_plugins=True, canonical_peer_preserved=True,
                         preferences_secret_free=True, reopened_key_blank=True,
                         cancel_no_mutation=True, denied_save_retry=True,
                         connect_delta=0, mutation_attempts=0, active_read_delta=0)
            path.write_text(json.dumps(value))
            self.assertEqual(M.read_receipt(path, 'write'), value)
            for bad in ({'preferences_secret_free': False}, {'extra': 'not-allowed'},
                        {'native_pid': True}, {'connect_delta': 1}):
                path.write_text(json.dumps(value | bad))
                with self.assertRaises(ValueError):
                    M.read_receipt(path, 'write')
            path.unlink()
            path.symlink_to('/missing')
            with self.assertRaises(ValueError):
                M.read_receipt(path, 'write')

    def test_environment_does_not_inherit_personal_bus_display_home(self):
        _, first, _ = M.helpers()
        with tempfile.TemporaryDirectory(dir=ROOT / 'build') as directory:
            root = pathlib.Path(directory)
            env = first.isolated_environment(root)
            self.assertNotIn('DBUS_SESSION_BUS_ADDRESS', env)
            self.assertNotIn('DISPLAY', env)
            self.assertNotIn('WING_LIVE_AUTH', env)
            self.assertEqual(env['HOME'], str(root / 'home'))
            for name in ('home', 'config', 'data', 'cache', 'runtime'):
                self.assertEqual((root / name).stat().st_mode & 0o777, 0o700)

    def test_failure_unwinds_owned_process_and_state(self):
        _, _, snapshot = M.helpers()
        if 'WING_STORAGE_RUNTIME_HELPER' in os.environ:
            spec = importlib.util.spec_from_file_location('frozen_runtime', os.environ['WING_STORAGE_RUNTIME_HELPER'])
            assert spec is not None and spec.loader is not None
            live = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(live)
        else:
            live, _ = snapshot.predecessor(ROOT)
        with tempfile.TemporaryDirectory(dir=ROOT / 'build') as directory:
            seen = []
            with self.assertRaisesRegex(RuntimeError, 'injected'):
                with live.owned_workspace(pathlib.Path(directory)) as root:
                    def observe(pid):
                        seen.append(pid)
                        raise RuntimeError('injected')
                    live.run_owned(['/usr/bin/sleep', '10'], root,
                                   {'PATH': '/usr/bin'}, observe=observe)
            self.assertTrue(seen)
            self.assertFalse(live.live_group(seen[0]))
            self.assertEqual(list(pathlib.Path(directory).iterdir()), [])

    def test_public_launcher_accepts_no_arguments(self):
        self.assertEqual(M.main(['--personal-state']), 2)


if __name__ == '__main__':
    unittest.main()
