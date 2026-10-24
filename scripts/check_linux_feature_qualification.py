#!/usr/bin/env python3
"""Validate private schema-1 Linux fixture receipts; never qualify live Linux/PARITY."""
import argparse
import json
import os
from pathlib import Path
import re
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent / 'support'))
import linux_qualification_support as qa
import run_linux_feature_qualification as driver

SOURCE = Path(__file__).resolve().parents[1]
LANES = ('shared', 'connections', 'chat', 'management', 'access')
# These files are captured but never executed by any of the five fixture lanes.
REPORT_INPUTS = {'scripts/check_linux_feature_qualification.py',
                 'test/tooling/linux_feature_qualification_report_test.py'}
# This target is dispatched only by Chat; no other lane imports it. A change here
# requires a fresh Chat receipt, never repinning any original receipt's source.
CHAT_TARGET = 'integration_test/linux_chat_feature_qualification_test.dart'
LIVE = {
    'PARITY-NATIVE-LINUX-LIVE': 'Real Agent/SSH/OAuth/provider custody, physical audio, Wayland/IME and screen reader',
    'PARITY-LIVE-WORKFLOW-LIVE': 'Actual generation, correlated approval, authoritative Stop and terminal recovery',
    'PARITYUPDATE-002-5c-LIVE': 'Actual Agent workflow and canonical readback',
    'BACKEND-SSH-KEY-NATIVE-LIVE': 'Real SSH identity, encrypted keys and native key acquisition',
    'DOC-NATIVE-FAILURE-BOUNDARY-LIVE': 'Intended-target failure, latency, cancellation and custody',
    'DOC-NATIVE-DESIGN-REVIEW-LIVE': 'Intended-device chooser/modal and UX review',
    'VERIFY-PERSONA-LIVE-COMPATIBILITY': 'Deployed SOUL revision/conflict persistence',
    'PARITYGAP-002-76-LIVE': 'Full GTK overwrite/readback/owner-change with live projected history',
    'VERIFY-SHELL-NATIVE-INPUT': 'Physical window/keyboard, OS menu and persisted intent',
    'VERIFY-DESKTOP-NATIVE-DELIVERY': 'Exact-artifact install/upgrade/retained keyring/removal/rollback',
}


# Public action groups traced to the target assertions. A group is a bounded
# subset, not a claim that every action in the corresponding family was tested.
ACTION_CASES = {
    'entry/local-folder-cancel-denial': ['connections.local-picker-recovery'],
    'entry/connect-retry-save-denial': ['connections.bootstrap-owner-replacement', 'connections.absent-native-contracts-no-replay'],
    'saved-host/edit-test-cancel': ['connections.saved-origin-credential-custody'],
    'ssh/connect-cancel-retired-trust': ['connections.ssh-retired-trust-review'],
    'chat/bot-canonical-and-rejections': ['chat.bot-canonical-draft', 'chat.bot-reject-registry', 'chat.bot-reject-hidden', 'chat.bot-reject-history', 'chat.bot-reject-replacement'],
    'chat/send-approval-stop-recovery': ['chat.native-stream-stop-recovery', 'chat.stale-stop'],
    'chat/follow-up-fifo-owner': ['chat.queue-owner-draft', 'chat.queue-fifo'],
    'chat/tab-activate-search-load-more': ['chat.api-tabs-search-pages'],
    'chat/pin-unpin-rename-branch-delete': ['chat.api-session-actions'],
    'chat/model-explicit-retry': ['chat.api-model-retry'],
    'chat/timestamp-slash-aliases': ['chat.local-timestamps'],
    'chat/attachment-late-chooser': ['chat.attachment-owner'],
    'chat/native-tabs-attachment-clarification-negative': ['chat.native-contract-gaps'],
    'export/json-consent-save-refuse-cancel-owner': ['chat.json-save', 'chat.json-refuse', 'chat.json-cancel', 'chat.json-owner', 'chat.json-cancel-read', 'chat.json-frozen-boundary'],
    'export/loaded-text-markdown': ['chat.loaded-text', 'chat.loaded-markdown', 'access-export'],
    'chat/settings-overlay-close': ['chat.streaming-overlay'],
    'chat/exact-two-process-restore': ['chat.two-process-recovery'],
    'profiles/search-clear-create-edit-delete-owner': ['management.profiles-lifecycle-owner'],
    'persona/save-conflict-retry': ['management.persona-revision-recovery'],
    'providers/search-clear-credential-contract-denial-owner': ['management.provider-secret-recovery', 'management.provider-stale-owner'],
    'providers/model-presets-catalog-main-vision': ['management.model-explicit-assignment'],
    'tools/search-clear-disclose-refresh-retry': ['management.read-only-inventory-recovery'],
    'schedules/search-filter-clear-refresh-retry': ['management.read-only-inventory-recovery'],
    'connections/health-refresh-retry': ['management.connections-health-recovery'],
    'settings/appearance-voice-diagnostics-copy-retry': ['management.settings-diagnostics'],
    'navigation/legacy-agents-redirect': ['management.legacy-agents-alias'],
    'management/missing-denied-readonly-no-dispatch': ['management.authority-missing', 'management.authority-denied', 'management.authority-read-only'],
    'management/unavailable-controls': ['management.unavailable-administration'],
    'access/footer-status-inspection': ['access-footer', 'access-status'],
    'access/composer-traversal-model-escape': ['access-keyboard'],
    'access/voice-negative-cancel-stop-teardown': ['access-voice-' + s for s in ('unavailable', 'denied', 'cancel', 'background', 'owner', 'dispose', 'playback')],
    'access/framework-settings-command': ['access-host-command'],
    'enrollment/positive-welcome-all-actions': [],
    'local-setup/composed-ui': [],
    'saved-host/all-connect-disconnect-remove': [],
    'native/physical-os-menu-window': [],
    'delivery/install-upgrade-remove-rollback': [],
}


def require(condition, message):
    if not condition:
        raise ValueError(message)


def schema(value):
    require(isinstance(value, dict) and type(value.get('schema')) is int and value['schema'] == 1,
            'Schema-1 document required')


def artifact(root, name, checksum):
    require(isinstance(name, str) and name and not Path(name).is_absolute() and '..' not in Path(name).parts,
            'Relative contained artifact required')
    path = qa.plain_path(root / name)
    require(path.is_relative_to(root) and isinstance(checksum, str) and qa.digest(path) == checksum,
            'Missing/changed artifact: ' + name)
    return path


def read_suite(path, command_code=None):
    # The driver's visible inventory deliberately omits framework records. Hidden
    # failures still invalidate a green wrapper and must survive in the ledger.
    tests = driver.suite_result(path, require_success=False)
    starts, terminals, success = {}, [], None
    for line in path.read_text(errors='replace').splitlines():
        try:
            event = json.loads(line)
        except ValueError:
            continue
        if not isinstance(event, dict):
            continue
        if event.get('type') == 'testStart':
            starts[event['test']['id']] = event['test']['name']
        elif event.get('type') == 'testDone':
            require(event.get('skipped') is False, 'Unexplained suite skip')
            terminals.append(event)
            if event.get('hidden') and event['result'] != 'success':
                tests.append(dict(id=event['testID'], name=starts[event['testID']], result=event['result'],
                                  skipped=False, hidden=True))
        elif event.get('type') == 'done':
            success = event['success']
    require(success == all(t['result'] == 'success' for t in terminals), 'Suite terminal/result mismatch')
    if command_code is not None:
        require(success == (command_code == 0), 'Suite terminal/command mismatch')
    return tests


def expected_cases(source):
    """Read the four existing fixture registries, not a claimed receipt inventory.

    These deliberately narrow source forms fail closed when a registry changes.
    They are not a general Dart parser or proof that a control was operated.
    """
    result = {}
    def strings(text):
        return re.findall(r"'([^']+)'", text)
    for lane, singular in (('connections', 'connection'), ('management', 'management')):
        text = (source / f'integration_test/linux_{singular}_feature_qualification_test.dart').read_text()
        rows = {}
        if lane == 'connections':
            for case, features in re.findall(r"cases.record\(\s*'([^']+)',\s*(\[[\s\S]*?\]),", text):
                rows[case] = (strings(features), ['/hermes/add'])
        else:
            for case, features, routes in re.findall(
                    r"cases.record\(\s*'([^']+)',\s*(\[[\s\S]*?\]),\s*(\[[\s\S]*?\]),", text):
                if case == 'absent-${entry.key}':
                    continue
                for name in (['authority-' + a for a in ('missing', 'denied', 'read-only')]
                             if case == 'authority-$authority' else [case]):
                    rows['management.' + name] = (strings(features), strings(routes))
            absent = re.search(r'const absent = \{([\s\S]*?)\};', text)
            require(absent is not None, 'Missing negative route registry')
            for feature, route in re.findall(r"'(HD-[^']+)': '([^']+)'", absent[1]):
                rows['management.absent-' + feature] = ([feature], [route])
        require(len(rows) == (5 if lane == 'connections' else 33), 'Changed case registry: ' + lane)
        result[lane] = rows
    text = (source / 'integration_test/support/linux_chat_feature_fixture.dart').read_text()
    registered = strings(re.search(r'static const expectedIds = \[([\s\S]*?)\];', text)[1])
    mapping = re.search(r'static List<String> _features\(String id\) => switch \(id\) \{([\s\S]*?)\n  \};', text)[1]
    rows = {}
    for keys, values in re.findall(r"((?:\s*'chat\.[^']+'\s*(?:\|\|\s*)?)+)=>\s*(\[[\s\S]*?\])", mapping):
        for key in strings(keys):
            rows[key] = (strings(values), ['/hermes'])
    require(len(rows) == 25 and set(rows) == set(registered), 'Changed Chat case registry')
    result['chat'] = rows
    text = (source / 'integration_test/linux_access_feature_qualification_test.dart').read_text()
    rows = {}
    for case, features, routes in re.findall(
            r"receipts.add\(\s*'([^']+)',\s*(\[[\s\S]*?\]),\s*(\[[\s\S]*?\]),", text):
        for name in (['access-voice-' + a for a in ('unavailable', 'denied', 'cancel', 'background', 'owner', 'dispose', 'playback')]
                     if case == 'access-voice-${boundary.name}' else [case]):
            rows[name] = (strings(features), strings(routes))
    require(len(rows) == 12, 'Changed access case registry')
    result['access'] = rows
    return result


def evidence_roots(root):
    path = root / 'composition.json'
    if not path.exists():
        return dict.fromkeys(LANES, root)
    value = qa.read_json(path)
    schema(value)
    require(isinstance(value.get('lanes'), dict) and set(value['lanes']) == set(LANES), 'Composition lane inventory mismatch')
    roots = {}
    for lane, binding in value['lanes'].items():
        directory = qa.plain_path(binding['directory'])
        require(directory.is_dir() and directory.stat().st_uid == os.getuid() and not directory.stat().st_mode & 0o077,
                'Owned private lane location required')
        artifact(directory, lane + '.json', binding.get('receipt_sha256'))
        artifact(directory, 'campaign.json', binding.get('campaign_sha256'))
        roots[lane] = directory
    return roots


def retained_failures(root, selected):
    """Retain superseded terminal failures, never treating them as current cases."""
    failures = []
    for lane in LANES:
        path = root / (lane + '.json')
        if selected[lane] == root or not path.exists():
            continue
        value = qa.read_json(path)
        schema(value)
        require(value.get('lane') == lane and value.get('status') == 'fail', 'Invalid retained failure identity')
        commands = value.get('commands', [])
        require(commands and all(type(c.get('exit_code')) is int for c in commands), 'Nonterminal retained failure')
        for command in commands:
            artifact(root, command.get('log'), command.get('log_sha256'))
        failures.append(dict(lane=lane, status='fail', source=value['source'], commands=commands,
                             receipt_sha256=qa.digest(path), qualification='historical-failure-not-current-coverage'))
    return failures


def check_lane(lane, root, current, expected):
    root = qa.plain_path(root)
    value = qa.read_json(root / (lane + '.json'))
    schema(value)
    require(value.get('lane') == lane and value.get('ready') is True and value.get('status') in ('pass', 'fail'),
            'Missing/nonterminal lane: ' + lane)
    binding = qa.read_json(root / 'campaign.json')
    schema(binding)
    source = value.get('source', {})
    captured = source.get('inputs')
    require(isinstance(captured, dict) and captured and source == binding.get('source') and
            value.get('toolchain') == binding.get('toolchain') and source.get('tree_sha256') == qa.identity(captured) and
            re.fullmatch(r'[0-9a-f]{40}', source.get('revision', '')) is not None,
            'Stale source/campaign binding: ' + lane)
    changed = {path for path in captured.keys() | current.keys() if captured.get(path) != current.get(path)}
    nonexecuted = REPORT_INPUTS | ({CHAT_TARGET} if lane != 'chat' else set())
    require(changed <= nonexecuted, 'Stale executed source inputs: ' + lane)
    equivalence = dict(current_sha256=qa.identity(current), captured_sha256=qa.identity(captured),
                       changed_nonexecuted_inputs=sorted(changed))
    cleanup = value.get('cleanup', {})
    require(cleanup.get('groups_gone') is True and cleanup.get('state_removed') is True,
            'Incomplete cleanup: ' + lane)
    state = cleanup.get('state')
    require(isinstance(state, str) and re.fullmatch(r'state-[\w-]+', state) is not None and
            not (root / state).exists(), 'Invalid/preserved state identity')
    rows = value.get('commands')
    require(isinstance(rows, list) and rows, 'Missing command inventory')
    expected_commands = driver.commands(lane, root / state / 'flutter', value['toolchain']) if lane != 'shared' else None
    if expected_commands is not None:
        require(len(rows) == len(expected_commands), 'Missing/duplicate dispatched target')
    logs = []
    for index, row in enumerate(rows):
        code = row.get('exit_code')
        require(type(code) is int and -64 <= code <= 255 and row.get('owned_group_gone') is True and
                type(row.get('driver_pid')) is int and row['driver_pid'] > 0 and
                row.get('status') == ('pass' if code == 0 else 'fail'), 'Interrupted/invalid command')
        if expected_commands is not None:
            require(row.get('command') == ['/bin/bash', '-c', 'exec "$@" 2>&1', 'qualification', *expected_commands[index]],
                    'Fixed dispatch mismatch')
        logs.append(artifact(root, row.get('log'), row.get('log_sha256')))
        for saved in row.get('artifacts', {}).values():
            artifact(root, saved.get('path'), saved.get('sha256'))
    require((value['status'] == 'pass') == (all(r['exit_code'] == 0 for r in rows) and not value.get('error')),
            'Lane status contradicts exact command results')
    if lane == 'shared':
        cases = check_shared(root, value, current, logs)
    else:
        require(re.fullmatch(r'[0-9a-f]{64}', value.get('executed_inputs_sha256', '')) is not None,
                'Missing executed input closure')
        cases = driver.validate_cases(dict(schema=1, cases=value.get('cases')))
        require(set(c['id'] for c in cases) == set(expected), 'Missing/unknown case inventory')
        for case in cases:
            features, routes = expected[case['id']]
            require(set(case['feature_ids']) == set(features) and set(case['route_ids']) == set(routes),
                    'Feature/route case inventory mismatch')
            if case['status'] in ('not_run', 'unsupported', 'coverage_gap'):
                require(case['skip_reason'].strip(), 'Unexplained skip')
            index = case.get('command_index')
            require(type(index) is int and index == 0, 'Case not bound to registered GTK target')
            command = rows[index]
            require(case.get('log_sha256') == command['log_sha256'], 'Case log binding mismatch')
            saved = artifact(root, lane + '-0-feature-cases.json', case.get('artifact_sha256'))
            document = qa.read_json(saved)
            originals = driver.validate_cases(document)
            require({c['id'] for c in originals} == set(expected), 'Artifact case inventory mismatch')
            original = next(c for c in originals if c['id'] == case['id'])
            require(case == original | {k: case[k] for k in ('command_index', 'artifact_sha256', 'log_sha256')},
                    'Case/artifact mismatch')
            processes = command.get('processes', [])
            require(any(p.get('native_pid') == case['native_pid'] and type(p.get('native_pid')) is int and
                        isinstance(p.get('start_ticks'), str) and p['start_ticks'].isdigit() for p in processes),
                    'Missing native case observation')
        runners = driver.RUNNERS.get(lane, ())
        nested = value.get('runner_receipts', [])
        successful = [name for index, name in enumerate(runners, 1) if rows[index]['exit_code'] == 0]
        require([n.get('runner') for n in nested] == successful, 'Missing/duplicate successful runner receipt')
        for index, name in enumerate(runners, 1):
            row = rows[index]
            saved = row.get('artifacts', {}).get('verification.json', {})
            path = artifact(root, saved.get('path'), saved.get('sha256'))
            proof = qa.read_json(path)
            if row['exit_code'] == 0:
                item = next(n for n in nested if n['runner'] == name)
                require(proof == item.get('receipt') and driver.validate_runner(name, path.parent) == proof,
                        'Nested receipt/validation mismatch')
            else:
                # Failed native runners return before the driver's success-only
                # runner_receipts append. Their retained terminal proof is evidence.
                require(proof.get('status') == 'FAIL' and type(proof.get('exit_code')) is int and
                        proof['exit_code'] != 0 and row.get('native_exit_code') == proof['exit_code'] and
                        proof.get('isolated_state_removed') is True and
                        proof.get('cleanup', {}).get('groups_gone') is True and
                        proof['cleanup'].get('state_removed') is True, 'Incomplete failed runner proof')
    return cases, dict(status=value['status'], source=source, source_equivalence=equivalence, toolchain=value['toolchain'],
                       receipt_sha256=qa.digest(root / (lane + '.json')), commands=rows)


def check_shared(root, value, current, logs):
    suites, rows = value.get('suite_runs', []), value['commands']
    require(len(rows) == len(suites) == 5 and len(value.get('batches', [])) == 4,
            'Missing shared batch/suite inventory')
    cases, observed, native_names, native_batches = [], set(), [], {}
    for index, (row, suite, log) in enumerate(zip(rows, suites, logs)):
        batch = 'core' if index < 2 else list(driver.SHARED_NATIVE_BATCHES)[index - 1]
        directory = root / ('shared-' + batch)
        binding = next((b for b in value['batches'] if b.get('batch') == batch), {})
        require(binding.get('receipt') == 'shared-' + batch + '/shared.json', 'Shared batch binding path mismatch')
        batch_path = artifact(root, binding['receipt'], binding.get('sha256'))
        batch_receipt = qa.read_json(batch_path)
        schema(batch_receipt)
        require(batch_receipt.get('source') == value['source'] and batch_receipt.get('toolchain') == value['toolchain'] and
                batch_receipt.get('batch') == batch and batch_receipt.get('lane') == 'shared' and
                batch_receipt.get('cleanup', {}).get('groups_gone') is True and
                batch_receipt['cleanup'].get('state_removed') is True, 'Stale/incomplete shared batch')
        state = batch_receipt['cleanup'].get('state', '')
        require(re.fullmatch(r'state-[\w-]+', state) is not None and not (directory / state).exists(), 'Preserved batch state')
        commands = driver.commands('shared', directory / state / 'flutter', value['toolchain'], shared_batch=batch)
        offset = index if batch == 'core' else 0
        require(row.get('command') == ['/bin/bash', '-c', 'exec "$@" 2>&1', 'qualification', *commands[offset]],
                'Shared fixed dispatch mismatch')
        require(row == batch_receipt['commands'][offset] | {'batch': batch, 'log': row['log']} and
                suite == batch_receipt['suite_runs'][offset] | {'batch': batch, 'command_index': index},
                'Shared batch join mismatch')
        tests = read_suite(log, row['exit_code'])
        require(suite.get('tests') == [t for t in tests if not t.get('hidden')] and suite.get('command_index') == index and
                suite.get('target_sha256') == current.get(suite.get('target')) and
                suite.get('log_sha256') == row['log_sha256'] and suite.get('status') == row['status'],
                'Shared suite/log/source mismatch')
        for test in tests:
            require(type(test.get('id')) is int and isinstance(test.get('name'), str), 'Invalid suite identity')
            case_id = 'shared.' + str(index) + '.' + str(test['id'])
            cases.append(dict(id=case_id, status='pass' if test['result'] == 'success' else 'fail',
                              feature_ids=[], route_ids=[], suite=suite['target'], name=test['name'],
                              log_sha256=row['log_sha256'], backend=suite.get('backend'),
                              input=suite.get('input'), storage=suite.get('storage')))
            match = re.match(r'(test/\S+_test\.dart) ', test['name'])
            if match:
                require(native_batches.get(test['name'], batch) == batch and
                        re.search(driver.SHARED_NATIVE_BATCHES[batch], test['name']),
                        'Overlapping/misselected shared test')
                native_batches[test['name']] = batch
                native_names.append(test['name'])
                observed.add(match[1])
        if index > 0:
            processes = suite.get('native_processes')
            require(isinstance(processes, list) and processes and all(
                type(p.get('native_pid')) is int and p['native_pid'] > 0 and
                isinstance(p.get('start_ticks'), str) and p['start_ticks'].isdigit() for p in processes),
                'Missing/invalid shared GTK observation')
    adapter = current.get('integration_test/linux_feature_regression_test.dart')
    require(adapter is not None, 'Missing adapter input')
    # The inventory is printed by the executed host test, not inferred from counts.
    inventories = []
    for line in logs[0].read_text(errors='replace').splitlines():
        try:
            event = json.loads(line)
            message = json.loads(event.get('message', '{}')) if isinstance(event, dict) else {}
        except (ValueError, TypeError):
            continue
        if isinstance(message, dict) and message.get('kind') == 'linux-adapter-inventory':
            inventories.append(message)
    require(len(inventories) == 1, 'Missing/duplicate executed adapter inventory')
    selected = inventories[0].get('selected_suites', [])
    adapter_text = (SOURCE / 'integration_test/linux_feature_regression_test.dart').read_text()
    imports = re.findall(r"import\s+'\.\./(test/[^']+_test\.dart)'\s+as\s+(\w+)\s*;", adapter_text)
    registered = re.findall(r"group\(\s*'(test/[^']+_test\.dart)'\s*,\s*(?:\(\)\s*=>\s*)?(\w+)\.main\b", adapter_text)
    require(qa.digest(SOURCE / 'integration_test/linux_feature_regression_test.dart') == adapter and
            len(imports) == len(set(imports)) and sorted(imports) == sorted(registered) and
            selected and len(set(selected)) == len(selected) and set(selected) == observed == {p for p, _ in imports} and
            all(path in current for path in selected), 'Selected/observed shared inventory mismatch')
    for batch, count in (('delete-timers', 3), ('create-timers', 2)):
        require(sum(1 for name in native_names if re.search(driver.SHARED_NATIVE_BATCHES[batch], name)) == count,
                'Missing full-duration timer cases')
    return cases


def make_ledger(cases, features, routes, actions):
    ids = {c['id']: c for c in cases}
    require(len(ids) == len(cases), 'Duplicate joined case identity')
    require(all(set(c['feature_ids']) <= set(features) for c in cases), 'Unknown feature inventory')
    def cell(names):
        require(all(name in ids for name in names), 'Unknown action/case inventory')
        return dict(cases=sorted(names), statuses=sorted({ids[n]['status'] for n in names}) if names else ['coverage_gap'],
                    **({} if names else {'reason': 'No case-level runtime evidence; not a synthetic result'}))
    feature_rows = {f: cell([c['id'] for c in cases if f in c['feature_ids']]) for f in features}
    route_rows = {r: cell([c['id'] for c in cases if r in c['route_ids']]) for r in routes}
    action_rows = {a: cell(names) for a, names in actions.items()}
    incomplete = any(c['status'] in ('fail', 'not_run', 'coverage_gap') for c in cases) or any(
        not c['cases'] for rows in (feature_rows, route_rows, action_rows) for c in rows.values())
    return dict(features=feature_rows, routes=route_rows, actions=action_rows,
                fixture_verdict='PARTIAL' if incomplete else 'COMPLETE', overall_linux_verdict='PARTIAL', parity_met=False,
                pending_live=[dict(task=k, status='not_run', scope=v) for k, v in LIVE.items()])


def dart_tokens(text):
    """Lex source, not strings/comments, retaining offsets for audit references."""
    token = re.compile(r'''r?(?:\"\"\"[\s\S]*?\"\"\"|\x27\x27\x27[\s\S]*?\x27\x27\x27|\"(?:\\.|[^\"\\])*\"|\x27(?:\\.|[^\x27\\])*\x27)|[A-Za-z_$][\w$]*|=>|==|[^\s]''')
    result, offset = [], 0
    while offset < len(text):
        if text[offset].isspace():
            offset += 1
            continue
        if text.startswith('//', offset):
            end = text.find('\n', offset)
            offset = len(text) if end < 0 else end
            continue
        if text.startswith('/*', offset):
            depth, offset = 1, offset + 2
            while depth and offset < len(text):
                if text.startswith('/*', offset):
                    depth, offset = depth + 1, offset + 2
                elif text.startswith('*/', offset):
                    depth, offset = depth - 1, offset + 2
                else:
                    offset += 1
            require(depth == 0, 'Unterminated Dart comment')
            continue
        match = token.match(text, offset)
        require(match is not None, 'Unrecognized Dart token')
        result.append((match[0], offset))
        offset = match.end()
    return result


def public_action_ledger(source):
    """Conservative concrete entry points, independent of scenario group claims.

    Scan every owned lib Dart file, including delegated widgets and platform
    variants, rather than selecting files/keys mentioned by tests. Named/cascade
    callbacks, individual menu/choice/navigation/slash/option descriptors, enum
    members, collection initializers, shortcut activators and raw key-handler
    branches all remain independently accountable.
    Internal forwarding and non-Linux variants are deliberately not excluded: a
    static scan cannot prove reachability or execution. No source token is a pass.
    """
    files, entries = {}, {}
    constructors = {'MenuItemButton', 'SubmenuButton', 'ChoiceChip', 'FilterChip',
                    'InputChip', 'ActionChip', 'RadioListTile', 'CheckboxListTile',
                    'NavigationDestination', 'NavigationRailDestination',
                    'AppShellDestination', 'ButtonSegment', '_LocalSlashCommand',
                    'SingleActivator', 'LogicalKeySet'}
    for path in sorted((source / 'lib').rglob('*.dart')):
        relative = str(path.relative_to(source))
        qa.plain_path(path)
        checksum = qa.digest(path)
        files[relative] = checksum
        text = path.read_text()
        tokens = dart_tokens(text)
        values = [t[0] for t in tokens]
        def add(index, kind, selector):
            offset = tokens[index][1]
            identity = f'{relative}:{offset}:{kind}'
            require(identity not in entries, 'Duplicate public action identity')
            entries[identity] = dict(
                source=dict(file=relative, line=text.count('\n', 0, offset) + 1,
                            offset=offset, kind=kind, selector=selector, sha256=checksum),
                cases=[], statuses=['coverage_gap'],
                reason='No case-level assertion bound to this concrete entry point; scenario groups are separate')
        # Enum-generated choices (e.g. Schedules' all/enabled/disabled) must
        # not collapse into the loop's single onSelected callback. Include all
        # enum members, even internal states, rather than guessing reachability.
        for index, value in enumerate(values[:-3]):
            if value != 'enum':
                continue
            name, start = values[index + 1], index + 2
            while start < len(values) and values[start] != '{': start += 1
            require(start < len(values), 'Unrecognized enum declaration')
            depth, member, end = 1, True, start + 1
            while end < len(values):
                item = values[end]
                if depth == 1 and item in (';', '}'):
                    break
                if depth == 1 and member and re.fullmatch(r'[A-Za-z_$][\w$]*', item):
                    add(end, 'enum-choice', name + '.' + item)
                    member = False
                if depth == 1 and item == ',': member = True
                depth += (item in ('(', '[', '{')) - (item in (')', ']', '}'))
                end += 1
            require(end < len(values), 'Unterminated enum declaration')
        for index, value in enumerate(values[:-1]):
            following = values[index + 1]
            if value in ('in', '='):
                start = index + 1 + (following == 'const')
                if start < len(values) and values[start] in ('[', '{'):
                    closing = ']' if values[start] == '[' else '}'
                    kind = 'literal-choice' if value == 'in' else 'collection-choice'
                    depth, first, end = 1, start + 1, start + 1
                    while end < len(values):
                        item = values[end]
                        if depth == 1 and item in (',', closing):
                            if end > first:
                                add(first, kind, ''.join(values[first:end]))
                            first = end + 1
                        depth += (item in ('(', '[', '{')) - (item in (')', ']', '}'))
                        if depth == 0: break
                        end += 1
                    require(end < len(values), 'Unterminated literal choices')
            if re.fullmatch(r'on[A-Z]\w*', value) and following in (':', '='):
                add(index, 'callback', value)
            if value == 'LogicalKeyboardKey' and following == '.' and index + 2 < len(values):
                add(index, 'key', values[index + 2])
            if value == 'case':
                end = index + 1
                while end < len(values) and values[end] not in (':', ')', '=>'): end += 1
                require(end < len(values), 'Unrecognized action dispatch branch')
                # Include if-case patterns conservatively as well as switch
                # branches; neither is evidence of operating a public control.
                add(index, 'dispatch', ' '.join(values[index + 1:end]))
            if value not in constructors and not value.endswith(('MenuItem', 'Option', 'Destination', 'Command')):
                continue
            start = index + 1
            if values[start] == '<':
                depth = 1
                start += 1
                while start < len(values) and depth:
                    depth += (values[start] == '<') - (values[start] == '>')
                    start += 1
            if start >= len(values) or values[start] != '(':
                continue
            # Constructor declarations are not entry points.
            if start + 1 < len(values) and values[start + 1] == '{':
                continue
            depth, end, selector = 1, start + 1, value
            while end < len(values) and depth:
                item = values[end]
                if depth == 1 and item in ('value', 'id', 'path', 'route', 'label') and values[end + 1] == ':':
                    first, last, nested = end + 2, end + 2, 0
                    while last < len(values):
                        part = values[last]
                        if nested == 0 and part in (',', ')'): break
                        nested += (part in ('(', '[', '{')) - (part in (')', ']', '}'))
                        last += 1
                    require(last < len(values) and last > first, 'Unrecognized action selector')
                    selector = ''.join(values[first:last])
                    break
                depth += (item in ('(', '[', '{')) - (item in (')', ']', '}'))
                end += 1
            require(end < len(values), 'Unrecognized action descriptor')
            add(index, 'descriptor', selector)
    require(files and entries, 'Empty public action source inventory')
    return dict(action_sources=files, actions=entries)


def validate_public_actions(report, source=SOURCE):
    expected = public_action_ledger(source)
    require(report.get('action_sources') == expected['action_sources'], 'Public action source inventory mismatch')
    actions = report.get('actions')
    require(isinstance(actions, dict) and set(actions) == set(expected['actions']),
            'Public action inventory mismatch')
    # Until an exact entry-point/case assertion binding is reviewed, a scenario
    # group's pass cannot upgrade any of its individual controls.
    for key, row in actions.items():
        require(row == expected['actions'][key], 'Public action source/disposition mismatch')


def build_report(root, source=SOURCE):
    current = qa.source_inputs(source)
    expected = expected_cases(source)
    cases, proofs = [], {}
    roots = evidence_roots(root)
    for lane in LANES:
        rows, proof = check_lane(lane, roots[lane], current, expected.get(lane, {}))
        cases.extend(rows)
        proofs[lane] = proof
    constants = (source / 'lib/router/routes/app_routes.dart').read_text()
    router = (source / 'lib/router/providers/app_router.dart').read_text()
    paths = dict(re.findall(r"static const (\w+) = '([^']+)';", constants))
    routes = ['/', *sorted({paths[name] for name in re.findall(r'path: AppRoutes\.(\w+)', router)})]
    matrix = qa.read_json(source / 'docs/product/hermes-desktop-feature-matrix.json')
    features = [f['id'] for f in matrix['features']]
    require(len(features) == len(set(features)) == 50, 'Changed matrix inventory')
    report = make_ledger(cases, features, routes, ACTION_CASES)
    report['action_groups'] = report.pop('actions')
    report.update(public_action_ledger(source))
    validate_public_actions(report, source)
    if any(row['statuses'] != ['pass'] for row in report['actions'].values()):
        report['fixture_verdict'] = 'PARTIAL'
    for feature, cell in report['features'].items():
        cell['pending_live_tasks'] = ['PARITY-NATIVE-LINUX-LIVE']
        if feature == 'HD-UPDATE':
            cell['pending_live_tasks'] = ['VERIFY-DESKTOP-NATIVE-DELIVERY']
        elif feature == 'HD-EXPORT':
            cell['pending_live_tasks'].append('PARITYGAP-002-76-LIVE')
        elif feature == 'HD-PROFILE':
            cell['pending_live_tasks'].append('VERIFY-PERSONA-LIVE-COMPATIBILITY')
        elif feature in ('HD-CHAT', 'HD-APPROVAL', 'HD-STOP', 'HD-RESUME', 'HD-CLARIFY', 'HD-QUEUE'):
            cell['pending_live_tasks'].extend(['PARITY-LIVE-WORKFLOW-LIVE', 'PARITYUPDATE-002-5c-LIVE'])
        elif feature == 'HD-SSH':
            cell['pending_live_tasks'].extend(['BACKEND-SSH-KEY-NATIVE-LIVE', 'DOC-NATIVE-FAILURE-BOUNDARY-LIVE', 'DOC-NATIVE-DESIGN-REVIEW-LIVE'])
        elif feature in ('HD-NATIVE', 'HD-ACCESS', 'HD-SHELL'):
            cell['pending_live_tasks'].append('VERIFY-SHELL-NATIVE-INPUT')
    report.update(schema=1, phase='fixture', evidence_kind='composed-source-equivalent-lane-receipts',
                  source_inputs_sha256=qa.identity(current), lanes=proofs, cases=cases,
                  retained_failures=retained_failures(root, roots),
                  aliases={'/': '/hermes', '/agents': '/profiles', 'AppRoutes.agents': '/profiles'},
                  route_evidence_scope='Declared journey context, not exhaustive router or alias qualification',
                  limitations=['Scenario action_groups are bounded subsets, not concrete control qualification. '
                               'The independent actions inventory conservatively scans all lib sources for callbacks, '
                               'descriptors, enum/collection choices, dispatch and keys, including forwarding and non-Linux variants. Entries without exact '
                               'case-level assertion bindings stay coverage_gap; static source is never runtime evidence.',
                               'Shared suite evidence retains mocked storage/input and is not native plugin qualification.'])
    return report


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--phase', required=True, choices=('fixture',))
    parser.add_argument('--input', required=True, type=Path)
    args = parser.parse_args(argv)
    root = None
    writable = False
    try:
        root = qa.plain_path(args.input)
        require(root.is_dir() and root.stat().st_uid == os.getuid() and not root.stat().st_mode & 0o077,
                'Owned private evidence directory required')
        writable = True
        report = build_report(root)
    except (OSError, ValueError, KeyError, TypeError, IndexError, AttributeError) as error:
        report = dict(schema=1, phase='fixture', fixture_verdict='INVALID',
                      overall_linux_verdict='PARTIAL', parity_met=False,
                      error=str(error) if isinstance(error, ValueError) else type(error).__name__)
        if writable:
            driver.atomic_json(root / 'qualification.json', report)
        print(json.dumps(report))
        return 2
    driver.atomic_json(root / 'qualification.json', report)
    print(json.dumps(dict(path=str(root / 'qualification.json'), sha256=qa.digest(root / 'qualification.json'),
                          fixture_verdict=report['fixture_verdict'], overall_linux_verdict='PARTIAL', parity_met=False)))
    return 0


if __name__ == '__main__':
    sys.exit(main())
