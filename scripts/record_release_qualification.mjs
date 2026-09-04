import { execFileSync } from 'node:child_process';
import { mkdtemp, rm, mkdir, writeFile, realpath } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { digest, readJson, verifyManifest, currentIdentity } from './release_evidence.mjs';

const requirements = {
  'physical-voice': {
    true: ['WING_ANDROID_PHYSICAL_DEVICE_OBSERVED', 'WING_ANDROID_PHYSICAL_MIC_OBSERVED',
      'WING_ANDROID_TTS_OBSERVED', 'WING_ANDROID_REARM_OBSERVED', 'WING_ANDROID_NO_SECRET_LEAKS',
      'WING_ANDROID_PROVIDER_REPLY_OBSERVED', 'WING_ANDROID_DISTINCT_REARMED_TURN_OBSERVED'],
    false: ['WING_ANDROID_SYNTHETIC_AUDIO_USED'],
  },
  'server-audio': {
    true: ['WING_HERMES_SERVER_AUDIO_TRANSPORT_OBSERVED', 'WING_HERMES_SERVER_AUDIO_PROVIDER_REPLY_OBSERVED',
      'WING_HERMES_SERVER_AUDIO_PLAYBACK_OBSERVED', 'WING_HERMES_SERVER_AUDIO_ROUND_TRIP_OBSERVED',
      'WING_HERMES_SERVER_AUDIO_NO_SECRET_LEAKS'],
    false: ['WING_HERMES_SERVER_AUDIO_DEVICE_STT_USED', 'WING_HERMES_SERVER_AUDIO_LOCAL_TTS_ONLY'],
  },
};
export function validateObservations(kind, observations) {
  if (!Object.hasOwn(requirements, kind)) throw new Error('Unsupported qualification scenario');
  for (const [value, names] of Object.entries(requirements[kind])) {
    for (const name of names) if (observations[name] !== value) throw new Error(`Manual observation required: ${name}=${value}`);
  }
}
async function inspectAndroid() {
  const device = process.env.WING_ANDROID_DEVICE_ID;
  if (!device || !/^[a-zA-Z0-9._:-]{1,120}$/.test(device)) throw new Error('An explicit Android device is required');
  const adb = args => execFileSync('adb', ['-s', device, ...args],
    { encoding: 'utf8', timeout: 30000, maxBuffer: 1024 * 1024, stdio: ['ignore', 'pipe', 'pipe'] }).trim();
  const packageName = 'com.trebuchetdynamics.hermes.wing';
  const path = adb(['shell', 'pm', 'path', packageName]);
  // A split/store installation is a different delivered artifact set.
  if (!/^package:\/data\/app\/[^\r\n]+\/base\.apk$/.test(path)) throw new Error('A single installed base APK is required');
  const properties = adb(['shell', 'dumpsys', 'package', packageName]);
  const isEmulator = device.startsWith('emulator-') ||
    adb(['shell', 'getprop', 'ro.kernel.qemu']) === '1' || adb(['shell', 'getprop', 'ro.boot.qemu']) === '1';
  const sdk = adb(['shell', 'getprop', 'ro.build.version.sdk']);
  if (!/^[0-9]{1,3}$/.test(sdk)) throw new Error('Missing Android OS identity');
  const temporary = await realpath(await mkdtemp(join(tmpdir(), 'wing-installed-artifact-')));
  try {
    const installed = join(temporary, 'installed.apk');
    adb(['pull', path.slice('package:'.length), installed]);
    return { ...await digest(installed), sdk, isEmulator,
      version: properties.match(/\bversionName=([^\s]+)/)?.[1],
      build: properties.match(/\bversionCode=([0-9]+)/)?.[1],
      microphoneGranted: /android\.permission\.RECORD_AUDIO:\s+granted=true/i.test(properties) };
  } finally { await rm(temporary, { recursive: true, force: true }); }
}
export async function recordQualification({ kind, root, dist, identity, observations, inspectDevice = inspectAndroid }) {
  validateObservations(kind, observations);
  const { source_dirty, ...expected } = identity;
  const manifestName = 'android-release-evidence.json';
  const manifest = await verifyManifest(await readJson(join(dist, manifestName)), root, dist, expected, 'android');
  const installed = await inspectDevice();
  const artifact = manifest.artifacts.find(item => item.name === 'hermes-wing-android.apk');
  if (installed.sha256 !== artifact.sha256 || installed.size !== artifact.size ||
      installed.version !== identity.version || installed.build !== identity.build_number) throw new Error('Installed package does not match release artifact');
  if (typeof installed.isEmulator !== 'boolean' || !/^[0-9]{1,3}$/.test(installed.sdk)) throw new Error('Missing platform identity');
  if (kind === 'physical-voice' && (installed.isEmulator || installed.microphoneGranted !== true)) throw new Error('Physical microphone device required');
  return {
    schema_version: 2, kind: 'release_qualification', identity: expected,
    manifest: { name: manifestName, ...await digest(join(dist, manifestName), 128 * 1024) },
    artifact, scenario: kind, timestamp_utc: new Date().toISOString(),
    platform: 'android', os: `Android API ${installed.sdk}`,
    device_class: installed.isEmulator ? 'emulator' : 'physical-device',
    evidence_kind: kind === 'physical-voice' ? 'physical' : 'manual-server-audio', result: 'pass',
    observations: Object.fromEntries(Object.values(requirements[kind]).flat().map(name => [name, observations[name] === 'true'])),
    limitations: kind === 'physical-voice'
      ? ['Manual observations require a truthful operator', 'No acoustic benchmark or AAB qualification']
      : ['Manual observations require a truthful operator', 'No physical microphone or acoustic qualification'],
  };
}
async function main() {
  const kind = process.argv[2];
  const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
  if (!process.env.WING_RELEASE_EVIDENCE_DIR) throw new Error('WING_RELEASE_EVIDENCE_DIR is required');
  const output = resolve(process.env.WING_RELEASE_QUALIFICATION_RECEIPT ?? `build/receipts/${kind}-release-qualification.json`);
  const receipt = await recordQualification({ kind, root, dist: resolve(process.env.WING_RELEASE_EVIDENCE_DIR),
    identity: currentIdentity(root), observations: process.env });
  await mkdir(dirname(output), { recursive: true });
  // Existing receipts are immutable observations; choose a new output for another run.
  await writeFile(output, JSON.stringify(receipt, null, 2) + '\n', { flag: 'wx' });
  console.log('Sanitized artifact-bound qualification receipt recorded.');
}
if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  main().catch(() => { console.error('Qualification not recorded: verify artifact identity, device, and manual observation flags.'); process.exitCode = 1; });
}
