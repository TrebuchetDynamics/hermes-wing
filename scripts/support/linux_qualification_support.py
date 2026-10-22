"""Shared inputs for credential-free, current-source Linux developer fixtures."""
import contextlib
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import stat
import subprocess
import sys
import tempfile
import time
from urllib.parse import unquote, urlsplit

ROOTS = ('lib', 'test', 'integration_test', 'assets', 'linux', 'macos', 'windows', 'web',
         '.github/workflows', 'scripts', 'playwright/support', 'playwright/tests', 'playwright/scripts')
FILES = ('pubspec.yaml', 'pubspec.lock', 'analysis_options.yaml', 'l10n.yaml', 'package.json',
         'package-lock.json', 'serve_web.mjs', 'playwright.config.mjs', 'docs/product/routes.md',
         'docs/product/hermes-desktop-feature-matrix.json')
EXCLUDED = {'.git', '.dart_tool', 'build', 'ephemeral', 'node_modules', '__pycache__',
            '.env', '.ssh', '.hermes', '.task-evidence'}
MODULES = ('gtk+-3.0', 'gstreamer-1.0', 'gstreamer-app-1.0', 'gstreamer-audio-1.0', 'libsecret-1')
METADATA = ('.dart_tool/package_config.json', '.dart_tool/package_graph.json', '.flutter-plugins-dependencies')


def digest(path):
    with open(path, 'rb') as stream:
        if not stat.S_ISREG(os.fstat(stream.fileno()).st_mode):
            raise ValueError('Regular input required')
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def identity(value):
    return hashlib.sha256(json.dumps(value, sort_keys=True, separators=(',', ':')).encode()).hexdigest()


def read_json(path, limit=2_000_000):
    path = Path(path)
    if path.is_symlink() or not path.is_file() or path.stat().st_size > limit:
        raise ValueError('Missing, linked or oversized JSON input: ' + path.name)
    return json.loads(path.read_text())


def plain_path(path):
    path = Path(os.path.abspath(path))
    if any(p.is_symlink() for p in (path, *path.parents)):
        raise ValueError('Linked input/output path rejected')
    return path


def reject_live(environ):
    if any(value and re.search(r'(^|_)(LIVE|PRODUCTION)(_|$)', name) for name, value in environ.items()):
        raise ValueError('Inherited live opt-in rejected')


def tree(root, *, links=False):
    result = {}
    def visit(path):
        if path.name in EXCLUDED or path.name.startswith('.env.'):
            return
        if path.is_symlink():
            if (not links or os.path.isabs(os.readlink(path)) or not path.exists() or
                    not path.resolve().is_relative_to(root)):
                raise ValueError('Escaping, absolute or unapproved input link')
            result[str(path.relative_to(root))] = 'link:' + os.readlink(path)
        elif path.is_dir():
            for child in sorted(path.iterdir()):
                visit(child)
        elif path.is_file():
            result[str(path.relative_to(root))] = digest(path)
        else:
            raise ValueError('Special input rejected')
    for child in sorted(root.iterdir()):
        visit(child)
    return result


def source_inputs(source):
    result = {}
    for name in (*ROOTS, *FILES):
        path = source / name
        if path.is_symlink():
            raise ValueError('Linked source root rejected')
        if path.is_dir():
            result.update({name + '/' + key: value for key, value in tree(path).items()})
        elif path.is_file():
            result[name] = digest(path)
    if not result or 'pubspec.lock' not in result:
        raise ValueError('Incomplete Wing source')
    return result


def snapshot(source, app, inputs):
    app.mkdir()
    for name, checksum in inputs.items():
        original = plain_path(source / name)
        if digest(original) != checksum:
            raise ValueError('Source changed before capture')
        target = app / name
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(original, target)
        if digest(target) != checksum:
            raise ValueError('Source changed during capture')
    if source_inputs(app) != inputs:
        raise ValueError('Incomplete current-source snapshot')


def dependency_prefix(environ):
    value = environ.get('WING_LINUX_DEPENDENCY_PREFIX')
    if not value:
        raise ValueError('Explicit WING_LINUX_DEPENDENCY_PREFIX usr directory required')
    prefix = plain_path(value)
    if prefix in (Path('/'), Path('/usr'), Path('/usr/local')) or not prefix.is_dir():
        raise ValueError('Disposable dependency prefix required')
    for path in (prefix, *prefix.rglob('*')):
        info = path.lstat()
        if info.st_uid != os.getuid() or (not path.is_symlink() and info.st_mode & 0o022):
            raise ValueError('Dependency prefix must be owned and not publicly writable')
    tree(prefix, links=True)
    for name in MODULES[1:]:
        pc = prefix / 'lib/x86_64-linux-gnu/pkgconfig' / (name + '.pc')
        if pc.is_symlink() or not pc.is_file() or 'prefix=' + str(prefix) not in pc.read_text().splitlines():
            raise ValueError('Missing/stale pkg-config metadata: ' + name)
    for name in ('libsecret-1.so', 'libgstreamer-1.0.so', 'libgstapp-1.0.so', 'libgstaudio-1.0.so'):
        elf(prefix / 'lib/x86_64-linux-gnu' / name)
    for name in ('libsecret-1/libsecret/secret.h', 'gstreamer-1.0/gst/gst.h'):
        if not (prefix / 'include' / name).is_file():
            raise ValueError('Missing dependency header: ' + name)
    return prefix


def elf(path):
    with path.open('rb') as stream:
        header = stream.read(20)
    if header[:6] != b'\x7fELF\x02\x01' or header[18:20] != b'\x3e\x00':
        raise ValueError('Linux x86_64 ELF dependency required')


def stage_dependencies(prefix, destination):
    expected = tree(prefix, links=True)
    shutil.copytree(prefix, destination, symlinks=True)
    if tree(destination, links=True) != expected:
        raise ValueError('Dependency changed during capture')
    for pc in destination.rglob('*.pc'):
        if not pc.is_symlink():
            pc.write_text(pc.read_text().replace(str(prefix), str(destination)))
    return destination


def isolated_environment(root, *, prefix=None, sdk=None, node=None):
    bins = ([str(sdk / 'bin')] if sdk else []) + ([str(Path(node).parent)] if node else [])
    env = dict(PATH=':'.join([*bins, '/usr/bin', '/bin']), LANG='C.UTF-8', LC_ALL='C.UTF-8')
    for name in ('home', 'config', 'data', 'cache', 'runtime'):
        (root / name).mkdir(mode=0o700, exist_ok=True)
    env.update(HOME=str(root / 'home'), XDG_CONFIG_HOME=str(root / 'config'),
               XDG_DATA_HOME=str(root / 'data'), XDG_CACHE_HOME=str(root / 'cache'),
               XDG_RUNTIME_DIR=str(root / 'runtime'), TMPDIR=str(root / 'cache'),
               PUB_CACHE=str(root / 'cache/pub'), WING_LINUX_TEST_ROOT=str(root),
               GDK_BACKEND='x11', LIBGL_ALWAYS_SOFTWARE='1', CMAKE_BUILD_PARALLEL_LEVEL='2',
               FLUTTER_SUPPRESS_ANALYTICS='true', DART_SUPPRESS_ANALYTICS='true', CI='true')
    if prefix:
        lib = prefix / 'lib/x86_64-linux-gnu'
        env.update(PKG_CONFIG_PATH=str(lib / 'pkgconfig'), CMAKE_PREFIX_PATH=str(prefix),
                   LIBRARY_PATH=str(lib), LD_LIBRARY_PATH=str(lib), CPATH=str(prefix / 'include'))
    return env


def package_inputs(source, sdk, pub_cache=None):
    missing = [name for name in METADATA if not (source / name).is_file()]
    if missing:
        raise ValueError('Missing checkout metadata: ' + ', '.join(missing))
    config = read_json(source / METADATA[0])
    graph = read_json(source / METADATA[1])
    if type(config.get('configVersion')) is not int or config['configVersion'] != 2 or not config.get('packages'):
        raise ValueError('Invalid package configuration')
    roots = {}
    for row in config['packages']:
        name = row['name']
        uri = urlsplit(row['rootUri'])
        if (not re.fullmatch('[a-zA-Z0-9_]+', name) or name in roots or
                uri.scheme not in ('', 'file') or uri.netloc or uri.query or uri.fragment):
            raise ValueError('Invalid/duplicate/nonlocal package identity')
        raw = Path(unquote(uri.path))
        path = (raw if raw.is_absolute() else source / '.dart_tool' / raw).resolve()
        if path != source and not path.is_relative_to(sdk) and (pub_cache is None or not path.is_relative_to(pub_cache)):
            raise ValueError('Package root outside explicit SDK/PUB_CACHE')
        if not path.is_dir() or (path != source and path.is_relative_to(source)):
            raise ValueError('Stale/unattributed package root')
        library = urlsplit(row.get('packageUri', 'lib/'))
        raw_library = Path(unquote(library.path))
        effective = (path / raw_library).resolve()
        # Stock native-only plugins receive lib/ from Pub despite having no Dart
        # library. This exception does not admit arbitrary missing import paths.
        manifest = path / 'pubspec.yaml'
        text = manifest.read_text() if manifest.is_file() and not manifest.is_symlink() else ''
        native_only = (raw_library == Path('lib') and effective == path / 'lib' and
                       not effective.exists() and not (path / 'lib').is_symlink() and
                       re.search(r'^  plugin:\s*$', text, re.MULTILINE) and
                       re.search(r'^        pluginClass:\s*\w+\s*$', text, re.MULTILINE) and
                       'dartPluginClass:' not in text and
                       any((path / platform).is_dir() for platform in ('android', 'ios', 'linux', 'macos', 'windows', 'darwin')))
        if (library.scheme or library.netloc or library.query or library.fragment or raw_library.is_absolute() or
                not effective.is_relative_to(path) or (not effective.is_dir() and not native_only)):
            raise ValueError('Invalid or escaping package import URI')
        roots[name] = path
    versions = {row['name']: row['version'] for row in graph['packages']}
    if len(versions) != len(graph['packages']) or set(versions) != set(roots):
        raise ValueError('Package graph/config disagree')
    locked, current = {}, None
    for line in (source / 'pubspec.lock').read_text().splitlines():
        package = re.fullmatch(r'  ([a-zA-Z0-9_]+):', line)
        version = re.fullmatch(r'    version: [\"\']?([^\"\']+)[\"\']?', line)
        if package: current = package[1]
        elif version and current: locked[current] = version[1]
    if (set(locked) != {n for n, p in roots.items() if p != source} or
            set(graph['roots']) != {n for n, p in roots.items() if p == source}):
        raise ValueError('Package lock/graph roots disagree')
    section = None
    for line in (source / 'pubspec.yaml').read_text().splitlines():
        if line and not line[0].isspace(): section = line.split(':', 1)[0]
        match = re.fullmatch(r'  ([a-zA-Z0-9_]+):\s*(.*?)\s*', line)
        if section in ('dependencies', 'dev_dependencies', 'dependency_overrides') and match:
            name, constraint = match[1], match[2].strip('\"\'')
            if name not in roots: raise ValueError('Missing direct dependency: ' + name)
            if constraint:
                wanted = re.fullmatch(r'(\^?)(\d+)\.(\d+)\.(\d+)', constraint)
                actual = re.fullmatch(r'(\d+)\.(\d+)\.(\d+)(?:\+.*)?', locked.get(name, ''))
                if not wanted or not actual: raise ValueError('Unsupported/stale direct dependency constraint')
                lower = tuple(map(int, wanted.groups()[1:]))
                number = tuple(map(int, actual.groups()))
                index = next((i for i, value in enumerate(lower) if value), 2)
                upper = (*lower[:index], lower[index] + 1, *([0] * (2 - index)))
                if not (lower <= number < upper if wanted[1] else lower == number):
                    raise ValueError('Lock violates current pubspec: ' + name)
    inputs = {}
    for name, root in roots.items():
        manifest = root / 'pubspec.yaml'
        if manifest.is_symlink() or not manifest.is_file(): raise ValueError('Package pubspec required')
        text = manifest.read_text()
        version = re.search(r'^version:\s*[\"\']?([^\s\"\']+)', text, re.MULTILINE)
        bundled = ((name != 'sky_engine' and root == sdk / 'packages' / name) or
                   (name == 'sky_engine' and root == sdk / 'bin/cache/pkg/sky_engine'))
        value = version[1] if version else '0.0.0' if bundled else None
        if (not re.search(r'^name:\s*' + re.escape(name) + r'\s*$', text, re.MULTILINE) or
                value != versions[name] or (root != source and value != locked[name])):
            raise ValueError('Stale package name/version/root')
        if root != source: inputs[name] = tree(root, links=True)
    plugins = read_json(source / METADATA[2])
    for rows in plugins['plugins'].values():
        for row in rows:
            if Path(row['path']).resolve() not in roots.values(): raise ValueError('Unattributed plugin path')
    inputs['metadata'] = {name: digest(source / name) for name in (*METADATA, 'pubspec.lock')}
    return config, roots, inputs


def sdk_inputs(sdk):
    plain_path(sdk)
    for directory, folders, files in os.walk(sdk, followlinks=False):
        folders[:] = [n for n in folders if n not in EXCLUDED]
        for name in (*folders, *files):
            path = Path(directory) / name
            if path.is_symlink() and (os.path.isabs(os.readlink(path)) or not path.exists() or
                                      not path.resolve().is_relative_to(sdk)):
                raise ValueError('SDK link aliases shared or missing state')
    files = ('bin/flutter', 'bin/internal/shared.sh', 'bin/cache/flutter_tools.snapshot',
             'bin/cache/dart-sdk/bin/dart', 'bin/cache/engine.stamp', 'bin/cache/flutter.version.json',
             'bin/cache/artifacts/engine/linux-x64/libflutter_linux_gtk.so',
             'bin/cache/artifacts/engine/linux-x64/icudtl.dat')
    result = {}
    for name in files:
        path = plain_path(sdk / name)
        if not path.is_file(): raise ValueError('Missing SDK input: ' + name)
        result[name] = digest(path)
    for name in ('bin/internal', 'packages/flutter_tools/lib',
                 'bin/cache/artifacts/engine/linux-x64/flutter_linux'):
        if (sdk / name).is_dir(): result[name] = tree(sdk / name, links=True)
    return result


def prepare(source, app, sdk, copied_sdk, env, pub_cache=None):
    original_sdk = sdk_inputs(sdk)
    config, roots, _ = package_inputs(source, sdk, pub_cache)
    version = read_json(sdk / 'bin/cache/flutter.version.json')
    if (version.get('frameworkVersion'), version.get('dartSdkVersion')) != ('3.44.2', '3.12.2'):
        raise ValueError('Flutter 3.44.2 / bundled Dart 3.12.2 required')
    # Never let Flutter acquire locks or refresh caches in the shared SDK.
    subprocess.run(['/bin/cp', '-a', '--reflink=auto', str(sdk), str(copied_sdk)],
                   env=env, check=True, timeout=180, stdout=subprocess.DEVNULL)
    if sdk_inputs(copied_sdk) != original_sdk:
        raise ValueError('SDK changed during copy')
    relocated = {}
    for row in config['packages']:
        original = roots[row['name']]
        if original == source: target = app
        elif original.is_relative_to(sdk): target = copied_sdk / original.relative_to(sdk)
        else:
            target = app.parent / 'packages' / row['name']
            shutil.copytree(original, target, symlinks=True,
                            ignore=lambda directory, names: [n for n in names if n in EXCLUDED or n.startswith('.env.')])
        relocated[original] = target
        row['rootUri'] = target.as_uri()
    (app / '.dart_tool').mkdir()
    (app / METADATA[0]).write_text(json.dumps(config))
    shutil.copy2(source / METADATA[1], app / METADATA[1])
    plugins = read_json(source / METADATA[2])
    for rows in plugins['plugins'].values():
        for row in rows: row['path'] = str(relocated[Path(row['path']).resolve()]) + '/'
    (app / METADATA[2]).write_text(json.dumps(plugins))


def inspect(source, environ, root):
    errors, tools = [], {'python': {'path': sys.executable, 'sha256': digest(sys.executable)}}
    env = isolated_environment(root)
    prefix = sdk = node = None
    if sys.version_info < (3, 11): errors.append('Python 3.11+ required')
    try:
        reject_live(environ)
    except ValueError as error: errors.append(str(error))
    try:
        prefix = dependency_prefix(environ)
        tools['dependencies_sha256'] = identity(tree(prefix, links=True))
        env = isolated_environment(root, prefix=prefix)
    except (OSError, ValueError) as error: errors.append(str(error))
    for name in ('flutter', 'node', 'pkg-config', 'xvfb-run', 'Xvfb', 'xauth', 'dbus-run-session', 'clang', 'cmake', 'ninja', 'git', 'bash'):
        runtime_path = ':'.join([*([str(sdk / 'bin')] if sdk else []),
                                 *([str(Path(node).parent)] if node else []), '/usr/bin', '/bin'])
        search = environ.get('PATH', '/usr/bin:/bin') if name in ('flutter', 'node') else runtime_path
        path = shutil.which(name, path=search)
        if path is None:
            errors.append('Missing tool: ' + name)
            continue
        path = Path(path).resolve()
        tools[name] = {'path': str(path), 'sha256': digest(path)}
        if name == 'flutter': sdk = path.parents[1]
        if name == 'node': node = str(path)
    try:
        if sdk:
            tools['sdk_sha256'] = identity(sdk_inputs(sdk))
            version = read_json(sdk / 'bin/cache/flutter.version.json')
            tools['flutter']['version'] = {name: version[name] for name in
                ('frameworkVersion', 'dartSdkVersion', 'frameworkRevision', 'engineRevision') if name in version}
            dart_version = subprocess.run([str(sdk / 'bin/cache/dart-sdk/bin/dart'), '--version'], env=env,
                                          capture_output=True, text=True, timeout=30, check=True)
            if not re.search(r'Dart SDK version: 3\.12\.2(?:\s|$)', dart_version.stdout + dart_version.stderr):
                raise ValueError('Bundled Dart 3.12.2 required')
            tools['engine_sha256'] = digest(sdk / 'bin/cache/engine.stamp')
            tools['dart_sha256'] = digest(sdk / 'bin/cache/dart-sdk/bin/dart')
            if (version['frameworkVersion'], version['dartSdkVersion']) != ('3.44.2', '3.12.2'):
                errors.append('Flutter 3.44.2 / bundled Dart 3.12.2 required')
            cache = Path(environ['PUB_CACHE']).resolve() if environ.get('PUB_CACHE') else None
            tools['packages_sha256'] = identity(package_inputs(source, sdk, cache)[2])
    except (OSError, ValueError, KeyError, TypeError, AttributeError, subprocess.SubprocessError) as error:
        errors.append(str(error) if isinstance(error, ValueError) else 'Missing/stale SDK/package metadata')
    if node:
        try:
            version = subprocess.run([node, '--version'], env=env, capture_output=True, text=True, timeout=30, check=True).stdout.strip()
            tools['node']['version'] = version
            if not re.fullmatch(r'v22\.\d+\.\d+', version): errors.append('Node 22 required')
        except (OSError, subprocess.SubprocessError): errors.append('Node version inspection failed')
    if prefix and 'pkg-config' in tools:
        try:
            command = tools['pkg-config']['path']
            versions = subprocess.run([command, '--modversion', *MODULES], env=env, capture_output=True, text=True, timeout=30, check=True).stdout.split()
            actual = [tuple(map(int, v.split('.'))) for v in versions]
            if len(actual) != 5 or any(v < m for v, m in zip(actual, ((3, 24), (1, 18), (1, 18), (1, 18), (0, 20)))):
                raise ValueError('Incompatible native module versions')
            tools['pkg_config_versions'] = dict(zip(MODULES, versions))
            tools['gtk_inputs'] = {}
            for variable, suffix in (('libdir', 'libgtk-3.so'), ('includedir', 'gtk-3.0/gtk/gtk.h')):
                directory = subprocess.run([command, '--variable=' + variable, 'gtk+-3.0'], env=env, capture_output=True, text=True, timeout=30, check=True).stdout.strip()
                path = (Path(directory) / suffix).resolve()
                if not any(path.is_relative_to(p) for p in (prefix, Path('/usr/lib'), Path('/lib'), Path('/usr/include'))):
                    raise ValueError('Unattributed GTK input')
                tools['gtk_inputs'][variable] = {'path': str(path), 'sha256': digest(path)}
                if variable == 'libdir': elf(path)
        except (OSError, ValueError, subprocess.SubprocessError): errors.append('Compatible GTK/GStreamer/libsecret inputs required')
    return dict(ready=not errors, errors=errors, toolchain=tools), prefix, sdk, node


@contextlib.contextmanager
def record_attempt(output, result):
    """Publish terminal nested cleanup even when native execution raises."""
    started = time.monotonic()
    result.setdefault('status', 'FAIL')
    try:
        yield
    except BaseException as error:
        result['status'] = 'FAIL'
        if str(error) == 'OWNED_TEARDOWN_INCOMPLETE':
            result['cleanup_error'] = 'OWNED_TEARDOWN_INCOMPLETE'
        raise
    finally:
        preserved = [p.name for p in output.iterdir() if p.is_dir()]
        clean = not preserved and result.get('cleanup_error') != 'OWNED_TEARDOWN_INCOMPLETE'
        if not clean: result['status'] = 'FAIL'
        result['cleanup'] = dict(groups_gone=clean, state_removed=clean, preserved=preserved,
                                 groups=[result['driver_pid']] if type(result.get('driver_pid')) is int else [])
        result['isolated_state_removed'] = clean
        result['duration_seconds'] = round(time.monotonic() - started, 3)
        fd, name = tempfile.mkstemp(prefix='verification-', suffix='.pending', dir=output)
        with os.fdopen(fd, 'w') as stream:
            json.dump(result, stream, indent=2)
        Path(name).replace(output / 'verification.json')


def runner_output(environ, prefix):
    reject_live(environ)
    scratch = plain_path(environ['TMPDIR'])
    if environ.get('WING_LINUX_RUNNER_OUTPUT'):
        path = plain_path(environ['WING_LINUX_RUNNER_OUTPUT'])
        if path == scratch or not path.is_relative_to(scratch): raise ValueError('Runner output outside TMPDIR')
        path.mkdir(mode=0o700)
        return path
    return Path(tempfile.mkdtemp(prefix=prefix, dir=scratch))
