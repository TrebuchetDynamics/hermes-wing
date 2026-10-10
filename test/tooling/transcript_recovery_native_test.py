import copy
import importlib.util
import json
import pathlib
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location('transcript', ROOT / 'scripts/support/transcript_recovery_native.py')
assert SPEC and SPEC.loader
module = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(module)


class TranscriptReceiptTest(unittest.TestCase):
    def receipt(self):
        decisions = [{'path': f'/v1/runs/run_{n}/approval', 'request_id': f'request_{n}', 'choice': 'once'} for n in (2, 3, 3, 4, 5)]
        return {'native_pid': 123, 'width': 390.0, 'text_scale': 2.0,
            'decisions': decisions, 'recovery_mutations': 0, 'creates': 0, 'stops': 0,
            'retired_rejected': True, 'late_failure_fenced': True, 'explicit_retry_only': True,
            'canonical_ids': ['canonical-user', 'canonical-commentary', 'canonical-read', 'canonical-web', 'canonical-answer'],
            'mutations': ['/v1/runs'] * 5 + [d['path'] for d in decisions],
            'reads': ['/health', '/v1/capabilities', '/api/sessions', '/api/sessions/synthetic-reconnect/messages']}

    def validate(self, value):
        with tempfile.TemporaryDirectory() as root:
            path = pathlib.Path(root) / 'receipt.json'
            path.write_text(json.dumps(value))
            return module.read_receipt(path)

    def test_valid_correlated_receipt(self):
        self.assertEqual(self.validate(self.receipt()), self.receipt())

    def test_reject_replay_and_wrong_owner(self):
        for key, value in [('recovery_mutations', 1), ('creates', 1), ('stops', True), ('retired_rejected', False)]:
            changed = self.receipt() | {key: value}
            with self.subTest(key=key), self.assertRaises(ValueError):
                self.validate(changed)
        changed = copy.deepcopy(self.receipt())
        changed['decisions'][-1]['request_id'] = 'request_4'
        with self.assertRaises(ValueError):
            self.validate(changed)

    def test_reject_extra_mutation_and_read(self):
        for key, extra in [('mutations', '/api/sessions'), ('reads', '/private')]:
            changed = self.receipt()
            changed[key].append(extra)
            with self.assertRaises(ValueError):
                self.validate(changed)

    def test_arguments_never_admitted(self):
        self.assertEqual(module.main(['--live']), 2)


if __name__ == '__main__':
    unittest.main()
