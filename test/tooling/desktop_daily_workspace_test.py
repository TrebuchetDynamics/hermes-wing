"""Exercise workspace resource isolation, not source-string snapshots."""
import importlib.util
import json
import pathlib
import fcntl
import os
import subprocess
import tempfile
import unittest

spec = importlib.util.spec_from_file_location(
    'workspace', pathlib.Path(__file__).resolve().parents[2] /
    'scripts/support/desktop_daily_workspace.py')
assert spec is not None and spec.loader is not None
workspace = importlib.util.module_from_spec(spec)
spec.loader.exec_module(workspace)


class WorkspaceTest(unittest.TestCase):
    def test_competing_launcher_cannot_truncate_owned_receipts(self):
        with tempfile.TemporaryDirectory(prefix='daily-lock-test.') as temp:
            logs = pathlib.Path(temp) / 'desktop-daily-workflow-harness'
            logs.mkdir()
            launcher = logs / 'launcher.log'
            launcher.write_text('owned receipt')
            with (logs / 'flutter-owner.lock').open('w') as lock:
                fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
                result = subprocess.run([
                    'bash', str(pathlib.Path(__file__).resolve().parents[2] /
                                'scripts/run_linux_desktop_daily_workflow_e2e.sh')],
                    env=dict(os.environ, TMPDIR=temp), capture_output=True, text=True, timeout=5)
            self.assertEqual(result.returncode, 3)
            self.assertIn('ownership occupied', result.stdout)
            self.assertEqual(launcher.read_text(), 'owned receipt')

    def test_resources_and_local_dependency_closure_are_independent(self):
        with tempfile.TemporaryDirectory(prefix='daily-workspace-test.') as temp:
            base = pathlib.Path(temp)
            source, sdk = base / 'source', base / 'sdk'
            for name in ('lib', 'test', 'integration_test', 'assets', 'linux', 'wing_link',
                         'scripts/support', 'playwright/support', '.dart_tool'):
                (source / name).mkdir(parents=True)
            (sdk / 'bin/cache').mkdir(parents=True)
            (sdk / 'packages/flutter').mkdir(parents=True)
            (sdk / 'bin/cache/lockfile').write_text('shared-lock')
            (source / 'lib/main.dart').write_text('source')
            (source / 'playwright/support/dependency.mjs').write_text('fixture')
            (source / 'wing_link/go.mod').write_text('host closure')
            (source / 'linux/flutter/ephemeral').mkdir(parents=True)
            (source / 'linux/flutter/ephemeral/shared-build').write_text('preserve')
            (source / '.dart_tool/package_graph.json').write_text('{"roots":["wing"]}')
            external = base / 'pub-cache/package'
            external.mkdir(parents=True)
            (source / '.dart_tool/package_config.json').write_text(json.dumps({
                'packages': [
                    {'name': 'wing', 'rootUri': '../'},
                    {'name': 'flutter', 'rootUri': (sdk / 'packages/flutter').as_uri()},
                    {'name': 'external', 'rootUri': external.as_uri()},
                ],
            }))
            app, isolated = workspace.prepare(source, base / 'owned', sdk)
            config = json.loads((app / '.dart_tool/package_config.json').read_text())
            self.assertEqual([p['rootUri'] for p in config['packages']], [
                app.as_uri(), (isolated / 'packages/flutter').as_uri(), external.as_uri()])
            self.assertTrue((app / 'playwright/support/dependency.mjs').is_file())
            self.assertTrue((app / 'wing_link/go.mod').is_file())
            self.assertTrue((app / '.dart_tool/package_graph.json').is_file())
            self.assertFalse((app / 'linux/flutter/ephemeral').exists())
            (isolated / 'bin/cache/lockfile').write_text('owned-lock')
            (app / 'lib/main.dart').write_text('owned-source')
            self.assertEqual((sdk / 'bin/cache/lockfile').read_text(), 'shared-lock')
            self.assertEqual((source / 'lib/main.dart').read_text(), 'source')
            self.assertEqual((source / 'linux/flutter/ephemeral/shared-build').read_text(), 'preserve')
            with self.assertRaises(ValueError):
                workspace.prepare(source, base / 'owned', sdk)


if __name__ == '__main__':
    unittest.main()
