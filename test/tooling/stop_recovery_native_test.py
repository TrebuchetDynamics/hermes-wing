import copy
import importlib.util
import json
import pathlib
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location('stop', ROOT / 'scripts/support/stop_recovery_native.py')
assert SPEC and SPEC.loader
module = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(module)


class StopReceiptTest(unittest.TestCase):
    def receipt(self):
        return {'native_pid': 123, 'width': 390.0, 'text_scale': 2.0,
            'phases': ['acknowledged-unresolved', 'unknown', 'wrong-run', 'status-error',
                       'history-error', 'canonical-recovered', 'stop-error', 'late-owner-fenced'],
            'mutations': ['/v1/runs', '/v1/runs/run_1/stop', '/v1/runs',
                          '/v1/runs/run_2/stop', '/v1/runs', '/v1/runs/run_3/stop', '/v1/runs'],
            'reads': ['/health', '/v1/capabilities', '/api/sessions',
                      '/api/sessions/synthetic-reconnect/messages',
                      '/v1/runs/run_1', '/v1/runs/run_2', '/v1/runs/run_3'],
            'canonical_ids': ['canonical-stop'], 'recovery_mutations': 0,
            'creates': 0, 'approvals': 0, 'stops': 3, 'deliberate_resumed_sends': 1,
            'late_owner_fenced': True}

    def validate(self, value):
        with tempfile.TemporaryDirectory() as root:
            path = pathlib.Path(root) / 'receipt.json'
            path.write_text(json.dumps(value))
            return module.read_receipt(path)

    def test_valid_correlated_receipt(self):
        self.assertEqual(self.validate(self.receipt()), self.receipt())

    def test_reject_replay_and_incomplete_coverage(self):
        for key, value in [('recovery_mutations', 1), ('creates', 1), ('approvals', 1),
                           ('stops', True), ('late_owner_fenced', False),
                           ('phases', ['canonical-recovered']), ('canonical_ids', ['local'])]:
            with self.subTest(key=key), self.assertRaises(ValueError):
                self.validate(self.receipt() | {key: value})

    def test_reject_wrong_owner_and_extra_requests(self):
        for key, extra in [('mutations', '/api/sessions'), ('reads', '/private')]:
            changed = self.receipt()
            changed[key].append(extra)
            with self.assertRaises(ValueError):
                self.validate(changed)
        changed = copy.deepcopy(self.receipt())
        changed['mutations'][3] = '/v1/runs/run_1/stop'
        with self.assertRaises(ValueError):
            self.validate(changed)

    def test_reject_missing_status_evidence(self):
        changed = self.receipt()
        changed['reads'].remove('/v1/runs/run_2')
        with self.assertRaises(ValueError):
            self.validate(changed)

    def test_arguments_never_admitted(self):
        self.assertEqual(module.main(['--live']), 2)


if __name__ == '__main__':
    unittest.main()
