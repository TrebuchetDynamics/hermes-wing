"""Preparation proofs only: never evidence of Linux/Android app execution."""
import importlib.util
import pathlib
import tempfile
import unittest

REPO = pathlib.Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location(
    'managed_ssh_key_native', REPO / 'scripts/support/managed_ssh_key_native.py')
assert SPEC is not None and SPEC.loader is not None


class PreparationTests(unittest.TestCase):
    def helper(self):
        self.assertTrue(SPEC.origin and pathlib.Path(SPEC.origin).is_file(),
                        'Executable native preparation helper is missing')
        module = importlib.util.module_from_spec(SPEC)
        SPEC.loader.exec_module(module)
        return module

    def test_mapping_is_explicit_and_bounded(self):
        m = self.helper()
        self.assertEqual(m.mapping('linux', None), '127.0.0.1')
        self.assertEqual(m.mapping('android', 'adb-reverse'), '127.0.0.1')
        for lane, mode in [('android', None), ('android', 'localhost'),
                           ('android', '10.0.2.2'), ('web', None)]:
            with self.assertRaises(ValueError):
                m.mapping(lane, mode)

    def test_snapshot_freezes_inputs_and_refuses_aliases(self):
        m = self.helper()
        evidence = REPO / '.task-evidence/parallel-key-native'
        evidence.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(dir=evidence) as temp:
            root = pathlib.Path(temp)
            source = root / 'source'
            (source / 'lib').mkdir(parents=True)
            (source / 'lib/main.dart').write_text('original')
            (source / 'pubspec.yaml').write_text('name: wing')
            target = root / 'snapshot'
            receipt = m.freeze(source, target)
            self.assertEqual(receipt['inputs']['lib/main.dart'],
                             m.sha(source / 'lib/main.dart'))
            (source / 'lib/main.dart').write_text('changed')
            self.assertEqual((target / 'lib/main.dart').read_text(), 'original')
            m.verify_product(target, receipt)
            (target / 'lib/main.dart').write_text('unexpected generator edit')
            with self.assertRaises(RuntimeError):
                m.verify_product(target, receipt)
            with self.assertRaises(ValueError):
                m.freeze(source, target)
            (source / 'lib/link').symlink_to(source / 'lib/main.dart')
            with self.assertRaises(ValueError):
                m.freeze(source, root / 'bad')

    def test_native_commands_keep_platform_lanes_separate(self):
        m = self.helper()
        linux = m.native_command('/sdk/flutter', 'linux', None)
        android = m.native_command('/sdk/flutter', 'android', 'owned-device')
        self.assertEqual(linux[:3], ['xvfb-run', '-a', '-s'])
        self.assertIn('linux', linux)
        self.assertNotIn('owned-device', linux)
        self.assertIn('owned-device', android)
        self.assertNotIn('xvfb-run', android)
        with self.assertRaises(ValueError):
            m.native_command('/sdk/flutter', 'android', None)

    def test_result_validation_rejects_unbounded_and_unsanitized_data(self):
        m = self.helper()
        journey = {f'GET {path}': 1 for path in ('/health', '/v1/capabilities',
            '/api/profiles', '/api/sessions', '/api/model/options',
            '/api/sessions/qa-history/messages')}
        value = {'platform': 'linux', 'workflow': 'PASS',
                 'native_picker': 'NOT_CHECKED', 'physical_secure_storage': 'NOT_CHECKED',
                 'encrypted_key': 'NOT_CHECKED', 'model': 'READ_ONLY_INVENTORY',
                 'wing_link': 'NO_LISTENER', 'cycles': [{'request_delta': journey}] * 2,
                 'counters': {'requests': {key: 2 for key in journey}, 'mutation_attempts': 0,
                              'forbidden_reads': 0, 'forbidden_ssh': 0,
                              'auth_denials': 0, 'ssh_auths': 3, 'ssh_denials': 1,
                              'forwards': 2, 'live_ssh': 0}}
        self.assertEqual(m.validate_result(value, 'linux'), value)
        value['private_key'] = 'never retain arbitrary Flutter output'
        with self.assertRaises(ValueError):
            m.validate_result(value, 'linux')
        del value['private_key']
        saved = journey.pop('GET /api/sessions/qa-history/messages')
        with self.assertRaises(ValueError):
            m.validate_result(value, 'linux')
        journey['GET /api/sessions/qa-history/messages'] = saved
        value['counters']['mutation_attempts'] = 1
        with self.assertRaises(ValueError):
            m.validate_result(value, 'linux')

    def test_supervisor_reaps_term_ignoring_descendant(self):
        import asyncio
        import os
        import sys
        m = self.helper()
        async def scenario():
            descendant = "import signal,time; signal.signal(signal.SIGTERM,signal.SIG_IGN); print('ready',flush=True); time.sleep(30)"
            script = "import subprocess,sys,time; subprocess.Popen([sys.executable,'-c'," + repr(descendant) + "]); time.sleep(30)"
            child = await asyncio.create_subprocess_exec(sys.executable, '-c', script,
                stdout=asyncio.subprocess.PIPE, start_new_session=True)
            assert child.stdout is not None
            await asyncio.wait_for(child.stdout.readline(), 3)
            await m.stop_group(child)
            await m.stop_group(child)
            self.assertEqual(child.returncode, -15)
            self.assertFalse(m.live_group(child.pid))
        asyncio.run(scenario())

    def test_disposable_ssh_fixture_probe_and_teardown(self):
        import asyncio
        m = self.helper()
        result = asyncio.run(m.probe_fixture())
        self.assertEqual(result, {'fixture_only': True, 'pinned_key_forward': True,
            'wrong_key_denied': True, 'changed_host_key_denied': True,
            'unowned_forward_denied': True, 'shell_denied': True,
            'closed': True, 'native_workflow': 'NOT_CHECKED'})

    def test_agent_routes_auth_and_mutation_fail_closed(self):
        m = self.helper()
        agent = m.Agent('disposable-test-token')
        self.assertEqual(agent.respond('GET', '/health', {}, '')[0], 401)
        headers = {'authorization': 'Bearer disposable-test-token'}
        self.assertEqual(agent.respond('POST', '/api/sessions', headers, '')[0], 405)
        self.assertEqual(agent.respond('GET', '/v1/host', headers, '')[0], 404)
        code, capabilities = agent.respond('GET', '/v1/capabilities', headers, '')
        self.assertEqual(code, 200)
        self.assertTrue(capabilities['auth']['required'])
        self.assertEqual(agent.respond('GET', '/api/sessions?profile=other', headers, '')[0], 404)
        code, history = agent.respond('GET', '/api/sessions/qa-history/messages?profile=qa-key', headers, '')
        self.assertEqual((code, history['session_id']), (200, 'qa-history'))
        self.assertEqual(agent.summary()['requests']['GET /v1/capabilities'], 1)
        self.assertEqual(agent.summary()['mutation_attempts'], 1)
        self.assertEqual(agent.summary()['forbidden_reads'], 2)
        self.assertNotIn('disposable-test-token', str(agent.summary()))


if __name__ == '__main__':
    unittest.main()
