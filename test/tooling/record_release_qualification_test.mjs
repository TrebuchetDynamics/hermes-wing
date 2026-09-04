import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, mkdir, writeFile, readFile, rm } from 'node:fs/promises';
import { join, dirname } from 'node:path';
import { tmpdir } from 'node:os';
import { createManifest, inputs, artifactsByTarget } from '../../scripts/release_evidence.mjs';
import { recordQualification } from '../../scripts/record_release_qualification.mjs';
const identity = { source_revision: 'a'.repeat(40), source_dirty: false, version: '0.1.0',
  build_number: '7', run_id: '12', run_attempt: '1', repository: 'example/wing', tag: 'v0.1.0-alpha.1' };
const observations = {
  WING_ANDROID_PHYSICAL_DEVICE_OBSERVED: 'true', WING_ANDROID_PHYSICAL_MIC_OBSERVED: 'true',
  WING_ANDROID_TTS_OBSERVED: 'true', WING_ANDROID_REARM_OBSERVED: 'true', WING_ANDROID_NO_SECRET_LEAKS: 'true',
  WING_ANDROID_PROVIDER_REPLY_OBSERVED: 'true', WING_ANDROID_DISTINCT_REARMED_TURN_OBSERVED: 'true', WING_ANDROID_SYNTHETIC_AUDIO_USED: 'false',
  WING_HERMES_SERVER_AUDIO_TRANSPORT_OBSERVED: 'true', WING_HERMES_SERVER_AUDIO_PROVIDER_REPLY_OBSERVED: 'true',
  WING_HERMES_SERVER_AUDIO_PLAYBACK_OBSERVED: 'true', WING_HERMES_SERVER_AUDIO_ROUND_TRIP_OBSERVED: 'true',
  WING_HERMES_SERVER_AUDIO_NO_SECRET_LEAKS: 'true', WING_HERMES_SERVER_AUDIO_DEVICE_STT_USED: 'false', WING_HERMES_SERVER_AUDIO_LOCAL_TTS_ONLY: 'false',
  WING_ANDROID_SPOKEN_PHRASE: 'synthetic-private-marker', WING_ANDROID_DEVICE_ID: 'synthetic-private-marker',
  WING_ANDROID_HERMES_URL: 'synthetic-private-marker',
};
async function fixture(t) {
  const root = await mkdtemp(join(tmpdir(), 'wing-qualification-'));
  t.after(() => rm(root, { recursive: true, force: true }));
  for (const name of [...inputs, ...artifactsByTarget.android, 'assets/config/termux_bootstrap.json']) {
    await mkdir(dirname(join(root, name)), { recursive: true }); await writeFile(join(root, name), `synthetic ${name}`);
  }
  await writeFile(join(root, 'android-termux-bootstrap.json'), await readFile(join(root, 'assets/config/termux_bootstrap.json')));
  const manifest = await createManifest(root, root, 'android', identity, { node: 'v22.0.0', flutter: '3.44.2' }, 'c'.repeat(64));
  await writeFile(join(root, 'android-release-evidence.json'), JSON.stringify(manifest));
  const installed = { ...manifest.artifacts[0], sdk: '34', isEmulator: false, microphoneGranted: true,
    version: identity.version, build: identity.build_number, serial: 'synthetic-private-marker', path: 'synthetic-private-marker' };
  return { kind: 'physical-voice', root, dist: root, identity, observations, installed, inspectDevice: async () => installed };
}
test('physical receipt binds installed bytes and omits private inputs', async t => {
  const args = await fixture(t);
  const receipt = await recordQualification(args);
  assert.equal(receipt.schema_version, 2);
  assert.equal(receipt.evidence_kind, 'physical');
  assert.equal(receipt.artifact.sha256, args.installed.sha256);
  assert(!JSON.stringify(receipt).includes('synthetic-private-marker'));
  assert(!JSON.stringify(receipt).includes(args.root));
});
for (const [name, mutate] of Object.entries({
  emulator: args => { args.installed.isEmulator = true; },
  digest: args => { args.installed.sha256 = 'b'.repeat(64); },
  permission: args => { args.installed.microphoneGranted = false; },
  version: args => { args.installed.version = '0.2.0'; },
  build: args => { args.installed.build = '8'; },
  observation: args => { args.observations = { ...observations, WING_ANDROID_TTS_OBSERVED: 'false' }; },
  synthetic: args => { args.observations = { ...observations, WING_ANDROID_SYNTHETIC_AUDIO_USED: 'true' }; },
})) {
  test(`physical receipt rejects ${name}`, async t => {
    const args = await fixture(t); mutate(args);
    await assert.rejects(recordQualification(args));
  });
}
test('server audio does not claim physical microphone qualification', async t => {
  const args = await fixture(t); args.kind = 'server-audio'; args.installed.isEmulator = true;
  const receipt = await recordQualification(args);
  assert.equal(receipt.evidence_kind, 'manual-server-audio');
  assert.equal(receipt.device_class, 'emulator');
  assert(!JSON.stringify(receipt).includes('synthetic-private-marker'));
  args.observations = { ...observations, WING_HERMES_SERVER_AUDIO_DEVICE_STT_USED: 'true' };
  await assert.rejects(recordQualification(args));
});
