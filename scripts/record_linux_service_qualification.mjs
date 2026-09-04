import { createHash } from 'node:crypto';
import { execFileSync } from 'node:child_process';
import { mkdir, writeFile, realpath } from 'node:fs/promises';
import { resolve, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { digest, readJson, validateManifest } from './release_evidence.mjs';

export const phases = ['install', 'start', 'restart', 'health', 'failed-activation-rollback', 'uninstall'];
export function validatePhase({ phase, candidate, previous, activeWingLink, activeWing, candidateWing, previousWing, observations }) {
  if (!phases.includes(phase)) throw new Error('Unknown lifecycle phase');
  validateManifest(candidate); validateManifest(previous);
  if (candidate.target !== 'wing-link' || previous.target !== 'wing-link') throw new Error('Wing Link manifest required');
  if (candidate.identity.source_revision === previous.identity.source_revision &&
      candidate.identity.tag === previous.identity.tag) throw new Error('A distinct verified predecessor is required');
  const required = ['WING_LINUX_PHASE_OBSERVED', 'WING_LINUX_NO_SECRET_LEAKS', 'WING_LINUX_PREVIOUS_VERIFIED_OBSERVED'];
  if (phase === 'failed-activation-rollback') required.push('WING_LINUX_ACTIVATION_FAILURE_OBSERVED', 'WING_LINUX_PREVIOUS_HEALTH_RESTORED');
  if (phase === 'uninstall') required.push('WING_LINUX_SERVICE_ABSENT_OBSERVED', 'WING_LINUX_FILES_REMOVED_OBSERVED');
  for (const key of required) if (observations[key] !== 'true') throw new Error(`Manual observation required: ${key}`);
  if (phase !== 'uninstall') {
    const rollback = phase === 'failed-activation-rollback';
    const manifest = rollback ? previous : candidate;
    const expected = manifest.artifacts.find(item => item.name === 'wing-link-linux-amd64');
    if (!activeWingLink || activeWingLink.sha256 !== expected.sha256 || activeWingLink.size !== expected.size) throw new Error('Active Wing Link bytes do not match expected generation');
    const wing = rollback ? previousWing : candidateWing;
    if (!wing || !activeWing || activeWing.sha256 !== wing.sha256 || activeWing.size !== wing.size) throw new Error('Active Wing bundle bytes do not match expected generation');
  } else if (activeWingLink !== null || activeWing !== null) throw new Error('Uninstall requires absent application files');
  return Object.fromEntries(required.map(key => [key, true]));
}
export function validateSequence(receipts) {
  if (!Array.isArray(receipts) || receipts.length !== phases.length) throw new Error('Incomplete lifecycle sequence');
  const first = receipts[0];
  for (const [index, receipt] of receipts.entries()) {
    const keys = ['schema_version', 'kind', 'sequence_id', 'phase', 'candidate', 'previous', 'active_wing_link', 'active_wing',
      'timestamp_utc', 'platform', 'evidence_kind', 'result', 'observations', 'limitations'];
    if (Object.keys(receipt).sort().join(',') !== keys.sort().join(',')) throw new Error('Unexpected lifecycle receipt fields');
    if (receipt.schema_version !== 2 || receipt.kind !== 'linux_service_phase' || receipt.result !== 'pass' ||
        receipt.phase !== phases[index] || receipt.sequence_id !== first.sequence_id ||
        JSON.stringify(receipt.candidate) !== JSON.stringify(first.candidate) ||
        JSON.stringify(receipt.previous) !== JSON.stringify(first.previous)) throw new Error('Lifecycle receipt identity or order mismatch');
    if (!Number.isFinite(Date.parse(receipt.timestamp_utc)) || (index && Date.parse(receipt.timestamp_utc) < Date.parse(receipts[index - 1].timestamp_utc))) throw new Error('Lifecycle receipt time mismatch');
  }
}
async function releaseSet(directory) {
  const wingLink = await readJson(join(directory, 'wing-link-release-evidence.json'));
  const linux = await readJson(join(directory, 'linux-release-evidence.json'));
  validateManifest(wingLink); validateManifest(linux);
  if (linux.target !== 'linux' || wingLink.target !== 'wing-link') throw new Error('Linux release set required');
  for (const key of ['source_revision', 'version', 'build_number', 'run_id', 'run_attempt', 'repository', 'tag']) {
    if (linux.identity[key] !== wingLink.identity[key]) throw new Error('Mixed release sets');
  }
  for (const manifest of [wingLink, linux]) for (const artifact of manifest.artifacts) {
    const actual = await digest(join(directory, artifact.name));
    if (actual.sha256 !== artifact.sha256 || actual.size !== artifact.size) throw new Error('Release artifact mismatch');
  }
  // Read only the fixed application member. No archive paths are extracted.
  const bytes = execFileSync('tar', ['-xOf', join(directory, 'hermes-wing-linux-x64.tar.gz'), 'bundle/wing'],
    { timeout: 30000, maxBuffer: 256 * 1024 ** 2, stdio: ['ignore', 'pipe', 'pipe'] });
  if (!bytes.length) throw new Error('Missing application bytes');
  return { wingLink, wing: { size: bytes.length, sha256: createHash('sha256').update(bytes).digest('hex') },
    identity: { source_revision: wingLink.identity.source_revision, tag: wingLink.identity.tag,
      wing_link_manifest: await digest(join(directory, 'wing-link-release-evidence.json'), 128 * 1024),
      linux_manifest: await digest(join(directory, 'linux-release-evidence.json'), 128 * 1024) } };
}
async function main() {
  const phase = process.argv[2];
  const sequence = process.env.WING_LINUX_QUALIFICATION_SEQUENCE;
  if (!/^[a-f0-9]{32}$/.test(sequence ?? '')) throw new Error('A random sequence identifier is required');
  for (const key of ['WING_RELEASE_EVIDENCE_DIR', 'WING_PREVIOUS_RELEASE_EVIDENCE_DIR', 'WING_LINUX_ACTIVE_WING_LINK', 'WING_LINUX_ACTIVE_WING']) {
    if (!process.env[key]) throw new Error('Explicit artifact and active file locations required');
  }
  const candidate = await releaseSet(resolve(process.env.WING_RELEASE_EVIDENCE_DIR));
  const previous = await releaseSet(resolve(process.env.WING_PREVIOUS_RELEASE_EVIDENCE_DIR));
  const output = resolve(process.env.WING_LINUX_QUALIFICATION_DIR ?? 'build/receipts/linux-service');
  if (phase === 'complete') {
    const receipts = [];
    const files = [];
    for (const item of phases) {
      const name = `${sequence}-${item}.json`;
      receipts.push(await readJson(join(output, name)));
      files.push({ name, ...await digest(join(output, name), 128 * 1024) });
    }
    validateSequence(receipts);
    for (const receipt of receipts) {
      if (JSON.stringify(receipt.candidate) !== JSON.stringify(candidate.identity) ||
          JSON.stringify(receipt.previous) !== JSON.stringify(previous.identity)) throw new Error('Sequence release identity mismatch');
      validatePhase({ phase: receipt.phase, candidate: candidate.wingLink, previous: previous.wingLink,
        activeWingLink: receipt.active_wing_link, activeWing: receipt.active_wing,
        candidateWing: candidate.wing, previousWing: previous.wing,
        observations: Object.fromEntries(Object.entries(receipt.observations).map(([key, value]) => [key, String(value)])) });
    }
    await writeFile(join(output, `${sequence}-index.json`), JSON.stringify({ schema_version: 2,
      kind: 'linux_service_qualification_index', sequence_id: sequence,
      candidate: candidate.identity, previous: previous.identity, receipts: files,
      limitations: ['Manual observations require a truthful operator', 'Linux amd64 only', 'No signed distribution qualification'],
    }, null, 2) + '\n', { flag: 'wx' });
    console.log('Linux lifecycle sequence bound to exact artifact and receipt bytes.');
    return;
  }
  async function active(path) {
    try { return await digest(await realpath(resolve(path))); }
    catch (error) { if (phase === 'uninstall' && error.code === 'ENOENT') return null; throw error; }
  }
  const activeWingLink = await active(process.env.WING_LINUX_ACTIVE_WING_LINK);
  const activeWing = await active(process.env.WING_LINUX_ACTIVE_WING);
  const observations = validatePhase({ phase, candidate: candidate.wingLink, previous: previous.wingLink,
    activeWingLink, activeWing, candidateWing: candidate.wing, previousWing: previous.wing, observations: process.env });
  const receipt = { schema_version: 2, kind: 'linux_service_phase', sequence_id: sequence, phase,
    candidate: candidate.identity, previous: previous.identity, active_wing_link: activeWingLink, active_wing: activeWing,
    timestamp_utc: new Date().toISOString(), platform: 'linux', evidence_kind: 'manual-native-service', result: 'pass', observations,
    limitations: ['Manual service and health observations require a truthful operator', 'Linux amd64 only', 'No signed distribution qualification'] };
  await mkdir(output, { recursive: true });
  await writeFile(join(output, `${sequence}-${phase}.json`), JSON.stringify(receipt, null, 2) + '\n', { flag: 'wx' });
  console.log('Sanitized Linux lifecycle phase receipt recorded.');
}
if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  main().catch(() => { console.error('Linux lifecycle receipt not recorded; verify bytes, phase, and observations.'); process.exitCode = 1; });
}
