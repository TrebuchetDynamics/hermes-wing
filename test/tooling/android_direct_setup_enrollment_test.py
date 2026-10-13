"""Exercise launcher admission and exact QA invocation without a device/build."""
import fcntl
import hashlib
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
RUNNER = ROOT / 'scripts/run_android_direct_setup_enrollment.sh'


class AndroidDirectSetupRunnerTest(unittest.TestCase):
    def setUp(self):
        self.scratch = tempfile.TemporaryDirectory(dir=os.environ['TMPDIR'])
        self.addCleanup(self.scratch.cleanup)
        root = Path(self.scratch.name)
        self.log = root / 'calls'
        self.env = {**os.environ, 'TMPDIR': str(root), 'WING_QA_DEVICE': 'synthetic-qa',
                    'WING_QA_DISPOSABLE': '1', 'CALL_LOG': str(self.log),
                    'PATH': str(root) + os.pathsep + os.environ['PATH']}
        self.env.pop('WING_LIVE_AUTH', None)
        (root / 'adb').write_text('#!/bin/sh\nprintf "adb %s\\n" "$*" >> "$CALL_LOG"\nprintf "%s\\n" "${ADB_STATE:-device}"\n')
        (root / 'flutter').write_text('#!/bin/sh\nprintf "flutter isolated=%s %s\\n" "$WING_ISOLATED_DEVICE_TEST" "$*" >> "$CALL_LOG"\nexit "${FLUTTER_STATUS:-0}"\n')
        for name in ('adb', 'flutter'):
            (root / name).chmod(0o700)

    def run_launcher(self, *args):
        return subprocess.run(['bash', str(RUNNER), *args], env=self.env,
                              capture_output=True, text=True, timeout=10)

    def calls(self):
        return self.log.read_text() if self.log.exists() else ''

    def test_explicit_serial_and_qa_only(self):
        result = self.run_launcher()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.calls().splitlines(), [
            'adb -s synthetic-qa get-state',
            'flutter isolated=1 test --no-pub --device-id synthetic-qa '
            '--dart-define=WING_ANDROID_DIRECT_SETUP_QA=true '
            'integration_test/android_direct_setup_enrollment_test.dart',
        ])

    def test_missing_serial_ownership_live_auth_and_arguments_fail_before_adb(self):
        for key, value, args in [
            ('WING_QA_DEVICE', '', ()), ('WING_QA_DISPOSABLE', '', ()),
            ('WING_LIVE_AUTH', '1', ()), ('WING_QA_DISPOSABLE', '1', ('extra',)),
        ]:
            with self.subTest(key=key, args=args):
                original = self.env.copy()
                self.env[key] = value
                self.assertNotEqual(self.run_launcher(*args).returncode, 0)
                self.assertEqual(self.calls(), '')
                self.env = original

    def test_offline_target_never_builds(self):
        self.env['ADB_STATE'] = 'offline'
        self.assertNotEqual(self.run_launcher().returncode, 0)
        self.assertNotIn('flutter', self.calls())

    def test_flutter_failure_is_preserved(self):
        self.env['FLUTTER_STATUS'] = '7'
        self.assertEqual(self.run_launcher().returncode, 7)

    def test_competing_target_writer_refused(self):
        root = Path(self.env['TMPDIR']) / 'desktop-daily-workflow-harness'
        root.mkdir()
        digest = hashlib.sha256(b'synthetic-qa').hexdigest()
        with (root / f'android-{digest}.lock').open('w') as lock:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            self.assertEqual(self.run_launcher().returncode, 3)
            self.assertEqual(self.calls(), '')


if __name__ == '__main__':
    unittest.main()
