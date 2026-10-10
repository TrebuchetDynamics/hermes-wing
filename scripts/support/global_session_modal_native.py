"""Isolated deterministic native shell qualification; no installs or live Agent."""
import hashlib
import json
import os
import pathlib
import queue
import shutil
import signal
import socket
import subprocess
import tempfile
import threading
import time

from desktop_daily_workspace import prepare


def live_groups(groups):
    live = set()
    for process in pathlib.Path('/proc').iterdir():
        try:
            fields = (process / 'stat').read_text().rsplit(')', 1)[1].split()
            if int(fields[2]) in groups and fields[0] != 'Z':
                live.add(int(fields[2]))
        except (OSError, ValueError, IndexError):
            continue  # Processes may exit while /proc is enumerated.
    return sorted(live)


def main():
    repo = pathlib.Path(__file__).resolve().parents[2]
    logs = repo / 'build/t_5ca5f71b/evidence'
    logs.mkdir(parents=True, exist_ok=True)
    # Independent receipt ownership, acquired before truncation or preparation.
    import fcntl
    with (logs / 'owner.lock').open('w') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        run(repo, logs)


def run(repo, logs):
    for name in ['native-receipt.json', 'build-fingerprint.json']:
        (logs / name).unlink(missing_ok=True)
    for tool in ['flutter', 'node', 'go', 'xvfb-run', 'Xvfb', 'pkg-config', 'cmake', 'ninja', 'clang++']:
        if not shutil.which(tool):
            raise RuntimeError(f'Missing prerequisite: {tool}')
    subprocess.run(['pkg-config', '--exists', 'gtk+-3.0', 'libsecret-1',
                    'gstreamer-1.0', 'gstreamer-app-1.0', 'gstreamer-audio-1.0'], check=True)
    root = pathlib.Path(tempfile.mkdtemp(prefix='wing-linux-panel.', dir=os.environ['TMPDIR']))
    marker = root / '.wing-linux-test-owner'
    marker.touch()
    children = []
    commands = []
    def interrupted(signum, frame):
        raise SystemExit(128 + signum)
    signal.signal(signal.SIGTERM, interrupted)
    signal.signal(signal.SIGINT, interrupted)
    try:
        for name in ['home', 'config', 'data', 'cache', 'runtime']:
            (root / name).mkdir(mode=0o700)
        flutter_path = shutil.which('flutter')
        assert flutter_path is not None
        sdk = pathlib.Path(flutter_path).resolve().parents[1]
        app, isolated_sdk = prepare(repo, root / 'workspace', sdk)
        shutil.copy2(root / 'workspace/source-manifest.json', logs / 'source-manifest.json')
        env = dict(os.environ)
        env.update(HOME=str(root / 'home'), XDG_CONFIG_HOME=str(root / 'config'),
                   XDG_DATA_HOME=str(root / 'data'), XDG_CACHE_HOME=str(root / 'cache'),
                   XDG_RUNTIME_DIR=str(root / 'runtime'), WING_LINUX_TEST_ROOT=str(root),
                   WING_ISOLATED_PREFERENCES='1', GDK_BACKEND='x11', LIBGL_ALWAYS_SOFTWARE='1',
                   PUB_CACHE=os.environ.get('PUB_CACHE', str(pathlib.Path.home() / '.pub-cache')),
                   GOMODCACHE=subprocess.check_output(['go', 'env', 'GOMODCACHE'], text=True).strip(),
                   GOCACHE=str(root / 'cache/go-build'), GOMAXPROCS='2', GOFLAGS='-p=2',
                   CMAKE_BUILD_PARALLEL_LEVEL='2', WING_PANEL_LOGS=str(logs))
        for name in ['DISPLAY', 'WAYLAND_DISPLAY', 'DBUS_SESSION_BUS_ADDRESS', 'SESSION_MANAGER']:
            env.pop(name, None)
        reservations = [socket.socket(), socket.socket()]
        for sock in reservations:
            sock.bind(('127.0.0.1', 0))
        ports = [sock.getsockname()[1] for sock in reservations]
        for sock in reservations:
            sock.close()
        origin = f'http://127.0.0.1:{ports[1]}'
        with (logs / 'fixture.log').open('w') as output:
            node_path = shutil.which('node')
            assert node_path is not None
            fixture = subprocess.Popen([node_path, 'serve_web.mjs'], cwd=app,
                env=dict(env, PORT=str(ports[0]), HERMES_E2E_PORT=str(ports[1])),
                stdout=subprocess.PIPE, stderr=output, text=True, start_new_session=True)
            children.append(fixture)
            lines = queue.Queue()
            def drain():
                assert fixture.stdout is not None
                for line in fixture.stdout:
                    lines.put(line)
            threading.Thread(target=drain, daemon=True).start()
            announcements = {f'Server running at http://127.0.0.1:{ports[0]}/',
                             f'Hermes API running at {origin}/'}
            deadline = time.monotonic() + 10
            while announcements:
                if fixture.poll() is not None or time.monotonic() >= deadline:
                    raise RuntimeError('Owned fixture did not announce both binds')
                try:
                    line = lines.get(timeout=0.2)
                except queue.Empty:
                    continue
                output.write(line)
                output.flush()
                announcements.discard(line.strip())
            env['WING_PANEL_ORIGIN'] = origin
            flutter = str(isolated_sdk / 'bin/flutter')
            checks = [
                ('format', [str(isolated_sdk / 'bin/dart'), 'format', '--output=none',
                    '--set-exit-if-changed', 'integration_test/linux_global_session_modal_test.dart',
                    'integration_test/support/global_session_fixture.dart']),
                ('analyze', [flutter, 'analyze', '--no-pub']),
                ('focused-tests', [flutter, 'test', '--no-pub', '--concurrency=1',
                    'test/shared/widgets/app_shell_global_session_modal_adaptive_test.dart',
                    'test/shared/widgets/app_shell_global_session_modal_test.dart',
                    'test/shared/widgets/app_shell_global_session_access_test.dart',
                    'test/shared/widgets/app_shell_global_session_modal_actions_test.dart',
                    'test/shared/widgets/app_shell_test.dart',
                    'test/shared/widgets/app_shell_focus_traversal_test.dart', '--reporter', 'expanded']),
                ('native', ['xvfb-run', '-a', '-s', '-screen 0 1600x1200x24 -nolisten tcp',
                    flutter, 'test', '--verbose', '--no-pub', '-d', 'linux',
                    'integration_test/linux_global_session_modal_test.dart', '--reporter', 'expanded']),
            ]
            for label, command in checks:
                print('COMMAND ' + ' '.join(command), flush=True)
                with (logs / f'{label}.log').open('w') as out:
                    child = subprocess.Popen(command, cwd=app, env=env, stdout=out,
                                             stderr=subprocess.STDOUT, start_new_session=True)
                    children.append(child)
                    code = child.wait(timeout=600)
                commands.append({'label': label, 'command': command, 'exit': code})
                (logs / 'checks.json').write_text(json.dumps(commands, indent=2) + '\n')
                print(f'{label} EXIT {code}', flush=True)
                if code:
                    raise RuntimeError(f'{label} failed; inspect retained log')
            bundle = app / 'build/linux/x64/debug/bundle'
            binaries = {str(p.relative_to(bundle)): hashlib.sha256(p.read_bytes()).hexdigest()
                        for p in bundle.rglob('*') if p.is_file()}
            if 'wing' not in binaries or 'data/flutter_assets/kernel_blob.bin' not in binaries:
                raise RuntimeError('Native compiled payload not found')
            (logs / 'build-fingerprint.json').write_text(json.dumps(binaries, indent=2) + '\n')
            receipt = json.loads((logs / 'native-receipt.json').read_text())
            import platform
            (logs / 'platform.json').write_text(json.dumps({
                'platform': platform.platform(), 'input': 'Flutter tester.sendKeyEvent and enterText',
                'display': 'owned Xvfb X11, GTK, software rendering',
                'head': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=repo, text=True).strip(),
            }, indent=2) + '\n')
            manifest = json.loads((logs / 'source-manifest.json').read_text())
            drift = [name for name, digest in manifest.items()
                     if not name.startswith('.dart_tool/') and
                     (repo / name).is_file() and
                     hashlib.sha256((repo / name).read_bytes()).hexdigest() != digest]
            (logs / 'source-drift.json').write_text(json.dumps(drift) + '\n')
            if drift:
                raise RuntimeError('Copied input drifted during qualification')
            assert receipt['synthetic'] and receipt['platform'] == 'linux'
            assert receipt['unexpected_mutation_count'] == 0 and len(receipt['phases']) == 12
    finally:
        signal.signal(signal.SIGTERM, signal.SIG_IGN)
        signal.signal(signal.SIGINT, signal.SIG_IGN)
        for child in reversed(children):
            try:
                os.killpg(child.pid, signal.SIGTERM)
            except ProcessLookupError:
                continue
        for child in reversed(children):
            try:
                child.wait(timeout=8)
            except subprocess.TimeoutExpired:
                os.killpg(child.pid, signal.SIGKILL)
                child.wait(timeout=3)
            # A reaped group leader does not prove its descendants exited.
            try:
                os.killpg(child.pid, signal.SIGKILL)
            except ProcessLookupError:
                continue
        groups = {child.pid for child in children}
        deadline = time.monotonic() + 3
        while live_groups(groups) and time.monotonic() < deadline:
            time.sleep(0.05)
        survivors = live_groups(groups)
        gone = not survivors and all(c.returncode is not None for c in children)
        if gone and marker.is_file() and root.parent == pathlib.Path(os.environ['TMPDIR']).resolve():
            shutil.rmtree(root)
        (logs / 'teardown-receipt.json').write_text(json.dumps({
            'children': [{'pid': c.pid, 'exit': c.returncode} for c in children],
            'surviving_groups': survivors, 'all_reaped': gone,
            'owned_root_removed': not root.exists(),
        }, indent=2) + '\n')
        if not gone:
            raise RuntimeError('Owned teardown incomplete; root retained')


if __name__ == '__main__':
    main()
