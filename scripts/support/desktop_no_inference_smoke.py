"""Credential-free GTK QA only; never calls the public live admission path."""
import hashlib
import json
import os
import pathlib
import re
import shutil
import stat
import subprocess
import sys
import tarfile
import tempfile
import time
import types

PREDECESSOR = '894439b76c889fed45f3c4d57b73086f1e18d479'
CARD = 't_e662982c'
SMOKE_PREDECESSOR = '358f645c52c9cb53f8368ecb3346d577c05e9f68'
PHASES = ('write', 'verify', 'verify401', 'verify403', 'bootstrap401', 'bootstrap403')
OWNED = ('scripts/run_linux_desktop_no_inference_smoke.sh',
         'scripts/support/desktop_no_inference_smoke.py',
         'integration_test/linux_desktop_no_inference_smoke_test.dart',
         'integration_test/support/desktop_no_inference_fixture.dart',
         'test/tooling/desktop_no_inference_smoke_test.py',
         'docs/quality/native-no-inference-bootstrap-recovery.md')
ROOTS = ('lib', 'test', 'integration_test', 'assets', 'linux', 'wing_link',
         'scripts', 'playwright/support', 'docs')
FILES = ('pubspec.yaml', 'pubspec.lock', 'analysis_options.yaml', 'l10n.yaml',
         'serve_web.mjs', 'CONTEXT.md', 'CONTRIBUTING.md', 'AGENTS.md', 'SECURITY.md')
EXCLUDED_NAMES = frozenset(('ephemeral', '__pycache__', 'node_modules', '.git',
                            'build', 'target', '.pi', '.hermes', '.ua',
                            '.dart_tool', '.env', '.env.local', '.env.production'))
OVERLAYS = ('scripts/support/desktop_live_workflow.py',
            'test/tooling/desktop_live_workflow_test.py',
            'test/tooling/desktop_live_workflow_budget_test.dart',
            'integration_test/linux_desktop_live_workflow_test.dart',
            'scripts/run_linux_desktop_live_workflow.sh')


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def predecessor(source):
    # This checkout contains older dirty helper bytes. Do not silently import them.
    raw = subprocess.check_output(['git', 'show', PREDECESSOR + ':scripts/support/desktop_live_workflow.py'], cwd=source, timeout=30)
    module = types.ModuleType('attributed_live_helpers')
    exec(compile(raw, 'attributed_live_helpers', 'exec'), module.__dict__)
    return module, hashlib.sha256(raw).hexdigest()


def freeze(source, app):
    source = pathlib.Path(source).resolve()
    app.mkdir()
    tracked = set(subprocess.check_output(['git', 'ls-files'], cwd=source, timeout=30).decode().splitlines())
    dirty = set(subprocess.check_output(['git', 'diff', '--name-only', 'HEAD'], cwd=source, timeout=30).decode().splitlines())
    inputs = {}
    def copy_entry(parent, name, target):
        # Resolve each component relative to an opened directory. Never follow
        # links, including a link substituted between enumeration and opening.
        info = os.stat(name, dir_fd=parent, follow_symlinks=False)
        if stat.S_ISLNK(info.st_mode):
            raise ValueError('Linked source input rejected')
        if stat.S_ISDIR(info.st_mode):
            fd = os.open(name, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW, dir_fd=parent)
            try:
                target.mkdir()
                for child in sorted(os.listdir(fd)):
                    if child not in EXCLUDED_NAMES and not child.startswith('.env.'):
                        copy_entry(fd, child, target / child)
            finally:
                os.close(fd)
        elif stat.S_ISREG(info.st_mode):
            fd = os.open(name, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK, dir_fd=parent)
            with os.fdopen(fd, 'rb') as original:
                before = os.fstat(original.fileno())
                if not stat.S_ISREG(before.st_mode):
                    raise ValueError('Non-regular source input rejected')
                raw = original.read()
                original.seek(0)
                after = os.fstat(original.fileno())
                if (original.read() != raw or
                        (after.st_size, after.st_mtime_ns, after.st_ino, after.st_dev) !=
                        (before.st_size, before.st_mtime_ns, before.st_ino, before.st_dev)):
                    raise ValueError('Source changed during capture')
            target.write_bytes(raw)
            target.chmod(stat.S_IMODE(before.st_mode))
            relative = str(target.relative_to(app))
            inputs[relative] = {'sha256': hashlib.sha256(raw).hexdigest(),
                                'owner': CARD if relative in OWNED else 'inherited',
                                'dirty': relative in dirty or relative not in tracked}
        else:
            raise ValueError('Non-regular source input rejected')
    for name in ROOTS:
        # ROOTS may be nested (playwright/support); open parents without links.
        fd = os.open(source, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW)
        try:
            parts = pathlib.PurePath(name).parts
            for part in parts[:-1]:
                next_fd = os.open(part, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW, dir_fd=fd)
                os.close(fd)
                fd = next_fd
            (app / name).parent.mkdir(parents=True, exist_ok=True)
            copy_entry(fd, parts[-1], app / name)
        finally:
            os.close(fd)
    for name in FILES:
        fd = os.open(source, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW)
        try:
            copy_entry(fd, name, app / name)
        finally:
            os.close(fd)
    # Exact reviewed predecessor tests/helper: current checkout has stale dirty bytes.
    overlays = {}
    for name in OVERLAYS:
        raw = subprocess.check_output(['git', 'show', PREDECESSOR + ':' + name], cwd=source, timeout=30)
        (app / name).write_bytes(raw)
        overlays[name] = {'sha256': digest(app / name), 'revision': PREDECESSOR, 'owner': 'predecessor'}
    inherited_owned = {}
    for name in OWNED[:-1]:
        raw = subprocess.check_output(['git', 'show', SMOKE_PREDECESSOR + ':' + name], cwd=source, timeout=30)
        inherited_owned[name] = {'revision': SMOKE_PREDECESSOR,
                                 'sha256': hashlib.sha256(raw).hexdigest()}
    return {'base_revision': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=source).decode().strip(),
            'owned_predecessor_inputs': inherited_owned,
            'inputs': inputs, 'reviewed_overlays': overlays,
            'excluded': ['upstream clones', 'personal runtime/state', 'credentials', 'build outputs']}


def candidate_hashes(identity):
    return {name: row['sha256'] for name, row in
            (identity['inputs'] | identity['reviewed_overlays']).items()}


def retain_candidate(app, evidence, identity):
    """Archive the complete attributed candidate before any check can mutate it."""
    hashes = candidate_hashes(identity)
    archive = evidence / 'executed-source.tar.gz'
    with tarfile.open(archive, 'x:gz') as bundle:
        for name, expected in sorted(hashes.items()):
            path = app / name
            if path.is_symlink() or digest(path) != expected:
                raise ValueError('Candidate changed before archive')
            bundle.add(path, arcname=name, recursive=False)
        bundle.add(evidence / 'source.json', arcname='source.json', recursive=False)
    # Verify archived bytes, not just the mutable source or archive metadata.
    with tarfile.open(archive, 'r:gz') as bundle:
        members = bundle.getmembers()
        if {m.name for m in members} != set(hashes) | {'source.json'} or any(not m.isfile() for m in members):
            raise ValueError('Incomplete candidate archive')
        for name, expected in hashes.items():
            stream = bundle.extractfile(name)
            if stream is None:
                raise ValueError('Missing archive input')
            with stream:
                if hashlib.sha256(stream.read()).hexdigest() != expected:
                    raise ValueError('Archive hash mismatch')
    archive.chmod(0o400)
    receipt = {'filename': archive.name, 'sha256': digest(archive),
               'bytes': archive.stat().st_size, 'candidate_files': len(hashes),
               'captured_before_checks': True, 'missing_inputs': [],
               'source_manifest_sha256': digest(evidence / 'source.json')}
    (evidence / 'archive.json').write_text(json.dumps(receipt, indent=2))
    return receipt


def read_receipt(path, phase):
    if path.is_symlink() or path.stat().st_size > 32768:
        raise ValueError('Invalid receipt file')
    value = json.loads(path.read_text())
    if (value['phase'] != phase or type(value['native_pid']) is not int or value['native_pid'] <= 0 or
            set(value['counts']) != {'sends', 'session_creates', 'model_writes', 'approvals', 'stops', 'provider_requests', 'management_requests', 'mutation_attempts'} or
            any(type(n) is not int or n != 0 for n in value['counts'].values()) or
            not all(value[k] is True for k in ('keyboard_loading_cancel', 'keyboard_error_retry', 'wrong_owner_rejected', 'saved_owner_retained', 'cancelled_wrong_owner_rejected', 'cancelled_valid_owner_rejected')) or
            not all(re.fullmatch('[0-9a-f]{64}', value[k]) for k in ('owner_identity', 'history_identity')) or
            not value['requests'] or any(r['method'] != 'GET' for r in value['requests'])):
        raise ValueError('Invalid no-inference phase result')
    status = {'verify401': 401, 'verify403': 403}.get(phase)
    expected_denials = [] if status is None else [
        {'status': status, 'path': '/api/sessions/synthetic-history/messages', 'profile': 'synthetic-qa'}] * 2
    bootstrap = {'bootstrap401': 401, 'bootstrap403': 403}.get(phase)
    if bootstrap is not None:
        expected_denials = [{'status': bootstrap, 'path': '/v1/capabilities', 'profile': None}] * 4
    expected_bootstrap = [] if bootstrap is None else [
        [{'method': 'GET', 'path': path, 'query': {}} for path in
         ('/health', '/v1/capabilities', '/health', '/v1/capabilities')],
        *[[{'method': 'GET', 'path': path, 'query': {}} for path in ('/health', '/v1/capabilities')] for _ in range(2)]]
    if (phase not in PHASES or value['restoration_denial_status'] != status or
            value['bootstrap_denial_status'] != bootstrap or
            (bootstrap is not None and type(value['bootstrap_denial_status']) is not int) or
            value['bootstrap_denied_requests'] != expected_bootstrap or
            (bootstrap is not None and value['requests'][:8] != sum(expected_bootstrap, [])) or
            value['keyboard_bootstrap_retry'] is not (bootstrap is not None) or
            (status is not None and type(value['restoration_denial_status']) is not int) or
            value['keyboard_restoration_retry'] is not (status is not None) or
            value['denied_reads'] != expected_denials or
            any(r['path'] not in ('/health', '/v1/capabilities', '/api/profiles', '/api/sessions',
                                 '/api/sessions/synthetic-first', '/api/sessions/synthetic-history',
                                 '/api/sessions/other-session',
                                 '/api/sessions/synthetic-first/messages', '/api/sessions/synthetic-history/messages')
                for r in value['requests'])):
        raise ValueError('Invalid denied-read recovery result')
    return value, digest(path)


def phases(live, app, root, env, evidence, display_pid):
    receipts = []
    for phase in PHASES:
        path = root / 'cache' / ('smoke-' + phase + '.json')
        if path.exists():
            raise ValueError('Stale phase receipt')
        observed = {}
        process = {}
        def observe(driver):
            if not path.exists():
                return
            # Only synthetic bounded read metadata; retain failure diagnostics too.
            if not path.is_symlink() and path.stat().st_size <= 32768:
                shutil.copyfile(path, evidence / (phase + '-receipt.json'))
            value, checksum = read_receipt(path, phase)
            if observed:
                if observed != {'pid': value['native_pid'], 'sha256': checksum}:
                    raise ValueError('Phase changed after observation')
                return
            fields = pathlib.Path('/proc', str(value['native_pid']), 'stat').read_text().rsplit(')', 1)[1].split()
            if int(fields[2]) != driver or fields[0] == 'Z' or driver == value['native_pid']:
                raise ValueError('GTK application not owned by driver')
            observed.update(pid=value['native_pid'], sha256=checksum)
            process.update(start_ticks=fields[19], executable=pathlib.Path('/proc', str(value['native_pid']), 'exe').resolve().name)
        command = [str(root / 'flutter/bin/flutter'), 'test', '--verbose', '--no-pub', '--concurrency=1', '-d', 'linux',
                   'integration_test/linux_desktop_no_inference_smoke_test.dart']
        started = time.monotonic()
        with (evidence / (phase + '.log')).open('wb') as log:
            code, driver = live.run_owned(['bash', '-c', 'exec "$@" 2>&1', 'smoke', *command], app, env | {'WING_SMOKE_PHASE': phase}, timeout=480, stdout=log, observe=observe)
        if code:
            raise ValueError('GTK phase failed; inspect phase log')
        value, checksum = read_receipt(path, phase)
        if observed != {'pid': value['native_pid'], 'sha256': checksum} or not live.live_group(display_pid):
            raise ValueError('Application/display observation missing')
        if receipts:
            first, first_hash = read_receipt(root / 'cache/smoke-write.json', 'write')
            if first_hash != receipts[0]['receipt_sha256'] or any(value[k] != first[k] for k in ('owner_identity', 'history_identity')) or value['native_pid'] == first['native_pid']:
                raise ValueError('Exact restart mismatch')
        receipts.append(dict(value, receipt_sha256=checksum, driver_pid=driver,
                             process=process, command=command, exit=code,
                             display_pid=display_pid, display=env['DISPLAY'],
                             owned_group_gone=True, duration_seconds=round(time.monotonic() - started, 3)))
    return receipts


def run(source):
    source = pathlib.Path(source).resolve()
    evidence_root = source / 'build' / CARD
    evidence_root.mkdir(parents=True, exist_ok=True)
    evidence = pathlib.Path(tempfile.mkdtemp(prefix='attempt-', dir=evidence_root))
    live, helper_hash = predecessor(source)
    checks = []
    result = {'status': 'FAIL', 'live_workflow': 'NOT_CHECKED', 'checks': checks,
              'predecessor_helper_sha256': helper_hash}
    started = time.monotonic()
    try:
        with live.owned_workspace(evidence) as root:
            app, sdk = root / 'app', root / 'flutter'
            identity = freeze(source, app)
            (evidence / 'source.json').write_text(json.dumps(identity, indent=2))
            result['source_archive'] = retain_candidate(app, evidence, identity)
            executable = shutil.which('flutter')
            if executable is None:
                raise ValueError('Flutter unavailable')
            flutter = pathlib.Path(executable).resolve()
            live.prepare_packages(source, app, flutter.parent.parent, sdk)
            env = {k: os.environ[k] for k in ('PATH', 'LANG', 'PKG_CONFIG_PATH', 'CMAKE_PREFIX_PATH', 'LIBRARY_PATH', 'CPATH') if k in os.environ}
            for name in ('home', 'config', 'data', 'cache', 'runtime'):
                (root / name).mkdir(mode=0o700)
            env.update(HOME=str(root / 'home'), XDG_CONFIG_HOME=str(root / 'config'), XDG_DATA_HOME=str(root / 'data'),
                       XDG_CACHE_HOME=str(root / 'cache'), XDG_RUNTIME_DIR=str(root / 'runtime'), TMPDIR=str(root / 'cache'),
                       WING_SMOKE_ROOT=str(root), GDK_BACKEND='x11', LIBGL_ALWAYS_SOFTWARE='1', CMAKE_BUILD_PARALLEL_LEVEL='2',
                       PUB_CACHE=os.environ.get('PUB_CACHE', str(pathlib.Path.home() / '.pub-cache')),
                       GOMODCACHE=subprocess.check_output(['go', 'env', 'GOMODCACHE'], timeout=30).decode().strip(),
                       GOMAXPROCS='2', GOFLAGS='-p=2', GOPROXY='off', GOSUMDB='off', GOTOOLCHAIN='local', GOCACHE=str(root / 'cache/go-build'))
            result['environment'] = {'uname': list(os.uname()), 'sdk': subprocess.check_output([str(sdk / 'bin/flutter'), '--version'], env=env, timeout=30).decode(),
                                     'package_config_sha256': digest(app / '.dart_tool/package_config.json'), 'plugins_sha256': digest(app / '.flutter-plugins-dependencies'),
                                     'build_dependency_archives': {p.name: digest(p) for p in sorted((evidence_root / 'deps/downloads').glob('*.deb'))},
                                     'pkg_config_versions': subprocess.check_output(['pkg-config', '--modversion', 'gtk+-3.0', 'gstreamer-1.0', 'gstreamer-app-1.0', 'gstreamer-audio-1.0', 'libsecret-1'], env=env, timeout=30).decode()}
            commands = [
                ['bash', '-n', 'scripts/run_linux_desktop_no_inference_smoke.sh'],
                ['python3', '-B', '-m', 'unittest', 'discover', '-s', 'test/tooling', '-p', 'desktop_no_inference_smoke_test.py'],
                [str(sdk / 'bin/dart'), 'format', '--output=none', '--set-exit-if-changed', *OWNED[2:4]],
                [str(sdk / 'bin/flutter'), 'analyze', '--no-pub'],
                [str(sdk / 'bin/flutter'), 'test', '--no-pub', '--concurrency=1', 'test/tooling/desktop_live_workflow_budget_test.dart',
                 'test/features/hermes_chat/screens/hermes_chat_screen_auth_recovery_test.dart',
                 'test/features/hermes_chat/screens/hermes_chat_session_restoration_test.dart',
                 'test/features/hermes_chat/gateways/hermes_gateway_restoration_adversarial_test.dart',
                 'test/features/hermes_chat/screens/hermes_chat_death_completion_recovery_test.dart',
                 'test/features/hermes_chat/screens/hermes_chat_session_search_resume_journey_test.dart',
                 'test/shared/widgets/app_shell_global_session_modal_test.dart'],
                ['python3', '-B', '-m', 'unittest', *[
                    'test.tooling.desktop_live_workflow_test.BoundaryTests.' + name for name in (
                        'test_no_auth_no_network_or_workspace',
                        'test_live_call_ceiling_refusal_survives_remaining_and_exhausted_budget',
                        'test_fresh_process_phase_and_reset_counter_cannot_upgrade_live_admission',
                        'test_real_launcher_no_inputs')]],
            ]
            for index, command in enumerate(commands):
                tick = time.monotonic()
                with (evidence / f'check-{index}.log').open('wb') as log:
                    code, _ = live.run_owned(['bash', '-c', 'exec "$@" 2>&1', 'smoke', *command], app, env, timeout=300, stdout=log)
                checks.append({'command': command, 'exit': code, 'duration_seconds': round(time.monotonic() - tick, 3)})
                if code:
                    raise ValueError('Scoped check failed')
            # Public no-input live launcher must refuse before reads or mutations.
            refusal = subprocess.run(['bash', 'scripts/run_linux_desktop_live_workflow.sh'], cwd=app, env=env,
                                     input=b'', capture_output=True, timeout=30)
            public = json.loads(refusal.stdout)
            if refusal.returncode != 2 or public['read_requests_attempted'] != 0 or public['mutations'] != 0 or public['inference_count'] != 0:
                raise ValueError('Live refusal changed')
            result['public_refusal'] = public
            authority = root / 'cache/display-authority'
            live.display_authority(authority)
            env['XAUTHORITY'] = str(authority)
            deadline = time.monotonic() + 10
            class Finished(Exception):
                pass
            with tempfile.TemporaryFile(dir=root / 'cache') as output:
                def observe(display_pid):
                    output.seek(0)
                    number = output.read(17)
                    if not re.fullmatch(rb'[0-9]{1,5}\n', number):
                        if time.monotonic() > deadline:
                            raise ValueError('Display startup failed')
                        return
                    env['DISPLAY'] = ':' + number.decode().strip()
                    live.admit_display(root, env)
                    result['display'] = {'pid': display_pid, 'display': env['DISPLAY'], 'authenticated': True, 'wrong_missing_authority_rejected': True}
                    result['phases'] = phases(live, app, root, env, evidence, display_pid)
                    raise Finished()
                try:
                    live.run_owned(['/usr/bin/Xvfb', '-displayfd', '1', '-screen', '0', '1440x1000x24', '-nolisten', 'tcp', '-auth', str(authority)],
                                   app, env, timeout=1000, stdout=output, observe=observe)
                except Finished:
                    result['display']['owned_group_gone'] = True
                else:
                    raise ValueError('Display exited before phases')

            result['executed_input_hashes'] = {name: digest(app / name) for name in candidate_hashes(identity)}
            if result['executed_input_hashes'] != candidate_hashes(identity):
                raise ValueError('Executed source inputs changed')
            if digest(evidence / 'executed-source.tar.gz') != result['source_archive']['sha256']:
                raise ValueError('Retained archive changed')
            result['status'] = 'NATIVE_NO_INFERENCE_PASS'
        result['isolated_state_deleted_after_teardown'] = True
    finally:
        result['duration_seconds'] = round(time.monotonic() - started, 3)
        (evidence / 'verification.json').write_text(json.dumps(result, indent=2))
    return result


def main(argv=None):
    argv = sys.argv[1:] if argv is None else argv
    if argv:
        print(json.dumps({'status': 'NO_ARGUMENTS_OR_CREDENTIALS_ACCEPTED'}))
        return 2
    result = run(pathlib.Path(__file__).resolve().parents[2])
    print(json.dumps({key: result[key] for key in ('status', 'duration_seconds', 'live_workflow', 'display', 'isolated_state_deleted_after_teardown')}, sort_keys=True))
    return 0


if __name__ == '__main__':
    sys.exit(main())
