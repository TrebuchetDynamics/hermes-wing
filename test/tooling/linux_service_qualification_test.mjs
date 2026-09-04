import { test } from 'node:test';
import assert from 'node:assert/strict';
import { phases, validatePhase, validateSequence } from '../../scripts/record_linux_service_qualification.mjs';
import { artifactsByTarget, inputs } from '../../scripts/release_evidence.mjs';
const hash = letter => ({ size: 1, sha256: letter.repeat(64) });
function manifest(letter, tag) {
  return { schema_version: 1, identity: { source_revision: letter.repeat(40), source_dirty: false,
    version: '0.1.0', build_number: '7', run_id: '12', run_attempt: '1', repository: 'example/wing', tag },
    target: 'wing-link', signing_identity: null, toolchains: { node: 'v22.0.0', go: 'go1.26.0' },
    inputs: Object.fromEntries(inputs.map(name => [name, hash(letter)])),
    artifacts: artifactsByTarget['wing-link'].map(name => ({ name, ...hash(letter) })) };
}
const candidate = manifest('a', 'v0.1.0-alpha.2');
const previous = manifest('b', 'v0.1.0-alpha.1');
const observations = Object.fromEntries(['WING_LINUX_PHASE_OBSERVED', 'WING_LINUX_NO_SECRET_LEAKS', 'WING_LINUX_PREVIOUS_VERIFIED_OBSERVED',
  'WING_LINUX_ACTIVATION_FAILURE_OBSERVED', 'WING_LINUX_PREVIOUS_HEALTH_RESTORED', 'WING_LINUX_SERVICE_ABSENT_OBSERVED', 'WING_LINUX_FILES_REMOVED_OBSERVED'].map(key => [key, 'true']));
const args = phase => ({ phase, candidate, previous, observations, candidateWing: hash('c'), previousWing: hash('d'),
  activeWingLink: phase === 'uninstall' ? null : hash(phase === 'failed-activation-rollback' ? 'b' : 'a'),
  activeWing: phase === 'uninstall' ? null : hash(phase === 'failed-activation-rollback' ? 'd' : 'c') });
test('all lifecycle phases bind the expected artifact generation', () => {
  for (const phase of phases) assert.doesNotThrow(() => validatePhase(args(phase)));
});
test('rollback must restore predecessor bytes and observed health', () => {
  assert.throws(() => validatePhase({ ...args('failed-activation-rollback'), activeWingLink: hash('a') }));
  assert.throws(() => validatePhase({ ...args('failed-activation-rollback'), activeWing: hash('c') }));
  assert.throws(() => validatePhase({ ...args('failed-activation-rollback'),
    observations: { ...observations, WING_LINUX_PREVIOUS_HEALTH_RESTORED: 'false' } }));
});
test('uninstall requires absent files and explicit service observations', () => {
  assert.throws(() => validatePhase({ ...args('uninstall'), activeWingLink: hash('a') }));
  assert.throws(() => validatePhase({ ...args('uninstall'), observations: {} }));
});
function sequence() {
  return phases.map(phase => ({ schema_version: 2, kind: 'linux_service_phase', sequence_id: 'a'.repeat(32),
    phase, candidate: { sha256: 'a'.repeat(64) }, previous: { sha256: 'b'.repeat(64) },
    active_wing_link: args(phase).activeWingLink, active_wing: args(phase).activeWing,
    timestamp_utc: '2026-09-04T12:00:00Z', platform: 'linux', evidence_kind: 'manual-native-service',
    result: 'pass', observations, limitations: [] }));
}
test('sequence rejects missing, duplicate, changed and failed phases', () => {
  validateSequence(sequence());
  assert.throws(() => validateSequence(sequence().slice(1)));
  for (const field of ['sequence_id', 'result', 'phase', 'candidate']) {
    const items = sequence(); items[2][field] = 'changed';
    assert.throws(() => validateSequence(items));
  }
  const duplicate = sequence(); duplicate[2] = duplicate[1];
  assert.throws(() => validateSequence(duplicate));
  const unknown = sequence(); unknown[0].private_path = 'synthetic-private-marker';
  assert.throws(() => validateSequence(unknown));
});
