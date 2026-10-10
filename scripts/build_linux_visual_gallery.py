#!/usr/bin/env python3
"""Build a local gallery from original native Linux screenshot evidence."""
import argparse
import html
import json
from pathlib import Path
import zipfile

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('directory', type=Path)
args = parser.parse_args()
root = args.directory.resolve()
records = json.loads((root / 'manifest.json').read_text())
cards = []
for row in records:
    name = html.escape(row['name'])
    details = html.escape(row['feature'])
    route = html.escape(row.get('route', ''))
    image = ''
    if row.get('file'):
        filename = row['file']
        if Path(filename).name != filename or not (root / filename).is_file():
            raise ValueError('Screenshot must exist inside the gallery directory')
        url = html.escape(filename, quote=True)
        image = f'<a href="{url}"><img loading="lazy" src="{url}" alt="{name}"></a>'
    cards.append(f'<article><h2>{name}</h2><p>{route} · {details}</p>{image}<small>{html.escape(row["status"])}</small></article>')
count = sum(row['status'] == 'captured' for row in records)
page = '''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Hermes Wing · Linux visual review</title>
<style>body{font:16px system-ui;margin:0;background:#10151c;color:#e8eef6}header{padding:28px;position:sticky;top:0;background:#10151cf5;z-index:1;border-bottom:1px solid #354052}h1{margin:0 0 12px;font-size:25px}p{line-height:1.5;color:#b6c5d7}input{width:min(90%,600px);padding:12px;border:1px solid #65788e;border-radius:6px;background:#202b38;color:white}main{display:grid;grid-template-columns:repeat(auto-fit,minmax(min(100%,540px),1fr));gap:24px;padding:24px}article{background:#202b38;border-radius:8px;padding:16px}h2{font-size:18px;margin:0}img{width:100%;height:auto;border:1px solid #506176}small{display:block;margin-top:10px;color:#c3d1e1}article[hidden]{display:none}a{color:#96d6ff}</style>
<header><h1>Hermes Wing — native Linux visual review</h1><p>COUNT original captures · real Hermes Agent + Wing Link · isolated synthetic chat · Linux/Xvfb.<br>Capability-gated screens are evidence of current limitations. Audio, physical display, and unavailable administration are not qualified.</p><label>Filter screens <input type="search" placeholder="Try dark, profile, chat, settings…" oninput="document.querySelectorAll('article').forEach(x=>x.hidden=!x.textContent.toLowerCase().includes(this.value.toLowerCase()))"></label><p>Click an image for its original resolution. <a href="manifest.json">Coverage manifest</a></p></header><main>CARDS</main></html>'''.replace('COUNT', str(count)).replace('CARDS', '\n'.join(cards))
(root / 'index.html').write_text(page)
with zipfile.ZipFile(root / 'linux-ui-review.zip', 'w', zipfile.ZIP_DEFLATED) as archive:
    for filename in ['index.html', 'manifest.json'] + [row['file'] for row in records if row.get('file')]:
        archive.write(root / filename, filename)
print(f'Gallery and ZIP created: {count} captures, {len(records)} recorded states')
