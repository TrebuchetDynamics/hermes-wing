import { createHash } from 'node:crypto';
import { createReadStream, readFileSync } from 'node:fs';
import { lstat, readFile, writeFile, realpath } from 'node:fs/promises';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { execFileSync } from 'node:child_process';

export const artifactsByTarget = Object.freeze({
  android: ['hermes-wing-android.apk', 'hermes-wing-android.aab'],
  linux: ['hermes-wing-linux-x64.tar.gz'],
  web: ['hermes-wing-web.tar.gz'],
  'wing-link': ['wing-link-android-arm64', 'wing-link-darwin-amd64', 'wing-link-darwin-arm64',
    'wing-link-linux-amd64', 'wing-link-linux-arm64', 'wing-link-windows-amd64.exe'],
});
export const inputs = ['pubspec.lock', 'package-lock.json', 'wing_link/go.mod', 'wing_link/go.sum'];
const hashPattern = /^[a-f0-9]{64}$/;
const fail = message => { throw new Error(message); };
const exactKeys = (object, keys) => {
  if (!object || typeof object !== 'object' || Array.isArray(object) ||
      Object.keys(object).sort().join(',') !== [...keys].sort().join(',')) fail('unexpected schema fields');
};
function text(value, pattern = /^[a-zA-Z0-9.+_ -]{1,120}$/) {
  if (typeof value !== 'string' || !pattern.test(value)) fail('invalid bounded identity');
}
export async function digest(path, maxSize = 2 * 1024 ** 3) {
  const info = await lstat(path);
  if (!info.isFile() || info.isSymbolicLink() || info.size < 1 || info.size > maxSize) fail('invalid file type or size');
  // Reject symlinked parent directories as well as the final entry.
  if (await realpath(path) !== resolve(path)) fail('symlinked file path');
  const hash = createHash('sha256');
  let size = 0;
  for await (const chunk of createReadStream(path)) {
    size += chunk.length;
    if (size > maxSize) fail('file grew beyond size bound');
    hash.update(chunk);
  }
  if (size !== info.size) fail('file changed while hashing');
  return { size, sha256: hash.digest('hex') };
}
function validateDigest(value) {
  exactKeys(value, ['size', 'sha256']);
  if (!Number.isSafeInteger(value.size) || value.size < 1 || value.size > 2 * 1024 ** 3 ||
      !hashPattern.test(value.sha256)) fail('invalid digest');
}
function validateIdentity(identity) {
  exactKeys(identity, ['source_revision', 'source_dirty', 'version', 'build_number', 'run_id', 'run_attempt', 'repository', 'tag']);
  text(identity.source_revision, /^[a-f0-9]{40}$/);
  if (typeof identity.source_dirty !== 'boolean') fail('invalid source dirty flag');
  text(identity.version, /^\d+\.\d+\.\d+(?:-[a-zA-Z0-9.]+)?$/);
  for (const key of ['build_number', 'run_id', 'run_attempt']) text(identity[key], /^[0-9]{1,20}$/);
  text(identity.repository, /^[a-zA-Z0-9_.-]+\/[a-zA-Z0-9_.-]+$/);
  text(identity.tag, /^v\d+\.\d+\.\d+-alpha\.\d+$/);
  if (!identity.tag.startsWith(`v${identity.version}-alpha.`)) fail('tag/version mismatch');
}
export async function createManifest(root, dist, target, identity, toolchains, signingIdentity = null) {
  validateIdentity(identity);
  if (!Object.hasOwn(artifactsByTarget, target)) fail('unknown target');
  const requiredInputs = [...inputs, ...(target === 'android' ? ['assets/config/termux_bootstrap.json'] : [])];
  const inputHashes = {};
  for (const name of requiredInputs) inputHashes[name] = await digest(join(root, name), 16 * 1024 ** 2);
  const artifacts = [];
  for (const name of artifactsByTarget[target]) artifacts.push({ name, ...await digest(join(dist, name)) });
  const manifest = { schema_version: 1, identity, target, toolchains, signing_identity: signingIdentity, inputs: inputHashes, artifacts };
  validateManifest(manifest);
  return manifest;
}
export function validateManifest(manifest) {
  exactKeys(manifest, ['schema_version', 'identity', 'target', 'toolchains', 'signing_identity', 'inputs', 'artifacts']);
  if (manifest.schema_version !== 1) fail('unsupported schema');
  validateIdentity(manifest.identity);
  if (!Object.hasOwn(artifactsByTarget, manifest.target)) fail('unknown target');
  if (manifest.target === 'android' ? !hashPattern.test(manifest.signing_identity) : manifest.signing_identity !== null) fail('invalid signing identity');
  exactKeys(manifest.toolchains, manifest.target === 'wing-link' ? ['node', 'go'] : ['node', 'flutter']);
  for (const value of Object.values(manifest.toolchains)) text(value);
  const expectedInputs = [...inputs, ...(manifest.target === 'android' ? ['assets/config/termux_bootstrap.json'] : [])];
  exactKeys(manifest.inputs, expectedInputs);
  for (const value of Object.values(manifest.inputs)) validateDigest(value);
  if (!Array.isArray(manifest.artifacts) || manifest.artifacts.length !== artifactsByTarget[manifest.target].length) fail('artifact inventory mismatch');
  const names = manifest.artifacts.map(artifact => {
    exactKeys(artifact, ['name', 'size', 'sha256']);
    validateDigest({ size: artifact.size, sha256: artifact.sha256 });
    return artifact.name;
  });
  if (names.sort().join(',') !== [...artifactsByTarget[manifest.target]].sort().join(',')) fail('artifact inventory mismatch');
}
export async function verifyManifest(manifest, root, dist, expectedIdentity, target) {
  validateManifest(manifest);
  if (manifest.target !== target) fail('target mismatch');
  for (const [key, value] of Object.entries(expectedIdentity)) {
    if (manifest.identity[key] !== value) fail(`identity mismatch: ${key}`);
  }
  for (const [name, expected] of Object.entries(manifest.inputs)) {
    // Android's generated input travels with the artifact, not the verifier checkout.
    const path = name === 'assets/config/termux_bootstrap.json'
      ? join(dist, 'android-termux-bootstrap.json') : join(root, name);
    const actual = await digest(path, 16 * 1024 ** 2);
    if (actual.sha256 !== expected.sha256 || actual.size !== expected.size) fail(`input mismatch: ${name}`);
  }
  for (const { name, size, sha256 } of manifest.artifacts) {
    const actual = await digest(join(dist, name));
    if (actual.sha256 !== sha256 || actual.size !== size) fail(`artifact mismatch: ${name}`);
  }
  return manifest;
}
export async function readJson(path) {
  await digest(path, 128 * 1024);
  return JSON.parse(await readFile(path, 'utf8'));
}
const smokeReceipts = {
  'android-artifact-smoke.txt': { target: 'android', names: ['hermes-wing-android.apk'], result: 'verified-installed-launched', evidence: 'emulator', scenario: 'apk-install-launch' },
  'wing-link-macos-smoke.txt': { target: 'wing-link', names: ['wing-link-darwin-arm64', 'wing-link-darwin-amd64'], result: 'verified-ran-version', evidence: 'native', scenario: 'binary-version' },
  'wing-link-windows-smoke.txt': { target: 'wing-link', names: ['wing-link-windows-amd64.exe'], result: 'verified-ran-version', evidence: 'native', scenario: 'binary-version' },
};
export function validateSmokeReceipt(receipt, manifest, manifestHash, contract) {
  exactKeys(receipt, ['tag', 'source_revision', 'run_id', 'run_attempt', 'build_number', 'binary',
    'artifact_sha256', 'manifest_sha256', 'result', 'evidence_kind', 'scenario', 'timestamp_utc']);
  for (const key of ['tag', 'source_revision', 'run_id', 'run_attempt', 'build_number']) {
    if (receipt[key] !== manifest.identity[key]) fail(`receipt identity mismatch: ${key}`);
  }
  const artifact = manifest.artifacts.find(item => item.name === receipt.binary);
  if (!contract.names.includes(receipt.binary) || !artifact || artifact.sha256 !== receipt.artifact_sha256 ||
      manifestHash !== receipt.manifest_sha256 || receipt.result !== contract.result ||
      receipt.evidence_kind !== contract.evidence || receipt.scenario !== contract.scenario ||
      !/^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ$/.test(receipt.timestamp_utc) || !Number.isFinite(Date.parse(receipt.timestamp_utc))) {
    fail('receipt artifact or qualification mismatch');
  }
}
export async function qualificationIndex(root, dist, identity) {
  const manifests = {};
  const manifestDigests = {};
  const artifacts = [];
  const { source_dirty, ...expected } = identity;
  for (const target of Object.keys(artifactsByTarget)) {
    const name = `${target}-release-evidence.json`;
    const manifest = await readJson(join(dist, name));
    await verifyManifest(manifest, root, dist, expected, target);
    manifests[target] = manifest;
    manifestDigests[name] = await digest(join(dist, name), 128 * 1024);
    artifacts.push(...manifest.artifacts);
  }
  const receipts = [];
  for (const [name, contract] of Object.entries(smokeReceipts)) {
    const file = await digest(join(dist, name), 8192);
    const receipt = {};
    for (const line of (await readFile(join(dist, name), 'utf8')).replace(/^\uFEFF/, '').trim().split(/\r?\n/)) {
      const match = /^([a-z_][a-z_0-9]*)=([^\r\n]+)$/.exec(line);
      if (!match || Object.hasOwn(receipt, match[1])) fail('invalid receipt fields');
      receipt[match[1]] = match[2];
    }
    validateSmokeReceipt(receipt, manifests[contract.target], manifestDigests[`${contract.target}-release-evidence.json`].sha256, contract);
    receipts.push({ name, ...file, artifact_sha256: receipt.artifact_sha256, scenario: contract.scenario, evidence_kind: contract.evidence });
  }
  const hostReceiptName = 'release-verification-receipt.json';
  const host = await readJson(join(dist, hostReceiptName));
  exactKeys(host, ['schema_version', 'tag', 'source_revision', 'verified_at', 'android_certificate_sha256', 'checks', 'artifacts']);
  if (host.schema_version !== 1 || host.tag !== identity.tag || host.source_revision !== identity.source_revision ||
      host.android_certificate_sha256.replaceAll(/[:\s]/g, '').toLowerCase() !== manifests.android.signing_identity) fail('host receipt identity mismatch');
  const expectedChecks = ['exact_allowlist', 'sha256_sidecars', 'android_apk_signature', 'android_aab_signature',
    'archive_path_safety', 'linux_bundle_launch', 'web_browser_launch', 'wing_link_linux_amd64_version',
    'wing_link_linux_arm64_version', 'foreign_binary_formats'];
  if (!Array.isArray(host.checks) || [...host.checks].sort().join(',') !== expectedChecks.sort().join(',')) fail('host checks incomplete');
  const auxiliary = ['android-termux-bootstrap.json', 'wing-link-checksums.sha256',
    ...Object.keys(manifestDigests), ...artifacts.filter(item => item.name.startsWith('hermes-wing')).map(item => `${item.name}.sha256`)];
  const expectedFiles = [...artifacts.map(item => item.name), ...auxiliary].sort();
  if (!Array.isArray(host.artifacts) || host.artifacts.map(item => item.name).sort().join(',') !== expectedFiles.join(',')) fail('host receipt artifact inventory mismatch');
  for (const item of host.artifacts) {
    exactKeys(item, ['name', 'bytes', 'sha256']);
    const actual = await digest(join(dist, item.name));
    if (actual.size !== item.bytes || actual.sha256 !== item.sha256) fail('host receipt bytes mismatch');
  }
  receipts.push({ name: hostReceiptName, ...await digest(join(dist, hostReceiptName), 128 * 1024),
    scenario: 'archive-signature-launch', evidence_kind: 'native-and-emulated' });
  return { schema_version: 1, identity: expected, inputs: manifests.web.inputs, manifests: manifestDigests,
    artifacts, auxiliary: host.artifacts.filter(item => auxiliary.includes(item.name)), receipts,
    limitations: ['No physical voice qualification', 'APK launch does not qualify AAB delivery', 'Native version execution does not qualify service lifecycle'] };
}
export function currentIdentity(root) {
  const [version, build_number = '1'] = readFileSyncVersion(root).split('+');
  return {
    source_revision: process.env.GITHUB_SHA ?? execFileSync('git', ['rev-parse', 'HEAD'], { cwd: root, encoding: 'utf8' }).trim(),
    source_dirty: execFileSync('git', ['status', '--porcelain', '--untracked-files=no'], { cwd: root, encoding: 'utf8' }).trim() !== '',
    version, build_number,
    run_id: process.env.GITHUB_RUN_ID ?? '0', run_attempt: process.env.GITHUB_RUN_ATTEMPT ?? '0',
    repository: process.env.GITHUB_REPOSITORY ?? 'local/hermes-wing', tag: process.env.TAG ?? '',
  };
}
function readFileSyncVersion(root) {
  const version = readFileSync(join(root, 'pubspec.yaml'), 'utf8').match(/^version:\s*(\S+)/m)?.[1];
  if (!version) fail('missing source version');
  return version;
}
export async function main(args) {
  const [command, target, directory] = args;
  const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
  if (command === 'aggregate' && args.length === 2) {
    const dist = resolve(target);
    const index = await qualificationIndex(root, dist, currentIdentity(root));
    await writeFile(join(dist, 'release-qualification-index.json'), `${JSON.stringify(index, null, 2)}\n`, { flag: 'wx' });
    return;
  }
  if (!['emit', 'verify'].includes(command) || args.length !== 3 || !Object.hasOwn(artifactsByTarget, target)) {
    fail('usage: release_evidence.mjs emit|verify android|linux|web|wing-link DIST');
  }
  const dist = resolve(directory);
  const path = join(dist, `${target}-release-evidence.json`);
  const identity = currentIdentity(root);
  if (command === 'emit') {
    // Read versions from the installed toolchain; never infer them from workflow labels.
    const toolchains = { node: process.version };
    if (target === 'wing-link') toolchains.go = execFileSync('go', ['version'], { encoding: 'utf8' }).trim().split(' ')[2];
    else toolchains.flutter = JSON.parse(execFileSync('flutter', ['--version', '--machine'], { encoding: 'utf8' })).frameworkVersion;
    const signingIdentity = target === 'android'
      ? (process.env.WING_RELEASE_CERT_SHA256 ?? '').replaceAll(/[:\s]/g, '').toLowerCase() : null;
    const manifest = await createManifest(root, dist, target, identity, toolchains, signingIdentity);
    if (target === 'android') await writeFile(join(dist, 'android-termux-bootstrap.json'), await readFile(join(root, 'assets/config/termux_bootstrap.json')), { flag: 'wx' });
    await writeFile(path, `${JSON.stringify(manifest, null, 2)}\n`, { flag: 'wx' });
  } else {
    const { source_dirty, ...expected } = identity;
    const manifest = await verifyManifest(await readJson(path), root, dist, expected, target);
    if (target === 'android' && manifest.signing_identity !==
        (process.env.WING_RELEASE_CERT_SHA256 ?? '').replaceAll(/[:\s]/g, '').toLowerCase()) fail('signing identity mismatch');
  }
}
if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  main(process.argv.slice(2)).catch(() => { console.error('Release evidence validation failed.'); process.exitCode = 1; });
}
