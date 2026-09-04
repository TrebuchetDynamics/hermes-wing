import { test } from 'node:test';
import assert from 'node:assert/strict';
import { verifyJobs, platformJobs, releaseJobs } from '../../scripts/ci_gate.mjs';
const state = mode => Object.fromEntries((mode === 'release' ? releaseJobs : [...platformJobs,
  'dependency-review', 'android-emulator-smoke', 'provider-hermes-smoke']).map(name => [name, { result: 'success' }]));
for (const mode of ['platform', 'release']) {
  test(`${mode} requires every job to report success`, () => {
    verifyJobs(mode, state(mode));
    for (const name of mode === 'release' ? releaseJobs : platformJobs) {
      for (const result of ['failure', 'skipped', 'cancelled', 'timed_out', undefined]) {
        const needs = state(mode); needs[name].result = result;
        assert.throws(() => verifyJobs(mode, needs));
      }
      const missing = state(mode); delete missing[name];
      assert.throws(() => verifyJobs(mode, missing));
    }
  });
}
test('optional jobs may skip only when not requested', () => {
  const needs = state('platform');
  for (const name of ['dependency-review', 'android-emulator-smoke', 'provider-hermes-smoke']) needs[name].result = 'skipped';
  verifyJobs('platform', needs);
  for (const options of [{ pullRequest: true }, { android: true }, { provider: true }]) {
    assert.throws(() => verifyJobs('platform', needs, options));
  }
});
