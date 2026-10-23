"""Public driver seams with synthetic tools/files; no installed GTK or Node."""
import contextlib
import importlib.util
import io
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO / 'scripts'))
sys.path.insert(0, str(REPO / 'scripts/support'))


class DriverTest(unittest.TestCase):
    def setUp(self):
        path = REPO / 'scripts/run_linux_feature_qualification.py'
        self.assertTrue(path.is_file(), 'The qualification entrypoint is missing')
        spec = importlib.util.spec_from_file_location('qualification_driver', path)
        self.driver = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(self.driver)
        temporary = tempfile.TemporaryDirectory(prefix='linuxqa-test-', dir=os.environ['TMPDIR'])
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.source = self.root / 'source'
        self.source.mkdir()
        self.put(self.source, 'lib/main.dart', 'current source')
        self.put(self.source, 'pubspec.yaml', 'name: wing\nversion: 0.1.0\n')
        self.put(self.source, 'pubspec.lock', 'packages: {}\n')
        self.put(self.source, '.dart_tool/package_config.json', json.dumps({'configVersion': 2,
            'packages': [{'name': 'wing', 'rootUri': self.source.as_uri()}]}))
        self.put(self.source, '.dart_tool/package_graph.json', json.dumps({'roots': ['wing'],
            'packages': [{'name': 'wing', 'version': '0.1.0'}]}))
        self.put(self.source, '.flutter-plugins-dependencies', '{"plugins": {}}')
        self.sdk = self.root / 'sdk'
        for name in ('bin/flutter', 'bin/cache/dart-sdk/bin/dart', 'bin/cache/engine.stamp',
                     'bin/internal/shared.sh', 'bin/cache/flutter_tools.snapshot',
                     'bin/cache/artifacts/engine/linux-x64/libflutter_linux_gtk.so',
                     'bin/cache/artifacts/engine/linux-x64/icudtl.dat'):
            self.put(self.sdk, name, 'synthetic executable')
        self.sdk_version = {'frameworkVersion': '3.44.2', 'dartSdkVersion': '3.12.2'}
        self.tools = self.root / 'tools'
        for name in ('node', 'pkg-config', 'xvfb-run', 'Xvfb', 'xauth', 'dbus-run-session',
                     'clang', 'cmake', 'ninja', 'git', 'bash'):
            self.put(self.tools, name, 'synthetic tool')
        self.prefix = self.root / 'prefix/usr'
        for name in ('gstreamer-1.0', 'gstreamer-app-1.0', 'gstreamer-audio-1.0', 'libsecret-1'):
            self.put(self.prefix, 'lib/x86_64-linux-gnu/pkgconfig/' + name + '.pc',
                     'prefix=' + str(self.prefix) + '\n')
        for name in ('libsecret-1.so', 'libgstreamer-1.0.so', 'libgstapp-1.0.so',
                     'libgstaudio-1.0.so', 'libgtk-3.so'):
            self.put(self.prefix, 'lib/x86_64-linux-gnu/' + name,
                     b'\x7fELF\x02\x01' + b'\0' * 12 + b'\x3e\0')
        for name in ('libsecret-1/libsecret/secret.h', 'gstreamer-1.0/gst/gst.h', 'gtk-3.0/gtk/gtk.h'):
            self.put(self.prefix, 'include/' + name, 'synthetic header')
        self.env = {'TMPDIR': str(self.root), 'PATH': '/usr/bin:/bin',
                    'WING_LINUX_DEPENDENCY_PREFIX': str(self.prefix), 'AUTOWORK_PORT_BASE': '20500'}
        self.out = self.root / 'output'
        self.node_version = 'v22.22.2'
        self.dart_version = 'Dart SDK version: 3.12.2 (stable)'
        self.calls, self.probes = [], []
        self.addCleanup(patch.stopall)
        patch('linux_qualification_support.shutil.which', side_effect=lambda name, **kw:
              str(self.sdk / 'bin/flutter') if name == 'flutter' else str(self.tools / name)).start()
        patch('linux_qualification_support.subprocess.run', side_effect=self.probe).start()
        patch.object(self.driver, 'run_owned', side_effect=self.child).start()
        patch.object(self.driver, 'live_group', return_value=False).start()
        patch.object(self.driver, 'native_processes', return_value=[{'native_pid': 124, 'start_ticks': '456'}]).start()
        patch.object(self.driver, 'process_identity', return_value={'native_pid': 124, 'start_ticks': '456'}).start()

    def put(self, root, name, value):
        path = root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        if isinstance(value, bytes):
            path.write_bytes(value)
        else:
            path.write_text(value)
        path.chmod(0o644)
        for parent in path.parents:
            if parent == self.root:
                break
            parent.chmod(0o755)
        return path

    def probe(self, command, **kwargs):
        self.probes.append(command)
        if command[0] == '/bin/cp':
            shutil.copytree(command[-2], command[-1], symlinks=True)
            output = ''
        elif '--modversion' in command:
            output = '3.24.38\n1.24.2\n1.24.2\n1.24.2\n0.21.4\n'
        elif '--variable=libdir' in command:
            output = str(self.prefix / 'lib/x86_64-linux-gnu')
        elif '--variable=includedir' in command:
            output = str(self.prefix / 'include')
        elif command[1:3] == ['rev-parse', 'HEAD']:
            output = 'a' * 40
        elif command[-1] == '--version':
            output = self.dart_version if command[0].endswith('/dart') else self.node_version
        else:
            raise AssertionError(command)
        return subprocess.CompletedProcess(command, 0, output, '')

    def case(self):
        return dict(id='synthetic-negative', feature_ids=['HD-PROJECT'], route_ids=['/projects'],
                    backend='synthetic', input='framework', storage='mock', status='unsupported',
                    skip_reason='Assignment API absent', negative_assertion=True, native_pid=124,
                    owner_count=1, operation_counts={'reads': 1, 'mutations': 0})

    def child(self, command, cwd, env, **kwargs):
        self.calls.append((command, cwd, env))
        self.assertEqual((cwd / 'lib/main.dart').read_text(), 'current source')
        if (self.source / 'macos').exists():
            for name in ('macos/Runner/AppDelegate.swift', 'windows/runner/main.cpp'):
                self.assertEqual((cwd / name).read_text(), 'synthetic host contract')
            self.assertEqual((cwd / '.github/workflows/fixture.yml').read_text(), 'synthetic workflow contract')
            self.assertEqual((cwd / 'playwright/tests/fixture.spec.mjs').read_text(), 'synthetic browser contract')
            self.assertEqual((cwd / 'web/index.html').read_text(), 'synthetic web entry')
        path = Path(env['WING_LINUX_TEST_ROOT']) / 'feature-cases.json'
        path.write_text(json.dumps({'schema': 1, 'cases': [self.case()]}))
        kwargs['observe'](123)
        return 0, 123

    def target(self, lane):
        names = {'connections': 'linux_connection_feature_qualification_test.dart',
                 'chat': 'linux_chat_feature_qualification_test.dart',
                 'management': 'linux_management_feature_qualification_test.dart',
                 'access': 'linux_access_feature_qualification_test.dart'}
        self.put(self.source, 'integration_test/' + names[lane], 'synthetic target')

    def invoke(self, lane='preflight', *, shared_batch=None):
        self.put(self.sdk, 'bin/cache/flutter.version.json', json.dumps(self.sdk_version))
        extra = ['--shared-batch', shared_batch] if shared_batch else []
        with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            return self.driver.main(['--lane', lane, '--output-dir', str(self.out), *extra],
                                    source=self.source, environ=self.env)

    def receipt(self, lane):
        return json.loads((self.out / (lane + '.json')).read_text())

    def test_preflight_and_runtime_reject_missing_stale_or_live_inputs(self):
        for kind in ('prefix', 'metadata', 'library', 'gtk', 'sdk', 'dart', 'node', 'packages', 'live'):
            with self.subTest(kind=kind):
                self.out = self.root / ('output-' + kind)
                env, sdk, node, dart = self.env.copy(), self.sdk_version.copy(), self.node_version, self.dart_version
                config = self.source / '.dart_tool/package_config.json'
                original_config = config.read_text()
                path = self.prefix / 'lib/x86_64-linux-gnu' / ('libgtk-3.so' if kind == 'gtk' else 'libsecret-1.so')
                original = path.read_bytes()
                pc = self.prefix / 'lib/x86_64-linux-gnu/pkgconfig/libsecret-1.pc'
                original_pc = pc.read_text()
                try:
                    if kind == 'prefix': self.env.pop('WING_LINUX_DEPENDENCY_PREFIX')
                    elif kind == 'metadata': pc.write_text('prefix=/obsolete/prefix\n')
                    elif kind in ('library', 'gtk'): path.unlink()
                    elif kind == 'sdk': self.sdk_version['frameworkVersion'] = '3.0.0'
                    elif kind == 'dart': self.dart_version = 'Dart SDK version: 3.0.0 (stable)'
                    elif kind == 'node': self.node_version = 'v26.0.0'
                    elif kind == 'packages': (self.source / '.dart_tool/package_config.json').unlink()
                    elif kind == 'live': self.env['WING_LIVE_AUTH'] = 'do-not-open'
                    self.assertEqual(self.invoke(), 0)
                    self.assertFalse(self.receipt('preflight')['ready'])
                    self.assertEqual(self.invoke('connections'), 2)
                    self.assertEqual(self.calls, [])
                finally:
                    self.env, self.sdk_version, self.node_version, self.dart_version = env, sdk, node, dart
                    config.write_text(original_config)
                    path.write_bytes(original)
                    path.chmod(0o644)
                    pc.write_text(original_pc)

    def test_unsafe_output_is_rejected_before_probes(self):
        for path in (self.source, self.root, self.prefix / 'output', self.root / 'nonempty', self.root / 'link'):
            with self.subTest(path=path):
                if path.name == 'nonempty': self.put(path, 'personal', 'preserve')
                if path.name == 'link': path.symlink_to(self.root)
                self.out = path
                self.assertEqual(self.invoke(), 2)
                self.assertEqual(self.probes, [])
                self.assertEqual(self.calls, [])

    def test_only_selected_late_target_is_required(self):
        self.target('connections')
        self.assertEqual(self.invoke(), 0)
        self.assertTrue(self.receipt('preflight')['ready'])
        self.assertEqual(self.invoke('management'), 2)
        self.assertEqual(self.calls, [])
        self.assertEqual(self.invoke('connections'), 0)
        self.assertEqual(self.calls[0][0][-1], 'integration_test/linux_connection_feature_qualification_test.dart')

    def test_dispatch_binds_current_source_and_owned_environment(self):
        self.target('management')
        self.put(self.source, 'macos/Runner/AppDelegate.swift', 'synthetic host contract')
        self.put(self.source, 'windows/runner/main.cpp', 'synthetic host contract')
        self.put(self.source, '.github/workflows/fixture.yml', 'synthetic workflow contract')
        self.put(self.source, 'playwright/tests/fixture.spec.mjs', 'synthetic browser contract')
        self.put(self.source, 'web/index.html', 'synthetic web entry')
        self.env.update(HOME='/personal', DISPLAY=':99', DBUS_SESSION_BUS_ADDRESS='private',
                        OPENAI_API_KEY='discard', HTTP_PROXY='discard', LD_PRELOAD='discard')
        self.assertEqual(self.invoke('management'), 0)
        receipt = self.receipt('management')
        self.assertEqual(receipt['schema'], 1)
        self.assertEqual(receipt['status'], 'pass')
        self.assertEqual(receipt['cases'][0]['id'], 'synthetic-negative')
        self.assertEqual(len(receipt['source']['tree_sha256']), 64)
        self.assertTrue(receipt['cleanup']['state_removed'])
        command, cwd, env = self.calls[0]
        self.assertIn(str(self.tools / 'xvfb-run'), command)
        self.assertIn(str(self.tools / 'dbus-run-session'), command)
        for key in ('DISPLAY', 'DBUS_SESSION_BUS_ADDRESS', 'OPENAI_API_KEY', 'HTTP_PROXY', 'LD_PRELOAD'):
            self.assertNotIn(key, env)
        self.assertNotEqual(env['HOME'], '/personal')
        self.assertEqual(env['XDG_CONFIG_HOME'], env['WING_LINUX_TEST_ROOT'] + '/config')
        self.assertFalse(cwd.exists())

    def test_exact_child_failure_and_signal_exits_survive(self):
        self.target('connections')
        for code in (37, -15):
            with self.subTest(code=code), patch.object(self.driver, 'run_owned', return_value=(code, 123)):
                self.assertEqual(self.invoke('connections'), code)
                self.assertEqual(self.receipt('connections')['commands'][0]['exit_code'], code)
                self.assertEqual(self.receipt('connections')['status'], 'fail')

    def test_invalid_or_empty_terminal_cases_never_pass(self):
        self.target('connections')
        valid = self.case()
        for cases in ([], [valid, valid], [valid | {'status': 'running'}], [valid | {'owner_count': True}],
                      [valid | {'operation_counts': {'reads': False}}], [valid | {'negative_assertion': False}]):
            with self.subTest(cases=cases):
                def child(command, cwd, env, **kwargs):
                    (Path(env['WING_LINUX_TEST_ROOT']) / 'feature-cases.json').write_text(
                        json.dumps({'schema': 1, 'cases': cases}))
                    kwargs['observe'](123)
                    return 0, 123
                with patch.object(self.driver, 'run_owned', side_effect=child):
                    self.assertEqual(self.invoke('connections'), 2)
                self.assertNotEqual(self.receipt('connections')['status'], 'pass')

    def test_interruption_replaces_prior_success_and_records_cleanup(self):
        self.target('connections')
        self.assertEqual(self.invoke('connections'), 0)
        with patch.object(self.driver, 'run_owned', side_effect=self.driver.Refusal('NATIVE_CANCELLED')):
            self.assertEqual(self.invoke('connections'), 2)
        receipt = self.receipt('connections')
        self.assertEqual(receipt['status'], 'fail')
        self.assertEqual(receipt['cases'], [])
        self.assertIsNone(receipt['commands'][0]['exit_code'])
        self.assertIn('log_sha256', receipt['commands'][0])
        self.assertTrue(receipt['cleanup']['state_removed'])

    def test_executed_snapshot_or_original_drift_cannot_pass(self):
        self.target('connections')
        for location in ('snapshot', 'original'):
            with self.subTest(location=location):
                self.out = self.root / ('drift-' + location)
                def child(command, cwd, env, **kwargs):
                    result = self.child(command, cwd, env, **kwargs)
                    ((cwd if location == 'snapshot' else self.source) / 'lib/main.dart').write_text('changed')
                    return result
                try:
                    with patch.object(self.driver, 'run_owned', side_effect=child):
                        self.assertEqual(self.invoke('connections'), 2)
                    self.assertEqual(self.receipt('connections')['status'], 'fail')
                finally:
                    (self.source / 'lib/main.dart').write_text('current source')

    def test_sdk_changed_between_inspection_and_copy_is_rejected(self):
        self.target('connections')
        original = self.driver.qa.prepare
        def prepare(*args, **kwargs):
            (self.sdk / 'bin/cache/dart-sdk/bin/dart').write_text('changed executable')
            return original(*args, **kwargs)
        with patch.object(self.driver.qa, 'prepare', side_effect=prepare):
            self.assertEqual(self.invoke('connections'), 2)
        self.assertEqual(self.calls, [])

    def test_sdk_cache_link_cannot_alias_shared_state(self):
        shared = self.root / 'shared-cache'
        shutil.move(str(self.sdk / 'bin/cache'), shared)
        (self.sdk / 'bin/cache').symlink_to(shared, target_is_directory=True)
        self.assertEqual(self.invoke(), 0)
        self.assertFalse(self.receipt('preflight')['ready'])
        self.assertEqual(self.invoke('connections'), 2)
        self.assertEqual(self.calls, [])

    def test_stale_campaign_is_not_reused(self):
        self.assertEqual(self.invoke(), 0)
        (self.source / 'lib/main.dart').write_text('changed')
        self.assertEqual(self.invoke('connections'), 2)
        self.assertEqual(self.calls, [])

    def test_package_config_cannot_add_an_unattributed_directory(self):
        self.put(self.source, 'pubspec.yaml', 'name: wing\nversion: 0.1.0\ndependencies:\n  absent: ^1.0.0\n')
        self.assertEqual(self.invoke(), 0)
        self.assertFalse(self.receipt('preflight')['ready'])
        self.assertEqual(self.calls, [])
        self.put(self.source, 'pubspec.yaml', 'name: wing\nversion: 0.1.0\n')
        config = json.loads((self.source / '.dart_tool/package_config.json').read_text())
        config['packages'][0]['packageUri'] = '../../outside/'
        (self.source / '.dart_tool/package_config.json').write_text(json.dumps(config))
        self.out = self.root / 'traversing-package-output'
        self.assertEqual(self.invoke(), 0)
        self.assertFalse(self.receipt('preflight')['ready'])

    def test_native_only_plugin_without_dart_library_is_a_valid_package_input(self):
        native = self.root / 'packages/native_plugin'
        self.put(native, 'pubspec.yaml', 'name: native_plugin\nversion: 1.0.0\nflutter:\n'
                 '  plugin:\n    platforms:\n      linux:\n        pluginClass: NativePlugin\n')
        self.put(native, 'linux/native_plugin.cc', 'synthetic native implementation')
        self.put(self.source, 'pubspec.lock', 'packages:\n  native_plugin:\n    version: "1.0.0"\n')
        config = json.loads((self.source / '.dart_tool/package_config.json').read_text())
        config['packages'].append({'name': 'native_plugin', 'rootUri': native.as_uri(), 'packageUri': 'lib/'})
        (self.source / '.dart_tool/package_config.json').write_text(json.dumps(config))
        self.put(self.source, '.dart_tool/package_graph.json', json.dumps({'roots': ['wing'],
            'packages': [{'name': 'wing', 'version': '0.1.0'}, {'name': 'native_plugin', 'version': '1.0.0'}]}))
        self.env['PUB_CACHE'] = str(native.parent)
        self.assertEqual(self.invoke(), 0)
        self.assertTrue(self.receipt('preflight')['ready'], self.receipt('preflight')['errors'])
        for uri in ('missing/', '../outside/', 'lib/../../outside/', 'file:///outside/'):
            with self.subTest(uri=uri):
                config['packages'][-1]['packageUri'] = uri
                (self.source / '.dart_tool/package_config.json').write_text(json.dumps(config))
                self.out = self.root / ('invalid-native-' + str(len(self.probes)))
                self.assertEqual(self.invoke(), 0)
                self.assertFalse(self.receipt('preflight')['ready'])
        config['packages'][-1]['packageUri'] = 'lib/'
        (self.source / '.dart_tool/package_config.json').write_text(json.dumps(config))
        (native / 'pubspec.yaml').write_text((native / 'pubspec.yaml').read_text().replace('1.0.0', '2.0.0'))
        self.out = self.root / 'stale-native'
        self.assertEqual(self.invoke(), 0)
        self.assertFalse(self.receipt('preflight')['ready'])

    def test_bundled_sky_engine_uses_the_sdk_zero_version(self):
        engine = self.sdk / 'bin/cache/pkg/sky_engine'
        self.put(engine, 'pubspec.yaml', 'name: sky_engine\n')
        self.put(engine, 'lib/ui.dart', 'synthetic engine library')
        self.put(self.source, 'pubspec.lock', 'packages:\n  sky_engine:\n    version: "0.0.0"\n')
        config = json.loads((self.source / '.dart_tool/package_config.json').read_text())
        config['packages'].append({'name': 'sky_engine', 'rootUri': engine.as_uri(), 'packageUri': 'lib/'})
        (self.source / '.dart_tool/package_config.json').write_text(json.dumps(config))
        self.put(self.source, '.dart_tool/package_graph.json', json.dumps({'roots': ['wing'],
            'packages': [{'name': 'wing', 'version': '0.1.0'}, {'name': 'sky_engine', 'version': '0.0.0'}]}))
        self.assertEqual(self.invoke(), 0)
        self.assertTrue(self.receipt('preflight')['ready'], self.receipt('preflight')['errors'])

        (engine / 'pubspec.yaml').write_text('name: sky_engine\nversion: 1.0.0\n')
        self.out = self.root / 'stale-engine'
        self.assertEqual(self.invoke(), 0)
        self.assertFalse(self.receipt('preflight')['ready'])
        other = self.sdk / 'packages/sky_engine'
        self.put(other, 'pubspec.yaml', 'name: sky_engine\n')
        self.put(other, 'lib/ui.dart', 'wrong engine location')
        config['packages'][-1]['rootUri'] = other.as_uri()
        (self.source / '.dart_tool/package_config.json').write_text(json.dumps(config))
        self.out = self.root / 'wrong-engine-root'
        self.assertEqual(self.invoke(), 0)
        self.assertFalse(self.receipt('preflight')['ready'])

    def test_nested_failure_keeps_native_exit_and_logs(self):
        self.target('access')
        self.put(self.source, 'integration_test/run_linux_shell_compact_return.py', 'synthetic runner')
        def child(command, cwd, env, **kwargs):
            if command[-1].endswith('.py'):
                out = Path(env['WING_LINUX_RUNNER_OUTPUT'])
                self.put(out, 'verification.json', json.dumps({'status': 'FAIL', 'exit_code': 37,
                    'isolated_state_removed': True, 'cleanup': {'groups_gone': True, 'state_removed': True}}))
                self.put(out, 'native.log', 'synthetic native failure')
                return 1, 123
            return self.child(command, cwd, env, **kwargs)
        with patch.object(self.driver, 'run_owned', side_effect=child):
            self.assertEqual(self.invoke('access'), 37)
        row = self.receipt('access')['commands'][1]
        self.assertEqual(row['exit_code'], 1)
        self.assertEqual(row['native_exit_code'], 37)
        self.assertEqual((self.out / row['artifacts']['native.log']['path']).read_text(), 'synthetic native failure')

    def test_nested_teardown_failure_preserves_the_owned_workspace(self):
        self.target('access')
        self.put(self.source, 'integration_test/run_linux_shell_compact_return.py', 'synthetic runner')
        def child(command, cwd, env, **kwargs):
            if command[-1].endswith('.py'):
                out = Path(env['WING_LINUX_RUNNER_OUTPUT'])
                self.put(out, 'verification.json', json.dumps({'status': 'FAIL', 'exit_code': None,
                    'cleanup_error': 'OWNED_TEARDOWN_INCOMPLETE', 'isolated_state_removed': False}))
                self.put(out, 'wing-linux-live.preserved/native-state', 'preserve')
                return 1, 123
            return self.child(command, cwd, env, **kwargs)
        with patch.object(self.driver, 'run_owned', side_effect=child):
            self.assertNotEqual(self.invoke('access'), 0)
        cleanup = self.receipt('access')['cleanup']
        self.assertFalse(cleanup['groups_gone'])
        self.assertFalse(cleanup['state_removed'])
        self.assertTrue((self.out / cleanup['state']).is_dir())
        attempt = self.root / 'producer-attempt'
        attempt.mkdir()
        result = {'status': 'PASS'}  # Cleanup failure must invalidate an earlier body verdict.
        with self.assertRaises(ValueError), self.driver.qa.record_attempt(attempt, result):
            (attempt / 'wing-linux-live.preserved').mkdir()
            raise ValueError('synthetic failure')
        proof = json.loads((attempt / 'verification.json').read_text())
        self.assertFalse(proof['cleanup']['groups_gone'])
        self.assertFalse(proof['isolated_state_removed'])
        self.assertEqual(proof['status'], 'FAIL')

    def test_shared_records_executed_suites_without_inventing_feature_cases(self):
        self.put(self.source, 'test/tooling/linux_feature_adapter_inventory_test.dart', 'inventory')
        self.put(self.source, 'integration_test/linux_feature_regression_test.dart', 'adapter')
        def child(command, cwd, env, **kwargs):
            self.calls.append((command, cwd, env))
            self.assertEqual(env.get('AUTOWORK_PORT_BASE'), '20500')
            name = 'synthetic suite'
            if '--name' in command:
                import re
                selection = re.compile(command[command.index('--name') + 1])
                name = next(n for n in (
                    'test/features/hermes_chat/bots/bot_chat_channel_test.dart synthetic suite',
                    'test/features/hermes_chat/screens/synthetic suite',
                    'test/features/profiles/profile_editor_sheet_test.dart failed delete needs fresh typed confirmation: synthetic',
                    'test/features/profiles/profile_editor_sheet_test.dart create failure clears credential and never replays: synthetic')
                    if selection.search(n))
            count = 3 if 'failed delete' in name else 2 if 'create failure' in name else 1
            events = []
            for number in range(1, count + 1):
                events.extend(({'type': 'testStart', 'test': {'id': number, 'name': name + str(number)}},
                               {'type': 'testDone', 'testID': number, 'skipped': False, 'result': 'success'}))
            events.append({'type': 'done', 'success': True})
            kwargs['stdout'].write(('\n'.join(json.dumps(e) for e in events) + '\n').encode())
            kwargs['observe'](123)
            return 0, 123
        with patch.object(self.driver, 'run_owned', side_effect=child):
            for batch in self.driver.SHARED_NATIVE_BATCHES:
                self.assertEqual(self.invoke('shared', shared_batch=batch), 0)
            self.assertTrue((self.out / '.wing-linux-qualification.json').exists())
            self.assertEqual(self.invoke('shared'), 0)
        receipt = self.receipt('shared')
        self.assertEqual(len(receipt['suite_runs']), 5)
        self.assertEqual(receipt['cases'], [])
        self.assertEqual(receipt['suite_runs'][1]['tests'][0]['name'],
                         'test/features/hermes_chat/bots/bot_chat_channel_test.dart synthetic suite1')
        calls = len(self.calls)
        self.assertEqual(self.invoke('shared'), 0)
        self.assertEqual(len(self.calls), calls, 'Matching terminal batches should be verified, not rerun')
        core = self.out / 'shared-core/shared.json'
        terminal = json.loads(core.read_text())
        for command in (['/bin/echo', 'test/tooling/linux_feature_adapter_inventory_test.dart'],
                        terminal['commands'][0]['command'] + ['--plain-name', 'narrowed']):
            changed = json.loads(json.dumps(terminal))
            changed['commands'][0]['command'] = command
            core.write_text(json.dumps(changed))
            self.assertEqual(self.invoke('shared'), 2)
        core.write_text(json.dumps(terminal | {'source': {}}))
        self.assertEqual(self.invoke('shared'), 2)
        core.write_text(json.dumps(terminal))
        log = self.out / 'shared-core' / terminal['commands'][0]['log']
        log.write_bytes(log.read_bytes() + b'changed')
        self.assertEqual(self.invoke('shared'), 2)
        self.assertNotIn('--name', self.calls[0][0])
        import re
        selections = [re.compile(c[c.index('--name') + 1]) for c, _, _ in self.calls[1:]]
        for title, count in (
                ('test/features/profiles/profile_editor_sheet_test.dart failed delete needs fresh typed confirmation: synthetic', 1),
                ('test/features/profiles/profile_editor_sheet_test.dart create failure clears credential and never replays: synthetic', 1),
                ('test/features/hermes_chat/bots/bot_chat_channel_test.dart synthetic Bot Chat', 1),
                ('test/features/hermes_chat/screens/hermes_chat_slash_commands_test.dart timestamp aliases are local', 1)):
            self.assertEqual(sum(bool(s.search(title)) for s in selections), count)
        start = {'type': 'testStart', 'test': {'id': 1, 'name': 'synthetic suite'}}
        end = {'type': 'testDone', 'testID': 1, 'skipped': False, 'result': 'success'}
        done = {'type': 'done', 'success': True}
        invalid = ([start, end, {'type': 'testStart', 'test': {'id': 2, 'name': 'unfinished'}}, done],
                   [start, start, end, done], [start, end | {'testID': 2}, done],
                   [start, end | {'hidden': True}, done])
        for index, events in enumerate(invalid):
            self.out = self.root / ('incomplete-' + str(index))
            def incomplete(command, cwd, env, **kwargs):
                kwargs['stdout'].write(('\n'.join(json.dumps(e) for e in events) + '\n').encode())
                kwargs['observe'](123)
                return 0, 123
            with self.subTest(events=events), patch.object(self.driver, 'run_owned', side_effect=incomplete):
                self.assertEqual(self.invoke('shared'), 2)

        def failed(command, cwd, env, **kwargs):
            kwargs['stdout'].write(('\n'.join(json.dumps(e) for e in
                (start, end | {'result': 'failure'}, done | {'success': False})) + '\n').encode())
            kwargs['observe'](123)
            return 37, 123
        self.out = self.root / 'failed-shared'
        with patch.object(self.driver, 'run_owned', side_effect=failed):
            self.assertEqual(self.invoke('shared', shared_batch='core'), 37)
        failed_suite = json.loads((self.out / 'shared-core/shared.json').read_text())['suite_runs'][0]
        self.assertEqual(failed_suite['status'], 'fail')
        self.assertEqual(failed_suite['tests'][0]['result'], 'failure')

    def test_report_delegation_does_not_need_a_native_runtime(self):
        self.put(self.source, 'scripts/check_linux_feature_qualification.py', 'synthetic checker')
        self.node_version = 'v26.0.0'
        def child(command, cwd, env, **kwargs):
            self.calls.append((command, cwd, env))
            return 0, 123
        with patch.object(self.driver, 'run_owned', side_effect=child):
            self.assertEqual(self.invoke('report'), 0)
        self.assertFalse(self.receipt('report')['ready'])
        self.assertEqual(self.receipt('report')['status'], 'pass')
        command = self.calls[0][0]
        self.assertEqual(command[-4:], ['--phase', 'fixture', '--input', str(self.out)])
        self.assertIn('scripts/check_linux_feature_qualification.py', command)
        self.assertFalse(any('xvfb-run' in v for v in command))

    def test_portable_runner_prefix_and_environment_isolation(self):
        import linux_qualification_support as qa
        state = self.root / 'state'
        state.mkdir()
        deps = qa.stage_dependencies(self.prefix, state / 'deps')
        env = qa.isolated_environment(state, prefix=deps, sdk=self.sdk)
        self.assertEqual(env['CMAKE_PREFIX_PATH'], str(deps))
        self.assertEqual(env['XDG_DATA_DIRS'], str(state / 'data'))
        self.assertEqual(env['GIO_USE_VFS'], 'local')
        self.assertEqual(env['GSETTINGS_BACKEND'], 'memory')
        self.assertIn('prefix=' + str(deps), (deps / 'lib/x86_64-linux-gnu/pkgconfig/libsecret-1.pc').read_text())
        sys.path.insert(0, str(REPO / 'integration_test'))
        for name in ('run_linux_shell_compact_return', 'run_linux_local_serve_reads', 'run_linux_transcript_keyboard'):
            spec = importlib.util.spec_from_file_location(name, REPO / 'integration_test' / (name + '.py'))
            module = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(module)
            with self.subTest(runner=name), patch.dict(os.environ, self.env | {'WING_LIVE_AUTH': 'discard'}, clear=True), \
                    patch.object(sys, 'argv', [name]), self.assertRaises(ValueError):
                module.run()


if __name__ == '__main__':
    unittest.main()
