import copy
import importlib.util
import json
import pathlib
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location('integrated', ROOT / 'scripts/support/integrated_daily_restart_native.py')
assert SPEC and SPEC.loader
module = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(module)


class IntegratedReceiptTest(unittest.TestCase):
    def receipt(self, phase='verify'):
        session = 'synthetic-off-page'
        model = {'method': 'POST', 'path': f'/api/sessions/{session}/model',
                 'profile': 'synthetic-qa', 'body': {'provider': 'synthetic', 'model': 'synthetic/model'}}
        def mutation(path, body):
            return {'method': 'POST', 'path': path, 'profile': 'synthetic-qa', 'body': body}
        sends = [mutation('/v1/runs', {'session_id': session, 'message': message}) for message in
                 ('Synthetic deliberate approval prompt', 'Synthetic deliberate Stop prompt', 'Synthetic deliberate resumed prompt')]
        trace = [model, sends[0], mutation('/v1/runs/run_1/approval', {'request_id': 'approval_run_1', 'choice': 'once'}),
                 sends[1], mutation('/v1/runs/run_2/stop', {})] if phase == 'write' else [model, sends[2]]
        requests = [{'method': 'GET', 'path': '/api/sessions', 'profile': 'synthetic-qa',
                     'query': {'profile': 'synthetic-qa'}, 'returned_ids': ['synthetic-first']},
                    *[{'method': 'GET', 'path': p, 'profile': 'synthetic-qa', 'query': {'profile': 'synthetic-qa'}}
                      for p in [f'/api/sessions/{session}', f'/api/sessions/{session}/messages', '/v1/runs/run_2']]]
        return {'native_pid': 123, 'phase': phase, 'width': 390.0, 'text_scale': 2.0,
                'profile': 'synthetic-qa', 'session': session, 'mutations': trace, 'requests': requests,
                'restore_mutations': 0, 'leave_mutations': 0, 'late_owner_fenced': phase == 'write',
                'phases': (['explicit-off-page-selection', 'correlated-approval', 'uncertain-stop-blocks-send', 'terminal-canonical-recovered']
                           if phase == 'write' else ['exact-restored-no-replay', 'explicit-reselection-resumed-send']),
                'canonical_ids': ['canonical_run_1', 'canonical_run_2'] + (['canonical_run_3'] if phase == 'verify' else []),
                'focus': [{'target': 'synthetic-control', 'rect': [0, 0, 100, 50]}]}

    def validate(self, value):
        with tempfile.TemporaryDirectory() as root:
            path = pathlib.Path(root) / 'receipt.json'
            path.write_text(json.dumps(value))
            return module.read_receipt(path)

    def test_valid_two_phases(self):
        for phase in ('write', 'verify'):
            self.assertEqual(self.validate(self.receipt(phase)), self.receipt(phase))

    def test_reject_restore_replay(self):
        changed = self.receipt()
        changed['mutations'].append(copy.deepcopy(changed['mutations'][-1]))
        with self.assertRaises(ValueError):
            self.validate(changed)

    def test_reject_wrong_approval_owner(self):
        changed = self.receipt('write')
        changed['mutations'][2]['path'] = '/v1/runs/run_2/approval'
        with self.assertRaises(ValueError):
            self.validate(changed)

    def test_reject_wrong_profile_session_request_and_run(self):
        for phase in ('write', 'verify'):
            for index, field, value in [(0, 'profile', 'foreign'), (1, 'body', {'session_id': 'foreign', 'message': 'Synthetic deliberate resumed prompt'})]:
                changed = self.receipt(phase)
                changed['mutations'][index][field] = value
                with self.subTest(phase=phase, field=field), self.assertRaises(ValueError):
                    self.validate(changed)
        changed = self.receipt('write')
        changed['mutations'][2]['body']['request_id'] = 'approval_run_2'
        with self.assertRaises(ValueError):
            self.validate(changed)

    def test_reject_missing_recovery_offpage_and_canonical(self):
        for key, value in [('canonical_ids', ['local']), ('restore_mutations', 1), ('leave_mutations', True),
                           ('phase', 'other'), ('focus', []), ('phases', [])]:
            with self.subTest(key=key), self.assertRaises(ValueError):
                self.validate(self.receipt() | {key: value})
        changed = self.receipt()
        changed['requests'][0]['returned_ids'].append('synthetic-off-page')
        with self.assertRaises(ValueError):
            self.validate(changed)
        changed = self.receipt('write')
        changed['late_owner_fenced'] = False
        with self.assertRaises(ValueError):
            self.validate(changed)


if __name__ == '__main__':
    unittest.main()
