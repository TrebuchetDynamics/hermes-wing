import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, mkdir, writeFile, rm, symlink, readFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { artifactsByTarget, inputs, createManifest, verifyManifest, digest, qualificationIndex, readJson, main } from '../../scripts/release_evidence.mjs';

const identity = { source_revision: 'a'.repeat(40), source_dirty: false, version: '0.1.0',
  build_number: '7', run_id: '12', run_attempt: '1', repository: 'example/wing', tag: 'v0.1.0-alpha.1' };
async function fixture(t, target = 'android') {
  const root = await mkdtemp(join(tmpdir(), 'wing-evidence-'));
  t.after(() => rm(root, { recursive: true, force: true }));
  for (const name of [...inputs, 'assets/config/termux_bootstrap.json', ...artifactsByTarget[target]]) {
    await mkdir(dirname(join(root, name)), { recursive: true });
    await writeFile(join(root, name), `synthetic bytes for ${name}`);
  }
  await writeFile(join(root, 'android-termux-bootstrap.json'), await readFile(join(root, 'assets/config/termux_bootstrap.json')));
  const manifest = await createManifest(root, root, target, identity, { node: 'v22.0.0', flutter: '3.44.2' }, target === 'android' ? 'c'.repeat(64) : null);
  // Exercise emitted JSON, not object identity or source-text assertions.
  const path = join(root, 'release-evidence.json');
  await writeFile(path, JSON.stringify(manifest));
  return { root, manifest: JSON.parse(await readFile(path, 'utf8')) };
}
test('emitted manifest verifies exact artifact and input bytes', async t => {
  const { root, manifest } = await fixture(t);
  await verifyManifest(manifest, root, root, identity, 'android');
});
for (const name of ['hermes-wing-android.apk', 'pubspec.lock', 'android-termux-bootstrap.json']) {
  test(`changed bytes fail: ${name}`, async t => {
    const { root, manifest } = await fixture(t);
    const bytes = await readFile(join(root, name)); bytes[0] ^= 1;
    await writeFile(join(root, name), bytes);
    await assert.rejects(verifyManifest(manifest, root, root, identity, 'android'), /mismatch/);
  });
}
for (const [name, change] of Object.entries({
  schema: m => { m.schema_version = 2; },
  revision: m => { m.identity.source_revision = 'b'.repeat(40); },
  build: m => { m.identity.build_number = '8'; },
  inputHash: m => { m.inputs['pubspec.lock'].sha256 = 'b'.repeat(64); },
  missingInput: m => { delete m.inputs['wing_link/go.sum']; },
  malformedHash: m => { m.artifacts[0].sha256 = 'not-a-hash'; },
  duplicate: m => { m.artifacts[1] = m.artifacts[0]; },
  traversal: m => { m.artifacts[0].name = '../hermes-wing-android.apk'; },
  extraField: m => { m.private_endpoint = 'redacted'; },
  target: m => { m.target = 'web'; },
})) {
  test(`reject ${name}`, async t => {
    const { root, manifest } = await fixture(t); change(manifest);
    await assert.rejects(verifyManifest(manifest, root, root, identity, 'android'));
  });
}
test('reject symlinks and missing artifacts', async t => {
  const { root, manifest } = await fixture(t);
  const path = join(root, 'hermes-wing-android.apk');
  await rm(path);
  await assert.rejects(verifyManifest(manifest, root, root, identity, 'android'));
  await symlink(join(root, 'hermes-wing-android.aab'), path);
  await assert.rejects(verifyManifest(manifest, root, root, identity, 'android'), /file type/);
});

async function qualificationFixture(t) {
  const { root } = await fixture(t);
  for (const [target, names] of Object.entries(artifactsByTarget)) {
    for (const name of names) await writeFile(join(root, name), `synthetic ${name}`);
    const manifest = await createManifest(root, root, target, identity,
      target === 'wing-link' ? { node: 'v22.0.0', go: 'go1.26.0' } : { node: 'v22.0.0', flutter: '3.44.2' }, target === 'android' ? 'c'.repeat(64) : null);
    await writeFile(join(root, `${target}-release-evidence.json`), JSON.stringify(manifest));
  }
  for (const [name, target, binary, result, evidence_kind, scenario] of [
    ['android-artifact-smoke.txt', 'android', 'hermes-wing-android.apk', 'verified-installed-launched', 'emulator', 'apk-install-launch'],
    ['wing-link-macos-smoke.txt', 'wing-link', 'wing-link-darwin-arm64', 'verified-ran-version', 'native', 'binary-version'],
    ['wing-link-windows-smoke.txt', 'wing-link', 'wing-link-windows-amd64.exe', 'verified-ran-version', 'native', 'binary-version'],
  ]) {
    const { tag, source_revision, run_id, run_attempt, build_number } = identity;
    const receipt = { tag, source_revision, run_id, run_attempt, build_number, binary,
      artifact_sha256: (await digest(join(root, binary))).sha256,
      manifest_sha256: (await digest(join(root, `${target}-release-evidence.json`))).sha256,
      result, evidence_kind, scenario, timestamp_utc: '2026-09-04T12:00:00Z' };
    await writeFile(join(root, name), Object.entries(receipt).map(([k, v]) => `${k}=${v}`).join('\n') + '\n');
  }
  const payloads = Object.values(artifactsByTarget).flat();
  const sidecars = ['wing-link-checksums.sha256', ...payloads.filter(name => name.startsWith('hermes-wing')).map(name => `${name}.sha256`)];
  for (const name of sidecars) await writeFile(join(root, name), 'synthetic checksum sidecar\n');
  const files = [...payloads, ...sidecars, 'android-termux-bootstrap.json', ...Object.keys(artifactsByTarget).map(target => `${target}-release-evidence.json`)];
  const host = { schema_version: 1, tag: identity.tag, source_revision: identity.source_revision,
    verified_at: '2026-09-04T12:00:00Z', android_certificate_sha256: 'c'.repeat(64),
    checks: ['exact_allowlist', 'sha256_sidecars', 'android_apk_signature', 'android_aab_signature',
      'archive_path_safety', 'linux_bundle_launch', 'web_browser_launch', 'wing_link_linux_amd64_version',
      'wing_link_linux_arm64_version', 'foreign_binary_formats'], artifacts: [] };
  for (const name of files) { const { size, sha256 } = await digest(join(root, name)); host.artifacts.push({ name, bytes: size, sha256 }); }
  await writeFile(join(root, 'release-verification-receipt.json'), JSON.stringify(host));
  return root;
}
test('final index binds every manifest, artifact, and required receipt', async t => {
  const root = await qualificationFixture(t);
  const index = await qualificationIndex(root, root, identity);
  assert.equal(Object.keys(index.manifests).length, 4);
  assert.equal(index.artifacts.length, 10);
  assert.equal(index.receipts.length, 4);
  for (const receipt of index.receipts) assert.deepEqual(
    { size: receipt.size, sha256: receipt.sha256 }, await digest(join(root, receipt.name)));
});
for (const [name, change] of Object.entries({
  absentDigest: s => s.replace(/^artifact_sha256=.*\n/m, ''),
  wrongArtifact: s => s.replace(/^artifact_sha256=.*/m, `artifact_sha256=${'b'.repeat(64)}`),
  otherRevision: s => s.replace(/^source_revision=.*/m, `source_revision=${'b'.repeat(40)}`),
  otherBuild: s => s.replace(/^build_number=.*/m, 'build_number=8'),
  otherAttempt: s => s.replace(/^run_attempt=.*/m, 'run_attempt=2'),
  falsePhysicalClaim: s => s.replace('evidence_kind=emulator', 'evidence_kind=physical'),
  aabClaim: s => s.replace('binary=hermes-wing-android.apk', 'binary=hermes-wing-android.aab'),
  duplicateField: s => s + 'scenario=apk-install-launch\n',
  failed: s => s.replace('result=verified-installed-launched', 'result=failed'),
})) {
  test(`final index rejects receipt ${name}`, async t => {
    const root = await qualificationFixture(t);
    const path = join(root, 'android-artifact-smoke.txt');
    await writeFile(path, change(await readFile(path, 'utf8')));
    await assert.rejects(qualificationIndex(root, root, identity));
  });
}
test('final index rejects missing required receipts', async t => {
  const root = await qualificationFixture(t);
  await rm(join(root, 'wing-link-macos-smoke.txt'));
  await assert.rejects(qualificationIndex(root, root, identity));
});

// These are synthetic comparison fixtures, never observed platform qualification.
test('offline admission round-trips the index and independently hashes its file bindings', async t => {
  const root = await qualificationFixture(t);
  const indexPath = join(root, 'synthetic-qualification-index.json');
  await writeFile(indexPath, JSON.stringify(await qualificationIndex(root, root, identity)));
  const index = await readJson(indexPath);
  const { source_dirty, ...expected } = identity;
  assert.deepEqual(index.identity, expected);
  assert.deepEqual(index, await qualificationIndex(root, root, expected));
  for (const [name, binding] of Object.entries(index.manifests)) {
    assert.deepEqual(binding, await digest(join(root, name)));
  }
  for (const { name, size, sha256 } of [...index.artifacts, ...index.receipts]) {
    assert.deepEqual({ size, sha256 }, await digest(join(root, name)));
  }
  for (const [name, binding] of Object.entries(index.inputs)) {
    assert.deepEqual(binding, await digest(join(root, name)));
  }
  for (const { name, bytes, sha256 } of index.auxiliary) {
    assert.deepEqual({ size: bytes, sha256 }, await digest(join(root, name)));
  }
});

for (const [key, changed] of Object.entries({
  source_revision: 'b'.repeat(40), tag: 'v0.1.0-alpha.2', version: '0.1.1',
  build_number: '8', run_id: '13', run_attempt: '2', repository: 'example/other',
})) {
  test(`offline admission rejects independently changed expected ${key}`, async t => {
    const root = await qualificationFixture(t);
    const manifest = await readJson(join(root, 'android-release-evidence.json'));
    const expected = { ...identity, [key]: changed };
    const error = { message: `identity mismatch: ${key}` };
    await assert.rejects(verifyManifest(manifest, root, root, expected, 'android'), error);
    await assert.rejects(qualificationIndex(root, root, expected), error);
  });
}

for (const name of [...inputs, 'android-termux-bootstrap.json', ...Object.values(artifactsByTarget).flat()]) {
  test(`offline admission rejects same-size changed bytes: ${name}`, async t => {
    const root = await qualificationFixture(t);
    const path = join(root, name);
    const before = await digest(path);
    const bytes = await readFile(path);
    bytes[0] ^= 1;
    await writeFile(path, bytes);
    const after = await digest(path);
    assert.equal(after.size, before.size);
    assert.notEqual(after.sha256, before.sha256);
    const stage = inputs.includes(name) || name === 'android-termux-bootstrap.json' ? 'input' : 'artifact';
    const binding = name === 'android-termux-bootstrap.json' ? 'assets/config/termux_bootstrap.json' : name;
    await assert.rejects(qualificationIndex(root, root, identity), { message: `${stage} mismatch: ${binding}` });
  });
}

for (const name of ['android-artifact-smoke.txt', 'wing-link-macos-smoke.txt',
  'wing-link-windows-smoke.txt', 'release-verification-receipt.json']) {
  test(`offline admission rejects missing named receipt: ${name}`, async t => {
    const root = await qualificationFixture(t);
    await rm(join(root, name));
    await assert.rejects(qualificationIndex(root, root, identity), error => {
      assert.equal(error.code, 'ENOENT');
      assert.equal(error.path, join(root, name));
      return true;
    });
  });
}

test('offline admission rejects host certificate disagreement and incomplete host checks', async t => {
  const root = await qualificationFixture(t);
  const path = join(root, 'release-verification-receipt.json');
  const host = await readJson(path);
  await writeFile(path, JSON.stringify({ ...host, android_certificate_sha256: 'd'.repeat(64) }));
  await assert.rejects(qualificationIndex(root, root, identity), { message: 'host receipt identity mismatch' });
  await writeFile(path, JSON.stringify({ ...host, checks: host.checks.slice(1) }));
  await assert.rejects(qualificationIndex(root, root, identity), { message: 'host checks incomplete' });
});

test('offline admission rejects altered auxiliary bytes at the host receipt stage', async t => {
  const root = await qualificationFixture(t);
  await writeFile(join(root, 'wing-link-checksums.sha256'), 'changed synthetic checksum sidecar\n');
  await assert.rejects(qualificationIndex(root, root, identity), { message: 'host receipt bytes mismatch' });
});

test('offline certificate expectation uses the real verify seam, not qualificationIndex', async t => {
  const { root, manifest } = await fixture(t);
  // main(verify) reads public checkout locks/version and runs read-only Git identity
  // discovery. All candidate files stay synthetic in the disposable fixture.
  const checkout = fileURLToPath(new URL('../../', import.meta.url));
  const versionText = await readFile(join(checkout, 'pubspec.yaml'), 'utf8');
  const [version, build_number = '1'] = versionText.match(/^version:\s*(\S+)/m)[1].split('+');
  manifest.identity = { ...identity, version, build_number, tag: `v${version}-alpha.1` };
  for (const name of inputs) manifest.inputs[name] = await digest(join(checkout, name));
  await writeFile(join(root, 'android-release-evidence.json'), JSON.stringify(manifest));
  const env = { GITHUB_SHA: identity.source_revision, GITHUB_RUN_ID: identity.run_id,
    GITHUB_RUN_ATTEMPT: identity.run_attempt, GITHUB_REPOSITORY: identity.repository,
    TAG: manifest.identity.tag, WING_RELEASE_CERT_SHA256: 'C'.repeat(64).match(/../g).join(':') };
  const previous = Object.fromEntries(Object.keys(env).map(key => [key, process.env[key]]));
  t.after(() => {
    for (const [key, value] of Object.entries(previous)) {
      if (value === undefined) delete process.env[key]; else process.env[key] = value;
    }
  });
  Object.assign(process.env, env);
  assert.equal(await main(['verify', 'android', root]), undefined);
  for (const expectation of ['d'.repeat(64), '']) {
    process.env.WING_RELEASE_CERT_SHA256 = expectation;
    await assert.rejects(main(['verify', 'android', root]), { message: 'signing identity mismatch' });
  }
});
