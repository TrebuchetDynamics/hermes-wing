import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('task_report', ROOT / 'scripts/report_task_status.py')
report = importlib.util.module_from_spec(spec)
spec.loader.exec_module(report)


class TaskStatusReportTest(unittest.TestCase):
    def test_done_waiver_does_not_become_runtime_acceptance_or_an_open_task(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            items = root / 'tasks/items'
            items.mkdir(parents=True)
            records = {
                'closed': 'id="CLOSED"\nstatus="done"\nclosure_reason="Owner waived live checks; no live evidence"',
                'open': 'id="OPEN"\nstatus="open"\ndepends_on=["BLOCKED"]',
                'complete': 'id="COMPLETE"\nstatus="done"',
            }
            for name, fields in records.items():
                (items / f'{name}.md').write_text(f'+++\n{fields}\n+++\nHistorical status = "open"', encoding='utf-8')
            before = {p.name: p.read_bytes() for p in items.iterdir()}
            result = report.summarize(root)
            self.assertEqual(result['statuses'], {'done': 2, 'open': 1})
            self.assertEqual(result['waived_items'], ['CLOSED'])
            self.assertEqual(result['qualification_pending_items'], ['CLOSED'])
            self.assertEqual(result['dispositions']['waived'], 1)
            self.assertEqual(result['dispositions']['unverified_closure'], 1)
            self.assertEqual(result['dispositions']['recorded_verification'], 0)
            self.assertEqual(result['open_items'], [{'id': 'OPEN', 'status': 'open', 'depends_on': ['BLOCKED']}])
            self.assertEqual(before, {p.name: p.read_bytes() for p in items.iterdir()})

    def write_task(self, root, task_id, **fields):
        items = root / 'tasks/items'
        items.mkdir(parents=True, exist_ok=True)
        values = {'id': task_id, 'status': 'done', **fields}
        header = '\n'.join(f'{key} = {json.dumps(value)}' for key, value in values.items())
        (items / f'{task_id}.md').write_text(f'+++\n{header}\n+++\n', encoding='utf-8')

    def test_dispositions_partition_records_without_counting_closure_as_delivery(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            reasons = {
                'WAIVED': '2026-10-22 owner decision: waived this auto-generated live follow-up.',
                'DEFERRED': '2026-10-22 owner decision: defer this device/live qualification and close the queue row.',
                'AGGREGATE': '2026-10-22 owner decision: retire the aggregated live-qualification queue row.',
                'RETIRED': '2026-10-22 engineering/owner review: this proof targets the retired Wing Link service.',
                'SUPERSEDED': 'Superseded by an Autowork fix.',
                'DELIVERED': 'Delivered in abc1234 with a separate recorded receipt.',
            }
            for task_id, reason in reasons.items():
                self.write_task(root, task_id, closure='manual', closure_reason=reason,
                                closure_evidence='Reference only; no verified pass receipt')
            self.write_task(root, 'HISTORICAL')
            self.write_task(root, 'OPEN', status='open')
            result = report.summarize(root)
            self.assertEqual(result['dispositions'], {
                'open': 1, 'waived': 1, 'deferred': 1, 'retired_qualification': 1,
                'retired': 1, 'superseded': 1, 'recorded_verification': 0,
                'reported_delivery': 1, 'unverified_closure': 1,
            })
            self.assertEqual(sum(result['dispositions'].values()), result['total'])
            self.assertEqual(result['qualification_pending_items'], ['AGGREGATE', 'DEFERRED', 'WAIVED'])
            delivered = next(item for item in result['items'] if item['id'] == 'DELIVERED')
            self.assertEqual(delivered['closure_reason'], reasons['DELIVERED'])

    def test_verification_requires_readable_matching_pass_receipt(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.write_task(root, 'VERIFIED', closure='coordinator_verified',
                            closure_evidence='tasks/evidence/VERIFIED.toml')
            receipt = root / 'tasks/evidence/VERIFIED.toml'
            receipt.parent.mkdir(parents=True)
            for content in (None, 'invalid = [', 'task="OTHER"\nresult="pass"\nreview="passed"',
                            'task="VERIFIED"\nresult="fail"\nreview="passed"',
                            'task="VERIFIED"\nresult="pass"\nreview="pending"'):
                with self.subTest(content=content):
                    if content is not None:
                        receipt.write_text(content, encoding='utf-8')
                    result = report.summarize(root)
                    self.assertEqual(result['dispositions']['recorded_verification'], 0)
                    self.assertEqual(result['dispositions']['unverified_closure'], 1)
            receipt.write_text('task="VERIFIED"\nresult="pass"\nreview="passed"', encoding='utf-8')
            self.assertEqual(report.summarize(root)['dispositions']['recorded_verification'], 1)
            # A waiver still leaves qualification outstanding even with a pass receipt.
            self.write_task(root, 'VERIFIED', closure='coordinator_verified',
                            closure_reason='Owner waived remaining live checks.',
                            closure_evidence='tasks/evidence/VERIFIED.toml')
            self.assertEqual(report.summarize(root)['dispositions']['waived'], 1)

    def test_superseded_and_reopened_records_do_not_inherit_old_closure(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.write_task(root, 'OLD', status='superseded')
            self.write_task(root, 'REOPENED', status='open',
                            closure_reason='Owner waived live checks.')
            result = report.summarize(root)
            self.assertEqual(result['dispositions']['superseded'], 1)
            self.assertEqual(result['waived_items'], [])
            self.assertEqual([item['id'] for item in result['open_items']], ['REOPENED'])

    def test_unknown_reason_and_missing_manual_reference_are_not_delivery(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for task_id, reason in {'UNKNOWN': 'No checks were waived.',
                                    'MISSING': 'Delivered in abc1234.'}.items():
                self.write_task(root, task_id, closure='manual', closure_reason=reason)
            result = report.summarize(root)
            self.assertEqual(result['dispositions']['unverified_closure'], 2)
            self.assertEqual(result['waived_items'], [])
            self.assertEqual(result['dispositions']['reported_delivery'], 0)

    def test_cli_text_and_json_expose_qualification_instead_of_done_total(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.write_task(root, 'WAIVED', closure_reason='Owner waived live checks.')
            command = [sys.executable, str(ROOT / 'scripts/report_task_status.py'), '--root', str(root)]
            output = subprocess.run(command, text=True, capture_output=True, check=True).stdout
            self.assertIn('Closed by waiver; qualification outstanding: 1', output)
            self.assertIn('Completion/parity percentage: not established', output)
            self.assertNotIn('done: 1', output)
            data = json.loads(subprocess.run(command + ['--json'], text=True,
                                             capture_output=True, check=True).stdout)
            self.assertEqual(data['qualification_pending_items'], ['WAIVED'])
            self.assertEqual(data['items'][0]['disposition'], 'waived')
            self.assertEqual(data['statuses'], {'done': 1})

    def test_duplicate_task_ids_cannot_inflate_inventory(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.write_task(root, 'ONE')
            item = root / 'tasks/items/ONE.md'
            (item.parent / 'duplicate.md').write_bytes(item.read_bytes())
            with self.assertRaisesRegex(ValueError, 'Duplicate task ID'):
                report.summarize(root)

    def test_empty_store_cannot_look_complete(self):
        with tempfile.TemporaryDirectory() as directory:
            with self.assertRaisesRegex(ValueError, 'No task records'):
                report.summarize(Path(directory))

    def test_malformed_frontmatter_is_not_silently_skipped(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            items = root / 'tasks/items'
            items.mkdir(parents=True)
            (items / 'bad.md').write_text('status="done"', encoding='utf-8')
            with self.assertRaisesRegex(ValueError, 'Invalid task frontmatter'):
                report.summarize(root)


if __name__ == '__main__':
    unittest.main()
