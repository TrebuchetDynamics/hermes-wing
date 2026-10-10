"""Disposable source and SDK copies for native qualification, never shared builds."""
import json
import hashlib
import pathlib
import shutil
import subprocess
import sys


def prepare(source, destination, sdk):
    source, destination, sdk = map(lambda p: pathlib.Path(p).resolve(), (source, destination, sdk))
    if destination.exists():
        raise ValueError('Workspace must be fresh')
    destination.mkdir()
    app = destination / 'app'
    app.mkdir()
    for name in ('lib', 'test', 'integration_test', 'assets', 'linux', 'wing_link', 'scripts/support', 'playwright/support'):
        shutil.copytree(source / name, app / name, ignore=shutil.ignore_patterns('ephemeral', '__pycache__'))
    for name in ('pubspec.yaml', 'pubspec.lock', 'analysis_options.yaml', 'l10n.yaml',
                 '.flutter-plugins-dependencies', 'serve_web.mjs',
                 'scripts/run_linux_desktop_daily_workflow_e2e.sh'):
        if (source / name).is_file():
            shutil.copy2(source / name, app / name)
    # Independent inodes even on filesystems without reflinks. SDK locks, stamps,
    # and tool state must never alias another worker's SDK.
    isolated_sdk = destination / 'flutter'
    subprocess.run(['cp', '-a', '--reflink=auto', str(sdk), str(isolated_sdk)], check=True)
    config_path = source / '.dart_tool/package_config.json'
    config = json.loads(config_path.read_text())
    from urllib.parse import urlparse, unquote
    for package in config['packages']:
        uri = package['rootUri']
        parsed = urlparse(uri)
        if parsed.scheme not in ('', 'file'):
            raise ValueError('Only local package roots are supported')
        root = pathlib.Path(unquote(parsed.path))
        if not root.is_absolute():
            root = config_path.parent / root
        root = root.resolve()
        if root == source:
            root = app
        elif root.is_relative_to(sdk):
            root = isolated_sdk / root.relative_to(sdk)
        package['rootUri'] = root.as_uri()
    (app / '.dart_tool').mkdir()
    (app / '.dart_tool/package_config.json').write_text(json.dumps(config, indent=2) + '\n')
    shutil.copy2(source / '.dart_tool/package_graph.json', app / '.dart_tool/package_graph.json')
    # Bind retained evidence to the copied inputs, including uncommitted changes.
    hashes = {str(p.relative_to(app)): hashlib.sha256(p.read_bytes()).hexdigest()
              for p in sorted(app.rglob('*')) if p.is_file() and '.dart_tool' not in p.parts}
    (destination / 'source-manifest.json').write_text(json.dumps(hashes, indent=2) + '\n')
    return app, isolated_sdk


if __name__ == '__main__':
    prepare(*sys.argv[1:])
