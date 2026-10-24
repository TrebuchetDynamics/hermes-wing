#!/usr/bin/env python3
"""Read the repository task store without changing task state or acceptance."""

import argparse
from collections import Counter
import json
from pathlib import Path
import re
import tomllib


DISPOSITIONS = {
    'open': 'Open queue',
    'waived': 'Closed by waiver; qualification outstanding',
    'deferred': 'Closed by deferral; qualification outstanding',
    'retired_qualification': 'Retired aggregate rows; qualification outstanding',
    'retired': 'Retired scope; not delivered',
    'superseded': 'Superseded; not counted as delivery',
    'recorded_verification': 'Closed with a matching pass receipt (task scope only)',
    'reported_delivery': 'Manually reported delivery (not revalidated)',
    'unverified_closure': 'Historical/other closures without a verified receipt',
}
PENDING_QUALIFICATION = {'waived', 'deferred', 'retired_qualification'}
QUALIFICATION = (
    'Task closures are not a completion or parity percentage. Pass receipts '
    'describe their original task scope, not current product/platform acceptance. '
    'Outstanding qualification counts records, including overlapping aggregate '
    'rows, not unique features. Product work outside this store remains in '
    'docs/plans/2026-10-21-desktop-literal-clone.md.'
)


def has_pass_receipt(root: Path, item: dict) -> bool:
    # Only the store's own receipt is read; free-form evidence can name commits,
    # URLs or external files and is not a machine-verifiable pass receipt.
    relative = Path('tasks/evidence') / f"{item['id']}.toml"
    if item.get('closure_evidence') != relative.as_posix():
        return False
    receipt = root / relative
    if not receipt.resolve().is_relative_to((root / 'tasks/evidence').resolve()):
        return False
    try:
        evidence = tomllib.loads(receipt.read_text(encoding='utf-8'))
    except (OSError, ValueError):
        return False
    return (evidence.get('task') == item['id']
            and evidence.get('result') == 'pass'
            and evidence.get('review') == 'passed')


def disposition(root: Path, item: dict) -> str:
    if item['status'] == 'superseded':
        return 'superseded'
    if item['status'] != 'done':
        return 'open'
    # These are recorded decision clauses, not keywords in titles or task bodies.
    # Unrecognised reasons stay unverified; absence of a waiver is not success.
    reason = re.sub(
        r'^\d{4}-\d{2}-\d{2} (?:owner decision|engineering/owner review):\s*',
        '', item.get('closure_reason', '').strip().lower(),
    )
    if reason.startswith(('waived ', 'owner waived ')):
        return 'waived'
    if reason.startswith('defer this device/live qualification'):
        return 'deferred'
    if reason.startswith('retire the aggregated live-qualification queue row'):
        return 'retired_qualification'
    if reason.startswith('this proof targets the retired wing link service'):
        return 'retired'
    if reason.startswith('superseded by '):
        return 'superseded'
    if item.get('closure') == 'coordinator_verified' and has_pass_receipt(root, item):
        return 'recorded_verification'
    if (item.get('closure') == 'manual' and reason.startswith('delivered in ')
            and item.get('closure_evidence', '').strip()):
        return 'reported_delivery'
    return 'unverified_closure'


def summarize(root: Path) -> dict:
    counts = Counter()
    dispositions = Counter({name: 0 for name in DISPOSITIONS})
    items = []
    open_items = []
    waived_items = []
    pending_qualification = []
    ids = set()
    files = sorted((root / 'tasks' / 'items').glob('*.md'))
    if not files:
        raise ValueError('No task records found')
    for path in files:
        text = path.read_text(encoding='utf-8')
        parts = text.split('+++', 2)
        if len(parts) != 3 or parts[0].strip():
            raise ValueError(f'Invalid task frontmatter: {path.name}')
        item = tomllib.loads(parts[1])
        for key in ('id', 'status'):
            if not isinstance(item.get(key), str) or not item[key].strip():
                raise ValueError(f'Invalid task {key}: {path.name}')
        if item['id'] in ids:
            raise ValueError(f"Duplicate task ID: {item['id']}")
        ids.add(item['id'])
        status = item['status']
        counts[status] += 1
        category = disposition(root, item)
        dispositions[category] += 1
        items.append({
            'id': item['id'], 'status': status, 'disposition': category,
            'closure_reason': item.get('closure_reason'),
            'closure_evidence': item.get('closure_evidence'),
        })
        if category == 'open':
            open_items.append({'id': item['id'], 'status': status,
                               'depends_on': item.get('depends_on', [])})
        if category == 'waived':
            waived_items.append(item['id'])
        if category in PENDING_QUALIFICATION:
            pending_qualification.append(item['id'])
    return {'total': len(files), 'dispositions': dict(dispositions),
            'qualification_pending_items': pending_qualification, 'items': items,
            # Retained for existing consumers; these are administrative states.
            'statuses': dict(sorted(counts.items())),
            'open_items': open_items, 'waived_items': waived_items,
            'qualification': QUALIFICATION}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument('--json', action='store_true')
    args = parser.parse_args()
    result = summarize(args.root)
    if args.json:
        print(json.dumps(result, indent=2))
        return
    print(f"Task records: {result['total']} (administrative inventory)")
    for category, label in DISPOSITIONS.items():
        print(f"{label}: {result['dispositions'][category]}")
    print('Closed records with qualification outstanding '
          f"(waived + deferred + retired aggregates): {len(result['qualification_pending_items'])}")
    print('Completion/parity percentage: not established')
    for item in result['open_items']:
        dependencies = ', '.join(item['depends_on']) or 'none'
        print(f"{item['id']} [{item['status']}] depends on: {dependencies}")
    print(result['qualification'])
    print('Use --json for task IDs, recorded reasons and evidence references.')


if __name__ == '__main__':
    main()
