import importlib.util
from pathlib import Path
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
            self.assertEqual(result['open_items'], [{'id': 'OPEN', 'status': 'open', 'depends_on': ['BLOCKED']}])
            self.assertEqual(before, {p.name: p.read_bytes() for p in items.iterdir()})

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
