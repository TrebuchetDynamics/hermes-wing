"""Receipt and launcher regressions; native behavior requires the GTK command."""
import importlib.util
import json
import pathlib
import shutil
import tarfile
import tempfile
import unittest
from typing import Any
from unittest import mock

ROOT = pathlib.Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('smoke', ROOT / 'scripts/support/desktop_no_inference_smoke.py')
assert spec is not None and spec.loader is not None
smoke = importlib.util.module_from_spec(spec)
spec.loader.exec_module(smoke)


def receipt(phase='write') -> dict[str, Any]:
    status = {'verify401': 401, 'verify403': 403}.get(phase)
    bootstrap = {'bootstrap401': 401, 'bootstrap403': 403}.get(phase)
    return dict(phase=phase, native_pid=123, owner_identity='a' * 64,
                history_identity='b' * 64,
                counts={k: 0 for k in ('sends', 'session_creates', 'model_writes', 'approvals', 'stops', 'provider_requests', 'management_requests', 'mutation_attempts')},
                requests=([dict(method='GET', path=p, query={}) for p in ('/health', '/v1/capabilities') * 4]
                          if bootstrap is not None else [dict(method='GET', path='/api/sessions', query={})]),
                keyboard_loading_cancel=True, keyboard_error_retry=True, wrong_owner_rejected=True,
                saved_owner_retained=True, cancelled_wrong_owner_rejected=True, cancelled_valid_owner_rejected=True,
                restoration_denial_status=status, keyboard_restoration_retry=status is not None,
                bootstrap_denial_status=bootstrap, keyboard_bootstrap_retry=bootstrap is not None,
                bootstrap_denied_requests=[] if bootstrap is None else [
                    [dict(method='GET', path=p, query={}) for p in ('/health', '/v1/capabilities', '/health', '/v1/capabilities')],
                    *[[dict(method='GET', path=p, query={}) for p in ('/health', '/v1/capabilities')] for _ in range(2)]],
                denied_reads=([dict(status=bootstrap, path='/v1/capabilities', profile=None)] * 4 if bootstrap is not None else
                              [] if status is None else [dict(status=status, path='/api/sessions/synthetic-history/messages', profile='synthetic-qa')] * 2))


class SnapshotTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = pathlib.Path(self.temp.name)
        self.source = self.root / 'source'
        self.source.mkdir()
        (self.source / 'lib/nested').mkdir(parents=True)
        (self.source / 'lib/nested/example.dart').write_text('original synthetic source')
        (self.source / 'pubspec.lock').write_text('synthetic dependency input')
        for attr, value in [('ROOTS', ('lib',)), ('FILES', ('pubspec.lock',)), ('OVERLAYS', ())]:
            patcher = mock.patch.object(smoke, attr, value)
            patcher.start()
            self.addCleanup(patcher.stop)
        patcher = mock.patch.object(smoke.subprocess, 'check_output', return_value=b'synthetic-base\n')
        patcher.start()
        self.addCleanup(patcher.stop)

    def test_source_file_link_rejected_without_reading_target(self):
        outside = self.root / 'outside'
        outside.write_text('synthetic forbidden bytes')
        (self.source / 'lib/nested/link.dart').symlink_to(outside)
        with mock.patch.object(pathlib.Path, 'read_bytes', side_effect=AssertionError('must not read link target')):
            with self.assertRaisesRegex(ValueError, 'Linked source'):
                smoke.freeze(self.source, self.root / 'app')
        self.assertFalse((self.root / 'app/lib/nested/link.dart').exists())

    def test_source_directory_and_root_links_rejected(self):
        for location in ('lib/nested/link', 'lib'):
            with self.subTest(location=location):
                path = self.source / location
                if path.exists():
                    shutil.rmtree(path)
                path.symlink_to(self.root, target_is_directory=True)
                with self.assertRaisesRegex(ValueError, 'Linked source'):
                    smoke.freeze(self.source, self.root / ('app-' + location.replace('/', '-')))

    def test_nested_runtime_state_never_copied_or_archived(self):
        for name in ('.pi', '.hermes', '.ua', '.env.private'):
            path = self.source / 'lib/nested' / name
            path.mkdir()
            (path / 'state.json').write_text('synthetic excluded state')
            # An excluded tree is not even descended into to inspect its links.
            (path / 'outside').symlink_to(self.root)
        app = self.root / 'app'
        identity = smoke.freeze(self.source, app)
        self.assertEqual(set(identity['inputs']), {'lib/nested/example.dart', 'pubspec.lock'})
        self.assertEqual({str(p.relative_to(app)) for p in app.rglob('*') if p.is_file()}, set(identity['inputs']))
        evidence = self.root / 'evidence'
        evidence.mkdir()
        (evidence / 'source.json').write_text(json.dumps(identity))
        smoke.retain_candidate(app, evidence, identity)
        with tarfile.open(evidence / 'executed-source.tar.gz') as bundle:
            self.assertEqual(set(bundle.getnames()), set(identity['inputs']) | {'source.json'})

    def test_archive_survives_source_edit_and_candidate_deletion(self):
        with mock.patch.object(smoke, 'OVERLAYS', ('lib/nested/example.dart',)):
            identity = smoke.freeze(self.source, self.root / 'app')
        evidence = self.root / 'evidence'
        evidence.mkdir()
        (evidence / 'source.json').write_text(json.dumps(identity))
        receipt = smoke.retain_candidate(self.root / 'app', evidence, identity)
        (self.source / 'lib/nested/example.dart').write_text('later shared edit')
        shutil.rmtree(self.root / 'app')
        archive = evidence / receipt['filename']
        self.assertEqual(smoke.digest(archive), receipt['sha256'])
        self.assertEqual(receipt['missing_inputs'], [])
        self.assertTrue(receipt['captured_before_checks'])
        self.assertEqual(archive.stat().st_mode & 0o777, 0o400)
        with tarfile.open(archive) as bundle:
            for name, expected in smoke.candidate_hashes(identity).items():
                stream = bundle.extractfile(name)
                self.assertIsNotNone(stream)
                self.assertEqual(smoke.hashlib.sha256(stream.read()).hexdigest(), expected)
            self.assertEqual(bundle.extractfile('lib/nested/example.dart').read(), b'synthetic-base\n')


class SmokeTest(unittest.TestCase):
    def test_arguments_refused_before_preparation(self):
        with mock.patch.object(smoke, 'run', side_effect=AssertionError('unexpected preparation')):
            self.assertEqual(smoke.main(['--live']), 2)
            self.assertEqual(smoke.main(['--origin=https://example.invalid']), 2)

    def check(self, value, reject=False, phase='write'):
        with tempfile.TemporaryDirectory() as root:
            path = pathlib.Path(root) / 'receipt.json'
            path.write_text(json.dumps(value))
            if reject:
                with self.assertRaises(ValueError):
                    smoke.read_receipt(path, phase)
            else:
                self.assertEqual(smoke.read_receipt(path, phase)[0], value)

    def test_valid_zero_mutation_receipt(self):
        self.check(receipt())

    def test_denial_matrix_requires_exact_owner_and_deliberate_retry(self):
        for phase in ('verify401', 'verify403'):
            self.check(receipt(phase), phase=phase)
            for key, wrong in [('saved_owner_retained', False),
                               ('keyboard_restoration_retry', False),
                               ('cancelled_wrong_owner_rejected', False),
                               ('cancelled_valid_owner_rejected', False),
                               ('restoration_denial_status', 404), ('denied_reads', [])]:
                with self.subTest(phase=phase, key=key):
                    value = receipt(phase)
                    value[key] = wrong
                    self.check(value, True, phase=phase)
            value = receipt(phase)
            value['denied_reads'][0]['profile'] = 'other-owner'
            self.check(value, True, phase=phase)

    def test_management_read_is_not_agent_recovery(self):
        value = receipt()
        value['requests'][0]['path'] = '/v1/devices'
        self.check(value, True)

    def test_bootstrap_requires_no_downstream_reads_and_deliberate_recovery(self):
        for phase in ('bootstrap401', 'bootstrap403'):
            self.check(receipt(phase), phase=phase)
            for key, wrong in [('bootstrap_denial_status', 404),
                               ('keyboard_bootstrap_retry', False),
                               ('bootstrap_denied_requests', []),
                               ('denied_reads', []), ('saved_owner_retained', False),
                               ('cancelled_valid_owner_rejected', False)]:
                with self.subTest(phase=phase, key=key):
                    value = receipt(phase)
                    value[key] = wrong
                    self.check(value, True, phase=phase)
            for path in ('/api/profiles', '/api/sessions', '/api/sessions/synthetic-history/messages'):
                value = receipt(phase)
                value['bootstrap_denied_requests'][0].append(dict(method='GET', path=path, query={}))
                self.check(value, True, phase=phase)

    def test_all_mutations_rejected(self):
        for key in receipt()['counts']:
            with self.subTest(key=key):
                value = receipt()
                value['counts'][key] = 1
                self.check(value, True)

    def test_boolean_counters_are_not_zero(self):
        value = receipt()
        value['counts']['sends'] = False
        self.check(value, True)

    def test_non_read_request_rejected(self):
        value = receipt()
        value['requests'][0]['method'] = 'POST'
        self.check(value, True)

    def test_wrong_phase_and_identity_rejected(self):
        for key, wrong in [('phase', 'verify'), ('owner_identity', 'wrong-owner'),
                           ('history_identity', 'wrong-history'), ('native_pid', True),
                           ('keyboard_loading_cancel', False), ('keyboard_error_retry', False),
                           ('wrong_owner_rejected', False)]:
            with self.subTest(key=key):
                value = receipt()
                value[key] = wrong
                self.check(value, True)

    def test_symlink_receipt_rejected(self):
        with tempfile.TemporaryDirectory() as root:
            path = pathlib.Path(root)
            (path / 'real').write_text(json.dumps(receipt()))
            (path / 'link').symlink_to(path / 'real')
            with self.assertRaises(ValueError):
                smoke.read_receipt(path / 'link', 'write')

    def test_fixture_has_no_default_transport_or_credentials(self):
        text = (ROOT / smoke.OWNED[3]).read_text()
        for transport in ('Post', 'Patch', 'Put', 'Delete', 'PostStream', 'GetStream'):
            self.assertIn('unsupportedHermesApi' + transport, text)
        self.assertNotIn('HttpClient(', text)
        self.assertNotIn('apiKey:', text)
        driver = (ROOT / smoke.OWNED[2]).read_text()
        self.assertIn('GatewayContactCache()', driver)
        self.assertNotIn('setMockInitialValues', driver)
        self.assertIn('HermesApiChannel(', driver)
        self.assertIn('AppShell(', driver)
        self.assertIn('HermesChatScreen()', driver)


if __name__ == '__main__':
    unittest.main()
