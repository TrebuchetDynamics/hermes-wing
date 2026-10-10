"""Freeze only Wing sources/dependencies for this bounded qualification."""
import hashlib
import json
from pathlib import Path
import shutil
import subprocess

root = Path(__file__).resolve().parents[2]
out = root / '.dart_tool/local-setup-recovery'
out.mkdir(parents=True, exist_ok=True)
manifest = {}
for name in ['lib', 'test', 'integration_test', 'assets', 'web', 'pubspec.yaml',
             'pubspec.lock', 'analysis_options.yaml', 'l10n.yaml',
             'package.json', 'package-lock.json']:
    source = root / name
    paths = sorted(p for p in source.rglob('*') if p.is_file()) if source.is_dir() else [source]
    for path in paths:
        rel = path.relative_to(root)
        destination = out / rel
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(path, destination)
        manifest[str(rel)] = hashlib.sha256(destination.read_bytes()).hexdigest()
record = {
    'base': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=root, text=True).strip(),
    'files': manifest,
    'source_sha256': hashlib.sha256(json.dumps(manifest, sort_keys=True).encode()).hexdigest(),
    'flutter': subprocess.check_output(['flutter', '--version'], text=True),
    'node': subprocess.check_output(['node', '--version'], text=True).strip(),
    'chromium': subprocess.check_output(['/usr/bin/chromium', '--version'], text=True).strip(),
}
(out / 'source-manifest.json').write_text(json.dumps(record, indent=2) + '\n')
print(json.dumps({k: v for k, v in record.items() if k != 'files'}, indent=2))
print(out)
