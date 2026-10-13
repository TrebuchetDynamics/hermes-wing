import assert from 'node:assert/strict';
import test from 'node:test';
import { existsSync, readFileSync, readdirSync, statSync, mkdtempSync, mkdirSync, writeFileSync, rmSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { execFileSync } from 'node:child_process';
import { tmpdir } from 'node:os';
import { fileURLToPath } from 'node:url';
import { artifactsByTarget, inputs, validateManifest } from '../../scripts/release_evidence.mjs';
import { platformJobs, releaseJobs } from '../../scripts/ci_gate.mjs';

const retired = ['wing_link', 'lib/core/wing_link', 'install-wing-link.sh', 'install-termux.sh',
  'assets/config/termux_bootstrap.json', 'integration_test/linux_live_directory_service_test.dart',
  'scripts/run_linux_live_directory_service_e2e.sh', 'scripts/run_linux_live_retained_security_service_e2e.sh',
  'scripts/record_linux_service_qualification.mjs'];
const deliveryRoots = ['.github', 'linux', 'scripts', 'pubspec.yaml', 'package.json'];
function files(path) {
  if (!existsSync(path)) return [];
  return statSync(path).isDirectory()
    ? readdirSync(path).flatMap(name => files(join(path, name))) : [path];
}
function violations(root) {
  const removed = retired.filter(name => files(join(root, name)).length > 0);
  const dependencies = deliveryRoots.flatMap(name => files(join(root, name)))
    .filter(path => /\.(?:mjs|py|sh|json|yaml|yml|txt)$/.test(path))
    .filter(path => /wing_link\/|install-wing-link\.sh|install-termux\.sh|wing-link-(?:release|linux|android|darwin|windows|directory)|WING_LINK_BUNDLE/.test(readFileSync(path, 'utf8')));
  return [...removed, ...dependencies];
}
test('no shipped service, installer, bootstrap, Go input, job or artifact remains', () => {
  assert.deepEqual(violations(fileURLToPath(new URL('../../', import.meta.url))), []);
  assert.deepEqual(Object.keys(artifactsByTarget), ['android', 'linux', 'web']);
  assert.deepEqual(inputs, ['pubspec.lock', 'package-lock.json']);
  assert.equal([...platformJobs, ...releaseJobs].some(name => /wing-link/.test(name)), false);
  assert.throws(() => validateManifest({ target: 'wing-link' }));
});
test('absence guard detects restored implementation and delivery dependencies', t => {
  const root = mkdtempSync(join(tmpdir(), 'link-retirement-'));
  t.after(() => rmSync(root, { recursive: true, force: true }));
  for (const [name, body] of [
    ['wing_link/main.go', 'package main'],
    ['lib/core/wing_link/client.dart', 'WingLinkClient()'],
    ['install-wing-link.sh', '#!/bin/sh'],
    ['assets/config/termux_bootstrap.json', '{}'],
    ['linux/CMakeLists.txt', 'set(WING_LINK_BUNDLE_BINARY wing-link)'],
    ['.github/workflows/release.yml', 'needs: wing-link-release'],
    ['scripts/native.py', "subprocess.run(['go', 'build'], cwd=app / 'wing_link/service')"],
    ['package.json', '{"scripts":{"setup":"./install-termux.sh"}}'],
  ]) {
    const path = join(root, name);
    mkdirSync(dirname(path), { recursive: true });
    writeFileSync(path, body);
    assert.notEqual(violations(root).length, 0, name);
    rmSync(path);
    assert.deepEqual(violations(root), []);
  }
});

test('archive guard accepts client bundles and rejects reintroduced management payloads', t => {
  const root = mkdtempSync(join(tmpdir(), 'retirement-archives-'));
  t.after(() => rmSync(root, { recursive: true, force: true }));
  const verifier = readFileSync(new URL('../../scripts/verify_release_artifacts.sh', import.meta.url), 'utf8');
  const extraction = verifier.match(/python3 - "\$dist" "\$temp_dir" <<'PY'\n([\s\S]*?)\nPY/)[1];
  const android = verifier.match(/python3 - "\$dist" <<'PY'\n([\s\S]*?)\nPY/)[1];
  for (const payload of ['', 'bundle/wing-link', 'bundle/lib/wing_link/service', 'termux_bootstrap.json']) {
    execFileSync('python3', ['-c', `
import io, pathlib, sys, tarfile, zipfile
root = pathlib.Path(sys.argv[1])
payload = sys.argv[2]
for name, entries in [('hermes-wing-linux-x64.tar.gz', ['bundle/wing']),
                      ('hermes-wing-web.tar.gz', ['index.html', 'main.dart.js', 'flutter_bootstrap.js'])]:
    with tarfile.open(root / name, 'w:gz') as archive:
        for entry in entries + ([payload] if payload else []):
            info = tarfile.TarInfo(entry)
            info.size = 1
            archive.addfile(info, io.BytesIO(b'x'))
for name in ['hermes-wing-android.apk', 'hermes-wing-android.aab']:
    with zipfile.ZipFile(root / name, 'w') as archive:
        archive.writestr('client', b'x')
        if payload: archive.writestr(payload, b'x')
`, root, payload]);
    const out = join(root, 'out');
    mkdirSync(out);
    if (payload) {
      assert.throws(() => execFileSync('python3', ['-c', extraction, root, out], { stdio: 'pipe' }), /retired management payload/);
      assert.throws(() => execFileSync('python3', ['-c', android, root], { stdio: 'pipe' }), /retired management payload/);
    } else {
      execFileSync('python3', ['-c', extraction, root, out]);
      execFileSync('python3', ['-c', android, root]);
    }
    rmSync(out, { recursive: true });
  }
});
