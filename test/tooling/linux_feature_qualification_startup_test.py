"""Startup proof must include an owned rendered window, not just a live process."""
import contextlib
import importlib.util
import io
import json
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import Mock, patch

REPO = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('linux_startup', REPO / 'integration_test/run_linux_production_startup.py')
startup = importlib.util.module_from_spec(spec)
spec.loader.exec_module(startup)


class StartupTest(unittest.TestCase):
    def test_blank_small_and_wrong_sized_images_do_not_prove_startup(self):
        window = startup.window_geometry('WINDOW=42\nWIDTH=1280\nHEIGHT=960\n')
        self.assertEqual(startup.image_geometry('1280 960 128', window)['colors'], 128)
        for value in ('1280 960 1', '0 0 128', '1280 959 128', '1280 960'):
            with self.subTest(value=value), self.assertRaises(ValueError):
                startup.image_geometry(value, window)
        with self.assertRaises(ValueError):
            startup.window_geometry('WIDTH=0\nHEIGHT=0\n')

    def test_inherited_live_opt_in_cannot_start_or_prepare_anything(self):
        with patch.dict(os.environ, {'WING_LIVE_AUTH': 'synthetic'}, clear=True), \
                patch.object(startup.qa, 'runner_output') as output, self.assertRaises(ValueError):
            startup.run()
        output.assert_not_called()

    def test_unready_preflight_stops_before_snapshot_and_retains_the_gap(self):
        with tempfile.TemporaryDirectory() as temporary:
            env = {'TMPDIR': temporary}
            with patch.dict(os.environ, env, clear=True), \
                    patch.object(startup.qa, 'inspect', return_value=(
                        dict(ready=False, errors=['Missing tool: Xvfb'], toolchain={}), None, None, None)), \
                    patch.object(startup.qa, 'snapshot') as snapshot, \
                    contextlib.redirect_stdout(io.StringIO()):
                self.assertEqual(startup.run(), 2)
            snapshot.assert_not_called()
            receipt = json.loads(next(Path(temporary).glob('*/verification.json')).read_text())
            self.assertEqual(receipt['status'], 'NOT_RUN')
            self.assertEqual(receipt['commands'], [])
            self.assertEqual(receipt['errors'], ['Missing tool: Xvfb'])
            self.assertTrue(receipt['cleanup']['state_removed'])

    def test_a_live_process_without_a_mapped_window_fails_and_is_terminated(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / 'app').mkdir()
            (root / '.wing-startup-owner').touch()
            child = Mock(pid=os.getpid())
            child.poll.return_value = None
            env = {'WING_LINUX_TEST_ROOT': temporary, 'HOME': str(root / 'home'), 'DISPLAY': ':999'}
            with patch.dict(os.environ, env, clear=True), patch.object(startup, 'SOURCE', root / 'app'), \
                    patch.object(startup.subprocess, 'Popen', return_value=child), \
                    patch.object(startup.time, 'monotonic', side_effect=[0, 31]), \
                    self.assertRaisesRegex(ValueError, 'did not map'):
                startup.observe_window()
            child.terminate.assert_called_once()
            child.wait.assert_called_once_with(timeout=5)


if __name__ == '__main__':
    unittest.main()
