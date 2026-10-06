import { isDeepStrictEqual } from 'node:util';
import { lstat, realpath } from 'node:fs/promises';
import { join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { readJson, verifyManifest, qualificationIndex } from './release_evidence.mjs';

const identityPatterns = {
  source_revision: /^[a-f0-9]{40}$/,
  tag: /^v\d+\.\d+\.\d+-alpha\.\d+$/,
  version: /^\d+\.\d+\.\d+$/,
  build_number: /^[0-9]{1,20}$/,
  run_id: /^[0-9]{1,20}$/,
  run_attempt: /^[0-9]{1,20}$/,
  repository: /^[a-zA-Z0-9_.-]+\/[a-zA-Z0-9_.-]+$/,
};
const identityFlags = Object.keys(identityPatterns).map(key => key.replaceAll('_', '-'));
const requiredFlags = ['source-root', 'candidate-dir', ...identityFlags, 'android-certificate-sha256'];
const fail = () => { throw new Error('Candidate comparison failed.'); };

function options(args) {
  if (args.length !== requiredFlags.length * 2) fail();
  const values = {};
  for (let i = 0; i < args.length; i += 2) {
    const flag = args[i].slice(2);
    const value = args[i + 1];
    if (!args[i].startsWith('--') || !requiredFlags.includes(flag) || Object.hasOwn(values, flag) ||
        typeof value !== 'string' || !value.length || value.length > 4096 || /[\x00-\x1f\x7f]/.test(value)) fail();
    values[flag] = value;
  }
  const identity = {};
  for (const [key, pattern] of Object.entries(identityPatterns)) {
    const value = values[key.replaceAll('_', '-')];
    if (value.length > 120 || !pattern.test(value)) fail();
    identity[key] = value;
  }
  if (!identity.tag.startsWith(`v${identity.version}-alpha.`) ||
      !/^[a-f0-9]{64}$/.test(values['android-certificate-sha256'])) fail();
  return { root: resolve(values['source-root']), dist: resolve(values['candidate-dir']),
    identity, certificate: values['android-certificate-sha256'] };
}

async function directory(path) {
  const info = await lstat(path);
  if (!info.isDirectory() || info.isSymbolicLink() || await realpath(path) !== path) fail();
}

// Expectations come only from explicit arguments, never candidate metadata, Git or environment.
export async function compareReleaseCandidate(args) {
  const { root, dist, identity, certificate } = options(args);
  await directory(root);
  await directory(dist);
  const published = await readJson(join(dist, 'release-qualification-index.json'));
  const android = await verifyManifest(await readJson(join(dist, 'android-release-evidence.json')),
    root, dist, identity, 'android');
  if (android.signing_identity !== certificate) fail();
  const recomputed = await qualificationIndex(root, dist, identity);
  if (!isDeepStrictEqual(published, recomputed)) fail();
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  compareReleaseCandidate(process.argv.slice(2)).then(() => {
    console.log('Offline candidate comparison matched. Signatures and runtime NOT_CHECKED.');
  }).catch(() => {
    // Never expose exception messages, paths, candidate content or supplied arguments.
    console.error('Offline candidate comparison failed.');
    process.exitCode = 1;
  });
}
