import { resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

export const platformJobs = ['linux-web-android', 'wing-link-directory-host', 'wing-link-directory-android-build',
  'windows-build', 'ios-simulator-build', 'macos-build'];
export const releaseJobs = ['validation', 'android', 'linux', 'web', 'wing-link', 'verify-artifacts',
  'android-artifact-smoke', 'wing-link-macos-smoke', 'wing-link-windows-smoke'];

export function verifyJobs(mode, needs, options = {}) {
  const required = mode === 'platform' ? [...platformJobs] : mode === 'release' ? [...releaseJobs] : null;
  if (!required) throw new Error('Unknown CI gate');
  const optional = mode === 'platform' ? ['dependency-review', 'android-emulator-smoke', 'provider-hermes-smoke'] : [];
  if (options.pullRequest) required.push('dependency-review');
  if (options.android) required.push('android-emulator-smoke');
  if (options.provider) required.push('provider-hermes-smoke');
  const known = new Set([...required, ...optional]);
  if (Object.keys(needs).some(name => !known.has(name)) || [...known].some(name => !Object.hasOwn(needs, name))) {
    throw new Error('CI job inventory mismatch');
  }
  for (const name of required) {
    if (needs[name]?.result !== 'success') throw new Error(`Required job did not succeed: ${name}`);
  }
  for (const name of optional.filter(name => !required.includes(name))) {
    if (!['success', 'skipped'].includes(needs[name]?.result)) throw new Error(`Optional job failed: ${name}`);
  }
}
if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try {
    verifyJobs(process.argv[2], JSON.parse(process.env.WING_CI_NEEDS), {
      pullRequest: process.env.WING_CI_EVENT === 'pull_request',
      android: process.env.WING_CI_ANDROID === 'true', provider: process.env.WING_CI_PROVIDER === 'true',
    });
  } catch (error) { console.error(error.message); process.exitCode = 1; }
}
