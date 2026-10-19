import copy
import importlib.util
import json
import pathlib
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location('transcript', ROOT / 'scripts/support/transcript_recovery_native.py')
module = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(module)


class TranscriptReceiptTest(unittest.TestCase):
    def receipt(self, phase='verify'):
        request = {'method': 'GET', 'origin': 'http://127.0.0.1:8642',
                   'path': '/api/sessions/synthetic-reconnect/messages',
                   'query': {'limit': '500', 'offset': '0', 'order': 'latest'}}
        return {'phase': phase, 'native_pid': 123 if phase == 'write' else 456,
            'width': 390.0, 'text_scale': 2.0,
            'owner': {'gateway': 'synthetic-transcript', 'profile': 'default',
                      'session': 'synthetic-reconnect', 'origin': 'http://127.0.0.1:8642'},
            'lease': {'run_id': 'run_1', 'session_id': 'synthetic-reconnect',
                      'base_url': 'http://127.0.0.1:8642', 'created_at': '2026-01-01T00:00:00.000Z'},
            'canonical_ids': ['canonical-user', 'canonical-commentary', 'canonical-read', 'canonical-web', 'canonical-answer'],
            'tools': [{'name': n, 'status': s} for n, s in (
                ('read_file', 'completed'), ('web_search', 'completed'), ('terminal', 'failed'), ('browser', 'running'))],
            'mutations': ['/v1/runs'] if phase == 'write' else [], 'decisions': [],
            'requests': [request, {'method': 'SSE', 'origin': 'http://127.0.0.1:8642',
                'path': '/v1/runs/run_1/events', 'query': {}}] + ([{'method': 'POST',
                'origin': 'http://127.0.0.1:8642', 'path': '/v1/runs', 'query': {},
                'body': {'session_id': 'synthetic-reconnect', 'message': 'Synthetic pending restart request',
                         'input': 'Synthetic pending restart request'}}]
                if phase == 'write' else [{'method': 'GET', 'origin': 'http://127.0.0.1:8642',
                    'path': '/v1/runs/run_1', 'query': {}}]),
            'approval_visible': phase == 'write', 'unresolved': True,
            'last_status': 'streaming' if phase == 'write' else 'failed'}

    def validate(self, value):
        with tempfile.TemporaryDirectory() as root:
            path = pathlib.Path(root) / 'receipt.json'
            path.write_text(json.dumps(value))
            return module.read_receipt(path)

    def test_correlated_receipts_reject_replay_and_false_success(self):
        for phase in ('write', 'verify'):
            self.assertEqual(self.validate(self.receipt(phase)), self.receipt(phase))
        for key, value in [('mutations', ['/v1/runs']), ('decisions', [{}]),
                           ('approval_visible', True), ('last_status', 'completed'),
                           ('unresolved', False), ('native_pid', True)]:
            with self.subTest(key=key), self.assertRaises(ValueError):
                self.validate(self.receipt() | {key: value})
        for field, value in [('path', '/private'), ('query', {'profile': 'foreign'}),
                             ('query', {'offset': '500', 'limit': '500', 'order': 'latest'}),
                             ('origin', 'http://foreign.invalid'), ('method', 'POST')]:
            changed = copy.deepcopy(self.receipt())
            changed['requests'][0][field] = value
            with self.subTest(field=field), self.assertRaises(ValueError):
                self.validate(changed)
        for field, value in [('profile', 'foreign'), ('input', 'changed')]:
            changed = self.receipt('write')
            changed['requests'][-1]['body'][field] = value
            with self.subTest(body=field), self.assertRaises(ValueError):
                self.validate(changed)

    def test_pair_requires_distinct_process_and_exact_owner(self):
        first, second = self.receipt('write'), self.receipt()
        module.validate_pair(first, second)
        for key, value in [('native_pid', first['native_pid']), ('owner', {}),
                           ('canonical_ids', []), ('tools', []), ('lease', {})]:
            with self.subTest(key=key), self.assertRaises(ValueError):
                module.validate_pair(first, second | {key: value})

    def test_build_identity_includes_dart_payload_not_only_runner(self):
        with tempfile.TemporaryDirectory() as root:
            bundle = pathlib.Path(root)
            (bundle / 'wing').write_bytes(b'runner')
            kernel = bundle / 'data/flutter_assets/kernel_blob.bin'
            kernel.parent.mkdir(parents=True)
            kernel.write_bytes(b'first synthetic Dart payload')
            before = module.bundle_hashes(bundle)
            kernel.write_bytes(b'changed synthetic Dart payload')
            after = module.bundle_hashes(bundle)
            self.assertEqual(before['wing'], after['wing'])
            self.assertNotEqual(before['data/flutter_assets/kernel_blob.bin'],
                                after['data/flutter_assets/kernel_blob.bin'])

    def test_arguments_never_admitted(self):
        self.assertEqual(module.main(['--live']), 2)


if __name__ == '__main__':
    unittest.main()
