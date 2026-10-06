#!/usr/bin/env python3
"""Offline actual-source refusal, external-consumer and isolated mutation probes."""
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
EVIDENCE = ROOT / '.task-evidence/t_41606eec'
SOURCES = [
    'integration_test/hermes_m2_observer_main.dart',
    'integration_test/support/m2_observer.dart',
    'integration_test/support/m2_metadata.dart',
    'test/tooling/m2_bootstrap_test.dart',
    'test/tooling/m2_observer_test.dart',
    'test/tooling/m2_receipt_admission_test.dart',
    'test/tooling/support/m2_fake_harness.dart',
    'test/tooling/support/m2_diagnostic_writer.dart',
    'test/tooling/support/m2_observer_cases.dart',
    'test/tooling/support/m2_receipt_admission_cases.dart',
    'test/tooling/support/m2_bootstrap_probe.dart.template',
]
RECEIPTS = []


def fingerprint():
    return {s: hashlib.sha256((ROOT / s).read_bytes()).hexdigest() for s in SOURCES}


def run(cwd, args, label, expected=0, discriminator=None):
    proc = subprocess.run(args, cwd=cwd, text=True, capture_output=True)
    text = proc.stdout + proc.stderr
    (EVIDENCE / (label + '.log')).write_text(text)
    RECEIPTS.append({'label': label, 'command': ' '.join(args),
                     'cwd': str(cwd), 'exit': proc.returncode,
                     'expected_exit': expected, 'discriminator': discriminator})
    print(f'{label}: exit={proc.returncode}', flush=True)
    if proc.returncode != expected:
        raise AssertionError(f'{label}: unexpected exit\n{text}')
    if discriminator and discriminator not in text:
        raise AssertionError(f'{label}: missing invariant {discriminator}\n{text}')
    return text


def mirror(base):
    for source in SOURCES:
        dest = base / source
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(ROOT / source, dest)
    # The original resolved package configuration keeps all actual dependency
    # imports resolvable. No package install, plugin, product graph or network.
    from urllib.parse import urljoin
    tool = base / '.dart_tool'
    tool.mkdir()
    origin = ROOT / '.dart_tool/package_config.json'
    config = json.loads(origin.read_text())
    for package in config['packages']:
        package['rootUri'] = urljoin(origin.as_uri(), package['rootUri'])
    config['packages'].append({'name': 'm2_probe', 'rootUri': base.as_uri() + '/',
                               'packageUri': './', 'languageVersion': '3.12'})
    (tool / 'package_config.json').write_text(json.dumps(config))
    shutil.copyfile(ROOT / '.dart_tool/package_graph.json', tool / 'package_graph.json')
    (base / 'assets').symlink_to(ROOT / 'assets', target_is_directory=True)
    shutil.copyfile(ROOT / 'pubspec.yaml', base / 'pubspec.yaml')
    return base


def bootstrap_probe(base):
    support = base / SOURCES[1]
    original = support.read_text()
    support.write_text(original.replace(
        "export 'm2_metadata.dart';",
        "import 'dart:async';\nexport 'm2_metadata.dart';\n"
        "part '../../test/tooling/support/m2_bootstrap_probe.dart';"))
    shutil.copyfile(base / SOURCES[-1],
                    base / 'test/tooling/support/m2_bootstrap_probe.dart')
    test = base / 'test/tooling/private_bootstrap_test.dart'
    test.write_text("import 'package:flutter_test/flutter_test.dart';\n"
                    "import '../../integration_test/support/m2_observer.dart';\n"
                    "void main() { test('REG-DEFAULT boundary counters', verifyPrivateBootstrap); }\n")
    return test


NEGATIVE = {
    'raw_sink': ("M2SecureSink('a', 'b');", 'M2SecureSink', 'UNDEFINED_FUNCTION'),
    'sink_io': ("M2Sink sink; sink.read(); sink.write('x');", 'M2Sink', 'UNDEFINED_CLASS'),
    'journal': ("M2Journal(attempt: 'a', generation: 'b', sink: Object());", 'M2Journal', 'UNDEFINED_FUNCTION'),
    'journal_sink': ("M2Journal journal; journal.sink.read();", 'M2Journal', 'UNDEFINED_CLASS'),
    'observer': ("M2StoreObserver(delegate: Object(), journal: Object());", 'M2StoreObserver', 'UNDEFINED_FUNCTION'),
    'app': ("M2ObserverApp(journal: Object());", 'M2ObserverApp', 'UNDEFINED_FUNCTION'),
    'authority': ("m2Bootstrap(authority: Object());", 'authority', 'UNDEFINED_NAMED_PARAMETER'),
    'journal_input': ("m2Bootstrap(journal: Object());", 'journal', 'UNDEFINED_NAMED_PARAMETER'),
    'sink_input': ("m2Bootstrap(sink: Object());", 'sink', 'UNDEFINED_NAMED_PARAMETER'),
    'provider_input': ("m2Bootstrap(overrides: []);", 'overrides', 'UNDEFINED_NAMED_PARAMETER'),
    'fake_selector': ("m2Bootstrap(fake: true);", 'fake', 'UNDEFINED_NAMED_PARAMETER'),
    'main_input': ("qa.main(authority: Object());", 'authority', 'UNDEFINED_NAMED_PARAMETER'),
    'fake_journal': ("_M2Journal(attempt: 'a', generation: 'b', sink: Object());", '_M2Journal', 'UNDEFINED_FUNCTION'),
    'fake_sink': ("_M2Sink sink; sink.read();", '_M2Sink', 'UNDEFINED_CLASS'),
    'runtime_boundary': ("_UnavailableRuntime();", '_UnavailableRuntime', 'UNDEFINED_FUNCTION'),
}


def consumer(base, route, name, body):
    dest = base / f'consumer_{route}_{name}.dart'
    # Barrel tests real export resolution. File URI tests the exact resolved
    # source; package URI intentionally follows Wing's configured package root.
    routes = {
        'relative': 'integration_test/support/m2_observer.dart',
        'resolved': (base / SOURCES[1]).as_uri(),
        'export': 'public_barrel.dart',
        'package': 'package:m2_probe/integration_test/support/m2_observer.dart',
    }
    (base / 'public_barrel.dart').write_text(
        "export 'integration_test/support/m2_observer.dart';\n")
    dest.write_text("// ignore_for_file: unused_import\n"
                    f"import '{routes[route]}';\n"
                    "import 'integration_test/hermes_m2_observer_main.dart' as qa;\n"
                    "import 'test/tooling/support/m2_fake_harness.dart';\n"
                    f'void main() {{ {body} }}\n')
    return dest


def compile_probe(base, route, name, body, member, code, prefix=''):
    dest = consumer(base, route, name, body)
    output = run(base, ['dart', 'analyze', '--format=machine', str(dest)],
                 f'{prefix}api-{route}-{name}', expected=3, discriminator=code)
    errors = [line for line in output.splitlines() if line.startswith('ERROR|')]
    assert errors and all(code in line and member in line for line in errors), errors
    assert 'URI_DOES_NOT_EXIST' not in output, output


def closure():
    # Trace every literal branch of import/export/part (including conditional
    # directive alternatives), resolving relative, file and package URIs.
    config = json.loads((ROOT / '.dart_tool/package_config.json').read_text())
    from urllib.parse import urljoin, urlparse, unquote
    packages = {}
    config_uri = (ROOT / '.dart_tool/package_config.json').as_uri()
    for package in config['packages']:
        packages[package['name']] = urljoin(
            urljoin(config_uri, package['rootUri']).rstrip('/') + '/',
            package.get('packageUri', ''))
    edges = []
    pending = [ROOT / SOURCES[0]]
    visited = set()
    while pending:
        source = pending.pop().resolve()
        if source in visited:
            continue
        visited.add(source)
        content = source.read_text()
        for directive in re.findall(r'(?m)^\s*(?:import|export|part)\s+[^;]+;', content):
            for uri in re.findall(r"['\"]([^'\"]+)['\"]", directive):
                if uri.startswith('dart:'):
                    edges.append([str(source.relative_to(ROOT)), uri, 'stdlib'])
                    continue
                if uri.startswith('package:'):
                    package, path = uri[8:].split('/', 1)
                    target = Path(unquote(urlparse(urljoin(packages[package], path)).path))
                elif uri.startswith('file:'):
                    target = Path(unquote(urlparse(uri).path))
                else:
                    target = source.parent / uri
                target = target.resolve()
                assert target.exists(), (source, uri)
                local = target.is_relative_to(ROOT)
                edges.append([str(source.relative_to(ROOT)), uri,
                              str(target.relative_to(ROOT)) if local else 'resolved dependency'])
                if local:
                    pending.append(target)
    actual = {str(path.relative_to(ROOT)) for path in visited}
    assert actual == set(SOURCES[:3]), actual
    # No binding/store/channel/plugin/launch/test-support dependency is delivered.
    runtime = '\n'.join((ROOT / path).read_text() for path in SOURCES[:3])
    for forbidden in ['FlutterSecureStorage', 'runApp(', 'ensureInitialized(',
                      'M2Journal(', 'M2SecureSink(', 'M2StoreObserver(',
                      'HermesApiChannel(', 'ProviderScope(', 'registerM2']:
        assert forbidden not in runtime, forbidden
    return {'runtime_local_closure': sorted(actual), 'resolved_edges': edges,
            'parts': ['test-only m2_fake_harness: three private diagnostic parts'],
            'factory_contract': 'No runtime graph or storage factory exists; private boundary launch is unavailable.'}


def discovery():
    roots = ['lib', 'test', 'integration_test', 'scripts', 'android', 'ios',
             'linux', 'macos', 'windows', 'web', '.github', 'playwright']
    skip = {'build', '.dart_tool', '.gradle', 'ephemeral', 'Pods', 'node_modules',
            'vendor', 'third_party', 'tools', '.git'}
    pattern = re.compile(r'M2(?:SecureSink|Sink|Journal|StoreObserver|ObserverApp)|m2_observer|hermes_m2_observer|m2Bootstrap')
    hits, edges, fingerprints = [], [], {}
    for directory in roots:
        for path in sorted((ROOT / directory).rglob('*.dart')):
            if path.is_symlink() or skip.intersection(path.relative_to(ROOT).parts):
                continue
            source = str(path.relative_to(ROOT))
            text = path.read_text()
            fingerprints[source] = hashlib.sha256(path.read_bytes()).hexdigest()
            for line, content in enumerate(text.splitlines(), 1):
                if pattern.search(content):
                    hits.append({'source': source, 'line': line})
            for directive in re.findall(r'(?m)^\s*(?:import|export|part)\s+[^;]+;', text):
                for uri in re.findall(r"['\"]([^'\"]+)['\"]", directive):
                    if uri.startswith('package:wing/'):
                        target = ROOT / 'lib' / uri[len('package:wing/'):]
                    elif not uri.startswith(('package:', 'dart:')):
                        target = path.parent / uri
                    else:
                        continue
                    target = target.resolve()
                    assert target.is_relative_to(ROOT) and target.is_file(), (source, uri)
                    edges.append({'source': source, 'uri': uri,
                                  'target': str(target.relative_to(ROOT))})
    implicated = {hit['source'] for hit in hits}
    assert implicated <= set(SOURCES), implicated - set(SOURCES)
    relevant = [edge for edge in edges
                if edge['source'] in SOURCES or edge['target'] in SOURCES]
    # Neither a product import nor an export/part barrel may reopen QA runtime.
    for edge in relevant:
        if edge['target'] in SOURCES:
            assert edge['source'] in SOURCES, edge
    return {'roots': roots, 'dart_files_scanned': len(fingerprints),
            'manifest': fingerprints, 'matching_callers': hits,
            'incoming_and_support_directives': relevant,
            'scope': 'All literal conditional branches and relative/package:wing paths; no reflection or packaging proof.'}


def main():
    EVIDENCE.mkdir(parents=True, exist_ok=True)
    before = fingerprint()
    source_closure = closure()
    source_discovery = discovery()
    scratch = os.environ.get('TMPDIR')
    assert scratch, 'Use the configured profile scratch directory'
    with tempfile.TemporaryDirectory(prefix='m2-refusal-', dir=scratch) as directory:
        root = Path(directory)
        clean = mirror(root / 'clean')
        probe = bootstrap_probe(clean)
        run(clean, ['flutter', 'test', '--no-pub', str(probe)], 'boundary-green')
        for route in ['relative', 'resolved', 'export', 'package']:
            positive = consumer(clean, route, 'positive',
                                "final v = M2Validator(attempt: m2RandomAlias(), generation: m2RandomAlias()); "
                                "M2Validator.freeze({'phase': M2Phase.availability.name}); "
                                "m2Bootstrap(); qa.main(); print(v.attempt);")
            run(clean, ['dart', 'analyze', '--format=machine', str(positive)],
                f'api-{route}-positive')
            for name, (body, member, code) in NEGATIVE.items():
                compile_probe(clean, route, name, body, member, code)
        gate = mirror(root / 'gate')
        test = bootstrap_probe(gate)
        path = gate / SOURCES[1]
        path.write_text(path.read_text().replace(
            'if (!runtime.admitted) return const M2BootstrapResult._();', ''))
        run(gate, ['flutter', 'test', '--no-pub', str(test)], 'mutation-gate',
            expected=1, discriminator='REG-DEFAULT construction/start/I/O/launch')
        reopened = mirror(root / 'reopened')
        path = reopened / SOURCES[1]
        path.write_text(path.read_text() + '\nclass M2SecureSink { M2SecureSink(String a, String b); }\n')
        try:
            compile_probe(reopened, 'relative', 'raw_sink', *NEGATIVE['raw_sink'],
                          prefix='mutation-constructor-')
        except AssertionError as error:
            assert 'unexpected exit' in str(error), error
            RECEIPTS.append({'label': 'mutation-constructor', 'invariant': 'raw_sink must not compile',
                             'result': 'detected: reopened constructor compiled'})
        else:
            raise AssertionError('REG-API missed reopened constructor')
        foreign = mirror(root / 'foreign')
        path = foreign / 'test/tooling/support/m2_receipt_admission_cases.dart'
        text = path.read_text()
        start = text.index('  void _check() {')
        end = text.index('\n  @override', start)
        path.write_text(text[:start] + '  void _check() {}\n' + text[end:])
        run(foreign, ['flutter', 'test', '--no-pub',
                     'test/tooling/m2_receipt_admission_test.dart',
                     '--plain-name', 'REG-INJECTION: foreign writer'],
            'mutation-foreign', expected=1,
            discriminator='REG-INJECTION foreign writer reached fake I/O')
    after = fingerprint()
    assert before == after, 'Original sources changed during isolated probes'
    # All destructive mutation writes happened in disposable mirrors only.
    run(ROOT, ['flutter', 'test', '--concurrency=1',
               'test/tooling/m2_bootstrap_test.dart',
               'test/tooling/m2_observer_test.dart',
               'test/tooling/m2_receipt_admission_test.dart'], 'restored-green')
    (EVIDENCE / 'probes.json').write_text(json.dumps({
        'checks': RECEIPTS, 'before': before, 'after': after,
        'source_closure': source_closure, 'original_sources_unchanged': True,
        'discovery': source_discovery,
        'negative_consumers': len(NEGATIVE) * 4, 'positive_consumers': 4,
        'limits': 'Source-level Linux only. Installed/storage/Android/cross-process/history/count/live NOT_CHECKED.',
    }, indent=2) + '\n')
    print('PASS: original sources unchanged; final tooling suite GREEN', flush=True)


if __name__ == '__main__':
    main()
