import test from 'node:test';
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { mkdtemp, mkdir, readFile, writeFile, readdir, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { spawnSync } from 'node:child_process';

const source = await readFile(new URL('../../install-termux.sh', import.meta.url), 'utf8');
const sha = data => createHash('sha256').update(data).digest('hex');
const pin = (text, key, value) => text.replace(new RegExp(`^${key}=.*$`, 'm'), `${key}='${value}'`);

test('standalone pins match the reviewed application source metadata', async () => {
  const metadata = JSON.parse(await readFile(new URL('../../assets/config/termux_bootstrap.json', import.meta.url)));
  const fields = {
    hermes_commit: 'hermes_commit', hermes_installer_sha256: 'hermes_installer_sha256',
    hermes_installer_size: 'hermes_installer_size', wing_commit: 'commit',
    wing_archive_sha256: 'archive_sha256', wing_archive_size: 'archive_size',
    wing_installer_sha256: 'installer_sha256',
  };
  for (const [variable, field] of Object.entries(fields)) {
    const value = source.match(new RegExp(`^${variable}='?([a-f0-9]+)'?$`, 'm'))?.[1];
    assert.equal(value, String(metadata[field]), variable);
  }
});

test('help, invalid arguments, and non-Termux execution never install packages', () => {
  const env = { ...process.env, TERMUX_VERSION: '', PREFIX: '' };
  const script = resolve('install-termux.sh');
  assert.equal(spawnSync('bash', [script, '--help'], { env }).status, 0);
  assert.equal(spawnSync('bash', [script, '--unknown'], { env }).status, 2);
  const result = spawnSync('bash', [script], { env, encoding: 'utf8' });
  assert.equal(result.status, 2);
  assert.match(result.stderr, /Open Termux/);
});

for (const mode of ['valid', 'http-failure', 'hermes-size', 'hermes-digest', 'archive-size', 'archive-digest', 'installer-digest', 'adopt', 'broken-existing', 'fresh', 'update', 'launch-failure', 'repair', 'repair-rejected']) {
  test(`artifact verification: ${mode}`, async t => {
    const root = await mkdtemp(join(tmpdir(), 'wing-termux-test-'));
    t.after(() => rm(root, { recursive: true, force: true }));
    const bin = join(root, 'bin');
    const scratch = join(root, 'scratch');
    const commit = 'a'.repeat(40);
    const tree = join(root, `hermes-wing-${commit}`);
    await Promise.all([mkdir(bin), mkdir(scratch), mkdir(tree)]);
    const installer = '#!/bin/bash\nprintf \'%s\\n\' "$1" >> "$FIXTURE_ROOT/executed"\n';
    await writeFile(join(root, 'hermes.sh'), installer);
    await writeFile(join(tree, 'install-wing-link.sh'), installer);
    const archive = join(root, 'source.tar.gz');
    assert.equal(spawnSync('tar', ['-czf', archive, '-C', root, `hermes-wing-${commit}`]).status, 0);
    const archiveBytes = await readFile(archive);
    const installing = ['adopt', 'broken-existing', 'fresh', 'update', 'launch-failure', 'repair', 'repair-rejected'].includes(mode);
    let script = source.replaceAll('/data/data/com.termux/files/usr', root);
    for (const [key, value] of Object.entries({
      wing_commit: commit,
      hermes_installer_sha256: mode === 'hermes-digest' ? '0'.repeat(64) : sha(installer),
      hermes_installer_size: Buffer.byteLength(installer) + (mode === 'hermes-size' ? 1 : 0),
      wing_archive_sha256: mode === 'archive-digest' ? '0'.repeat(64) : sha(archiveBytes),
      wing_archive_size: archiveBytes.length + (mode === 'archive-size' ? 1 : 0),
      wing_installer_sha256: mode === 'installer-digest' ? '0'.repeat(64) : sha(installer),
    })) script = pin(script, key, value);
    const fixtureScript = join(root, 'install-termux.sh');
    await writeFile(fixtureScript, script);
    await writeFile(join(bin, 'curl'), `#!/bin/bash
set -eu
[[ "$CASE_MODE" != http-failure ]] || exit 22
args=" $* "
[[ "$args" == *" --proto =https "* && "$args" == *" --proto-redir =https "* ]]
[[ "$args" == *" --fail "* && "$args" == *" --max-filesize "* && "$args" == *" --max-time 300 "* ]]
while [[ $# -gt 0 ]]; do
  case "$1" in --output) out="$2"; shift 2 ;; *) url="$1"; shift ;; esac
done
case "$url" in
  https://raw.githubusercontent.com/NousResearch/hermes-agent/*/scripts/install.sh) cp "$FIXTURE_ROOT/hermes.sh" "$out" ;;
  https://codeload.github.com/TrebuchetDynamics/hermes-wing/tar.gz/*) cp "$FIXTURE_ROOT/source.tar.gz" "$out" ;;
  *) exit 90 ;;
esac
`, { mode: 0o700 });
    await writeFile(join(bin, 'bash'), '#!/bin/sh\nexec /bin/bash "$@"\n', { mode: 0o700 });
    await writeFile(join(bin, 'uname'), '#!/bin/sh\necho aarch64\n', { mode: 0o700 });
    await writeFile(join(bin, 'pkg'), '#!/bin/sh\nexit 0\n', { mode: 0o700 });
    await writeFile(join(bin, 'clang'), `#!/bin/sh
printf '#!/bin/sh\\nexit 0\\n' > "$4"
touch "$FIXTURE_ROOT/candidate-built"
`, { mode: 0o700 });
    await writeFile(join(bin, 'go'), `#!/bin/sh
case "$CASE_MODE" in
  launch-failure|repair-rejected) exit 1 ;;
  repair) [ -f "$FIXTURE_ROOT/candidate-built" ] || exit 1 ;;
esac
exit 0
`, { mode: 0o700 });
    if (mode === 'adopt' || mode === 'broken-existing' || mode === 'update' || mode === 'launch-failure') {
      await writeFile(join(bin, 'hermes'), `#!/bin/sh\nexit ${mode === 'broken-existing' ? 1 : 0}\n`, { mode: 0o700 });
    }
    const result = spawnSync('/bin/bash', [fixtureScript, ...(['update', 'repair', 'repair-rejected'].includes(mode) ? ['--update-hermes'] : installing ? [] : ['--verify-only'])], {
      encoding: 'utf8', env: { ...process.env, PATH: `${bin}:/usr/bin:/bin`, TMPDIR: scratch, FIXTURE_ROOT: root, CASE_MODE: mode, TERMUX_VERSION: 'fixture', PREFIX: root },
    });
    assert.equal(result.status, ['valid', 'adopt', 'fresh', 'update', 'repair'].includes(mode) ? 0 : mode === 'http-failure' ? 22 : 1, result.stderr);
    if (mode === 'repair') assert.match(result.stdout, /verified native Hermes launcher/);
    if (mode === 'valid') assert.match(result.stdout, /Nothing was installed/);
    const executed = await readFile(join(root, 'executed'), 'utf8').catch(() => '');
    assert.equal(executed, mode === 'adopt' ? '--build\n' : ['fresh', 'update', 'repair'].includes(mode) ? '--commit\n--build\n' : mode === 'repair-rejected' ? '--commit\n' : '');
    if (mode === 'broken-existing') assert.match(result.stderr, /will not overwrite/);
    if (mode === 'launch-failure') assert.match(result.stderr, /stopped before Wing Link/);
    assert.deepEqual(await readdir(scratch), [], 'temporary downloads are cleaned after success or failure');
  });
}

test('real Go launch probe ignores extra Android argv and propagates target failure', async t => {
  const root = await mkdtemp(join(tmpdir(), 'wing-termux-probe-'));
  t.after(() => rm(root, { recursive: true, force: true }));
  const goSource = source.match(/<<'GO'\n([\s\S]*?)\nGO\n/)?.[1];
  assert.ok(goSource);
  const file = join(root, 'probe.go');
  const binary = join(root, 'probe');
  await writeFile(file, goSource);
  const built = spawnSync('go', ['build', '-o', binary, file], { encoding: 'utf8' });
  assert.equal(built.status, 0, built.stderr);
  for (const [target, expected] of [['/bin/true', 0], ['/bin/false', 1]]) {
    const run = spawnSync(binary, [binary, 'unexpected-interpreter-argument'], {
      env: { ...process.env, WING_INSTALL_CHECK_EXECUTABLE: target },
    });
    assert.equal(run.status, expected);
  }
});
