#!/usr/bin/env python3
"""Read the repository task store without changing task state or acceptance."""

import argparse
from collections import Counter
import json
from pathlib import Path
import tomllib


def summarize(root: Path) -> dict:
    counts = Counter()
    open_items = []
    waived_items = []
    files = sorted((root / 'tasks' / 'items').glob('*.md'))
    if not files:
        raise ValueError('No task records found')
    for path in files:
        text = path.read_text(encoding='utf-8')
        parts = text.split('+++', 2)
        if len(parts) != 3 or parts[0].strip():
            raise ValueError(f'Invalid task frontmatter: {path.name}')
        item = tomllib.loads(parts[1])
        status = item['status']
        counts[status] += 1
        if status != 'done':
            open_items.append({'id': item['id'], 'status': status,
                               'depends_on': item.get('depends_on', [])})
        # This is explicit recorded disposition, never inferred test acceptance.
        if 'waiv' in item.get('closure_reason', '').lower():
            waived_items.append(item['id'])
    return {'total': len(files), 'statuses': dict(sorted(counts.items())),
            'open_items': open_items, 'waived_items': waived_items,
            'qualification': 'Task status does not establish implementation or runtime acceptance.'}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument('--json', action='store_true')
    args = parser.parse_args()
    result = summarize(args.root)
    if args.json:
        print(json.dumps(result, indent=2))
        return
    print(f"Task records: {result['total']}")
    for status, count in result['statuses'].items():
        print(f'{status}: {count}')
    print(f"Explicit waivers: {len(result['waived_items'])}")
    for item in result['open_items']:
        dependencies = ', '.join(item['depends_on']) or 'none'
        print(f"{item['id']} [{item['status']}] depends on: {dependencies}")
    print(result['qualification'])


if __name__ == '__main__':
    main()
