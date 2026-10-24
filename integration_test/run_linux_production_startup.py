"""Smoke-launch normal main.dart in private GTK state; no Agent or account access."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import time

SOURCE = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(SOURCE / 'scripts/support'))
import linux_qualification_support as qa
from desktop_live_workflow import Refusal, cancellation_scope, live_group, owned_workspace, run_owned


def window_geometry(text):
    fields = dict(line.split('=', 1) for line in text.splitlines() if '=' in line)
    width, height = int(fields['WIDTH']), int(fields['HEIGHT'])
    if width < 320 or height < 200:
        raise ValueError('Startup window is empty or too small')
    return dict(width=width, height=height)


def image_geometry(text, window):
    width, height, colors = map(int, text.split())
    if (width, height) != (window['width'], window['height']) or colors < 8:
        raise ValueError('Startup image is blank or does not match the window')
    return dict(width=width, height=height, colors=colors)


def observe_window():
    qa.reject_live(os.environ)
    root = qa.plain_path(os.environ['WING_LINUX_TEST_ROOT'])
    if (SOURCE != root / 'app' or os.environ['HOME'] != str(root / 'home') or
            not (root / '.wing-startup-owner').is_file() or
            os.environ.get('WAYLAND_DISPLAY') or not os.environ.get('DISPLAY')):
        raise ValueError('Private startup display/state required')
    bundle = root / 'app/build/linux/x64/debug/bundle'
    child = subprocess.Popen([str(bundle / 'wing')], cwd=bundle)
    try:
        birth = (Path('/proc') / str(child.pid) / 'stat').read_text().rsplit(')', 1)[1].split()[19]
        window = None
        deadline = time.monotonic() + 30
        while child.poll() is None and time.monotonic() < deadline:
            query = subprocess.run(['xdotool', 'search', '--onlyvisible', '--pid', str(child.pid)],
                                   capture_output=True, text=True, timeout=3)
            if query.returncode == 0 and query.stdout.strip():
                window = query.stdout.splitlines()[0]
                break
            time.sleep(0.1)
        if window is None or not window.isdigit():
            raise ValueError('Normal GTK startup did not map an owned window')
        geometry = window_geometry(subprocess.check_output(
            ['xdotool', 'getwindowgeometry', '--shell', window], text=True, timeout=3))
        # Wait for the first rendered welcome frame rather than counting a mapped
        # GTK container or a process which merely remains alive as startup proof.
        image = root / 'startup.png'
        while child.poll() is None and time.monotonic() < deadline:
            subprocess.run(['magick', 'import', '-window', window, str(image)], check=True, timeout=5)
            try:
                pixels = image_geometry(subprocess.check_output(
                    ['magick', 'identify', '-format', '%w %h %k', str(image)], text=True, timeout=5), geometry)
                break
            except ValueError:
                time.sleep(0.1)
        else:
            raise ValueError('Normal GTK startup did not render a nonempty frame')
        title = subprocess.check_output(['xdotool', 'getwindowname', window], text=True, timeout=3).strip()
        if title != 'Hermes Wing':
            raise ValueError('Unexpected startup window')
        fields = (Path('/proc') / str(child.pid) / 'stat').read_text().rsplit(')', 1)[1].split()
        if fields[19] != birth or fields[0] == 'Z' or child.poll() is not None:
            raise ValueError('Startup process identity changed')
        (root / 'startup-window.json').write_text(json.dumps(dict(
            native_pid=child.pid, start_ticks=birth, process_group=int(fields[2]),
            window_id=window, title=title, geometry=geometry, image=pixels)))
    finally:
        if child.poll() is None:
            child.terminate()
            try:
                child.wait(timeout=5)
            except subprocess.TimeoutExpired:
                child.kill()
                child.wait(timeout=5)


@cancellation_scope()
def run():
    qa.reject_live(os.environ)
    output = qa.runner_output(os.environ, 'linux-startup-')
    result = dict(schema=1, status='FAIL', live_agent='NOT_CHECKED',
                  screenshot_review='REQUIRED', commands=[], cleanup=dict(groups_gone=True))
    try:
        with owned_workspace(output) as root:
            inspection, prefix, sdk, node = qa.inspect(SOURCE, os.environ, root)
            result.update(inspection)
            if not inspection['ready']:
                result['status'] = 'NOT_RUN'
                return 2
            for tool in ('xdotool', 'magick'):
                executable = shutil.which(tool, path=qa.isolated_environment(root, prefix=prefix)['PATH'])
                if not executable:
                    result['status'] = 'NOT_RUN'
                    result['errors'].append('Missing startup tool: ' + tool)
                    return 2
                result['toolchain'][tool] = dict(path=executable, sha256=qa.digest(executable))
            inputs = qa.source_inputs(SOURCE)
            revision = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=SOURCE,
                                               env=qa.isolated_environment(root), text=True, timeout=10).strip()
            result['source'] = dict(revision=revision, inputs=inputs, tree_sha256=qa.identity(inputs))
            app, copied_sdk = root / 'app', root / 'flutter'
            qa.snapshot(SOURCE, app, inputs)
            deps = qa.stage_dependencies(prefix, root / 'deps')
            env = qa.isolated_environment(root, prefix=deps, sdk=copied_sdk, node=node)
            cache = Path(os.environ['PUB_CACHE']) if os.environ.get('PUB_CACHE') else None
            qa.prepare(SOURCE, app, sdk, copied_sdk, env, cache)
            before = dict(source=qa.source_inputs(app), sdk=qa.sdk_inputs(copied_sdk),
                          dependencies=qa.tree(deps, links=True))
            (root / '.wing-startup-owner').touch()
            commands = [
                [str(copied_sdk / 'bin/flutter'), 'build', 'linux', '--debug', '--no-pub', '-t', 'lib/main.dart'],
                ['xvfb-run', '-a', '-s', '-screen 0 1440x1000x24 -nolisten tcp',
                 'dbus-run-session', '--', sys.executable, 'integration_test/run_linux_production_startup.py', '--observe'],
            ]
            for index, command in enumerate(commands):
                log = output / ('build.log' if index == 0 else 'startup.log')
                row = dict(command=command, exit_code=None)
                result['commands'].append(row)
                result['cleanup']['groups_gone'] = False
                with log.open('wb') as stream:
                    code, group = run_owned(['/bin/bash', '-c', 'exec "$@" 2>&1', 'startup', *command],
                                            app, env, timeout=600 if index == 0 else 60, stdout=stream)
                row.update(exit_code=code, driver_pid=group, log_sha256=qa.digest(log))
                result['cleanup']['groups_gone'] = not live_group(group)
                if code:
                    return code
                if index == 0:
                    bundle = app / 'build/linux/x64/debug/bundle'
                    result['bundle_sha256'] = qa.identity(qa.tree(bundle))
                else:
                    window = qa.read_json(root / 'startup-window.json')
                    if window['process_group'] != group or window['native_pid'] == group:
                        raise ValueError('Startup window was not owned by the display command')
                    result['window'] = window
                    shutil.copyfile(root / 'startup.png', output / 'startup.png')
                    result['screenshot_sha256'] = qa.digest(output / 'startup.png')
            after = dict(source=qa.source_inputs(app), sdk=qa.sdk_inputs(copied_sdk),
                         dependencies=qa.tree(deps, links=True))
            if (before != after or qa.source_inputs(SOURCE) != inputs or
                    qa.identity(qa.sdk_inputs(sdk)) != result['toolchain']['sdk_sha256'] or
                    qa.identity(qa.tree(prefix, links=True)) != result['toolchain']['dependencies_sha256']):
                raise ValueError('Startup input drift')
            result['status'] = 'PASS'
        return 0
    except Refusal as error:
        result['cleanup']['groups_gone'] = str(error) != 'OWNED_TEARDOWN_INCOMPLETE'
        raise
    finally:
        result['cleanup']['state_removed'] = not any(p.is_dir() for p in output.iterdir())
        if not all(result['cleanup'].values()):
            result['status'] = 'FAIL'
        (output / 'verification.json').write_text(json.dumps(result, indent=2))
        print(json.dumps(dict(status=result['status'], evidence=str(output))))
        if not all(result['cleanup'].values()):
            raise Refusal('OWNED_TEARDOWN_INCOMPLETE')


if __name__ == '__main__':
    if sys.argv[1:] == ['--observe']:
        observe_window()
    elif not sys.argv[1:]:
        sys.exit(run())
    else:
        raise SystemExit('No target, credential or executable arguments accepted')
