import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, mkdir, writeFile, readFile, readdir, lstat, rm, symlink } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
import { artifactsByTarget, inputs, createManifest, digest, qualificationIndex } from '../../scripts/release_evidence.mjs';

const execute = promisify(execFile);
const command = fileURLToPath(new URL('../../scripts/compare_release_candidate.mjs', import.meta.url));
const identity = { source_revision: 'a'.repeat(40), source_dirty: false, version: '0.1.0',
  build_number: '7', run_id: '12', run_attempt: '1', repository: 'example/wing', tag: 'v0.1.0-alpha.1' };
const certificate = 'c'.repeat(64);
const failure = 'Offline candidate comparison failed.\n';
const success = 'Offline candidate comparison matched. Signatures and runtime NOT_CHECKED.\n';

// Entirely synthetic bytes and receipt assertions; no observed release/platform evidence.
async function fixture(t) {
  const base = await mkdtemp(join(tmpdir(), 'wing-offline-comparison-'));
  t.after(() => rm(base, { recursive: true, force: true }));
  const root = join(base, 'source');
  const dist = join(base, 'public');
  await mkdir(dist);
  for (const name of [...inputs, 'assets/config/termux_bootstrap.json']) {
    await mkdir(dirname(join(root, name)), { recursive: true });
    await writeFile(join(root, name), `synthetic input ${name}`);
  }
  await writeFile(join(dist, 'android-termux-bootstrap.json'), await readFile(join(root, 'assets/config/termux_bootstrap.json')));
  const payloads = Object.values(artifactsByTarget).flat();
  for (const name of payloads) await writeFile(join(dist, name), `synthetic artifact ${name}`);
  for (const target of Object.keys(artifactsByTarget)) {
    const manifest = await createManifest(root, dist, target, identity,
      target === 'wing-link' ? { node: 'v22.0.0', go: 'go1.26.0' } : { node: 'v22.0.0', flutter: '3.44.2' },
      target === 'android' ? certificate : null);
    await writeFile(join(dist, `${target}-release-evidence.json`), JSON.stringify(manifest));
  }
  for (const [name, target, binary, result, evidence_kind, scenario] of [
    ['android-artifact-smoke.txt', 'android', 'hermes-wing-android.apk', 'verified-installed-launched', 'emulator', 'apk-install-launch'],
    ['wing-link-macos-smoke.txt', 'wing-link', 'wing-link-darwin-arm64', 'verified-ran-version', 'native', 'binary-version'],
    ['wing-link-windows-smoke.txt', 'wing-link', 'wing-link-windows-amd64.exe', 'verified-ran-version', 'native', 'binary-version'],
  ]) {
    const { tag, source_revision, run_id, run_attempt, build_number } = identity;
    const receipt = { tag, source_revision, run_id, run_attempt, build_number, binary,
      artifact_sha256: (await digest(join(dist, binary))).sha256,
      manifest_sha256: (await digest(join(dist, `${target}-release-evidence.json`))).sha256,
      result, evidence_kind, scenario, timestamp_utc: '2026-09-04T12:00:00Z' };
    await writeFile(join(dist, name), Object.entries(receipt).map(([k, v]) => `${k}=${v}`).join('\n') + '\n');
  }
  const auxiliary = ['android-termux-bootstrap.json', 'wing-link-checksums.sha256',
    ...Object.keys(artifactsByTarget).map(target => `${target}-release-evidence.json`),
    ...payloads.filter(name => name.startsWith('hermes-wing')).map(name => `${name}.sha256`)];
  for (const name of auxiliary.filter(name => name.endsWith('.sha256'))) await writeFile(join(dist, name), 'synthetic checksum declaration\n');
  const host = { schema_version: 1, tag: identity.tag, source_revision: identity.source_revision,
    verified_at: '2026-09-04T12:00:00Z', android_certificate_sha256: certificate,
    checks: ['exact_allowlist', 'sha256_sidecars', 'android_apk_signature', 'android_aab_signature',
      'archive_path_safety', 'linux_bundle_launch', 'web_browser_launch', 'wing_link_linux_amd64_version',
      'wing_link_linux_arm64_version', 'foreign_binary_formats'], artifacts: [] };
  for (const name of [...payloads, ...auxiliary]) {
    const { size, sha256 } = await digest(join(dist, name));
    host.artifacts.push({ name, bytes: size, sha256 });
  }
  await writeFile(join(dist, 'release-verification-receipt.json'), JSON.stringify(host));
  await writeFile(join(dist, 'release-qualification-index.json'), JSON.stringify(await qualificationIndex(root, dist, identity)));
  const { source_dirty, ...expected } = identity;
  const values = { 'source-root': root, 'candidate-dir': dist,
    ...Object.fromEntries(Object.entries(expected).map(([key, value]) => [key.replaceAll('_', '-'), value])),
    'android-certificate-sha256': certificate };
  return { base, root, dist, values };
}

async function snapshot(path) {
  const result = {};
  for (const name of (await readdir(path)).sort()) {
    const file = join(path, name);
    const info = await lstat(file);
    result[name] = info.isSymbolicLink() ? 'symlink' : info.isDirectory() ? await snapshot(file) : (await readFile(file)).toString('hex');
  }
  return result;
}
async function run(f, values = f.values, extra = [], expectedCode = 1) {
  const before = await snapshot(f.base);
  const args = [...Object.entries(values).flatMap(([key, value]) => [`--${key}`, value]), ...extra];
  let result;
  try {
    result = { ...await execute(process.execPath, [command, ...args], {
      cwd: f.base, timeout: 10000, maxBuffer: 4096,
      // No tools are discoverable; environment identity cannot supply expectations.
      env: { ...process.env, PATH: '', GITHUB_SHA: 'b'.repeat(40), TAG: 'v9.9.9-alpha.1',
        GITHUB_RUN_ID: '999', WING_RELEASE_CERT_SHA256: 'd'.repeat(64) },
    }), code: 0 };
  } catch (error) {
    if (typeof error.code !== 'number') throw error;
    result = error;
  }
  assert.equal(result.code, expectedCode);
  assert.equal(result.stdout, expectedCode === 0 ? success : '');
  assert.equal(result.stderr, expectedCode === 0 ? '' : failure);
  assert.deepEqual(await snapshot(f.base), before, 'comparison must not mutate source or candidate tree');
}

test('explicit complete expectations match; environment and cwd cannot infer identity', async t => {
  const f = await fixture(t);
  await run(f, f.values, [], 0);
  // Source bootstrap is not a verifier input: the generated public copy is authoritative here.
  await rm(join(f.root, 'assets'), { recursive: true });
  await run(f, f.values, [], 0);
});
for (const key of ['source-root', 'candidate-dir', 'source-revision', 'tag', 'version', 'build-number', 'run-id', 'run-attempt', 'repository', 'android-certificate-sha256']) {
  test(`omitted argument fails closed: ${key}`, async t => {
    const f = await fixture(t);
    const values = { ...f.values }; delete values[key];
    await run(f, values);
  });
}
for (const [key, value] of Object.entries({ 'source-revision': 'b'.repeat(40), tag: 'v0.1.0-alpha.2',
  version: '0.1.1', 'build-number': '8', 'run-id': '13', 'run-attempt': '2', repository: 'example/other',
  'android-certificate-sha256': 'd'.repeat(64) })) {
  test(`independent expectation disagreement fails: ${key}`, async t => {
    const f = await fixture(t);
    const values = { ...f.values, [key]: value };
    if (key === 'version') values.tag = 'v0.1.1-alpha.1';
    await run(f, values);
  });
}
for (const [key, value] of Object.entries({ 'source-revision': 'A'.repeat(40), tag: 'other', version: 'other',
  'build-number': '-1', 'run-id': '1.0', 'run-attempt': '1'.repeat(21), repository: '../private',
  'android-certificate-sha256': 'not-a-certificate', 'source-root': '', 'candidate-dir': '\nprivate' })) {
  test(`malformed argument fails with redacted output: ${key}`, async t => {
    const f = await fixture(t);
    await run(f, { ...f.values, [key]: value });
  });
}
test('unknown, duplicate, positional, oversized and empty arguments fail', async t => {
  const f = await fixture(t);
  for (const extra of [['--unknown', 'private-content'], ['--tag', identity.tag], ['private-content'], ['--tag'], ['--tag', 'x'.repeat(4097)]]) {
    await run(f, f.values, extra);
  }
  await run(f, {});
  const values = { ...f.values }; delete values.repository; values.unknown = 'private-content';
  await run(f, values);
  delete values.unknown;
  await run(f, values, ['--tag', identity.tag]);
});
for (const name of [...inputs, 'android-termux-bootstrap.json', ...Object.values(artifactsByTarget).flat(), 'wing-link-checksums.sha256']) {
  test(`same-size byte mutation fails: ${name}`, async t => {
    const f = await fixture(t);
    const path = join(inputs.includes(name) ? f.root : f.dist, name);
    const bytes = await readFile(path); bytes[0] ^= 1;
    await writeFile(path, bytes);
    await run(f);
  });
}
for (const name of ['release-qualification-index.json', 'android-artifact-smoke.txt', 'wing-link-macos-smoke.txt',
  'wing-link-windows-smoke.txt', 'release-verification-receipt.json']) {
  test(`missing required evidence fails: ${name}`, async t => {
    const f = await fixture(t);
    await rm(join(f.dist, name));
    await run(f);
  });
}
for (const change of [index => { index.identity.run_attempt = '2'; }, index => { index.artifacts[0].sha256 = 'e'.repeat(64); },
  index => { index.untrusted = 'private-content'; }, index => { index.receipts.pop(); }]) {
  test('altered published index fails deep comparison', async t => {
    const f = await fixture(t);
    const path = join(f.dist, 'release-qualification-index.json');
    const index = JSON.parse(await readFile(path, 'utf8')); change(index);
    await writeFile(path, JSON.stringify(index));
    await run(f);
  });
}
test('malformed and oversized JSON and receipt reads fail without content leakage', async t => {
  const f = await fixture(t);
  for (const name of ['release-qualification-index.json', 'android-release-evidence.json', 'release-verification-receipt.json', 'android-artifact-smoke.txt']) {
    const path = join(f.dist, name);
    const original = await readFile(path);
    for (const bytes of ['private-content not JSON', 'x'.repeat(name.endsWith('.txt') ? 8193 : 128 * 1024 + 1)]) {
      await writeFile(path, bytes);
      await run(f);
    }
    await writeFile(path, original);
  }
});
for (const [name, change] of [
  ['android-release-evidence.json', value => { value.identity.run_attempt = '2'; }],
  ['linux-release-evidence.json', value => { value.target = 'web'; }],
  ['web-release-evidence.json', value => { value.private_content = 'redacted'; }],
  ['release-verification-receipt.json', value => { value.checks.pop(); }],
  ['release-verification-receipt.json', value => { value.android_certificate_sha256 = 'd'.repeat(64); }],
]) {
  test(`altered manifest or host contract fails: ${name}`, async t => {
    const f = await fixture(t);
    const path = join(f.dist, name);
    const value = JSON.parse(await readFile(path, 'utf8')); change(value);
    await writeFile(path, JSON.stringify(value));
    await run(f);
  });
}
test('false Android physical receipt claim fails', async t => {
  const f = await fixture(t);
  const path = join(f.dist, 'android-artifact-smoke.txt');
  await writeFile(path, (await readFile(path, 'utf8')).replace('evidence_kind=emulator', 'evidence_kind=physical'));
  await run(f);
});
test('published index comparison is semantic, not JSON whitespace or object-key order', async t => {
  const f = await fixture(t);
  const path = join(f.dist, 'release-qualification-index.json');
  const index = JSON.parse(await readFile(path, 'utf8'));
  await writeFile(path, JSON.stringify(Object.fromEntries(Object.entries(index).reverse()), null, 2));
  await run(f, f.values, [], 0);
});
test('symlink files, parent directories and declared roots fail', async t => {
  const f = await fixture(t);
  const path = join(f.dist, 'hermes-wing-web.tar.gz');
  const bytes = await readFile(path);
  await writeFile(join(f.base, 'external'), bytes);
  await rm(path); await symlink(join(f.base, 'external'), path);
  await run(f);
  await rm(path); await writeFile(path, bytes);
  await symlink(f.dist, join(f.base, 'alias'));
  await run(f, { ...f.values, 'candidate-dir': join(f.base, 'alias') });
  await symlink(f.root, join(f.base, 'source-alias'));
  await run(f, { ...f.values, 'source-root': join(f.base, 'source-alias') });
  await mkdir(join(f.base, 'locks'));
  for (const name of ['go.mod', 'go.sum']) await writeFile(join(f.base, 'locks', name), await readFile(join(f.root, 'wing_link', name)));
  await rm(join(f.root, 'wing_link'), { recursive: true });
  await symlink(join(f.base, 'locks'), join(f.root, 'wing_link'));
  await run(f);
});
