#!/usr/bin/env bash
# Deterministic native transport/UI + real preferences; never live inference.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
umask 077
scratch=$(realpath "${TMPDIR:?Set TMPDIR to the wing profile scratch directory}")
logs="$scratch/desktop-daily-workflow-harness"
mkdir -p "$logs"
exec > >(tee "$logs/launcher.log") 2>&1
printf 'Deterministic native daily workflow; no live Agent/provider acceptance.\n'
missing=0
for tool in flutter dart node python3 Xvfb xvfb-run xauth pkg-config cmake ninja clang++ timeout flock setsid; do
  if ! command -v "$tool" >/dev/null; then printf 'BLOCKER: missing executable %s\n' "$tool"; missing=1; fi
done
for package in gtk+-3.0 libsecret-1 gstreamer-1.0 gstreamer-app-1.0 gstreamer-audio-1.0; do
  if ! pkg-config --exists "$package"; then printf 'BLOCKER: missing pkg-config development package %s\n' "$package"; missing=1; fi
done
[[ -f .dart_tool/package_config.json ]] || { printf 'BLOCKER: existing package configuration missing (no pub get allowed).\n'; missing=1; }
[[ "$missing" == 0 ]] || exit 2
# Cooperating harnesses lock this scope. Also refuse pre-existing Flutter/build
# owners, which may not use this lock. Never remove SDK locks or shared output.
exec 9>"$logs/flutter-owner.lock"
flock -n 9 || { printf 'BLOCKER: daily workflow build ownership occupied.\n'; exit 3; }
python3 - <<'PY'
import pathlib, sys
owners = []
for process in pathlib.Path('/proc').iterdir():
    if not process.name.isdigit():
        continue
    try:
        args = (process / 'cmdline').read_bytes().split(b'\0')
        executable = pathlib.Path(args[0].decode()).name
        flutter_owner = executable in {'dart', 'dartvm', 'dartaotruntime', 'flutter_tester'} and any(
            b'flutter_tools.snapshot' in arg or b'frontend_server' in arg or b'flutter_tester' in arg
            for arg in args)
        native_owner = executable in {'cmake', 'ninja', 'clang', 'clang++'} and (
            (process / 'cwd').resolve() == pathlib.Path.cwd() or
            pathlib.Path.cwd() in (process / 'cwd').resolve().parents)
        if flutter_owner or native_owner:
            owners.append(process.name)
    except (OSError, UnicodeError, IndexError):
        continue
if owners:
    print('BLOCKER: active Flutter/build owners: ' + ', '.join(owners))
    sys.exit(3)
PY
root=$(mktemp -d "$scratch/wing-linux-daily.XXXXXX")
touch "$root/.wing-linux-test-owner"
runner_pid=''
cleanup() {
  local code=$?
  trap '' INT TERM
  if [[ -n "$runner_pid" ]]; then
    # The asynchronous wait is interruptible. Signal only our fresh session;
    # its timeout owns escalation while Python awaits its separate child groups.
    kill -TERM -- "-$runner_pid" 2>/dev/null || kill -TERM "$runner_pid" 2>/dev/null || true
    wait "$runner_pid" 2>/dev/null || true
    # timeout may exit before xvfb-run's own trap has finished. Do not remove
    # isolated preferences/display state until the remaining group has drained.
    python3 - "$runner_pid" <<'TEARDOWN'
import os, pathlib, signal, sys, time
pgid = int(sys.argv[1])
def live_group():
    for process in pathlib.Path('/proc').iterdir():
        try:
            stat = (process / 'stat').read_text().rsplit(')', 1)[1].split()
            if int(stat[2]) == pgid and stat[0] != 'Z':
                return True
        except (OSError, ValueError, IndexError):
            continue
    return False
deadline = time.monotonic() + 12
while live_group() and time.monotonic() < deadline:
    time.sleep(0.05)
if live_group():
    try:
        os.killpg(pgid, signal.SIGKILL)
    except ProcessLookupError:
        pass
    deadline = time.monotonic() + 2
    while live_group() and time.monotonic() < deadline:
        time.sleep(0.05)
if live_group():
    sys.exit('BLOCKER: owned process group survived; isolated state retained.')
TEARDOWN
  fi
  [[ "$(dirname "$root")" == "$scratch" && "$(basename "$root")" == wing-linux-daily.* && -f "$root/.wing-linux-test-owner" ]] || return 1
  rm -r -- "$root"
  printf 'TEARDOWN: owned runner reaped; guarded isolated state removed.\n'
  return "$code"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
mkdir -p "$root"/{home,config,data,cache,runtime}
chmod 700 "$root/runtime"
# xvfb-run owns and tears down Xvfb/Xauthority. No personal display, Wayland,
# session bus, portals, HOME or preference directories reach the test processes.
# Keep installed package/tool caches explicit: no package installation/download.
export WING_DAILY_FLUTTER="$(command -v flutter)"
export WING_DAILY_NODE="$(command -v node)"
export PUB_CACHE="${PUB_CACHE:-$HOME/.pub-cache}"
export WING_LINUX_TEST_ROOT="$root" WING_DAILY_LOGS="$logs"
export HOME="$root/home" XDG_CONFIG_HOME="$root/config" XDG_DATA_HOME="$root/data"
export XDG_CACHE_HOME="$root/cache" XDG_RUNTIME_DIR="$root/runtime"
export WING_ISOLATED_PREFERENCES=1 GDK_BACKEND=x11 LIBGL_ALWAYS_SOFTWARE=1
unset DISPLAY WAYLAND_DISPLAY DBUS_SESSION_BUS_ADDRESS SESSION_MANAGER
# One bounded runner owns the fixture and both app processes; only synthetic
# selection preferences survive between phases. Logs survive root cleanup.
setsid timeout --signal=TERM --kill-after=15s 600s xvfb-run -a -s '-screen 0 1600x1200x24 -nolisten tcp' python3 - <<'PY' &
import json, os, pathlib, queue, signal, socket, subprocess, threading, time, urllib.request
logs = pathlib.Path(os.environ['WING_DAILY_LOGS'])
children = []
def terminate():
    signal.signal(signal.SIGTERM, signal.SIG_IGN)
    signal.signal(signal.SIGINT, signal.SIG_IGN)
    # Signal every owned group first, then use one deadline for all children.
    for child in reversed(children):
        try:
            os.killpg(child.pid, signal.SIGTERM)
        except ProcessLookupError:
            pass
    deadline = time.monotonic() + 8
    for child in reversed(children):
        try:
            child.wait(timeout=max(0.01, deadline - time.monotonic()))
        except subprocess.TimeoutExpired:
            pass
    for child in reversed(children):
        # Reap the leader AND terminate any compiler/app descendants left behind.
        try:
            os.killpg(child.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
        child.wait(timeout=2)
    (logs / 'teardown-receipt.json').write_text(json.dumps({
        'synthetic': True, 'children': [
            {'pid': child.pid, 'exit': child.returncode} for child in children],
        'all_reaped': all(child.returncode is not None for child in children),
    }, indent=2) + '\n')
def interrupted(signum, frame):
    # timeout forwards the group signal again. Make cancellation idempotent
    # before unwinding, so that second TERM cannot interrupt owned teardown.
    signal.signal(signal.SIGTERM, signal.SIG_IGN)
    signal.signal(signal.SIGINT, signal.SIG_IGN)
    raise SystemExit(128 + signum)
signal.signal(signal.SIGTERM, interrupted)
signal.signal(signal.SIGINT, interrupted)
# Reserve both ports simultaneously; fail on bind race before contacting anything.
sockets = [socket.socket(), socket.socket()]
for sock in sockets:
    sock.bind(('127.0.0.1', 0))
ports = [sock.getsockname()[1] for sock in sockets]
for sock in sockets:
    sock.close()
origin = f'http://127.0.0.1:{ports[1]}'
environment = dict(os.environ, PORT=str(ports[0]), HERMES_E2E_PORT=str(ports[1]))
try:
    with (logs / 'fixture.log').open('w') as output:
        server = subprocess.Popen([os.environ['WING_DAILY_NODE'], 'scripts/support/desktop_daily_workflow_fixture.mjs'],
            env=environment, stdout=subprocess.PIPE, stderr=output, text=True, bufsize=1, start_new_session=True)
        children.append(server)
        announcements = {f'Server running at http://127.0.0.1:{ports[0]}/',
                         f'Hermes API running at {origin}/'}
        lines = queue.Queue()
        def drain():
            for line in server.stdout:
                lines.put(line)
        reader = threading.Thread(target=drain, daemon=True)
        reader.start()
        deadline = time.monotonic() + 10
        while announcements:
            if server.poll() is not None or time.monotonic() >= deadline:
                raise RuntimeError('Owned fixture did not announce both binds; no control request sent.')
            try:
                line = lines.get(timeout=0.2)
            except queue.Empty:
                continue
            output.write(line)
            output.flush()
            announcements.discard(line.strip())
        for phase in ['write', 'verify']:
            env = dict(os.environ, WING_DAILY_PHASE=phase, WING_DAILY_ORIGIN=origin)
            command = [os.environ['WING_DAILY_FLUTTER'], 'test', '--no-pub', '-d', 'linux',
                'integration_test/linux_desktop_daily_workflow_test.dart', '--reporter', 'expanded']
            print('COMMAND ' + ' '.join(command) + ' phase=' + phase, flush=True)
            with (logs / f'{phase}.log').open('w') as phase_log:
                app = subprocess.Popen(command, env=env, stdout=phase_log, stderr=subprocess.STDOUT, start_new_session=True)
                children.append(app)
                code = app.wait(timeout=260)
            print(f'PHASE {phase} EXIT {code}', flush=True)
            if code:
                raise SystemExit(code)
            if server.poll() is not None:
                raise RuntimeError('Owned fixture exited between phases.')
        with urllib.request.urlopen(origin + '/e2e/hermes/lifecycle', timeout=5) as response:
            receipt = json.load(response)
        assert receipt['synthetic'] is True
        assert len(receipt['submits']) == 2 and len(receipt['approvals']) == 1 and len(receipt['stops']) == 1
        assert not receipt['unexpected_mutations']
        restoration = receipt['restoration']
        pages = [r for r in restoration['inventory_reads'] if r['offset'] == 0 and r['status'] == 200]
        assert len(pages) >= 2 and all('e2e-hermes-session' not in r['session_ids'] for r in pages)
        exact_metadata = [r for r in restoration['metadata_reads'] if r['status'] == 200
            and r['profile_id'] == 'default' and r['session_id'] == 'e2e-hermes-session'
            and r['returned_session_id'] == 'e2e-hermes-session']
        assert len(exact_metadata) >= 2
        assert any(r['session_id'] == 'e2e-hermes-session' and r['profile_id'] == 'default'
            and 'canonical_run_2' in r['message_ids'] for r in receipt['history_reads'])
        (logs / 'final-receipt.json').write_text(json.dumps(receipt, indent=2) + '\n')
        print('PASS: two native processes; 2 submissions, 1 correlated approval, 1 Stop. Synthetic only.', flush=True)
finally:
    terminate()
PY
runner_pid=$!
# Unlike a foreground external command, bash wait returns immediately on a
# trapped signal; EXIT then forwards cancellation and awaits owned teardown.
wait "$runner_pid"
