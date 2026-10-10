"""Receipt negatives discriminate passive inspection from domain mutation."""

import importlib.util
import json
import pathlib
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('status_native', ROOT / 'scripts/support/status_accessibility_native.py')
assert spec is not None and spec.loader is not None
native = importlib.util.module_from_spec(spec)
spec.loader.exec_module(native)


class StatusReceiptTest(unittest.TestCase):
    def receipt(self):
        return {'native_pid': 123, 'width': 390.0, 'text_scale': 2.0,
                'phases': ['connected', 'recovering', 'failed', 'replacement', 'returned'],
                'mutations': dict.fromkeys(('sends', 'creates', 'approvals', 'model_writes',
                                            'stops', 'profile_writes', 'selections'), 0),
                'keyboard_inspection': True, 'reduced_motion': True,
                'route_return': True, 'resize_return': True,
                'current_owner': 'synthetic-replacement'}

    def validate(self, value):
        with tempfile.TemporaryDirectory() as root:
            path = pathlib.Path(root) / 'receipt.json'
            path.write_text(json.dumps(value))
            return native.read_receipt(path)

    def test_all_matrix_receipts(self):
        for width in (390.0, 1280.0):
            for scale in (1.0, 2.0):
                v = self.receipt() | {'width': width, 'text_scale': scale}
                self.assertEqual(self.validate(v), v)

    def test_every_mutation_including_failed_attempt_rejected(self):
        for key in self.receipt()['mutations']:
            for value in (1, -1, False):
                with self.subTest(key=key, value=value):
                    v = self.receipt()
                    v['mutations'][key] = value
                    with self.assertRaises(ValueError):
                        self.validate(v)

    def test_incomplete_or_obsolete_result_rejected(self):
        v = self.receipt()
        cases = [v | {'phases': v['phases'][:-1]}, v | {'current_owner': 'synthetic-status'},
                 v | {'keyboard_inspection': False}, v | {'resize_return': False},
                 v | {'route_return': False}, v | {'native_pid': True}, v | {'text_scale': 3.0}]
        for bad in cases:
            with self.assertRaises(ValueError):
                self.validate(bad)

    def test_symlink_and_oversized_receipt_rejected(self):
        with tempfile.TemporaryDirectory() as root:
            path = pathlib.Path(root) / 'receipt.json'
            path.write_text(json.dumps(self.receipt()))
            link = pathlib.Path(root) / 'link'
            link.symlink_to(path)
            with self.assertRaises(ValueError):
                native.read_receipt(link)
            path.write_text(' ' * 32769)
            with self.assertRaises(ValueError):
                native.read_receipt(path)

    def test_arguments_never_admit_live_credentials(self):
        self.assertEqual(native.main(['unexpected']), 2)


if __name__ == '__main__':
    unittest.main()
